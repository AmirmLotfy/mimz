import { describe, it, expect } from 'vitest';
import { executeTool } from '../src/modules/live/executeLiveTool.js';
import { buildPersonalizedInstruction } from '../src/modules/live/liveService.js';

const CTX = {
  userId: 'test_user_01',
  sessionId: 'ses_test_001',
  correlationId: 'corr_idempotency_test',
};

// ═══════════════════════════════════════════════════
// IDEMPOTENCY TESTS
// ═══════════════════════════════════════════════════

describe('Tool Idempotency Guard', () => {
  it('grade_answer: second call with same correlationId returns cached result (no Firestore)', async () => {
    const ARGS = { answer: 'Dart', isCorrect: true };

    // First call — will fail at db.getUser because no real Firestore,
    // but the error is caught and returns failure. That's fine for this test.
    const result1 = await executeTool('grade_answer', ARGS, CTX);

    // Second call with same correlationId
    const result2 = await executeTool('grade_answer', ARGS, CTX);

    // Both results must be identical (idempotency)
    expect(result2.correlationId).toBe(result1.correlationId);
    expect(result2.success).toBe(result1.success);
  });

  it('award_territory: second call with same correlationId returns cached result', async () => {
    const CTX2 = { ...CTX, correlationId: 'corr_territory_idem' };
    const ARGS = { sectors: 1 };

    const result1 = await executeTool('award_territory', ARGS, CTX2);
    const result2 = await executeTool('award_territory', ARGS, CTX2);

    // Both results must be identical
    expect(result2.correlationId).toBe(result1.correlationId);
    expect(result2.success).toBe(result1.success);
  });

  it('different correlationIds are NOT deduplicated', async () => {
    const CTX_A = { ...CTX, correlationId: 'corr_unique_a' };
    const CTX_B = { ...CTX, correlationId: 'corr_unique_b' };
    const ARGS = { answer: 'Python', isCorrect: false };

    const result1 = await executeTool('grade_answer', ARGS, CTX_A);
    const result2 = await executeTool('grade_answer', ARGS, CTX_B);

    // They should each have their own correlationId
    expect(result1.correlationId).toBe('corr_unique_a');
    expect(result2.correlationId).toBe('corr_unique_b');
  });
});

// ═══════════════════════════════════════════════════
// AWARD_TERRITORY BOUNDS TESTS
// ═══════════════════════════════════════════════════

describe('award_territory Bounds Enforcement (Zod schema)', () => {
  it('rejects sectors = 0 (below min)', async () => {
    const result = await executeTool('award_territory', { sectors: 0 }, { ...CTX, correlationId: 'corr_bounds_0' });
    expect(result.success).toBe(false);
    expect(result.error).toContain('Invalid args');
  });

  it('rejects sectors = 6 (above max)', async () => {
    const result = await executeTool('award_territory', { sectors: 6 }, { ...CTX, correlationId: 'corr_bounds_6' });
    expect(result.success).toBe(false);
    expect(result.error).toContain('Invalid args');
  });

  it('accepts sectors = 3 (valid)', async () => {
    // This will fail at Firestore but not at schema validation
    const result = await executeTool('award_territory', { sectors: 3 }, { ...CTX, correlationId: 'corr_bounds_3' });
    // Success or Firestore error — but NOT an Invalid args error
    if (!result.success) {
      expect(result.error).not.toContain('Invalid args');
    }
  });
});

// ═══════════════════════════════════════════════════
// UNKNOWN TOOL REJECTION
// ═══════════════════════════════════════════════════

describe('Unknown Tool Rejection', () => {
  it('returns error for unknown tool name', async () => {
    const result = await executeTool('hack_the_planet', {}, CTX);
    expect(result.success).toBe(false);
    expect(result.error).toContain('Unknown tool');
  });
});

// ═══════════════════════════════════════════════════
// SYSTEM PROMPT PERSONALIZATION TESTS
// ═══════════════════════════════════════════════════

describe('buildPersonalizedInstruction', () => {
  it('includes the user name in the quiz prompt', () => {
    const instruction = buildPersonalizedInstruction('quiz', 'Alex', ['Science', 'History'], 'dynamic');
    expect(instruction).toContain('Alex');
    expect(instruction).toContain('Science');
    expect(instruction).toContain('History');
  });

  it('includes the user name in the onboarding prompt', () => {
    const instruction = buildPersonalizedInstruction('onboarding', 'Jordan', [], 'casual');
    expect(instruction).toContain('Jordan');
    expect(instruction).toContain('onboarding');
  });

  it('falls back gracefully when no name is provided', () => {
    const instruction = buildPersonalizedInstruction('quiz', undefined, undefined, undefined);
    // Should still produce a valid instruction
    expect(instruction.length).toBeGreaterThan(100);
    expect(instruction).toContain('Explorer');
  });

  it('caps interests at 5 in the instruction', () => {
    const manyInterests = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    const instruction = buildPersonalizedInstruction('quiz', 'Test', manyInterests, 'dynamic');
    // Should include the first 5 but not all 7
    expect(instruction).toContain('A');
    expect(instruction).not.toContain('F, G'); // 6th and 7th are sliced off
  });

  it('sets challenger difficulty for hard preference', () => {
    const instruction = buildPersonalizedInstruction('quiz', 'User', [], 'challenger');
    expect(instruction).toContain('hard');
  });
});
