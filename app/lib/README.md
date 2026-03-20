# App Lib Index

`app/lib` is organized around product features first, then shared app infrastructure.

## Main Areas

- `features/`
  Feature-owned UI, providers, application logic, and data flow.
- `core/`
  App-wide lifecycle, guards, and foundational runtime behavior.
- `data/`
  Shared models and repositories used across features.
- `design_system/`
  Tokens, components, theme primitives, and reusable visual building blocks.
- `routing/`
  App navigation and route gating.
- `services/`
  Cross-cutting integrations such as API, auth, connectivity, audio, and push.

## Feature Layout

Most feature folders follow a consistent split:

- `presentation/`
- `providers/`
- `application/`
- `domain/`
- `data/`

Not every feature uses every layer yet, but that is the intended shape.
