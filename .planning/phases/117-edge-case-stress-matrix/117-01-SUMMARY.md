---
phase: 117-edge-case-stress-matrix
plan: 01
subsystem: testing
tags: [golden-files, sha256, determinism, test-support, edge-matrix, elixir]

# Dependency graph
requires:
  - phase: 116-payslip-ticket-families
    provides: "deterministic Rendro.render/2 (fixed epoch + sorted dict keys + embedded fonts) that makes PDF-byte hashes cross-platform stable"
provides:
  - "Rendro.Test.Golden.assert_deterministic!/1 — two-run deterministic byte-identity pre-check returning the PDF bytes"
  - "Rendro.Test.Golden.assert_or_bless/3 — un-gated SHA-256 compare-or-bless with missing-ref hard-flunk and DEFECT-not-refresh doctrine"
  - "MIX_GOLDEN_BLESS / MIX_GOLDEN_DUMP env-var contract for the whole 117 golden lane"
affects: [117-04-edge-matrix, 117-06-raster-snapshot, edge-case-stress-matrix]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Un-gated byte-golden assert/bless (sibling of the GITHUB_ACTIONS-gated raster assert_or_bless)"
    - "Missing-ref hard-flunk (inverse of Jest -u auto-bless footgun)"
    - "Two-run determinism pre-check before any hash is taken or blessed"

key-files:
  created:
    - test/support/golden.ex
    - test/support/golden_test.exs
  modified: []

key-decisions:
  - "Resolved the PATTERNS.md namespace ambiguity in favor of Rendro.Test.* (matching Rendro.Test.HexBuildCache), not Rendro.TestSupport.*"
  - "Verified the default base_dir (priv/goldens) via a read-only missing-ref flunk on a guaranteed-nonexistent pair — never writing to the real committed tree"

patterns-established:
  - "Pattern 1: byte-SHA-256 golden refs are hash-only, one lowercase-hex line + \\n, at <base_dir>/<family>/<dimension>.sha256"
  - "Pattern 2: bless is un-gated (MIX_GOLDEN_BLESS=true) because PDF-byte hashes are cross-platform stable; refresh is an explicit human gesture"
  - "Pattern 3: MIX_GOLDEN_DUMP writes raw PDF bytes to a gitignored scratch dir for eyeballing, with zero effect on the assert/bless/flunk outcome"

requirements-completed: [EDGE-01]

coverage:
  - id: D1
    description: "assert_deterministic!/1 renders twice with deterministic: true, asserts byte-equality, returns the PDF bytes"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/support/golden_test.exs#assert_deterministic!/1 renders twice with deterministic: true and returns the byte-identical PDF"
        status: pass
    human_judgment: false
  - id: D2
    description: "assert_or_bless/3 hard-flunks on a missing ref (never silent auto-create) with 'Missing golden ref' and the exact path"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/support/golden_test.exs#hard-flunks with 'Missing golden ref' and the exact path, writing nothing"
        status: pass
    human_judgment: false
  - id: D3
    description: "assert_or_bless/3 un-gated bless writes lowercase-hex sha256 + newline and returns :ok (no GITHUB_ACTIONS gate)"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/support/golden_test.exs#writes lowercase-hex sha256 + newline, creating the dir, and returns :ok"
        status: pass
    human_judgment: false
  - id: D4
    description: "assert_or_bless/3 passes on hash match and fails with 'Golden hash mismatch' + DEFECT-not-refresh doctrine on mismatch"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/support/golden_test.exs#returns :ok when the stored hash matches / fails with 'Golden hash mismatch'"
        status: pass
    human_judgment: false
  - id: D5
    description: "MIX_GOLDEN_DUMP writes raw PDF bytes to a scratch dir when set (no-op unset), never altering the assert/bless/flunk outcome"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/support/golden_test.exs#MIX_GOLDEN_DUMP escape hatch (3 cases: set / unset / mismatch-still-fails)"
        status: pass
    human_judgment: false

