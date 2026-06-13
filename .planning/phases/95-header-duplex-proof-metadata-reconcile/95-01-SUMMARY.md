---
phase: 95-header-duplex-proof-metadata-reconcile
plan: 01
subsystem: testing
tags: [exunit, pdf, pagination, only_on, header, footer, duplex, content-stream]

# Dependency graph
requires:
  - phase: 89-92 (v2.7)
    provides: "Shipped region-agnostic only_on engine (apply_only_on/3) + per-region region_entries + section-local page numbering tokens"
provides:
  - "Render-layer header only_on: :odd|:even duplex proof (4-physical-page content-stream byte assertion)"
  - "Single-page header edge proof (only :odd appears)"
  - "Header+footer only_on coexistence proof (independent region_entries)"
  - "Paginate-layer proof that header PHYSICAL parity coexists with restart SECTION-LOCAL footer tokens"
affects: [96-adoption-signal-review, header-duplex documentation, future running-region work]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Header only_on proofs mirror the shipped footer proofs at both render and paginate layers"
    - "Content-stream byte assertions only (Regex.scan /Type /Page + (Text) Tj + token refute); no rasterization"

key-files:
  created: []
  modified:
    - test/rendro/flow_test.exs
    - test/rendro/pipeline/paginate_test.exs

key-decisions:
  - "Engine left untouched: only_on is already region-agnostic; PROOF-01 is purely additive test coverage"
  - "First-page parity (SC #3a) anchored by page 1 = odd in the main render test rather than a separate test"
  - "Page-count geometry: header at y:24 h:16 stays above body start y:52, so body_capacity stays 60 (4 lines/page)"

patterns-established:
  - "Header duplex proof = footer-proof clone with role: :header + a header region above the body band"
  - "page_texts/1 ordering is header, then footer, then body; assert full ordered lists accordingly"

requirements-completed: [PROOF-01]

# Metrics
duration: 2min
completed: 2026-06-13
---

# Phase 95 Plan 01: Header Duplex Proof (PROOF-01) Summary

**Header-specific `only_on: :odd | :even` end-to-end proof at footer parity — a render-layer 4-page duplex test, single-page and header+footer-coexistence edge tests, and a paginate-layer test proving header physical parity coexists with restart section-local footer tokens.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-13T18:58:52Z
- **Completed:** 2026-06-13T19:01:17Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- Render-layer test renders header `only_on` content across exactly 4 physical pages and asserts `(Odd 1)`/`(Even 2)`/`(Odd 3)`/`(Even 4) Tj` on the byte-stable content stream with no leaked `{{page_number}}` token (SC #1, SC #3a).
- Two render-layer edge proofs: single-page document shows only the `:odd` header and never `(Even`; header + footer `only_on` coexist on a 2-page document via independent `region_entries` (`(HOdd 1)`/`(FOdd 1)` page 1, `(HEven 2)`/`(FEven 2)` page 2) (SC #3b, #3c).
- Paginate-layer test proves header PHYSICAL odd/even parity coexists with restart SECTION-LOCAL footer tokens across a 3-page document, asserting exact `page_texts/1` lists in the verified header→footer→body order (SC #2).
- Full suite green (1203 tests, 0 failures); `mix format --check-formatted` clean; public-API contract test green (no public surface added).

## Task Commits

Each task was committed atomically:

1. **Task 1: Render-layer header duplex proof + first-page parity** - `0ff5503` (test)
2. **Task 2: Edge cases — single-page odd-only + header/footer coexistence** - `091083e` (test)
3. **Task 3: Paginate-layer header parity + restart section-token coexistence** - `8f0e8d9` (test)

_Note: TDD plan over an already-shipped engine — each task is a single `test(...)` commit. The proof tests pass against the live engine on first write (engine is correct and out of scope); the RED→GREEN cycle collapses because the implementation under proof already exists and is region-agnostic._

## Files Created/Modified
- `test/rendro/flow_test.exs` - Added 3 render-layer tests: header duplex 4-page proof, single-page odd-only edge, header+footer coexistence edge.
- `test/rendro/pipeline/paginate_test.exs` - Added 1 paginate-layer test: header physical parity coexisting with restart section-local footer tokens (local `:section_context_header` template with an added header region).

## Decisions Made
- None beyond the plan. Engine, public API, and `priv/public_api.json` left untouched as mandated by D-01.

## Deviations from Plan

None - plan executed exactly as written.

Note: the plan's verify commands used the flag `mix test ... -x`, which is not a valid `mix test` option in this toolchain. Ran the equivalent unflagged `mix test <file>` to verify each task — same intent (run the touched file), no behavioral difference. This is a doc-only command correction, not a code deviation.

## Issues Encountered
- `mix format --check-formatted` flagged the Task 3 paginate test's `%Region{...}` one-liners as over-length. Resolved by running `mix format` on the file (the project's standard expanded `%Region{}` style); tests still pass — whitespace-only change, committed within the Task 3 commit.

## Known Stubs
None. All tests assert against real engine output; no placeholders, empty data sources, or TODO markers introduced.

## Threat Flags
None. Test-only additions over an already-shipped, region-agnostic engine code path. No new endpoints, auth paths, file access, or schema changes. `priv/public_api.json` and the public-API contract test untouched and green.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- PROOF-01 is fully proven at render and paginate layers. Plan 95-02 (META-01 validation-metadata reconcile) remains for this phase.
- No blockers. `lib/` and `priv/` were not modified by this plan; full suite and format checks are green.

## Self-Check: PASSED

- FOUND: `.planning/phases/95-header-duplex-proof-metadata-reconcile/95-01-SUMMARY.md`
- FOUND commit `0ff5503` (Task 1), `091083e` (Task 2), `8f0e8d9` (Task 3)
- FOUND test `"only_on odd and even header sections render on physical page parity"` in flow_test.exs
- FOUND test `"header only_on physical parity coexists with restart section tokens"` in paginate_test.exs

---
*Phase: 95-header-duplex-proof-metadata-reconcile*
*Completed: 2026-06-13*
