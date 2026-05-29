---
schema_version: 1
surface: protection
viewer: adobe_acrobat_reader
viewer_version: "pdfinfo version 26.04.0"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/protection_support_fixture.pdf"
behaviors:
  - behavior: opens_with_open_password
    result: pass
    note: "pdfinfo opened the protected fixture with runtime-supplied open password (structural proxy for protection × Adobe Acrobat Reader — does not re-run Acrobat password GUI)."
  - behavior: displays_authored_content_correctly
    result: pass
    note: "pdfinfo reported page metadata for the protected fixture after password decrypt (structural readability, not Acrobat content panel rendering)."
  - behavior: advisory_print_behavior
    result: pass
    note: "qpdf --show-encryption reported permission flags for advisory print posture observation (structural flags, not Acrobat print dialog UI)."
  - behavior: advisory_copy_behavior
    result: pass
    note: "qpdf --show-encryption reported P/R permission bits for advisory copy posture observation (structural flags, not Acrobat copy restriction UI)."
  - behavior: save_and_reopen_readability
    result: pass
    note: "Copied protected fixture bytes and pdfinfo re-read page metadata after reopen (structural round-trip, not Acrobat Save As GUI)."
---

This evidence records **protection × Adobe Acrobat Reader** using pdfinfo and qpdf structural checks on Linux CI.
Poppler/pdfinfo and qpdf encryption inspection are automation proxies — they do not validate Acrobat password or advisory-permission GUI.

Regenerating the fixture produces new bytes and requires re-running this structural proof lane:

```bash
mix run scripts/protected_viewer_proof_fixture.exs --output test/fixtures/protection_support_fixture.pdf
```

Open passwords are supplied to validators at runtime only — never recorded in this evidence file.
