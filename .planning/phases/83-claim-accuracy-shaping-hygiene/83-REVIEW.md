---
phase: 83-claim-accuracy-shaping-hygiene
reviewed: 2026-06-10T00:00:00Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - guides/api_stability.md
  - lib/mix/tasks/rendro/api.gen.ex
  - lib/rendro/adapters/harfbuzz.ex
  - lib/rendro/error.ex
  - lib/rendro/pipeline/measure.ex
  - lib/rendro/public_api.ex
  - lib/rendro/text/bidi.ex
  - lib/rendro/text/script_tags.ex
  - lib/rendro/text/shaper.ex
  - lib/rendro/text/shaper/simple.ex
  - priv/public_api.json
  - priv/support_matrix.json
  - scripts/verify_docs.exs
  - test/docs_contract/public_api_contract_test.exs
  - test/docs_contract/script_support_claims_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - test/rendro/error_test.exs
  - test/rendro/i18n_test.exs
  - test/rendro/pipeline/measure_test.exs
  - test/rendro/public_api/manifest_test.exs
  - test/rendro/text/script_tags_test.exs
  - test/rendro/text/shaper_test.exs
  - test/test_helper.exs
  - mix.exs
findings:
  critical: 5
  warning: 7
  info: 6
  total: 18
status: issues_found
---

# Phase 83: Code Review Report

**Reviewed:** 2026-06-10
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Phase 83 makes `harfbuzz_ex` optional behind a new stable-tier `Rendro.Text.Shaper` behaviour with a pure-Elixir `Shaper.Simple` default, migrates to the `unicode` package, and wires `shaping_required` instructive errors through the measure stage. The behaviour/config seam, ScriptTags migration, and docs-contract lanes are structurally sound, and the no-auto-activation determinism invariant holds in `lib/` (config-only shaper selection; `Code.ensure_loaded?` is used only for error-message wording).

However, the review found five Critical defects. The most severe: `Shaper.Simple` blanket-rejects all embedded fonts, which breaks every embedded-font document — including the first-party branded recipes shipping bundled B612 fonts — on a default install without `harfbuzz_ex`. This directly contradicts the phase's own claim-accuracy artifacts (Simple's moduledoc and the `latin_and_cjk: supported, engine: Shaper.Simple` support-matrix row). The stable-tier `Rendro.Text.Shaper` moduledoc also documents a per-render override that does not exist anywhere in the codebase. The HarfBuzz adapter's cluster approximation can silently drop characters from rendered PDF bytes, and its SHA256-keyed temp-file cache is vulnerable to symlink/pre-planting attacks and stale-partial-file poisoning. The test suite masks the embedded-font regression because `test_helper.exs` auto-activates the HarfBuzz shaper via `Code.ensure_loaded?`, so the default code path users actually receive is never exercised end-to-end.

Cross-file facts verified during review: `Rendro.PDF.Font.text_width/3` and `has_glyph?/2` work identically for embedded and built-in fonts (`lib/rendro/pdf/font.ex:176-194`); the renderer writes `run.text` from measured lines (`lib/rendro/pdf/writer.ex:600-607`), so measured-run text loss becomes PDF byte loss; `lib/rendro/pipeline.ex:139-143` passes `%Rendro.Error{}` through without backfilling correlation metadata; the `unicode` dep returns lowercase atoms (`:arabic`, `:al`) as the new code expects; `Unicode.script(0x11C00)` returns `:bhaiksuki`, confirming the ScriptTags typo clause is dead code.

## Critical Issues

### CR-01: Shaper.Simple rejects ALL embedded fonts, breaking default-install rendering and contradicting the phase's own support claims

**File:** `lib/rendro/text/shaper/simple.ex:82-84`
**Issue:** `do_shape(%Rendro.PDF.Font{source: :embedded}, _text)` unconditionally returns `{:error, {:shaping_required, :embedded_font_requires_harfbuzz}}`. Consequences:

