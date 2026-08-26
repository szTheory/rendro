---
phase: 130-catalog-quality-evidence-ratchet
plan: "01"
subsystem: recipes
tags: [elixir, rendro, themes, pagination, byte-identity]
requires:
  - phase: 129
    provides: fixed catalog, theme presets, and frozen recipe byte contracts
provides:
  - Public supplied-theme Receipt semantic cells shared by measurement and rendering
  - Compact Invoice Total Due and due-date hierarchy on the ordinary themed path
  - Minimal-Mono Statement closing-band whitespace refinement with catalog parity
affects: [130-02, 130-03, catalog-quality-evidence]
tech-stack:
  added: []
  patterns:
    - Materialize themed table cells once and reuse them for measure/render inputs
    - Keep nil-theme recipe bytes frozen while theming adjusts hierarchy tokens
key-files:
  created: []
  modified:
    - lib/rendro/recipes/receipt.ex
    - lib/rendro/recipes/invoice.ex
    - lib/rendro/recipes/statement.ex
    - test/rendro/recipes/receipt_test.exs
    - test/rendro/recipes/receipt_typography_test.exs
    - test/rendro/recipes/invoice_test.exs
    - test/rendro/recipes/statement_test.exs
key-decisions:
  - "Receipt receives structured semantic cells only when a theme is supplied; nil-theme cell literals remain untouched."
  - "A themed Invoice moves an available due date beside Total Due only when that payment fact exists; otherwise it remains in the header."
  - "Statement catalog_layout continues to vary header capacity only; public themed and catalog calls share closing-balance hierarchy."
patterns-established:
  - "Use theme semantic colors and metric-font registration in both table measurement and rendering."
  - "Use zero-height path overlays for restrained themed arithmetic backdrops without changing flow."
requirements-completed: [CATALOG-06, CATALOG-07]
coverage:
  - id: D1
    description: Receipt uses public Humanist semantic cells, muted footer labels, and a zero-flow totals backdrop.
    requirement: CATALOG-07
    verification:
      - kind: unit
        ref: mix test test/rendro/recipes/receipt_test.exs test/rendro/recipes/receipt_typography_test.exs test/rendro/recipes/receipt_byte_identity_test.exs --max-failures 1
        status: pass
    human_judgment: false
  - id: D2
    description: Corporate-Classic Invoice presents Total Due before its complete adjacent due date on the public themed path.
    requirement: CATALOG-06
    verification:
      - kind: unit
        ref: mix test test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_typography_test.exs test/rendro/recipes/invoice_byte_identity_test.exs --max-failures 1
        status: pass
    human_judgment: false
  - id: D3
    description: Minimal-Mono Statement retains a full-width public closing-balance band with isolated mono focal value.
    requirement: CATALOG-06
    verification:
      - kind: unit
        ref: mix test test/rendro/recipes/statement_test.exs test/rendro/recipes/statement_typography_test.exs test/rendro/recipes/statement_byte_identity_test.exs --max-failures 1
        status: pass
    human_judgment: false
duration: 11m 28s
completed: 2026-08-20
status: complete
---

# Phase 130 Plan 01: Public Theme Recipe Hierarchy Summary

**Public supplied-theme Receipt, Invoice, and Statement hierarchy repairs with unchanged no-theme byte identities.**

## Performance

- **Duration:** 11m 28s
- **Started:** 2026-08-20T00:57:02Z
- **Completed:** 2026-08-20T01:02:10Z
- **Tasks:** 3/3
- **Files modified:** 7

## Accomplishments

- Receipt now materializes the same Humanist semantic table cells for metric measurement and rendering, with themed metric-font registration, muted footer pagination, and a restrained zero-flow totals surface/rule overlay.
- Invoice retains its no-theme layout while moving a supplied-theme due date directly after the display-scale Total Due payment fact.
- Statement preserves its austere full-width closing band and mono focal value while adding supplied-theme whitespace from the preset token; catalog layout remains capacity-only.

## Task Commits

1. **Task 1: Carry Humanist Receipt semantics through measure, paginate, and render** — `f1213df` (RED test), `d75e72b` (GREEN implementation)
2. **Task 2: Make Corporate-Classic Invoice read Total Due before due date** — `3319daf` (RED test), `8250056` (GREEN implementation)
3. **Task 3: Sharpen Minimal-Mono Statement closing balance without changing its genre** — `ee78ea3` (RED test), `8fa8d0a` (GREEN implementation), `4f593dc` (formatting)

