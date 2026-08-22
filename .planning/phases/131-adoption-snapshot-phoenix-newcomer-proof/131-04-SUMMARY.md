---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "04"
subsystem: release
tags: [release, preflight, hex, hexdocs]
requires: [131-03]
provides: [private v1.3.2 exact-SHA candidate]
affects: [131-05]
tech-stack: {added: [], patterns: [ref-free detached candidate proof]}
key-files: [scripts/release_preflight_proof.exs, scripts/verify_public_release.exs]
key-decisions: ["v1.3.2 remains private and untagged pending approval"]
requirements-completed: [JOURNEY-01, JOURNEY-02, JOURNEY-04]
status: complete
---

# Phase 131 Plan 04: Private v1.3.2 Candidate Summary

**A ref-free, exact-SHA v1.3.2 release candidate with immutable failed-release history checks.**

## Accomplishments

- Added candidate-SHA preflight parity and tag-ref snapshot proof mode.
- Bound verifier policy and protected HexDocs gate to v1.3.2 while retaining v1.3.0/v1.3.1 incident facts.
- Sealed candidate `3bfa1f1374097cc6994950fef0f3f33e45a3a66a` with package checksum `a3e1517b175510c868cb8fd883290fe90dcd6fa02e045b9c6d7dec4fa6eececb`.

## Verification

- Focused preflight/verifier/workflow contracts: passed.
- Open-silent FIFO regression: passed without overwrite prompt.
- Detached `mix ci.fast`: passed (Dialyzer total errors: 0).
- Exact-SHA no-tag preflight, Hex dry run, package build/inventory, and docs: passed.
- Tag refs unchanged; no local v1.3.2 tag.

## Task Commits

- `c4cdc29`, `3c0735b`: Task 1 TDD and implementation.
- `6bd3938`, `1769ef8`, `c11742d`, `3bfa1f1`: Task 2 and parity fixes.
- `b749d68`: Task 3 candidate evidence.

## Deviations from Plan

### Auto-fixed Issues

- [Rule 1 - Bug] Updated version-coupled preflight and HexDocs contract fixtures discovered by detached CI.

## Self-Check: PASSED
