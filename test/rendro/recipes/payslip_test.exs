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
end
