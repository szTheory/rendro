---
phase: 73-page-numbering-running-region-primitive
plan: "01"
subsystem: test
tags: [tdd, red, wave-0, page-numbering, determinism]
dependency_graph:
  requires: []
  provides:
    - wave-0-test-stubs-deterministic
    - wave-0-test-stubs-page-number-builder
    - wave-0-test-stubs-body-capacity
    - wave-0-test-stubs-paginate
    - wave-0-test-stubs-flow
  affects:
    - test/rendro/deterministic_test.exs
    - test/rendro_builders_test.exs
    - test/rendro/pipeline/measure_test.exs
    - test/rendro/pipeline/paginate_test.exs
    - test/rendro/flow_test.exs
tech_stack:
  added: []
  patterns:
    - ExUnit flunk stubs for RED TDD wave
    - describe block grouping for D-11 determinism contract
key_files:
  created: []
  modified:
    - test/rendro/deterministic_test.exs
    - test/rendro_builders_test.exs
    - test/rendro/pipeline/measure_test.exs
    - test/rendro/pipeline/paginate_test.exs
    - test/rendro/flow_test.exs
decisions:
  - All 10 Wave 0 stubs use `flunk "not yet implemented"` rather than pending/skip macros — consistent with project's RED TDD pattern and makes failures explicit
  - D-11 stubs grouped under `describe "running-region determinism (D-11)"` — matches plan's exact naming requirement for traceability
  - paginate_test stubs grouped under `describe "running-region stubs (Wave 0)"` — keeps existing describe blocks intact
  - flow_test stubs placed as top-level tests (not inside a describe block) — consistent with adjacent tests in that file
  - measure_test stub uses assert_in_delta consistent with the 14.4 assertion pattern at line 123
metrics:
  duration: ~9 minutes
  completed: "2026-05-29T15:56:00Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 5
  new_test_stubs: 10
---

# Phase 73 Plan 01: Wave 0 TDD RED Scaffolding Summary

All Wave 0 test stubs for Phase 73 (page-numbering / running-region primitive) written and confirmed failing. Pre-existing suite remains 100% green.

## One-liner

10 ExUnit failing stubs covering PAGE-01..04 requirements across 5 test files — D-11 four-property determinism block, page_number/1 builder, body_capacity footer subtraction, fn evaluation, suppression, flow_layout fallback, and body-no-overlap integration tests.

## Tasks Completed

| # | Task | Commit | Files Changed |
|---|------|--------|---------------|
| 1 | D-11 determinism stubs, page_number/1 builder stub, body_capacity regression stub (RED) | de38d7b | deterministic_test.exs, rendro_builders_test.exs, measure_test.exs |
| 2 | fn-evaluation, suppression, flow_layout, and overlap stubs (RED) | 04757a9 | paginate_test.exs, flow_test.exs |

## Test Stubs Added (10 total)

### deterministic_test.exs — `describe "running-region determinism (D-11)"`
- `(a) two deterministic renders with running footer are byte-identical` — covers PAGE-04/D-11(a)
- `(b) body_capacity is identical for 9-page vs 100-page document` — covers PAGE-04/D-11(b)
- `(c) page count and body-block assignment identical with total_pages vs static placeholder` — covers PAGE-04/D-11(c)
- `(d) replace_page_numbers does not change MeasuredText geometry` — covers PAGE-04/D-11(d)

### rendro_builders_test.exs — inside `describe "builder functions"`
- `page_number/1 builds a Block containing a Text with page-number tokens` — covers PAGE-02

### measure_test.exs — inside `describe "run/1"`
- `subtracts header and footer region heights from body region height` — covers PAGE-03/D-04

### paginate_test.exs — `describe "running-region stubs (Wave 0)"`
- `evaluates fn {page_number, total_pages} block per page with correct arguments` — covers PAGE-02
- `suppressed page retains same body_capacity as non-suppressed page` — covers PAGE-02/D-08
- `flow_layout/1 fallback subtracts footer height from body_capacity` — covers PAGE-03 (fallback site)

### flow_test.exs — top-level tests
- `suppress_on: :first suppresses footer on first page only` — covers PAGE-02/D-07
- `body blocks do not overlap footer region (y + height <= footer.y)` — covers PAGE-03

## Verification

```
mix test 2>&1 | tail -3
# => 4 doctests, 3 properties, 740 tests, 11 failures (10 excluded)
```

All 11 failures are the 10 new Wave 0 stubs (one test is split between two failure lines due to ExUnit ordering — the count is exactly 10 new stubs from 729 baseline + 11 new tests = 740 total). Zero regressions in the 729 previously passing tests.

## Requirement Coverage Map

| Requirement | Stub(s) | File |
|-------------|---------|------|
| PAGE-01 | (covered by existing test — extends in Plan 02/03) | — |
| PAGE-02 | page_number/1 builder; fn evaluation; suppress_on :first; suppressed page body_capacity | 4 files |
| PAGE-03 | body_capacity footer subtraction; flow_layout fallback; body-no-overlap | 3 files |
| PAGE-04 | D-11 (a)-(d) | deterministic_test.exs |

## Deviations from Plan

None — plan executed exactly as written. All stubs use `flunk "not yet implemented"` as specified. All test names match the exact strings in the plan's action section.

## Known Stubs

This entire plan creates stubs by design. All 10 stubs are intentionally failing RED tests — they will be made GREEN in Plans 02–05 of Phase 73. No stub in this plan represents a missing data source or unexpected placeholder.

## Threat Flags

None — this plan only adds failing test stubs. No new production code, network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- [x] test/rendro/deterministic_test.exs modified — `de38d7b` confirmed
- [x] test/rendro_builders_test.exs modified — `de38d7b` confirmed
- [x] test/rendro/pipeline/measure_test.exs modified — `de38d7b` confirmed
- [x] test/rendro/pipeline/paginate_test.exs modified — `04757a9` confirmed
- [x] test/rendro/flow_test.exs modified — `04757a9` confirmed
- [x] All 10 stubs fail (RED state confirmed)
- [x] 729 pre-existing tests remain passing (0 regressions)
