defmodule Rendro.Recipes.InvoiceTypographyTest do
  @moduledoc """
  TYPE-02 raise-path proof for the Invoice typography seam (Phase 122).

  An Invoice built with a `theme:` whose `typography.fonts.<role>` names an
  UNREGISTERED font atom must fail loud with the exact typed
  `{:unknown_text_font, _}` tuple from `Build.run/1` — never a silent Helvetica
  substitute. This is the "fail loud, never substitute" mitigation for
  threat T-122-01 (an unregistered font role in `theme.typography.fonts`).

  `Rendro.Theme.resolve/1` does NOT validate font atoms (only colors), so the
  bad atom survives resolution and surfaces at build/validate time via the
  shipped `font_registry.ex -> build.ex` path (mirrors `font_test.exs:90`).

  Invoice reads `fonts.mono` (title / totals) and `fonts.body` (prose/labels);
  it does not read `fonts.heading`. The raise-path is therefore proven on
  `fonts.mono` (the title "INVOICE #<id>", always rendered) — the plan's
  behavior explicitly permits `.mono`/`.body` in place of `.heading`.
  """
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Build
  alias Rendro.Recipes.Invoice

  defp sample_data do
    %{
      id: "INV-TYPO-01",
      date: ~D[2026-04-30],
      items: [
        %{name: "Widget X", qty: 2, price: 100}
      ]
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
      doc = Invoice.document(sample_data(), theme: theme)

      assert {:error, {:unknown_text_font, :no_such_font}} = Build.run(doc)
    end

    test "an unregistered fonts.body atom surfaces {:unknown_text_font, :no_such_font} from Build.run/1" do
      theme = theme_with_bad_font(:body, :no_such_font)
      doc = Invoice.document(sample_data(), theme: theme)

      assert {:error, {:unknown_text_font, :no_such_font}} = Build.run(doc)
    end

    test "the default theme (all :default fonts, registered) builds cleanly — no false raise" do
      doc = Invoice.document(sample_data(), theme: Rendro.Theme.default())

      assert {:ok, _built} = Build.run(doc)
    end
  end
end
