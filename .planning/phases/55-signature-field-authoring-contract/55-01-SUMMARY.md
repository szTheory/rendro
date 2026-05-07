---
phase: 55-signature-field-authoring-contract
plan: 01
subsystem: api
tags: [forms, signatures, validation, exunit]
requires:
  - phase: 54-02
    provides: proof-backed trust-boundary discipline for narrow support surfaces
provides:
  - explicit `Rendro.signature_field/2` authoring helper
  - shared `%Rendro.FormField{}` support for `type: :signature`
  - validate-stage rejection of unsupported signature authored state
affects: [phase-56-signature-widget-serialization, forms, validation]
tech-stack:
  added: []
  patterns: [shared form-field carrier, rejection-only signature seam, validate-stage boundary enforcement]
key-files:
  created: []
  modified:
    - lib/rendro.ex
    - lib/rendro/form_field.ex
    - lib/rendro/rules/check_form_fields.ex
    - test/rendro_builders_test.exs
    - test/rendro/rules/check_form_fields_test.exs
    - test/rendro/pipeline/validate_test.exs
key-decisions:
  - "Keep `Rendro.signature_field/2` as the explicit public unsigned-signature entrypoint while still normalizing into `%Rendro.FormField{}`."
  - "Carry only enumerated blocked signature attrs through `signature_rejections` so validation can fail them before render."
  - "Enforce visible-placeholder geometry for signature fields in the existing validate stage instead of the writer."
patterns-established:
  - "Signature authoring stays on the shared `%Rendro.FormField{}` path; no parallel forms engine."
  - "Trust-sensitive authored state is preserved only long enough to produce typed validate-stage errors."
requirements-completed: [SIGN-01, SIGN-02]
duration: 4min
completed: 2026-05-07
---

# Phase 55 Plan 01: Signature Field Authoring Contract Summary

**Unsigned signature placeholders now author through `Rendro.signature_field/2` and fail unsupported signature semantics in `Rendro.Pipeline.Validate` before render.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-07T00:30:12Z
- **Completed:** 2026-05-07T00:33:44Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `Rendro.signature_field/2` as the explicit public builder for visible unsigned signature placeholders.
- Extended the shared `%Rendro.FormField{}` model to represent `:signature` and carry only enumerated blocked signature attrs for validate-stage rejection.
- Replaced the old invalid-type posture with typed signature-specific validation for blocked values, widget-family mismatches, signing metadata, signing-policy attrs, and zero-rect placeholders.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the explicit public `Rendro.signature_field/2` helper on the shared form-field path**
   - `1af1849` (`test`) RED: failing builder coverage for the explicit helper
   - `ffa78fb` (`feat`) GREEN: helper implementation plus shared `:signature` type support
2. **Task 2: Replace the old invalid-type rule with a narrow validate-stage signature contract**
   - `63f00ea` (`test`) RED: failing rule and pipeline coverage for signature validation
   - `1b53633` (`feat`) GREEN: rejection-only carrier and typed validate-stage signature enforcement

## Files Created/Modified

- `lib/rendro.ex` - adds `signature_field/2` and preserves blocked signature attrs on a finite internal seam.
- `lib/rendro/form_field.ex` - extends the shared field model with `:signature` and `signature_rejections`.
- `lib/rendro/rules/check_form_fields.ex` - accepts `:signature` internally and rejects unsupported authored signature state with typed tuples.
- `test/rendro_builders_test.exs` - locks the explicit public builder and shared normalization path.
- `test/rendro/rules/check_form_fields_test.exs` - covers accepted signature placeholders and rejected signature misuse categories.
- `test/rendro/pipeline/validate_test.exs` - proves signature-specific validate errors surface through the existing error envelope.

## Decisions Made

- The canonical public seam is `Rendro.signature_field/2`; the generic `form_field(..., type: :signature)` path remains normalization detail, not the primary DX.
- Signature-only blocked attrs are transported in a dedicated finite carrier instead of being silently dropped or exposed as a generic PDF passthrough bag.
- Visible-placeholder enforcement is owned by validation, keeping writer work deferred to the next phase.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix test` emits pre-existing adapter module redefinition warnings for `Rendro.Adapters.Mailglass` and `Rendro.Adapters.Accrue`; tests still passed and this plan did not widen scope to address them.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 56 can now serialize signature widgets against a locked public authoring shape instead of an open-ended signature API.
- The current contract still truthfully excludes signature serialization, external signing preparation, and digital-signature behavior claims.

## Self-Check: PASSED

- Verified modified files exist: `lib/rendro.ex`, `lib/rendro/form_field.ex`, `lib/rendro/rules/check_form_fields.ex`, `test/rendro_builders_test.exs`, `test/rendro/rules/check_form_fields_test.exs`, `test/rendro/pipeline/validate_test.exs`
- Verified commits exist: `1af1849`, `ffa78fb`, `63f00ea`, `1b53633`
- Verified plan-level command passes: `mix test test/rendro_builders_test.exs test/rendro/rules/check_form_fields_test.exs test/rendro/pipeline/validate_test.exs`

---
*Phase: 55-signature-field-authoring-contract*
*Completed: 2026-05-07*
