import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as game from '../services/gameService.js';
import { ProfilePatchSchema, ACHIEVEMENT_CATALOG } from '../models/types.js';
import * as db from '../lib/db.js';

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

  // GET /profile/search — Search players by display name
  server.get('/search', async (request: FastifyRequest, reply: FastifyReply) => {
    const { q } = request.query as { q?: string };
    if (!q || q.trim().length < 2) {
      return { results: [] };
    }
    const results = await db.searchUsers(q.trim());
    return { results };
  });

  // GET /profile/badges — Get user's achievements
  server.get('/badges', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const badges = await db.getUserBadges(userId);
    return {
      badges,
      catalog: ACHIEVEMENT_CATALOG,
    };
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
