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
- **Wave 3 / Plan 05 task feedback:** After Plans 02, 03, and 04 complete, run the direct static-file smoke contract, `mix rendro.configurator.gen --check`, and `mix rendro.livebook.check` within the approximately 60-second task-level target
- **Wave 3 / Plan 05 terminal gate:** After focused task feedback passes, run `mix ci.fast` as the separately timed approximately 180-second terminal gate. The graph-disconnected pinned Chromium browser job and the serial fresh-consumer subprocess test are required automated gates; neither is a product Node dependency.
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
| 128-05-01 | 05 | 3 | CONFIG-01..06 | T-128-06 / T-128-07 | All three consumers integrate with the canonical formatter; committed index drift, Livebook execution, and direct static-file topology provide focused feedback after Wave 2 | integration + static-file smoke | `mix test test/docs_contract/configurator_phase_gate_test.exs --max-failures 1 && mix rendro.configurator.gen --check && mix rendro.livebook.check` | ❌ W0 | ⬜ pending |
| 128-05-terminal | 05 | 3 | CONFIG-01..06 | T-128-06 | Complete deterministic CI passes after focused feedback and before manual acceptance | terminal integration gate | `mix ci.fast` (~180 seconds; excluded from task-level latency) | existing alias | ⬜ pending |
| 128-05-02 | 05 | 3 | CONFIG-01..06 | T-128-07 | Pinned Chromium proves bounded UI behavior, scoped accessibility tree, axe checks, and pinned-container visual baselines; a serial fresh Mix consumer proves the generator in a real subprocess | browser + subprocess E2E | `npm ci --prefix scripts/configurator_e2e && npm test --prefix scripts/configurator_e2e` and `mix test test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/theme/snippet_test.exs` — 504 formatter/index parse-evaluate checks and representative recipe/font bridge proof
- [ ] `test/mix/tasks/rendro_gen_theme_test.exs` — strict flags, safe derivation, compiled output, create/conflict/force/check behavior
- [ ] `test/docs_contract/configurator_static_contract_test.exs` — static packaging, semantic/accessibility contract, safe DOM APIs, and no build/server dependency
- [ ] `test/docs_contract/configurator_resolver_contract_test.exs` — exact/representative/none and atomic fallback cases against synthetic manifests
- [ ] Extend `test/mix/tasks/rendro_livebook_check_test.exs` — exact shared snippet, themed render evidence, and explicit no-server/no-interactive exclusions
- [ ] `test/docs_contract/configurator_phase_gate_test.exs` — Wave-3 direct-file integration smoke proving every shipped local asset/reference, both committed JSON inputs, canonical snippet provenance, and no required server/build/runtime dependency

---

## Automated Browser and Fresh-Consumer Evidence

Plan 05 replaces the human checkpoint with a zero-human gate: pinned Playwright Chromium exercises the required states with scoped accessibility-tree snapshots, enumerated axe checks, and pinned-container screenshots; a serial ExUnit subprocess creates a real local-path consumer and audits generator writes. These gates do not claim Firefox/Safari behavior, VoiceOver/NVDA comprehension, WCAG certification, or aesthetic quality.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
