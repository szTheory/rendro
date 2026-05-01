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
      # Arabic string
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
      assert error.reason == {:unsupported_script, :rtl_required}
    end
  end
end
