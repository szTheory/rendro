---
phase: 92-docs-claims-release-hygiene
plan: 02
subsystem: docs-release
tags: [hexdocs, package, github-actions, release]

requires:
  - phase: 92-docs-claims-release-hygiene
    provides: public docs and support rows from plan 92-01
provides:
  - Hex package and ExDoc inclusion for ADOPTION.md and CHANGELOG.md
  - Read-only CI and release workflow permissions
  - Package and workflow guardrail tests
affects: [hex-package, hexdocs, release-workflows]

tech-stack:
  added: []
  patterns:
    - Public linked root docs included in package.files and docs.extras
    - Workflow token permissions asserted through parsed YAML guardrails

key-files:
  created: []
  modified:
    - mix.exs
    - guides/upgrading_to_1.0.md
    - CHANGELOG.md
    - .github/workflows/ci.yml
    - .github/workflows/release.yml
    - test/docs_contract/launch_artifacts_claims_test.exs
    - test/guardrails/required_checks_contract_test.exs

key-decisions:
  - "Include ADOPTION.md and CHANGELOG.md as ExDoc extras so public docs links resolve."
  - "Use top-level contents: read permissions for CI and release without changing tag-gated Hex publishing."

patterns-established:
  - "Release hygiene changes should be guarded by package-content tests and parsed workflow YAML tests."

requirements-completed: [DOC-02]

duration: single session
completed: 2026-06-13
---

# Plan 92-02: Package, HexDocs, and Workflow Hygiene Summary

**Public linked docs are now included in package/docs contexts, and CI/release workflows use read-only repository token permissions.**

## Accomplishments

- Added `ADOPTION.md` and `CHANGELOG.md` to `mix.exs` package/docs configuration.
- Fixed the upgrading guide changelog link for ExDoc.
- Added top-level `permissions: contents: read` to CI and release workflows.
- Extended package and workflow tests for `ADOPTION.md` package inclusion and read-only workflow permissions.

## Task Commits

1. **Package and workflow hygiene:** `a0eb1b1` ci(92-02): harden docs package and workflow hygiene

## Verification

- `mix test test/docs_contract/launch_artifacts_claims_test.exs test/guardrails/required_checks_contract_test.exs` - 30 tests, 0 failures.
- `mix hex.build --unpack /tmp/rendro_hex_phase92` - passed and listed `ADOPTION.md`.
- `mix docs` - passed; targeted missing `ADOPTION.md` and `../CHANGELOG.md` warnings removed.

## Self-Check

Self-Check: PASSED

---
*Phase: 92-docs-claims-release-hygiene*
*Plan: 02*
*Completed: 2026-06-13*
