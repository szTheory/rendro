---
phase: 83
slug: claim-accuracy-shaping-hygiene
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-10
---

# Phase 83 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test --only <tag-or-path>` (targeted file runs, e.g. `mix test test/rendro/text/`) |
| **Full suite command** | `mix test` (deterministic suite; `mix ci` for the merge gate) |
| **Estimated runtime** | ~60–120 seconds full suite |

---

## Sampling Rate

- **After every task commit:** Run targeted test files for the modules touched (`mix test test/rendro/text/ test/rendro/pipeline/`)
- **After every plan wave:** Run `mix test` (full deterministic suite)
- **Before `/gsd:verify-work`:** Full suite must be green, plus `mix ci` (format, compile, tests, docs, package build, dialyzer)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

> Filled in by the planner per task. Key validation surfaces for this phase:

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (planner fills) | — | — | HYG-01 | — | Optional dep never silently activates | unit + integration | `mix test` | ✅ | ⬜ pending |
| (planner fills) | — | — | HYG-02 | — | Complex script → instructive error, never silent output | unit | `mix test` | ✅ | ⬜ pending |
| (planner fills) | — | — | HYG-03 | — | Simple-path bytes unchanged (property test per-grapheme == per-run) | unit + golden | `mix test` | ✅ | ⬜ pending |
| (planner fills) | — | — | HYG-04 | — | Run itemization unchanged on fixtures (before/after diff) | unit + golden | `mix test` | ✅ | ⬜ pending |
| (planner fills) | — | — | HYG-05 | — | Matrix rows terminal + docs-contract guard | docs-contract | `mix test test/docs_contract/` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] None expected — ExUnit infrastructure, golden-test harness, docs-contract lanes, and support-matrix schema validator all exist and cover the phase requirements.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fresh project without `harfbuzz_ex` compiles with zero NIF steps | HYG-01 | Requires an out-of-repo consumer project | `mix new /tmp/rendro_consumer && cd /tmp/rendro_consumer`, add `{:rendro, path: ...}` only, `mix deps.get && mix compile` — assert no Rust/NIF compilation occurs, then render a Latin PDF |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
