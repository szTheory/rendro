defmodule Rendro.DocsContract.RecipesContractTest do
  use ExUnit.Case, async: false

  alias Rendro.Test.DocsContract

  for guide <- ["guides/recipes.md", "guides/page_primitive.md"] do
    @guide guide

    test "every #{guide} fence body is evaluable and free of skeleton placeholders" do
      fences = DocsContract.verified_fences(@guide)
      assert length(fences) > 0

      Enum.each(fences, fn %{code: code} ->
        refute String.contains?(code, "...")
        refute String.contains?(code, "%{...}")
        DocsContract.evaluate!(code, @guide)
      end)
    end

    test "every #{guide} fence has a valid docs-contract id" do
      fences = DocsContract.verified_fences(@guide)
      assert length(fences) > 0

      for %{id: id} <- fences do
        assert is_binary(id) and id != ""
      end
    end
  end

  test "guides/recipes.md ships the expected verified fence IDs" do
    fences = DocsContract.verified_fences("guides/recipes.md")
    fence_ids = Enum.map(fences, & &1.id)

    assert "recipes-statement-document" in fence_ids
    assert "recipes-statement-escape-hatch" in fence_ids
    assert "recipes-receipt-document" in fence_ids
    assert "recipes-receipt-escape-hatch" in fence_ids
    assert "recipes-certificate-document" in fence_ids
    assert "recipes-certificate-escape-hatch" in fence_ids
  end

  test "guides/page_primitive.md ships the expected verified fence IDs" do
    fences = DocsContract.verified_fences("guides/page_primitive.md")
    fence_ids = Enum.map(fences, & &1.id)

    assert "page-primitive-basic" in fence_ids
    assert "page-primitive-suppress" in fence_ids
  end
end
