---
phase: 114-domain-research-reader-quality-rubric-realistic-example-data
plan: 04
subsystem: infra
tags: [priv-examples, loader, path-traversal, public-api-surface, tdd, json]

# Dependency graph
requires:
  - phase: 114-01
    provides: "priv/examples/invoice/acme-phoenix-saas/invoice.json — the de-quarantined realistic Invoice fixture the loader reads"
provides:
  - "Rendro.Examples (@moduledoc false) — the phase's one lib/ product change: load!/1 (read + JSON.decode! a fixture) and list/1 (enumerate a domain's .json fixtures), both resolved via Application.app_dir/2 so they work identically in-repo, for Hex consumers, and under Mix.install Livebook"
  - "In-repo wildcard extension-ban test — the fast, no-hex-build half of EXL-05's raster-ban proof"
  - "Rendro.Examples asserted :hidden in public_api_contract_test.exs and confirmed absent from api.gen.ex @public_modules — EXL-02's 'absent from priv/public_api.json' mechanism"
affects: [114-05, 114-07, examples-loader, guides, livebook]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pattern 1 (mirror Rendro.Branded): @moduledoc false priv-reader resolving absolute paths via Application.app_dir(:rendro, subpath) so one code path serves in-repo dev/test, installed Hex deps, and Mix.install Livebook."
    - "Defense-in-depth path guard: both load!/1 and list/1 route their string input through a shared safe!/1 helper wrapping Path.safe_relative/1 ({:ok, safe} | :error), raising ArgumentError before any File.read!/Path.wildcard touches the filesystem (T-114-04-01/02 mitigation)."
    - "Built-in JSON.decode!/1, never Jason.decode!/1 — Jason is a :dev/:test-only transitive dep and would crash a prod Hex consumer (RESEARCH Pitfall 3)."

key-files:
  created:
    - lib/rendro/examples.ex
    - test/rendro/examples_test.exs
  modified:
    - test/docs_contract/public_api_contract_test.exs

key-decisions:
  - "Kept the RESEARCH-specified load!(relative_path :: String.t()) / list(domain :: String.t()) signatures (not an enumerated-atom API) since every current caller is internal/hardcoded; the Path.safe_relative/1 guard is defense-in-depth against hypothetical future indirect exposure (e.g. Milestone C's public catalog)."
  - "Both functions share a single private safe!/1 helper rather than duplicating the guard, keeping the two mitigations (T-114-04-01, T-114-04-02) identical by construction."
  - "Loader returns raw JSON-decoded maps (money still as strings) — Decimal mapping is deferred to each family's data-shaping code (Phase 115+), consistent with 'no lib/ product change except the loader'."

metrics:
  duration: ~2 min
  completed: 2026-07-11
  tasks-completed: 2
  files-created: 2
  files-modified: 1

requirements-completed: [EXL-02, EXL-05]
status: complete
---

# Phase 114 Plan 04: Rendro.Examples Loader & Hidden-Surface Assertion Summary

`Rendro.Examples` (`@moduledoc false`) is the phase's single `lib/` product change — a priv/examples loader mirroring `Rendro.Branded`'s `Application.app_dir/2` idiom, with `load!/1`/`list/1` both guarded by `Path.safe_relative/1`, proven by TDD tests and asserted `:hidden` in the public-API contract.

## What Was Built

### Task 1 — `Rendro.Examples` loader (TDD)
- `lib/rendro/examples.ex`: `@moduledoc false`, `@base_dir "priv/examples"`.
  - `load!/1` → `Application.app_dir(:rendro, "priv/examples")` → `Path.join(safe)` → `File.read!` → `JSON.decode!` (built-in `JSON`, never `Jason`).
  - `list/1` → same base → `Path.join(safe) |> Path.join("**/*.json") |> Path.wildcard()`.
  - Shared `safe!/1` helper wraps `Path.safe_relative/1`; `:error` raises `ArgumentError` naming the rejected path before any filesystem access.
- `test/rendro/examples_test.exs` (`Rendro.ExamplesTest`, `async: true`) covers all five `<behavior>` bullets: happy-path decode with `fixture_id == "invoice_v1"`, `load!` traversal rejection, `list` returns non-empty absolute `.json` paths incl. the acme fixture, `list` domain-traversal rejection, and the `priv/examples/**/*` wildcard extension-ban (`.json`/`.md`/`.svg`, directories filtered via `File.regular?/1`).
- TDD cycle: RED commit (4 failing behavior tests) → GREEN commit (loader). Verify: `mix test test/rendro/examples_test.exs` → 5 tests, 0 failures. `grep -c Path.safe_relative` = 3 (≥2). `grep -c Jason` = 0.

### Task 2 — Hidden-surface assertion (EXL-02)
- Added `Rendro.Examples` to the `hidden_modules` list in `test/docs_contract/public_api_contract_test.exs` (Assertion 3). Existing `Code.ensure_loaded?/1` + `Code.fetch_docs/1` + `module_doc == :hidden` assertions cover the new entry.
- Confirmed (grep-only, no edit) `lib/mix/tasks/rendro/api.gen.ex` `@public_modules` has zero `Rendro.Examples` references — it stays out of `priv/public_api.json` by construction.
- Verify: `mix test test/docs_contract/public_api_contract_test.exs` → 6 tests, 0 failures; `ABSENT_FROM_REGISTRY` printed.

## Deviations from Plan

None — plan executed exactly as written. No auto-fixes, no authentication gates, no checkpoints.

## Threat Model Coverage

- **T-114-04-01 / T-114-04-02 (mitigate):** `Path.safe_relative/1` guard applied to both `load!/1` and `list/1` inputs via shared `safe!/1`, raising `ArgumentError` before `File.read!`/`Path.wildcard`. Verified by the two traversal-rejection tests.
- **T-114-04-03 (accept):** Enforced by Task 2's hidden-modules assertion plus the negative `@public_modules` registry check.

## Requirements Completed

- **EXL-02** — `Rendro.Examples` loader present, asserted absent from `priv/public_api.json` (`:hidden`).
- **EXL-05** — In-repo wildcard extension-ban test (the non-hex-build half; the tarball-content half is Plan 114-07).

## Verification

- `mix test test/rendro/examples_test.exs` → 5 tests, 0 failures.
- `mix test test/docs_contract/public_api_contract_test.exs` → 6 tests, 0 failures.
- Full-suite confirmation deferred to the phase-level run after all Wave-2 plans land (per plan `<verification>`).

## Self-Check: PASSED

All created files exist on disk; all three task commits (7688e67, 24e0c7e, 1839160) present in git history.
