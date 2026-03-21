import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';
import { ClientTelemetryEventSchema } from '../models/types.js';

export async function telemetryRoutes(server: FastifyInstance) {
  server.post('/client', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const parsed = ClientTelemetryEventSchema.safeParse(request.body ?? {});

    if (!parsed.success) {
      return reply.status(400).send({
        error: 'Invalid telemetry payload',
        details: parsed.error.issues,
      });
    }

    const id = await db.createClientTelemetryEvent(userId, parsed.data);
    request.log.info(
      {
        telemetryId: id,
        userId,
        event: parsed.data.event,
        route: parsed.data.route,
        correlationId: parsed.data.correlationId,
      },
      'client telemetry received',
    );

    return { success: true, id };
  });
}
