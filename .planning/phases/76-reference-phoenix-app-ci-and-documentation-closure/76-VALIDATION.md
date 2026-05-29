---
phase: 76
slug: reference-phoenix-app-ci-and-documentation-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
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
| 76-app-deps | (app) | 1 | REF-01 | — | N/A (high-trust Hex floor bumps only) | smoke | `cd examples/phoenix_example && mix compile --warnings-as-errors` | ✅ app exists | ⬜ pending |
| 76-app-errorjson | (app) | 1 | REF-01 | T-76 supply/config | clean render-error handling; boots without missing-module crash | smoke/boot | `cd examples/phoenix_example && mix phx.server` (manual boot) + optional JSON-404 test | ❌ W0 (new module) | ⬜ pending |
| 76-app-readme | (app) | 1 | REF-01 | — | N/A | manual/grep | optional README substring assertion (branding precedent) | ❌ W0 (new file) | ⬜ pending |
| 76-recipe-actions | (app) | 2 | REF-02 | V5 input (params ignored) | endpoints serve fixed demo data only | integration (ConnCase) | `cd examples/phoenix_example && mix test test/phoenix_example_web/controllers/pdf_controller_test.exs` | ✅ test file exists; +3 blocks | ⬜ pending |
| 76-recipe-structural | (app) | 2 | REF-02 | — | N/A | unit (structural) | same file (`%Rendro.Document{}` + page_template + regions; Certificate = single `:body` region) | ✅ +3 assertions | ⬜ pending |
| 76-ci-job | (ci) | 2 | REF-03 | T-76 CI token leak | job runs no secrets; never gates engine lanes | CI + contract | `mix test test/guardrails/required_checks_contract_test.exs` | ✅ refactor `[advisory]` destructure + lane count | ⬜ pending |
| 76-ci-guardrail | (ci) | 2 | REF-03 | — | engine lanes stay required (`@required_contexts` unchanged) | contract test | same file | ✅ | ⬜ pending |
| 76-guides | (docs) | 2 | CONTRACT-02 | T-76 overclaim | guides claim only matrix-`supported` capabilities | docs-contract claims | `mix test test/docs_contract/recipes_claims_test.exs test/docs_contract/page_primitive_claims_test.exs` | ❌ W0 (new tests + guides) | ⬜ pending |
| 76-guides-fences | (docs) | 2 | CONTRACT-02 | — | runnable ` ```elixir ` fences evaluate (`elixir-schematic` skipped) | docs-contract fence | `mix test test/docs_contract/recipes_contract_test.exs` | ❌ W0 (new test) | ⬜ pending |
| 76-docs-wiring | (docs) | 2 | CONTRACT-02 | — | ExDoc extras + group; no undefined-ref warnings | docs build | `mix docs` (inside `mix ci`) | ✅ mix.exs edited | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/phoenix_example/lib/phoenix_example_web/controllers/error_json.ex` — D-03 (new module; unblocks clean boot before recipe-action tests run).
- [ ] `examples/phoenix_example/README.md` — REF-01 setup + per-recipe docs (new file).
- [ ] `guides/page_primitive.md`, `guides/recipes.md` — CONTRACT-02 (new guides; the claims/fence tests assert against them).
- [ ] `test/docs_contract/page_primitive_claims_test.exs`, `test/docs_contract/recipes_claims_test.exs`, `test/docs_contract/recipes_contract_test.exs` — D-16 (new test files; RED until guides + wiring land).
- [ ] No framework install needed — ExUnit + ConnCase + `Rendro.Test.DocsContract` harness all present.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App boots and serves the chooser page + a PDF download in a browser | REF-01 | `mix phx.server` is a long-running process, not asserted in CI's `mix test` | `cd examples/phoenix_example && mix phx.server`; open `http://localhost:4000`, follow a recipe download link, confirm a valid PDF downloads |
| `example-phoenix` CI job appears as an independent, non-required check on a PR | REF-03 | Branch-protection required-set is GitHub-side config, not in-repo; the in-repo guardrail test only asserts the manifest | After merge, open a PR and confirm `example-phoenix` runs and is NOT in the required checks list |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (ErrorJSON module, README, 2 guides, 3 docs-contract tests)
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
