import type { Question, AnswerValidationResult } from '../models/types.js';
import { calculateScore } from './gameService.js';

// ═══════════════════════════════════════════════════════
// ANSWER VALIDATION SERVICE — Server-authoritative
// ═══════════════════════════════════════════════════════

/**
 * Normalizes a raw answer string for comparison:
 * - lowercase
 * - trim whitespace
 * - remove punctuation
 * - collapse multiple spaces
 */
export function normalizeAnswer(raw: string): string {
  return raw
    .toLowerCase()
    .trim()
    .replace(/[.,!?;:'"()\-]/g, '')
    .replace(/\s+/g, ' ');
}

/**
 * Main validation entry point. Takes a Question (with its answerSchema)
 * and the raw user answer, returns a fully graded AnswerValidationResult.
 */
export function validateAnswer(
  question: Question,
  rawAnswer: string,
  currentStreak: number,
  difficulty: string = 'medium',
): AnswerValidationResult {
  const normalized = normalizeAnswer(rawAnswer);
  const schema = question.answerSchema;

  // ── Multiple choice ──────────────────────────────────
  if (question.type === 'multiple_choice') {
    return validateMultipleChoice(question, normalized, currentStreak, difficulty);
  }

  // ── Numeric ───────────────────────────────────────────
  if (question.type === 'numeric' && schema.numericAnswer !== undefined) {
    return validateNumeric(question, rawAnswer, currentStreak, difficulty);
  }

  // ── True / False ─────────────────────────────────────
  if (question.type === 'true_false') {
    return validateTrueFalse(question, normalized, currentStreak, difficulty);
  }

  // ── Exact / Alias (short_answer, fill_blank) ─────────
  if (schema.exact) {
    const exactResult = validateExact(question, normalized, currentStreak, difficulty);
    if (exactResult.isCorrect || exactResult.matchType !== 'none') {
      return exactResult;
    }
  }

  // ── Semantic fallback ─────────────────────────────────
  return validateSemantic(question, normalized, currentStreak, difficulty);
}

// ── Exact + Alias matching ────────────────────────────

function validateExact(
  question: Question,
  normalizedAnswer: string,
  streak: number,
  difficulty: string,
): AnswerValidationResult {
  const schema = question.answerSchema;
  const correct = normalizeAnswer(schema.exact ?? '');
  const correctDisplay = schema.exact ?? '';

  // Exact match
  if (normalizedAnswer === correct) {
    const score = calculateScore(true, streak, difficulty);
    return {
      isCorrect: true,
      confidenceScore: 1.0,
      matchType: 'exact',
      normalizedAnswer,
      correctAnswer: correctDisplay,
      pointsAwarded: score.points,
      streakBonus: score.streakBonus,
      newStreak: score.newStreak,
    };
  }

  // Alias match
  const matchedAlias = schema.aliases.find(a => normalizeAnswer(a) === normalizedAnswer);
  if (matchedAlias) {
    const score = calculateScore(true, streak, difficulty);
    return {
      isCorrect: true,
      confidenceScore: 0.95,
      matchType: 'alias',
      normalizedAnswer,
      correctAnswer: correctDisplay,
      pointsAwarded: score.points,
      streakBonus: score.streakBonus,
      newStreak: score.newStreak,
    };
  }

  return _wrongResult(correctDisplay, normalizedAnswer);
}

// ── Multiple choice matching ──────────────────────────

function validateMultipleChoice(
  question: Question,
  normalizedAnswer: string,
  streak: number,
  difficulty: string,
): AnswerValidationResult {
  const schema = question.answerSchema;
  const correctChoice = schema.choices.find(c => c.isCorrect);
  if (!correctChoice) return _wrongResult('', normalizedAnswer);

  const correctNorm = normalizeAnswer(correctChoice.text);
  const correctId = correctChoice.id.toLowerCase();

  // Allow match by choice ID (e.g., "a", "b") or choice text
  const isCorrect = normalizedAnswer === correctNorm || normalizedAnswer === correctId;
  if (isCorrect) {
    const score = calculateScore(true, streak, difficulty);
    return {
      isCorrect: true,
      confidenceScore: 1.0,
      matchType: 'multiple_choice',
      normalizedAnswer,
      correctAnswer: correctChoice.text,
      pointsAwarded: score.points,
      streakBonus: score.streakBonus,
      newStreak: score.newStreak,
    };
  }
  return _wrongResult(correctChoice.text, normalizedAnswer);
}

// ── Numeric matching ──────────────────────────────────

function validateNumeric(
  question: Question,
  rawAnswer: string,
  streak: number,
  difficulty: string,
): AnswerValidationResult {
  const schema = question.answerSchema;
  const target = schema.numericAnswer!;
  const tolerance = schema.numericTolerance ?? 0;

  const parsed = parseFloat(rawAnswer.replace(/[^0-9.\-]/g, ''));
  if (isNaN(parsed)) return _wrongResult(String(target), rawAnswer);

  const isCorrect = Math.abs(parsed - target) <= tolerance;
  if (isCorrect) {
    const score = calculateScore(true, streak, difficulty);
    return {
      isCorrect: true,
      confidenceScore: 1.0,
      matchType: 'numeric',
      normalizedAnswer: String(parsed),
      correctAnswer: String(target),
      pointsAwarded: score.points,
      streakBonus: score.streakBonus,
      newStreak: score.newStreak,
    };
  }
  return _wrongResult(String(target), rawAnswer);
}

// ── True / False matching ─────────────────────────────

function validateTrueFalse(
  question: Question,
  normalizedAnswer: string,
  streak: number,
  difficulty: string,
): AnswerValidationResult {
  const schema = question.answerSchema;
  const correct = normalizeAnswer(schema.exact ?? 'true');

  const trueSynonyms = ['true', 'yes', 'correct', 'right', 'yeah', '1'];
  const falseSynonyms = ['false', 'no', 'incorrect', 'wrong', 'nope', '0'];

  let userBool: boolean | null = null;
  if (trueSynonyms.includes(normalizedAnswer)) userBool = true;
  if (falseSynonyms.includes(normalizedAnswer)) userBool = false;

  const correctBool = trueSynonyms.includes(correct);

  if (userBool !== null && userBool === correctBool) {
    const score = calculateScore(true, streak, difficulty);
    return {
      isCorrect: true,
      confidenceScore: 1.0,
      matchType: 'exact',
      normalizedAnswer,
      correctAnswer: correct,
      pointsAwarded: score.points,
      streakBonus: score.streakBonus,
      newStreak: score.newStreak,
    };
  }

  return _wrongResult(correct, normalizedAnswer);
}

// ── Semantic matching (keyword-based fallback) ────────
// Full LLM semantic grading happens in the live session AI tool.
// This function implements a fast keyword-overlap heuristic that
// does NOT require an AI call, for offline/degraded scenarios.

function validateSemantic(
  question: Question,
  normalizedAnswer: string,
  streak: number,
  difficulty: string,
): AnswerValidationResult {
  const schema = question.answerSchema;
  const keywords = schema.semanticKeywords.map(k => normalizeAnswer(k));
  const threshold = schema.semanticThreshold ?? 0.7;
  const correctDisplay = schema.exact ?? schema.aliases[0] ?? keywords.join(', ');

  if (keywords.length === 0) return _wrongResult(correctDisplay, normalizedAnswer);

  const matchedCount = keywords.filter(k => normalizedAnswer.includes(k)).length;
  const confidence = matchedCount / keywords.length;

  if (confidence >= threshold) {
    const score = calculateScore(true, streak, difficulty);
    return {
      isCorrect: true,
      confidenceScore: confidence,
      matchType: 'semantic',
      normalizedAnswer,
      correctAnswer: correctDisplay,
      explanation: `Matched ${matchedCount}/${keywords.length} key concepts.`,
      pointsAwarded: Math.round(score.points * confidence),
      streakBonus: score.streakBonus,
      newStreak: score.newStreak,
    };
  }

  return {
    ..._wrongResult(correctDisplay, normalizedAnswer),
    confidenceScore: confidence,
    explanation: confidence > 0 ? 'Partial match — try to be more specific.' : undefined,
  };
}

// ── Helpers ───────────────────────────────────────────

function _wrongResult(correctAnswer: string, normalizedAnswer: string): AnswerValidationResult {
  return {
    isCorrect: false,
    confidenceScore: 0,
    matchType: 'none',
    normalizedAnswer,
    correctAnswer,
    pointsAwarded: 0,
    streakBonus: 0,
    newStreak: 0,
  };
}
