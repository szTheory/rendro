---
phase: 05
slug: early-ecosystem-recipes
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-26
reconstructed_from: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md, 05-04-SUMMARY.md, 05-VERIFICATION.md]
---

# Phase 05 — Validation Strategy

> Per-phase validation contract reconstructed retroactively from execution artifacts. Phase shipped with full automated coverage on every implementation task; only documentation prose is verified manually via shell-based heading/keyword checks.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19) |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/adapters/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~0.1s (adapters) / ~2.9s (full suite, 3 properties + 191 tests) |
| **Optional-adapter harness** | `Rendro.Test.Mocks.AdapterReloader.recompile/0` (re-evaluates `Code.ensure_loaded?/1` guards after stubs load) |
| **Cross-process telemetry capture** | ETS table `:rendro_threadline_calls` keyed by test pid via `:"$callers"` chain |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/adapters/`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~3s (full suite); ~0.1s (adapter subset)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-T1 | 01 | 1 | ADPT-05 | T-05-01 | Threadline adapter forwards only allowlisted telemetry keys (no document bodies, blocks, or rendered binaries) | unit | `mix test test/rendro/adapters/threadline_test.exs` | ✅ | ✅ green |
| 05-01-T2 | 01 | 1 | ADPT-05 | T-05-02 | Mailglass `attach_pdf/3` runs through `Rendro.render/1`, inheriting policy bounds (max_pages, max_bytes) — no DoS bypass | unit | `mix test test/rendro/adapters/mailglass_test.exs` | ✅ | ✅ green |
| 05-01-T3 | 01 | 1 | ADPT-05 | — | Test stubs (Threadline / Mailglass / Swoosh) keep optional libs out of `mix.exs` deps | unit | `mix test test/rendro/adapters/` | ✅ | ✅ green |
| 05-02-T1 | 02 | 1 | ADPT-05 | — | Accrue/Invoice/LineItem stub modules in `test/support/mocks.ex`; `AdapterReloader` extended | unit (gating proof) | `mix compile --warnings-as-errors && mix test test/rendro/adapters/accrue_test.exs` | ✅ | ✅ green |
| 05-02-T2 | 02 | 1 | ADPT-05 | T-05-02-01 | `recipe/1` pattern-matches `%Accrue.Invoice{}`; non-Invoice inputs return `{:error, {:invalid_invoice, _}}` (no Document fabrication) | unit | `mix test test/rendro/adapters/accrue_test.exs` | ✅ | ✅ green |
| 05-03-T1 | 03 | 1 | ADPT-05 | T-05-03-01 / T-05-03-02 | RED tests for CR-01 / CR-02 / WR-03 — assert error tuples and that `attach_pdf/3` does NOT raise | unit | `mix test test/rendro/adapters/mailglass_test.exs` | ✅ | ✅ green |
| 05-03-T2 | 03 | 1 | ADPT-05 | T-05-03-01 / T-05-03-02 / T-05-03-03 | `extract_swoosh/1` returns `{:error, {:unrecognized_message_shape, _}}` (no silent empty-email fabrication); `attach_binary/3` returns `{:error, %Rendro.Error{reason: {:invalid_email_target, _}}}` (no crash); `mailglass_message?/1` narrowed | unit (negative path) | `mix test test/rendro/adapters/mailglass_test.exs` | ✅ | ✅ green |
| 05-04-T1 | 04 | 2 | ADPT-05 | T-05-04-01 / T-05-04-02 | `guides/integrations.md` enumerates new error tuples (`:invalid_email_target`, `:unrecognized_message_shape`, `:invalid_invoice`) and documents WR-01 timeout-audit gap with verbatim opening sentence | manual (doc grep) | `grep -c "{:invalid_email_target,\|{:unrecognized_message_shape,\|{:invalid_invoice," guides/integrations.md` | ✅ | ✅ green (verified) |
| 05-04-T2 | 04 | 2 | ADPT-05 | T-05-04-02 | `mix.exs :extras` includes guide; README points to it; project still compiles | unit + grep | `mix compile --warnings-as-errors && mix test && grep -c "guides/integrations.md" mix.exs README.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Test counts (post-execution):** 11 Threadline + 10 Mailglass (6 happy + 4 negative) + 5 Accrue = **23 adapter tests**. Full suite: **3 properties, 191 tests, 0 failures**.

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* All testing harness pre-existed (ExUnit, `test/test_helper.exs`, `test/support/mocks.ex`). Phase 5's own additions (Accrue stubs, AdapterReloader extension) were implemented as part of plan 05-02-T1 — not a Wave 0 dependency, since the Threadline/Mailglass test infrastructure landed in plan 05-01.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Integration guide prose accuracy (`guides/integrations.md`) | ADPT-05 | Documentation content cannot be unit-tested; verified via shell-based heading + keyword grep (see plan 05-04-T1 acceptance criteria — 18 grep assertions covering H1/H2/H3 structure, the verbatim WR-01 sentence, and each adapter's error-tuple atoms) | Run the grep assertions in `.planning/phases/05-early-ecosystem-recipes/05-04-PLAN.md` lines 202-222. CI gate via `mix docs` (smoke check that ExDoc renders extras without error). |
| Mailglass custom-wrapper dispatch via `put_swoosh/2` (REVIEW CR-01 follow-up) | ADPT-05 | `put_swoosh/2` hard-codes dispatch through `Mailglass.Message.update_swoosh/2`. A custom wrapper struct (ends in `.Message`, exports own `update_swoosh/2`, has `:swoosh` field) crashes with `FunctionClauseError`. Cannot reproduce in CI: the test fixture `Mailglass.Wrapper.Message` deliberately omits `:swoosh` so it bails earlier in `extract_swoosh/1`, never reaching `put_swoosh/2`. Requires a real `:mailglass` install. | See `05-HUMAN-UAT.md` Test 1 — instantiate `MyApp.Invoice.Message` matching the three conditions, call `Rendro.Adapters.Mailglass.attach_pdf(msg, doc, "invoice.pdf")`, expect `{:ok, %MyApp.Invoice.Message{}}`. Decision required: accept canonical recipe satisfies SC1, OR apply 5-line fix from REVIEW CR-01 dispatching through `message.__struct__`. |

---

## Audit Trail

This VALIDATION.md was reconstructed retroactively after phase execution and gap-closure (plans 05-02, 05-03, 05-04) had completed. No gaps were found at audit time — every implementation task already had an automated verification command, and execution evidence in `05-VERIFICATION.md` confirmed 7/7 must-haves verified plus 23 adapter tests green.

| Metric | Count |
|--------|-------|
| Tasks audited | 9 (across 4 plans) |
| Automated coverage | 8 (89%) |
| Manual-only | 1 (documentation prose) + 1 known-limitation human UAT |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Tests generated by validate-phase | 0 (none needed) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none required — existing infra sufficient)
- [x] No watch-mode flags
- [x] Feedback latency < 3s (full suite) / < 0.1s (adapter subset)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-26 (retroactive reconstruction)
