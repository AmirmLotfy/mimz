import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';

export async function rewardsRoutes(server: FastifyInstance) {
  // GET /rewards — Get user's recent reward history
  server.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // Last 7 days
    const rewards = await db.getRewardsSince(userId, since);

    const totalXp = rewards.filter(r => r.type === 'xp').reduce((sum, r) => sum + r.amount, 0);
    const totalTerritory = rewards.filter(r => r.type === 'territory').reduce((sum, r) => sum + r.amount, 0);

    return {
      rewards,
      summary: {
        period: '7d',
        totalXp,
        totalTerritory,
        totalRewards: rewards.length,
      },
    };
  });
}
