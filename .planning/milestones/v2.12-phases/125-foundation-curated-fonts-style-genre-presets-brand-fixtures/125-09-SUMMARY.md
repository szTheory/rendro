---
phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
plan: 09
subsystem: testing
tags: [examples, fixtures, certificates, tickets, hex-package, docs-contract]
requires:
  - phase: 125
    provides: "Generic data-only brand schema and Invoice, Payslip, Statement, and Receipt fixture additions"
provides:
  - "Aster Institute and Meridian Arts Fellowship Certificate fixtures with safe local SVG marks"
  - "Field Notes Conference and The Letterpress Hall Ticket fixtures with safe local SVG marks"
  - "Non-vacuous six-domain corpus, original-byte, and Hex package contract"
affects: [127-public-example-catalog, example-fixtures, docs-contract]
tech-stack:
  added: []
  patterns: ["Fixture brands remain JSON plus local one-color SVG data; the docs contract owns corpus closure."]
key-files:
  created:
    - priv/examples/certificate/aster-institute/certificate.json
    - priv/examples/certificate/meridian-arts-fellowship/certificate.json
    - priv/examples/ticket/field-notes-conference/ticket.json
    - priv/examples/ticket/the-letterpress-hall/ticket.json
  modified:
    - test/docs_contract/examples_schema_contract_test.exs
key-decisions:
  - "Certificate and Ticket brands use the locked D-22 tuples and text-free, one-color local SVG geometry."
  - "A closed docs contract asserts exact twelve additions, three fixtures in each domain, six unchanged controls, and text-only Hex archive entries."
patterns-established:
  - "Use exact fixture paths and brand tuples rather than minimum-count assertions for bounded public corpus data."
requirements-completed: [CATALOG-05]
coverage:
  - id: D1
    description: "Certificate and Ticket each receive their two locked synthetic brand fixtures with safe local marks."
    requirement: CATALOG-05
    verification:
      - kind: unit
        ref: test/docs_contract/examples_schema_contract_test.exs#Certificate-and-Ticket-fixture-contracts
        status: pass
    human_judgment: false
  - id: D2
    description: "The six-domain fixture corpus has exactly twelve additions, preserves original fixture bytes, and packages examples as text-only files."
    requirement: CATALOG-05
    verification:
      - kind: integration
        ref: "mix test test/docs_contract/examples_schema_contract_test.exs test/rendro/examples_data_test.exs --max-failures 1 && mix hex.build"
        status: pass
    human_judgment: false
metrics:
  duration: 2min
  completed: 2026-08-17
status: complete
---

# Phase 125 Plan 09: Certificate and Ticket Fixture Corpus Summary

**Two realistic Certificate and Ticket brand pairs complete the twelve-fixture, six-domain data-only corpus with locked package and byte-integrity contracts.**

## Performance

- **Duration:** 2min
- **Started:** 2026-08-16T20:55:31-04:00
- **Completed:** 2026-08-17T00:57:37Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Added Aster Institute (Swiss) and Meridian Arts Fellowship (Editorial) Certificates with text-free one-color page-frame and seal marks.
- Added Field Notes Conference (Minimal-Mono) and The Letterpress Hall (Editorial) Tickets with registration-grid and ticket-stub marks.
- Closed the six-domain corpus contract around exact tuples and counts, unique data identities, safe local SVGs, original controls, data-only fixture trees, and text-only Hex archive entries.

## Task Commits

1. **Task 1: Add Aster Institute and Meridian Arts Fellowship certificates** - `57b2c61` (test), `4e5a9b6` (feat)
2. **Task 2: Add Ticket brands and close all corpus/package invariants** - `3c62294` (test), `1e15d09` (feat)

## Files Created/Modified

- `test/docs_contract/examples_schema_contract_test.exs` - Exact brand, corpus, original-byte, SVG, and package contracts.
- `priv/examples/certificate/aster-institute/` - Swiss technical credential data and local mark.
- `priv/examples/certificate/meridian-arts-fellowship/` - Editorial fellowship credential data and local seal.
- `priv/examples/ticket/field-notes-conference/` - Minimal-Mono conference admission data and local registration-grid mark.
- `priv/examples/ticket/the-letterpress-hall/` - Editorial cultural-event admission data and local ticket-stub mark.

## Decisions Made

- Kept the public corpus strictly data-only: JSON fixtures and safe local SVGs, with no fixture-specific modules, recipes, custom fonts, or remote assets.
- Made the final closure contract exact and non-vacuous: it names every new tuple and verifies both the twelve additions and the six original controls.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the corpus test's fixture path join direction**
- **Found during:** Task 2 (Add Ticket brands and close all corpus/package invariants)
- **Issue:** The contract attempted to read a valid fixture through a reversed `Path.join/2` result.
- **Fix:** Joined the `priv/examples` root to the relative fixture path in the correct order.
- **Files modified:** `test/docs_contract/examples_schema_contract_test.exs`
- **Verification:** Targeted docs-contract and data tests passed, followed by `mix hex.build` and format checking.
- **Committed in:** `1e15d09` (part of task commit)

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Required test correction only; no scope expansion.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 127 can select from exactly three locked fixture candidates in each of the six domains without adding fixture identities during catalog work.

## Self-Check: PASSED

All nine plan files exist, all four task commits are present, and the final targeted test, Hex-build, and formatting verification passed.

---
*Phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures*
*Completed: 2026-08-17*
