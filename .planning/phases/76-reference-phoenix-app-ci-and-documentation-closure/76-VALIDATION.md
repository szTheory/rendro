---
phase: 76
slug: reference-phoenix-app-ci-and-documentation-closure
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
validated: 2026-05-29
---

# Phase 76 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 28) |
| **Config file** | root `mix.exs`; `mix ci` alias = format-check, hex.build, compile --warnings-as-errors, test, docs, credo --strict, dialyzer. Example app: `examples/phoenix_example/test/test_helper.exs` + `test/support/conn_case.ex` |
| **Quick run command** | library: `mix test test/<file>` · example app: `cd examples/phoenix_example && mix test` |
| **Full suite command** | `mix ci` (root) AND `cd examples/phoenix_example && mix test` AND `mix run scripts/verify_docs.exs` |
| **Estimated runtime** | ~60–180 seconds (library suite + example app + docs lanes) |

---

## Sampling Rate

- **After every task commit:** Run the touched file's quick test — `mix test test/<file>` (library) or `cd examples/phoenix_example && mix test` (example app).
- **After every plan wave:** Run full library suite `mix test` + example-app `mix test` + `mix run scripts/verify_docs.exs`.
- **Before `/gsd-verify-work`:** `mix ci` green (root) AND example-app `mix test` green AND `mix phx.server` boots clean.
- **Max feedback latency:** ~180 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 76-app-deps | (app) | 1 | REF-01 | — | N/A (high-trust Hex floor bumps only) | smoke | `cd examples/phoenix_example && mix compile --warnings-as-errors` | ✅ app exists | ✅ green |
| 76-app-errorjson | (app) | 1 | REF-01 | T-76 supply/config | clean render-error handling; boots without missing-module crash | smoke/boot | `cd examples/phoenix_example && mix test` (suite boots through endpoint+ErrorJSON; module load-bearing) | ✅ module exists | ✅ green |
| 76-app-readme | (app) | 1 | REF-01 | — | N/A | manual/grep | README substring grep (mix deps.get, mix phx.server, 5 recipe names, "not required") | ✅ file exists | ✅ green |
| 76-recipe-actions | (app) | 2 | REF-02 | V5 input (params ignored) | endpoints serve fixed demo data only | integration (ConnCase) | `cd examples/phoenix_example && mix test test/phoenix_example_web/controllers/pdf_controller_test.exs` | ✅ 12 tests | ✅ green |
| 76-recipe-structural | (app) | 2 | REF-02 | — | N/A | unit (structural) | same file (`%Rendro.Document{}` + page_template + regions; Certificate = single `:body` region) | ✅ structural asserts | ✅ green |
| 76-ci-job | (ci) | 2 | REF-03 | T-76 CI token leak | job runs no secrets; never gates engine lanes | CI + contract | `mix test test/guardrails/required_checks_contract_test.exs` | ✅ Enum.find advisory + lane count 10 | ✅ green |
| 76-ci-guardrail | (ci) | 2 | REF-03 | — | engine lanes stay required (`@required_contexts` unchanged) | contract test | same file | ✅ | ✅ green |
| 76-guides | (docs) | 2 | CONTRACT-02 | T-76 overclaim | guides claim only matrix-`supported` capabilities | docs-contract claims | `mix test test/docs_contract/recipes_claims_test.exs test/docs_contract/page_primitive_claims_test.exs` | ✅ tests + guides exist | ✅ green |
| 76-guides-fences | (docs) | 2 | CONTRACT-02 | — | runnable ` ```elixir ` fences evaluate (`elixir-schematic` skipped) | docs-contract fence | `mix test test/docs_contract/recipes_contract_test.exs` | ✅ test exists | ✅ green |
| 76-docs-wiring | (docs) | 2 | CONTRACT-02 | — | ExDoc extras + group; no undefined-ref warnings | docs build | `mix docs` (inside `mix ci`) | ✅ mix.exs wired | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> Audit note (2026-05-29): `mix docs` emits one warning about `guides/user_flows_and_jtbd.md` (an untracked phase-74 WIP file referenced from README.md) — **not** from the phase-76 guides, which build clean. Out of scope for Phase 76.

---

## Wave 0 Requirements

- [x] `examples/phoenix_example/lib/phoenix_example_web/controllers/error_json.ex` — D-03 (new module; unblocks clean boot before recipe-action tests run). **Landed (commit 02d58af).**
- [x] `examples/phoenix_example/README.md` — REF-01 setup + per-recipe docs (new file). **Landed (commit 550c58a).**
- [x] `guides/page_primitive.md`, `guides/recipes.md` — CONTRACT-02 (new guides; the claims/fence tests assert against them). **Landed (commit e73889e).**
- [x] `test/docs_contract/page_primitive_claims_test.exs`, `test/docs_contract/recipes_claims_test.exs`, `test/docs_contract/recipes_contract_test.exs` — D-16 (new test files). **Landed (commit 8b7a606); all green.**
- [x] No framework install needed — ExUnit + ConnCase + `Rendro.Test.DocsContract` harness all present.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App boots and serves the chooser page + a PDF download in a browser | REF-01 | `mix phx.server` is a long-running process, not asserted in CI's `mix test` | `cd examples/phoenix_example && mix phx.server`; open `http://localhost:4000`, follow a recipe download link, confirm a valid PDF downloads |
| `example-phoenix` CI job appears as an independent, non-required check on a PR | REF-03 | Branch-protection required-set is GitHub-side config, not in-repo; the in-repo guardrail test only asserts the manifest | After merge, open a PR and confirm `example-phoenix` runs and is NOT in the required checks list |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (ErrorJSON module, README, 2 guides, 3 docs-contract tests) — all landed
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-05-29

---

## Validation Audit 2026-05-29

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only (inherent) | 2 |

**State A audit** — VALIDATION.md was authored pre-execution; this audit re-classified every Per-Task entry against the executed codebase. All 10 task entries are COVERED and green; no MISSING/PARTIAL gaps required the gsd-nyquist-auditor. Evidence re-run live during the audit:

- Library docs-contract + guardrail contract: `mix test test/docs_contract/{page_primitive_claims,recipes_claims,recipes_contract}_test.exs test/guardrails/required_checks_contract_test.exs` → **49 tests, 0 failures**
- Example app: `cd examples/phoenix_example && mix test` → **12 tests, 0 failures**
- Docs lanes: `mix run scripts/verify_docs.exs` → **10/10 lanes green ("Docs contract VERIFIED!")**
- Docs build: `mix docs` builds; only warning is the unrelated untracked phase-74 `guides/user_flows_and_jtbd.md` README reference (out of scope).

The 2 Manual-Only items (browser PDF download via `mix phx.server`; `example-phoenix` shown as a non-required check on a live PR) are inherently un-assertable in `mix test` and remain correctly classified as manual. Phase 76 is **Nyquist-compliant**.
