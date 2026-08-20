---
phase: 130
plan: 04
status: complete
---

# Phase 130 Plan 04: Candidate Evidence Summary

Verified a private, fixed-root catalog candidate route with 32 candidate PNGs, 12 review PNGs, and four separate multipage proofs.

## Evidence

- Source SHA: `411cdcafa5d3090f3d0ec144c0cba59d991ba99f`
- Route run/job: `32417257428` / `96581121473`
- Route SHA: `30657d92cf8be49f30094c57aaf163b76bd0ad9c`
- Artifacts: `9424562803`, `9424563354`, `9424563918`
- PDFium: v0.11.0, executable/pin SHA `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`
- Focused deterministic verification: 317 tests, 0 failures.

## Partition

The manifest truthfully contains 12 changed scored/review-required IDs, 20 changed unscored IDs, and zero byte-stable IDs. All 32 source PDF hashes drift from the canonical binding; default catalog rows use explicit `Rendro.Theme.default()`, not nil-theme controls. Nil-theme compatibility remains separately covered.

## Deviations

Candidate generation required multipage, final-payload, and artifact-layout contract fixes. Aggregate CI launch-artifact drift was bypassed only through the independently verified, unmerged candidate-only route; canonical assets, rubric scores, and SIGN-OFF were not modified.
