---
phase: 117-edge-case-stress-matrix
plan: 04
subsystem: testing
tags: [edge-matrix, golden-files, sha256, determinism, coverage-honesty, elixir]

# Dependency graph
requires:
  - phase: 117-01
    provides: "Rendro.Test.Golden.assert_deterministic!/1 + assert_or_bless/2 — the un-gated byte-golden helper each :applies cell consumes"
  - phase: 117-02
    provides: "Rendro.Test.EdgeFixtures.document/2 — the {family, dimension} -> recipe-shaped document dispatch every :applies cell renders"
provides:
  - "Rendro.EdgeMatrixTest — the phase's central @matrix (102-entry family × stress-dimension grid, 62 :applies / 40 N/A) plus the D-02 coverage-honesty meta-test and 62 generated golden byte-identity tests"
  - "Rendro.EdgeMatrixTest.stress_fixture_ids/0 — public MapSet of the 62 :applies 'family/dimension' string IDs; 117-07's D-15 rubric-exemption disjointness guard imports this as its single source of truth"
  - "priv/goldens/<family>/<dimension>.sha256 — 62 committed one-line SHA-256 refs (no PDF bytes)"
affects: [117-06-raster-snapshot, 117-07-rubric-exemption, edge-case-stress-matrix]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Row-based @matrix construction (zip each {dimension, [6 values]} row against @families) so a short/long row structurally drops a pair the D-02 meta-test then catches — defense-in-depth against transcription drift"
    - "Module-scope for-comprehension over :applies cells generating one named ExUnit test per cell via unquote/1 of the compile-time comprehension variables"
    - "Repeated N/A reason strings promoted to module attributes so one shared root cause reads byte-identical everywhere it recurs"

key-files:
  created:
    - test/rendro/edge_matrix_test.exs
    - priv/goldens/**/*.sha256 (62 files)
  modified: []

key-decisions:
  - "Built @matrix by zipping row-vectors against @families rather than hand-writing 102 literal {family, dimension} keys — reduces transcription surface while the D-02 meta-test still independently machine-checks exhaustiveness."
  - "Blessed all 62 priv/goldens refs in a single deliberate MIX_GOLDEN_BLESS=true run (the D-04 human/CI authoring gesture); committed hash files only, never PDF bytes."

requirements-completed: [EDGE-01]

coverage:
  - id: M1
    description: "Every one of the 102 {family, dimension} pairs has a @matrix entry (:applies or an N/A reason string); a coverage gap cannot masquerade as coverage (D-02)"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/rendro/edge_matrix_test.exs#every {family, dimension} pair has a @matrix entry"
        status: pass
    human_judgment: false
  - id: M2
    description: "@matrix has exactly 102 entries and exactly 62 are :applies (transcription tripwires)"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/rendro/edge_matrix_test.exs#the matrix has exactly 102 entries / exactly 62 cells are :applies"
        status: pass
    human_judgment: false
  - id: M3
    description: "Every :applies cell (62) renders a deterministic golden PDF verified by SHA-256 against a committed priv/goldens/<family>/<dimension>.sha256 ref; two-run determinism is proven before any hash is taken (D-04)"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/rendro/edge_matrix_test.exs#<family>/<dimension> golden byte-identity (62 generated tests)"
        status: pass
    human_judgment: false
  - id: M4
    description: "A missing golden ref hard-flunks rather than silently auto-creating (inherited from 117-01's Rendro.Test.Golden)"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "pre-bless `mix test test/rendro/edge_matrix_test.exs` — 62 clean 'Missing golden ref' flunks, no crashes"
        status: pass
    human_judgment: false
  - id: M5
    description: "stress_fixture_ids/0 returns a 62-element MapSet of 'family/dimension' strings for 117-07 to import"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "derived from the same :applies filter the count-sanity test (==62) machine-checks"
        status: pass
    human_judgment: false

# Metrics
duration: ~3min
completed: 2026-07-19
status: complete
---

# Phase 117 Plan 04: Family × Stress-Dimension Golden Matrix Summary

**Authored `Rendro.EdgeMatrixTest` — the phase's central, machine-checked-honest @matrix mapping all 102 {family, dimension} pairs to `:applies` or an N/A reason string, with a D-02 coverage-honesty meta-test, two transcription tripwires, a public `stress_fixture_ids/0`, and 62 data-driven golden byte-identity tests blessed against committed hash-only refs — zero `lib/` edits.**

## Performance
- **Duration:** ~3 min
- **Completed:** 2026-07-19
- **Tasks:** 2 of 2
- **Files modified:** 1 test file created + 62 golden ref files created

