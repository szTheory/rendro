# Only compiled/run when the optional harfbuzz_ex dep is present (the adapter
# module itself is compile-gated in lib/). The adapter is exercised directly —
# no global :rendro, :shaper config is touched, so the default suite still runs
# under Shaper.Simple.
if Code.ensure_loaded?(Rendro.Adapters.HarfBuzz) do
  defmodule Rendro.Adapters.HarfBuzzTest do
    use ExUnit.Case, async: true

    defp b612_font do
      font_path = Path.join(:code.priv_dir(:rendro), "branded/fonts/B612-Regular.ttf")

      %Rendro.PDF.Font{
        source: :embedded,
        font_bytes: File.read!(font_path),
        name: "F_B612",
        base_font: "B612",
        subtype: :truetype,
        units_per_em: 1000,
        ascent: 718,
        descent: -207,
        default_width: 500,
        widths: %{},
        cmap: nil
      }
    end

    defp grapheme_byte_offsets(text) do
      text
      |> String.graphemes()
      |> Enum.scan(0, fn g, offset -> offset + byte_size(g) end)
      |> List.insert_at(0, 0)
      |> Enum.drop(-1)
    end

    describe "font cache hardening (CR-05)" do
      test "a poisoned/stale cache file is detected and atomically rewritten" do
        font = b612_font()
        hash = :crypto.hash(:sha256, font.font_bytes) |> Base.encode16()

        cache_dir =
          Path.join(System.tmp_dir!(), "rendro_fonts_#{:erlang.phash2({node(), :rendro})}")

        File.mkdir_p!(cache_dir)
        cache_path = Path.join(cache_dir, "#{hash}.ttf")

        # Simulate a pre-planted / truncated cache entry at the predictable name.
        File.write!(cache_path, "not a font")

        # Shaping must not trust the poisoned file: it rewrites it and succeeds.
        assert {:ok, glyphs} = Rendro.Adapters.HarfBuzz.shape(font, "Hello", script: :latn)
        assert glyphs != []
        assert File.read!(cache_path) == font.font_bytes
      end
    end

    describe "cluster semantics (CR-04)" do
      test "1:1 output gets grapheme byte-offset clusters; non-1:1 output gets all-zero clusters" do
        font = b612_font()

        for text <- ["Hello", "Hello world", "ffi", "é", "táble"] do
          assert {:ok, glyphs} = Rendro.Adapters.HarfBuzz.shape(font, text, script: :latn)
          assert glyphs != []

          clusters = Enum.map(glyphs, & &1.cluster)
          graphemes = String.graphemes(text)

          if length(glyphs) == length(graphemes) do
            # Exact 1:1 mapping: clusters are the grapheme start byte offsets.
            assert clusters == grapheme_byte_offsets(text),
                   "expected byte-offset clusters for 1:1 output of #{inspect(text)}"
          else
            # No real cluster data available: the adapter must not fabricate
            # boundaries — all-zero clusters mark the run as one atomic cluster.
            assert Enum.all?(clusters, &(&1 == 0)),
                   "expected all-zero clusters for non-1:1 output of #{inspect(text)}"
          end
        end
      end

      test "every glyph advance is preserved (no zip truncation)" do
        font = b612_font()

        # A multi-codepoint grapheme: regardless of whether the font maps it to
        # one or several glyphs, all returned advances must be kept.
        assert {:ok, glyphs} = Rendro.Adapters.HarfBuzz.shape(font, "é", script: :latn)
        total = Enum.reduce(glyphs, 0, fn g, acc -> acc + g.x_advance end)
        assert total > 0
        assert Enum.all?(glyphs, &Map.has_key?(&1, :cluster))
        assert Enum.all?(glyphs, &Map.has_key?(&1, :gid))
      end
    end
  end
end
