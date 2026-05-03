defmodule Rendro.Pipeline.Validate do
  @moduledoc false

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
    # PDF dict entries can appear in any order; in deterministic mode the writer
    # sorts keys alphabetically (so /Count precedes /Type). Try both orderings
    # within the same enclosing object before declaring a mismatch.
    cond do
      result = match_count_after_pages(pdf_binary) -> result
      result = match_count_before_pages(pdf_binary) -> result
      true -> 0
    end
  end

  defp match_count_after_pages(pdf_binary) do
    case Regex.run(~r{/Type\s+/Pages.*?/Count\s+(\d+)}s, pdf_binary, capture: :all_but_first) do
      [n] -> String.to_integer(n)
      _ -> nil
    end
  end

  defp match_count_before_pages(pdf_binary) do
    # Capture /Count N followed (within the same object dict, so before the next ">>")
    # by /Type /Pages. The negated set [^>] keeps the lazy traversal bounded to one
    # dict body — adversarial input with no ">>" cannot expand the match window.
    case Regex.run(~r{/Count\s+(\d+)[^>]*?/Type\s+/Pages}s, pdf_binary, capture: :all_but_first) do
      [n] -> String.to_integer(n)
      _ -> nil
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
