defmodule Rendro.I18nTest do
  use ExUnit.Case, async: true

  describe "End-to-end I18n System Verification" do
    test "traps missing glyphs cleanly at the measurement stage" do
      # Emitting a character not present in the default Helvetica font (e.g. Emoji or rare char)
      doc =
        Rendro.document(
          pages: [
            Rendro.page(
              blocks: [
                Rendro.block(Rendro.text("Test missing glyph: 👾", font: :default, size: 12))
              ]
            )
          ]
        )

      assert {:error, %Rendro.Error{} = error} = Rendro.render(doc)
      assert error.stage == :measure
      assert error.reason == {:unsupported_glyph, "👾"}
    end

    test "traps unsupported scripts natively" do
      # Arabic string with the default Helvetica font (which has no Arabic glyphs).
      # Font resolution fails for Arabic characters, returning an unsupported_glyph
      # error that propagates as a structured Rendro.Error from the measure stage.
      doc =
        Rendro.document(
          pages: [
            Rendro.page(
              blocks: [
                Rendro.block(Rendro.text("مرحبا بك", font: :default, size: 12))
              ]
            )
          ]
        )

      assert {:error, %Rendro.Error{} = error} = Rendro.render(doc)
      assert error.stage == :measure
      assert {:unsupported_glyph, _char} = error.reason
      assert error.next =~ "fallback font"
    end
  end
end
