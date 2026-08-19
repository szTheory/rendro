defmodule Mix.Tasks.Rendro.Configurator.Gen do
  use Mix.Task

  @moduledoc false
  @shortdoc "Generate or check the static Rendro configurator snippet index"
  @index_path "assets/rendro/configurator/index.json"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    check? = parse_args!(args)
    expected = Rendro.Theme.Snippet.index_json()

    if check? do
      check!(expected)
    else
      File.mkdir_p!(Path.dirname(@index_path))
      File.write!(@index_path, expected)
      Mix.shell().info("Generated #{@index_path}")
    end
  end

  defp parse_args!([]), do: false
  defp parse_args!(["--check"]), do: true

  defp parse_args!(args),
    do: Mix.raise("Unexpected configurator arguments: #{Enum.join(args, " ")}")

  defp check!(expected) do
    case File.read(@index_path) do
      {:ok, ^expected} ->
        Mix.shell().info("Configurator index is current: #{@index_path}")

      {:ok, _actual} ->
        Mix.raise("Configurator index drifted; run mix rendro.configurator.gen")

      {:error, :enoent} ->
        Mix.raise("Configurator index is missing; run mix rendro.configurator.gen")

      {:error, reason} ->
        Mix.raise("Could not read #{@index_path}: #{inspect(reason)}")
    end
  end
end
