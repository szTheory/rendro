---
phase: 83
plan: 01
subsystem: text-shaping
tags: [shaper, behaviour, harfbuzz, unicode, optional-dep, refactor]
dependency_graph:
  requires: []
  provides:
    - Rendro.Text.Shaper behaviour (stable-tier public API)
    - Rendro.Text.Shaper.Simple (pure-Elixir default shaper)
    - Rendro.Adapters.HarfBuzz (optional NIF adapter, compile-gated)
  affects:
    - lib/rendro/text/bidi.ex (unicode_data → unicode migration)
    - lib/rendro/pipeline/measure.ex (hard-match softening)
    - test/test_helper.exs (HarfBuzz configured for embedded font tests)
tech_stack:
  added:
    - unicode ~> 1.22 (replaces unicode_data 0.8.0)
  patterns:
    - Code.ensure_loaded?/1 compile gate for optional NIF dep
    - Application.get_env(:rendro, :shaper, Default) runtime dispatch
    - @behaviour + @callback + @impl annotation pattern
    - SHA256-keyed font temp file caching (preserved from original shaper)
key_files:
  created:
    - lib/rendro/text/shaper.ex (rewritten as behaviour)
    - lib/rendro/text/shaper/simple.ex (new pure-Elixir shaper)
    - lib/rendro/adapters/harfbuzz.ex (new optional NIF adapter)
  modified:
    - mix.exs (harfbuzz_ex optional, unicode added, unicode_data removed)
    - lib/rendro/public_api.ex (harfbuzz.ex in @adapter_files)
    - priv/public_api.json (regenerated to include new stable+adapter modules)
    - test/docs_contract/public_api_contract_test.exs (remove Shaper from hidden)
    - lib/rendro/text/bidi.ex (unicode migration, Rule 3)
    - lib/rendro/pipeline/measure.ex (hard-match softening, Rule 3)
    - test/test_helper.exs (HarfBuzz test config, Rule 3)
    - test/rendro/text/shaper_test.exs (updated for new 3-arg API)
decisions:
  - "D-02 enforced: runtime shaper is always Application.get_env-driven, never auto-detected from lockfile presence"
  - "HarfBuzz adapter adds built-in font delegation clause to Shaper.Simple to support apps using both font types with a single configured shaper"
  - "Test isolation: shaper_test.exs is async: false to safely clear global HarfBuzz test config; all other tests benefit from globally configured HarfBuzz"
  - "cluster: 0 placeholder in Shaper.Simple is intentional — cluster-aware splitting is Plan 04's concern (D-11)"
requirements-completed:
  - HYG-01
  - HYG-04
metrics:
  duration: "34m 28s"
  completed: "2026-06-10"
  tasks: 2
  files: 11
---

# Phase 83 Plan 01: Shaper Behaviour + Shaper.Simple + HarfBuzz Adapter Summary

## One-liner

JWT-style behaviour split: Rendro.Text.Shaper becomes a stable-tier public behaviour with Shaper.Simple (cmap+advance widths) as pure-Elixir default, Rendro.Adapters.HarfBuzz as compile-gated NIF adapter, harfbuzz_ex flipped to optional, and unicode_data replaced with unicode ~> 1.22.

## Tasks

### Task 1: Rewrite shaper.ex as behaviour + create Shaper.Simple

**Status:** COMPLETE

**Commits:**
- `7f1fee3` — test(83-01): add failing tests (RED phase, TDD)
- `5be2efc` — feat(83-01): rewrite Shaper as behaviour + create Shaper.Simple (GREEN phase)

**Verification passed:**
- `Rendro.Text.Shaper.impl()` returns `Rendro.Text.Shaper.Simple` when no app config set
- `Shaper.Simple.shape(built_in_font, "Hello", [script: :latn])` returns `{:ok, [glyphs]}`
- `Shaper.Simple.shape(font, "test", [script: :arab])` returns `{:error, {:shaping_required, :arab, hint}}`
- 9 shaper tests pass

### Task 2: Create HarfBuzz adapter + update mix.exs + public_api.ex

**Status:** COMPLETE

**Commits:**
- `af815ff` — feat(83-01): create HarfBuzz adapter + update mix.exs + public_api.ex
- `222b929` — fix(83-01): Rule 3 auto-fixes for blocking issues from dep removal

**Verification passed:**
- `lib/rendro/adapters/harfbuzz.ex` exists with `Code.ensure_loaded?(HarfbuzzEx)` gate
- `mix.exs` has `{:harfbuzz_ex, "~> 1.2", optional: true}` and `{:unicode, "~> 1.22"}`
- `unicode_data` absent from mix.exs
- `lib/rendro/public_api.ex` @adapter_files starts with "lib/rendro/adapters/harfbuzz.ex"
- `mix compile` zero errors

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing functionality] Rendro.Text.Shaper removed from hidden_modules contract**
- **Found during:** Task 1
- **Issue:** `public_api_contract_test.exs` had `Rendro.Text.Shaper` in the `hidden_modules` list; after promotion to stable-tier public behaviour, this check failed.
- **Fix:** Removed `Rendro.Text.Shaper` from the `hidden_modules` list and regenerated `priv/public_api.json` to include `Rendro.Text.Shaper` and `Rendro.Text.Shaper.Simple`.
- **Files modified:** `test/docs_contract/public_api_contract_test.exs`, `priv/public_api.json`
- **Commit:** `5be2efc`

