import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';

export async function rewardsRoutes(server: FastifyInstance) {
  // GET /rewards — Get user's recent reward history
  server.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const query = request.query as { limit?: string; all?: string };
    const limit = Math.min(parseInt(query.limit ?? '20', 10), 100);
    const useHistory = query.all === 'true';

    const rewards = useHistory
      ? await db.getUserRewards(userId, limit)
      : await db.getRewardsSince(userId, new Date(Date.now() - 7 * 24 * 60 * 60 * 1000));

    const totalXp = rewards.filter(r => r.type === 'xp').reduce((sum, r) => sum + r.amount, 0);
    const totalTerritory = rewards.filter(r => r.type === 'territory').reduce((sum, r) => sum + r.amount, 0);

    return {
      rewards,
      summary: {
        period: useHistory ? 'all' : '7d',
        totalXp,
        totalTerritory,
        totalRewards: rewards.length,
      },
    };
  });
}
