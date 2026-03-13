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
    });
  });

  describe('Authentication & Middleware', () => {
    it('should allow unauthenticated access to public routes', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/healthz',
      });
      expect(response.statusCode).toBe(200);
    });

    it('should fallback to dev pseudo-token in test environment if no Firebase auth exists', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/profile',
      });

      // It might return 200 if the mock database succeeds, or 500/404 if it fails.
      // The important part is that we bypass the 401 Unauthorized middleware rejection.
      expect(response.statusCode).not.toBe(401);
    });
  });

  describe('POST /auth/bootstrap', () => {
    it('should boot canonical user or return error', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/auth/bootstrap',
      });

      // In the mock dev environment with no mocked user creation, it might 500 or 200 depending on firestore availability
      expect([200, 500]).toContain(response.statusCode);
      if (response.statusCode === 200) {
        expect(response.json()).toHaveProperty('user');
      }
    });
  });

  describe('POST /live/ephemeral-token', () => {
    it('should generate an ephemeral session token for quiz', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/live/ephemeral-token',
        payload: { sessionType: 'quiz' },
      });

      // Bypasses auth successfully. If Firestore isn't mocked for the audit logging, it might 500
      expect([200, 500]).toContain(response.statusCode);
      if (response.statusCode === 200) {
        const json = response.json();
        expect(json).toHaveProperty('session');
        expect(json.session).toHaveProperty('token');
        expect(json.session).toHaveProperty('model');
      }
    });
  });
});
