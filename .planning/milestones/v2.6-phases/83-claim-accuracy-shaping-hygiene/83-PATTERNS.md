# Phase 83: Claim-Accuracy & Shaping Hygiene - Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 10 new/modified surfaces
**Analogs found:** 10 / 10

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/text/shaper.ex` | behaviour (rewrite) | request-response | `lib/rendro/sign/adapter.ex` (behaviour def) + current `shaper.ex` (content source) | exact — same module, promoted to behaviour |
| `lib/rendro/text/shaper/simple.ex` | service (new) | request-response | `lib/rendro/text/shaper.ex` (current logic to extract) | role-match |
| `lib/rendro/adapters/harfbuzz.ex` | adapter (new) | request-response | `lib/rendro/adapters/accrue.ex` | exact — same `Code.ensure_loaded?` compile-gate + `@moduledoc tags: [:adapter]` |
| `lib/rendro/text/bidi.ex` | utility (rewrite) | transform | `lib/rendro/text/bidi.ex` itself (self-analog) | exact — same file, API swap |
| `lib/rendro/pipeline/measure.ex` | service (edit) | transform | `lib/rendro/pipeline/measure.ex` itself — `{:unsupported_glyph, _}` path at line 633 | exact — same error-propagation seam |
| `lib/rendro/error.ex` | utility (edit) | transform | `lib/rendro/error.ex` — existing `why/2` + `next_step/2` clauses at lines 114, 241–247 | exact — append new pattern-matched clauses |
| `lib/rendro/public_api.ex` | config (edit) | — | `lib/rendro/public_api.ex` — `@adapter_files` at line 6 | exact — prepend one entry to existing list |
| `mix.exs` | config (edit) | — | `mix.exs` lines 45–46 (deps) + lines 167–175 (groups_for_modules Ecosystem Adapters) | exact |
| `priv/support_matrix.json` | config (edit) | — | `priv/support_matrix.json` — `pdfjs` explicit_deferral row at line 65–68 | exact vocabulary |
| `test/docs_contract/script_support_claims_test.exs` | test (new) | — | `test/docs_contract/signing_claims_test.exs` | exact — same structure: read matrix JSON, assert/refute string keys |

---

## Pattern Assignments

---

### `lib/rendro/text/shaper.ex` — behaviour rewrite (behaviour, request-response)

**Analog:** Current `lib/rendro/text/shaper.ex` (content to transform) + `lib/rendro/public_api.ex` (tier-tag pattern)

**Current module header to replace** (lines 1–3):
```elixir
defmodule Rendro.Text.Shaper do
  @moduledoc false
```

**Target module header pattern** (copy `@moduledoc tags:` from `lib/rendro/adapters/accrue.ex` line 52):
```elixir
defmodule Rendro.Text.Shaper do
  @moduledoc """
  Behaviour for text shaping adapters.

  Implement this behaviour to provide a custom text shaping engine.
  The default implementation is `Rendro.Text.Shaper.Simple` (pure Elixir, cmap + advance widths).
  For complex scripts (Arabic, Indic, Thai, etc.) configure `Rendro.Adapters.HarfBuzz`.

  ## Configuration

      config :rendro, shaper: Rendro.Adapters.HarfBuzz

  ## Per-render override

      Rendro.render(doc, shaper: Rendro.Adapters.HarfBuzz)
  """
  @moduledoc tags: [:stable]
```

**`@type glyph` — required by stable-tier contract** (Assertion 5 in `test/docs_contract/public_api_contract_test.exs` line 210 requires `@spec` on every stable-tier public function; `@type` is not tested separately but required by D-05):
```elixir
  @type glyph :: %{
    gid: non_neg_integer(),
    cluster: non_neg_integer(),
    x_advance: integer(),
    y_advance: integer(),
    x_offset: integer(),
    y_offset: integer()
  }
