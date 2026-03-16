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
