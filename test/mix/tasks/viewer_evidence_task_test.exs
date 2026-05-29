defmodule Mix.Tasks.Rendro.ViewerEvidenceTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Rendro.ViewerEvidence

  @moduletag :subcommands

  describe "list/1" do
    test "returns :ok against the production matrix" do
      {messages, result} = capture_shell_messages(fn -> ViewerEvidence.run(["list"]) end)

      assert result == :ok
      output = Enum.join(messages, "\n")
      assert output =~ "Viewer evidence: 26 cells"
      assert output =~ "supported=6, unverified=20, explicit_deferral=0"
      refute output =~ "legacy: missing evidence pointer"
    end

    test "--json emits summary and cells on stdout only" do
      json_output =
        capture_io(fn ->
          assert :ok = ViewerEvidence.run(["list", "--json"])
        end)

      assert {:ok, payload} = JSON.decode(json_output)
      assert payload["summary"]["total"] == 26
      assert payload["summary"]["supported"] == 6
      assert payload["summary"]["unverified"] == 20
      assert payload["summary"]["explicit_deferral"] == 0
      assert length(payload["cells"]) == 26

      assert Enum.all?(payload["cells"], fn cell ->
               Map.has_key?(cell, "surface") and
                 Map.has_key?(cell, "viewer") and
                 Map.has_key?(cell, "status")
             end)
    end
  end

  describe "missing/1" do
    test "exits 1 when unverified cells exist" do
      {messages, exit_reason} =
        capture_shell_messages(fn ->
          catch_exit(ViewerEvidence.run(["missing"]))
        end)

      assert exit_reason == {:shutdown, 1}
      output = Enum.join(messages, "\n")
      assert output =~ "20 unverified viewer cell(s)"
    end

    test "--json filters to unverified cells only" do
      json_output =
        capture_io(fn ->
          catch_exit(ViewerEvidence.run(["missing", "--json"]))
        end)

      assert {:ok, payload} = JSON.decode(json_output)
      assert payload["summary"]["total"] == 20
      assert payload["summary"]["unverified"] == 20
      assert payload["summary"]["supported"] == 0
      assert Enum.all?(payload["cells"], &(&1["status"] == "unverified"))
    end
  end

  describe "validate/1" do
    test "returns :ok on the unchanged production matrix" do
      {messages, result} = capture_shell_messages(fn -> ViewerEvidence.run(["validate"]) end)

      assert result == :ok
      output = Enum.join(messages, "\n")
      assert output =~ "Viewer evidence validation passed"
      refute output =~ "missing promotion-complete"
    end
  end

  describe "module contract" do
    test "moduledoc mentions mix docs.contract" do
      {:docs_v1, _, _, _, module_doc, _, _} = Code.fetch_docs(ViewerEvidence)

      doc =
        case module_doc do
          %{"en" => text} -> text
          doc when is_list(doc) -> Enum.map_join(doc, "", fn {:doc, _line, text} -> text end)
        end

      assert doc =~ "mix docs.contract"
      assert doc =~ "guides/viewer_evidence.md"
    end

    test "mix ci alias does not register rendro.viewer_evidence" do
      mix_source = File.read!("mix.exs")
      refute mix_source =~ "rendro.viewer_evidence"
    end
  end

  defp capture_shell_messages(fun) do
    original_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    result =
      try do
        fun.()
      after
        Mix.shell(original_shell)
      end

    {flush_shell_messages([]), result}
  end

  defp flush_shell_messages(messages) do
    receive do
      {:mix_shell, _level, payload} ->
        flush_shell_messages([IO.iodata_to_binary(payload) | messages])
    after
      0 -> Enum.reverse(messages)
    end
  end
end
