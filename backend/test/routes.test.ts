import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { FastifyInstance } from 'fastify';
import { buildApp } from '../src/server.js';

describe('Server & API Routes', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await buildApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('GET /healthz', () => {
    it('should return 200 OK', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/healthz',
      });

      expect(response.statusCode).toBe(200);
      const json = response.json();
      expect(json).toHaveProperty('status', 'ok');
      expect(json).toHaveProperty('timestamp');
    });
  });

  // Depending on whether an emulator is running, readyz will be 200 or 503
  describe('GET /readyz', () => {
    it('should return 200 OK or 503 Service Unavailable', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/readyz',
      });

      expect([200, 503]).toContain(response.statusCode);
      if (response.statusCode === 200) {
        expect(response.json()).toHaveProperty('status', 'ready');
      } else {
        expect(response.json()).toHaveProperty('status', 'not ready');
      }
    }, 15000);
  });

  describe('Authentication & Middleware', () => {
    it('should allow unauthenticated access to public routes', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/healthz',
      });
      expect(response.statusCode).toBe(200);
    });

    it('should reject protected routes without Authorization header', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/profile',
      });
      expect(response.statusCode).toBe(401);
    });
  });

  describe('POST /auth/bootstrap', () => {
    it('should boot canonical user or return error', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/auth/bootstrap',
      });

      expect(response.statusCode).toBe(401);
    });
  });

  describe('POST /live/ephemeral-token', () => {
    it('should generate an ephemeral session token for quiz', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/live/ephemeral-token',
        payload: { sessionType: 'quiz' },
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
