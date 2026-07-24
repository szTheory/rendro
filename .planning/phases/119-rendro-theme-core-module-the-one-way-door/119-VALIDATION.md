---
phase: 119
slug: rendro-theme-core-module-the-one-way-door
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-24
---

# Phase 119 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `119-RESEARCH.md` §Validation Architecture. All phase tests are **pure unit tests** (no rendering, no I/O); the existing golden suite is re-run **unchanged** to prove zero regression.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (stdlib) + `stream_data ~> 1.3` for properties (`mix.exs:63`) |
| **Config file** | none custom — standard `mix test` |
| **Quick run command** | `mix test test/rendro/theme_test.exs` |
| **Full suite command** | `mix test` |
| **Manifest reconcile check** | `mix test test/docs_contract/public_api_contract_test.exs test/rendro/public_api/manifest_test.exs` |
| **Regression proof** | `mix test test/rendro/recipes/` green with NO `MIX_GOLDEN_BLESS` + `git status priv/goldens` clean |
| **Estimated runtime** | ~30 seconds (quick), ~2–3 min (full) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/theme_test.exs` (+ the new CONTRACT-03 guard)
- **After every plan wave:** Run `mix test test/rendro/recipes/ test/docs_contract/public_api_contract_test.exs test/rendro/public_api/manifest_test.exs`
- **Before `/gsd-verify-work`:** Full `mix test` green + `git status priv/goldens` clean
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Requirement / Criterion | Behavior | Test Type | Automated Command / Assertion | File Exists |
|-------------------------|----------|-----------|-------------------------------|-------------|
| THEME-01 | Full field set on `%Theme{}` (9 color roles + typography/spacing/rules/radius/density/mode) | unit (example) | `mix test test/rendro/theme_test.exs` — assert `Map.keys(t.colors)` == 9 roles; `t.typography.scale` has 6 steps; all groups present | ❌ W0 |
| THEME-01 | Bare `%Theme{}` == light default (no half-nil) | unit (example) | `assert %Rendro.Theme{} == Rendro.Theme.default()` | ❌ W0 |
| THEME-02 | `resolve/1` idempotent | **property** | `check all t <- theme_or_partial(), do: assert Theme.resolve(Theme.resolve(t)) == Theme.resolve(t)` | ❌ W0 |
| THEME-02 | deep-merge of partial input never `KeyError`s | **property** | `check all part <- partial_map(), do: assert match?(%Theme{}, Theme.resolve(part))` | ❌ W0 |
| THEME-02 | every color role integer `{r,g,b}` | unit (example/property) | for each role: `assert Rendro.Color.validate(get(t, role)) == :ok` | ❌ W0 |
| THEME-02 | invalid token raises instructive error | unit (example) | `assert_raise ArgumentError, ~r/hex/, fn -> Theme.resolve(colors: %{ink: "#000"}) end` | ❌ W0 |
| COLOR-01 | 9 roles are the only color surface | unit (example) | assert exact key set of `t.colors` == `[:accent,:background,:ink,:muted,:negative,:on_accent,:positive,:rule,:surface]` | ❌ W0 |
| COLOR-02 | `from_brand/2` from single `accent:` seed, `on_accent` derived | unit (example) | `t = Theme.from_brand(accent: {44,107,237}); assert t.colors.on_accent in [t.colors.background, t.colors.ink]` | ❌ W0 |
| COLOR-02 | `on_accent` branch-selection determinism (integer out) | **property** | `check all rgb <- rgb_gen(), do: (r = Theme.from_brand(accent: rgb).colors.on_accent; assert is_integer(elem(r,0)))` | ❌ W0 |
| COLOR-02 | override respected, never recomputed | unit (example) | `assert Theme.from_brand(accent: {44,107,237}, on_accent: {1,2,3}).colors.on_accent == {1,2,3}` | ❌ W0 |
| COLOR-02 | emits tokens only, registers NO asset | unit (example) | `from_brand/2` returns `%Theme{}`, no `FontRegistry`/`AssetRegistry` side effect | ❌ W0 |
| THEME-03 | adapter tier + manifest reconcile | contract | `mix rendro.api.gen` then RG-1 `public_api_contract_test.exs:72` + RG-2 `manifest_test.exs:98` green; `PublicApi.tier_of(Rendro.Theme) == :adapter` | ✅ RG exist |
| THEME-03 | every public fn has `@spec` | contract | explicit `Code.Typespec` check for `default/0,dark/1,from_brand/2,resolve/1` in `theme_test.exs` | ❌ W0 |
| THEME-03 | helpers private/`@doc false` | contract | `refute on_accent_for/hex_to_rgb/deep_merge` in manifest `functions` for `Elixir.Rendro.Theme` (covered by RG byte-equality) | ✅ via RG |
| THEME-04 | web concepts absent by construction | unit (example) | recurse group maps, assert no `:shadow/:elevation/:z_index/:opacity/:gradient` keys | ❌ W0 |
| CONTRACT-01 | ALL hidden/byte assertions reconcile | contract | run RG-1 + RG-2 together, both green after gen+commit | ✅ exist |
| CONTRACT-03 | `theme.ex` names no industry/brand | **source-grep guard** | `source = File.read!("lib/rendro/theme.ex")`; refute each forbidden term + "preset"/"catalog"/"configurator" (mirror `integrations_claims_test.exs:37-42`) | ❌ W0 |
| Byte-repro | all default/dark color values integers | unit (property) | `for {_r,{r,g,b}} <- Theme.default().colors, do: assert is_integer(r) and is_integer(g) and is_integer(b)` | ❌ W0 |
| Byte-repro | type-scale values integers/single-decimals | unit (example) | `for {_s,v} <- Theme.default().typography.scale, do: assert v == Float.round(v,1)` | ❌ W0 |
| **Zero-recipe-change** | every v2.10 golden byte-identical | regression | `mix test test/rendro/recipes/` green, NO bless, `git status priv/goldens` clean (62 committed `.sha256` unchanged) | ✅ exist |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/theme_test.exs` — covers THEME-01/02/04, COLOR-01/02 (example + property); property generators `theme_or_partial()`, `partial_map()`, `rgb_gen()` (inline or extend `test/support/generators.ex`)
- [ ] `test/docs_contract/theme_industry_guard_test.exs` — CONTRACT-03 source-grep guard (sibling of `integrations_claims_test.exs` / `branding_contract_test.exs`)
- [ ] No framework install needed — ExUnit + `stream_data ~> 1.3` already present

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | All phase behaviors have automated verification. |

*The manifest red→green (THEME-03/CONTRACT-01) is automated via `mix rendro.api.gen` + the two RG tests; it is a pre-declared planned red→green, not a manual step.*

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (`theme_test.exs`, `theme_industry_guard_test.exs`)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
