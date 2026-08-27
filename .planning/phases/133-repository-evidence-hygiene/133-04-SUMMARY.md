---
phase: 133-repository-evidence-hygiene
plan: "04"
subsystem: repository evidence
tags: [elixir, jsv, json-schema, sha256, release-evidence, journey]
requires:
  - phase: 133-repository-evidence-hygiene
    provides: first four sealed journey records and fail-closed capsule loader
provides:
  - Complete nine-record v1.3.4 journey preservation capsule
  - Eight byte-identical Markdown sidecars and one explicit pre-schema no-sidecar record
  - Digest-bound manifest/index ordering for all historical attempts
affects: [133-05, release-evidence, clean-room-proof]
tech-stack:
  added: []
  patterns: ["Historical source facts remain byte-preserved and digest-bound; narrative absence is an explicit structured fact rather than a fabricated sidecar."]
key-files:
  created:
    - evidence/releases/v1.3.4/journey/journey-005.json
    - evidence/releases/v1.3.4/journey/journey-005.md
    - evidence/releases/v1.3.4/journey/journey-006.json
    - evidence/releases/v1.3.4/journey/journey-006.md
    - evidence/releases/v1.3.4/journey/journey-007.json
    - evidence/releases/v1.3.4/journey/journey-008.json
    - evidence/releases/v1.3.4/journey/journey-008.md
    - evidence/releases/v1.3.4/journey/journey-009.json
    - evidence/releases/v1.3.4/journey/journey-009.md
  modified:
    - evidence/releases/v1.3.4/manifest.json
    - evidence/releases/v1.3.4/journey/index.json
    - priv/schemas/release_evidence_attempt.schema.json
    - test/scripts/repository_evidence_test.exs
key-decisions:
  - "The pre-schema success is a structured journey record with an explicit absent narrative, so no Markdown is invented."
  - "All nine records remain advisory and inert; active consumers remain restricted to sealed core roles."
requirements-completed: [HYGIENE-02]
duration: 21min
completed: 2026-08-26
status: complete
---

# Phase 133 Plan 04: Complete Journey Evidence Preservation Summary

**All nine v1.3.4 clean-room attempts are now ordered, source-digest-bound advisory records, with eight byte-identical Markdown sidecars and one truthful pre-schema no-sidecar record.**

## Performance

- **Duration:** 21 min
- **Completed:** 2026-08-26T22:32:00Z
- **Tasks:** 1/1
- **Files modified:** 13

## Accomplishments

- Imported attempts 005–009 in stable chronology and appended their manifest/index identities and content digests.
- Preserved original JSON facts and source digests for all remaining failure, pre-schema-success, and schema-complete-success records without making Markdown an active fact source.
- Extended the focused contract to verify nine unique records, eight byte-identical sidecars, the one explicit narrative absence, retained legacy sources, and every manifest digest.

## Task Commits

1. **Task 1: Import journey attempts 005-009** - `5938ac3` (RED test), `984ae72` (GREEN implementation)

## Verification

- `mix test test/scripts/repository_evidence_test.exs` passed: 6 tests, 0 failures.
- A deterministic Node digest check confirmed every capsule manifest record resolves to its exact SHA-256 payload.
- A source-retention check confirmed all five imported legacy source JSON files still exist.
- A focused repository scan found no active journey consumer; `journey_attempt` remains excluded from core-role dispatch.

## TDD Gate Compliance

- RED commit `5938ac3` failed as expected before the remaining records existed.
- GREEN commit `984ae72` made the focused suite pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical preservation] Generalized the record schema for historical success and explicit narrative absence**
- **Found during:** Task 1 implementation.
- **Issue:** The first-batch schema accepted only failure-shaped facts and mandatory sidecars, which would have rewritten or excluded the pre-schema success.
- **Fix:** Permitted preserved nonempty historical fact objects and a closed `narrative.role: absent` form for the one source with no Markdown.
- **Files modified:** `priv/schemas/release_evidence_attempt.schema.json`.
- **Verification:** All nine JSON records validate in the focused suite.
- **Commit:** `984ae72`.

**2. [Rule 1 - Bug] Kept copied Markdown sidecars byte-identical to their legacy sources**
- **Found during:** Task 1 digest verification.
- **Issue:** newline normalization changed copied sidecar digests.
- **Fix:** Replaced the generated copies with exact source bytes before sealing their hashes.
- **Files modified:** `evidence/releases/v1.3.4/journey/journey-005.md`, `journey-006.md`, `journey-008.md`, `journey-009.md`.
- **Verification:** Focused suite confirms source/sidecar byte equality and all digests resolve.
- **Commit:** `984ae72`.

**3. [Rule 3 - Blocking] Used the Mix-compatible focused test command**
- **Found during:** Task 1 verification.
- **Issue:** Mix 1.19 rejects the plan's `-x` option.
- **Fix:** Ran the equivalent `mix test test/scripts/repository_evidence_test.exs` command.
- **Files modified:** None.
- **Verification:** 6 tests passed.

**Total deviations:** 3 auto-fixed (Rule 1: 1; Rule 2: 1; Rule 3: 1).
**Impact:** Preservation is stricter and more truthful; no runtime API, active consumer, or public contract was added.

## Known Stubs

None. The records are intentionally inert advisory evidence, and the sole no-sidecar source is explicitly represented rather than stubbed.

## Threat Flags

None. This plan adds no network, authentication, filesystem-input, or runtime trust-boundary surface.

## Self-Check: PASSED

- `journey-005.json` through `journey-009.json` exist.
- TDD commits `5938ac3` and `984ae72` exist in Git history.
- The implementation commit contains no tracked file deletions.
