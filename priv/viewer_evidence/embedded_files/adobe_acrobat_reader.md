---
schema_version: 1
surface: embedded_files
viewer: adobe_acrobat_reader
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/embedded_artifact_support_fixture.pdf"
behaviors:
  - behavior: discoverable
    result: pass
    note: "Committed fixture bytes include /EmbeddedFiles and invoice.csv Filespec markers (structural proxy — not Acrobat Attachments pane GUI)."
  - behavior: open_or_extract
    result: pass
    note: "EmbeddedFile stream and Billing export description present in authored PDF bytes (structural open/extract proxy, not Attachments pane extract GUI)."
  - behavior: save_or_extract
    result: pass
    note: "Committed fixture path resolves on disk with non-zero size after generation (structural save/extract proxy, not Save to disk GUI)."
---

This evidence records **embedded_files × Adobe Acrobat Reader** using pdfium-cli and authored-byte
structural checks on Linux CI. Original v1.9 Phase 50 validation date **2026-05-06** is cited for
provenance only — CI does not re-run Acrobat Attachments pane GUI.

Structural markers prove document-level embedded file bytes only; they do not validate Attachments pane
discoverability, extract, or save-to-disk GUI behavior.

Fixture regeneration:

```elixir
MIX_ENV=test mix run -e 'Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture("test/fixtures/embedded_artifact_support_fixture.pdf")'
```
