---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "01"
subsystem: adoption-evidence
tags: [adoption, evidence, hex, github, docs-contract]
dependency_graph:
  requires: [ADOPTION.md, public Hex API, GitHub CLI]
  provides: [bounded adoption observer, immutable dated sidecar, offline contract]
  affects: [package contents, adoption gate documentation]
tech_stack:
  added: []
  patterns: [injected command runner, canonical JSON SHA-256 digest, exclusive atomic output, offline docs contract]
key_files:
  created:
    - scripts/adoption_snapshot.exs
    - test/docs_contract/adoption_evidence_contract_test.exs
    - priv/adoption_evidence/2026-08-21.json
  modified:
    - ADOPTION.md
    - mix.exs
    - test/docs_contract/adoption_claims_test.exs
decisions:
  - "The dated 2026-08-21 review records Downloads ACCUMULATING, Demand HOLD, Contributor HOLD, and composite HOLD."
  - "Snapshot output uses an exclusive temporary file plus hard-link publication so an authoritative dated target cannot be replaced."
metrics:
  duration: "~12 minutes"
  completed: 2026-08-21
status: complete
---

# Phase 131 Plan 01: Bounded Adoption Snapshot Summary

Implemented a one-shot read-only observer that turns bounded Hex and GitHub observations into a packaged, offline-auditable adoption decision.

## Tasks Completed

1. Traced fixture-backed availability, canonical-digest, and exclusive-write behavior through the observer contract.
2. Recorded the sole dated advisory observation and linked its public HOLD decision from `ADOPTION.md`.

## Verification

- `mix test test/docs_contract/adoption_evidence_contract_test.exs --max-failures 1` — passed (8 tests).
- `mix test test/docs_contract/adoption_evidence_contract_test.exs test/docs_contract/adoption_claims_test.exs test/docs_contract/preset_fonts_package_contract_test.exs --max-failures 1 && mix hex.build` — passed (17 tests; archive includes `priv/adoption_evidence/2026-08-21.json`).
- `mix ci.fast` — passed.

## Evidence Outcome

The 2026-08-21 source-backed record retains Hex downloads of 3,149 all-time and 182 weekly, with empty bounded demand and merged-contributor candidate sets. Retrieval was AVAILABLE for all three families. The resulting family decisions are Downloads `ACCUMULATING`, Demand `HOLD`, Contributor `HOLD`, and composite `HOLD` by the minimum-family rule.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected the observer's runnable Mix invocation.
- **Found during:** Task 2
- **Issue:** `mix run scripts/adoption_snapshot.exs -- --output ...` does not pass arguments to an auto-run script in this Mix invocation mode.
- **Fix:** Documented and used `mix run --require scripts/adoption_snapshot.exs -- --output ...`, which preserves the same one-shot read-only observer while delivering its bounded options.
- **Files modified:** `scripts/adoption_snapshot.exs`
- **Commit:** `3fbce94`

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed the observer, contract test, and dated evidence sidecar exist.
- Confirmed commits `5b6552b`, `e3f5c30`, `1c05476`, and `3fbce94` exist.
