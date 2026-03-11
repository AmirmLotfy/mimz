import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';

export async function notificationsRoutes(server: FastifyInstance) {
  // GET /notifications — Get user's notifications
  server.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const notifications = await db.getUserNotifications(userId);
    return { notifications };
  });
}
