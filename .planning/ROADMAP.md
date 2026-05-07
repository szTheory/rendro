# Milestone v2.1: Cryptographic Signing & Signed-Artifact Proof

**Status:** planned
**Started:** 2026-05-07
**Phases:** 60-63
**Total Plans:** 8

## Overview

`v2.1` adds one proof-backed cryptographic-signing path to Rendro by extending the shipped unsigned/preparation seam into actual signing, keeping the core writer pure, and proving the resulting signed-artifact posture through optional validation tooling. The milestone is intentionally scoped to cryptographic signing, signed-artifact proof, and truthful support boundaries; long-lived signatures, viewer promotion, and compliance claims remain deferred.

## Phases

### Phase 60: Public Cryptographic-Signing Contract

**Goal:** Lock the public `Rendro.Sign.sign/2` contract, redaction rules, and signed-artifact metadata posture without widening the shipped unsigned/preparation boundary.
**Depends on:** Phase 59
**Plans:** 2 plans

Plans:

- [ ] 60-01: Signing API option contract, field validation, and typed error taxonomy
- [ ] 60-02: Signed-artifact metadata, redaction coverage, and deterministic-vs-signed behavior proof

**Requirements:** `SIGN-04`, `SIGN-05`, `SIGN-06`
**Success criteria:**
1. Engineers can sign a rendered artifact through one explicit public API without changing `Rendro.render/2` semantics.
2. Invalid field selection and malformed adapter configuration fail with typed, redacted errors.
3. Signed artifacts clearly advertise non-deterministic signing state and do not leak secret material in shared metadata.

### Phase 61: First-Party Signing and Validation Adapters

**Goal:** Ship the first proof-backed optional signing and signed-artifact validation adapters while preserving the existing runtime-executable boundary discipline.
**Depends on:** Phase 60
**Plans:** 2 plans

Plans:

- [ ] 61-01: First-party pyHanko signing adapter and runtime boundary hardening
- [ ] 61-02: First-party pdfsig validation adapter and posture classification

**Requirements:** `ADAPT-04`, `ADAPT-05`
**Success criteria:**
1. Rendro ships a first-party pyHanko-backed signing adapter without introducing a hard Python dependency.
2. Rendro ships a first-party pdfsig-backed validation adapter that reports signed-artifact posture separately from certificate trust.
3. Adapter execution remains injectable, optional, and safe around temp files and tool failures.

### Phase 62: Live Proof and Support-Contract Closure

**Goal:** Prove the supported end-to-end toolchain and align docs/support surfaces with that exact proof-backed path.
**Depends on:** Phase 61
**Plans:** 2 plans

Plans:

- [ ] 62-01: Live signing proof lane with real pyHanko, pdfsig, and OpenSSL fixtures
- [ ] 62-02: Support-matrix, guide wording, and docs-contract updates for digital signatures

**Requirements:** `ADAPT-06`, `TRUST-04`, `TRUST-05`
**Success criteria:**
1. A live-tool lane can sign a representative artifact and validate the resulting signed posture through the supported validator path.
2. Public support docs distinguish signature integrity, certificate trust, viewer posture, and deferred compliance claims.
3. `priv/support_matrix.json` and docs-contract tests stay in lockstep with the proof-backed path.

### Phase 63: Verification and Operational Proof Closure

**Goal:** Close the milestone with explicit verification artifacts and operational guidance for the supported signing path.
**Depends on:** Phase 62
**Plans:** 2 plans

Plans:

- [ ] 63-01: Milestone verification artifact for cryptographic-signing and redaction boundaries
- [ ] 63-02: Operational guidance, closeout audit notes, and deferred-scope confirmation

**Requirements:** `TRUST-06`
**Success criteria:**
1. Verification artifacts cite the live proof lanes that back the supported signing path.
2. The closeout trail explicitly proves the credential-redaction boundary and keeps long-lived-signature/compliance claims out of scope.
3. Operators have one truthful supported-path recipe for signing and validating artifacts.

## Phase Ordering Rationale

- Phase 60 constrains public semantics first so adapter work cannot smuggle wider trust claims into the API.
- Phase 61 follows because signing and validation adapters are the first concrete proof-backed implementation boundary for the milestone.
- Phase 62 closes the support contract only after the real toolchain path exists, keeping public claims downstream of evidence.
- Phase 63 closes the milestone with explicit verification and operational guidance so the signed-artifact story is auditable rather than implied.

## Deferred

- In-core key custody, certificate-store management, or HSM orchestration
- Timestamp, revocation, and long-lived-signature evidence
- PAdES/LTV/TSA/OCSP/CRL and broad compliance narratives
- Broad viewer support claims without recorded evidence

## Coverage Summary

| Phase | Requirements Covered |
|-------|----------------------|
| 60 | `SIGN-04`, `SIGN-05`, `SIGN-06` |
| 61 | `ADAPT-04`, `ADAPT-05` |
| 62 | `ADAPT-06`, `TRUST-04`, `TRUST-05` |
| 63 | `TRUST-06` |

## Milestone Summary

**Key Decisions:**

- Keep cryptographic signing artifact-first over the shipped unsigned/preparation seam instead of reopening render-time semantics.
- Keep signing credentials, executable invocation, and tool-specific metadata adapter-local and optional at runtime.
- Treat signed output as intentionally non-deterministic while preserving deterministic claims for authored unsigned render output.
- Separate cryptographic signature integrity, certificate trust, viewer posture, and compliance narratives in every public surface.
- Defer long-lived-signature and compliance evidence to a later milestone even if the chosen tools expose those features.

**Primary Risks:**

- Public docs or metadata may overclaim what a "signed" artifact proves.
- Adapter failures may leak credentials or tool-specific details if redaction is incomplete.
- Tool capability may tempt the milestone into timestamp/revocation/PAdES scope creep.

**Mitigations:**

- Lock support-matrix/docs-contract updates to the exact live proof path.
- Test redaction boundaries at the API and adapter layers.
- Keep deferred scope explicit in requirements, roadmap, and closeout artifacts.

---
_For current status, see `.planning/STATE.md`, `.planning/PROJECT.md`, and milestone archives under `.planning/milestones/`._
