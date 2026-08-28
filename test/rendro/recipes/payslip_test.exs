defmodule Rendro.Recipes.PayslipTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Payslip

  # ---------------------------------------------------------------------------
  # Test Fixture Helpers
  # ---------------------------------------------------------------------------

  # Fictional-only payslip fixture (D-14 PII masking is mandatory -- no real
  # personal data, ever). Masked identifier fields use the "·" (middot)
  # masking token. :net_pay is auto-derived from :earnings/:deductions unless
  # explicitly overridden in opts, so callers can vary line items (e.g.
  # overflow/D-17 tests) without hand-computing a reconciling net_pay.
  defp fixture_data(opts \\ []) do
    overrides = Map.new(opts)

    earnings = Map.get(overrides, :earnings, default_earnings())
    deductions = Map.get(overrides, :deductions, default_deductions())

    net_pay =
      cond do
        Map.has_key?(overrides, :net_pay) ->
          overrides.net_pay

        all_decimal_amounts?(earnings) and all_decimal_amounts?(deductions) ->
          Decimal.sub(sum_amounts(earnings), sum_amounts(deductions))

        true ->
          Decimal.new("3580.00")
      end

    base = %{
      employer: %{name: "Aurora Textiles Co.", address: "500 Loom Street, Raleigh, NC 27601"},
      employee: %{
        name: "Jordan Rivera",
        id: "E-·····4821",
        tax_code: "1257L"
      },
      period: %{from: ~D[2026-06-01], to: ~D[2026-06-30]},
      pay_date: ~D[2026-07-05],
      earnings: earnings,
      deductions: deductions,
      net_pay: net_pay,
      payment_method: "Direct Deposit ···· 4321"
    }

    Map.merge(base, Map.drop(overrides, [:earnings, :deductions, :net_pay]))
  end

  defp default_earnings do
    [%{description: "Base Salary", amount: Decimal.new("4200.00"), ytd: Decimal.new("25200.00")}]
  end

  defp default_deductions do
    [
      %{
        description: "Federal Income Tax",
        amount: Decimal.new("620.00"),
        ytd: Decimal.new("3720.00")
      }
    ]
  end

  defp all_decimal_amounts?(lines) do
    Enum.all?(lines, fn line -> match?(%Decimal{}, Map.get(line, :amount)) end)
  end

  defp sum_amounts(lines) do
    Enum.reduce(lines, Decimal.new(0), fn line, acc -> Decimal.add(acc, line.amount) end)
  end

  # ---------------------------------------------------------------------------
  # page_template/1 (D-14 geometry)
  # ---------------------------------------------------------------------------

  describe "page_template/1" do
    test "returns a %Rendro.PageTemplate{} with the 4 D-14 region names" do
      template = Payslip.page_template()
      assert %Rendro.PageTemplate{} = template

      region_names = Enum.map(template.regions, & &1.name)
      assert :header in region_names
      assert :summary in region_names
      assert :body in region_names
      assert :footer in region_names
    end

    test "page_size: :us_letter yields different geometry than the :a4 default" do
      a4 = Payslip.page_template()
      letter = Payslip.page_template(page_size: :us_letter)

      refute {a4.width, a4.height} == {letter.width, letter.height}
    end
  end

  # ---------------------------------------------------------------------------
  # @default_labels (D-18)
  # ---------------------------------------------------------------------------

  describe "@default_labels (D-18)" do
    test "ships all 13 jurisdiction-neutral English label keys" do
      expected_keys = [
        :earnings,
        :deductions,
        :description,
        :amount,
        :ytd_amount,
        :gross_pay,
        :total_deductions,
        :net_pay,
        :year_to_date,
        :pay_period,
        :pay_date,
        :employer,
        :employee
      ]

      labels = Payslip.__default_labels__()

      for key <- expected_keys do
        assert Map.has_key?(labels, key), "expected @default_labels to have key #{inspect(key)}"
      end

      assert map_size(labels) == length(expected_keys)
    end
  end

  # ---------------------------------------------------------------------------
  # validate_data!/1 (via Payslip.document/2) -- D-15 shape/type checks
  # ---------------------------------------------------------------------------

  describe "validate_data!/1 (D-15 shape/type checks)" do
    test "does NOT raise for a well-formed minimal payload (empty :deductions is valid)" do
      data = fixture_data(deductions: [])
      assert %Rendro.Document{} = Payslip.document(data)
    end

    test "raises an instructive ArgumentError for missing :net_pay" do
      data = fixture_data() |> Map.delete(:net_pay)

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Payslip.document(data)
      end
    end

    test "raises an instructive ArgumentError for empty :earnings" do
      data = fixture_data(earnings: [])

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Payslip.document(data)
      end
    end

    test "raises an instructive ArgumentError for a Float in an earnings line's :amount" do
      data = fixture_data(earnings: [%{description: "Base", amount: 100.0}])

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Payslip.document(data)
      end
    end

    test "raises an instructive ArgumentError for a Float in a deductions line's :ytd" do
      data =
        fixture_data(
          deductions: [%{description: "Tax", amount: Decimal.new("100.00"), ytd: 500.0}]
        )

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Payslip.document(data)
      end
    end

    test "raises an instructive ArgumentError for a non-%Date{} :pay_date" do
      data = fixture_data(pay_date: "2026-07-05")

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Payslip.document(data)
      end
    end

    test "raises an instructive ArgumentError for :employer missing :name" do
      data = fixture_data(employer: %{address: "123 Main St"})

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Payslip.document(data)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # PII masking (D-14, FAM-01) -- test-enforced, not prose-only
  # ---------------------------------------------------------------------------

  describe "PII masking is test-enforced (D-14, FAM-01)" do
    test "fixture_data()'s masked identifier fields are masked, never full-length unmasked ids" do
      data = fixture_data()

      for field <- [data.employee.id, data.payment_method] do
        assert String.contains?(field, "·"),
               "expected masked field #{inspect(field)} to contain the middot masking token"

        refute Regex.match?(~r/^\d{9}$/, field),
               "masked field #{inspect(field)} matched an unmasked SSN-style 9-digit pattern"

        refute Regex.match?(~r/^\d{6,}$/, field),
               "masked field #{inspect(field)} matched an unmasked bank/NI-style 6+-digit pattern"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # sections/2, document/2, D-11 net-pay visual anchor (Task 2)
  # ---------------------------------------------------------------------------

  describe "sections/2 and document/2" do
    test "sections/2 returns %Section{} structs whose regions include :header and :footer" do
      sections = Payslip.sections(fixture_data())
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))

      region_names = Enum.map(sections, & &1.region)
      assert :header in region_names
      assert :footer in region_names
    end

    test "document/2 renders {:ok, pdf} starting with the PDF magic bytes" do
      doc = Payslip.document(fixture_data())
      assert %Rendro.Document{} = doc

      assert {:ok, pdf} = Rendro.render(doc)
      assert String.starts_with?(pdf, "%PDF-")
    end

    test "the net-pay anchor's value is the single largest text element on the page (D-11)" do
      data = fixture_data()
      sections = Payslip.sections(data)

      sizes_by_region =
        Enum.map(sections, fn section -> {section.region, collect_text_sizes(section)} end)

      all_sizes = Enum.flat_map(sizes_by_region, fn {_region, sizes} -> sizes end)
      max_size = Enum.max(all_sizes)

      summary_sizes = sizes_for_region(sizes_by_region, :summary)
      header_sizes = sizes_for_region(sizes_by_region, :header)
      footer_sizes = sizes_for_region(sizes_by_region, :footer)

      assert max_size in summary_sizes,
             "expected the global-max text size #{max_size} to occur in the :summary (net-pay anchor) region"

      refute max_size in header_sizes,
             "the :header region must not contain the global-max text size"

      refute max_size in footer_sizes,
             "the :footer region must not contain the global-max text size"
    end

    test ":labels opts override the net-pay label end to end" do
      doc = Payslip.document(fixture_data(), labels: %{net_pay: "TAKE HOME"})
      assert {:ok, pdf} = Rendro.render(doc)
      assert pdf =~ "(TAKE HOME)"
    end

    test "a supplied Swiss theme keeps the complete Net Pay amount right-aligned in its focal band" do
      theme = Rendro.Theme.preset(:swiss, accent: "#2C6BED")
      sections = Payslip.sections(fixture_data(), theme: theme)
      summary = Enum.find(sections, &(&1.region == :summary))

      summary_region =
        Enum.find(Payslip.page_template(theme: theme).regions, &(&1.name == :summary))

      value_block =
        Enum.find(summary.content, fn block ->
          is_struct(block.content, Rendro.Text) and block.content.content == "$3,580.00"
        end)

      label_block =
        Enum.find(summary.content, fn block ->
          is_struct(block.content, Rendro.Text) and block.content.content == "NET PAY"
        end)

      assert value_block.content.size == theme.typography.scale.display
      assert label_block.content.size == theme.typography.scale.body
      assert value_block.content.size > label_block.content.size
      assert value_block.x > 0
      assert_in_delta value_block.x + value_block.width, summary_region.width, 0.01
    end
  end

  # ---------------------------------------------------------------------------
  # D-12 combined ledger, pagination, D-13 reconciliation, D-17 (Task 3)
  # ---------------------------------------------------------------------------

  describe "body_section/2 — combined ledger, pagination, D-13 reconciliation" do
    test "1 earnings + 1 deductions line renders with right-aligned formatted amounts" do
      doc = Payslip.document(fixture_data())
      assert {:ok, pdf} = Rendro.render(doc)

      assert pdf =~ "(Base Salary)"
      assert pdf =~ "(Federal Income Tax)"
      assert pdf =~ Rendro.Format.money(Decimal.new("4200.00"))
      assert pdf =~ Rendro.Format.money(Decimal.new("620.00"))
    end

    test "overflowing earnings paginate across 2+ pages, repeating the header, reconciliation only on the last page" do
      earnings =
        for i <- 1..80 do
          %{
            description: "Earning Line #{i}",
            amount: Decimal.new("100.00"),
            ytd: Decimal.new("1200.00")
          }
        end

      data = fixture_data(earnings: earnings)
      doc = Payslip.document(data)
      assert {:ok, pdf} = Rendro.render(doc)

      assert pdf =~ "(Page 2 of"

      assert count_occurrences(pdf, "(Earnings)") >= 2,
             "expected the 6-column table header to repeat on every ledger page"

      assert count_occurrences(pdf, "Gross Pay") == 2,
             "expected \"Gross Pay\" to appear exactly twice (subtotal row + reconciliation " <>
               "equation), both on the last page only -- never once per page"
    end

    test "raises an instructive ArgumentError naming the net_pay mismatch" do
      data = fixture_data(net_pay: Decimal.new("1.00"))

      error =
        assert_raise ArgumentError, fn ->
          Payslip.document(data)
        end

      assert error.message =~ "net_pay"
      assert error.message =~ "1.00"
      assert error.message =~ ~r/What:.*Where:.*Why:.*Next:/s
    end

    test "raises an instructive ArgumentError (not ArithmeticError) for a Float earnings amount" do
      data = fixture_data(earnings: [%{description: "Base", amount: 100.0}])

      assert_raise ArgumentError, ~r/What:.*Where:.*Why:.*Next:/s, fn ->
        Payslip.document(data)
      end
    end

    test "byte-identity holds across two deterministic renders" do
      doc = Payslip.document(fixture_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "D-17: arbitrary non-English/unrelated :description strings round-trip unchanged, no jurisdiction-keyword filtering" do
      data =
        fixture_data(
          earnings: [
            %{description: "Impôt sur le revenu (PAYE)", amount: Decimal.new("100.00")},
            %{description: "Xyzzy Plugh Quux Nonstandard Label", amount: Decimal.new("50.00")}
          ]
        )

      sections = Payslip.sections(data)
      all_text_contents = Enum.flat_map(sections, &collect_text_contents/1)

      assert "Impôt sur le revenu (PAYE)" in all_text_contents,
             "expected the accented description to appear verbatim, unmutated, in the built content"

      assert "Xyzzy Plugh Quux Nonstandard Label" in all_text_contents,
             "expected the nonstandard description to appear verbatim, unmutated, in the built content"

      doc = Payslip.document(data)
      assert {:ok, pdf} = Rendro.render(doc)
      assert String.starts_with?(pdf, "%PDF-")
      # A long description wraps across multiple lines/Tj runs at table
      # column width, so a raw whole-string byte search isn't reliable here
      # (word fragments still round-trip -- verified structurally above via
      # the unmutated Section/Block content check).
      assert pdf =~ "Nonstandard"
    end
  end

  # ---------------------------------------------------------------------------
  # 118-08 gap-closure — de-crowd the earnings/deductions table (SHOW-01)
  # ---------------------------------------------------------------------------

  describe "118-08: de-crowded earnings/deductions table" do
    test "a group spacer column separates the earnings YTD header from the Deductions header" do
      sections = Payslip.sections(fixture_data())
      body = Enum.find(sections, &(&1.region == :body))
      table_block = Enum.find(body.content, fn b -> is_struct(b.content, Rendro.Table) end)
      table = table_block.content

      # 7 columns: Earnings|Current|YTD|<spacer>|Deductions|Current|YTD.
      # The spacer's own header cell is blank, giving the two groups a
      # genuine visual gap (never zero-width butting, per 118-06-FINDINGS.md).
      assert length(table.header) == 7
      assert Enum.at(table.header, 3) == ""
      assert Enum.at(table.header, 0) =~ "Earnings"
      assert Enum.at(table.header, 4) =~ "Deductions"
    end

    test "a wide YTD money value ($25,200.00) does not wrap onto a second line" do
      data =
        fixture_data(
          earnings: [
            %{
              description: "Base Salary",
              amount: Decimal.new("4200.00"),
              ytd: Decimal.new("25200.00")
            }
          ],
          deductions: []
        )

      sections = Payslip.sections(data)
      body = Enum.find(sections, &(&1.region == :body))
      table_block = Enum.find(body.content, fn b -> is_struct(b.content, Rendro.Table) end)
      table = table_block.content

      content_width = 595.28 - 2 * 72
      table_opts = [header: table.header, columns: table.columns, cell_align: table.cell_align]
      doc = Rendro.Document.new()
      {_header_h, row_heights} = Rendro.measure_rows(table.rows, content_width, doc, table_opts)

      # Single-line height at size 11 * line_height 1.2 = 13.2. A wrapped
      # 2-line cell would measure ~26.4 — assert every row stays single-line.
      assert Enum.all?(row_heights, fn h -> h < 20 end),
             "expected every row (incl. the $25,200.00 YTD cell) to stay single-line, got: #{inspect(row_heights)}"
    end

    test "the Net Pay summary box remains the dominant (largest) element (CH=5 preserved)" do
      doc = Payslip.document(fixture_data())
      sizes_by_region = doc.sections |> Enum.map(&{&1.region, collect_text_sizes(&1)})

      all_sizes = Enum.flat_map(sizes_by_region, fn {_region, sizes} -> sizes end)
      max_size = Enum.max(all_sizes)
      summary_sizes = sizes_for_region(sizes_by_region, :summary)

      assert max_size in summary_sizes,
             "expected the global-max text size #{max_size} to remain in the :summary (net-pay anchor) region"
    end

    @genres [:swiss, :humanist, :editorial, :corporate_classic, :minimal_mono, :brutalist]

    test "Current and YTD money tokens stay atomic at the selected width across supplied themes" do
      data =
        fixture_data(
          earnings: [
            %{
              description: "Base Salary",
              amount: Decimal.new("4200.00"),
              ytd: Decimal.new("25200.00")
            }
          ],
          deductions: [
            %{
              description: "Withholding",
              amount: Decimal.new("4550.00"),
              ytd: Decimal.new("25200.00")
            }
          ]
        )

      themes =
        [
          {:default, Rendro.Theme.default()}
          | Enum.map(@genres, &{&1, Rendro.Theme.preset(&1, accent: "#2C6BED")})
        ]

      for {name, theme} <- themes do
        {table, doc} = themed_table_and_document(data, theme)

        for {label, cell, width} <- amount_cells(table) do
          assert one_line?(cell, width, doc),
                 "#{name} must keep #{label} on one line at #{width}pt"

          if name == :humanist do
            refute one_line?(cell, width - 1, doc),
                   "#{name} must prove #{label}'s selected #{width}pt width is a real one-point boundary"
          end
        end
      end
    end
  end

  describe "sequential measured ledger profile" do
    test "omitted and nil YTD values render as blank while present values keep money formatting" do
      data =
        fixture_data(
          earnings: [
            %{description: "Omitted YTD", amount: Decimal.new("100.00")},
            %{description: "Nil YTD", amount: Decimal.new("200.00"), ytd: nil},
            %{description: "Zero YTD", amount: Decimal.new("300.00"), ytd: Decimal.new("0.00")}
          ],
          deductions: [
            %{
              description: "Present YTD",
              amount: Decimal.new("50.00"),
              ytd: Decimal.new("625.00")
            }
          ]
        )

      opts = [
        theme: Rendro.Theme.preset(:swiss, accent: "#2C6BED"),
        presentation_profile: %{ledger_layout: :sequential_measured}
      ]

      document = Payslip.document(data, opts)
      assert {:ok, first_pdf} = Rendro.render(document, deterministic: true)
      assert {:ok, second_pdf} = Rendro.render(document, deterministic: true)
      assert first_pdf == second_pdf

      body = Enum.find(document.sections, &(&1.region == :body))
      [earnings, deductions] = Enum.filter(body.content, &is_struct(&1.content, Rendro.Table))

      assert Enum.map(earnings.content.rows, &collect_content_from_row/1) == [
               ["Omitted YTD", "$100.00", ""],
               ["Nil YTD", "$200.00", ""],
               ["Zero YTD", "$300.00", "$0.00"]
             ]

      assert Enum.map(deductions.content.rows, &collect_content_from_row/1) == [
               ["Present YTD", "$50.00", "$625.00"]
             ]
    end

    test "zero, one, and many real rows preserve supplied section order without padding" do
      cases = [
        {"zero deductions", default_earnings(), []},
        {"one row per section", default_earnings(), default_deductions()},
        {"asymmetric many rows",
         for(
           index <- 1..5,
           do: %{
             description: "Earning #{index}",
             amount: Decimal.new("100.00"),
             ytd: Decimal.new("1200.00")
           }
         ),
         for(
           index <- 1..3,
           do: %{
             description: "Deduction #{index}",
             amount: Decimal.new("10.00"),
             ytd: Decimal.new("120.00")
           }
         )}
      ]

      for {label, earnings, deductions} <- cases do
        document = sequential_document(fixture_data(earnings: earnings, deductions: deductions))
        body = Enum.find(document.sections, &(&1.region == :body))

        earning_rows = rows_for_heading(body, "Earnings")
        deduction_rows = rows_for_heading(body, "Deductions")

        assert Enum.map(earning_rows, &(&1 |> collect_content_from_row() |> hd())) ==
                 Enum.map(earnings, & &1.description),
               label

        assert Enum.map(deduction_rows, &(&1 |> collect_content_from_row() |> hd())) ==
                 Enum.map(deductions, & &1.description),
               label

        assert length(earning_rows) == length(earnings), label
        assert length(deduction_rows) == length(deductions), label

        refute Enum.any?(
                 earning_rows ++ deduction_rows,
                 &(collect_content_from_row(&1) == ["", "", ""])
               )

        assert {:ok, first_pdf} = Rendro.render(document, deterministic: true)
        assert {:ok, second_pdf} = Rendro.render(document, deterministic: true)
        assert first_pdf == second_pdf, label
      end
    end

    test "the held-out description boundary wraps only prose while equal money ties stay atomic" do
      exact_fit = Enum.join(List.duplicate("route", 7), " ")
      one_step_over = Enum.join(List.duplicate("route", 8), " ")
      widest_money = Decimal.new("123456789.00")

      data =
        fixture_data(
          earnings: [
            %{description: exact_fit, amount: widest_money, ytd: widest_money},
            %{description: one_step_over, amount: widest_money, ytd: widest_money}
          ],
          deductions: []
        )

      document = sequential_document(data)
      body = Enum.find(document.sections, &(&1.region == :body))
      [table_block] = tables_for_heading(body, "Earnings")
      table = table_block.content

      {_header_height, [exact_height, over_height]} =
        Rendro.measure_rows(table.rows, 595.28 - 2 * 72, document,
          header: table.header,
          columns: table.columns,
          cell_align: table.cell_align,
          borders: table.borders
        )

      assert exact_height < 20
      assert over_height > exact_height
      assert fixed_width(table.columns, 1) == fixed_width(table.columns, 2)

      for row <- table.rows, index <- [1, 2] do
        assert one_line?(Enum.at(row, index), fixed_width(table.columns, index), document)
      end

      assert Enum.map(table.rows, &(&1 |> collect_content_from_row() |> hd())) == [
               exact_fit,
               one_step_over
             ]

      assert {:ok, first_pdf} = Rendro.render(document, deterministic: true)
      assert {:ok, second_pdf} = Rendro.render(document, deterministic: true)
      assert first_pdf == second_pdf
    end

    test "28 exactly fitting rows stay on one ledger page and row 29 starts a repeated header" do
      exact_document =
        sequential_document(fixture_data(earnings: boundary_earnings(28), deductions: []))

      over_document =
        sequential_document(fixture_data(earnings: boundary_earnings(29), deductions: []))

      exact_body = Enum.find(exact_document.sections, &(&1.region == :body))
      over_body = Enum.find(over_document.sections, &(&1.region == :body))

      assert length(tables_for_heading(exact_body, "Earnings")) == 1
      assert length(tables_for_heading(over_body, "Earnings")) == 2
      assert length(rows_for_heading(exact_body, "Earnings")) == 28
      assert length(rows_for_heading(over_body, "Earnings")) == 29

      assert Enum.map(rows_for_heading(over_body, "Earnings"), fn row ->
               row |> collect_content_from_row() |> hd()
             end) == Enum.map(1..29, &"Boundary earning #{&1}")

      for document <- [exact_document, over_document] do
        assert {:ok, first_pdf} = Rendro.render(document, deterministic: true)
        assert {:ok, second_pdf} = Rendro.render(document, deterministic: true)
        assert first_pdf == second_pdf
        assert first_pdf =~ "Gross Pay"
        assert first_pdf =~ "Total Deductions"
        assert first_pdf =~ "NET PAY"
      end

      assert {:ok, over_pdf} = Rendro.render(over_document, deterministic: true)
      assert count_occurrences(over_pdf, "(Earnings)") == 2
      assert over_pdf =~ "(Page 2 of"
    end

    test "renders independent full-width Earnings then Deductions tables for the Swiss profile" do
      sections =
        Payslip.sections(fixture_data(),
          theme: Rendro.Theme.preset(:swiss, accent: "#2C6BED"),
          presentation_profile: %{ledger_layout: :sequential_measured}
        )

      body = Enum.find(sections, &(&1.region == :body))
      tables = Enum.filter(body.content, &is_struct(&1.content, Rendro.Table))

      assert Enum.map(tables, &collect_content_from_row(&1.content.header)) == [
               ["Earnings", "Current", "YTD"],
               ["Deductions", "Current", "YTD"]
             ]

      assert Enum.all?(tables, fn block ->
               block.content.columns |> length() |> Kernel.==(3)
             end)
    end

    test "keeps a continued ledger's own header and reconciliation adjacent to the final table" do
      earnings =
        for index <- 1..80 do
          %{
            description: "Long earned route coverage description #{index}",
            amount: Decimal.new("100.00"),
            ytd: Decimal.new("1200.00")
          }
        end

      sections =
        Payslip.sections(fixture_data(earnings: earnings),
          theme: Rendro.Theme.preset(:swiss, accent: "#2C6BED"),
          presentation_profile: %{ledger_layout: :sequential_measured}
        )

      body = Enum.find(sections, &(&1.region == :body))
      tables = Enum.filter(body.content, &is_struct(&1.content, Rendro.Table))
      headers = Enum.map(tables, &collect_content_from_row(&1.content.header))
      deduction_index = Enum.find_index(headers, &(&1 == ["Deductions", "Current", "YTD"]))

      assert Enum.count(headers, &(&1 == ["Earnings", "Current", "YTD"])) >= 2
      assert deduction_index && deduction_index > 0
      refute Enum.at(tables, deduction_index).break_before

      [last_table | _] = Enum.reverse(tables)

      reconciliation_index =
        Enum.find_index(body.content, &(&1.content == last_table.content)) + 1

      assert %Rendro.Text{content: reconciliation} =
               Enum.at(body.content, reconciliation_index).content

      assert reconciliation =~ "Gross Pay"
      assert reconciliation =~ "Total Deductions"
      assert reconciliation =~ "NET PAY"
    end
  end

  # ---------------------------------------------------------------------------
  # Recursive %Rendro.Text{} size/content collectors — reused by Task 3's
  # table assertions (a table's header/rows/cells may wrap Rendro.Block/
  # Rendro.Cell content, or be plain (unmeasured) strings, per
  # lib/rendro/pipeline/measure.ex's normalize_cells/1).
  # ---------------------------------------------------------------------------

  defp count_occurrences(haystack, needle) do
    haystack
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end

  defp collect_text_contents(%Rendro.Section{content: content}) do
    Enum.flat_map(content, &collect_content_from_block/1)
  end

  defp collect_content_from_block(%Rendro.Block{content: %Rendro.Text{content: c}}), do: [c]

  defp collect_content_from_block(%Rendro.Block{content: %Rendro.Table{} = table}) do
    collect_content_from_table(table)
  end

  defp collect_content_from_block(_other), do: []

  defp collect_content_from_table(table) do
    header = if table.header, do: collect_content_from_row(table.header), else: []
    rows = Enum.flat_map(table.rows, &collect_content_from_row/1)
    header ++ rows
  end

  defp collect_content_from_row(%Rendro.Row{cells: cells}),
    do: Enum.flat_map(cells, &collect_content_from_cell/1)

  defp collect_content_from_row(cells) when is_list(cells),
    do: Enum.flat_map(cells, &collect_content_from_cell/1)

  defp collect_content_from_cell(%Rendro.Cell{content: content}),
    do: collect_content_from_cell_value(content)

  defp collect_content_from_cell(content), do: collect_content_from_cell_value(content)

  defp collect_content_from_cell_value(%Rendro.Block{} = block),
    do: collect_content_from_block(block)

  defp collect_content_from_cell_value(%Rendro.Text{content: c}), do: [c]
  defp collect_content_from_cell_value(str) when is_binary(str), do: [str]
  defp collect_content_from_cell_value(_other), do: []

  defp sizes_for_region(sizes_by_region, region) do
    sizes_by_region
    |> Enum.filter(fn {r, _sizes} -> r == region end)
    |> Enum.flat_map(fn {_r, sizes} -> sizes end)
  end

  defp collect_text_sizes(%Rendro.Section{content: content}) do
    Enum.flat_map(content, &collect_from_block/1)
  end

  defp collect_from_block(%Rendro.Block{content: %Rendro.Text{size: size}}), do: [size]

  defp collect_from_block(%Rendro.Block{content: %Rendro.Table{} = table}) do
    collect_from_table(table)
  end

  defp collect_from_block(_other), do: []

  defp collect_from_table(table) do
    header_sizes = if table.header, do: collect_from_row(table.header), else: []
    row_sizes = Enum.flat_map(table.rows, &collect_from_row/1)
    header_sizes ++ row_sizes
  end

  defp collect_from_row(%Rendro.Row{cells: cells}), do: Enum.flat_map(cells, &collect_from_cell/1)
  defp collect_from_row(cells) when is_list(cells), do: Enum.flat_map(cells, &collect_from_cell/1)

  defp collect_from_cell(%Rendro.Cell{content: content}), do: collect_from_cell_content(content)
  defp collect_from_cell(content), do: collect_from_cell_content(content)

  defp collect_from_cell_content(%Rendro.Block{} = block), do: collect_from_block(block)
  defp collect_from_cell_content(%Rendro.Text{size: size}), do: [size]
  defp collect_from_cell_content(_other), do: []

  defp themed_table_and_document(data, theme) do
    doc = Payslip.document(data, theme: theme)
    body = Enum.find(doc.sections, &(&1.region == :body))
    table = Enum.find(body.content, &is_struct(&1.content, Rendro.Table)).content
    {table, doc}
  end

  defp amount_cells(%Rendro.Table{rows: [row | _], columns: columns}) do
    [
      {"$4,200.00", Enum.at(row, 1), fixed_width(columns, 1)},
      {"$25,200.00", Enum.at(row, 2), fixed_width(columns, 2)},
      {"$4,550.00", Enum.at(row, 5), fixed_width(columns, 5)}
    ]
  end

  defp fixed_width(columns, index) do
    {:fixed, width} = Enum.at(columns, index)
    width
  end

  defp one_line?(cell, width, doc) do
    {_header_height, [row_height]} =
      Rendro.measure_rows([[cell]], width, doc, columns: [{:fixed, width}])

    row_height < 20
  end

  defp sequential_document(data) do
    Payslip.document(data,
      theme: Rendro.Theme.preset(:swiss, accent: "#2C6BED"),
      presentation_profile: %{ledger_layout: :sequential_measured}
    )
  end

  defp tables_for_heading(body, heading) do
    Enum.filter(body.content, fn block ->
      is_struct(block.content, Rendro.Table) and
        collect_content_from_row(block.content.header) == [heading, "Current", "YTD"]
    end)
  end

  defp rows_for_heading(body, heading) do
    body
    |> tables_for_heading(heading)
    |> Enum.flat_map(& &1.content.rows)
  end

  defp boundary_earnings(count) do
    for index <- 1..count do
      %{
        description: "Boundary earning #{index}",
        amount: Decimal.new("100.00"),
        ytd: Decimal.new("1200.00")
      }
    end
  end
end
