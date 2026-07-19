---
phase: 117-edge-case-stress-matrix
plan: 06
subsystem: testing
tags: [edge-matrix, raster, pdfium, snapshot, pagination, page-size, deterministic]

requires:
  - phase: 117-01
    provides: Rendro.Test.Golden.assert_deterministic!/1 — the pre-rasterization two-run determinism guard
  - phase: 117-02
    provides: Rendro.Test.EdgeFixtures (document/2, build/2, opts/2) — the recipe-shaped fixture dispatch table
provides:
  - Six D-10 curated @tag raster_snapshot fixtures inside the existing pdfium_raster_snapshot_test.exs
  - CI-discoverable raster coverage of the placement-geometry sub-grid (page breaks, A4-vs-Letter dims, odd/even parity, extreme wrap)
affects: []

tech-stack:
  added: []
  patterns:
    - "Extend the existing hardcoded-path CI raster test file in place (no new file) so CI discovers fixtures with zero ci.yml edit"
    - "Build raster PDFs via Rendro (EdgeFixtures) + prove two-run determinism before rasterizing, reusing the file's private assert_or_bless/2 verbatim"
    - "A4/Letter geometry pair from one shared data map, varying only document/2 opts"

key-files:
  created: []
  modified:
    - test/rendro/adapters/pdfium_raster_snapshot_test.exs

key-decisions:
  - "Fixtures added IN PLACE to the existing pdfium_raster_snapshot_test.exs (not a new file) so the CI raster job's hardcoded single-file path discovers them with zero .github/workflows/ci.yml edit — the locked in-fence resolution to RESEARCH Landmine 1."
  - "Raster refs are NOT blessed in this environment (no pdfium-cli, not the pinned GITHUB_ACTIONS container). Tests are authored assert-only and fail at the missing-ref stage locally, exactly like the pre-existing forms_support_fixture case; blessing happens once in the pinned CI container per D-11."
  - "Test descriptions use the underscore fixture-name strings verbatim so the raster_refs/<fixture>/ directory names, the trace output, and the assert_or_bless argument all read identically."

requirements-completed: [EDGE-01]

coverage:
  - id: D-10a
    description: "Three combined fixtures each simultaneously prove pagination + 60+ line items + odd/even running-content parity across >=2 pages (Invoice/Statement/Payslip)"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/rendro/adapters/pdfium_raster_snapshot_test.exs — edge_invoice/statement/payslip_pagination_60plus_odd_even (assert length(pngs) >= 2 before hash compare)"
        status: pass_pending_ci_bless
    human_judgment: false
  - id: D-10b
    description: "A4/Letter geometry pair on Certificate from identical data, varying only document/2 opts; plus one Invoice extreme-wrap fixture"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/rendro/adapters/pdfium_raster_snapshot_test.exs — edge_certificate_a4 / edge_certificate_us_letter / edge_invoice_extreme_wrap"
        status: pass_pending_ci_bless
    human_judgment: false

duration: 6min
completed: 2026-07-19
status: complete
---

# Phase 117 Plan 06: Curated pdfium Raster Fixtures Summary

**Extended the existing `test/rendro/adapters/pdfium_raster_snapshot_test.exs` in place with the six D-10 curated raster fixtures — three combined pagination+60plus+odd-even renders (Invoice/Statement/Payslip), a Certificate A4/Letter geometry pair, and an Invoice extreme-wrap — each building its PDF via `EdgeFixtures`, proving two-run determinism, and reusing the file's private `assert_or_bless/2` verbatim, with zero `lib/` and zero `ci.yml` edits.**

## Performance

- **Duration:** ~6 min
- **Completed:** 2026-07-19
- **Tasks:** 2 of 2
- **Files modified:** 1 (`test/rendro/adapters/pdfium_raster_snapshot_test.exs`, extended in place)

## Accomplishments

- Added exactly 6 new `@tag raster_snapshot: true` tests inside `Rendro.Adapters.PdfiumRasterSnapshotTest`, respecting D-10's `<=8` fixture ceiling:
  1. `edge_invoice_pagination_60plus_odd_even` — Invoice, `>=2` pages
  2. `edge_statement_pagination_60plus_odd_even` — Statement, `>=2` pages
  3. `edge_payslip_pagination_60plus_odd_even` — Payslip, `>=2` pages
  4. `edge_certificate_a4` — Certificate at default A4 geometry
  5. `edge_certificate_us_letter` — same underlying data, `page_size: :us_letter`
  6. `edge_invoice_extreme_wrap` — Invoice narrow `{:share, 1}` item-name column
