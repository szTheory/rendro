---
phase: 128
slug: static-configurator-theme-codegen-livebook
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-18
---

# Phase 128 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 / Mix) |
| **Config file** | `.formatter.exs`; ExUnit defaults from `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/theme/snippet_test.exs test/mix/tasks/rendro_gen_theme_test.exs test/mix/tasks/rendro_livebook_check_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | ~60 seconds quick; ~180 seconds full |

---

## Sampling Rate

- **After every task commit:** Run the narrowest mapped ExUnit command below plus `mix format --check-formatted`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Run `mix ci.fast`, `mix rendro.livebook.check`, and the static-file smoke check; all must be green
- **Max feedback latency:** 60 seconds for task-level checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Assigned by planner | TBD | TBD | CONFIG-01 | T-128-01 | Configurator is static, packaged, and requires no Node, server, or build step | docs contract | `mix test test/docs_contract/configurator_static_contract_test.exs` | ❌ W0 | ⬜ pending |
| Assigned by planner | TBD | TBD | CONFIG-02 | T-128-01 | Resolver accepts only closed dimensions and never crosses family, preset, or mode | unit + JS source contract | `mix test test/docs_contract/configurator_resolver_contract_test.exs` | ❌ W0 | ⬜ pending |
| Assigned by planner | TBD | TBD | CONFIG-03 | T-128-02 | Clipboard receives the exact formatter-owned visible source, with no URL-to-code interpolation | exhaustive unit + source contract | `mix test test/rendro/theme/snippet_test.exs` | ❌ W0 | ⬜ pending |
| Assigned by planner | TBD | TBD | CONFIG-04 | T-128-01 | Query input is validated atomically and DOM construction avoids unsafe HTML sinks | static JS contract | `mix test test/docs_contract/configurator_static_contract_test.exs` | ❌ W0 | ⬜ pending |
| Assigned by planner | TBD | TBD | CONFIG-05 | T-128-03 / T-128-04 | Generator rejects unsafe aliases/paths and `--check` never writes | unit + Mix task integration | `mix test test/rendro/theme/snippet_test.exs test/mix/tasks/rendro_gen_theme_test.exs` | ❌ W0 | ⬜ pending |
| Assigned by planner | TBD | TBD | CONFIG-06 | T-128-05 | Notebook remains no-server and evaluates only the marked, formatter-owned preset path | notebook source + integration | `mix test test/mix/tasks/rendro_livebook_check_test.exs && mix rendro.livebook.check` | ✅ extend existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/theme/snippet_test.exs` — 504 formatter/index parse-evaluate checks and representative recipe/font bridge proof
- [ ] `test/mix/tasks/rendro_gen_theme_test.exs` — strict flags, safe derivation, compiled output, create/conflict/force/check behavior
- [ ] `test/docs_contract/configurator_static_contract_test.exs` — static packaging, semantic/accessibility contract, safe DOM APIs, and no build/server dependency
- [ ] `test/docs_contract/configurator_resolver_contract_test.exs` — exact/representative/none and atomic fallback cases against synthetic manifests
- [ ] Extend `test/mix/tasks/rendro_livebook_check_test.exs` — exact shared snippet, themed render evidence, and explicit no-server/no-interactive exclusions

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Responsive visual hierarchy and natural-aspect preview remain legible in light, dark, and system modes | CONFIG-01, CONFIG-02 | Visual quality and browser rendering are not fully established by source-contract tests | Open the packaged configurator at narrow and wide viewports in current Chrome, Firefox, and Safari; inspect light/dark/system, exact/representative/none, loading/error, long-code overflow, and reduced-motion states against `128-UI-SPEC.md` |
| Keyboard, focus, native control, and screen-reader status flow is understandable | CONFIG-01, CONFIG-04 | Automated markup checks cannot establish the full assistive-technology experience | Complete family/preset/accent/mode selection and copy using keyboard only; then verify labels, live-region announcements, copy failure recovery, and focus order with VoiceOver or NVDA |
| Generated module feels conventional in a fresh consumer project | CONFIG-05 | Compilation proves correctness but not the end-to-end prompt/error ergonomics | In a disposable Mix project, run default, override, conflict, `--force`, and `--check` paths; confirm every failure explains what/where/why/next and no unexpected file is written |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
