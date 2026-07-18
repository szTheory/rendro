defmodule Rendro.TableCellAlignTest do
  use ExUnit.Case, async: true

  # Same golden hash as `test/rendro/table_byte_identity_test.exs` — this
  # file only ADDS positive + differential coverage; it never edits the
  # frozen INV-05 no-op golden.
  @table_golden_sha256 "aad749043644fe7bc405516fbc2831e16ab6a4379f77883a600f729d85348bb7"

  # Representative multi-column, multi-row table: a mix of {:share, 1} and
  # {:fixed, N} columns, 3 rows, header. Mirrors
  # `table_byte_identity_test.exs`'s `golden_table/0` exactly so the no-op
  # case below is directly comparable to the frozen baseline.
  defp golden_table(opts \\ []) do
    rows = [
      ["Widget", "2", "$10.00"],
      ["Gadget", "1", "$25.50"],
      ["Gizmo", "3", "$5.25"]
    ]

    Rendro.table(
      rows,
      Keyword.merge(
        [header: ["Item", "Qty", "Price"], columns: [{:share, 1}, {:fixed, 60}, {:fixed, 80}]],
        opts
      )
    )
  end

  defp render_sha256(doc) do
    assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
    {:crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower), pdf}
  end

  describe "INV-05: no-op when cell_align is unset" do
    test "matches the plan-01 frozen baseline exactly (byte-identical no-op)" do
      doc = Rendro.flow([Rendro.block(golden_table())])
      {sha256, _pdf} = render_sha256(doc)

      assert sha256 == @table_golden_sha256,
             "a table with no cell_align option must still hash to the frozen " <>
               "pre-cell_align baseline — the additive primitive must be a true no-op."
    end
  end

  describe "INV-05: cell_align: :right right-aligns the target column" do
    test "right-aligned render differs from the same table with no cell_align" do
      doc_left = Rendro.flow([Rendro.block(golden_table())])
      doc_right = Rendro.flow([Rendro.block(golden_table(cell_align: %{2 => :right}))])

      {_sha_left, pdf_left} = render_sha256(doc_left)
      {_sha_right, pdf_right} = render_sha256(doc_right)

      refute pdf_left == pdf_right,
             "cell_align: :right on the money column must produce different bytes " <>
               "than the same table with no cell_align (offset must actually apply)."
    end

    test "right-aligned render is deterministic across two renders" do
      doc_right = Rendro.flow([Rendro.block(golden_table(cell_align: %{2 => :right}))])

      assert {:ok, pdf1} = Rendro.render(doc_right, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc_right, deterministic: true)
      assert pdf1 == pdf2
    end

    test "a per-cell cell_align: :right override behaves the same as the column-level option" do
      # The table-level `cell_align: %{2 => :right}` option applies to every
      # cell in that column INCLUDING the header, so the per-cell equivalent
      # must set `cell_align: :right` on both the header cell and the data
      # cell to be a fair apples-to-apples comparison.
      rows_with_override = [
        [
          "Widget",
          "2",
          %Rendro.Cell{content: "$10.00", cell_align: :right}
        ]
      ]

      table_override =
        Rendro.table(rows_with_override,
          header: ["Item", "Qty", %Rendro.Cell{content: "Price", cell_align: :right}],
          columns: [{:share, 1}, {:fixed, 60}, {:fixed, 80}]
        )

      table_column_level =
        Rendro.table(
          [["Widget", "2", "$10.00"]],
          header: ["Item", "Qty", "Price"],
          columns: [{:share, 1}, {:fixed, 60}, {:fixed, 80}],
          cell_align: %{2 => :right}
        )

      doc_override = Rendro.flow([Rendro.block(table_override)])
      doc_column_level = Rendro.flow([Rendro.block(table_column_level)])

      assert {:ok, pdf_override} = Rendro.render(doc_override, deterministic: true)
      assert {:ok, pdf_column_level} = Rendro.render(doc_column_level, deterministic: true)

      assert pdf_override == pdf_column_level,
             "a per-cell cell_align: :right override must place content identically to " <>
               "the equivalent column-level cell_align option."
    end
  end
end
