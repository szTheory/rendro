# Phase 30 Verification

**Goal:** Ensure the PNG to PDF conversion handles all required PNG types correctly (RGB, RGBA, Indexed) and successfully paints them on the canvas.

## Evidence

1. **Branded Invoice Logo:** The user visually verified (`mix rendro.visual_uat 29`) that the `rendro-logo.png` is clearly painted and positioned correctly on the PDF canvas.
2. **Interlaced PNGs:** Added tests to `test/rendro/pdf/png_test.exs` ensuring that `{:error, :interlaced}` is returned for PNGs with an interlace method of 1.
3. **Supported Formats:** Added tests and implementation in `Rendro.PDF.PNG.process_for_pdf/1` to handle:
   - RGB (DeviceRGB pass-through)
   - RGBA (split into color stream and SMask stream)
   - Indexed (DeviceRGB with PLTE chunk)
4. **Regression Testing:** `pdftoppm` was installed in the CI workflow, and an automated regression test was added to `test/rendro/pipeline/render_test.exs` to guarantee the PDF stream rasterizes without errors.

All validation criteria from `30-VALIDATION.md` have been met. Phase is complete.