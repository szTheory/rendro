defmodule Rendro.Rules.CheckIds do
  @moduledoc false

  alias Rendro.{Block, Document, Page, Row, Table}

  def check(%Document{} = doc, _root_doc) do
    errors = duplicate_ids(doc)

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end

  def check(_, _doc), do: :ok

  defp duplicate_ids(%Document{} = doc) do
    doc
    |> collect_ids()
    |> duplicate_strings()
    |> Enum.map(&{:duplicate_id, &1})
  end

  defp collect_ids(%Document{pages: pages}) do
    Enum.flat_map(pages, &collect_page_ids/1)
  end

  defp collect_page_ids(%Page{blocks: blocks}) do
    Enum.flat_map(blocks, &collect_block_ids/1)
  end

  defp collect_block_ids(%Block{id: id, content: %Table{} = table}) do
    table_ids = collect_row_ids(table.header) ++
      Enum.flat_map(table.rows, &collect_row_ids/1)

    if valid_identity?(id) do
      [id | table_ids]
    else
      table_ids
    end
  end

  defp collect_block_ids(%Block{id: id}) do
    if valid_identity?(id), do: [id], else: []
  end

  defp collect_block_ids(_), do: []

  defp collect_row_ids(nil), do: []

  defp collect_row_ids(%Row{cells: cells}) do
    Enum.flat_map(cells, fn %Rendro.Cell{content: block} -> collect_block_ids(block) end)
  end

  defp duplicate_strings(values) do
    values
    |> Enum.group_by(& &1)
    |> Enum.filter(fn {_value, grouped} -> length(grouped) > 1 end)
    |> Enum.map(fn {value, _grouped} -> value end)
    |> Enum.sort()
  end

  defp valid_identity?(value), do: is_binary(value) and byte_size(value) > 0
end
