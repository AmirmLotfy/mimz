import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { mintEphemeralToken, isSessionValid, getSessionEventId } from '../modules/live/liveService.js';
import { executeTool, type ToolContext } from '../modules/live/executeLiveTool.js';
import { LiveSessionTokenRequestSchema, LiveToolExecutionRequestSchema } from '../models/types.js';
import { randomUUID } from 'crypto';
import * as game from '../services/gameService.js';
import { z } from 'zod';

const SessionLogSchema = z.object({
  sessionId: z.string().min(1),
  events: z.array(z.record(z.string(), z.unknown())).max(500),
});

export async function liveRoutes(server: FastifyInstance) {
  // ─── POST /live/ephemeral-token ──────────────────
  server.post('/ephemeral-token', async (request: FastifyRequest, reply: FastifyReply) => {
    const traceId = (request.headers['x-correlation-id'] as string | undefined)?.trim() || request.id;
    reply.header('x-correlation-id', traceId);
    const userId = request.userId!;
    const body = LiveSessionTokenRequestSchema.safeParse(request.body ?? {});
    const sessionType = body.success ? body.data.sessionType : 'quiz';
    const eventId = body.success ? body.data.eventId : undefined;

    let session;
    try {
      session = await mintEphemeralToken(userId, sessionType, eventId);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      const isConfig = msg.includes('GEMINI_API_KEY') ||
        msg.includes('not configured') ||
        msg.includes('Vertex auth failed');
      server.log.warn({ userId, sessionType, traceId, err: msg }, 'Ephemeral token mint failed');
      return reply.status(isConfig ? 503 : 500).send({
        error: isConfig ? 'Live sessions are temporarily unavailable.' : 'Failed to start live session.',
        code: isConfig ? 'LIVE_NOT_CONFIGURED' : 'LIVE_ERROR',
        traceId,
        retryable: !isConfig,
      });
    }

    await game.audit(userId, 'ephemeral_token_minted', {
      sessionType,
      expiresAt: session.expiresAt,
    });

    server.log.info({ userId, sessionType, traceId }, 'Ephemeral token minted');
    return {
      session: {
        token: session.token,
        authType: session.authType,
        websocketUrl: session.websocketUrl,
        sessionId: session.sessionId,
        model: session.model,
        expiresAt: session.expiresAt,
        tools: session.tools,
        systemInstruction: session.systemInstruction,
        traceId,
      },
    };
  });

  // ─── POST /live/tool-execute ─────────────────────
  server.post('/tool-execute', async (request: FastifyRequest, reply: FastifyReply) => {
    const traceId = (request.headers['x-correlation-id'] as string | undefined)?.trim() || request.id;
    reply.header('x-correlation-id', traceId);
    const userId = request.userId!;
    const parsed = LiveToolExecutionRequestSchema.safeParse(request.body);

    if (!parsed.success) {
      return reply.status(400).send({
        success: false,
        error: `Invalid request: ${parsed.error.message}`,
        code: 'LIVE_TOOL_BAD_REQUEST',
        traceId,
        retryable: false,
      });
    }

    const { toolName, args, sessionId, correlationId } = parsed.data;
    const ctx: ToolContext = {
      userId,
      sessionId,
      correlationId: correlationId || `corr_${randomUUID().substring(0, 8)}`,
      eventId: getSessionEventId(sessionId),
    };

    // Session validation is best-effort: in-memory state can be lost on Cloud
    // Run restart or scale-out. Log a warning but still execute the tool so
    // the game doesn't silently break. Security here relies on Firebase auth
    // (userId already verified by middleware).
    if (sessionId && !isSessionValid(sessionId, userId)) {
      server.log.warn({ userId, sessionId, traceId }, 'Session not found in memory — may have been lost on Cloud Run restart/scale. Continuing anyway.');
    }

    server.log.info({ userId, toolName, sessionId, correlationId: ctx.correlationId, traceId }, 'Tool execution');

    const result = await executeTool(toolName, args, ctx);
    return result;
  });

  // ─── POST /live/session-log ──────────────────────
  server.post('/session-log', async (request: FastifyRequest, reply: FastifyReply) => {
    const traceId = (request.headers['x-correlation-id'] as string | undefined)?.trim() || request.id;
    reply.header('x-correlation-id', traceId);
    const userId = request.userId!;
    const parsed = SessionLogSchema.safeParse(request.body ?? {});
    if (!parsed.success) {
      return reply.status(400).send({
        error: 'Invalid session log payload',
        code: 'LIVE_SESSION_LOG_BAD_REQUEST',
        traceId,
      });
    }
    const { sessionId, events } = parsed.data;

    server.log.info({ userId, sessionId, eventCount: events?.length || 0, traceId }, 'Session log received');

    await game.audit(userId, 'session_log', {
      sessionId,
      eventCount: events?.length || 0,
    });

    return { received: true, sessionId, traceId };
  });

  // ─── GET /live/config ────────────────────────────
  server.get('/config', async (request: FastifyRequest, reply: FastifyReply) => {
    return {
      supportedModes: ['onboarding', 'quiz', 'sprint', 'vision_quest', 'event'],
      voiceName: 'Aoede',
      responseModalities: ['AUDIO'],
    };
  });

  // ─── GET /live/vision-quests ──────────────────────
  server.get('/vision-quests', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const quests = await import('../lib/db.js').then(db => db.getUserVisionQuests(userId, 20));
    return { quests };
  });
}
