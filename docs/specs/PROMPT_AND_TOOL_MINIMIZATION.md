# Prompt and Tool Minimization

## System Prompt Optimization

### Before
`MIMZ_PERSONA` in `liveService.ts` was **43 lines** covering personality traits, context explanation, quiz behavior, vision behavior, and tool usage rules. This was redundant because the app-side `LiveSessionConfig` presets include mode-specific instructions.

### After
`MIMZ_PERSONA` trimmed to **15 lines** — covers only:
- Core identity ("charismatic AI game host")
- Universal rules (2-3 sentences max, always use tools, never fabricate state)
- Cross-mode tool usage patterns

Mode-specific behavior (quiz vs onboarding vs vision quest) stays in the app-side `LiveSessionConfig` presets, which are more targeted and contextual.

### Token Savings
- ~300 fewer input tokens per session setup
- For 50 sessions: ~15K tokens saved

## Tool Schema Compactness

The 15 tool declarations in `LIVE_TOOL_DECLARATIONS` are already well-structured:
- Short descriptions (1 sentence each)
- Minimal required fields
- Proper type annotations
- Defaults where sensible

**No changes needed** — the schemas are already production-quality.

## Tool Response Trimming

### Change
Added `toModelPayload()` in `executeLiveTool.ts` that strips the `message` field from tool responses before sending back to Gemini.

### Why
Every tool handler returns a human-readable `message` string (e.g., "Correct! +500 XP"). This is useful for the client UI but wastes tokens in the model's context window. The model should make decisions based on structured data (`isCorrect`, `pointsAwarded`, `streakBonus`) not prose.

### Example
```typescript
// Before: model receives
{ success: true, data: { isCorrect: true, pointsAwarded: 500, message: "Correct! +500 XP (+100 streak bonus!)" } }

// After: model receives (via toModelPayload)
{ success: true, data: { isCorrect: true, pointsAwarded: 500 } }
```

## Prompt Fragment Rules
1. Never repeat the persona in every tool response
2. Keep live turn context lean — no conversation history replay
3. Each mode preset is self-contained — no prompt inheritance chain
4. Tool descriptions are behavioral, not narrative
