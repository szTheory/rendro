---
schema_version: 1
surface: forms
viewer: example_viewer
viewer_version: "0.0.0"
platform: "macOS 15 (example)"
recorded_at: "2026-01-01"
fixture: "test/fixtures/example.pdf"
behaviors:
  - behavior: open
    result: pass
    note: "Fixture describing an oversized evidence file violation."
---

This fixture intentionally documents the 65536-byte budget rejection case.
