---
phase: 121
slug: light-dark-background-fill-mechanism-all-7-recipes
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 121-01-1 | 01 | 1 | MODE-01/02 | — | `Rendro.Recipes.Background` (`emit?/1`/`region/2`/`section/3`) is the single source of truth; Statement wired end-to-end, all text draw-sites seamed to `colors.*`, `palette/1` nil-branch completed; light path byte-identical (no inline literals) | golden/behavior | `mix test test/rendro/recipes/statement_byte_identity_test.exs test/rendro/recipes/no_inline_color_literals_test.exs` | ✅ existing | ✅ green |
| 121-01-2 | 01 | 1 | MODE-02 | — | Dark Statement emits the `:background` fill as first content op on page 1 AND on every forced-overflow page (fill count == page count); light render emits NO fill; Statement dark golden blessed | golden/behavior | `mix test test/rendro/recipes/theme_mode_background_golden_test.exs` | ✅ existing | ✅ green |
| 121-02-1 | 02 | 2 | MODE-01 | — | Certificate wires shared region+section on its OWN resolved landscape `{pw,ph}`; both body text sites read `colors.ink`; non-black `:rule` `{34,34,34}` preserved; light byte-identical | golden/behavior | `mix test test/rendro/recipes/certificate_byte_identity_test.exs test/rendro/recipes/no_inline_color_literals_test.exs` | ✅ existing | ✅ green |
| 121-02-2 | 02 | 2 | MODE-02 | — | Certificate landscape dark case: fill is first content op on the single landscape page (fill count == 1); Certificate dark golden blessed | golden/behavior | `mix test test/rendro/recipes/theme_mode_background_golden_test.exs` | ✅ existing | ✅ green |
| 121-03-1 | 03 | 2 | MODE-02 | — | Payslip, Invoice, Receipt wire shared region+section (dual-gate on `Background.emit?(palette(opts))`) using own resolved dims; frozen sha256 goldens UNCHANGED (no re-bless) | golden | `mix test test/rendro/recipes/payslip_byte_identity_test.exs test/rendro/recipes/invoice_byte_identity_test.exs test/rendro/recipes/receipt_byte_identity_test.exs` | ✅ existing | ✅ green |
| 121-03-2 | 03 | 2 | MODE-02 | — | BrandedInvoice (full A4 `595.28x841.89`, not content-box width) and Ticket (A6 `geometry(opts)`) wire shared region+section; frozen sha256 goldens UNCHANGED | golden | `mix test test/rendro/recipes/branded_invoice_byte_identity_test.exs test/rendro/recipes/ticket_byte_identity_test.exs` | ✅ existing | ✅ green |
| 121-04-1 | 04 | 1 | MODE-03 | — | `theming.light`/`theming.dark` support-matrix rows with all 4 boundary keys (print/PDF-UA/WCAG/GUI-fidelity) = unsupported; `Theme.dark/1` @doc carries the screen-oriented non-print boundary sentence | contract | `mix test test/docs_contract/theming_claims_test.exs` | ✅ existing | ✅ green |
| 121-04-2 | 04 | 1 | MODE-03 | — | `theming_claims_test.exs` self-defends: overclaim tripwire (any print/PDF-UA/WCAG term paired with a `supported*` status) + non-vacuity teeth | contract | `mix test test/docs_contract/theming_claims_test.exs` | ✅ existing | ✅ green |

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

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags (`mix test` is one-shot by default)
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-07-28 — all 8 tasks carry automated verification, all green.

---

## Validation Audit 2026-07-28

Seed Per-Task Verification Map (placeholder `121-XX-XX` rows) reconciled against the 4 executed plans, 4 SUMMARYs, and the passing test suite. No new tests authored — every requirement was already covered by tests committed during execution. Re-ran `mix test test/rendro/recipes/ test/docs_contract/theming_claims_test.exs` → **3 doctests, 392 tests, 0 failures**.

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All three requirements (MODE-01, MODE-02, MODE-03) are COVERED by automated tests. Phase is Nyquist-compliant.
