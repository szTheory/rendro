---
phase: 84-drawn-path-primitive-visible-polish
plan: "01"
subsystem: color-path-foundation
tags: [color, path, test-stubs, wave-0, red-state, docs-contract]
dependency_graph:
  requires: []
  provides:
    - lib/rendro/color.ex (Rendro.Color internal helper)
    - lib/rendro/path.ex (Rendro.Path public struct)
    - test/rendro/path_test.exs (P01a-P01f RED stubs)
    - test/rendro/table_borders_test.exs (P02a-P02f RED stubs)
    - test/docs_contract/path_claims_test.exs (PATH-04 docs-contract lane)
    - scripts/verify_docs.exs (Path claims lane entry)
  affects:
    - test/rendro/recipes/certificate_test.exs (C15-C20 appended)
tech_stack:
  added: []
  patterns:
    - "@moduledoc false internal helper (Rendro.Color matches page_size.ex analog)"
    - "@moduledoc tags: [:stable] public struct (Rendro.Path matches image.ex analog)"
    - "errors-as-product ArgumentError with What/Where/Why/Next + hex footgun message (D-04)"
    - "private format_num/1 verbatim copy from writer.ex for byte-determinism"
    - "docs-contract lane self-registration pattern (matches script_support_claims_test.exs)"
key_files:
  created:
    - lib/rendro/color.ex
    - lib/rendro/path.ex
    - test/rendro/path_test.exs
    - test/rendro/table_borders_test.exs
    - test/docs_contract/path_claims_test.exs
  modified:
    - test/rendro/recipes/certificate_test.exs
    - scripts/verify_docs.exs
decisions:
  - "Rendro.Color.validate/1 error messages contain 'hex' per D-04 mandate — users get explicit conversion example #2C6BED → {44,107,237}"
  - "format_num/1 copied verbatim from writer.ex (not imported) — Rendro.Color is standalone with zero coupling"
  - "Rendro.Path is a pure struct module (no functions) matching image.ex — all behavior lives in pipeline stages"
  - "Wave 0 test stubs use struct! with fields not yet in Table — this produces correct RED failures until plan 84-02 adds the fields"
requirements-completed:
  - PATH-01
metrics:
  duration: "465s (7m)"
  completed: "2026-06-10"
  tasks_completed: 2
  tasks_total: 2
  files_created: 5
  files_modified: 2
---

# Phase 84 Plan 01: Color+Path Foundation + Wave 0 Test Stubs Summary

**One-liner:** Internal `Rendro.Color` helper (rg/rg_stroke/validate with hex-footgun errors) and public `%Rendro.Path{}` struct foundation, plus all Wave 0 RED-state test stubs giving the pipeline harness for plans 84-02 through 84-05.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Rendro.Color + Rendro.Path | a0f2e0c | lib/rendro/color.ex, lib/rendro/path.ex |
| 2 | Wave 0 test stubs + verify_docs lane | 52333d4 | test/rendro/path_test.exs, test/rendro/table_borders_test.exs, test/docs_contract/path_claims_test.exs, test/rendro/recipes/certificate_test.exs (+C15-C20), scripts/verify_docs.exs |

## What Was Built

### Task 1: Rendro.Color + Rendro.Path

**`lib/rendro/color.ex`** (`@moduledoc false` — excluded from public API manifest):
- `rg({r,g,b})` — returns `"R G B rg\n"` PDF fill color operator string
- `rg_stroke({r,g,b})` — returns `"R G B RG\n"` PDF stroke color operator string
- `to_pdf_components({r,g,b})` — returns `{r/255, g/255, b/255}` as floats
- `validate({r,g,b})` — returns `:ok` for valid 0-255 integer tuples; `{:error, reason}` with hex-footgun message for any invalid input (the error always contains "hex" and includes the conversion example `"#2C6BED" → {44, 107, 237}`)
- Private `format_num/1` — verbatim copy from writer.ex:1758-1762 for byte-determinism guarantee

**`lib/rendro/path.ex`** (`@moduledoc tags: [:stable]` — part of public Tier-1 API):
- `@enforce_keys [:ops]`; `defstruct [:ops, fill: nil, stroke: nil]`
- `@type t` covers all six ops (move/line/curve/rect/rounded_rect/close) and stroke/fill style types
- Pure inert struct module (no functions) — all rendering behavior lives in pipeline stages

### Task 2: Wave 0 Test Stubs (RED State)

**`test/rendro/path_test.exs`** — P01a through P01f:
- P01a: rect path renders `re\nS` in content stream
- P01b: two-render byte-identity (determinism)
- P01c: format_num precision (max 4 decimal places, no scientific notation)
- P01d: rounded_rect kappa approximation (0.5523 in content stream)
- P01e: paint-op selection (stroke-only→S, fill-only→f, both→B, neither→n)
- P01f: Color.validate hex footgun error (`{:error, msg}` where msg contains "hex")

