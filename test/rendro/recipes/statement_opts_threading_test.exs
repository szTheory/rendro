defmodule Rendro.Recipes.StatementOptsThreadingTest do
  @moduledoc """
  Phase 120 Plan 03 (swap): proves the `:theme` opt threads through Statement's
  `palette/1` seam — recolors the closing-balance band, respects `:palette`
  override precedence (D-01), and leaves the no-theme path byte-identical
  (PLUMB-03).
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Statement

  defp sample_data do
    %{
      period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
      account: %{name: "Acme Corp"},
      opening_balance: Decimal.new("100.00"),
      lines: [
        %{date: ~D[2026-05-05], description: "Payment", amount: Decimal.new("-25.00")},
        %{date: ~D[2026-05-20], description: "Invoice", amount: Decimal.new("50.00")}
      ]
    }
  end

  describe "Statement :theme threading (PLUMB-02)" do
    test ":theme threads through page_template/1 without KeyError" do
      assert %Rendro.PageTemplate{} = Statement.page_template(theme: Rendro.Theme.default())
    end

    test "a themed render differs from the no-theme render" do
      data = sample_data()
      refute Statement.sections(data) == Statement.sections(data, theme: Rendro.Theme.default())
    end

    test ":palette override wins over :theme (D-01)" do
      data = sample_data()
      themed = Statement.sections(data, theme: Rendro.Theme.default())

      overridden =
        Statement.sections(data, theme: Rendro.Theme.default(), palette: %{surface: {200, 0, 0}})

      refute themed == overridden
    end
  end

  describe "Statement no-theme byte-identity (PLUMB-03)" do
    test "sections(data) equals sections(data, [])" do
      data = sample_data()
      assert Statement.sections(data) == Statement.sections(data, [])
    end

    test "default palette (no override) renders byte-identically" do
      data = sample_data()
      assert Statement.sections(data) == Statement.sections(data, palette: %{})
    end
  end

  describe "typography(opts) seam (TYPE-01/02/03)" do
    test "no-op: sections(data) equals sections(data, typography: %{})" do
      data = sample_data()
      assert Statement.sections(data) == Statement.sections(data, typography: %{})
    end

    test "a :typography override changes the output (live seam)" do
      data = sample_data()

      # `leading` is threaded onto every %Text{} block, so overriding it is
      # guaranteed to change the sections — proving the seam is live, not inert.
      refute Statement.sections(data) == Statement.sections(data, typography: %{leading: 2.0})
    end
  end
end
