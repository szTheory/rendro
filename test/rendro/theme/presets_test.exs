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
    @preset_contracts %{
      swiss: %{
        fonts: %{
          heading: :rendro_preset_grotesque,
          body: :rendro_preset_grotesque,
          mono: :rendro_preset_mono
        },
        scale: %{display: 21, title: 16.5, subtitle: 13, body: 10.5, small: 9, caption: 8},
        leading: 1.3,
        spacing: %{unit: 6, tight: 4, normal: 8, loose: 12, section: 24},
        rules: %{hairline: 0.5, thin: 1, thick: 2},
        radius: %{none: 0, sm: 1, md: 2},
        neutrals: %{
          ink: {16, 24, 39},
          muted: {91, 101, 115},
          surface: {247, 243, 234},
          rule: {196, 188, 169}
        }
      },
      humanist: %{
        fonts: %{
          heading: :rendro_preset_humanist_sans,
          body: :rendro_preset_humanist_sans,
          mono: :rendro_preset_mono
        },
        scale: %{display: 22, title: 17, subtitle: 13.5, body: 11, small: 9.5, caption: 8.5},
        leading: 1.45,
        spacing: %{unit: 6, tight: 5, normal: 10, loose: 16, section: 28},
        rules: %{hairline: 0.5, thin: 0.75, thick: 1.5},
        radius: %{none: 0, sm: 3, md: 6},
        neutrals: %{
          ink: {16, 24, 39},
          muted: {101, 91, 78},
          surface: {247, 243, 234},
          rule: {205, 194, 174}
        }
      },
      editorial: %{
        fonts: %{
          heading: :rendro_preset_text_serif,
          body: :rendro_preset_humanist_sans,
          mono: :rendro_preset_mono
        },
        scale: %{display: 30, title: 18, subtitle: 13, body: 10, small: 8.5, caption: 7.5},
        leading: 1.42,
        spacing: %{unit: 7, tight: 4, normal: 9, loose: 14, section: 32},
        rules: %{hairline: 0.5, thin: 1, thick: 2},
        radius: %{none: 0, sm: 1, md: 2},
        neutrals: %{
          ink: {16, 24, 39},
          muted: {91, 101, 115},
          surface: {247, 243, 234},
          rule: {196, 188, 169}
        }
      },
      corporate_classic: %{
        fonts: %{
          heading: :rendro_preset_text_serif,
          body: :rendro_preset_text_serif,
          mono: :rendro_preset_mono
        },
        scale: %{display: 18, title: 14, subtitle: 12, body: 10, small: 9, caption: 8},
        leading: 1.3,
        spacing: %{unit: 6, tight: 4, normal: 8, loose: 12, section: 24},
        rules: %{hairline: 0.5, thin: 1, thick: 2.5},
        radius: %{none: 0, sm: 0, md: 0},
        neutrals: %{
          ink: {16, 24, 39},
          muted: {78, 89, 105},
          surface: {244, 246, 248},
          rule: {143, 154, 169}
        }
      },
      minimal_mono: %{
        fonts: %{
          heading: :rendro_preset_mono,
          body: :rendro_preset_grotesque,
          mono: :rendro_preset_mono
        },
        scale: %{display: 16, title: 13, subtitle: 11, body: 9.5, small: 8.5, caption: 8},
        leading: 1.25,
        spacing: %{unit: 4, tight: 3, normal: 6, loose: 10, section: 20},
        rules: %{hairline: 0.5, thin: 0.75, thick: 1.5},
        radius: %{none: 0, sm: 0, md: 0},
        neutrals: %{
          ink: {16, 24, 39},
          muted: {96, 96, 96},
          surface: {248, 248, 248},
          rule: {184, 184, 184}
        }
      },
      brutalist: %{
        fonts: %{
          heading: :rendro_preset_grotesque,
          body: :rendro_preset_grotesque,
          mono: :rendro_preset_mono
        },
        scale: %{display: 34, title: 20, subtitle: 13, body: 10, small: 9, caption: 8},
        leading: 1.2,
        spacing: %{unit: 8, tight: 4, normal: 8, loose: 12, section: 24},
        rules: %{hairline: 1, thin: 2, thick: 3},
        radius: %{none: 0, sm: 0, md: 0},
        neutrals: %{
          ink: {16, 24, 39},
          muted: {91, 101, 115},
          surface: {238, 238, 238},
          rule: {16, 24, 39}
        }
      }
    }

    test "materializes every canonical genre as the D-10 literal contract" do
      Enum.each(@preset_contracts, fn {genre, expected} ->
        theme = Theme.preset(genre, accent: "#2C6BED")

        assert theme.typography.fonts == expected.fonts
        assert theme.typography.scale == expected.scale
        assert theme.typography.leading == expected.leading
        assert theme.spacing == expected.spacing
        assert theme.rules == expected.rules
        assert theme.radius == expected.radius
        assert theme.density == :comfortable
        assert Map.take(theme.colors, Map.keys(expected.neutrals)) == expected.neutrals
      end)
    end

    test "keeps the complete grammar deterministic with dark-last behavior" do
      Enum.each(Map.keys(@preset_contracts), fn genre ->
        light = Theme.preset(genre, accent: "#2C6BED")
        assert light == Theme.preset(genre, accent: {44, 107, 237}, mode: :light)

        dark = Theme.preset(genre, accent: "#2C6BED", mode: :dark)
        assert dark.mode == :dark
        assert dark.colors.background == {27, 23, 19}
        assert dark.colors.accent == {44, 107, 237}
        assert dark.typography == light.typography
        assert dark.spacing == light.spacing
      end)
    end

    test "keeps Minimal-Mono comfortable by default and honors compact through Theme.resolve/1" do
      assert Theme.preset(:minimal_mono, accent: "#2C6BED").typography.leading == 1.25

      assert Theme.preset(:minimal_mono, accent: "#2C6BED", density: :compact).typography.leading ==
               1.1
    end

    test "has stable, unequal signatures with three material axes between nearest neighbors" do
      signatures =
        for {genre, _expected} <- @preset_contracts, into: %{} do
          theme = Theme.preset(genre, accent: "#2C6BED")
          {genre, signature(theme)}
        end

      assert map_size(Map.new(signatures)) == map_size(@preset_contracts)
      assert MapSet.size(MapSet.new(Map.values(signatures))) == map_size(@preset_contracts)

      for {left, right} <- [
            {:swiss, :humanist},
            {:swiss, :corporate_classic},
            {:humanist, :editorial},
            {:corporate_classic, :minimal_mono},
            {:swiss, :brutalist}
          ] do
        assert differing_axes(signatures[left], signatures[right]) >= 3
      end
    end

    test "builds the exact Swiss theme deterministically" do
      first = Theme.preset(:swiss, accent: "#2C6BED")
      second = Theme.preset(:swiss, mode: :light, accent: {44, 107, 237})

      assert first == second

      assert first.typography.fonts == %{
               heading: :rendro_preset_grotesque,
               body: :rendro_preset_grotesque,
               mono: :rendro_preset_mono
             }

      assert first.typography.scale == %{
               display: 21,
               title: 16.5,
               subtitle: 13,
               body: 10.5,
               small: 9,
               caption: 8
             }

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
      for invalid <- ["swiss", :Swiss, :unknown, :brutalism] do
        assert_raise ArgumentError, ~r/#{inspect(invalid)}/, fn ->
          Theme.preset(invalid, accent: "#2C6BED")
        end
      end

      assert_raise ArgumentError, ~r/accent/, fn -> Theme.preset(:swiss, []) end

      assert_raise ArgumentError, ~r/keyword/, fn ->
        Theme.preset(:swiss, %{accent: "#2C6BED"})
      end

      assert_raise ArgumentError, ~r/#12/, fn -> Theme.preset(:swiss, accent: "#12") end

      assert_raise ArgumentError, ~r/unknown/, fn ->
        Theme.preset(:swiss, accent: "#2C6BED", unknown: :value)
      end

      assert_raise ArgumentError, ~r/mode/, fn ->
        Theme.preset(:swiss, accent: "#2C6BED", mode: :print)
      end

      assert_raise ArgumentError, ~r/density/, fn ->
        Theme.preset(:swiss, accent: "#2C6BED", density: :spacious)
      end
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

      assert {:error, %Rendro.Error{reason: {:unknown_text_font, :rendro_preset_mono}}} =
               Rendro.render(unregistered)

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

      colliding =
        Rendro.Document.register_font(first, :rendro_preset_grotesque, built_in: :helvetica)

      assert_raise ArgumentError, ~r/collision.*rendro_preset_grotesque/, fn ->
        Presets.register_fonts(colliding, :swiss)
      end

      assert {:ok, %{source: :built_in, family: :helvetica}} =
               FontRegistry.fetch(colliding.font_registry, :rendro_preset_grotesque)
    end
  end

  defp signature(theme) do
    %{
      fonts: theme.typography.fonts,
      display_body_ratio: theme.typography.scale.display / theme.typography.scale.body,
      leading: theme.typography.leading,
      spacing: theme.spacing,
      rules: theme.rules,
      radius: theme.radius,
      neutrals: Map.take(theme.colors, [:ink, :muted, :surface, :rule])
    }
  end

  defp differing_axes(left, right) do
    Enum.count(Map.keys(left), &(Map.fetch!(left, &1) != Map.fetch!(right, &1)))
  end
end
