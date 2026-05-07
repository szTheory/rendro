---
phase: 55
slug: signature-field-authoring-contract
status: ready
nyquist_compliant: true
wave_0_complete: true
source: planning + execution + phase-58 backfill
created: 2026-05-06
updated: 2026-05-07
---

# Phase 55 — Validation Strategy

> Per-phase validation contract for the unsigned signature-field authoring seam and its truthful support-boundary wording.

Phase 55 has two intentionally separate proof lanes:

1. The **authoring/validation lane** proves `Rendro.signature_field/2` normalizes into the shared form model and that unsupported signature semantics fail during `Rendro.Pipeline.Validate`.
2. The **support-contract lane** proves docs and the support matrix keep unsigned authoring distinct from unsupported rendered/digital-signature claims.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + docs-contract script |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro_builders_test.exs test/rendro/rules/check_form_fields_test.exs test/rendro/pipeline/validate_test.exs test/docs_contract/forms_claims_test.exs` |
| **Full suite command** | `mix test test/rendro_builders_test.exs test/rendro/rules/check_form_fields_test.exs test/rendro/pipeline/validate_test.exs test/docs_contract/forms_claims_test.exs && mix run scripts/verify_docs.exs` |
| **Estimated runtime** | ~15-30 seconds |

## Sampling Rate

- After each `55-01` task: run the narrowest affected builder/validation command.
- After each `55-02` task: run `mix test test/docs_contract/forms_claims_test.exs`.
- Before `$gsd-verify-work`: run the full suite command once the worktree is clean.
- Max automated feedback latency: 30 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 55-01-01 | 01 | 1 | SIGN-01 | T-55-01 | `Rendro.signature_field/2` exists as the canonical public helper and normalizes into `%Rendro.FormField{type: :signature}` without creating a second widget model. | builder / unit | `mix test test/rendro_builders_test.exs` | ✅ | ✅ green |
| 55-01-02 | 01 | 1 | SIGN-02 | T-55-02, T-55-03 | Unsupported signature authored state fails in `Rendro.Pipeline.Validate`, including `value`, button-family carryover attrs, explicit blocked signer metadata / signing keys, and invisible or zero-rect intent. | rule + pipeline | `mix test test/rendro/rules/check_form_fields_test.exs test/rendro/pipeline/validate_test.exs` | ✅ | ✅ green |
| 55-02-01 | 02 | 2 | SIGN-01, SIGN-02 | T-55-04, T-55-05 | Public docs and support metadata distinguish the authored API contract from unsupported rendered/digital-signature claims, without prematurely promoting `forms.widgets.signature`. | docs-contract | `mix test test/docs_contract/forms_claims_test.exs` | ✅ | ✅ green |
| 55-02-02 | 02 | 2 | SIGN-01, SIGN-02 | T-55-05, T-55-06 | The canonical docs verification lane fails on either underclaiming the new helper or overclaiming rendered/digital-signature support. | docs-contract | `mix run scripts/verify_docs.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

## Wave 0 Requirements

- [x] `55-RESEARCH.md` names the validation architecture and the explicit code/test seams.
- [x] Every planned task has an automated verification command.
- [x] The authoring/validation lane and support-contract lane are separated.
- [x] The canonical docs gate remains `mix run scripts/verify_docs.exs`.
- [x] No live viewer proof, signing adapter, or external PDF-tool dependency is required in this phase.

## Automated Proof Lanes

### 1. Authoring / validation lane

Purpose:
- Prove the public helper exists and that validate-stage rejection closes the unsupported signature semantics before render.

Automation:
- `mix test test/rendro_builders_test.exs`
- `mix test test/rendro/rules/check_form_fields_test.exs test/rendro/pipeline/validate_test.exs`

Important boundary:
- `lib/rendro/pdf/writer.ex` remains out of scope for this phase.
- The validator must reject unsupported signature semantics explicitly instead of silently ignoring them.
- Geometry rejection must cover visible-placeholder-only posture, including zero-width, zero-height, or hidden intent.

Expected result:
- One explicit public helper exists.
- Shared form-model reuse remains intact.
- Typed validate errors cover the blocked signature shapes required by the phase context.

### 2. Support-contract lane

Purpose:
- Prove docs and machine-readable claims keep unsigned authoring distinct from unsupported rendered/digital-signature behavior.

Automation:
- `mix test test/docs_contract/forms_claims_test.exs`
- `mix run scripts/verify_docs.exs`

Important boundary:
- `forms.widgets.signature` must not be promoted in a way that reads as writer/viewer support before Phase 56 serialization exists.
- `digital_signatures` and compliance-oriented claims remain unsupported.
- Docs can mention the new helper, but must not imply finished `/Sig` serialization, viewer proof, or signing validity.

Expected result:
- The authored helper is documented truthfully.
- The support matrix and prose remain conservative about rendered signature support.
- Docs-contract tests fail on drift in either direction.

## Manual-Only Verifications

All Phase 55 behaviors have automated verification. No manual-only lane is required.

## Threat References

| Threat ID | Category | Risk | Mitigation |
|-----------|----------|------|------------|
| T-55-01 | Spoofing / semantic confusion | Users infer broad signature support from a convenient helper. | Keep one explicit helper and conservative docs wording. |
| T-55-02 | Tampering / scope creep | Unsupported signature attrs slip past validation and become future ambiguous state. | Add typed validate-stage rejection for blocked signature attrs and hidden/zero-rect intent. |
| T-55-03 | Integrity | A second form-model path fragments the forms contract. | Reuse `%Rendro.FormField{}` and the existing validation pipeline. |
| T-55-04 | Semantic confusion | Public docs collapse unsigned placeholders into digital-signature claims. | Separate authored helper language from rendered/signing support language. |
| T-55-05 | Repudiation | Support matrix and prose drift apart. | Lock both through `forms_claims_test.exs` and `scripts/verify_docs.exs`. |
| T-55-06 | Scope drift | Phase 55 wording starts claiming viewer/compliance outcomes. | Refute viewer, tamper-evidence, and compliance claims until later phases. |

## Validation Sign-Off

- [x] All planned tasks have automated verification coverage
- [x] Sampling continuity is preserved across Plans 01 and 02
- [x] Authoring/validation and support-contract lanes are explicitly separated
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 55 validation contract prepared on 2026-05-06 during plan-phase revision and finalized on 2026-05-07 after live proof-lane execution plus the Phase 58 verification backfill.
