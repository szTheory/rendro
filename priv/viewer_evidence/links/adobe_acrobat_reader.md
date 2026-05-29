---
schema_version: 1
surface: links
viewer: adobe_acrobat_reader
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/embedded_artifact_support_fixture.pdf"
behaviors:
  - behavior: external_uri_handoff
    result: pass
    note: "Authored /URI (https://example.com/docs) link annotation present in fixture bytes (structural proxy — not Acrobat external link handoff GUI)."
  - behavior: internal_page_navigation
    result: pass
    note: "Authored internal /Dest page link annotation present in fixture bytes (structural proxy — not Acrobat internal navigation GUI)."
---

This evidence records **links × Adobe Acrobat Reader** using pdfium-cli and authored-byte structural
checks on the shared embedded-artifact fixture. Original v1.9 Phase 50 validation date **2026-05-06**
is cited for provenance only — CI does not re-run Acrobat URI handoff or internal navigation GUI.

Fixture regeneration:

```elixir
MIX_ENV=test mix run -e 'Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture("test/fixtures/embedded_artifact_support_fixture.pdf")'
```
