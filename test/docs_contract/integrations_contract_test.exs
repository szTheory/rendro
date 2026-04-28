defmodule Rendro.DocsContract.IntegrationsContractTest do
  use ExUnit.Case, async: false

  alias Rendro.Test.DocsContract
  alias Rendro.Test.Mocks

  setup do
    Mocks.reset_threadline()
    :ok
  end

  test "curated integration guide fences stay executable" do
    fences = DocsContract.verified_fences("guides/integrations.md")

    assert Enum.map(fences, & &1.id) == [
             "integrations-threadline-happy-path",
             "integrations-mailglass-swoosh",
             "integrations-mailglass-message",
             "integrations-accrue-verification"
           ]

    Enum.each(fences, fn %{id: id, code: code} ->
      refute String.contains?(code, "...")
      refute String.contains?(code, "%{...}")

      case id do
        _ ->
          DocsContract.evaluate!(code, "guides/integrations.md")
      end
    end)
  end
end
