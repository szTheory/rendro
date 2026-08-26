defmodule Rendro.PhoenixCleanRoomProof do
  @moduledoc false

  @version "1.3.4"
  @candidate "f03c78bab54efe1cd1596d51cf3f28193232e2a3"
  @phx_new_version "1.8.5"
  @public_outer_checksum "a6048f87aa54a8467374c56bab87d25be26e8c835e8cf8f06050573f8c4a7c80"
  @public_inner_checksum "2a72bac4466e7b34e26486242d6aa22971edbd92cac2572d739441ff85615cc7"
  @bootstrap_timeout_ms 120_000
  @loopback_attempts 240
  @loopback_retry_ms 250
  @forbidden ~w(MIX_HOME HEX_HOME HEX_USER_HOME REBAR_CACHE_DIR MIX_DEPS_PATH MIX_BUILD_PATH NETRC)

  def main(args \\ System.argv(), executor \\ &run_with_cleanup/2) do
    result =
      try do
        with {:ok, options} <- parse_args(args),
             {:ok, prerequisite} <- read_prerequisite(options.prerequisite),
             :ok <- validate_prerequisite(prerequisite) do
          executor.(options, prerequisite)
        else
          {:error, reason} -> failure(reason)
        end
      rescue
        error -> failure({:exception, error.__struct__})
      catch
        kind, reason -> failure({kind, reason})
      end

    emit(result, options_output(args))
    result
  end

  @doc false
  def run_with_cleanup(
        options,
        prerequisite,
        runner \\ &run_once/3,
        cleanup \\ &cleanup_root/1
      ) do
    with {:ok, root} <- create_root(options.root) do
      result =
        try do
          runner.(root, options, prerequisite)
        rescue
          error -> failure({:exception, error.__struct__})
        catch
          kind, reason -> failure({kind, reason})
        end

      case cleanup_root(root, cleanup) do
        :ok -> mark_workspace_removed(result)
        {:error, reason} -> failure({:cleanup_failed, reason})
      end
    else
      {:error, reason} -> failure(reason)
    end
  end

  def validate_prerequisite(prerequisite) when is_map(prerequisite) do
    required = %{
      "public_prerequisite" => "VERIFIED",
      "version" => @version,
      "hex_version" => @version,
      "hexdocs_version" => @version,
      "candidate_commit_sha" => @candidate,
      "peeled_tag_sha" => @candidate,
      "release_name" => "Release to Hex",
      "release_conclusion" => "success",
      "release_publish_job_conclusion" => "success",
      "hexdocs_provenance" => "hexdocs_workflow_dispatch",
      "hexdocs_conclusion" => "success",
      "hexdocs_event" => "workflow_dispatch",
      "hexdocs_name" => "HexDocs",
      "v1_3_0_conclusion" => "failure",
      "v1_3_1_conclusion" => "cancelled",
      "v1_3_2_conclusion" => "failure",
      "v1_3_3_conclusion" => "failure"
    }

    with true <- Enum.all?(required, fn {key, value} -> Map.get(prerequisite, key) == value end),
         :ok <- valid_sha?(prerequisite["hexdocs_head_sha"]),
         :ok <- valid_numeric?(prerequisite["docs_provenance_run_id"]),
         :ok <-
           validate_candidate_binding(
             prerequisite["hexdocs_candidate_binding"],
             prerequisite["hexdocs_head_sha"],
             prerequisite["docs_provenance_run_id"]
           ) do
      :ok
    else
      _ -> {:error, :invalid_public_prerequisite}
    end
  end

  def validate_prerequisite(_), do: {:error, :invalid_public_prerequisite}

  defp validate_candidate_binding(binding, control_sha, run_id) when is_map(binding) do
    required = %{
      "control_ref" => "refs/heads/main",
      "control_sha" => control_sha,
      "requested_artifact_sha" => @candidate,
      "peeled_tag_sha" => @candidate,
      "detached_artifact_head" => @candidate,
      "tag" => "v#{@version}",
      "workflow_name" => "HexDocs",
      "workflow_event" => "workflow_dispatch",
      "workflow_run_id" => run_id
    }

    if Enum.all?(required, fn {key, value} -> Map.get(binding, key) == value end),
      do: :ok,
      else: {:error, :invalid_public_prerequisite}
  end

  defp validate_candidate_binding(_, _, _), do: {:error, :invalid_public_prerequisite}

  defp valid_sha?(value) when is_binary(value) do
    if Regex.match?(~r/^[0-9a-f]{40}$/, value),
      do: :ok,
      else: {:error, :invalid_public_prerequisite}
  end

  defp valid_sha?(_), do: {:error, :invalid_public_prerequisite}

  defp valid_numeric?(value) when is_binary(value) do
    if Regex.match?(~r/^\d+$/, value), do: :ok, else: {:error, :invalid_public_prerequisite}
  end

  defp valid_numeric?(_), do: {:error, :invalid_public_prerequisite}

  def audit_dependency_source!(source) when is_binary(source) do
    cond do
      source != "{:rendro, \"1.3.4\"}" ->
        {:error, :non_exact_public_dependency}

      String.contains?(source, ["path:", "git:", "github:", "workspace"]) ->
        {:error, :non_public_dependency}

      true ->
        :ok
    end
  end

  def audit_lock!(%{
        rendro:
          {:hex, :rendro, @version, @public_inner_checksum, managers, dependencies, "hexpm",
           @public_outer_checksum}
      })
      when is_list(managers) and is_list(dependencies) do
    if :mix in managers and Enum.all?(dependencies, &is_tuple/1),
      do: :ok,
      else: {:error, :invalid_rendro_lock}
  end

  def audit_lock!(_), do: {:error, :invalid_rendro_lock}

  def add_exact_rendro_dependency(mix) when is_binary(mix) do
    case Regex.replace(~r/(defp deps do\s*\[)/, mix, "\\1\n      {:rendro, \"1.3.4\"},",
           global: false
         ) do
      ^mix -> {:error, :deps_list_not_found}
      patched -> {:ok, patched}
    end
  end

  def project_evidence(facts) when is_map(facts) do
    facts
    |> Map.take([
      :schema_version,
      :lane,
      :advisory,
      :version,
      :candidate_sha,
      :prerequisite_sha,
      :elixir,
      :otp,
      :phoenix,
      :plug,
      :bandit,
      :hex,
      :phx_new,
      :phx_new_source,
      :commands,
      :lock_sha256,
      :source_audits,
      :conn_case,
      :loopback,
      :cleanup,
      :outcome,
      :next_action
    ])
    |> Enum.into(%{}, fn {key, value} -> {Atom.to_string(key), redact(value)} end)
  end

  @doc false
  def resolved_versions(lock) when is_map(lock) do
    with {:ok, phoenix} <- hex_lock_version(lock, :phoenix),
         {:ok, plug} <- hex_lock_version(lock, :plug),
         {:ok, bandit} <- hex_lock_version(lock, :bandit) do
      {:ok, %{phoenix: phoenix, plug: plug, bandit: bandit}}
    end
  end

  defp hex_lock_version(lock, dependency) do
    case Map.get(lock, dependency) do
      {:hex, ^dependency, version, _checksum, _managers, _dependencies, "hexpm", _outer}
      when is_binary(version) ->
        {:ok, version}

      _ ->
        {:error, :missing_resolved_dependency}
    end
  end

  def templates do
    %{
      mix: """
      defmodule CleanRoom.MixProject do
        use Mix.Project
        def project, do: [app: :clean_room, version: \"0.1.0\", deps: deps()]
        def application, do: [mod: {CleanRoom.Application, []}, extra_applications: [:logger]]
        defp deps, do: [{:phoenix, \"~> 1.8\"}, {:bandit, \"~> 1.5\"}, {:rendro, \"1.3.4\"}]
      end
      """,
      document: """
      defmodule CleanRoomWeb.InvoiceDocument do
        def build do
          invoice = %{id: \"INV-134\", date: ~D[2026-08-24], items: [%{name: \"Consulting\", qty: 1, price: 100}]}
          preset = :swiss
          theme = Rendro.Theme.preset(preset, accent: {44, 107, 237}, mode: :light)
          invoice |> Rendro.Recipes.Invoice.document(theme: theme) |> Rendro.Theme.Presets.register_fonts(preset)
        end
      end
      """,
      controller: """
      defmodule CleanRoomWeb.InvoiceController do
        use CleanRoomWeb, :controller
        alias CleanRoomWeb.InvoiceDocument
        def show(conn, _params), do: Rendro.Adapters.Phoenix.render_pdf(conn, InvoiceDocument.build(), \"invoice.pdf\")
      end
      """,
      router: """
      defmodule CleanRoomWeb.Router do
        use CleanRoomWeb, :router
        scope \"/\" do
          get \"/invoice.pdf\", CleanRoomWeb.InvoiceController, :show
        end
      end
      """,
      test: """
      defmodule CleanRoomWeb.InvoiceControllerTest do
        use CleanRoomWeb.ConnCase
        test \"ConnCase proof\" do
          conn = get(build_conn(), \"/invoice.pdf\")
          assert conn.status == 200
          assert [\"application/pdf; charset=utf-8\"] = Plug.Conn.get_resp_header(conn, \"content-type\")
          assert [\"attachment; filename=\\\"invoice.pdf\\\"\"] = Plug.Conn.get_resp_header(conn, \"content-disposition\")
          assert byte_size(conn.resp_body) > 0 and String.starts_with?(conn.resp_body, \"%PDF-\")
        end
        test \"loopback proof\" do
          assert true
        end
      end
      """
    }
  end

  @doc false
  def bootstrap_phx_new(
        root,
        runner \\ &run_bounded/5,
        inspector \\ &archive_sources/1,
        version_runner \\ &run_bounded/5
      ) do
    env = isolated_env(root)

    with {_, 0} <-
           runner.(
             "mix",
             ["archive.install", "hex", "phx_new", @phx_new_version, "--force"],
             env,
             root,
             @bootstrap_timeout_ms
           ),
         {:ok, sources} <- inspector.(root),
         :ok <- verify_archive_sources(sources, root),
         {version, 0} <-
           version_runner.("mix", ["phx.new", "--version"], env, root, @bootstrap_timeout_ms),
         true <- String.contains?(version, "#{@phx_new_version}") do
      :ok
    else
      :timeout -> {:error, :phx_new_install_timeout}
      {_, 1} -> {:error, :phx_new_install_failed}
      {_, status} when is_integer(status) -> {:error, :phx_new_install_failed}
      {:error, _} = error -> error
      false -> {:error, :phx_new_wrong_version}
      _ -> {:error, :phx_new_install_failed}
    end
  end

  defp parse_args(args) do
    if args != [] and hd(args) == "--", do: parse_args(tl(args)), else: parse_options(args)
  end

  defp parse_options(args) do
    defaults = %{prerequisite: default_prerequisite(), output: nil, root: nil}

    case args do
      [] ->
        {:ok, defaults}

      ["--prerequisite", prerequisite] ->
        {:ok, %{defaults | prerequisite: prerequisite}}

      ["--prerequisite", prerequisite, "--output", output] ->
        {:ok, %{defaults | prerequisite: prerequisite, output: output}}

      ["--prerequisite", prerequisite, "--output", output, "--root", root] ->
        {:ok, %{defaults | prerequisite: prerequisite, output: output, root: root}}

      _ ->
        {:error, :invalid_arguments}
    end
  end

  defp options_output(["--" | args]), do: options_output(args)
  defp options_output(["--prerequisite", _, "--output", output | _]), do: output
  defp options_output(_), do: nil

  defp default_prerequisite,
    do:
      Path.expand(
        "../.planning/milestones/v2.13-phases/131-adoption-snapshot-phoenix-newcomer-proof/131-PUBLIC-PREREQUISITE.json",
        __DIR__
      )

  defp read_prerequisite(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, prerequisite} <- Jason.decode(contents),
         do: {:ok, prerequisite}
  end

  defp create_root(nil) do
    root =
      Path.join(
        System.tmp_dir!(),
        "rendro-phoenix-clean-room-#{System.unique_integer([:positive])}"
      )

    create_root(root)
  end

  defp create_root(root) do
    expanded = Path.expand(root)

    if String.starts_with?(expanded, [Path.expand("."), Path.expand("~")]) or
         File.exists?(expanded) do
      {:error, :unsafe_or_nonempty_root}
    else
      case File.mkdir_p(expanded) do
        :ok -> {:ok, expanded}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp run_once(root, options, prerequisite) do
    env = isolated_env(root)
    app = Path.join(root, "clean_room")

    with :ok <- assert_empty_root(root),
         :ok <- bootstrap_phx_new(root),
         :ok <-
           run_stage(
             :generated_app,
             "mix",
             [
               "phx.new",
               app,
               "--no-install",
               "--no-ecto",
               "--no-html",
               "--no-assets",
               "--no-mailer",
               "--app",
               "clean_room",
               "--module",
               "CleanRoom"
             ],
             env,
             root
           ),
         :ok <- write_consumer(app),
         :ok <- audit_dependency_source!(File.read!(Path.join(app, "mix.exs")) |> rendro_dep()),
         :ok <- run_stage(:deps_get, "mix", ["deps.get"], env, app),
         {:ok, lock} <- read_lock(app),
         :ok <- audit_lock!(lock),
         {:ok, resolved} <- resolved_versions(lock),
         :ok <-
           run_stage(
             :generated_consumer_test,
             "mix",
             ["test"],
             [{"MIX_ENV", "test"} | env],
             app
           ),
         :ok <- audit_public_source(app),
         {:ok, loopback_port} <- reserve_port(),
         :ok <- configure_loopback(app, loopback_port),
         :ok <- compile_loopback(app, env),
         {:ok, loopback} <- loopback_facts(app, env, loopback_port),
         :ok <- assert_cleanup_candidate(root, app) do
      project_evidence(%{
        schema_version: 1,
        lane: "advisory_external_evidence",
        advisory: true,
        version: @version,
        candidate_sha: prerequisite["candidate_commit_sha"],
        prerequisite_sha: sha256(options.prerequisite),
        elixir: System.version(),
        otp: System.otp_release(),
        phoenix: resolved.phoenix,
        plug: resolved.plug,
        bandit: resolved.bandit,
        hex: command_version("mix", ["hex.info"], env, app),
        phx_new: command_version("mix", ["phx.new", "--version"], env, root),
        phx_new_source: "isolated_mix_archive_phx_new_#{@phx_new_version}",
        commands: [
          "mix archive.install hex phx_new 1.8.5 --force",
          "mix phx.new --no-install --no-ecto --no-html --no-assets --no-mailer",
          "mix deps.get",
          "mix test",
          "mix compile",
          "loopback endpoint start",
          "loopback HTTP probe"
        ],
        lock_sha256: sha256(Path.join(app, "mix.lock")),
        source_audits: "public_hex_exact_1.3.4",
        conn_case: response_facts(),
        loopback: loopback,
        cleanup: "pending",
        outcome: "success",
        next_action: "none"
      })
    else
      {:error, reason} ->
        failure(reason)
    end
  end

  def isolated_env(root) do
    isolated = [
      {"MIX_HOME", Path.join(root, "mix")},
      {"HEX_HOME", Path.join(root, "hex")},
      {"HEX_USER_HOME", Path.join(root, "hex-user")},
      {"REBAR_CACHE_DIR", Path.join(root, "rebar")},
      {"MIX_DEPS_PATH", Path.join(root, "deps")},
      {"NETRC", Path.join(root, "netrc")}
    ]

    @forbidden
    |> Enum.reject(fn key ->
      Enum.any?(isolated, fn {isolated_key, _} -> key == isolated_key end)
    end)
    |> Enum.map(&{&1, nil})
    |> Kernel.++(isolated)
  end

  defp run(command, args, env, cd),
    do: System.cmd(command, args, env: env, cd: cd, stderr_to_stdout: true)

  defp read_lock(app) do
    try do
      lock = app |> Path.join("mix.lock") |> File.read!() |> Code.eval_string() |> elem(0)
      {:ok, lock}
    rescue
      _ -> {:error, :invalid_lockfile}
    end
  end

  defp run_stage(stage, command, args, env, cd) do
    case run(command, args, env, cd) do
      {_output, 0} -> :ok
      {output, status} -> {:error, {:command_failed, stage, status, bounded(output)}}
    end
  end

  defp run_bounded(command, args, env, cd, timeout) do
    task = Task.async(fn -> run(command, args, env, cd) end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      nil -> :timeout
    end
  end

  defp archive_sources(root) do
    archive_root = Path.join(root, "mix/archives")

    case File.ls(archive_root) do
      {:ok, entries} ->
        entries
        |> Enum.map(&Path.join(archive_root, &1))
        |> Enum.map(&read_archive(&1, root))
        |> collect_archives()

      _ ->
        {:error, :phx_new_archive_root_unavailable}
    end
  end

  defp read_archive(path, root) do
    name = Path.basename(path)

    {app_name, version} =
      if String.starts_with?(name, "phx_new-"),
        do: {"phx_new", String.replace_prefix(name, "phx_new-", "")},
        else: {"hex", String.replace_prefix(name, "hex-", "")}

    app_path = Path.join([path, "#{app_name}-#{version}", "ebin", "#{app_name}.app"])

    with true <- String.starts_with?(path, root),
         {:ok, %File.Stat{type: :directory}} <- File.lstat(path),
         {:ok, %File.Stat{type: :regular}} <- File.lstat(app_path),
         {:ok, app} <- File.read(app_path) do
      {:ok, %{path: path, app: app, role: String.to_atom(app_name)}}
    else
      false -> {:error, :phx_new_archive_outside_root}
      {:error, :enoent} -> {:error, :phx_new_app_missing}
      {:ok, %File.Stat{type: :symlink}} -> {:error, :phx_new_archive_symlink}
      {:ok, %File.Stat{type: _}} -> {:error, :phx_new_archive_type_mismatch}
      _ -> {:error, :phx_new_archive_invalid}
    end
  end

  defp collect_archives(results) do
    if Enum.all?(results, &match?({:ok, _}, &1)),
      do: {:ok, Enum.map(results, fn {:ok, archive} -> archive end)},
      else:
        Enum.find(results, {:error, :phx_new_archive_invalid}, fn result ->
          if match?({:error, _}, result), do: result, else: false
        end)
  end

  defp verify_archive_sources(sources, root) when is_list(sources) do
    expected = Path.join(root, "mix/archives/phx_new-#{@phx_new_version}")

    exact =
      Enum.find(sources, fn source ->
        source.path == expected and source.role == :phx_new and
          String.contains?(source.app, "{application,phx_new,") and
          String.contains?(source.app, "{vsn,\"#{@phx_new_version}\"}")
      end)

    allowed = ["phx_new-#{@phx_new_version}", "hex-2.5.1"]

    if not is_nil(exact) and
         Enum.all?(
           sources,
           &(String.starts_with?(&1.path, root) and Path.basename(&1.path) in allowed)
         ),
       do: :ok,
       else: {:error, :phx_new_archive_identity_mismatch}
  end

  defp command_version(command, args, env, cd),
    do: run(command, args, env, cd) |> elem(0) |> bounded()

  defp assert_empty_root(root),
    do: if(File.ls!(root) == [], do: :ok, else: {:error, :root_not_empty})

  defp rendro_dep(mix), do: Regex.run(~r/\{:rendro,[^}]+\}/, mix) |> List.first() || ""

  defp write_consumer(app) do
    source = templates()

    with {:ok, mix} <- File.read(Path.join(app, "mix.exs")),
         {:ok, patched_mix} <- add_exact_rendro_dependency(mix),
         :ok <- File.write(Path.join(app, "mix.exs"), patched_mix) do
      files = [
        {"lib/clean_room_web/invoice_document.ex", source.document},
        {"lib/clean_room_web/controllers/invoice_controller.ex", source.controller},
        {"lib/clean_room_web/router.ex", source.router},
        {"test/clean_room_web/controllers/invoice_controller_test.exs", source.test}
      ]

      Enum.reduce_while(files, :ok, fn {relative, contents}, :ok ->
        path = Path.join(app, relative)
        File.mkdir_p!(Path.dirname(path))

        case File.write(path, contents) do
          :ok -> {:cont, :ok}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp audit_public_source(app) do
    contents = File.read!(Path.join(app, "mix.lock"))

    if String.contains?(contents, ["path:", "git", "rendro/", Path.expand(".")]),
      do: {:error, :source_leakage},
      else: :ok
  end

  @doc false
  def compile_loopback(app, env, runner \\ &run_bounded/5) do
    case runner.("mix", ["compile"], [{"MIX_ENV", "test"} | env], app, @bootstrap_timeout_ms) do
      {_output, 0} -> :ok
      :timeout -> {:error, :loopback_build_timeout}
      {_output, _status} -> {:error, :loopback_build_failed}
    end
  end

  defp response_facts,
    do: %{
      status: 200,
      content_type: "application/pdf",
      filename: "invoice.pdf",
      nonempty: true,
      pdf_magic: true
    }

  def loopback_facts(app, env, port) do
    with {:ok, server} <- start_server(app, env, port) do
      run_loopback(server, fn server ->
        await_loopback(server, @loopback_attempts, fn -> request_loopback(port) end)
      end)
    end
  end

  defp reserve_port do
    with {:ok, socket} <- :gen_tcp.listen(0, [:binary, ip: {127, 0, 0, 1}, active: false]),
         {:ok, {_ip, port}} <- :inet.sockname(socket),
         :ok <- :gen_tcp.close(socket),
         do: {:ok, port}
  end

  defp configure_loopback(app, port) do
    path = Path.join(app, "config/test.exs")

    File.write(
      path,
      "\nconfig :clean_room, CleanRoomWeb.Endpoint, http: [ip: {127, 0, 0, 1}, port: #{port}], server: true\n",
      [:append]
    )
  end

  defp start_server(app, env, port) do
    with {:ok, {executable, args, port_env}} <- port_launcher(env, port) do
      server =
        Port.open(
          {:spawn_executable, executable},
          [
            :binary,
            :exit_status,
            args: Enum.map(args, &String.to_charlist/1),
            cd: String.to_charlist(app),
            env:
              Enum.map(port_env, fn {key, value} ->
                {String.to_charlist(key), String.to_charlist(value)}
              end)
          ]
        )

      {:ok, server}
    end
  rescue
    error -> {:error, {:server_start_failed, Exception.message(error)}}
  end

  @doc false
  def port_launcher(env, port, finder \\ &System.find_executable/1)

  def port_launcher(env, port, finder)
      when is_integer(port) and port in 1..65_535 do
    env_executable = finder.("env") || "/usr/bin/env"
    mix_executable = finder.("mix") || "mix"

    assignments =
      [{"MIX_ENV", "test"}, {"RENDRO_LOOPBACK_PORT", Integer.to_string(port)} | env]
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)

    command =
      "port = String.to_integer(System.fetch_env!(\"RENDRO_LOOPBACK_PORT\")); config = Application.get_env(:clean_room, CleanRoomWeb.Endpoint, []); http = Keyword.merge(Keyword.get(config, :http, []), ip: {127, 0, 0, 1}, port: port); Application.put_env(:clean_room, CleanRoomWeb.Endpoint, Keyword.merge(config, server: true, http: http)); Application.ensure_all_started(:clean_room)"

    args =
      Enum.flat_map(@forbidden, &["-u", &1]) ++
        assignments ++ [mix_executable, "run", "--no-start", "--no-halt", "-e", command]

    {:ok, {env_executable, args, []}}
  end

  def port_launcher(_env, _port, _finder), do: {:error, :invalid_loopback_port}

  @doc false
  def run_loopback(server, waiter, stopper \\ &stop_server/1) do
    try do
      waiter.(server)
    after
      stopper.(server)
    end
  end

  @doc false
  def await_loopback(server, attempts, requester, sleeper \\ &Process.sleep/1)

  def await_loopback(server, attempts, requester, sleeper) do
    await_loopback(server, attempts, requester, sleeper, %{exit_status: nil, output: ""}, :none)
  end

  defp await_loopback(_server, 0, _requester, _sleeper, server_state, last_http) do
    {:error, {:loopback_timeout, server_output_kind(server_state), last_http}}
  end

  defp await_loopback(server, attempts, requester, sleeper, server_state, _last_http) do
    server_state = drain_server_messages(server, server_state)

    case server_state.exit_status do
      status when is_integer(status) ->
        {:error, {:loopback_server_exited, status, server_output_kind(server_state)}}

      nil ->
        case requester.() do
          {:ok, 200, headers, body} ->
            validate_loopback_response(headers, body)

          {:ok, status, _headers, _body} ->
            {:error, {:loopback_http_status, status}}

          {:error, reason} ->
            sleeper.(@loopback_retry_ms)
            await_loopback(server, attempts - 1, requester, sleeper, server_state, reason)
        end
    end
  end

  defp drain_server_messages(server, server_state) do
    receive do
      {^server, {:data, data}} when is_binary(data) ->
        output = String.slice(server_state.output <> data, -240, 240)
        drain_server_messages(server, %{server_state | output: bounded(output)})

      {^server, {:exit_status, status}} when is_integer(status) ->
        %{server_state | exit_status: status}
    after
      0 -> server_state
    end
  end

  defp server_output_kind(%{output: output}) do
    cond do
      output == "" ->
        :no_output

      String.contains?(output, "address already in use") ->
        :bind_failed

      String.contains?(output, ["could not compile", "Compilation error"]) ->
        :compile_failed

      String.contains?(output, "Compiling ") ->
        :compiling

      String.contains?(output, ["Running CleanRoomWeb.Endpoint", "Access CleanRoomWeb.Endpoint"]) ->
        :endpoint_started

      String.contains?(output, ["error", "Error"]) ->
        :server_error

      true ->
        :output_observed
    end
  end

  defp request_loopback(port) do
    :inets.start()

    with {:ok, socket} <- :gen_tcp.connect({127, 0, 0, 1}, port, [:binary], 1_000),
         :ok <- :gen_tcp.close(socket) do
      case :httpc.request(
             :get,
             {String.to_charlist("http://127.0.0.1:#{port}/invoice.pdf"), []},
             [],
             body_format: :binary
           ) do
        {:ok, {{_http, status, _reason}, headers, body}} -> {:ok, status, headers, body}
        {:error, _reason} -> {:error, :http_unavailable}
      end
    else
      {:error, _reason} -> {:error, :tcp_unavailable}
    end
  end

  defp validate_loopback_response(headers, body) do
    content_type = header(headers, ~c"content-type")
    disposition = header(headers, ~c"content-disposition")

    cond do
      not (content_type =~ "application/pdf" and disposition =~ "filename=\"invoice.pdf\"") ->
        {:error, :loopback_invalid_headers}

      byte_size(body) == 0 or not String.starts_with?(body, "%PDF-") ->
        {:error, :loopback_invalid_body}

      true ->
        {:ok, response_facts()}
    end
  end

  defp header(headers, key),
    do: headers |> List.keyfind(key, 0, {key, ~c""}) |> elem(1) |> to_string()

  defp stop_server(server) do
    case Port.info(server, :os_pid) do
      {:os_pid, pid} ->
        _ = System.cmd("kill", ["-TERM", Integer.to_string(pid)], stderr_to_stdout: true)

      _ ->
        :ok
    end

    Port.close(server)

    receive do
      {^server, {:exit_status, _}} -> :ok
    after
      2_000 -> :ok
    end
  end

  defp assert_cleanup_candidate(root, app),
    do: if(String.starts_with?(app, root), do: :ok, else: {:error, :unsafe_app_path})

  defp cleanup_root(root, cleanup) do
    try do
      case cleanup.(root) do
        :ok -> if File.exists?(root), do: {:error, :workspace_still_exists}, else: :ok
        {:error, _} = error -> error
        other -> {:error, {:cleanup_invalid_result, other}}
      end
    rescue
      error -> {:error, {:cleanup_exception, error.__struct__}}
    catch
      kind, reason -> {:error, {:cleanup_exit, kind, reason}}
    end
  end

  defp cleanup_root(root) do
    remove_root(root)
  end

  defp remove_root(root) do
    case File.rm_rf(root) do
      {:ok, _} -> :ok
      {:error, reason, _} -> {:error, reason}
    end
  end

  defp sha256(path), do: :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)

  defp failure(reason),
    do:
      project_evidence(%{
        outcome: "failure",
        next_action: bounded(inspect(reason)),
        cleanup: "workspace_cleanup_attempted"
      })

  defp mark_workspace_removed(%{"outcome" => "success"} = result),
    do: Map.put(result, "cleanup", "workspace_removed")

  defp mark_workspace_removed(result), do: result

  defp emit(result, nil), do: IO.puts(Jason.encode!(result))

  defp emit(result, output) do
    encoded = Jason.encode!(result)
    temporary = "#{output}.#{System.unique_integer([:positive])}.tmp"

    with :ok <- File.write(temporary, encoded),
         :ok <- File.rename(temporary, output) do
      :ok
    else
      _ ->
        File.rm(temporary)
        IO.puts(Jason.encode!(failure(:evidence_write_failed)))
    end
  end

  defp bounded(value) when is_binary(value),
    do:
      value
      |> String.replace(~r{(^|[^[:alnum:]_])/(?:[^\s]+)}, "\\1[redacted]")
      |> String.replace(~r/\b\d{4,}\b/, "[redacted]")
      |> String.slice(0, 240)

  defp redact(value) when is_map(value),
    do: Map.new(value, fn {k, v} -> {to_string(k), redact(v)} end)

  defp redact(value) when is_list(value), do: Enum.map(value, &redact/1)
  defp redact(value) when is_binary(value), do: bounded(value)
  defp redact(value), do: value
end

if Process.whereis(ExUnit.Server) == nil, do: Rendro.PhoenixCleanRoomProof.main()
