defmodule Rendro.Recipes.InvoiceByteIdentityTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Invoice

  # Pre-Phase-115 baseline. Frozen on pristine (unedited) `invoice.ex` before
  # any Phase-115 `lib/` edit landed — this is the byte-identity contract
  # INV-01 requires: a fresh toy-call render must keep hashing to this exact
  # value after every downstream Invoice-anatomy change in this phase.
  # Changing this hash is a defect, not a golden-file refresh, unless a
  # human explicitly re-authorizes a new baseline.
  @toy_golden_sha256 "c3625eb53a87805475a346876b4b927ba6186b794b5e20d0eb37daec0d6c8407"

  # Fixed, deterministic toy data map — ONLY the required :id, :date, :items
  # keys, no anatomy fields, so it exercises the frozen toy-call path exactly.
  defp toy_data do
    %{
      id: "INV-001",
      date: ~D[2026-01-15],
      items: [
        %{name: "Widget", qty: 2, price: 10.00},
        %{name: "Gadget", qty: 1, price: 25.50}
      ]
    }
  end

  describe "INV-01 baseline: toy-call byte identity" do
    test "two deterministic renders are byte-identical" do
      doc = Invoice.document(toy_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "fresh render sha256 matches the frozen pre-Phase-115 golden" do
      doc = Invoice.document(toy_data())
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)

      assert sha256 == @toy_golden_sha256,
             "toy-call render drifted from the frozen INV-01 baseline. " <>
               "If this drift is an intentional, human-approved change, " <>
               "recompute @toy_golden_sha256 and update it deliberately."
    end
  end
end
