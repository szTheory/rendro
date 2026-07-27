---
phase: 121
slug: light-dark-background-fill-mechanism-all-7-recipes
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-27
---

# Phase 121 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Seeded from `121-RESEARCH.md` § Validation Architecture; the planner fills the Per-Task Verification Map.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19), byte-golden discipline via `Rendro.Test.Golden` (`assert_or_bless/2`, `assert_deterministic!/1`, missing-ref hard-flunk, `MIX_GOLDEN_BLESS` refresh) |
| **Config file** | `mix.exs` / `test/test_helper.exs` (existing — no Wave 0 framework install) |
| **Quick run command** | `mix test test/rendro/recipes/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~7s (recipe subset ~2s) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/recipes/` (recipe byte-identity + threading + the new dark-mode goldens).
- **After every plan wave:** Run `mix test` (full suite; catch cross-recipe/edge_matrix regressions).
- **Before `/gsd-verify-work`:** Full suite must be green with NO golden re-bless (a drifted frozen golden is a DEFECT, not a refresh — `golden.ex` hard-flunk).
- **Max feedback latency:** ~7 seconds.

---

## Per-Task Verification Map

*Seeded — the planner completes one row per task. Every behavior-adding task must carry an `<automated>` `mix test ...` command.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 121-XX-XX | XX | X | MODE-02 | — | Light/no-theme emits NO background rect; byte-identical to v2.10 (frozen sha256 goldens green, no re-bless) | golden | `mix test test/rendro/recipes/` | ✅ existing | ⬜ pending |
| 121-XX-XX | XX | X | MODE-01/02 | — | Dark (`theme: Theme.dark(...)`) emits the `:background` fill as first content op on page 1 AND on a forced-overflow page; fill == resolved `colors.background` tuple; existing ops byte-unchanged | golden/behavior | `mix test test/rendro/recipes/theme_mode_background_golden_test.exs` | ❌ W-plan | ⬜ pending |
| 121-XX-XX | XX | X | MODE-01 | — | Statement + Certificate render legibly in dark (all text reads a swappable role, no implicit `{0,0,0}`); light path byte-identical | golden/behavior | `mix test test/rendro/recipes/` | ❌ W-plan | ⬜ pending |
| 121-XX-XX | XX | X | MODE-03 | — | `theming` support-matrix row carries screen-oriented / non-print / no-PDF-UA / no-WCAG boundary keys = unsupported; `Theme.dark/1` @doc has the print boundary sentence | contract | `mix test test/docs_contract/` | ❌ W-plan | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing ExUnit + `Rendro.Test.Golden` infrastructure covers all phase requirements — no framework install needed.
- New test files to be authored by the plan (not framework setup): `test/rendro/recipes/theme_mode_background_golden_test.exs` (or folded into the determinism-golden suite) and `test/docs_contract/theming_claims_test.exs`.
- The 7 existing `*_byte_identity_test.exs` goldens ARE the MODE-02 light-path guard — they must stay green with no re-bless (byte-identity of the no-theme path).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | None — all Phase-121 behaviors are deterministically checkable (byte goldens + first-op assertions + contract lanes). The human-facing dark VISUAL is deferred to Phase 123. | — |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags (`mix test` is one-shot by default)
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
