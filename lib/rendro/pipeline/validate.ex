defmodule Rendro.Pipeline.Validate do
  @moduledoc """
  Trailing post-render checks for the Rendro pipeline.

  Three checks run in order:

  1. **Structural sanity** — the rendered binary starts with `%PDF-` and contains `%%EOF`.
  2. **Page-count parity** — the PDF's `/Type /Pages /Count N` matches `length(doc.pages)`.
  3. **`:max_bytes` policy** — `byte_size(pdf) <= policies[:max_bytes]` when set.

  `Validate.run/2` is identity-on-success: the input binary is returned unchanged.
  Failure cases return bare atom reasons; the orchestrator's `span/4` wraps them
  in `%Rendro.Error{}` via `Rendro.Error.from_stage(:validate, reason, base_meta)`.
  """

  @pdf_header "%PDF-"
  @pdf_trailer "%%EOF"

  @spec run(binary(), Rendro.Document.t()) :: {:ok, binary()} | {:error, atom()}
  def run(pdf_binary, %Rendro.Document{} = doc) when is_binary(pdf_binary) do
    with :ok <- check_structural(pdf_binary),
         :ok <- check_page_count(pdf_binary, doc),
         :ok <- check_max_bytes(pdf_binary, doc) do
      {:ok, pdf_binary}
    end
  end

  defp check_structural(pdf_binary) do
    cond do
      not String.starts_with?(pdf_binary, @pdf_header) ->
        {:error, :structural_corruption}

      not String.contains?(pdf_binary, @pdf_trailer) ->
        {:error, :structural_corruption}

      true ->
        :ok
    end
  end

  defp check_page_count(pdf_binary, %Rendro.Document{pages: pages}) do
    expected = length(pages)
    actual = parse_page_count(pdf_binary)
    if actual == expected, do: :ok, else: {:error, :page_count_mismatch}
  end

  defp parse_page_count(pdf_binary) do
    case Regex.run(~r{/Type\s+/Pages.*?/Count\s+(\d+)}s, pdf_binary, capture: :all_but_first) do
      [n] -> String.to_integer(n)
      _ -> 0
    end
  end

  defp check_max_bytes(pdf_binary, %Rendro.Document{options: options}) do
    policies = Map.get(options, :policies, [])
    max_bytes = Keyword.get(policies, :max_bytes)

    cond do
      is_nil(max_bytes) -> :ok
      byte_size(pdf_binary) > max_bytes -> {:error, :max_bytes_exceeded}
      true -> :ok
    end
  end
end
