import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { mintEphemeralToken, isSessionValid } from '../modules/live/liveService.js';
import { executeTool, type ToolContext } from '../modules/live/executeLiveTool.js';
import { LiveSessionTokenRequestSchema, LiveToolExecutionRequestSchema } from '../models/types.js';
import { randomUUID } from 'crypto';
import * as game from '../services/gameService.js';

export async function liveRoutes(server: FastifyInstance) {
  // ─── POST /live/ephemeral-token ──────────────────
  server.post('/ephemeral-token', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const body = LiveSessionTokenRequestSchema.safeParse(request.body ?? {});
    const sessionType = body.success ? body.data.sessionType : 'quiz';

    const session = mintEphemeralToken(userId, sessionType);

    await game.audit(userId, 'ephemeral_token_minted', {
      sessionType,
      expiresAt: session.expiresAt,
    });

    server.log.info({ userId, sessionType }, 'Ephemeral token minted');
    return { session: { token: session.token, sessionId: session.sessionId, model: session.model, expiresAt: session.expiresAt, tools: session.tools } };
  });

  // ─── POST /live/tool-execute ─────────────────────
  server.post('/tool-execute', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const parsed = LiveToolExecutionRequestSchema.safeParse(request.body);

    if (!parsed.success) {
      return reply.status(400).send({
        success: false,
        error: `Invalid request: ${parsed.error.message}`,
      });
    }

    const { toolName, args, sessionId, correlationId } = parsed.data;
    const ctx: ToolContext = {
      userId,
      sessionId,
      correlationId: correlationId || `corr_${randomUUID().substring(0, 8)}`,
    };

    // Validate session is still active
    if (sessionId && !isSessionValid(sessionId)) {
      return reply.status(410).send({
        success: false,
        error: 'Session expired. Request a new ephemeral token.',
      });
    }

    server.log.info({ userId, toolName, sessionId, correlationId: ctx.correlationId }, 'Tool execution');

    const result = await executeTool(toolName, args, ctx);
    return result;
  });

  // ─── POST /live/session-log ──────────────────────
  server.post('/session-log', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const body = request.body as any;
    const { sessionId, events } = body || {};

    server.log.info({ userId, sessionId, eventCount: events?.length || 0 }, 'Session log received');

    await game.audit(userId, 'session_log', {
      sessionId,
      eventCount: events?.length || 0,
    });

    return { received: true, sessionId };
  });

  // ─── GET /live/config ────────────────────────────
  server.get('/config', async (request: FastifyRequest, reply: FastifyReply) => {
    return {
      supportedModes: ['onboarding', 'quiz', 'vision_quest'],
      voiceName: 'Aoede',
      responseModalities: ['AUDIO', 'TEXT'],
    };
  });
}
