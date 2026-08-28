defmodule Mix.Tasks.Rendro.Catalog.Gallery do
  use Mix.Task

  @moduledoc false
  @shortdoc "Build a non-authoritative visual gallery for the six changed catalog targets"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    {opts, rest, invalid} = OptionParser.parse(args, strict: [output: :string])

    if rest != [] or invalid != [] do
      Mix.raise("Unexpected catalog gallery arguments")
    end

    output = Keyword.get(opts, :output, "tmp/catalog-visual-gallery")

    case Rendro.CatalogVisualGallery.build(
           "tmp/phase130-candidate/candidate-manifest.json",
           output
         ) do
      {:ok, path} ->
        Mix.shell().info("Generated convenience-only visual gallery at #{path}/index.html")

      {:error, reason} ->
        Mix.raise("Catalog visual gallery failed: #{inspect(reason)}")
    end
  end
end
