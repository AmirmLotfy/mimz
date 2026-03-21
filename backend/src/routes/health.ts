import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { getDb } from '../lib/firebase.js';

export async function healthRoutes(server: FastifyInstance) {
  // GET /health — Liveness probe (using cleaner path)
  server.get('/health', async (request: FastifyRequest, reply: FastifyReply) => {
    return { status: 'ok', timestamp: new Date().toISOString() };
  });

  // GET /healthz — Legacy probe
  server.get('/healthz', async (request: FastifyRequest, reply: FastifyReply) => {
    return { status: 'ok', timestamp: new Date().toISOString() };
  });

  // GET /readyz — Readiness probe (checks Firestore connectivity without composite index)
  server.get('/readyz', async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      await Promise.race([
        getDb().collection('_health').limit(1).get(),
        new Promise((_, reject) =>
          setTimeout(() => reject(new Error('Firestore readiness timeout')), 1200),
        ),
      ]);
      return { status: 'ready', timestamp: new Date().toISOString() };
    } catch (err) {
      return reply.status(503).send({ status: 'not ready', error: 'Firestore unavailable' });
    }
  });
}
