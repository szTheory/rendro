defmodule Mix.Tasks.Rendro.Catalog.Candidate do
  use Mix.Task

  @moduledoc false
  @shortdoc "Generate an isolated, candidate-only Rendro catalog bundle"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case Rendro.Catalog.generate_candidate(parse_opts(args)) do
      :ok ->
        Mix.shell().info("Generated tmp/phase130-candidate/candidate-manifest.json")

      {:error, reason} ->
        Mix.shell().error("Candidate catalog generation failed: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp parse_opts(args) do
    {opts, rest, invalid} = OptionParser.parse(args, strict: [pdfium: :string])

    if rest != [] or invalid != [],
      do:
        Mix.raise(
          "Unexpected catalog arguments: #{Enum.join(rest ++ Enum.map(invalid, &elem(&1, 0)), " ")}"
        ),
      else: opts
  end
end
