defmodule Rendro.Recipes.StatementTypographyTest do
  @moduledoc """
  TYPE-02 raise-path proof for the Statement typography seam (Phase 122-02) —
  the REPRESENTATIVE raise-path test for the wave-2 expansion group
  (Statement/Receipt/Payslip). The `theme.typography.fonts.<role>` resolution
  path is identical across every recipe, so proving it on Statement covers the
  group (threat T-122-02).

  A Statement built with a `theme:` whose `typography.fonts.<role>` names an
  UNREGISTERED font atom must fail loud with the exact typed
  `{:unknown_text_font, _}` tuple from `Build.run/1` — never a silent Helvetica
  substitute.

  `Rendro.Theme.resolve/1` does NOT validate font atoms (only colors), so the
  bad atom survives resolution and surfaces at build/validate time via the
  shipped `font_registry.ex -> build.ex` path (mirrors `font_test.exs:90`).

  Statement reads `fonts.heading` (account name, always rendered), `fonts.mono`
  (closing-balance amount), and `fonts.body` (prose/labels/table cells). The
  raise-path is proven on `fonts.heading` (the account name is always present)
  and `fonts.mono` (the closing balance).
  """
  use ExUnit.Case, async: true

  alias Rendro.Pipeline.Build
  alias Rendro.Recipes.Statement
  alias Rendro.Theme.Presets

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
    test "a curated body role composes for metric measurement but still requires the explicit bridge" do
      theme = Rendro.Theme.preset(:swiss, accent: "#2C6BED")
      document = Statement.document(sample_data(), theme: theme)

      assert {:error, {:unknown_text_font, :rendro_preset_grotesque}} = Build.run(document)

      assert {:ok, _} =
               document
               |> Presets.register_fonts(:swiss)
               |> Build.run()
    end

    test "an unregistered fonts.heading atom surfaces {:unknown_text_font, :no_such_font} from Build.run/1" do
      theme = theme_with_bad_font(:heading, :no_such_font)
      doc = Statement.document(sample_data(), theme: theme)

      assert {:error, {:unknown_text_font, :no_such_font}} = Build.run(doc)
    end

    test "an unregistered fonts.mono atom surfaces {:unknown_text_font, :no_such_font} from Build.run/1" do
      theme = theme_with_bad_font(:mono, :no_such_font)
      doc = Statement.document(sample_data(), theme: theme)

      assert {:error, {:unknown_text_font, :no_such_font}} = Build.run(doc)
    end

    test "the default theme (all :default fonts, registered) builds cleanly — no false raise" do
      doc = Statement.document(sample_data(), theme: Rendro.Theme.default())

      assert {:ok, _built} = Build.run(doc)
    end
  end
end
