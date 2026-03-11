import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as game from '../services/gameService.js';

export async function profileRoutes(server: FastifyInstance) {
  // GET /profile — Get current user profile
  server.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const user = await game.getUser(userId);

    if (!user) {
      return reply.status(404).send({ error: 'User not found. Call POST /auth/bootstrap first.' });
    }

    return { user };
  });

  // PATCH /profile — Update profile fields
  server.patch('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const body = request.body as Record<string, unknown>;

    const user = await game.updateProfile(userId, body as any);
    if (!user) {
      return reply.status(404).send({ error: 'User not found' });
    }

    await game.audit(userId, 'update_profile', body);
    return { user };
  });
}
