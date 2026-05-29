---
schema_version: 1
surface: protection
viewer: apple_preview
viewer_version: "pdfinfo version 26.04.0"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/protection_support_fixture.pdf"
behaviors:
  - behavior: opens_with_open_password
    result: pass
    note: "pdfinfo opened the protected fixture when supplied the fixture open password at validation time (structural proxy — password not recorded in evidence; does not exercise Preview password prompt GUI)."
  - behavior: displays_authored_content_correctly
    result: pass
    note: "pdfinfo reported page count metadata after decrypting with the open password (structural readability proxy, not Preview rendered content GUI)."
  - behavior: advisory_print_behavior
    result: pass
    note: "qpdf --show-encryption reported permission flags observationally (advisory posture only — not Preview print UI behavior)."
  - behavior: advisory_copy_behavior
    result: pass
    note: "qpdf --show-encryption output includes P/R permission fields for observational advisory copy/print posture (not Preview copy UI behavior)."
  - behavior: save_and_reopen_readability
    result: pass
    note: "Copied protected fixture bytes to a temp path and pdfinfo re-opened successfully with the open password (structural round-trip, not Preview Save As GUI)."
---

This evidence records **protection × Apple Preview** using pdfinfo and qpdf structural checks on Linux CI.
Original v1.10 Phase 54 protection audit is cited for provenance only — CI does not re-run Preview password
prompt, advisory print/copy UI, or Save As GUI.

Regenerating the fixture produces **new bytes** and requires re-running this structural proof lane:

```bash
mix run scripts/protected_viewer_proof_fixture.exs --output test/fixtures/protection_support_fixture.pdf
```

Open passwords are supplied to validators at runtime only — never recorded in this evidence file.
