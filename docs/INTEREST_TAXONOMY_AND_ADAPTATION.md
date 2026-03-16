# Interest Taxonomy & Adaptation

## The Problem
"Do not collect interests without using them." Currently, the backend accepts an array of strings for interests but operates completely flatly. It relies on the Gemini model reading array values during live sessions blindly.

## Taxonomy Structure
We need a standardized JSON catalog or database structure containing categories and selectable tags. Ex:

```json
[
  {
    "categoryId": "tech",
    "label": "Technology & Coding",
    "tags": ["Software Engineering", "AI", "Hardware", "Startups"]
  },
  {
    "categoryId": "humanities",
    "label": "History & Arts",
    "tags": ["World History", "Literature", "Design", "Architecture"]
  }
]
```

## How It Will Be Used
1. **Onboarding**: The `InterestSelectionScreen` dynamically renders the taxonomy grid. Users select tags.
2. **Profile Storage**: Stored as normalized IDs (`tech_ai`, `hum_history`).
3. **Gameplay Adaptation**:
   - When calling `start_live_round`, the backend weights the probability of question topics based on the intersection of the user's `coreInterests` and the daily event/domain pool.
   - If User A chose "Software Engineering", their random questions bias 30% towards coding trivia even in freeplay mode.
4. **Persona Adaptation**: The system prompt injected into Gemini Live is appended with user context: "The user is studying Software Engineering. Frame analogies using tech concepts when applicable."
