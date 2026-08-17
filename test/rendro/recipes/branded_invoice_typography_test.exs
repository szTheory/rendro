defmodule Rendro.Recipes.BrandedInvoiceTypographyTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.BrandedInvoice
  alias Rendro.Theme.Presets

  defp sample_data do
    %{
      id: "INV-TYPO-BRANDED-01",
      date: ~D[2026-08-16],
      items: [%{name: "Semantic typography review", qty: 1, price: 250}],
      brand: %{font_name: :brand_heading, logo_name: :company_logo}
    }
  end

  test "materializes the supplied scale, body role, and leading by semantic content" do
    theme = Rendro.Theme.preset(:swiss, accent: "#2C6BED")
    sections = BrandedInvoice.sections(sample_data(), theme: theme)

    assert %Rendro.Text{size: size, font: font, line_height: leading} =
             find_text(sections, "Date: 2026-08-16")

    assert size == theme.typography.scale.body
    assert font == theme.typography.fonts.body
    assert leading == theme.typography.leading
  end

  test "an explicit complete nested typography override wins while retained fields stay materialized" do
    theme = Rendro.Theme.preset(:swiss, accent: "#2C6BED")

    override = %{
      theme.typography
      | leading: 1.7,
        fonts: %{theme.typography.fonts | body: :default}
    }

    assert %Rendro.Text{font: :default, line_height: 1.7} =
             BrandedInvoice.sections(sample_data(), theme: theme, typography: override)
             |> find_text("Date: 2026-08-16")

    assert override.scale.title == theme.typography.scale.title
    assert override.fonts.heading == theme.typography.fonts.heading
  end

  test "curated roles fail before registration and render after the explicit bridge" do
    theme = Rendro.Theme.preset(:swiss, accent: "#2C6BED")
    document = BrandedInvoice.document(sample_data(), theme: theme)

    assert {:error, %Rendro.Error{reason: {:unknown_text_font, _role}}} =
             Rendro.render(document, deterministic: true)

    assert {:ok, pdf} =
             document
             |> Presets.register_fonts(:swiss)
             |> Rendro.render(deterministic: true)

    assert byte_size(pdf) > 0
  end

  defp find_text(sections, content), do: Enum.find(texts(sections), &(&1.content == content))
  defp texts(value) when is_list(value), do: Enum.flat_map(value, &texts/1)
  defp texts(%Rendro.Section{content: content}), do: texts(content)
  defp texts(%Rendro.Block{content: content}), do: texts(content)
  defp texts(%Rendro.Table{rows: rows, header: header}), do: texts([rows, header])
  defp texts(%Rendro.Text{} = text), do: [text]
  defp texts(_), do: []
end
