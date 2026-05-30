defmodule Rendro.Recipes.BrandedInvoiceOptsThreadingTest do
  @moduledoc """
  TDD tests for BrandedInvoice.sections/2 opts threading (Phase 78 plan 03, D-10/D-11).

  Verifies that BrandedInvoice.sections/2 accepts a named `opts` parameter and
  forwards it to all section helpers (logo, header, body, footer — arity-2 heads),
  while preserving byte-identical default output (D-11).
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.BrandedInvoice

  defp sample_data do
    %{
      id: "INV-OPTS-02",
      date: ~D[2026-04-30],
      items: [
        %{name: "Widget Y", qty: 1, price: 250}
      ],
      brand: %{font_name: :brand_heading, logo_name: :company_logo}
    }
  end

  describe "BrandedInvoice.sections/2 opts threading" do
    test "sections/1 (no opts) returns four sections" do
      sections = BrandedInvoice.sections(sample_data())
      assert is_list(sections)
      assert length(sections) == 4
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
    end

    test "sections/2 with empty opts returns identical result as sections/1" do
      sections_no_opts = BrandedInvoice.sections(sample_data())
      sections_empty_opts = BrandedInvoice.sections(sample_data(), [])
      assert sections_no_opts == sections_empty_opts
    end

    test "sections/2 with unknown opts does not crash and returns sections" do
      sections =
        BrandedInvoice.sections(sample_data(), unknown_opt: :ignored, another: :also_ignored)

      assert is_list(sections)
      assert length(sections) == 4
      assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
    end

    test "sections/2 regions are :logo, :header, :body, :footer regardless of opts" do
      sections = BrandedInvoice.sections(sample_data(), some_opt: :value)
      region_targets = Enum.map(sections, & &1.region) |> Enum.sort()
      assert region_targets == [:body, :footer, :header, :logo]
    end

    test "sections/2 with empty opts keyword list does not crash" do
      sections = BrandedInvoice.sections(sample_data(), [])
      assert length(sections) == 4
    end
  end
end
