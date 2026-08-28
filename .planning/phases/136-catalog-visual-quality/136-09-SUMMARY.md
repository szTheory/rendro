---
phase: 136-catalog-visual-quality
plan: "09"
subsystem: catalog-quality
tags: [elixir, deterministic-rendering, json-schema, tdd, catalog]

requires:
  - phase: 136-08
    provides: gap-closure plan and locked six-target catalog scope
provides:
  - Exact byte-derived six-target and 26-control catalog partition independent of review status
  - Profile-gated Ticket locator header treatment with frozen default behavior
  - Closed dark-unscored print-safety scope metadata without reviewer authority
affects: [catalog-candidate-evidence, visual-review, rubric-contracts]

actuals:
  tokens: 6109
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - Canonical full-hash partitions are authoritative while review buckets remain descriptive
    - Unscored dark print-safety metadata is closed, explicit, and separate from reviewer evidence

key-files:
  created:
    - .planning/phases/136-catalog-visual-quality/deferred-items.md
  modified:
    - dev/rendro/catalog.ex
    - lib/rendro/recipes/ticket.ex
    - priv/schemas/rubric_scores.schema.json
    - priv/quality/rubric_scores.json
    - test/fixtures/quality/rubric_scores_phase130_non_prose.json
    - test/rendro/catalog_test.exs
    - test/rendro/recipes/ticket_test.exs
    - test/docs_contract/rubric_manifest_contract_test.exs

key-decisions:
  - "Complete PDF/PNG inequality in canonical order determines changed_targets; scored/unscored buckets cannot authorize candidate scope."
  - "Top-level print_safety:false on an unscored dark disposition is scope-boundary metadata only, never a review score, approval, or support claim."
  - "The Ticket semantic surface fill exists only behind locator_layout: :atomic_equal_share; omitted and unrelated profiles preserve prior bytes."

patterns-established:
  - "Exact candidate scope: compare complete hashes, require exact ordered allowlist membership, and validate descriptive bucket union separately."
  - "Evidence authority separation: unscored records carry reasons and narrow scope boundaries but no score, gate, signer, justification, or promotion fields."

requirements-completed: [CATALOG-10, CATALOG-12]

coverage:
  - id: D1
    description: Real catalog rendering produces exactly the locked six changed targets and 26 byte-stable controls in canonical order, independent of reviewer status.
    requirement: CATALOG-10
    verification:
      - kind: integration
        ref: "test/rendro/catalog_test.exs#real catalog exact-six and candidate scope contracts"
        status: pass
    human_judgment: false
  - id: D2
    description: Ticket light and dark atomic locator profiles receive a real semantic header treatment while default geometry and bytes remain frozen.
    requirement: CATALOG-10
    verification:
      - kind: unit
        ref: "test/rendro/recipes/ticket_test.exs#atomic locator header fill and geometry contracts"
        status: pass
    human_judgment: false
  - id: D3
    description: Every dark unscored disposition explicitly carries false print-safety scope metadata without acquiring reviewer-owned evidence.
    requirement: CATALOG-12
    verification:
      - kind: integration
        ref: "test/docs_contract/rubric_manifest_contract_test.exs#dark unscored print safety schema contracts"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-08-28
status: complete
---

# Phase 136 Plan 09: Exact Catalog Scope and Dark Print Boundary Summary

**Exact six-target catalog classification now comes from complete rendered hashes, both Ticket targets have a bounded real treatment, and all dark dispositions state non-print-safe truth without manufacturing review authority.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-08-28T19:10:39Z
- **Completed:** 2026-08-28T19:24:13Z
- **Tasks:** 2
- **Files modified:** 8 production/test files

## Accomplishments

- Made canonical `diff.changed_targets` the exact reviewer-independent scope authority and covered five-, seven-, reordered-, changed-control-PDF-, and changed-control-PNG failure boundaries.
- Added a profile-gated semantic header fill to the existing one-row atomic Ticket locator table, giving both locked Ticket targets a real rendered delta while preserving omitted-profile bytes and geometry.
- Required `print_safety: false` on exactly seven dark unscored records in both durable manifests, while the closed schema rejects missing/non-false values and all reviewer-owned fields on unscored dispositions.

## Task Commits

