defmodule Rendro.TableByteIdentityTest do
  use ExUnit.Case, async: true

  # Pre-`cell_align` baseline. Frozen on pristine (unedited) `table.ex` /
  # `cell.ex` before any Phase-115 `lib/` edit landed — this is the
  # byte-identity contract INV-05 requires: a fresh render of a table with
  # NO `cell_align` option set anywhere must keep hashing to this exact
  # value, proving Plan 03's additive `cell_align: :right` primitive is a
  # true no-op on the default (left) path. Changing this hash is a defect,
  # not a golden-file refresh, unless a human explicitly re-authorizes a
  # new baseline.
  @table_golden_sha256 "aad749043644fe7bc405516fbc2831e16ab6a4379f77883a600f729d85348bb7"

  # Representative multi-column, multi-row table: a mix of {:share, 1} and
  # {:fixed, N} columns, 3 rows, header — and crucially NO `cell_align` key
  # set anywhere, so this exercises the default-alignment path exactly.
  defp golden_table do
    rows = [
      ["Widget", "2", "$10.00"],
      ["Gadget", "1", "$25.50"],
      ["Gizmo", "3", "$5.25"]
    ]

    Rendro.table(rows,
      header: ["Item", "Qty", "Price"],
      columns: [{:share, 1}, {:fixed, 60}, {:fixed, 80}]
    )
  end

  defp golden_doc do
    Rendro.flow([Rendro.block(golden_table())])
  end

  describe "INV-05 baseline: no-cell_align table byte identity" do
    test "two deterministic renders are byte-identical" do
      doc = golden_doc()
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "fresh render sha256 matches the frozen pre-cell_align golden" do
      doc = golden_doc()
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)

      assert sha256 == @table_golden_sha256,
             "no-cell_align table render drifted from the frozen INV-05 baseline. " <>
               "If this drift is an intentional, human-approved change, " <>
               "recompute @table_golden_sha256 and update it deliberately."
    end
  end
end
