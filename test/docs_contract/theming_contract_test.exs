defmodule Rendro.DocsContract.ThemingContractTest do
  use ExUnit.Case, async: true

  alias Rendro.Test.DocsContract

  test "guides/theming.md ships exactly the three expected verified fence IDs in order" do
    fences = DocsContract.verified_fences("guides/theming.md")

    assert Enum.map(fences, & &1.id) == [
             "theming-accent-only",
             "theming-accent-contrast-both-ways",
             "theming-brand-orthogonal"
           ]
  end

  test "every guides/theming.md fence body is evaluable and free of skeleton placeholders" do
    fences = DocsContract.verified_fences("guides/theming.md")
    assert length(fences) == 3

    Enum.each(fences, fn %{code: code} ->
      refute String.contains?(code, "...")
      refute String.contains?(code, "%{...}")
      DocsContract.evaluate!(code, "guides/theming.md")
    end)
  end
end
