defmodule Rendro.Theme.PresetsTest do
  use ExUnit.Case, async: true

  alias Rendro.FontRegistry
  alias Rendro.Recipes.Invoice
  alias Rendro.Theme
  alias Rendro.Theme.Presets

  defp invoice_data do
    %{
      id: "INV-SWISS-001",
      date: ~D[2026-08-16],
      items: [
        %{name: "Layout audit", qty: 1, price: 250.00},
        %{name: "PDF delivery", qty: 2, price: 75.00}
      ]
    }
  end

  describe "preset/2" do
    test "builds the exact Swiss theme deterministically" do
      first = Theme.preset(:swiss, accent: "#2C6BED")
      second = Theme.preset(:swiss, mode: :light, accent: {44, 107, 237})

      assert first == second
      assert first.typography.fonts == %{heading: :rendro_preset_grotesque, body: :rendro_preset_grotesque, mono: :rendro_preset_mono}
      assert first.typography.scale == %{display: 21, title: 16.5, subtitle: 13, body: 10.5, small: 9, caption: 8}
      assert first.typography.leading == 1.3
      assert first.spacing == %{unit: 6, tight: 4, normal: 8, loose: 12, section: 24}
      assert first.rules == %{hairline: 0.5, thin: 1, thick: 2}
      assert first.radius == %{none: 0, sm: 1, md: 2}
      assert first.density == :comfortable
      assert first.colors.accent == {44, 107, 237}
    end

    test "applies the existing dark semantics last" do
      dark = Theme.preset(:swiss, accent: "#2C6BED", mode: :dark)

      assert dark.mode == :dark
      assert dark.colors.background == {27, 23, 19}
      assert dark.colors.accent == {44, 107, 237}
      assert dark.typography.fonts.heading == :rendro_preset_grotesque
    end

    test "accepts only canonical atoms and a strict keyword contract" do
      for invalid <- ["swiss", :Swiss, :unknown] do
        assert_raise ArgumentError, ~r/#{inspect(invalid)}/, fn ->
          Theme.preset(invalid, accent: "#2C6BED")
        end
      end

      assert_raise ArgumentError, ~r/accent/, fn -> Theme.preset(:swiss, []) end
      assert_raise ArgumentError, ~r/keyword/, fn -> Theme.preset(:swiss, %{accent: "#2C6BED"}) end
      assert_raise ArgumentError, ~r/#12/, fn -> Theme.preset(:swiss, accent: "#12") end
      assert_raise ArgumentError, ~r/unknown/, fn -> Theme.preset(:swiss, accent: "#2C6BED", unknown: :value) end
      assert_raise ArgumentError, ~r/mode/, fn -> Theme.preset(:swiss, accent: "#2C6BED", mode: :print) end
      assert_raise ArgumentError, ~r/density/, fn -> Theme.preset(:swiss, accent: "#2C6BED", density: :spacious) end
    end

    test "exposes preset/2 but not preset/1" do
      functions = Theme.__info__(:functions)
      assert {:preset, 2} in functions
      refute {:preset, 1} in functions
    end
  end

  describe "register_fonts/2" do
    test "requires explicit registration, then renders curated roles into deterministic bytes" do
      theme = Theme.preset(:swiss, accent: "#2C6BED")
      unregistered = Invoice.document(invoice_data(), theme: theme)

      assert {:error, {:unknown_logical_font, :rendro_preset_grotesque}} = Rendro.render(unregistered)

      document = Presets.register_fonts(unregistered, :swiss)
      assert {:ok, pdf} = Rendro.render(document, deterministic: true)
      assert byte_size(pdf) > 0
      assert pdf =~ "Inter"
      assert pdf =~ "JetBrainsMono"
    end

    test "is idempotent for Rendro descriptors, rejects collisions, and keeps documents isolated" do
      theme = Theme.preset(:swiss, accent: "#2C6BED")
      first = Invoice.document(invoice_data(), theme: theme)
      second = Invoice.document(invoice_data(), theme: theme)

      registered = Presets.register_fonts(first, :swiss)
      assert Presets.register_fonts(registered, :swiss) == registered
      assert :error = FontRegistry.fetch(second.font_registry, :rendro_preset_grotesque)

      colliding = Rendro.Document.register_font(first, :rendro_preset_grotesque, built_in: :helvetica)

      assert_raise ArgumentError, ~r/rendro_preset_grotesque.*collision/, fn ->
        Presets.register_fonts(colliding, :swiss)
      end

      assert {:ok, %{source: :built_in, family: :helvetica}} =
               FontRegistry.fetch(colliding.font_registry, :rendro_preset_grotesque)
    end
  end
end
