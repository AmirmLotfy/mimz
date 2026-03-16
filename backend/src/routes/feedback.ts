import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';
import { FeedbackSubmissionSchema } from '../models/types.js';

export async function feedbackRoutes(server: FastifyInstance) {
  server.post('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const parsed = FeedbackSubmissionSchema.safeParse(request.body ?? {});

    if (!parsed.success) {
      return reply.status(400).send({
        error: 'Invalid feedback payload',
        details: parsed.error.issues,
      });
    }

    const id = await db.createFeedback(userId, parsed.data);
    return { success: true, id };
  });
}
