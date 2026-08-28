---
phase: 136-catalog-visual-quality
plan: "14"
subsystem: catalog evidence operations
tags: [elixir, git-provenance, transactional-publication, github-actions, reviewer-packet]

requires:
  - phase: 136-11
    provides: closed semantic bundle validator, exact eight-image authority-none packet, and receipt schemas
provides:
  - Git-proven baseline ownership proven by exact manifest blob bytes
  - Transactional canonical asset and manifest publication with complete rollback
  - Separate authoritative evidence and authority-none reviewer-packet workflow artifacts
  - Dynamic run-attempt, independent archive digest, evidence-first intake runbook
affects: [136-12, 136-13, 136-15, catalog-evidence, canonical-publication]

actuals:
  tokens: 16046
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - Git identity is accepted only after a full commit blob byte-matches the checked-in baseline
    - Canonical publication tracks backup and install progress before rollback removes any path
    - Authoritative evidence and navigation-only review packets use distinct artifact identities and digests

key-files:
  created: []
  modified:
    - dev/rendro/catalog.ex
    - test/rendro/catalog_test.exs
    - .github/workflows/catalog-evidence.yml
    - .github/workflows/CATALOG-EVIDENCE.md
    - test/docs_contract/catalog_evidence_runbook_test.exs
    - test/guardrails/required_checks_contract_test.exs

key-decisions:
  - "A baseline commit is trusted only when its full Git SHA resolves and its catalog manifest blob is byte-identical to the clean checked-in baseline."
  - "Canonical publication snapshots both asset-directory and manifest state, records each successful move/install, and restores only paths the transaction actually changed."
  - "The closed evidence bundle and authority-none eight-image packet remain separate artifacts; operators independently hash both archives and validate the bundle before packet binding."

patterns-established:
  - "Provenance before generation: unresolved, malformed, dirty, or byte-mismatched baseline history aborts before candidate evidence publication."
  - "Evidence-first review: exact run-attempt artifact resolution and both archive digest checks precede bundle validation, packet binding, and image viewing."

requirements-completed: [CATALOG-10, CATALOG-11, CATALOG-12, CATALOG-13]

coverage:
  - id: D1
    description: Candidate baseline provenance names the full Git commit owning the exact clean baseline bytes, and canonical publication restores the complete prior generation at every modeled failure boundary.
    requirement: CATALOG-10
    verification:
      - kind: integration
        ref: "test/rendro/catalog_test.exs#baseline commit identity and failure-injected canonical publication"
        status: pass
    human_judgment: false
  - id: D2
    description: The review workflow publishes separately named authoritative evidence and exact authority-none eight-image reviewer packet artifacts for one candidate, control, run, attempt, and renderer identity.
    requirement: CATALOG-12
    verification:
      - kind: integration
        ref: "test/guardrails/required_checks_contract_test.exs#Catalog Evidence workflow boundary"
        status: pass
      - kind: integration
        ref: "mix help rendro.catalog.gallery"
        status: pass
    human_judgment: false
  - id: D3
    description: The operator runbook derives attempt 1 or later, uniquely resolves and hashes both archives, validates detached-control evidence first, then binds all eight packet roles before image viewing or receipt creation.
    requirement: CATALOG-13
    verification:
      - kind: unit
        ref: "test/docs_contract/catalog_evidence_runbook_test.exs#dual-artifact intake and receipt contract"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-08-28
status: complete
---

# Phase 136 Plan 14: Transactional Publication and Dual-Artifact Operations Summary

**Exact Git-blob provenance and rollback-safe canonical publication now feed a two-artifact review workflow whose closed evidence and eight-image authority-none packet are independently identified, hashed, and validated.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-08-28T20:32:26Z
- **Completed:** 2026-08-28T20:49:12Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added full-SHA baseline resolution that reads the candidate baseline from Git, rejects dirty or mismatched bytes, and never substitutes the candidate identity for unproven ownership.
- Replaced best-effort canonical swaps with a failure-injected two-artifact transaction that preserves the complete prior asset directory and manifest under every modeled backup, install, and verification failure.
- Reconciled the live GitHub workflow with Plan 11's semantic validator: real `cells` payloads, trusted baseline SHA, exact renderer-pin validation, normalized final/multipage/preset roles, and a separately uploaded eight-role reviewer packet.
- Rewrote the operator contract around the actual run attempt, unique dual-artifact API records, independent provider/archive digests, detached-control bundle validation, packet binding, and complete/unavailable receipt fields with a three-attempt Revision Gate.

