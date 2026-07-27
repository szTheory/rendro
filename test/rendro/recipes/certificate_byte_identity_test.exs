defmodule Rendro.Recipes.CertificateByteIdentityTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Certificate

  # Frozen on the un-seamed HEAD render of `certificate.ex`, BEFORE the S1
  # `palette/1` color seam landed. This is the PLUMB-03 byte-identity contract:
  # moving the frame color default behind `colors.rule` (retrofit default equal
  # to the old NON-BLACK `{34, 34, 34}` literal — the D-02 stress case) MUST
  # keep both the no-border and border toy renders hashing to these exact
  # values. Changing a hash is a defect, not a golden refresh, unless a human
  # explicitly re-authorizes a new baseline.
  @toy_golden_sha256 "7d3ac77c26d3e98c9303a9c84bce0a67ee010ea9492275efb2a9e825624829f5"

  # Border-frame render exercises the {34,34,34} frame default path (stress case).
  @toy_border_golden_sha256 "b96e9e498bb1f1e160d0ec19037ce0d0562be3552c7822c7f89154c4c6288717"

  defp toy_data do
    %{title: "Certificate of Completion", recipient: "Jane Smith", date: ~D[2026-05-29]}
  end

  describe "PLUMB-03 baseline: toy-call byte identity" do
    test "two deterministic renders are byte-identical" do
      doc = Certificate.document(toy_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "fresh no-border render sha256 matches the frozen pre-seam retrofit baseline" do
      doc = Certificate.document(toy_data())
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)

      assert sha256 == @toy_golden_sha256,
             "Certificate no-border render drifted from the frozen S1 retrofit " <>
               "baseline. The palette/1 seam must be byte-identical on the " <>
               "no-theme path. If this drift is intentional and human-approved, " <>
               "recompute @toy_golden_sha256 and update it deliberately."
    end

    test "border: true render exercises the {34,34,34} frame and stays byte-identical" do
      doc = Certificate.document(toy_data(), border: true)
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)

      assert sha256 == @toy_border_golden_sha256,
             "Certificate border-frame render drifted from the frozen S1 " <>
               "retrofit baseline. The {34,34,34} frame default (colors.rule) " <>
               "must be byte-identical on the no-theme path. If this drift is " <>
               "intentional and human-approved, recompute " <>
               "@toy_border_golden_sha256 and update it deliberately."
    end
  end
end
