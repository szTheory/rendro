defmodule Rendro.RecipesFacadeDriftTest do
  use ExUnit.Case, async: true

  # Single source of truth for recipe facade entries (D-07).
  # Adding a recipe requires a deliberate edit here and in lib/rendro/recipes.ex.
  @recipes [
    {:invoice, Rendro.Recipes.Invoice},
    {:branded_invoice, Rendro.Recipes.BrandedInvoice},
    {:statement, Rendro.Recipes.Statement},
    {:receipt, Rendro.Recipes.Receipt},
    {:certificate, Rendro.Recipes.Certificate}
  ]

  # --- Assertion 1: Reachability (D-08 item 1) ---

  test "each recipe is reachable as name/1 and name/2 on Rendro.Recipes" do
    for {name, _module} <- @recipes do
      assert function_exported?(Rendro.Recipes, name, 1),
             "Expected Rendro.Recipes.#{name}/1 to be exported"

      assert function_exported?(Rendro.Recipes, name, 2),
             "Expected Rendro.Recipes.#{name}/2 to be exported"
    end
  end

  # --- Assertion 2: No extra or missing functions (D-08 item 2) ---

  test "Rendro.Recipes exposes exactly the expected 10 functions" do
    expected =
      for {name, _} <- @recipes, arity <- [1, 2] do
        {name, arity}
      end
      |> MapSet.new()

    actual = MapSet.new(Rendro.Recipes.__info__(:functions))

    assert actual == expected,
           """
           Rendro.Recipes function set does not match expected 10-function set.

           In actual but NOT expected (unexpected extras):
             #{MapSet.difference(actual, expected) |> Enum.sort() |> Enum.map_join(", ", fn {f, a} -> "#{f}/#{a}" end)}

           In expected but NOT actual (missing from facade):
             #{MapSet.difference(expected, actual) |> Enum.sort() |> Enum.map_join(", ", fn {f, a} -> "#{f}/#{a}" end)}
           """
  end

  # --- Assertion 3: Struct byte-identity (D-08 item 3) ---

  test "Rendro.Recipes delegates produce struct-identical result to recipe modules" do
    for {name, module} <- @recipes do
      data = fixture_for(name)
      facade_result = apply(Rendro.Recipes, name, [data])
      direct_result = module.document(data)

      assert facade_result == direct_result,
             "Rendro.Recipes.#{name}/1 struct does not match #{inspect(module)}.document/1"
    end
  end

  # --- Assertion 4: Auto-discovery orphan sweep (D-09) ---

  test "no orphan recipe modules missing facade wrapper" do
    {:ok, all_modules} = :application.get_key(:rendro, :modules)

    recipe_modules_with_document2 =
      all_modules
      |> Enum.filter(fn mod ->
        mod_str = Atom.to_string(mod)

        String.starts_with?(mod_str, "Elixir.Rendro.Recipes.") and
          function_exported?(mod, :document, 2) and
          mod != Rendro.Recipes.Pagination
      end)
      |> MapSet.new()

    expected_modules = MapSet.new(Enum.map(@recipes, fn {_, mod} -> mod end))

    assert recipe_modules_with_document2 == expected_modules,
           """
           Orphan recipe modules found (have document/2 but no facade wrapper):
             #{MapSet.difference(recipe_modules_with_document2, expected_modules) |> Enum.sort() |> Enum.join(", ")}

           Missing from discovered set but listed in @recipes:
             #{MapSet.difference(expected_modules, recipe_modules_with_document2) |> Enum.sort() |> Enum.join(", ")}
           """
  end

  # --- Facade opts-threading regression (D-10) ---

  describe "facade opts-threading regression" do
    test "statement/2 with sentinel opts produces struct-identical result to Statement.document/2" do
      data = fixture_for(:statement)
      opts = [labels: %{balance: "Saldo"}]
      assert Rendro.Recipes.statement(data, opts) == Rendro.Recipes.Statement.document(data, opts)
    end

    test "statement/2 with sentinel opts changes result vs no-opts" do
      data = fixture_for(:statement)
      opts = [labels: %{balance: "Saldo"}]
      assert Rendro.Recipes.statement(data, opts) != Rendro.Recipes.statement(data)
    end

    test "certificate/2 with border: true produces struct-identical result to Certificate.document/2" do
      data = fixture_for(:certificate)
      opts = [border: true]
      assert Rendro.Recipes.certificate(data, opts) == Rendro.Recipes.Certificate.document(data, opts)
    end

    test "receipt/1 with empty opts returns same as receipt/2 with []" do
      data = fixture_for(:receipt)
      assert Rendro.Recipes.receipt(data, []) == Rendro.Recipes.receipt(data)
    end

    test "invoice/2 with empty opts is struct-identical to Invoice.document/2 with []" do
      data = fixture_for(:invoice)
      assert Rendro.Recipes.invoice(data, []) == Rendro.Recipes.Invoice.document(data, [])
    end
  end

  # --- Fixture helpers (inline — not importable from other test files, Pitfall 5) ---

  defp fixture_for(:invoice) do
    %{id: "INV-001", date: ~D[2026-01-01], items: []}
  end

  defp fixture_for(:branded_invoice) do
    %{
      id: "INV-DRIFT-01",
      date: ~D[2026-01-01],
      items: [],
      brand: %{font_name: :brand_heading, logo_name: :company_logo}
    }
  end

  defp fixture_for(:statement) do
    %{
      period: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
      account: %{name: "Drift Test Co"},
      opening_balance: Decimal.new("0.00"),
      lines: []
    }
  end

  defp fixture_for(:receipt) do
    %{
      title: "Receipt",
      date: ~D[2026-01-01],
      customer: %{name: "Drift Test Co"},
      lines: [],
      totals: %{subtotal: Decimal.new("0.00"), total: Decimal.new("0.00")}
    }
  end

  defp fixture_for(:certificate) do
    %{
      title: "Certificate of Completion",
      recipient: "Drift Test",
      body: "Completed.",
      date: ~D[2026-01-01],
      seal_line: "Signed"
    }
  end
end
