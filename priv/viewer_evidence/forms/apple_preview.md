---
schema_version: 1
surface: forms
viewer: apple_preview
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/forms_support_fixture.pdf"
behaviors:
  - behavior: open
    result: pass
    note: "pdfium-cli info opened the forms fixture without parse errors (structural proxy for the forms × Apple Preview matrix row — does not re-run Preview GUI)."
  - behavior: default_state_visible
    result: pass
    note: "pdfium-cli form reported email, terms checkbox, and contact radio default widget values for the representative forms fixture (structural AcroForm bytes, not Preview widget rendering)."
  - behavior: edit_or_toggle
    result: pass
    note: "Automation proxy re-rendered edited fixture bytes; pdfium-cli form confirmed toggled widget values (structural round-trip, not Preview edit/toggle GUI)."
  - behavior: save
    result: pass
    note: "pdfium-cli re-read persisted widget values after edited fixture write (structural save round-trip, not Preview Save As GUI)."
---

This evidence records **forms × Apple Preview** using pdfium-cli structural re-attestation on Linux CI.
Original v1.8 Phase 47 GUI validation date **2026-05-05** is cited here for provenance only — CI does
not re-run Apple Preview GUI in this lane.

pdfium-cli form extraction is an automation proxy — it does not validate Apple Preview GUI behavior
and does not inherit `forms × chrome_pdfium` automation as Preview GUI proof (cross-boundary negation).

Fixture regeneration:

```elixir
MIX_ENV=test mix run -e 'Rendro.Test.FormSupportFixture.write_fixture("test/fixtures/forms_support_fixture.pdf")'
```
