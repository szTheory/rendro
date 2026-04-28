defmodule Mix.Tasks.Verify do
  use Mix.Task

  @moduledoc """
  Runs full verification suite with deterministic and advisory lanes.
  """

  @shortdoc "Runs full verification suite with deterministic and advisory lanes"

  def run(_args) do
    case run_with_lanes() do
      {:ok, _results} -> :ok
      {:error, _results} -> exit({:shutdown, 1})
    end
  end

  def run_with_lanes(lanes \\ verification_lanes()) do
    Mix.shell().info("=== RENDRO VERIFICATION SUITE ===")

    results =
      Enum.flat_map(lanes, fn {lane_name, steps} ->
        Mix.shell().info("\n[LANE: #{lane_name}]")

        Enum.map(steps, fn {step_name, fun} ->
          run_step(lane_name, step_name, fun)
        end)
      end)

    print_summary(results)

    if Enum.any?(results, &(&1.status == :fail)) do
      {:error, results}
    else
      {:ok, results}
    end
  end

  defp verification_lanes do
    [
      {"DETERMINISTIC (CORE)",
       [
         {"CI", fn -> Mix.Task.run("ci") end},
         {"Docs Contract", fn -> Mix.Task.run("run", ["scripts/verify_docs.exs"]) end}
       ]},
      {"ADVISORY (ADAPTERS)",
       [
         {"Phoenix Example", &verify_phoenix_example/0}
       ]}
    ]
  end

  defp run_step(lane_name, step_name, fun) do
    Mix.shell().info("Running #{step_name}...")

    result =
      try do
        case fun.() do
          :ok ->
            %{lane: lane_name, step: step_name, status: :pass}

          {:error, code, output} ->
            %{lane: lane_name, step: step_name, status: :fail, code: code, output: output}

          {:error, reason} ->
            %{lane: lane_name, step: step_name, status: :fail, code: 1, output: inspect(reason)}

          _ ->
            %{lane: lane_name, step: step_name, status: :pass}
        end
      rescue
        error ->
          %{lane: lane_name, step: step_name, status: :fail, code: 1, output: Exception.message(error)}
      catch
        :exit, {:shutdown, code} when code != 0 ->
          %{lane: lane_name, step: step_name, status: :fail, code: code}

        kind, reason ->
          %{lane: lane_name, step: step_name, status: :fail, code: 1, output: "#{inspect(kind)}: #{inspect(reason)}"}
      end

    print_step_result(result)
    result
  end

  defp print_step_result(%{step: step_name, status: :pass}) do
    Mix.shell().info("  - #{step_name}: PASS")
  end

  defp print_step_result(%{step: step_name, status: :fail} = result) do
    code = Map.get(result, :code, 1)
    Mix.shell().error("  - #{step_name}: FAIL (code #{code})")

    case Map.get(result, :output) do
      output when is_binary(output) and output != "" ->
        Mix.shell().error(output)

      _ ->
        :ok
    end
  end

  defp print_summary(results) do
    Mix.shell().info("\nVERIFICATION COMPLETE")
    Mix.shell().info("Summary:")

    Enum.each(results, fn %{lane: lane_name, step: step_name, status: status} ->
      Mix.shell().info("  - [#{lane_name}] #{step_name}: #{String.upcase(to_string(status))}")
    end)

    if Enum.any?(results, &(&1.status == :fail)) do
      Mix.shell().error("Overall: FAIL")
    else
      Mix.shell().info("Overall: PASS")
    end
  end

  defp verify_phoenix_example do
    File.cd!("examples/phoenix_example", fn ->
      with :ok <- run_system_step("mix", ["deps.get"]),
           :ok <- run_system_step("mix", ["compile"]) do
        :ok
      end
    end)
  end

  defp run_system_step(command, args) do
    {output, exit_code} = System.cmd(command, args, stderr_to_stdout: true)

    if exit_code == 0 do
      :ok
    else
      {:error, exit_code, output}
    end
  end
end