- Each fixture builds its PDF via `EdgeFixtures.document/2` (5 of 6) or `EdgeFixtures.build/2` + `Certificate.document/2` (the A4 half of the pair), proves two-run byte-determinism via `Golden.assert_deterministic!/1`, rasterizes ALL pages at `dpi: 150` (no `:pages` opt), and calls the file's existing private `assert_or_bless/2` — no forked/duplicated bless logic.
- Added `alias Rendro.Test.EdgeFixtures` and `alias Rendro.Test.Golden` below the existing `alias Rendro.Adapters.Pdfium`.
- Default `mix test` still excludes the raster lane (`raster_snapshot: true` excluded — 7 tests excluded on this file), and the pre-existing bless-guard test (`MIX_RASTER_BLESS=true` outside `GITHUB_ACTIONS` raises) runs and passes unchanged.

## Task Commits

1. **Task 1: 3 combined pagination+60plus+odd-even raster fixtures (Invoice/Statement/Payslip)** — `91a1070` (test)
2. **Task 2: Certificate A4/Letter pair + Invoice extreme-wrap raster fixture** — `1fbb477` (test)

_Both tasks were `tdd="true"`; in this TEST/INFRA phase the tests ARE the deliverable, so each committed as a single `test(...)` commit, run green (compile + discovery) before commit._

## In-fence decision rationale (recorded per critical_constraints)

The six fixtures were added **in place** to the EXISTING `pdfium_raster_snapshot_test.exs` rather than a new file because the CI raster job invokes a hardcoded single explicit file path (`mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs`), not a tag-wide sweep (RESEARCH.md "Landmine 1"). Extending this exact file means the existing CI wiring discovers all six fixtures automatically with **zero `.github/workflows/ci.yml` edit**, keeping the phase's edit surface fenced to `test/`. The raster lane (`@tag raster_snapshot: true`, `async: false`) is reused verbatim per D-11.

## Raster ref blessing state (documented per critical_constraints)

**No raster refs were blessed in this environment — this is EXPECTED and acceptable.**

- `pdfium-cli` is not installed in this sandbox, and the environment is not the pinned `GITHUB_ACTIONS` container. `priv/raster_refs/` currently contains only the pre-existing `forms_support_fixture/` ref; no `priv/raster_refs/edge_*/` dirs exist.
- The six tests are authored **assert-only**. Run locally (`--include raster_snapshot`), they fail cleanly at the `Pdfium.render/2` stage with `{:error, {:missing_executable, "pdfium-cli"}}` — the same way the pre-existing `forms_support_fixture` test fails locally today.
- Actual `priv/raster_refs/<fixture>/page_N.sha256` blessing happens **once in the pinned CI container** via `MIX_RASTER_BLESS=true GITHUB_ACTIONS=true mix test --include raster_snapshot ...` (D-11), gated by the intact bless-guard. Raster hashes are not portable, so blessing them locally would be meaningless.
- Byte goldens (117-04) remain the gating signal; the raster lane is ADVISORY (excluded from default `mix test`), so this pending-bless state does not block the phase.

## Deviations from Plan

Minor, cosmetic, no scope impact:

**1. [Rule 3 — Blocking-verify] Test descriptions use the underscore fixture-name strings**
- **Found during:** Task 1 verification
- **Issue:** The plan's `<verify>` command greps the trace output for `edge_`, but human-readable ExUnit descriptions with spaces (`"edge invoice pagination ..."`) do not contain the underscore token, so the grep matched 0.
- **Fix:** Named each test description with the exact underscore fixture-name string (e.g. `test "edge_invoice_pagination_60plus_odd_even renders ..."`), making the trace output, the `assert_or_bless/2` argument, and the future `priv/raster_refs/<fixture>/` directory name read identically.
- **Files modified:** test/rendro/adapters/pdfium_raster_snapshot_test.exs
- **Committed in:** `91a1070`

No `lib/` changes. No new file. No `ci.yml` edit.

## Issues Encountered

- **pdfium-cli unavailable locally:** anticipated by the plan; raster verification is limited to compilation + test discovery in this sandbox. Both are green — all six fixtures compile under `--warnings-as-errors` and appear as distinct discovered tests.

## User Setup Required

None. Raster refs are blessed automatically in the pinned CI container; no local operator action.

## Known Stubs

None. Each fixture builds a real recipe-shaped document through the actual Rendro pipeline; the absent raster refs are an intentional, documented CI-blessing step (D-11), not a stub.

## Self-Check: PASSED

- `test/rendro/adapters/pdfium_raster_snapshot_test.exs` — FOUND (extended in place)
- 6 discovered edge fixtures — FOUND (`edge_invoice/statement/payslip_pagination_60plus_odd_even`, `edge_certificate_a4`, `edge_certificate_us_letter`, `edge_invoice_extreme_wrap`)
- Commit `91a1070` — FOUND
- Commit `1fbb477` — FOUND
- `mix compile --warnings-as-errors` — clean
- Default `mix test` on the file — raster lane excluded (7 excluded), bless-guard passes (1 test, 0 failures)
