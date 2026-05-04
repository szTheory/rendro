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
  def shape(%Rendro.PDF.Font{source: :built_in} = font, text) do
    # Built-in fonts do not have font files to shape with HarfBuzz.
    # Return mock glyphs based on their widths.
    glyphs =
      text
      |> String.graphemes()
      |> Enum.map(fn grapheme ->
        width = Rendro.PDF.Font.text_width(font, grapheme, 1000) |> round()

        %{
          name: grapheme,
          x_advance: width,
          y_advance: 0,
          x_offset: 0,
          y_offset: 0
        }
      end)

    {:ok, glyphs}
  end

  def shape(%Rendro.PDF.Font{source: :embedded, font_bytes: bytes}, text)
      when is_binary(bytes) and is_binary(text) do
    # Use a cached temp file for shaping
    hash = :crypto.hash(:sha256, bytes) |> Base.encode16()
    temp_dir = System.tmp_dir() || "/tmp"
    font_path = Path.join(temp_dir, "rendro_font_#{hash}.ttf")

    unless File.exists?(font_path) do
      File.write!(font_path, bytes)
    end

    # Use HarfbuzzEx.get! to quickly shape the text and return all glyph information.
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
