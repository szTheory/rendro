defmodule Rendro.Recipes.StatementByteIdentityTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Statement

  # Frozen on the un-seamed HEAD render of `statement.ex`, BEFORE the S1
  # `palette/1` color seam landed. This is the PLUMB-03 byte-identity contract:
  # moving the `closing_backdrop` band fill/stroke behind `colors.surface` /
  # `colors.rule` (retrofit defaults equal to the old `{245,245,245}` /
  # `{0,0,0}` literals) MUST keep the toy-call render hashing to this exact
  # value. Changing this hash is a defect, not a golden refresh, unless a human
  # explicitly re-authorizes a new baseline.
  @toy_golden_sha256 "87f6a2c8a4d3f6cc70be53d93d7768b902ac6160ca6d4ab702f3052ac7493a4c"

  # Fixed, deterministic toy data with only the required :period, :account,
  # :opening_balance, :lines keys.
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

  describe "PLUMB-03 baseline: toy-call byte identity" do
    test "two deterministic renders are byte-identical" do
      doc = Statement.document(toy_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "fresh render sha256 matches the frozen pre-seam retrofit baseline" do
      doc = Statement.document(toy_data())
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)

      assert sha256 == @toy_golden_sha256,
             "Statement toy-call render drifted from the frozen S1 retrofit " <>
               "baseline. The palette/1 seam must be byte-identical on the " <>
               "no-theme path. If this drift is an intentional, human-approved " <>
               "change, recompute @toy_golden_sha256 and update it deliberately."
    end
  end
end
