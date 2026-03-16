# Question Generation and Validation

## Current State
The app currently delegates **all** question generation and validation logic directly to the live Gemini model via system instructions (`liveService.ts`). There is no structured question database, no generated payloads fetched before the round, no deterministic answer validation, and no structured grading taxonomy.

This violates production readiness:
- We cannot guarantee difficulty curves.
- We cannot verify model hallucination in grading.
- Answers are evaluated loosely in the prompt context.

## Required Architecture

### 1. Structured Question Object
Every question needs a rigid structure:
```ts
interface Question {
  id: string;
  topicId: string;
  difficulty: 'easy' | 'medium' | 'hard';
  type: 'short_answer' | 'multiple_choice';
  promptText: string;          // Full text for UI/transcript
  spokenPromptText: string;    // Concact/TTS optimized text
  canonicalAnswers: string[];  // Exact matches
  acceptableVariants: string[];// Known aliases
  validationStrategy: 'exact_match' | 'alias_match' | 'semantic';
  pointsValue: number;
}
```

### 2. Validation Pipeline
Validation must occur on the backend, not inside the raw conversational flow of the model unless explicitly required (semantic).
- Step 1: Client sends spoken answer.
- Step 2: Backend attempts deterministic validation (`exact_match` or `alias_match` against `canonicalAnswers`).
- Step 3: If deterministic fails but string distance is close, mark correct.
- Step 4: If distance is far but `validationStrategy === 'semantic'`, use off-session small AI call to grade concept match.
- Step 5: Backend updates score and round state, returns result to client.

### 3. Generation Approaches
Rounds should be pre-seeded. When a user requests a round on "Space":
1. Query `questions` collection in Firestore for curated questions.
2. If short, use an async backend function to structure-generate 5 questions immediately using AI, save them to the DB, and return them for the round. The Live Model is only responsible for *delivering* the questions and maintaining rapport, not spontaneously inventing them.
