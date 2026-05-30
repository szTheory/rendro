---
phase: 74
phase_slug: statement-recipe
created: 2026-05-29
status: validated
nyquist_compliant: true
validated: 2026-05-30
---

# Phase 74 Validation Strategy

> Derived from RESEARCH.md "Validation Architecture" section.
> This file defines HOW the phase's success criteria will be validated.

## Validation Layers

- **Unit tests (ExUnit)** — the primary layer. The Statement recipe is pure
  data assembly + formatting, so its behavior is fully observable by inspecting
  the `%Rendro.Document{}` it builds and the paginated output of
  `Rendro.render/1`. No external services, no Chrome, no I/O.
- **Property/invariant tests** — page-count-vs-`ceil` and the running-balance
  fold are invariants that hold for arbitrary row counts; cover them with a
  small generated range of row counts (e.g. 0, 1, capacity−1, capacity,
  capacity+1, several pages) rather than relying on a single fixture.
- **Determinism check** — render the same statement twice and assert
  byte-identical output (the `deterministic: true` contract).

## Critical Behaviors to Validate

Mapped from RESEARCH.md V1–V10 to the four phase success criteria (STMT-01..04).

| # | Behavior | Type | Maps to |
|---|----------|------|---------|
| V1 | `document/2` returns a renderable `%Rendro.Document{}` from a data map alone (no template authoring) | Unit | STMT-01 |
| V2 | Multi-page statement: page count equals `ceil(rows / capacity)` | Unit/Property | STMT-02 |
| V3 | Carried-forward is the last body row of each non-final page | Unit | STMT-02 |
| V4 | Brought-forward is the first body row of each subsequent page | Unit | STMT-02 |
| V5 | Carried-forward suppressed on the last page; brought-forward suppressed on page 1 | Unit | STMT-02 |
| V6 | Running balance correct across page breaks (`opening + Σ amount`, Decimal fold) | Unit/Property | STMT-02 |
| V7 | "Page X of Y" appears in the footer on every page incl. the last, with correct Y | Unit | STMT-04 |
| V8 | Float amount rejected with an instructive `validate_data!/1` error | Unit | STMT-01 |
| V9 | Three-rung override consistency (`document/2` / `page_template/1` / `sections/2`) mirrors `Invoice` | Unit | STMT-03 |
| V10 | Decimal fold + `Rendro.Format` determinism — byte-identical render across runs | Unit | STMT-02 / cross-cutting |

Additional load-bearing checks (from D-09/D-10):
- **No `:content_overflow`** — render a statement whose row count straddles a
  page boundary and assert it succeeds (the recipe's conservative-capacity
  margin + engine-sourced measurement prevent off-by-one overflow).
- **No double-pagination / no stranded carried-forward row** — the recipe's
  pre-chunked groups are each ≤ `body_capacity`, so the engine never re-breaks
  mid-chunk.

## Test Data / Fixtures

- A small statement (single page) — opening balance, a handful of signed
  `Decimal` lines, derived closing balance.
- A multi-page statement — enough lines to force ≥3 pages, so carried/brought
  forward placement and suppression are observable on first / middle / last
  pages.
- Boundary row counts: 0 lines, exactly `capacity`, `capacity ± 1`.
- An invalid input (Float amount, missing required key, malformed `period`) for
  each `validate_data!/1` error path.

## Coverage Targets

- Every behavior V1–V10 has at least one dedicated test.
- All `validate_data!/1` error branches (missing required keys, non-`Decimal`
  amount, caller-supplied per-line `:balance`, malformed `period`) are exercised.
- The page-grouping invariant (D-10): page count matches `ceil`, and the
  first/last rows of every page carry the correct labels.
- Critical paths: the pagination chunking + balance fold in `sections/2`, and
  the D-09 measurement helper's agreement with the engine's own measurement.

## Out of Scope

- Receipt/Report and Certificate recipes (Phase 75).
- The reference Phoenix app (Phase 76).
- Any change to the engine's pagination *behavior* — PAGE-04 single-pass /
  no-convergence is preserved and is not re-validated here beyond confirming the
  new public measurement helper is a read-only projection.
- Locale/currency-aware formatting (the `:formatters` escape hatch is the
  supported i18n path; only the deterministic default formatter is validated).
- Conventional Debit/Credit display columns (deferred `:columns` ergonomic).

---

## Validation Audit 2026-05-30

Audited via `/gsd-validate-phase 74` (top-level workflow, run as part of phase 77 / plan 77-03). Coverage verified by execution — every behavior V1–V10 and the load-bearing D-09/D-10 checks have a dedicated describe block in `test/rendro/recipes/statement_test.exs` that runs green.

| Behavior | Maps to | Test (`statement_test.exs`) | Status |
|----------|---------|------------------------------|--------|
| V1 renderable Document from data map | STMT-01 | `describe "V1: ..."` (line 103) | ✅ green |
| V2 page count == ceil(rows/capacity) | STMT-02 | `describe "V2: multi-page page count"` (line 153) | ✅ green |
| V3/V4 carried/brought-forward placement | STMT-02 | `describe "V3/V4: ..."` (line 213) | ✅ green |
| V5 CF/BF suppression | STMT-02 | `describe "V5: ..."` (line 293) | ✅ green |
| V6 running balance across breaks (Decimal fold) | STMT-02 | `describe "V6: balance continuity ..."` (line 321) | ✅ green |
| V7 "Page X of Y" footer every page | STMT-04 | `describe "V7: ..."` (line 383) | ✅ green |
| V8 malformed input → instructive ArgumentError | STMT-01 | `describe "V8: validate_data!/1 rejects ..."` (line 430) | ✅ green |
| V9 three-rung override consistency | STMT-03 | `describe "V9: three-rung escape hatch"` (line 527) | ✅ green |
| V10 deterministic byte-identical render | STMT-02 | `describe "V10: ..."` (line 590) + `deterministic_test.exs` | ✅ green |
| No `:content_overflow` (D-09) | cross-cutting | `describe "load-bearing: no content_overflow"` (line 619) | ✅ green |
| Page-grouping invariant (D-10) | STMT-02 | `describe "page-grouping invariant (D-10)"` (line 644) | ✅ green |

| Metric | Count |
|--------|-------|
| Behaviors (V1–V10 + load-bearing) | 11 |
| COVERED (green) | 11 |
| MISSING | 0 |
| Gaps found | 0 |
| Tests generated | 0 (all coverage already present from execution) |

**Test run:** `mix test test/rendro/recipes/statement_test.exs test/rendro/deterministic_test.exs` → **3 properties, 64 tests, 0 failures**.

**Sign-off:** All V1–V10 behaviors and all `validate_data!/1` error branches have automated verification. `nyquist_compliant: true`. Approved 2026-05-30.
