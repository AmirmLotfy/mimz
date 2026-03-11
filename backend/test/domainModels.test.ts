import { describe, it, expect } from 'vitest';
import {
  UserSchema, DistrictSchema, SquadSchema, EventSchema,
  LiveSessionTokenRequestSchema, LiveToolExecutionRequestSchema,
  RewardGrantSchema, AuditLogSchema,
} from '../src/models/types.js';

describe('Domain Models', () => {
  describe('UserSchema', () => {
    it('validates a complete user', () => {
      const result = UserSchema.safeParse({
        id: 'user_001',
        displayName: 'TestPlayer',
        handle: '@test',
        xp: 500,
        streak: 3,
        bestStreak: 5,
        sectors: 2,
        createdAt: new Date().toISOString(),
      });
      expect(result.success).toBe(true);
    });

    it('applies defaults', () => {
      const result = UserSchema.parse({
        id: 'user_002',
        createdAt: new Date().toISOString(),
      });
      expect(result.displayName).toBe('Explorer');
      expect(result.xp).toBe(0);
      expect(result.visibility).toBe('coarse');
    });

    it('rejects too-long display names', () => {
      const result = UserSchema.safeParse({
        id: 'user_003',
        displayName: 'A'.repeat(31),
        createdAt: new Date().toISOString(),
      });
      expect(result.success).toBe(false);
    });
  });

  describe('LiveToolExecutionRequestSchema', () => {
    it('validates a valid request', () => {
      const result = LiveToolExecutionRequestSchema.safeParse({
        toolName: 'grade_answer',
        args: { answer: 'Paris' },
        sessionId: 'session_001',
      });
      expect(result.success).toBe(true);
    });

    it('rejects missing sessionId', () => {
      const result = LiveToolExecutionRequestSchema.safeParse({
        toolName: 'grade_answer',
        args: {},
      });
      expect(result.success).toBe(false);
    });

    it('rejects empty toolName', () => {
      const result = LiveToolExecutionRequestSchema.safeParse({
        toolName: '',
        sessionId: 'session_001',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('RewardGrantSchema', () => {
    it('validates and applies defaults', () => {
      const result = RewardGrantSchema.parse({
        id: 'rw_001',
        userId: 'user_001',
        type: 'xp',
        amount: 100,
        source: 'grade_answer',
        grantedAt: new Date().toISOString(),
      });
      expect(result.detail).toEqual({});
    });
  });
});
