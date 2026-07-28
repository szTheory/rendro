defmodule Rendro.Recipes.BrandedInvoiceByteIdentityTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.BrandedInvoice

  # NET-NEW baseline (PLUMB-01/03 blind spot): BrandedInvoice had NO existing
  # golden and is absent from the edge_matrix, so nothing pre-existing guarded
  # its byte output. This sha256 is frozen from the un-seamed HEAD render,
  # BEFORE the S1 `palette/1` color seam landed — the seam is byte-identical by
  # construction (default `ink {0,0,0}` renders identically to no color arg),
  # so the post-seam render hashes to this same value. Changing this hash is a
  # defect, not a golden refresh, unless a human explicitly re-authorizes a new
  # baseline.
  @toy_golden_sha256 "6b20ecc8dba82b88cb4f8216ca49bba052838e6cb3e0dd0c7ba8142139f6a9ad"

  # Fixed, deterministic toy data — required :id, :date, :items, :brand keys.
  defp toy_data do
    %{
      id: "INV-001",
      date: ~D[2026-01-15],
      items: [
        %{name: "Widget", qty: 2, price: 10},
        %{name: "Gadget", qty: 1, price: 25}
      ],
      brand: %{font_name: :brand_heading, logo_name: :company_logo}
    }
  end

  describe "PLUMB-03 baseline: toy-call byte identity (net-new golden)" do
    test "two deterministic renders are byte-identical" do
      doc = BrandedInvoice.document(toy_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "fresh render sha256 matches the frozen net-new baseline" do
      doc = BrandedInvoice.document(toy_data())
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)

      assert sha256 == @toy_golden_sha256,
             "BrandedInvoice toy-call render drifted from the frozen net-new S1 " <>
               "retrofit baseline. The palette/1 seam must be byte-identical on " <>
               "the no-theme path. If this drift is an intentional, human-approved " <>
               "change, recompute @toy_golden_sha256 and update it deliberately."
    end
  end

  describe "PLUMB-02: page_template/1 opts whitelist" do
    test "page_template/1 does not raise KeyError on :palette / :theme opts" do
      assert %Rendro.PageTemplate{} = BrandedInvoice.page_template(palette: %{})
      # 121-03: page_template/1 now resolves palette(opts) directly (to gate
      # the shared :background region), so :theme must be a value
      # Rendro.Theme.resolve/1 actually accepts — an empty map resolves to
      # the theme defaults and still exercises the whitelist (:theme is
      # filtered from the struct!/2 keys and reaches palette/1 unharmed).
      assert %Rendro.PageTemplate{} = BrandedInvoice.page_template(theme: %{})
    end
  end
end
