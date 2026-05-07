<user_constraints>
## User Constraints (from CONTEXT.md)
[No locked decisions from CONTEXT.md found, this was a planned phase without a discuss-phase interaction]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ASSET-04 | Make registered PNG image assets actually render visibly on the page. | PDF Image XObject encoding standards, PNG decompression/filter logic, Alpha channel extraction. |
</phase_requirements>

# Phase 30: Visually Correct PNG Image Rendering - Research

**Researched:** 2026-05-02
**Domain:** Native PDF generation (Elixir) / ISO 32000-1 Image XObjects
**Confidence:** HIGH

## Summary
The phase addresses a critical bug where PNG files are embedded directly as PDF `Image XObject` streams. The PDF specification requires `FlateDecode` filters to contain pure pixel samples (or raw IDAT chunks with correct Predictor configurations), not the full PNG file container. Because the current `lib/rendro/pdf/writer.ex` embeds raw PNG bytes, PDF viewers silently fail to paint the PNGs despite correct structural embedding.

**Primary recommendation:** Use Elixir's `:zlib` to inflate PNG `IDAT` chunks, un-filter the rows (Sub, Up, Average, Paeth) for Alpha channel extraction (RGBA/GrayA to separate SMask), and pass predictor-enabled raw IDAT chunks directly for standard RGB/Gray/Indexed PNGs. Introduce `pdftoppm` in tests to catch rendering failures.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PNG Parsing (IHDR, PLTE) | Core Library (Rendro.PDF.PNG) | — | Must extract chunks, color type, filters to inform PDF dictionaries. |
| PNG Decompression & Un-filtering | Core Library (Rendro.PDF.PNG) | — | Must manually decompress IDAT and un-apply scanline predictors to access raw alpha masks. |
| PDF Image XObject Stream generation | Core Library (Rendro.PDF.Writer) | — | Needs to handle Predictors via `/DecodeParms` or emit separate color and `/SMask` streams. |
| Visual Rendering Tests | CI / Test Suite | `pdftoppm` (OS binary) | Structural byte-substring testing is blind to PDF painting logic; rasterization proves visible output. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:zlib` | native | Inflate/deflate PNG streams | Built-in to Erlang OTP, avoids C-NIF dependencies for fast byte manipulation. |
| `pdftoppm` | *OS util* | Rasterize PDF to pixels | Poppler-utils is standard, deterministic, and fast for test-driven visual rendering assertions. |

## Architecture Patterns

### PDF PNG Embedding Approach

1. **Grayscale (0), RGB (2), Indexed (3):**
   Pass `IDAT` stream straight through `/FlateDecode` using `/DecodeParms` to handle PNG's native predictor bytes.
   **Why:** Fastest path. Bypasses the need to decompress and re-compress in Elixir.

2. **Grayscale+Alpha (4) & RGBA (6):**
   PDF does not support Alpha channels in the main stream. We must extract the `IDAT`, inflate it via `:zlib`, apply inverse PNG predictor filters per scanline, separate the Alpha bytes from Color bytes, then re-compress both streams into a base `XObject` and an `SMask` `XObject`.
   **Why:** Required by ISO 32000-1 for transparency.

### Recommended Project Structure
```
lib/rendro/pdf/
├── writer.ex      # Updated to handle Image color_type and create SMask objects
└── png.ex         # New module for PNG chunk parsing and predictor un-filtering
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Compression | Custom LZ77/Deflate | `:zlib` | Erlang native implementation is heavily optimized; hand-rolling deflate in Elixir is slow and error-prone. |
| PDF Rendering Verification | Pure byte matching | `pdftoppm` | Byte substrings cannot tell if the sequence forms a valid viewable structure. Only rasterization proves visible pixels. |

## Common Pitfalls

### Pitfall 1: Retaining predictor bytes during Alpha separation
**What goes wrong:** The PNG pixels appear skewed or color-shifted when the `SMask` is applied, or the test crashes.
**Why it happens:** Each PNG scanline has a leading filter byte (0=None, 1=Sub, 2=Up, etc.). If you split the RGB and Alpha bytes without first un-filtering the entire image, the split operates on compressed diffs instead of raw pixels, destroying both streams.
**How to avoid:** Always run the complete un-filter step (handling Sub, Up, Average, Paeth) on the inflated stream before attempting to split alpha channels.

### Pitfall 2: Supplying entire PNG bytes to `/FlateDecode`
**What goes wrong:** PDF viewer shows a blank space where the image should be, but no error is reported.
**Why it happens:** `FlateDecode` only accepts the raw deflated payload.
**How to avoid:** Ensure only the `IDAT` chunks (concatenated) are passed.

## Code Examples

### Correct PNG XObject (No Alpha)
```elixir
color_space = {:name, "DeviceRGB"}
decode_parms = {:dict, [{"Predictor", 15}, {"Colors", 3}, {"BitsPerComponent", 8}, {"Columns", width}]}
entries = [
  {"Type", {:name, "XObject"}},
  {"Subtype", {:name, "Image"}},
  {"Filter", {:name, "FlateDecode"}},
  {"DecodeParms", decode_parms}
]
# stream payload is purely the concatenated IDAT chunks
```

### Correct PNG XObject (With Alpha)
```elixir
# Base Image
base_entries = [
  {"Filter", {:name, "FlateDecode"}},
  {"SMask", {:ref, smask_obj_num, 0}}
]
# SMask Image
smask_entries = [
  {"ColorSpace", {:name, "DeviceGray"}},
  {"Filter", {:name, "FlateDecode"}}
]
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `pdftoppm` | Visual UAT / Regression Tests | ✓ | 26.04.0 | ImageMagick (`convert`) |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ASSET-04 | PNG renders correctly via `pdftoppm` pixels | integration | `mix test test/rendro/pipeline/render_test.exs` | ✅ Wave 0 |
| ASSET-04 | Core PDF Image streams valid | unit | `mix test test/rendro/pdf/writer_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements, but `pdftoppm` needs to be wired into a new test case in `render_test.exs` to verify rasterization.

## Sources

### Primary (HIGH confidence)
- ISO 32000-1 Document Management — Portable document format (PDF spec)
- Poppler utilities documentation (`pdftoppm`)
- Elixir OTP `:zlib` documentation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Built-in Erlang tools and standard OS utils.
- Architecture: HIGH - Matches PDF specification requirements perfectly.
- Pitfalls: HIGH - Documented cases of PNG predictor bugs and alpha masking issues.

**Research date:** 2026-05-02
**Valid until:** 2026-06-01
