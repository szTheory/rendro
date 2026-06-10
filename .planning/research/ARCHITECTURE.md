# Architecture Research — v2.6 Public Launch & Adoption Bootstrap

**Researched:** 2026-06-10
**Confidence:** HIGH (all integration points verified by direct source inspection)

## Integration map (per phase)

### Phase 83 — Shaper behaviour seam

- `Rendro.Text.Shaper` (`lib/rendro/text/shaper.ex`) currently calls `HarfbuzzEx.get!(font_path, text, :all)`, writing embedded-font bytes to a SHA256-keyed temp file per call (lines ~32-38). `Rendro.Text.Bidi` (`lib/rendro/text/bidi.ex`) is a script/direction run itemizer via `UnicodeData.Script` — **not** UAX #9 (no embedding levels, bracket pairing, mirroring, or visual reordering).
- Target shape (idiomatic optional-adapter pattern, mirrors existing Poppler/qpdf/pyHanko adapters):
  - `Rendro.Text.Shaper` becomes a **behaviour**: `shape(font, text, opts) :: {:ok, [glyph]} | {:error, term}` with glyphs carrying `gid, cluster, x_advance, y_advance, x_offset, y_offset`.
  - Core ships `Shaper.Simple` — pure Elixir, cmap + advance widths (current no-shaping capability, keeps Latin-ish behavior byte-identical).
  - `Shaper.HarfBuzz` activates when optional `harfbuzz_ex` is loaded (`Code.ensure_loaded?`); selection via config/document opts.
  - Complex-script codepoints + no shaping adapter ⇒ deterministic instructive error (`{:error, {:shaping_required, script}}`) — iText pdfCalligraph seam pattern, never silent broken output (the Prawn failure mode).
- **Bug fix**: `lib/rendro/pipeline/measure.ex` `split_graphemes` (~601-650) shapes one grapheme at a time (`Shaper.shape(font, grapheme)` at ~607) — destroys cross-grapheme contextual forms/kerning. The run path (`measure_text_into_runs`, ~658-688) shapes whole sub-runs and is the correct model: shape runs, break at HarfBuzz cluster boundaries.
- Byte-identical output for existing Latin fixtures is the exit criterion (this is a refactor + fence, not a behavior change).

### Phase 84 — `%Rendro.Path{}` primitive

- `Rendro.Block.content` is an open union (Text/Table/FormField/Link/Image/`term()`) — a declarative Path element slots in with: one `render_block` clause in the writer, one measure clause (intrinsic bbox, **no fragmentation**), no font/image collection.
- The writer already emits the full operator set inside form-field appearance XObject streams (`lib/rendro/pdf/writer.ex` ~1278-1410: `q/Q`, `re`, `f`, `S`, `RG`, `rg`, `w`) — this is promotion of an internal capability to an authored element, not new writer territory. Numeric formatting already goes through `format_num` → byte determinism inherited.
- Struct shape: `%Rendro.Path{ops: [{:move,x,y}, {:line,x,y}, {:curve,...}, {:rect,...}, {:rounded_rect,...}], stroke: %{color, width, dash, cap, join}, fill: color}`. PDF operators needed: `m l c v y h re` (construction), `S s f f* B B* b n` (painting), `w J j M d RG rg q Q` (state).
- **Defer with explicit support-matrix `unsupported`/deferral entries**: transformations (`cm`), clipping (`W`), gradients.
- Table borders/rules/header-band: option on the existing table surface rendering via the same operators; Certificate `border:` frame derives coordinates from template geometry (existing v2.4 discipline — no hardcoded A4).

### Phase 85 — Raster lane

