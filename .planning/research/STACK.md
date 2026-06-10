# Stack Research — v2.6 Public Launch & Adoption Bootstrap

**Researched:** 2026-06-10
**Confidence:** HIGH (dependency facts verified against mix.exs, hex.pm APIs, and upstream repos)

## Dependency decisions

### harfbuzz_ex — hard dep → optional dep (Phase 83, the headline stack change)

- Today: `{:harfbuzz_ex, "~> 1.2"}` and `{:unicode_data, "~> 0.8.0"}` are **non-optional** in `mix.exs` (~lines 45-46). harfbuzz_ex is "Elixir binding for Harfbuzz using Rustybuzz as NIF, with RustlerPrecompiled" (MIT, maintainer jkwchui, ~755 total downloads, 1 star, 23 commits — **bus-factor-1**). Depends on `rustler ~> 0.30`, `rustler_precompiled ~> 0.7`, `nimble_pool ~> 1.1`.
- Target: `optional: true` + `Code.ensure_loaded?` activation behind a `Rendro.Text.Shaper` behaviour (idiomatic Elixir pattern: Ecto.Adapter / Tesla adapters / ExAws HTTP clients). Core ships `Shaper.Simple` (pure Elixir, cmap+advance widths, Latin-ish — current capability without shaping).
- Risk hedge: harfbuzz_ex is a thin MIT wrapper over rustybuzz; forking/vendoring under the project org is cheap insurance if upstream stalls. rustybuzz itself is maintained **under the harfbuzz org**, pure Rust, matches HarfBuzz v10.x behavior (2221/2252 of HarfBuzz's shaping tests).
- Determinism: same crate version → identical shaping output on every platform (pure Rust, no system-lib variance). Shaper version bumps can legally change glyph output (HarfBuzz fixes alter glyph streams between versions) — treat as deliberate golden-regeneration events.
- Hygiene: the temp-file dance in `lib/rendro/text/shaper.ex:32-38` (writes font bytes to SHA256-keyed temp file per call) should move to harfbuzz_ex's in-memory/pooled API.

### unicode_data 0.8.0 → kipcole9 ex_unicode stack (Phase 83)

- `unicode_data 0.8.0` last released **March 2019** (maintainer jbowtie) — Unicode ~11/12-era property tables; missing newer script tags and bidi classes.
- Replacement: actively maintained `ex_unicode` / `unicode_string` family (kipcole9 / elixir-unicode org) — exposes Bidi_Class, Bidi_Mirrored, Bidi_Paired_Bracket, UAX #29 segmentation, UAX #14 line-break classes. Also positions a future pure-Elixir UAX #9 implementation for v2.7.

### pdfium-cli — pinned render tool for the raster lane (Phase 85)

- klippa-app/pdfium-cli: WASM build embeds pdfium inside a single static binary via wazero — strongest determinism story of any rasterizer surveyed. Already on PATH in the advisory `viewer-evidence-live-proof` lane; `Rendro.Adapters.Pdfium` already wraps `info`/`form`/`--version`.
- Add `render/2` wrapping `pdfium render <pdf> <out> --dpi N --file-type png`. Pin by release version + sha256. Same renderer binary + embedded fonts + same DPI → byte-stable PNGs **on a pinned CI environment only** (cross-OS rasterization deltas are the universally documented footgun — see PITFALLS.md).

### Node/pdfjs-dist — DEFERRED

- A `Rendro.Adapters.PdfJs` lane (Mozilla's `examples/node/pdf2png` on `@napi-rs/canvas`, lockfile-pinned) is feasible and the matrix already reserves `viewer_kind: "pdfjs-dist"` — but it brings a Node toolchain into CI. Defer; pdfium lane covers the gallery need. Revisit only if pdfjs-row re-testing becomes valuable post-launch.

### Release automation — NO new tooling

- Survey of real Elixir libs (inspected workflows): ecto/phoenix/oban/req/jason have **no hex publish workflow at all**; absinthe publishes on GitHub release; ash uses local `mix git_ops.release`; tesla is the rare release-please example (manifest mode, `release-type: elixir`, **requires a PAT** because GITHUB_TOKEN-created tags don't trigger downstream workflows).
- Verdict: keep the existing proof-gated manual tag pipeline. If version-sync pain ever materializes, `git_ops` (zero new CI credentials, conventional-commit changelog, human pulls the trigger) is the BEAM-native answer — not release-please.

### Benchmark/comparison harness (Phase 87)

- Pure mix tasks + checked-in scripts; measure cold start, RSS, container image size, dependency count vs `chromic_pdf` (~1M downloads), `pdf_generator` (wkhtmltopdf, archived upstream), Typst CLI. No new runtime deps; benchmark deps (if any) dev/test-only.

### Livebook lane (Phase 87)

- ExDoc natively supports "Run in Livebook" badges on extras. Kino for inline PDF preview. Notebook executed in CI so it can't rot. No runtime deps added to the library.

## Version/pin summary

| Component | Action | Pin discipline |
|---|---|---|
| harfbuzz_ex ~> 1.2 | make `optional: true` | exact-version golden tests; bumps = deliberate re-bless |
| unicode_data 0.8.0 | remove | replaced by ex_unicode family |
| ex_unicode / unicode_string | add (core) | maintained, pure Elixir |
| pdfium-cli | CI tool (not a dep) | release version + sha256 pin recorded in evidence |
| pdfjs-dist / Node | deferred | — |
| release-please / git_ops | not adopted | — |
