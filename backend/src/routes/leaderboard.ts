import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';

export async function leaderboardRoutes(server: FastifyInstance) {
  // GET /leaderboard — Get global leaderboard
  server.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const entries = await db.getLeaderboard('global');
    return { scope: 'global', entries };
  });

  // GET /leaderboard/:scope — Get scoped leaderboard
  server.get<{ Params: { scope: string } }>('/:scope', async (request, reply) => {
    const entries = await db.getLeaderboard(request.params.scope);
    return { scope: request.params.scope, entries };
  });
}
