---
phase: 73-page-numbering-running-region-primitive
plan: "05"
subsystem: test
tags: [tdd, green, wave-5, page-numbering, determinism, PAGE-04]

dependency_graph:
  requires:
    - phase: 73-04
      provides: "RunningContent fn primitive, suppress_on, page_number/1 — pipeline complete"
  provides:
    - D-11(a) byte-identical determinism proof for running-footer documents
    - D-11(b) body_capacity geometry-independence proof (9-page vs 100-page → same capacity)
    - D-11(c) page-count and body-block-assignment invariance ({{total_pages}} vs static placeholder)
    - D-11(d) MeasuredText geometry freeze proof (run widths and block height unchanged post-substitution)
    - PAGE-04 requirement fully satisfied
  affects:
    - "Phase 74-76: PAGE primitive proven deterministic; recipes can build on it"

tech_stack:
  added: []
  patterns:
    - running_footer_doc/1 helper — small-body explicit template, 60-line body for multi-page
    - measure_body_capacity/1 helper — Build→Compose→Measure pipeline to read layout.body_capacity
    - body_block_counts/1 helper — per-page body block count extraction via source content heuristic
    - find_footer_block/1 helper — locates MeasuredText footer block from page.blocks
    - footer_run_widths/1 helper — extracts run widths from MeasuredText lines for geometry guard

key_files:
  created: []
  modified:
    - test/rendro/deterministic_test.exs

decisions:
  - "D-11(b) uses 9 vs 100 body lines rather than exact page counts to remain independent of per-font line heights; both documents use the same explicit template so geometry is identical"
  - "running_footer_doc/1 uses a small 300-height template with 220-height body region and 20-height footer — this ensures body blocks paginate quickly (generates 2+ pages with 60 lines)"
  - "D-11(d) compares run widths across page 1 vs page 2 of the same document — both are post-substitution but measured from the same source token, so widths must be identical; this guards against any future re-measure-on-substitute"
  - "body_block? helper uses source.content string heuristic (contains 'Page' and 'of') to distinguish footer blocks from body blocks — fragile but sufficient for this test's controlled document"
  - "measure_body_capacity/1 uses footer_height=30 (different from 20 in running_footer_doc) to confirm subtraction is correct for arbitrary heights"

metrics:
  duration: ~4 minutes
  completed: "2026-05-29T16:25:47Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
  new_tests_green: 4
---

# Phase 73 Plan 05: D-11 Determinism Proofs (PAGE-04 Closed)

**Four D-11 determinism assertions GREEN — byte-identity, geometry-independence, substitution-invariance, and geometry-freeze all proven. Full `mix test` suite exits 0. PAGE-04 requirement satisfied. Phase 73 complete.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-05-29T16:22:00Z
- **Completed:** 2026-05-29T16:25:47Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Implemented D-11(a): `running_footer_doc/1` builds a 2-page flow doc with `"Page {{page_number}} of {{total_pages}}"` footer section; renders twice with `deterministic: true`; asserts `pdf1 == pdf2` and confirms `"(Page 1 of"` in output
- Implemented D-11(b): `measure_body_capacity/1` runs `Build.run/1 → Compose.run/1 → Measure.run/1` on docs with 9 and 100 body lines using footer_height=30; asserts `assert_in_delta cap_9, cap_100, 1.0e-9` — proves `body_capacity` is pure geometry
- Implemented D-11(c): builds two docs differing only in footer text (`{{total_pages}}` vs `"999"`); runs full pipeline; asserts `length(pages)` and per-page `body_block_counts` are identical — proves token presence does not affect pagination
- Implemented D-11(d): runs full pipeline on running_footer_doc; extracts footer run widths from page 1 and page 2; asserts `runs1 == runs2` and `footer1.height == footer2.height` — proves geometry is frozen post-substitution, regression guard for D-10
- Added 5 private helper functions: `running_footer_doc/1`, `measure_body_capacity/1`, `body_block_counts/1`, `find_footer_block/1`, `footer_run_widths/1`

## Task Commits

| # | Task | Commit | Files Changed |
|---|------|--------|---------------|
| 1 | D-11(a) and D-11(b) implementation (byte-identity and body_capacity invariance) | 59d6359 | deterministic_test.exs |
| 2 | D-11(c) and D-11(d) implementation; full suite confirmation (PAGE-04 closed) | 59d6359 | (same commit — both tasks implemented together) |

## Verification Results

```
mix test test/rendro/deterministic_test.exs
# => 3 properties, 12 tests, 0 failures

mix test
# => 4 doctests, 3 properties, 741 tests, 0 failures (10 excluded)

grep -rn "flunk" test/rendro/deterministic_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs test/rendro_builders_test.exs
# => (no output — zero flunk stubs remaining)
```

## Decisions Made

**D-11(d) geometry guard approach:** The plan offered two options — compare run widths to "back-substituted" token widths, or compare widths across page 1 vs page 2. The cross-page comparison was chosen because it is directly observable from the paginated output without needing to re-invoke the measure stage or maintain a pre-substitution snapshot. Since `run.width` is measured from the token string at measure time (D-10), both pages receive the same token-length width regardless of the substituted digit string — so `page1_widths == page2_widths` directly proves the geometry-freeze invariant.

**body_block? heuristic:** Footer blocks post-substitution have source.content containing `"Page N of M"`. Body blocks contain `"Line N"`. The string heuristic is sufficient for the controlled test document. A more robust approach (e.g., checking block coordinates against the footer region) would require template geometry access inside the helper; the string heuristic is simpler and avoids coupling to page layout.

## Deviations from Plan

None — plan executed exactly as written. Both tasks were implemented in a single commit since the tests are closely related and task 2 depended on helpers from task 1.

## Requirement Coverage

| Requirement | Test(s) | Result |
|-------------|---------|--------|
| PAGE-04 | D-11(a), D-11(b), D-11(c), D-11(d) | GREEN |
| PAGE-01..03 | Prior plans 02, 03, 04 | GREEN (unchanged) |

## Phase 73 Completion

All PAGE-01..04 requirements are satisfied:
- **PAGE-01**: `{{total_pages}}` single-pass substitution — proven in plan 03 integration test + D-11(c)
- **PAGE-02**: RunningContent fn primitive, suppress_on, page_number/1 — proven in plan 04
- **PAGE-03**: body_capacity subtracts header/footer heights — proven in plan 02 + D-11(b)
- **PAGE-04**: Byte-identical determinism, geometry-independence, substitution-invariance — proven in D-11(a-d)

## Threat Flags

None — test-only changes. No new external input surface.

## Self-Check: PASSED

- [x] test/rendro/deterministic_test.exs modified — `59d6359` confirmed
- [x] All 4 D-11 tests pass GREEN (12 tests, 0 failures)
- [x] Full `mix test` suite: 741 tests, 0 failures
- [x] Zero `flunk` stubs in any Phase 73 test file
- [x] D-11(a): `pdf1 == pdf2` byte-identical assertion confirmed
- [x] D-11(b): `assert_in_delta cap_9, cap_100, 1.0e-9` confirmed
- [x] D-11(c): page count and body-block-count lists identical confirmed
- [x] D-11(d): run widths and block height identical across pages confirmed
