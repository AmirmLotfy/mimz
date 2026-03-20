import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import * as game from '../services/gameService.js';
import * as db from '../lib/db.js';
import { STRUCTURE_CATALOG } from '../models/types.js';

export async function districtRoutes(server: FastifyInstance) {
  const expandSchema = z.object({
    sectors: z.number().int().min(1).max(10),
  });
  const addResourcesSchema = z.object({
    stone: z.number().int().optional(),
    glass: z.number().int().optional(),
    wood: z.number().int().optional(),
  });
  const resolveConflictSchema = z.object({
    winnerId: z.string().optional(),
    cellsWon: z.number().int().min(0).max(10).default(1),
  });

  // GET /district — Get user's district
  server.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const district = await game.getDistrict(userId);

    if (!district) {
      return reply.status(404).send({ error: 'No district found. Call POST /auth/bootstrap first.' });
    }

    return {
      district,
      resourceRate: game.calculateResourceRate(district.structures),
      catalog: STRUCTURE_CATALOG,
    };
  });

  // POST /district/expand — Expand territory
  server.post('/expand', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const parsed = expandSchema.safeParse(request.body ?? {});
    if (!parsed.success) {
      return reply.status(400).send({
        error: 'Invalid expand payload',
        details: parsed.error.issues,
      });
    }
    try {
      const result = await game.expandTerritory(userId, parsed.data.sectors);
      await game.audit(userId, 'expand_territory_rest', parsed.data as unknown as Record<string, unknown>);
      return result;
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  // POST /district/resources — Add resources
  server.post('/resources', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const parsed = addResourcesSchema.safeParse(request.body ?? {});
    if (!parsed.success) {
      return reply.status(400).send({
        error: 'Invalid resources payload',
        details: parsed.error.issues,
      });
    }

    try {
      const district = await game.getDistrict(userId);
      if (!district) {
        return reply.status(404).send({ error: 'No district found' });
      }
      await db.addResources(district.id, parsed.data);
      await game.audit(userId, 'add_resources_rest', parsed.data as unknown as Record<string, unknown>);
      return { success: true };
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  // GET /district/public/:districtId — Public coarse district view
  server.get<{ Params: { districtId: string } }>('/public/:districtId', async (request, reply) => {
    const district = await db.getDistrict(request.params.districtId);
    if (!district) {
      return reply.status(404).send({ error: 'District not found' });
    }

    // Privacy-safe: only return coarse data
    return {
      name: district.name,
      sectors: district.sectors,
      structureCount: district.structures.length,
      prestigeLevel: district.prestigeLevel,
      visibility: district.visibility,
      // Never return: ownerId, cells, exact coordinates
    };
  });

  // POST /district/preview-growth — Preview what expansion would look like
  server.post('/preview-growth', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const body = request.body as any;
    const sectors = body?.sectors ?? 1;

    const district = await game.getDistrict(userId);
    if (!district) {
      return reply.status(404).send({ error: 'No district found' });
    }

    const newTotal = district.sectors + sectors;
    return {
      currentSectors: district.sectors,
      addedSectors: sectors,
      newTotal,
      newArea: `${(newTotal * 1.1).toFixed(1)} sq km`,
    };
  });

  // POST /district/sync-cells — Sync territory cell model for current user
  server.post('/sync-cells', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    try {
      const cells = await game.syncTerritoryCells(userId);
      await game.promoteStableFrontier(userId);
      return { success: true, cellCount: cells.length };
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  // POST /district/decay — Apply inactivity decay (call from cron/scheduler)
  server.post('/decay', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const user = await db.getUser(userId);
    if (!user) return reply.status(404).send({ error: 'User not found' });

    const lastActivity = (user as any).lastActivityDate;
    if (!lastActivity) return { cellsLost: 0, frontierWeakened: 0, message: 'No activity date' };

    const daysSince = Math.floor(
      (Date.now() - new Date(lastActivity).getTime()) / (1000 * 60 * 60 * 24)
    );

    const result = await game.applyInactivityDecay(userId, daysSince);

    if (result.cellsLost > 0 || result.frontierWeakened > 0) {
      db.createNotification({
        id: `notif_${Date.now()}`,
        userId,
        title: 'Your district influence is cooling',
        body: result.cellsLost > 0
          ? `${result.cellsLost} frontier cells were lost to inactivity. Play to reclaim them!`
          : `${result.frontierWeakened} frontier cells are weakening. Play to stabilize them!`,
        type: 'decay_warning',
        createdAt: new Date().toISOString(),
        read: false,
      }).catch(() => {});
    }

    return { ...result, daysSinceActivity: daysSince };
  });

  // GET /district/conflicts — Get active conflicts for current user
  server.get('/conflicts', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    try {
      const conflicts = await db.getActiveConflicts(userId);
      return { conflicts };
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  server.post('/reclaim-frontier', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    try {
      const result = await game.reclaimFrontier(userId);
      await game.audit(userId, 'reclaim_frontier_rest', {
        stabilizedCells: result.stabilizedCells,
        recoveredCells: result.recoveredCells,
      });
      return result;
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  server.get('/zones', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    try {
      const [district, events, conflicts] = await Promise.all([
        game.syncDistrictDerivedState(userId),
        db.listEvents().catch(() => []),
        db.getActiveConflicts(userId).catch(() => []),
      ]);

      if (!district) {
        return reply.status(404).send({ error: 'No district found' });
      }

      return {
        district: {
          id: district.id,
          name: district.name,
          regionAnchor: (district as any).regionAnchor,
          decayState: (district as any).decayState,
        },
        eventZones: events.map((event) => game.buildEventZone(event as any, district)),
        conflicts,
      };
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  server.post<{ Params: { conflictId: string } }>('/conflicts/:conflictId/resolve', async (request, reply) => {
    const userId = request.userId!;
    const parsed = resolveConflictSchema.safeParse(request.body ?? {});
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid resolve conflict payload', details: parsed.error.issues });
    }

    const conflict = await db.getConflict(request.params.conflictId);
    if (!conflict) {
      return reply.status(404).send({ error: 'Conflict not found' });
    }

    const winnerId = parsed.data.winnerId ?? userId;
    try {
      await game.resolveConflict(request.params.conflictId, winnerId, parsed.data.cellsWon);
      await game.audit(userId, 'resolve_conflict_rest', {
        conflictId: request.params.conflictId,
        winnerId,
        cellsWon: parsed.data.cellsWon,
      });
      return { success: true, conflictId: request.params.conflictId, winnerId, cellsWon: parsed.data.cellsWon };
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });

  // POST /district/unlock-structure — Unlock a structure
  server.post('/unlock-structure', async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.userId!;
    const body = request.body as any;

    if (!body?.structureId) {
      return reply.status(400).send({ error: 'structureId is required' });
    }

    try {
      const result = await game.unlockStructure(userId, body.structureId);
      await game.audit(userId, 'unlock_structure_rest', { structureId: body.structureId });
      return result;
    } catch (err: any) {
      return reply.status(400).send({ error: err.message });
    }
  });
}
