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
| TBD-01 | TBD | 0/1 | CATALOG-01 | T-127-01, T-127-03 | Safe paths and pinned raster provenance | integration + advisory raster | `mix test test/rendro/catalog_test.exs`; `mix rendro.catalog.check --pdfium PATH` | ❌ W0 | ⬜ pending |
| TBD-02 | TBD | 0/1 | CATALOG-02 | T-127-05 | Exact ordered membership and hard ceiling | unit | `mix test test/rendro/catalog_test.exs` | ❌ W0 | ⬜ pending |
| TBD-03 | TBD | 0/1 | CATALOG-03 | T-127-01, T-127-04 | Safe relative paths and truthful manifest contract | docs/package contract | `mix test test/docs_contract/catalog_manifest_contract_test.exs` | ❌ W0 | ⬜ pending |
| TBD-04 | TBD | 0/1 | CATALOG-04 | T-127-02, T-127-04 | Exact disposition join and fail-closed drift | schema + contract | `mix test test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/catalog_test.exs` — registry, generation, and bounded membership tests for CATALOG-01/02.
- [ ] `test/docs_contract/catalog_manifest_contract_test.exs` — manifest, paths, and sibling-tree isolation for CATALOG-03.
- [ ] `test/docs_contract/catalog_quality_contract_test.exs` — exact disposition join, score validation, and freshness behavior for CATALOG-04.
- [ ] Extend `rubric_scores.schema.json` additively with the catalog scored/unscored disposition union.
- [ ] Add the catalog checker to the advisory CI/guardrail in lockstep; keep PDFium out of the deterministic required lane.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Curated flagship visual quality and any `false -> true` resolution evidence | CATALOG-04 | Rubric judgments are intentionally human-authored and generation must not mutate them | Review the 12 scored page-one PNGs at native geometry in both modes, record evidence, then run the catalog checker to bind dispositions to current hashes. |
| Bounded final-page proof for paginating fixtures | CATALOG-01 | The public catalog intentionally publishes page one only | Render the selected invoice, statement, and certificate fixtures with pinned PDFium; inspect final pages for truncation/overflow and retain the small external proof artifact. |

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
