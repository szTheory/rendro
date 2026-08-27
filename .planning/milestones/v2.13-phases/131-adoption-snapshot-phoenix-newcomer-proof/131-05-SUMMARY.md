---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "05"
subsystem: release
tags: [release, preflight, hex, hexdocs]
requires: [131-04]
provides: [sealed-private-v1.3.3-candidate]
affects: [131-06]
key-decisions: ["v1.3.3 candidate proof cannot bypass CI or security audits"]
status: complete
---

# Phase 131 Plan 05: Complete-Audit v1.3.3 Candidate Summary

Private exact-SHA v1.3.3 candidate sealed without tags or registry mutation.

## Candidate Evidence

- Candidate SHA: `cfc58a81865e060351ce33d98f5e52de8cd198d9`
- Required ancestor: `9dabf90`
- Archive SHA-256: `41b1766c8010dbd401da610ef32e12cdcf13e5062da5c17960beaba466a872c8`
- Focused contracts: 67 tests passed, including FIFO, timeout, bypass, verifier, and isolated Livebook boundaries.
- Detached `mix ci.fast`: passed; Dialyzer reported 0 errors.
- `mix deps.audit` and `mix hex.audit`: passed.
- Complete detached `mix release.preflight --candidate-sha cfc58a81865e060351ce33d98f5e52de8cd198d9`: passed all Phase 1/2 gates, including repeated CI, docs, package unpack, Hex dry run, and both audits.
- Local and remote tag snapshots remained unchanged; v1.3.3 remains absent locally and remotely.

## Immutable Incidents

v1.3.0, v1.3.1, and v1.3.2 remain untouched failed public history. The verifier binds v1.3.2 tag object `9b7ff50c69c0e9bd6ae39f0c79f76c4663d936fd`, peeled SHA `47af6448d2989ffe69c4b80c77935c896b1ddb07`, run `32586098785`, and failed/skipped jobs `97062582546`/`97064173653`.

## Deviations from Plan

### Auto-fixed Issues

- [Rule 1 - Bug] Candidate preflight package checks initially rejected the intentionally isolated tutorial boundary; the final package ships the guide only and verifies its converter from the source checkout.
- [Rule 1 - Bug] Updated a stale HexDocs launch-contract expectation from v1.3.2 to the active v1.3.3 target.

## Self-Check: PASSED
