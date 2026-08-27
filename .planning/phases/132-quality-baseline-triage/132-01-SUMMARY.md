---
phase: 132-quality-baseline-triage
plan: "01"
subsystem: quality-control-plane
tags: [quality-ledger, jsv, baseline, evidence, exunit]
requires: []
provides:
  - "Human-first quality ledger linked to a schema-valid initial evidence snapshot"
  - "Default-excluded maintenance contract invoked only through mix quality.baseline"
  - "Permanent evidence, signal, and finding identity checks"
affects: [132-02, 133-repository-evidence-hygiene, 134-architecture-readability, 135-test-ci, 136-catalog, 137-closure]
tech-stack:
  added: []
  patterns: ["Markdown judgment ledger plus JSV-validated normalized evidence", "purpose-tagged maintenance contract outside ordinary CI"]
key-files:
  created: [.planning/QUALITY.md, .planning/quality/schema/baseline-v1.schema.json, .planning/quality/baselines/132-initial.json, test/quality/baseline_ledger_contract_test.exs]
  modified: [mix.exs, test/test_helper.exs]
key-decisions:
  - "QUALITY.md remains the human-first decision ledger; JSON retains only normalized evidence facts."
  - "The baseline contract is explicitly invoked through mix quality.baseline and excluded from ordinary test and CI lanes."
  - "QL-001 rejects compile-connected xref topology as a repair mandate until concrete harm is demonstrated."
patterns-established:
  - "Validate snapshots with JSV, then apply focused identity checks for IDs JSON Schema cannot compare across nested records."
requirements-completed: [AUDIT-01, AUDIT-02, AUDIT-03, AUDIT-04]
coverage:
  - id: D1
    description: "Schema-valid immutable initial baseline links EV-ARCH-001 to QL-001."
    requirement: AUDIT-01
    verification:
      - kind: integration
        ref: "mix quality.baseline"
        status: pass
    human_judgment: false
  - id: D2
    description: "Ledger lifecycle, qualitative rubric, routing, and closure rules are mechanically checked."
    requirement: AUDIT-03
    verification:
      - kind: unit
        ref: "test/quality/baseline_ledger_contract_test.exs"
        status: pass
    human_judgment: false
status: complete
---

# Phase 132 Plan 01: Quality Baseline Tracer Summary

**A human-first quality ledger now links one actual xref baseline result through a versioned JSV snapshot to a permanent, governed finding.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-08-26T18:15:47Z
- **Completed:** 2026-08-26T18:22:16Z
- **Tasks:** 3/3
- **Files modified:** 6

## Accomplishments

- Added the canonical, archive-independent `.planning/QUALITY.md` with the compatibility contract, baseline registry, lifecycle, qualitative rubric, owner routing, and closure rules.
- Added the Draft 2020-12 baseline schema and `baseline-132-initial` snapshot containing a real local compile-connected xref result at exact source SHA `a43e8f62ae04d6761d99be7959d6027b876c9373`.
- Added `mix quality.baseline`, a purpose-tagged contract excluded from ordinary `mix test` and `mix ci.fast`, with JSV mutation, immutability, identity, and ledger seam checks.

## Task Commits

1. **Task 1: Prove one evidence-to-finding path end to end** — `a43e8f6` (RED), `5d5afa1` (GREEN)
2. **Task 2: Expand evidence identity, authority, and immutability contracts** — `f972525` (RED), `84bc3f8` (GREEN), `54bcef7` (duplicate-ID correction)
3. **Task 3: Expand finding lifecycle, deduplication, and disposition governance** — `68b4071` (RED), `60702ff` (GREEN)

## Files Created/Modified

- `.planning/QUALITY.md` — canonical current ledger and maintainer governance contract.
- `.planning/quality/schema/baseline-v1.schema.json` — closed Draft 2020-12 normalized-evidence schema.
- `.planning/quality/baselines/132-initial.json` — immutable, hash-addressed initial baseline snapshot.
- `test/quality/baseline_ledger_contract_test.exs` — purpose-tagged JSV and bounded ledger contract.
- `mix.exs` and `test/test_helper.exs` — explicit maintenance alias and default exclusion boundary.

## Decisions Made

- Keep local reproduction distinct from primary-CI, proof, advisory, and human-review authority.
- Treat xref topology as a reproducible signal, not automatic repair authority; QL-001 remains `reject_signal` unless its trigger is met.
- Keep raw command output out of Git while recording its SHA-256, size, location, expiry, and redaction status in normalized evidence.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 3 - Blocking issue] Added the `quality.baseline` preferred Mix environment.**
- **Found during:** Task 1
- **Issue:** `mix quality.baseline` initially ran in `:dev`, so Mix refused to invoke `mix test`.
- **Fix:** Added `"quality.baseline": :test` to `Rendro.MixProject.cli/0`.
- **Verification:** The RED test then reached the missing-artifact assertion; the GREEN contract passes in `:test`.
- **Committed in:** `a43e8f6`

2. **[Rule 2 - Missing critical functionality] Rejected duplicate stable evidence and signal IDs in the focused contract.**
- **Found during:** Task 2
- **Issue:** JSON Schema validates record shape but cannot enforce nested ID uniqueness by ID alone.
- **Fix:** Added a focused validity helper and duplicate `EV-*`/`SIG-*` mutation checks.
- **Verification:** `mix quality.baseline` passes and explicitly rejects duplicated evidence or signal records.
- **Committed in:** `54bcef7`

**Total deviations:** 2 auto-fixed (Rule 2: 1; Rule 3: 1). Both preserve the plan's explicit maintenance and concurrency requirements without widening runtime behavior.

## Verification

- `mix quality.baseline` — passed repeatedly; the snapshot SHA remained byte-identical across two runs.
- `mix ci.fast` — passed; the ordinary lane excludes `:quality_ledger_contract`.
- `git diff -- lib .github/workflows` — empty during tracer verification.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

Plan 02 can add the complete registered baseline evidence set and inverse SIG-to-finding classification. Remote and advisory evidence must remain explicitly unavailable until their authoritative artifacts exist.

## Self-Check: PASSED

Verified all four created artifacts exist and task commits `a43e8f6`, `5d5afa1`, `f972525`, `84bc3f8`, `68b4071`, `60702ff`, and `54bcef7` exist in Git history.
