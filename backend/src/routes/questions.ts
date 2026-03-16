import type { FastifyPluginAsync } from 'fastify';
import { QuestionGenerationRequestSchema, AnswerValidationRequestSchema } from '../models/types.js';
import { generateQuestions, getQuestionById } from '../services/questionService.js';
import { validateAnswer } from '../services/validationService.js';
import * as db from '../lib/db.js';

export const questionsRoutes: FastifyPluginAsync = async (server) => {

  // ── GET /questions ─────────────────────────────────────
  // Returns a set of personalized questions for a session.
  server.get('/questions', {
    schema: {
      querystring: {
        type: 'object',
        properties: {
          sessionId: { type: 'string' },
          difficulty: { type: 'string', enum: ['easy', 'medium', 'hard'] },
          count: { type: 'integer', minimum: 1, maximum: 20 },
          topic: { type: 'string' },
          exclude: { type: 'string' }, // comma-separated IDs
        },
      },
    },
  }, async (request, reply) => {
    const userId = (request as any).userId as string;
    const query = request.query as Record<string, string>;

    // Fetch user interests
    const user = await db.getUser(userId);
    const interests = user?.interests ?? [];

    const excludeIds = query.exclude ? query.exclude.split(',') : [];

    const questions = generateQuestions({
      userId,
      sessionId: query.sessionId ?? `sess_${Date.now()}`,
      interests,
      difficulty: (query.difficulty as any) ?? 'medium',
      count: query.count ? parseInt(query.count) : 5,
      excludeIds,
      topic: query.topic,
    });

    return reply.send({ questions, count: questions.length });
  });

  // ── GET /questions/:id ─────────────────────────────────
  // Returns a single client-safe question.
  server.get<{ Params: { id: string } }>('/questions/:id', async (request, reply) => {
    const q = getQuestionById(request.params.id);
    if (!q) return reply.code(404).send({ error: 'Question not found' });

    const { answerSchema, ...clientQ } = q;
    return reply.send(clientQ);
  });

  // ── POST /questions/validate ───────────────────────────
  // Server-authoritative answer validation.
  server.post('/questions/validate', {
    schema: {
      body: {
        type: 'object',
        required: ['sessionId', 'questionId', 'userAnswer'],
        properties: {
          sessionId: { type: 'string' },
          questionId: { type: 'string' },
          userAnswer: { type: 'string', maxLength: 500 },
          answeredInMs: { type: 'integer' },
        },
      },
    },
  }, async (request, reply) => {
    const userId = (request as any).userId as string;
    const body = request.body as any;

    // Validate request
    const parsed = AnswerValidationRequestSchema.safeParse(body);
    if (!parsed.success) {
      return reply.code(400).send({ error: 'Invalid request', details: parsed.error.flatten() });
    }

    // Look up question (with answerSchema — never sent to client)
    const question = getQuestionById(parsed.data.questionId);
    if (!question) {
      return reply.code(404).send({ error: 'Question not found' });
    }

    // Look up current user streak
    const user = await db.getUser(userId);
    const currentStreak = user?.streak ?? 0;
    const difficulty = user?.difficultyPreference ?? 'dynamic';
    const effectiveDifficulty = difficulty === 'dynamic'
      ? question.difficulty
      : difficulty === 'hard' ? 'hard' : 'easy';

    // Validate the answer
    const result = validateAnswer(question, parsed.data.userAnswer, currentStreak, effectiveDifficulty);

    // Update user streak if correct
    if (result.isCorrect) {
      await db.updateUser(userId, {
        streak: result.newStreak,
        bestStreak: Math.max(result.newStreak, user?.bestStreak ?? 0),
        xp: (user?.xp ?? 0) + result.pointsAwarded,
      });
    } else {
      // Reset streak on wrong answer
      await db.updateUser(userId, { streak: 0 });
    }

    return reply.send(result);
  });
};
