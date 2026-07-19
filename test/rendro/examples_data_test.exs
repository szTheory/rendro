defmodule Rendro.ExamplesDataTest do
  use ExUnit.Case, async: true

  # Proves Pitfall 1 is closed: each fixture, loaded and transformed, feeds its
  # recipe's document/2 without a KeyError/FunctionClauseError and yields a
  # %Rendro.Document{}. This is the D-06 single data source both the demo set
  # (SHOW-01) and the gallery (SHOW-03) render through.

  alias Rendro.Examples
  alias Rendro.ExamplesData

  test "transform_invoice feeds Rendro.Recipes.Invoice.document/1" do
    doc =
      "invoice/acme-phoenix-saas/invoice.json"
      |> Examples.load!()
      |> ExamplesData.transform_invoice()
      |> Rendro.Recipes.Invoice.document()

    assert %Rendro.Document{} = doc
  end

  test "118-08: transform_invoice/1 threads issuer/customer/due_date/terms/totals through with faithful Decimal money" do
    data =
      "invoice/acme-phoenix-saas/invoice.json"
      |> Examples.load!()
      |> ExamplesData.transform_invoice()

    assert %{name: _} = data.issuer
    assert %{name: _} = data.customer
    assert %Date{} = data.due_date
    assert is_binary(data.terms)
    assert %Decimal{} = data.totals.subtotal
    assert %Decimal{} = data.totals.tax
    assert %Decimal{} = data.totals.total

    # Faithful cents — never a lossy float/integer coercion (INV-02).
    rendered = Rendro.Recipes.Invoice.document(data)
    flat = inspect(rendered, limit: :infinity, printable_limit: :infinity)
    refute flat =~ ~r/\$\d[\d,]*\.\d(?!\d)/
  end

  test "transform_statement feeds Rendro.Recipes.Statement.document/1" do
    doc =
      "statement/northwind-ledger-co/statement.json"
      |> Examples.load!()
      |> ExamplesData.transform_statement()
      |> Rendro.Recipes.Statement.document()

    assert %Rendro.Document{} = doc
  end

  test "transform_receipt feeds Rendro.Recipes.Receipt.document/1" do
    doc =
      "receipt/harbor-and-oak-cafe/receipt.json"
      |> Examples.load!()
      |> ExamplesData.transform_receipt()
      |> Rendro.Recipes.Receipt.document()

    assert %Rendro.Document{} = doc
  end

  test "transform_certificate feeds Rendro.Recipes.Certificate.document/2 (border: true)" do
    doc =
      "certificate/summit-training-institute/certificate.json"
      |> Examples.load!()
      |> ExamplesData.transform_certificate()
      |> Rendro.Recipes.Certificate.document(border: true)

    assert %Rendro.Document{} = doc
  end

  test "transform_payslip feeds Rendro.Recipes.Payslip.document/1 and net_pay reconciles" do
    data =
      "payslip/aurora-live/payslip.json"
      |> Examples.load!()
      |> ExamplesData.transform_payslip()

    doc = Rendro.Recipes.Payslip.document(data)
    assert %Rendro.Document{} = doc

    earnings_sum =
      Enum.reduce(data.earnings, Decimal.new(0), fn %{amount: a}, acc -> Decimal.add(acc, a) end)

    deductions_sum =
      Enum.reduce(data.deductions, Decimal.new(0), fn %{amount: a}, acc -> Decimal.add(acc, a) end)

    assert Decimal.equal?(data.net_pay, Decimal.sub(earnings_sum, deductions_sum))
  end

  test "transform_ticket feeds Rendro.Recipes.Ticket.document/1" do
    doc =
      "ticket/aurora-live/ticket.json"
      |> Examples.load!()
      |> ExamplesData.transform_ticket()
      |> Rendro.Recipes.Ticket.document()

    assert %Rendro.Document{} = doc
  end
end
