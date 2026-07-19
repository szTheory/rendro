---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
plan: 02
subsystem: docs
tags: [domain-anatomy, rubric, docs-contract, examples, exunit]

# Dependency graph
requires:
  - phase: 114-domain-research-rubric-example-data-library
    provides: invoice/DOMAIN.md four-heading anchor + the domain_md_contract_test.exs glob contract
  - phase: 118-01
    provides: the six per-family fixtures under priv/examples/*/*/*.json that seed the demonstrated-domain derivation
provides:
  - Five co-located DOMAIN.md anatomy files (statement, receipt, certificate, payslip, ticket) each carrying the four required D-04 headings
  - A strengthened DomainMdContractTest that requires a DOMAIN.md per demonstrated domain (derived from fixture dirs, not hardcoded)
affects: [118-06, rubric-gated-demos, D-05-demo-cites-DOMAIN.md]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Demonstrated-domain set derived from priv/examples/*/*/*.json fixture dirs so future domains inherit the DOMAIN.md contract automatically"
    - "ONE-fact-first persona framing per domain (closing balance / amount paid / recipient / net pay / placement)"

key-files:
  created:
    - priv/examples/statement/DOMAIN.md
    - priv/examples/receipt/DOMAIN.md
    - priv/examples/certificate/DOMAIN.md
    - priv/examples/payslip/DOMAIN.md
    - priv/examples/ticket/DOMAIN.md
  modified:
    - test/docs_contract/domain_md_contract_test.exs

key-decisions:
  - "Per-domain assertion derives the demonstrated-domain set from priv/examples/*/*/*.json (not a hardcoded family list) so future families inherit the contract"
  - "Added a non-vacuous guard asserting the derived domain set is non-empty, so the per-domain loop can never pass trivially"
  - "Domain prose held to information-design craft — no accessibility/tagged-PDF/screen-reader claims (T-118-03, D-14 tripwire)"

patterns-established:
  - "Disk-derived contract: test asserts one artifact per demonstrated domain, discovered from fixtures rather than enumerated"
  - "DOMAIN.md section shape mirrors invoice/DOMAIN.md exactly: Domain Language (Nouns + Verbs/events), Personas & JTBD (ONE fact first), Reading Context, Layout & Typographic Conventions"

requirements-completed: [SHOW-01]

coverage:
  - id: D1
    description: "Five new domains each have a co-located DOMAIN.md carrying all four required headings (D-04)"
    requirement: "SHOW-01"
    verification:
      - kind: unit
        ref: "test/docs_contract/domain_md_contract_test.exs#every DOMAIN.md carries all four required section headings"
        status: pass
    human_judgment: false
  - id: D2
    description: "DomainMdContractTest requires a DOMAIN.md per demonstrated domain, derived from fixture dirs (teeth verified: removing any DOMAIN.md fails)"
    requirement: "SHOW-01"
    verification:
      - kind: unit
        ref: "test/docs_contract/domain_md_contract_test.exs#every demonstrated domain has a co-located DOMAIN.md (D-04)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Domain prose is faithful to how each business document is actually read and used, with no accessibility overclaims"
    verification:
      - kind: manual_procedural
        ref: "grep -rniE 'tagged.pdf|pdf-ua|screen.reader|reading.order|accessib|wcag' priv/examples/*/DOMAIN.md (empty)"
        status: pass
    human_judgment: true
    rationale: "Domain faithfulness (does each DOMAIN.md correctly encode its domain's language, readers, and layout grammar) is an information-design judgment the rubric scores demos against — reserved for phase verification / human sanity-check, mirroring the 114-05 precedent."

# Metrics
duration: 3min
completed: 2026-07-19
status: complete
---

# Phase 118 Plan 02: Domain Anatomy Docs & Strengthened DOMAIN.md Contract Summary

**Five co-located four-heading DOMAIN.md anatomy files (statement, receipt, certificate, payslip, ticket) plus a DomainMdContractTest strengthened from "at least one" to "one per demonstrated domain" derived from fixture dirs.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-19T15:45:34Z
- **Completed:** 2026-07-19T15:48:55Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Authored five DOMAIN.md files, each mirroring invoice/DOMAIN.md's section shape with domain-accurate language sourced from the recipes and fixtures, and ONE-fact-first personas (statement → closing balance; receipt → amount paid + proof; certificate → recipient + credential; payslip → net pay; ticket → placement).
- Strengthened the D-04 contract from "at least one DOMAIN.md exists" to "a DOMAIN.md exists per demonstrated domain," deriving the domain set from `priv/examples/*/*/*.json` so future families inherit the contract without a hardcoded list.
- Added a non-vacuous guard so the per-domain assertion can't pass trivially; teeth confirmed by temporarily removing ticket/DOMAIN.md (test failed) and restoring it (test green).
- Kept all prose to information-design craft — zero accessibility/tagged-PDF/screen-reader claims (T-118-03, guarded repo-wide by the D-14 tripwire in 118-07).

## Task Commits

Each task was committed atomically:

1. **Task 1: Author five new DOMAIN.md files** - `eec5760` (docs)
2. **Task 2: Strengthen DomainMdContractTest to require one DOMAIN.md per demonstrated domain** - `e0745b1` (test)

## Files Created/Modified
- `priv/examples/statement/DOMAIN.md` - Account-statement anatomy; closing balance as the headline, running-balance ladder, carried/brought-forward across pages.
- `priv/examples/receipt/DOMAIN.md` - Receipt anatomy; total paid as proof figure, small-format legibility, keep-as-proof reading context.
- `priv/examples/certificate/DOMAIN.md` - Certificate anatomy; recipient name as the central anchor, centered/symmetric ceremonial layout, seal/signature authority.
- `priv/examples/payslip/DOMAIN.md` - Payslip anatomy; net pay as the tinted-band anchor, earnings/deductions tables with YTD, jurisdiction-neutral labels.
- `priv/examples/ticket/DOMAIN.md` - Ticket anatomy; placement grid as the largest-type anchor, bordered code/stub with human-readable reference, gate-read context.
- `test/docs_contract/domain_md_contract_test.exs` - Per-demonstrated-domain assertion derived from fixture dirs; four-heading loop left intact.

## Decisions Made
- Derived the demonstrated-domain set from `priv/examples/*/*/*.json` fixture directories rather than a hardcoded family list, so future domains inherit the DOMAIN.md contract automatically (mirrors the 114-05 glob-based four-heading contract intent).
- Added an explicit non-vacuous guard (`demonstrated_domains != []`) so a future refactor that broke the derivation would fail loudly instead of silently passing an empty loop.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. Both tasks verified green (`mix test test/docs_contract/domain_md_contract_test.exs` and the full `mix test test/docs_contract/` at 271 tests, 0 failures). The teeth check produced the expected single failure when a DOMAIN.md was removed and returned to green on restore.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The five DOMAIN.md paths now exist as citation targets for the D-05 demo-cites-DOMAIN.md check authored in 118-06.
- The strengthened contract guarantees every current and future demonstrated domain is bound to a DOMAIN.md, so a demo can never cite a missing anchor.

## Self-Check: PASSED

All five DOMAIN.md files and the strengthened contract test exist on disk; both task commits (`eec5760`, `e0745b1`) are present in git history.

---
*Phase: 118-rubric-gated-demonstration-set-gallery-docs-closure*
*Completed: 2026-07-19*
