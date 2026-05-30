defmodule Rendro.Recipes.InvoiceOptsThreadingTest do
  @moduledoc """
  TDD tests for Invoice.sections/2 opts threading (Phase 78 plan 03, D-10/D-11).

  Verifies that Invoice.sections/2 accepts a named `opts` parameter and
  forwards it to all section helpers (arity-2 heads), while preserving
  byte-identical default output (D-11).
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Invoice

  defp sample_data do
    %{
      id: "INV-OPTS-01",
      date: ~D[2026-04-30],
      items: [
        %{name: "Widget X", qty: 2, price: 100}
      ]
    }
  end

  describe "Invoice.sections/2 opts threading" do
    test "sections/1 (no opts) returns a list of sections" do
      sections = Invoice.sections(sample_data())
      assert is_list(sections)
      assert length(sections) == 3
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
    end

    test "sections/2 with empty opts returns identical result as sections/1" do
      sections_no_opts = Invoice.sections(sample_data())
      sections_empty_opts = Invoice.sections(sample_data(), [])
      assert sections_no_opts == sections_empty_opts
    end

    test "sections/2 with unknown opts does not crash and returns sections" do
      sections = Invoice.sections(sample_data(), unknown_opt: :ignored, another: :also_ignored)
      assert is_list(sections)
      assert length(sections) == 3
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
    end

    test "sections/2 regions are :header, :body, :footer regardless of opts" do
      sections = Invoice.sections(sample_data(), some_opt: :value)
      region_targets = Enum.map(sections, & &1.region)
      assert :header in region_targets
      assert :body in region_targets
      assert :footer in region_targets
    end

    test "sections/2 with empty opts keyword list does not crash" do
      sections = Invoice.sections(sample_data(), [])
      assert length(sections) == 3
    end
  end
end
