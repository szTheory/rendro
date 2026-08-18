---
phase: 127-public-example-catalog-quality-ratchet
reviewed: 2026-08-17T00:00:00Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - dev/rendro/catalog.ex
  - dev/mix/tasks/rendro/catalog/gen.ex
  - dev/mix/tasks/rendro/catalog/check.ex
  - mix.exs
  - lib/rendro/recipes/statement.ex
  - lib/rendro/recipes/ticket.ex
  - priv/examples/ticket/aurora-live/ticket.json
  - test/rendro/catalog_test.exs
  - test/docs_contract/catalog_manifest_contract_test.exs
  - test/docs_contract/catalog_quality_contract_test.exs
  - test/docs_contract/rubric_manifest_contract_test.exs
  - priv/quality/rubric_scores.json
  - priv/quality/SIGN-OFF.md
  - priv/schemas/rubric_scores.schema.json
  - assets/rendro/catalog.json
  - assets/rendro/catalog/
  - .github/workflows/ci.yml
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 127: Code Review Report

**Reviewed:** 2026-08-17T00:00:00Z
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found — **BLOCKED**

## Summary

The catalog's registry, reviewer disposition join, package boundary, and CI routing were reviewed along with the committed 32-PNG artifact set. Focused contract tests (88 tests) and `mix rendro.catalog.check` pass, but those checks do not establish the catalog claims they are intended to protect. The public manifest currently makes a false page-count disclosure for every catalog entry, and the required catalog CI check does not verify any committed PNG against its recorded hash.

## Critical Issues

### CR-01: Page count treats the PDF `/Pages` tree node as a physical page

**Classification:** BLOCKER

**File:** `dev/rendro/catalog.ex:619`

**Issue:** `page_count/1` counts every occurrence of `"/Type /Page"`, which is also the prefix of `"/Type /Pages"`. A direct render of `invoice--default--default--light` contains one `/Type /Page` object and one `/Type /Pages` object, yet the helper returns `2`. Consequently, all 32 committed cells report `page_count: 2` and `Preview: page 1 of 2` even for one-page documents. This makes the D-10 disclosure factually false and prevents the one-page `preview_copy: null` branch from ever being used.

**Fix:** Derive the count from a PDF parser/renderer page list rather than substring matching. At minimum, exclude the `/Pages` token precisely and add a regression test for both a one-page document and a real multi-page document. For example:

```elixir
defp page_count(pdf) do
  pdf
  |> Pdfium.render(dpi: @dpi)
  |> then(fn {:ok, pages} -> length(pages) end)
end
```

Then regenerate `assets/rendro/catalog.json` and validate that one-page cells have `page_count: 1` and `preview_copy: null`.

### CR-02: Required catalog check never verifies public PNG bytes or hashes

**Classification:** BLOCKER

**File:** `dev/rendro/catalog.ex:353-375`

**Issue:** `rendered_contract_errors/1` re-renders only the source PDF and compares its hash/page count. It never reads `cell["png_path"]`, checks existence, recalculates `png_sha256`, verifies PNG dimensions, or confirms that PDFium's page-one render matches the committed image. `.github/workflows/ci.yml:318-325` invokes this method as the required Catalog Artifacts check. The only test that verifies PNG hashes is tagged `:raster_snapshot` (`test/rendro/catalog_raster_review_test.exs:23-42`) and runs only on the temporary Phase-127 blessing branch route, not on pull requests or main. Therefore a deleted, corrupted, or substituted catalog PNG can ship while `mix rendro.catalog.check` and normal CI report success, defeating the hash-bound artifact and reviewer-evidence contract.

**Fix:** Make `rendered_contract_errors/1` validate every committed PNG in the normal check: safe path, existence, SHA-256, PNG dimensions, and equality with a freshly rendered page-one PNG when the pinned renderer is available. Keep the artifact-only hash/existence validation mandatory even where rerendering is advisory. Add a non-raster-snapshot contract test that alters a temporary manifest/path or extracted validation helper and proves a missing/hash-drift PNG fails the required check.

---

_Reviewed: 2026-08-17T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
