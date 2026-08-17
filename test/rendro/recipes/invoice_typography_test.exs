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
  alias Rendro.TestSupport.FontFixture

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

  describe "TYPE-02 raise-path (unregistered font role → actionable error, never silent Helvetica)" do
    test "an unregistered fonts.mono atom is rejected before table measurement" do
      theme = theme_with_bad_font(:mono, :no_such_font)

      assert_raise ArgumentError, ~r/:font_registry.*no_such_font/s, fn ->
        Invoice.document(sample_data(), theme: theme)
      end
    end

    test "an unregistered fonts.body atom is rejected before table measurement" do
      theme = theme_with_bad_font(:body, :no_such_font)

      assert_raise ArgumentError, ~r/:font_registry.*no_such_font/s, fn ->
        Invoice.document(sample_data(), theme: theme)
      end
    end

    test "the default theme (all :default fonts, registered) builds cleanly — no false raise" do
      doc = Invoice.document(sample_data(), theme: Rendro.Theme.default())

      assert {:ok, _built} = Build.run(doc)
    end
  end

  describe "Phase 126 semantic typography contract" do
    test "materializes title/body roles, scale, and leading by semantic content" do
      theme = Rendro.Theme.default()
      sections = Invoice.sections(sample_data(), theme: theme)

      assert %Rendro.Text{size: title_size, font: title_font, line_height: title_leading} =
               find_text(sections, "INVOICE #INV-TYPO-01")

      assert title_size == theme.typography.scale.title
      assert title_font == theme.typography.fonts.mono
      assert title_leading == theme.typography.leading

      assert %Rendro.Text{size: body_size, font: body_font, line_height: body_leading} =
               find_text(sections, "Date: 2026-04-30")

      assert body_size == theme.typography.scale.body
      assert body_font == theme.typography.fonts.body
      assert body_leading == theme.typography.leading
    end

    test "a complete nested typography override wins without erasing retained values" do
      theme = Rendro.Theme.default()
      override = %{theme.typography | leading: 1.7, scale: %{theme.typography.scale | title: 31}}

      assert %Rendro.Text{size: 31, line_height: 1.7} =
               Invoice.sections(sample_data(), theme: theme, typography: override)
               |> find_text("INVOICE #INV-TYPO-01")

      assert override.scale.body == theme.typography.scale.body
      assert override.fonts.body == theme.typography.fonts.body
    end

    test "measures and renders a registered custom body font with the same registry" do
      %{bytes: bytes} = FontFixture.supported_font()

      registry =
        Rendro.FontRegistry.new()
        |> Rendro.FontRegistry.register_embedded(:invoice_body, {:binary, bytes})

      theme = Rendro.Theme.default()
      typography = %{theme.typography | fonts: %{theme.typography.fonts | body: :invoice_body}}
      custom_theme = %{theme | typography: typography}

      document = Invoice.document(sample_data(), theme: custom_theme, font_registry: registry)

      assert Map.has_key?(document.font_registry.fonts, :invoice_body)
      assert {:ok, _built} = Build.run(document)
    end

    test "rejects an unregistered custom body font before table measurement" do
      theme = theme_with_bad_font(:body, :unregistered_invoice_body)

      assert_raise ArgumentError, ~r/:font_registry.*unregistered_invoice_body/s, fn ->
        Invoice.document(sample_data(), theme: theme)
      end
    end
  end

  defp find_text(sections, content), do: Enum.find(texts(sections), &(&1.content == content))
  defp texts(value) when is_list(value), do: Enum.flat_map(value, &texts/1)
  defp texts(%Rendro.Section{content: content}), do: texts(content)
  defp texts(%Rendro.Block{content: content}), do: texts(content)
  defp texts(%Rendro.Table{rows: rows, header: header}), do: texts([rows, header])
  defp texts(%Rendro.Text{} = text), do: [text]
  defp texts(_), do: []
end