```

**`@callback` and public delegation functions with `@spec`** (stable-tier functions need `@spec` — contract test line 211–241):
```elixir
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
```

**Tier-tag enforcement** — the contract test at `test/docs_contract/public_api_contract_test.exs` lines 163–203 verifies exactly one tier tag (`:stable` xor `:adapter`). `Rendro.Text.Shaper` takes `:stable`.

---

### `lib/rendro/text/shaper/simple.ex` — new pure-Elixir implementation (service, request-response)

**Analog:** `lib/rendro/text/shaper.ex` lines 8–27 (built-in font branch) and lines 29–57 (embedded font branch) — extract and adapt this logic

**Module header** (copy `@moduledoc tags: [:stable]` from accrue.ex line 52 pattern):
```elixir
defmodule Rendro.Text.Shaper.Simple do
  @moduledoc """
  Pure-Elixir text shaper. Uses cmap advance widths only — no NIF compilation required.

  This is the default shaper. It supports Latin, Greek, Cyrillic, Armenian, Georgian,
  Han, Hiragana, Katakana, and precomposed Hangul. For complex scripts (Arabic, Indic,
  Thai, Hebrew, etc.) configure `Rendro.Adapters.HarfBuzz`.
  """
  @moduledoc tags: [:stable]

  @behaviour Rendro.Text.Shaper
```

**Complex-script gate** — the `@requires_shaping` MapSet constant and gate check inside `shape/3`:
```elixir
  @requires_shaping MapSet.new([
    # Joining scripts
    :arab, :syrc, :nkoo, :mong,
    # Hebrew/RTL (Rendro has no UAX #9 reordering)
    :hebr,
    # Indic
    :deva, :beng, :guru, :gujr, :orya, :taml, :telu, :knda, :mlym, :sinh,
    # SEA
    :thai, :laoo, :khmr, :mymr,
    # Tibetan
    :tibt
  ])

  @impl Rendro.Text.Shaper
  @spec shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
    {:ok, [Rendro.Text.Shaper.glyph()]} | {:error, term()}
  def shape(font, text, opts \\ []) do
    script = Keyword.get(opts, :script, :latn)
    if MapSet.member?(@requires_shaping, script) do
      hint =
        if Code.ensure_loaded?(HarfbuzzEx) do
          "\n    Add to your config: config :rendro, shaper: Rendro.Adapters.HarfBuzz"
        else
          "\n    Add {:harfbuzz_ex, \"~> 1.2\", optional: true} to deps and:\n    config :rendro, shaper: Rendro.Adapters.HarfBuzz"
        end
      {:error, {:shaping_required, script, hint}}
    else
      do_shape(font, text)
    end
  end
```

**`do_shape/2` implementation** — migrated from `lib/rendro/text/shaper.ex` current lines 8–27 (built-in) and a simplified cmap+advance path for embedded (the current embedded branch calls `HarfbuzzEx.get!` — this must become a cmap+advance-width lookup using `Rendro.PDF.Font.text_width/3` for both branches):
```elixir
  # Extract from current shaper.ex lines 8-27:
  defp do_shape(%Rendro.PDF.Font{source: :built_in} = font, text) do
    glyphs =
      text
      |> String.graphemes()
      |> Enum.map(fn grapheme ->
        width = Rendro.PDF.Font.text_width(font, grapheme, 1000) |> round()
        %{gid: 0, cluster: 0, name: grapheme, x_advance: width, y_advance: 0, x_offset: 0, y_offset: 0}
      end)
    {:ok, glyphs}
  end
```

**Telemetry event** — preserve the existing `[:rendro, :shaper, :missing_glyph]` event name from `lib/rendro/text/shaper.ex` lines 46–51 in the embedded branch.

---

### `lib/rendro/adapters/harfbuzz.ex` — new optional-dep adapter (adapter, request-response)

**Analog:** `lib/rendro/adapters/accrue.ex` — full file is the template

**Compile gate** (accrue.ex line 1):
```elixir
if Code.ensure_loaded?(HarfbuzzEx) do
  defmodule Rendro.Adapters.HarfBuzz do
```

**Module-doc structure** (accrue.ex lines 2–52):
```elixir
    @moduledoc """
    HarfBuzz text shaping adapter via the `harfbuzz_ex` NIF.

    Requires `{:harfbuzz_ex, "~> 1.2", optional: true}` in your mix.exs and:

        config :rendro, shaper: Rendro.Adapters.HarfBuzz

    This adapter handles all scripts including Arabic, Indic, Thai, Hebrew, and other
    complex scripts. It delegates to `HarfbuzzEx.get!/3` with SHA256-keyed font temp files.

    This module is only compiled when `HarfbuzzEx` is available at compile time
    (via `Code.ensure_loaded?/1`). If `harfbuzz_ex` is not in your dependencies,
    this module is absent and core Rendro is unaffected.
    """
    @moduledoc tags: [:adapter]

    @behaviour Rendro.Text.Shaper
