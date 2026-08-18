---
phase: 127-public-example-catalog-quality-ratchet
verified: 2026-08-18T02:09:10Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "A passed:true catalog disposition now requires both supersedes_evidence_ref and resolution_ref."
  gaps_remaining: []
  regressions: []
---

# Phase 127: Public Example Catalog & Quality Ratchet Verification Report

**Phase Goal:** A public, hash-checked, bounded by-domain example catalog exists as a sibling of the launch gallery, with every generated cell either human-scored or explicitly unscored, never silently unverified.

**Verified:** 2026-08-18T02:09:10Z  
**Status:** passed  
**Re-verification:** Yes — after gap closure `a5850c6`

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | New generation/check tasks produce a deterministic, SHA-checked 32-cell sibling catalog without changing the 11-row launch gallery. | ✓ VERIFIED | `Rendro.Catalog` is dev/test-only; `MIX_ENV=test mix rendro.catalog.check` returned `Catalog VERIFIED`; all 32 on-disk PNG SHA-256 values exactly match `catalog.json`; no `assets/rendro/artifacts.json` or `Rendro.LaunchArtifacts` diff exists from the phase implementation range. The prior full `mix ci.fast` passed 1,782 tests and its Hex tarball inspection contained neither `dev/rendro/catalog` nor catalog/rubric assets. |
| 2 | A machine-tested hard combinatorial ceiling blocks silent grid growth. | ✓ VERIFIED | The literal ordered registry has 32 entries and `catalog_contract_errors/1` requires both `length == 32` and `length <= 32`. `catalog_test.exs` exercises 31 and 33 entries; the scoped suite passed. No filesystem enumeration or Cartesian-product generator feeds membership. |
| 3 | Rows populate preset/theme/mode and are by-domain, brand-tagged public assets. | ✓ VERIFIED | `catalog.json` has 32 cells arranged under `assets/rendro/catalog/<family>/<brand>/`; six truthful default rows (`brand/preset: null`, `theme: default`, `mode: light`), 13 dark rows with exact screen-only disclosure, and 19 light rows with null disclosure. All 32 cells have one-page/null `preview_copy`; native dimensions include landscape certificate and A6 ticket sizes. |
| 4 | Every generated cell is scored or explicitly unscored, coverage fails loudly, and failed evidence cannot silently become passing without defect closure. | ✓ VERIFIED | Current coverage remains exactly 12 scored `passed:false` and 20 reasoned unscored. Post-fix adversarial promotion mutations each return `{:error, ...}`: omission of `supersedes_evidence_ref` reports missing prior/superseded evidence; omission of `resolution_ref` reports missing behavioral resolution. Schema and runtime tests cover both cases. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `dev/rendro/catalog.ex` | Dev-only registry, generation, hash/check and quality join | ✓ VERIFIED | Substantive dev/test-only implementation, called by both catalog tasks. `promotion_evidence_errors/2` is reached from the exact disposition join and rejects a passed disposition missing either closure reference. |
| `dev/mix/tasks/rendro/catalog/{gen,check}.ex` | Deliberate writer and read-only verifier | ✓ VERIFIED | Both delegate to `Rendro.Catalog.generate/1` and `check/1`; `check` emits errors and writes nothing. |
| `assets/rendro/catalog.json` + `assets/rendro/catalog/` | Ordered public manifest and 32 page-one PNGs | ✓ VERIFIED | 32 manifest cells / 32 PNGs; independently recomputed all 32 PNG hashes. No PDFs or trailing-page images occur below the public catalog tree. |
| `priv/quality/rubric_scores.json` | Exact scored/unscored dispositions | ✓ VERIFIED | 32 dispositions: 12 scored-false and 20 reasoned-unscored, all hash-bound to current cells. |
| `priv/schemas/rubric_scores.schema.json` | Additive scored/unscored schema | ✓ VERIFIED | `review_status: scored` plus `passed: true` now requires both closure fields; checked-in schema mutation tests fail for each missing field. |
| Contract suites and raster review suite | Automated contract and bounded review evidence | ✓ VERIFIED | Re-verification ran 89 focused catalog/rubric tests, all passing. The prior full deterministic lane passed 1,782 tests; the raster review route remains a separate pinned advisory lane. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Rendro.Catalog` | fixtures / transforms / presets | literal `fixture_ref` → `Examples.load!` → `ExamplesData.transform` → preset font registration | WIRED | Source dispatch is explicit; deterministic full-PDF check passed. |
| `catalog.json` | catalog PNG tree | `png_path` + SHA-256 + parsed PNG dimensions | WIRED | All 32 hashes matched; post-review `e717689`/`f40fa16` now exercise missing/hash/width/height through `Catalog.check/1`. |
| `catalog.json` | rubric dispositions | exact ID, metadata, PNG hash, PDF hash join and derived quality projection | WIRED | Missing/duplicate/orphan/stale/projection cases fail; the runtime join now rejects either missing promotion-closure reference. |
| CI required lane | catalog check | normal CI invokes `mix rendro.catalog.check` | WIRED | `.github/workflows/ci.yml` invokes it except the documented initial isolated hash-capture condition. |
| isolated pinned raster lane | PDFium generation/review | branch-scoped `gsd/phase-127-catalog-bless-*` job | WIRED | Guardrail test passes; lane is branch/event-gated and separate from deterministic required CI. Historical success is advisory evidence only, not treated as a local deterministic proof. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `catalog.json` | cells, source-PDF/PNG SHA-256, dimensions | literal registry → real fixture render → PDFium page-one output | Yes | ✓ FLOWING |
| catalog quality projection | `quality` | `rubric_scores.json.catalog_dispositions` exact join | Yes | ✓ FLOWING — current projection remains 12 `needs_work` / 20 `unscored`; a future `passes` projection is rejected unless it carries both closure references. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Current committed catalog check | `MIX_ENV=test mix rendro.catalog.check` | `Catalog VERIFIED` | ✓ PASS |
| Catalog/rubric promotion contracts | `mix test test/rendro/catalog_test.exs test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/catalog_quality_contract_test.exs` | 89 tests, 0 failures | ✓ PASS |
| Complete deterministic lane and package build | prior `MIX_ENV=test mix ci.fast` | 1,782 tests, 0 failures; Hex tarball built; Credo/Dialyzer clean | ✓ PASS |
| Missing superseded-evidence closure | threshold-valid in-memory promotion with `supersedes_evidence_ref` omitted | `Catalog.check` returned the specific missing-prior-evidence error | ✓ PASS |
| Missing behavioral-resolution closure | threshold-valid in-memory promotion with `resolution_ref` omitted | `Catalog.check` returned the specific missing-resolution error | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| CATALOG-01 | 01, 03, 05 | Deterministic sibling hash catalog | ✓ SATISFIED | literal registry, source-PDF checks, 32 matching committed PNG hashes, separate gallery. |
| CATALOG-02 | 01, 05 | Explicit bounded row-count ceiling | ✓ SATISFIED | Exact-32 and <=32 checks plus 31/33 test coverage. |
| CATALOG-03 | 02, 03, 05 | Domain/brand organization and reserved manifest metadata | ✓ SATISFIED | Domain/brand paths and complete `preset`/`theme`/`mode` metadata verified. |
| CATALOG-04 | 02–05 | Additive human quality ratchet | ✓ SATISFIED | Exact current coverage and identity/projection checks remain sound; both runtime and JSON-schema promotion-closure mutations now fail loud. |

No orphaned Phase-127 requirements: `CATALOG-01` through `CATALOG-04` are all mapped to Phase 127; `CATALOG-05` is explicitly assigned to Phase 125.

### Anti-Patterns Found

No blocker or warning anti-pattern remains in the Phase-127 implementation and test artifacts examined. No `TBD`, `FIXME`, `XXX`, placeholder, or empty-render markers were found.

### Residual Risks / Human Evidence

- Jon’s provisional semantics are represented faithfully in the current data: all 12 flagships are `passed:false`; the dark Poppy & Grain Receipt retains `reader_affordances: 2`, `typographic_craft: 2`, and `print_safety: false`. This is recorded human evidence, not an automated visual-quality proof.
- The committed catalog only exposes page-one previews. The separate 12-flagship/4-multipage PNG review route correctly stays outside the public tree and is pinned-PDFium advisory evidence; it does not prove universal viewer, print, PDF/UA, WCAG, or accessibility behavior.
- The closure evidence is syntax/presence-validated by the deterministic schema/runtime gate. Maintainers still own the human judgment that the cited resolution actually fixes the named visual or behavioral defect; the current catalog makes no `passed:true` claim.

## Gaps Summary

None. The former promotion-closure blocker is closed by `a5850c6`, and the verifier re-ran both adversarial missing-field mutations against `Catalog.check/1` rather than relying on the new tests alone.

---

_Verified: 2026-08-18T02:09:10Z_  
_Verifier: the agent (gsd-verifier)_
