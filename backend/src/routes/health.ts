import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';

export async function healthRoutes(server: FastifyInstance) {
  // GET /healthz — Liveness probe
  server.get('/healthz', async (request: FastifyRequest, reply: FastifyReply) => {
    return { status: 'ok', timestamp: new Date().toISOString() };
  });

  // GET /readyz — Readiness probe (checks dependencies)
  server.get('/readyz', async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      // Could check Firestore connectivity here
      return { status: 'ready', timestamp: new Date().toISOString() };
    } catch (err) {
      return reply.status(503).send({ status: 'not ready', error: 'Dependencies unavailable' });
    }
  });
}
