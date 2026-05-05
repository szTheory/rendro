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
  def validate(file_path) do
    case System.find_executable("pdfinfo") do
      nil ->
        {:error, {:missing_executable, "pdfinfo"}}

      executable ->
        case System.cmd(executable, [file_path], stderr_to_stdout: true) do
          {output, 0} ->
            {:ok, parse_output(output)}

          {output, _exit_code} ->
            {:error, {:invalid_pdf, String.trim(output)}}
        end
    end
  end

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
end
