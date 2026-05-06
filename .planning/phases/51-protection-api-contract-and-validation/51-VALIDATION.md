---
phase: 51
slug: protection-api-contract-and-validation
status: ready
nyquist_compliant: true
wave_0_complete: false
source: planning + execution (Plans 01-02)
created: 2026-05-06
started: 2026-05-06
updated: 2026-05-06
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for the artifact-first protection API, the optional qpdf runtime seam, and password-safe audit/docs boundaries.

Phase 51 closes one narrow surface with three proof lanes:

1. The **public contract lane** proves `Rendro.Protect.password/2` is the canonical artifact boundary and rejects malformed authored state before adapter execution.
2. The **runtime seam lane** proves the first-party qpdf adapter stays optional, typed, and cleanup-safe on success and failure.
3. The **redaction and claims lane** proves password material stays out of artifact metadata, audit-facing maps, and public support wording.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/protect_test.exs test/rendro/adapters/qpdf_test.exs test/rendro/error_test.exs test/rendro/artifact_test.exs test/rendro/audit_test.exs test/docs_contract/protection_claims_test.exs` |
| **Full suite command** | `mix test test/rendro/protect_test.exs test/rendro/adapters/qpdf_test.exs test/rendro/error_test.exs test/rendro/artifact_test.exs test/rendro/audit_test.exs test/docs_contract/protection_claims_test.exs` |
| **Estimated runtime** | ~1-5 seconds |

## Sampling Rate

- After every protection API or metadata task: run the focused Phase 51 command set.
- After every qpdf adapter change: re-run `test/rendro/adapters/qpdf_test.exs` and `test/rendro/protect_test.exs` at minimum, then restore the full Phase 51 command set before completion.
- After any docs/support wording change on this surface: re-run `test/docs_contract/protection_claims_test.exs`.
- Before `$gsd-verify-work`: the full Phase 51 command set must be green.
- Max automated feedback latency: 5 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-01 | 01 | 1 | PROTECT-01, PROTECT-02, PROTECT-03 | T-51-01, T-51-02 | Public protection input is validated at the artifact boundary, only `:aes_256` is accepted, and malformed options never reach the adapter seam. | unit | `mix test test/rendro/protect_test.exs test/rendro/error_test.exs` | ✅ | ✅ green |
| 51-01-02 | 01 | 1 | PROTECT-01, PROTECT-03 | T-51-02, T-51-03 | qpdf remains an optional executable seam with typed missing-executable and failure behavior, safe redaction, and temp-dir cleanup on non-success paths. | unit | `mix test test/rendro/adapters/qpdf_test.exs test/rendro/protect_test.exs test/rendro/error_test.exs` | ✅ | ✅ green |
| 51-02-01 | 02 | 2 | PROTECT-01, PROTECT-03 | T-51-04 | Protected output remains a normal `%Rendro.Artifact{}` with minimal password-safe `metadata.protection` and truthful `deterministic: false`. | unit | `mix test test/rendro/protect_test.exs test/rendro/artifact_test.exs` | ✅ | ✅ green |
| 51-02-02 | 02 | 2 | PROTECT-03 | T-51-04, T-51-05, T-51-06 | Audit scrubbing removes password keys recursively and docs/support claims stay narrow, truthful, and free of password-persistence guidance. | unit + docs-contract | `mix test test/rendro/audit_test.exs test/docs_contract/protection_claims_test.exs test/rendro/protect_test.exs test/rendro/artifact_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

## Requirement Coverage Summary

| Requirement | Coverage | Evidence |
|-------------|----------|----------|
| PROTECT-01 | COVERED | `test/rendro/protect_test.exs`, `test/rendro/adapters/qpdf_test.exs`, `test/rendro/artifact_test.exs` |
| PROTECT-02 | COVERED | `test/rendro/protect_test.exs`, `test/rendro/error_test.exs` |
| PROTECT-03 | COVERED | `test/rendro/protect_test.exs`, `test/rendro/audit_test.exs`, `test/docs_contract/protection_claims_test.exs`, `test/rendro/error_test.exs` |

Focused verification run on 2026-05-06:
- `mix test test/rendro/protect_test.exs test/rendro/adapters/qpdf_test.exs test/rendro/error_test.exs test/rendro/artifact_test.exs test/rendro/audit_test.exs test/docs_contract/protection_claims_test.exs`
- Result: `37 tests, 0 failures`

## Wave 0 Requirements

Existing infrastructure covers all Phase 51 requirements.

## Manual-Only Verifications

All phase behaviors have automated verification.

## Validation Audit 2026-05-06

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity is preserved across both executed plans
- [x] No Wave 0 test scaffolding is required
- [x] No watch-mode flags
- [x] Feedback latency is below 5 seconds for the focused phase suite
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 51 reconstructed and audited on 2026-05-06 from executed plans, summaries, and green focused verification.
