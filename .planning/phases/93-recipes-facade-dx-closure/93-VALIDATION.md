---
phase: 93
slug: recipes-facade-dx-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 93 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in — no separate install) |
| **Config file** | `test/test_helper.exs` (standard) |
| **Quick run command** | `mix test test/rendro/recipes/ test/docs_contract/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/recipes/ test/docs_contract/`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green AND `git diff priv/public_api.json` must show additive-only (`+` lines, no `-` lines)
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| facade expansion | 01 | 1 | DX-01 | — | All 5 recipes reachable as `name/1`+`name/2`, opts thread verbatim | unit (reflection + regression) | `mix test test/rendro/recipes_facade_drift_test.exs` | ❌ W0 | ⬜ pending |
| opts-drop footgun fix | 01 | 1 | DX-01 | — | `:formatters`/`:labels`/`:border`/`:page_number_opts` reach recipe instead of being dropped | unit (regression) | `mix test test/rendro/recipes_facade_drift_test.exs` | ❌ W0 | ⬜ pending |
| drift test | 02 | 1 | DX-02 | — | reachability + no-extra-fns MapSet equality + struct byte-identity + orphan sweep | unit (reflection) | `mix test test/rendro/recipes_facade_drift_test.exs` | ❌ W0 | ⬜ pending |
| contract regen | 03 | 2 | DX-01, DX-02 | — | `priv/public_api.json` grows 2→10 Recipes fns, additive-only; byte-compare passes | integration | `mix test test/docs_contract/public_api_contract_test.exs` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**RED-before / GREEN-after expectation:** The drift test and opts-threading regression (Signals A + B) are authored RED — they MUST fail before the facade is expanded (functions undefined, MapSet mismatch). This is correct for this phase. The contract byte-compare (Signal C) is RED until `mix rendro.api.gen` is re-run with all 10 `@spec`'d functions present.

---

## Wave 0 Requirements

- [ ] `test/rendro/recipes_facade_drift_test.exs` — covers DX-01 + DX-02 (4 drift assertions: reachability, no-extra-functions MapSet equality, struct byte-identity, auto-discovery orphan sweep) plus the facade-level opts-threading regression. Reuses sample-data builders from `test/rendro/recipes/{invoice,receipt,certificate,statement,branded_invoice}_test.exs` and the opts-threading assertion style from `test/rendro/recipes/*_opts_threading_test.exs`.

*(Filename `test/rendro/recipes_test.exs` acceptable at executor discretion per CONTEXT.md D-10.)*

No framework install required — ExUnit is built in. The contract test (`public_api_contract_test.exs`) already exists and needs no Wave 0 stub.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `priv/public_api.json` diff is additive-only | DX-01 | Diff-shape check is a reviewer assertion, not an ExUnit test | After `mix rendro.api.gen`, run `git diff priv/public_api.json`; confirm only `+` lines in the `Elixir.Rendro.Recipes.functions` array (8 new entries), zero `-` lines, no other module touched |
| README footgun line corrected | DX-01 (SC#2) | Doc-prose accuracy is a human read | Confirm `README.md` (~L135) no longer claims `invoice` delegates to `…document/1` dropping opts; now notes opts thread through `…document/2` |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers the one MISSING reference (`recipes_facade_drift_test.exs`)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
