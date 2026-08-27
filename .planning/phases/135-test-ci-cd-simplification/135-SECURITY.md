---
phase: 135
slug: test-ci-cd-simplification
status: verified
threats_open: 0
asvs_level: 2
block_on: high
created: 2026-08-27
verified: 2026-08-27
---

# Phase 135 — Security

> ASVS-2 verification of the plan-authored threat register after the final code-review repair loop.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Default-branch control → candidate | A SHA-pinned trusted control job is isolated from detached, credential-free candidate execution | Full candidate SHA and bounded candidate output |
| Candidate artifact → bundle validator | A fresh runner accepts only an allowlisted, size/count-bounded regular-file handoff | Catalog manifests, checksums, and PDFium pin |
| Remote artifacts → parity authority | Route-specific normalization feeds a sealed same-SHA record and exact 16-column inventory projection | Typed run, artifact, archive, renderer, action, and per-file hash facts |
| Manual evidence → ordinary CI | The evidence workflow remains graph-disconnected from merge/release authority | Advisory/proof evidence only; `ci-success` remains sole authority |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-135-01 | Spoofing | candidate/control identity | high | mitigate | Full-SHA validation, detached candidate `HEAD` equality, default-ref guard, SHA-pinned control checkout, and sealed same-SHA verification | closed |
| T-135-02 | Tampering | control plane vs candidate | high | mitigate | Separate jobs/runners, credential-free checkouts, environment-mediated inputs, and artifact-only handoff | closed |
| T-135-03 | Tampering / information disclosure | paths and payloads | high | mitigate | Regular-file allowlist, file/size/count bounds, closed roles, safe paths, recomputed hashes, exact cardinalities, and tagged malformed-path rejection | closed |
| T-135-04 | Information disclosure | tokens, secrets, caches | high | mitigate | `contents: read`, `persist-credentials: false`, and no secrets, caches, writes, id-token, or attestation path | closed |
| T-135-05 | Elevation of privilege | workflow graph | high | mitigate | Manual-only dispatch, no `workflow_run`, no ordinary-CI edge, and preserved sole `ci-success` authority | closed |
| T-135-06 | Supply-chain tampering | actions and PDFium | high | mitigate | Immutable action commit pins plus PDFium version and binary SHA-256 verification before execution | closed |
| T-135-07 | Repudiation / tampering | parity and artifact integrity | high | mitigate | Typed per-side provenance, ordered artifact arrays, sealed candidate binding, route-specific normalized records, and exact inventory projection | closed |
| T-135-08 | Elevation of authority | evidence claims | high | mitigate | Candidate evidence forbids reviewer approval; runbook excludes merge, release, publication, and visual authority | closed |
| T-135-09 | Denial of service | runner and remote availability | medium | accept | Jobs time out after 45 minutes; handoff is at most 5 files/20 MiB; retention is bounded; unavailability gates only evidence/cutover | closed |
| T-135-SC | Tampering | package installs | low | accept | Phase adds no npm, pip, cargo, or dependency installation; existing Mix dependencies and immutable pins remain authoritative | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-135-01 | T-135-09 | Remote runner/PDFium availability cannot be eliminated; bounded failure is truthful and cannot gain merge/release authority | Plan-authored project policy | 2026-08-27 |
| R-135-02 | T-135-SC | Existing dependency installation remains necessary; this phase introduces no new package authority and retains immutable pins | Plan-authored project policy | 2026-08-27 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-27 | 10 | 10 | 0 | gsd-security-auditor, ASVS-2 |

Focused verification: 44 Phase 135 tests passed after the malformed canonical-path regression was added. No unregistered summary threat flags were found.

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks are documented.
- [x] `threats_open: 0` is confirmed at the high blocking threshold.
- [x] `status: verified` is set.

**Approval:** verified 2026-08-27