## Task Commits

Each TDD task was committed with a distinct RED and GREEN gate:

1. **Task 1 RED: provenance and rollback contracts** - `d96a203` (test)
2. **Task 1 GREEN: truthful provenance and transactional publication** - `819c80a` (feat)
3. **Task 2 RED: dual-artifact workflow/runbook contracts** - `586860d` (test)
4. **Task 2 GREEN: bound evidence and reviewer-packet operations** - `947393a` (feat)

## Files Created/Modified

- `dev/rendro/catalog.ex` - Resolves exact Git baseline ownership, records truthful source identity, and publishes canonical files transactionally.
- `test/rendro/catalog_test.exs` - Covers Git history failures, canonical semantic validation, successful swaps, and six injected rollback boundaries.
- `.github/workflows/catalog-evidence.yml` - Builds semantically valid roles and uploads closed evidence separately from the eight-image packet.
- `.github/workflows/CATALOG-EVIDENCE.md` - Documents dynamic attempt resolution, independent archive verification, evidence-first packet intake, and receipt/revision contracts.
- `test/docs_contract/catalog_evidence_runbook_test.exs` - Pins attempt 2+, exact artifact metadata/digests, validation order, all eight roles, and truthful receipt language.
- `test/guardrails/required_checks_contract_test.exs` - Pins workflow topology, renderer-pin fail-closed checks, real collection shapes, packet command arguments, and artifact separation.

## Decisions Made

- Explicit baseline SHAs are not trusted as labels: the resolver validates full lowercase identity, reads that commit's exact manifest blob, and byte-compares it to the clean working-tree baseline.
- Rollback is state-aware. It deletes only replacements that were installed by the active transaction and restores only backups that were successfully created, preventing untouched canonical paths from being removed.
- Canonical workflow evidence is limited to the trusted control commit because the canonical payload's truthful `source_commit_sha` must equal the control-plane identity.
- The reviewer packet is produced by the committed three-argument Mix task after final rasters exist; Invoice-light and Statement-light remain explicit controls beside the six target images.

## Deviations from Plan

None - the plan was executed as written. The existing uncommitted workflow, runbook, and contract-test edits were preserved and upgraded from the obsolete six-image convenience-gallery shape to the planned exact eight-image reviewer packet.

## Issues Encountered

- `mix ci.fast` stops at `quality.hygiene` because the tracked pre-existing `.planning/todos/pending/2026-08-28-unify-catalog-recipe-visual-design-system.md` is outside an active phase directory or milestone archive. Plan 136-09 already records this out-of-scope governance item in `deferred-items.md`. Every remaining CI-fast stage was run directly and passed.

## Verification

- `mix test test/rendro/catalog_test.exs --max-failures 1` - 25 tests, 0 failures, including the post-commit tracer feedback gate.
- `mix help rendro.catalog.gallery >/dev/null && mix test test/docs_contract/catalog_evidence_runbook_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` - 29 tests, 0 failures.
- Combined plan suite - 54 tests, 0 failures.
- `mix format --check-formatted` - passed.
- Remaining `mix ci.fast` stages - warnings-as-errors compilation passed; 2,012 tests plus 12 doctests and 8 properties passed with 0 failures; ExDoc warnings-as-errors passed; Credo strict found no issues; Dialyzer reported 0 errors.
- `git diff --check` - passed.

## Known Stubs

None. The six plan-owned files contain no new TODO, FIXME, placeholder, coming-soon, unavailable-data, rendered empty-value, or mock-data stub.

## Threat Flags

None. Git-history provenance, provider-artifact transport, and canonical filesystem publication are the plan's declared trust boundaries and are covered by exact blob comparison, closed identities/digests, authority separation, and failure-injected rollback tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 136-12 can record a complete or unavailable receipt from independently digested evidence and packet archives.
- Plan 136-13 can perform genuine eight-image human review only after the fresh evidence-first intake gate succeeds.
- Plan 136-15 can audit closure without inferring a visual score, approval, or canonical authority from workflow success.

## Self-Check: PASSED

- All six plan-owned implementation, workflow, documentation, and test files exist.
- All four Task 1-2 TDD commits exist in repository history.
- The summary exists at the plan's canonical output path, and the verification evidence above was produced in this execution session.

---
*Phase: 136-catalog-visual-quality*
*Plan: 14*
*Completed: 2026-08-28*
