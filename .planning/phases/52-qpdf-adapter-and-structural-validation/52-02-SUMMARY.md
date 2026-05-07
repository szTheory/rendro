---
phase: 52-qpdf-adapter-and-structural-validation
plan: 02
subsystem: adapters
tags: [elixir, pdf, poppler, qpdf, validation, docs-contract]
requires:
  - phase: 52-01
    provides: contracted protection permission surface and qpdf mapping
provides:
  - password-aware Poppler validation with stable redacted failure reasons
  - opt-in live qpdf plus pdfinfo proof lane excluded from default tests
  - docs-contract coverage for owner-password fallback wording
affects: [phase-52, validation, poppler, protection, docs]
tech-stack:
  added: []
  patterns: [injected executable seams, normalized external-tool failures, opt-in live proof lane]
key-files:
  created:
    - test/rendro/adapters/protected_validation_live_test.exs
  modified:
    - lib/rendro/adapters/poppler.ex
    - test/rendro/adapters/poppler_test.exs
    - test/test_helper.exs
    - guides/api_stability.md
    - test/docs_contract/protection_claims_test.exs
key-decisions:
  - Poppler now uses exactly one password path per call: `open_password` first, otherwise `owner_password`, never both.
  - Raw `pdfinfo` stderr remains internal and is normalized into stable reason atoms at the public boundary.
  - The real-tool proof lane stays explicit and excluded by default so ordinary `mix test` does not depend on host qpdf availability.
patterns-established:
  - "External validation seams inject finder/runner functions for hermetic tests and classify raw tool failures before returning."
  - "Live host-tool proof stays behind the `live_pdf_tools` tag and skips cleanly when required executables are absent."
requirements-completed: [ADAPT-02]
duration: 1 execution pass
completed: 2026-05-06
---

# Phase 52 Plan 02: Qpdf Adapter and Structural Validation Summary

**Password-aware Poppler validation, normalized failure reasons, and an explicit live proof lane**

## Accomplishments

- Reworked `Rendro.Adapters.Poppler.validate/2` around injected executable finder/runner seams, single-path password precedence, and stable reason classification (`:password_required`, `:incorrect_password`, `:structural_invalidity`, `:tool_failure`) while preserving the existing missing-executable contract.
- Replaced host-dependent default Poppler tests with hermetic regression coverage for password precedence, missing executable handling, metadata parsing, and failure normalization.
- Added `test/rendro/adapters/protected_validation_live_test.exs` under `@tag live_pdf_tools: true` and configured `ExUnit` to exclude that lane by default; after installing `qpdf 12.3.2`, the explicit live command now passes on this host with real `qpdf` + `pdfinfo`.
- Narrowed the API stability wording so owner-password-only validation is documented as structural fallback proof, not proof of the normative password-to-open path.

## Verification

- `mix test test/rendro/adapters/poppler_test.exs test/docs_contract/protection_claims_test.exs`
- `mix test --include live_pdf_tools test/rendro/adapters/protected_validation_live_test.exs`
- `mix test test/rendro/protect_test.exs test/rendro/adapters/qpdf_test.exs test/rendro/adapters/poppler_test.exs test/docs_contract/protection_claims_test.exs`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The initial live proof file had a syntax error**
- **Found during:** Live-lane verification
- **Issue:** The first draft of `protected_validation_live_test.exs` failed to compile.
- **Fix:** Rewrote the control flow to a simpler `cond`-based structure and reran the explicit live command.
- **Files modified:** `test/rendro/adapters/protected_validation_live_test.exs`
- **Verification:** `mix test --include live_pdf_tools test/rendro/adapters/protected_validation_live_test.exs`

### Workflow Deviations

**1. [Rule 3 - Tooling] `gsd-sdk query` subcommands were unavailable in this environment**
- **Impact:** The stock execute-phase orchestration could not auto-update init/state metadata or wave tracking.
- **Handling:** Executed directly from the phase plan artifacts and captured the results in summary files instead.

**2. [Rule 4 - Execution hygiene] Atomic task commits were skipped because the worktree was already dirty**
- **Impact:** Per-task commits were unsafe because they could have captured unrelated in-progress repo changes.
- **Handling:** Left all changes uncommitted for user review and manual sequencing.

## Issues Encountered

- The first real-tool execution surfaced two correctness gaps in the live lane rather than adapter bugs: the runtime-built fixed-page fixture initially overflowed Rendro's page bounds, and Poppler's local no-password failure text was `Incorrect password`, which needed to normalize to `:password_required` when no password was supplied. Both were fixed and re-verified.

## Next Phase Readiness

- Phase 52 now has both hermetic default coverage and an explicit real-tool proof lane for protected structural validation.
- The docs and adapter semantics now distinguish normative open-password proof from owner-password fallback, which keeps downstream support claims truthful.

## Self-Check: PASSED

- Verified the targeted Poppler/docs test command passed with `14 tests, 0 failures`.
- Verified the combined phase-targeted test command passed with `34 tests, 0 failures`.
- Verified the explicit live-lane command passed on this host with real `qpdf 12.3.2` and `pdfinfo`.
- Verified this summary file exists at `.planning/phases/52-qpdf-adapter-and-structural-validation/52-02-SUMMARY.md`.

---
*Phase: 52-qpdf-adapter-and-structural-validation*
*Completed: 2026-05-06*
