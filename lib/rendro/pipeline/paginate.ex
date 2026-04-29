defmodule Rendro.Pipeline.Paginate do
  @moduledoc """
  Assigns content to pages respecting page boundaries, then stacks y-coordinates.

  For the fixed-position API, blocks are already on explicit pages; this stage
  validates fit and applies y-stacking per page. For the flow API, content is
  split across pages (with table-row repeating headers) and then y-coordinates
  are computed against each page's `margin_top` — never inheriting from the
  previous page (D-04 latent bug fix).
  """

  alias Rendro.{Document, Page, PageTemplate, Region}

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Document{pages: pages, content: content} = doc) do
    cond do
      pages != [] -> validate_fixed_pages(doc)
      content != [] or has_flow_layout?(doc) -> paginate_flow(doc)
      true -> {:error, :no_content}
    end
  end

  defp paginate_flow(%Document{} = doc) do
    layout = flow_layout(doc)
    template = layout.template
    page_template = page_from_template(template)
    body_blocks = Map.get(layout.region_blocks, :body, doc.content)
    max_h = layout.body_capacity

    try do
      pages =
        paginate_blocks(
          body_blocks,
          [%{page_template | blocks: []}],
          page_template,
          max_h,
          %{overflow_source: :bounded_region, region: :body}
        )
        |> Enum.reverse()
        |> Enum.with_index(1)
        |> Enum.map(fn {page, idx} ->
          page
          |> stack_body_blocks(layout.body_region)
          |> validate_body_region_fit!(layout.body_region, idx)
          |> apply_page_template(idx, layout)
        end)

      {:ok, %{doc | pages: pages, content: []}}
    catch
      {:error, :content_overflow, details} ->
        {:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}
    end
  end

  defp paginate_blocks([], pages, _template, _max_h, _overflow_details), do: pages

  defp paginate_blocks(blocks, pages, template, max_h, overflow_details) do
    {group, remaining} = next_flow_group(blocks)

    pages =
      pages
      |> maybe_break_before(template, group)
      |> place_flow_group_for(group, template, max_h, overflow_details)
      |> maybe_break_after(template, group, remaining)

    paginate_blocks(remaining, pages, template, max_h, overflow_details)
  end

  defp has_flow_layout?(%Document{options: %{layout: _layout}}), do: true
  defp has_flow_layout?(%Document{}), do: false

  # D-04: y-stacking stays page-local and now starts at the explicit body
  # region origin instead of relying on implicit page margins.
  defp stack_body_blocks(%Page{blocks: blocks} = page, %Region{} = body_region) do
    starting_y = relative_y(body_region, page)
    starting_x = relative_x(body_region, page)

    {stacked, _} =
      Enum.reduce(blocks, {[], starting_y}, fn block, {acc, current_y} ->
        stacked_block =
          block
          |> Map.put(:x, starting_x + block.x)
          |> Map.put(:y, current_y)
          |> stack_table_cells()

        next_y = current_y + (block.height || 0)
        {acc ++ [stacked_block], next_y}
      end)

    %{page | blocks: stacked}
  end

  defp stack_table_cells(%Rendro.Block{content: %Rendro.Table{} = table} = block) do
    header_y = block.y || 0
    start_x = block.x || 0
    col_widths = table.column_widths || []

    stacked_header =
      if table.header, do: stack_cells(table.header, start_x, header_y, col_widths), else: nil

    header_offset = table.header_height || 0

    {stacked_rows, _} =
      Enum.reduce(Enum.zip(table.rows, table.row_heights || []), {[], header_y + header_offset}, fn {row, row_h}, {acc, y} ->
        stacked_row = stack_cells(row, start_x, y, col_widths)
        {acc ++ [stacked_row], y + row_h}
      end)

    %{block | content: %{table | header: stacked_header, rows: stacked_rows}}
  end

  defp stack_table_cells(block), do: block

  defp stack_cells(row, start_x, y, col_widths) do
    {cells, _} =
      Enum.reduce(Enum.zip(row, col_widths), {[], start_x}, fn {cell, col_w}, {acc, x} ->
        # Cell already has its width set by Measure, but its x needs stacking
        {acc ++ [%{cell | x: x, y: y}], x + col_w}
      end)

    cells
  end

  defp paginate_block(block, [current_page | rest] = _pages, template, max_h, overflow_details) do
    block_h = block.height || 0
    current_h = Enum.sum(Enum.map(current_page.blocks, &(&1.height || 0)))
    failure_details =
      Map.merge(overflow_details, %{
        page_index: length(rest) + 1,
        block_index: length(current_page.blocks)
      })

    case block.content do
      %Rendro.Table{} = table when current_h + block_h > max_h ->
        handle_table_split(
          block,
          table,
          current_page,
          rest,
          template,
          max_h,
          current_h,
          block_h,
          failure_details
        )

      _ ->
        if current_h + block_h <= max_h do
          [%{current_page | blocks: current_page.blocks ++ [block]} | rest]
        else
          check_overflow!(block, block_h, max_h, failure_details)
          [%{template | blocks: [block]}, current_page | rest]
        end
    end
  end

  defp place_flow_group_for(pages, group, template, max_h, overflow_details) do
    place_flow_group(group, pages, template, max_h, overflow_details)
  end

  defp place_flow_group([block], pages, template, max_h, overflow_details) do
    if block.keep_together do
      place_hard_group([block], pages, template, max_h, overflow_details, :keep_together)
    else
      paginate_block(block, pages, template, max_h, overflow_details)
    end
  end

  defp place_flow_group(group, pages, template, max_h, overflow_details) do
    place_hard_group(group, pages, template, max_h, overflow_details, :keep_with_next)
  end

  defp place_hard_group(group, [current_page | rest], template, max_h, overflow_details, keep_rule) do
    group_h = Enum.sum(Enum.map(group, &(&1.height || 0)))
    current_h = Enum.sum(Enum.map(current_page.blocks, &(&1.height || 0)))

    cond do
      current_h + group_h <= max_h ->
        [%{current_page | blocks: current_page.blocks ++ group} | rest]

      group_h <= max_h ->
        [%{template | blocks: group}, current_page | rest]

      true ->
        throw(
          {:error, :content_overflow,
           keep_rule_overflow_details(
             group,
             group_h,
             max_h,
             current_page,
             rest,
             overflow_details,
             keep_rule
           )}
        )
    end
  end

  defp maybe_break_before([current_page | _] = pages, template, group) do
    if hd(group).break_before and current_page.blocks != [] do
      [%{template | blocks: []} | pages]
    else
      pages
    end
  end

  defp maybe_break_after([current_page | _] = pages, template, group, remaining) do
    if remaining != [] and List.last(group).break_after and current_page.blocks != [] do
      [%{template | blocks: []} | pages]
    else
      pages
    end
  end

  defp next_flow_group([block | rest]) do
    if block.keep_with_next do
      collect_keep_with_next_chain(rest, [block])
    else
      {[block], rest}
    end
  end

  defp collect_keep_with_next_chain([], acc), do: {Enum.reverse(acc), []}

  defp collect_keep_with_next_chain([block | rest], acc) do
    updated = [block | acc]

    if block.keep_with_next do
      collect_keep_with_next_chain(rest, updated)
    else
      {Enum.reverse(updated), rest}
    end
  end

  defp handle_table_split(
         block,
         table,
         current_page,
         rest,
         template,
         max_h,
         current_h,
         _block_h,
         overflow_details
       ) do
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
        if current_h == 0 do
          impossible_row_h = List.first(table.row_heights || []) || 0
          details = Map.merge(overflow_details, %{
            row_index: 0, # Since we didn't split, it's the first row of this table chunk
            row_height: impossible_row_h,
            header_height: table.header_height || 0,
            column_widths: table.column_widths || []
          })
          throw({:error, :content_overflow, details})
        else
          [%{template | blocks: [block]}, current_page | rest]
        end

      true ->
        [%{current_page | blocks: current_page.blocks ++ [block]} | rest]
    end
  end

  defp check_overflow!(block, block_h, max_h, overflow_details) do
    if block_h > max_h do
      throw(
        {:error, :content_overflow,
         Map.merge(
           %{
             block_height: block_h,
             max_height: max_h,
             block: block_rect(block)
           },
           overflow_details
         )}
      )
    end
  end

  defp keep_rule_overflow_details(
         group,
         group_h,
         max_h,
         current_page,
         rest,
         overflow_details,
         keep_rule
       ) do
    Map.merge(overflow_details, %{
      keep_rule: keep_rule,
      kept_height: group_h,
      max_height: max_h,
      page_index: keep_rule_page_index(current_page, rest),
      region: Map.get(overflow_details, :region),
      overflow_source: Map.get(overflow_details, :overflow_source),
      block_indexes: keep_rule_block_indexes(current_page, group),
      block: block_rect(hd(group))
    })
  end

  defp keep_rule_page_index(%Page{blocks: []}, rest), do: length(rest) + 1
  defp keep_rule_page_index(%Page{}, rest), do: length(rest) + 2

  defp keep_rule_block_indexes(%Page{blocks: blocks}, group) do
    start_index = length(blocks)
    finish_index = start_index + length(group) - 1
    Enum.to_list(start_index..finish_index)
  end

  defp apply_page_template(%Page{} = page, idx, layout) do
    anchored_blocks =
      layout.template.regions
      |> Enum.reject(&(&1.name == :body))
      |> Enum.flat_map(fn region ->
        anchored_region_blocks =
          layout.region_blocks
          |> Map.get(region.name, [])
          |> replace_page_numbers(idx)
          |> anchor_region_blocks(region, page)

        maybe_validate_region_fit(anchored_region_blocks, region, page, idx, region.name)
      end)

    %{page | blocks: anchored_blocks ++ page.blocks}
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

        %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text} = source} = measured ->
          replaced = String.replace(text, "{{page_number}}", Integer.to_string(page_num))

          %{
            block
            | content: %{
                measured
                | source: %{source | content: replaced},
                  lines:
                    Enum.map(measured.lines, fn line ->
                      String.replace(line, "{{page_number}}", Integer.to_string(page_num))
                    end)
              }
          }

        _ ->
          block
      end
    end)
  end

  defp anchor_region_blocks(blocks, %Region{} = region, %Page{} = page) do
    start_x = relative_x(region, page)
    start_y = relative_y(region, page)

    {anchored, _} =
      Enum.reduce(blocks, {[], start_y}, fn block, {acc, current_y} ->
        anchored_block =
          block
          |> Map.put(:x, start_x + block.x)
          |> Map.put(:y, current_y)
          |> stack_table_cells()

        next_y = current_y + (block.height || 0)
        {acc ++ [anchored_block], next_y}
      end)

    anchored
  end

  defp flow_layout(%Document{options: %{layout: layout}}), do: layout

  defp flow_layout(%Document{} = doc) do
    template = %PageTemplate{}

    body_region = %Region{
      name: :body,
      role: :body,
      anchor: :flow,
      x: template.margin_left,
      y: template.margin_top,
      width: template.width - template.margin_left - template.margin_right,
      height: template.height - template.margin_top - template.margin_bottom
    }

    %{
      template: template,
      body_region: body_region,
      body_capacity: body_region.height,
      region_blocks: %{
        body: doc.content,
        header: doc.header,
        footer: doc.footer
      }
    }
  end

  defp page_from_template(%PageTemplate{} = template) do
    %Page{
      width: template.width,
      height: template.height,
      margin_top: template.margin_top,
      margin_right: template.margin_right,
      margin_bottom: template.margin_bottom,
      margin_left: template.margin_left,
      blocks: []
    }
  end

  defp relative_x(%Region{x: x}, %Page{margin_left: margin_left}), do: x - margin_left
  defp relative_y(%Region{y: y}, %Page{margin_top: margin_top}), do: y - margin_top

  defp validate_fixed_pages(%Document{pages: pages} = doc) do
    pages
    |> Enum.with_index(1)
    |> Enum.each(fn {page, page_index} ->
      validate_fixed_page_directives!(page, page_index)
      validate_page_fit!(page, page_index)
    end)

    {:ok, doc}
  catch
    {:error, :content_overflow, details} ->
      {:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}

    {:error, :invalid_flow_directive, details} ->
      {:error, Rendro.Error.from_stage(:paginate, :invalid_flow_directive, %{details: details})}
  end

  defp validate_fixed_page_directives!(%Page{blocks: blocks}, page_index) do
    blocks
    |> Enum.with_index()
    |> Enum.each(fn {block, block_index} ->
      case invalid_fixed_page_directive(block) do
        nil ->
          :ok

        directive ->
          throw(
            {:error, :invalid_flow_directive,
             %{
               directive: directive,
               page_index: page_index,
               block_index: block_index
             }}
          )
      end
    end)
  end

  defp invalid_fixed_page_directive(%Rendro.Block{} = block) do
    cond do
      block.break_before -> :break_before
      block.break_after -> :break_after
      block.keep_together -> :keep_together
      block.keep_with_next -> :keep_with_next
      match?(%Rendro.Table{}, block.content) -> invalid_table_directive(block.content)
      true -> nil
    end
  end

  defp invalid_table_directive(%Rendro.Table{header: header, rows: rows}) do
    Enum.find_value(List.wrap(header), &invalid_fixed_page_directive/1) ||
      Enum.find_value(rows, fn row -> Enum.find_value(row, &invalid_fixed_page_directive/1) end)
  end

  defp validate_page_fit!(%Page{blocks: blocks} = page, page_index) do
    bounds = %{
      x: 0,
      y: 0,
      width: usable_page_width(page),
      height: usable_page_height(page)
    }

    validate_blocks_fit!(blocks, bounds, fn block, block_index ->
      fixed_page_overflow_details(page_index, block_index, block, bounds)
    end)
  end

  defp validate_body_region_fit!(%Page{blocks: blocks} = page, %Region{} = region, page_index) do
    validate_region_fit!(blocks, region, page, page_index, :body)
    page
  end

  defp maybe_validate_region_fit(blocks, %Region{} = region, %Page{} = page, page_index, region_name) do
    if bounded_region?(region) do
      validate_region_fit!(blocks, region, page, page_index, region_name)
    else
      blocks
    end
  end

  defp validate_region_fit!(blocks, %Region{} = region, %Page{} = page, page_index, region_name) do
    bounds = %{
      x: relative_x(region, page),
      y: relative_y(region, page),
      width: region.width || 0,
      height: region.height || 0
    }

    validate_blocks_fit!(blocks, bounds, fn block, block_index ->
      region_overflow_details(page_index, block_index, block, region_name, bounds)
    end)
  end

  defp validate_blocks_fit!(blocks, bounds, details_fun) do
    blocks
    |> Enum.with_index()
    |> Enum.each(fn {block, block_index} ->
      unless block_fits_bounds?(block, bounds) do
        throw({:error, :content_overflow, details_fun.(block, block_index)})
      end
    end)

    blocks
  end

  defp block_fits_bounds?(block, bounds) do
    x = block.x || 0
    y = block.y || 0
    width = block.width || 0
    height = block.height || 0

    max_x = bounds.x + bounds.width
    max_y = bounds.y + bounds.height

    x >= bounds.x and y >= bounds.y and x + width <= max_x and y + height <= max_y
  end

  defp fixed_page_overflow_details(page_index, block_index, block, bounds) do
    %{
      overflow_source: :fixed_page,
      page_index: page_index,
      block_index: block_index,
      block: block_rect(block),
      bounds: bounds
    }
  end

  defp region_overflow_details(page_index, block_index, block, region_name, bounds) do
    %{
      overflow_source: :bounded_region,
      page_index: page_index,
      region: region_name,
      block_index: block_index,
      block: block_rect(block),
      bounds: bounds
    }
  end

  defp block_rect(block) do
    %{
      x: block.x || 0,
      y: block.y || 0,
      width: block.width || 0,
      height: block.height || 0
    }
  end

  defp usable_page_width(%Page{} = page) do
    page.width - page.margin_left - page.margin_right
  end

  defp usable_page_height(%Page{} = page) do
    page.height - page.margin_top - page.margin_bottom
  end

  defp bounded_region?(%Region{width: width, height: height}) do
    is_number(width) and width > 0 and is_number(height) and height > 0
  end

  defp table_height(%Rendro.Table{} = table) do
    header_h = table.header_height || 0
    rows_h = if table.row_heights, do: Enum.sum(table.row_heights), else: 0
    header_h + rows_h
  end

  defp split_table(%Rendro.Table{} = table, available_h) do
    header_h = table.header_height || 0
    row_heights = table.row_heights || []

    {fit_count, _} =
      Enum.reduce_while(row_heights, {0, header_h}, fn rh, {count, current_h} ->
        if current_h + rh <= available_h do
          {:cont, {count + 1, current_h + rh}}
        else
          {:halt, {count, current_h}}
        end
      end)

    if fit_count == 0 do
      {nil, table}
    else
      split_table_rows(table, fit_count)
    end
  end

  defp split_table_rows(table, fit_count) when fit_count <= 0, do: {nil, table}

  defp split_table_rows(table, fit_count) do
    {this_rows, rest_rows} = Enum.split(table.rows, fit_count)
    {this_row_heights, rest_row_heights} = if table.row_heights, do: Enum.split(table.row_heights, fit_count), else: {nil, nil}

    case rest_rows do
      [] ->
        {table, nil}

      _ ->
        this_table = %{table | rows: this_rows, row_heights: this_row_heights}
        # Repeat header on rest
        rest_table = %{table | rows: rest_rows, row_heights: rest_row_heights}
        {this_table, rest_table}
    end
  end
end
