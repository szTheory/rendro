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
end
