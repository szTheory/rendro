defmodule Mix.Tasks.Docs.Contract do
  use Mix.Task

  @moduledoc """
  Runs the canonical docs-contract verification command.
  """
  @moduledoc tags: [:adapter]

  @shortdoc "Runs the canonical docs-contract verification command"

  def run(_args) do
    runner = Application.get_env(:rendro, :docs_contract_command_runner, &System.cmd/3)
    {output, status} = runner.("mix", ["run", "scripts/verify_docs.exs"], stderr_to_stdout: true)
    print_output(output)

    if status == 0 do
      :ok
    else
      exit({:shutdown, 1})
    end
  end

  defp print_output(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.each(fn line -> Mix.shell().info(line) end)
  end
end
