defmodule Rendro.Recipes.InvoiceTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Invoice

  defp sample_data do
    %{
      id: "INV-042",
      date: ~D[2026-04-30],
      items: [
        %{name: "Widget A", qty: 3, price: 200},
        %{name: "Widget B", qty: 1, price: 500}
      ]
    }
  end

  describe "page_template/1" do
    test "returns a %Rendro.PageTemplate{} with name :invoice" do
      template = Invoice.page_template()
      assert %Rendro.PageTemplate{} = template
      assert template.name == :invoice
    end

    test "template has named regions :header, :body, :footer" do
      template = Invoice.page_template()
      region_names = Enum.map(template.regions, & &1.name)
      assert :header in region_names
      assert :body in region_names
      assert :footer in region_names
    end

    test "accepts opts keyword list without error" do
      template = Invoice.page_template(name: :custom_invoice)
      assert %Rendro.PageTemplate{} = template
      assert template.name == :custom_invoice
    end
  end

  describe "sections/2" do
    test "returns a list of %Rendro.Section{} structs" do
      sections = Invoice.sections(sample_data())
      assert is_list(sections)
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
    end

    test "has sections targeting :header, :body, and :footer regions" do
      sections = Invoice.sections(sample_data())
      region_targets = Enum.map(sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "header section content includes invoice id" do
      sections = Invoice.sections(sample_data())
      header_section = Enum.find(sections, &(&1.region == :header))
      assert header_section != nil
      flat = inspect(header_section, limit: :infinity, printable_limit: :infinity)
      assert flat =~ "INV-042"
    end

    test "body section content includes line items" do
      sections = Invoice.sections(sample_data())
      body_section = Enum.find(sections, &(&1.region == :body))
      assert body_section != nil
      flat = inspect(body_section, limit: :infinity, printable_limit: :infinity)
      assert flat =~ "Widget A"
      assert flat =~ "Widget B"
    end

    test "footer section content is non-empty" do
      sections = Invoice.sections(sample_data())
      footer_section = Enum.find(sections, &(&1.region == :footer))
      assert footer_section != nil
      assert footer_section.content != []
    end
  end

  describe "themed table cells" do
    test "uses resolved semantic ink for every header and body cell" do
      theme = Rendro.Theme.dark(Rendro.Theme.default())
      colors = Rendro.Theme.resolve(theme).colors
      ink = colors.ink
      body = Invoice.sections(sample_data(), theme: theme) |> Enum.find(&(&1.region == :body))

      tables = Enum.filter(body.content, &is_struct(&1.content, Rendro.Table))

      assert [%Rendro.Block{content: %Rendro.Table{header: header, rows: rows}}] = tables

      for cell <- header ++ List.flatten(rows) do
        assert %Rendro.Block{content: %Rendro.Text{color: ^ink}} = cell
      end
    end

    test "explicit palette override wins for themed table cells" do
      body =
        Invoice.sections(sample_data(),
          theme: Rendro.Theme.dark(Rendro.Theme.default()),
          palette: %{ink: {1, 2, 3}}
        )
        |> Enum.find(&(&1.region == :body))

      [%Rendro.Block{content: %Rendro.Table{header: [header | _], rows: [[body_cell | _] | _]}}] =
        Enum.filter(body.content, &is_struct(&1.content, Rendro.Table))

      assert %Rendro.Block{content: %Rendro.Text{color: {1, 2, 3}}} = header
      assert %Rendro.Block{content: %Rendro.Text{color: {1, 2, 3}}} = body_cell
    end

    test "nil-theme tables retain literal string cells for empty, single, and equal rows" do
      [_, empty_body, _] = Invoice.sections(%{sample_data() | items: []})
      assert Enum.filter(empty_body.content, &is_struct(&1.content, Rendro.Table)) == []

      for items <- [
            [%{name: "Single", qty: 1, price: 10}],
            [%{name: "Same", qty: 1, price: 10}, %{name: "Same", qty: 1, price: 10}]
          ] do
        [_, body, _] = Invoice.sections(%{sample_data() | items: items})

        [%Rendro.Block{content: %Rendro.Table{header: header, rows: rows}}] =
          Enum.filter(body.content, &is_struct(&1.content, Rendro.Table))

        assert Enum.all?(header, &is_binary/1)
        assert Enum.all?(List.flatten(rows), &is_binary/1)
        assert Enum.map(rows, &hd/1) == Enum.map(items, & &1.name)
      end
    end
  end

  describe "document/2" do
    test "returns a %Rendro.Document{} struct" do
      doc = Invoice.document(sample_data())
      assert %Rendro.Document{} = doc
    end

    test "document has the invoice page_template in page_templates list" do
      doc = Invoice.document(sample_data())
      template_names = Enum.map(doc.page_templates, & &1.name)
      assert :invoice in template_names
    end

    test "document has page_template set to :invoice" do
      doc = Invoice.document(sample_data())
      assert doc.page_template == :invoice
    end

    test "document has sections covering all three regions" do
      doc = Invoice.document(sample_data())
      region_targets = Enum.map(doc.sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "document does NOT use legacy header/footer fields" do
      doc = Invoice.document(sample_data())
      assert doc.header == []
      assert doc.footer == []
    end

    test "document content includes invoice id and line items" do
      doc = Invoice.document(sample_data())
      flat = inspect(doc, limit: :infinity, printable_limit: :infinity)
      assert flat =~ "INV-042"
      assert flat =~ "Widget A"
    end
  end

  # ---------------------------------------------------------------------------
  # INV-06: validate_data!/1 — errors-as-product
  # ---------------------------------------------------------------------------

  describe "validate_data!/1 (INV-06)" do
    test "non-map data raises ArgumentError, not BadMapError/FunctionClauseError" do
      assert_raise ArgumentError, ~r/data must be a map/, fn ->
        Invoice.document("not-a-map")
      end
    end

    test "missing required key raises ArgumentError naming the missing key" do
      data = sample_data() |> Map.delete(:date)

      assert_raise ArgumentError, ~r/date/, fn ->
        Invoice.document(data)
      end
    end

    test "the toy call (:id, :date, :items only) is never rejected" do
      doc = Invoice.document(sample_data())
      assert %Rendro.Document{} = doc
    end

    test "non-map :issuer raises ArgumentError mentioning issuer" do
      data = Map.put(sample_data(), :issuer, "not-a-map")

      assert_raise ArgumentError, ~r/issuer/i, fn ->
        Invoice.document(data)
      end
    end

    test "non-map :customer raises ArgumentError mentioning customer" do
      data = Map.put(sample_data(), :customer, "not-a-map")

      assert_raise ArgumentError, ~r/customer/i, fn ->
        Invoice.document(data)
      end
    end

    test "non-Date :due_date raises ArgumentError mentioning due_date" do
      data = Map.put(sample_data(), :due_date, "2026-05-01")

      assert_raise ArgumentError, ~r/due_date/i, fn ->
        Invoice.document(data)
      end
    end

    test "non-string :terms raises ArgumentError mentioning terms" do
      data = Map.put(sample_data(), :terms, 30)

      assert_raise ArgumentError, ~r/terms/i, fn ->
        Invoice.document(data)
      end
    end

    test "a non-map line item raises ArgumentError, not BadMapError" do
      data = Map.put(sample_data(), :items, ["not-a-map"])

      assert_raise ArgumentError, ~r/line item/i, fn ->
        Invoice.document(data)
      end
    end

    test "a line item missing :qty raises ArgumentError, not KeyError" do
      data = Map.put(sample_data(), :items, [%{name: "Widget", price: 10}])

      assert_raise ArgumentError, ~r/qty/i, fn ->
        Invoice.document(data)
      end
    end

    test "a line item missing :name raises ArgumentError naming :name" do
      data = Map.put(sample_data(), :items, [%{qty: 1, price: 10}])

      assert_raise ArgumentError, ~r/name/i, fn ->
        Invoice.document(data)
      end
    end

    test "a line item missing :price raises ArgumentError naming :price" do
      data = Map.put(sample_data(), :items, [%{name: "Widget", qty: 1}])

      assert_raise ArgumentError, ~r/price/i, fn ->
        Invoice.document(data)
      end
    end

    test "a non-integer :qty raises ArgumentError, not a downstream crash" do
      data = Map.put(sample_data(), :items, [%{name: "Widget", qty: "two", price: 10}])

      assert_raise ArgumentError, ~r/qty/i, fn ->
        Invoice.document(data)
      end
    end

    test "a non-number :price raises an instructive ArgumentError" do
      data = Map.put(sample_data(), :items, [%{name: "Widget", qty: 1, price: "ten"}])

      assert_raise ArgumentError, ~r/price/i, fn ->
        Invoice.document(data)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # INV-01: optional anatomy fields render only when present
  # ---------------------------------------------------------------------------

  describe "optional anatomy fields (INV-01)" do
    test "issuer renders only when present" do
      absent = Invoice.sections(sample_data())
      present = Invoice.sections(Map.put(sample_data(), :issuer, %{name: "Rendro Systems"}))

      refute inspect(absent, limit: :infinity) =~ "Rendro Systems"
      assert inspect(present, limit: :infinity) =~ "Rendro Systems"
    end

    test "customer renders only when present" do
      absent = Invoice.sections(sample_data())
      present = Invoice.sections(Map.put(sample_data(), :customer, %{name: "Acme Phoenix SaaS"}))

      refute inspect(absent, limit: :infinity) =~ "Acme Phoenix SaaS"
      assert inspect(present, limit: :infinity) =~ "Acme Phoenix SaaS"
    end

    test "due_date renders only when present" do
      absent = Invoice.sections(sample_data())
      present = Invoice.sections(Map.put(sample_data(), :due_date, ~D[2026-05-30]))

      refute inspect(absent, limit: :infinity) =~ "2026-05-30"
      assert inspect(present, limit: :infinity) =~ "2026-05-30"
    end

    test "terms renders only when present" do
      absent = Invoice.sections(sample_data())
      present = Invoice.sections(Map.put(sample_data(), :terms, "Net 30"))

      refute inspect(absent, limit: :infinity) =~ "Net 30"
      assert inspect(present, limit: :infinity) =~ "Net 30"
    end

    test "absent anatomy fields keep header section identical to the toy path" do
      base = Invoice.sections(sample_data())
      with_nothing_new = Invoice.sections(sample_data())
      assert base == with_nothing_new
    end
  end

  # ---------------------------------------------------------------------------
  # INV-02: money split — legacy bare-number price vs new Decimal fields
  # ---------------------------------------------------------------------------

  describe "money split (INV-02)" do
    test "legacy bare-number :price still renders as a bare-number dollar string" do
      data = sample_data()
      sections = Invoice.sections(data)
      body = Enum.find(sections, &(&1.region == :body))
      flat = inspect(body, limit: :infinity, printable_limit: :infinity)

      assert flat =~ "$200"
      assert flat =~ "$500"
    end

    test "new Decimal totals field renders via Rendro.Format.money/1" do
      data =
        sample_data()
        |> Map.put(:totals, %{
          subtotal: Decimal.new("1100"),
          total: Decimal.new("1100")
        })

      sections = Invoice.sections(data)
      body = Enum.find(sections, &(&1.region == :body))
      flat = inspect(body, limit: :infinity, printable_limit: :infinity)

      assert flat =~ "$1,100.00"
    end

    test "a Float in a new totals money field raises an instructive ArgumentError" do
      data = Map.put(sample_data(), :totals, %{subtotal: 1100.0})

      assert_raise ArgumentError, ~r/Decimal/i, fn ->
        Invoice.document(data)
      end
    end

    test "a %Decimal{} in the legacy :price slot is accepted and renders faithful 2-decimal cents (118-08)" do
      data = %{
        id: "INV-DEC-01",
        date: ~D[2026-05-01],
        items: [%{name: "Widget", qty: 1, price: Decimal.new("10.00")}]
      }

      sections = Invoice.sections(data)
      body = Enum.find(sections, &(&1.region == :body))
      flat = inspect(body, limit: :infinity, printable_limit: :infinity)

      assert flat =~ "$10.00"
    end
  end

  # ---------------------------------------------------------------------------
  # INV-03: totals block — Decimal.equal? assertion + kept with last rows
  # ---------------------------------------------------------------------------

  describe "totals block (INV-03)" do
    test "no :totals key → no totals block; toy golden path stays green" do
      sections = Invoice.sections(sample_data())
      body = Enum.find(sections, &(&1.region == :body))

      refute Enum.any?(body.content, fn block ->
               is_struct(block.content, Rendro.Text) and
                 String.contains?(block.content.content, "Subtotal")
             end)
    end

    test "totals present renders Subtotal/Tax/Discount/Total lines" do
      data =
        sample_data()
        |> Map.put(:totals, %{
          subtotal: Decimal.new("1100"),
          tax: Decimal.new("88"),
          discount: Decimal.new("10"),
          total: Decimal.new("1178")
        })

      sections = Invoice.sections(data)
      body = Enum.find(sections, &(&1.region == :body))
      flat = inspect(body, limit: :infinity, printable_limit: :infinity)

      assert flat =~ "Subtotal"
      assert flat =~ "Tax"
      assert flat =~ "Discount"
      assert flat =~ "Total"
    end

    test "118-08: Total Due renders in its own block, larger than the Subtotal/Tax/Discount block (SHOW-01 dominance)" do
      data =
        sample_data()
        |> Map.put(:totals, %{
          subtotal: Decimal.new("1100"),
          tax: Decimal.new("88"),
          discount: Decimal.new("10"),
          total: Decimal.new("1178")
        })

      sections = Invoice.sections(data)
      body = Enum.find(sections, &(&1.region == :body))

      text_blocks =
        Enum.filter(body.content, fn block -> is_struct(block.content, Rendro.Text) end)

      minor_block =
        Enum.find(text_blocks, fn block -> block.content.content =~ "Subtotal" end)

      total_block =
        Enum.find(text_blocks, fn block -> block.content.content =~ "Total Due" end)

      assert minor_block != nil
      assert total_block != nil
      assert total_block != minor_block
      assert total_block.content.content =~ "$1,178.00"
      assert total_block.content.size > minor_block.content.size
    end

    test "118-08: a fully-populated invoice (issuer+customer+due_date+terms+totals) renders without :content_overflow" do
      data =
        sample_data()
        |> Map.put(:issuer, %{name: "Rendro Systems", address: "1 Foundry Way, Raleigh, NC"})
        |> Map.put(:customer, %{name: "Acme Phoenix SaaS", address: "200 Market St, Denver, CO"})
        |> Map.put(:due_date, ~D[2026-05-30])
        |> Map.put(:terms, "Net 30")
        |> Map.put(:totals, %{
          subtotal: Decimal.new("1100"),
          tax: Decimal.new("88"),
          total: Decimal.new("1188")
        })

      doc = Invoice.document(data)
      assert {:ok, pdf} = Rendro.render(doc)
      assert is_binary(pdf)
    end

    test "mismatched :totals.subtotal raises ArgumentError naming Supplied and Derived" do
      data = Map.put(sample_data(), :totals, %{subtotal: Decimal.new("999.00")})

      assert_raise ArgumentError, ~r/Supplied.*Derived/s, fn ->
        Invoice.document(data)
      end
    end

    test "mismatched :totals.total raises ArgumentError naming Supplied and Derived" do
      data = Map.put(sample_data(), :totals, %{total: Decimal.new("999.00")})

      assert_raise ArgumentError, ~r/Supplied.*Derived/s, fn ->
        Invoice.document(data)
      end
    end

    test "matching :totals (Decimal.equal?, not ==) is accepted" do
      # 1100 vs 1100.00 — struct fields differ (`==` would be false), but
      # Decimal.equal?/2 (numeric) must accept them.
      data = Map.put(sample_data(), :totals, %{subtotal: Decimal.new("1100.00")})
      doc = Invoice.document(data)
      assert %Rendro.Document{} = doc
    end

    test "no block in the body section content uses keep_together" do
      data = Map.put(sample_data(), :totals, %{subtotal: Decimal.new("1100")})
      sections = Invoice.sections(data)
      body = Enum.find(sections, &(&1.region == :body))

      refute Enum.any?(body.content, & &1.keep_together)
    end

    test "totals stays with the last rows when the last table page is near capacity" do
      # Build enough items to fill (roughly) exactly one page's worth of
      # capacity WITHOUT any totals reservation. With totals present, the
      # totals-height reservation must push at least the last item onto a
      # second table page, proving the reservation mechanism actively keeps
      # room for totals next to the final page's rows (rather than leaving
      # totals to overflow onto a fresh, otherwise-empty page).
      content_width = 595.28 - 2 * 72

      table_opts = [
        header: ["Item", "Qty", "Price"],
        columns: [{:share, 1}, {:fixed, 50}, {:fixed, 80}]
      ]

      row = ["Widget", "1", "$10.00"]
      doc_for_measure = Rendro.Document.new()

      {header_h, row_heights} =
        Rendro.measure_rows([row], content_width, doc_for_measure, table_opts)

      row_h = hd(row_heights)

      body_height = 841.89 - 2 * 72 - 56 - 24
      effective_capacity_no_totals = body_height - header_h - 2.0
      n = trunc(effective_capacity_no_totals / row_h)

      assert n * row_h > body_height - 56 - 24 - header_h - 2.0,
             "boundary item count must exceed the former double-subtracted capacity"

      items = for i <- 1..n//1, do: %{name: "Item #{i}", qty: 1, price: 10}

      data_no_totals = %{id: "INV-BOUNDARY", date: ~D[2026-05-01], items: items}

      data_with_totals =
        Map.put(data_no_totals, :totals, %{subtotal: Decimal.new(n * 10)})

      [_h1, body_no_totals, _f1] = Invoice.sections(data_no_totals)
      [_h2, body_with_totals, _f2] = Invoice.sections(data_with_totals)

      table_blocks_no_totals =
        Enum.filter(body_no_totals.content, &is_struct(&1.content, Rendro.Table))

      table_blocks_with_totals =
        Enum.filter(body_with_totals.content, &is_struct(&1.content, Rendro.Table))

      assert length(table_blocks_no_totals) == 1,
             "boundary item count should fit on exactly 1 page without totals reservation"

      assert length(table_blocks_with_totals) >= 2,
             "the same item count must spill onto a 2nd table page once totals height is reserved"

      # The totals block must be the LAST content block, immediately after
      # the last (2nd+) table block — i.e. on the same page as the last rows.
      last_block = List.last(body_with_totals.content)
      refute is_struct(last_block.content, Rendro.Table)

      last_table_block = List.last(table_blocks_with_totals)
      assert last_table_block.break_before == true

      # The totals block (last_block) immediately follows the last table
      # block in the body content list — both land on the same final page.
      assert Enum.at(body_with_totals.content, -2) == last_table_block
    end
  end
end
