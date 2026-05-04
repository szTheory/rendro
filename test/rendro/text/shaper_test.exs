defmodule Rendro.Text.ShaperTest do
  use ExUnit.Case, async: true

  alias Rendro.Text.Shaper
  alias Rendro.Test.ComplexFonts

  describe "shape/2" do
    test "returns glyphs and bounding boxes for supported characters" do
      font_path = ComplexFonts.b612_path()
      text = "Hello"

      assert {:ok, result} = Shaper.shape(font_path, text)
      
      # Should return a list of glyph structures
      assert [%{name: "H", x_advance: advance} | _] = result
      assert is_integer(advance)
      assert advance > 0
    end

    test "detects missing glyphs and emits structured Telemetry event without crashing" do
      font_path = ComplexFonts.b612_path()
      # Arabic character using B612 which only supports Latin, so it should fallback to .notdef
      text = "مرحبا"

      # Capture telemetry
      parent = self()
      ref = make_ref()

      :telemetry.attach(
        "shaper-missing-glyph-test",
        [:rendro, :shaper, :missing_glyph],
        fn _event, measurements, metadata, _config ->
          send(parent, {:telemetry_event, ref, measurements, metadata})
        end,
        nil
      )

      assert {:ok, result} = Shaper.shape(font_path, text)
      
      # Should fallback and still return result (with .notdef glyphs)
      assert Enum.all?(result, fn glyph -> glyph.name == ".notdef" end)

      assert_receive {:telemetry_event, ^ref, %{count: 5}, %{font: ^font_path, text: ^text}}, 1000

      :telemetry.detach("shaper-missing-glyph-test")
    end
  end
end
