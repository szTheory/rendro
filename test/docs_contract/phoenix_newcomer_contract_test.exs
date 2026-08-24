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

  test "clean-room evidence preserves all failed attempts and retains no sensitive run state" do
    evidence = File.read!("priv/journey_evidence/phoenix_clean_room_1.3.4.json")
    transcript = File.read!("priv/journey_evidence/phoenix_clean_room_1.3.4.md")

    assert evidence =~ "\"version\":\"1.3.4\""
    assert evidence =~ "\"outcome\":\"failure\""
    assert transcript =~ "phx_new_source_missing"
    assert transcript =~ "advisory failure"
    assert File.exists?("priv/journey_evidence/phoenix_clean_room_1.3.4_failed_attempt.json")
    assert File.exists?("priv/journey_evidence/phoenix_clean_room_1.3.4_failed_attempt.md")

    assert File.exists?(
             "priv/journey_evidence/phoenix_clean_room_1.3.4_second_failed_attempt.json"
           )

    assert File.exists?("priv/journey_evidence/phoenix_clean_room_1.3.4_second_failed_attempt.md")

    assert File.exists?(
             "priv/journey_evidence/phoenix_clean_room_1.3.4_third_failed_attempt.json"
           )

    assert File.exists?("priv/journey_evidence/phoenix_clean_room_1.3.4_third_failed_attempt.md")

    assert File.exists?(
             "priv/journey_evidence/phoenix_clean_room_1.3.4_fourth_failed_attempt.json"
           )

    assert File.exists?("priv/journey_evidence/phoenix_clean_room_1.3.4_fourth_failed_attempt.md")

    refute evidence =~ ~r/HEX_API_KEY|HOME|\/Users\/|\"pid\"|\"port\"|%PDF-/
    refute transcript =~ ~r/HEX_API_KEY|HOME|\/Users\/|\bPID\b|%PDF-/
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
