defmodule Rendro.Phase71.SignedArtifactViewerProofFixture do
  @moduledoc false

  alias Rendro.Sign

  @fixtures_dir Path.expand("test/fixtures/signing", File.cwd!())
  @widget_fixture Path.expand("test/fixtures/signature_widget_support_fixture.pdf", File.cwd!())

  @usage """
  Usage:
    mix run scripts/signed_artifact_viewer_proof_fixture.exs --output PATH
    mix run scripts/signed_artifact_viewer_proof_fixture.exs --dry-run --output PATH

  Preconditions:
    - test/fixtures/signature_widget_support_fixture.pdf exists (run signing_viewer_proof_fixtures.exs first)
    - pyhanko available on the host
    - test/fixtures/signing/live_signer_*.pem fixtures present
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
      pem_readiness("live_signer_key.pem"),
      pem_readiness("live_signer_cert.pem"),
      pem_readiness("live_signer_passphrase.txt"),
      tool_readiness("pyhanko")
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

  defp pem_readiness(file_name) do
    path = Path.join(@fixtures_dir, file_name)

    if File.exists?(path) do
      {file_name, :ready, "Found at #{path}."}
    else
      {file_name, :blocked, "Missing #{path}."}
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
    IO.puts("Phase 71 signed-artifact viewer proof fixture")
    IO.puts("Fixture path: #{Path.expand(output_path)}")
    IO.puts("Source widget fixture: #{@widget_fixture}")
    IO.puts("Signer keys: test/fixtures/signing/live_signer_*.pem")
    IO.puts("")
    IO.puts("Preconditions:")

    Enum.each(readiness, fn {name, status, detail} ->
      IO.puts("  - #{name}: #{format_status(status)} - #{detail}")
    end)
  end

  defp format_status(:ready), do: "ready"
  defp format_status(:blocked), do: "blocked"

  defp write_fixture!(output_path) do
    File.mkdir_p!(Path.dirname(output_path))

    artifact = sample_artifact()

    {:ok, signed} =
      Sign.sign(artifact,
        field: "customer_signature",
        adapter: Rendro.Adapters.PyHanko,
        adapter_opts: [
          key: fixture_path("live_signer_key.pem"),
          cert: fixture_path("live_signer_cert.pem"),
          passfile: fixture_path("live_signer_passphrase.txt"),
          reason: "Phase 71 viewer evidence fixture"
        ]
      )

    File.write!(output_path, signed.binary)
    IO.puts("")
    IO.puts("Fixture generated successfully.")
  end

  defp fixture_path(file_name), do: Path.join(@fixtures_dir, file_name)

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

Rendro.Phase71.SignedArtifactViewerProofFixture.main(System.argv())
