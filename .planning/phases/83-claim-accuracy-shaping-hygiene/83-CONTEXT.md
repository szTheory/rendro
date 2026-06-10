# Phase 83: Claim-Accuracy & Shaping Hygiene - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Restore the "pure Elixir core / no hard NIF dependencies" claim to truth before any launch content ships: `harfbuzz_ex` becomes an optional dependency behind a public `Rendro.Text.Shaper` behaviour (core ships pure-Elixir `Shaper.Simple`), complex scripts with no shaping adapter fail with a deterministic instructive error (never silent broken output), the per-grapheme shaping bug in `split_graphemes` is fixed to shape runs and break at cluster boundaries, dead `unicode_data 0.8.0` is replaced by the maintained `ex_unicode` stack, and `priv/support_matrix.json` gains `explicit_deferral` rows for complex scripts. Requirements: HYG-01..05. Must merge before Phase 88 (launch execution).

</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched by parallel advisor agents (minimal_decisive calibration) and locked per the user's research-first decision-handling profile. Full comparison tables in `83-DISCUSSION-LOG.md`.

### Shaper selection mechanism (HYG-01)
- **D-01:** Selection is **explicit, never auto-detected**: `config :rendro, shaper: <module>` (application config) defaulting to `Rendro.Text.Shaper.Simple`, with a per-render `shaper:` option override threaded through the existing `doc.options[:render]` path. Precedence: per-render opt > app config > `Shaper.Simple` default.
- **D-02:** No `Code.ensure_loaded?` auto-activation for output-affecting behavior — PDF bytes must depend only on code + config, never on lockfile contents. The HarfBuzz adapter module is compile-gated behind `Code.ensure_loaded?(HarfbuzzEx)` (so it exists only when the optional dep is present), but it never silently becomes the active shaper.
- **D-03:** The friction of explicit config is neutralized via errors-as-product: when `Shaper.Simple` hits a requires-shaping script AND `harfbuzz_ex` is loaded but not configured, the error message prints the exact fix line (`config :rendro, shaper: Rendro.Adapters.HarfBuzz`).

### Public surface shape & stability tier (HYG-01)
- **D-04:** **Split layout**: `Rendro.Text.Shaper` (behaviour, tier `:stable`) + `Rendro.Text.Shaper.Simple` (tier `:stable`, pure-Elixir core) + `Rendro.Adapters.HarfBuzz` (tier `:adapter`, optional-dep implementation). This keeps the namespace-defined Tier-2 contract in `guides/api_stability.md` intact verbatim (Tier-2 = `Rendro.Adapters.*`) and matches HYG-01's own "HarfBuzz adapter" wording.
- **D-05:** Behaviour callback locked at `shape(font, text, opts) :: {:ok, [glyph]} | {:error, term}` with glyphs carrying `gid, cluster, x_advance, y_advance, x_offset, y_offset`. The behaviour is `:stable` because it is the seam third-party shaping engines implement and the v2.7 demand gate points at — define `@type glyph` and full `@spec`s now (stable tier requires them).
- **D-06:** Mechanical churn path (verified by research agent): remove `Rendro.Text.Shaper` from the `hidden_modules` list in `test/docs_contract/public_api_contract_test.exs` (line ~89), add `@moduledoc tags:` + `@spec`s, add the HarfBuzz adapter file to `Rendro.PublicApi`'s `@adapter_files` conditional-compile list, flip mix.exs to `{:harfbuzz_ex, "~> 1.2", optional: true}`, run `mix rendro.api.gen` to regenerate `priv/public_api.json`, update tier lists in `guides/api_stability.md`.

