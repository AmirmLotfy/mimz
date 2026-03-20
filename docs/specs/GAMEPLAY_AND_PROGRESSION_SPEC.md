# Gameplay And Progression Spec

Last updated: 2026-03-18

## Core Loop

1. Enter live play (quiz or vision).
2. Receive concise spoken challenge.
3. Answer via voice (or camera input for vision).
4. Backend validates and grants outcome.
5. Results screen explains rewards.
6. District visibly updates in world map.
7. Player chooses next action (continue, event, squad, world).

## Challenge Types

- Short factual
- Multiple-choice voiced
- Open short answer
- Visual quest
- Rapid fire chain
- Higher-value challenge
- Hint-enabled challenge

## Scoring and Reward Variables

- `correctness`
- `responseLatency`
- `currentStreak`
- `comboWindow`
- `difficultyTier`
- `eventMultiplier`
- `squadContributionMultiplier`
- anti-abuse caps (hourly and per-round)

## Reward Logic (Backend Authoritative)

- Correct answer:
  - base score + materials
  - sector growth chance/amount by mode and tier
- Incorrect answer:
  - no harsh punishment; small consolation progression allowed if configured
- Streak/combo:
  - increasing material and score multipliers
- Event bonus:
  - temporary additive multiplier
- Squad bonus:
  - contribution credit + optional team pool bonus
- Structure unlock:
  - threshold based on cumulative sectors/material milestones
- Live tool execution requires a valid backend-issued session id; stale/foreign sessions must be rejected server-side.

## Fairness Rules

- No hidden random heavy penalties.
- Reward explanations must be shown on result screen.
- Caps and balancing logic documented and server-enforced.
- Client cannot unilaterally mutate persisted progression.

## Result Screen Contract

- Always show:
  - correctness summary
  - score delta
  - materials delta
  - sector delta
  - streak impact
- CTA:
  - claim rewards (server call)
  - retry if claim fails
  - no silent success on failed claim
- If live round transport fails, show explicit recovery actions without losing confirmed progress.

## Squad/Event Progression

- Every reward can optionally contribute:
  - squad weekly progress
  - active event objective progress
- Contribution feedback shown in-session and in result summary.

## Retention Hooks

- Session streak reminders
- Structure unlock progression meter
- Event windows and squad goals surfaced on world/home
- Daily meaningful target achievable in <10 minutes
