defmodule Mix.Tasks.Rendro.Comparison.Check do
  use Mix.Task

  @shortdoc "Verify committed Rendro comparison benchmark evidence"

  @moduledoc """
  Verifies the committed comparison manifest and raw artifacts without rerunning
  benchmarks or launching external comparator tools.

      mix rendro.comparison.check
  """
  @moduledoc tags: [:adapter]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      [] ->
        run_check()

      _ ->
        Mix.raise("Unexpected arguments: #{Enum.join(args, " ")}")
    end
  end

  defp run_check do
    case Rendro.Comparison.check() do
      :ok ->
        Mix.shell().info("Comparison benchmark evidence VERIFIED")

      {:error, errors} ->
        shell = Mix.shell()
        Enum.each(errors, &shell.error/1)
        exit({:shutdown, 1})
    end
  end
end
