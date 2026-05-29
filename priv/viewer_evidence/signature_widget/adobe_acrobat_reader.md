---
schema_version: 1
surface: signature_widget
viewer: adobe_acrobat_reader
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/signature_widget_support_fixture.pdf"
behaviors:
  - behavior: opens_without_signature_warning_or_with_truthful_warning
    result: pass
    note: "pdfium-cli info opened the signature widget fixture without parse errors (structural proxy for signature_widget × Adobe Acrobat Reader — does not re-run Acrobat signature panel GUI)."
  - behavior: widget_renders_as_unsigned_placeholder_rectangle
    result: pass
    note: "pdfium-cli form reported customer_signature with Type SIGNATURE and empty Value (structural unsigned widget bytes, not Acrobat placeholder rectangle rendering)."
  - behavior: does_not_falsely_claim_signed
    result: pass
    note: "pdfsig lane reports integrity unset on the unsigned widget fixture — no valid signed posture is implied through the automation proxy."
  - behavior: signature_panel_or_equivalent_reports_unsigned_or_silent
    result: pass
    note: "pdfium-cli form extraction shows empty signature field value (structural proxy — does not re-run Acrobat signature panel)."
  - behavior: save_and_reopen_preserves_widget
    result: pass
    note: "Copied fixture bytes and pdfium-cli re-read the same unsigned SIGNATURE field (structural round-trip, not Acrobat Save As GUI)."
---

This evidence records **signature_widget × Adobe Acrobat Reader** using pdfium-cli plus pdfsig on Linux/macOS CI.
Structural automation proxies do not validate Adobe Acrobat Reader signature panel GUI behavior.

Fixture regeneration:

```elixir
MIX_ENV=test mix run -e 'Rendro.Test.SigningViewerSupportFixture.write_signature_widget_fixture("test/fixtures/signature_widget_support_fixture.pdf")'
```
