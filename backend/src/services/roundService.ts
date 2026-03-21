import { randomUUID } from 'crypto';
import * as db from '../lib/db.js';
import type {
  AnswerResult,
  ClientQuestion,
  Question,
  Resources,
  RoundDefinition,
  RoundSession,
  User,
} from '../models/types.js';
import { generateQuestions, getQuestionById, toClientQuestion } from './questionService.js';
import { validateAnswer } from './validationService.js';
import * as game from './gameService.js';

type RoundMode = 'quiz' | 'sprint' | 'event';

type DifficultyPreference = 'easy' | 'dynamic' | 'hard' | 'medium';

function mapDifficultyPreference(
  preference: DifficultyPreference | string | undefined,
  fallback: 'easy' | 'dynamic' | 'hard' = 'dynamic',
): 'easy' | 'dynamic' | 'hard' {
  if (preference === 'easy') return 'easy';
  if (preference === 'hard') return 'hard';
  return fallback;
}

function toQuestionDifficulty(
  preference: 'easy' | 'dynamic' | 'hard' | 'medium' | string,
): 'easy' | 'medium' | 'hard' {
  if (preference === 'easy' || preference === 'hard') return preference;
  return 'medium';
}

function normalizeStoredRoundDifficulty(
  difficulty: string | undefined,
): 'easy' | 'dynamic' | 'hard' {
  if (difficulty === 'easy' || difficulty === 'hard') return difficulty;
  return 'dynamic';
}

function defaultTopicForUser(user: User): string {
  return user.interests[0] ?? 'General';
}

function questionCountForMode(mode: RoundMode): number {
  switch (mode) {
    case 'sprint':
      return 3;
    case 'event':
      return 5;
    case 'quiz':
    default:
      return 5;
  }
}

function weeklyScope(now = new Date()): string {
  const startOfYear = new Date(now.getFullYear(), 0, 1);
  const weekNum = Math.ceil(((now.getTime() - startOfYear.getTime()) / 86400000 + startOfYear.getDay() + 1) / 7);
  return `weekly_${now.getFullYear()}_${weekNum}`;
}

function resourceGrantForDifficulty(difficulty: 'easy' | 'medium' | 'hard'): Resources {
  switch (difficulty) {
    case 'hard':
      return { stone: 6, glass: 3, wood: 5 };
    case 'medium':
      return { stone: 4, glass: 2, wood: 3 };
    case 'easy':
    default:
      return { stone: 2, glass: 1, wood: 2 };
  }
}

function scaleResources(resources: Resources, multiplier: number): Resources {
  return {
    stone: Math.max(0, Math.floor(resources.stone * multiplier)),
    glass: Math.max(0, Math.floor(resources.glass * multiplier)),
    wood: Math.max(0, Math.floor(resources.wood * multiplier)),
  };
}

function sumResources(a: Resources, b: Resources): Resources {
  return {
    stone: a.stone + b.stone,
    glass: a.glass + b.glass,
    wood: a.wood + b.wood,
  };
}

function todayUtc(): string {
  return new Date().toISOString().slice(0, 10);
}

async function applyAutomaticSquadMissionContribution(
  userId: string,
  round: RoundSession,
): Promise<{ squadId: string | null; missionId: string | null; amount: number }> {
  const squadId = await db.getSquadIdForUser(userId);
  if (!squadId) {
    return { squadId: null, missionId: null, amount: 0 };
  }

  const missions = await db.getSquadMissions(squadId);
  const activeMission = missions.find((mission) => {
    const status = (mission.status as string | undefined) ?? '';
    const goal = (mission.goalProgress as number | undefined) ?? (mission.targetProgress as number | undefined) ?? 0;
    const progress = (mission.currentProgress as number | undefined) ?? 0;
    return status !== 'completed' && progress < goal;
  });

  if (!activeMission?.id) {
    return { squadId, missionId: null, amount: 0 };
  }

  const amount = Math.max(1, round.correctAnswers);
  await db.updateSquadMissionProgress(squadId, activeMission.id as string, amount);
  return { squadId, missionId: activeMission.id as string, amount };
}

function buildHint(question: Question): string {
  if (question.type === 'multiple_choice' && question.answerSchema.choices.length > 0) {
    const options = question.answerSchema.choices.map((choice) => `${choice.id.toUpperCase()}: ${choice.text}`).join(', ');
    return `Listen to the options again: ${options}.`;
  }

  if (question.type === 'true_false') {
    return 'This one is a true-or-false judgment. Keep it short.';
  }

  if (question.type === 'numeric') {
    return `Think in numbers. Focus on ${question.subtopic ?? question.topic}.`;
  }

  const keywords = question.answerSchema.semanticKeywords.slice(0, 2);
  if (keywords.length > 0) {
    return `Hint: think about ${keywords.join(' and ')}.`;
  }

  if (question.subtopic) {
    return `Hint: this is in ${question.subtopic}.`;
  }

  return `Hint: stay in the lane of ${question.topic}.`;
}

