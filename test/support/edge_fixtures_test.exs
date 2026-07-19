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

      assert {:ok, _pdf} =
               Rendro.render(EdgeFixtures.document(:statement, :money_negative_parens))
    end

    test "invoice/money_large totals Decimal-equal the summed items and does not raise" do
      data = EdgeFixtures.build(:invoice, :money_large)

      derived =
        Enum.reduce(data.items, Decimal.new(0), fn %{qty: q, price: p}, acc ->
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

  # Structural + page_size + odd/even cells implemented in Task 2 — document/2
  # must render each successfully.
  @task2_cells (for family <- [:invoice, :statement, :receipt, :payslip],
                    dim <- [
                      :line_items_page_boundary,
                      :pagination_boundary,
                      :line_items_60_plus,
                      :odd_even_running_content
                    ] do
                  {family, dim}
                end) ++
                 [
                   {:certificate, :page_size_a4_letter},
                   {:payslip, :page_size_a4_letter},
                   {:ticket, :page_size_a4_letter}
                 ]

  describe "structural pagination dimensions" do
    test "statement/line_items_page_boundary is rows_per_page + 1 lines and renders as a 2-page document" do
      data = EdgeFixtures.build(:statement, :line_items_page_boundary)

      assert {:ok, pdf} =
               Rendro.render(EdgeFixtures.document(:statement, :line_items_page_boundary))

      assert pdf =~ "(Page 2 of 2)", "expected exactly 2 pages for #{length(data.lines)} lines"
    end

    test "receipt/pagination_boundary is 2*rows_per_page + 1 lines and renders as a 3-page document" do
      data = EdgeFixtures.build(:receipt, :pagination_boundary)
      assert {:ok, pdf} = Rendro.render(EdgeFixtures.document(:receipt, :pagination_boundary))
      assert pdf =~ "(Page 3 of 3)", "expected exactly 3 pages for #{length(data.lines)} lines"
    end

    test "payslip/line_items_60_plus returns 65+ earnings and renders as a multi-page document" do
      data = EdgeFixtures.build(:payslip, :line_items_60_plus)
      assert length(data.earnings) >= 65
      assert {:ok, pdf} = Rendro.render(EdgeFixtures.document(:payslip, :line_items_60_plus))
      assert pdf =~ "(Page 2 of"
    end
  end

  describe "page_size_a4_letter" do
    test "certificate renders byte-different at US Letter vs the default A4 geometry" do
      {:ok, letter} = Rendro.render(EdgeFixtures.document(:certificate, :page_size_a4_letter))
      {:ok, a4} = Rendro.render(EdgeFixtures.document(:certificate, :missing_optional_fields))
      assert letter != a4
    end
  end

  describe "odd_even_running_content" do
    test "invoice document wires distinct odd/even footer sections and spans 2+ pages" do
      doc = EdgeFixtures.document(:invoice, :odd_even_running_content)
      assert %Rendro.Document{} = doc

      footers = Enum.filter(doc.sections, &(&1.region == :footer))
      odd = Enum.find(footers, &(&1.only_on == :odd))
      even = Enum.find(footers, &(&1.only_on == :even))
      assert odd, "expected an only_on: :odd footer section"
      assert even, "expected an only_on: :even footer section"

      odd_text = odd.content |> hd() |> get_text()
      even_text = even.content |> hd() |> get_text()
      assert odd_text != even_text

      assert {:ok, pdf} = Rendro.render(doc)
      # Both parity footers only render if the document spans 2+ pages.
      assert pdf =~ "Odd-page footer"
      assert pdf =~ "Even-page footer"
    end
  end

  describe "EDGE-02 error fixtures" do
    test "overflow_document renders to a paginate/content_overflow error whose details.block is a map" do
      assert {:error, %Rendro.Error{stage: :paginate, reason: :content_overflow} = e} =
               Rendro.render(EdgeFixtures.overflow_document())

      assert is_map(e.details.block)
      assert e.next =~ "does not auto-fit"
    end

    test "tall_row_document renders to a paginate/content_overflow error with :row_height and no :block key" do
      assert {:error, %Rendro.Error{stage: :paginate, reason: :content_overflow} = e} =
               Rendro.render(EdgeFixtures.tall_row_document())

      assert Map.has_key?(e.details, :row_height)
      refute Map.has_key?(e.details, :block)
    end

    test "rtl_default_font_document renders to a measure/unsupported_glyph error" do
      assert {:error, %Rendro.Error{stage: :measure} = e} =
               Rendro.render(EdgeFixtures.rtl_default_font_document())

      assert match?({:unsupported_glyph, _char}, e.reason)
    end

    test "rtl_shaping_required_document renders to a measure/shaping_required :arab error" do
      assert {:error, %Rendro.Error{stage: :measure} = e} =
               Rendro.render(EdgeFixtures.rtl_shaping_required_document())

      assert match?({:shaping_required, :arab, _hint}, e.reason)
    end

    test "render/2 never returns {:ok, _} for RTL under the default shaper" do
      refute match?({:ok, _}, Rendro.render(EdgeFixtures.rtl_default_font_document()))
      refute match?({:ok, _}, Rendro.render(EdgeFixtures.rtl_shaping_required_document()))
    end
  end

  describe "document/2 — Task 2 cells all render without raising" do
    for {family, dimension} <- @task2_cells do
      test "#{family}/#{dimension} renders successfully" do
        assert {:ok, _pdf} =
                 Rendro.render(EdgeFixtures.document(unquote(family), unquote(dimension)))
      end
    end
  end

  defp get_text(%Rendro.Block{content: %Rendro.Text{content: text}}), do: text

  defp sum(lines) do
    Enum.reduce(lines, Decimal.new(0), fn %{amount: a}, acc -> Decimal.add(acc, a) end)
  end
end
