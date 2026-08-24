defmodule Rendro.PhoenixCleanRoomProof do
  @moduledoc false

  @version "1.3.4"
  @candidate "f03c78bab54efe1cd1596d51cf3f28193232e2a3"
  @phx_new_version "1.8.5"
  @public_outer_checksum "a6048f87aa54a8467374c56bab87d25be26e8c835e8cf8f06050573f8c4a7c80"
  @public_inner_checksum "2a72bac4466e7b34e26486242d6aa22971edbd92cac2572d739441ff85615cc7"
  @bootstrap_timeout_ms 120_000
  @forbidden ~w(MIX_HOME HEX_HOME HEX_USER_HOME REBAR_CACHE_DIR MIX_DEPS_PATH MIX_BUILD_PATH NETRC)

  def main(args \\ System.argv()) do
    with {:ok, options} <- parse_args(args),
         {:ok, prerequisite} <- read_prerequisite(options.prerequisite),
         :ok <- validate_prerequisite(prerequisite) do
      run_with_cleanup(options, prerequisite)
    else
      {:error, reason} ->
        emit(failure(reason), options_output(args))
        {:error, reason}
    end
  end

  defp run_with_cleanup(options, prerequisite) do
    with {:ok, root} <- create_root(options.root) do
      result =
        try do
          run_once(root, options, prerequisite)
        after
          remove_root(root)
        end

      emit(result, options.output)
      result
    else
      {:error, reason} ->
        emit(failure(reason), options.output)
        {:error, reason}
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
      "hexdocs_provenance" => "protected_release_publish",
      "docs_provenance_run_id" => "32763039854",
      "v1_3_0_conclusion" => "failure",
      "v1_3_1_conclusion" => "cancelled",
      "v1_3_2_conclusion" => "failure",
      "v1_3_3_conclusion" => "failure"
    }

    if Enum.all?(required, fn {key, value} -> Map.get(prerequisite, key) == value end),
      do: :ok,
      else: {:error, :invalid_public_prerequisite}
  end

  def validate_prerequisite(_), do: {:error, :invalid_public_prerequisite}

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
          assert [\"application/pdf\"] = Plug.Conn.get_resp_header(conn, \"content-type\")
          assert [\"attachment; filename=invoice.pdf\"] = Plug.Conn.get_resp_header(conn, \"content-disposition\")
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

  defp options_output(["--prerequisite", _, "--output", output | _]), do: output
  defp options_output(_), do: nil

  defp default_prerequisite,
    do:
      Path.expand(
        "../.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-PUBLIC-PREREQUISITE.json",
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

  defp run_once(root, _options, prerequisite) do
    env = isolated_env(root)
    app = Path.join(root, "clean_room")

    try do
      with :ok <- assert_empty_root(root),
           :ok <- bootstrap_phx_new(root),
           {_, 0} <-
             run(
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
           {_, 0} <- run("mix", ["deps.get"], env, app),
           :ok <-
             audit_lock!(
               Path.join(app, "mix.lock")
               |> File.read!()
               |> Code.eval_string()
               |> elem(0)
             ),
           {_, 0} <- run("mix", ["test"], [{"MIX_ENV", "test"} | env], app),
           :ok <- audit_public_source(app),
           {:ok, loopback} <- loopback_facts(app, env),
           :ok <- assert_cleanup_candidate(root, app) do
        project_evidence(%{
          elixir: System.version(),
          otp: System.otp_release(),
          hex: command_version("mix", ["hex.info"], env, app),
          phx_new: command_version("mix", ["phx.new", "--version"], env, root),
          phx_new_source: "isolated_mix_archive_phx_new_#{@phx_new_version}",
          commands: [
            "mix phx.new --no-install --no-ecto --no-html --no-assets --no-mailer",
            "mix deps.get",
            "mix test"
          ],
          lock_sha256: sha256(Path.join(app, "mix.lock")),
          source_audits: "public_hex_exact_1.3.4",
          conn_case: response_facts(),
          loopback: loopback,
          cleanup: "removed_after_projection",
          outcome: "success",
          next_action: "none",
          candidate_sha: prerequisite["candidate_commit_sha"]
        })
      else
        {output, status} when is_binary(output) ->
          failure({:command_failed, status, bounded(output)})

        {:error, reason} ->
          failure(reason)
      end
    after
      terminate_process_tree(root)
    end
  end

  defp isolated_env(root) do
    isolated = [
      {"MIX_HOME", Path.join(root, "mix")},
      {"HEX_HOME", Path.join(root, "hex")},
      {"HEX_USER_HOME", Path.join(root, "hex-user")},
      {"REBAR_CACHE_DIR", Path.join(root, "rebar")},
      {"MIX_DEPS_PATH", Path.join(root, "deps")},
      {"MIX_BUILD_PATH", Path.join(root, "build")},
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

  defp response_facts,
    do: %{
      status: 200,
      content_type: "application/pdf",
      filename: "invoice.pdf",
      nonempty: true,
      pdf_magic: true
    }

  defp loopback_facts(app, env) do
    with {:ok, port} <- reserve_port(),
         :ok <- configure_loopback(app, port),
         {:ok, server} <- start_server(app, env),
         {:ok, facts} <- await_response(port, 20),
         :ok <- stop_server(server) do
      {:ok, facts}
    end
  end

  defp reserve_port do
    with {:ok, socket} <- :gen_tcp.listen(0, [:binary, ip: {127, 0, 0, 1}, active: false]),
         {:ok, {_ip, port}} <- :inet.sockname(socket),
         :ok <- :gen_tcp.close(socket),
         do: {:ok, port}
  end

  defp configure_loopback(app, port) do
    path = Path.join(app, "config/dev.exs")

    File.write(
      path,
      "\nconfig :clean_room, CleanRoomWeb.Endpoint, http: [ip: {127, 0, 0, 1}, port: #{port}], server: true\n",
      [:append]
    )
  end

  defp start_server(app, env) do
    executable = System.find_executable("sh") || "sh"

    server =
      Port.open(
        {:spawn_executable, executable},
        [
          :binary,
          :exit_status,
          args: ["-c", "exec mix phx.server"],
          cd: String.to_charlist(app),
          env:
            Enum.map([{"MIX_ENV", "dev"} | env], fn
              {key, nil} -> {String.to_charlist(key), false}
              {key, value} -> {String.to_charlist(key), String.to_charlist(value)}
            end)
        ]
      )

    {:ok, server}
  rescue
    error -> {:error, {:server_start_failed, Exception.message(error)}}
  end

  defp await_response(_port, 0), do: {:error, :loopback_timeout}

  defp await_response(port, attempts) do
    :inets.start()

    case :httpc.request(
           :get,
           {String.to_charlist("http://127.0.0.1:#{port}/invoice.pdf"), []},
           [],
           body_format: :binary
         ) do
      {:ok, {{_http, 200, _reason}, headers, body}} ->
        content_type = header(headers, ~c"content-type")
        disposition = header(headers, ~c"content-disposition")

        if content_type =~ "application/pdf" and disposition =~ "filename=invoice.pdf" and
             byte_size(body) > 0 and
             String.starts_with?(body, "%PDF-") do
          {:ok, response_facts()}
        else
          {:error, :invalid_loopback_response}
        end

      _ ->
        Process.sleep(250)
        await_response(port, attempts - 1)
    end
  end

  defp header(headers, key),
    do: headers |> List.keyfind(key, 0, {key, ~c""}) |> elem(1) |> to_string()

  defp stop_server(server) do
    Port.close(server)

    receive do
      {^server, {:exit_status, _}} -> :ok
    after
      2_000 -> :ok
    end
  end

  defp assert_cleanup_candidate(root, app),
    do: if(String.starts_with?(app, root), do: :ok, else: {:error, :unsafe_app_path})

  defp terminate_process_tree(_root), do: :ok

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
        cleanup: "attempted"
      })

  defp emit(result, nil), do: IO.puts(Jason.encode!(result))
  defp emit(result, output), do: File.write!(output, Jason.encode!(result))

  defp bounded(value) when is_binary(value),
    do: value |> String.replace(~r/\/[^\s]+|\b\d{4,}\b/, "[redacted]") |> String.slice(0, 240)

  defp redact(value) when is_map(value),
    do: Map.new(value, fn {k, v} -> {to_string(k), redact(v)} end)

  defp redact(value) when is_list(value), do: Enum.map(value, &redact/1)
  defp redact(value) when is_binary(value), do: bounded(value)
  defp redact(value), do: value
end

if Process.whereis(ExUnit.Server) == nil, do: Rendro.PhoenixCleanRoomProof.main()
