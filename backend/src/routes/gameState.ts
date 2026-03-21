import type { FastifyPluginAsync } from 'fastify';
import { getCanonicalGameState } from '../services/gameStateService.js';
import * as game from '../services/gameService.js';

export const gameStateRoutes: FastifyPluginAsync = async (server) => {
  server.get('/game-state', async (request, reply) => {
    const userId = (request as any).userId as string;
    let state = await getCanonicalGameState(userId);

    if (!state) {
      await game.bootstrapUser(
        userId,
        (request as any).userEmail as string | undefined,
      );
      state = await getCanonicalGameState(userId);
    }

    if (!state) {
      return reply.code(404).send({ error: 'Game state not found' });
    }

    return reply.send(state);
  });
};
