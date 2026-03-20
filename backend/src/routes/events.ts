import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';
import * as game from '../services/gameService.js';

import { z } from 'zod';

const ScoreEventSchema = z.object({
  score: z.number().int().default(0),
});

export async function eventsRoutes(server: FastifyInstance) {
  // GET /events — List active/upcoming events
  server.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const events = await db.listEvents();
    return { events };
  });

  server.get('/zones', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const [events, district] = await Promise.all([
      db.listEvents(),
      game.getDistrict(userId),
    ]);
    return {
      zones: events.map((event) => game.buildEventZone(event, district)),
    };
  });

  // GET /events/:eventId — Get event detail
  server.get<{ Params: { eventId: string } }>('/:eventId', async (request, reply) => {
    const event = await db.getEvent(request.params.eventId);
    if (!event) {
      return reply.status(404).send({ error: 'Event not found' });
    }
    return { event };
  });

  // POST /events/:eventId/join — Join an event
  server.post<{ Params: { eventId: string } }>('/:eventId/join', async (request, reply) => {
    const userId = request.userId!;
    const event = await db.getEvent(request.params.eventId);

    if (!event) {
      return reply.status(404).send({ error: 'Event not found' });
    }
    if (event.status === 'completed') {
      return reply.status(400).send({ error: 'Event has ended' });
    }

    await db.joinEvent(request.params.eventId, userId);
    return { success: true, eventId: request.params.eventId };
  });

  server.post<{ Params: { eventId: string } }>('/:eventId/participate', async (request, reply) => {
    const userId = request.userId!;
    const event = await db.getEvent(request.params.eventId);

    if (!event) {
      return reply.status(404).send({ error: 'Event not found' });
    }
    if (event.status === 'completed') {
      return reply.status(400).send({ error: 'Event has ended' });
    }

    const [joined, district] = await Promise.all([
      db.joinEvent(request.params.eventId, userId),
      game.getDistrict(userId),
    ]);

    return {
      success: true,
      joined,
      eventId: request.params.eventId,
      zone: game.buildEventZone(event, district),
    };
  });

  // POST /events/:eventId/score — Submit contribution score
  server.post<{ Params: { eventId: string } }>('/:eventId/score', async (request, reply) => {
    const userId = request.userId!;
    
    const parsed = ScoreEventSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.issues[0].message });
    }
    const { score } = parsed.data;

    await db.addEventScore(request.params.eventId, userId, score);
    return { success: true, scored: score };
  });
}
