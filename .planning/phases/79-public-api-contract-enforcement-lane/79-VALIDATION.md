---
phase: 79
slug: public-api-contract-enforcement-lane
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 79 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built into Elixir 1.14+) |
| **Config file** | `test/test_helper.exs` (standard, existing) |
| **Quick run command** | `mix test test/docs_contract/public_api_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5–15 seconds for the contract lane; full `mix ci` (format + compile --warnings-as-errors + test + docs + credo + dialyzer) longer |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/docs_contract/public_api_contract_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** `mix ci` full suite must be green (dialyzer included — validates backfilled `@spec`)
- **Max feedback latency:** ~15 seconds (quick lane)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 79-01-* | 01 | 1 | API-04 (equality) | — | Fresh in-memory manifest byte-equals `priv/public_api.json`; drift fails with two-list diff | contract | `mix test test/docs_contract/public_api_contract_test.exs` | ❌ W0 | ⬜ pending |
| 79-01-* | 01 | 1 | API-04 (schema) | — | On-disk manifest validates against `priv/schemas/public_api.schema.json` via JSV | contract | same | ❌ W0 | ⬜ pending |
| 79-01-* | 01 | 1 | API-04 (hidden) | — | Known internals report `:hidden`; re-exposure fails | contract | same | ❌ W0 | ⬜ pending |
| 79-01-* | 01 | 1 | API-04 (tier-tag) | — | Every manifested module carries exactly one tier tag (`:stable` xor `:adapter`) | contract | same | ❌ W0 | ⬜ pending |
| 79-02-* | 02 | 1 | API-04 (@spec) | — | Every stable-tier manifested function has `@spec`; `Rendro.Component` backfilled | contract | same | ❌ W0 (starts RED) | ⬜ pending |
| 79-03-* | 03 | 2 | API-04 (guardrails) | — | `scripts/verify_docs.exs` lane count bumped; `required_checks_contract_test.exs` assertion updated in lockstep | contract | `mix test test/guardrails/required_checks_contract_test.exs` | ✅ (needs update) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/docs_contract/public_api_contract_test.exs` — new lane covering all API-04 sub-assertions (equality, schema, hidden, tier-tag, @spec)
- Existing infrastructure (`test/rendro/public_api/manifest_test.exs`, `test/guardrails/required_checks_contract_test.exs`) covers preconditions; no new fixtures or `test_helper` changes needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Drift-diff failure message reads as errors-as-product (two named lists + `mix rendro.api.gen` hint) | API-04 | Message ergonomics are a human-readability judgment, not a boolean assertion | Temporarily add a stray public function, run the lane, confirm the failure names it under "in code but not manifested" and instructs `mix rendro.api.gen` |

*All structural behaviors have automated verification; only the failure-message UX is manually confirmed.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
