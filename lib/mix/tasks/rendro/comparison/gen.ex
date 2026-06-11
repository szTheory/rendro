defmodule Mix.Tasks.Rendro.Comparison.Gen do
  use Mix.Task

  @shortdoc "Generate Rendro comparison benchmark artifacts"

  @moduledoc """
  Generates comparison benchmark artifacts.

  The normal path is the pinned reproduction command documented in
  `bench/comparison/README.md`. `--skip-external` is a development-only mode for
  re-encoding the current non-public static scaffold; it refuses to publish a
  manifest with public claims.

      mix rendro.comparison.gen --skip-external
  """
  @moduledoc tags: [:adapter]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_opts(args)

    case Rendro.Comparison.generate(opts) do
      :ok ->
        Mix.shell().info("Generated #{Rendro.Comparison.manifest_path()}")

      {:error, errors} when is_list(errors) ->
        shell = Mix.shell()
        Enum.each(errors, &shell.error/1)
        exit({:shutdown, 1})
    end
  end

  defp parse_opts(args) do
    {opts, rest, _invalid} = OptionParser.parse(args, strict: [skip_external: :boolean])

    case rest do
      [] -> opts
      _ -> Mix.raise("Unexpected arguments: #{Enum.join(rest, " ")}")
    end
  end
end
