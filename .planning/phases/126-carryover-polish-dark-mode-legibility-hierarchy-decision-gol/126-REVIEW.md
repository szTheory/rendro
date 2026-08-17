---
phase: 126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol
reviewed: 2026-08-17T06:09:06Z
depth: standard
files_reviewed: 26
files_reviewed_list:
  - .github/workflows/ci.yml
  - lib/rendro/recipes/table_cell.ex
  - lib/rendro/recipes/invoice.ex
  - lib/rendro/recipes/ticket.ex
  - lib/rendro/recipes/payslip.ex
  - test/rendro/recipes/table_cell_test.exs
  - test/rendro/recipes/invoice_test.exs
  - test/rendro/recipes/ticket_test.exs
  - test/rendro/recipes/payslip_test.exs
  - test/rendro/theme/preset_accent_golden_test.exs
  - test/rendro/recipes/branded_invoice_typography_test.exs
  - test/rendro/recipes/payslip_typography_test.exs
  - test/rendro/recipes/receipt_typography_test.exs
  - test/rendro/recipes/invoice_typography_test.exs
  - test/rendro/recipes/statement_typography_test.exs
  - test/rendro/recipes/certificate_typography_test.exs
  - test/rendro/recipes/ticket_typography_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - priv/raster_refs/presets/swiss/light.sha256
  - priv/raster_refs/presets/corporate_classic/dark.sha256
  - priv/raster_refs/presets/editorial/dark.sha256
  - priv/raster_refs/presets/minimal_mono/dark.sha256
  - priv/raster_refs/presets/humanist/dark.sha256
  - priv/raster_refs/presets/brutalist/dark.sha256
  - priv/quality/SIGN-OFF.md
  - priv/quality/rubric_scores.json
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 126: Code Review Report

**Reviewed:** 2026-08-17T06:09:06Z
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

The submitted recipes, CI contract, evidence files, and focused tests were reviewed at standard depth. The focused test set passes (161 tests), but Invoice's pagination still uses an incorrect available height and can measure with font metrics that differ from the eventual document. Both defects can produce wrong page breaks despite successful rendering.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Invoice subtracts header and footer from its body region twice

**File:** `lib/rendro/recipes/invoice.ex:340-341`
**Issue:** `body_height` already equals the actual `:body` region height (`page - margins - header - footer`). The following `capacity` calculation subtracts `resolved_header_height` and `@footer_height` a second time. With the default header this throws away 80pt of usable body space; with anatomy fields it discards even more. `chunk_rows_into_pages/2` therefore breaks tables early and creates unnecessary pages, contradicting the nearby claim that capacity matches the rendered region.
**Fix:** Use `body_height` as the capacity before subtracting the table header, totals reserve, and epsilon.

```elixir
body_height = @page_height - 2 * @margin - resolved_header_height - @footer_height
effective_capacity = body_height - header_h - totals_reserved_height(data) - @row_epsilon
```

Add a boundary test whose rows fit in the real body region but exceed the currently undercounted capacity, then assert it remains one page.

### WR-02: Invoice silently measures arbitrary custom fonts as Helvetica

**File:** `lib/rendro/recipes/invoice.ex:385-391`
**Issue:** `measurement_type/1` replaces every font outside four preset roles with `:default`, while the table later renders with the original `type.fonts.body`. A caller can supply and register a supported custom font after `Invoice.document/2`; the real glyph widths and wraps can then differ from the measurements used for `chunk_rows_into_pages/2`. This makes page breaks font-dependent and can yield an overflowing final table page or an avoidable extra break. The fallback hides the missing measurement-font setup instead of preserving the font contract.
**Fix:** Measure with the same registered font roles used to render. Add an explicit, validated font-registration/measurement option that is applied to the measurement document before `measure_rows/4`, or fail with an actionable error for an unregistered custom role. Do not substitute `:default` for a role that will be rendered differently. Add a regression test using a non-preset embedded font and a near-wrap table value.

---

_Reviewed: 2026-08-17T06:09:06Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
