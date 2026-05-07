# Phase 30 Validation Criteria

This phase is successful if the following conditions are met:

1. **Branded Invoice Logo:** The branded invoice logo renders visibly in the generated PDF.
2. **Interlaced PNGs:** Interlaced PNGs fail gracefully with a specific error (e.g., `{:error, :interlaced}`).
3. **Supported Formats:** RGB, RGBA, and Indexed PNG formats are explicitly supported and correctly processed into PDF-compatible payload formats.
4. **Regression Testing:** CI passes, including the `pdftoppm`-based visual regression tests to ensure no visual regressions are introduced.