function requireRoundQuestion(round: RoundSession): { question: Question; questionId: string } {
  const questionId = round.questionIds[round.currentQuestionIndex];
  if (!questionId) {
    throw new Error('No current question is available for this round');
  }
  const question = getQuestionById(questionId);
  if (!question) {
    throw new Error(`Question not found: ${questionId}`);
  }
  return { question, questionId };
}

function toRoundQuestion(question: Question): ClientQuestion {
  return toClientQuestion(question);
}

async function updateLeaderboardsForFinishedRound(
  userId: string,
  round: RoundSession,
): Promise<void> {
  const [user, district, squadId] = await Promise.all([
    db.getUser(userId),
    game.getDistrict(userId),
    db.getSquadIdForUser(userId),
  ]);
  if (!user) return;

  const districtName = district?.name ?? user.districtName;
  const regionId = (district as any)?.regionAnchor?.regionId ?? 'global_central';
  const topTopic = Object.values(((user as any).topicStats ?? {}) as Record<string, any>)
    .sort((a, b) => (b.masteryScore ?? 0) - (a.masteryScore ?? 0))[0]?.topic as string | undefined;

  await db.upsertLeaderboardEntry('global', userId, {
    userId,
    displayName: user.displayName,
    score: user.xp,
    districtName,
    regionId,
    scope: 'global',
  });

  await db.upsertLeaderboardEntry(weeklyScope(), userId, {
    userId,
    displayName: user.displayName,
    score: round.totalScore,
    districtName,
    regionId,
    scope: 'weekly',
  });

  await db.upsertLeaderboardEntry(`region_${regionId}`, userId, {
    userId,
    displayName: user.displayName,
    score: district?.sectors ?? user.sectors,
    districtName,
    regionId,
    scope: 'region',
  });

  if (round.topic) {
    await db.upsertLeaderboardEntry(`topic_${game.slugifyTopic(round.topic)}`, userId, {
      userId,
      displayName: user.displayName,
      score: round.correctAnswers,
      districtName,
      topic: round.topic,
      scope: 'topic',
    });
  } else if (topTopic) {
    await db.upsertLeaderboardEntry(`topic_${game.slugifyTopic(topTopic)}`, userId, {
      userId,
      displayName: user.displayName,
      score: round.correctAnswers,
      districtName,
      topic: topTopic,
      scope: 'topic',
    });
  }

  if (round.eventId) {
    await db.addEventScore(round.eventId, userId, round.totalScore).catch(() => {});
    await db.upsertLeaderboardEntry(`event_${round.eventId}`, userId, {
      userId,
      displayName: user.displayName,
      score: round.totalScore,
      districtName,
      scope: 'event',
    });
  }

  if (squadId) {
    await db.upsertLeaderboardEntry(`squad_${squadId}`, userId, {
      userId,
      displayName: user.displayName,
      score: round.totalScore,
      districtName,
      scope: 'squad',
    });
  }
}

