defmodule Rendro.Recipes.ReceiptTypographyTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Receipt
  alias Rendro.Theme.Presets

  defp sample_data do
    %{
      title: "Payment Receipt",
      date: ~D[2026-08-16],
      customer: %{name: "Acme Corp"},
      lines: [%{description: "Semantic typography review", amount: Decimal.new("250.00")}],
      totals: %{subtotal: Decimal.new("250.00"), total: Decimal.new("250.00")}
    }
  end

  test "materializes heading and mono role text with theme scale and leading" do
    theme = Rendro.Theme.preset(:swiss, accent: "#2C6BED")
    sections = Receipt.sections(sample_data(), theme: theme)

    assert %Rendro.Text{size: title_size, font: title_font, line_height: title_leading} =
             find_text(sections, "Payment Receipt")

    assert title_size == theme.typography.scale.subtitle
    assert title_font == theme.typography.fonts.heading
    assert title_leading == theme.typography.leading

    assert %Rendro.Text{size: total_size, font: total_font, line_height: total_leading} =
             find_text(sections, "Total: $250.00")

    assert total_size == theme.typography.scale.display
    assert total_font == theme.typography.fonts.mono
    assert total_leading == theme.typography.leading
  end

  test "a complete nested explicit override wins while untouched roles remain materialized" do
    theme = Rendro.Theme.preset(:swiss, accent: "#2C6BED")

    override = %{
      theme.typography
      | leading: 1.7,
        scale: %{theme.typography.scale | display: 31},
        fonts: %{theme.typography.fonts | mono: :default}
    }

    assert %Rendro.Text{size: 31, font: :default, line_height: 1.7} =
             Receipt.sections(sample_data(), theme: theme, typography: override)
             |> find_text("Total: $250.00")

    assert override.fonts.heading == theme.typography.fonts.heading
  end

  test "curated roles fail before registration and render after the explicit bridge" do
    theme = Rendro.Theme.preset(:swiss, accent: "#2C6BED")
    document = Receipt.document(sample_data(), theme: theme)

    assert {:error, %Rendro.Error{reason: {:unknown_text_font, _role}}} =
             Rendro.render(document, deterministic: true)

    assert {:ok, pdf} =
             document
             |> Presets.register_fonts(:swiss)
             |> Rendro.render(deterministic: true)

    assert byte_size(pdf) > 0
  end

  test "Humanist receipt table cells use the exact semantic ink role in both target modes" do
    for mode <- [:light, :dark] do
      theme = Rendro.Theme.preset(:humanist, accent: "#2C6BED", mode: mode)
      sections = Receipt.sections(sample_data(), theme: theme)

      for content <- ["Description", "Amount", "Semantic typography review", "$250.00"] do
        assert %Rendro.Text{color: color} = find_text(sections, content)
        assert color == theme.colors.ink
      end
    end
  end

  defp find_text(sections, content), do: Enum.find(texts(sections), &(&1.content == content))
  defp texts(value) when is_list(value), do: Enum.flat_map(value, &texts/1)
  defp texts(%Rendro.Section{content: content}), do: texts(content)
  defp texts(%Rendro.Block{content: content}), do: texts(content)
  defp texts(%Rendro.Table{rows: rows, header: header}), do: texts([rows, header])
  defp texts(%Rendro.Text{} = text), do: [text]
  defp texts(_), do: []
end
