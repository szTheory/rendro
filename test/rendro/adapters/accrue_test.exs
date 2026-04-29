defmodule Rendro.Adapters.AccrueTest do
  use ExUnit.Case, async: true

  alias Rendro.Adapters.Accrue, as: Adapter

  defp sample_invoice do
    %Accrue.Invoice{
      id: "INV-001",
      customer: %{name: "Acme", email: "billing@acme.test"},
      line_items: [
        %Accrue.LineItem{description: "Widget", quantity: 2, unit_amount: 1500, subtotal: 3000},
        %Accrue.LineItem{description: "Gizmo", quantity: 1, unit_amount: 500, subtotal: 500}
      ],
      total: 3500,
      issued_at: ~D[2026-04-26]
    }
  end

  describe "recipe/1 happy path" do
    test "returns {:ok, %Rendro.Document{}} for a valid Accrue.Invoice" do
      assert {:ok, %Rendro.Document{} = doc} = Adapter.recipe(sample_invoice())
      assert is_list(doc.content) and doc.content != []
    end

    test "produces a document containing the invoice id, line item descriptions, and explicit table columns" do
      {:ok, doc} = Adapter.recipe(sample_invoice())
      flat = inspect(doc, limit: :infinity, printable_limit: :infinity)
      assert flat =~ "INV-001"
      assert flat =~ "Widget"
      assert flat =~ "Gizmo"
      assert flat =~ "columns: [share: 1, fixed: 40, fixed: 60, fixed: 60]"
    end

    test "the resulting document renders to a valid PDF" do
      {:ok, doc} = Adapter.recipe(sample_invoice())
      assert {:ok, binary} = Rendro.render(doc)
      assert <<"%PDF-", _rest::binary>> = binary
    end
  end

  describe "optional-gating proof" do
    test "module is loaded after AdapterReloader.recompile/0 (Code.ensure_loaded? gate evaluated true)" do
      assert Code.ensure_loaded?(Rendro.Adapters.Accrue)
      assert function_exported?(Rendro.Adapters.Accrue, :recipe, 1)
    end
  end

  describe "recipe/1 input validation" do
    test "returns {:error, {:invalid_invoice, _}} for non-Invoice input" do
      assert {:error, {:invalid_invoice, :not_an_invoice}} = Adapter.recipe(:not_an_invoice)
    end
  end
end
