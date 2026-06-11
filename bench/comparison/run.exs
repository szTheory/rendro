defmodule Rendro.Comparison.Runner do
  @moduledoc false

  @comparators ~w(rendro chromic_pdf chromic_pdf_warm_pool pdf_generator typst_cli)
  @required_tools [
    {"docker", ["docker"]},
    {"chrome_or_chromium", ["google-chrome", "chrome", "chromium", "chromium-browser"]},
    {"wkhtmltopdf", ["wkhtmltopdf"]},
    {"typst", ["typst"]}
  ]

  def main(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [help: :boolean, track: :string, all: :boolean, comparator: :string],
        aliases: [h: :help]
      )

    cond do
      opts[:help] ->
        IO.puts(help())
        System.halt(0)

      invalid != [] ->
        IO.puts(:stderr, "Invalid options: #{inspect(invalid)}")
        System.halt(64)

      rest != [] ->
        IO.puts(:stderr, "Unexpected arguments: #{Enum.join(rest, " ")}")
        System.halt(64)

      opts[:track] not in [nil, "normalized"] ->
        IO.puts(:stderr, "Only --track normalized is supported")
        System.halt(64)

      true ->
        run_selected(opts)
    end
  end

  defp run_selected(opts) do
    selected =
      cond do
        opts[:all] -> @comparators
        is_binary(opts[:comparator]) -> [opts[:comparator]]
        true -> []
      end

    cond do
      selected == [] ->
        IO.puts(:stderr, "Select --all or --comparator #{Enum.join(@comparators, "|")}")
        System.halt(64)

      Enum.any?(selected, &(&1 not in @comparators)) ->
        IO.puts(:stderr, "Unknown comparator. Expected one of: #{Enum.join(@comparators, ", ")}")
        System.halt(64)

      true ->
        case missing_tools() do
          [] ->
            IO.puts(
              "All required tools detected for normalized track: #{Enum.join(selected, ", ")}"
            )

            IO.puts("Benchmark execution is intentionally pinned to the project README command.")
            System.halt(0)

          missing ->
            IO.puts(:stderr, missing_tool_message(missing))
            System.halt(2)
        end
    end
  end

  defp missing_tools do
    @required_tools
    |> Enum.reject(fn {_label, candidates} -> Enum.any?(candidates, &tool_available?/1) end)
    |> Enum.map(fn {label, candidates} -> {label, candidates} end)
  end

  defp tool_available?(command) do
    case System.find_executable(command) do
      nil -> false
      path -> executable_responds?(command, path)
    end
  end

  defp executable_responds?("chrome", path), do: executable_responds?(path)
  defp executable_responds?("chromium", path), do: executable_responds?(path)
  defp executable_responds?("chromium-browser", path), do: executable_responds?(path)
  defp executable_responds?("google-chrome", path), do: executable_responds?(path)
  defp executable_responds?(_command, _path), do: true

  defp executable_responds?(path) do
    case System.cmd(path, ["--version"], stderr_to_stdout: true) do
      {_output, 0} -> true
      _other -> false
    end
  rescue
    _ -> false
  end

  defp missing_tool_message(missing) do
    details =
      missing
      |> Enum.map(fn {label, candidates} ->
        "- #{label}: tried #{Enum.join(candidates, ", ")}"
      end)
      |> Enum.join("\n")

    """
    Missing required benchmark tools for Phase 87 normalized track:
    #{details}

    Install the missing tools or run inside the pinned benchmark container, then rerun:
    elixir bench/comparison/run.exs --track normalized --all
    """
    |> String.trim()
  end

  defp help do
    """
    Rendro comparison benchmark runner

    Track:
      normalized       Fixed invoice_v1 workload used for quantitative claims

    Comparator IDs:
      #{Enum.join(@comparators, "\n      ")}

    Usage:
      elixir bench/comparison/run.exs --track normalized --all
      elixir bench/comparison/run.exs --track normalized --comparator rendro
    """
    |> String.trim()
  end
end

Rendro.Comparison.Runner.main(System.argv())