## Files Created/Modified

- `lib/rendro/recipes/receipt.ex` — structured themed cells, metric measurement context, muted footer, and totals overlay.
- `lib/rendro/recipes/invoice.ex` — themed payment-summary adjacency without nil-theme drift.
- `lib/rendro/recipes/statement.ex` — theme-token closing-band whitespace while preserving public/capacity boundaries.
- `test/rendro/recipes/receipt_test.exs` and `test/rendro/recipes/receipt_typography_test.exs` — Receipt semantic and hierarchy contracts.
- `test/rendro/recipes/invoice_test.exs` — Corporate-Classic payment-order contract.
- `test/rendro/recipes/statement_test.exs` — Minimal-Mono public/catalog hierarchy contract.

## Decisions Made

- **D-26 engineering checkpoint:** Engineering checkpoint — not a human-quality disposition.
- **D-19 engineering checkpoint:** Deterministic hierarchy contracts remain non-promotional and do not alter score, sign-off, disposition, or catalog evidence authority.
- The `catalog_layout` Statement branch remains limited to demonstrated header capacity; it does not select a separate hierarchy or visual branch.

## Verification

- `mix test test/rendro/recipes/receipt_test.exs test/rendro/recipes/receipt_typography_test.exs test/rendro/recipes/receipt_byte_identity_test.exs --max-failures 1` — pass (56 tests).
- `mix test test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_typography_test.exs test/rendro/recipes/invoice_byte_identity_test.exs --max-failures 1` — pass (59 tests).
- `mix test test/rendro/recipes/statement_test.exs test/rendro/recipes/statement_typography_test.exs test/rendro/recipes/statement_byte_identity_test.exs --max-failures 1` — pass (62 tests).
- Combined nine-suite command — pass (177 tests).
- `mix format --check-formatted` for changed recipe and test files — pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the Receipt path assertion to inspect its enclosing block.**
- **Found during:** Task 1
- **Issue:** The initial red test treated `height` as a `Rendro.Path` field rather than the enclosing `Rendro.Block` layout field.
- **Fix:** Asserted the block/path nesting used by `Rendro.path/2`.
- **Files modified:** `test/rendro/recipes/receipt_test.exs`
- **Verification:** Receipt focused suite passed.

**2. [Rule 1 - Bug] Moved a keyword lookup out of an Elixir guard.**
- **Found during:** Task 1
- **Issue:** `opts[:theme]` expands through `Access.get/2`, which cannot be invoked in a guard.
- **Fix:** Performed the theme decision inside `totals_overlay/2`.
- **Files modified:** `lib/rendro/recipes/receipt.ex`
- **Verification:** Receipt focused suite passed.

**3. [Rule 1 - Bug] Added the date formatter to Invoice totals composition.**
- **Found during:** Task 2
- **Issue:** The themed due-date relocation needed the existing date formatter in `build_totals_blocks/2`.
- **Fix:** Resolved it through the recipe’s existing pagination formatter seam.
- **Files modified:** `lib/rendro/recipes/invoice.ex`
- **Verification:** Invoice focused suite passed.

**Total deviations:** 3 auto-fixed (Rule 1: 3).
**Impact on plan:** Correctness-only fixes within the owned recipe/test files; no public API, dependency, preset, catalog, evidence, score, or disposition changes.

## Known Stubs

None.

## Issues Encountered

The first Statement red assertion already passed because the existing band stroke already used the preset thin-rule token. It was tightened to cover the missing supplied-theme whitespace token before the implementation proceeded.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The three Wave-1 public theme repairs are deterministic and byte-identity-protected. Subsequent catalog/payload plans can consume these recipe bytes without treating the engineering checks as human-review evidence.

## Self-Check: PASSED

- All seven changed recipe/test files exist.
- Task commits `f1213df`, `d75e72b`, `3319daf`, `8250056`, `ee78ea3`, `8fa8d0a`, and `4f593dc` exist in git history.

---

*Phase: 130-catalog-quality-evidence-ratchet*
*Completed: 2026-08-20*
