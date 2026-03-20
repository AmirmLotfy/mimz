# Backend Source Index

`backend/src` is organized by runtime responsibility.

## Main Areas

- `config/`
  Environment parsing, model selection, and configuration helpers.
- `lib/`
  Shared infrastructure, database helpers, and low-level integrations.
- `middleware/`
  Auth and request-level enforcement.
- `models/`
  Domain types, schemas, and shared backend contracts.
- `modules/`
  Larger capability modules such as live-session orchestration and tool execution.
- `routes/`
  HTTP route registration by surface area.
- `services/`
  Business logic and state mutation engines used by routes/modules.

## Rule Of Thumb

- Keep request wiring in `routes/`
- Keep authoritative game logic in `services/`
- Keep live-agent orchestration in `modules/live/`
- Keep shared contracts in `models/`
