defmodule Rendro.DocsContract.ReadmeDoctestTest do
  use ExUnit.Case, async: true

  import ExUnit.DocTest

  alias Rendro.Test.DocsContract

  doctest_file("README.md")

  test "README compile/eval fences are explicit and compile cleanly" do
    fences = DocsContract.verified_fences("README.md")

    assert Enum.map(fences, & &1.id) == [
             "readme-flow-compile",
             "readme-flow-breaks-compile",
             "readme-table-compile",
             "readme-fixed-compile",
             "readme-inspector-compile",
             "readme-policies-compile"
           ]

    Enum.each(fences, fn %{code: code} ->
      refute String.contains?(code, "...")
      refute String.contains?(code, "%{...}")
      Code.compile_string(code, "README.md")
    end)
  end
end
