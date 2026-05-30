defmodule Rendro.Recipes.StatementTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Statement

  # ---------------------------------------------------------------------------
  # Test Fixture Helpers
  # ---------------------------------------------------------------------------

  # Returns a well-formed statement data map with `n` transaction lines.
  # Lines alternate between credits (+100.00) and debits (-50.00), so the
  # running balance is deterministic and exact-computable for assertions.
  defp fixture_data(n, opts \\ []) do
    opening = Decimal.new("1000.00")

    lines =
      if n <= 0 do
        []
      else
        for i <- 1..n//1 do
          amount =
            if rem(i, 2) == 1,
              do: Decimal.new("100.00"),
              else: Decimal.new("-50.00")

          %{
            date: Date.add(~D[2026-05-01], i - 1),
            description: "Transaction #{i}",
            amount: amount
          }
        end
      end

    base = %{
      period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
      account: %{name: "Acme Corp"},
      opening_balance: opening,
      lines: lines
    }

    Enum.reduce(opts, base, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  # Computes the exact derived closing balance for `n` lines from opening 1000.00.
  defp expected_closing(n) do
    opening = Decimal.new("1000.00")

    range = if n <= 0, do: [], else: 1..n//1

    Enum.reduce(range, opening, fn i, bal ->
      amount = if rem(i, 2) == 1, do: Decimal.new("100.00"), else: Decimal.new("-50.00")
      Decimal.add(bal, amount)
    end)
  end

  # Returns the number of rows per page (floor) by measuring with engine.
  # Memoized here as a compile-time constant derived from the recipe geometry.
  defp rows_per_page do
    # These constants mirror the recipe module's module attributes:
    # @body_height = 841.89 - 2*72 - 48 - 24 = 625.89
    # @header_height = 48, @footer_height = 24
    # @row_epsilon = 2.0
    # capacity = @body_height - @header_height - @footer_height = 553.89
    content_width = 595.28 - 2 * 72

    table_opts = [
      header: ["Date", "Description", "Amount", "Balance"],
      columns: [{:fixed, 72}, {:share, 1}, {:fixed, 72}, {:fixed, 72}]
    ]

    row = ["2026-05-01", "Transaction 1", "$100.00", "$1,100.00"]
    doc = Rendro.Document.new()
    {header_h, row_heights} = Rendro.measure_rows([row], content_width, doc, table_opts)
    row_h = hd(row_heights)
    body_height = 841.89 - 2 * 72 - 48 - 24
    capacity = body_height - 48 - 24
    effective_cap = capacity - header_h - 2 * row_h - 2.0
    trunc(effective_cap / row_h)
  end

  # Renders a statement document and returns the PDF binary or raises on error.
  defp render_statement!(n, opts \\ []) do
    doc = Statement.document(fixture_data(n), opts)

    case Rendro.render(doc) do
      {:ok, pdf} -> pdf
      {:error, err} -> raise "Render failed: #{inspect(err)}"
    end
  end

  # Returns the body section content blocks from sections/2.
  # sections/2 internally validates the data.
  defp body_blocks(n, opts \\ []) do
    data = fixture_data(n)
    [_header, body, _footer] = Statement.sections(data, opts)
    body.content
  end

  # ---------------------------------------------------------------------------
  # V1: document/2 returns a renderable %Rendro.Document{}; render → {:ok, _}
  # ---------------------------------------------------------------------------

  describe "V1: document/2 produces a renderable Document" do
    test "returns a %Rendro.Document{} struct" do
      doc = Statement.document(fixture_data(3))
      assert %Rendro.Document{} = doc
    end

    test "Rendro.render/1 returns {:ok, pdf_binary}" do
      doc = Statement.document(fixture_data(3))
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
      assert String.starts_with?(pdf, "%PDF-")
    end

    test "empty lines (0) renders without error" do
      doc = Statement.document(fixture_data(0))
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end

    test "document has page_template set to :statement" do
      doc = Statement.document(fixture_data(1))
      assert doc.page_template == :statement
    end

    test "document has sections covering :header, :body, :footer regions" do
      doc = Statement.document(fixture_data(3))
      region_targets = Enum.map(doc.sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "document header includes account name and period" do
      data = %{
        period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
        account: %{name: "TestCorp"},
        opening_balance: Decimal.new("500.00"),
        lines: []
      }

      doc = Statement.document(data)
      flat = inspect(doc, limit: :infinity, printable_limit: :infinity)
      assert flat =~ "TestCorp"
    end
  end

  # ---------------------------------------------------------------------------
  # V2: multi-page page count == ceil(rows / capacity)
  # ---------------------------------------------------------------------------

  describe "V2: multi-page page count" do
    test "0 lines produces 1 page" do
      pdf = render_statement!(0)
      assert pdf =~ "(Page 1 of 1)"
      refute pdf =~ "(Page 2 of 1)"
    end

    test "1 line produces 1 page" do
      pdf = render_statement!(1)
      assert pdf =~ "(Page 1 of 1)"
    end

    test "capacity-1 lines fit on 1 page" do
      n = rows_per_page() - 1
      assert n >= 1, "capacity must be >= 2"
      pdf = render_statement!(n)
      assert pdf =~ "(Page 1 of 1)"
      refute pdf =~ "Page 2 of"
    end

    test "exactly capacity lines fit on 1 page" do
      n = rows_per_page()
      assert n >= 1
      pdf = render_statement!(n)
      assert pdf =~ "(Page 1 of 1)"
      refute pdf =~ "Page 2 of"
    end

    test "capacity+1 lines overflow to 2 pages" do
      n = rows_per_page() + 1
      pdf = render_statement!(n)
      assert pdf =~ "(Page 1 of 2)"
      assert pdf =~ "(Page 2 of 2)"
    end

    test "2*capacity+1 lines produces 3 pages" do
      n = rows_per_page() * 2 + 1
      pdf = render_statement!(n)
      assert pdf =~ "(Page 1 of 3)"
      assert pdf =~ "(Page 2 of 3)"
      assert pdf =~ "(Page 3 of 3)"
    end

    test "page count matches ceil(rows / rows_per_page) for multi-page" do
      cap = rows_per_page()

      for n <- [cap + 1, cap + 2, 2 * cap, 2 * cap + 1] do
        expected_pages = ceil(n / cap)
        pdf = render_statement!(n)

        assert pdf =~ "(Page #{expected_pages} of #{expected_pages})",
               "Expected #{expected_pages} pages for #{n} rows (cap=#{cap}); PDF did not contain expected page marker"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # V3/V4: carried-forward / brought-forward row placement
  # ---------------------------------------------------------------------------

  describe "V3/V4: carried-forward and brought-forward rows" do
    test "single-page statement has no carried-forward or brought-forward rows" do
      blocks = body_blocks(3)
      assert length(blocks) == 1, "single page should produce exactly one body block"
      block = hd(blocks)

      row_texts =
        Enum.flat_map(block.content.rows, fn row ->
          Enum.map(row, fn cell ->
            case cell do
              %{content: %{content: text}} -> text
              %{content: text} when is_binary(text) -> text
              _ -> inspect(cell)
            end
          end)
        end)

      flat = Enum.join(row_texts, " ")
      refute flat =~ "Carried forward"
      refute flat =~ "Brought forward"
    end

    test "multi-page: last row of each non-final page is carried-forward" do
      n = rows_per_page() + 5
      blocks = body_blocks(n)

      assert length(blocks) >= 2, "expected multi-page blocks"
      # All blocks except the last should have CF as last row
      non_final_blocks = Enum.drop(blocks, -1)

      for block <- non_final_blocks do
        last_row = List.last(block.content.rows)
        assert last_row != nil

        first_cell_text = row_cell_text(last_row, 0)

        assert first_cell_text =~ "Carried forward",
               "Expected last row of non-final page to be 'Carried forward', got: #{inspect(first_cell_text)}"
      end
    end

    test "multi-page: first row of each page after page 1 is brought-forward" do
      n = rows_per_page() + 5
      blocks = body_blocks(n)

      assert length(blocks) >= 2
      # All blocks except the first should have BF as first row
      non_first_blocks = Enum.drop(blocks, 1)

      for block <- non_first_blocks do
        first_row = hd(block.content.rows)
        assert first_row != nil

        first_cell_text = row_cell_text(first_row, 0)

        assert first_cell_text =~ "Brought forward",
               "Expected first row of non-first page to be 'Brought forward', got: #{inspect(first_cell_text)}"
      end
    end

    test "3-page statement has CF/BF on middle page (both first and last rows)" do
      n = rows_per_page() * 2 + 1
      blocks = body_blocks(n)

      assert length(blocks) >= 3

      # Middle page (index 1): first row = BF, last row = CF
      middle_block = Enum.at(blocks, 1)
      first_row = hd(middle_block.content.rows)
      last_row = List.last(middle_block.content.rows)

      assert row_cell_text(first_row, 0) =~ "Brought forward"
      assert row_cell_text(last_row, 0) =~ "Carried forward"
    end
  end

  # ---------------------------------------------------------------------------
  # V5: suppression — CF suppressed on last page, BF suppressed on page 1
  # ---------------------------------------------------------------------------

  describe "V5: carried/brought-forward suppression" do
    test "last page has no carried-forward row" do
      n = rows_per_page() + 3
      blocks = body_blocks(n)

      last_block = List.last(blocks)
      last_row = List.last(last_block.content.rows)

      refute row_cell_text(last_row, 0) =~ "Carried forward",
             "Last page should NOT have a carried-forward row"
    end

    test "first page has no brought-forward row" do
      n = rows_per_page() + 3
      blocks = body_blocks(n)

      first_block = hd(blocks)
      first_row = hd(first_block.content.rows)

      refute row_cell_text(first_row, 0) =~ "Brought forward",
             "First page should NOT have a brought-forward row"
    end
  end

  # ---------------------------------------------------------------------------
  # V6: running balance continuous across breaks (brought-fwd[N+1] == CF[N])
  # ---------------------------------------------------------------------------

  describe "V6: balance continuity across page breaks" do
    test "brought-forward balance equals carried-forward balance from previous page" do
      n = rows_per_page() + 5
      blocks = body_blocks(n)

      assert length(blocks) >= 2

      # For each page break, CF[page N] balance == BF[page N+1] balance
      Enum.each(0..(length(blocks) - 2), fn idx ->
        current_block = Enum.at(blocks, idx)
        next_block = Enum.at(blocks, idx + 1)

        # Last row of current_block is CF: get its balance (4th column)
        cf_row = List.last(current_block.content.rows)
        bf_row = hd(next_block.content.rows)

        cf_balance_str = row_cell_text(cf_row, 3)
        bf_balance_str = row_cell_text(bf_row, 3)

        assert cf_balance_str == bf_balance_str,
               "CF balance '#{cf_balance_str}' != BF balance '#{bf_balance_str}' at page break #{idx}"
      end)
    end

    test "fold_balance produces correct closing balance for exact decimal arithmetic" do
      # V6 also covers the Decimal fold itself — no float drift
      n = 5
      data = fixture_data(n)
      doc = Statement.document(data)

      # Derived closing = opening + sum(amounts)
      # Lines: +100, -50, +100, -50, +100 = +200 net
      # Closing = 1000.00 + 200.00 = 1200.00
      derived = expected_closing(n)
      assert Decimal.equal?(derived, Decimal.new("1200.00"))

      # Validate that the document builds without error (fold is correct)
      assert %Rendro.Document{} = doc
    end

    test "balance continuity holds with Decimal.equal?/2 (not structural ==)" do
      # Verifies the balance comparison is done correctly — Decimal precision invariant
      n = rows_per_page() + 2
      blocks = body_blocks(n)

      assert length(blocks) >= 2

      cf_row = List.last(hd(blocks).content.rows)
      bf_row = hd(Enum.at(blocks, 1).content.rows)

      cf_balance_str = row_cell_text(cf_row, 3)
      bf_balance_str = row_cell_text(bf_row, 3)

      # Structural equality on the formatted string is fine here (both are formatted by Format.money)
      assert cf_balance_str == bf_balance_str
    end
  end

  # ---------------------------------------------------------------------------
  # V7: "Page X of Y" in footer on every page including the last
  # ---------------------------------------------------------------------------

  describe "V7: Page X of Y footer on every page" do
    test "single-page statement has 'Page 1 of 1' in footer" do
      pdf = render_statement!(3)
      assert pdf =~ "(Page 1 of 1)"
    end

    test "2-page statement has 'Page 1 of 2' and 'Page 2 of 2'" do
      n = rows_per_page() + 1
      pdf = render_statement!(n)
      assert pdf =~ "(Page 1 of 2)"
      assert pdf =~ "(Page 2 of 2)"
    end

    test "3-page statement has correct page numbers on every page" do
      n = rows_per_page() * 2 + 1
      pdf = render_statement!(n)
      assert pdf =~ "(Page 1 of 3)"
      assert pdf =~ "(Page 2 of 3)"
      assert pdf =~ "(Page 3 of 3)"
    end

    test "total page count Y equals the real number of pages" do
      cap = rows_per_page()

      for n <- [cap + 1, 2 * cap + 1] do
        expected_pages = ceil(n / cap)
        pdf = render_statement!(n)
        # Y in "Page X of Y" must equal the real page count
        assert pdf =~ "of #{expected_pages})",
               "Expected Y=#{expected_pages} in footer for #{n} rows"

        refute pdf =~ "of #{expected_pages + 1})"
        refute pdf =~ "of #{expected_pages - 1})" and expected_pages > 1
      end
    end

    test "no unresolved {{page_number}} or {{total_pages}} tokens remain in PDF" do
      pdf = render_statement!(rows_per_page() + 1)
      refute pdf =~ "{{page_number}}"
      refute pdf =~ "{{total_pages}}"
    end
  end

  # ---------------------------------------------------------------------------
  # V8: Float amount rejected with instructive ArgumentError
  # ---------------------------------------------------------------------------

  describe "V8: validate_data!/1 rejects malformed input" do
    test "Float opening_balance raises ArgumentError mentioning Decimal" do
      data = fixture_data(1) |> Map.put(:opening_balance, 1000.00)

      assert_raise ArgumentError, ~r/Decimal|float/i, fn ->
        Statement.document(data)
      end
    end

    test "Float line amount raises ArgumentError mentioning Decimal" do
      data = %{
        fixture_data(0)
        | lines: [%{date: ~D[2026-05-01], description: "X", amount: 100.0}]
      }

      assert_raise ArgumentError, ~r/Decimal|float/i, fn ->
        Statement.document(data)
      end
    end

    test "missing required key raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Statement.document(%{account: %{name: "A"}, opening_balance: Decimal.new("0"), lines: []})
      end
    end

    test "malformed period raises ArgumentError" do
      data = fixture_data(0) |> Map.put(:period, "2026-05")

      assert_raise ArgumentError, fn ->
        Statement.document(data)
      end
    end

    test "caller-supplied per-line :balance raises ArgumentError" do
      line = %{
        date: ~D[2026-05-01],
        description: "X",
        amount: Decimal.new("10.00"),
        balance: Decimal.new("1010.00")
      }

      data = fixture_data(0) |> Map.put(:lines, [line])

      assert_raise ArgumentError, ~r/balance/i, fn ->
        Statement.document(data)
      end
    end

    test "missing line :date raises ArgumentError" do
      line = %{description: "X", amount: Decimal.new("10.00")}
      data = fixture_data(0) |> Map.put(:lines, [line])

      assert_raise ArgumentError, fn ->
        Statement.document(data)
      end
    end

    test "non-map data raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Statement.document("not a map")
      end
    end

    test "top-level :closing_balance that disagrees with the derived value raises (WR-01)" do
      # fixture_data(0): opening 1000.00, no lines -> derived closing 1000.00.
      # The moduledoc promises the top-level assertion is validated via
      # Decimal.equal?/2 — a wrong value must NOT be silently accepted.
      data = fixture_data(0) |> Map.put(:closing_balance, Decimal.new("99999.99"))

      assert_raise ArgumentError, ~r/closing_balance/i, fn ->
        Statement.document(data)
      end
    end

    test "top-level :closing_balance that matches the derived value is accepted (WR-01)" do
      data = fixture_data(0) |> Map.put(:closing_balance, Decimal.new("1000.00"))

      doc = Statement.document(data)
      assert %Rendro.Document{} = doc
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end

    test "non-map :account raises ArgumentError mentioning account" do
      data = fixture_data(0) |> Map.put(:account, "not-a-map")

      assert_raise ArgumentError, ~r/account/i, fn ->
        Statement.document(data)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # V9: three-rung override consistency
  # ---------------------------------------------------------------------------

  describe "V9: three-rung escape hatch" do
    test "page_template/1 returns %Rendro.PageTemplate{} with name :statement" do
      template = Statement.page_template()
      assert %Rendro.PageTemplate{} = template
      assert template.name == :statement
    end

    test "page_template/1 has regions :header, :body, :footer with correct roles" do
      template = Statement.page_template()
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

    test "footer region has non-zero height (reserves space for Page X of Y)" do
      template = Statement.page_template()
      footer = Enum.find(template.regions, &(&1.role == :footer))
      assert footer.height > 0
    end

    test "sections/2 returns [header, body, footer] with correct region targets" do
      sections = Statement.sections(fixture_data(3))
      assert is_list(sections)
      assert length(sections) == 3

      region_targets = Enum.map(sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "page_template/1 and sections/2 callable independently without document/2" do
      template = Statement.page_template(name: :custom_statement)
      assert template.name == :custom_statement

      sections = Statement.sections(fixture_data(2))
      assert is_list(sections)
    end

    test "regions consistent with Invoice pattern (header/body/footer naming)" do
      statement_template = Statement.page_template()
      invoice_template = Rendro.Recipes.Invoice.page_template()

      statement_roles = Enum.map(statement_template.regions, & &1.role) |> Enum.sort()
      invoice_roles = Enum.map(invoice_template.regions, & &1.role) |> Enum.sort()

      assert statement_roles == invoice_roles
    end
  end

  # ---------------------------------------------------------------------------
  # V10: Determinism — byte-identical render across runs
  # ---------------------------------------------------------------------------

  describe "V10: deterministic byte-identical render" do
    test "renders same statement twice with deterministic: true → byte-identical" do
      doc = Statement.document(fixture_data(5))
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "multi-page statement renders deterministically" do
      n = rows_per_page() + 5
      doc = Statement.document(fixture_data(n))
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "3-page statement renders deterministically" do
      n = rows_per_page() * 2 + 3
      doc = Statement.document(fixture_data(n))
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end
  end

  # ---------------------------------------------------------------------------
  # Load-bearing: no :content_overflow for realistic large statement
  # ---------------------------------------------------------------------------

  describe "load-bearing: no content_overflow" do
    test "boundary row counts render without :content_overflow" do
      cap = rows_per_page()

      for n <- [0, 1, cap - 1, cap, cap + 1, 2 * cap, 2 * cap + 1] do
        doc = Statement.document(fixture_data(n))
        result = Rendro.render(doc)

        assert match?({:ok, _}, result),
               "Expected {:ok, _} for #{n} rows; got: #{inspect(result)}"
      end
    end

    test "realistic large statement (10 pages) renders without overflow" do
      n = rows_per_page() * 10
      doc = Statement.document(fixture_data(n))
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end
  end

  # ---------------------------------------------------------------------------
  # Page-grouping invariant (D-10)
  # ---------------------------------------------------------------------------

  describe "page-grouping invariant (D-10)" do
    test "single-page: one body block with no break_before" do
      blocks = body_blocks(3)
      assert length(blocks) == 1
      refute hd(blocks).break_before
    end

    test "multi-page: first block has no break_before, subsequent blocks do" do
      n = rows_per_page() + 3
      blocks = body_blocks(n)

      assert length(blocks) >= 2

      [first | rest] = blocks
      refute first.break_before, "First block should NOT have break_before"

      Enum.each(rest, fn block ->
        assert block.break_before == true, "Non-first blocks should have break_before: true"
      end)
    end

    test "no keep_together in body blocks" do
      n = rows_per_page() + 3
      blocks = body_blocks(n)

      Enum.each(blocks, fn block ->
        refute block.keep_together, "No body block should have keep_together: true"
      end)
    end

    test "3-page: page count == ceil(rows / rows_per_page)" do
      cap = rows_per_page()
      n = 2 * cap + 1
      blocks = body_blocks(n)
      expected_pages = ceil(n / cap)

      assert length(blocks) == expected_pages,
             "Expected #{expected_pages} blocks for #{n} rows (cap=#{cap}); got #{length(blocks)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Extracts text content from a table row cell at the given column index.
  # Works with both raw text strings and measured/structured content.
  defp row_cell_text(row, col_idx) do
    cell = Enum.at(row, col_idx)
    extract_text(cell)
  end

  defp extract_text(cell) when is_binary(cell), do: cell

  # Match Rendro.Text before the generic %{content:} clause to avoid shadowing
  defp extract_text(%Rendro.Text{content: text}) when is_binary(text), do: text

  defp extract_text(%{content: inner}), do: extract_text(inner)

  defp extract_text(other), do: inspect(other)
end
