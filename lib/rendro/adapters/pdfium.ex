defmodule Rendro.Adapters.Pdfium do
  @moduledoc """
  Optional runtime adapter for [pdfium-cli](https://github.com/klippa-app/pdfium-cli).

  pdfium-cli is an external executable, not a Hex dependency. Rendro uses it only for
  automatable viewer-evidence observation (`viewer_kind: pdfium-cli`), not for core rendering.
  """

  @type form_field :: %{
          optional(String.t()) => term()
        }

  @doc """
  Returns PDF metadata from `pdfium info`.

  On success returns `{:ok, metadata_map}` with string keys (for example `"PDF Version"`).
  """
  @spec info(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def info(file_path, opts \\ []) do
    with {:ok, executable} <- find_executable(),
         {:ok, output} <- run_command(executable, info_args(file_path, opts)) do
      {:ok, parse_info_output(output)}
    end
  end

  @doc """
  Returns form field observations from `pdfium form --output-type json`.
  """
  @spec form_fields(String.t(), keyword()) :: {:ok, [form_field()]} | {:error, term()}
  def form_fields(file_path, opts \\ []) do
    with {:ok, executable} <- find_executable(),
         {:ok, output} <-
           run_command(executable, form_args(file_path, opts) ++ ["-"]) do
      decode_form_json(output)
    end
  end

  @doc """
  Returns the pdfium-cli version string (for example `"v0.10.3"`).
  """
  @spec version(keyword()) :: {:ok, String.t()} | {:error, term()}
  def version(opts \\ []) do
    with {:ok, executable} <- find_executable(),
         {:ok, output} <- run_command(executable, ["--version"], opts) do
      version =
        output
        |> String.trim()
        |> String.replace_prefix("pdfium version ", "")

      {:ok, version}
    end
  end

  defp find_executable do
    finder =
      Application.get_env(:rendro, :pdfium_cli_executable_finder, &default_finder/1)

    case finder.("pdfium-cli") || finder.("pdfium") do
      nil -> {:error, {:missing_executable, "pdfium-cli"}}
      executable -> {:ok, executable}
    end
  end

  defp default_finder(name), do: System.find_executable(name)

  defp info_args(file_path, opts) do
    password_args(opts) ++ ["info", file_path]
  end

  defp form_args(file_path, opts) do
    password_args(opts) ++ ["form", file_path, "--output-type", "json"]
  end

  defp password_args(opts) do
    case Keyword.get(opts, :password) do
      password when is_binary(password) and password != "" -> ["-p", password]
      _ -> []
    end
  end

  defp run_command(executable, args, opts \\ []) do
    runner = Application.get_env(:rendro, :pdfium_cli_command_runner, &System.cmd/3)
    cmd_opts = Keyword.get(opts, :cmd_opts, stderr_to_stdout: true)

    try do
      case runner.(executable, args, cmd_opts) do
        {output, 0} -> {:ok, output}
        {output, exit_code} -> {:error, {:pdfium_cli_failed, exit_code, output}}
      end
    rescue
      error -> {:error, {:command_failed, error.__struct__}}
    end
  end

  defp parse_info_output(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [key, value] -> Map.put(acc, String.trim(key), String.trim(value))
        _ -> acc
      end
    end)
  end

  defp decode_form_json(output) do
    case JSON.decode(output) do
      {:ok, %{"Fields" => fields}} when is_list(fields) ->
        {:ok, fields}

      {:ok, _} ->
        {:error, {:invalid_form_json, "missing Fields array"}}

      {:error, reason} ->
        {:error, {:invalid_form_json, reason}}
    end
  end
end
