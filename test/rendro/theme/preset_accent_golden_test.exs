defmodule Rendro.Theme.PresetAccentGoldenTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Invoice
  alias Rendro.Theme
  alias Rendro.Theme.Presets

  @variants [
    {:from_brand_blue_light, :from_brand, "#2C6BED", :light},
    {:swiss_orange_light, :swiss, "#D97706", :light},
    {:minimal_mono_teal_dark, :minimal_mono, "#0E7C76", :dark}
  ]

  @expected_hashes %{
    from_brand_blue_light: "7916b21b98c297726436dc358f8c389e7a183eba9f4c260ca207ff6122cceee7",
    swiss_orange_light: "8e7fbae00ad81d34297b07364045689ead5c85578118de23940d69162bf4873c",
    minimal_mono_teal_dark: "4e23731142bbf58c576272599b101b24cb396c4a4931df6abc19de900abbafa7"
  }

  test "the bounded variants are the exact resolved accent matrix in declaration order" do
    assert @variants == [
             {:from_brand_blue_light, :from_brand, "#2C6BED", :light},
             {:swiss_orange_light, :swiss, "#D97706", :light},
             {:minimal_mono_teal_dark, :minimal_mono, "#0E7C76", :dark}
           ]

    assert MapSet.new(Enum.map(@variants, &elem(&1, 0))) == MapSet.new(Map.keys(@expected_hashes))
    assert length(@variants) == 3
  end

  test "each accent variant is deterministic and matches its named SHA-256" do
    for {id, constructor, accent, mode} <- @variants do
      theme = theme_for(constructor, accent, mode)
      document = document_for(theme)

      registered =
        case constructor do
          :from_brand -> document
          genre -> Presets.register_fonts(document, genre)
        end

      assert {:ok, first} = Rendro.render(registered, deterministic: true)
      assert {:ok, second} = Rendro.render(registered, deterministic: true)
      assert first == second, "#{id} must be byte-identical across deterministic renders"

      assert sha256(first) == Map.fetch!(@expected_hashes, id)
    end
  end

  test "preset variants fail loudly without their curated-font registration" do
    for {id, genre, accent, mode} <-
          Enum.reject(@variants, &(elem(&1, 0) == :from_brand_blue_light)) do
      assert {:error, %Rendro.Error{reason: {:unknown_text_font, _role}}} =
               genre
               |> theme_for(accent, mode)
               |> document_for()
               |> Rendro.render(deterministic: true),
             "#{id} must require explicit curated-font registration"
    end
  end

  defp theme_for(:from_brand, accent, mode), do: Theme.from_brand([accent: accent], mode: mode)
  defp theme_for(genre, accent, mode), do: Theme.preset(genre, accent: accent, mode: mode)

  defp document_for(theme) do
    Invoice.document(
      %{
        id: "INV-ACCENT-GOLDEN-001",
        date: ~D[2026-08-16],
        items: [
          %{name: "Deterministic layout audit", qty: 1, price: 250},
          %{name: "Semantic typography review", qty: 2, price: 125}
        ]
      },
      theme: theme,
      header_height: 90
    )
  end

  defp sha256(pdf), do: :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)
end
