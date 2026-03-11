import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as game from '../services/gameService.js';

export async function authRoutes(server: FastifyInstance) {
  // POST /auth/bootstrap — Create or retrieve user profile + district
  server.post('/bootstrap', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const email = request.userEmail;

    const user = await game.bootstrapUser(userId, email);
    const district = await game.getDistrict(userId);

    server.log.info({ userId }, 'User bootstrapped');
    return { user, district };
  });
}