```

**Core HarfBuzz logic** — migrated from `lib/rendro/text/shaper.ex` lines 29–57 with `@impl` and glyph enrichment:
```elixir
    @impl Rendro.Text.Shaper
    @spec shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
      {:ok, [Rendro.Text.Shaper.glyph()]} | {:error, term()}
    def shape(%Rendro.PDF.Font{source: :embedded, font_bytes: bytes}, text, _opts)
        when is_binary(bytes) and is_binary(text) do
      hash = :crypto.hash(:sha256, bytes) |> Base.encode16()
      temp_dir = System.tmp_dir() || "/tmp"
      font_path = Path.join(temp_dir, "rendro_font_#{hash}.ttf")
      unless File.exists?(font_path), do: File.write!(font_path, bytes)

      raw_glyphs = HarfbuzzEx.get!(font_path, text, :all)
      glyphs = enrich_with_cluster(raw_glyphs, text)

      missing_count = Enum.count(glyphs, fn g -> g.name == ".notdef" end)
      if missing_count > 0 do
        :telemetry.execute(
          [:rendro, :shaper, :missing_glyph],
          %{count: missing_count},
          %{font: font_path, text: text}
        )
      end
      {:ok, glyphs}
    rescue
      e -> {:error, e}
    end
```

**`enrich_with_cluster/2` helper** — derive cluster from sequential grapheme byte offsets (sequential approximation per RESEARCH.md Pitfall 3):
```elixir
    defp enrich_with_cluster(raw_glyphs, text) do
      grapheme_offsets =
        text
        |> String.graphemes()
        |> Enum.scan(0, fn g, offset -> offset + byte_size(g) end)
        |> List.insert_at(0, 0)
        |> Enum.drop(-1)

      Enum.zip(raw_glyphs, grapheme_offsets)
      |> Enum.map(fn {g, cluster} ->
        Map.from_struct(g) |> Map.put(:cluster, cluster) |> Map.put(:gid, 0)
      end)
    end
  end
end
```

---

### `lib/rendro/text/bidi.ex` — unicode package migration (utility, transform)

**Analog:** `lib/rendro/text/bidi.ex` itself — lines 63–84 are the only change area

**Current `resolve_state/1`** (lines 63–84 — the section being replaced):
```elixir
  defp resolve_state(cp) do
    script_name = UnicodeData.Script.script_from_codepoint(cp)

    script_tag =
      if script_name in ["Common", "Inherited", "Unknown"] do
        :common
      else
        script_name |> UnicodeData.Script.script_to_tag() |> String.to_atom()
      end

    bidi_class = UnicodeData.Bidi.bidi_class(cp)

    direction =
      case bidi_class do
        "L" -> :ltr
        "R" -> :rtl
        "AL" -> :rtl
        _ -> :neutral
      end

    %{script: script_tag, direction: direction}
  end
```

**Target `resolve_state/1`** — atom-based API (RESEARCH.md Pattern 5; string-to-atom guard changes are the critical correctness axis per Pitfall 1):
```elixir
  defp resolve_state(cp) do
    script_atom = Unicode.script(cp)

    script_tag =
      if script_atom in [:common, :inherited, :unknown] do
        :common
      else
        to_opentype_tag(script_atom)
      end

    bidi_class = Unicode.BidiClass.bidi_class(cp)

    direction =
      case bidi_class do
        :l -> :ltr
        :r -> :rtl
        :al -> :rtl
        _ -> :neutral
      end

    %{script: script_tag, direction: direction}
  end
