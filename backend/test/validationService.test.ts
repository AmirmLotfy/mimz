import {
  validateAnswer,
  normalizeAnswer,
} from '../src/services/validationService.js';
import type { Question } from '../src/models/types.js';

// ── Helpers ───────────────────────────────────────────

function makeQuestion(overrides: Partial<Question> = {}): Question {
  return {
    id: 'q_test_001',
    topic: 'Test Topic',
    difficulty: 'medium',
    type: 'short_answer',
    text: 'What is the test answer?',
    spokenPhrase: 'What is the test answer?',
    tags: [],
    interests: [],
    source: 'deterministic',
    answerSchema: {
      exact: 'correct answer',
      aliases: ['right answer', 'right'],
      choices: [],
      semanticKeywords: ['correct', 'answer'],
      numericTolerance: 0,
      semanticThreshold: 0.8,
    },
    ...overrides,
  };
}

// ── normalizeAnswer ────────────────────────────────────

describe('normalizeAnswer', () => {
  it('lowercases and trims', () => {
    expect(normalizeAnswer('  Hello World  ')).toBe('hello world');
  });

  it('strips punctuation', () => {
    expect(normalizeAnswer("It's a test!")).toBe('its a test');
  });

  it('collapses multiple spaces', () => {
    expect(normalizeAnswer('foo   bar')).toBe('foo bar');
  });
});

// ── Exact matching ─────────────────────────────────────

describe('validateAnswer - exact', () => {
  it('returns isCorrect=true for exact match', () => {
    const q = makeQuestion();
    const result = validateAnswer(q, 'correct answer', 0);
    expect(result.isCorrect).toBe(true);
    expect(result.matchType).toBe('exact');
    expect(result.confidenceScore).toBe(1.0);
  });

  it('is case-insensitive', () => {
    const q = makeQuestion();
    const result = validateAnswer(q, 'CORRECT ANSWER', 0);
    expect(result.isCorrect).toBe(true);
  });

  it('matches alias', () => {
    const q = makeQuestion();
    const result = validateAnswer(q, 'right answer', 0);
    expect(result.isCorrect).toBe(true);
    expect(result.matchType).toBe('alias');
  });

  it('returns isCorrect=false for wrong answer', () => {
    const q = makeQuestion();
    const result = validateAnswer(q, 'totally wrong', 0);
    expect(result.isCorrect).toBe(false);
    expect(result.matchType).not.toBe('exact');
  });

  it('awards more points with higher streak', () => {
    const q = makeQuestion();
    const r0 = validateAnswer(q, 'correct answer', 0);
    const r5 = validateAnswer(q, 'correct answer', 5);
    expect(r5.pointsAwarded).toBeGreaterThanOrEqual(r0.pointsAwarded);
  });
});

// ── Multiple choice ────────────────────────────────────

describe('validateAnswer - multiple_choice', () => {
  const mcQuestion = makeQuestion({
    type: 'multiple_choice',
    answerSchema: {
      exact: 'sftp',
      aliases: [],
      choices: [
        { id: 'a', text: 'FTP', isCorrect: false },
        { id: 'b', text: 'SFTP', isCorrect: true },
        { id: 'c', text: 'HTTP', isCorrect: false },
      ],
      semanticKeywords: [],
      numericTolerance: 0,
      semanticThreshold: 0.8,
    },
  });

  it('matches by choice text', () => {
    const result = validateAnswer(mcQuestion, 'SFTP', 0);
    expect(result.isCorrect).toBe(true);
    expect(result.matchType).toBe('multiple_choice');
  });

  it('matches by choice ID', () => {
    const result = validateAnswer(mcQuestion, 'b', 0);
    expect(result.isCorrect).toBe(true);
  });

  it('rejects wrong choice', () => {
    const result = validateAnswer(mcQuestion, 'FTP', 0);
    expect(result.isCorrect).toBe(false);
  });
});

// ── Numeric matching ───────────────────────────────────

describe('validateAnswer - numeric', () => {
  const numQuestion = makeQuestion({
    type: 'numeric',
    answerSchema: {
      exact: '1945',
      aliases: [],
      choices: [],
      numericAnswer: 1945,
      numericTolerance: 0,
      semanticKeywords: [],
      semanticThreshold: 0.8,
    },
  });

  it('matches exact numeric', () => {
    const result = validateAnswer(numQuestion, '1945', 0);
    expect(result.isCorrect).toBe(true);
    expect(result.matchType).toBe('numeric');
  });

  it('rejects wrong number', () => {
    const result = validateAnswer(numQuestion, '1944', 0);
    expect(result.isCorrect).toBe(false);
  });

  const toleranceQuestion = makeQuestion({
    type: 'numeric',
    answerSchema: {
      exact: '300000',
      aliases: [],
      choices: [],
      numericAnswer: 300000,
      numericTolerance: 5000,
      semanticKeywords: [],
      semanticThreshold: 0.8,
    },
  });

  it('accepts answer within tolerance', () => {
    const result = validateAnswer(toleranceQuestion, '299000', 0);
    expect(result.isCorrect).toBe(true);
  });

  it('rejects answer outside tolerance', () => {
    const result = validateAnswer(toleranceQuestion, '290000', 0);
    expect(result.isCorrect).toBe(false);
  });
});

// ── True/False matching ────────────────────────────────

describe('validateAnswer - true_false', () => {
  const tfQuestion = makeQuestion({
    type: 'true_false',
    answerSchema: {
      exact: 'false',
      aliases: [],
      choices: [],
      semanticKeywords: [],
      numericTolerance: 0,
      semanticThreshold: 0.8,
    },
  });

  it('accepts "false"', () => {
    const result = validateAnswer(tfQuestion, 'false', 0);
    expect(result.isCorrect).toBe(true);
  });

  it('accepts "no" as false synonym', () => {
    const result = validateAnswer(tfQuestion, 'no', 0);
    expect(result.isCorrect).toBe(true);
  });

  it('rejects "true" when answer is false', () => {
    const result = validateAnswer(tfQuestion, 'true', 0);
    expect(result.isCorrect).toBe(false);
  });
});

// ── Semantic fallback ──────────────────────────────────

describe('validateAnswer - semantic', () => {
  const semanticQ = makeQuestion({
    type: 'short_answer',
    answerSchema: {
      exact: undefined,
      aliases: [],
      choices: [],
      semanticKeywords: ['mitochondria', 'energy', 'cell'],
      numericTolerance: 0,
      semanticThreshold: 0.6,
    },
  });

  it('accepts answer containing majority of keywords', () => {
    const result = validateAnswer(semanticQ, 'the mitochondria produce energy for the cell', 0);
    expect(result.isCorrect).toBe(true);
    expect(result.matchType).toBe('semantic');
    expect(result.confidenceScore).toBeGreaterThan(0.6);
  });

  it('rejects answer with no matching keywords', () => {
    const result = validateAnswer(semanticQ, 'I do not know', 0);
    expect(result.isCorrect).toBe(false);
  });
});
