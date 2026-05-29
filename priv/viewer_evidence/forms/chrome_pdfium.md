---
schema_version: 1
surface: forms
viewer: chrome_pdfium
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-28"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/forms_support_fixture.pdf"
behaviors:
  - behavior: open
    result: pass
    note: "pdfium-cli info opened test/fixtures/forms_support_fixture.pdf without parse errors (PDFium CLI open proxy, not GUI Apple Preview)."
  - behavior: default_state_visible
    result: pass
    note: "pdfium-cli form reported email=jon@example.test, terms checked, and contact radio group value email for the representative forms fixture widgets."
  - behavior: edit_or_toggle
    result: pass
    note: "Automation proxy: re-rendered edited fixture bytes and pdfium-cli form confirmed email updated@example.test, terms unchecked, and contact radio switched to phone."
  - behavior: save
    result: pass
    note: "Saved edited PDF to forms_support_edited.pdf and pdfium-cli form re-read the persisted widget values after reopen (structural round-trip, not Save As GUI)."
---

This evidence records **forms × chrome_pdfium** using pdfium-cli on Linux/macOS CI.
PDFium CLI structural and form-field extraction is an automation proxy — it does not
validate GUI Apple Preview or Adobe Acrobat behavior.

Fixture regeneration:

```elixir
MIX_ENV=test mix run -e 'Rendro.Test.FormSupportFixture.write_fixture("test/fixtures/forms_support_fixture.pdf")'
```

Boundary: Poppler/pdfinfo structural proof and pdfium-cli form extraction prove authored
AcroForm bytes and field values only. Promoting this cell does not promote other viewers
or surfaces.
