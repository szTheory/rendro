defmodule Rendro.Text.Shaper.Simple do
  @moduledoc """
  Pure-Elixir text shaper. Uses cmap advance widths only — no NIF compilation required.

  This is the default shaper. It supports Latin, Greek, Cyrillic, Armenian, Georgian,
  Han, Hiragana, Katakana, and precomposed Hangul. For complex scripts (Arabic, Indic,
  Thai, Hebrew, etc.) configure `Rendro.Adapters.HarfBuzz`.
  """
  @moduledoc tags: [:stable]

  @behaviour Rendro.Text.Shaper

  @requires_shaping MapSet.new([
                      # Joining scripts
                      :arab,
                      :syrc,
                      :nkoo,
                      :mong,
                      # Hebrew/RTL (Rendro has no UAX #9 reordering)
                      :hebr,
                      # Indic
                      :deva,
                      :beng,
                      :guru,
                      :gujr,
                      :orya,
                      :taml,
                      :telu,
                      :knda,
                      :mlym,
                      :sinh,
                      # SEA
                      :thai,
                      :laoo,
                      :khmr,
                      :mymr,
                      # Tibetan
                      :tibt
                    ])

  @doc """
  Shapes `text` using cmap advance widths only (one glyph per grapheme,
  `cluster: 0`).

  Works for both built-in and embedded fonts. Returns
  `{:error, {:shaping_required, script, hint}}` when `opts[:script]` is one of
  the requires-shaping scripts this engine cannot render correctly (Arabic,
  Indic, Thai, Hebrew, and the rest of the curated complex-shaping set).
  """
  @spec shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
          {:ok, [Rendro.Text.Shaper.glyph()]} | {:error, term()}
  @impl Rendro.Text.Shaper
  def shape(font, text, opts \\ []) do
    script = Keyword.get(opts, :script, :latn)

    if MapSet.member?(@requires_shaping, script) do
      {:error, {:shaping_required, script, shaping_hint(font, script, opts)}}
    else
      do_shape(font, text)
    end
  end

  # The instructive hint depends on the EFFECTIVE shaper, not on lockfile
  # contents alone (WR-04): when a shaping adapter is already the effective
  # shaper and we still got here (the adapter delegated a :built_in font to
  # Simple), telling the user to configure the adapter again is wrong — the
  # actual fix is an embedded font carrying the script's glyphs, because
  # built-in Type1 PDF fonts cannot contain them.
  defp shaping_hint(%Rendro.PDF.Font{source: :built_in}, script, opts) do
    effective = Keyword.get(opts, :shaper) || Rendro.Text.Shaper.impl()

    if effective != __MODULE__ do
      "\n    Built-in PDF fonts cannot contain #{inspect(script)} glyphs." <>
        "\n    Register an embedded font that covers this script with Rendro.register_embedded_font/3."
    else
      adapter_config_hint()
    end
  end

  defp shaping_hint(_font, _script, _opts), do: adapter_config_hint()

  defp adapter_config_hint do
    if Code.ensure_loaded?(HarfbuzzEx) do
      "\n    Add to your config: config :rendro, shaper: Rendro.Adapters.HarfBuzz"
    else
      "\n    Add {:harfbuzz_ex, \"~> 1.2\", optional: true} to deps and:\n    config :rendro, shaper: Rendro.Adapters.HarfBuzz"
    end
  end

  # The widths map and default_width are populated for both :built_in fonts
  # (Font.helvetica/0) and :embedded fonts (Font.embedded/1), so the
  # cmap + advance-width path works identically for both sources. The
  # requires-shaping script gate above applies to embedded fonts exactly as
  # it does to built-in ones (D-07).
  defp do_shape(%Rendro.PDF.Font{source: source} = font, text)
       when source in [:built_in, :embedded] do
    glyphs =
      text
      |> String.graphemes()
      |> Enum.map(fn grapheme ->
        width = Rendro.PDF.Font.text_width(font, grapheme, 1000) |> round()

        %{
          gid: 0,
          cluster: 0,
          name: grapheme,
          x_advance: width,
          y_advance: 0,
          x_offset: 0,
          y_offset: 0
        }
      end)

    {:ok, glyphs}
  end
end