```

**`to_opentype_tag/1` private helper** — must be added to the module (Claude's discretion on placement: either inline in `bidi.ex` or extracted to `lib/rendro/text/script_tags.ex`). Source data: `deps/unicode_data/lib/unicodedata/script.ex` lines ~32–200. Key entries needed for the gate scripts:
```elixir
  defp to_opentype_tag(:arabic), do: :arab
  defp to_opentype_tag(:syriac), do: :syrc
  defp to_opentype_tag(:nko), do: :nkoo
  defp to_opentype_tag(:mongolian), do: :mong
  defp to_opentype_tag(:hebrew), do: :hebr
  defp to_opentype_tag(:devanagari), do: :deva
  defp to_opentype_tag(:bengali), do: :beng
  defp to_opentype_tag(:gurmukhi), do: :guru
  defp to_opentype_tag(:gujarati), do: :gujr
  defp to_opentype_tag(:oriya), do: :orya
  defp to_opentype_tag(:tamil), do: :taml
  defp to_opentype_tag(:telugu), do: :telu
  defp to_opentype_tag(:kannada), do: :knda
  defp to_opentype_tag(:malayalam), do: :mlym
  defp to_opentype_tag(:sinhala), do: :sinh
  defp to_opentype_tag(:thai), do: :thai
  defp to_opentype_tag(:lao), do: :laoo
  defp to_opentype_tag(:khmer), do: :khmr
  defp to_opentype_tag(:myanmar), do: :mymr
  defp to_opentype_tag(:tibetan), do: :tibt
  defp to_opentype_tag(:latin), do: :latn
  defp to_opentype_tag(:greek), do: :grek
  defp to_opentype_tag(:cyrillic), do: :cyrl
  defp to_opentype_tag(:armenian), do: :armn
  defp to_opentype_tag(:georgian), do: :geor
  defp to_opentype_tag(:han), do: :hani
  defp to_opentype_tag(:hiragana), do: :hira
  defp to_opentype_tag(:katakana), do: :kana
  defp to_opentype_tag(:hangul), do: :hang
  # ... full ~100-entry table copied from deps/unicode_data/lib/unicodedata/script.ex
  defp to_opentype_tag(script), do: script  # fallback: pass atom through unchanged
```

---

### `lib/rendro/pipeline/measure.ex` — hard-match softening + cluster-boundary fix (service, transform)

**Analog:** `lib/rendro/pipeline/measure.ex` lines 590–598 (existing `{:error, _}` halt pattern) and lines 632–633 (`{:unsupported_glyph, _}` halt pattern)

**Existing error-halt pattern to copy** (lines 593–598 — the `reduce_while` halt that propagates errors already):
```elixir
    Enum.reduce_while(enum, {:ok, []}, fn item, {:ok, acc} ->
      # ...
      {:error, _} = err -> {:halt, err}
    end)
```

**Site 1 — `split_graphemes` line 607 hard-match to soften:**
```elixir
# BEFORE (line 607):
{:ok, glyphs} = Rendro.Text.Shaper.shape(font, grapheme)

# AFTER — mirrors the unsupported_glyph halt at line 632–633:
case Rendro.Text.Shaper.shape(font, grapheme) do
  {:ok, glyphs} ->
    # ... existing width calculation and continue logic ...
  {:error, reason} ->
    {:halt, {:error, reason}}
end
```

**Site 2 — `measure_text_into_runs` line 667 hard-match to soften + script opt threading:**
```elixir
# BEFORE (line 667):
{:ok, glyphs} = Rendro.Text.Shaper.shape(font, sub_text)

# AFTER — also adds script: opt per D-09/Pattern 6:
case Rendro.Text.Shaper.shape(font, sub_text, script: bidi_run.script) do
  {:ok, glyphs} ->
    width =
      glyphs
      |> Enum.reduce(0, fn g, acc -> acc + g.x_advance end)
      |> Kernel.*(font_size / font.units_per_em)
    %{font: font, text: sub_text, width: width}
  {:error, reason} ->
    # Must break out of inner Enum.map — convert to reduce_while:
    {:halt, {:error, reason}}
end
```

**Note:** `measure_text_into_runs` lines 665–675 currently uses `Enum.map` inside `reduce_while`. When softening site 2, the inner `Enum.map` over `font_runs` must become a `reduce_while` or `Enum.reduce_while` so the `{:error, _}` can halt propagation. The outer `reduce_while` at line 662 already halts on `{:error, _}` — the inner `Enum.map` hides errors. Convert to `Enum.reduce_while(font_runs, {:ok, []}, ...)`.

**Stage-boundary wrapping** — after the `reduce_while` result, wrap errors via `Rendro.Error.from_stage/3`. Pattern from existing measure.ex usage (lines 507–508 show the stage calls measure and wraps in calling code — verify where `from_stage` is called for `:measure` stage errors before adding a new call site).

**`split_graphemes` cluster-boundary fix (D-11)** — the whole function currently iterates `String.graphemes/1` (line 603) and shapes one grapheme at a time (line 607). After the fix, it must shape runs and break at cluster boundaries. The structure stays `Enum.reduce_while` over graphemes but now calls `Rendro.Text.Shaper.shape` on accumulated text runs, breaking at the `cluster` field boundary rather than grapheme count.

---

### `lib/rendro/error.ex` — new shaping_required clauses (utility, transform)

**Analog:** `lib/rendro/error.ex` lines 114 and 241–247 — the existing `{:unsupported_glyph, _}` and `{:unsupported_script, _}` clauses

**Pattern to copy — `why/2` clause** (line 114):
```elixir
defp why(_stage, {:unsupported_glyph, char}), do: "Missing glyph for character: #{char}"
```

**New `why/2` clause to add** (insert after line 114):
```elixir
defp why(_stage, {:shaping_required, script, _hint}),
  do: "Script #{inspect(script)} requires a shaping adapter; Shaper.Simple cannot produce correct output for this script."

