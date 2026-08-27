defmodule Rendro.Recipes.ThemedRenderSmokeTest do
  @moduledoc """
  WR-02 (122-VERIFICATION) coverage-hole closure: a permanent, cross-recipe
  themed end-to-end render guard.

  The Phase-122 themed assertions only compared `sections/2` `%Section{}` structs
  (refute equality) — never `Rendro.render/2` / `measure_rows/4`. That is exactly
  why CR-01 (a themed Payslip that crashed on its own documented data) passed CI.
  This module exercises the FULL render path for every recipe under
  `Rendro.Theme.default()`, so any future themed-path regression that breaks a
  recipe's render surfaces here — not only at manual verification time.

  The Payslip row deliberately uses masked-middot (D-14 `•`) + accented (D-17)
  content so the B612 unicode-fallback path is exercised end-to-end (CR-01).
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.{BrandedInvoice, Certificate, Invoice, Payslip, Receipt, Statement, Ticket}

  @theme Rendro.Theme.default()

  test "Invoice renders {:ok, _} under the default theme" do
    data = %{
      id: "INV-SMOKE-01",
      date: ~D[2026-04-30],
      items: [%{name: "Widget X", qty: 2, price: 100}]
    }

    assert {:ok, _} = Rendro.render(Invoice.document(data, theme: @theme))
  end

  test "BrandedInvoice renders {:ok, _} under the default theme" do
    data = %{
      id: "INV-SMOKE-02",
      date: ~D[2026-04-30],
      items: [%{name: "Widget Y", qty: 1, price: 250}],
      brand: %{font_name: :brand_heading, logo_name: :company_logo}
    }

    assert {:ok, _} = Rendro.render(BrandedInvoice.document(data, theme: @theme))
  end

  test "Statement renders {:ok, _} under the default theme" do
    data = %{
      period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
      account: %{name: "Acme Corp"},
      opening_balance: Decimal.new("100.00"),
      lines: [
        %{date: ~D[2026-05-05], description: "Payment", amount: Decimal.new("-25.00")},
        %{date: ~D[2026-05-20], description: "Invoice", amount: Decimal.new("50.00")}
      ]
    }

    assert {:ok, _} = Rendro.render(Statement.document(data, theme: @theme))
  end

  test "Receipt renders {:ok, _} under the default theme" do
    data = %{
      title: "Payment Receipt",
      date: ~D[2026-05-29],
      customer: %{name: "Acme Corp"},
      lines: [
        %{description: "Widget A", amount: Decimal.new("29.99")},
        %{description: "Widget B", amount: Decimal.new("49.99")}
      ],
      totals: %{subtotal: Decimal.new("79.98"), total: Decimal.new("79.98")}
    }

    assert {:ok, _} = Rendro.render(Receipt.document(data, theme: @theme))
  end

  test "Payslip renders {:ok, _} under the default theme (masked-middot + accented, CR-01)" do
    data = %{
      employer: %{name: "Aurora Textiles Co.", address: "500 Loom Street, Raleigh, NC 27601"},
      employee: %{name: "Jordan Rivera", id: "E-·····4821", tax_code: "1257L"},
      period: %{from: ~D[2026-06-01], to: ~D[2026-06-30]},
      pay_date: ~D[2026-07-05],
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
        },
        %{
          description: "Impôt sur le revenu",
          amount: Decimal.new("100.00"),
          ytd: Decimal.new("600.00")
        }
      ],
      # gross 4200.00 - deductions 720.00 = net 3480.00 (D-13 reconciliation)
      net_pay: Decimal.new("3480.00"),
      payment_method: "Direct Deposit ···· 4321"
    }

    document = Payslip.document(data, theme: @theme)

    assert {:ok, _} = Rendro.render(document, deterministic: true)

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
  end

  test "Certificate renders {:ok, _} under the default theme" do
    data = %{
      title: "Certificate of Completion",
      recipient: "Jane Smith",
      date: ~D[2026-05-29],
      body: "For outstanding achievement and dedication.",
      seal_line: "Awarded 2026"
    }

    assert {:ok, _} = Rendro.render(Certificate.document(data, theme: @theme))
  end

  test "Ticket renders {:ok, _} under the default theme" do
    data = %{
      issuer: %{name: "Aurora Live"},
      title: "Indie Night: The Lumen Set",
      placement: [
        %{label: "Section", value: "GA"},
        %{label: "Row", value: "H"},
        %{label: "Seat", value: "24"}
      ],
      code: %{reference: "AUR-88213-GA"}
    }

    assert {:ok, _} = Rendro.render(Ticket.document(data, theme: @theme))
  end
end
