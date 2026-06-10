# Phase 83: Claim-Accuracy & Shaping Hygiene - Research

**Researched:** 2026-06-10
**Domain:** Elixir text shaping pipeline refactor (harfbuzz_ex optional-dep, unicode migration, error gating, support matrix)
**Confidence:** HIGH (all code paths verified by direct source inspection; API surfaces verified against installed deps and hex.pm)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Shaper selection is explicit, never auto-detected: `config :rendro, shaper: <module>` (application config) defaulting to `Rendro.Text.Shaper.Simple`, with a per-render `shaper:` option override threaded through the existing `doc.options[:render]` path. Precedence: per-render opt > app config > `Shaper.Simple` default.

**D-02:** No `Code.ensure_loaded?` auto-activation for output-affecting behavior. The HarfBuzz adapter module is compile-gated behind `Code.ensure_loaded?(HarfbuzzEx)` (so it exists only when the optional dep is present), but it never silently becomes the active shaper.

**D-03:** When `Shaper.Simple` hits a requires-shaping script AND `harfbuzz_ex` is loaded but not configured, the error message prints the exact config line (`config :rendro, shaper: Rendro.Adapters.HarfBuzz`).

**D-04:** Split layout: `Rendro.Text.Shaper` (behaviour, tier `:stable`) + `Rendro.Text.Shaper.Simple` (tier `:stable`, pure-Elixir core) + `Rendro.Adapters.HarfBuzz` (tier `:adapter`, optional-dep implementation).

**D-05:** Behaviour callback locked at `shape(font, text, opts) :: {:ok, [glyph]} | {:error, term}` with glyphs carrying `gid, cluster, x_advance, y_advance, x_offset, y_offset`. The behaviour is `:stable`.

**D-06:** Mechanical churn path: remove `Rendro.Text.Shaper` from the `hidden_modules` list in `test/docs_contract/public_api_contract_test.exs` (line ~89), add `@moduledoc tags:` + `@spec`s, add the HarfBuzz adapter file to `Rendro.PublicApi`'s `@adapter_files` conditional-compile list, flip mix.exs to `{:harfbuzz_ex, "~> 1.2", optional: true}`, run `mix rendro.api.gen` to regenerate `priv/public_api.json`, update tier lists in `guides/api_stability.md`.

**D-07:** The runtime gate uses a principled requires-shaping script set (curated list derived from HarfBuzz's complex-shaper dispatch families), NOT just the four scripts named in the success criterion. Curated set: joining scripts (Arabic, Syriac, N'Ko, Mongolian), Hebrew (RTL), Indic (Devanagari, Bengali, Gurmukhi, Gujarati, Oriya, Tamil, Telugu, Kannada, Malayalam, Sinhala), SEA (Thai, Lao, Khmer, Myanmar), Tibetan. Passing: Latin, Greek, Cyrillic, Armenian, Georgian, Han, Hiragana/Katakana, precomposed Hangul.

**D-08:** Gate lives inside `Shaper.Simple`, keyed on the Bidi run's script tag passed via `shape/3` opts. `Rendro.Adapters.HarfBuzz` never gates.

**D-09:** Error envelope: `{:error, {:shaping_required, script}}` flows through measure's existing `reduce_while` tuple-halt path, wrapped at the stage boundary via `Rendro.Error.from_stage(:measure, ...)`. The two hard-match sites in `measure.ex` (~607, ~667) must become `case`/`with`.

**D-10:** HYG-05's matrix records `explicit_deferral` rows for the four named script families (Arabic, Hebrew/RTL, Devanagari, Thai).

**D-11:** Uniform fix, no two-path fork: rewrite `split_graphemes` to shape runs and break at cluster boundaries everywhere.

**D-12:** Add a property test asserting per-grapheme widths == per-run widths under `Shaper.Simple`.

**D-13:** Any HarfBuzz-path golden shifts AND any ex_unicode run-itemization shifts are consolidated into one deliberate, changelogged re-bless event.

### Claude's Discretion

- Exact module/file organization within the locked split layout (e.g., where the requires-shaping script list constant lives).
- Telemetry event naming for the new seam (existing `[:rendro, :shaper, :missing_glyph]` event should be preserved or deliberately migrated).
- Edge-script pass/fail calls not in the curated list (Thaana, Ethiopic, Hangul jamo) — document each call in the support matrix or code comments.
- Whether `Shaper.HarfBuzz`'s temp-file caching strategy (SHA256-keyed temp files) is kept or improved during the move to `Rendro.Adapters.HarfBuzz`.

### Deferred Ideas (OUT OF SCOPE)

