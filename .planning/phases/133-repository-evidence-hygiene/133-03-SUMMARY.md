---
phase: 133-repository-evidence-hygiene
plan: "03"
subsystem: repository evidence
tags: [elixir, jsv, json-schema, sha256, release-evidence, journey]
requires:
  - phase: 133-repository-evidence-hygiene
    provides: sealed v1.3.4 capsule manifest, journey index, and fail-closed loader
provides:
  - Four immutable, digest-bound advisory journey attempt records in source chronology
  - Paired Markdown narratives and strict source/import/redaction record validation
affects: [133-04, release-evidence, clean-room-proof]
tech-stack:
  added: []
  patterns: ["Journey attempts are append-only historical records with source facts, separate import metadata, a paired narrative digest, and no active consumer."]
key-files:
  created:
    - priv/schemas/release_evidence_attempt.schema.json
    - evidence/releases/v1.3.4/journey/journey-001.json
    - evidence/releases/v1.3.4/journey/journey-001.md
    - evidence/releases/v1.3.4/journey/journey-002.json
    - evidence/releases/v1.3.4/journey/journey-002.md
    - evidence/releases/v1.3.4/journey/journey-003.json
    - evidence/releases/v1.3.4/journey/journey-003.md
    - evidence/releases/v1.3.4/journey/journey-004.json
    - evidence/releases/v1.3.4/journey/journey-004.md
  modified:
    - evidence/releases/v1.3.4/manifest.json
    - evidence/releases/v1.3.4/journey/index.json
    - dev/rendro/repository_evidence.ex
    - test/scripts/repository_evidence_test.exs
key-decisions:
  - "The first four failed attempts retain source digests, source commits, exact facts, byte-identical Markdown sidecars, and separate import/redaction metadata."
  - "Only journey_attempt records may share a manifest role; IDs and paths remain globally unique while sealed core roles stay singleton."
requirements-completed: [HYGIENE-02]
duration: 10min
completed: 2026-08-26
status: complete
---

# Phase 133 Plan 03: Preserve First Journey Evidence Batch Summary

**Four historical clean-room failures are now preserved as ordered, digest-bound JSON records with byte-identical explanatory sidecars, while remaining inert advisory evidence.**

## Performance

- **Duration:** 10 min
- **Completed:** 2026-08-26T22:02:35Z
- **Tasks:** 1/1
- **Files modified:** 13

## Accomplishments

- Added a strict journey-attempt schema that separates historical facts, provenance, paired narrative, import metadata, redaction classification, and append-only supersession.
- Imported source attempts 001–004 in stable chronology, retaining their source SHA-256 values, Git commits, source facts, and byte-identical Markdown narratives.
- Expanded the journey index and manifest with stable IDs and payload digests; focused tests verify order, uniqueness, schema validity, source-digest/fact equality, narrative pairing, and no supersession.

## Task Commits

1. **Task 1: Import journey attempts 001-004** - `3d217db` (RED test), `4b16d33` (GREEN implementation)

## Verification

- `mix test test/scripts/repository_evidence_test.exs` passed: 6 tests, 0 failures.
- The focused test proves exactly four unique ordered journey IDs, one manifest record and paired sidecar per ID, schema-valid source/import/redaction separation, and digest-bound source facts.
- Original `priv/journey_evidence/` sources remain unchanged and no journey consumer or public API was activated.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Allowed the append-only journey role to repeat in the manifest**
- **Found during:** Task 1 green verification.
- **Issue:** The existing uniqueness validator rejected all repeated roles, including the planned four `journey_attempt` records.
- **Fix:** Kept ID/path global uniqueness and core-role singleton enforcement, but excluded only `journey_attempt` from role-singleton checking.
- **Files modified:** `dev/rendro/repository_evidence.ex`.
- **Verification:** Focused suite passed with all four journey records present.
- **Commit:** `4b16d33`.

**2. [Rule 3 - Blocking] Used the Mix-compatible focused test command**
- **Found during:** Task 1 verification.
- **Issue:** Mix 1.19 rejects the plan's `-x` option.
- **Fix:** Ran the equivalent `mix test test/scripts/repository_evidence_test.exs` command.
- **Files modified:** None.
- **Verification:** Focused suite passed.

**Total deviations:** 2 auto-fixed (Rule 1: 1; Rule 3: 1).
**Impact:** No public contract or consumer was added; the loader change is required for the manifest's explicitly append-only journey role.

## Known Stubs

None. The records are intentionally inert historical evidence; later plans may append records but do not need a runtime consumer.

## Threat Flags

None. This plan adds no network endpoint, authentication path, filesystem input boundary, or schema at a runtime trust boundary.

## Self-Check: PASSED

- Created attempt schema and all four JSON/Markdown record pairs exist.
- TDD commits `3d217db` and `4b16d33` exist in Git history.
