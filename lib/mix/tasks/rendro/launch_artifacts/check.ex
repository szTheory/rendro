defmodule Mix.Tasks.Rendro.LaunchArtifacts.Check do
  use Mix.Task

  @shortdoc "Verify Rendro launch gallery/manual artifacts"

  @moduledoc """
  Regenerates launch artifact hashes and compares them to
  `assets/rendro/artifacts.json` without writing repo files.

      mix rendro.launch_artifacts.check
      mix rendro.launch_artifacts.check --pdfium /path/to/pdfium

  The check requires `pdfium-cli` on PATH, or `RENDRO_PDFIUM_CLI`.
  """
  @moduledoc tags: [:adapter]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_opts(args)

    case Rendro.LaunchArtifacts.check(opts) do
      :ok ->
        Mix.shell().info("Launch artifacts VERIFIED")

      {:error, errors} ->
        shell = Mix.shell()
        Enum.each(errors, &shell.error/1)
        exit({:shutdown, 1})
    end
  end

  defp parse_opts(args) do
    {opts, rest, _invalid} = OptionParser.parse(args, strict: [pdfium: :string])

    case rest do
      [] -> opts
      _ -> Mix.raise("Unexpected arguments: #{Enum.join(rest, " ")}")
    end
  end
end
