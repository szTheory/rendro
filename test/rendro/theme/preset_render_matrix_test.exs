defmodule Rendro.Theme.PresetRenderMatrixTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.{BrandedInvoice, Certificate, Invoice, Payslip, Receipt, Statement, Ticket}
  alias Rendro.Theme.Presets

  @rows [
    {:swiss_invoice_light, :swiss, :light, :invoice},
    {:swiss_certificate_dark, :swiss, :dark, :certificate},
    {:humanist_receipt_light, :humanist, :light, :receipt},
    {:humanist_payslip_dark, :humanist, :dark, :payslip},
    {:editorial_certificate_light, :editorial, :light, :certificate},
    {:editorial_ticket_dark, :editorial, :dark, :ticket},
    {:corporate_classic_branded_invoice_light, :corporate_classic, :light, :branded_invoice},
    {:corporate_classic_invoice_dark, :corporate_classic, :dark, :invoice},
    {:minimal_mono_statement_light, :minimal_mono, :light, :statement},
    {:minimal_mono_ticket_dark, :minimal_mono, :dark, :ticket},
    {:brutalist_receipt_light, :brutalist, :light, :receipt},
    {:brutalist_payslip_dark, :brutalist, :dark, :payslip}
  ]

  test "the fixed matrix covers every genre/mode, recipe, and curated role" do
    assert length(@rows) == 12

    assert MapSet.new(Enum.map(@rows, &elem(&1, 1))) ==
             MapSet.new([
               :swiss,
               :humanist,
               :editorial,
               :corporate_classic,
               :minimal_mono,
               :brutalist
             ])

    assert MapSet.new(Enum.map(@rows, &elem(&1, 2))) == MapSet.new([:light, :dark])

    assert MapSet.new(Enum.map(@rows, &elem(&1, 3))) ==
             MapSet.new([
               :invoice,
               :branded_invoice,
               :certificate,
               :receipt,
               :payslip,
               :statement,
               :ticket
             ])

    roles =
      @rows
      |> Enum.flat_map(fn {_id, genre, mode, _recipe} ->
        genre
        |> Rendro.Theme.preset(accent: "#2C6BED", mode: mode)
        |> then(&Map.values(&1.typography.fonts))
      end)
      |> MapSet.new()

    assert roles ==
             MapSet.new([
               :rendro_preset_grotesque,
               :rendro_preset_humanist_sans,
               :rendro_preset_text_serif,
               :rendro_preset_mono
             ])
  end

  test "each row renders byte-identically and bridgeable recipe paths fail loudly when omitted" do
    for {id, genre, mode, recipe} <- @rows do
      theme = Rendro.Theme.preset(genre, accent: "#2C6BED", mode: mode)
      document = document_for(recipe, theme)

      assert_omission_failure!(document, recipe, id)

      registered = Presets.register_fonts(document, genre)

      for role <- Map.values(theme.typography.fonts) do
        assert {:ok, %{source: :embedded}} =
                 Rendro.FontRegistry.fetch(registered.font_registry, role),
               "#{id} must register #{inspect(role)} as an embedded curated face"
      end

      assert {:ok, first} = Rendro.render(registered, deterministic: true)
      assert {:ok, second} = Rendro.render(registered, deterministic: true)
      assert first == second, "#{id} must render deterministically"
      assert byte_size(first) > 0
    end
  end

  defp document_for(:invoice, theme) do
    Invoice.document(
      %{
        id: "INV-MATRIX-001",
        date: ~D[2026-08-16],
        items: [%{name: "Layout audit", qty: 1, price: 250}]
      },
      theme: theme,
      header_height: 90
    )
  end

  defp document_for(:branded_invoice, theme) do
    BrandedInvoice.document(
      %{
        id: "INV-MATRIX-002",
        date: ~D[2026-08-16],
        items: [%{name: "Brand audit", qty: 1, price: 250}],
        brand: %{font_name: :brand_heading, logo_name: :company_logo}
      },
      theme: theme,
      header_height: 90
    )
  end

  defp document_for(:certificate, theme) do
    Certificate.document(
      %{
        title: "Certificate of Completion",
        recipient: "Jane Smith",
        date: ~D[2026-08-16],
        body: "For outstanding achievement and dedication.",
        seal_line: "Awarded 2026"
      },
      theme: theme
    )
  end

  defp document_for(:receipt, theme) do
    Receipt.document(
      %{
        title: "Payment Receipt",
        date: ~D[2026-08-16],
        customer: %{name: "Acme Corp"},
        lines: [%{description: "Layout audit", amount: Decimal.new("250.00")}],
        totals: %{subtotal: Decimal.new("250.00"), total: Decimal.new("250.00")}
      },
      theme: theme
    )
  end

  defp document_for(:payslip, theme) do
    Payslip.document(
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
      },
      theme: theme
    )
  end

  defp document_for(:statement, theme) do
    Statement.document(
      %{
        period: %{from: ~D[2026-07-01], to: ~D[2026-07-31]},
        account: %{name: "Acme Corp"},
        opening_balance: Decimal.new("100.00"),
        lines: [%{date: ~D[2026-07-05], description: "Payment", amount: Decimal.new("-25.00")}]
      },
      theme: theme,
      typography: %{fonts: %{heading: :default, body: :default, mono: :default}}
    )
  end

  defp document_for(:ticket, theme) do
    Ticket.document(
      %{
        issuer: %{name: "Aurora Live"},
        title: "Indie Night: The Lumen Set",
        placement: [
          %{label: "Section", value: "GA"},
          %{label: "Row", value: "H"},
          %{label: "Seat", value: "24"}
        ],
        code: %{reference: "AUR-88213-GA"}
      },
      theme: theme,
      page_size: :a4
    )
  end

  defp assert_omission_failure!(document, :payslip, id) do
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
             Rendro.render(missing_fallback, deterministic: true),
           "#{id} must preserve the typed omission failure"
  end

  defp assert_omission_failure!(document, :statement, _id) do
    assert {:ok, _} = Rendro.render(document, deterministic: true)
  end

  defp assert_omission_failure!(document, _recipe, id) do
    assert {:error, %Rendro.Error{reason: {:unknown_text_font, _role}}} =
             Rendro.render(document, deterministic: true),
           "#{id} must preserve the typed omission failure"
  end
end
