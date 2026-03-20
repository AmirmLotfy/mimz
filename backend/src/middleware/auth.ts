import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import fp from 'fastify-plugin';
import { getFirebaseAuth } from '../lib/firebase.js';
import { config } from '../config/index.js';

declare module 'fastify' {
  interface FastifyRequest {
    userId?: string;
    userEmail?: string;
  }
}

/** Routes that skip authentication. */
const PUBLIC_ROUTES = ['/health', '/healthz', '/readyz'];

/**
 * Firebase Auth middleware — verifies ID token from Authorization header.
 *
 * In development without Firebase configured, falls back to demo user.
 * In production, rejects unauthenticated requests.
 */
export const authMiddleware = fp(async (server: FastifyInstance) => {
  server.decorateRequest('userId', undefined);
  server.decorateRequest('userEmail', undefined);

  server.addHook('onRequest', async (request: FastifyRequest, reply: FastifyReply) => {
    const traceId = (request.headers['x-correlation-id'] as string | undefined)?.trim() || request.id;
    reply.header('x-correlation-id', traceId);
    // Skip auth for public routes
    if (PUBLIC_ROUTES.some(r => request.url.startsWith(r))) return;

    const authHeader = request.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      if (config.allowDevAuthBypass) {
        request.userId = 'demo_user_001';
        request.userEmail = 'demo@mimz.app';
        return;
      }
      return reply.status(401).send({
        error: 'Missing authorization header',
        code: 'AUTH_HEADER_MISSING',
        traceId,
        retryable: false,
      });
    }

    const token = authHeader.replace('Bearer ', '');

    try {
      const auth = getFirebaseAuth();
      const decoded = await auth.verifyIdToken(token);
      request.userId = decoded.uid;
      request.userEmail = decoded.email;
    } catch (err) {
      if (config.allowDevAuthBypass) {
        request.userId = `user_${token.substring(0, 8)}`;
        request.userEmail = 'dev@mimz.app';
        return;
      }

      request.log.warn({ err, traceId }, 'Token verification failed');
      return reply.status(401).send({
        error: 'Invalid authentication token',
        code: 'AUTH_TOKEN_INVALID',
        traceId,
        retryable: false,
      });
    }
  });
});
