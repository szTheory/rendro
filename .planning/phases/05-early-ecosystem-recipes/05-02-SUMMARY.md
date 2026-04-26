---
phase: "05-early-ecosystem-recipes"
plan: "02"
subsystem: adapters
tags: [adapters, accrue, billing, optional-deps, gap-closure, tdd]
dependency_graph:
  requires:
    - "05-01 (Threadline adapter — established optional-gating pattern)"
  provides:
    - "lib/rendro/adapters/accrue.ex (optional Accrue billing-document recipe)"
    - "test/rendro/adapters/accrue_test.exs (contract-mock-driven test suite)"
    - "Accrue/Accrue.Invoice/Accrue.LineItem stub modules in test/support/mocks.ex"
  affects:
    - "test/support/mocks.ex (extended with Accrue stubs + AdapterReloader entry)"
tech_stack:
  added: []
  patterns:
    - "Optional-gating via Code.ensure_loaded?(Accrue) (mirrors Threadline/Mailglass pattern)"
    - "TDD RED/GREEN cycle: test commit before implementation commit"
    - "AdapterReloader force-recompile so optional guard re-evaluates in test env"
key_files:
  created:
    - lib/rendro/adapters/accrue.ex
    - test/rendro/adapters/accrue_test.exs
  modified:
    - test/support/mocks.ex
decisions:
  - "recipe/1 returns {:ok, doc} (not bare doc) so the contract aligns with Rendro.render/1's {ok,_}|{:error,_} shape"
  - "recipe/1 does NOT call Rendro.render/1 — keeps API composable and avoids re-implementing render-error fan-out"
  - "Three nested stubs (Accrue, Accrue.Invoice, Accrue.LineItem) pinned to minimal contract fields used by adapter"
  - "Accrue marker module defined last so Accrue.LineItem and Accrue.Invoice can be defined in the same unless block boundary"
metrics:
  duration_minutes: 3
  completed_date: "2026-04-26"
  tasks_completed: 2
  files_changed: 3
---

# Phase 05 Plan 02: Accrue Adapter Summary

## One-Liner

Optional `Rendro.Adapters.Accrue` recipe gated by `Code.ensure_loaded?(Accrue)` that maps `%Accrue.Invoice{}` structs (id, customer, line_items, total, issued_at) to `{:ok, %Rendro.Document{}}` via `Rendro.flow/2`, with contract-mock tests and no hard `:accrue` dependency.

## What Was Built

### lib/rendro/adapters/accrue.ex

Optional billing-document recipe module gated by `if Code.ensure_loaded?(Accrue) do`. Exports `recipe/1` which:

- Accepts `%Accrue.Invoice{}` and returns `{:ok, %Rendro.Document{}}`
- Builds a header with invoice id, issued_at date, and customer name
- Builds content with a line items table (`["Description", "Qty", "Unit", "Subtotal"]` headers) and a total row
- Builds a footer attribution line
- Returns `{:error, {:invalid_invoice, other}}` for any non-`%Accrue.Invoice{}` input

Accrue fields consumed by the recipe:

| Field | Usage |
|-------|-------|
| `:id` | Rendered as `"INVOICE #<id>"` in header |
| `:customer` | `.name` field extracted for `"Bill to: <name>"` in header |
| `:line_items` | List of `%Accrue.LineItem{}` mapped into table rows |
| `:total` | Rendered as `"Total: $<total>"` in content |
| `:issued_at` | Rendered as `"Issued: <date>"` in header |

`%Accrue.LineItem{}` fields consumed: `:description`, `:quantity`, `:unit_amount`, `:subtotal`.

### test/rendro/adapters/accrue_test.exs

Contract-mock-driven test suite (5 tests across 3 describe blocks):

- `"recipe/1 happy path"` — {:ok, %Rendro.Document{}} returned; content non-empty; id and line item descriptions appear in inspected doc
- `"recipe/1 happy path"` — rendered document produces valid `<<"%PDF-", _>>` binary via `Rendro.render/1`
- `"optional-gating proof"` — `Code.ensure_loaded?(Rendro.Adapters.Accrue)` and `function_exported?/3` both true after `AdapterReloader.recompile/0`
- `"recipe/1 input validation"` — `recipe(:not_an_invoice)` returns `{:error, {:invalid_invoice, :not_an_invoice}}`

### test/support/mocks.ex (extended)

Added three stub blocks and one AdapterReloader entry:

- `Accrue.LineItem` — `defstruct [:description, :quantity, :unit_amount, :subtotal]`
- `Accrue.Invoice` — `defstruct [:id, :customer, :line_items, :total, :issued_at]`
- `Accrue` — marker module with `__accrue_stub__/0` to satisfy `Code.ensure_loaded?(Accrue)` at test compile time
- `AdapterReloader @adapter_files` — extended to include `"lib/rendro/adapters/accrue.ex"`

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED | `1b44bb9` — `test(05-02): add failing tests for Accrue adapter recipe` | All 5 tests failed as expected |
| GREEN | `91157d1` — `feat(05-02): implement optional Accrue billing-document recipe` | All 5 tests pass |
| REFACTOR | N/A | No refactoring needed; code was clean on first pass |

## Verification Results

```
mix compile --warnings-as-errors   → exit 0
mix test test/rendro/adapters/accrue_test.exs → 5 tests, 0 failures
mix test test/rendro/adapters/   → 19 tests, 0 failures (Threadline + Mailglass + Accrue)
awk '/defp deps do/,/^  end$/' mix.exs | grep -c ":accrue" → 0 (no hard dep)
```

## Commits

| Hash | Message |
|------|---------|
| `259e827` | `chore(05-02): add Accrue stub modules and extend AdapterReloader` |
| `1b44bb9` | `test(05-02): add failing tests for Accrue adapter recipe` |
| `91157d1` | `feat(05-02): implement optional Accrue billing-document recipe` |

## Deviations from Plan

None - plan executed exactly as written.

The pre-existing Threadline typing warnings (`{:ok, _}` and `{:error, _}` clauses that never match against the stub's `dynamic(:ok)` return type) appeared during test runs but are out of scope for this plan. They exist in `lib/rendro/adapters/threadline.ex` which was committed in plan 05-01. Logged to deferred-items for future resolution.

## Known Stubs

None. The `Accrue.Invoice` stub in `test/support/mocks.ex` is intentional test infrastructure (not a UI-facing stub) — it exists to satisfy `Code.ensure_loaded?(Accrue)` so the optional adapter compiles in the test environment. The adapter itself is fully implemented and wired.

## Threat Surface Scan

No new security-relevant surface introduced beyond what the plan's threat model documented:

- `recipe/1` pattern-matches on `%Accrue.Invoice{}` — non-Invoice inputs are rejected (T-05-02-01 mitigated)
- No new network endpoints, auth paths, or file system access introduced
- Render policies enforced via downstream `Rendro.render/1` call (T-05-02-03 accepted)

## Self-Check: PASSED

Files created/modified:

- FOUND: lib/rendro/adapters/accrue.ex
- FOUND: test/rendro/adapters/accrue_test.exs
- FOUND: test/support/mocks.ex
- FOUND: .planning/phases/05-early-ecosystem-recipes/05-02-SUMMARY.md

Commits:

- FOUND: 259e827 (chore: stub modules + AdapterReloader)
- FOUND: 1b44bb9 (test: RED phase)
- FOUND: 91157d1 (feat: GREEN phase implementation)
