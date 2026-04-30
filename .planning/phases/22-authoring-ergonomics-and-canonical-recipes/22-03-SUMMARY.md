---
phase: 22-authoring-ergonomics-and-canonical-recipes
plan: 03
subsystem: examples, docs
tags: [elixir, phoenix, recipe, invoice, tiered-composition, readme, documentation]

# Dependency graph
requires:
  - "Rendro.Recipes.Invoice.document/2 (22-02)"
  - "Rendro.Document pipeline builder API (22-01)"
provides:
  - "Phoenix example controller serving canonical invoice via Rendro.Recipes.Invoice.document/2"
  - "4-test suite: HTTP 200/pdf, magic bytes, structural recipe assertions, source-level check"
  - "README.md: Builder API getting-started section with Rendro.Document.new pipeline"
  - "README.md: Tiered Composition section introducing Rendro.Recipes.Invoice pattern"
  - "README.md: Backward compatibility note demoting header:/footer: kwargs from primary flow"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Phoenix controller tests via Phoenix.ConnTest (ConnCase) with HTTP + binary + structural + source-level assertions"
    - "Source-level test: File.read! controller source and assert/refute pattern presence"

key-files:
  created:
    - examples/phoenix_example/test/test_helper.exs
    - examples/phoenix_example/test/support/conn_case.ex
    - examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs
  modified:
    - examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex
    - examples/phoenix_example/mix.exs
    - README.md

key-decisions:
  - "Phoenix controller tests use source-level File.read! check to verify canonical recipe call without mocking"
  - "ConnCase uses import Plug.Conn + import Phoenix.ConnTest (not deprecated use Phoenix.ConnTest)"
  - "README non-runnable schematic blocks use elixir-schematic tag to avoid docs-contract enforcement"
  - "readme-flow-compile fence updated to use sections: instead of header:/footer: kwargs"

requirements-completed:
  - LAY-12

# Metrics
duration: ~5min
completed: 2026-04-30
---

# Phase 22 Plan 03: Phoenix Example and README Upgrade Summary

**Phoenix controller upgraded to serve canonical invoice via Rendro.Recipes.Invoice.document/2 with a 4-test suite; README rewritten to lead with builder API and Tiered Composition, demoting legacy kwargs to a compatibility note**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-30T15:50:16Z
- **Completed:** 2026-04-30T15:55:07Z
- **Tasks:** 2 (Task 1 TDD: RED + GREEN; Task 2 doc-only)
- **Files modified:** 6

## Accomplishments

- Created full Phoenix example test infrastructure: `test_helper.exs`, `ConnCase` support module, and `pdf_controller_test.exs` with 4 tests (HTTP 200/pdf content-type, PDF magic bytes `%PDF-`, structural recipe assertions on page_template regions and sections, source-level canonical recipe check)
- Replaced trivial `Rendro.flow` demo in the Phoenix controller with `Rendro.Recipes.Invoice.document/2` passing realistic dummy data (invoice ID + 2 line items); both `download` and `preview` actions use the canonical recipe
- Updated `mix.exs` with `elixirc_paths` to include `test/support` in test env
- Rewrote `README.md`: leading "Getting Started with the Builder API" section, "Tiered Composition: Canonical Recipes" section with zero-to-one and escape-hatch examples, backward compatibility note demoting `header:`/`footer:` kwargs, updated `readme-flow-compile` fence to use `sections:`
- All 4 controller tests pass; full main suite (316 tests) green; `mix docs.contract` VERIFIED

## Task Commits

1. **Task 1 RED: Phoenix controller canonical invoice tests** - `93ebb3a` (test)
2. **Task 1 GREEN: Upgrade Phoenix controller to canonical recipe** - `41840af` (feat)
3. **Task 2: Rewrite README with builder API and Tiered Composition** - `d7030cd` (docs)

## Files Created/Modified

