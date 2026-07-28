defmodule Rendro.Recipes.ThemeModeBackgroundGoldenTest do
  @moduledoc """
  121-01 D-08: proves the `:background` full-page fill is the FIRST content
  op on page 1 and on every page of a forced-overflow render, painted with
  the resolved `theme.colors.background`. The light/no-theme path emits ZERO
  background ops (byte-identical to v2.10, PLUMB-03).

  Raw-binary regex idiom mirrors `test/rendro/path_test.exs` (content streams
  are uncompressed under `deterministic: true`, Pitfall 5) and
  `test/rendro/flow_test.exs` (`/Type /Page` page-count scan +
  per-page-repeated-text occurrence counting).
  """
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Statement

  @dark_theme Rendro.Theme.dark(Rendro.Theme.default())
  @dark_bg @dark_theme.colors.background
  @fill_op Rendro.Color.rg(@dark_bg)

  # Fixed, deterministic toy data — mirrors statement_byte_identity_test.exs's
  # toy_data/0 (same required-keys-only shape).
  defp toy_data do
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

  # `n` alternating-sign transaction lines — mirrors statement_test.exs's
  # fixture_data/2 shape, sized generously (well past the recipe's ~30-row
  # capacity per page) to force a multi-page (forced-overflow) render.
  defp overflow_data(n) do
    lines =
      for i <- 1..n//1 do
        amount = if rem(i, 2) == 1, do: Decimal.new("100.00"), else: Decimal.new("-50.00")

        %{
          date: Date.add(~D[2026-05-01], i - 1),
          description: "Transaction #{i}",
          amount: amount
        }
      end

    %{
      period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
      account: %{name: "Acme Corp"},
      opening_balance: Decimal.new("1000.00"),
      lines: lines
    }
  end

  describe "(a) light/no-theme: zero background ops, byte-identical" do
    test "two deterministic renders are byte-identical and contain no dark-bg fill op" do
      doc = Statement.document(toy_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
      refute pdf1 =~ @fill_op
    end
  end

  describe "(b) dark page 1: background fill is the first content op" do
    test "the fill op's first occurrence precedes the first BT text token" do
      doc = Statement.document(toy_data(), theme: @dark_theme)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      assert pdf =~ @fill_op

      {fill_offset, _} = :binary.match(pdf, @fill_op)
      {bt_offset, _} = :binary.match(pdf, "BT")

      assert fill_offset < bt_offset,
             "expected the :background fill op (offset #{fill_offset}) to precede " <>
               "the first BT text op (offset #{bt_offset}) — full-page fill must " <>
               "paint first (bottom of the paint stack)"
    end
  end

  describe "(c) forced-overflow: fill op present on EVERY page" do
    test "fill op occurrence count equals the rendered page count" do
      doc = Statement.document(overflow_data(60), theme: @dark_theme)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      page_count = length(Regex.scan(~r"/Type\s*/Page\b", pdf))
      assert page_count > 1, "fixture must force a multi-page (forced-overflow) render"

      fill_count = length(:binary.matches(pdf, @fill_op))

      assert fill_count == page_count,
             "expected the :background fill op once per page (#{page_count} pages), " <>
               "got #{fill_count} occurrences — every page (incl. paginate-generated " <>
               "overflow pages) must repaint the region"
    end
  end

  describe "(d) determinism/composition + blessed dark golden" do
    test "two dark renders are byte-identical and match the blessed golden" do
      doc = Statement.document(toy_data(), theme: @dark_theme)
      pdf = Rendro.Test.Golden.assert_deterministic!(doc)
      Rendro.Test.Golden.assert_or_bless({:statement, :dark}, pdf)
    end
  end
end