**`test/rendro/table_borders_test.exs`** — P02a through P02f:
- P02a: `borders: :all` renders `re` and `S` operators
- P02b: borderless table byte-identity (baseline)
- P02c: `borders: :none` byte-identity
- P02d: `[:outer, :rows]` renders borders
- P02e: draw-once (no doubled segments for 2x2 table)
- P02f: `header_fill: {0, 102, 204}` emits `rg` and `f\n`

**`test/rendro/recipes/certificate_test.exs`** — C15 through C20 appended:
- C15: `border: true` renders `re` and `S`
- C16: `border: false` byte-identity
- C17: frame coords differ A4 vs US Letter (geometry-derived proof)
- C18: inset = 0.5 * min(margins) formula
- C19: `border: %{color: {255, 0, 0}}` emits `1.0000 0.0000 0.0000 RG` in content stream
- C20: `validate_border!` rejects unknown keys, hex colors, and oversized inset

**`test/docs_contract/path_claims_test.exs`** (PATH-04 lane):
- Test 1: `priv/support_matrix.json` has `path_primitive` section with `transforms_cm`, `clipping_W`, `gradients` as `explicit_deferral` entries with 40-char evidence strings
- Test 2 (self-registration): `scripts/verify_docs.exs` contains the path claims lane entry — **passes immediately**

**`scripts/verify_docs.exs`** — added lane entry:
```elixir
{"Path claims lane", ["test", "test/docs_contract/path_claims_test.exs"]},
```

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

| Check | Status | Notes |
|-------|--------|-------|
| color.ex compiles clean | PASS | `elixir -e "Code.compile_file(\"lib/rendro/color.ex\")"` |
| path.ex compiles clean | PASS | `elixir -e "Code.compile_file(\"lib/rendro/path.ex\")"` |
| Rendro.Color is @moduledoc false | PASS | `grep "moduledoc false" lib/rendro/color.ex` |
| Rendro.Path has @moduledoc tags: [:stable] | PASS | `grep "moduledoc tags.*stable" lib/rendro/path.ex` |
| Rendro.Color.rg({0,0,0}) == "0.0000 0.0000 0.0000 rg\n" | PASS | functional test |
| Rendro.Color.rg_stroke({255,0,0}) == "1.0000 0.0000 0.0000 RG\n" | PASS | functional test |
| validate({0,0,0}) returns :ok | PASS | functional test |
| validate("#000") returns {:error, msg} with "hex" in msg | PASS | functional test |
| @enforce_keys [:ops] on Path | PASS | struct!([]) raises ArgumentError |
| Path self-registration test passes | PASS | lane entry in verify_docs.exs confirmed |
| existing deterministic_test.exs green | PASS | `mix test test/rendro/deterministic_test.exs` in main repo |
| scripts/verify_docs.exs contains Path claims lane entry | PASS | grep -c returns 1 |
| All 4 test files compile (syntax valid) | PASS | Code.string_to_quoted! on all files |
| C15-C20 describe blocks in certificate_test.exs | PASS | grep confirmed |

## Known Stubs

The following test stubs are intentionally RED (pending implementation in plans 84-02 through 84-05):

| File | Stub | Reason |
|------|------|--------|
| test/rendro/path_test.exs | P01a-P01e | Rendro.Path pipeline dispatch not implemented until plan 84-02 |
| test/rendro/table_borders_test.exs | P02a-P02f (except P02b) | Table.borders field + rendering not implemented until plan 84-03 |
| test/rendro/recipes/certificate_test.exs | C15-C19 | Certificate border: option not implemented until plan 84-04 |
| test/docs_contract/path_claims_test.exs | Test 1 | support_matrix.json path_primitive section not added until plan 84-05 |

These stubs are Wave 0 RED-state test infrastructure. Their RED state is intentional and expected.

## Threat Surface Scan

T-84-01 (Tampering: Rendro.Color.validate/1) — mitigated as planned. The implementation:
- Rejects non-tuple inputs (hex strings, atoms)
- Rejects wrong-arity tuples
- Rejects out-of-range integers (negative or > 255)
- Rejects float components
- Error messages always contain "hex" (D-04 footgun naming)

No new network endpoints, file access patterns, or auth paths introduced.

## Self-Check: PASSED

Files verified present:
- lib/rendro/color.ex: FOUND
- lib/rendro/path.ex: FOUND
- test/rendro/path_test.exs: FOUND
- test/rendro/table_borders_test.exs: FOUND
- test/docs_contract/path_claims_test.exs: FOUND
- test/rendro/recipes/certificate_test.exs (C15-C20 appended): FOUND
- scripts/verify_docs.exs (Path claims lane): FOUND

Commits verified:
- a0f2e0c: feat(84-01): add Rendro.Color helper and Rendro.Path public struct
- 52333d4: feat(84-01): add Wave 0 test stubs (RED state) and verify_docs lane entry
