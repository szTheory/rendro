defmodule Rendro.Theme.PresetFontsTest do
  use ExUnit.Case, async: true

  alias Rendro.{Document, FontRegistry}
  alias Rendro.PDF.FontParser
  alias Rendro.Theme.Presets

  @faces [
    {:rendro_preset_grotesque, :swiss, "priv/fonts/inter/Inter-Regular.ttf"},
    {:rendro_preset_humanist_sans, :humanist, "priv/fonts/source-sans-3/SourceSans3-Regular.ttf"},
    {:rendro_preset_text_serif, :editorial, "priv/fonts/source-serif-4/SourceSerif4-Regular.ttf"},
    {:rendro_preset_mono, :minimal_mono, "priv/fonts/jetbrains-mono/JetBrainsMono-Regular.ttf"}
  ]

  test "each curated role is an embeddable static TrueType face with a bound NOTICE record" do
    notice = File.read!("NOTICE")

    for {role, genre, path} <- @faces do
      bytes = File.read!(path)

      assert byte_size(bytes) > 0
      assert binary_part(bytes, 0, 4) in [<<0, 1, 0, 0>>, "true"]
      assert {:ok, parsed} = FontParser.parse(bytes)
      assert map_size(parsed.cmap) > 0
      assert parsed.units_per_em > 0
      assert parsed.ascent > parsed.descent

      document = Presets.register_fonts(Document.new(), genre)
      assert {:ok, descriptor} = FontRegistry.fetch(document.font_registry, role)
      assert %{source: :embedded, source_kind: :path, variant: :regular} = descriptor
      assert {:ok, _} = FontRegistry.preflight(document.font_registry)

      assert notice =~ "BEGIN RENDRO CURATED FONT: #{path}"
      assert notice =~ "Path: #{path}"
      assert notice =~ "SHA-256: #{sha256(path)}"
      assert notice =~ "END RENDRO CURATED FONT: #{path}"
    end
  end

  defp sha256(path) do
    path
    |> File.read!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
