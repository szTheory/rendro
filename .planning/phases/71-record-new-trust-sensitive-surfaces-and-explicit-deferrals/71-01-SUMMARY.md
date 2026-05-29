---
phase: 71-record-new-trust-sensitive-surfaces-and-explicit-deferrals
plan: 01
subsystem: testing
tags: [viewer-evidence, fixtures, signing, pdf]

requires: []
provides:
  - Four committed signing-surface fixture PDFs for viewer recording
  - SigningViewerSupportFixture generator module
  - Regen scripts with preflight pattern for signed and long-lived proofs
affects: [71-02, 71-03]

tech-stack:
  added: []
  patterns:
    - "Viewer-evidence carve-out: committed signed PDFs outside test/fixtures/signing/"
    - "Regen scripts mirror protected_viewer_proof_fixture.exs preflight"

key-files:
  created:
    - test/support/signing_viewer_support_fixture.ex
    - test/rendro/signing_viewer_support_fixture_test.exs
    - scripts/signing_viewer_proof_fixtures.exs
    - scripts/signed_artifact_viewer_proof_fixture.exs
    - scripts/long_lived_viewer_proof_fixture.exs
    - test/fixtures/signature_widget_support_fixture.pdf
    - test/fixtures/signing_preparation_support_fixture.pdf
    - test/fixtures/signed_artifact_viewer_proof.pdf
    - test/fixtures/long_lived_viewer_proof.pdf
  modified:
    - test/fixtures/signing/README.md

key-decisions:
  - "Committed signed/LTV PDFs live at test/fixtures/ root per D-09 viewer-evidence carve-out"
  - "Scripts use inline sample_artifact/0 rather than test-only module for default MIX_ENV"

patterns-established:
  - "SigningViewerSupportFixture mirrors FormSupportFixture write_fixture pattern"
  - "signed/long_lived scripts reuse certomancer + pyhanko preflight from signing_live_test"

requirements-completed: [VIEWER-04, VIEWER-05, VIEWER-06, VIEWER-07]

duration: 25min
completed: 2026-05-28
---

# Phase 71 Plan 01 Summary

**Committed signing-surface fixture PDFs and regen scripts unblock Wave 2 manual recording and pdfium-cli promotions.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 4/4
- **Files modified:** 10

## Accomplishments

- Created `Rendro.Test.SigningViewerSupportFixture` with signature widget and signing preparation generators
- Committed four PDF fixtures with structural tests (`/FT /Sig`, `/ByteRange`)
- Added signed-artifact and long-lived regen scripts with preflight blocking
- Documented viewer-evidence carve-out in `test/fixtures/signing/README.md`

## Task Commits

1. **Task 1: Signature widget fixture** - `3dc2db1` (feat)
2. **Task 2: Signing preparation fixture** - `254d8eb` (feat)
3. **Task 3: Signed and long-lived scripts + PDFs** - `9f4f1ef` (feat)
4. **Task 4: Operator regen wrapper** - `10e092f` (feat)

## Files Created/Modified

- `test/support/signing_viewer_support_fixture.ex` - Fixture generator module
- `test/rendro/signing_viewer_support_fixture_test.exs` - Structural assertions
- `scripts/signed_artifact_viewer_proof_fixture.exs` - live_signer PEM signing script
- `scripts/long_lived_viewer_proof_fixture.exs` - certomancer LTV script
- `scripts/signing_viewer_proof_fixtures.exs` - Operator wrapper
- `test/fixtures/*.pdf` - Four committed viewer proof PDFs
- `test/fixtures/signing/README.md` - Viewer-evidence carve-out section

## Verification

- `mix test test/rendro/signing_viewer_support_fixture_test.exs` — 4 tests, 0 failures
- All four fixture PDFs exist with `%PDF` headers
- `grep -i "viewer-evidence carve-out" test/fixtures/signing/README.md` — match
- `mix run scripts/signing_viewer_proof_fixtures.exs --help` — documents all regen commands

## Self-Check: PASSED

- key-files.created spot-check: all exist on disk
- git log grep 71-01: 4 commits found
- Plan verification commands re-run successfully

## Deviations

None — plan executed as written.

## Next

Wave 2 (71-02) requires manual Acrobat/Preview recording sessions before pdfium-cli automation and deferral drafts.
