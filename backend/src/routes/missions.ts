import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';
import * as game from '../services/gameService.js';

export async function missionsRoutes(server: FastifyInstance) {
  server.get('/current', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;

    const [user, district, squadId] = await Promise.all([
      db.getUser(userId),
      game.getDistrict(userId),
      db.getSquadIdForUser(userId),
    ]);

    if (!user) {
      return reply.status(404).send({ error: 'User not found' });
    }

    const sectors = district?.sectors ?? user.sectors ?? 0;
    const structures = district?.structures ?? [];
    const dailyStreak = (user as any).dailyStreak ?? 0;

    if (sectors < 3) {
      return { mission: 'Win your first quiz round', type: 'quiz', xpReward: 500 };
    }
    if (sectors < 10 && structures.length === 0) {
      return { mission: 'Unlock your first structure via Vision Quest', type: 'vision', xpReward: 750 };
    }
    if (dailyStreak === 0) {
      return { mission: 'Start a daily streak — play today!', type: 'streak', xpReward: 300 };
    }
    if (!squadId) {
      return { mission: 'Join or create a squad', type: 'social', xpReward: 200 };
    }
    return { mission: `Expand to ${sectors + 5} sectors`, type: 'growth', xpReward: 1000 };
  });
}
