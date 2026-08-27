defmodule Mix.Tasks.Quality.Hygiene do
  use Mix.Task

  @moduledoc false
  @shortdoc "Verify repository package and evidence hygiene without authoritative writes"

  @impl Mix.Task
  def run([]) do
    Mix.Task.run("app.start")

    case Rendro.RepositoryHygiene.run() do
      :ok ->
        Mix.shell().info("Repository hygiene VERIFIED")

      {:error, diagnostics} ->
        shell = Mix.shell()
        Enum.each(diagnostics, &shell.error/1)
        exit({:shutdown, 1})
    end
  end

  def run(args), do: Mix.raise("Unexpected hygiene arguments: #{Enum.join(args, " ")}")
end
