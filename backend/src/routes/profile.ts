import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as game from '../services/gameService.js';
import { ProfilePatchSchema } from '../models/types.js';

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
    const parsed = ProfilePatchSchema.safeParse(request.body ?? {});
    if (!parsed.success) {
      return reply.status(400).send({
        error: 'Invalid profile payload',
        details: parsed.error.issues,
      });
    }

    try {
      const user = await game.updateProfile(userId, parsed.data);
      if (!user) {
        return reply.status(404).send({ error: 'User not found' });
      }

      await game.audit(userId, 'update_profile', parsed.data as Record<string, unknown>);
      return { user };
    } catch (err: any) {
      return reply.status(400).send({
        error: err?.message ?? 'Failed to update profile',
      });
    }
  });
}