export async function startRound(
  userId: string,
  options: {
    mode?: RoundMode;
    topic?: string;
    difficulty?: 'easy' | 'dynamic' | 'hard';
    eventId?: string;
  } = {},
): Promise<RoundDefinition> {
  const user = await db.getUser(userId);
  if (!user) {
    throw new Error('User not found');
  }

  const mode = options.mode ?? 'quiz';
  const count = questionCountForMode(mode);
  let topic = options.topic ?? defaultTopicForUser(user);
  if (options.eventId && !options.topic) {
    const event = await db.getEvent(options.eventId).catch(() => null);
    if (event?.title?.trim()) {
      topic = event.title.trim();
    }
  }
  const difficulty = mapDifficultyPreference(
    options.difficulty ?? user.difficultyPreference,
  );
  const questionDifficulty = toQuestionDifficulty(difficulty);
  const existing = await db.getActiveRound(userId);

  if (existing && existing.status === 'active') {
    const currentQuestionId = existing.questionIds[existing.currentQuestionIndex];
    const currentQuestion = currentQuestionId ? getQuestionById(currentQuestionId) : null;
    return {
      roundId: existing.id,
      mode: existing.mode,
      topic: existing.topic,
      difficulty: normalizeStoredRoundDifficulty(existing.difficulty),
      eventId: existing.eventId,
      questionCount: existing.questionCount,
      currentQuestionIndex: existing.currentQuestionIndex,
      currentQuestion: currentQuestion ? toRoundQuestion(currentQuestion) : undefined,
      questions: existing.questionIds
        .map((id) => getQuestionById(id))
        .filter((q): q is Question => q !== null)
        .map((q) => toRoundQuestion(q)),
      hintCount: existing.hintCount,
      repeatCount: existing.repeatCount,
      isComplete: existing.roundComplete,
    };
  }

  const questions = generateQuestions({
    userId,
    sessionId: `round_seed_${Date.now()}`,
    interests: user.interests,
    difficulty: questionDifficulty,
    count,
    excludeIds: [],
    topic,
  });

  if (questions.length === 0) {
    throw new Error('No questions available for this round');
  }

  const now = new Date().toISOString();
  const round: RoundSession = {
    id: `round_${randomUUID()}`,
    userId,
    mode,
    topic,
    difficulty,
    eventId: options.eventId,
    questionIds: questions.map((q) => q.id),
    questionCount: count,
    currentQuestionIndex: 0,
    hintCount: 0,
    repeatCount: 0,
    questionsAsked: 0,
    correctAnswers: 0,
    totalScore: 0,
    maxStreak: 0,
    roundComplete: false,
    status: 'active',
    startedAt: now,
  };

  await db.createRound(round);

  return {
    roundId: round.id,
    mode,
    topic,
    difficulty,
    eventId: options.eventId,
    questionCount: count,
    currentQuestionIndex: 0,
    currentQuestion: questions[0],
    questions,
    hintCount: 0,
    repeatCount: 0,
    isComplete: false,
  };
}

export async function answerRound(
  userId: string,
  roundId: string,
  answer: string,
  questionId?: string,
): Promise<AnswerResult> {
  const [user, round] = await Promise.all([
    db.getUser(userId),
    db.getRound(roundId),
  ]);
  if (!user) throw new Error('User not found');
  if (!round || round.userId !== userId) throw new Error('Round not found');
  if (round.status !== 'active') throw new Error('Round is no longer active');
  if (round.roundComplete) throw new Error('Round is already complete');

  const { question, questionId: currentQuestionId } = requireRoundQuestion(round);
  if (questionId && questionId !== currentQuestionId) {
    throw new Error('Question does not match the current round state');
  }

  const effects = await game.getStructureEffects(userId);
  const effectiveDifficulty = toQuestionDifficulty(round.difficulty);
  const validation = validateAnswer(question, answer, user.streak, effectiveDifficulty);

  let xpAwarded = 0;
  let influenceGranted = 0;
  let comboXp = 0;
  let materialsEarned: Resources = { stone: 0, glass: 0, wood: 0 };
  let growthResult: Awaited<ReturnType<typeof game.checkGrowthThreshold>> | null = null;

  if (validation.isCorrect) {
    xpAwarded = Math.floor(validation.pointsAwarded * effects.xpMultiplier);
    materialsEarned = scaleResources(resourceGrantForDifficulty(effectiveDifficulty), effects.materialMultiplier);
    influenceGranted = Math.floor(
      game.calculateInfluenceGrant('grade_answer', effectiveDifficulty, validation.newStreak) * effects.influenceMultiplier,
    );

    await db.incrementUserXp(userId, xpAwarded);
    await db.updateUserStreak(userId, validation.newStreak, user.bestStreak);
    await db.incrementUserInfluence(userId, influenceGranted);

    const district = await game.getDistrict(userId);
    if (district) {
      await Promise.all([
        db.incrementDistrictInfluence(district.id, influenceGranted),
        db.addResources(district.id, materialsEarned),
      ]);
    }

    await Promise.all([
      game.grantReward(userId, 'xp', xpAwarded, 'round_answer', round.id, {
        questionId: currentQuestionId,
        topic: question.topic,
      }),
      game.grantReward(userId, 'influence', influenceGranted, 'round_answer', round.id, {
        questionId: currentQuestionId,
        topic: question.topic,
      }),
      game.grantReward(userId, 'materials', materialsEarned.stone + materialsEarned.glass + materialsEarned.wood, 'round_answer', round.id, {
        questionId: currentQuestionId,
        topic: question.topic,
      }),
    ]);

    if (validation.newStreak >= 3) {
      const combo = game.calculateComboBonus(validation.newStreak, 1.25);
      comboXp = combo.bonusXp;
      materialsEarned = sumResources(materialsEarned, combo.bonusMaterials);
      await db.incrementUserXp(userId, combo.bonusXp);
      if (district) {
        await db.addResources(district.id, combo.bonusMaterials);
      }
      await game.grantReward(userId, 'combo', combo.bonusXp, 'round_combo', round.id, {
        questionId: currentQuestionId,
        streak: validation.newStreak,
      });
    }

    growthResult = await game.checkGrowthThreshold(userId);
  } else {
    await db.updateUserStreak(userId, 0, user.bestStreak);
  }

  await game.recordTopicOutcome(userId, question.topic, validation.isCorrect);

  const nextQuestionIndex = round.currentQuestionIndex + 1;
  const roundComplete = nextQuestionIndex >= round.questionCount;
  const totalScore = round.totalScore + xpAwarded + comboXp;

  await db.updateRound(round.id, {
    currentQuestionIndex: Math.min(nextQuestionIndex, round.questionCount),
    questionsAsked: round.questionsAsked + 1,
    correctAnswers: round.correctAnswers + (validation.isCorrect ? 1 : 0),
    totalScore,
    maxStreak: Math.max(round.maxStreak, validation.newStreak),
    roundComplete,
  });

  await game.updatePrestigeIfNeeded(userId);
  await game.syncDistrictDerivedState(userId);

  const nextQuestion = !roundComplete
    ? getQuestionById(round.questionIds[nextQuestionIndex])
    : null;

  return {
    ...validation,
    roundId: round.id,
    questionId: currentQuestionId,
    topic: question.topic,
    xpAwarded,
    influenceGranted,
    sectorsGained: growthResult?.sectorsGained ?? 0,
    materialsEarned,
    comboXp,
    territoryExpanded: growthResult?.expanded ?? false,
    nextQuestion: nextQuestion ? toRoundQuestion(nextQuestion) : undefined,
    questionCount: round.questionCount,
    currentQuestionIndex: Math.min(nextQuestionIndex, round.questionCount),
    roundComplete,
  };
}

