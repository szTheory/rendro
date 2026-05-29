---
phase: 71-record-new-trust-sensitive-surfaces-and-explicit-deferrals
plan: 02
subsystem: viewer-evidence
tags: [viewer-evidence, ci, structural-proxy, signing, forms, protection]

requires: [71-01]
provides:
  - Phase 71 structural-proxy proof modules and Recorder entries
  - Committed priv/viewer_evidence files for all promoted trust-sensitive cells
  - Live tests that regenerate evidence via Recorder.record/2
affects: [71-03]

tech-stack:
  added: []
  patterns:
    - "Structural-proxy model: matrix viewer labels with pdfium/pdfsig/pyhanko/poppler CI lanes"
    - "GUI negation in evidence body prose (Phase 70 precedent)"

key-files:
  created:
    - lib/rendro/viewer_evidence/forms_acrobat_proof.ex
    - lib/rendro/viewer_evidence/protection_acrobat_proof.ex
    - lib/rendro/viewer_evidence/signature_widget_acrobat_proof.ex
    - lib/rendro/viewer_evidence/signature_widget_apple_preview_proof.ex
    - lib/rendro/adapters/signing_preparation_pdfium_proof.ex
    - lib/rendro/adapters/signed_artifact_acrobat_proof.ex
    - lib/rendro/adapters/long_lived_acrobat_proof.ex
    - test/rendro/adapters/trust_sensitive_viewer_evidence_live_test.exs
    - priv/viewer_evidence/forms/adobe_acrobat_reader.md
    - priv/viewer_evidence/protection/adobe_acrobat_reader.md
    - priv/viewer_evidence/signature_widget/adobe_acrobat_reader.md
    - priv/viewer_evidence/signature_widget/apple_preview.md
    - priv/viewer_evidence/signing_preparation/adobe_acrobat_reader.md
    - priv/viewer_evidence/signed_artifact/adobe_acrobat_reader.md
    - priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md
  modified:
    - lib/rendro/viewer_evidence/recorder.ex
    - lib/rendro/viewer_evidence/observation_environment.ex
    - .planning/phases/71-record-new-trust-sensitive-surfaces-and-explicit-deferrals/71-CONTEXT.md
    - .planning/phases/71-record-new-trust-sensitive-surfaces-and-explicit-deferrals/71-VALIDATION.md
    - .planning/phases/71-record-new-trust-sensitive-surfaces-and-explicit-deferrals/71-02-PLAN.md

key-decisions:
  - "Revoked D-06/D-07/D-19 human GUI checkpoints — CI structural-proxy replaces manual Acrobat/Preview sessions"
  - "viewer_kind stays pdfium-cli for all CI lanes (schema enum constraint)"
  - "signing_preparation non-Acrobat rows inherit signature_widget evidence (D-15)"

requirements-completed: [VIEWER-02, VIEWER-03, VIEWER-04, VIEWER-05, VIEWER-06]

duration: 90min
completed: 2026-05-29
---

# Phase 71 Plan 02 Summary

**Zero-human structural-proxy closure records all Phase 71 promoted viewer evidence via CI proof modules — no GUI sessions.**

## Accomplishments

- Amended 71-CONTEXT to revoke human GUI checkpoints (D-06/D-07/D-19)
- Implemented seven new proof modules covering forms×acrobat, protection×acrobat, signature_widget×{acrobat,preview}, signing_preparation×acrobat, signed_artifact×acrobat, long_lived×acrobat
- Extended Recorder with entries for all promoted cells
- Added trust_sensitive_viewer_evidence_live_test.exs recording all Phase 71 evidence
- Committed nine new/updated evidence markdown files under priv/viewer_evidence/

## Verification

- `mix test --include live_pdf_tools test/rendro/adapters/*viewer_evidence*` — 7 tests, 0 failures
- `mix rendro.viewer_evidence validate` — passed
- All promoted evidence files exist with honest GUI negation in body prose

## Deviations

- forms×pdfjs auto-deferred instead of PdfJs adapter bootstrap (plan optional item cancelled)
- pdfsig/pyhanko/poppler lanes recorded as viewer_kind pdfium-cli per schema enum (honest tool named in evidence body)

## Next

Plan 71-03 closes matrix terminal states, api_stability mirrors, CHANGELOG, and docs-contract in the same PR.