1. **Functional regression for every embedded-font user.** Pre-phase, embedded fonts were shaped via the then-mandatory HarfbuzzEx dep. Post-phase, a default install (no `harfbuzz_ex`, no `:shaper` config) fails to render *any* embedded font — including pure-Latin text. There is no technical necessity: `Rendro.PDF.Font.text_width/3` (`lib/rendro/pdf/font.ex:176`) computes advance widths from the `widths` map populated by `Font.embedded/1` (`font.ex:156-173`), exactly as the `:built_in` clause does. The cmap+advance-width path Simple claims to implement works for embedded fonts.
2. **First-party recipes break out-of-the-box.** `Rendro.Recipes.branded_invoice/1` (stable tier, `priv/public_api.json` line 307) and `Rendro.Recipes.Certificate` register embedded B612 fonts (`lib/rendro/recipes/branded_invoice.ex:123`, `lib/rendro/recipes/certificate.ex:151`). On a clean hex install these now return an error instructing the user to add a NIF dependency to render Latin text.
3. **Claim-accuracy violation (the phase's namesake).** Simple's moduledoc claims it "supports Latin, Greek, Cyrillic, Armenian, Georgian, Han, Hiragana, Katakana, and precomposed Hangul" — but Han/Kana/Hangul are only reachable via embedded fonts (built-in Type1 fonts carry no CJK glyphs), which Simple rejects. `priv/support_matrix.json` line 430-434 claims `latin_and_cjk: supported` with `engine: Rendro.Text.Shaper.Simple` — false for CJK and for embedded Latin under this code.

**Fix:** Shape embedded fonts in Simple via the same advance-width path, keeping only the complex-script gate:
```elixir
defp do_shape(%Rendro.PDF.Font{source: source} = font, text)
     when source in [:built_in, :embedded] do
  # widths map + default_width is populated for both sources (Font.embedded/1)
  ...existing grapheme/advance loop...
end
```
If embedded shaping must remain HarfBuzz-only, then the moduledoc, `latin_and_cjk` matrix row, and branded recipes must all change, and the error must name the actual script (see WR-01) — but that contradicts the recipes' stable contract, so shaping embedded fonts in Simple is the correct fix.

### CR-02: Stable-tier moduledoc documents a per-render `shaper:` override that does not exist

**File:** `lib/rendro/text/shaper.ex:13-15`
**Issue:** The Tier-1 `Rendro.Text.Shaper` moduledoc states:
```
## Per-render override

    Rendro.render(doc, shaper: Rendro.Adapters.HarfBuzz)
```
No such option exists. `Rendro.render_option` is `{:output, Path.t()} | {:deterministic, boolean()}` (`lib/rendro.ex:40`), nothing in `lib/rendro.ex` or `lib/rendro/pipeline.ex` reads a `:shaper` option, and `Shaper.impl/0` reads only `Application.get_env(:rendro, :shaper, ...)`. A user following the stable-tier docs passes a silently-ignored option and still gets `shaping_required` errors (or, worse, believes complex-script output is HarfBuzz-shaped when it is not). This is a documented stable API that was never implemented — a direct claim-accuracy failure on the new public surface.
**Fix:** Either implement the option (thread `opts[:shaper]` from `Rendro.render/2` through the pipeline into `Shaper.shape/3` calls, and add it to `render_option`), or delete the "Per-render override" section from the moduledoc before release. Add a docs-contract assertion that every option shown in stable moduledocs appears in `render_option`.

### CR-03: Silent character loss in `glyphs_to_cluster_runs` when a shaped run collapses to a single cluster

**File:** `lib/rendro/pipeline/measure.ex:704-718`
**Issue:** The `simple_path?` heuristic (`Enum.all?(clusters, &(&1 == 0))`) assumes all-zero clusters imply one-glyph-per-grapheme and zips graphemes with glyphs:
```elixir
Enum.zip(graphemes, glyphs)
```
Under the HarfBuzz adapter, `enrich_with_cluster` assigns clusters positionally (0, then byte offsets), so a multi-grapheme run that HarfBuzz fully ligates into **one glyph** (e.g., Arabic lam-alef "لا", or an "fi" liga in an embedded font) yields `clusters == [0]` → simple path → `Enum.zip(["ل", "ا"], [glyph])` keeps only the first grapheme. The dropped grapheme never appears in the measured line, and the writer renders `run.text` from measured lines (`lib/rendro/pdf/writer.ex:600-607`), so **characters silently vanish from the PDF bytes**. Reachable whenever an oversized token (split_graphemes path) contains a whole-run ligature under a configured HarfBuzz shaper. This violates the no-silent-degradation invariant in the worst possible way: data loss with `{:ok, ...}` returned.
**Fix:** Make the dispatch explicit instead of heuristic — e.g., require shapers to mark cluster semantics (a `cluster_semantics: :byte_offset | :none` callback or per-glyph guarantee), or in the simple path assert `length(glyphs) == length(graphemes)` and fall back to the byte-offset grouping branch (which preserves all text by slicing `run_text`) when counts differ.

### CR-04: HarfBuzz adapter cluster approximation assigns wrong clusters for ligatures, decompositions, and RTL; drops glyph advances; hardcodes `gid: 0`

**File:** `lib/rendro/adapters/harfbuzz.ex:54-66`
**Issue:** `enrich_with_cluster/2` zips HarfBuzz output glyphs positionally with logical grapheme byte offsets:
```elixir
Enum.zip(raw_glyphs, grapheme_offsets)
```
This is wrong in every case where shaping is non-trivial — i.e., exactly the cases the adapter exists for:
- **Ligatures (fewer glyphs than graphemes):** trailing offsets are discarded; cluster values map glyphs to the wrong text slices, so `glyphs_to_cluster_runs` (`measure.ex:722-744`) assigns ligature advances to the wrong substrings and line breaks can split inside what should be atomic clusters.
- **Decompositions/marks (more glyphs than graphemes):** `Enum.zip` truncates the *glyph* list — the extra glyphs' `x_advance` values are silently dropped, under-measuring line width and causing rendered overflow.
- **RTL scripts:** HarfBuzz returns Arabic/Hebrew glyphs in visual order; positional zip assigns the first visual glyph the first *logical* grapheme's offset, reversing every cluster-to-text mapping.
- `Map.put(:gid, 0)` discards real glyph IDs while the stable `glyph()` type documents `gid: non_neg_integer()` as meaningful, and any genuine cluster data HarfbuzzEx returns is overwritten by the approximation.

The phase context calls this the "byte-offset approximation"; as implemented it is not an approximation of clusters — it is positional indexing that is incorrect whenever glyph count ≠ grapheme count or direction is RTL.
**Fix:** Use HarfBuzz's own cluster values (HarfBuzz reports a cluster per glyph keyed to input offsets — preserve the field from the `HarfbuzzEx` glyph struct instead of overwriting it). If `harfbuzz_ex` 1.2 does not expose clusters, sum advances per run and do not fabricate per-glyph clusters; have `glyphs_to_cluster_runs` treat the run as a single atomic cluster rather than inventing wrong boundaries. Preserve the real glyph ID instead of `gid: 0`.

### CR-05: Temp-file font cache is vulnerable to symlink/pre-planting attacks, write races, and stale-partial-file poisoning

**File:** `lib/rendro/adapters/harfbuzz.ex:31-36`
**Issue:**
```elixir
font_path = Path.join(temp_dir, "rendro_font_#{hash}.ttf")
unless File.exists?(font_path), do: File.write!(font_path, bytes)
raw_glyphs = HarfbuzzEx.get!(font_path, text, :all)
```
Three distinct problems at a predictable name in the world-writable shared temp dir:
1. **Pre-planted/symlink file trusted blindly (CWE-377/CWE-59).** The filename is predictable for any known font (e.g., the bundled B612 fonts). On a multi-user host, an attacker can pre-create `rendro_font_<hash>.ttf` with arbitrary content; the existence check skips the write and feeds attacker-controlled bytes into the native HarfBuzz parser (NIF memory-safety exposure plus wrong metrics). A pre-created symlink alternatively redirects `File.write!` to an attacker-chosen path with the victim's permissions. Content is never verified against the hash that names the file.
2. **TOCTOU race between concurrent renders.** `File.write!` is not atomic. Render B can pass `File.exists?` while render A is mid-write and shape against a truncated font file.
3. **Stale poisoning.** If a write is interrupted (crash, disk full), the partial file persists and is trusted forever — every subsequent render with that font reuses the corrupt file, and nothing ever rewrites or cleans it.

**Fix:** Write to a private per-OS-user directory created with restrictive permissions, write to a random temp name, then atomically rename:
```elixir
dir = Path.join(System.tmp_dir!(), "rendro_fonts_#{:erlang.phash2(:os.getpid())}")
File.mkdir_p!(dir)
tmp = Path.join(dir, "#{hash}.#{System.unique_integer([:positive])}.tmp")
File.write!(tmp, bytes)
File.rename!(tmp, font_path)
```
And on cache hit, verify the existing file's SHA256 matches `hash` before use (rewrite atomically if not). Reject paths whose `File.lstat` reports a symlink.

## Warnings

### WR-01: `{:shaping_required, :embedded_font_requires_harfbuzz}` abuses the script slot, producing a nonsense instructive error

**File:** `lib/rendro/text/shaper/simple.ex:83`; `lib/rendro/error.ex:120-122, 261-267`
**Issue:** The error tuple's second element is documented/handled everywhere else as a script atom. `Rendro.Error.why/2` renders this reason as "Script :embedded_font_requires_harfbuzz requires a shaping adapter; Shaper.Simple cannot produce correct output for this script." and `next_step` says "Script :embedded_font_requires_harfbuzz requires a shaping adapter. Add {:harfbuzz_ex, ...}". The errors-as-product invariant requires the error to name the actual script; this names an implementation detail dressed as a script.
**Fix:** If CR-01's fix lands, this clause disappears. Otherwise use a distinct reason shape (e.g., `{:embedded_font_shaping_unavailable, font.logical_name}`) with dedicated `why/2` and `next_step/2` clauses.

### WR-02: shaping_required errors wrapped inside Measure lose render_id and correlation metadata

**File:** `lib/rendro/pipeline/measure.ex:84-88`
**Issue:** `measure_block` wraps shaping errors with `Rendro.Error.from_stage(:measure, reason)` using the default empty context, so `render_id`, `document_type`, and `deterministic` are all nil. The pipeline's `span` (`lib/rendro/pipeline.ex:139-140`) passes pre-built `%Error{}` structs through without backfilling `base_meta`. Every other stage error carries `render_id` (asserted in `test/rendro/error_test.exs:26`); shaping errors uniquely do not, breaking the "correlation metadata" promise in `Rendro.Error`'s moduledoc. The wrapping is also unnecessary: returning the raw tuple would let `span`'s `{:error, reason}` branch build the identical instructive error *with* `base_meta`.
**Fix:** Delete the two wrapping clauses in `measure_block`'s `else` block and return the raw `{:error, {:shaping_required, ...}}` tuple; the pipeline already wraps it at `pipeline.ex:142-143`. (The HYG-02 test calls `Measure.run/1` directly and would need to assert on the raw tuple instead.)

### WR-03: test_helper auto-activates HarfBuzz via `Code.ensure_loaded?`, so the default Simple path is never exercised end-to-end

**File:** `test/test_helper.exs:16-18`
**Issue:** `if Code.ensure_loaded?(HarfbuzzEx) ... Application.put_env(:rendro, :shaper, Rendro.Adapters.HarfBuzz)` means the entire suite — including `deterministic_test.exs` and the embedded-font measure tests — runs under the HarfBuzz adapter, not the `Shaper.Simple` default that hex consumers receive. This is precisely the `Code.ensure_loaded?` auto-activation pattern the phase banned from `lib/`, relocated into the test harness, and it is what masks CR-01: no end-to-end test renders an embedded font under default config. Determinism proofs are also now proofs about the HarfBuzz engine, not the shipped default.
**Fix:** Run the default suite with the default shaper; tag HarfBuzz-dependent tests (e.g., `@tag :harfbuzz`) and opt them into the adapter via per-test `Application.put_env` in their own `setup` (async: false), or a dedicated `mix test --include harfbuzz` lane. At minimum add one end-to-end test that renders an embedded Latin font with the shaper env deleted.

### WR-04: Misleading fix instruction when HarfBuzz is already configured (built-in font + complex script)

**File:** `lib/rendro/text/shaper/simple.ex:48-53`; `lib/rendro/adapters/harfbuzz.ex:24-27`
**Issue:** `Rendro.Adapters.HarfBuzz.shape/3` delegates `:built_in` fonts to `Shaper.Simple`, whose complex-script gate fires with a hint chosen by `Code.ensure_loaded?(HarfbuzzEx)` — which is true — so the user is told: "Add to your config: config :rendro, shaper: Rendro.Adapters.HarfBuzz". They already did. The actual fix is to register an embedded font for that script (built-in Type1 fonts cannot carry Arabic/Indic glyphs). The instructive error names the wrong next step, violating the errors-as-product invariant.
**Fix:** The hint should depend on the *configured* impl, not dep presence: when `Rendro.Text.Shaper.impl() != Rendro.Text.Shaper.Simple` (or when called via the HarfBuzz adapter's delegation), say "Script :arab requires an embedded font that contains its glyphs; built-in PDF fonts cannot render this script. Register one with register_embedded_font/3."

### WR-05: ScriptTags wrong/dead mappings: `:old_turkic → :otk`, `:bhaisuki` typo, `:byzantine_music`

**File:** `lib/rendro/text/script_tags.ex:35, 164, 188`
**Issue:**
- Line 35: `def to_opentype_tag(:old_turkic), do: :otk` — the OpenType script tag for Old Turkic is `orkh` (all OT tags are 4 characters; `otk` is not a registered tag).
- Line 188: `def to_opentype_tag(:bhaisuki), do: :bhks` — the Unicode script atom is `:bhaiksuki` (verified: `Unicode.script(0x11C00) == :bhaiksuki`), so this clause is unreachable dead code and Bhaiksuki text falls through to the passthrough, yielding the non-tag `:bhaiksuki`.
- Line 164: `:byzantine_music` is a Unicode block, not a script; `Unicode.script/1` never returns it — dead clause.
**Fix:** `def to_opentype_tag(:old_turkic), do: :orkh`; `def to_opentype_tag(:bhaiksuki), do: :bhks`; delete the `:byzantine_music` clause. Consider a generated test cross-checking every clause head against `Unicode.Script.scripts/0` to catch future typos.

### WR-06: Stable-tier `glyph()` contract is under-specified and already violated by both first-party implementations

**File:** `lib/rendro/text/shaper.ex:19-29`
**Issue:** The behaviour is Tier-1 stable, but:
- `cluster` semantics are undocumented (byte offset into the input? monotonic? zero?), yet `measure.ex:704-744` dispatches on exact cluster-value patterns ("all zero" vs "byte offsets"). A conforming third-party shaper returning, say, codepoint indices would be mis-measured or hit CR-03's data-loss path while fully satisfying the typespec.
- `Shaper.Simple` emits an undocumented `:name` key (`simple.ex:70`) that `Rendro.Adapters.HarfBuzz` relies on for `.notdef` detection (`harfbuzz.ex:39`), and the map-literal typespec `%{gid: ..., ...}` does not admit extra keys, so both implementations violate the declared `glyph()` type under Dialyzer semantics.
- The meaning of the `opts` keyword (the `:script` key the whole gate depends on) is not documented on the callback.
**Fix:** Document cluster semantics ("byte offset of the first input byte of the cluster, non-decreasing in logical order"), add optional `name` to the type (`optional(:name) => String.t()` via a non-literal map type), and document `opts` (`:script` OpenType tag atom) in the `@callback` doc.

### WR-07: Tier-1 claim for Shaper.Simple is vacuous — its only function is hidden from ExDoc and the manifest

**File:** `guides/api_stability.md:15`; `priv/public_api.json:470-474`; `lib/rendro/text/shaper/simple.ex:43-44`
**Issue:** `Simple.shape/3` has `@impl` and no `@doc`, so the compiler marks it hidden; the manifest records `"Elixir.Rendro.Text.Shaper.Simple": {"functions": []}` and ExDoc renders no functions. The guide's own rule is "Public ≡ what ExDoc renders" (api_stability.md:34), so the Tier-1 promise for Simple covers an empty surface, and the stable-tier @spec-coverage assertion (public_api_contract_test Assertion 5) is vacuous for it. Same for `Rendro.Adapters.HarfBuzz` (`functions: []`).
**Fix:** Add `@doc` to `Simple.shape/3` (and HarfBuzz's `shape/3`) so the stable implementation's entry point is actually public, then regenerate `priv/public_api.json` (the byte-equality test will force this).

## Info

### IN-01: HarfBuzz adapter telemetry leaks full document text

**File:** `lib/rendro/adapters/harfbuzz.ex:42-47`
**Issue:** The `[:rendro, :shaper, :missing_glyph]` event metadata includes the complete `text` being shaped (and the temp font path). Documents routinely contain PII; telemetry handlers (loggers, APM exporters) will receive it.
**Fix:** Emit a redacted sample or just the missing grapheme count/script; drop raw `text` from metadata.

### IN-02: Cached temp font files are never cleaned up

**File:** `lib/rendro/adapters/harfbuzz.ex:33-34`
**Issue:** One file per distinct font hash accumulates in the temp dir for the host's lifetime; nothing removes them.
**Fix:** Note the cache location in the adapter moduledoc and/or clean files older than N days on startup (combine with CR-05's private-directory fix).

### IN-03: script_support_claims_test asserts on raw JSON text with regexes; evidence-length check covers only `arabic`

**File:** `test/docs_contract/script_support_claims_test.exs:26-31`
**Issue:** The `evidence_deferred` minimum-length assertion is applied only to the `arabic` row; `hebrew_rtl`/`devanagari`/`thai` rows could regress to empty reasons undetected. Regex-over-text is also brittle against reformatting.
**Fix:** `Jason.decode!` the matrix and assert `String.length(entry["evidence_deferred"]) >= 40` for all four deferral rows.

### IN-04: split_graphemes tags an entire font run with the script of its first bidi run only

**File:** `lib/rendro/pipeline/measure.ex:634-639`
**Issue:** A font-homogeneous run mixing scripts (e.g., Latin+Greek) passes only the first run's script to the shaper. Currently benign — `measure_text_into_runs` gates complex scripts earlier and both shapers ignore script except for gating — but it is a latent mismatch with the comment "Use the bidi script for the run text".
**Fix:** Itemize the font run by bidi runs (as `measure_text_into_runs` does) before shaping, or document why first-run script is sufficient.

### IN-05: Shaping-hint text duplicated in two modules and dependent on `Code.ensure_loaded?`

**File:** `lib/rendro/text/shaper/simple.ex:48-53`; `lib/rendro/error.ex:261-267`
**Issue:** The same two-branch hint (dep present vs absent) is implemented independently in Simple and in `Error.next_step/2`; they can drift. Error wording also varies with lockfile contents — permitted by the stability guide (wording is excluded from SemVer), but worth centralizing.
**Fix:** Extract a single `shaping_hint/1` helper (e.g., on `Rendro.Text.Shaper`) used by both.

### IN-06: public_api.json byte-equality contract fails in environments where harfbuzz_ex is absent or its NIF fails to build

**File:** `priv/public_api.json:38-42`; `test/docs_contract/public_api_contract_test.exs:25-79`
**Issue:** The checked-in manifest includes `Elixir.Rendro.Adapters.HarfBuzz`. A contributor whose `harfbuzz_ex` NIF fails to compile (platform without the toolchain) gets a fresh manifest without that module and a byte-equality failure pointing them at `mix rendro.api.gen` — which would then produce a manifest diff that must not be committed. The failure message does not mention the optional-dep cause.
**Fix:** Have the drift-diff `flunk` message note that missing entries for `Rendro.Adapters.*` conditional modules usually mean an optional dep is unavailable locally, not real drift.

---

_Reviewed: 2026-06-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
