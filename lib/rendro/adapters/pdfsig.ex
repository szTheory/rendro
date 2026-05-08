defmodule Rendro.Adapters.Pdfsig do
  @moduledoc """
  External binary adapter for Poppler's `pdfsig` tool.

  This adapter validates that a PDF exposes one or more signatures and reports
  cryptographic-signature posture separately from certificate trust.
  """

  @doc """
  Validates a signed PDF at the given path using `pdfsig`.

  Returns `{:ok, %{signatures: signatures}}` on success.
  Returns `{:error, {:missing_executable, "pdfsig"}}` if `pdfsig` is unavailable.
  Returns `{:error, {:invalid_pdf, reason}}` if the file cannot be read or
  contains no signatures.
  """
  def validate(file_path, opts \\ []) do
    case find_executable() do
      nil ->
        {:error, {:missing_executable, "pdfsig"}}

      executable ->
        case run_command(executable, pdfsig_args(file_path, opts)) do
          {:ok, output} ->
            parse_validation(output)

          {:error, {:pdfsig_failed, exit_code, output}} ->
            case parse_validation(output) do
              {:ok, _result} = ok -> ok
              {:error, _reason} -> {:error, {:invalid_pdf, classify_failure(output, exit_code)}}
            end

          {:error, {:command_failed, _error_module}} ->
            {:error, {:invalid_pdf, :tool_failure}}
        end
    end
  end

  defp find_executable do
    finder = Application.get_env(:rendro, :pdfsig_executable_finder, &System.find_executable/1)
    finder.("pdfsig")
  end

  defp run_command(executable, args) do
    runner = Application.get_env(:rendro, :pdfsig_command_runner, &System.cmd/3)

    try do
      case runner.(executable, args, stderr_to_stdout: true) do
        {output, 0} -> {:ok, output}
        {output, exit_code} -> {:error, {:pdfsig_failed, exit_code, output}}
      end
    rescue
      error -> {:error, {:command_failed, error.__struct__}}
    end
  end

  defp pdfsig_args(file_path, opts) do
    cert_mode =
      if Keyword.get(opts, :skip_certificate_validation, true),
        do: ["-nocert"],
        else: []

    cert_mode ++ [file_path]
  end

  defp parse_validation(output) do
    signatures =
      output
      |> String.split(~r/\n(?=Signature #\d+:)/, trim: true)
      |> Enum.filter(&String.starts_with?(&1, "Signature #"))
      |> Enum.map(&parse_signature_block/1)

    if signatures == [] do
      {:error, {:invalid_pdf, :no_signatures}}
    else
      {:ok, %{signatures: signatures}}
    end
  end

  defp parse_signature_block(block) do
    trust =
      if String.contains?(String.downcase(block), "certificate validation:") do
        classify_status(capture(block, ~r/Certificate Validation:\s*(.+)/))
      else
        :skipped
      end

    %{
      field: capture(block, ~r/Signature Field Name:\s*(.+)/),
      total_document_signed: String.contains?(block, "Total document signed"),
      integrity: classify_status(capture(block, ~r/Signature Validation:\s*(.+)/)),
      trust: trust
    }
  end

  defp capture(block, regex) do
    case Regex.run(regex, block, capture: :all_but_first) do
      [value] -> String.trim(value)
      _ -> nil
    end
  end

  defp classify_status(nil), do: nil

  defp classify_status(status) do
    text = String.downcase(status)

    cond do
      String.contains?(text, "isn't trusted") ->
        :untrusted

      String.contains?(text, "valid") and not String.contains?(text, "invalid") ->
        :valid

      String.contains?(text, "invalid") ->
        :invalid

      true ->
        :unknown
    end
  end

  defp classify_failure(output, exit_code) do
    text = output |> to_string() |> String.trim() |> String.downcase()

    cond do
      String.contains?(text, "couldn't read xref table") -> :structural_invalidity
      String.contains?(text, "could not read xref table") -> :structural_invalidity
      String.contains?(text, "not a pdf") -> :structural_invalidity
      String.contains?(text, "syntax error") -> :structural_invalidity
      String.contains?(text, "no signatures") -> :no_signatures
      exit_code in [1, 2, 3, 99] -> :tool_failure
      true -> :tool_failure
    end
  end
end
