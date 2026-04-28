defmodule Rendro.Pipeline.Paginate do
  @moduledoc """
  Assigns content to pages respecting page boundaries, then stacks y-coordinates.

  For the fixed-position API, blocks are already on explicit pages; this stage
  validates fit and applies y-stacking per page. For the flow API, content is
  split across pages (with table-row repeating headers) and then y-coordinates
  are computed against each page's `margin_top` — never inheriting from the
  previous page (D-04 latent bug fix).
  """

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{pages: pages, content: content} = doc) do
    cond do
      pages != [] -> {:ok, doc}
      content != [] -> paginate_flow(doc)
      true -> {:error, :no_content}
    end
  end

  defp paginate_flow(%Rendro.Document{content: content, header: h_blocks, footer: f_blocks} = doc) do
    template = %Rendro.Page{}

    header_h = Enum.sum(Enum.map(h_blocks, &(&1.height || 0)))
    footer_h = Enum.sum(Enum.map(f_blocks, &(&1.height || 0)))

    max_h = template.height - template.margin_top - template.margin_bottom - header_h - footer_h

    try do
      pages =
        content
        |> Enum.reduce([%{template | blocks: []}], fn block, pages ->
          paginate_block(block, pages, template, max_h)
        end)
        |> Enum.reverse()
        |> Enum.with_index(1)
        |> Enum.map(fn {page, idx} ->
          apply_page_template(page, idx, h_blocks, f_blocks)
        end)
        |> Enum.map(&stack_block_y/1)

      {:ok, %{doc | pages: pages, content: []}}
    catch
      {:error, :content_overflow, details} ->
        {:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}
    end
  end

  # D-04: y-stacking absorbed from Compose, applied per page with the cursor
  # reset to the page's margin_top so page-2 remainder rows never inherit y
  # from page 1. Flow-content blocks all share the Block default `y: 0`, so we
  # unconditionally assign `current_y` (matching the original `compose_page/1`
  # design at commit 093f32c, before a regression flipped the override into a
  # `block.y || current_y` fallthrough that froze every flow block at y=0).
  defp stack_block_y(%Rendro.Page{blocks: blocks, margin_top: margin_top} = page) do
    starting_y = margin_top || 0

    {stacked, _} =
      Enum.reduce(blocks, {[], starting_y}, fn block, {acc, current_y} ->
        stacked_block = stack_table_cells(%{block | y: current_y})
        next_y = current_y + (block.height || 0)
        {acc ++ [stacked_block], next_y}
      end)

    %{page | blocks: stacked}
  end

  defp stack_table_cells(%Rendro.Block{content: %Rendro.Table{} = table} = block) do
    row_height = 14.4
    col_width = 100

    header_y = block.y || 0

    stacked_header =
      if table.header, do: stack_cells(table.header, header_y, col_width), else: nil

    header_offset = if table.header, do: row_height, else: 0

    {stacked_rows, _} =
      Enum.reduce(table.rows, {[], (block.y || 0) + header_offset}, fn row, {acc, y} ->
        stacked_row = stack_cells(row, y, col_width)
        {acc ++ [stacked_row], y + row_height}
      end)

    %{block | content: %{table | header: stacked_header, rows: stacked_rows}}
  end

  defp stack_table_cells(block), do: block

  defp stack_cells(row, y, col_width) do
    {cells, _} =
      Enum.reduce(row, {[], 0}, fn cell, {acc, x} ->
        {acc ++ [%{cell | x: x, y: y}], x + col_width}
      end)

    cells
  end

  defp paginate_block(block, [current_page | rest] = _pages, template, max_h) do
    block_h = block.height || 0
    current_h = Enum.sum(Enum.map(current_page.blocks, &(&1.height || 0)))

    case block.content do
      %Rendro.Table{} = table when current_h + block_h > max_h ->
        handle_table_split(block, table, current_page, rest, template, max_h, current_h, block_h)

      _ ->
        if current_h + block_h <= max_h do
          [%{current_page | blocks: current_page.blocks ++ [block]} | rest]
        else
          check_overflow!(block_h, max_h)
          [%{template | blocks: [block]}, current_page | rest]
        end
    end
  end

  defp handle_table_split(block, table, current_page, rest, template, max_h, current_h, block_h) do
    available_h = max_h - current_h
    {this_page_table, remaining_table} = split_table(table, available_h)

    cond do
      this_page_table && remaining_table ->
        this_block = %{block | content: this_page_table, height: table_height(this_page_table)}

        remaining_block = %{
          block
          | content: remaining_table,
            height: table_height(remaining_table)
        }

        current_page = %{current_page | blocks: current_page.blocks ++ [this_block]}
        [%{template | blocks: [remaining_block]}, current_page | rest]

      remaining_table ->
        check_overflow!(block_h, max_h)
        [%{template | blocks: [block]}, current_page | rest]

      true ->
        [%{current_page | blocks: current_page.blocks ++ [block]} | rest]
    end
  end

  defp check_overflow!(block_h, max_h) do
    if block_h > max_h do
      throw({:error, :content_overflow, %{block_height: block_h, max_height: max_h}})
    end
  end

  defp apply_page_template(page, idx, h_blocks, f_blocks) do
    h = replace_page_numbers(h_blocks, idx)
    f = replace_page_numbers(f_blocks, idx)
    %{page | blocks: h ++ page.blocks ++ f}
  end

  defp replace_page_numbers(blocks, page_num) do
    Enum.map(blocks, fn block ->
      case block.content do
        %Rendro.Text{content: text} = t ->
          %{
            block
            | content: %{
                t
                | content: String.replace(text, "{{page_number}}", Integer.to_string(page_num))
              }
          }

        _ ->
          block
      end
    end)
  end

  defp table_height(%Rendro.Table{rows: rows, header: header}) do
    row_height = 14.4
    header_h = if header, do: row_height, else: 0
    header_h + length(rows) * row_height
  end

  defp split_table(%Rendro.Table{rows: rows, header: header} = table, available_h) do
    row_height = 14.4
    header_h = if header, do: row_height, else: 0

    if available_h < header_h + row_height do
      # Not even one row fits with header
      {nil, table}
    else
      # Calculate how many rows fit
      fit_count = floor((available_h - header_h) / row_height)
      split_table_rows(table, rows, fit_count)
    end
  end

  defp split_table_rows(table, _rows, fit_count) when fit_count <= 0, do: {nil, table}

  defp split_table_rows(table, rows, fit_count) do
    {this_rows, rest_rows} = Enum.split(rows, fit_count)

    case rest_rows do
      [] ->
        {table, nil}

      _ ->
        this_table = %{table | rows: this_rows}
        # Repeat header on rest
        rest_table = %{table | rows: rest_rows}
        {this_table, rest_table}
    end
  end
end
