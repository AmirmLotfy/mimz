import type { FastifyPluginAsync } from 'fastify';
import { getCanonicalGameState } from '../services/gameStateService.js';

export const gameStateRoutes: FastifyPluginAsync = async (server) => {
  server.get('/game-state', async (request, reply) => {
    const userId = (request as any).userId as string;
    const state = await getCanonicalGameState(userId);

    if (!state) {
      return reply.code(404).send({ error: 'Game state not found' });
    }

    return reply.send(state);
  });
};
