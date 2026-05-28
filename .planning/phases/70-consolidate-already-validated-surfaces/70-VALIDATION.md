---
phase: 70
slug: consolidate-already-validated-surfaces
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-28
---

# Phase 70 — Validation Strategy

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
- **Before `/gsd-verify-work`:** `mix docs.contract` must be green (8/8 lanes); `mix rendro.viewer_evidence validate` exit 0 with **zero** legacy warnings
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 70-01-01 | 01 | 1 | VIEWER-01 | T-70-01-01 | Embedded fixture committed with deterministic structure | unit | `mix test test/support/embedded_artifact_support_fixture_test.exs` | ✅ | ⬜ pending |
| 70-01-02 | 01 | 1 | VIEWER-01 | — | Protection fixture file exists on disk | unit | `test -f test/fixtures/protection_support_fixture.pdf` | ❌ W0 | ⬜ pending |
| 70-02-01 | 02 | 2 | VIEWER-01 | T-70-02-01 | Five evidence files pass Validator.validate_evidence_file | integration | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ❌ W0 | ⬜ pending |
| 70-02-02 | 02 | 2 | VIEWER-01 | — | Evidence lint: no secrets/home paths | unit | `mix rendro.viewer_evidence validate` (pre-matrix) | ✅ | ⬜ pending |
| 70-03-01 | 03 | 3 | VIEWER-01 | T-70-03-01 | Production matrix promotion-complete | integration | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ❌ W0 | ⬜ pending |
| 70-03-02 | 03 | 3 | VIEWER-01 | — | JSON Schema tier-B flip rejects pointerless supported | unit | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ❌ W0 | ⬜ pending |
| 70-03-03 | 03 | 3 | VIEWER-01 | — | api_stability mirrors all five evidence paths | integration | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ❌ W0 | ⬜ pending |
| 70-03-04 | 03 | 3 | VIEWER-01 | — | forms_claims chrome_pdfium supported drift fixed | integration | `mix test test/docs_contract/forms_claims_test.exs` | ✅ | ⬜ pending |
| 70-03-05 | 03 | 3 | VIEWER-01 | — | embedded/protection family lanes unchanged | integration | `mix test test/docs_contract/embedded_artifact_claims_test.exs test/docs_contract/protection_claims_test.exs` | ✅ | ⬜ pending |
| 70-03-06 | 03 | 3 | VIEWER-01 | — | Zero legacy warnings on validate | manual+test | `mix rendro.viewer_evidence validate` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement Coverage

| Requirement | Verification | Status |
|-------------|--------------|--------|
| VIEWER-01 | Five evidence files + matrix pointers + api_stability mirrors + zero legacy warnings | PENDING |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- [x] `test/docs_contract/viewer_evidence_claims_test.exs` — lane 8 (Phase 68–69)
- [x] `test/docs_contract/forms_claims_test.exs` — forms mirror regression
- [x] `test/docs_contract/embedded_artifact_claims_test.exs` — embedded/links posture
- [x] `test/docs_contract/protection_claims_test.exs` — protection mirror
- [x] `lib/rendro/viewer_evidence/validator.ex` — tier A/B validation
- [x] `test/support/embedded_artifact_support_fixture.ex` — fixture generator

Phase 70 creates new artifacts (two fixture PDFs, five evidence files, schema flip) — no new test framework needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| forms × Apple Preview re-attestation | VIEWER-01 | CI never runs Preview GUI | §5.1 checklist in 70-RESEARCH.md |
| embedded_files × Acrobat re-attestation | VIEWER-01 | Attachments pane not automatable | §5.2 checklist; batch with links × Acrobat |
| links × Acrobat re-attestation | VIEWER-01 | URI handoff not automatable | §5.3 checklist |
| links × Apple Preview re-attestation | VIEWER-01 | Preview link UX not automatable | §5.4 checklist; independent of embedded_files |
| protection × Apple Preview five-check | VIEWER-01 | Password UX trust-sensitive | §5.5 full five-check checklist |
| CHANGELOG five re-home bullets | VIEWER-01 | Human review for RECIPE-05 discipline | Verify five `Changed` bullets under Viewer Evidence (v2.3) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
