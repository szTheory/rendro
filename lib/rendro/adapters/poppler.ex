defmodule Rendro.Adapters.Poppler do
  @moduledoc """
  External binary adapter for Poppler's pdfinfo tool.
  Provides structural validation of generated PDF files.
  """

  @doc """
  Validates a PDF file at the given path using `pdfinfo`.

  Returns `{:ok, metadata_map}` on success.
  Returns `{:error, {:invalid_pdf, reason}}` if the PDF is invalid.
  Returns `{:error, {:missing_executable, "pdfinfo"}}` if `pdfinfo` is not installed.
  """
  def validate(file_path, opts \\ []) do
    case find_executable() do
      nil ->
        {:error, {:missing_executable, "pdfinfo"}}

      executable ->
        case run_command(executable, pdfinfo_args(file_path, opts)) do
          {:ok, output} ->
            {:ok, parse_output(output)}

          {:error, {:pdfinfo_failed, exit_code, output}} ->
            {:error, {:invalid_pdf, classify_failure(output, exit_code, opts)}}

          {:error, {:command_failed, _error_module}} ->
            {:error, {:invalid_pdf, :tool_failure}}
        end
    end
  end

  defp find_executable do
    finder = Application.get_env(:rendro, :pdfinfo_executable_finder, &System.find_executable/1)
    finder.("pdfinfo")
  end

  defp run_command(executable, args) do
    runner = Application.get_env(:rendro, :pdfinfo_command_runner, &System.cmd/3)

    try do
      case runner.(executable, args, stderr_to_stdout: true) do
        {output, 0} -> {:ok, output}
        {output, exit_code} -> {:error, {:pdfinfo_failed, exit_code, output}}
      end
    rescue
      error -> {:error, {:command_failed, error.__struct__}}
    end
  end

  defp pdfinfo_args(file_path, opts) do
    password_args(opts) ++ [file_path]
  end

  defp password_args(opts) do
    cond do
      present_password?(Keyword.get(opts, :open_password)) ->
        ["-upw", Keyword.get(opts, :open_password)]

      present_password?(Keyword.get(opts, :owner_password)) ->
        ["-opw", Keyword.get(opts, :owner_password)]

      true ->
        []
    end
  end

  defp present_password?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_password?(_value), do: false

  defp parse_output(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [key, value] ->
          Map.put(acc, String.trim(key), String.trim(value))

        _ ->
          acc
      end
    end)
  end

  defp classify_failure(output, exit_code, opts) do
    text = output |> to_string() |> String.trim() |> String.downcase()

    password_supplied? =
      present_password?(Keyword.get(opts, :open_password)) or
        present_password?(Keyword.get(opts, :owner_password))

    cond do
      password_required?(text, password_supplied?) -> :password_required
      incorrect_password?(text, password_supplied?) -> :incorrect_password
      structural_invalidity?(text) -> :structural_invalidity
      exit_code in [1, 2, 3, 99] -> :tool_failure
      true -> :tool_failure
    end
  end

  defp password_required?(text, password_supplied?) do
    not password_supplied? and
      String.contains?(text, "password") and
      (String.contains?(text, "encrypted") or
         String.contains?(text, "required") or
         String.contains?(text, "needed") or
         String.contains?(text, "incorrect password"))
  end

  defp incorrect_password?(text, password_supplied?) do
    password_supplied? and
      (String.contains?(text, "incorrect password") or
         String.contains?(text, "wrong password"))
  end

  defp structural_invalidity?(text) do
    Enum.any?(
      [
        "not a pdf",
        "couldn't read xref table",
        "could not read xref table",
        "couldn't find trailer dictionary",
        "could not find trailer dictionary",
        "syntax error",
        "damaged",
        "invalid xref",
        "malformed",
        "invalid pdf"
      ],
      &String.contains?(text, &1)
    )
  end
end