defp why(_stage, {:shaping_required, script}),
  do: "Script #{inspect(script)} requires a shaping adapter; Shaper.Simple cannot produce correct output for this script."
```

**Pattern to copy — `next_step/2` clause** (lines 241–247):
```elixir
defp next_step(:measure, {:unsupported_glyph, _char}) do
  "Register an appropriate fallback font that contains the missing character using the fallbacks: [...] option."
end

defp next_step(:measure, {:unsupported_script, _reason}) do
  "Rendro does not currently support complex text shaping or RTL boundaries. Ensure input text falls within supported Unicode boundaries."
end
```

**New `next_step/2` clauses to add** (insert after lines 241–247):
```elixir
defp next_step(:measure, {:shaping_required, script, hint}) do
  "Script #{inspect(script)} requires a shaping adapter. #{hint}"
end

defp next_step(:measure, {:shaping_required, script}) do
  if Code.ensure_loaded?(HarfbuzzEx) do
    "Script #{inspect(script)} requires a shaping adapter. Add to your config: config :rendro, shaper: Rendro.Adapters.HarfBuzz"
  else
    "Script #{inspect(script)} requires a shaping adapter. Add {:harfbuzz_ex, \"~> 1.2\", optional: true} to deps and: config :rendro, shaper: Rendro.Adapters.HarfBuzz"
  end
end
```

---

### `lib/rendro/public_api.ex` — @adapter_files edit (config)

**Analog:** `lib/rendro/public_api.ex` lines 6–12 — existing `@adapter_files` list

**Current list** (lines 6–12):
```elixir
@adapter_files [
  "lib/rendro/adapters/threadline.ex",
  "lib/rendro/adapters/mailglass.ex",
  "lib/rendro/adapters/accrue.ex",
  "lib/rendro/adapters/phoenix.ex",
  "lib/rendro/adapters/oban/render_worker.ex"
]
```

**Target list** (add `harfbuzz.ex` entry):
```elixir
@adapter_files [
  "lib/rendro/adapters/harfbuzz.ex",
  "lib/rendro/adapters/threadline.ex",
  "lib/rendro/adapters/mailglass.ex",
  "lib/rendro/adapters/accrue.ex",
  "lib/rendro/adapters/phoenix.ex",
  "lib/rendro/adapters/oban/render_worker.ex"
]
```

**Downstream effect:** `recompile_conditional_adapters/0` (lines 91–102) will compile `harfbuzz.ex` before `mix rendro.api.gen` introspects — same mechanism that makes `Rendro.Adapters.Accrue` appear in the manifest when `accrue` is loaded.

---

### `mix.exs` — deps flip + groups_for_modules edits (config)

**Analog:** `mix.exs` lines 45–46 (deps) + lines 167–175 (groups_for_modules "Ecosystem Adapters") + lines 137–157 ("Core Builder API" group for `Rendro.Text.Shaper` + `Rendro.Text.Shaper.Simple`)

**Deps change** (lines 45–46):
```elixir
# BEFORE:
{:harfbuzz_ex, "~> 1.2"},
{:unicode_data, "~> 0.8.0"},

