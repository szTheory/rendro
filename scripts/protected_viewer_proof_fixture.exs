defmodule Rendro.Phase54.ProtectedViewerProofFixture do
  alias Rendro.Protect

  @open_password "open-secret"
  @owner_password "owner-secret"
  @usage """
  Usage:
    mix run scripts/protected_viewer_proof_fixture.exs --output PATH
    mix run scripts/protected_viewer_proof_fixture.exs --dry-run --output PATH

  Preconditions:
    - Accepted Phase 52 completion for the real protected-fixture path
    - qpdf available on the host
    - pdfinfo available on the host
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

  defp print_usage do
    IO.puts(@usage)
  end

  defp readiness do
    [
      phase52_readiness(),
      tool_readiness("qpdf"),
      tool_readiness("pdfinfo")
    ]
  end

  defp phase52_readiness do
    state_path = Path.expand(".planning/STATE.md")

    cond do
      not File.exists?(state_path) ->
        {"Phase 52 acceptance", :blocked,
         "STATE.md missing; confirm accepted Phase 52 completion before manual proof."}

      true ->
        state = File.read!(state_path)

        if phase52_pending?(state) do
          {"Phase 52 acceptance", :blocked,
           "STATE.md still marks Phase 52 as incomplete; do not run viewer proof yet."}
        else
          {"Phase 52 acceptance", :ready,
           "No pending Phase 52 marker detected in STATE.md."}
        end
    end
  end

  defp phase52_pending?(state) do
    String.contains?(state, "Phase: 52") or
      String.contains?(state, "52-01 / 52-02 pending") or
      String.contains?(state, "Phase 52 remains the next incomplete dependency")
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
    IO.puts("Phase 54 representative protected fixture")
    IO.puts("Fixture path: #{Path.expand(output_path)}")
    IO.puts("Fixture name: #{Path.basename(output_path)}")
    IO.puts("Open password: #{@open_password}")
    IO.puts("Owner password: #{@owner_password} (observation-only; do not record in validation notes)")
    IO.puts("Advisory permissions: [] (manual proof should verify print/copy restrictions observationally)")
    IO.puts("")
    IO.puts("Preconditions:")

    Enum.each(readiness, fn {name, status, detail} ->
      IO.puts("  - #{name}: #{format_status(status)} - #{detail}")
    end)

    IO.puts("")
    IO.puts("Checklist fields for 54-VALIDATION.md:")
    IO.puts("  - opens_with_open_password")
    IO.puts("  - displays_authored_content_correctly")
    IO.puts("  - advisory_print_behavior")
    IO.puts("  - advisory_copy_behavior")
    IO.puts("  - save_and_reopen_readability")
  end

  defp format_status(:ready), do: "ready"
  defp format_status(:blocked), do: "blocked"

  defp write_fixture!(output_path) do
    File.mkdir_p!(Path.dirname(output_path))

    {:ok, artifact} = Rendro.render_to_artifact(sample_document(), deterministic: true)

    {:ok, protected} =
      Protect.password(artifact,
        open_password: @open_password,
        owner_password: @owner_password,
        advisory_permissions: []
      )

    File.write!(output_path, protected.binary)
    IO.puts("")
    IO.puts("Fixture generated successfully.")
  end

  defp sample_document do
    Rendro.fixed([
      Rendro.page(
        blocks: [
          Rendro.block(
            Rendro.text("Protected validation", size: 12),
            x: 36,
            y: 72
          ),
          Rendro.block(
            Rendro.text("Phase 54 viewer proof fixture", size: 10),
            x: 36,
            y: 96
          )
        ]
      )
    ])
  end
end

Rendro.Phase54.ProtectedViewerProofFixture.main(System.argv())
