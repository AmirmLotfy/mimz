import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';

export async function healthRoutes(server: FastifyInstance) {
  // GET /healthz — Liveness probe
  server.get('/healthz', async (request: FastifyRequest, reply: FastifyReply) => {
    return { status: 'ok', timestamp: new Date().toISOString() };
  });

  // GET /readyz — Readiness probe (checks Firestore connectivity)
  server.get('/readyz', async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      // Lightweight read to verify Firestore is accessible
      await db.getLeaderboard('__health_check__');
      return { status: 'ready', timestamp: new Date().toISOString() };
    } catch (err) {
      return reply.status(503).send({ status: 'not ready', error: 'Firestore unavailable' });
    }
  });
}
