# Phase 27 - Wave 3 Summary

## Objective
Update the PDF Writer to output multi-font text runs and establish the end-to-end verification of the honest I18n matrix.

## Execution Details
- Task 1: Updated `Rendro.PDF.Writer` (`render_text_block` and `collect_block_fonts`) to correctly iterate over the runs inside `MeasuredText`, resolving the correct font name and outputting `/#{run.font.name} #{text.size} Tf` for each text run.
- Task 2: Added `test/rendro/i18n_test.exs` as a system test to verify that unmapped glyphs and unsupported scripts correctly halt the pipeline and emit a properly formatted `Rendro.Error`.
- Updated `Rendro.Document` module documentation to explain the "honest I18n" model.
- Updated `Rendro.Test.Generators` to use `string(:ascii)` rather than `:printable` to prevent test flakiness due to unsupported randomly generated characters across the rest of the test suite.
- Fixed failing test assertions across `measure_test.exs`, `paginate_test.exs`, and `deterministic_test.exs` to support the new list of lists format for runs.

## Verification
- All tests in `test/rendro/i18n_test.exs` pass.
- End-to-end test suite (`mix test`) passes cleanly, confirming no regressions.

## State
Wave 3 of Phase 27 is complete. Phase 27 is completed successfully.
