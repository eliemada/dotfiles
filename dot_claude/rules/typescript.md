---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript / JavaScript

- Use the project's package manager and scripts (check the lockfile: bun, pnpm, npm).
- Strict types: avoid `any`; prefer `unknown` and narrow it. Validate external data with
  the project's schema library (zod etc.) at the boundary.
- Prefer immutable updates (spread, `map`/`filter`) over mutating shared objects/state.
- Run the project's typecheck, lint and tests after changes and report the result.
