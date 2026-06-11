defmodule Mix.Tasks.Rendro.LaunchArtifacts.Gen do
  use Mix.Task

  @shortdoc "Generate Rendro launch gallery/manual artifacts"

  @moduledoc """
  Generates the public launch artifact set:

    * `assets/rendro/gallery/*.png`
    * `assets/rendro/manual.pdf`
    * `assets/rendro/artifacts.json`
    * generated README and recipes-guide blocks

  The task requires `pdfium-cli` on PATH, or pass a binary path:

      mix rendro.launch_artifacts.gen --pdfium /path/to/pdfium

  You may also set `RENDRO_PDFIUM_CLI=/path/to/pdfium`.
  """
  @moduledoc tags: [:adapter]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_opts(args)

    case Rendro.LaunchArtifacts.generate(opts) do
      :ok ->
        Mix.shell().info("Generated #{Rendro.LaunchArtifacts.manifest_path()}")

      {:error, reason} ->
        Mix.shell().error("Launch artifact generation failed: #{inspect(reason)}")
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
