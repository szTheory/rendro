---
phase: 87
slug: comparison-page-livebook
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-11
---

# Phase 87 - Validation Strategy

Per-phase validation contract for the benchmark comparison guide and Livebook
tutorial.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in, Elixir 1.19) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/docs_contract/comparison_claims_test.exs test/rendro/comparison_test.exs test/guardrails/required_checks_contract_test.exs` |
| Livebook command | `mix test test/mix/tasks/rendro_livebook_check_test.exs` |
| Docs-contract command | `mix run scripts/verify_docs.exs` |
| Full suite command | `mix test` |
| Estimated runtime | ~30-60 seconds for static required tests; advisory benchmark and Livebook lanes depend on external/runtime setup |

---

## Sampling Rate

- After comparison manifest or benchmark fixture changes: run `mix test test/rendro/comparison_test.exs`.
- After comparison guide or docs-contract changes: run `mix test test/docs_contract/comparison_claims_test.exs`.
- After CI or guardrail changes: run `mix test test/guardrails/required_checks_contract_test.exs`.
- After Livebook or notebook-runner changes: run `mix test test/mix/tasks/rendro_livebook_check_test.exs` and, when dependencies are available, `mix rendro.livebook.check`.
- After ExDoc/package changes: run `mix hex.build`, inspect package contents, and remove the generated tarball.
- Before phase verification: run `mix test`, `mix run scripts/verify_docs.exs`, `mix ci`, `mix rendro.comparison.check`, and `mix rendro.livebook.check` where local external requirements are present.
- Max default feedback latency: ~60 seconds for required/static checks. Advisory benchmark reruns are intentionally outside required latency.

---

## Requirement Coverage Summary

| Requirement | Planned Evidence |
|-------------|------------------|
| CMP-01 | `bench/comparison/**`, `bench/results/comparison.json`, raw SHA-256 artifacts, `Rendro.Comparison.static_contract_errors/0`, and benchmark harness tests prove pins, environment metadata, whole-process metric fields, image-size/dependency-count fields, and comparator coverage. |
| CMP-02 | `guides/comparison.md`, generated result/fit blocks, `[bench:CMP-*]` citations, `test/docs_contract/comparison_claims_test.exs`, and `scripts/verify_docs.exs` prove every public comparative claim is bounded to checked-in results. |
| CMP-03 | `guides/livebook/first_invoice.livemd`, ExDoc extras/package checks, README/guide links, `mix rendro.livebook.check`, advisory CI, and guardrail tests prove the notebook runs without becoming required CI. |

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Evidence Files | Status |
|---------|------|------|-------------|-----------|-------------------|----------------|--------|
| 87-01 | 01 | 1 | CMP-01, CMP-02 | scaffold/docs contract | `mix test test/docs_contract/comparison_claims_test.exs test/rendro/comparison_test.exs` | `lib/rendro/comparison.ex`, `test/docs_contract/comparison_claims_test.exs`, `test/rendro/comparison_test.exs`, `bench/results/comparison.json` | pending |
| 87-02 | 02 | 2 | CMP-01 | benchmark harness | `mix test test/rendro/comparison_test.exs` | `bench/comparison/**`, `bench/results/raw/**`, `bench/results/comparison.json`, `lib/mix/tasks/rendro/comparison/*.ex` | pending |
| 87-04 | 04 | 2 | CMP-03 | notebook execution/unit | `mix test test/mix/tasks/rendro_livebook_check_test.exs`; `mix rendro.livebook.check` | `guides/livebook/first_invoice.livemd`, `lib/mix/tasks/rendro/livebook/check.ex` | pending |
| 87-03 | 03 | 3 | CMP-02 | docs contract/generated docs | `mix test test/docs_contract/comparison_claims_test.exs`; `mix run scripts/verify_docs.exs` | `guides/comparison.md`, `lib/rendro/comparison.ex`, `scripts/verify_docs.exs` | pending |
| 87-05 | 05 | 4 | CMP-02, CMP-03 | ExDoc/package/CI guardrails | `mix test test/guardrails/required_checks_contract_test.exs test/docs_contract/comparison_claims_test.exs`; package inspection command | `mix.exs`, `README.md`, `.github/workflows/ci.yml`, `priv/guardrails/required_status_checks.json` | pending |
| 87-06 | 06 | 5 | CMP-01, CMP-02, CMP-03 | final generation/verification | `mix test`; `mix run scripts/verify_docs.exs`; `mix ci`; `mix rendro.comparison.check`; `mix rendro.livebook.check` | final generated assets, guide, notebook, manifest, CI config | pending |

---

## Cross-Reference Matrix

| Behavior | Requirement | Automated Check | Status |
|----------|-------------|-----------------|--------|
| Manifest covers `rendro`, `chromic_pdf`, `pdf_generator`, `typst_cli` comparators | CMP-01 | `test/rendro/comparison_test.exs` | pending |
| Manifest includes pinned tool/library versions and environment metadata | CMP-01 | `test/rendro/comparison_test.exs`; `test/docs_contract/comparison_claims_test.exs` | pending |
| Raw artifact paths have SHA-256 values that match committed files | CMP-01 | `Rendro.Comparison.static_contract_errors/0`; comparison docs-contract test | pending |
| Whole-process metrics include cold start, RSS/memory, container image size, and dependency count | CMP-01 | comparison manifest tests | pending |
| Guide generated blocks equal generator output | CMP-02 | `test/docs_contract/comparison_claims_test.exs` | pending |
| Every `[bench:CMP-*]` citation resolves to a manifest claim | CMP-02 | `test/docs_contract/comparison_claims_test.exs` | pending |
| Every public docs claim from manifest appears in `guides/comparison.md` | CMP-02 | `test/docs_contract/comparison_claims_test.exs` | pending |
| Uncited comparative phrases fail the docs contract | CMP-02 | mutation-friendly tests in `test/docs_contract/comparison_claims_test.exs` | pending |
| Guide praises alternatives where true and includes complex-script/HTML boundaries | CMP-02 | source assertions in docs-contract test | pending |
| Notebook is listed in ExDoc extras and Hex package contents | CMP-03 | package/extras assertions in docs-contract tests | pending |
| Notebook uses `Kino.HTML.new/1` and `Kino.Download.new/2` | CMP-03 | notebook static assertions; livebook check script | pending |
| Notebook executes through `Livebook.live_markdown_to_elixir/1` in advisory lane | CMP-03 | `mix rendro.livebook.check`; CI guardrail test | pending |
| Benchmark and Livebook advisory jobs are absent from `required_contexts` | CMP-01, CMP-03 | `test/guardrails/required_checks_contract_test.exs` | pending |
| Required `test` job remains external-tool free | CMP-01, CMP-03 | scoped CI job-block assertions | pending |

---

## Wave 0 Requirements

- [ ] `test/docs_contract/comparison_claims_test.exs` - docs-contract scaffold for manifest shape, citations, generated blocks, forbidden overclaims, ExDoc/package links.
- [ ] `test/rendro/comparison_test.exs` - pure unit tests for manifest helpers, static contract errors, raw hash validation, and generated block helpers.
- [ ] `bench/results/comparison.json` - committed initial manifest with required schema fields and placeholder raw artifacts only if clearly marked non-public; final plan must replace placeholders with real pinned results before guide publication.
- [ ] `test/mix/tasks/rendro_livebook_check_test.exs` - runner test seam for `mix rendro.livebook.check`.
- [ ] Guardrail tests extended for benchmark and Livebook advisory contexts before adding CI jobs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Public comparison guide reads as fair, not hype or attack copy | CMP-02 | Tone and buyer-guide clarity are not fully reducible to source assertions | Read `guides/comparison.md`; confirm it uses fit/tradeoff language, praises ChromicPDF/Typst where true, and avoids a single winner framing. |
| Final benchmark numbers are plausible and environment metadata is understandable | CMP-01 | Humans should sanity-check public benchmark posture before launch | Review `bench/results/comparison.json`, raw artifacts, and guide tables; confirm no surprising result is published without explanation or caveat. |
| Notebook preview renders acceptably in real Livebook UI | CMP-03 | CI can execute cells, but cannot fully grade the hosted notebook UX | Open `guides/livebook/first_invoice.livemd` in Livebook once before launch and confirm preview/download affordances are visible. |

All contract and rot-prevention behaviors have automated verification. Manual checks are final launch-quality review, not substitutes for tests.

---

## Validation Sign-Off

- [x] All planned tasks have automated verification commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 requirements cover the missing docs/benchmark/notebook test surfaces.
- [x] No watch-mode flags.
- [x] Required feedback latency target is under 60 seconds for static checks.
- [x] Advisory benchmark/Livebook execution remains separated from required deterministic checks.
- [x] `nyquist_compliant: true` set in frontmatter.

Approval: planned 2026-06-11
