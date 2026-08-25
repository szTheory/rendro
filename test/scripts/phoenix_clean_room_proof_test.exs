Code.require_file(Path.expand("../../scripts/phoenix_clean_room_proof.exs", __DIR__))
Code.require_file(Path.expand("../../scripts/verify_public_release.exs", __DIR__))

defmodule Rendro.PhoenixCleanRoomProofTest do
  use ExUnit.Case, async: true

  alias Rendro.PhoenixCleanRoomProof
  alias Rendro.PublicReleaseVerifier

  @candidate "f03c78bab54efe1cd1596d51cf3f28193232e2a3"
  @prerequisite_path Path.expand(
                       "../../.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-PUBLIC-PREREQUISITE.json",
                       __DIR__
                     )

  test "atomically emits a bounded failure when the harness exits unexpectedly" do
    directory =
      Path.join(
        System.tmp_dir!(),
        "rendro-clean-room-proof-#{System.unique_integer([:positive])}"
      )

    output = Path.join(directory, "result.json")
    prerequisite = Path.join(directory, "prerequisite.json")
    File.mkdir_p!(directory)
    File.write!(prerequisite, Jason.encode!(valid_prerequisite()))

    assert %{"outcome" => "failure", "next_action" => next_action} =
             PhoenixCleanRoomProof.main(
               [
                 "--prerequisite",
                 prerequisite,
                 "--output",
                 output,
                 "--root",
                 Path.join(directory, "root")
               ],
               fn _, _ -> exit(:injected_harness_exit) end
             )

    assert String.length(next_action) <= 240
    assert {:ok, emitted} = File.read(output)
    assert %{"outcome" => "failure", "next_action" => ^next_action} = Jason.decode!(emitted)
    assert [] = Path.wildcard("#{output}.*.tmp")
    refute emitted =~ directory

    File.rm_rf!(directory)
  end

  test "uses the requested output path when Mix supplies its leading separator" do
    directory =
      Path.join(
        System.tmp_dir!(),
        "rendro-clean-room-proof-#{System.unique_integer([:positive])}"
      )

    output = Path.join(directory, "result.json")
    prerequisite = Path.join(directory, "prerequisite.json")
    File.mkdir_p!(directory)
    File.write!(prerequisite, Jason.encode!(valid_prerequisite()))

    assert %{"outcome" => "failure"} =
             PhoenixCleanRoomProof.main(
               [
                 "--",
                 "--prerequisite",
                 prerequisite,
                 "--output",
                 output,
                 "--root",
                 Path.join(directory, "root")
               ],
               fn _, _ -> exit(:injected_harness_exit) end
             )

    assert %{"outcome" => "failure"} = output |> File.read!() |> Jason.decode!()
    File.rm_rf!(directory)
  end

  test "cleanup failures turn an otherwise-successful run into bounded failure" do
    root =
      Path.join(
        System.tmp_dir!(),
        "rendro-clean-room-proof-#{System.unique_integer([:positive])}"
      )

    assert %{"outcome" => "failure", "next_action" => next_action} =
             PhoenixCleanRoomProof.run_with_cleanup(
               %{root: root, output: nil, prerequisite: "unused"},
               %{},
               fn _, _, _ -> %{"outcome" => "success", "next_action" => "none"} end,
               fn _ -> exit(:injected_cleanup_exit) end
             )

    assert String.length(next_action) <= 240
    refute next_action =~ root
    File.rm_rf!(root)
  end

  test "a successful evidence record is marked removed only after cleanup succeeds" do
    root =
      Path.join(
        System.tmp_dir!(),
        "rendro-clean-room-proof-#{System.unique_integer([:positive])}"
      )

    parent = self()

    assert %{"outcome" => "success", "cleanup" => "removed"} =
             PhoenixCleanRoomProof.run_with_cleanup(
               %{root: root, output: nil, prerequisite: "unused"},
               %{},
               fn _, _, _ ->
                 send(parent, :runner_finished)
                 %{"outcome" => "success", "cleanup" => "pending", "next_action" => "none"}
               end,
               fn cleanup_root ->
                 assert_received :runner_finished
                 File.rm_rf!(cleanup_root)
                 send(parent, :cleanup_finished)
                 :ok
               end
             )

    assert_received :cleanup_finished
    refute File.exists?(root)
  end

  test "loopback retries delayed readiness and records only response facts" do
    server = make_ref()
    calls = :counters.new(1, [])

    requester = fn ->
      call = :counters.add(calls, 1, 1)

      if call == 1 do
        {:error, :tcp_unavailable}
      else
        {:ok, 200,
         [
           {~c"content-type", ~c"application/pdf"},
           {~c"content-disposition", ~c"attachment; filename=\"invoice.pdf\""}
         ], "%PDF-1.7"}
      end
    end

    assert {:ok, %{status: 200, pdf_magic: true}} =
             PhoenixCleanRoomProof.await_loopback(server, 2, requester, fn _ -> :ok end)
  end

  test "loopback build uses the consumer test environment and has typed failures" do
    app = "/isolated/clean-room"
    env = [{"MIX_HOME", "/isolated/mix"}]

    assert :ok =
             PhoenixCleanRoomProof.compile_loopback(app, env, fn "mix",
                                                                 ["compile"],
                                                                 actual_env,
                                                                 ^app,
                                                                 120_000 ->
               assert {"MIX_ENV", "test"} in actual_env
               {"compiled", 0}
             end)

    assert {:error, :loopback_build_timeout} =
             PhoenixCleanRoomProof.compile_loopback(app, env, fn _, _, _, _, _ -> :timeout end)

    assert {:error, :loopback_build_failed} =
             PhoenixCleanRoomProof.compile_loopback(app, env, fn _, _, _, _, _ ->
               {"failure", 1}
             end)
  end

  test "loopback configuration is compiled before the server starts" do
    source = File.read!(Path.expand("../../scripts/phoenix_clean_room_proof.exs", __DIR__))

    assert :binary.match(source, "configure_loopback(app, loopback_port)") <
             :binary.match(source, "compile_loopback(app, env)")

    assert :binary.match(source, "compile_loopback(app, env)") <
             :binary.match(source, "loopback_facts(app, env, loopback_port)")

    assert source =~ "{\"MIX_ENV\", \"test\"}"
    assert source =~ "Keyword.merge(config, server: true, http: http)"
    assert source =~ "ip: {127, 0, 0, 1}, port: port"
    assert source =~ "Application.ensure_all_started(:clean_room)"
  end

  test "Port launcher clears host overrides and supplies only the isolated environment" do
    root = "/isolated/clean-room"

    assert {:ok, {executable, args, port_env}} =
             PhoenixCleanRoomProof.port_launcher(
               PhoenixCleanRoomProof.isolated_env(root),
               40_123,
               fn
                 "env" -> "/usr/bin/env"
                 "mix" -> "/usr/local/bin/mix"
               end
             )

    assert executable == "/usr/bin/env"
    assert port_env == []

    assert Enum.take(args, 14) ==
             Enum.flat_map(
               ~w(MIX_HOME HEX_HOME HEX_USER_HOME REBAR_CACHE_DIR MIX_DEPS_PATH MIX_BUILD_PATH NETRC),
               &["-u", &1]
             )

    assert "MIX_ENV=test" in args
    assert "RENDRO_LOOPBACK_PORT=40123" in args
    assert "MIX_HOME=/isolated/clean-room/mix" in args
    assert "MIX_DEPS_PATH=/isolated/clean-room/deps" in args
    refute Enum.any?(args, &String.starts_with?(&1, "MIX_BUILD_PATH="))
    assert "/usr/local/bin/mix" in args
    refute Enum.any?(args, &String.contains?(&1, "sh -c"))
    assert Enum.any?(args, &String.contains?(&1, "ip: {127, 0, 0, 1}, port: port"))

    assert Enum.any?(
             args,
             &String.contains?(&1, "Keyword.merge(config, server: true, http: http)")
           )

    assert {:error, :invalid_loopback_port} = PhoenixCleanRoomProof.port_launcher([], 0)
    assert {:error, :invalid_loopback_port} = PhoenixCleanRoomProof.port_launcher([], 65_536)
  end

  test "loopback fails fast on server exit and classifies bounded port output" do
    server = make_ref()
    send(self(), {server, {:data, "could not compile /tmp/private"}})
    send(self(), {server, {:exit_status, 1}})

    assert {:error, {:loopback_server_exited, 1, :compile_failed}} =
             PhoenixCleanRoomProof.await_loopback(
               server,
               2,
               fn -> flunk("must not request") end,
               fn _ -> :ok end
             )
  end

  test "loopback classifies compilation output without retaining it" do
    server = make_ref()
    send(self(), {server, {:data, "Compiling /tmp/secret.ex"}})

    assert {:error, {:loopback_timeout, :compiling, :tcp_unavailable}} =
             PhoenixCleanRoomProof.await_loopback(
               server,
               1,
               fn -> {:error, :tcp_unavailable} end,
               fn _ -> :ok end
             )
  end

  test "loopback distinguishes HTTP statuses, invalid headers, invalid body, and timeout" do
    server = make_ref()

    headers = [
      {~c"content-type", ~c"application/pdf"},
      {~c"content-disposition", ~c"attachment; filename=\"invoice.pdf\""}
    ]

    assert {:error, {:loopback_http_status, 404}} =
             PhoenixCleanRoomProof.await_loopback(server, 1, fn -> {:ok, 404, [], ""} end, fn _ ->
               :ok
             end)

    assert {:error, {:loopback_http_status, 500}} =
             PhoenixCleanRoomProof.await_loopback(server, 1, fn -> {:ok, 500, [], ""} end, fn _ ->
               :ok
             end)

    assert {:error, :loopback_invalid_headers} =
             PhoenixCleanRoomProof.await_loopback(
               server,
               1,
               fn -> {:ok, 200, [], "%PDF-1.7"} end,
               fn _ -> :ok end
             )

    assert {:error, :loopback_invalid_body} =
             PhoenixCleanRoomProof.await_loopback(
               server,
               1,
               fn -> {:ok, 200, headers, ""} end,
               fn _ -> :ok end
             )

    assert {:error, {:loopback_timeout, :no_output, :tcp_unavailable}} =
             PhoenixCleanRoomProof.await_loopback(
               server,
               1,
               fn -> {:error, :tcp_unavailable} end,
               fn _ -> :ok end
             )
  end

  test "loopback teardown runs after a timeout" do
    server = make_ref()
    parent = self()

    assert {:error, {:loopback_timeout, :no_output, :tcp_unavailable}} =
             PhoenixCleanRoomProof.run_loopback(
               server,
               fn server ->
                 PhoenixCleanRoomProof.await_loopback(
                   server,
                   1,
                   fn -> {:error, :tcp_unavailable} end,
                   fn _ -> :ok end
                 )
               end,
               fn ^server -> send(parent, :stopped) end
             )

    assert_receive :stopped
  end

  test "shares the current HexDocs workflow-dispatch prerequisite contract with the public verifier" do
    prerequisite = current_prerequisite()

    assert :ok = PublicReleaseVerifier.validate(prerequisite)
    assert :ok = PhoenixCleanRoomProof.validate_prerequisite(prerequisite)

    legacy =
      prerequisite
      |> Map.put("hexdocs_provenance", "protected_release_publish")
      |> Map.delete("hexdocs_candidate_binding")

    assert_rejected_by_both(legacy)

    for mutation <- [
          fn facts -> Map.delete(facts, "hexdocs_candidate_binding") end,
          fn facts ->
            put_in(
              facts,
              ["hexdocs_candidate_binding", "control_ref"],
              "refs/heads/release"
            )
          end,
          fn facts ->
            put_in(facts, ["hexdocs_candidate_binding", "control_sha"], String.duplicate("a", 40))
          end,
          fn facts ->
            put_in(
              facts,
              ["hexdocs_candidate_binding", "requested_artifact_sha"],
              String.duplicate("a", 40)
            )
          end,
          fn facts ->
            put_in(
              facts,
              ["hexdocs_candidate_binding", "peeled_tag_sha"],
              String.duplicate("a", 40)
            )
          end,
          fn facts ->
            put_in(
              facts,
              ["hexdocs_candidate_binding", "detached_artifact_head"],
              String.duplicate("a", 40)
            )
          end,
          fn facts -> put_in(facts, ["hexdocs_candidate_binding", "tag"], "v1.3.3") end,
          fn facts ->
            put_in(facts, ["hexdocs_candidate_binding", "workflow_event"], "push")
          end,
          fn facts -> put_in(facts, ["hexdocs_candidate_binding", "workflow_name"], "Release to Hex") end,
          fn facts -> put_in(facts, ["hexdocs_candidate_binding", "workflow_run_id"], "1") end,
          fn facts -> Map.put(facts, "hexdocs_head_sha", "not-a-sha") end,
          fn facts -> Map.put(facts, "hexdocs_conclusion", "failure") end,
          fn facts -> Map.put(facts, "hexdocs_event", "push") end,
          fn facts -> Map.put(facts, "hexdocs_name", "Release to Hex") end,
          fn facts -> Map.put(facts, "docs_provenance_run_id", "not-a-run") end
        ] do
      assert_rejected_by_both(mutation.(prerequisite))
    end
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
        port: 40_123,
        response_body: "%PDF-secret",
        hex_api_key: "secret",
        commands: ["loopback HTTP probe \"/tmp/rendro-clean-room-secret\""],
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
    refute inspect(projected) =~ "/tmp/"
    refute inspect(projected) =~ "secret"
  end

  test "projects the complete advisory identity schema without corrupting safe MIME values" do
    projected =
      PhoenixCleanRoomProof.project_evidence(%{
        schema_version: 1,
        lane: "advisory_external_evidence",
        advisory: true,
        version: "1.3.4",
        candidate_sha: @candidate,
        prerequisite_sha: String.duplicate("a", 64),
        phoenix: "1.8.5",
        plug: "1.18.1",
        bandit: "1.7.0",
        lock_sha256: String.duplicate("b", 64),
        commands: ["mix archive.install hex phx_new 1.8.5 --force", "loopback HTTP probe"],
        conn_case: %{content_type: "application/pdf", filename: "invoice.pdf", status: 200},
        loopback: %{content_type: "application/pdf", filename: "invoice.pdf", status: 200},
        cleanup: "removed"
      })

    for key <-
          ~w(schema_version lane advisory version candidate_sha prerequisite_sha phoenix plug bandit lock_sha256 commands conn_case loopback cleanup) do
      assert Map.has_key?(projected, key)
    end

    assert projected["conn_case"]["content_type"] == "application/pdf"
    assert projected["loopback"]["content_type"] == "application/pdf"
    assert projected["candidate_sha"] == @candidate
    assert projected["prerequisite_sha"] == String.duplicate("a", 64)
    assert projected["lock_sha256"] == String.duplicate("b", 64)
  end

  test "extracts only resolver-selected Phoenix, Plug, and Bandit versions from atom-key locks" do
    lock = %{
      phoenix: {:hex, :phoenix, "1.8.5", "checksum", [:mix], [], "hexpm", "outer"},
      plug: {:hex, :plug, "1.18.1", "checksum", [:mix], [], "hexpm", "outer"},
      bandit: {:hex, :bandit, "1.7.0", "checksum", [:mix], [], "hexpm", "outer"},
      private: {:git, "https://example.test/private", "sha", []}
    }

    assert {:ok, %{phoenix: "1.8.5", plug: "1.18.1", bandit: "1.7.0"}} =
             PhoenixCleanRoomProof.resolved_versions(lock)

    assert {:error, :missing_resolved_dependency} = PhoenixCleanRoomProof.resolved_versions(%{})
  end

  test "success evidence records only the bounded command allowlist" do
    source = File.read!(Path.expand("../../scripts/phoenix_clean_room_proof.exs", __DIR__))

    for command <- [
          "mix archive.install hex phx_new 1.8.5 --force",
          "mix phx.new --no-install --no-ecto --no-html --no-assets --no-mailer",
          "mix deps.get",
          "mix test",
          "mix compile",
          "loopback endpoint start",
          "loopback HTTP probe"
        ] do
      assert source =~ ~s("#{command}")
    end
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

  defp current_prerequisite, do: @prerequisite_path |> File.read!() |> Jason.decode!()

  defp valid_prerequisite, do: current_prerequisite()

  defp assert_rejected_by_both(prerequisite) do
    assert {:error, _} = PublicReleaseVerifier.validate(prerequisite)
    assert {:error, _} = PhoenixCleanRoomProof.validate_prerequisite(prerequisite)
  end
end
