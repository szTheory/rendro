defmodule Rendro.Test.EdgeFixturesTest do
  # Pure functions, no shared/env state.
  use ExUnit.Case, async: true

  alias Rendro.Test.EdgeFixtures

  # {family, dimension} pairs implemented as recipe-shaped data cells in Task 1
  # (content-substitution dimensions). document/2 must render each successfully.
  @task1_cells [
    # missing_optional_fields — all 6 families
    {:invoice, :missing_optional_fields},
    {:statement, :missing_optional_fields},
    {:receipt, :missing_optional_fields},
    {:certificate, :missing_optional_fields},
    {:payslip, :missing_optional_fields},
    {:ticket, :missing_optional_fields},
    # text_wrap — all 6 families
    {:invoice, :text_wrap},
    {:statement, :text_wrap},
    {:receipt, :text_wrap},
    {:certificate, :text_wrap},
    {:payslip, :text_wrap},
    {:ticket, :text_wrap},
    # line_items_zero / one / few — invoice/statement/receipt/payslip
    {:invoice, :line_items_zero},
    {:invoice, :line_items_one},
    {:invoice, :line_items_few},
    {:statement, :line_items_zero},
    {:statement, :line_items_one},
    {:statement, :line_items_few},
    {:receipt, :line_items_zero},
    {:receipt, :line_items_one},
    {:receipt, :line_items_few},
    {:payslip, :line_items_zero},
    {:payslip, :line_items_one},
    {:payslip, :line_items_few},
    # money edges
    {:invoice, :money_zero},
    {:invoice, :money_large},
    {:invoice, :money_cents_rounding},
    {:statement, :money_zero},
    {:statement, :money_large},
    {:statement, :money_cents_rounding},
    {:statement, :money_negative_parens},
    {:receipt, :money_zero},
    {:receipt, :money_large},
    {:receipt, :money_cents_rounding},
    {:payslip, :money_zero},
    {:payslip, :money_large},
    {:payslip, :money_cents_rounding},
    # qty_zero — invoice only
    {:invoice, :qty_zero},
    # currency_format — invoice/statement/receipt/payslip
    {:invoice, :currency_format},
    {:statement, :currency_format},
    {:receipt, :currency_format},
    {:payslip, :currency_format},
    # tax_label — payslip only
    {:payslip, :tax_label}
  ]

  describe "recipe_module/1" do
    test "maps all six family atoms to their Rendro.Recipes.* module" do
      assert EdgeFixtures.recipe_module(:invoice) == Rendro.Recipes.Invoice
      assert EdgeFixtures.recipe_module(:statement) == Rendro.Recipes.Statement
      assert EdgeFixtures.recipe_module(:receipt) == Rendro.Recipes.Receipt
      assert EdgeFixtures.recipe_module(:certificate) == Rendro.Recipes.Certificate
      assert EdgeFixtures.recipe_module(:payslip) == Rendro.Recipes.Payslip
      assert EdgeFixtures.recipe_module(:ticket) == Rendro.Recipes.Ticket
    end
  end

  describe "build/2 — behavior cases" do
    test "invoice/missing_optional_fields has exactly :id, :date, :items and renders" do
      data = EdgeFixtures.build(:invoice, :missing_optional_fields)
      assert Map.keys(data) |> Enum.sort() == [:date, :id, :items]
      assert {:ok, _pdf} = Rendro.render(Rendro.Recipes.Invoice.document(data))
    end

    test "invoice/text_wrap item name exceeds 200 chars and renders" do
      data = EdgeFixtures.build(:invoice, :text_wrap)
      [item] = data.items
      assert byte_size(item.name) > 200
      assert {:ok, _pdf} = Rendro.render(EdgeFixtures.document(:invoice, :text_wrap))
    end

    test "statement/money_negative_parens carries a negative Decimal amount and renders" do
      data = EdgeFixtures.build(:statement, :money_negative_parens)
      [line] = data.lines
      assert Decimal.equal?(line.amount, Decimal.new("-200.00"))
      assert {:ok, _pdf} = Rendro.render(EdgeFixtures.document(:statement, :money_negative_parens))
    end

    test "invoice/money_large totals Decimal-equal the summed items and does not raise" do
      data = EdgeFixtures.build(:invoice, :money_large)
      derived = Enum.reduce(data.items, Decimal.new(0), fn %{qty: q, price: p}, acc ->
        Decimal.add(acc, Decimal.mult(Decimal.new(q), Decimal.new(to_string(p))))
      end)
      assert Decimal.equal?(data.totals.subtotal, derived)
      assert Decimal.equal?(data.totals.total, derived)
      assert {:ok, _pdf} = Rendro.render(EdgeFixtures.document(:invoice, :money_large))
    end

    test "payslip/money_cents_rounding derives net_pay via exact Decimal.sub and does not raise" do
      data = EdgeFixtures.build(:payslip, :money_cents_rounding)
      gross = sum(data.earnings)
      ded = sum(data.deductions)
      assert Decimal.equal?(data.net_pay, Decimal.sub(gross, ded))
      assert {:ok, _pdf} = Rendro.render(EdgeFixtures.document(:payslip, :money_cents_rounding))
    end

    test "certificate/qty_zero is a genuine N/A cell: build/2 raises ArgumentError" do
      assert_raise ArgumentError, fn -> EdgeFixtures.build(:certificate, :qty_zero) end
    end
  end

  describe "opts/2" do
    test "currency_format returns an arity-1 :amount formatter" do
      opts = EdgeFixtures.opts(:invoice, :currency_format)
      fun = opts[:formatters][:amount]
      assert is_function(fun, 1)
      assert fun.(Decimal.new("1250.00")) == "GBP 1,250.00"
    end

    test "non-currency dimensions return []" do
      assert EdgeFixtures.opts(:invoice, :text_wrap) == []
      assert EdgeFixtures.opts(:payslip, :tax_label) == []
    end
  end

  describe "document/2 — Task 1 cells all render without raising" do
    for {family, dimension} <- @task1_cells do
      test "#{family}/#{dimension} renders successfully" do
        assert {:ok, _pdf} =
                 Rendro.render(EdgeFixtures.document(unquote(family), unquote(dimension)))
      end
    end
  end

  defp sum(lines) do
    Enum.reduce(lines, Decimal.new(0), fn %{amount: a}, acc -> Decimal.add(acc, a) end)
  end
end
