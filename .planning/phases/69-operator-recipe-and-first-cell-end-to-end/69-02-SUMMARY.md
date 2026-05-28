---
phase: 69-operator-recipe-and-first-cell-end-to-end
plan: 02
subsystem: viewer-evidence
tags: [pdfium-cli, forms, automation, live-proof]

requires:
  - phase: 69-01
    provides: operator guide and fixture path
provides:
  - forms × chrome_pdfium CI-automated evidence (RECIPE-01)
  - Rendro.Adapters.Pdfium + FormsPdfiumProof + Recorder
  - mix rendro.viewer_evidence record forms chrome_pdfium
affects:
  - 69-03 public contract closure

tech-stack:
  added: []
  patterns:
    - "pdfium-cli automation proxy with viewer_kind pdfium-cli"
    - "live_pdf_tools gated forms viewer evidence lane"

key-files:
  created:
    - lib/rendro/adapters/pdfium.ex
    - lib/rendro/viewer_evidence/forms_pdfium_proof.ex
    - lib/rendro/viewer_evidence/recorder.ex
    - priv/viewer_evidence/forms/chrome_pdfium.md
    - test/rendro/adapters/forms_viewer_evidence_live_test.exs
    - test/rendro/forms/acroform_fixture_test.exs
  modified:
    - priv/support_matrix.json
    - lib/mix/tasks/rendro/viewer_evidence.ex
    - guides/viewer_evidence.md

requirements-completed: [RECIPE-01]

duration: 45min
completed: 2026-05-28
---

# Phase 69 Plan 02: Forms × Chrome PDFium (CI-Automated) Summary

Shift-left pivot: first worked cell is **forms × chrome_pdfium** via pdfium-cli on Linux CI — zero human Preview checkpoint. Apple Preview re-home deferred to Phase 70.

## Self-Check: PASSED

- Fixture committed; evidence validates; matrix promoted with `viewer_kind: pdfium-cli`
- `mix test` 701 tests 0 failures; `mix docs.contract` 8/8 lanes green
