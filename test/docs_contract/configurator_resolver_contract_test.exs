defmodule Rendro.DocsContract.ConfiguratorResolverContractTest do
  use ExUnit.Case, async: true

  @javascript "assets/rendro/configurator/configurator.js"

  defp resolve(cells, state) do
    Enum.find_value(cells, fn cell ->
      if Map.take(cell, ~w(family preset accent mode)) == state, do: {:exact, cell}
    end) ||
      Enum.find_value(cells, :none, fn cell ->
        if Map.take(cell, ~w(family preset mode)) == Map.take(state, ~w(family preset mode)) and
             cell["accent"] != state["accent"],
           do: {:representative, cell}
      end)
  end

  test "synthetic resolver prefers exact then first same family preset and mode representative" do
    state = %{
      "family" => "invoice",
      "preset" => "swiss",
      "accent" => "#2C6BED",
      "mode" => "light"
    }

    cells = [
      Map.put(state, "accent", "#1F4FB8"),
      Map.put(state, "accent", "#0E7C76"),
      state
    ]

    assert {:exact, ^state} = resolve(cells, state)

    [first, second | _] = cells
    assert {:representative, ^first} = resolve([first, second], state)
  end

  test "synthetic resolver never crosses family preset or mode and has an explicit none state" do
    state = %{
      "family" => "invoice",
      "preset" => "swiss",
      "accent" => "#2C6BED",
      "mode" => "light"
    }

    cells = [
      %{"family" => "receipt", "preset" => "swiss", "accent" => "#1F4FB8", "mode" => "light"},
      %{"family" => "invoice", "preset" => "humanist", "accent" => "#1F4FB8", "mode" => "light"},
      %{"family" => "invoice", "preset" => "swiss", "accent" => "#1F4FB8", "mode" => "dark"}
    ]

    assert resolve(cells, state) == :none
  end

  test "controller uses strict atomic query state and serializes only four canonical keys" do
    javascript = File.read!(@javascript)

    assert javascript =~ "params.getAll(key)"
    assert javascript =~ "state.family.length === 1"
    assert javascript =~ "state.preset.length === 1"
    assert javascript =~ "state.accent.length === 1"
    assert javascript =~ "state.mode.length === 1"
    assert javascript =~ "return valid ?"
    assert javascript =~ " : FALLBACK"
    assert javascript =~ "new URLSearchParams()"
    assert javascript =~ "[\"family\", \"preset\", \"accent\", \"mode\"].forEach"
    assert javascript =~ "history.replaceState"
    assert javascript =~ "catalogUsesClosedEnums"
    assert javascript =~ "firstSelectableState"
    refute javascript =~ "preview="
  end

  test "selected committed index string is both visible and copied without browser source generation" do
    javascript = File.read!(@javascript)
    index = JSON.decode!(File.read!("assets/rendro/configurator/index.json"))

    assert length(index["records"]) == 504
    assert javascript =~ "const recordFor"
    assert javascript =~ "snippetCode.textContent = record.snippet"
    assert javascript =~ "const visibleCodeText = snippetCode.textContent"
    assert javascript =~ "await navigator.clipboard.writeText(visibleCodeText)"
    assert javascript =~ "Snippet copied"
    assert javascript =~ "2000"
    assert javascript =~ "Select the visible source and try again."
    refute javascript =~ "Rendro.Theme.preset("
    refute javascript =~ "String.raw"
  end

  test "controller distinguishes exact representative and absent evidence without changing code selection" do
    javascript = File.read!(@javascript)

    assert javascript =~ "kind: \"exact\""
    assert javascript =~ "kind: \"representative\""
    assert javascript =~ "kind: \"none\""
    assert javascript =~ "cell.accent !== state.accent"

    assert javascript =~
             "No catalog preview matches this selection. Copied code is valid, but this catalog has no equivalent pre-rendered example."

    assert javascript =~
             "Preview: catalog example uses ${resolution.cell.accent}. Copied code uses your exact accent ${state.accent}."

    assert javascript =~ "boundary_disclosure"
  end
end
