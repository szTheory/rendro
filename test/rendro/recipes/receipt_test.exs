defmodule Rendro.Recipes.ReceiptTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Receipt

  # ---------------------------------------------------------------------------
  # Test Fixture Helpers
  # ---------------------------------------------------------------------------

  # Returns a well-formed receipt data map with `n` line items.
  # Each line has description "Item N" and amount Decimal.new("10.00").
  defp fixture_data(n, opts \\ []) do
    n = max(n, 0)

    lines =
      if n == 0 do
        []
      else
        for i <- 1..n//1 do
          %{description: "Item #{i}", amount: Decimal.new("10.00")}
        end
      end

    subtotal = Decimal.mult(Decimal.new("10.00"), Decimal.new(n))

    base = %{
      title: "Payment Receipt",
      date: ~D[2026-05-29],
      customer: %{name: "Acme Corp"},
      lines: lines,
      totals: %{
        subtotal: subtotal,
        total: subtotal
      }
    }

    Enum.reduce(opts, base, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  # Returns the number of line-item rows that fit on one page (floor).
  # Uses the Receipt capacity formula: no CF/BF overhead subtracted.
  defp rows_per_page do
    # These constants mirror the receipt module's module attributes:
    # @body_height = 841.89 - 2*72 - 48 - 24 = 625.89
    # @header_height = 48, @footer_height = 24, @row_epsilon = 2.0
    # capacity = @body_height - @header_height - @footer_height = 553.89
    content_width = 595.28 - 2 * 72
    table_opts = [header: ["Description", "Amount"], columns: [{:share, 1}, {:fixed, 72}]]
    row = ["Item 1", "$10.00"]
    doc = Rendro.Document.new()
    {header_h, row_heights} = Rendro.measure_rows([row], content_width, doc, table_opts)
    row_h = hd(row_heights)
    body_height = 841.89 - 2 * 72 - 48 - 24
    capacity = body_height - 48 - 24
    # Receipt formula: no CF/BF overhead (no 2 * typical_row_h subtracted)
    effective_cap = capacity - header_h - 2.0
    trunc(effective_cap / row_h)
  end

  # Renders a receipt document and returns the PDF binary or raises on error.
  defp render_receipt!(data_or_n, opts \\ [])

  defp render_receipt!(n, opts) when is_integer(n) do
    doc = Receipt.document(fixture_data(n), opts)

    case Rendro.render(doc) do
      {:ok, pdf} -> pdf
      {:error, err} -> raise "Render failed: #{inspect(err)}"
    end
  end

  defp render_receipt!(data, opts) when is_map(data) do
    doc = Receipt.document(data, opts)

    case Rendro.render(doc) do
      {:ok, pdf} -> pdf
      {:error, err} -> raise "Render failed: #{inspect(err)}"
    end
  end

  # Returns the body section content blocks from sections/2.
  defp body_blocks(n, opts \\ []) do
    data = fixture_data(n)
    [_header, body, _footer] = Receipt.sections(data, opts)
    body.content
  end

  # ---------------------------------------------------------------------------
  # V1: document/2 returns a renderable %Rendro.Document{}; render → {:ok, _}
  # ---------------------------------------------------------------------------

  describe "V1: document/2 produces a renderable Document" do
    test "returns a %Rendro.Document{} struct" do
      doc = Receipt.document(fixture_data(1))
      assert %Rendro.Document{} = doc
    end

    test "Rendro.render/1 returns {:ok, pdf_binary}" do
      doc = Receipt.document(fixture_data(1))
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
      assert String.starts_with?(pdf, "%PDF-")
    end

    test "empty lines (0) renders without error" do
      doc = Receipt.document(fixture_data(0))
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end

    test "document has page_template set to :receipt" do
      doc = Receipt.document(fixture_data(1))
      assert doc.page_template == :receipt
    end

    test "document has sections covering :header, :body, :footer regions" do
      doc = Receipt.document(fixture_data(3))
      region_targets = Enum.map(doc.sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "document header includes title and customer name" do
      data = %{
        title: "Test Receipt",
        date: ~D[2026-05-29],
        customer: %{name: "TestCorp"},
        lines: [],
        totals: %{subtotal: Decimal.new("0"), total: Decimal.new("0")}
      }

      doc = Receipt.document(data)
      flat = inspect(doc, limit: :infinity, printable_limit: :infinity)
      assert flat =~ "TestCorp"
    end
  end

  # ---------------------------------------------------------------------------
  # V2: single-page rendering — 0 lines through capacity-1 lines fit 1 page
  # ---------------------------------------------------------------------------

  describe "V2: single-page receipts" do
    test "0 lines produces 1 page" do
      pdf = render_receipt!(0)
      assert pdf =~ "(Page 1 of 1)"
      refute pdf =~ "(Page 2 of 1)"
    end

    test "1 line produces 1 page" do
      pdf = render_receipt!(1)
      assert pdf =~ "(Page 1 of 1)"
    end

    test "capacity-1 lines fit on 1 page" do
      n = rows_per_page() - 1
      assert n >= 1, "capacity must be >= 2"
      pdf = render_receipt!(n)
      assert pdf =~ "(Page 1 of 1)"
      refute pdf =~ "Page 2 of"
    end

    test "single-page receipt has no unresolved {{page_number}} or {{total_pages}} tokens" do
      pdf = render_receipt!(1)
      refute pdf =~ "{{page_number}}"
      refute pdf =~ "{{total_pages}}"
    end
  end

  # ---------------------------------------------------------------------------
  # V3: multi-page continuation — capacity+1 lines → 2 pages; header repeats
  # ---------------------------------------------------------------------------

  describe "V3: multi-page continuation" do
    test "capacity+1 lines produces 2 pages" do
      n = rows_per_page() + 1
      pdf = render_receipt!(n)
      assert pdf =~ "(Page 1 of 2)"
      assert pdf =~ "(Page 2 of 2)"
    end

    test "body blocks for capacity+1 lines has 2 blocks" do
      n = rows_per_page() + 1
      blocks = body_blocks(n)
      # At minimum 2 table blocks (one per page) + totals block
      assert length(blocks) >= 2
    end

    test "second page block has break_before == true" do
      n = rows_per_page() + 1
      blocks = body_blocks(n)
      assert length(blocks) >= 2
      # First table block: no break_before; second table block: break_before true
      [first_block | rest_blocks] = blocks
      refute first_block.break_before
      # The second block (first of rest) should be a table with break_before
      second_table = Enum.find(rest_blocks, fn b -> is_struct(b.content, Rendro.Table) end)
      assert second_table != nil
      assert second_table.break_before == true
    end

    test "each page's table block has column header in content" do
      n = rows_per_page() + 1
      blocks = body_blocks(n)
      table_blocks = Enum.filter(blocks, fn b -> is_struct(b.content, Rendro.Table) end)
      assert length(table_blocks) >= 2

      Enum.each(table_blocks, fn block ->
        assert block.content.header != nil,
               "Each page's table block must have a header (column headers repeat)"
      end)
    end
  end

  # ---------------------------------------------------------------------------
  # V4: footer — "Page X of Y" on every page; no unresolved tokens
  # ---------------------------------------------------------------------------

  describe "V4: Page X of Y footer on every page" do
    test "single-page receipt has 'Page 1 of 1' in footer" do
      pdf = render_receipt!(3)
      assert pdf =~ "(Page 1 of 1)"
    end

    test "2-page receipt has 'Page 1 of 2' and 'Page 2 of 2'" do
      n = rows_per_page() + 1
      pdf = render_receipt!(n)
      assert pdf =~ "(Page 1 of 2)"
      assert pdf =~ "(Page 2 of 2)"
    end

    test "3-page receipt has correct page numbers on every page" do
      n = rows_per_page() * 2 + 1
      pdf = render_receipt!(n)
      assert pdf =~ "(Page 1 of 3)"
      assert pdf =~ "(Page 2 of 3)"
      assert pdf =~ "(Page 3 of 3)"
    end

    test "footer region has height > 0" do
      template = Receipt.page_template()
      footer = Enum.find(template.regions, &(&1.role == :footer))
      assert footer != nil
      assert footer.height > 0
    end

    test "no unresolved {{page_number}} or {{total_pages}} tokens remain in multi-page PDF" do
      pdf = render_receipt!(rows_per_page() + 1)
      refute pdf =~ "{{page_number}}"
      refute pdf =~ "{{total_pages}}"
    end
  end

  # ---------------------------------------------------------------------------
  # V5: totals block — present on last page; Decimal validation
  # ---------------------------------------------------------------------------

  describe "V5: totals block and validation" do
    test "sections output's last body block is the totals block (not a table)" do
      blocks = body_blocks(3)
      last_block = List.last(blocks)
      # The totals block is a non-table block (should be a text or non-table content)
      refute is_struct(last_block.content, Rendro.Table),
             "Last block should be the totals block, not a table"
    end

    test "body section has both table block(s) and totals block" do
      blocks = body_blocks(3)
      table_blocks = Enum.filter(blocks, fn b -> is_struct(b.content, Rendro.Table) end)
      non_table_blocks = Enum.reject(blocks, fn b -> is_struct(b.content, Rendro.Table) end)
      assert table_blocks != [], "Expected at least one table block"
      assert non_table_blocks != [], "Expected at least one totals block"
    end

    test "validate_data! raises when totals.subtotal != sum of line amounts" do
      data =
        fixture_data(3)
        |> Map.put(:totals, %{subtotal: Decimal.new("999.00"), total: Decimal.new("999.00")})

      assert_raise ArgumentError, ~r/subtotal|totals/i, fn ->
        Receipt.document(data)
      end
    end

    test "validate_data! accepts matching totals" do
      data = fixture_data(3)
      doc = Receipt.document(data)
      assert %Rendro.Document{} = doc
    end
  end

  # ---------------------------------------------------------------------------
  # V6: validate_data!/1 — Float amounts, missing keys, malformed data
  # ---------------------------------------------------------------------------

  describe "V6: validate_data!/1 rejects malformed input" do
    test "Float line amount raises ArgumentError mentioning Decimal" do
      data = fixture_data(0) |> Map.put(:lines, [%{description: "X", amount: 9.99}])

      assert_raise ArgumentError, ~r/Decimal|float/i, fn ->
        Receipt.document(data)
      end
    end

    test "missing :title key raises ArgumentError" do
      data = fixture_data(1) |> Map.delete(:title)

      assert_raise ArgumentError, fn ->
        Receipt.document(data)
      end
    end

    test "missing :lines key raises ArgumentError" do
      data = fixture_data(1) |> Map.delete(:lines)

      assert_raise ArgumentError, fn ->
        Receipt.document(data)
      end
    end

    test "missing :date key raises ArgumentError" do
      data = fixture_data(1) |> Map.delete(:date)

      assert_raise ArgumentError, fn ->
        Receipt.document(data)
      end
    end

    test "missing :customer key raises ArgumentError" do
      data = fixture_data(1) |> Map.delete(:customer)

      assert_raise ArgumentError, fn ->
        Receipt.document(data)
      end
    end

    test "non-list :lines raises ArgumentError" do
      data = fixture_data(1) |> Map.put(:lines, "not a list")

      assert_raise ArgumentError, fn ->
        Receipt.document(data)
      end
    end

    test "non-map data raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Receipt.document("not a map")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # V7: three-rung escape hatch — page_template/1 and sections/2 callable
  # ---------------------------------------------------------------------------

  describe "V7: three-rung escape hatch" do
    test "page_template/1 returns %Rendro.PageTemplate{} with name :receipt" do
      template = Receipt.page_template()
      assert %Rendro.PageTemplate{} = template
      assert template.name == :receipt
    end

    test "page_template/1 has regions :header, :body, :footer with correct roles" do
      template = Receipt.page_template()
      region_names = Enum.map(template.regions, & &1.name)
      assert :header in region_names
      assert :body in region_names
      assert :footer in region_names

      header = Enum.find(template.regions, &(&1.name == :header))
      body = Enum.find(template.regions, &(&1.name == :body))
      footer = Enum.find(template.regions, &(&1.name == :footer))

      assert header.role == :header
      assert body.role == :body
      assert footer.role == :footer
    end

    test "footer region has non-zero height" do
      template = Receipt.page_template()
      footer = Enum.find(template.regions, &(&1.role == :footer))
      assert footer.height > 0
    end

    test "sections/2 returns a list of %Rendro.Section{} structs" do
      sections = Receipt.sections(fixture_data(1))
      assert is_list(sections)
      assert Enum.all?(sections, fn s -> is_struct(s, Rendro.Section) end)
    end

    test "sections/2 returns sections covering :header, :body, :footer regions" do
      sections = Receipt.sections(fixture_data(3))
      region_targets = Enum.map(sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "page_template/1 and sections/2 callable independently without document/2" do
      template = Receipt.page_template(name: :custom_receipt)
      assert template.name == :custom_receipt

      sections = Receipt.sections(fixture_data(2))
      assert is_list(sections)
    end
  end

  # ---------------------------------------------------------------------------
  # V8: Determinism — byte-identical render across runs
  # ---------------------------------------------------------------------------

  describe "V8: deterministic byte-identical render" do
    test "renders same receipt twice with deterministic: true → byte-identical" do
      doc = Receipt.document(fixture_data(5))
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "multi-page receipt renders deterministically" do
      n = rows_per_page() + 5
      doc = Receipt.document(fixture_data(n))
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end
  end

  # ---------------------------------------------------------------------------
  # V9: No :content_overflow at boundary row counts
  # ---------------------------------------------------------------------------

  describe "V9: no :content_overflow at boundary counts" do
    test "boundary row counts render without :content_overflow" do
      cap = rows_per_page()

      for n <- [0, 1, cap - 1, cap, cap + 1] do
        doc = Receipt.document(fixture_data(n))
        result = Rendro.render(doc)

        assert match?({:ok, _}, result),
               "Expected {:ok, _} for #{n} rows; got: #{inspect(result)}"
      end
    end

    test "3*rows_per_page rows renders without :content_overflow" do
      n = rows_per_page() * 3
      doc = Receipt.document(fixture_data(n))
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end
  end

  # ---------------------------------------------------------------------------
  # V10: break_before and no keep_together invariants
  # ---------------------------------------------------------------------------

  describe "V10: break_before and no keep_together" do
    test "single-page: first body block has no break_before" do
      blocks = body_blocks(3)
      assert blocks != []
      refute hd(blocks).break_before
    end

    test "multi-page: first block has no break_before, subsequent table blocks do" do
      n = rows_per_page() + 3
      blocks = body_blocks(n)

      assert length(blocks) >= 2

      table_blocks = Enum.filter(blocks, fn b -> is_struct(b.content, Rendro.Table) end)
      [first | rest] = table_blocks
      refute first.break_before, "First block should NOT have break_before"

      Enum.each(rest, fn block ->
        assert block.break_before == true,
               "Non-first table blocks should have break_before: true"
      end)
    end

    test "all blocks in sections/2 output have no keep_together" do
      n = rows_per_page() + 3
      [_header, body, _footer] = Receipt.sections(fixture_data(n))

      Enum.each(body.content, fn block ->
        refute block.keep_together, "No body block should have keep_together: true"
      end)
    end
  end

  # ---------------------------------------------------------------------------
  # V8: validate_data!/1 rejects malformed :customer and :date
  # ---------------------------------------------------------------------------

  describe "V11: validate_data!/1 rejects malformed input" do
    test "non-map :customer raises ArgumentError mentioning customer" do
      data = fixture_data(0) |> Map.put(:customer, "not-a-map")

      assert_raise ArgumentError, ~r/customer/i, fn ->
        Receipt.document(data)
      end
    end

    test "non-%Date{} :date raises ArgumentError mentioning date" do
      data = fixture_data(0) |> Map.put(:date, "2026-05-29")

      assert_raise ArgumentError, ~r/date/i, fn ->
        Receipt.document(data)
      end
    end
  end
end
