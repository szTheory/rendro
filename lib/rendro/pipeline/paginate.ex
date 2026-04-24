defmodule Rendro.Pipeline.Paginate do
  @moduledoc """
  Assigns content to pages respecting page boundaries.

  For the fixed-position API, blocks are already assigned to explicit pages
  by the user, so this stage validates that blocks fit within the printable
  area. The flow API will use this stage to split content across pages.
  """

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{pages: pages, content: content} = doc) do
    cond do
      length(pages) > 0 -> {:ok, doc}
      length(content) > 0 -> paginate_flow(doc)
      true -> {:error, :no_content}
    end
  end

  defp paginate_flow(%Rendro.Document{content: content, header: h_blocks, footer: f_blocks} = doc) do
    # Default page template
    template = %Rendro.Page{}

    header_h = Enum.sum(Enum.map(h_blocks, &(&1.height || 0)))
    footer_h = Enum.sum(Enum.map(f_blocks, &(&1.height || 0)))

    max_h = template.height - template.margin_top - template.margin_bottom - header_h - footer_h

    try do
      pages =
        content
        |> Enum.reduce([%{template | blocks: []}], fn block, [current_page | rest] ->
          block_h = block.height || 0
          current_h = Enum.sum(Enum.map(current_page.blocks, &(&1.height || 0)))

          case block.content do
            %Rendro.Table{} = table when current_h + block_h > max_h ->
              # Table doesn't fit, try to split it
              available_h = max_h - current_h
              {this_page_table, remaining_table} = split_table(table, available_h)

              cond do
                this_page_table && remaining_table ->
                  # Split table: put part on current page, rest as new flow elements
                  this_block = %{block | content: this_page_table, height: table_height(this_page_table)}
                  remaining_block = %{block | content: remaining_table, height: table_height(remaining_table)}

                  current_page = %{current_page | blocks: current_page.blocks ++ [this_block]}
                  new_page = %{template | blocks: [remaining_block]}
                  [new_page, current_page | rest]

                remaining_table ->
                  # Didn't fit at all on current page, move to next
                  if block_h > max_h do
                    throw({:error, :content_overflow, %{block_height: block_h, max_height: max_h}})
                  end

                  new_page = %{template | blocks: [block]}
                  [new_page, current_page | rest]

                true ->
                  # Fits in current page
                  [%{current_page | blocks: current_page.blocks ++ [block]} | rest]
              end

            _ ->
              if current_h + block_h <= max_h do
                # Fits in current page
                [%{current_page | blocks: current_page.blocks ++ [block]} | rest]
              else
                # Needs new page
                if block_h > max_h do
                  throw({:error, :content_overflow, %{block_height: block_h, max_height: max_h}})
                end

                new_page = %{template | blocks: [block]}
                [new_page, current_page | rest]
              end
          end
        end)
        |> Enum.reverse()
        |> Enum.with_index(1)
        |> Enum.map(fn {page, idx} ->
          # Apply header/footer and page numbers
          h = replace_page_numbers(h_blocks, idx)
          f = replace_page_numbers(f_blocks, idx)
          %{page | blocks: h ++ page.blocks ++ f}
        end)

      {:ok, %{doc | pages: pages, content: []}}
    catch
      {:error, :content_overflow, details} ->
        {:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}
    end
  end

  defp replace_page_numbers(blocks, page_num) do
    Enum.map(blocks, fn block ->
      case block.content do
        %Rendro.Text{content: text} = t ->
          %{block | content: %{t | content: String.replace(text, "{{page_number}}", Integer.to_string(page_num))}}

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

      if fit_count <= 0 do
        {nil, table}
      else
        {this_rows, rest_rows} = Enum.split(rows, fit_count)

        if rest_rows == [] do
          {table, nil}
        else
          this_table = %{table | rows: this_rows}
          # Repeat header on rest
          rest_table = %{table | rows: rest_rows}
          {this_table, rest_table}
        end
      end
    end
  end
end
