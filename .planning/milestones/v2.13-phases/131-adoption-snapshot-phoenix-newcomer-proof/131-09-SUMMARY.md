---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "09"
subsystem: release
tags: [hex, hexdocs, verifier, provenance]
status: complete
---

# Phase 131 Plan 09: Exact Public v1.3.4 Summary

**Protected v1.3.4 publication is atomically VERIFIED with canonical package identity and combined-release HexDocs provenance.**

## Accomplishments

- Recorded the exact blocking-human approval, then pushed annotated `v1.3.4` object `84b0a632af6f6fa96af5fb515cecbbe18dcf6d37` peeled to `f03c78bab54efe1cd1596d51cf3f28193232e2a3`.
- Protected release run `32763039854` succeeded: validate job `97546095415`, actual Hex publish job `97549444486`.
- Hex/API outer SHA is `a6048f87aa54a8467374c56bab87d25be26e8c835e8cf8f06050573f8c4a7c80`; sealed local outer SHA remains `7c886783fa1f73b2b154b4840295e6092b3f26e7bf568203476d204b0c0c369a`.
- Canonical manifest `d2ba1a33339d501291736c67df74cbed3ef46f5063409043ac7d6f4f38012f9e` and metadata `52d92fd928453dcf23c1dd0ef1fc0daf699c1de97b68ce3cadb6c5cb0c8564b3` match public and sealed payloads.
- Combined protected `mix hex.publish --yes` supplied versioned docs; redundant HexDocs dispatch was intentionally skipped.
- Bounded prerequisite is VERIFIED, SHA `505394af4ab54393ac06ac35592e8b2bfd935b3365983775191a2a7cca7278bf`; read-only recheck preserved bytes and mtime.

## Fail-Closed Incidents and Repairs

- Initial outer-hash mismatch exposed Hex ordering; canonical manifest/metadata verification replaced unsafe outer equality.
- Metadata parser, truthful versioned HexDocs probes, bounded output, and existing-output recheck were repaired before acceptance.
- Rejected legacy pre-canonical and pre-bounded records are retained (both SHA `1e9d45c3c411b3e4c308462a7f7989633d86e9c0c82e2e0f4c33c59a7089a50c`).

## Verification

- `mix test test/scripts/public_release_verifier_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` — 41 tests, 0 failures.
- Corrected live verifier create and `--check-existing` recheck — pass.

## Decisions

- Future package-only releases treat combined protected release publishing as the docs provenance; do not dispatch a redundant HexDocs workflow.

## Self-Check: PASSED

- Public prerequisite and both legacy artifacts exist in commit `6a15870`.
