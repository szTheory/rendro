defmodule Rendro.Text.ShaperTest.ConfigShaper do
  @moduledoc false
  @behaviour Rendro.Text.Shaper

  @impl Rendro.Text.Shaper
  def shape(_font, _text, _opts), do: {:error, :config_shaper_called}
end

defmodule Rendro.Text.ShaperTest.OverrideShaper do
  @moduledoc false
  @behaviour Rendro.Text.Shaper

  @impl Rendro.Text.Shaper
  def shape(_font, _text, _opts), do: {:error, :override_shaper_called}
end

defmodule Rendro.Text.ShaperTest do
  # async: false required — setup uses Application.delete_env to test default (no-config) behavior.
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Rendro.Text.Shaper
  alias Rendro.Text.Shaper.Simple

  # This test module tests Shaper.Simple directly — clear any globally configured shaper.
  # async: false ensures Application.put_env/delete_env is safe. The test isolates itself
  # to verify default (no-config) behavior and Simple's explicit logic.
  setup do
    prev = Application.get_env(:rendro, :shaper)
    Application.delete_env(:rendro, :shaper)

    on_exit(fn ->
      if prev != nil do
        Application.put_env(:rendro, :shaper, prev)
      else
        Application.delete_env(:rendro, :shaper)
      end
    end)

    :ok
  end

  describe "Rendro.Text.Shaper behaviour" do
    test "impl/0 returns Rendro.Text.Shaper.Simple by default (no app config set)" do
      assert Shaper.impl() == Rendro.Text.Shaper.Simple
    end

    test "shape/3 delegates to impl and returns {:ok, glyphs} for built-in font" do
      font = %Rendro.PDF.Font{
        source: :built_in,
        name: "Helvetica",
        base_font: "Helvetica",
        subtype: :type1,
        units_per_em: 1000,
        ascent: 718,
        descent: -207,
        default_width: 500,
        widths: %{72 => 722, 101 => 556, 108 => 222, 111 => 556},
        cmap: nil
      }

      assert {:ok, glyphs} = Shaper.shape(font, "Hello", [])
      assert is_list(glyphs)
      assert length(glyphs) > 0
    end

    test "shape/3 with default opts (omitted) works" do
      font = %Rendro.PDF.Font{
        source: :built_in,
        name: "Helvetica",
        base_font: "Helvetica",
        subtype: :type1,
        units_per_em: 1000,
        ascent: 718,
        descent: -207,
        default_width: 500,
        widths: %{},
        cmap: nil
      }

      assert {:ok, _glyphs} = Shaper.shape(font, "Hi")
    end
  end

  describe "default-install end-to-end (WR-03)" do
    test "an embedded Latin font renders under the default Simple shaper with zero config" do
      # The setup block deleted the :rendro, :shaper env — this is exactly the
      # clean hex install path: no harfbuzz_ex config, no shaper option.
      font_path = Path.join(:code.priv_dir(:rendro), "branded/fonts/B612-Regular.ttf")

      doc =
        Rendro.flow([
          Rendro.block(Rendro.text("Hello from an embedded font", font: :brand, size: 12))
        ])
        |> Rendro.register_embedded_font(:brand, {:path, font_path})

      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
      assert byte_size(pdf) > 0
    end
  end

  describe "per-render shaper override (D-01 / CR-02)" do
    test "per-render :shaper render option wins over app config" do
      Application.put_env(:rendro, :shaper, Rendro.Text.ShaperTest.ConfigShaper)
      doc = Rendro.flow([Rendro.block(Rendro.text("Hello"))])

      assert {:error, %Rendro.Error{stage: :measure, reason: :override_shaper_called}} =
               Rendro.render(doc, shaper: Rendro.Text.ShaperTest.OverrideShaper)
    end

    test "app config wins over the Simple default when no per-render option is given" do
      Application.put_env(:rendro, :shaper, Rendro.Text.ShaperTest.ConfigShaper)
      doc = Rendro.flow([Rendro.block(Rendro.text("Hello"))])

      assert {:error, %Rendro.Error{stage: :measure, reason: :config_shaper_called}} =
               Rendro.render(doc)
    end

    test "shape/3 honors opts[:shaper] directly over app config" do
      Application.put_env(:rendro, :shaper, Rendro.Text.ShaperTest.ConfigShaper)

      font = %Rendro.PDF.Font{
        source: :built_in,
        name: "Helvetica",
        base_font: "Helvetica",
        subtype: :type1,
        units_per_em: 1000,
        ascent: 718,
        descent: -207,
        default_width: 500,
        widths: %{},
        cmap: nil
      }

      assert {:error, :override_shaper_called} =
               Shaper.shape(font, "Hi", shaper: Rendro.Text.ShaperTest.OverrideShaper)
    end
  end

  describe "Rendro.Text.Shaper.Simple" do
    setup do
      font = %Rendro.PDF.Font{
        source: :built_in,
        name: "Helvetica",
        base_font: "Helvetica",
        subtype: :type1,
        units_per_em: 1000,
        ascent: 718,
        descent: -207,
        default_width: 500,
        widths: %{72 => 722, 101 => 556, 108 => 222, 111 => 556},
        cmap: nil
      }

      {:ok, font: font}
    end

    test "shape/3 returns {:ok, glyphs} for Latin text with built_in font", %{font: font} do
      assert {:ok, glyphs} = Simple.shape(font, "Hello", [])

      assert [%{name: "H", x_advance: advance} | _] = glyphs
      assert is_integer(advance)
      assert advance > 0
    end

    test "shape/3 returns glyphs with required fields", %{font: font} do
      assert {:ok, glyphs} = Simple.shape(font, "Hi", [])

      for glyph <- glyphs do
        assert Map.has_key?(glyph, :gid)
        assert Map.has_key?(glyph, :cluster)
        assert Map.has_key?(glyph, :name)
        assert Map.has_key?(glyph, :x_advance)
        assert Map.has_key?(glyph, :y_advance)
        assert Map.has_key?(glyph, :x_offset)
        assert Map.has_key?(glyph, :y_offset)
        assert glyph.y_advance == 0
        assert glyph.x_offset == 0
        assert glyph.y_offset == 0
      end
    end

    test "shape/3 returns {:error, {:shaping_required, :arab, hint}} for Arabic script", %{
      font: font
    } do
      assert {:error, {:shaping_required, :arab, hint}} =
               Simple.shape(font, "مرحبا", script: :arab)

      assert is_binary(hint)
      assert String.starts_with?(hint, "\n    Add")
    end

    test "hint names the embedded-font fix when a shaping adapter is already effective (WR-04)",
         %{font: font} do
      # A built-in font reached Simple's gate even though a shaping adapter is
      # configured (the adapter delegates :built_in fonts to Simple). Telling
      # the user to configure the adapter again would be wrong.
      Application.put_env(:rendro, :shaper, Rendro.Text.ShaperTest.ConfigShaper)

      assert {:error, {:shaping_required, :arab, hint}} =
               Simple.shape(font, "مرحبا", script: :arab)

      assert hint =~ "register_embedded_font/3"
      assert hint =~ "Built-in PDF fonts cannot contain :arab glyphs"
      refute hint =~ "config :rendro, shaper:"
    end

    test "shape/3 returns shaping_required error for all complex scripts", %{font: font} do
      complex_scripts = [
        :syrc,
        :nkoo,
        :mong,
        :hebr,
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
        :thai,
        :laoo,
        :khmr,
        :mymr,
        :tibt
      ]

      for script <- complex_scripts do
        assert {:error, {:shaping_required, ^script, _hint}} =
                 Simple.shape(font, "test", script: script),
               "Expected shaping_required error for script #{inspect(script)}"
      end
    end

    test "shape/3 with :latn script (default) returns {:ok, glyphs}", %{font: font} do
      assert {:ok, glyphs} = Simple.shape(font, "Hello", script: :latn)
      assert length(glyphs) == 5
    end

    test "shape/3 shapes embedded fonts via the same advance-width path (CR-01)" do
      font_path = Path.join(:code.priv_dir(:rendro), "branded/fonts/B612-Regular.ttf")
      font_bytes = File.read!(font_path)

      font = %Rendro.PDF.Font{
        source: :embedded,
        font_bytes: font_bytes,
        name: font_path,
        base_font: "B612",
        subtype: :truetype,
        units_per_em: 1000,
        ascent: 718,
        descent: -207,
        default_width: 500,
        widths: %{?H => 600, ?e => 500, ?l => 250, ?o => 520},
        cmap: nil
      }

      assert {:ok, glyphs} = Simple.shape(font, "Hello", [])
      assert length(glyphs) == 5
      assert [%{name: "H", x_advance: 600} | _] = glyphs
      assert Enum.all?(glyphs, &(&1.x_advance > 0))
    end

    test "shape/3 still gates requires-shaping scripts for embedded fonts (D-07)" do
      font = %Rendro.PDF.Font{
        source: :embedded,
        font_bytes: <<0>>,
        name: "embedded",
        base_font: "Embedded",
        subtype: :truetype,
        units_per_em: 1000,
        ascent: 718,
        descent: -207,
        default_width: 500,
        widths: %{},
        cmap: nil
      }

      assert {:error, {:shaping_required, :arab, _hint}} =
               Simple.shape(font, "مرحبا", script: :arab)
    end
  end

  describe "Rendro.Text.Shaper.Simple — per-grapheme == per-run width property" do
    # Font with widths for all printable ASCII codepoints (32–126).
    # default_width covers anything not explicitly listed.
    setup do
      widths =
        for cp <- 32..126, into: %{} do
          # Vary widths realistically: space=278, others 500-722 based on codepoint
          w =
            case cp do
              32 -> 278
              _ -> 500 + rem(cp, 223)
            end

          {cp, w}
        end

      font = %Rendro.PDF.Font{
        source: :built_in,
        name: "TestAsciiFont",
        base_font: "TestAsciiFont",
        subtype: :type1,
        units_per_em: 1000,
        ascent: 718,
        descent: -207,
        default_width: 500,
        widths: widths,
        cmap: nil
      }

      {:ok, font: font}
    end

    property "per-grapheme width sum equals per-run width under Shaper.Simple (D-12)", %{
      font: font
    } do
      check all(text <- StreamData.string(:ascii, min_length: 1)) do
        {:ok, per_run_glyphs} = Simple.shape(font, text, [])
        per_run_total = Enum.sum(Enum.map(per_run_glyphs, & &1.x_advance))

        per_grapheme_total =
          text
          |> String.graphemes()
          |> Enum.map(fn g ->
            {:ok, glyphs} = Simple.shape(font, g, [])
            Enum.sum(Enum.map(glyphs, & &1.x_advance))
          end)
          |> Enum.sum()

        assert per_run_total == per_grapheme_total
      end
    end
  end
end
