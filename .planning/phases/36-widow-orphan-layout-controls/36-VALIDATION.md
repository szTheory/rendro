# Validation Plan for Phase 36: Widow/Orphan Layout Controls

## Scope
This validation document covers the end-to-end verification of Phase 36 (S01), which implements widow and orphan typographic limits during text block pagination.

## Nyquist Audit
- **Goal Backward:** Does this prove the text cleanly breaks without solitary lines? Yes.
- **Coverage:** We must validate structural correctness (lines shifted correctly) and behavior under constraints (block moved to next page if constraints fail).

## Test Cases
1. **Perfect Fit:** A paragraph that perfectly fits the space. No split.
2. **Standard Split:** A paragraph that splits cleanly, leaving >= widows on page 2 and >= orphans on page 1.
3. **Orphan Violation:** A split that leaves only 1 line on page 1 (when orphans=2). The entire block should be moved to page 2.
4. **Widow Violation:** A split that leaves only 1 line on page 2 (when widows=2). The algorithm must reduce the number of lines on page 1 to push an extra line to page 2.
5. **Cascading Violation (Unfittable Split):** A paragraph that tries to fix a widow violation, but pushing lines to page 2 causes an orphan violation on page 1. The entire block should be moved to page 2.

## UAT Script
```elixir
mix test test/rendro/pipeline/paginate_test.exs
mix test test/rendro/pipeline/measure_test.exs
```
Verify 0 failures.