# Phase 30: Visually Correct PNG Image Rendering

## Goal
Make registered PNG image assets actually render visibly on the page so the asset surface delivered in `v1.2` is truthful, not just structurally present.

## Depends on
Phase 29

## Requirements
[ASSET-04]

## Planned work
- Replace the current `build_image_objects` path in `lib/rendro/pdf/writer.ex` so PNG XObject streams contain valid `/FlateDecode` payloads (decoded RGB samples, or IDAT pass-through with explicit `/DecodeParms /Predictor 15 /Colors N /BitsPerComponent 8 /Columns W`).
- Honor PNG color types correctly: RGB → `/DeviceRGB`; RGBA → `/DeviceRGB` + `/SMask`; Gray/Gray+α → `/DeviceGray` (+ `/SMask`); Indexed → `/Indexed [/DeviceRGB N <palette>]`.
- Add a rasterize-and-decode regression class (e.g. via `pdftoppm` + targeted pixel sampling) so the existing structural/byte-substring tests are paired with at least one test that proves the image actually paints. This closes the test-class blind spot that allowed the bug to ship through phases 28 and 29.
- Re-run the phase 29 visual UAT (`mix rendro.visual_uat 29`) and confirm the branded preview now passes the logo criterion before closing.

## Source Context
Surfaced 2026-05-01 during Phase 29 visual UAT (Claude vision verdict on `29-branded-preview.png`).

**Root Cause**:
`lib/rendro/pdf/writer.ex:238-258` (`build_image_objects/2`) writes the entire raw PNG file bytes into the Image XObject stream while declaring `/Filter /FlateDecode`. PDF requires a FlateDecode stream to contain raw zlib-compressed RGB pixel samples (with optional `/DecodeParms /Predictor` for PNG-style predictor filtering), NOT the PNG file format itself. PDF readers attempt to inflate the PNG container as a zlib stream, fail or produce garbage, and silently skip drawing the image — leaving the logo region blank. The `Do` operator IS emitted, the XObject resource IS wired, `/Width`/`/Height`/`/Subtype`/`/Filter` metadata IS correct, the byte-substring tests all pass, but the bytes inside the stream are wrong. JPEG happens to work incidentally because raw JPEG file bytes ≈ `DCTDecode`-filtered data; PNG is the only failing path today.

**Fix Direction**:
In `build_image_objects/2`: parse PNG (`IHDR` + concatenate `IDAT` chunks + inflate + strip per-scanline predictor bytes) to obtain raw RGB samples, then re-deflate; OR pass `IDAT` data through with `/DecodeParms << /Predictor 15 /Colors N /BitsPerComponent 8 /Columns W >>`. Also handle PNG color type → `/ColorSpace` (RGB / RGBA→SMask / Gray / Indexed); current hard-coded `/DeviceRGB` will mismatch RGBA inputs.
