import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import * as db from '../lib/db.js';
import * as game from '../services/gameService.js';

function weeklyScope(now = new Date()): string {
  const startOfYear = new Date(now.getFullYear(), 0, 1);
  const weekNum = Math.ceil(((now.getTime() - startOfYear.getTime()) / 86400000 + startOfYear.getDay() + 1) / 7);
  return `weekly_${now.getFullYear()}_${weekNum}`;
}

function resolveScopeKey(
  scope: string | undefined,
  topic?: string,
  region?: string,
  squadId?: string,
  eventId?: string,
): string {
  switch (scope) {
    case 'weekly':
      return weeklyScope();
    case 'region':
      return `region_${region ?? 'global_central'}`;
    case 'topic':
      return `topic_${game.slugifyTopic(topic ?? 'general')}`;
    case 'squad':
      return `squad_${squadId ?? 'default'}`;
    case 'event':
      return `event_${eventId ?? 'default'}`;
    case 'global':
    default:
      return 'global';
  }
}

export async function leaderboardRoutes(server: FastifyInstance) {
  // GET /leaderboard — Get global leaderboard
  server.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const query = (request.query ?? {}) as Record<string, string | undefined>;
    const scope = query.scope ?? 'global';
    const squadId = scope === 'squad' ? await db.getSquadIdForUser(request.userId!) : undefined;
    const key = resolveScopeKey(scope, query.topic, query.region, squadId ?? undefined, query.event);
    const entries = await db.getLeaderboard(key);
    return { scope, key, entries };
  });

  // GET /leaderboard/:scope — Get scoped leaderboard
  server.get<{ Params: { scope: string } }>('/:scope', async (request, reply) => {
    const query = (request.query ?? {}) as Record<string, string | undefined>;
    const scope = request.params.scope;
    const squadId = scope === 'squad' ? await db.getSquadIdForUser(request.userId!) : undefined;
    const key = resolveScopeKey(scope, query.topic, query.region, squadId ?? undefined, query.event);
    const entries = await db.getLeaderboard(key);
    return { scope, key, entries };
  });
}
