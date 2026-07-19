---
phase: 114
slug: domain-research-reader-quality-rubric-realistic-example-data
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-10
---

# Phase 114 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `114-RESEARCH.md` → Validation Architecture. All test files are
> Wave 0 gaps unless noted otherwise.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in), `mix test` |
| **Config file** | `test/test_helper.exs` (excludes `:quarantine`, `:live_pdf_tools`, `:live_signing`, `:raster_snapshot` by default) |
| **Quick run command** | `mix test test/rendro/examples_test.exs test/docs_contract/examples_schema_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs` |
| **Full suite command** | `mix test --exclude quarantine --slowest 10` (the required `test` job's exact command) |
| **Estimated runtime** | ~30–60 seconds (targeted lanes are sub-5s) |

---

## Sampling Rate

- **After every task commit:** Run the targeted `mix test` invocation for the file(s) touched (see Quick run command)
- **After every plan wave:** Run `mix test --exclude quarantine --slowest 10` (full suite)
- **Before `/gsd-verify-work`:** Full suite green + `mix hex.build` (or `mix ci.fast`) must pass
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| EXL-01 | Fixtures exist, encode domain language, money-as-strings, optional empty brand/logo slot | unit (schema) | `mix test test/docs_contract/examples_schema_contract_test.exs` | ❌ W0 |
| EXL-02 | Loader reads fixtures via `app_dir`; absent from `public_api.json` | unit | `mix test test/rendro/examples_test.exs test/docs_contract/public_api_contract_test.exs` | ❌ W0 (examples_test) · ✅ public_api_contract_test (extend hidden list) |
| EXL-03 | Every fixture validates against `examples.schema.json` | unit (docs-contract) | `mix test test/docs_contract/examples_schema_contract_test.exs` | ❌ W0 |
| EXL-04 | De-quarantine is a provable no-op; `mix rendro.comparison.check` stays green | integration + explicit byte-diff | `mix rendro.comparison.check` **plus** a new before/after bytes-equal assertion (check alone is necessary-but-insufficient) | ❌ W0 |
| EXL-05 | `priv/examples/` ships text-only; raster-ban test mirrors `brand/` | unit + tarball integration | in-repo wildcard-extension ban + `mix hex.build` tarball-content assertion | ❌ W0 |
| EXL-06 | Optional empty `brand`/`logo` sub-object present in every fixture (S4) | unit (schema `required`/`properties`) | `mix test test/docs_contract/examples_schema_contract_test.exs` | ❌ W0 |
| RUB-01 | `DOMAIN.md` exists per domain with required sections | unit (docs-contract, structural headings) | new `test/docs_contract/domain_md_contract_test.exs` | ❌ W0 |
| RUB-02 | Rubric defined with 6 core dims + 2 gates, concrete anchors | doc content + schema enumeration | `rubric_manifest_contract_test.exs` structural enumeration check (anchor prose is human-reviewed) | ❌ W0 |
| RUB-03 | Rubric manifest schema-backed, appendable; structure + threshold arithmetic enforced (not subjective score) | unit (docs-contract) | `mix test test/docs_contract/rubric_manifest_contract_test.exs` | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/examples_test.exs` — loader behavior (`load!/1`, `list/1`) + in-repo wildcard extension-ban assertion for `priv/examples/**`
- [ ] `test/docs_contract/examples_schema_contract_test.exs` — every `priv/examples/**/*.json` validates against `priv/schemas/examples.schema.json`
- [ ] `test/docs_contract/rubric_manifest_contract_test.exs` — `priv/quality/rubric_scores.json` validates against its schema; asserts threshold arithmetic (hierarchy == 5, core dims ≥ 4, both gates pass) structurally, not the subjective score
- [ ] `test/docs_contract/domain_md_contract_test.exs` — each domain's `DOMAIN.md` has required section headings
- [ ] Extend `test/docs_contract/public_api_contract_test.exs` "known internal modules are :hidden" list to include `Rendro.Examples`
- [ ] Extend/mirror `test/docs_contract/branding_claims_test.exs` tarball test to `refute` shipped `priv/schemas/examples.schema.json` and `priv/quality/` (repo-only)
- [ ] No new framework install — ExUnit + `jsv` + built-in `JSON` already present

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rubric anchor prose is genuinely non-designer-applicable | RUB-02 | Anchor quality is subjective prose, not machine-checkable | Human review: each of 6 dims has concrete 1/3/4/5 anchors a non-designer can apply |
| `DOMAIN.md` domain-language / personas / JTBD are accurate & useful | RUB-01 | Domain-research content quality is editorial | Human review against real-world domain knowledge |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
