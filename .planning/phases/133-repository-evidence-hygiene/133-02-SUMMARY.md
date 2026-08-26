---
phase: 133-repository-evidence-hygiene
plan: "02"
subsystem: repository evidence
tags: [elixir, jsv, json-schema, sha256, release-evidence]
requires:
  - phase: 133-repository-evidence-hygiene
    provides: manifest-led public prerequisite tracer and fail-closed loader
provides:
  - Strict sealed release identity, validation, and journey index capsule roles
  - Maintainer-only role dispatch through one fail-closed validation pipeline
affects: [133-03, 133-04, release-evidence, clean-room-proof]
tech-stack:
  added: []
  patterns: ["Authority-separated advisory evidence roles validate schema, path, digest, and release/candidate binding before exposure."]
key-files:
  created:
    - evidence/releases/v1.3.4/release_identity.json
    - evidence/releases/v1.3.4/validation.json
    - evidence/releases/v1.3.4/journey/index.json
    - priv/schemas/release_evidence_identity.schema.json
    - priv/schemas/release_evidence_validation.schema.json
    - priv/schemas/release_evidence_journey_index.schema.json
  modified:
    - evidence/releases/v1.3.4/manifest.json
    - dev/rendro/repository_evidence.ex
    - test/scripts/repository_evidence_test.exs
key-decisions:
  - "The new role envelopes bind to the manifest release, tag, and candidate while explicitly retaining Git controls as authority."
  - "The journey index starts empty and append-only; no attempt consumer is activated until later plans add records."
patterns-established:
  - "Use load_role/1 only for the four fixed maintainer-internal role atoms; do not expose repository evidence as runtime or public API."
requirements-completed: [HYGIENE-02]
coverage:
  - id: D1
    description: "All four sealed roles load only after manifest, role-specific schema, regular-path, digest, and release/candidate binding validation."
    requirement: HYGIENE-02
    verification:
      - kind: integration
        ref: "mix test test/scripts/repository_evidence_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Role substitution, wrong schemas, binding and digest changes, unsafe paths, and missing or duplicate core roles fail closed."
    requirement: HYGIENE-02
    verification:
      - kind: integration
        ref: "test/scripts/repository_evidence_test.exs#fails closed when a requested role, role schema, binding, digest, path, or core role is invalid"
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-26
status: complete
---

# Phase 133 Plan 02: Add Authority-Separated Core Capsule Roles Summary

**The v1.3.4 capsule now seals separate advisory identity, validation, and ordered-journey roles behind one strict, maintainer-only loader.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-08-26T21:35:53Z
- **Completed:** 2026-08-26T21:43:50Z
- **Tasks:** 1/1
- **Files modified:** 12

## Accomplishments

- Added provenance-preserving release identity, successful validation identity, and empty append-only journey-index records.
- Added strict JSV schemas with explicit advisory classification, source/import separation, immutable supersession fields, and Git-authority wording.
- Extended `Rendro.RepositoryEvidence.load_role/1` to validate every fixed core role through the same manifest, confinement, digest, schema, and binding pipeline.

## Task Commits

1. **Task 1: Add authority-separated core capsule roles** - `c510941` (test), `d8a0def` (feat)

## Files Created/Modified

- `evidence/releases/v1.3.4/manifest.json` - stable core-role index with release and candidate binding.
- `evidence/releases/v1.3.4/{release_identity,validation}.json` and `journey/index.json` - sealed, advisory historical role envelopes.
- `priv/schemas/release_evidence_{identity,validation,journey_index}.schema.json` - strict role-specific contracts.
- `dev/rendro/repository_evidence.ex` - shared internal `load_role/1` dispatch and fail-closed validation.
- `test/scripts/repository_evidence_test.exs` - positive role loading and mutation rejection coverage.

## Decisions Made

- Kept historical source facts, import metadata, redaction classification, and authority wording separate in every new role record.
- Used an intentionally empty journey index as valid preparation for later attempt-record plans; it has no active consumer.

## Verification

- `mix test test/scripts/repository_evidence_test.exs` passed: 5 tests, 0 failures.
- All nine planned physical paths exist; focused tests exercise every new role and core-role mutation rejection.
- No `lib/`, public documentation, runtime API, consumer, package, workflow, or rendered output changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated the obsolete focused-test invocation**
- **Found during:** Task 1
- **Issue:** Mix 1.19 rejects the plan's `-x` option.
- **Fix:** Ran the equivalent focused test command without `-x`.
- **Files modified:** None.
- **Verification:** The focused suite passed after the implementation.

---

**Total deviations:** 1 auto-fixed (Rule 3).
**Impact on plan:** No scope change; the current Mix-compatible command covers the same role contract.

## Known Stubs

None. The empty journey dataset is intentional, schema-valid preparation for Plans 03-04 and does not block this plan's sealed-core-role goal.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plans 133-03 and 133-04 can add immutable journey attempt records to the established empty index without changing the loader boundary.

## Self-Check: PASSED

- All nine declared physical paths exist.
- Task commits `c510941` and `d8a0def` exist in Git history.

---
*Phase: 133-repository-evidence-hygiene*
*Completed: 2026-08-26*
