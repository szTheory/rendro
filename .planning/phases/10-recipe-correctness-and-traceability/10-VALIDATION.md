---
phase: 10
slug: recipe-correctness-and-traceability
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
updated: 2026-04-28
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for recipe correctness, traceability sync, and truthful non-ownership of release proof.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5; this phase closes through targeted adapter regressions plus artifact consistency checks. |
| **Config file** | `mix.exs` plus `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/accrue_test.exs` |
| **Full suite command** | `mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/accrue_test.exs` plus `rg -n "requirements_completed:|ADPT-05|QUAL-04 remains" .planning/phases/10-recipe-correctness-and-traceability/10-VERIFICATION.md .planning/phases/10-recipe-correctness-and-traceability/10-01-SUMMARY.md .planning/phases/10-recipe-correctness-and-traceability/10-02-SUMMARY.md` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/accrue_test.exs`
- **After every plan wave:** Run the targeted adapter suite plus artifact-consistency grep checks
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | ADPT-05 | T-10-01 | Mailglass custom `.Message` wrappers with their own `update_swoosh/2` return an updated wrapper instead of raising. | unit | `mix test test/rendro/adapters/mailglass_test.exs` | ✅ | ✅ green |
| 10-01-02 | 01 | 1 | ADPT-05 | T-10-02 | Accrue rejects invalid nested `line_items` with `{:error, {:invalid_invoice, _}}` and never partially renders. | unit | `mix test test/rendro/adapters/accrue_test.exs` | ✅ | ✅ green |
| 10-01-03 | 01 | 1 | ADPT-05 | T-10-03 | Accrue renders `issued_at` as `YYYY-MM-DD` and never leaks `~D[...]` or other debug syntax into invoice text. | unit | `mix test test/rendro/adapters/accrue_test.exs` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | QUAL-04 | T-10-04 | Phase 10 traceability artifacts record `ADPT-05` closure and keep `QUAL-04` truthful as a later release-proof dependency rather than a false completion. | doc consistency | `rg -n "requirements_completed:|QUAL-04 remains|ADPT-05" .planning/phases/10-recipe-correctness-and-traceability/10-VERIFICATION.md .planning/phases/10-recipe-correctness-and-traceability/10-01-SUMMARY.md .planning/phases/10-recipe-correctness-and-traceability/10-02-SUMMARY.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/rendro/adapters/mailglass_test.exs` — success-path regression for a non-canonical wrapper with `:swoosh` and its own `update_swoosh/2`
- [x] `test/rendro/adapters/accrue_test.exs` — negative-path regression for invalid nested `line_items`
- [x] `test/rendro/adapters/accrue_test.exs` — exact `Issued:` rendering assertions for accepted temporal inputs
- [x] Phase 10 artifact summaries use `requirements_completed` and no longer overstate `QUAL-04`

---

## Manual-Only Verifications

None. Phase 10's owned behavior is fully covered by adapter tests and artifact-consistency checks. The release-preflight happy-path proof that `QUAL-04` depends on was later automated in Phase 13 and is cited as supporting evidence rather than treated as an open manual gate here.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-28
