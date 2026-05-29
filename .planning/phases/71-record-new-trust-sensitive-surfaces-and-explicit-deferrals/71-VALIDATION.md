---
phase: 71
slug: record-new-trust-sensitive-surfaces-and-explicit-deferrals
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-28
---

# Phase 71 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) |
| **Config file** | `mix.exs` test alias |
| **Quick run command** | `mix test test/docs_contract/viewer_evidence_claims_test.exs` |
| **Full suite command** | `mix docs.contract` |
| **Estimated runtime** | ~5 seconds (lane 8); ~5 seconds (full docs.contract) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/docs_contract/viewer_evidence_claims_test.exs`
- **After every plan wave:** Run `mix docs.contract`
- **Before `/gsd-verify-work`:** `mix docs.contract` 8/8 green; `mix rendro.viewer_evidence missing` empty; zero bare `unverified` in trust-sensitive surfaces
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 71-01-01 | 01 | 1 | VIEWER-04, VIEWER-05 | — | Signature widget fixture committed | unit | `mix test test/rendro/signing_viewer_support_fixture_test.exs` | ❌ W0 | ⬜ pending |
| 71-01-02 | 01 | 1 | VIEWER-05 | — | Signing preparation fixture committed | unit | same module test | ❌ W0 | ⬜ pending |
| 71-01-03 | 01 | 1 | VIEWER-06, VIEWER-07 | — | Signed + long-lived viewer proof PDFs | unit | `test -f test/fixtures/signed_artifact_viewer_proof.pdf && test -f test/fixtures/long_lived_viewer_proof.pdf` | ❌ W0 | ⬜ pending |
| 71-02-01 | 02 | 2 | VIEWER-02 | — | forms × Acrobat evidence schema-valid | integration | `mix run -e '...validate_evidence_file(..., skip_path_alignment: true)'` | ❌ W0 | ⬜ pending |
| 71-02-02 | 02 | 2 | VIEWER-03 | — | protection × Acrobat evidence | integration | same pattern | ❌ W0 | ⬜ pending |
| 71-02-03 | 02 | 2 | VIEWER-04 | — | signature_widget evidence (3 supported) | integration | validate each file | ❌ W0 | ⬜ pending |
| 71-02-04 | 02 | 2 | VIEWER-05 | — | signing_preparation × Acrobat evidence | integration | validate file | ❌ W0 | ⬜ pending |
| 71-02-05 | 02 | 2 | VIEWER-06 | — | signed_artifact evidence (Acrobat + PDFium) | integration | validate + live test | ❌ W0 | ⬜ pending |
| 71-02-06 | 02 | 2 | VIEWER-07 | — | long_lived × Acrobat evidence | integration | validate file | ❌ W0 | ⬜ pending |
| 71-02-07 | 02 | 2 | VIEWER-04 | — | pdfium-cli live proofs | integration | `mix test --include live_pdf_tools test/rendro/adapters/signature_widget_viewer_evidence_live_test.exs` | ❌ W0 | ⬜ pending |
| 71-03-01 | 03 | 3 | VIEWER-02–07 | T-71-03-01 | All 20 cells terminal (no bare unverified) | integration | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ❌ W0 | ⬜ pending |
| 71-03-02 | 03 | 3 | VIEWER-04–07 | — | Explicit deferral lint passes | integration | same lane | ❌ W0 | ⬜ pending |
| 71-03-03 | 03 | 3 | VIEWER-05 | — | api_stability equivalence note present | integration | `mix test test/docs_contract/signing_claims_test.exs` | ✅ | ⬜ pending |
| 71-03-04 | 03 | 3 | VIEWER-02–07 | — | `mix rendro.viewer_evidence missing` empty | manual+test | `mix rendro.viewer_evidence missing` | ✅ | ⬜ pending |
| 71-03-05 | 03 | 3 | VIEWER-02–07 | — | CHANGELOG bullets per row | review | human review | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement Coverage

| Requirement | Verification | Status |
|-------------|--------------|--------|
| VIEWER-02 | forms × Acrobat supported + evidence | PENDING |
| VIEWER-03 | protection × Acrobat supported + evidence | PENDING |
| VIEWER-04 | signature_widget promotions + pdfjs deferral | PENDING |
| VIEWER-05 | signing_prep Acrobat + equivalence inheritance | PENDING |
| VIEWER-06 | signed_artifact Acrobat/PDFium + Preview/pdfjs deferrals | PENDING |
| VIEWER-07 | long_lived Acrobat + three deferrals | PENDING |

---

## Wave 0 Requirements

Existing infrastructure covers framework; Phase 71 creates new artifacts:

- [x] `test/docs_contract/viewer_evidence_claims_test.exs` — lane 8 (extend for signing surfaces)
- [x] `lib/rendro/viewer_evidence/validator.ex` — surface path mapping exists
- [x] `scripts/protected_viewer_proof_fixture.exs` — script pattern reference
- [x] `test/rendro/adapters/forms_viewer_evidence_live_test.exs` — pdfium-cli live test pattern
- [ ] `test/support/signing_viewer_support_fixture.ex` — Wave 1 creates
- [ ] `test/rendro/signing_viewer_support_fixture_test.exs` — Wave 1 creates

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Acrobat six-PDF session | VIEWER-02–07 | No headless Acrobat CI | §5.1 in 71-RESEARCH.md checklist |
| Preview signature_widget GUI | VIEWER-04 | No Preview automation | Open fixture; run 5-check; record manual evidence |
| embedded_files × Preview re-verify | VIEWER-04 (adjacent) | GUI Attachments pane | 5-minute re-open; promote or defer per D-12 |
| PDF.js forms 4-check | VIEWER-02 | Browser GUI | Attempt promotion; defer only on failure |
| Deferral clause wording | VIEWER-04–07 | Human judgment within templates | Pre-validate against lint before matrix commit |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
