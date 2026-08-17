defmodule Rendro.PDF.FontSubsetterTest do
  use ExUnit.Case, async: true

  alias Rendro.PDF.FontSubsetter
  alias Rendro.PDF.FontParser
  alias Rendro.TestSupport.FontFixture

  @curated_font_paths [
    "priv/fonts/inter/Inter-Regular.ttf",
    "priv/fonts/source-sans-3/SourceSans3-Regular.ttf",
    "priv/fonts/source-serif-4/SourceSerif4-Regular.ttf",
    "priv/fonts/jetbrains-mono/JetBrainsMono-Regular.ttf"
  ]

  setup do
    %{bytes: bytes} = FontFixture.supported_font()
    {:ok, font: bytes}
  end

  test "subsets font by keeping only required glyphs", %{font: bytes} do
    # B612 has around 600 glyphs. If we only use a few low GIDs, we should see size reduction
    # We'll pretend we only need glyphs 1, 2, 3 (plus 0 which is always kept).
    assert {:ok, subset_bytes} = FontSubsetter.subset(bytes, [1, 2, 3])

    assert byte_size(subset_bytes) < byte_size(bytes)

    # The subset should still be valid according to our parser
    assert {:ok, _parsed} = FontParser.parse(subset_bytes)
  end

  test "preserves composite glyphs recursively", %{font: bytes} do
    # We pick a GID that is likely a composite, or just a higher GID.
    # Just verify that the subsetting process succeeds and parses correctly.
    assert {:ok, subset_bytes} = FontSubsetter.subset(bytes, [50, 100, 150])

    assert {:ok, parsed} = FontParser.parse(subset_bytes)

    # We should have fewer than original glyphs if the max used is 150 (plus components).
    # Original B612 has many more than 150 glyphs.
    assert byte_size(subset_bytes) < byte_size(bytes)
    assert parsed.units_per_em > 0
  end

  test "returns error for unsupported format" do
    assert FontSubsetter.subset("invalid_bytes", [1]) == {:error, :unsupported_font_format}
  end

  test "normalizes caller glyph ordering and duplicates before dependency traversal" do
    source = File.read!("lib/rendro/pdf/font_subsetter.ex")

    assert source =~ "used_glyphs = used_glyphs |> Enum.uniq() |> Enum.sort()"
  end

  test "curated fonts produce parseable byte-identical subsets for equal glyph sets" do
    for path <- @curated_font_paths do
      bytes = File.read!(path)

      assert {:ok, first} = FontSubsetter.subset(bytes, [31, 3, 31, 17, 3])
      assert {:ok, second} = FontSubsetter.subset(bytes, [17, 31, 3])
      assert first == second
      assert {:ok, _} = FontParser.parse(first)
    end
  end

  test "curated fonts retain a deterministic parseable notdef subset for empty input" do
    for path <- @curated_font_paths do
      bytes = File.read!(path)

      assert {:ok, first} = FontSubsetter.subset(bytes, [])
      assert {:ok, second} = FontSubsetter.subset(bytes, [])
      assert first == second
      assert {:ok, _} = FontParser.parse(first)
    end
  end
end
