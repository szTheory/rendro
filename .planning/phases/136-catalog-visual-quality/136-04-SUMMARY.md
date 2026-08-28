---
phase: 136-catalog-visual-quality
plan: "04"
subsystem: ticket-recipe
tags: [catalog, ticket, deterministic-rendering, semantic-ink, tdd]
requires:
  - phase: 136-01
    provides: generic dev-only presentation-profile selection
provides:
  - Atomic four-cell equal-share Aurora locator profile
  - Target-only dark secondary treatment for Ticket stub reference
affects: [136-05, 136-06]
tech-stack:
  added: []
  patterns: [generic presentation profile, atomic table cells, semantic palette roles, deterministic render comparison]
key-files:
  created: []
  modified:
    - dev/rendro/catalog.ex
    - lib/rendro/recipes/ticket.ex
    - test/rendro/recipes/ticket_test.exs
    - test/rendro/recipes/ticket_byte_identity_test.exs
decisions:
  - Ticket consumes only generic locator_layout: :atomic_equal_share, never catalog identity.
  - The dark target's human-readable stub reference uses existing muted semantic ink; placement values remain primary ink.
metrics:
  duration: 15m
  completed_date: 2026-08-28
status: complete
---

# Phase 136 Plan 04: Ticket locator clarity and dark semantics Summary

Aurora's A6 Ticket now preserves a single source-ordered equal-share locator with four atomic Section/GA, Row/H, Seat/24, and Gate/B cells, while dark target support facts use semantic secondary ink without geometry changes.

## Tasks Completed

1. **Render the Aurora locator as four atomic, directly associated equal-share cells**
   - Added a generic `:atomic_equal_share` profile that wraps only target locator cells in explicit atomic `Rendro.Cell` boundaries.
   - Corrected the existing dev-only Ticket profile value to the plan's generic contract, leaving catalog identity outside the recipe.
   - Commits: `625acb4`, `4fab4e2`.

2. **Prove light/dark geometry parity and readable muted dark semantics**
   - Routed the target dark stub reference through the existing muted semantic role, while keeping locator values on primary ink and preserving rules, labels, terms, A6 geometry, and `print_safety: false` scope.
   - Added light/dark locator geometry and two-render deterministic tests with registered Brutalist fonts.
   - Commits: `373c9df`, `54d7589`.

## Verification

- `mix test test/rendro/recipes/ticket_test.exs test/rendro/recipes/ticket_byte_identity_test.exs --max-failures 1` — PASS (39 tests)
- `mix format --check-formatted` — PASS
- `mix ci.fast` — PASS

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Corrected the dev-only Ticket profile name from `:one_row_clear` to `:atomic_equal_share`**
   - **Found during:** Task 1
   - **Issue:** Plan 01's already-committed target map used a generic value that did not match this plan's required recipe contract.
   - **Fix:** Updated only the two allowed Ticket profile values in dev catalog tooling; the recipe still receives generic profile data only.
   - **Files modified:** `dev/rendro/catalog.ex`
   - **Commit:** `4fab4e2`

2. **[Rule 1 - Bug] Used explicit cell atomicity instead of table-level atomicity**
   - **Found during:** Task 1
   - **Issue:** `Rendro.table/2` normalizes its temporary `:atomic` table alias to `:row_atomic`, which does not express per-token protection.
   - **Fix:** Wrapped the profile-active label/value cells in `Rendro.Cell` values with `split_policy: :atomic`.
   - **Files modified:** `lib/rendro/recipes/ticket.ex`, `test/rendro/recipes/ticket_test.exs`
   - **Commit:** `4fab4e2`

3. **[Rule 1 - Bug] Registered Brutalist fonts before deterministic themed renders in the new test**
   - **Found during:** Task 2
   - **Issue:** The recipe returns logical preset fonts, while direct test rendering requires the existing preset registration seam used by catalog tooling.
   - **Fix:** Registered existing Brutalist fonts inside the test before each render.
   - **Files modified:** `test/rendro/recipes/ticket_byte_identity_test.exs`
   - **Commit:** `54d7589`

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all four task-owned files exist.
- Confirmed task commits `625acb4`, `4fab4e2`, `373c9df`, and `54d7589` exist in Git history.
