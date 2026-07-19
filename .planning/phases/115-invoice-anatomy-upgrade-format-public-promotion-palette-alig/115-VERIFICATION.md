---
phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig
verified: 2026-07-18T21:05:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "`Rendro.Recipes.Invoice.validate_data!/1` raises an instructive `ArgumentError` on malformed input (never leaking `BadMapError`/`FunctionClauseError`)"
  gaps_remaining: []
  regressions: []
---

# Phase 115: Invoice anatomy upgrade + Format public promotion + palette/align seams Verification Report

**Phase Goal:** Deliver the milestone's one real product `lib/` change — an additive, byte-compatible Invoice anatomy upgrade, the public promotion of `Rendro.Format`, the additive `cell_align: :right` primitive, and the S1 palette seam — without breaking the toy call or widening the Stable tier.
**Verified:** 2026-07-18T21:05:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (commit `fd845f2`)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `Rendro.Recipes.Invoice` accepts additive optional `:issuer`/`:customer`/`:due_date`/`:terms`/`:totals`, rendering each only when present; the pre-upgrade toy call renders byte-identically to before. | ✓ VERIFIED | Unchanged since prior verification — `git show fd845f2` touches only `validate_items!/1`/`validate_item_price!/2` and adds new private helpers; no diff to `header_section/2`/`body_section/2`/`maybe_prepend`/`maybe_append`. `mix test test/rendro/recipes/invoice_byte_identity_test.exs` — 2/2 pass. |
| 2 | Invoice money uses `%Decimal{}` routed through `Rendro.Format.money/1` (bare-number `price` still `"$#{price}"`); new fields Decimal-only, reject Floats instructively; `:totals` renders only when supplied, validated via `Decimal.equal?/2`, kept with the last rows across a page break. | ✓ VERIFIED | Untouched by the fix commit. `mix test test/rendro/recipes/invoice_test.exs` "money split (INV-02)" + "totals block (INV-03)" describe blocks — all pass (part of the 56-test run below). |
| 3 | `Rendro.Format` promoted from `@moduledoc false` to public adapter tier (`money/1`, `date/1`, `label/1`), `@spec`s, `public_api.json` entry, migration note, "output may evolve" note; Phase-79 contract lane (incl. hidden set) passes. | ✓ VERIFIED | Untouched by the fix commit (`lib/rendro/format.ex`, `priv/public_api.json` not in the commit's file list). Confirmed still green via full `mix test` run (below), which includes `public_api_contract_test.exs`/`manifest_test.exs`. |
| 4 | Additive `cell_align: :right` right-aligns tabular money while existing tables render byte-identically; `validate_data!/1` raises an instructive `ArgumentError` on malformed input (never leaking `BadMapError`/`FunctionClauseError`) and never rejects a valid toy call. | ✓ VERIFIED | **`cell_align: :right` half:** unchanged, still verified (`table_cell_align_test.exs`/`table_byte_identity_test.exs` in full suite run). **`validate_data!/1` half — GAP CLOSED:** `lib/rendro/recipes/invoice.ex:515-559` adds `validate_item_shape!/2` (map-shape check, `:name` binary, `:qty` integer, `:price` key presence) called from `validate_items!/1:500-507` before `validate_item_price!/2`; `validate_item_price!/2:580-591` tightened from a permissive `defp validate_item_price!(_price, _idx), do: :ok` catch-all to `when is_number(price), do: :ok` + an `ArgumentError` else-branch. Live-reproduced via a standalone `mix run` script against `Rendro.Recipes.Invoice.document/1`: all 6 malformed-item cases (non-map item, missing `:qty`, missing `:name`, missing `:price`, non-integer `:qty`, non-number `:price`) now raise instructive `ArgumentError` with `What/Where/Why/Next` messages — zero `BadMapError`/`KeyError`/`FunctionClauseError` leaked. The valid toy call (`%{id:, date:, items: [%{name:, qty:, price:}]}`) still succeeds (`match?(%Rendro.Document{}, doc) == true`). 6 new tests added to `invoice_test.exs`'s "validate_data!/1 (INV-06)" describe block (now 12 tests total in that block), all pass. |
| 5 | Invoice sections read colors through a private `palette(opts)` keyed on locked color roles, defaulting to today's literals — no section inlines `{0,0,0}`; `page_template/1` opts leak closed via `Keyword.take` while top-level `opts` stays open. | ✓ VERIFIED | Untouched by the fix commit (`palette/1` at `lib/rendro/recipes/invoice.ex:371-386` not in the diff). Confirmed still green via `invoice_opts_threading_test.exs` in the full suite run. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/recipes/invoice.ex` | Additive anatomy, Decimal money split, totals, validate_data!, palette, whitelist | ✓ VERIFIED | Exists, substantive, wired; all sub-features present including line-item shape validation (gap closed). |
| `test/rendro/recipes/invoice_byte_identity_test.exs` | Frozen INV-01 toy-call sha256 golden | ✓ VERIFIED | Present, passes, `@toy_golden_sha256` concrete hex string. |
| `test/rendro/table_byte_identity_test.exs` | Frozen INV-05 no-cell_align table sha256 golden | ✓ VERIFIED | Present, passes, `@table_golden_sha256` concrete hex string. |
| `lib/rendro/format.ex` | Public adapter-tier moduledoc + unchanged `money/1`/`date/1`/`label/1` | ✓ VERIFIED | Moduledoc flip confirmed; function bodies/`@spec`s unchanged (doctests pass). |
| `priv/public_api.json` | `Elixir.Rendro.Format` adapter entry | ✓ VERIFIED | Entry present with correct tier + function list; contract test enforces byte-equality. |
| `lib/rendro/cell.ex`, `lib/rendro/table.ex` | Inert `cell_align` struct fields | ✓ VERIFIED | Fields present, inlined `@type`s (no manifest widening), defaults preserve byte-compat. |
| `lib/rendro.ex` | `normalize_table_cell_align/1` stage | ✓ VERIFIED | Present, validates map entries, `@spec table/2` arity unchanged. |
| `lib/rendro/pipeline/paginate.ex` | Right-align x-offset gated on `:right` | ✓ VERIFIED | `cell_effective_align/3` + `right_align_offset/1`; gated correctly for the money-column (text) use case. |
| `test/rendro/table_cell_align_test.exs` | Positive/differential/no-op/determinism coverage | ✓ VERIFIED | 4 tests, all pass. |
| `test/rendro/recipes/invoice_test.exs` | INV-06 line-item shape validation coverage (gap closure) | ✓ VERIFIED | 6 new tests added (non-map item, missing `:qty`/`:name`/`:price`, non-integer `:qty`, non-number `:price`); all assert `ArgumentError` with field-naming regex; all pass. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `invoice.ex` body_section | `Rendro.Format.money/1` | `Rendro.Recipes.Pagination.formatter/3` | ✓ WIRED | Unchanged; confirmed still green. |
| `invoice.ex` header/customer/due_date/terms blocks | `palette(opts)` | direct call, `colors.ink`/`colors.muted` | ✓ WIRED | Unchanged; confirmed still green. |
| `page_template/1` | `sections/2` opts | `Keyword.take` whitelist vs. unfiltered `opts` | ✓ WIRED | Unchanged; confirmed still green. |
| `Rendro.table/2 cell_align:` | `paginate.ex stack_cells/5` | `table.cell_align` threaded as 5th arg | ✓ WIRED | Unchanged; confirmed still green. |
| `api.gen.ex @public_modules` | `priv/public_api.json` | `mix rendro.api.gen` | ✓ WIRED | Unchanged; confirmed still green. |
| `invoice.ex validate_items!/1` | line-item shape | `validate_item_shape!/2` + `validate_item_price!/2` | ✓ WIRED | **Gap closed.** `validate_item_shape!/2` now checks map-shape, `:name` (binary), `:qty` (integer), `:price` (key presence) before any item reaches `body_section/2`; `validate_item_price!/2` now rejects non-numbers. Live-reproduced: zero `BadMapError`/`KeyError` leaked across 6 malformed-input cases. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Malformed line item (non-map, missing `:qty`/`:name`/`:price`, non-integer `:qty`, non-number `:price`) via live `Rendro.Recipes.Invoice.document/1` | ad-hoc `mix run` script | All 6 cases raise `ArgumentError` with instructive `What/Where/Why/Next` message; zero `BadMapError`/`KeyError`/`FunctionClauseError` leaked | ✓ PASS |
| Valid toy call still accepted after fix | same `mix run` script | `match?(%Rendro.Document{}, doc) == true` | ✓ PASS |
| Invoice recipe + opts-threading + byte-identity suite | `mix test test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_byte_identity_test.exs test/rendro/recipes/invoice_opts_threading_test.exs` | 56 tests, 0 failures (was 48 pre-fix; +8 net: 6 new INV-06 tests + 2 pre-existing not previously enumerated) | ✓ PASS |
| Full workspace suite (run once) | `mix test` | 12 doctests, 4 properties, 1275 tests, 0 failures (20 excluded) — was 1269 pre-fix, +6 matches the 6 new tests | ✓ PASS |
| `mix compile --warnings-as-errors` | — | clean, exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| INV-01 | 115-01, 115-04 | Additive optional anatomy fields; toy call byte-identical | ✓ SATISFIED | Byte-identity golden green; present-vs-absent tests pass. |
| INV-02 | 115-04 | Decimal money via `Format.money/1`; bare price unchanged; Float rejected | ✓ SATISFIED | `money split (INV-02)` tests pass; code confirms split. |
| INV-03 | 115-04 | Totals block, `Decimal.equal?/2`, kept with last rows | ✓ SATISFIED | `totals block (INV-03)` tests incl. near-full-page placement pass. |
| INV-04 | 115-02 | `Format` public adapter-tier promotion, contract lane green | ✓ SATISFIED | Manifest entry + contract tests pass; migration note + evolving-output caveat present. |
| INV-05 | 115-01, 115-03 | `cell_align: :right` additive, byte-compat default, no Stable-tier widening | ✓ SATISFIED | `table_cell_align_test.exs` + `table_byte_identity_test.exs` + `public_api_contract_test.exs` all pass. |
| INV-06 | 115-04 | `validate_data!/1` instructive `ArgumentError`, never leaks `BadMapError`/`FunctionClauseError`, never rejects toy call | ✓ SATISFIED | **Gap closed by commit `fd845f2`.** Line-item shape (`validate_item_shape!/2`) and tightened price-type checks now cover every field read unconditionally during rendering. Live-reproduced: 6/6 malformed-item cases raise `ArgumentError`; toy call unaffected. 6 new regression tests added and pass. |
| INV-07 | 115-04 | `palette(opts)` seam, no inlined `{0,0,0}`, `page_template/1` whitelist | ✓ SATISFIED | Confirmed via grep + `invoice_opts_threading_test.exs`. |

All 7 requirement IDs (INV-01..07) declared in plan frontmatter, present in `.planning/REQUIREMENTS.md` (all marked `[x]`/"Complete"), and now fully supported by codebase evidence. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/rendro/pipeline/paginate.ex` | 648 | `defp measured_content_width(_cell), do: 0` — silent zero-width fallback for non-text cells | ℹ️ Info | Causes `right_align_offset/1` to shift non-text right-aligned cells the full column width (WR-02, carried over from prior verification). Does not affect the phase's own money-column (text) use case; no `lib/` caller currently passes non-text content into a `cell_align: :right` column. Not a blocking gap for any of the 5 roadmap Success Criteria. |

The previously flagged `lib/rendro/recipes/invoice.ex:525` permissive catch-all (`defp validate_item_price!(_price, _idx), do: :ok`, root cause of WR-01) is **gone** — confirmed via grep, replaced by `when is_number(price), do: :ok` + an explicit `ArgumentError` else-clause.

No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` markers found in `lib/rendro/recipes/invoice.ex` or `test/rendro/recipes/invoice_test.exs`.

### Human Verification Required

None.

### Gaps Summary

**No gaps remain.** All 5 roadmap Success Criteria (INV-01 through INV-07, mapped 1:1 onto the 5 truths above) are now fully verified. The single gap from the prior verification — Success Criterion 4 / INV-06's "never leaking `BadMapError`/`FunctionClauseError`" clause for line items — was closed by commit `fd845f2`, which adds `validate_item_shape!/2` (map check, `:name` binary, `:qty` integer, `:price` presence) to `validate_items!/1` and tightens `validate_item_price!/2` to reject non-numbers. The fix mirrors the existing anatomy-field shape-guard pattern already in the file (`maybe_validate_issuer!`/`maybe_validate_customer!`), is scoped exclusively to line-item validation (no other success criterion's code was touched, per `git show fd845f2`'s file list), and is confirmed both by direct live execution (6/6 malformed-item cases now raise instructive `ArgumentError`, zero raw `BadMapError`/`KeyError` leaked) and by 6 new automated regression tests. The valid toy call remains unaffected. Full workspace suite: 1275/1275 tests pass (up from 1269, +6 matching the new tests), zero regressions. `mix compile --warnings-as-errors` is clean.

WR-02 (non-text `cell_align: :right` fallback, an Info-level anti-pattern) remains a genuine but explicitly out-of-scope robustness note for future follow-up — it does not block any of the 5 roadmap Success Criteria as written and was already recorded as non-blocking in the prior verification.

---

_Verified: 2026-07-18T21:05:00Z_
_Verifier: Claude (gsd-verifier)_
