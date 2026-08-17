defmodule Rendro.Recipes.PayslipTypographyTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Payslip
  alias Rendro.Theme.Presets

  defp sample_data do
    %{
      employer: %{name: "Aurora Textiles Co."},
      employee: %{name: "Jordan Rivera", id: "E-4821", tax_code: "1257L"},
      period: %{from: ~D[2026-07-01], to: ~D[2026-07-31]},
      pay_date: ~D[2026-08-05],
      earnings: [
        %{
          description: "Base Salary",
          amount: Decimal.new("4200.00"),
          ytd: Decimal.new("25200.00")
        }
      ],
      deductions: [
        %{
          description: "Federal Income Tax",
          amount: Decimal.new("620.00"),
          ytd: Decimal.new("3720.00")
        }
      ],
      net_pay: Decimal.new("3580.00"),
      payment_method: "Direct Deposit 4321"
    }
  end

  test "materializes themed scale, Payslip fallback role, and leading by semantic content" do
    theme = Rendro.Theme.preset(:humanist, accent: "#2C6BED")

    assert %Rendro.Text{size: size, font: :payslip_sans, line_height: leading} =
             Payslip.sections(sample_data(), theme: theme)
             |> find_text("$3,580.00")

    assert size == theme.typography.scale.display
    assert leading == theme.typography.leading
  end

  test "an explicit complete nested override wins without removing Payslip's fallback role" do
    theme = Rendro.Theme.preset(:humanist, accent: "#2C6BED")

    override = %{
      theme.typography
      | leading: 1.7,
        scale: %{theme.typography.scale | display: 31},
        fonts: %{heading: :payslip_sans, body: :payslip_sans, mono: :payslip_sans}
    }

    assert %Rendro.Text{size: 31, font: :payslip_sans, line_height: 1.7} =
             Payslip.sections(sample_data(), theme: theme, typography: override)
             |> find_text("$3,580.00")

    assert override.scale.title == theme.typography.scale.title
  end

  test "the private payslip_sans fallback fails loudly when omitted and survives the curated-font bridge" do
    theme = Rendro.Theme.preset(:humanist, accent: "#2C6BED")
    document = Payslip.document(sample_data(), theme: theme)

    assert {:ok, _} = Rendro.FontRegistry.fetch(document.font_registry, :payslip_sans)

    missing_fallback = %{
      document
      | font_registry: %{
          document.font_registry
          | fonts: Map.delete(document.font_registry.fonts, :payslip_sans),
            default_font: :default
        },
        default_font: :default
    }

    assert {:error, %Rendro.Error{reason: {:unknown_text_font, :payslip_sans}}} =
             Rendro.render(missing_fallback, deterministic: true)

    assert {:ok, pdf} =
             document
             |> Presets.register_fonts(:humanist)
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
