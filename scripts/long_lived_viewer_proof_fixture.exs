defmodule Rendro.Phase71.LongLivedViewerProofFixture do
  @moduledoc false

  alias Rendro.Sign

  @fixtures_dir Path.expand("test/fixtures/signing", File.cwd!())
  @certomancer_dir Path.join(@fixtures_dir, "certomancer")
  @widget_fixture Path.expand("test/fixtures/signature_widget_support_fixture.pdf", File.cwd!())

  @usage """
  Usage:
    mix run scripts/long_lived_viewer_proof_fixture.exs --output PATH
    mix run scripts/long_lived_viewer_proof_fixture.exs --dry-run --output PATH

  Preconditions:
    - test/fixtures/signature_widget_support_fixture.pdf exists
    - certomancer, pyhanko, and pdfsig available on the host
    - test/fixtures/signing/certomancer/ offline PKI fixtures present
  """

  def main(argv) do
    {opts, args, invalid} =
      OptionParser.parse(argv,
        strict: [output: :string, dry_run: :boolean, help: :boolean],
        aliases: [o: :output, h: :help]
      )

    cond do
      invalid != [] ->
        print_invalid_options(invalid)
        exit({:shutdown, 1})

      args != [] ->
        IO.puts(:stderr, "Unexpected positional arguments: #{Enum.join(args, " ")}")
        print_usage()
        exit({:shutdown, 1})

      opts[:help] ->
        print_usage()

      is_nil(opts[:output]) ->
        IO.puts(:stderr, "--output PATH is required")
        print_usage()
        exit({:shutdown, 1})

      opts[:dry_run] ->
        print_summary(opts[:output], readiness())

      true ->
        ready = readiness()
        print_summary(opts[:output], ready)

        case blocking_prerequisites(ready) do
          [] ->
            write_fixture!(opts[:output])

          blockers ->
            IO.puts(:stderr, "")
            IO.puts(:stderr, "Blocked prerequisites:")
            Enum.each(blockers, &IO.puts(:stderr, "  - #{&1}"))
            exit({:shutdown, 1})
        end
    end
  end

  defp print_invalid_options(invalid) do
    rendered =
      Enum.map_join(invalid, ", ", fn {name, value} ->
        "--#{name}=#{inspect(value)}"
      end)

    IO.puts(:stderr, "Invalid options: #{rendered}")
    print_usage()
  end

  defp print_usage, do: IO.puts(@usage)

  defp readiness do
    [
      fixture_readiness(@widget_fixture, "signature_widget_support_fixture.pdf"),
      certomancer_readiness(),
      tool_readiness("pyhanko"),
      tool_readiness("pdfsig")
    ]
  end

  defp fixture_readiness(path, label) do
    if File.exists?(path) do
      {label, :ready, "Found at #{path}."}
    else
      {label, :blocked,
       "Missing #{path}; run mix run scripts/signing_viewer_proof_fixtures.exs first."}
    end
  end

  defp certomancer_readiness do
    config = Path.join(@certomancer_dir, "certomancer.yml")

    if File.exists?(config) do
      {"certomancer PKI", :ready, "Found config at #{config}."}
    else
      {"certomancer PKI", :blocked, "Missing #{config}."}
    end
  end

  defp tool_readiness(tool) do
    case System.find_executable(tool) do
      nil -> {tool, :blocked, "#{tool} is not installed on this host."}
      path -> {tool, :ready, "#{tool} detected at #{path}."}
    end
  end

  defp blocking_prerequisites(readiness) do
    readiness
    |> Enum.filter(fn {_name, status, _detail} -> status == :blocked end)
    |> Enum.map(fn {name, _status, detail} -> "#{name}: #{detail}" end)
  end

  defp print_summary(output_path, readiness) do
    IO.puts("Phase 71 long-lived signed-artifact viewer proof fixture")
    IO.puts("Fixture path: #{Path.expand(output_path)}")
    IO.puts("Source widget fixture: #{@widget_fixture}")
    IO.puts("PKI chain: test/fixtures/signing/certomancer/")
    IO.puts("")
    IO.puts("Preconditions:")

    Enum.each(readiness, fn {name, status, detail} ->
      IO.puts("  - #{name}: #{format_status(status)} - #{detail}")
    end)
  end

  defp format_status(:ready), do: "ready"
  defp format_status(:blocked), do: "blocked"

  defp write_fixture!(output_path) do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "rendro-long-lived-viewer-proof-#{System.unique_integer([:positive, :monotonic])}"
      )

    File.mkdir_p!(tmp_dir)
    File.mkdir_p!(Path.dirname(output_path))

    port_number = available_port()
    service_url_prefix = "http://127.0.0.1:#{port_number}"
    certs_dir = Path.join(tmp_dir, "certs")

    {certomancer_pid, certomancer_log} =
      start_certomancer!(port_number, service_url_prefix, tmp_dir)

    try do
      wait_for_certomancer!(service_url_prefix, certomancer_log)
      export_certificates!(service_url_prefix, certs_dir)

      passfile = Path.join(tmp_dir, "signer-passphrase.txt")
      File.write!(passfile, "secret")

      artifact = sample_artifact()

      {:ok, signed} =
        Sign.sign(artifact,
          field: "customer_signature",
          adapter: Rendro.Adapters.PyHanko,
          adapter_opts: [
            key: certomancer_key_path("signer.key.pem"),
            cert: Path.join(certs_dir, "signer1-long.cert.pem"),
            passfile: passfile,
            chain: [Path.join(certs_dir, "interm.cert.pem")]
          ]
        )

      {:ok, augmented} =
        Sign.augment(signed,
          adapter: Rendro.Adapters.PyHanko,
          adapter_opts: [
            tsa_url: "#{service_url_prefix}/testing-ca/tsa/tsa",
            trust_roots: [Path.join(certs_dir, "root.cert.pem")],
            other_certs: [Path.join(certs_dir, "interm.cert.pem")]
          ]
        )

      File.write!(output_path, augmented.binary)
      IO.puts("")
      IO.puts("Fixture generated successfully.")
    after
      System.cmd("kill", ["-TERM", Integer.to_string(certomancer_pid)], stderr_to_stdout: true)
      File.rm_rf(tmp_dir)
    end
  end

  defp start_certomancer!(port_number, service_url_prefix, tmp_dir) do
    executable = System.find_executable("certomancer") || raise "certomancer not found"
    log_path = Path.join(tmp_dir, "certomancer.log")
    config = Path.join(@certomancer_dir, "certomancer.yml")

    command =
      [
        shell_quote(executable),
        "--config",
        shell_quote(config),
        "--key-root",
        shell_quote(@certomancer_dir),
        "--service-url-prefix",
        shell_quote(service_url_prefix),
        "animate",
        "--port",
        Integer.to_string(port_number),
        "--no-web-ui"
      ]
      |> Enum.join(" ")

    {pid, 0} =
      System.cmd("sh", [
        "-c",
        "#{command} > #{shell_quote(log_path)} 2>&1 & echo $!"
      ])

    {String.trim(pid) |> String.to_integer(), log_path}
  end

  defp export_certificates!(service_url_prefix, certs_dir) do
    config = Path.join(@certomancer_dir, "certomancer.yml")

    {_, 0} =
      System.cmd(
        System.find_executable("certomancer") || raise("certomancer not found"),
        [
          "--config",
          config,
          "--key-root",
          @certomancer_dir,
          "--service-url-prefix",
          service_url_prefix,
          "mass-summon",
          "testing-ca",
          certs_dir,
          "--flat"
        ],
        stderr_to_stdout: true
      )
  end

  defp wait_for_certomancer!(service_url_prefix, log_path) do
    :inets.start()
    :ssl.start()
    url = String.to_charlist("#{service_url_prefix}/testing-ca/certs/root/ca.crt")

    wait_until(
      fn ->
        case :httpc.request(:get, {url, []}, [], []) do
          {:ok, {{_, 200, _}, _headers, _body}} -> true
          _ -> false
        end
      end,
      50,
      log_path
    )
  end

  defp wait_until(fun, attempts_remaining, log_path) when attempts_remaining > 0 do
    if fun.() do
      :ok
    else
      Process.sleep(100)
      wait_until(fun, attempts_remaining - 1, log_path)
    end
  end

  defp wait_until(_fun, 0, log_path) do
    log =
      case File.read(log_path) do
        {:ok, contents} when contents != "" -> "\n\ncertomancer log:\n#{contents}"
        _ -> ""
      end

    raise "certomancer did not become ready before timeout#{log}"
  end

  defp available_port do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, {_ip, port_number}} = :inet.sockname(socket)
    :ok = :gen_tcp.close(socket)
    port_number
  end

  defp certomancer_key_path(file_name), do: Path.join([@certomancer_dir, "keys-rsa", file_name])

  defp shell_quote(value) do
    escaped = String.replace(value, "'", "'\"'\"'")
    "'#{escaped}'"
  end

  defp sample_artifact do
    doc =
      Rendro.fixed([
        Rendro.page(
          width: 612,
          height: 792,
          margin_left: 72,
          margin_top: 72,
          blocks: [
            Rendro.signature_field("customer_signature",
              x: 10,
              y: 20,
              width: 180,
              height: 48
            )
          ]
        )
      ])

    {:ok, artifact} = Rendro.render_to_artifact(doc, deterministic: true)
    artifact
  end
end

Rendro.Phase71.LongLivedViewerProofFixture.main(System.argv())
