import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';
import { randomUUID } from 'crypto';

export async function squadsRoutes(server: FastifyInstance) {
  // POST /squad — Create a new squad
  server.post('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const body = request.body as any;

    if (!body?.name) {
      return reply.status(400).send({ error: 'Squad name is required' });
    }

    const joinCode = Math.random().toString(36).substring(2, 8).toUpperCase();
    const squad = await db.createSquad({
      id: `squad_${randomUUID().substring(0, 8)}`,
      name: body.name,
      joinCode,
      leaderId: userId,
      memberCount: 1,
      totalXp: 0,
      createdAt: new Date().toISOString(),
    });

    await db.addSquadMember(squad.id, {
      userId,
      displayName: body.displayName || 'Leader',
      rank: 1,
      xpContributed: 0,
      joinedAt: new Date().toISOString(),
    });

    return { squad };
  });

  // POST /squad/join — Join by code
  server.post('/join', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const body = request.body as any;

    if (!body?.joinCode) {
      return reply.status(400).send({ error: 'joinCode is required' });
    }

    const squad = await db.getSquadByCode(body.joinCode.toUpperCase());
    if (!squad) {
      return reply.status(404).send({ error: 'Squad not found' });
    }

    await db.addSquadMember(squad.id, {
      userId,
      displayName: body.displayName || 'Member',
      rank: squad.memberCount + 1,
      xpContributed: 0,
      joinedAt: new Date().toISOString(),
    });

    return { squad };
  });

  // GET /squad/:squadId — Get squad details
  server.get<{ Params: { squadId: string } }>('/:squadId', async (request, reply) => {
    const squad = await db.getSquad(request.params.squadId);
    if (!squad) {
      return reply.status(404).send({ error: 'Squad not found' });
    }
    return { squad };
  });

  // POST /squad/:squadId/contribute — Contribute to squad mission
  server.post<{ Params: { squadId: string } }>('/:squadId/contribute', async (request, reply) => {
    const userId = request.userId!;
    const body = request.body as any;
    const amount = body?.amount ?? 10;
    const missionId = body?.missionId;

    if (!missionId) {
      return reply.status(400).send({ error: 'missionId is required' });
    }

    await db.updateSquadMissionProgress(request.params.squadId, missionId, amount);
    return { success: true, contributed: amount, missionId };
  });
}
