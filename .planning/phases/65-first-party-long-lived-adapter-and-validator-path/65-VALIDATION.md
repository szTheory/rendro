---
phase: 65
slug: first-party-long-lived-adapter-and-validator-path
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 65 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/rendro/sign_test.exs test/rendro/error_test.exs test/rendro/adapters/py_hanko_test.exs test/rendro/adapters/pdfsig_test.exs` |
| **Full suite command** | `mix test test/rendro/sign_test.exs test/rendro/error_test.exs test/rendro/adapters/py_hanko_test.exs test/rendro/adapters/pdfsig_test.exs test/docs_contract/signing_claims_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smallest affected sign/error/adapter lane
- **After every plan wave:** Run the phase-scoped suite for the files touched in that wave
- **Before `$gsd-verify-work`:** Run `mix test test/rendro/sign_test.exs test/rendro/error_test.exs test/rendro/adapters/py_hanko_test.exs test/rendro/adapters/pdfsig_test.exs test/docs_contract/signing_claims_test.exs`
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 65-01-01 | 01 | 1 | ADAPT-07 | T-65-01 / T-65-02 | pyHanko augmentation stays explicit on `augment/2`, embeds one narrow timestamp-plus-revocation path, and avoids public LT/LTA refresh semantics | unit | `mix test test/rendro/adapters/py_hanko_test.exs test/rendro/sign_test.exs` | ✅ | pending |
| 65-01-02 | 01 | 1 | ADAPT-07 | T-65-01 / T-65-02 / T-65-03 | augmentation runtime failures, temp-file cleanup, and augment-stage wording/redaction remain injectable, secret-free, and typed | unit | `mix test test/rendro/adapters/py_hanko_test.exs test/rendro/sign_test.exs test/rendro/error_test.exs` | ✅ | pending |
| 65-02-01 | 02 | 2 | ADAPT-08 | T-65-04 | the pyHanko-backed validator helper returns machine-readable timestamp/revocation/compliance-evidence facts while pdfsig remains integrity/trust-only | unit | `mix test test/rendro/adapters/py_hanko_test.exs test/rendro/adapters/pdfsig_test.exs test/rendro/error_test.exs` | ✅ | pending |
| 65-02-02 | 02 | 2 | ADAPT-08 | T-65-05 / T-65-06 | the public `%{adapter, signatures}` envelope stays compact while exposing explicit posture facts and keeping docs/support wording frozen | unit + docs-contract | `mix test test/rendro/sign_test.exs test/rendro/adapters/py_hanko_test.exs test/rendro/adapters/pdfsig_test.exs test/rendro/error_test.exs test/docs_contract/signing_claims_test.exs` | ✅ | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

Existing infrastructure covers the phase:

- ExUnit and the current sign/error/adapter lanes already exist for the public `augment/2`, `validate/2`, and adapter seams.
- `test/rendro/sign_test.exs` and `test/rendro/error_test.exs` already provide the public contract and wording/redaction lanes Phase 65 may extend.
- `test/rendro/adapters/py_hanko_test.exs` and `test/rendro/adapters/pdfsig_test.exs` already provide the adapter-local runner/parser lanes that execution will expand.
- The current host does not have `pyhanko`, so live proof is intentionally excluded from Phase 65 validation and remains explicit future work for Phase 66.

---

## Manual-Only Verifications

None. Phase 65 execution should remain covered by automated unit and docs-contract checks; live toolchain proof is deferred to Phase 66 by plan and by current environment reality.

---

## Validation Sign-Off

- [x] All tasks have automated verify lanes or existing infrastructure
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all referenced lanes
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 65 validation finalized on 2026-05-07 for the planned sign/error/adapter unit lanes, with live proof explicitly deferred to Phase 66.
