import Fastify from 'fastify';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import { config } from './config/index.js';
import { initFirebase } from './lib/firebase.js';
import { authMiddleware } from './middleware/auth.js';
import { healthRoutes } from './routes/health.js';
import { authRoutes } from './routes/auth.js';
import { liveRoutes } from './routes/live.js';
import { validateVertexLiveConfig } from './modules/live/liveService.js';
import { profileRoutes } from './routes/profile.js';
import { districtRoutes } from './routes/district.js';
import { squadsRoutes } from './routes/squads.js';
import { eventsRoutes } from './routes/events.js';
import { leaderboardRoutes } from './routes/leaderboard.js';
import { rewardsRoutes } from './routes/rewards.js';
import { notificationsRoutes } from './routes/notifications.js';
import { interestsRoutes } from './routes/interests.js';
import { questionsRoutes } from './routes/questions.js';
import { feedbackRoutes } from './routes/feedback.js';
import { missionsRoutes } from './routes/missions.js';
import { gameStateRoutes } from './routes/gameState.js';
import { roundsRoutes } from './routes/rounds.js';
import { visionQuestRoutes } from './routes/visionQuests.js';
import { telemetryRoutes } from './routes/telemetry.js';

// ─── Initialize Firebase ──────────────────────────
initFirebase();

// ─── Log active AI model configuration ────────────
import { logActiveModels } from './config/models.js';
logActiveModels();

// ─── Create Server Builder ────────────────────────
export async function buildApp() {
  const server = Fastify({
    logger: {
      level: config.logLevel,
      transport:
        config.nodeEnv === 'development'
          ? { target: 'pino-pretty', options: { colorize: true } }
          : undefined,
      // Cloud Logging-friendly JSON in production
      ...(config.nodeEnv === 'production' && {
        formatters: {
          level: (label: string) => ({ severity: label.toUpperCase() }),
        },
      }),
    },
    requestTimeout: 30000,
    bodyLimit: 1048576, // 1MB
  });

  // ─── Plugins ──────────────────────────────────────
  await server.register(cors, {
    origin: true,
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  });

  await server.register(rateLimit, {
    max: config.rateLimitMax,
    timeWindow: config.rateLimitWindow,
  });

  // ─── Middleware ───────────────────────────────────
  await server.register(authMiddleware);

  // ─── Request logging ─────────────────────────────
  server.addHook('onResponse', (request, reply, done) => {
    const traceId = (request.headers['x-correlation-id'] as string | undefined)?.trim() || request.id;
    request.log.info({
      method: request.method,
      url: request.url,
      statusCode: reply.statusCode,
      responseTime: reply.elapsedTime,
      userId: request.userId,
      traceId,
    }, 'request completed');
    done();
  });

  // ─── Error handler ───────────────────────────────
  server.setErrorHandler((error, request, reply) => {
    request.log.error({
      err: error,
      method: request.method,
      url: request.url,
      userId: request.userId,
    }, 'Request error');

    // Never leak internal error details in production
    const err = error as any;
    const statusCode = err.statusCode ?? 500;
    reply.status(statusCode).send({
      error: statusCode >= 500 ? 'Internal server error' : err.message,
      statusCode,
    });
  });

  // ─── Routes ──────────────────────────────────────
  await server.register(healthRoutes, { prefix: '' });
  await server.register(authRoutes, { prefix: '/auth' });
  await server.register(liveRoutes, { prefix: '/live' });
  await server.register(profileRoutes, { prefix: '/profile' });
  await server.register(districtRoutes, { prefix: '/district' });
  await server.register(squadsRoutes, { prefix: '/squad' });
  await server.register(eventsRoutes, { prefix: '/events' });
  await server.register(leaderboardRoutes, { prefix: '/leaderboard' });
  await server.register(rewardsRoutes, { prefix: '/rewards' });
  await server.register(notificationsRoutes, { prefix: '/notifications' });
  await server.register(feedbackRoutes, { prefix: '/feedback' });
  await server.register(interestsRoutes, { prefix: '/interests' });
  await server.register(questionsRoutes, { prefix: '' });
  await server.register(missionsRoutes, { prefix: '/missions' });
  await server.register(gameStateRoutes, { prefix: '' });
  await server.register(roundsRoutes, { prefix: '' });
  await server.register(visionQuestRoutes, { prefix: '/vision-quests' });
  await server.register(telemetryRoutes, { prefix: '/telemetry' });
  await server.register(leaderboardRoutes, { prefix: '/leaderboards' });

  return server;
}

// ─── Start ─────────────────────────────────────────
async function start() {
  const server = await buildApp();
  if (config.nodeEnv === 'production') {
    try {
      await validateVertexLiveConfig();
      server.log.info('Vertex Live API config validated');
    } catch (err) {
      server.log.error({ err }, 'Vertex Live API config invalid; live sessions will fail');
      process.exit(1);
    }
  }
  try {
    await server.listen({ port: config.port, host: '0.0.0.0' });
    server.log.info(`🚀 Mimz backend v1.0.0 listening on port ${config.port} [${config.nodeEnv}]`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
}

if (process.env.NODE_ENV !== 'test') {
  start();
}
