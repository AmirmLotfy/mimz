import { randomUUID } from 'crypto';
import type { Question, ClientQuestion, QuestionGenerationRequest } from '../models/types.js';

// ═══════════════════════════════════════════════════════
// QUESTION BANK — Deterministic seed questions
// Organized by topic, tagged with interest taxonomy.
// ═══════════════════════════════════════════════════════

const QUESTION_BANK: Question[] = [
  // Technology
  {
    id: 'q_tech_001',
    topic: 'Technology & Engineering',
    subtopic: 'Artificial Intelligence',
    tags: ['ai', 'ml', 'neural_networks'],
    difficulty: 'medium',
    type: 'short_answer',
    text: 'What does the acronym "GPU" stand for?',
    spokenPhrase: 'What does the acronym G-P-U stand for?',
    answerSchema: {
      exact: 'graphics processing unit',
      aliases: ['graphics processor unit', 'graphical processing unit'],
      choices: [],
      semanticKeywords: ['graphics', 'processing', 'unit'],
      numericTolerance: 0,
      semanticThreshold: 0.8,
    },
    source: 'deterministic',
    interests: ['Technology & Engineering', 'Artificial Intelligence'],
  },
  {
    id: 'q_tech_002',
    topic: 'Technology & Engineering',
    subtopic: 'Software Engineering',
    tags: ['programming', 'cs_basics'],
    difficulty: 'easy',
    type: 'true_false',
    text: 'Python is a compiled programming language.',
    spokenPhrase: 'True or false — Python is a compiled programming language.',
    answerSchema: {
      exact: 'false',
      aliases: ['no'],
      choices: [],
      semanticKeywords: ['interpreted', 'scripting'],
      numericTolerance: 0,
      semanticThreshold: 0.8,
    },
    source: 'deterministic',
    interests: ['Technology & Engineering', 'Software Engineering'],
  },
  {
    id: 'q_tech_003',
    topic: 'Technology & Engineering',
    subtopic: 'Cybersecurity',
    tags: ['security', 'networking'],
    difficulty: 'medium',
    type: 'multiple_choice',
    text: 'Which protocol is used to securely transfer files over the internet?',
    spokenPhrase: 'Which protocol is used to securely transfer files over the internet? A: FTP, B: SFTP, C: HTTP, or D: SMTP',
    answerSchema: {
      exact: 'sftp',
      aliases: ['secure file transfer protocol'],
      choices: [
        { id: 'a', text: 'FTP', isCorrect: false },
        { id: 'b', text: 'SFTP', isCorrect: true },
        { id: 'c', text: 'HTTP', isCorrect: false },
        { id: 'd', text: 'SMTP', isCorrect: false },
      ],
      semanticKeywords: ['secure', 'sftp'],
      numericTolerance: 0,
      semanticThreshold: 0.8,
    },
    source: 'deterministic',
    interests: ['Technology & Engineering', 'Cybersecurity'],
  },
  // Science
  {
    id: 'q_sci_001',
    topic: 'Science & Nature',
    subtopic: 'Physics & Astronomy',
    tags: ['physics', 'constants'],
    difficulty: 'easy',
    type: 'numeric',
    text: 'What is the approximate speed of light in km/s? (to the nearest hundred thousand)',
    spokenPhrase: 'What is the approximate speed of light in kilometers per second? Round to the nearest 100,000.',
    answerSchema: {
      exact: '300000',
      aliases: ['three hundred thousand', '300,000'],
      choices: [],
      numericAnswer: 300000,
      numericTolerance: 5000,
      semanticKeywords: ['speed', 'light', '300000'],
      semanticThreshold: 0.8,
    },
    source: 'deterministic',
    interests: ['Science & Nature', 'Physics & Astronomy'],
  },
  {
    id: 'q_sci_002',
    topic: 'Science & Nature',
    subtopic: 'Biology & Medicine',
    tags: ['biology', 'cells'],
    difficulty: 'easy',
    type: 'short_answer',
    text: 'What is the powerhouse of the cell?',
    spokenPhrase: 'What is the powerhouse of the cell?',
    answerSchema: {
      exact: 'mitochondria',
      aliases: ['mitochondrion', 'the mitochondria'],
      choices: [],
      semanticKeywords: ['mitochondria', 'energy'],
      numericTolerance: 0,
      semanticThreshold: 0.8,
    },
    source: 'deterministic',
    interests: ['Science & Nature', 'Biology & Medicine'],
  },
  // History
  {
    id: 'q_hist_001',
    topic: 'Arts & Humanities',
    subtopic: 'World History',
    tags: ['history', 'wwii'],
    difficulty: 'medium',
    type: 'short_answer',
    text: 'In what year did World War II end?',
    spokenPhrase: 'In what year did World War Two end?',
    answerSchema: {
      exact: '1945',
      aliases: ['nineteen forty-five', 'nineteen 45'],
      choices: [],
      numericAnswer: 1945,
      numericTolerance: 0,
      semanticKeywords: ['1945'],
      semanticThreshold: 1.0,
    },
    source: 'deterministic',
    interests: ['Arts & Humanities', 'World History'],
  },
  // Business
  {
    id: 'q_biz_001',
    topic: 'Business & Economics',
    subtopic: 'Finance & Markets',
    tags: ['finance', 'investing'],
    difficulty: 'medium',
    type: 'short_answer',
    text: 'What does "IPO" stand for?',
    spokenPhrase: 'What does I-P-O stand for?',
    answerSchema: {
      exact: 'initial public offering',
      aliases: ['initial public offer'],
      choices: [],
      semanticKeywords: ['initial', 'public', 'offering'],
      numericTolerance: 0,
      semanticThreshold: 0.7,
    },
    source: 'deterministic',
    interests: ['Business & Economics', 'Finance & Markets'],
  },
  // Pop Culture
  {
    id: 'q_pop_001',
    topic: 'Pop Culture & Trivia',
    subtopic: 'Movies & TV',
    tags: ['movies', 'cinema'],
    difficulty: 'easy',
    type: 'short_answer',
    text: 'Who directed The Dark Knight?',
    spokenPhrase: 'Who directed The Dark Knight?',
    answerSchema: {
      exact: 'christopher nolan',
      aliases: ['nolan', 'chris nolan'],
      choices: [],
      semanticKeywords: ['nolan', 'christopher'],
      numericTolerance: 0,
      semanticThreshold: 0.8,
    },
    source: 'deterministic',
    interests: ['Pop Culture & Trivia', 'Movies & TV'],
  },
  {
    id: 'q_tech_004',
    topic: 'Technology & Engineering',
    subtopic: 'Data Science',
    tags: ['data', 'statistics'],
    difficulty: 'hard',
    type: 'short_answer',
    text: 'In machine learning, what term describes when a model performs well on training data but poorly on unseen data?',
    spokenPhrase: 'In machine learning, what term describes when a model performs well on training data but poorly on unseen data?',
    answerSchema: {
      exact: 'overfitting',
      aliases: ['over-fitting', 'over fitting'],
      choices: [],
      semanticKeywords: ['overfitting', 'generalization', 'variance'],
      numericTolerance: 0,
      semanticThreshold: 0.7,
    },
    source: 'deterministic',
    interests: ['Technology & Engineering', 'Data Science', 'Artificial Intelligence'],
  },
  {
    id: 'q_sci_003',
    topic: 'Science & Nature',
    subtopic: 'Chemistry',
    tags: ['chemistry', 'periodic_table'],
    difficulty: 'easy',
    type: 'short_answer',
    text: 'What is the chemical symbol for gold?',
    spokenPhrase: 'What is the chemical symbol for gold?',
    answerSchema: {
      exact: 'au',
      aliases: ['Au'],
      choices: [],
      semanticKeywords: ['au', 'gold'],
      numericTolerance: 0,
      semanticThreshold: 1.0,
    },
    source: 'deterministic',
    interests: ['Science & Nature', 'Chemistry'],
  },
];

