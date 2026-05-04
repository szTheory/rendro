defmodule Rendro.Text.Shaper do
  @moduledoc """
  Wraps the `harfbuzz_ex` text shaping engine to return exact glyphs and bounding boxes.
  Also detects missing glyph IDs from the shaping engine and emits structured Telemetry
  events instead of crashing.
  """

  @doc """
  Shapes a given text string using the specified font.
  Returns `{:ok, glyphs}` where `glyphs` is a list of `HarfbuzzEx.Shaper.Glyph` structs.
  """
  def shape(font_path, text) when is_binary(font_path) and is_binary(text) do
    # Use HarfbuzzEx.get! to quickly shape the text and return all glyph information.
    # In a long-running system, we should cache the Harfbuzz shaper process per font,
    # but for simplicity we rely on the single-shot API here.
    glyphs = HarfbuzzEx.get!(font_path, text, :all)

    # Check for missing glyphs
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
end
