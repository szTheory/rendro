---
phase: 124
slug: address-v2-11-tech-debt-stale-113-docs-contract-test-formatt
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-28
---

# Phase 124 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. This is a maintenance/tech-debt
> phase: the "feature" is that three previously-red (or false-red) `mix ci.fast` gates go green **without
> any change to rendered output**. Validation is therefore gate-parity + a byte-identity regression guard.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / Erlang 28.4.1); Dialyxir for static analysis |
| **Config file** | none — existing `mix.exs` + built PLT (`_build/dev/dialyxir_erlang-28.4.1_elixir-1.19.5_deps-dev.plt`) |
| **Quick run command** | `mix format --check-formatted && mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` |
| **Full suite command** | `mix ci.fast` (format → hex.build → compile → test → docs → credo → dialyzer) |
| **Estimated runtime** | ~10s tests + ~30–90s dialyzer (PLT already built) |

---

## Sampling Rate

- **After every task commit:** Run the target's own gate (`mix format --check-formatted`, or the stale-test file, or `mix dialyzer`).
- **After every plan wave:** Run the byte-identity golden suite + `mix ci.fast`.
- **Before `/gsd-verify-work`:** `mix ci.fast` green end-to-end AND golden suite byte-identical.
- **Max feedback latency:** ~90 seconds (dialyzer-bound).

---

## Per-Task Verification Map

Task IDs finalized by the planner; each in-scope target maps to a deterministic gate.

| Target | Plan | Requirement (acceptance) | Test Type | Automated Command | Expected | Status |
|--------|------|--------------------------|-----------|-------------------|----------|--------|
| Stale 113 test | TBD | D-01: suite green, no deleted-path reads | unit | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` | 0 failures (3 remaining tests pass; no compile warning) | ⬜ pending |
| Formatter drift | TBD | D-02: formatted, bounded, formatting-only | format | `mix format --check-formatted` | exit 0 | ⬜ pending |
| Dialyzer contract | TBD | D-03: contract cascade cleared, spec-only | static | `mix dialyzer` | 0 errors (was 133 across 10 files) | ⬜ pending |
| Byte-identity guard | (cross-cutting) | D-03/D-06: rendered bytes unchanged | golden | byte-identity / frozen-SHA golden suite (per RESEARCH §Validation Architecture) | unchanged pass/fail (byte-identical) | ⬜ pending |
| ci.fast parity | (cross-cutting) | D-06: chain green end-to-end | integration | `mix ci.fast` | passes steps 1–7 (1,4,7 were the only red gates) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*None. Existing ExUnit + Dialyxir infrastructure and the built PLT cover all phase acceptance criteria. No new test framework, fixtures, or stubs required — the gates already exist; this phase makes them pass.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Diff is formatting-only | D-02 | Automated check confirms "formatted" but not "no logic change" | `git diff --stat` bounded to ~7 files; spot-check `git diff` shows only whitespace/paren/wrap changes |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (N/A — none)
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] Byte-identity golden suite asserted unchanged (the milestone guard)
- [ ] `nyquist_compliant: true` set in frontmatter (by validate-phase)

**Approval:** pending
