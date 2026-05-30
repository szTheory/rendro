defmodule Rendro.Inspector do
  @moduledoc """
  Deterministic layout inspector for ASCII snapshot testing.
  Provides string serialization of document structure and diagnostics.
  """
  @moduledoc tags: [:adapter]

  alias Rendro.Document

  @doc """
  Returns a multiline string representing the document layout and diagnostics.
  """
  @spec inspect(Document.t()) :: String.t()
  def inspect(%Document{} = doc) do
    pages_out =
      doc.pages
      |> Enum.with_index(1)
      |> Enum.map(fn {page, index} ->
        format_page(page, index)
      end)
      |> Enum.join("\n")

    if doc.diagnostics == [] do
      pages_out
    else
      diagnostics_out =
        doc.diagnostics
        |> Enum.map(&format_diagnostic/1)
        |> Enum.join("\n")

      "#{pages_out}\n\nDiagnostics:\n#{diagnostics_out}"
    end
  end

  defp format_page(page, index) do
    header = "Page #{index} (#{format_number(page.width)}x#{format_number(page.height)})"

    blocks =
      page.blocks
      |> Enum.map(&format_block/1)
      |> Enum.join("\n")

    if blocks == "" do
      header
    else
      "#{header}\n#{blocks}"
    end
  end

  defp format_block(block) do
    type =
      case block.content do
        %struct{} -> struct |> Module.split() |> List.last()
        binary when is_binary(binary) -> "String"
        _ -> "Unknown"
      end

    "├── Block: #{type} (x: #{format_number(block.x)}, y: #{format_number(block.y)}, w: #{format_number(block.width)}, h: #{format_number(block.height)})"
  end

  defp format_diagnostic(diag) do
    details =
      case Map.get(diag, :message) do
        nil ->
          diag
          |> diagnostic_details()
          |> Enum.join(", ")

        message ->
          to_string(message)
      end

    "- [#{diag.level}] #{diag.type}: #{details}"
  end

  defp diagnostic_details(diag) do
    [:keep_rule, :page_index, :reason]
    |> Enum.flat_map(fn key ->
      case Map.fetch(diag, key) do
        {:ok, value} -> ["#{key}=#{value}"]
        :error -> []
      end
    end)
  end

  defp format_number(nil), do: "nil"
  defp format_number(num) when is_integer(num), do: to_string(num)

  defp format_number(num) when is_float(num) do
    num
    |> :erlang.float_to_binary(decimals: 2)
    |> String.replace(~r/\.00$/, "")
    |> String.replace(~r/(\.\d)0$/, "\\1")
  end
end
