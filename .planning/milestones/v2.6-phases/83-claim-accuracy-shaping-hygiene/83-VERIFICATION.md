---
phase: 83-claim-accuracy-shaping-hygiene
verified: 2026-06-10T00:00:00Z
status: passed
score: 4/4 roadmap success criteria verified
overrides_applied: 0
---

# Phase 83: Claim Accuracy & Shaping Hygiene Verification Report

**Phase Goal:** The "pure Elixir core / no hard NIF dependencies" claim is restored to truth before any launch content ships — `harfbuzz_ex` is an optional dep behind a behaviour, complex scripts fail instructively, the shaping bug is fixed, and dead `unicode_data` is replaced.
**Verified:** 2026-06-10
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A project without `harfbuzz_ex` can compile and render Latin-script PDFs without any NIF step — `mix.exs` lists `harfbuzz_ex` as `optional: true` | VERIFIED | `mix.exs:45` has `{:harfbuzz_ex, "~> 1.2", optional: true}`; `unicode_data` absent; `{:unicode, "~> 1.22"}` present; `Shaper.Simple.do_shape/2` handles `source in [:built_in, :embedded]` (CR-01 fix in `b9356de`); `test_helper.exs` runs full suite under `Shaper.Simple` default (WR-03 fix in `1537f60`) |
| 2 | Rendering text in Arabic, Hebrew, Devanagari, or Thai with no shaping adapter raises a deterministic instructive error naming the script and the fix — never silent wrong/disconnected output | VERIFIED | `Rendro.Text.Shaper.Simple` has a 20-atom `@requires_shaping` MapSet gating `:arab`, `:hebr`, `:deva`, `:thai`, `:laoo`, `:khmr`, `:mymr`, `:tibt`, etc. Returns `{:error, {:shaping_required, script, hint}}`. `lib/rendro/error.ex` has `why/2` and `next_step/2` clauses for both 3-arg and 2-arg `{:shaping_required, ...}` forms. `measure_block` returns raw `{:error, ...}` which `pipeline.ex:143` wraps with `base_meta` (WR-02 fix in `5e56c88`). HYG-02 integration test in `measure_test.exs` passes (27 tests, 0 failures). WR-04 fix (`5a1a104`): hint keys on effective shaper, not dep presence — built-in font + complex script when HarfBuzz is already configured now gets the "register an embedded font" hint. |
| 3 | All existing Latin-script golden tests pass byte-identically (or are deliberately re-blessed with a changelog note) after the `split_graphemes` cluster-boundary fix and the `ex_unicode` migration | VERIFIED | `split_graphemes/4` rewritten to shape font-homogeneous runs (not per-grapheme) with `glyphs_to_cluster_runs/4` helper (commit `4bfa5cf`). Under `Shaper.Simple` (all `cluster: 0`), behaviour is byte-identical to old per-grapheme loop by construction. StreamData property test in `shaper_test.exs` formally verifies `per_run_total == per_grapheme_total` for random ASCII strings. `mix test test/rendro/deterministic_test.exs` passes: 3 properties, 12 tests, 0 failures. `CHANGELOG.md` has `[Unreleased]` HYG-03 re-bless event entry (no golden files changed). CR-03 fix (`99a2182`): `glyphs_to_cluster_runs` never drops graphemes — glyph count ≠ grapheme count falls back to single atomic cluster-run. |
| 4 | `priv/support_matrix.json` contains `explicit_deferral` rows for Arabic, Hebrew/RTL, Devanagari, and Thai with named reasons, and README/guide script-support claims align — no overclaim | VERIFIED | `priv/support_matrix.json` has `text_shaping` top-level key with 5 entries: `latin_and_cjk` (supported) + 4 `explicit_deferral` rows. Evidence string lengths: arabic=262 chars, hebrew_rtl=191 chars, devanagari=198 chars, thai=193 chars — all > 40 char minimum. `guides/api_stability.md` mirrors all 4 deferral reasons verbatim (required by `viewer_evidence_claims_test`). `test/docs_contract/script_support_claims_test.exs` (2 tests) CI-enforces all 4 rows. `mix test test/docs_contract/` passes: 1 doctest + 109 tests, 0 failures. |

**Score:** 4/4 roadmap success criteria verified

### Code Review Fixes Verified (5 Critical + 7 Warning)