// ═══════════════════════════════════════════════════════
// QUESTION GENERATION SERVICE
// ═══════════════════════════════════════════════════════

/**
 * Selects and returns questions filtered by user interests and difficulty.
 * Falls back to random selection if there aren't enough interest-matched questions.
 */
export function generateQuestions(request: QuestionGenerationRequest): ClientQuestion[] {
  const { interests, difficulty, count, excludeIds, topic } = request;

  let pool = QUESTION_BANK.filter(q => !excludeIds.includes(q.id));

  // Filter by topic if specified
  if (topic) {
    pool = pool.filter(q =>
      q.topic.toLowerCase().includes(topic.toLowerCase()) ||
      (q.subtopic?.toLowerCase() ?? '').includes(topic.toLowerCase()),
    );
  }

  // Score by interest overlap
  const scored = pool.map(q => {
    const overlap = interests.filter(i =>
      q.interests.some(qi => qi.toLowerCase().includes(i.toLowerCase()) || i.toLowerCase().includes(qi.toLowerCase())),
    ).length;
    const diffMatch = q.difficulty === difficulty ? 2 : q.difficulty === 'medium' ? 1 : 0;
    return { q, score: overlap * 3 + diffMatch + Math.random() };
  });

  scored.sort((a, b) => b.score - a.score);

  const selected = scored.slice(0, count).map(s => s.q);

  // If we still don't have enough, pad with any remaining questions
  if (selected.length < count) {
    const extras = pool.filter(q => !selected.includes(q)).slice(0, count - selected.length);
    selected.push(...extras);
  }

  return selected.map(toClientQuestion);
}

/**
 * Strips answerSchema from a Question before sending to the client.
 */
export function toClientQuestion(q: Question): ClientQuestion {
  const { answerSchema, ...rest } = q;

  // For multiple choice, include shuffled options without isCorrect
  const choices = q.type === 'multiple_choice'
    ? shuffleArray(answerSchema.choices.map(c => ({ id: c.id, text: c.text })))
    : undefined;

  return { ...rest, ...(choices ? { choices } : {}) };
}

/**
 * Looks up a stored question by ID (for server-side validation).
 * In production this would go to the DB; here it reads from the seed bank.
 */
export function getQuestionById(id: string): Question | null {
  return QUESTION_BANK.find(q => q.id === id) ?? null;
}

function shuffleArray<T>(arr: T[]): T[] {
  return [...arr].sort(() => Math.random() - 0.5);
}
