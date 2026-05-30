---
phase: 80-stability-contract-migration-docs
plan: "01"
subsystem: documentation
tags: [api-stability, semver, docs-contract, deprecation-policy, label-scrub]

requires:
  - phase: 78-public-api-surface-definition
    provides: priv/public_api.json with tier assignments (stable/adapter) for all modules

provides:
  - "guides/api_stability.md rewritten with two-tier SemVer contract (Tier-1 Stable / Tier-2 Evolving) leading the document"
  - "Byte-output carve-out with exact string 'deterministic within a version, not frozen across versions'"
  - "Six-bullet NOT covered by SemVer list per D-13"
  - "Soft-deprecate-first deprecation policy + Deprecations table with None as of 1.0.0 sentinel row"
  - "All per-surface support boundary blocks relocated verbatim under ## Per-Surface Support Boundaries"
  - "Internal labels scrubbed from api_stability.md (Phase 53, Phase 71, Rendro v1.10)"
  - "protection_claims_test.exs updated in lockstep (D-05): lines 48 and 55-57"
  - "D-09 reconcile: Rendro.Inspector removed from Tier-1 framing; :diagnostics map common keys described as stable contract"

affects:
  - 80-02 (viewer_evidence.md label scrub)
  - 80-03 (upgrading_to_1.0.md + mix.exs wiring)
  - 80-04 (api_stability_claims_test.exs — STAB-05 — asserts content this plan ships)
  - 81-release-hardening
  - 82-consolidation-publish

tech-stack:
  added: []
  patterns:
    - "D-01/D-02: Contract-first document structure with verbatim block relocation (zero test churn)"
    - "D-05: CI-pinned lockstep — guide + test updated atomically in same commit"
    - "D-09: Inspector reconcile — describe map keys as stable contract, not the adapter-tier module"

key-files:
  created: []
  modified:
    - guides/api_stability.md
    - test/docs_contract/protection_claims_test.exs

key-decisions:
  - "D-01 executed: contract section (Tier-1/Tier-2/NOT covered/Deprecation Policy/Deprecations) leads the document; per-surface blocks relocated byte-identical under ## Per-Surface Support Boundaries"
  - "D-09 reconcile: Rendro.Inspector described as adapter-tier in prose; :diagnostics map common keys (:level, :type) named as the stable contract"
  - "D-05 lockstep: guide lines 128 and 136 updated; protection_claims_test.exs lines 48 and 55-57 updated in the same commit"
  - "D-06 free edits applied: 'Phase 71 review' -> 'operator review' (line 54), 'after Phase 71 re-verify' removed from line 118, suffix edits on lines 148 and 155 preserving 40-char prefixes"

patterns-established:
  - "Lockstep commit: guide edit + pinned test update in single atomic commit ensures CI never goes red between commits"
  - "D-02 zero-churn: position-independent guide =~ substring assertions tolerate section relocation"

requirements-completed:
  - STAB-01
  - STAB-02
  - STAB-04

duration: 8min
completed: "2026-05-30"
---

# Phase 80 Plan 01: API Stability Guide Rewrite Summary

**Two-tier SemVer contract (Tier-1 Stable / Tier-2 Evolving) now leads guides/api_stability.md with byte-output carve-out, NOT covered list, deprecation policy, and Deprecations sentinel table; all nine per-surface blocks relocated verbatim; all internal labels scrubbed; protection_claims_test.exs updated atomically.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-30T19:08:00Z
- **Completed:** 2026-05-30T19:16:05Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Rewrote `guides/api_stability.md` so the two-tier SemVer contract (Tier-1 Stable, Tier-2 Evolving, NOT covered by SemVer, Deprecation Policy, Deprecations table) leads the document before the per-surface blocks
- Relocated all nine per-surface support boundary blocks byte-identical below `## Per-Surface Support Boundaries` (zero test churn per D-02)
- Applied D-09 reconcile: `Rendro.Inspector` removed from Tier-1 framing; the `:diagnostics` map common keys (`:level`, `:type`) described as the stable contract instead
- Applied all internal-label scrubs (D-05 CI-pinned + D-06 free edits): no "Phase 71", "Phase 53", or "Rendro v1.10" remains
- Updated `protection_claims_test.exs` lines 48 and 55-57 in the same atomic commit (D-05 lockstep)
- `mix test test/docs_contract/` exits 0: 103 tests, 0 failures

## Task Commits

1. **Task 1: Rewrite guides/api_stability.md — contract-first structure, label scrub, D-05 lockstep** - `913f457` (feat)

**Plan metadata:** (pending final docs commit)

## Files Created/Modified

- `/Users/jon/projects/rendro/guides/api_stability.md` — Full rewrite: contract-first structure with Tier-1/Tier-2/NOT covered/Deprecation Policy/Deprecations leading; per-surface blocks verbatim below subordinate heading; all internal labels scrubbed
- `/Users/jon/projects/rendro/test/docs_contract/protection_claims_test.exs` — D-05 lockstep: lines 48 and 55-57 updated to match new guide strings

## Decisions Made

- D-09 reconcile applied: wrote `:diagnostics` map common keys as the stable contract instead of naming `Rendro.Inspector` (adapter-tier per `priv/public_api.json`)
- D-06 line 118 "after Phase 71 re-verify" → phrase deleted (sentence reads cleanly: "on the version recorded" was added to line 155 instead)
- The `## Viewer Evidence and CHANGELOG Discipline` section was placed between the Deprecations table and the `## Per-Surface Support Boundaries` heading (Claude's discretion per plan)

## Deviations from Plan

None — plan executed exactly as written. All edits followed the byte-identical relocation constraint (D-02), the lockstep constraint (D-05), the 40-char prefix safety constraint for lines 148 and 155, and the D-09 reconcile. No banned phrases introduced.

## Issues Encountered

None. `mix test test/docs_contract/` passed on first run after changes (103 tests, 0 failures).

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. This plan edits only public documentation and one docs-contract test file. No new threat surface.

## Self-Check

- [x] `guides/api_stability.md` exists and contains all required sections
- [x] `test/docs_contract/protection_claims_test.exs` updated with new assertion strings
- [x] Commit `913f457` exists in git log
- [x] `grep -c "Rendro v1.10\|Phase 53\|Phase 71" guides/api_stability.md` returns 0
- [x] `mix test test/docs_contract/` exits 0

## Self-Check: PASSED

## Next Phase Readiness

- 80-02: `guides/viewer_evidence.md` label scrub is ready to proceed (api_stability.md scrub complete)
- 80-03: `guides/upgrading_to_1.0.md` creation and `mix.exs` wiring can proceed
- 80-04: `test/docs_contract/api_stability_claims_test.exs` (STAB-05) can now be authored against the content this plan ships — the exact heading strings (`## Tier-1 Stable`, `## Tier-2 Evolving`, `## NOT covered by SemVer`, `## Deprecation Policy`, `## Deprecations`) and key sentences are finalized

---
*Phase: 80-stability-contract-migration-docs*
*Completed: 2026-05-30*