## Accomplishments
- `@matrix` (102 entries): the full 17-dimension × 6-family grid transcribed verbatim from RESEARCH.md's resolved N/A table — 62 `:applies`, 40 genuinely-N/A reason strings (including the Receipt-genuinely-paginates correction: Receipt's pagination/line-item/60+ cells are `:applies`).
- D-02 coverage-honesty meta-test asserts `@matrix`'s own exhaustiveness against the cross product `@families × @dimensions`, so a future new family or dimension lacking an entry fails the suite immediately.
- Two count-sanity tripwires (`map_size == 102`, `:applies count == 62`) catch silent transcription drift.
- `stress_fixture_ids/0` — public (not a `test`) — returns a 62-element `MapSet` of `"family/dimension"` IDs, the single source of truth 117-07's D-15 disjointness guard will import.
- 62 generated golden byte-identity tests, one per `:applies` cell: `EdgeFixtures.document/2` → `Golden.assert_deterministic!/1` (two-run determinism proven BEFORE any hash) → `Golden.assert_or_bless/2`.
- Blessed 62 `priv/goldens/<family>/<dimension>.sha256` refs (one lowercase-hex line + `\n`, no PDF bytes) via one deliberate `MIX_GOLDEN_BLESS=true` gesture; assert-only `mix test` is fully green (65 tests: 1 meta + 2 count-sanity + 62 golden).

## Task Commits
1. **Task 1: @matrix + D-02 coverage-honesty meta-test + count-sanity + stress_fixture_ids/0** — `246e8e6` (test)
2. **Task 2: 62 data-driven golden byte-identity tests + blessed priv/goldens refs** — `a8e5897` (feat)

_Both tasks were `tdd="true"`; for this test-authoring plan the tests ARE the artifact (the file generates its own assertions), so each task's tests were run green before commit._

## Files Created/Modified
- `test/rendro/edge_matrix_test.exs` — `Rendro.EdgeMatrixTest` (`async: true`): `@families`, `@dimensions`, `@matrix`, byte-vs-raster split comment (D-09/D-10), D-02 meta-test, 2 count-sanity tests, `stress_fixture_ids/0`, and the 62-cell golden comprehension.
- `priv/goldens/**/*.sha256` — 62 committed hash-only refs (no PDF bytes).

## Decisions Made
See `key-decisions` frontmatter. Load-bearing: row-vector `@matrix` construction (transcription-error resistant, still independently exhaustiveness-checked) and the single deliberate bless run committing hash files only.

## Deviations from Plan
None — plan executed exactly as written. Both wave-1 dependencies (`Rendro.Test.Golden` from 117-01, `Rendro.Test.EdgeFixtures.document/2` from 117-02) matched their documented contracts; every `:applies` cell rendered deterministically and blessed on the first attempt.

## Issues Encountered
None. Pre-bless run produced 62 clean "Missing golden ref" hard-flunks (never crashes), confirming the D-04 missing-ref discipline; the bless run and the subsequent assert-only run were both green.

## User Setup Required
None — no external service configuration required.

## Known Stubs
None. Every `:applies` cell renders a real recipe-shaped document through the actual pipeline and is hash-verified; N/A pairs carry an explicit human-readable reason and are never rendered.

## Threat Flags
None. `test/rendro/edge_matrix_test.exs` is a pure test-data table plus generated assertions over already-shipped `lib/` recipe output — no untrusted input, no network, no new runtime surface. The two count-sanity tests fulfill the T-117-04-01 transcription-accuracy mitigation from the plan's threat register.

## Next Phase Readiness
- `stress_fixture_ids/0` is ready for 117-07's rubric-exemption disjointness guard (D-15) to import as its single source of truth.
- The byte-vs-raster split comment enumerates the exactly-6 curated cells 117-06 will additionally raster-check ({invoice,statement,payslip} × odd_even_running_content, certificate × page_size_a4_letter, invoice × text_wrap).
- `priv/goldens/` is excluded from the Hex tarball by construction (mix.exs `files:` allowlist); 117's D-12 tarball-guard test is a separate plan's tail item.
- Zero `lib/` changes — posture-clean, test/priv-only.

## Self-Check: PASSED
- `test/rendro/edge_matrix_test.exs` — FOUND
- `priv/goldens/**/*.sha256` — 62 files FOUND (all one 64-char lowercase-hex line + newline, no PDF bytes)
- Commit `246e8e6` — FOUND
- Commit `a8e5897` — FOUND
- No file deletions in either task commit
- Assert-only `mix test test/rendro/edge_matrix_test.exs` — 65 tests, 0 failures

---
*Phase: 117-edge-case-stress-matrix*
*Completed: 2026-07-19*
