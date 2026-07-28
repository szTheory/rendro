defmodule Rendro.Recipes.TicketOptsThreadingTest do
  @moduledoc """
  Phase 120 Plan 04 (swap): proves the `:theme` opt threads through Ticket's
  `palette/1` seam — recolors the seamed text (ink/muted roles), respects
  `:palette` override precedence (D-01), and leaves the no-theme path
  byte-identical (PLUMB-03).
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Ticket

  defp sample_data do
    %{
      issuer: %{name: "Aurora Live"},
      title: "Indie Night: The Lumen Set",
      placement: [
        %{label: "Section", value: "GA"},
        %{label: "Row", value: "H"},
        %{label: "Seat", value: "24"}
      ],
      code: %{reference: "AUR-88213-GA"}
    }
  end

  describe "Ticket :theme threading (PLUMB-02 swap)" do
    test ":theme threads through page_template/1 without KeyError" do
      assert %Rendro.PageTemplate{} = Ticket.page_template(theme: Rendro.Theme.default())
    end

    test "a themed render differs from the no-theme render" do
      data = sample_data()
      refute Ticket.sections(data) == Ticket.sections(data, theme: Rendro.Theme.default())
    end

    test ":palette override wins over :theme (D-01)" do
      data = sample_data()
      themed = Ticket.sections(data, theme: Rendro.Theme.default())

      overridden =
        Ticket.sections(data, theme: Rendro.Theme.default(), palette: %{ink: {200, 0, 0}})

      refute themed == overridden
    end
  end

  describe "Ticket no-theme byte-identity (PLUMB-03)" do
    test "sections(data) equals sections(data, [])" do
      data = sample_data()
      assert Ticket.sections(data) == Ticket.sections(data, [])
    end

    test "default palette (no override) renders byte-identically" do
      data = sample_data()
      assert Ticket.sections(data) == Ticket.sections(data, palette: %{})
    end
  end

  describe "typography(opts) seam (TYPE-01/02/03)" do
    test "no-op: sections(data) equals sections(data, typography: %{})" do
      data = sample_data()
      assert Ticket.sections(data) == Ticket.sections(data, typography: %{})
    end

    test "a :typography override changes the output (live seam)" do
      data = sample_data()

      # `leading` is threaded onto every seamed %Text{} block (including the two
      # exempted mono micro-size runs), so overriding it is guaranteed to change
      # the sections — proving the seam is live.
      refute Ticket.sections(data) == Ticket.sections(data, typography: %{leading: 2.0})
    end
  end
end
