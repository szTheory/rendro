defmodule Rendro.DocsContract.BrandingContractTest do
  use ExUnit.Case, async: false

  alias Rendro.Test.DocsContract

  test "guides/branding.md ships exactly the four expected verified fence IDs in order" do
    fences = DocsContract.verified_fences("guides/branding.md")

    assert Enum.map(fences, & &1.id) == [
             "branding-register-assets",
             "branding-tiered-document",
             "branding-tiered-template",
             "branding-missing-asset-diagnostic"
           ]
  end

  test "every guides/branding.md fence body is evaluable and free of skeleton placeholders" do
    fences = DocsContract.verified_fences("guides/branding.md")
    assert length(fences) == 4

    Enum.each(fences, fn %{code: code} ->
      refute String.contains?(code, "...")
      refute String.contains?(code, "%{...}")
      DocsContract.evaluate!(code, "guides/branding.md")
    end)
  end
end
