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
      assert output =~ "Viewer evidence: 30 cells"
      assert output =~ "supported=17, unverified=0, explicit_deferral=13"
      refute output =~ "legacy: missing evidence pointer"
    end

    test "--json emits summary and cells on stdout only" do
      json_output =
        capture_io(fn ->
          assert :ok = ViewerEvidence.run(["list", "--json"])
        end)

      assert {:ok, payload} = JSON.decode(json_output)
      assert payload["summary"]["total"] == 30
      assert payload["summary"]["supported"] == 17
      assert payload["summary"]["unverified"] == 0
      assert payload["summary"]["explicit_deferral"] == 13
      assert length(payload["cells"]) == 30

      assert Enum.all?(payload["cells"], fn cell ->
               Map.has_key?(cell, "surface") and
                 Map.has_key?(cell, "viewer") and
                 Map.has_key?(cell, "status")
             end)
    end
  end

  describe "missing/1" do
    test "exits 0 when no unverified cells remain after Phase 71 closure" do
      {messages, result} = capture_shell_messages(fn -> ViewerEvidence.run(["missing"]) end)

      assert result == :ok
      output = Enum.join(messages, "\n")
      assert output =~ "No unverified cells"
    end

    test "--json reports empty unverified backlog" do
      json_output =
        capture_io(fn ->
          assert :ok = ViewerEvidence.run(["missing", "--json"])
        end)

      assert {:ok, payload} = JSON.decode(json_output)
      assert payload["summary"]["total"] == 0
      assert payload["summary"]["unverified"] == 0
      assert payload["cells"] == []
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

  describe "validate --strict" do
    test "returns :ok on the production matrix with current recorded_at dates" do
      {messages, result} =
        capture_shell_messages(fn -> ViewerEvidence.run(["validate", "--strict"]) end)

      assert result == :ok
      output = Enum.join(messages, "\n")
      assert output =~ "Viewer evidence validation passed"
    end

    test "exits 1 when supported row recorded_at exceeds 180 days" do
      tmp = stale_matrix_fixture!()

      try do
        parent = self()

        pid =
          spawn(fn ->
            File.cd!(tmp, fn ->
              send(parent, {:run_result, ViewerEvidence.run(["validate", "--strict"])})
            end)
          end)

        ref = Process.monitor(pid)
        assert_receive {:DOWN, ^ref, :process, ^pid, {:shutdown, 1}}, 5_000
        refute_receive {:run_result, _}, 100
      after
        File.rm_rf!(tmp)
      end
    end

    test "default validate exits 0 with stale recorded_at (advisory only)" do
      tmp = stale_matrix_fixture!()

      try do
        File.cd!(tmp, fn ->
          {messages, result} =
            capture_shell_messages(fn ->
              ViewerEvidence.run(["validate"])
            end)

          assert result == :ok
          output = Enum.join(messages, "\n")
          assert output =~ "Viewer evidence validation passed"
          assert Enum.any?(messages, &String.contains?(&1, "is older than"))
        end)
      after
        File.rm_rf!(tmp)
      end
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

  defp stale_matrix_fixture! do
    tmp =
      Path.join(System.tmp_dir!(), "rendro_stale_matrix_#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp)
    File.cp_r!("priv", Path.join(tmp, "priv"))

    matrix_path = Path.join(tmp, "priv/support_matrix.json")
    matrix = matrix_path |> File.read!() |> JSON.decode!()

    stale_date =
      Date.utc_today()
      |> Date.add(-181)
      |> Date.to_iso8601()

    matrix = put_in(matrix, ["forms", "viewers", "apple_preview", "recorded_at"], stale_date)
    File.write!(matrix_path, JSON.encode!(matrix))

    tmp
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