Each TDD task was committed as a RED/GREEN pair:

1. **Task 1 RED: exact catalog scope contracts** - `1cefa14` (test)
2. **Task 1 GREEN: reviewer-independent scope and Ticket treatment** - `349aac2` (feat)
3. **Task 2 RED: dark print-safety contracts** - `7771543` (test)
4. **Task 2 GREEN: explicit dark print-safety scope** - `c1bdcfd` (feat)

## Files Created/Modified

- `dev/rendro/catalog.ex` - Derives canonical changed targets from complete PDF/PNG inequality and validates exact ordered scope separately from descriptive review buckets.
- `lib/rendro/recipes/ticket.ex` - Adds the atomic-profile-only locator table header treatment.
- `priv/schemas/rubric_scores.schema.json` - Closes dark-unscored print-safety metadata and prohibits reviewer-owned fields for all unscored records.
- `priv/quality/rubric_scores.json` - Adds explicit false values to the seven dark unscored dispositions.
- `test/fixtures/quality/rubric_scores_phase130_non_prose.json` - Mirrors the seven scope-boundary values without adding scored prose.
- `test/rendro/catalog_test.exs` - Covers real 32-cell rendering, exact six/26 scope, advisory-state independence, and explicit dark boundaries.
- `test/rendro/recipes/ticket_test.exs` - Freezes locator geometry/default bytes and verifies the semantic header treatment.
- `test/docs_contract/rubric_manifest_contract_test.exs` - Validates both manifests and rejects missing, non-false, or reviewer-bearing unscored records.
- `.planning/phases/136-catalog-visual-quality/deferred-items.md` - Records the pre-existing repository-hygiene blocker for the aggregate CI alias.

## Decisions Made

- Complete deterministic PDF/PNG hashes and canonical membership are the sole candidate-scope authority. Review status is retained only as truthful descriptive metadata.
- An unscored dark record's top-level false value is a narrow scope boundary; it does not imply visual review, promotion, accessibility, PDF/UA, viewer support, or print support.
- The existing Ticket table structure remains unchanged; only the locked atomic locator profile receives the new semantic surface option.

## Deviations from Plan

None - plan behavior and file scope were implemented as specified.

## Issues Encountered

- `dev/rendro/catalog.ex` already contained overlapping Phase 136 candidate/evidence workflow logic. The implementation was surgical: it preserved that surrounding workflow and changed only the exact diff classifier and scope validation required by this plan.
- `mix ci.fast` stops in its pre-existing `quality.hygiene` stage because `.planning/todos/pending/2026-08-28-unify-catalog-recipe-visual-design-system.md` is outside an active phase or milestone archive. Commit `744b8d3` and the file predate this plan's starting HEAD. The remaining CI-fast stages were run directly and passed: Hex package build, warnings-as-errors compilation, 1,989 non-quarantined tests plus 12 doctests and 8 properties, ExDoc warnings-as-errors, Credo strict, and Dialyzer. The limitation is recorded in `deferred-items.md` and `.planning/WINDOWS.md`.

## Verification

- `mix test test/rendro/catalog_test.exs test/rendro/recipes/ticket_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1` - 139 tests, 0 failures.
- `mix format --check-formatted` - passed.
- Manifest facts - 32 dispositions, 20 unscored, 7 dark-unscored explicit false values, and 0 light records with top-level print-safety metadata.
- Remaining `mix ci.fast` stages executed individually - all passed; aggregate alias remains blocked only by the pre-existing planning-placement issue above.

## Known Stubs

None. Added nil assertions freeze the intentionally absent table option on default/unrelated Ticket profiles; they are contract checks, not rendered-data stubs.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The deterministic catalog scope and dark boundary are ready for a fresh candidate/evidence run.
- The owning workflow should move or archive the pre-existing pending TODO, then rerun `mix ci.fast` to clear the aggregate hygiene gate.

## Self-Check: PASSED

- All eight plan-owned production/test files exist.
- RED/GREEN commits `1cefa14`, `349aac2`, `7771543`, and `c1bdcfd` exist in repository history.
- The realized production diff touches only the eight files declared by Plan 136-09.

---
*Phase: 136-catalog-visual-quality*
*Completed: 2026-08-28*