# AFTER:
{:harfbuzz_ex, "~> 1.2", optional: true},
{:unicode, "~> 1.22"},
```

**Optional-dep pattern** — `{:phoenix, "~> 1.7", optional: true}` at line 48 is the existing pattern to copy exactly.

**`groups_for_modules` — "Ecosystem Adapters" group** (lines 167–175) — add `Rendro.Adapters.HarfBuzz`:
```elixir
"Ecosystem Adapters": [
  Rendro.Adapters.HarfBuzz,          # add
  Rendro.Adapters.Phoenix,
  Rendro.Adapters.Oban.RenderWorker,
  # ... rest unchanged
]
```

**`groups_for_modules` — text shaping modules** — `Rendro.Text.Shaper` and `Rendro.Text.Shaper.Simple` are `:stable` tier; add them to an appropriate group. The "Core Builder API" group (lines 138–158) is the right home for stable-tier text modules. Add after `Rendro.Error` (line 157):
```elixir
"Core Builder API": [
  # ... existing ...
  Rendro.Error,
  Rendro.Text.Shaper,
  Rendro.Text.Shaper.Simple
]
```

---

### `priv/support_matrix.json` — new `text_shaping` section (config)

**Analog:** `priv/support_matrix.json` lines 65–68 — the `pdfjs` explicit_deferral row (simplest existing example of the vocabulary)

**Existing explicit_deferral vocabulary to copy** (lines 65–68):
```json
"pdfjs": {
  "status": "explicit_deferral",
  "evidence_deferred": "PDF.js failed the forms four-check save-and-reopen round-trip on the representative fixture during Phase 71 operator review; edit_or_toggle persistence is not reliable."
}
```

**Required fields:** `status` + `evidence_deferred` (minLength: 40 per schema).
**Forbidden fields:** `evidence`, `recorded_at`, `viewer_kind`.

**Target `text_shaping` section** — new top-level key added to the root JSON object (the `additionalProperties: true` schema root allows this per RESEARCH.md Pitfall 5):
```json
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
```

---

### `test/docs_contract/script_support_claims_test.exs` — new contract test (test)

**Analog:** `test/docs_contract/signing_claims_test.exs` — full file is the template

**Test module structure** (copy from signing_claims_test.exs lines 1–101):
```elixir
defmodule Rendro.DocsContract.ScriptSupportClaimsTest do
  use ExUnit.Case, async: true

  test "support matrix has text_shaping section with four explicit_deferral entries" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"text_shaping"|
    assert matrix =~ ~s|"arabic"|
    assert matrix =~ ~s|"hebrew_rtl"|
    assert matrix =~ ~s|"devanagari"|
    assert matrix =~ ~s|"thai"|

    assert matrix =~
             ~r/"arabic"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    assert matrix =~
             ~r/"hebrew_rtl"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    assert matrix =~
             ~r/"devanagari"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    assert matrix =~
             ~r/"thai"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    # Verify evidence_deferred strings are non-empty (schema: minLength 40)
    assert matrix =~
             ~r/"arabic".*?"evidence_deferred"\s*:\s*".{40,}"/s

    # latin_and_cjk must be "supported", not deferred
    assert matrix =~
             ~r/"latin_and_cjk"\s*:\s*\{.*?"status"\s*:\s*"supported"/s

    refute matrix =~ ~s|"arabic": "supported"|
    refute matrix =~ ~s|"complex scripts are supported"|
  end

  test "docs verification script includes the script support claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Script support claims lane", ["test", "test/docs_contract/script_support_claims_test.exs"]}|
  end
