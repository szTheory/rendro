---
schema_version: 1
surface: signature_widget
viewer: chrome_pdfium
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/signature_widget_support_fixture.pdf"
behaviors:
  - behavior: opens_without_signature_warning_or_with_truthful_warning
    result: pass
    note: "pdfium-cli info opened test/fixtures/signature_widget_support_fixture.pdf without parse errors (PDFium CLI open proxy, not GUI Apple Preview or Adobe Acrobat)."
  - behavior: widget_renders_as_unsigned_placeholder_rectangle
    result: pass
    note: "pdfium-cli form reported customer_signature with Type SIGNATURE and empty Value for the representative unsigned widget fixture."
  - behavior: does_not_falsely_claim_signed
    result: pass
    note: "pdfsig lane reports integrity unset and total_document_signed false on the unsigned widget fixture — no valid signed posture is implied."
  - behavior: signature_panel_or_equivalent_reports_unsigned_or_silent
    result: pass
    note: "pdfium-cli form extraction shows an empty signature field value with no signed contents dictionary surfaced through the automation proxy."
  - behavior: save_and_reopen_preserves_widget
    result: pass
    note: "Copied fixture to signature_widget_roundtrip.pdf and pdfium-cli form re-read the same unsigned SIGNATURE field after reopen (structural round-trip, not Save As GUI)."
---

This evidence records **signature_widget × chrome_pdfium** using pdfium-cli on Linux/macOS CI.
PDFium CLI structural and form-field extraction is an automation proxy — it does not
validate GUI Apple Preview or Adobe Acrobat signature panel behavior.

Fixture regeneration:

```elixir
MIX_ENV=test mix run -e 'Rendro.Test.SigningViewerSupportFixture.write_signature_widget_fixture("test/fixtures/signature_widget_support_fixture.pdf")'
```

Boundary: pdfium-cli form extraction and pdfsig integrity posture prove authored unsigned
`/Sig` widget bytes only. Promoting this cell does not promote manual GUI viewers or other surfaces.
