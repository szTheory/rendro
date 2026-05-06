---
phase: 51-protection-api-contract-and-validation
plan: 01
subsystem: api
tags: [elixir, pdf, qpdf, validation, security]
requires:
  - phase: 50-03
    provides: artifact-first rendering and typed artifact surfaces used by the protection wrapper
provides:
  - canonical `Rendro.Protect.password/2` boundary validation with typed `:protect` errors
  - optional-runtime qpdf adapter execution with cleanup on success and failure
  - redacted protect-stage failures that avoid password and stderr leakage
affects: [phase-52, phase-53, protection, adapter-runtime]
tech-stack:
  added: [qpdf-runtime-seam]
  patterns: [artifact-first post-processing, injected executable runner, redacted error envelopes]
key-files:
  created:
    - lib/rendro/protect.ex
    - lib/rendro/protect/adapter.ex
    - lib/rendro/adapters/qpdf.ex
    - test/rendro/protect_test.exs
    - test/rendro/adapters/qpdf_test.exs
  modified:
    - lib/rendro/error.ex
    - test/rendro/error_test.exs
key-decisions:
  - Keep option normalization inside `Rendro.Protect` instead of extracting a helper module, preserving the canonical public seam.
  - Collapse qpdf process failures to safe typed reasons (`{:qpdf_failed, exit_code}` and `{:command_failed, exception_module}`) so stderr and passwords never escape.
patterns-established:
  - "Artifact-first protection remains a wrapper over rendered `%Rendro.Artifact{}` values, not a render-pipeline option."
  - "Executable-backed adapters use injectable runtime seams and always clean temporary state in `after` cleanup."
requirements-completed: [PROTECT-01, PROTECT-02, PROTECT-03]
duration: 4 min
completed: 2026-05-06
---

# Phase 51 Plan 01: Protection API Contract and Validation Summary

**Artifact-first PDF protection with strict AES-256 option validation, typed protect-stage failures, and cleanup-safe qpdf runtime execution**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-06T10:34:52Z
- **Completed:** 2026-05-06T10:39:09Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Locked `Rendro.Protect.password/2` as the canonical artifact boundary, including typed rejection of malformed top-level options before any adapter call.
- Proved the public contract for adapter validity, AES-256-only enforcement, required passwords, and curated advisory permissions.
- Hardened qpdf execution so temp directories are removed on success, non-zero exit, and runner crashes while public errors stay redacted.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock the public protection contract at the artifact boundary** - `770b534` (`test`), `f64bec2` (`feat`)
2. **Task 2: Harden qpdf execution and the typed protect-stage failure envelope** - `a71de1d` (`test`), `f12f359` (`feat`)

## Files Created/Modified

- `lib/rendro/protect.ex` - Canonical public protection API, option normalization, metadata shaping, and redacted adapter failure wrapping.
- `lib/rendro/protect/adapter.ex` - Minimal adapter behavior contract for artifact protection backends.
- `lib/rendro/adapters/qpdf.ex` - Optional-runtime qpdf adapter with injected executable/runner seams and guaranteed temp-dir cleanup.
- `lib/rendro/error.ex` - Protect-stage diagnostic wording for safe qpdf and command-runner failures.
- `test/rendro/protect_test.exs` - Public contract regression coverage, including malformed options and public error redaction.
- `test/rendro/adapters/qpdf_test.exs` - qpdf runtime seam coverage for success, non-zero exits, and runner crashes.
- `test/rendro/error_test.exs` - Protect-stage guidance coverage for invalid algorithms and safe qpdf failure phrasing.

## Decisions Made

- Kept the normalization logic inline in `Rendro.Protect` because the public seam was already clear and did not justify a helper-module extraction.
- Preserved `Rendro.render_protected/3` as composition-only sugar and concentrated all contract enforcement in `Rendro.Protect.password/2`.
- Treated qpdf stderr as sensitive operational noise and redacted it from the adapter reason tuple instead of forwarding raw process output.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first TDD pass showed most of the public contract had already landed in the dirty worktree; the remaining correctness gaps were malformed top-level option handling and qpdf failure-path cleanup/redaction.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 51 now has a locked public protection contract and a hardened first-party qpdf seam ready for downstream metadata, docs, and validation follow-on work.
- No blockers were introduced for `51-02`; the remaining milestone work is about metadata threading, support claims, and proof lanes rather than API shape.

## Self-Check: PASSED

- Verified `.planning/phases/51-protection-api-contract-and-validation/51-01-SUMMARY.md` exists.
- Verified task commits `770b534`, `f64bec2`, `a71de1d`, and `f12f359` exist in git history.

---
*Phase: 51-protection-api-contract-and-validation*
*Completed: 2026-05-06*
