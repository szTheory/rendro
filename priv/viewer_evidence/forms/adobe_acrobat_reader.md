---
schema_version: 1
surface: forms
viewer: adobe_acrobat_reader
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/forms_support_fixture.pdf"
behaviors:
  - behavior: open
    result: pass
    note: "pdfium-cli info opened the forms fixture without parse errors (structural proxy for forms × Adobe Acrobat Reader — does not re-run Acrobat GUI)."
  - behavior: default_state_visible
    result: pass
    note: "pdfium-cli form reported default AcroForm widget values for the representative forms fixture (structural bytes, not Acrobat field panel rendering)."
  - behavior: edit_or_toggle
    result: pass
    note: "Automation proxy re-rendered edited fixture bytes; pdfium-cli form confirmed toggled widget values (structural round-trip, not Acrobat edit/toggle GUI)."
  - behavior: save
    result: pass
    note: "pdfium-cli re-read persisted widget values after edited fixture write (structural round-trip, not Acrobat Save As GUI)."
---

This evidence records **forms × Adobe Acrobat Reader** using pdfium-cli structural checks on Linux/macOS CI.
PDFium CLI form extraction is an automation proxy — it does not validate Adobe Acrobat Reader GUI behavior.

Fixture regeneration:

```elixir
MIX_ENV=test mix run -e 'Rendro.Test.FormSupportFixture.write_fixture("test/fixtures/forms_support_fixture.pdf")'
```
