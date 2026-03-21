import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { randomUUID } from 'crypto';
import { GoogleAuth } from 'google-auth-library';
import * as db from '../lib/db.js';
import * as game from '../services/gameService.js';
import { config } from '../config/index.js';

const StartVisionQuestSchema = z.object({
  theme: z.string().default('discovery'),
});

const CaptureVisionQuestSchema = z.object({
  objectIdentified: z.string().min(1).optional(),
  confidence: z.number().min(0).max(1).optional(),
  imageBase64: z.string().optional(),
});

function extractJsonPayload(raw: string): Record<string, unknown> | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;

  try {
    return JSON.parse(trimmed) as Record<string, unknown>;
  } catch (_) {
    const start = trimmed.indexOf('{');
    const end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      return JSON.parse(trimmed.slice(start, end + 1)) as Record<string, unknown>;
    } catch (_) {
      return null;
    }
  }
}

async function inferVisionObservation(
  imageBase64: string,
  quest: {
    targetPrompt?: string;
    targetKeywords?: string[];
  },
): Promise<{ label: string; confidence: number } | null> {
  const prompt = [
    'You are validating a Mimz vision quest capture.',
    `Target prompt: ${quest.targetPrompt ?? 'discovery'}.`,
    `Target keywords: ${(quest.targetKeywords ?? []).join(', ') || 'none'}.`,
    'Look at the image and return JSON only.',
    'Schema: {"label":"short label","confidence":0.0}',
    'Use a low confidence if the target is not clearly visible.',
  ].join('\n');

  const body = {
    contents: [
      {
        role: 'user',
        parts: [
          { text: prompt },
          {
            inlineData: {
              mimeType: 'image/jpeg',
              data: imageBase64,
            },
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.1,
      responseMimeType: 'application/json',
    },
  };

  let response: Response;
  if (config.geminiAuthMode === 'vertex') {
    const auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });
    const token = await auth.getAccessToken();
    if (!token) {
      throw new Error('Could not mint a Vertex access token for vision analysis.');
    }

    const url =
      `https://${config.geminiVertexLocation}-aiplatform.googleapis.com/v1/` +
      `projects/${config.gcpProjectId}/locations/${config.geminiVertexLocation}/` +
      `publishers/google/models/${config.geminiImageModel}:generateContent`;

    response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });
  } else {
    if (!config.geminiApiKey || config.geminiApiKey === 'dev-key-replace-me') {
      throw new Error('Gemini API key is not configured for vision analysis.');
    }

    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/` +
      `${config.geminiImageModel}:generateContent?key=${config.geminiApiKey}`;

    response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
  }

  if (!response.ok) {
    throw new Error(`Vision analysis failed with ${response.status}`);
  }

  const payload = await response.json() as {
    candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
  };
  const rawText = payload.candidates?.[0]?.content?.parts
    ?.map((part) => part.text ?? '')
    .join('\n') ?? '';
  const parsed = extractJsonPayload(rawText);
  if (!parsed) return null;

  const label = String(parsed.label ?? parsed.objectIdentified ?? '').trim();
  const confidence = Number(parsed.confidence ?? 0);
  if (!label) return null;

  return {
    label,
    confidence: Number.isFinite(confidence)
      ? Math.max(0, Math.min(1, confidence))
      : 0,
  };
}

export async function visionQuestRoutes(server: FastifyInstance) {
  server.post('/start', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const parsed = StartVisionQuestSchema.safeParse(request.body ?? {});
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid vision quest payload' });
    }

    const blueprint = game.buildVisionQuestBlueprint(parsed.data.theme);
    const quest = {
      id: `vq_${randomUUID()}`,
      userId,
      theme: parsed.data.theme,
      targetPrompt: blueprint.targetPrompt,
      targetKeywords: blueprint.targetKeywords,
      status: 'active',
      confidence: 0,
      isValid: false,
      startedAt: new Date().toISOString(),
    };

    await db.createVisionQuest(quest);
    await game.audit(userId, 'vision_quest_start_rest', {
      questId: quest.id,
      theme: quest.theme,
      targetKeywords: blueprint.targetKeywords,
    });

    return {
      questId: quest.id,
      theme: quest.theme,
      targetPrompt: blueprint.targetPrompt,
      targetKeywords: blueprint.targetKeywords,
      rewardStructureId: blueprint.rewardStructureId,
    };
  });

  server.post<{ Params: { questId: string } }>(
    '/:questId/capture',
    async (request, reply) => {
      const userId = request.userId!;
      const parsed = CaptureVisionQuestSchema.safeParse(request.body ?? {});
      if (!parsed.success) {
        return reply.status(400).send({ error: 'Invalid vision capture payload' });
      }

      const quest = await db.getVisionQuest(request.params.questId);
      if (!quest || quest.userId !== userId) {
        return reply.status(404).send({ error: 'Vision quest not found' });
      }

      const inferred = !parsed.data.objectIdentified && parsed.data.imageBase64
        ? await inferVisionObservation(parsed.data.imageBase64, {
            targetPrompt: quest.targetPrompt as string | undefined,
            targetKeywords: Array.isArray(quest.targetKeywords)
              ? quest.targetKeywords as string[]
              : [],
          }).catch(() => null)
        : null;

      const objectIdentified = parsed.data.objectIdentified ?? inferred?.label ?? '';
      const confidence = parsed.data.confidence ?? inferred?.confidence ?? 0;
      const isValid = game.validateVisionQuestObservation(
        Array.isArray(quest.targetKeywords) ? quest.targetKeywords as string[] : [],
        objectIdentified,
        confidence,
      );

      let xpAwarded = 0;
      let influenceGranted = 0;
      let materialsEarned = { stone: 0, glass: 0, wood: 0 };

      if (isValid) {
        xpAwarded = 200;
        influenceGranted = game.calculateInfluenceGrant('vision_quest', 'medium', 0);
        materialsEarned = { stone: 8, glass: 4, wood: 6 };

        await db.incrementUserXp(userId, xpAwarded);
        await db.incrementUserInfluence(userId, influenceGranted);
        const district = await game.getDistrict(userId);
        if (district) {
          await db.incrementDistrictInfluence(district.id, influenceGranted);
          await db.addResources(district.id, materialsEarned);
        }
      }

      await db.updateVisionQuest(request.params.questId, {
        objectIdentified,
        confidence,
        isValid,
        status: isValid ? 'completed' : 'failed',
        completedAt: new Date().toISOString(),
      });

      await game.audit(userId, 'vision_quest_capture_rest', {
        questId: request.params.questId,
        objectIdentified,
        confidence,
        isValid,
      });

      return {
        questId: request.params.questId,
        targetPrompt: quest.targetPrompt,
        objectIdentified,
        confidence,
        isValid,
        xpAwarded,
        influenceGranted,
        materialsEarned,
      };
    },
  );

  server.post<{ Params: { questId: string } }>(
    '/:questId/finish',
    async (request, reply) => {
      const quest = await db.getVisionQuest(request.params.questId);
      if (!quest || quest.userId !== request.userId) {
        return reply.status(404).send({ error: 'Vision quest not found' });
      }

      return { quest };
    },
  );
}
