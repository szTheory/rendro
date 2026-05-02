---
status: complete
phase: 29-branded-recipes-docs-and-proof-closure
source: [29-VERIFICATION.md, multimodal-claude-direct]
started: 2026-05-01T21:14:00Z
updated: 2026-05-01T21:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Branded preview visual quality
expected: |
  Start the Phoenix example (`cd examples/phoenix_example && mix phx.server`),
  open `http://localhost:4000/branded/preview`, and visually inspect the rendered
  branded invoice PDF. The logo renders, the header uses the embedded branded
  font, and the overall branded invoice layout looks readable and intentional.
result: issue
severity: major
verifier: Claude Opus 4.7 (direct multimodal inspection of 29-branded-preview.png; pipeline rendered via mix rendro.visual_uat)
artifact: 29-branded-preview.png
verdict:
  logo_present: false
  logo_notes: "Top-left logo region (x:72 y:72, 64x64pt) is completely blank. The PDF metadata has :company_logo registered and /XObject markers exist, but no logo pixels appear on the rendered page."
  header_uses_branded_font: true
  header_notes: "Header text 'Rendro, Inc.' / 'Invoice #INV-...' is rendered in what looks like B612 (or another sans-serif distinct from body font). This part is OK."
  layout_intentional: false
  layout_notes: "Header 'Invoice #INV-2026-001' wraps awkwardly across THREE lines: 'Invoice', '#INV-2026-0', '01'. The invoice id breaks mid-token at the digit boundary, indicating the header text exceeds the available width given font size 18 in the configured header region (width: 371.28pt minus the indent for the wrapped first line)."
  overall_pass: false
  overall_notes: "Two real defects in the branded recipe: missing logo render and broken header wrap. Header font is branded as expected. Captured PNG is committed locally as 29-branded-preview.png."

## Summary

total: 1
passed: 0
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Branded invoice preview renders the registered logo image visibly in the logo region of page 1."
  status: deferred
  deferred_to: "Phase 30: Visually Correct PNG Image Rendering"
  reason: "Logo region (x:72 y:72, 64x64pt) is blank in the rendered PNG; :company_logo is registered in asset_registry and /XObject markers are present in the PDF binary, but no visible logo on the page. Root cause is in the core PDF writer, not the branded recipe — fix scope (rewrite PNG XObject stream encoding, add rasterize-and-decode regression class) is too large for phase 29 closure and routes to phase 30 within the same v1.2 milestone."
  severity: major
  test: 1
  artifacts: [29-branded-preview.png]
  missing: []
  root_cause: |
    lib/rendro/pdf/writer.ex:238-258 (build_image_objects/2) writes the entire raw PNG file
    bytes into the Image XObject stream while declaring /Filter /FlateDecode. PDF requires
    a FlateDecode stream to contain raw zlib-compressed RGB pixel samples (with optional
    /DecodeParms /Predictor for PNG-style predictor filtering), NOT the PNG file format
    itself. PDF readers attempt to inflate the PNG container as a zlib stream, fail or
    produce garbage, and silently skip drawing the image — leaving the logo region blank.
    The Do operator IS emitted, the XObject resource IS wired, /Width/Height/Subtype/Filter
    metadata IS correct, the byte-substring tests all pass, but the bytes inside the stream
    are wrong. JPEG happens to work incidentally because raw JPEG file bytes ≈ DCTDecode-
    filtered data; PNG is the only failing path today.
  fix_direction: |
    In build_image_objects/2: parse PNG (IHDR + concatenate IDAT chunks + inflate + strip
    per-scanline predictor bytes) to obtain raw RGB samples, then re-deflate; OR pass IDAT
    data through with /DecodeParms << /Predictor 15 /Colors N /BitsPerComponent 8
    /Columns W >>. Also handle PNG color type → /ColorSpace (RGB / RGBA→SMask /
    Gray / Indexed); current hard-coded /DeviceRGB will mismatch RGBA inputs.
  scope_note: |
    This is a CORE LIBRARY bug in the PDF writer, not a recipe defect. Affects ALL PNG
    image rendering across the entire rendro library. Branded recipe is the first user-
    facing surface where the bug becomes visible because no prior phase rasterized the
    output. Existing structural-substring tests cannot catch this class of bug — gap fix
    must include a rasterize-and-decode regression test (e.g. via pdftoppm + simple
    pixel-sampling) to prevent regression.

- truth: "Branded invoice header text fits the header region without breaking the invoice id mid-token."
  status: closed
  reason: "Fixed in gap-closure plan 29-08. Title and invoice id were split into independent blocks, ensuring the id renders on a single line without mid-token grapheme splits."
  severity: major
  test: 1
  artifacts: [29-branded-preview.png]
  missing: []
  root_cause: |
    lib/rendro/pipeline/measure.ex:354-395 (split_graphemes/4) is the only overflow strategy
    for a non-whitespace token wider than block width — it greedy-splits at whatever grapheme
    boundary first exceeds the width. Given branded_invoice.ex:123 width: 260, font size 18,
    B612 Regular metrics, the chunk "#INV-2026-001" alone exceeds 260pt, so split_chunk falls
    through to split_graphemes and produces "#INV-2026-0" + "01". Worse, this broken layout
    is currently LOCKED IN by test/rendro/recipes/branded_invoice_test.exs:148 which asserts
    `length(tl(lines)) > 1` — the test treats the broken wrap as expected behavior.
  fix_direction: |
    Recommended (minimum impact): widen the header block from 260 to 340 in
    branded_invoice.ex:123, and update branded_invoice_test.exs:148 to assert the id stays
    intact on a single line (e.g. `assert "Invoice #INV-2026-001" in lines` or
    `assert length(lines) == 2` for title + id-only).
    Alternative: split the title and id into two stacked Rendro.block fragments so the id
    sizes itself.
    Not recommended for this gap fix: adding break_inside_word: false to Rendro.Text — correct
    long-term but oversized for a single demo recipe fix.
  scope_note: |
    Recipe + test fix only. No core writer/measure changes. ~5-line fix plus updated test
    assertion.
