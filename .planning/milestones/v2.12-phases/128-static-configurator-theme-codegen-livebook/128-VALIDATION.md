---
phase: 128
slug: static-configurator-theme-codegen-livebook
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 128-01-01 | 01 | 1 | CONFIG-03, CONFIG-05 | T-128-02 | One closed formatter owns the tracer snippet and deterministic committed index without evaluating browser input. | unit + integration | `mix test test/rendro/theme/snippet_test.exs --max-failures 1 && mix rendro.configurator.gen --check` | ✅ | ✅ green |
| 128-01-02 | 01 | 1 | CONFIG-03, CONFIG-05 | T-128-02 | The exact 504-record vocabulary is ordered, parseable, executable only as trusted source, and free of dynamic atom creation. | exhaustive unit | `mix test test/rendro/theme/snippet_test.exs --max-failures 1` | ✅ | ✅ green |
| 128-02-01 | 02 | 1 | CONFIG-05 | T-128-03, T-128-04 | CLI derivation rejects unsafe aliases/paths and compiles the formatter-owned wrapper. | unit + Mix task | `mix test test/rendro/theme/snippet_test.exs test/mix/tasks/rendro_gen_theme_test.exs --max-failures 1` | ✅ | ✅ green |
| 128-02-02 | 02 | 1 | CONFIG-05 | T-128-03, T-128-04 | Create/conflict/force/check behavior is byte-stable and read-only in check mode. | integration | `mix test test/mix/tasks/rendro_gen_theme_test.exs --max-failures 1` | ✅ | ✅ green |
| 128-03-01 | 03 | 2 | CONFIG-01, CONFIG-02, CONFIG-03, CONFIG-04 | T-128-01, T-128-02 | The packaged configurator is static, semantic, safely loaded, and free of required server/build dependencies. | docs contract | `mix test test/docs_contract/configurator_static_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 128-03-02 | 03 | 2 | CONFIG-01, CONFIG-02, CONFIG-03, CONFIG-04 | T-128-01, T-128-02 | Atomic URL state and exact/representative/unavailable preview resolution preserve source identity and safe DOM behavior. | resolver + source contract | `mix test test/docs_contract/configurator_static_contract_test.exs test/docs_contract/configurator_resolver_contract_test.exs test/rendro/theme/snippet_test.exs --max-failures 1` | ✅ | ✅ green |
| 128-04-01 | 04 | 2 | CONFIG-06 | T-128-05 | The focused Livebook render uses the canonical formatter and explicit font registration without a server. | notebook integration | `mix test test/mix/tasks/rendro_livebook_check_test.exs test/rendro/theme/snippet_test.exs --max-failures 1 && mix rendro.livebook.check` | ✅ | ✅ green |
| 128-04-02 | 04 | 2 | CONFIG-06 | T-128-05 | Pedagogy and claims remain limited to the exact no-server preset path. | notebook contract | `mix test test/mix/tasks/rendro_livebook_check_test.exs test/rendro/theme/snippet_test.exs --max-failures 1 && RENDRO_LIVEBOOK_LOCAL=1 mix rendro.livebook.check` | ✅ | ✅ green |
| 128-05-01 | 05 | 3 | CONFIG-01..06 | T-128-06, T-128-07 | All three consumers integrate with the canonical formatter and pass the direct static-graph and terminal deterministic gates. | integration + CI | `mix test test/docs_contract/configurator_phase_gate_test.exs --max-failures 1 && mix rendro.configurator.gen --check && mix rendro.livebook.check && mix ci.fast` | ✅ | ✅ green |
| 128-05-02 | 05 | 3 | CONFIG-01..06 | T-128-07 | Pinned Chromium covers bounded behavior/accessibility/pixels and a real fresh consumer covers generator subprocess semantics. | browser + subprocess E2E | `npm run test:container --prefix scripts/configurator_e2e && mix test test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs` | ✅ | ✅ green |
| 128-06-01 | 06 | 4 | CONFIG-01, CONFIG-02, CONFIG-03, CONFIG-05 | T-128-07 | Clipboard/preview recovery, chrome/document independence, TTY-safe conflict behavior, and deterministic CI close the verification gaps. | browser + subprocess + CI | `npm run test:container --prefix scripts/configurator_e2e && mix test test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs --max-failures 1 && mix ci.fast` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/rendro/theme/snippet_test.exs` — 504 formatter/index parse-evaluate checks and representative recipe/font bridge proof
- [x] `test/mix/tasks/rendro_gen_theme_test.exs` — strict flags, safe derivation, compiled output, create/conflict/force/check behavior
- [x] `test/docs_contract/configurator_static_contract_test.exs` — static packaging, semantic/accessibility contract, safe DOM APIs, and no build/server dependency
- [x] `test/docs_contract/configurator_resolver_contract_test.exs` — exact/representative/none and atomic fallback cases against synthetic manifests
- [x] `test/mix/tasks/rendro_livebook_check_test.exs` — exact shared snippet, themed render evidence, and explicit no-server/no-interactive exclusions
- [x] `test/docs_contract/configurator_phase_gate_test.exs` — Wave-3 direct-file integration smoke proving every shipped local asset/reference, both committed JSON inputs, canonical snippet provenance, and no required server/build/runtime dependency

---

## Automated Browser and Fresh-Consumer Evidence

Plan 05 replaces the human checkpoint with a zero-human gate: pinned Playwright Chromium exercises the required states with scoped accessibility-tree snapshots, enumerated axe checks, and pinned-container screenshots; a serial ExUnit subprocess creates a real local-path consumer and audits generator writes. These gates do not claim Firefox/Safari behavior, VoiceOver/NVDA comprehension, WCAG certification, or aesthetic quality.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or completed Wave 0 dependencies.
- [x] Sampling continuity: no three consecutive tasks lack automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency remains under 60 seconds for focused checks; terminal CI is tracked separately.
- [x] `nyquist_compliant: true` is set after validation evidence exists.

**Approval:** validated — 2026-08-19

## Validation Audit 2026-08-19

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Evidence: all eleven executed task bindings have automated coverage; the pinned Chromium suite passed 13/13, the fresh-consumer test passed in non-TTY and pseudo-TTY modes, `mix ci.fast` passed, and `128-VERIFICATION.md` records 11/11 must-haves verified.
