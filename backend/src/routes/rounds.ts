import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { RoundStartRequestSchema } from '../models/types.js';
import * as rounds from '../services/roundService.js';

const AnswerBodySchema = z.object({
  answer: z.string().min(1).max(500),
  questionId: z.string().optional(),
});

export const roundsRoutes: FastifyPluginAsync = async (server) => {
  server.post('/rounds/start', async (request, reply) => {
    const userId = (request as any).userId as string;
    const parsed = RoundStartRequestSchema.safeParse(request.body ?? {});

    if (!parsed.success) {
      return reply.code(400).send({ error: 'Invalid round start payload', details: parsed.error.issues });
    }

    const round = await rounds.startRound(userId, parsed.data);
    return reply.send(round);
  });

  server.post<{ Params: { roundId: string } }>('/rounds/:roundId/answer', async (request, reply) => {
    const userId = (request as any).userId as string;
    const parsed = AnswerBodySchema.safeParse(request.body ?? {});

    if (!parsed.success) {
      return reply.code(400).send({ error: 'Invalid answer payload', details: parsed.error.issues });
    }

    try {
      const result = await rounds.answerRound(
        userId,
        request.params.roundId,
        parsed.data.answer,
        parsed.data.questionId,
      );
      return reply.send(result);
    } catch (error: any) {
      return reply.code(400).send({ error: error.message });
    }
  });

  server.post<{ Params: { roundId: string } }>('/rounds/:roundId/hint', async (request, reply) => {
    const userId = (request as any).userId as string;
    try {
      return reply.send(await rounds.requestRoundHint(userId, request.params.roundId));
    } catch (error: any) {
      return reply.code(400).send({ error: error.message });
    }
  });

  server.post<{ Params: { roundId: string } }>('/rounds/:roundId/repeat', async (request, reply) => {
    const userId = (request as any).userId as string;
    try {
      return reply.send(await rounds.requestRoundRepeat(userId, request.params.roundId));
    } catch (error: any) {
      return reply.code(400).send({ error: error.message });
    }
  });

  server.post<{ Params: { roundId: string } }>('/rounds/:roundId/finish', async (request, reply) => {
    const userId = (request as any).userId as string;
    try {
      return reply.send(await rounds.finishRound(userId, request.params.roundId));
    } catch (error: any) {
      return reply.code(400).send({ error: error.message });
    }
  });
};
