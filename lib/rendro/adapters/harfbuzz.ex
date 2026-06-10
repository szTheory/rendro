if Code.ensure_loaded?(HarfbuzzEx) do
  defmodule Rendro.Adapters.HarfBuzz do
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

    @spec shape(Rendro.PDF.Font.t(), String.t(), keyword()) ::
            {:ok, [Rendro.Text.Shaper.glyph()]} | {:error, term()}
    @impl Rendro.Text.Shaper
    def shape(%Rendro.PDF.Font{source: :embedded, font_bytes: bytes}, text, _opts)
        when is_binary(bytes) and is_binary(text) do
      hash = :crypto.hash(:sha256, bytes) |> Base.encode16()
      temp_dir = System.tmp_dir() || "/tmp"
      font_path = Path.join(temp_dir, "rendro_font_#{hash}.ttf")
      unless File.exists?(font_path), do: File.write!(font_path, bytes)

      raw_glyphs = HarfbuzzEx.get!(font_path, text, :all)
      glyphs = enrich_with_cluster(raw_glyphs, text)

      missing_count = Enum.count(glyphs, fn g -> Map.get(g, :name) == ".notdef" end)

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