**2. [Rule 3 - Blocking] bidi.ex broke after unicode_data removal**
- **Found during:** Task 2 (after removing `unicode_data` from mix.exs)
- **Issue:** `lib/rendro/text/bidi.ex` used `UnicodeData.Script.script_from_codepoint/1` and `UnicodeData.Bidi.bidi_class/1` which became undefined after removing `unicode_data`. 249 test failures.
- **Fix:** Migrated `bidi.ex` to use `Unicode.script/1` and `Unicode.BidiClass.bidi_class/1` from the new `unicode` package. Added `to_opentype_tag/1` private function mapping ~45 Unicode atom script names to 4-letter OT tags (covering all 20 gated complex scripts + common supported scripts).
- **Files modified:** `lib/rendro/text/bidi.ex`
- **Commit:** `222b929`

**3. [Rule 3 - Blocking] measure.ex hard-matches broke after Shaper.Simple embedded font error**
- **Found during:** Task 2 (after Shaper.Simple returns `{:error, :embedded_font_requires_harfbuzz}` for embedded fonts)
- **Issue:** Two hard-match sites in `measure.ex` (`{:ok, glyphs} = Rendro.Text.Shaper.shape(...)`) crashed with `MatchError` when Shaper.Simple was used with embedded fonts. 6 test failures.
- **Fix:** Converted both hard-match sites to `case` expressions with `{:error, reason} -> {:halt, {:error, reason}}` propagation. Converted inner `Enum.map` in `measure_text_into_runs` to `Enum.reduce_while` to enable error halting. Threaded `script: bidi_run.script` option to `Shaper.shape/3`.
- **Files modified:** `lib/rendro/pipeline/measure.ex`
- **Commit:** `222b929`

**4. [Rule 3 - Blocking] HarfBuzz adapter needed built-in font delegation**
- **Found during:** Task 2 integration testing
- **Issue:** `Rendro.Adapters.HarfBuzz.shape/3` only matched `source: :embedded` fonts. Applications configured with `shaper: HarfBuzz` that also use built-in fonts (which is the common case) would get `FunctionClauseError`.
- **Fix:** Added `shape/3` clause for `source: :built_in` that delegates to `Rendro.Text.Shaper.Simple.shape/3`.
- **Files modified:** `lib/rendro/adapters/harfbuzz.ex`
- **Commit:** `222b929`

**5. [Rule 3 - Blocking] Test infrastructure needed HarfBuzz for embedded font pipeline tests**
- **Found during:** Task 2 (after Rule 3 fixes #2-4, still 4 failures)
- **Issue:** `Rendro.render()` spawns a `Task.async` process which doesn't inherit process dict; `Application.put_env` needed for cross-process shaper config.
- **Fix:** Configured `Application.put_env(:rendro, :shaper, Rendro.Adapters.HarfBuzz)` globally in `test_helper.exs` (conditional on harfbuzz_ex availability). Made `shaper_test.exs` `async: false` so its `setup` can safely clear the global config to test default Simple behavior.
- **Files modified:** `test/test_helper.exs`, `test/rendro/text/shaper_test.exs`, `test/rendro/deterministic_test.exs`
- **Commit:** `222b929`

## Known Stubs

- `cluster: 0` in `Rendro.Text.Shaper.Simple.do_shape/2` — intentional placeholder per plan (D-11). Cluster-aware grapheme splitting is Plan 04's responsibility. This value flows to glyph structs but is not used in display rendering (only x_advance matters for line-breaking).

## Final Verification

All 974 tests pass (12 doctests, 3 properties, 959 regular tests), 10 excluded (live_pdf_tools, live_signing), 0 failures.

```
mix compile    → zero warnings on new files
mix test test/rendro/text/shaper_test.exs  → 9/9 pass
mix test       → 974 tests, 0 failures (10 excluded)
grep harfbuzz_ex mix.exs  → optional: true
grep unicode_data mix.exs → no match
grep unicode mix.exs      → {:unicode, "~> 1.22"}
```

## Self-Check: PASSED

Files exist:
- lib/rendro/text/shaper.ex ✓
- lib/rendro/text/shaper/simple.ex ✓
- lib/rendro/adapters/harfbuzz.ex ✓

Commits exist:
- 7f1fee3 ✓ (test RED)
- 5be2efc ✓ (feat GREEN)
- af815ff ✓ (feat Task 2)
- 222b929 ✓ (fix Rule 3)