- Extend `Rendro.Adapters.Pdfium` (`lib/rendro/adapters/pdfium.ex` — configurable finder + command runner with test fakes already) with `render/2` wrapping pdfium-cli `render --dpi N --file-type png`.
- Golden-PNG harness (Typst model): small refs (≤20 KiB, 72–96 dpi), committed in-repo; **bless only via containerized/pinned-CI command, never dev laptops**; hash-equality fast path; pixelmatch-style perceptual tolerance only during deliberate renderer-version bumps, then re-bless.
- CI: advisory lane (extends the existing `viewer-evidence-live-proof` advisory context pattern in `priv/guardrails/required_status_checks.json`) — never a required engine lane.
- Evidence vocabulary: new `viewer_kind: "pdfium-render"` distinct from GUI observation; evidence frontmatter gains `renderer`, `renderer_version`, `dpi`, `png_sha256`. Renderer upgrades = evidence re-recording events (matrix already models `recorded_at` + 180-day staleness).
- **Claim boundary**: raster evidence upgrades `chrome_pdfium`-class rows and adds renderer-class claims; Adobe/Preview rows remain structural proxies — automation must not convert them into GUI-viewer proof (guard via vocabulary + existing docs-contract lint mechanism).

### Phase 86 — Gallery/manual pipeline

- New mix task (e.g. `mix rendro.gallery`) renders the five recipes deterministically → `Pdfium.render/2` → PNGs under `priv/`/docs assets; a docs-contract lane asserts committed image hashes match regenerated output (same lockstep pattern as existing docs-contract lanes).
- `manual.pdf`: a Rendro document (built with recipes + Path + page primitive) rendered with `deterministic: true`; SHA-256 published in README/guide; CI re-renders and compares hash. Fold the phase-29-era `mix rendro.visual_uat` into this harness or retire it.

### Phase 87 — Benchmarks + Livebook

- Benchmark harness as checked-in scripts (separate dir or `bench/`), results committed; comparison guide is a HexDocs extra bounded by a docs-contract test (claims must cite checked-in results — existing pattern).
- `.livemd` executed in CI (advisory lane, same isolation discipline as `example-phoenix`: graph-disconnected, never gating engine lanes).

### Phase 88 — Launch + instrumentation

- ADOPTION.md ledger in `.planning/` or repo root; GitHub Discussions + issue templates; demand-gate thresholds recorded in PROJECT.md. Mobile evidence rows via the existing `mix rendro.viewer_evidence` recipe — zero new machinery.

## Deferred designs (recorded so future milestones don't re-derive)

### TOC without fixpoint (future)
- Anti-models: LaTeX .aux rerun oscillation; ReportLab `multiBuild(maxPasses=10)` raising IndexError; Typst converge-cap-5 shipping stale numbers. All data-dependent failure modes — anathema to the determinism brand.
- Rendro design: paginate emits `anchor_id → page_number` map (it already knows pages); TOC rows are **fixed-height, one line per entry, ellipsis overflow**, so TOC page count = `ceil(entries / rows_per_page)` is computable **before pagination**; `{{toc_page:<anchor>}}` substitutes in the existing `replace_page_numbers/3` site (`lib/rendro/pipeline/paginate.ex`, `apply_page_template/4`). D-10 (no re-measure after substitution) is honored via a **fixed-width page-number column** sized for max digits; dot leaders as a Path dashed line, not width-dependent glyph runs. Headline claim: "single-pass, no fixpoint, no rerun." Free byproduct: `/Outlines` bookmarks. fpdf2's TOC bug list (#372, #548, #1312, #1343) is the regression-test plan.

### Charts (future)
- `%Rendro.Chart{}` fixed-size non-fragmenting block lowering to Path+Text at compose/measure; Decimal-based tick selection (float "nice numbers" are the determinism hotspot); never SVG import.

### v2.7 shaping slice (future, demand-gated)
- Pure-Elixir UAX #9 in core (properties from ex_unicode; UCD BidiTest.txt/BidiCharacterTest.txt conformance suite ~490k cases); cluster-aware line breaking; visual reordering at line level per UAX #9; ToUnicode from cluster maps; Arabic+Hebrew with named fonts (Noto Naskh Arabic, Noto Sans Hebrew); per-script matrix rows (`supported` vs `explicit_deferral` for Devanagari/Thai/vertical); viewer-evidence checklists extended with text-extraction order + RTL copy-paste (where RTL PDFs actually fail in the wild); cross-platform byte-identical CI proof.
