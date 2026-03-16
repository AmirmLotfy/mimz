import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';

export async function notificationsRoutes(server: FastifyInstance) {
  // GET /notifications — Get user's notifications
  server.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const notifications = await db.getUserNotifications(userId);
    return { notifications };
  });

  // PATCH /notifications/:id/read — Mark a notification read
  server.patch<{ Params: { id: string } }>('/:id/read', async (request, reply) => {
    const userId = request.userId!;
    const id = request.params.id;
    await db.markNotificationRead(userId, id);
    return { success: true };
  });

  // PATCH /notifications/read-all — Mark all notifications read
  server.patch('/read-all', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    await db.markAllNotificationsRead(userId);
    return { success: true };
  });
}