end
```

**Lane self-registration pattern** — the second test (`"docs verification script includes..."`) is present in every docs-contract test. Copy exactly from `signing_claims_test.exs` lines 95–101, adjusting the lane name and file path string.

---

### `test/docs_contract/public_api_contract_test.exs` — hidden_modules edit (test)

**Analog:** Same file, Assertion 3 at lines 82–119

**Current `hidden_modules` list** (lines 85–92):
```elixir
hidden_modules = [
  Rendro.PDF.CidFont,
  Rendro.PDF.FontSubsetter,
  Rendro.Text.Bidi,
  Rendro.Text.Shaper,     # line 89 — REMOVE this entry
  Rendro.Format,
  Rendro.Audit
]
```

**Target list** (remove `Rendro.Text.Shaper`):
```elixir
hidden_modules = [
  Rendro.PDF.CidFont,
  Rendro.PDF.FontSubsetter,
  Rendro.Text.Bidi,
  Rendro.Format,
  Rendro.Audit
]
```

**False-pass guard pattern** (lines 98–101) — do NOT change this guard; it catches renamed/deleted modules. It now applies to the 5 remaining entries.

---

### `guides/api_stability.md` — tier lists update (config)

**Analog:** `guides/api_stability.md` lines 1–36 — the tier description sections

**Tier-1 Stable section** (line 3 onward) — add `Rendro.Text.Shaper` and `Rendro.Text.Shaper.Simple` to the stable module list. These two modules need an entry analogous to the existing "Core document model" bullet:

```markdown
**Text shaping behaviour:** `Rendro.Text.Shaper` (behaviour) and `Rendro.Text.Shaper.Simple` (pure-Elixir default implementation)
```

**Tier-2 Evolving section** (lines 19–25) — add `Rendro.Adapters.HarfBuzz` to the adapter modules listed:

```markdown
**Adapter modules:** `Rendro.Adapters.PyHanko`, `Rendro.Adapters.Qpdf`, `Rendro.Adapters.HarfBuzz`, and all other `Rendro.Adapters.*` modules.
```

**NOT covered by SemVer section** (lines 27–36) — no change needed; the existing item 4 (`Rendro.Adapters.*`) already covers `Rendro.Adapters.HarfBuzz`, and item 1 (byte-output carve-out) covers the re-bless event.

**Claims test guard** — `test/docs_contract/api_stability_claims_test.exs` at lines 5–26 asserts exact prose. After editing `guides/api_stability.md`, verify `assert guide =~ "## Tier-1 Stable"` and `assert guide =~ "## Tier-2 Evolving"` still pass (header text must be preserved verbatim).

---

## Shared Patterns

### Compile-gate for optional dependencies
**Source:** `lib/rendro/adapters/accrue.ex` line 1
**Apply to:** `lib/rendro/adapters/harfbuzz.ex`
```elixir
if Code.ensure_loaded?(HarfbuzzEx) do
  defmodule Rendro.Adapters.HarfBuzz do
    # ...
  end
end
```

### Tier-tag annotation (stable tier)
**Source:** `lib/rendro/adapters/accrue.ex` line 52 (`:adapter` tag) — flip to `:stable` for behaviour and Simple
**Apply to:** `lib/rendro/text/shaper.ex` and `lib/rendro/text/shaper/simple.ex`
```elixir
@moduledoc tags: [:stable]
```

### Tier-tag annotation (adapter tier)
**Source:** `lib/rendro/adapters/accrue.ex` line 52
**Apply to:** `lib/rendro/adapters/harfbuzz.ex`
```elixir
@moduledoc tags: [:adapter]
```

### @spec requirement on stable-tier public functions
**Source:** `test/docs_contract/public_api_contract_test.exs` lines 210–241 (Assertion 5)
**Apply to:** Every public function in `Rendro.Text.Shaper` and `Rendro.Text.Shaper.Simple`
All public functions in stable-tier modules must have `@spec`. The contract test fetches specs via `Code.Typespec.fetch_specs/1` and fails if any public function is unspecced.

### reduce_while tuple-halt error propagation
**Source:** `lib/rendro/pipeline/measure.ex` lines 593–598 (existing halt pattern) and line 633 (`{:unsupported_glyph, _}` halt)
**Apply to:** Both hard-match sites in `measure.ex` (lines 607 and 667)
```elixir
{:error, _} = err -> {:halt, err}
```

### Rendro.Error.from_stage/3 stage-boundary wrapping
**Source:** `lib/rendro/error.ex` lines 24–43
**Apply to:** The new `{:shaping_required, script}` error path in `measure.ex`
```elixir
Rendro.Error.from_stage(:measure, {:shaping_required, script})
```

### docs-contract test structure (matrix JSON assertions)
**Source:** `test/docs_contract/signing_claims_test.exs` lines 1–101
**Apply to:** `test/docs_contract/script_support_claims_test.exs`
Pattern: `File.read!("priv/support_matrix.json")` + `assert matrix =~` string/regex assertions + lane self-registration second test.

---

## No Analog Found

All files have analogs. No entries in this section.

---

## Metadata

**Analog search scope:** `lib/rendro/text/`, `lib/rendro/adapters/`, `lib/rendro/pipeline/`, `lib/rendro/`, `test/docs_contract/`, `mix.exs`, `priv/support_matrix.json`, `guides/api_stability.md`
**Files scanned:** 14 source files read directly
**Pattern extraction date:** 2026-06-10
