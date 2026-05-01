# Phase 27 - Wave 2 Summary

## Objective
Apply fallback chains during text measurement, breaking text into font-specific runs, and implement strict structural diagnostics (errors) for unsupported text boundaries.

## Execution Details
- Task 1: Updated `MeasuredText` structure so that `lines` are a list of lines, where each line is a list of font runs (`%{font: font, text: text, width: width}`). Added test helper `lines_text` to maintain backwards compatibility in test assertions.
- Task 2: Integrated `resolve_pdf_font_chain/3` into `Rendro.Pipeline.Measure`. Explicitly handled unsupported scripts and missing glyphs by trapping and propagating an `{:error, {:unsupported_glyph, char}}` or `{:error, {:unsupported_script, reason}}`. Split lines correctly into runs.
- Task 3: Implemented actionable error contexts in `Rendro.Error` for `{:unsupported_glyph, char}` and `{:unsupported_script, reason}` mapping to specific actionable `next_step` messages.

## Verification
- All tests in `test/rendro/pipeline/measure_test.exs` and `test/rendro/error_test.exs` passed successfully.

## State
Wave 2 of Phase 27 is complete.