### Complex-script gate policy (HYG-02)
- **D-07:** The runtime gate uses a **principled requires-shaping script set** (curated list derived from HarfBuzz's complex-shaper dispatch families), NOT just the four scripts named in the success criterion. Gating only four scripts would re-create Prawn-style silent garbage for Bengali, Tamil, Khmer, Myanmar, Syriac, etc. Curated set: joining scripts (Arabic, Syriac, N'Ko, Mongolian), Hebrew (RTL — Rendro has no UAX #9 reordering), Indic (Devanagari, Bengali, Gurmukhi, Gujarati, Oriya, Tamil, Telugu, Kannada, Malayalam, Sinhala), SEA (Thai, Lao, Khmer, Myanmar), Tibetan. Passing: Latin, Greek, Cyrillic, Armenian, Georgian, Han, Hiragana/Katakana, precomposed Hangul.
- **D-08:** Gate lives **inside `Shaper.Simple`**, keyed on the Bidi run's script tag passed via `shape/3` opts — single classification source (Bidi itemizer), no double-classification drift during the ex_unicode migration. `Rendro.Adapters.HarfBuzz` never gates (correct seam semantics).
- **D-09:** Error envelope: `{:error, {:shaping_required, script}}` flows through measure's existing `reduce_while` tuple-halt path (same as `{:error, {:unsupported_glyph, grapheme}}`), wrapped at the stage boundary via `Rendro.Error.from_stage(:measure, ...)` with details naming the script and the fix. The two call sites in `measure.ex` that hard-match `{:ok, glyphs} = Rendro.Text.Shaper.shape(...)` (lines ~607, ~667) must become `case`/`with` so the error propagates instead of crashing with MatchError.
- **D-10:** HYG-05's matrix records `explicit_deferral` rows for the four named script families (Arabic, Hebrew/RTL, Devanagari, Thai) as required; the runtime gate being broader than the matrix is the honest direction of mismatch.

### Golden-test posture for the cluster-boundary fix (HYG-03)
- **D-11:** **Uniform fix, no two-path fork**: rewrite `split_graphemes` to shape runs and break at cluster boundaries everywhere — do NOT keep a bug-compatible per-grapheme path for `Shaper.Simple`. `Shaper.Simple` is pure cmap+advance with no cross-grapheme effects, so run-shaping is byte-identical on the pure-Elixir path by construction; the only goldens that can shift are HarfBuzz-shaped ones where old per-grapheme widths were objectively wrong.
- **D-12:** Add a property test asserting per-grapheme widths == per-run widths under `Shaper.Simple` — proving the byte-freeze rather than engineering it.
- **D-13:** Any HarfBuzz-path golden shifts AND any ex_unicode run-itemization shifts are consolidated into **one deliberate, changelogged re-bless event** for the phase (not two). Before re-blessing, run run-itemization diffs on existing fixtures (PITFALLS #3) so every change is deliberate and documented.

### Claude's Discretion
- Exact module/file organization within the locked split layout (e.g., where the requires-shaping script list constant lives).
- Telemetry event naming for the new seam (existing `[:rendro, :shaper, :missing_glyph]` event should be preserved or deliberately migrated).
- Edge-script pass/fail calls not in the curated list (Thaana, Ethiopic, Hangul jamo) — document each call in the support matrix or code comments.
- Whether `Shaper.HarfBuzz`'s temp-file caching strategy (SHA256-keyed temp files) is kept or improved during the move to `Rendro.Adapters.HarfBuzz` — behavior-preserving either way.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone research (decisive design input)
- `.planning/research/ARCHITECTURE.md` §"Phase 83 — Shaper behaviour seam" — verified integration map: current shaper internals, target behaviour shape, bug-fix model, byte-identical exit criterion
- `.planning/research/PITFALLS.md` §"Phase 83" items 1–4 — behavior drift, silent degradation, ex_unicode reclassification, per-grapheme fix consequences; item 18 (launch ordering)

### Contract surfaces this phase must update
- `test/docs_contract/public_api_contract_test.exs` — pins `Rendro.Text.Shaper` as hidden (line ~89); byte-compares `priv/public_api.json`; enforces tier tags + stable-tier `@spec`s
- `priv/public_api.json` — public API manifest, regenerate via `mix rendro.api.gen`
- `guides/api_stability.md` — two-tier SemVer contract; Tier-2 defined by `Rendro.Adapters.*` namespace
- `priv/support_matrix.json` — `explicit_deferral` row vocabulary (named reason required), schema-validated

### Code under change
- `lib/rendro/text/shaper.ex` — current hidden module calling `HarfbuzzEx.get!` (becomes behaviour + Simple)
- `lib/rendro/text/bidi.ex` — script/direction run itemizer on `UnicodeData.Script` (lines 64–83; migrates to ex_unicode)
- `lib/rendro/pipeline/measure.ex` — `split_graphemes` (~601), `measure_text_into_runs` (~658), two `{:ok, glyphs} =` hard-matches (~607, ~667), `{:error, {:unsupported_glyph, _}}` precedent (~633)
- `lib/rendro/public_api.ex` — `recompile_conditional_adapters/0` / `@adapter_files` machinery for optional-dep adapters
- `lib/rendro/error.ex` — `from_stage/3` stage-boundary error wrapping
- `mix.exs` — `{:harfbuzz_ex, "~> 1.2"}` (line 45, becomes `optional: true`), `{:unicode_data, "~> 0.8.0"}` (line 46, replaced by ex_unicode)
- `lib/rendro/adapters/accrue.ex` — compile-gating precedent (`Code.ensure_loaded?`) for optional library adapters

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.PublicApi.recompile_conditional_adapters/0` + `@adapter_files`: existing machinery that makes conditional adapters (Phoenix, Oban) appear in the manifest — the HarfBuzz adapter slots straight in.
- `Rendro.Text.Bidi` run itemizer: already tags every run with a script atom — the single classification source for the requires-shaping gate.
- Measure-stage tuple-error propagation (`reduce_while` halt + `Rendro.Error.from_stage/3`): the `{:shaping_required, script}` error reuses this path exactly like `{:unsupported_glyph, grapheme}`.
- Existing first-party adapters (Poppler, qpdf, pyHanko, Pdfium) under `lib/rendro/adapters/`: naming, config-seam, and test-fake conventions to mirror.

### Established Patterns
- Optional-adapter philosophy: explicit seams, never silent magic; tool adapters use `Application.get_env` config seams; library integrations compile-gate via `Code.ensure_loaded?`.
- Errors-as-product: structured instructive errors naming the fix; tuple errors in pipeline stages, structured `ArgumentError` at recipe boundaries.
- Docs-contract lockstep: claims bounded to `priv/support_matrix.json` + manifest byte-comparison; drift fails CI with instructive two-list diffs.
- Determinism discipline: any deliberate output change is a documented re-bless event with changelog note.

### Integration Points
- `Rendro.render/2` opts threading (`lib/rendro.ex` ~83–89) — where the per-render `shaper:` opt enters.
- Phase 87 (comparison page) and Phase 88 (launch) depend on this phase's claim accuracy; Phase 83 has no upstream dependencies and can run parallel to 84/85.

</code_context>

<specifics>
## Specific Ideas

- Error message for loaded-but-unconfigured HarfBuzz must print the exact config line — the iText pdfCalligraph seam precedent (error + named add-on fix), explicitly avoiding Prawn's decade of silent broken Arabic.
- "Pure Elixir core" acceptance shape: a project without `harfbuzz_ex` in its deps compiles and renders Latin PDFs with zero NIF-compilation steps and zero config.

</specifics>

<deferred>
## Deferred Ideas

- Full complex-script shaping (UAX #9 bidi, visual reordering, Arabic/Hebrew vertical slice) — conditional v2.7 behind the LNCH-03 demand gate; design recorded in `.planning/research/ARCHITECTURE.md` §"v2.7 shaping slice".
- PDF.js render lane re-testing pdfjs deferral rows — recorded v2 requirement.
- None raised during discussion beyond the above — scope stayed within phase boundary.

</deferred>

---

*Phase: 83-Claim-Accuracy & Shaping Hygiene*
*Context gathered: 2026-06-10*
