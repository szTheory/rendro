defmodule Rendro.Recipes.ReceiptByteIdentityTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Receipt

  # Frozen on the un-seamed HEAD render of `receipt.ex`, BEFORE the S1
  # `palette/1` color seam landed. This is the PLUMB-03 byte-identity contract:
  # seaming the primary text runs (title, customer, date, minor total, dominant
  # total) to `colors.ink` (retrofit default `{0,0,0}`, which renders
  # identically to no color arg) MUST keep the toy-call render hashing to this
  # exact value. Changing this hash is a defect, not a golden refresh, unless a
  # human explicitly re-authorizes a new baseline.
  @toy_golden_sha256 "8a2560100a4d6f15927b3fa32b33249cdb7c7faf62b4040fdd882c35123d6a4b"

  # Fixed, deterministic toy data with the required :title, :date, :customer,
  # :lines keys plus :totals so the render exercises the seamed header text
  # (title/customer/date) and both totals runs (minor subtotal + dominant
  # total). No :merchant (optional) so geometry stays on the frozen path.
  defp toy_data do
    %{
      title: "Payment Receipt",
      date: ~D[2026-05-29],
      customer: %{name: "Acme Corp"},
      lines: [
        %{description: "Widget A", amount: Decimal.new("29.99")},
        %{description: "Widget B", amount: Decimal.new("49.99")}
      ],
      totals: %{subtotal: Decimal.new("79.98"), total: Decimal.new("79.98")}
    }
  end

  describe "PLUMB-03 baseline: toy-call byte identity" do
    test "two deterministic renders are byte-identical" do
      doc = Receipt.document(toy_data())
      assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end

    test "fresh render sha256 matches the frozen pre-seam retrofit baseline" do
      doc = Receipt.document(toy_data())
      assert {:ok, pdf} = Rendro.render(doc, deterministic: true)

      sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)

      assert sha256 == @toy_golden_sha256,
             "Receipt toy-call render drifted from the frozen S1 retrofit " <>
               "baseline. The palette/1 seam must be byte-identical on the " <>
               "no-theme path. If this drift is an intentional, human-approved " <>
               "change, recompute @toy_golden_sha256 and update it deliberately."
    end
  end

  describe "PLUMB-02: page_template/1 opts whitelist" do
    test "page_template/1 does not raise KeyError on :palette / :theme opts" do
      assert %Rendro.PageTemplate{} = Receipt.page_template(palette: %{})
      # 121-03: page_template/1 now resolves palette(opts) directly (to gate
      # the shared :background region), so :theme must be a value
      # Rendro.Theme.resolve/1 actually accepts — an empty map resolves to
      # the theme defaults and still exercises the whitelist (:theme is
      # filtered from the struct!/2 keys and reaches palette/1 unharmed).
      assert %Rendro.PageTemplate{} = Receipt.page_template(theme: %{})
    end
  end
end
