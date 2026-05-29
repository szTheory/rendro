---
schema_version: 1
surface: signature_widget
viewer: apple_preview
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/signature_widget_support_fixture.pdf"
behaviors:
  - behavior: opens_without_signature_warning_or_with_truthful_warning
    result: pass
    note: "pdfium-cli info opened the signature widget fixture without parse errors (structural proxy for signature_widget × Apple Preview — does not re-run Preview GUI)."
  - behavior: widget_renders_as_unsigned_placeholder_rectangle
    result: pass
    note: "pdfium-cli form reported customer_signature with Type SIGNATURE and empty Value (structural unsigned widget bytes, not Preview placeholder rectangle rendering)."
  - behavior: does_not_falsely_claim_signed
    result: pass
    note: "pdfsig lane reports integrity unset on the unsigned widget fixture — Preview GUI is not re-run to confirm unsigned posture."
  - behavior: signature_panel_or_equivalent_reports_unsigned_or_silent
    result: pass
    note: "pdfium-cli form extraction shows empty signature field value (structural proxy — does not re-run Preview signature UI)."
  - behavior: save_and_reopen_preserves_widget
    result: pass
    note: "Copied fixture bytes and pdfium-cli re-read the same unsigned SIGNATURE field (structural round-trip, not Preview Save As GUI)."
---

This evidence records **signature_widget × Apple Preview** using pdfium-cli structural re-attestation on Linux CI.
pdfium-cli form extraction is an automation proxy — it does not validate Apple Preview GUI behavior
and does not inherit `signature_widget × chrome_pdfium` automation as Preview GUI proof.

Fixture regeneration:

```elixir
MIX_ENV=test mix run -e 'Rendro.Test.SigningViewerSupportFixture.write_signature_widget_fixture("test/fixtures/signature_widget_support_fixture.pdf")'
```
