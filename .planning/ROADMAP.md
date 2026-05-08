# Milestone v2.2: Long-Lived Signatures & Compliance Evidence

**Status:** Active
**Started:** 2026-05-07
**Phases:** 64-67
**Total Plans:** 8

## Overview

`v2.2` turns the shipped cryptographic-signing seam into a truthful long-lived-signature story. The milestone is intentionally scoped to artifact-first timestamp and revocation evidence, validator-backed long-lived posture classification, and exact support-boundary language. It does not widen Rendro into blanket compliance marketing, viewer portability promises, or in-core trust-management infrastructure.

## Phases

### Phase 64: Public Long-Lived Artifact Contract

**Goal:** Lock the public long-lived-signature API, redaction rules, and artifact metadata posture without widening the shipped render/sign seams.
**Depends on:** Phase 63
**Plans:** 2 plans

Plans:

- [x] 64-01: Long-lived artifact API option contract, typed error taxonomy, and unsigned/unsupported-artifact rejection
- [x] 64-02: Long-lived artifact metadata posture, redaction coverage, and deterministic-vs-augmented behavior proof

**Requirements:** `SIGN-07`, `SIGN-08`, `SIGN-09`
**Success criteria:**
1. Engineers can add timestamp and revocation evidence through one explicit artifact-stage API over a supported signed artifact.
2. Unsupported artifact state and malformed adapter inputs fail with typed, redacted errors.
3. Long-lived artifacts advertise their non-deterministic evidence posture without leaking secrets into shared metadata.

### Phase 65: First-Party Long-Lived Adapter and Validator Path

**Goal:** Ship the first proof-backed optional adapter path for long-lived evidence and the validator surface that classifies resulting posture precisely.
**Depends on:** Phase 64
**Plans:** 2 plans

Plans:

- [x] 65-01: First-party optional timestamp/revocation evidence adapter path and runtime-boundary hardening
- [x] 65-02: Validator-backed long-lived posture classification for integrity, timestamp, revocation, and narrow compliance evidence

**Requirements:** `ADAPT-07`, `ADAPT-08`
**Success criteria:**
1. Rendro ships one first-party optional path that can add timestamp and revocation evidence without introducing a hard runtime dependency in core.
2. Rendro can classify cryptographic integrity, timestamp presence, and revocation evidence as separate signals.
3. Adapter execution remains injectable, optional, and safe around temp files, tool failures, and secret-bearing inputs.

### Phase 66: Live Proof and Support-Contract Closure

**Goal:** Prove the supported long-lived path with live tooling and align docs/support surfaces with that exact evidence-backed claim set.
**Depends on:** Phase 65
**Plans:** 2 plans

Plans:

- [x] 66-01: Live long-lived-signature proof lane with representative fixtures and validator confirmation
- [x] 66-02: Support-matrix, guide wording, docs-contract, and operator recipe updates for long-lived evidence

**Requirements:** `ADAPT-09`, `TRUST-07`, `TRUST-08`
**Success criteria:**
1. A live-tool lane can produce a representative long-lived signed artifact and verify the supported posture through the named validator path.
2. Public support docs distinguish integrity, trust, viewer behavior, and narrow compliance evidence without collapsing them into one claim.
3. `priv/support_matrix.json` and docs-contract tests stay in lockstep with the exact proof-backed long-lived path.

### Phase 67: Verification and Milestone Closure

**Goal:** Close the milestone with explicit verification artifacts, deferred-scope confirmation, and a durable handoff into the next trust-and-adoption milestones.
**Depends on:** Phase 66
**Plans:** 2 plans

Plans:

- [ ] 67-01: Milestone verification artifact for long-lived evidence, redaction boundaries, and compliance-language discipline
- [ ] 67-02: Closeout audit notes, deferred-scope confirmation, and next-milestone handoff

**Requirements:** `TRUST-09`
**Success criteria:**
1. Verification artifacts cite the live proof lanes that back the supported long-lived path.
2. Closeout notes explicitly keep viewer promotion, multi-signature workflows, and broader compliance packaging out of scope.
3. The next milestone starts from an explicit strategic handoff instead of reopening the trust-and-adoption sequence.

## Phase Ordering Rationale

- Phase 64 constrains public semantics first so long-lived support cannot smuggle broader compliance claims into the API.
- Phase 65 follows because adapter and validator behavior define the first concrete proof-backed implementation boundary for the milestone.
- Phase 66 closes the support contract only after the real toolchain path exists, keeping public claims downstream of evidence.
- Phase 67 closes the milestone with explicit verification and strategic handoff so the long-lived story is auditable and the next milestone sequence stays intentional.

## Deferred

- In-core key custody, trust-store management, or HSM orchestration
- Viewer promotion for long-lived or signed-artifact surfaces without recorded proof
- Multi-signature workflows, counter-signatures, and signer-identity orchestration
- Broad compliance branding beyond the exact proof-backed path

## Coverage Summary

| Phase | Requirements Covered |
|-------|----------------------|
| 64 | `SIGN-07`, `SIGN-08`, `SIGN-09` |
| 65 | `ADAPT-07`, `ADAPT-08` |
| 66 | `ADAPT-09`, `TRUST-07`, `TRUST-08` |
| 67 | `TRUST-09` |

## Milestone Summary

**Key Decisions:**

- Keep long-lived evidence artifact-first over the shipped signing seam instead of reopening render-time semantics.
- Treat timestamp, revocation, certificate trust, viewer behavior, and compliance packaging as separate claims in every public surface.
- Require a validator-backed and live-tool-backed proof lane before promoting any long-lived-signature support language.
- Preserve the optional-adapter boundary and keep secret-bearing runtime inputs out of public metadata and error surfaces.

**Issues Targeted:**

- Rendro can sign today, but it does not yet provide the durable evidence story many real-world signed-document workflows require.
- Current support surfaces stop at bare cryptographic validity and intentionally defer timestamp, revocation, and compliance-evidence posture.
- The next public adoption push should not happen until the trust-sensitive story advances beyond “can sign once” into “can prove the supported evidence path truthfully.”

**Issues Deferred:**

- Broader viewer portability claims
- Multi-signature workflows and signer orchestration
- Generic compliance/regulatory packaging
- Large new core feature families unrelated to trust-and-adoption closure

---
_For current project status, see `.planning/STATE.md`, `.planning/PROJECT.md`, and milestone archives under `.planning/milestones/`._
