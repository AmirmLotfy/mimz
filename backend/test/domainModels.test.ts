import { describe, it, expect } from 'vitest';
import {
  UserSchema, DistrictSchema, SquadSchema, EventSchema,
  LiveSessionTokenRequestSchema, LiveToolExecutionRequestSchema,
  RewardGrantSchema, AuditLogSchema,
  AnswerResultSchema, GameStateSchema, RoundDefinitionSchema,
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

  describe('RoundDefinitionSchema', () => {
    it('validates a backend-authored round definition', () => {
      const result = RoundDefinitionSchema.safeParse({
        roundId: 'round_001',
        mode: 'quiz',
        topic: 'Technology & Engineering',
        difficulty: 'medium',
        questionCount: 5,
        currentQuestionIndex: 0,
        currentQuestion: {
          id: 'q_tech_001',
          topic: 'Technology & Engineering',
          difficulty: 'medium',
          type: 'short_answer',
          text: 'What does GPU stand for?',
          spokenPhrase: 'What does G P U stand for?',
          source: 'deterministic',
          interests: ['Technology & Engineering'],
          tags: ['ai'],
        },
      });
      expect(result.success).toBe(true);
    });
  });

  describe('GameStateSchema', () => {
    it('validates the canonical game-state payload', () => {
      const now = new Date().toISOString();
      const result = GameStateSchema.safeParse({
        user: {
          id: 'user_001',
          displayName: 'Explorer',
          handle: '@explorer',
          createdAt: now,
        },
        district: {
          id: 'district_001',
          ownerId: 'user_001',
          name: 'My District',
          createdAt: now,
        },
        currentMission: 'Win your first quiz round',
        eventZones: [],
        streakState: {
          liveStreak: 0,
          dailyStreak: 0,
          bestStreak: 0,
        },
        structureEffects: {},
        structureProgress: {
          unlockedCount: 0,
          totalAvailable: 5,
          readyToBuild: false,
        },
        notifications: [],
        leaderboardSnippets: [],
        activeConflicts: [],
      });
      expect(result.success).toBe(true);
    });
  });

  describe('AnswerResultSchema', () => {
    it('validates a round answer result with district rewards', () => {
      const result = AnswerResultSchema.safeParse({
        roundId: 'round_001',
        questionId: 'q_tech_001',
        topic: 'Technology & Engineering',
        isCorrect: true,
        confidenceScore: 1,
        matchType: 'exact',
        normalizedAnswer: 'graphics processing unit',
        correctAnswer: 'graphics processing unit',
        pointsAwarded: 100,
        streakBonus: 0,
        newStreak: 1,
        xpAwarded: 100,
        influenceGranted: 75,
        sectorsGained: 1,
        materialsEarned: { stone: 4, glass: 2, wood: 3 },
        comboXp: 0,
        territoryExpanded: true,
        questionCount: 5,
        currentQuestionIndex: 1,
        roundComplete: false,
      });
      expect(result.success).toBe(true);
    });
  });
});
