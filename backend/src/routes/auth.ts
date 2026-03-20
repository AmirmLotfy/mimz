import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as game from '../services/gameService.js';
import { getDb } from '../lib/firebase.js';

export async function authRoutes(server: FastifyInstance) {
  // POST /auth/bootstrap — Create or retrieve user profile + district
  server.post('/bootstrap', async (request: FastifyRequest, reply: FastifyReply) => {
    const traceId = (request.headers['x-correlation-id'] as string | undefined)?.trim() || request.id;
    reply.header('x-correlation-id', traceId);
    const userId = request.userId;
    const email = request.userEmail;

    if (!userId) {
      return reply.status(401).send({
        error: 'Authentication required',
        code: 'AUTH_REQUIRED',
        traceId,
        retryable: false,
      });
    }

    // Be tolerant of optional/empty body; bootstrap currently uses auth context only.
    const body = request.body ?? {};
    if (body === null || typeof body !== 'object' || Array.isArray(body)) {
      return reply.status(400).send({
        error: 'Invalid bootstrap payload',
        code: 'BOOTSTRAP_BAD_PAYLOAD',
        traceId,
        retryable: false,
      });
    }

    try {
      const user = await game.bootstrapUser(userId, email);
      const district = await game.getDistrict(userId);
      server.log.info({ userId, traceId }, 'User bootstrapped');
      return { user, district, traceId };
    } catch (err) {
      server.log.error({ err, userId, traceId }, 'Bootstrap failed');
      return reply.status(500).send({
        error: 'Failed to bootstrap user profile',
        code: 'BOOTSTRAP_FAILED',
        traceId,
        retryable: true,
      });
    }
  });

  server.post('/register-device', async (request, reply) => {
    const userId = request.userId!;
    const { fcmToken, platform } = request.body as { fcmToken: string; platform: string };
    if (!fcmToken) return reply.status(400).send({ error: 'Missing fcmToken' });

    await getDb().collection('deviceTokens').doc(fcmToken).set({
      userId,
      fcmToken,
      platform: platform || 'android',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });

    return { registered: true };
  });

  server.delete('/register-device', async (request, reply) => {
    const { fcmToken } = request.body as { fcmToken: string };
    if (fcmToken) {
      await getDb().collection('deviceTokens').doc(fcmToken).delete();
    }
    return { unregistered: true };
  });
}
