defmodule Rendro.Recipes.PaginationTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Pagination

  describe "label_resolver/2 (D-18)" do
    test "opts[:labels] wins over default_labels" do
      opts = [labels: %{net_pay: "NETTO"}]
      default_labels = %{net_pay: "Net Pay"}

      resolver = Pagination.label_resolver(opts, default_labels)

      assert resolver.(:net_pay) == "NETTO"
    end

    test "default_labels wins when opts[:labels] is absent" do
      resolver = Pagination.label_resolver([], %{net_pay: "Net Pay"})

      assert resolver.(:net_pay) == "Net Pay"
    end

    test "falls through to Rendro.Format.label/1 when both opts and default_labels are empty" do
      resolver = Pagination.label_resolver([], %{})

      assert resolver.(:opening_balance) == "Opening balance"
    end

    test "arity-1 call (default_labels defaulted) still compiles and resolves identically" do
      resolver = Pagination.label_resolver(labels: %{net_pay: "NETTO"})

      assert resolver.(:net_pay) == "NETTO"

      resolver2 = Pagination.label_resolver([])
      assert resolver2.(:opening_balance) == "Opening balance"
    end
  end

  describe "validate_labels!/2 and validate_formatters!/2 (D-19)" do
    test "validate_labels!/2 returns :ok when :labels key is absent" do
      assert Pagination.validate_labels!([], "Rendro.Recipes.Payslip.document/2") == :ok
    end

    test "validate_labels!/2 returns :ok for a well-formed :labels map" do
      opts = [labels: %{net_pay: "Net Pay"}]

      assert Pagination.validate_labels!(opts, "Rendro.Recipes.Payslip.document/2") == :ok
    end

    test "validate_labels!/2 raises an instructive ArgumentError when :labels is not a map" do
      opts = [labels: "not a map"]

      error =
        assert_raise ArgumentError, fn ->
          Pagination.validate_labels!(opts, "Rendro.Recipes.Payslip.document/2")
        end

      assert error.message =~ "What:"
      assert error.message =~ "Where:"
      assert error.message =~ "Why:"
      assert error.message =~ "Next:"
      assert error.message =~ "String"
    end

    test "validate_labels!/2 raises when a :labels value is an empty string" do
      opts = [labels: %{net_pay: ""}]

      assert_raise ArgumentError, fn ->
        Pagination.validate_labels!(opts, "Rendro.Recipes.Payslip.document/2")
      end
    end

    test "validate_formatters!/2 returns :ok when :formatters key is absent" do
      assert Pagination.validate_formatters!([], "Rendro.Recipes.Payslip.document/2") == :ok
    end

    test "validate_formatters!/2 returns :ok for a well-formed :formatters keyword list" do
      opts = [formatters: [amount: &Rendro.Format.money/1]]

      assert Pagination.validate_formatters!(opts, "Rendro.Recipes.Payslip.document/2") == :ok
    end

    test "validate_formatters!/2 raises when :formatters is not a keyword list" do
      opts = [formatters: %{amount: & &1}]

      error =
        assert_raise ArgumentError, fn ->
          Pagination.validate_formatters!(opts, "Rendro.Recipes.Payslip.document/2")
        end

      assert error.message =~ "What:"
      assert error.message =~ "Where:"
      assert error.message =~ "Why:"
      assert error.message =~ "Next:"
    end

    test "validate_formatters!/2 raises when a formatter function has the wrong arity" do
      opts = [formatters: [amount: fn _a, _b -> "x" end]]

      assert_raise ArgumentError, fn ->
        Pagination.validate_formatters!(opts, "Rendro.Recipes.Payslip.document/2")
      end
    end
  end
end
