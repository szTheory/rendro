Code.require_file(Path.expand("../../scripts/phoenix_clean_room_proof.exs", __DIR__))

defmodule Rendro.PhoenixCleanRoomProofTest do
  use ExUnit.Case, async: true

  alias Rendro.PhoenixCleanRoomProof

  @candidate "f03c78bab54efe1cd1596d51cf3f28193232e2a3"

  test "accepts only the exact verified public 1.3.4 combined-release prerequisite" do
    prerequisite = %{
      "public_prerequisite" => "VERIFIED",
      "version" => "1.3.4",
      "hex_version" => "1.3.4",
      "hexdocs_version" => "1.3.4",
      "candidate_commit_sha" => @candidate,
      "peeled_tag_sha" => @candidate,
      "release_name" => "Release to Hex",
      "release_conclusion" => "success",
      "release_publish_job_conclusion" => "success",
      "hexdocs_provenance" => "protected_release_publish",
      "docs_provenance_run_id" => "32763039854",
      "v1_3_0_conclusion" => "failure",
      "v1_3_1_conclusion" => "cancelled",
      "v1_3_2_conclusion" => "failure",
      "v1_3_3_conclusion" => "failure"
    }

    assert :ok = PhoenixCleanRoomProof.validate_prerequisite(prerequisite)

    assert {:error, _} =
             PhoenixCleanRoomProof.validate_prerequisite(
               Map.put(prerequisite, "version", "1.3.3")
             )

    assert {:error, _} =
             PhoenixCleanRoomProof.validate_prerequisite(
               Map.delete(prerequisite, "v1_3_3_conclusion")
             )

    assert {:error, _} =
             PhoenixCleanRoomProof.validate_prerequisite(
               Map.put(prerequisite, "hexdocs_provenance", "workflow_dispatch")
             )
  end

  test "rejects non-public dependency sources and malformed exact lock entries" do
    assert :ok = PhoenixCleanRoomProof.audit_dependency_source!("{:rendro, \"1.3.4\"}")

    for source <- [
          "{:rendro, path: \"../rendro\"}",
          "{:rendro, git: \"https://github.com/szTheory/rendro.git\"}",
          "{:rendro, github: \"szTheory/rendro\"}",
          "{:rendro, \"~> 1.3\"}"
        ] do
      assert {:error, _} = PhoenixCleanRoomProof.audit_dependency_source!(source)
    end

    lock =
      {:hex, :rendro, "1.3.4", "2a72bac4466e7b34e26486242d6aa22971edbd92cac2572d739441ff85615cc7",
       [:mix], [{:decimal, "~> 2.3"}, {:telemetry, "~> 1.4"}], "hexpm",
       "a6048f87aa54a8467374c56bab87d25be26e8c835e8cf8f06050573f8c4a7c80"}

    assert :ok = PhoenixCleanRoomProof.audit_lock!(%{rendro: lock})

    for bad <- [
          %{"rendro" => lock},
          %{rendro: {:hex, :rendro, "1.3.4", "checksum", [:mix], "hexpm", "outer"}},
          %{rendro: put_elem(lock, 3, String.duplicate("a", 64))},
          %{rendro: put_elem(lock, 7, String.duplicate("b", 64))},
          %{rendro: put_elem(lock, 2, "1.3.3")},
          %{rendro: {:git, "https://example.test/rendro", "sha", []}}
        ] do
      assert {:error, :invalid_rendro_lock} = PhoenixCleanRoomProof.audit_lock!(bad)
    end

    assert {:error, _} =
             PhoenixCleanRoomProof.audit_lock!(%{
               "rendro" => {:git, "https://example.test/rendro", "sha", []}
             })
  end

  test "projects bounded evidence without paths, bodies, ports, PIDs, or secrets" do
    projected =
      PhoenixCleanRoomProof.project_evidence(%{
        elixir: "1.19.5",
        otp: "28",
        root: "/tmp/rendro-clean-room-secret",
        pid: 1234,
        port: 40123,
        response_body: "%PDF-secret",
        hex_api_key: "secret",
        conn_case: %{
          status: 200,
          content_type: "application/pdf",
          filename: "invoice.pdf",
          pdf_magic: true
        },
        loopback: %{
          status: 200,
          content_type: "application/pdf",
          filename: "invoice.pdf",
          pdf_magic: true
        },
        cleanup: "removed"
      })

    assert projected["elixir"] == "1.19.5"
    assert projected["cleanup"] == "removed"
    refute inspect(projected) =~ "/tmp/"
    refute inspect(projected) =~ "secret"
    refute Map.has_key?(projected, "pid")
    refute Map.has_key?(projected, "port")
    refute Map.has_key?(projected, "response_body")
  end

  test "generated source keeps the document app-owned, the controller thin, and ConnCase before loopback" do
    templates = PhoenixCleanRoomProof.templates()

    assert templates.document =~ "defmodule CleanRoomWeb.InvoiceDocument"
    assert templates.document =~ "preset = :swiss"
    assert templates.document =~ "{44, 107, 237}"
    assert templates.document =~ "mode: :light"

    assert templates.controller =~
             "Rendro.Adapters.Phoenix.render_pdf(conn, InvoiceDocument.build(), \"invoice.pdf\")"

    assert templates.test =~ "use CleanRoomWeb.ConnCase"
    assert templates.test =~ "application/pdf; charset=utf-8"
    assert templates.test =~ "attachment; filename=\\\"invoice.pdf\\\""
    assert templates.test =~ "loopback proof"

    assert :binary.match(templates.test, "ConnCase proof") <
             :binary.match(templates.test, "loopback proof")

    refute templates.mix =~ "ecto"
    refute templates.mix =~ "path:"
    refute templates.mix =~ "git:"
  end

  test "consumer dependency patch adds only exact public Rendro" do
    mix = "defp deps do\n  [\n    {:phoenix, \"~> 1.8\"}\n  ]\nend\n"

    assert {:ok, patched} = PhoenixCleanRoomProof.add_exact_rendro_dependency(mix)
    assert patched =~ "{:rendro, \"1.3.4\"}"
    assert :ok = PhoenixCleanRoomProof.audit_dependency_source!("{:rendro, \"1.3.4\"}")
    refute patched =~ "path:"
    refute patched =~ "git:"
  end

  test "bootstraps only the exact phx_new archive inside the disposable root" do
    root = "/isolated/clean-room"

    runner = fn "mix", args, env, ^root, _timeout ->
      assert args == ["archive.install", "hex", "phx_new", "1.8.5", "--force"]
      refute Enum.any?(env, fn {key, _} -> key == "HOME" end)
      assert {"MIX_HOME", Path.join(root, "mix")} in env
      assert {"NETRC", Path.join(root, "netrc")} in env
      {"* creating phx_new 1.8.5", 0}
    end

    inspector = fn ^root ->
      {:ok,
       [
         %{
           path: Path.join(root, "mix/archives/phx_new-1.8.5"),
           app: "{application,phx_new,[{vsn,\"1.8.5\"}]}.",
           role: :phx_new
         },
         %{
           path: Path.join(root, "mix/archives/hex-2.5.1"),
           app: "{application,hex,[{vsn,\"2.5.1\"}]}.",
           role: :hex
         }
       ]}
    end

    version = fn "mix", ["phx.new", "--version"], _env, ^root, _timeout ->
      {"Phoenix v1.8.5", 0}
    end

    assert :ok = PhoenixCleanRoomProof.bootstrap_phx_new(root, runner, inspector, version)
  end

  test "keeps generated-app build artifacts app-owned while clearing host build paths" do
    root = "/isolated/clean-room"

    env = PhoenixCleanRoomProof.isolated_env(root)

    assert {"MIX_DEPS_PATH", Path.join(root, "deps")} in env
    assert {"MIX_BUILD_PATH", nil} in env
    refute {"MIX_BUILD_PATH", Path.join(root, "build")} in env
  end

  test "rejects failed, wrong-version, host-sourced, and timed-out phx_new bootstrap" do
    root = "/isolated/clean-room"

    inspector = fn _ ->
      {:ok,
       [
         %{
           path: Path.join(root, "mix/archives/phx_new-1.8.5"),
           app: "{application,phx_new,[{vsn,\"1.8.5\"}]}.",
           role: :phx_new
         },
         %{
           path: Path.join(root, "mix/archives/hex-2.5.1"),
           app: "{application,hex,[{vsn,\"2.5.1\"}]}.",
           role: :hex
         }
       ]}
    end

    version = fn _, _, _, _, _ -> {"Phoenix v1.8.5", 0} end

    assert {:error, :phx_new_install_failed} =
             PhoenixCleanRoomProof.bootstrap_phx_new(
               root,
               fn _, _, _, _, _ -> {"failed", 1} end,
               inspector,
               version
             )

    assert {:error, :phx_new_wrong_version} =
             PhoenixCleanRoomProof.bootstrap_phx_new(
               root,
               fn _, _, _, _, _ -> {"ok", 0} end,
               inspector,
               fn _, _, _, _, _ -> {"Phoenix v1.8.4", 0} end
             )

    assert {:error, :phx_new_archive_identity_mismatch} =
             PhoenixCleanRoomProof.bootstrap_phx_new(
               root,
               fn _, _, _, _, _ -> {"ok", 0} end,
               fn _ ->
                 {:ok,
                  [%{path: "/Users/me/.mix/archives/phx_new-1.8.5", app: "", role: :phx_new}]}
               end,
               version
             )

    assert {:error, :phx_new_install_timeout} =
             PhoenixCleanRoomProof.bootstrap_phx_new(
               root,
               fn _, _, _, _, _ -> :timeout end,
               inspector,
               version
             )
  end
end
