---
phase: 127
slug: public-example-catalog-quality-ratchet
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-17
---

# Phase 127 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with JSV schema validation |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/catalog_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.fast`; advisory artifact lane: `mix rendro.catalog.check --pdfium PATH` |
| **Estimated runtime** | Measure during Wave 0 and record before validation sign-off |

---

## Sampling Rate

- **After every task commit:** Run the narrowest affected ExUnit file, including `--max-failures 1` while iterating.
- **After every plan wave:** Run `mix ci.fast`.
- **Before `$gsd-verify-work`:** `mix ci.fast` must be green and the pinned-PDFium advisory catalog check must pass.
- **Max feedback latency:** 60 seconds for deterministic checks; the external raster advisory check may run separately.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 127-01-01 | 01 | 1 | CATALOG-01 | T-127-01 | Default-cell fixture/theme/render tracer and safe paths | deterministic integration | `mix test test/rendro/catalog_test.exs --max-failures 1` | ❌ W0 — Plan 01 Task 1 | ⬜ pending |
| 127-01-02 | 01 | 1 | CATALOG-02 | T-127-05 | Exact ordered membership, 31/32/33 boundaries, hard ceiling | unit | `mix test test/rendro/catalog_test.exs --max-failures 1` | ❌ W0 — Plan 01 Task 2 | ⬜ pending |
| 127-01-03 | 01 | 1 | CATALOG-01 | T-127-03 | Separate generation/check task semantics and read-only errors | integration | `mix test test/rendro/catalog_test.exs --max-failures 1` | ❌ W0 — Plan 01 Task 3 | ⬜ pending |
| 127-02-01 | 02 | 2 | CATALOG-03 | T-127-01, T-127-04 | Safe relative paths, truthful manifest, package/public isolation | docs/package contract | `mix test test/docs_contract/catalog_manifest_contract_test.exs --max-failures 1` | ❌ W0 — Plan 02 Task 1 | ⬜ pending |
| 127-02-02 | 02 | 2 | CATALOG-04 | T-127-02, T-127-04 | Exact disposition join, schema, stale/orphan/projection/transition behavior | schema + contract | `mix test test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1` | ❌ W0 — Plan 02 Task 2 | ⬜ pending |
| 127-03-01 | 03 | 3 | CATALOG-01 | T-127-03, T-127-05 | Pinned isolated generation, bounded review payload, CI separation | guardrail + advisory raster | `mix test test/guardrails/required_checks_contract_test.exs test/rendro/catalog_raster_review_test.exs --exclude raster_snapshot --max-failures 1` | ❌ W0 — Plan 03 Task 1 | ⬜ pending |
| 127-03-02 | 03 | 3 | CATALOG-01, CATALOG-03, CATALOG-04 | T-127-02, T-127-03 | Exact 32 artifact import and hash-bound initial dispositions | integration + advisory raster | `mix test test/rendro/catalog_test.exs test/docs_contract/catalog_manifest_contract_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1`; `mix rendro.catalog.check --pdfium PATH` | ❌ dependent artifacts | ⬜ pending |
| 127-04-01 | 04 | 4 | CATALOG-04 | T-127-02, T-127-04 | Twelve full-size human rubric records plus bounded multipage verdict | manual procedural | `test "$(find tmp/rendro_phase127_review -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')" = "16"` | ❌ dependent review | ⬜ pending |
| 127-05-01 | 05 | 5 | CATALOG-04 | T-127-02, T-127-04 | Exact 12 scored/20 unscored transcription and final projection | schema + contract | `mix test test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1` | ❌ dependent review | ⬜ pending |
| 127-05-02 | 05 | 5 | CATALOG-01, CATALOG-02, CATALOG-03, CATALOG-04 | T-127-01, T-127-02, T-127-03, T-127-04, T-127-05 | Full source/security/package/CI closure | full deterministic + advisory | `mix test`; `mix ci.fast`; `mix rendro.catalog.check --pdfium PATH` | ❌ dependent closure | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Plan 01 Tasks 1-3 own `test/rendro/catalog_test.exs` before dependent catalog implementation — registry, generation/check, and bounded membership tests for CATALOG-01/02.
- [ ] Plan 02 Task 1 owns `test/docs_contract/catalog_manifest_contract_test.exs` before manifest/package implementation — manifest, paths, and sibling-tree isolation for CATALOG-03.
- [ ] Plan 02 Task 2 owns `test/docs_contract/catalog_quality_contract_test.exs` and the additive `rubric_scores.schema.json` union before disposition/join implementation — score validation and freshness behavior for CATALOG-04.
- [ ] Plan 03 Task 1 owns `test/rendro/catalog_raster_review_test.exs` and advisory CI/guardrail assertions before pinned generation; PDFium remains outside deterministic required CI.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Curated flagship visual quality and any `false -> true` resolution evidence | CATALOG-04 | Rubric judgments are intentionally human-authored and generation must not mutate them | Review the 12 scored page-one PNGs at native geometry in both modes, record evidence, then run the catalog checker to bind dispositions to current hashes. |
| Bounded final-page proof for paginating fixtures | CATALOG-01 | The public catalog intentionally publishes page one only | Render the representative 60-plus-row Invoice and Statement fixtures with pinned PDFium; inspect first/final physical pages for truncation/overflow and retain the four-image external proof artifact. |

---

## Threat Model

| Ref | Threat | STRIDE | Mitigation |
|-----|--------|--------|------------|
| T-127-01 | Unsafe fixture or asset path escapes the intended tree | Tampering / Information disclosure | Require literal safe-relative registry paths and validate before read, write, or render. |
| T-127-02 | Artifact and human review records drift apart | Tampering | Recompute hashes/page counts and enforce an exact one-to-one disposition join. |
| T-127-03 | Unpinned rasterizer changes public evidence | Tampering | Preserve PDFium version and executable-hash provenance from the existing pin contract. |
| T-127-04 | Status or accessibility claims exceed the evidence | Repudiation | Use the fixed three-state status vocabulary and prohibit unsupported WCAG, PDF/UA, print, or viewer claims. |
| T-127-05 | Cartesian growth makes generation and review unbounded | Denial of service | Use an explicit 32-cell registry with exact-count and hard-ceiling tests. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Deterministic feedback latency is below 60 seconds.
- [ ] `nyquist_compliant: true` is set in frontmatter.

**Approval:** pending
