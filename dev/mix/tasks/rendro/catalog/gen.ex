defmodule Mix.Tasks.Rendro.Catalog.Gen do
  use Mix.Task
  @shortdoc "Generate bounded Rendro catalog artifacts"
  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case Rendro.Catalog.generate(parse_opts(args)) do
      :ok ->
        Mix.shell().info("Generated #{Rendro.Catalog.manifest_path()}")

      {:error, reason} ->
        Mix.shell().error("Catalog generation failed: #{inspect(reason)}")
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
