---
phase: 127
slug: public-example-catalog-quality-ratchet
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 127-01-01 | 01 | 1 | CATALOG-01 | T-127-01 | Default-cell fixture/theme/render tracer and safe paths | deterministic integration | `mix test test/rendro/catalog_test.exs --max-failures 1` | ✅ | ✅ green |
| 127-01-02 | 01 | 1 | CATALOG-02 | T-127-05 | Exact ordered membership, 31/32/33 boundaries, hard ceiling | unit | `mix test test/rendro/catalog_test.exs --max-failures 1` | ✅ | ✅ green |
| 127-01-03 | 01 | 1 | CATALOG-01 | T-127-03 | Separate generation/check task semantics and read-only errors | integration | `mix test test/rendro/catalog_test.exs --max-failures 1` | ✅ | ✅ green |
| 127-02-01 | 02 | 2 | CATALOG-03 | T-127-01, T-127-04 | Safe relative paths, truthful manifest, exact D-10 page-count-derived `preview_copy` with null one-page semantics and anti-complete-document mutations, exact D-25 dark-only derived disclosure, copy/disclosure/quality separation, package/public isolation | docs/package contract | `mix test test/docs_contract/catalog_manifest_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 127-02-02 | 02 | 2 | CATALOG-04 | T-127-02, T-127-04 | Exact disposition join, schema, stale/orphan/projection/transition behavior | schema + contract | `mix test test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 127-03-01 | 03 | 3 | CATALOG-01 | T-127-03, T-127-05 | Pinned isolated generation and bounded review payload | guardrail + advisory raster | exact advisory job `95552265981` | ✅ | ✅ green |
| 127-03-02 | 03 | 3 | CATALOG-01, CATALOG-03, CATALOG-04 | T-127-02, T-127-03 | Exact 32 artifact import and hash-bound initial dispositions | integration + advisory raster | exact advisory job `95554693775`; `mix ci.fast` | ✅ | ✅ green |
| 127-04-01 | 04 | 4 | CATALOG-04 | T-127-02, T-127-04 | Twelve full-size human rubric records plus bounded multipage verdict | manual procedural | committed `127-04-SUMMARY.md` and exact 16-image advisory artifact | ✅ | ✅ green |
| 127-05-01 | 05 | 5 | CATALOG-04 | T-127-02, T-127-04 | Exact 12 scored/20 unscored transcription and final projection | schema + contract | `mix test test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 127-05-02 | 05 | 5 | CATALOG-01, CATALOG-02, CATALOG-03, CATALOG-04 | T-127-01, T-127-02, T-127-03, T-127-04, T-127-05 | Full source/security/package/CI closure including all-cell exact/null D-10 `preview_copy` audit and mutation coverage | full deterministic + advisory | `mix test`; `mix ci.fast`; exact pinned advisory job `95565301370`; D-10/D-25 jq audit | ✅ | ✅ green |
| 127-POST-01 | post-review | post | CATALOG-01, CATALOG-03 | T-127-01, T-127-02, T-127-04 | Exact physical-page counting plus mandatory PNG path, existence, SHA-256, width, and height validation through `Catalog.check/1` | integration + mutation | `mix test test/rendro/catalog_test.exs --max-failures 1`; `mix rendro.catalog.check` | ✅ | ✅ green |
| 127-GAP-01 | verification-gap | post | CATALOG-04 | T-127-02, T-127-04 | Any `passed:true` promotion requires both prior-evidence provenance and a concrete behavioral-resolution reference in runtime and schema contracts | schema + public-check mutation | `mix test test/rendro/catalog_test.exs test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Plan 01 Tasks 1-3 own `test/rendro/catalog_test.exs` before dependent catalog implementation — registry, generation/check, and bounded membership tests for CATALOG-01/02.
- [ ] Plan 02 Task 1 owns `test/docs_contract/catalog_manifest_contract_test.exs` before manifest/package implementation — manifest, paths, sibling-tree isolation, D-10 exact multi-page/null-one-page `preview_copy` with missing/wrong/complete-document mutation rejection, and D-25 exact dark/null-light `boundary_disclosure`, each kept independent from reviewer data and quality state for CATALOG-03.
- [ ] Plan 02 Task 2 owns `test/docs_contract/catalog_quality_contract_test.exs` and the additive `rubric_scores.schema.json` union before disposition/join implementation — score validation and freshness behavior for CATALOG-04.
- [ ] Plan 03 Task 1 owns `test/rendro/catalog_raster_review_test.exs` and advisory CI/guardrail assertions before pinned generation; PDFium remains outside deterministic required CI.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Curated flagship visual quality and any `false -> true` resolution evidence | CATALOG-04 | Rubric judgments are intentionally human-authored and generation must not mutate them | Review the 12 scored page-one PNGs at native geometry in both modes, record evidence, then run the catalog checker to bind dispositions to current hashes. |
| Bounded final-page proof for paginating fixtures | CATALOG-01 | The public catalog intentionally publishes page one only | Render `Rendro.Test.EdgeFixtures.document(:invoice, :line_items_60_plus)` and `Rendro.Test.EdgeFixtures.document(:statement, :line_items_60_plus)`, require `page_count > 1` for each, then inspect `invoice_line_items_60_plus_page_first.png`, `invoice_line_items_60_plus_page_final.png`, `statement_line_items_60_plus_page_first.png`, and `statement_line_items_60_plus_page_final.png` for physical sequence and truncation/overflow. |

---

## Threat Model

| Ref | Threat | STRIDE | Mitigation |
|-----|--------|--------|------------|
| T-127-01 | Unsafe fixture or asset path escapes the intended tree | Tampering / Information disclosure | Require literal safe-relative registry paths and validate before read, write, or render. |
| T-127-02 | Artifact and human review records drift apart | Tampering | Recompute hashes/page counts and enforce an exact one-to-one disposition join. |
| T-127-03 | Unpinned rasterizer changes public evidence | Tampering | Preserve PDFium version and executable-hash provenance from the existing pin contract. |
| T-127-04 | Status, page coverage, or accessibility claims exceed the evidence | Repudiation | Derive exact D-10 `preview_copy` from integer page count for multi-page cells and null for one-page cells, reject copy that presents page one as the complete document, and use the fixed three-state status vocabulary plus an independent mode-derived D-25 disclosure. |
| T-127-05 | Cartesian growth makes generation and review unbounded | Denial of service | Use an explicit 32-cell registry with exact-count and hard-ceiling tests. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Deterministic feedback latency is below 60 seconds.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** complete — deterministic checks and the separate exact-SHA pinned-PDFium advisory job are both recorded; human review remains bounded to its named images.

## Validation Audit 2026-08-18

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Post-execution review and goal verification added three trust-boundary regressions without introducing a new coverage gap: exact `/Page` counting, end-to-end committed-PNG integrity, and fail-closed false-to-true promotion provenance. CATALOG-01 through CATALOG-04 remain automated except for the deliberately human-owned visual judgments and bounded multipage inspection listed above.