export async function updateRoundDifficulty(
  userId: string,
  roundId: string,
  difficultyPreference: DifficultyPreference,
): Promise<RoundDefinition & { appliesFromQuestionIndex: number }> {
  const [user, round] = await Promise.all([
    db.getUser(userId),
    db.getRound(roundId),
  ]);
  if (!user) throw new Error('User not found');
  if (!round || round.userId !== userId) throw new Error('Round not found');
  if (round.status !== 'active') throw new Error('Round is no longer active');
  if (round.roundComplete) throw new Error('Round is already complete');

  const mappedDifficulty = mapDifficultyPreference(difficultyPreference);
  const replacementDifficulty = toQuestionDifficulty(mappedDifficulty);
  const appliesFromQuestionIndex = Math.min(
    round.currentQuestionIndex + 1,
    round.questionCount,
  );

  const remainingCount = Math.max(0, round.questionCount - appliesFromQuestionIndex);
  let nextIds = round.questionIds.slice();

  if (remainingCount > 0) {
    const replacementQuestions = generateQuestions({
      userId,
      sessionId: `difficulty_${Date.now()}`,
      interests: user.interests,
      difficulty: replacementDifficulty,
      count: remainingCount,
      excludeIds: round.questionIds.slice(0, appliesFromQuestionIndex),
      topic: round.topic,
    });

    nextIds = [
      ...round.questionIds.slice(0, appliesFromQuestionIndex),
      ...replacementQuestions.map((question) => question.id),
    ];
  }

  await Promise.all([
    db.updateRound(round.id, {
      difficulty: mappedDifficulty,
      questionIds: nextIds,
    }),
    db.updateUser(userId, {
      difficultyPreference:
        difficultyPreference === 'medium' ? 'dynamic' : (difficultyPreference === 'dynamic' ? 'dynamic' : difficultyPreference),
    } as any),
  ]);

  const currentQuestionId = nextIds[round.currentQuestionIndex];
  const currentQuestion = currentQuestionId ? getQuestionById(currentQuestionId) : null;

  return {
    roundId: round.id,
    mode: round.mode,
    topic: round.topic,
    difficulty: mappedDifficulty,
    eventId: round.eventId,
    questionCount: round.questionCount,
    currentQuestionIndex: round.currentQuestionIndex,
    currentQuestion: currentQuestion ? toRoundQuestion(currentQuestion) : undefined,
    questions: nextIds
      .map((id) => getQuestionById(id))
      .filter((question): question is Question => question !== null)
      .map((question) => toRoundQuestion(question)),
    hintCount: round.hintCount,
    repeatCount: round.repeatCount,
    isComplete: round.roundComplete,
    appliesFromQuestionIndex,
  };
}

