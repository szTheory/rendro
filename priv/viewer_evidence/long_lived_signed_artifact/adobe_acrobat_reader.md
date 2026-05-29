---
schema_version: 1
surface: long_lived_signed_artifact
viewer: adobe_acrobat_reader
viewer_version: "pyHanko, version 0.35.1 (CLI 0.4.0)"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/long_lived_viewer_proof.pdf"
behaviors:
  - behavior: opens_long_lived_artifact_without_corruption
    result: pass
    note: "pdfium-cli info opened test/fixtures/long_lived_viewer_proof.pdf without parse errors (structural proxy for long_lived_signed_artifact × Adobe Acrobat Reader — does not re-run Acrobat LTV GUI)."
  - behavior: timestamp_recognized_or_silent
    result: pass
    note: "pyHanko validation lane reports document timestamp present on the certomancer-backed long-lived fixture (adapter posture, not Acrobat timestamp panel UI)."
  - behavior: revocation_evidence_recognized_or_silent
    result: pass
    note: "pyHanko validation lane reports revocation embedded embedded in the augmented artifact (adapter posture, not Acrobat revocation UI)."
  - behavior: posture_reported_truthfully
    result: pass
    note: "pyHanko validation reports integrity valid and embedded validation evidence posture without conflating certificate trust (skipped)."
  - behavior: expiry_behavior_honest
    result: pass
    note: "pyHanko validation completed on the representative long-lived fixture; expiry and trust-store policy remain external to Rendro and are not claimed via Acrobat GUI observation."
---

This evidence records **long_lived_signed_artifact × Adobe Acrobat Reader** using pyHanko validation on Linux/macOS CI.
Timestamp and revocation posture come from the pyHanko adapter lane — not from Adobe Acrobat Reader LTV panel GUI observation.

Fixture regeneration:

```bash
mix run scripts/long_lived_viewer_proof_fixture.exs --output test/fixtures/long_lived_viewer_proof.pdf
```