# Metrics
duration: ~18min
completed: 2026-07-19
status: complete
---

# Phase 117 Plan 01: Byte-Golden assert/bless Helper Summary

**`Rendro.Test.Golden` — the un-gated byte-SHA-256 assert/bless helper with a two-run determinism pre-check, missing-ref hard-flunk, and a MIX_GOLDEN_DUMP eyeball escape hatch, self-tested in isolation.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-07-19
- **Completed:** 2026-07-19
- **Tasks:** 2
- **Files modified:** 2 (both created)

## Accomplishments
- `Rendro.Test.Golden.assert_deterministic!/1`: renders a document twice with `deterministic: true`, asserts byte-equality (so a non-determinism leak can never be blessed into a ref), returns the PDF bytes.
- `Rendro.Test.Golden.assert_or_bless/3`: SHA-256 compare-or-bless against `priv/goldens/<family>/<dimension>.sha256`, **un-gated** (no `GITHUB_ACTIONS` check — byte hashes are cross-platform stable), with a **missing-ref hard-flunk** (never a silent auto-create) and a "a hash change is a DEFECT, not a refresh" mismatch doctrine.
- `MIX_GOLDEN_DUMP=<dir>` escape hatch: dumps raw PDF bytes to a gitignored scratch dir for human eyeballing, with zero effect on the assert/bless/flunk decision.
- `test/support/golden_test.exs`: 9 passing self-tests covering all five behavior cases plus the three dump cases; never writes into the real `priv/goldens/` tree (every call uses a temp `base_dir` cleaned up via `on_exit`).

## Task Commits

Each task was committed atomically (TDD: test → feat):

1. **Task 1: assert_deterministic!/1 + assert_or_bless/3 core dispatch**
   - `20fb547` (test) — failing self-test for the core helper
   - `0f00306` (feat) — implementation
2. **Task 2: MIX_GOLDEN_DUMP eyeball escape hatch**
   - `d794cf2` (test) — failing self-test for the dump hatch
   - `9d96953` (feat) — implementation

## Files Created/Modified
- `test/support/golden.ex` - `Rendro.Test.Golden` (`@moduledoc false`, `@spec`-annotated): `assert_deterministic!/1`, `assert_or_bless/3`, private `maybe_dump/3`.
- `test/support/golden_test.exs` - `Rendro.Test.GoldenTest` (`async: false`): env-var-safe self-test of both public functions + the dump hatch.

## Decisions Made
- **Namespace:** used `Rendro.Test.*` (matching the sibling self-tested support module `Rendro.Test.HexBuildCache`), NOT the unrelated `Rendro.TestSupport.*` namespace — per the task's explicit instruction to not introduce a third namespace.
- **Default base_dir verification:** proved the `priv/goldens` default via a read-only missing-ref flunk on a guaranteed-nonexistent `{:__nonexistent_family__, :__nonexistent_dimension__}` pair. This asserts the computed path is rooted at `priv/goldens` while writing nothing and modifying nothing under the real committed tree (`git status --porcelain priv/goldens` stays clean).
- **Dump placement:** `maybe_dump/3` runs before the `cond` (before any bless/assert/flunk branch), making the eyeball dump unconditional on and independent of the outcome, exactly as the task specified.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `Rendro.Test.Golden.assert_deterministic!/1` and `assert_or_bless/3` are the load-bearing dependency for 117-04 (the 62-cell family × stress-dimension golden matrix) and are reused by 117-06 (raster snapshot determinism pre-check). Both are ready.
- Zero `lib/` changes — posture-clean, test/support-only.
- No `priv/goldens/` files were committed (hashes are authored later, per case, via `MIX_GOLDEN_BLESS=true`).

## Self-Check: PASSED

- Files verified present: `test/support/golden.ex`, `test/support/golden_test.exs`, `117-01-SUMMARY.md`
- Commits verified present: `20fb547`, `0f00306`, `d794cf2`, `9d96953`

---
*Phase: 117-edge-case-stress-matrix*
*Completed: 2026-07-19*
