---
phase: 124
slug: address-v2-11-tech-debt-stale-113-docs-contract-test-formatt
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| Stale 113 test | 124-01 | D-01: suite green, no deleted-path reads | unit | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` | 0 failures (3 remaining tests pass; no compile warning) | ✅ green |
| Formatter drift | 124-01 | D-02: formatted, bounded, formatting-only | format | `mix format --check-formatted` | exit 0 | ✅ green |
| Dialyzer contract | 124-01 | D-03: contract cascade cleared, spec-only | static | `mix dialyzer` | 0 errors (was 133 across 10 files) | ✅ green |
| Byte-identity guard | 124-01 (cross-cutting) | D-03/D-06: rendered bytes unchanged | golden | `mix test test/rendro/recipes/theme_mode_background_golden_test.exs` (+ golden suite per RESEARCH §Validation Architecture) | unchanged pass/fail (byte-identical) | ✅ green |
| ci.fast parity | 124-01 (cross-cutting) | D-06: chain green end-to-end | integration | `mix ci.fast` | passes steps 1–7 (1,4,7 were the only red gates) | ✅ green |

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

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (N/A — none)
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] Byte-identity golden suite asserted unchanged (the milestone guard)
- [x] `nyquist_compliant: true` set in frontmatter (by validate-phase)

**Approval:** validated 2026-07-28 — all 5 targets automated + live-green; 1 belt-and-suspenders manual spot-check retained (redundant with byte-identity guard).

---

## Validation Audit 2026-07-28

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 5 in-scope targets (D-01, D-02, D-03, byte-identity, D-06) already carried deterministic automated commands. Each was re-run live during this audit and confirmed green:

| Target | Command | Live result |
|--------|---------|-------------|
| D-01 stale test | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` | 3 tests, 0 failures |
| D-02 formatter | `mix format --check-formatted` | exit 0 |
| D-03 dialyzer | `mix dialyzer` | Total errors: 0 |
| Byte-identity | `mix test test/rendro/recipes/theme_mode_background_golden_test.exs` | 7 tests, 0 failures |
| D-06 parity | `mix ci.fast` | exit 0, end-to-end green |

No test generation required. Phase is Nyquist-compliant. The lone Manual-Only item ("diff is formatting-only") is a human spot-check whose behavioral claim is already automatically corroborated by the byte-identity golden guard + full green suite; it does not constitute a coverage gap.
