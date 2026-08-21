defmodule Rendro.DocsContract.PhoenixNewcomerContractTest do
  use ExUnit.Case, async: true

  test "README owns the ordered public Phoenix newcomer route without copying the formatter snippet" do
    readme = File.read!("README.md")

    for label <- ["Install", "Select", "Customize", "Serve", "Verify"] do
      assert readme =~ "### #{label}"
    end

    assert ordered?(readme, [
             "### Install",
             "### Select",
             "### Customize",
             "### Serve",
             "### Verify"
           ])

    assert readme =~ "{:rendro, \"~> 1.3\"}"
    assert readme =~ "https://hexdocs.pm/rendro"
    assert readme =~ "guides/presets.md"
    assert readme =~ "assets/rendro/configurator/index.html"
    assert readme =~ "examples/phoenix_example/README.md"
    assert readme =~ "Invoice / Swiss / `#2C6BED` / light"
    assert readme =~ "formatter-owned"
    assert readme =~ "broader runnable reference, not clean-room authority"
    refute readme =~ "Rendro.Theme.preset(:swiss"
  end

  defp ordered?(text, values) do
    values
    |> Enum.map(&:binary.match(text, &1))
    |> Enum.reduce_while(-1, fn
      {index, _length}, previous when index > previous -> {:cont, index}
      _, _previous -> {:halt, :error}
    end)
    |> Kernel.!=(:error)
  end
end
