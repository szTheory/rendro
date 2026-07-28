defmodule Rendro.Recipes.TicketTypographyTest do
  @moduledoc """
  TYPE-02 raise-path proof for the Ticket typography seam (Phase 122-03) — the
  REPRESENTATIVE raise-path test for the wave-2 expansion group
  (BrandedInvoice/Certificate/Ticket). The `theme.typography.fonts.<role>`
  resolution path is identical across every recipe, so proving it on Ticket
  covers the group (threat T-122-03).

  A Ticket built with a `theme:` whose `typography.fonts.<role>` names an
  UNREGISTERED font atom must fail loud with the exact typed
  `{:unknown_text_font, _}` tuple from `Build.run/1` — never a silent Helvetica
  substitute.

  `Rendro.Theme.resolve/1` does NOT validate font atoms (only colors), so the
  bad atom survives resolution and surfaces at build/validate time via the
  shipped `font_registry.ex -> build.ex` path (mirrors `font_test.exs:90`).

  Ticket reads `fonts.mono` (the reference code — the D-01 display anchor,
  plus the two exempted micro-sizes), `fonts.heading` (the ticket title), and
  `fonts.body` (issuer / subtitle / placement / terms). The raise-path is proven
  on `fonts.mono` (the reference code always renders) and `fonts.heading` (the
  title always renders).
  """
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Build
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

  # Rendro.Theme.default() with a single font role replaced by an unregistered
  # atom. Only the named `role` is corrupted; every other typography value is
  # the shipped default so the failure is isolated to the bad font.
  defp theme_with_bad_font(role, bad_atom) do
    theme = Rendro.Theme.default()
    fonts = %{theme.typography.fonts | role => bad_atom}
    typography = %{theme.typography | fonts: fonts}
    %{theme | typography: typography}
  end

  describe "TYPE-02 raise-path (unregistered font role → typed error, never silent Helvetica)" do
    test "an unregistered fonts.mono atom surfaces {:unknown_text_font, :no_such_font} from Build.run/1" do
      theme = theme_with_bad_font(:mono, :no_such_font)
      doc = Ticket.document(sample_data(), theme: theme)

      assert {:error, {:unknown_text_font, :no_such_font}} = Build.run(doc)
    end

    test "an unregistered fonts.heading atom surfaces {:unknown_text_font, :no_such_font} from Build.run/1" do
      theme = theme_with_bad_font(:heading, :no_such_font)
      doc = Ticket.document(sample_data(), theme: theme)

      assert {:error, {:unknown_text_font, :no_such_font}} = Build.run(doc)
    end

    test "the default theme (all :default fonts, registered) builds cleanly — no false raise" do
      doc = Ticket.document(sample_data(), theme: Rendro.Theme.default())

      assert {:ok, _built} = Build.run(doc)
    end
  end
end
