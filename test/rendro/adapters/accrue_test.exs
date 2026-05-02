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
      assert {:ok, %Rendro.Document{}} = Adapter.recipe(sample_invoice())
    end

    test "document page_templates contains a template with named regions :header, :body, :footer" do
      {:ok, doc} = Adapter.recipe(sample_invoice())
      assert doc.page_templates != []
      template = hd(doc.page_templates)
      region_names = Enum.map(template.regions, & &1.name)
      assert :header in region_names
      assert :body in region_names
      assert :footer in region_names
    end

    test "document sections assigns content to each of the three regions (one section per region)" do
      {:ok, doc} = Adapter.recipe(sample_invoice())
      assert length(doc.sections) == 3
      region_targets = Enum.map(doc.sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "document does NOT carry legacy header or footer content (doc.header and doc.footer are empty)" do
      {:ok, doc} = Adapter.recipe(sample_invoice())
      assert doc.header == []
      assert doc.footer == []
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

  describe "source-level contract" do
    test "accrue.ex does not reference header: or footer: as Rendro.flow/2 kwargs" do
      source = File.read!("lib/rendro/adapters/accrue.ex")

      # Ensure no legacy 'header: <var>' or 'footer: <var>' keyword args are passed to Rendro.flow/2
      refute source =~ ~r/Rendro\.flow\([^)]*header:/
      refute source =~ ~r/Rendro\.flow\([^)]*footer:/
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
