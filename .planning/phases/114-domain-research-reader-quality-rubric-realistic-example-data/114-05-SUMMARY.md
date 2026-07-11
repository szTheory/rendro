---
phase: 114-domain-research-reader-quality-rubric-realistic-example-data
plan: 05
subsystem: testing
tags: [documentation, domain-research, docs-contract, exunit, invoice]

# Dependency graph
requires:
  - phase: 114
    provides: "priv/examples/invoice/ fixture directory (Plans 114-01/114-03) to co-locate DOMAIN.md within"
provides:
  - "priv/examples/invoice/DOMAIN.md — Invoice domain-research doc (domain language, personas + JTBD, reading context, layout/typographic conventions)"
  - "test/docs_contract/domain_md_contract_test.exs — structural headings contract enforcing DOMAIN.md shape for every domain"
affects: [118, SHOW-01, rubric-gated-demos]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Structural (headings-present) docs-contract test lane using Path.wildcard + substring assertions"

key-files:
  created:
    - priv/examples/invoice/DOMAIN.md
    - test/docs_contract/domain_md_contract_test.exs
  modified: []

key-decisions:
  - "Authored domain-research prose as the locked research-first recommendation (114-RESEARCH flags it MEDIUM/LOW confidence — synthesized, not tool-verifiable), leaving a light human sanity-check for phase verification."
  - "Contract test iterates every priv/examples/*/DOMAIN.md so the heading contract auto-applies to future domain families with no test changes."

patterns-established:
  - "Structural docs-contract lane: assert wildcard non-empty, then assert each required '## ' heading present per matched file, naming the offending path on failure."

requirements-completed: [RUB-01]

coverage:
  - id: D1
    description: "priv/examples/invoice/DOMAIN.md exists with all four required sections and genuine (non-placeholder) Invoice domain content"
    requirement: "RUB-01"
    verification:
      - kind: unit
        ref: "test/docs_contract/domain_md_contract_test.exs#every DOMAIN.md carries all four required section headings"
        status: pass
    human_judgment: true
    rationale: "Structural test proves headings exist, but whether the prose is genuinely faithful domain research (vs. plausible-looking filler) needs the light human sanity-check the plan reserves for phase verification."
  - id: D2
    description: "Docs-contract test structurally enforces the four-heading DOMAIN.md contract for every domain family"
    requirement: "RUB-01"
    verification:
      - kind: unit
        ref: "test/docs_contract/domain_md_contract_test.exs"
        status: pass
    human_judgment: false

# Metrics
duration: 1min
completed: 2026-07-11
status: complete
---

# Phase 114 Plan 05: Invoice Domain Anatomy + DOMAIN.md Contract Lane Summary

**Authored `priv/examples/invoice/DOMAIN.md` (domain language, personas + JTBD, reading context, layout conventions) and a structural docs-contract test enforcing the four-heading shape for every domain family.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-07-11T05:15:09Z
- **Completed:** 2026-07-11T05:16:29Z
- **Tasks:** 2
- **Files modified:** 2 (both created)

## Accomplishments
- Invoice `DOMAIN.md` (94 lines) with all four required `## ` sections, each carrying genuine domain-research content: nouns/verbs/lifecycle events; AP-clerk/issuer/bookkeeper personas each with the ONE fact they need first; queue-triage + print-and-screen reading context; total-due-prominence and aligned-money layout conventions.
- New `domain_md_contract_test.exs` lane that guards against an empty wildcard match and asserts every `priv/examples/*/DOMAIN.md` contains all four required headings, naming the offending path on failure.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author priv/examples/invoice/DOMAIN.md** - `96ce387` (docs)
2. **Task 2: Write test/docs_contract/domain_md_contract_test.exs** - `a5121c4` (test)

## Files Created/Modified
- `priv/examples/invoice/DOMAIN.md` - Invoice domain-research doc cited by Phase 118 rubric-gated demos (SHOW-01)
- `test/docs_contract/domain_md_contract_test.exs` - structural headings contract for every domain's DOMAIN.md

## Decisions Made
- Authored the domain-research prose as the locked research-first recommendation. 114-RESEARCH flags this content MEDIUM/LOW confidence because it is necessarily synthesized rather than tool-verifiable; per this project's planning preference it is treated as the locked recommendation with a light human sanity-check reserved for phase verification.
- Made the contract test iterate all `priv/examples/*/DOMAIN.md` rather than hardcoding the invoice path, so future domain families inherit the heading contract automatically.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. Both tasks' automated verifications passed on first run (`grep` heading checks; `mix test` 2 tests, 0 failures).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `priv/examples/invoice/DOMAIN.md` is available for Phase 118's rubric-gated demos (SHOW-01) to cite.
- The docs-contract lane is registered as a test file; note that Plan 114-07 is responsible for wiring the 3 new docs-contract lanes into `scripts/verify_docs.exs` and bumping the guardrail lane-count assertion (22 -> 25) — that registration is out of scope for this plan.

## Self-Check: PASSED

- FOUND: priv/examples/invoice/DOMAIN.md
- FOUND: test/docs_contract/domain_md_contract_test.exs
- FOUND commit: 96ce387
- FOUND commit: a5121c4

---
*Phase: 114-domain-research-reader-quality-rubric-realistic-example-data*
*Completed: 2026-07-11*