export async function requestRoundHint(userId: string, roundId: string): Promise<{
  roundId: string;
  questionId: string;
  hintCount: number;
  hint: string;
  currentQuestion: ClientQuestion;
}> {
  const round = await db.getRound(roundId);
  if (!round || round.userId !== userId) throw new Error('Round not found');
  if (round.status !== 'active') throw new Error('Round is no longer active');

  const { question, questionId } = requireRoundQuestion(round);
  const hintCount = (round.hintCount ?? 0) + 1;
  await db.updateRound(round.id, { hintCount });

  return {
    roundId: round.id,
    questionId,
    hintCount,
    hint: buildHint(question),
    currentQuestion: toRoundQuestion(question),
  };
}

export async function requestRoundRepeat(userId: string, roundId: string): Promise<{
  roundId: string;
  questionId: string;
  repeatCount: number;
  currentQuestion: ClientQuestion;
}> {
  const round = await db.getRound(roundId);
  if (!round || round.userId !== userId) throw new Error('Round not found');
  if (round.status !== 'active') throw new Error('Round is no longer active');

  const { question, questionId } = requireRoundQuestion(round);
  const repeatCount = (round.repeatCount ?? 0) + 1;
  await db.updateRound(round.id, { repeatCount });

  return {
    roundId: round.id,
    questionId,
    repeatCount,
    currentQuestion: toRoundQuestion(question),
  };
}

export async function finishRound(userId: string, roundId: string): Promise<{
  roundId: string;
  totalScore: number;
  questionsAnswered: number;
  correctAnswers: number;
  newBadges: string[];
  dailyBonusXp: number;
  dailyBonusInfluence: number;
  squadContribution: {
    squadId: string | null;
    missionId: string | null;
    amount: number;
  };
  isDailySprint: boolean;
  eventParticipation: {
    eventId: string | null;
    joined: boolean;
  };
}> {
  const [round, user] = await Promise.all([
    db.getRound(roundId),
    db.getUser(userId),
  ]);
  if (!round || round.userId !== userId) throw new Error('Round not found');
  if (!user) throw new Error('User not found');

  if (round.status !== 'completed') {
    await db.updateRound(round.id, {
      status: 'completed',
      endedAt: new Date().toISOString(),
      roundComplete: true,
    });
  }

  const qualifiesForDailyBonus =
    round.mode == 'sprint' && user.lastActivityDate != todayUtc();
  let dailyBonusXp = 0;
  let dailyBonusInfluence = 0;
  if (qualifiesForDailyBonus) {
    dailyBonusXp = 150;
    dailyBonusInfluence = game.calculateInfluenceGrant('event', 'easy', user.dailyStreak);
    await db.incrementUserXp(userId, dailyBonusXp);
    await db.incrementUserInfluence(userId, dailyBonusInfluence);
    const districtForBonus = await game.getDistrict(userId);
    if (districtForBonus) {
      await db.incrementDistrictInfluence(districtForBonus.id, dailyBonusInfluence);
    }
    await Promise.all([
      game.grantReward(userId, 'xp', dailyBonusXp, 'daily_sprint_bonus', round.id),
      game.grantReward(userId, 'influence', dailyBonusInfluence, 'daily_sprint_bonus', round.id),
    ]);
  }

  await db.updateDailyStreak(userId);

  const district = await game.getDistrict(userId);
  if (district && district.structures.length > 0) {
    await db.addResources(district.id, game.calculateResourceRate(district.structures));
  }

  let eventParticipation = { eventId: null as string | null, joined: false };
  if (round.eventId) {
    await db.joinEvent(round.eventId, userId).catch(() => {});
    eventParticipation = { eventId: round.eventId, joined: true };
  }

  const squadContribution = await applyAutomaticSquadMissionContribution(userId, round);

  await updateLeaderboardsForFinishedRound(userId, round);
  await game.updatePrestigeIfNeeded(userId);
  await game.syncDistrictDerivedState(userId);

  const newBadges = await game.checkAndGrantAchievements(userId);

  return {
    roundId: round.id,
    totalScore: round.totalScore,
    questionsAnswered: round.questionsAsked,
    correctAnswers: round.correctAnswers,
    newBadges,
    dailyBonusXp,
    dailyBonusInfluence,
    squadContribution,
    isDailySprint: round.mode === 'sprint',
    eventParticipation,
  };
}