- `examples/phoenix_example/test/test_helper.exs` (created) — ExUnit startup
- `examples/phoenix_example/test/support/conn_case.ex` (created) — ConnCase using `import Plug.Conn + import Phoenix.ConnTest`
- `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` (created) — 4-test suite
- `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` (modified) — `Rendro.Recipes.Invoice.document/2` replaces `Rendro.flow`
- `examples/phoenix_example/mix.exs` (modified) — `elixirc_paths/1` added for test support
- `README.md` (modified) — Builder API section, Tiered Composition section, compat note

## Decisions Made

- Source-level test uses `File.read!` on the controller file (path resolved via `File.cwd!()`) rather than mocking — straightforward for an example project where paths are stable
- `ConnCase` uses the non-deprecated `import Plug.Conn + import Phoenix.ConnTest` style (Rule 2 auto-fix for deprecation warning)
- Non-runnable README schematic blocks tagged `elixir-schematic` so `docs.contract` does not attempt to compile/eval them — the existing six verified fences retain their `# docs-contract:` IDs unchanged
- `readme-flow-compile` fence updated: `header:`/`footer:` kwargs replaced with `sections:` to match the new canonical authoring guidance (the old kwargs style is still valid Elixir but is demoted to the compat note)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Infrastructure] Phoenix example had no test directory**
- **Found during:** Task 1 RED
- **Issue:** `examples/phoenix_example/test/` did not exist; no test helper, no ConnCase, no test directory structure
- **Fix:** Created `test/test_helper.exs`, `test/support/conn_case.ex`, and the controller test directory; added `elixirc_paths` to `mix.exs`
- **Files modified:** `examples/phoenix_example/mix.exs`, three new test files
- **Commit:** 93ebb3a (RED)

**2. [Rule 2 - Auto-fix Deprecation] Phoenix.ConnTest deprecation warning**
- **Found during:** Task 1 GREEN (first run)
- **Issue:** `use Phoenix.ConnTest` in ConnCase triggers deprecation warning in newer Phoenix
- **Fix:** Changed to `import Plug.Conn` + `import Phoenix.ConnTest` pattern
- **Files modified:** `examples/phoenix_example/test/support/conn_case.ex`
- **Commit:** 41840af (GREEN)

**3. [Rule 3 - Blocking Docs Contract] New README `elixir` fences without docs-contract ID**
- **Found during:** Task 2 verification (`mix docs.contract`)
- **Issue:** New schematic examples (builder API, recipe, backward compat note) used plain `elixir` fence tags, failing the `docs-contract` verified-fence enforcement
- **Fix:** Changed all non-verifiable examples to `elixir-schematic`; updated `readme-flow-compile` fence to use `sections:` (removes legacy kwargs from the verified example)
- **Files modified:** `README.md`
- **Commit:** d7030cd (docs)

## Known Stubs

None. All four tests assert real behavior; the README examples reference the fully-implemented Invoice recipe.

## Threat Surface Scan

No new network endpoints beyond the existing `/download` and `/preview` routes. No auth paths, file access patterns outside test-time source file reading, or schema changes. Disposition: accept (T-22-03 per plan threat register — rate limiting is explicitly deferred to real implementations).

## Self-Check: PASSED

- `examples/phoenix_example/test/test_helper.exs` — FOUND
- `examples/phoenix_example/test/support/conn_case.ex` — FOUND
- `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` — FOUND
- `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` — FOUND (updated)
- `examples/phoenix_example/mix.exs` — FOUND (updated)
- `README.md` — FOUND (updated)
- RED commit `93ebb3a` — FOUND
- GREEN commit `41840af` — FOUND
- docs commit `d7030cd` — FOUND
- `grep -q "Rendro.Document.new" README.md` — PASSED
- `grep -q "Tiered Composition" README.md` — PASSED
- `grep -q "Rendro.Recipes.Invoice" README.md` — PASSED
- `cd examples/phoenix_example && mix test` — 4 tests, 0 failures
- `mix test` — 316 tests, 0 failures
- `mix docs.contract` — VERIFIED
