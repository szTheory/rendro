---
phase: 56
slug: writer-and-external-signing-preparation-seam
status: ready
nyquist_compliant: true
wave_0_complete: true
source: planning + execution + phase-59 backfill
created: 2026-05-06
updated: 2026-05-07
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for deterministic unsigned signature-widget serialization and the artifact-first external-signing preparation seam.

Phase 56 has two intentionally separate runtime proof lanes:

1. The **writer lane** proves unsigned signature widgets serialize deterministically and stay free of signing-value and signing-policy placeholders in ordinary render output.
2. The **preparation lane** proves `Rendro.Sign.prepare/2` mutates final artifact bytes only, returns a wrapped artifact with a narrow manifest, and keeps signer-specific trust work outside core.

Support-matrix, guide wording, docs-contract publication, and viewer-proof promotion remain deferred to Phase 57.
Phase 59 backfill cites those later support-contract lanes from `56-VERIFICATION.md`, but this validation record remains the authoritative Phase 56 runtime-proof contract.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/pdf/writer_test.exs test/rendro/sign_test.exs` |
| **Full suite command** | `mix test test/rendro/pdf/writer_test.exs test/rendro/deterministic_test.exs test/rendro/sign_test.exs test/rendro/error_test.exs` |
| **Estimated runtime** | ~20-30 seconds |

## Sampling Rate

- After Task `56-01-01`: run `mix test test/rendro/pdf/writer_test.exs`.
- After Task `56-01-02`: run `mix test test/rendro/deterministic_test.exs test/rendro/pdf/writer_test.exs`.
- After Task `56-02-01`: run `mix test test/rendro/sign_test.exs test/rendro/error_test.exs`.
- After Task `56-02-02`: run `mix test test/rendro/sign_test.exs`.
- Before phase handoff: run the full suite command once the worktree is clean.
- Max automated feedback latency: 30 seconds for per-task feedback commands.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 56-01-01 | 01 | 1 | SIGN-03 | T-56-01 | Visible unsigned signature widgets serialize through the existing AcroForm path with `/FT /Sig`, deterministic geometry, and no `/V`, `/Contents`, `/ByteRange`, `/Lock`, `/SV`, `/Reference`, `/Filter`, or `/SubFilter` in ordinary render output. | writer / regression | `mix test test/rendro/pdf/writer_test.exs` | ✅ | ✅ green |
| 56-01-02 | 01 | 1 | SIGN-03 | T-56-02 | Repeated deterministic renders of the same authored unsigned signature document produce identical bytes without any prepare-time mutation. | deterministic / regression | `mix test test/rendro/deterministic_test.exs test/rendro/pdf/writer_test.exs` | ✅ | ✅ green |
| 56-02-01 | 02 | 2 | PREP-01, PREP-02, PREP-03 | T-56-03, T-56-04, T-56-05 | `Rendro.Sign.prepare/2` accepts a `%Rendro.Artifact{}`, returns a wrapped artifact with a narrow nested signing-preparation manifest, and keeps cryptographic or signer-specific trust data out of core. | unit / API boundary | `mix test test/rendro/sign_test.exs test/rendro/error_test.exs` | ✅ | ✅ green |
| 56-02-02 | 02 | 2 | PREP-03 | T-56-05, T-56-06 | The optional adapter seam remains behavior-only and does not widen into a bundled signer path, root-level sugar, or in-core signing helper. | unit / contract | `mix test test/rendro/sign_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

## Wave 0 Requirements

- [x] `56-RESEARCH.md` names the writer and preparation validation architecture.
- [x] Every planned task has an explicit automated verification command.
- [x] The writer lane and preparation lane are separated.
- [x] No docs-contract, viewer-proof, or external signing tool dependency is required in this phase.
- [x] Support-contract publication is explicitly deferred to Phase 57.

## Automated Proof Lanes

### 1. Writer lane

Purpose:
- Prove deterministic unsigned `/Sig` widget serialization.

Automation:
- `mix test test/rendro/pdf/writer_test.exs`
- `mix test test/rendro/deterministic_test.exs test/rendro/pdf/writer_test.exs`

Important boundary:
- Base render must stay unsigned and must not emit `/V`, `/Contents`, `/ByteRange`, `/Lock`, `/SV`, `/Reference`, `/Filter`, or `/SubFilter`.
- The proof is ordinary-render-only and must not rely on any preparation API or placeholder reservation.

Expected result:
- One deterministic writer path produces visible unsigned signature widgets.
- The new writer branch cannot silently drift into signing-value or signer-policy output.

### 2. Preparation lane

Purpose:
- Prove the explicit post-render preparation seam over `%Rendro.Artifact{}`.

Automation:
- `mix test test/rendro/sign_test.exs`
- `mix test test/rendro/sign_test.exs test/rendro/error_test.exs`

Important boundary:
- `Rendro.Sign.prepare/2` must operate on final artifact bytes, not on authored document state or root render flags.
- The prepared-artifact manifest must stay generic and non-cryptographic: field identity, reserve sizing, and deterministic placeholder coordinates only.
- No root-level signing helper or first-party signer integration belongs in this phase.

Expected result:
- One explicit artifact-first prepare seam returns a normal `%Rendro.Artifact{}` with nested `metadata.signing_preparation`.
- Typed failures remain actionable without exposing secrets or pretending Rendro performed a signature.

## Manual-Only Verifications

All Phase 56 behaviors have automated verification. No manual-only lane is required.

## Threat References

| Threat ID | Category | Risk | Mitigation |
|-----------|----------|------|------------|
| T-56-01 | Semantic confusion | Unsigned render output could look like partially signed output. | Prove `/FT /Sig` presence and explicit absence of signing-value and signing-policy dictionaries in writer tests. |
| T-56-02 | Integrity | The new signature writer branch could become nondeterministic. | Add repeated-render regression proof for the signature document path. |
| T-56-03 | Tampering / scope creep | Invalid preparation input could mutate the wrong field or create ambiguous handoff state. | Require explicit field selection and typed prepare-boundary validation. |
| T-56-04 | Integrity | Preparation work could widen root render semantics or create a second artifact model. | Keep preparation artifact-first and wrapper-preserving. |
| T-56-05 | Information disclosure / semantic drift | The manifest could accumulate signer or cryptographic data that core does not own. | Limit the manifest to field identity, reserve sizing, and deterministic placeholder coordinates. |
| T-56-06 | Scope drift | Phase 56 could drift into a bundled signer path. | Keep the adapter seam behavior-only and defer support-contract publication to Phase 57. |

## Validation Sign-Off

- [x] All planned tasks have automated verification coverage
- [x] Sampling continuity is preserved across Plans 01 and 02
- [x] Writer and preparation proof lanes are explicitly separated
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 56 validation contract prepared on 2026-05-06 and finalized on 2026-05-07 after live proof-lane execution plus the Phase 59 verification backfill.
