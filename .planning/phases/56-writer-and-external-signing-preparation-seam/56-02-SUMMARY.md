---
phase: 56-writer-and-external-signing-preparation-seam
plan: 02
subsystem: api
tags: [elixir, pdf, signing, artifact, adapters]
requires:
  - phase: 56-01
    provides: deterministic unsigned signature widget bytes in the existing writer output
provides:
  - artifact-first `Rendro.Sign.prepare/2` seam over rendered `%Rendro.Artifact{}`
  - narrow `metadata.signing_preparation` manifest with placeholder offsets and reserve sizing
  - optional `Rendro.Sign.Adapter` behaviour for future signer-specific handoff work
affects: [57-01, 57-02, signing, support-boundaries]
tech-stack:
  added: []
  patterns: [artifact-first post-render transform, namespaced adapter metadata, typed prepare-stage errors]
key-files:
  created: [lib/rendro/sign.ex, lib/rendro/sign/adapter.ex, test/rendro/sign_test.exs]
  modified: [lib/rendro/error.ex, test/rendro/error_test.exs]
key-decisions:
  - "Prepare operates by patching Rendro-owned `/FT /Sig` widget bytes after render instead of threading document state or adding a render-time index."
  - "The shared core manifest stays generic under `metadata.signing_preparation`; adapter-local data, when present, is isolated under `metadata.signing_preparation_adapter`."
patterns-established:
  - "Mirror `Rendro.Protect` for trust-sensitive post-render APIs: normalize options, mutate artifact bytes once, and return `Artifact.wrap/3`."
  - "Keep signing support truthful by reserving only placeholder coordinates and capacity in core while deferring cryptographic execution to optional adapters."
requirements-completed: [PREP-01, PREP-02, PREP-03]
duration: 32 min
completed: 2026-05-07
---

# Phase 56 Plan 02: Writer and External Signing Preparation Seam Summary

**Artifact-first signing preparation that patches rendered `/FT /Sig` widget bytes, returns a wrapped prepared artifact, and keeps signer-specific state outside the shared core manifest**

## Performance

- **Duration:** 32 min
- **Started:** 2026-05-07T01:16:00Z
- **Completed:** 2026-05-07T01:48:49Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added `Rendro.Sign.prepare/2` as the canonical post-render signing-preparation seam over `%Rendro.Artifact{}`.
- Added deterministic placeholder reservation and manifest offsets for `/ByteRange` and `/Contents` without changing `Rendro.render/2` or authored document state.
- Added a behaviour-only optional adapter boundary and prepare-stage error guidance that stays free of signer secrets and trust claims.

## Task Commits

1. **TDD RED: failing signing-preparation coverage** - `fcf6bb2` (`test`)
2. **Task 1 + Task 2 GREEN: signing-preparation seam and optional adapter boundary** - `d2abb3f` (`feat`)

## Files Created/Modified
- `lib/rendro/sign.ex` - Normalizes prepare options, patches rendered signature widget bytes, wraps prepared artifacts, and optionally invokes a signer adapter.
- `lib/rendro/sign/adapter.ex` - Defines the optional behaviour boundary for external signer integrations.
- `lib/rendro/error.ex` - Adds `:prepare` stage `what/why/next` guidance for signing-preparation failures.
- `test/rendro/sign_test.exs` - Covers prepared artifact manifest shape, typed validation, field lookup failures, and adapter metadata isolation.
- `test/rendro/error_test.exs` - Pins prepare-stage caller guidance and secret-free wording.

## Decisions Made
- Kept field lookup binary-first and scoped to Rendro-owned unsigned widget output from `56-01` so the artifact seam does not pull `%Rendro.Document{}` or new render metadata into the API.
- Reserved only deterministic placeholder offsets and lengths in the shared manifest; no keys, certificates, signer identity, compliance labels, `/Filter`, or `/SubFilter` data enters core metadata.
- Let optional adapters run only after core preparation and forced their metadata into a separate namespaced metadata key to preserve the shared contract.

## Deviations from Plan

- Task 1 and Task 2 were implemented in one GREEN commit instead of two separate feature commits.
- Reason: the shared `test/rendro/sign_test.exs` RED gate covered both the core prepare seam and the optional adapter metadata boundary; splitting the implementation would have required temporary test churn rather than a clean atomic task boundary.
- Impact: no scope expansion. The shipped code still matches the plan boundaries and each TDD gate remains explicit (`test` commit then `feat` commit).

## Issues Encountered

- The initial RED test shape bound manifest offsets incorrectly and failed at compile time. The test was corrected before proceeding so the red gate reflected the missing seam rather than a broken assertion.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 57 can now document and verify the narrow support boundary between unsigned signature fields, prepared artifacts, and unsupported digital-signature trust claims.
- No signer implementation, key custody flow, certificate trust surface, or compliance claim was added in core.

## Self-Check: PASSED

- Verified summary file exists at `.planning/phases/56-writer-and-external-signing-preparation-seam/56-02-SUMMARY.md`.
- Verified task commits `fcf6bb2` and `d2abb3f` exist in git history.
