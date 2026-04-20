---
name: strict-feature-build
description: >-
  Enforces ask-first planning, strict TDD, smallest-unit implementation,
  incremental execution, and skeptical verification. Use for non-trivial
  features, refactors, bugfixes, screens, UI, API or persistence integration,
  state changes, and non-trivial logic changes.
---

# Strict Feature Build

## When to use

- Feature work beyond a one-liner or obvious typo
- Non-trivial bug fixes
- Refactors that change structure or behavior
- UI/screens and layout-sensitive work
- API, persistence, or state changes
- Logic that affects correctness, security, or data integrity

## Instructions

1. **Do not start coding immediately.**
2. Identify ambiguities that materially affect architecture, UX, schema, state, naming, persistence, or tests.
3. **Ask clarifying questions** when more than one reasonable interpretation exists and the choice would change the outcome.
4. Break the work into the **smallest meaningful implementation units** (one concern per unit when practical).
5. For **each unit**, define before implementing:
   - Source file(s) to touch
   - Dedicated test file(s) (new or existing)
   - Likely **failure modes** (wrong assumptions, edge cases, races, partial failure)
   - **Exact verification command** (narrowest that exercises the unit)
6. Implement **one unit at a time**.
7. Create or update **dedicated tests** for that unit before claiming that unit is done.
8. Run the **narrowest relevant verification** immediately after the unit’s code and tests land.
9. After the command passes, do a short **verifier / QA-breaker** pass: try to break the change (see **Mandatory test depth**).
10. Only then move to the next unit.
11. Keep **commits small and scoped** to one unit or one coherent slice when using git.
12. **Never claim complete** unless code was actually run and verification succeeded (or gaps are explicitly listed).

## Mandatory test depth

Design and tests should deliberately stress:

- Edge cases and boundaries
- Empty / null / missing data
- Invalid or malformed input
- Large input or large collections (performance or correctness)
- Rapid repeated actions (double-submit, spam clicks, retried requests)
- Async ordering, cancellation, stale state, and race conditions
- Partial failures (timeouts, 4xx/5xx, network flakiness) where applicable
- Unusual UI sizes and layout states when UI is involved

## Output format (per unit)

After each unit, report using this structure:

```markdown
### Unit: [short name]

**Changed:** [files and brief what/why]

**Tests:** [test file paths]

**Command:** `[exact command]`

**Result:** [pass / fail; if fail, what broke]

**Unknown / follow-ups:** [explicit gaps, assumptions, or unanswered questions]
```

## Anti-patterns

- Implementing multiple units before any test or command runs
- “Done” without a command that was actually executed
- Decorative tests that only cover the happy path
- Guessing product or schema behavior instead of asking when ambiguity is material