| Finding | Commit | Verification |
|---------|--------|-------------|
| CR-01: Simple rejects all embedded fonts | `b9356de` | `do_shape/2` matches `source in [:built_in, :embedded]`; embedded rejection clause absent from `simple.ex` |
| CR-02: Per-render `shaper:` option undocumented/unimplemented | `8914a4f` | `Rendro.render_option` type includes `{:shaper, module()}`; `render_with_diagnostics/2` threads it into `doc.options[:render]`; `shape_opts/1` reads it; `Shaper.shape/3` resolves `opts[:shaper] \|\| impl()` |
| CR-03: Silent grapheme loss in `glyphs_to_cluster_runs` zip | `99a2182` | All-zero clusters only zip when `length(glyphs) == length(graphemes)`; otherwise falls to single atomic cluster-run with summed advances — no truncation |
| CR-04: HarfBuzz cluster approximation fixes | `743ca91` | `enrich_with_cluster/2`: byte-offset path only when glyph count == grapheme count; all-zero path otherwise; gid stays 0 (NIF exposes no glyph ids); documented in code |
| CR-05: Temp-file font cache hardened | `6d8759c` | `cached_font_path/1` creates `rendro_fonts_*` subdirectory with `File.chmod(dir, 0o700)`; `cached_font_valid?/2` uses `File.lstat` to reject non-regular files (symlinks rejected) AND content-equality check; `write_font_atomically/3` writes to unique tmp name then `File.rename` |
| WR-01: Pseudo-script `:embedded_font_requires_harfbuzz` reason | resolved by CR-01 | Rejection clause is gone; reason no longer exists |
| WR-02: Shaping errors lose `render_id` / correlation metadata | `5e56c88` | `from_stage` wrapping deleted from `measure_block`; `measure.ex` has zero `from_stage` calls; `pipeline.ex:143` wraps raw `{:error, reason}` with `base_meta` |
| WR-03: test_helper auto-activates HarfBuzz | `1537f60` | `test_helper.exs` contains only comment warning against it; no `Application.put_env` for `:shaper`; 1022 tests pass under `Shaper.Simple` default |
| WR-04: Misleading fix instruction when HarfBuzz already configured | `5a1a104` | `shaping_hint/3` in `simple.ex` keys on `effective = Keyword.get(opts, :shaper) \|\| Rendro.Text.Shaper.impl()`; non-Simple effective shaper gets register-embedded-font hint |
| WR-05: ScriptTags wrong/dead mappings | `caa4a83` | `script_tags.ex:35`: `:old_turkic -> :orkh`; `script_tags.ex:187`: `:bhaiksuki -> :bhks` (correct spelling); `:byzantine_music` clause absent |
| WR-06: `glyph()` contract under-specified | `3933b7e` | `@typedoc` documents cluster semantics (byte offset, non-decreasing, all-zero interpretation); `optional(:name) => String.t()` added to type; `@callback` doc specifies `:script` and `:shaper` opts |
| WR-07: `shape/3` hidden from ExDoc and manifest | `451d71a` | `@doc` present on `Simple.shape/3` (line 41 of `simple.ex`) and `HarfBuzz.shape/3` (line 24 of `harfbuzz.ex`); `priv/public_api.json` lists `shape/3` for both; manifest byte-equality test passes |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/text/shaper.ex` | Behaviour definition with `@type glyph` and `@callback shape/3` | VERIFIED | `@moduledoc tags: [:stable]`, `@type glyph` with 6 fields + `optional(:name)`, `@callback shape/3`, `@spec impl/0`, per-render shaper delegation in `shape/3` |
| `lib/rendro/text/shaper/simple.ex` | Pure-Elixir shaper, `@behaviour Rendro.Text.Shaper` | VERIFIED | `@moduledoc tags: [:stable]`, `@behaviour Rendro.Text.Shaper`, 20-atom `@requires_shaping` MapSet, `do_shape/2` handles `source in [:built_in, :embedded]` |
| `lib/rendro/adapters/harfbuzz.ex` | Optional HarfBuzz adapter, `Code.ensure_loaded?(HarfbuzzEx)` gate | VERIFIED | Entire `defmodule` wrapped in `if Code.ensure_loaded?(HarfbuzzEx)`, `@moduledoc tags: [:adapter]`, `@behaviour Rendro.Text.Shaper`, `@doc` on `shape/3`, hardened `cached_font_path/1`, `enrich_with_cluster/2` |
| `lib/rendro/text/bidi.ex` | Uses `Unicode.script/1` and `Unicode.BidiClass.bidi_class/1` | VERIFIED | `Unicode.script(cp)` on line 64, `Rendro.Text.ScriptTags.to_opentype_tag/1` on line 70, `Unicode.BidiClass.bidi_class/1` on line 73; zero `UnicodeData` references |
| `lib/rendro/text/script_tags.ex` | OT tag mapping module, `to_opentype_tag/1` | VERIFIED | 192-line file with 152 `def to_opentype_tag/1` clauses, `@moduledoc false`, passthrough fallback |
| `lib/rendro/pipeline/measure.ex` | Cluster-boundary `split_graphemes`, case-softened shaper calls | VERIFIED | Per-grapheme `Shaper.shape` call gone; `split_graphemes/4` shapes font-homogeneous runs; `glyphs_to_cluster_runs/4` dispatches Simple vs HarfBuzz path; zero hard-match `{:ok, glyphs} = ...` sites |
| `lib/rendro/error.ex` | `why/2` and `next_step/2` clauses for `{:shaping_required, ...}` | VERIFIED | Lines 116, 120 (`why/2`), lines 257, 261 (`next_step/2`); 3-arg before 2-arg per shadowing rule |
| `mix.exs` | `harfbuzz_ex optional: true`, `unicode ~> 1.22`, `unicode_data` absent | VERIFIED | Line 45: `{:harfbuzz_ex, "~> 1.2", optional: true}`; line 46: `{:unicode, "~> 1.22"}`; no `unicode_data` match |
| `lib/rendro/public_api.ex` | `harfbuzz.ex` first in `@adapter_files` | VERIFIED | `@adapter_files` starts with `"lib/rendro/adapters/harfbuzz.ex"` |
| `priv/support_matrix.json` | `text_shaping` section with 4 `explicit_deferral` rows | VERIFIED | `text_shaping` key present; arabic/hebrew_rtl/devanagari/thai all `status: explicit_deferral` with evidence > 40 chars |
| `test/docs_contract/script_support_claims_test.exs` | CI guard for 4 deferral rows | VERIFIED | Asserts all 4 rows via regex patterns; passes (2 tests, 0 failures) |
| `priv/public_api.json` | `Rendro.Text.Shaper` stable tier, `Rendro.Adapters.HarfBuzz` adapter tier | VERIFIED | `Elixir.Rendro.Text.Shaper`: `{tier: stable, functions: [impl/0, shape/3], types: [glyph/0]}`; `Elixir.Rendro.Text.Shaper.Simple`: `{tier: stable, functions: [shape/3]}`; `Elixir.Rendro.Adapters.HarfBuzz`: `{tier: adapter, functions: [shape/3]}` |
| `guides/api_stability.md` | Tier-1 `Rendro.Text.Shaper` + Simple; Tier-2 `Rendro.Adapters.HarfBuzz` | VERIFIED | Line 15: Text shaping behaviour in Tier-1; Line 25: `Rendro.Adapters.HarfBuzz` in Tier-2 Adapters; Lines 193–196: all 4 deferral reasons mirrored |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/rendro/text/shaper.ex` | `Rendro.Text.Shaper.Simple` | `Application.get_env(:rendro, :shaper, Rendro.Text.Shaper.Simple)` | WIRED | `impl/0` body confirmed; `shape/3` resolves `opts[:shaper] \|\| impl()` |
| `lib/rendro/adapters/harfbuzz.ex` | `Rendro.Text.Shaper` | `@behaviour Rendro.Text.Shaper` | WIRED | Behaviour declaration at module level |
| `lib/rendro/text/bidi.ex` | `Unicode.script/1` | codepoint → atom script name | WIRED | `script_atom = Unicode.script(cp)` line 64 |
| `lib/rendro/text/bidi.ex` | `Rendro.Text.ScriptTags` | `to_opentype_tag/1` call | WIRED | `Rendro.Text.ScriptTags.to_opentype_tag(script_atom)` line 70 |
| `lib/rendro/pipeline/measure.ex` `split_graphemes` | `Rendro.Text.Shaper.shape/3` | shapes accumulated run, not individual grapheme | WIRED | `case Rendro.Text.Shaper.shape(font, run_text, Keyword.put(shape_opts, :script, script))` |
| `test/docs_contract/script_support_claims_test.exs` | `priv/support_matrix.json` | `File.read!` assertion | WIRED | `matrix = File.read!("priv/support_matrix.json")` |
| `lib/rendro.ex` | per-render `:shaper` opt | `render_with_diagnostics/2` threads into `doc.options[:render]` | WIRED | `render_option` type includes `{:shaper, module()}`; `shape_opts/1` in `measure.ex` reads `options[:render][:shaper]` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `Rendro.Text.Shaper.Simple.shape/3` | `glyphs` list | `Rendro.PDF.Font.text_width/3` for each grapheme in `do_shape/2` | Yes — real font advance widths from cmap | FLOWING |
| `split_graphemes` → `glyphs_to_cluster_runs` | `cluster_run_list` | `Rendro.Text.Shaper.shape/3` called per font-homogeneous run | Yes — real shaped glyph metrics | FLOWING |
| `priv/support_matrix.json` text_shaping | static JSON data | authored content, CI-verified by `script_support_claims_test.exs` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `harfbuzz_ex` is `optional: true` in `mix.exs` | `grep "harfbuzz_ex" mix.exs` | `{:harfbuzz_ex, "~> 1.2", optional: true}` | PASS |
| `unicode_data` absent from `mix.exs` | `grep "unicode_data" mix.exs` | no output | PASS |
| No `UnicodeData` references in `bidi.ex` | `grep "UnicodeData" lib/rendro/text/bidi.ex` | no output | PASS |
| No hard-match `{:ok, glyphs} = Rendro.Text.Shaper.shape` in `measure.ex` | `grep "= Rendro.Text.Shaper.shape" lib/rendro/pipeline/measure.ex` | no output | PASS |
| `test_helper.exs` has no HarfBuzz auto-activation | `grep "put_env.*HarfBuzz\|ensure_loaded.*Harfbuzz" test/test_helper.exs` | no output | PASS |
| Shaper tests pass (including StreamData property) | `mix test test/rendro/text/shaper_test.exs` | 1 property, 15 tests, 0 failures | PASS |
| Measure tests pass (HYG-02 integration test included) | `mix test test/rendro/pipeline/measure_test.exs` | 27 tests, 0 failures | PASS |
| Docs contract tests pass | `mix test test/docs_contract/` | 1 doctest + 109 tests, 0 failures | PASS |
| Deterministic golden tests pass | `mix test test/rendro/deterministic_test.exs` | 3 properties, 12 tests, 0 failures | PASS |
| Full test suite | `mix test` | 12 doctests + 4 properties + 1022 tests, 0 failures (10 excluded) | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| HYG-01 | Plan 83-01, 83-05 | `harfbuzz_ex` optional dep behind `Rendro.Text.Shaper` behaviour; `Shaper.Simple` pure-Elixir default | SATISFIED | `mix.exs` `optional: true`; behaviour module + `Shaper.Simple` exist with `@moduledoc tags: [:stable]`; `Rendro.Adapters.HarfBuzz` compile-gated; `priv/public_api.json` shows stable tier; `guides/api_stability.md` Tier-1 updated |
| HYG-02 | Plan 83-03 | Complex script with no adapter → deterministic instructive error, never silent wrong output | SATISFIED | 20-atom `@requires_shaping` MapSet in `Shaper.Simple`; `error.ex` has `why/2` and `next_step/2` for `{:shaping_required, script, hint}`; pipeline wraps with `base_meta`; HYG-02 integration test passes |
| HYG-03 | Plan 83-04 | Per-grapheme shaping bug fixed; Latin golden tests byte-identical | SATISFIED | `split_graphemes/4` shapes runs via `glyphs_to_cluster_runs/4`; StreamData property test verifies byte-identity; no golden re-bless needed; `CHANGELOG.md` has D-13 re-bless event entry |
| HYG-04 | Plans 83-01, 83-02 | Dead `unicode_data 0.8.0` replaced by `ex_unicode` | SATISFIED | `unicode_data` absent from `mix.exs`; `{:unicode, "~> 1.22"}` present; `bidi.ex` uses `Unicode.script/1` + `Unicode.BidiClass.bidi_class/1`; `Rendro.Text.ScriptTags` module (152 clauses); WR-05 fixes applied (`:old_turkic -> :orkh`, `:bhaiksuki -> :bhks`) |
| HYG-05 | Plan 83-05 | `priv/support_matrix.json` gains `explicit_deferral` rows; docs align | SATISFIED | `text_shaping` key with 4 `explicit_deferral` rows (all > 40 char evidence); `script_support_claims_test.exs` CI-enforces; `guides/api_stability.md` mirrors all 4 reasons; `Rendro.Text.Shaper` not in hidden_modules |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | — |

No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`, or stub patterns found in any of the phase files.

### Human Verification Required

None — all behaviors are mechanically verifiable. The full test suite (1022 tests, 0 failures) covers the complete feature surface including:
- Embedded font shaping under `Shaper.Simple` (CR-01 regression test)
- Per-render `shaper:` option precedence (CR-02)
- No-grapheme-loss zip path (CR-03)
- Hardened font cache behavior (CR-05)
- Default suite under `Shaper.Simple` (WR-03)

### Gaps Summary

No gaps. All 4 roadmap success criteria are verified. All 12 code review findings (5 Critical + 7 Warning) are confirmed fixed in the codebase. The full test suite passes under the shipped default (`Shaper.Simple`), including the deterministic golden tests.

---

_Verified: 2026-06-10T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
