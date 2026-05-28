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
    note: "Opened the fixture without error."
  - behavior: default_state_visible
    result: pass
    note: "Default field state was visible on first open."
  - behavior: edit_or_toggle
    result: pass
    note: "Edited or toggled the authored field successfully."
  - behavior: save
    result: pass
    note: "Saved the edited PDF without corruption."
---

This template documents the canonical viewer-evidence shape for Phase 68.

Use it when recording a promoted matrix cell. Keep bodies short, factual, and free of
secrets, home-directory paths, embedded images, or PEM material. Promotion state belongs
on the support matrix only; frontmatter carries observation facts and behavior notes.