- Full complex-script shaping (UAX #9 bidi, visual reordering, Arabic/Hebrew vertical slice) — conditional v2.7 behind the LNCH-03 demand gate.
- PDF.js render lane re-testing pdfjs deferral rows.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HYG-01 | `harfbuzz_ex` becomes optional dep behind `Rendro.Text.Shaper` behaviour; core ships pure-Elixir `Shaper.Simple`; "pure Elixir core / no hard NIF dependencies" claim becomes true | D-01..D-06 + `Code.ensure_loaded?` gating pattern from `Accrue` adapter; `@adapter_files` machinery from `Rendro.PublicApi` |
| HYG-02 | Complex-script rendering with no shaping adapter configured produces deterministic instructive error, never silent broken output | D-07..D-09; `Rendro.Error.from_stage/3` + existing `{:unsupported_glyph, _}` tuple-halt path in `measure.ex` |
| HYG-03 | Per-grapheme shaping bug in `split_graphemes` fixed to shape runs and break at cluster boundaries; Latin goldens byte-identical or deliberately re-blessed | D-11..D-13; cluster field absent from `harfbuzz_ex` NIF (discovered below) — adapter must derive/enrich cluster |
| HYG-04 | `unicode_data 0.8.0` replaced by maintained `unicode` (formerly `ex_unicode`) stack; run-itemization behavior verified unchanged or changes documented | `unicode` v1.22.0 API mapping discovered below; atom vs string type differences require attention |
| HYG-05 | `priv/support_matrix.json` gains `explicit_deferral` rows for Arabic, Hebrew/RTL, Devanagari, Thai with named reasons; README/guide claims align | Schema and Matrix module architecture discovered below; requires new top-level `text_shaping` section |
</phase_requirements>

---

## Summary

Phase 83 is a refactor + fence phase — the goal is correctness and claim accuracy, not new capability. The codebase has exactly one shaper module (`lib/rendro/text/shaper.ex`, 58 lines) that hard-calls `HarfbuzzEx.get!` with no behaviour indirection, and exactly one Unicode dependency (`unicode_data 0.8.0`) that is both unmaintained and returning strings where the replacement returns atoms.

The migration has five distinct work streams that interlock at test time: (1) extract the behaviour and split `Shaper` into `Shaper.Simple` + `Adapters.HarfBuzz` behind optional-dep compile gate; (2) add the complex-script gate inside `Shaper.Simple`; (3) fix `split_graphemes` in `measure.ex` to shape runs and break at HarfBuzz cluster boundaries; (4) migrate `Bidi.resolve_state/1` from `UnicodeData.Script`/`UnicodeData.Bidi` to `Unicode.Script`/`Unicode.BidiClass`, handling the string→atom return type change; (5) add a new `text_shaping` section to `priv/support_matrix.json` with `explicit_deferral` rows.

**Critical discovered fact:** The `harfbuzz_ex` v1.2.0 NIF does NOT expose the `cluster` field from HarfBuzz's glyph info — the Rust source maps only `name, x_advance, y_advance, x_offset, y_offset`. The D-05-locked `glyph` type requires `cluster`. The `Rendro.Adapters.HarfBuzz` implementation must either derive cluster from sequential byte offsets of the input text (approximation that works for pre-composed scripts) or accept the limitation. This is the key technical risk in HYG-03.

**Primary recommendation:** Implement in wave order — behaviour split first (HYG-01, passes tests immediately), then gate (HYG-02), then unicode migration (HYG-04), then cluster fix (HYG-03 — held for last because it touches golden outputs), then matrix (HYG-05).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Shaper behaviour definition | `lib/rendro/text/shaper.ex` | — | Pure interface, always compiled |
| Pure-Elixir shaping (Simple) | `lib/rendro/text/shaper/simple.ex` | — | Core, no NIF deps |
| HarfBuzz shaping adapter | `lib/rendro/adapters/harfbuzz.ex` | — | Tier-2 adapter, compile-gated |
| Complex-script gate | `Shaper.Simple` (inside `shape/3`) | — | D-08: single gate, Bidi is single classification source |
| Bidi run itemization | `lib/rendro/text/bidi.ex` | — | Script tagging feeds the gate; migrates to `unicode` |
| Cluster-boundary line-breaking | `lib/rendro/pipeline/measure.ex` `split_graphemes` | — | D-11: uniform fix |
| Support matrix script claims | `priv/support_matrix.json` new `text_shaping` section | `guides/api_stability.md` | Records honest deferrals |
| Public API manifest | `priv/public_api.json` (regenerated) | `public_api_contract_test.exs` | Contract lockstep |

---

## Standard Stack

### Core (no new packages)

| Library | Current | Becomes | Purpose |
|---------|---------|---------|---------|
| `harfbuzz_ex` | `~> 1.2` (hard dep) | `~> 1.2, optional: true` | HarfBuzz NIF shaping — optional, adapter-only |
| `unicode_data` | `~> 0.8.0` | REMOVED | Unmaintained; retired package |
| `unicode` | (not present) | `~> 1.22` | Replacement for `unicode_data`; provides `Unicode.Script.script/1` and `Unicode.BidiClass.bidi_class/1` |

### Package Legitimacy Audit

> `unicode_data` is being removed. `harfbuzz_ex` is being made optional. `unicode` is the new addition. All are Elixir/hex packages. slopcheck is Python-biased and cannot verify hex packages — hex.pm API used directly.

| Package | Registry | Version | Downloads (all-time) | Source Repo | slopcheck | Disposition |
|---------|----------|---------|----------------------|-------------|-----------|-------------|
| `unicode` | hex.pm | 1.22.0 | 946,031 | github.com/elixir-unicode/unicode | N/A — hex.pm verified | Approved `[VERIFIED: hex.pm API]` |
| `harfbuzz_ex` | hex.pm | 1.2.0 | 755 | github.com/jkwchui/harfbuzz_ex | N/A — hex.pm verified, already in mix.lock | Keep (optional) `[VERIFIED: hex.pm API + mix.lock]` |
| `unicode_data` | hex.pm | 0.8.0 | (in mix.lock) | — | — | REMOVED — retired package `[VERIFIED: hex.pm shows retired status]` |

**Packages removed:** `unicode_data` (replaced by `unicode`).
**Packages flagged [SUS]:** `harfbuzz_ex` has 755 total downloads — very low. However it is already a hard dep in the current mix.lock (verified present), published by jkwchui with a linked GitHub repo. It is being made optional, so its risk decreases. Accept with note.

*slopcheck unavailable for hex packages (Python registry bias); hex.pm API used directly for verification.*

### Installation change

```elixir
# mix.exs — before
{:harfbuzz_ex, "~> 1.2"},
{:unicode_data, "~> 0.8.0"},

# mix.exs — after
{:harfbuzz_ex, "~> 1.2", optional: true},
{:unicode, "~> 1.22"},
```

---

## Architecture Patterns

### System Architecture Diagram

```
lib/rendro.ex (per-render shaper: opt) ──────────────────┐
                                                          │
config :rendro, shaper: Module ──────────────────────────┤
                                                          ▼
                                            Rendro.Pipeline.Measure
                                                    │
                                                    ├── measure_text_into_runs
                                                    │         │
                                                    │    Rendro.Text.Bidi.split_runs/1
                                                    │    (migrated to Unicode.Script + Unicode.BidiClass)
                                                    │         │ returns [%{text, script, direction}]
                                                    │         ▼
                                                    │    Shaper.shape(font, text, [script: script_tag])
                                                    │         │
                                                    │    ┌────┴────────────────────┐
                                                    │    │                         │
                                                    │    ▼                         ▼
                                                    │  Shaper.Simple            Adapters.HarfBuzz
                                                    │  (always compiled)        (Code.ensure_loaded?(HarfbuzzEx))
                                                    │  - cmap + advance widths  - delegates to HarfbuzzEx.get!
                                                    │  - requires-shaping gate  - never gates on script
                                                    │    → {:error, {:shaping_required, script}}
                                                    │    → {:ok, [glyph]}
                                                    │         │
                                                    │    Rendro.Error.from_stage(:measure, ...)
                                                    │
                                                    └── split_graphemes (FIXED)
                                                         - shapes runs (not per-grapheme)
                                                         - breaks at cluster boundaries
```

### Recommended File Organization

```
lib/rendro/
├── text/
│   ├── shaper.ex          # behaviour module (becomes PUBLIC: @moduledoc tags: [:stable])
│   ├── shaper/
│   │   └── simple.ex      # Rendro.Text.Shaper.Simple (pure Elixir, tier :stable)
│   └── bidi.ex            # migrated to unicode package
├── adapters/
│   └── harfbuzz.ex        # Rendro.Adapters.HarfBuzz (if Code.ensure_loaded?(HarfbuzzEx))
└── pipeline/
    └── measure.ex         # split_graphemes fixed, hard-match sites softened
```

### Pattern 1: Behaviour with compile-gated implementation (existing pattern from Accrue/Phoenix/Oban)

```elixir
# lib/rendro/text/shaper.ex — becomes the behaviour
defmodule Rendro.Text.Shaper do
  @moduledoc """
  Behaviour for text shaping adapters.
  ...
  """
  @moduledoc tags: [:stable]

  @type glyph :: %{
    gid: non_neg_integer(),
    cluster: non_neg_integer(),
    x_advance: integer(),
    y_advance: integer(),
    x_offset: integer(),
    y_offset: integer()
  }

  @callback shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
    {:ok, [glyph()]} | {:error, term()}

  @spec impl() :: module()
  def impl do
    Application.get_env(:rendro, :shaper, Rendro.Text.Shaper.Simple)
  end

  @spec shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
    {:ok, [glyph()]} | {:error, term()}
  def shape(font, text, opts \\ []) do
    impl().shape(font, text, opts)
  end
end
```

### Pattern 2: Compile-gated adapter (mirrors lib/rendro/adapters/accrue.ex)

```elixir
# lib/rendro/adapters/harfbuzz.ex
if Code.ensure_loaded?(HarfbuzzEx) do
  defmodule Rendro.Adapters.HarfBuzz do
    @moduledoc """
    HarfBuzz shaping adapter via harfbuzz_ex NIF.
    Requires {:harfbuzz_ex, "~> 1.2", optional: true} in your mix.exs.
    ...
    """
    @moduledoc tags: [:adapter]

    @behaviour Rendro.Text.Shaper

    @impl Rendro.Text.Shaper
    def shape(%Rendro.PDF.Font{source: :embedded, font_bytes: bytes}, text, _opts)
        when is_binary(bytes) do
      hash = :crypto.hash(:sha256, bytes) |> Base.encode16()
      temp_dir = System.tmp_dir() || "/tmp"
      font_path = Path.join(temp_dir, "rendro_font_#{hash}.ttf")
      unless File.exists?(font_path), do: File.write!(font_path, bytes)

      raw_glyphs = HarfbuzzEx.get!(font_path, text, :all)
      # Derive cluster from sequential grapheme byte offsets (approximation for pre-composed)
      glyphs = enrich_with_cluster(raw_glyphs, text)

      missing = Enum.count(glyphs, fn g -> g.name == ".notdef" end)
      if missing > 0 do
        :telemetry.execute([:rendro, :shaper, :missing_glyph],
          %{count: missing}, %{font: font_path, text: text})
      end
      {:ok, glyphs}
    rescue
      e -> {:error, e}
    end
    # ... built_in branch ...
  end
end
```

### Pattern 3: Complex-script gate inside Shaper.Simple

```elixir
# lib/rendro/text/shaper/simple.ex
@requires_shaping MapSet.new([
  :arab, :syrc, :nkoo, :mong,   # joining scripts
  :hebr,                          # Hebrew/RTL (no UAX#9)
  :deva, :beng, :guru, :gujr, :orya, :taml, :telu, :knda, :mlym, :sinh,  # Indic
  :thai, :laoo, :khmr, :mymr,   # SEA
  :tibt                           # Tibetan
])

@impl Rendro.Text.Shaper
def shape(font, text, opts) do
  script = Keyword.get(opts, :script, :latn)
  if MapSet.member?(@requires_shaping, script) do
    hint = if Code.ensure_loaded?(HarfbuzzEx) do
      "\n    Add to your config: config :rendro, shaper: Rendro.Adapters.HarfBuzz"
    else
      "\n    Add harfbuzz_ex to deps and: config :rendro, shaper: Rendro.Adapters.HarfBuzz"
    end
    {:error, {:shaping_required, script, hint}}
  else
    do_shape(font, text)
  end
end
```

### Pattern 4: Softening hard-match sites in measure.ex

The two sites currently use `{:ok, glyphs} = Rendro.Text.Shaper.shape(font, text)` (lines ~607, ~667). These become `case`/`with` that propagate errors via the existing `reduce_while` halt path:

```elixir
# Before (line ~607 in split_graphemes):
{:ok, glyphs} = Rendro.Text.Shaper.shape(font, grapheme)

# After:
case Rendro.Text.Shaper.shape(font, grapheme) do
  {:ok, glyphs} -> # continue
  {:error, reason} -> {:halt, {:error, reason}}
end

# Before (line ~667 in measure_text_into_runs):
{:ok, glyphs} = Rendro.Text.Shaper.shape(font, sub_text)

# After:
case Rendro.Text.Shaper.shape(font, sub_text, script: bidi_run.script) do
  {:ok, glyphs} -> # continue
  {:error, reason} -> {:halt, {:error, reason}}
end
```

### Pattern 5: Unicode package migration (UnicodeData → unicode)

```elixir
# BEFORE (lib/rendro/text/bidi.ex resolve_state/1):
script_name = UnicodeData.Script.script_from_codepoint(cp)
# returns String: "Arabic", "Latin", "Common", "Inherited", "Unknown"

script_tag = if script_name in ["Common", "Inherited", "Unknown"] do
  :common
else
  script_name |> UnicodeData.Script.script_to_tag() |> String.to_atom()
  # script_to_tag returns 4-letter lowercase string: "arab", "latn", etc.
end

bidi_class = UnicodeData.Bidi.bidi_class(cp)
# returns String: "L", "R", "AL", "EN", "WS", etc.

direction = case bidi_class do
  "L" -> :ltr
  "R" -> :rtl
  "AL" -> :rtl
  _ -> :neutral
end

# AFTER (migrated to unicode package):
script_atom = Unicode.script(cp)
# returns atom: :arabic, :latin, :common, :inherited, :unknown

script_tag = if script_atom in [:common, :inherited, :unknown] do
  :common
else
  # unicode package returns :arabic → need to convert to 4-letter OT tag
  # unicode does NOT have script_to_tag/1 — must build internal map
  # OR keep the existing OpenType tag map from unicode_data (copy into Bidi or helper module)
  to_opentype_tag(script_atom)
end

bidi_class = Unicode.BidiClass.bidi_class(cp)
# returns atom: :l, :r, :al, :en, :ws, :s, :b, :an, :cs, :et, :nsm, :bn, :pdf, :lre, :lro, :rle, :rlo, :lri, :rli, :fsi, :pdi, :on

direction = case bidi_class do
  :l -> :ltr
  :r -> :rtl
  :al -> :rtl
  _ -> :neutral
end
```

**CRITICAL:** `Unicode.script/1` returns atoms (`:arabic`, `:latin`) but does NOT have a `script_to_tag/1` equivalent that maps to OpenType 4-letter tags. The `unicode_data` package's `script_to_tag/1` is a large mapping table (~100 entries). This table must be preserved — either copied into `Rendro.Text.Bidi` as a private function, or extracted to a helper module.

### Pattern 6: Shaper opts threading (how script tag flows to shape/3)

The script tag originates in `Rendro.Text.Bidi.split_runs/1` → each run has `%{text, script, direction}`. The `measure_text_into_runs` function in `measure.ex` iterates bidi runs and calls `Shaper.shape`. The `opts` parameter added to `shape/3` allows:

```elixir
# In measure_text_into_runs (~line 667):
Rendro.Text.Shaper.shape(font, sub_text, script: bidi_run.script)
```

### Anti-Patterns to Avoid

- **Auto-detecting HarfBuzz by presence:** `Code.ensure_loaded?` gates compile-time existence; it must NEVER determine the active shaper at runtime (D-02). The active shaper is config-only.
- **Gating in Rendro.Adapters.HarfBuzz:** The adapter never gates on script (D-08). If it receives Arabic text, it shapes it.
- **Two paths in split_graphemes:** D-11 forbids a bug-compatible per-grapheme branch. One implementation, cluster-aware everywhere.
- **Re-using `{:ok, glyphs} =` pattern match on shape/3 calls:** These are MatchError crashes if the shaper returns `{:error, _}`. All call sites must use `case` or `with`.
- **Leaving `@moduledoc false` on `Rendro.Text.Shaper`:** The behaviour must become public (remove from `hidden_modules` list, add `@moduledoc tags: [:stable]`). Leaving it hidden breaks the contract test and the API manifest.
- **Forgetting `@type glyph` and `@spec` on the behaviour:** Stable-tier modules require `@spec` on all public functions per `public_api_contract_test.exs` Assertion 5.
- **Adding `Rendro.Text.Shaper.Simple` to mix.exs docs groups:** The Simple module is `:stable` tier but its exact `@moduledoc` must include `tags: [:stable]` for the tier-tag test to pass.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Unicode script name from codepoint | Custom lookup table | `Unicode.script/1` | Maintained, tracks Unicode 17.0 as of v1.22.0 |
| Bidi class from codepoint | Custom DerivedBidiClass.txt parser | `Unicode.BidiClass.bidi_class/1` | Same maintainer, same data currency |
| OpenType 4-letter script tag mapping | Fresh research and table | Copy `UnicodeData.Script.script_to_tag/1` map body (already correct, ~100 entries) | Only needed for the `:latn`→`"latn"` style mapping; the `unicode` package doesn't provide it |
| Optional-dep compile gate | Custom macro | `if Code.ensure_loaded?(HarfbuzzEx) do` (mirrors existing `accrue.ex`) | Established pattern in this codebase |
| Stage-boundary error wrapping | New error struct | `Rendro.Error.from_stage(:measure, {:shaping_required, script})` | Existing pattern for `{:unsupported_glyph, _}` |

---

## Runtime State Inventory

> This is a refactor phase but involves no renames. Omitting — no stored runtime state uses the shaper module name as a key.

None — verified: harfbuzz_ex temp files use SHA256 font hash keys (not module names), config keys use `:rendro` app name (unchanged), no OS-registered state, no persistent databases involved. Re-bless of golden tests is a code-artifact change, not a runtime data migration.

---

## Common Pitfalls

### Pitfall 1: Unicode return type mismatch (string vs atom)

**What goes wrong:** `UnicodeData.Script.script_from_codepoint/1` returns strings like `"Arabic"`, `"Latin"`, `"Common"`. `Unicode.script/1` returns atoms like `:arabic`, `:latin`, `:common`. The `Rendro.Text.Bidi.split_runs/1` code currently matches on the strings `"Common"`, `"Inherited"`, `"Unknown"` and then calls `String.to_atom/1` on the result of `script_to_tag/1`. After migration, the guard check must change to atoms, and the `script_to_tag` step maps atoms to lowercase 4-letter strings.

**Why it happens:** Different design choices between the two packages — `unicode_data` uses Unicode's official mixed-case property names as strings; `unicode` (ex_unicode) uses lowercase atoms throughout.

**How to avoid:** Write the full `resolve_state/1` replacement in one pass, changing all three call sites (script_from_codepoint, script_to_tag check, bidi_class + direction match) atomically.

**Warning signs:** `bidi_test.exs` tests passing but run itemization producing wrong atoms (`:arabic` vs `:arab`) because the OT tag derivation step is wrong.

### Pitfall 2: OpenType tag mapping has no equivalent in `unicode` package

**What goes wrong:** `Unicode.script/1` returns `:arabic` but Rendro's internal code uses OpenType 4-letter tags (`:arab`, `:latn`, `:hebr`, etc.) for the script field in run maps. The `unicode` package has no `script_to_tag/1` equivalent.

**Why it happens:** The `unicode` package is a Unicode introspection library, not an OpenType layout library. OpenType script tags are a separate concern.

**How to avoid:** Extract the tag mapping from `UnicodeData.Script.script_to_tag/1` (lines ~32-200 in `deps/unicode_data/lib/unicodedata/script.ex`) into a private `to_opentype_tag/1` function within `Rendro.Text.Bidi`. The existing table is complete through Unicode 12.0 — adequate for this phase's scope (complex scripts added in Unicode 13.0+ are in the curated requires-shaping set regardless of tag).

**Warning signs:** Test failures on `bidi_test.exs` where script atoms don't match the expected `:arab`, `:latn`, `:hebr` atoms.

### Pitfall 3: harfbuzz_ex NIF drops the cluster field

**What goes wrong:** D-05 locks the behaviour glyph type to include `cluster: non_neg_integer()`. The HarfBuzz NIF's Rust source (`shaper_shape` in `lib.rs`) maps `info.glyph_id` and positions but does NOT extract `info.cluster` (which is the input byte offset for the cluster boundary). The `%HarfbuzzEx.Shaper.Glyph{}` struct has no `cluster` field.

**Why it happens:** The `harfbuzz_ex` v1.2.0 NIF was built to expose only glyph metrics, not cluster mapping.

**How to avoid (two acceptable approaches):**
1. **Sequential approximation (recommended for this phase):** In `Rendro.Adapters.HarfBuzz.enrich_with_cluster/2`, derive `cluster` by mapping each glyph to the byte offset of the corresponding grapheme in the input string. For pre-composed scripts (Latin, Han, etc.) where `Shaper.Simple` would handle them anyway, this is exact. For complex scripts where contextual shaping fuses multiple graphemes into one glyph, the cluster approximation is imprecise — but since `Rendro.Adapters.HarfBuzz` will only be used for complex scripts where actual HarfBuzz shaping is needed, the approximation is acceptable until a future harfbuzz_ex version exposes cluster.
2. **Force NIF build with cluster:** Fork `harfbuzz_ex` or add `info.cluster` to the Rust NIF. Deferred — out of scope for this phase.

**Warning signs:** The `split_graphemes` cluster-boundary fix produces incorrect line breaks for HarfBuzz-shaped Arabic text. Acceptable for this phase since Arabic is behind the `{:shaping_required, :arab}` gate in `Shaper.Simple` — HarfBuzz adapter will only be exercised in tests, not in the Latin-golden path.

### Pitfall 4: Two hard-match sites in measure.ex will MatchError on shaping gate

**What goes wrong:** `measure_text_into_runs` at line ~667 uses `{:ok, glyphs} = Rendro.Text.Shaper.shape(font, sub_text)`. When `Shaper.Simple` returns `{:error, {:shaping_required, :arab}}`, this raises a MatchError instead of flowing through the pipeline error path.

**Why it happens:** The current code assumes shaping always succeeds. The existing `{:error, {:unsupported_glyph, _}}` path in `resolve_fonts_for_run` flows correctly because `find_font_for_grapheme/2` returns `:error` not a tuple, which propagates through `reduce_while`.

**How to avoid:** Change both hard-match sites to `case` expressions. Also update `split_graphemes` (~line 607) which has the same pattern.

**Warning signs:** `{MatchError, message: "no match of right hand side value: {:error, ...}"}` in test output rather than a structured `{:error, %Rendro.Error{}}`.

### Pitfall 5: support_matrix.json schema validation catches viewer_row structure issues

**What goes wrong:** The existing `explicit_deferral` rows in `support_matrix.json` conform to the `viewer_row` schema definition (required: `evidence_deferred`, forbidden: `evidence`, `recorded_at`, `viewer_kind`). New script-support rows are NOT viewer rows — they live under a new top-level `text_shaping` section which is not covered by `@viewer_maps` in `Rendro.ViewerEvidence.Matrix`.

**Why it happens:** `Matrix.enumerate_viewer_cells/1` has a hard-coded list of 8 `@viewer_maps` paths. A new `text_shaping` section is invisible to it and won't be promotion-validated by `validate_promotion_complete/1`.

**How to avoid:** Add the new `text_shaping` section using a free-form structure (JSON object with named script families and `status`/`evidence_deferred` fields). The `additionalProperties: true` at the schema root level allows this. Write a new docs-contract test that asserts the four named script families have `explicit_deferral` status and non-empty `evidence_deferred` strings (similar to the `signing_claims_test.exs` pattern that reads the matrix directly).

**Warning signs:** `priv/support_matrix.json` changes pass JSV schema validation but drift from README/guide claims goes undetected because no docs-contract test asserts the new section.

### Pitfall 6: public_api_contract_test.exs has Assertion 3 that pins Rendro.Text.Shaper as hidden

**What goes wrong:** Test file line ~89 lists `Rendro.Text.Shaper` in `hidden_modules`. When the module is promoted to public with `@moduledoc tags: [:stable]`, this assertion will fail.

**Why it happens:** The test was written when `Shaper` was an internal engine module.

**How to avoid:** Remove `Rendro.Text.Shaper` from the `hidden_modules` list in Assertion 3, add it to `@adapter_files` in `Rendro.PublicApi` (so conditional compilation works), run `mix rendro.api.gen`, commit updated `priv/public_api.json`. Also add `Rendro.Text.Shaper.Simple` to `mix.exs` docs `groups_for_modules` and `Rendro.Adapters.HarfBuzz` to the "Ecosystem Adapters" group.

**Warning signs:** CI failing on `public_api_contract_test` with "Expected internal module Rendro.Text.Shaper to have @moduledoc false (:hidden)".

### Pitfall 7: Per-grapheme fix with Shaper.Simple is byte-identical by construction, but needs a property test to prove it

**What goes wrong (D-12):** Someone might doubt whether the cluster-boundary fix changes Latin output. Under `Shaper.Simple`, `split_graphemes` reshapes runs of graphemes — but `Shaper.Simple` uses only cmap + advance widths with no cross-grapheme effects. Per-grapheme and per-run results should be numerically identical. Without a test, this claim is a belief.

**How to avoid:** Add a `StreamData` property test that generates random Latin strings and asserts `per_grapheme_width_sum == per_run_width` under `Shaper.Simple`.

---

## Code Examples

### Exact current API of `UnicodeData.Script` (to be replaced)

```elixir
# Source: deps/unicode_data/lib/unicodedata/script.ex (compiled from Scripts.txt)

UnicodeData.Script.script_from_codepoint(0x0627)
# => "Arabic"   (String)

UnicodeData.Script.script_from_codepoint(?A)
# => "Latin"   (String)

UnicodeData.Script.script_from_codepoint(0x200D)
# => "Inherited"   (String — zero-width joiner)

UnicodeData.Script.script_to_tag("Arabic")
# => "arab"   (String — 4-letter OT tag)

UnicodeData.Script.script_to_tag("Latin")
# => "latn"   (String)

UnicodeData.Script.script_to_tag("Hebrew")
# => "hebr"   (String)
```

### Exact replacement API in `Unicode` (verified against hexdocs.pm/unicode v1.22.0)

```elixir
# Source: [VERIFIED: hexdocs.pm/unicode/Unicode.Script.html + Unicode.BidiClass.html]

Unicode.script(0x0627)
# => :arabic   (atom)

Unicode.script(?A)
# => :latin   (atom)

Unicode.script(0x200D)
# => :inherited   (atom)

# NO script_to_tag equivalent exists — must use internal map

Unicode.BidiClass.bidi_class(0x0627)
# => :al   (atom, Arabic Letter)

Unicode.BidiClass.bidi_class(?A)
# => :l   (atom, Left-to-Right)

Unicode.BidiClass.bidi_class(0x05D0)
# => :r   (atom, Right-to-Left)

Unicode.BidiClass.bidi_class(?.)
# => :cs   (atom, Common Separator — not :l/:r/:al, so → :neutral)
```

### Exact current API of `HarfbuzzEx.get!`

```elixir
# Source: deps/harfbuzz_ex/lib/harfbuzz_ex.ex (verified directly)
# [VERIFIED: local source inspection]

# get!/3 starts a GenServer, shapes, stops. Returns list of %HarfbuzzEx.Shaper.Glyph{}.
HarfbuzzEx.get!(font_path, text, :all)
# => [%HarfbuzzEx.Shaper.Glyph{name: "H", x_advance: 634, y_advance: 0, x_offset: 0, y_offset: 0}, ...]
# NOTE: NO cluster field in the struct

# Other data argument options:
HarfbuzzEx.get!(font_path, text, :name)       # => ["H", "e", "l", "l", "o"]
HarfbuzzEx.get!(font_path, text, :x_advance)  # => [634, 321, ...]
```

### support_matrix.json: explicit_deferral row vocabulary (from existing pdfjs row)

```json
{
  "pdfjs": {
    "status": "explicit_deferral",
    "evidence_deferred": "PDF.js failed the forms four-check save-and-reopen round-trip on the representative fixture during Phase 71 operator review; edit_or_toggle persistence is not reliable."
  }
}
```

Required fields for `explicit_deferral`: `status` + `evidence_deferred` (minLength: 40).
Forbidden fields: `evidence`, `recorded_at`, `viewer_kind`.

### Proposed text_shaping section structure for priv/support_matrix.json

```json
{
  "text_shaping": {
    "latin_and_cjk": {
      "status": "supported",
      "capabilities": ["cmap_advance_widths", "font_fallback_chain"],
      "engine": "Rendro.Text.Shaper.Simple"
    },
    "arabic": {
      "status": "explicit_deferral",
      "evidence_deferred": "Arabic shaping requires contextual glyph substitution, joining forms, and right-to-left reordering that Shaper.Simple does not implement; full shaping is demand-gated at LNCH-03. Use harfbuzz_ex optional dep with config :rendro, shaper: Rendro.Adapters.HarfBuzz."
    },
    "hebrew_rtl": {
      "status": "explicit_deferral",
      "evidence_deferred": "Hebrew rendering requires UAX #9 bidi reordering which is not implemented in Rendro.Text.Bidi; visual reordering and RTL line presentation are deferred to v2.7 behind the LNCH-03 demand gate."
    },
    "devanagari": {
      "status": "explicit_deferral",
      "evidence_deferred": "Devanagari and other Indic scripts require complex glyph reordering, conjunct formation, and matra positioning that Shaper.Simple does not implement; deferred to v2.7 behind the LNCH-03 demand gate."
    },
    "thai": {
      "status": "explicit_deferral",
      "evidence_deferred": "Thai and other SEA scripts require cluster-aware line breaking, vowel positioning, and tone mark handling that Shaper.Simple does not implement; deferred to v2.7 behind the LNCH-03 demand gate."
    }
  }
}
```

### Error.from_stage for shaping_required (new clause to add in error.ex)

```elixir
# Add to Rendro.Error for the new {:shaping_required, script} reason:
defp why(_stage, {:shaping_required, script}),
  do: "Script #{inspect(script)} requires a shaping adapter; Shaper.Simple cannot produce correct output for this script."

defp next_step(:measure, {:shaping_required, script}) do
  hint = if Code.ensure_loaded?(HarfbuzzEx) do
    "Add to your config: config :rendro, shaper: Rendro.Adapters.HarfBuzz"
  else
    "Add {:harfbuzz_ex, \"~> 1.2\", optional: true} to deps and: config :rendro, shaper: Rendro.Adapters.HarfBuzz"
  end
  "Script #{inspect(script)} requires a shaping adapter. #{hint}"
end
```

---

## State of the Art

| Old Approach | Current Approach | Impact for This Phase |
|--------------|------------------|----------------------|
| `unicode_data 0.8.0` (2019-era tables, unmaintained) | `unicode 1.22.0` (Unicode 17.0 data, actively maintained) | Script codepoint tables may reclassify some codepoints — run itemization diffs on fixtures required (PITFALL #1 above) |
| `UnicodeData.Script.script_from_codepoint/1` returns String | `Unicode.script/1` returns atom | All guard/match expressions in `bidi.ex` must change |
| `UnicodeData.Bidi.bidi_class/1` returns String ("L", "R", "AL") | `Unicode.BidiClass.bidi_class/1` returns atom (:l, :r, :al) | Direction switch in `bidi.ex` must match on atoms |
| `Rendro.Text.Shaper` is a concrete module calling HarfbuzzEx directly | `Rendro.Text.Shaper` is a behaviour with `Shaper.Simple` + `Adapters.HarfBuzz` | Clears the "pure Elixir core" claim |
| `harfbuzz_ex` is a hard dep (NIF always compiled) | `harfbuzz_ex` is optional (NIF only if user adds it) | Users without HarfBuzz get zero NIF compilation for Latin PDF rendering |
| Per-grapheme shaping in `split_graphemes` | Per-run shaping, break at cluster boundaries | Latin output byte-identical (by construction under `Shaper.Simple`); HarfBuzz path may legitimately shift wrapped-text goldens |

**Deprecated:**
- `unicode_data` hex package: officially retired on hex.pm — "Renamed to 'unicode' version 1.13 and later". `[VERIFIED: hex.pm]`
- `UnicodeData.Script`, `UnicodeData.Bidi` modules: removed with the package.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Sequential cluster approximation (derive cluster from grapheme byte offsets) is acceptable for this phase since Arabic/Hebrew/Indic/SEA are behind the shaping gate and won't reach `Adapters.HarfBuzz` in typical use | Architecture Patterns / Pitfall 3 | If a caller bypasses the gate (configures HarfBuzz adapter and renders Arabic), cluster values will be approximate — line breaks at cluster boundaries could be incorrect for ligatures |
| A2 | `Unicode.script/1` returns `:common` for Common and `:inherited` for Inherited codepoints (matching the guard logic in bidi.ex) | Code Examples | If the atom names differ (e.g., `:inherited` is returned as `:zinh` per ISO 15924), the neutral codepoint detection in `resolve_state/1` will break |
| A3 | The new `text_shaping` section in `support_matrix.json` will satisfy HYG-05 requirements without schema changes — `additionalProperties: true` at top level covers it | Architecture Patterns / Pitfall 5 | If the schema validator is tightened before this phase ships, the new section might fail validation |
| A4 | `mix rendro.api.gen` regenerates `priv/public_api.json` correctly when the new stable-tier modules (`Rendro.Text.Shaper`, `Rendro.Text.Shaper.Simple`) are added | D-06 | If the generator's `public_modules/0` discovery doesn't pick up the new modules, the manifest will be stale and the contract test will fail |

**If this table is empty:** N/A — four assumptions remain. A2 is the highest risk; verify `Unicode.script/1` return atoms for Common/Inherited in the first implementation task.

---

## Open Questions

1. **Does `Unicode.script/1` return `:common` and `:inherited` as those exact atoms?**
   - What we know: documentation confirms atoms for Arabic, Latin, Hebrew, Devanagari examples.
   - What's unclear: the exact atom for Common (could be `:common` or `:zinh` or `:zyyy`).
   - Recommendation: Add an early `iex> Unicode.script(0x200D)` verification step in the implementation task.

2. **Should the OpenType tag map be co-located in `bidi.ex` or extracted to a new `Rendro.Text.ScriptTags` helper?**
   - What we know: the map is ~100 entries and is currently in `UnicodeData.Script.script_to_tag/1`.
   - What's unclear: whether future phases (v2.7 shaping) will also need it.
   - Recommendation: Claude's discretion. Given future v2.7 use, a `lib/rendro/text/script_tags.ex` module (private/internal, `@moduledoc false`) is cleaner than embedding 100 map entries in `bidi.ex`.

3. **Does `Rendro.Text.Shaper.Simple` need its own file or can it stay as a nested module in `shaper.ex`?**
   - What we know: D-04 locks the module name as `Rendro.Text.Shaper.Simple`, suggesting a file at `lib/rendro/text/shaper/simple.ex`.
   - Recommendation: Separate file. The `docs` grouping in `mix.exs` will be cleaner, and the module is stable-tier requiring its own `@moduledoc`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All | ✓ | 1.19.5 | — |
| Erlang/OTP | All | ✓ | 28 (OTP 28) | — |
| Mix | Build | ✓ | 1.19.5 | — |
| `unicode` hex package | HYG-04 | ✗ (not yet in deps) | 1.22.0 on hex.pm | `mix deps.get` after mix.exs change |
| `harfbuzz_ex` NIF | HYG-01 (optional) | ✓ | 1.2.0 (in mix.lock) | N/A — becoming optional |

**Missing dependencies with no fallback:** None — `unicode` is available on hex.pm and installed via `mix deps.get`.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + StreamData |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/text/ test/rendro/pipeline/measure_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HYG-01 | `harfbuzz_ex` optional; `Shaper.Simple` compiles without NIF | unit | `mix test test/rendro/text/shaper_test.exs` | ✅ (needs rewrite) |
| HYG-01 | `Rendro.Text.Shaper` is public with `:stable` tag and `@spec` | contract | `mix test test/docs_contract/public_api_contract_test.exs` | ✅ (needs hidden_modules update) |
| HYG-01 | `priv/public_api.json` byte-matches regenerated manifest | contract | `mix test test/docs_contract/public_api_contract_test.exs` | ✅ (needs mix rendro.api.gen) |
| HYG-02 | Arabic text with `Shaper.Simple` returns `{:error, {:shaping_required, :arab}}` | unit | `mix test test/rendro/text/shaper_test.exs` | ✅ (new test needed) |
| HYG-02 | Shaping error propagates through measure stage as structured `Rendro.Error` | integration | `mix test test/rendro/pipeline/measure_test.exs` | ✅ (new test needed) |
| HYG-03 | Latin golden output byte-identical after cluster fix | deterministic | `mix test test/rendro/deterministic_test.exs` | ✅ |
| HYG-03 | Per-grapheme == per-run widths under `Shaper.Simple` (property test) | property | `mix test test/rendro/text/shaper_test.exs` | ❌ Wave 0 gap |
| HYG-04 | Bidi run itemization for Latin/Arabic/Hebrew unchanged after unicode migration | unit | `mix test test/rendro/text/bidi_test.exs` | ✅ (existing tests cover key cases) |
| HYG-04 | No change to wrapped-text line assignments for existing fixture strings | regression | `mix test test/rendro/pipeline/measure_test.exs` | ✅ (existing tests) |
| HYG-05 | `priv/support_matrix.json` has four explicit_deferral rows with evidence_deferred | contract | new docs_contract test | ❌ Wave 0 gap |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/text/ test/rendro/pipeline/measure_test.exs test/docs_contract/public_api_contract_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/rendro/text/shaper_test.exs` — property test for per-grapheme == per-run width invariant under `Shaper.Simple` (HYG-03 / D-12)
- [ ] `test/docs_contract/script_support_claims_test.exs` — asserts the four HYG-05 script families have `explicit_deferral` status and non-empty `evidence_deferred` in `priv/support_matrix.json`
- [ ] The existing `shaper_test.exs` needs a new test for `{:error, {:shaping_required, script}}` on Arabic input (HYG-02)
- [ ] The existing `measure_test.exs` needs a new test that a document with Arabic text returns a structured `Rendro.Error` from `Measure.run/1` (HYG-02)

---

## Security Domain

> `security_enforcement` is not explicitly disabled in `.planning/config.json` — included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | `Rendro.Error.from_stage/3` + structured error tuples; no user-controlled input reaches the shaper beyond text content already validated upstream |
| V6 Cryptography | no | — (the SHA256 font cache key is for deduplication, not security) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via font temp file | Tampering | SHA256-keyed filename (already in place); no user-supplied path components |
| Silent incorrect output (Arabic as disconnected glyphs) | Spoofing | HYG-02 gate — `{:error, {:shaping_required, script}}` prevents silent wrong rendering |
| Overclaiming script support in docs | Repudiation | HYG-05 — `explicit_deferral` rows in support matrix + docs-contract test bounds claims |

---

## Sources

### Primary (HIGH confidence)

- Direct source inspection of `lib/rendro/text/shaper.ex` — current HarfbuzzEx call pattern and glyph map structure
- Direct source inspection of `lib/rendro/text/bidi.ex` — UnicodeData.Script/Bidi call sites (lines 64–83)
- Direct source inspection of `lib/rendro/pipeline/measure.ex` — `split_graphemes` (601–650), `measure_text_into_runs` (658–688), two hard-match sites (~607, ~667)
- Direct source inspection of `deps/harfbuzz_ex/native/harfbuzz_ex/src/lib.rs` — Rust NIF confirms cluster field is NOT exposed
- Direct source inspection of `deps/harfbuzz_ex/lib/harfbuzz_ex.ex` — `get!/3` signature and return type
- Direct source inspection of `deps/harfbuzz_ex/lib/glyph.ex` — `%HarfbuzzEx.Shaper.Glyph{}` struct fields
- Direct source inspection of `deps/unicode_data/lib/unicodedata/script.ex` and `bidi.ex` — current return types (strings)
- Direct source inspection of `lib/rendro/public_api.ex` — `@adapter_files` list and `recompile_conditional_adapters/0`
- Direct source inspection of `lib/rendro/adapters/accrue.ex` — `Code.ensure_loaded?` compile-gate pattern
- Direct source inspection of `test/docs_contract/public_api_contract_test.exs` — `hidden_modules` list at line ~89, Assertion 3 structure
- Direct source inspection of `priv/support_matrix.json` — `explicit_deferral` row vocabulary
- Direct source inspection of `priv/schemas/support_matrix.schema.json` — `viewer_row` schema, `additionalProperties: true` at root
- Direct source inspection of `lib/rendro/viewer_evidence/matrix.ex` — hard-coded `@viewer_maps` (8 paths; new `text_shaping` section is invisible to it)
- hex.pm API for `unicode` — version 1.22.0, 946,031 downloads `[VERIFIED: hex.pm API]`
- hex.pm API for `harfbuzz_ex` — version 1.2.0, 755 downloads, github.com/jkwchui/harfbuzz_ex `[VERIFIED: hex.pm API]`
- hex.pm package page for `ex_unicode` — retired, renamed to `unicode` at v1.13 `[VERIFIED: hex.pm]`

### Secondary (MEDIUM confidence)

- [unicode hexdocs — Unicode.Script.html](https://unicode.hexdocs.pm/Unicode.Script.html) — `script/1` returns atom; `known_scripts/0`, `scripts/0` functions; no OT tag function `[CITED: unicode.hexdocs.pm]`
- [unicode hexdocs — Unicode.BidiClass.html](https://unicode.hexdocs.pm/Unicode.BidiClass.html) — `bidi_class/1` returns atoms `:l`, `:r`, `:al` for L/R/AL bidi classes `[CITED: unicode.hexdocs.pm]`
- [unicode hexdocs — Unicode.html](https://unicode.hexdocs.pm/Unicode.html) — `Unicode.script/1` returns `:arabic`, `:latin`, `:hebrew`, `:devanagari` for example codepoints `[CITED: unicode.hexdocs.pm]`
- [harfbuzz_ex GitHub](https://github.com/jkwchui/harfbuzz_ex) — confirms `get/2` and `get/3` API, no cluster field in README `[CITED: github.com/jkwchui/harfbuzz_ex]`

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified via hex.pm API + local dep inspection
- Architecture: HIGH — all key code paths read directly from source
- Pitfalls: HIGH — every pitfall derives from direct source observation (hard-match sites, cluster field absence, atom/string return type, hidden_modules test list)
- Unicode API mapping: MEDIUM — function signatures verified via hexdocs; exact atoms for Common/Inherited (A2 in Assumptions Log) confirmed by example but not exhaustively tested

**Research date:** 2026-06-10
**Valid until:** 2026-08-10 (stable packages; `unicode` v1.22.0 tracks Unicode 17.0 and is actively maintained)
