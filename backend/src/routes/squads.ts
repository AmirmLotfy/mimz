import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';
import { randomUUID } from 'crypto';
import { z } from 'zod';

const CreateSquadSchema = z.object({
  name: z.string().min(1, 'Squad name is required').max(30, 'Squad name too long'),
  displayName: z.string().optional(),
});

const JoinSquadSchema = z.object({
  joinCode: z.string().min(1, 'joinCode is required'),
  displayName: z.string().optional(),
});

const ContributeSquadSchema = z.object({
  amount: z.number().int().min(1).default(10),
  missionId: z.string().min(1, 'missionId is required'),
});

const CreateMissionSchema = z.object({
  title: z.string().min(1, 'title is required').max(80),
  description: z.string().max(300).optional(),
  goalProgress: z.number().int().min(1).default(100),
  deadline: z.string().optional(),
});

export async function squadsRoutes(server: FastifyInstance) {
  // POST /squad — Create a new squad
  server.post('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;

    const parsed = CreateSquadSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.issues[0].message });
    }
    const body = parsed.data;

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
    await db.updateUser(userId, { squadId: squad.id } as any);

    // Notify creator
    await db.createNotification({
      id: `notif_${randomUUID()}`,
      userId,
      title: 'Squad created!',
      body: `Welcome to ${body.name}! Share your join code: ${joinCode}`,
      type: 'squad_created',
      createdAt: new Date().toISOString(),
      read: false,
      data: { squadId: squad.id, joinCode },
    });

    return { squad };
  });

  // POST /squad/join — Join by code
  server.post('/join', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;

    const parsed = JoinSquadSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.issues[0].message });
    }
    const body = parsed.data;

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
    await db.updateUser(userId, { squadId: squad.id } as any);

    // Notify the new member
    await db.createNotification({
      id: `notif_${randomUUID()}`,
      userId,
      title: `Welcome to ${squad.name}!`,
      body: 'You joined a new squad. Play together to earn bonus rewards.',
      type: 'squad_joined',
      createdAt: new Date().toISOString(),
      read: false,
      data: { squadId: squad.id },
    });

    return { squad };
  });

  // GET /squad/me — Get the calling user's squad with members and missions
  server.get('/me', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const squadId = await db.getSquadIdForUser(userId);
    if (!squadId) {
      return reply.status(404).send({ error: 'No squad' });
    }
    const [squad, members, missions] = await Promise.all([
      db.getSquad(squadId),
      db.getSquadMembers(squadId),
      db.getSquadMissions(squadId),
    ]);
    if (!squad) {
      return reply.status(404).send({ error: 'Squad not found' });
    }
    return { squad: { ...squad, members, missions } };
  });

  // GET /squad/:squadId — Get squad details
  server.get<{ Params: { squadId: string } }>('/:squadId', async (request, reply) => {
    const squad = await db.getSquad(request.params.squadId);
    if (!squad) {
      return reply.status(404).send({ error: 'Squad not found' });
    }
    return { squad };
  });

  // GET /squad/:squadId/members — List squad members
  server.get<{ Params: { squadId: string } }>('/:squadId/members', async (request, reply) => {
    const squad = await db.getSquad(request.params.squadId);
    if (!squad) {
      return reply.status(404).send({ error: 'Squad not found' });
    }
    const members = await db.getSquadMembers(request.params.squadId);
    return { members };
  });

  // GET /squad/:squadId/missions — List squad missions
  server.get<{ Params: { squadId: string } }>('/:squadId/missions', async (request, reply) => {
    const squad = await db.getSquad(request.params.squadId);
    if (!squad) {
      return reply.status(404).send({ error: 'Squad not found' });
    }
    const missions = await db.getSquadMissions(request.params.squadId);
    return { missions };
  });

  // POST /squad/:squadId/missions — Create a squad mission
  server.post<{ Params: { squadId: string } }>('/:squadId/missions', async (request, reply) => {
    const userId = request.userId!;

    const parsed = CreateMissionSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.issues[0].message });
    }
    const body = parsed.data;

    const squad = await db.getSquad(request.params.squadId);
    if (!squad) {
      return reply.status(404).send({ error: 'Squad not found' });
    }
    // Only squad leader can create missions
    if (squad.leaderId !== userId) {
      return reply.status(403).send({ error: 'Only the squad leader can create missions' });
    }

    const missionId = `mission_${randomUUID().substring(0, 8)}`;
    const mission = {
      id: missionId,
      title: body.title,
      description: body.description,
      goalProgress: body.goalProgress,
      currentProgress: 0,
      createdAt: new Date().toISOString(),
      deadline: body.deadline,
    };
    await db.createSquadMission(request.params.squadId, mission);
    return { mission };
  });

  // POST /squad/:squadId/contribute — Contribute to squad mission
  server.post<{ Params: { squadId: string } }>('/:squadId/contribute', async (request, reply) => {
    const parsed = ContributeSquadSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: parsed.error.issues[0].message });
    }
    const { amount, missionId } = parsed.data;

    try {
      await db.updateSquadMissionProgress(request.params.squadId, missionId, amount);
    } catch (err) {
      return reply.status(404).send({ error: 'Mission not found' });
    }
    return { success: true, contributed: amount, missionId };
  });
}
