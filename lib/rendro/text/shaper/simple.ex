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

  @spec shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
          {:ok, [Rendro.Text.Shaper.glyph()]} | {:error, term()}
  @impl Rendro.Text.Shaper
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

  defp do_shape(%Rendro.PDF.Font{source: :built_in} = font, text) do
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

  defp do_shape(%Rendro.PDF.Font{source: :embedded}, _text) do
    {:error, {:shaping_required, :embedded_font_requires_harfbuzz}}
  end
end
