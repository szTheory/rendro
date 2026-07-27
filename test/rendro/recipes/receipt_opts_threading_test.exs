defmodule Rendro.Recipes.ReceiptOptsThreadingTest do
  @moduledoc """
  Phase 120 Plan 03 (swap): proves the `:theme` opt threads through Receipt's
  `palette/1` seam — a themed `ink` recolors the primary text, `:palette` wins
  over `:theme` (D-01), `:theme` reaches `page_template/1` without a KeyError
  (guarding the Plan 02 whitelist fix), and the no-theme path stays
  byte-identical (PLUMB-03).
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Receipt

  defp sample_data do
    %{
      title: "Payment Receipt",
      date: ~D[2026-05-29],
      customer: %{name: "Acme Corp"},
      lines: [
        %{description: "Widget A", amount: Decimal.new("29.99")},
        %{description: "Widget B", amount: Decimal.new("49.99")}
      ],
      totals: %{subtotal: Decimal.new("79.98"), total: Decimal.new("79.98")}
    }
  end

  describe "Receipt :theme threading (PLUMB-02)" do
    test ":theme threads through page_template/1 without KeyError" do
      assert %Rendro.PageTemplate{} = Receipt.page_template(theme: Rendro.Theme.default())
    end

    test "a themed render differs from the no-theme render" do
      data = sample_data()
      refute Receipt.sections(data) == Receipt.sections(data, theme: Rendro.Theme.default())
    end

    test ":palette override wins over :theme (D-01)" do
      data = sample_data()
      themed = Receipt.sections(data, theme: Rendro.Theme.default())

      overridden =
        Receipt.sections(data, theme: Rendro.Theme.default(), palette: %{ink: {200, 0, 0}})

      refute themed == overridden
    end
  end

  describe "Receipt no-theme byte-identity (PLUMB-03)" do
    test "sections(data) equals sections(data, [])" do
      data = sample_data()
      assert Receipt.sections(data) == Receipt.sections(data, [])
    end

    test "default palette (no override) renders byte-identically" do
      data = sample_data()
      assert Receipt.sections(data) == Receipt.sections(data, palette: %{})
    end
  end
end
