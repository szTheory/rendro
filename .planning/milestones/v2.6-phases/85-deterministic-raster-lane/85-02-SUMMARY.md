---
phase: 85-deterministic-raster-lane
plan: "02"
subsystem: adapter
tags: [elixir, pdfium, raster, render, security, tmp-dir, tdd]

requires:
  - plan: 85-01
    provides: render/2 @tag :skip RED stub in pdfium_test.exs

provides:
  - Rendro.Adapters.Pdfium.render/2 implemented with tmp-dir isolation (0o700/0o600) and PNG collection
  - RAST-01a (missing-executable error path) green
  - RAST-01b (mock-runner happy path) green
  - T-85-04 mitigation (write_private_file 0o600 + 0o700 dir) present in source
  - T-85-06 mitigation (no shell injection — list-form args, Integer.to_string/1 for dpi) present in source

affects:
  - 85-03 (snapshot harness can now call render/2 for live raster tests)
  - 86-self-proving-launch-artifacts (depends on raster lane being complete)

tech-stack:
  added: []
  patterns:
    - "with/try/after pattern for binary-input adapter operations (identical to qpdf.ex)"
    - "make_tmp_dir_for_raster/0: per-invocation isolated tmp dir (rendro-raster-$int, chmod 0o700)"
    - "write_private_file/2: [:write, :exclusive, :binary] + File.chmod(path, 0o600)"
    - "collect_pngs/1: Path.wildcard page_*.png |> Enum.sort |> File.read!/1"
    - "Injectable :pdfium_cli_command_runner via Application.get_env for unit testing"
    - "Mock runner derives tmp_dir from output_pattern arg (Enum.at(args, 2)) to write fake PNGs"

key-files:
  created: []
  modified:
    - lib/rendro/adapters/pdfium.ex
    - test/rendro/adapters/pdfium_test.exs
    - priv/public_api.json

key-decisions:
  - "Used render_args/3 as a separate private function (per plan action item 7) so run_render/5 is testable without duplication"
  - "Regenerated priv/public_api.json via mix rendro.api.gen to keep docs-contract manifest in sync with new render/2 public function (Rule 2 auto-fix)"

metrics:
  duration: 2min
  completed: 2026-06-11
---

# Phase 85 Plan 02: render/2 Implementation Summary

**Implemented Rendro.Adapters.Pdfium.render/2: accepts pdf_binary + opts (dpi:, pages:), writes to chmod 0o700/0o600 tmp dir, invokes pdfium-cli render via list-form args, collects page_*.png binaries; both RAST-01a and RAST-01b tests green**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-11T00:12:50Z
- **Completed:** 2026-06-11T00:15:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Implemented `Rendro.Adapters.Pdfium.render/2` with the `with/try/after` pattern copied from `qpdf.ex`
- Added input validation (dpi: positive integer, pages: non-empty string) per ASVS V5 / T-85-06
- `make_tmp_dir_for_raster/0` creates an isolated per-invocation tmp directory (chmod 0o700, named `rendro-raster-$int`)
- `write_private_file/2` writes input PDF with `[:write, :exclusive, :binary]` then chmod 0o600 (T-85-04 mitigation)
- `run_render/5` and `render_args/3` build list-form args for `System.cmd/3` — no shell interpolation (T-85-06)
- `collect_pngs/1` collects sorted `page_*.png` files and returns `{:ok, pngs}` or `{:error, {:no_pages_rendered, ...}}`
- Un-skipped render/2 missing-executable test (RAST-01a)
- Added mock-runner happy-path test that derives tmp_dir from output_pattern arg and writes fake PNG (RAST-01b)
- Regenerated `priv/public_api.json` manifest to include `render/2` in the Pdfium adapter public API

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement render/2 in pdfium.ex** - `501980f` (feat)
2. **Task 2: Un-skip render/2 tests + add mock-runner test + manifest regen** - `28eb5f1` (feat)

## Files Created/Modified

- `lib/rendro/adapters/pdfium.ex` — Added render/2, validate_dpi/1, validate_pages/1, make_tmp_dir_for_raster/0, write_private_file/2, render_in_tmp/4, run_render/5, render_args/3, collect_pngs/1 (102 lines added)
- `test/rendro/adapters/pdfium_test.exs` — Removed @tag :skip from render/2 missing-executable test; added mock-runner happy-path test
- `priv/public_api.json` — Regenerated to include render/2 in Pdfium adapter manifest

## Decisions Made

- **render_args/3 kept as separate private function:** Per plan action item 7, this enables clean testing and separation of concerns between arg construction and command invocation.
- **Manifest regen via mix rendro.api.gen:** The public_api_contract_test.exs docs-contract lane enforces byte-identical manifest on every test run. Adding a public `render/2` function to `pdfium.ex` caused 2 test failures — auto-fixed by running `mix rendro.api.gen` and committing the updated manifest.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Regenerated priv/public_api.json after adding render/2**
- **Found during:** Task 2 verification (`mix test` full suite)
- **Issue:** Adding `render/2` as a public function to `Rendro.Adapters.Pdfium` caused 2 docs-contract test failures in `public_api_contract_test.exs` and `manifest_test.exs` — both assert the checked-in manifest is byte-identical to a freshly-generated one
- **Fix:** Ran `mix rendro.api.gen` to regenerate `priv/public_api.json`, committed alongside the test file changes in Task 2
- **Files modified:** priv/public_api.json
- **Commit:** 28eb5f1

## Known Stubs

None. All render/2 tests are active (no @tag :skip remaining in pdfium_test.exs). The 3 remaining @tag :skip stubs in raster_claims_test.exs and pdfium_raster_snapshot_test.exs are Wave 0 placeholders for Plan 03 — unchanged from Plan 01.

## Threat Surface Scan

No new network endpoints or auth paths introduced. The new `render/2` function follows existing tmp-dir isolation patterns — trust boundary mitigations T-85-04 and T-85-06 are verifiable in source:
- `grep "0o600" lib/rendro/adapters/pdfium.ex` returns 2 matches
- `grep "0o700" lib/rendro/adapters/pdfium.ex` returns 2 matches

## Self-Check

Files exist:
- `lib/rendro/adapters/pdfium.ex` — FOUND (modified)
- `test/rendro/adapters/pdfium_test.exs` — FOUND (modified)
- `priv/public_api.json` — FOUND (modified)

Commits exist:
- `501980f` — FOUND
- `28eb5f1` — FOUND

## Self-Check: PASSED

---
*Phase: 85-deterministic-raster-lane*
*Completed: 2026-06-11*
