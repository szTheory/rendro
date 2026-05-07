---
phase: 57
slug: support-contract-and-proof-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 57 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/docs_contract/forms_claims_test.exs` |
| **Full suite command** | `mix run scripts/verify_docs.exs` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smallest affected docs-contract or structural lane
- **After every plan wave:** Run `mix run scripts/verify_docs.exs`
- **Before `$gsd-verify-work`:** Full docs-contract suite plus signature structural proof lanes must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | TRUST-01 | T-57-01 | Support matrix publishes separate unsigned-widget and signing-preparation claims without widening into digital-signature or compliance support | unit | `mix test test/docs_contract/forms_claims_test.exs test/docs_contract/signing_claims_test.exs` | ✅ | pending |
| 57-01-02 | 01 | 1 | TRUST-02 | T-57-02 | Guide wording keeps unsigned widgets, signing preparation, and unsupported trust narratives explicit and distinct | unit | `mix run scripts/verify_docs.exs` | ✅ | pending |
| 57-02-01 | 02 | 2 | TRUST-03 | T-57-03 | Verification artifacts and tests keep structural proof separate from viewer proof and cryptographic validity proof | integration | `mix test test/rendro/pdf/writer_test.exs test/rendro/sign_test.exs` | ✅ | pending |
| 57-02-02 | 02 | 2 | TRUST-03 | T-57-04 | Final milestone verification note uses canonical claim names and does not promote viewer support without recorded evidence | unit | `mix run scripts/verify_docs.exs && mix test test/rendro/pdf/writer_test.exs test/rendro/sign_test.exs` | ✅ | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

None - all phase behaviors should have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verify lanes or existing infrastructure
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all referenced lanes
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
