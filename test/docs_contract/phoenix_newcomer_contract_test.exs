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
    assert evidence =~ "\"outcome\":\"success\""
    assert transcript =~ "advisory success"
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

    assert File.exists?(
             "priv/journey_evidence/phoenix_clean_room_1.3.4_fifth_failed_attempt.json"
           )

    assert File.exists?("priv/journey_evidence/phoenix_clean_room_1.3.4_fifth_failed_attempt.md")

    refute evidence =~ ~r/HEX_API_KEY|HOME|\/Users\/|\"pid\"|\"port\"|%PDF-/
    refute transcript =~ ~r/HEX_API_KEY|HOME|\/Users\/|\bPID\b|%PDF-/
  end

  test "retained clean-room result proves the exact public PDF journey with dual HTTP facts" do
    transcript = File.read!("priv/journey_evidence/phoenix_clean_room_1.3.4.md")

    evidence =
      "priv/journey_evidence/phoenix_clean_room_1.3.4.json"
      |> File.read!()
      |> Jason.decode!()

    assert evidence["advisory"] == true
    assert evidence["outcome"] == "success"
    assert evidence["version"] == "1.3.4"
    assert evidence["candidate_sha"] == "f03c78bab54efe1cd1596d51cf3f28193232e2a3"
    assert evidence["source_audits"] == "public_hex_exact_1.3.4"
    assert evidence["cleanup"] == "workspace_removed"
    assert transcript =~ "does not verify process-tree state"
    refute transcript =~ "process state was removed"

    assert evidence["commands"] == [
             "mix archive.install hex phx_new 1.8.5 --force",
             "mix phx.new --no-install --no-ecto --no-html --no-assets --no-mailer",
             "mix deps.get",
             "mix test",
             "mix compile",
             "loopback endpoint start",
             "loopback HTTP probe"
           ]

    expected_response = %{
      "status" => 200,
      "content_type" => "application/pdf",
      "filename" => "invoice.pdf",
      "nonempty" => true,
      "pdf_magic" => true
    }

    assert evidence["conn_case"] == expected_response
    assert evidence["loopback"] == expected_response
  end

  test "published validation evidence identities match the retained journey files" do
    validation =
      File.read!(
        ".planning/milestones/v2.13-phases/131-adoption-snapshot-phoenix-newcomer-proof/131-VALIDATION.md"
      )

    assert validation =~
             "Replacement journey JSON SHA-256:\n  `#{sha256("priv/journey_evidence/phoenix_clean_room_1.3.4.json")}`"

    assert validation =~
             "Replacement journey transcript SHA-256:\n  `#{sha256("priv/journey_evidence/phoenix_clean_room_1.3.4.md")}`"
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

  defp sha256(path) do
    :crypto.hash(:sha256, File.read!(path))
    |> Base.encode16(case: :lower)
  end
end
