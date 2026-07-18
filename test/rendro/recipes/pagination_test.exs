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
end
