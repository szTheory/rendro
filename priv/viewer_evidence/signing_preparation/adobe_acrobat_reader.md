---
schema_version: 1
surface: signing_preparation
viewer: adobe_acrobat_reader
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/signing_preparation_support_fixture.pdf"
behaviors:
  - behavior: prepared_artifact_opens_cleanly
    result: pass
    note: "pdfium-cli info opened test/fixtures/signing_preparation_support_fixture.pdf without parse errors (structural proxy for signing_preparation × Adobe Acrobat Reader — does not re-run Acrobat GUI)."
  - behavior: widget_renders_as_unsigned_placeholder
    result: pass
    note: "pdfium-cli form reported customer_signature with Type SIGNATURE on the prepared artifact fixture."
  - behavior: viewer_does_not_silently_re_sign_or_corrupt
    result: pass
    note: "Authored bytes contain /ByteRange and /Contents placeholders from Sign.prepare/2 with no unexpected signature value dictionary."
  - behavior: byte_range_layout_intact_after_save_as
    result: pass
    note: "Copied prepared fixture bytes and pdfium-cli re-opened with /ByteRange and /Contents markers intact (structural round-trip, not Acrobat Save As GUI)."
---

This evidence records **signing_preparation × Adobe Acrobat Reader** using pdfium-cli structural checks on Linux/macOS CI.
Byte-range and /Contents placeholder observation is structural — it does not re-run Adobe Acrobat Reader Save As GUI.

Fixture regeneration:

```elixir
MIX_ENV=test mix run -e 'Rendro.Test.SigningViewerSupportFixture.write_signing_preparation_fixture("test/fixtures/signing_preparation_support_fixture.pdf")'
```
