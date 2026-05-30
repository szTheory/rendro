defmodule Rendro.Pipeline.Paginate do
  @moduledoc false

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
      {pages, diagnostics} =
        paginate_blocks(
          body_blocks,
          {[%{page_template | blocks: []}], []},
          page_template,
          max_h,
          %{overflow_source: :bounded_region, region: :body}
        )

      pages = Enum.reverse(pages)
      total = length(pages)

      pages =
        pages
        |> Enum.with_index(1)
        |> Enum.map(fn {page, idx} ->
          page
          |> stack_body_blocks(layout.body_region)
          |> validate_body_region_fit!(layout.body_region, idx)
          |> apply_page_template(idx, layout, total)
        end)

      {:ok,
       %{
         doc
         | pages: pages,
           content: [],
           diagnostics: Enum.reverse(diagnostics) ++ doc.diagnostics
       }}
    catch
      {:error, :content_overflow, details} ->
        {:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}

      {:error, :unsupported_table_split_policy, details} ->
        {:error,
         Rendro.Error.from_stage(:paginate, :unsupported_table_split_policy, %{details: details})}

      {:error, :running_content_error, details} ->
        {:error, Rendro.Error.from_stage(:paginate, :running_content_error, %{details: details})}
    end
  end

  defp paginate_blocks([], {pages, diagnostics}, _template, _max_h, _overflow_details),
    do: {pages, diagnostics}

  defp paginate_blocks(blocks, {pages, diagnostics}, template, max_h, overflow_details) do
    {group, remaining} = next_flow_group(blocks)

    {pages, diagnostics} =
      {pages, diagnostics}
      |> maybe_break_before(template, group)
      |> place_flow_group_for(group, template, max_h, overflow_details)
      |> maybe_break_after(template, group, remaining)

    paginate_blocks(remaining, {pages, diagnostics}, template, max_h, overflow_details)
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
    header_y = block.y
    start_x = block.x
    col_widths = table.column_widths || []

    stacked_header =
      if table.header, do: stack_cells(table.header, start_x, header_y, col_widths), else: nil

    header_offset = table.header_height || 0

    {stacked_rows, _} =
      Enum.reduce(
        Enum.zip(table.rows, table.row_heights || []),
        {[], header_y + header_offset},
        fn {row, row_h}, {acc, y} ->
          stacked_row = stack_cells(row, start_x, y, col_widths)
          {acc ++ [stacked_row], y + row_h}
        end
      )

    %{block | content: %{table | header: stacked_header, rows: stacked_rows}}
  end

  defp stack_table_cells(block), do: block

  defp stack_cells(%Rendro.Row{} = row, start_x, y, col_widths) do
    %{row | cells: stack_cells(row.cells, start_x, y, col_widths)}
  end

  defp stack_cells(row, start_x, y, col_widths) when is_list(row) do
    {cells, _} =
      Enum.reduce(Enum.zip(row, col_widths), {[], start_x}, fn {cell, col_w}, {acc, x} ->
        # Cell already has its width set by Measure, but its x needs stacking
        {acc ++ [%{cell | x: x, y: y}], x + col_w}
      end)

    cells
  end

  defp paginate_block(
         block,
         {[current_page | rest], diagnostics},
         template,
         max_h,
         overflow_details
       ) do
    block_h = block.height || 0
    current_h = Enum.sum(Enum.map(current_page.blocks, &(&1.height || 0)))

    failure_details =
      Map.merge(overflow_details, %{
        page_index: length(rest) + 1,
        block_index: length(current_page.blocks)
      })

    if match?(%Rendro.Table{}, block.content) do
      table_split_policy(block.content, failure_details)
    end

    if current_h + block_h <= max_h do
      {[%{current_page | blocks: current_page.blocks ++ [block]} | rest], diagnostics}
    else
      handle_split(
        block,
        current_page,
        rest,
        template,
        max_h,
        current_h,
        failure_details,
        diagnostics
      )
    end
  end

  defp handle_split(
         block,
         current_page,
         rest,
         template,
         max_h,
         current_h,
         overflow_details,
         diagnostics
       ) do
    available_h = max_h - current_h

    {this_block, remaining_block} = Rendro.Fragmentable.split(block, available_h)

    case {this_block, remaining_block} do
      {nil, _} ->
        if current_h == 0 do
          case block.content do
            %Rendro.Table{} = table ->
              impossible_row_h = List.first(table.row_heights || []) || 0

              details =
                Map.merge(overflow_details, %{
                  row_index: 0,
                  row_height: impossible_row_h,
                  header_height: table.header_height || 0,
                  column_widths: table.column_widths || []
                })

              throw({:error, :content_overflow, details})

            _ ->
              check_overflow!(block, block.height || 0, max_h, overflow_details)
          end
        else
          {[%{template | blocks: [block]}, current_page | rest], diagnostics}
        end

      {this_block, nil} ->
        current_page = %{current_page | blocks: current_page.blocks ++ [this_block]}
        {[current_page | rest], diagnostics}

      {this_block, remaining_block} ->
        current_page = %{current_page | blocks: current_page.blocks ++ [this_block]}

        diagnostic_type =
          case block.content do
            %Rendro.Table{} -> :table_split
            %Rendro.Pipeline.MeasuredText{} -> :text_split
            _ -> :component_split
          end

        new_diagnostic = %{
          level: :info,
          type: diagnostic_type,
          page_index: overflow_details.page_index
        }

        new_diagnostic =
          if diagnostic_type == :table_split do
            Map.put(new_diagnostic, :reason, :insufficient_height)
          else
            new_diagnostic
          end

        {[%{template | blocks: [remaining_block]}, current_page | rest],
         [new_diagnostic | diagnostics]}
    end
  end

  defp place_flow_group_for({pages, diagnostics}, group, template, max_h, overflow_details) do
    place_flow_group(group, {pages, diagnostics}, template, max_h, overflow_details)
  end

  defp place_flow_group([block], {pages, diagnostics}, template, max_h, overflow_details) do
    if block.keep_together do
      place_hard_group(
        [block],
        {pages, diagnostics},
        template,
        max_h,
        overflow_details,
        :keep_together
      )
    else
      paginate_block(block, {pages, diagnostics}, template, max_h, overflow_details)
    end
  end

  defp place_flow_group(group, {pages, diagnostics}, template, max_h, overflow_details) do
    place_hard_group(
      group,
      {pages, diagnostics},
      template,
      max_h,
      overflow_details,
      :keep_with_next
    )
  end

  defp place_hard_group(
         group,
         {[current_page | rest], diagnostics},
         template,
         max_h,
         overflow_details,
         keep_rule
       ) do
    group_h = Enum.sum(Enum.map(group, &(&1.height || 0)))
    current_h = Enum.sum(Enum.map(current_page.blocks, &(&1.height || 0)))

    cond do
      current_h + group_h <= max_h ->
        {[%{current_page | blocks: current_page.blocks ++ group} | rest], diagnostics}

      group_h <= max_h ->
        new_diagnostic = %{
          level: :info,
          type: :keep_rule_break,
          keep_rule: keep_rule,
          page_index: length(rest) + 2
        }

        {[%{template | blocks: group}, current_page | rest], [new_diagnostic | diagnostics]}

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

  defp maybe_break_before({[current_page | _] = pages, diagnostics}, template, group) do
    if hd(group).break_before and current_page.blocks != [] do
      {[%{template | blocks: []} | pages], diagnostics}
    else
      {pages, diagnostics}
    end
  end

  defp maybe_break_after({[current_page | _] = pages, diagnostics}, template, group, remaining) do
    if remaining != [] and List.last(group).break_after and current_page.blocks != [] do
      {[%{template | blocks: []} | pages], diagnostics}
    else
      {pages, diagnostics}
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

  defp apply_page_template(%Page{} = page, idx, layout, total) do
    region_suppress_on = Map.get(layout, :region_suppress_on, %{})

    anchored_blocks =
      layout.template.regions
      |> Enum.reject(&(&1.name == :body))
      |> Enum.flat_map(fn region ->
        suppress_on = Map.get(region_suppress_on, region.name)

        anchored_region_blocks =
          layout.region_blocks
          |> Map.get(region.name, [])
          |> apply_suppression(suppress_on, idx)
          |> evaluate_fn_blocks(idx, total)
          |> replace_page_numbers(idx, total)
          |> anchor_region_blocks(region, page)

        maybe_validate_region_fit(anchored_region_blocks, region, page, idx, region.name)
      end)

    %{page | blocks: anchored_blocks ++ page.blocks}
  end

  defp replace_page_numbers(blocks, page_num, total) do
    Enum.map(blocks, fn block ->
      case block.content do
        %Rendro.Text{content: text} = t ->
          new_text =
            text
            |> String.replace("{{page_number}}", Integer.to_string(page_num))
            |> String.replace("{{total_pages}}", Integer.to_string(total))

          %{block | content: %{t | content: new_text}}

        %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text} = source} = measured ->
          new_source_text =
            text
            |> String.replace("{{page_number}}", Integer.to_string(page_num))
            |> String.replace("{{total_pages}}", Integer.to_string(total))

          new_lines =
            Enum.map(measured.lines, fn line ->
              Enum.map(line, fn run ->
                new_run_text =
                  run.text
                  |> String.replace("{{page_number}}", Integer.to_string(page_num))
                  |> String.replace("{{total_pages}}", Integer.to_string(total))

                # NOTE: run.width intentionally NOT updated (D-10)
                %{run | text: new_run_text}
              end)
            end)

          %{
            block
            | content: %{
                measured
                | source: %{source | content: new_source_text},
                  lines: new_lines
              }
          }

        _ ->
          block
      end
    end)
  end

  defp evaluate_fn_blocks(blocks, page_num, total) do
    Enum.flat_map(blocks, fn block ->
      case block.content do
        %Rendro.RunningContent{fun: fun} ->
          try do
            result = fun.({page_num, total})

            case result do
              nil -> []
              [] -> []
              list when is_list(list) -> list
              single -> [single]
            end
          rescue
            reason ->
              throw(
                {:error, :running_content_error, %{page_num: page_num, reason: inspect(reason)}}
              )
          end

        _ ->
          [block]
      end
    end)
  end

  defp apply_suppression(blocks, suppress_on, page_idx) do
    case suppress_on do
      nil ->
        blocks

      :first when page_idx == 1 ->
        []

      :first ->
        blocks

      {:pages, page_list} when is_list(page_list) ->
        if page_idx in page_list, do: [], else: blocks

      _ ->
        blocks
    end
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

    header_region = Enum.find(template.regions, &(&1.name == :header))
    footer_region = Enum.find(template.regions, &(&1.name == :footer))

    body_y = body_region.y
    body_h = body_region.height

    header_h =
      if header_region && is_number(header_region.height) && is_number(header_region.y) &&
           is_number(body_y) && is_number(body_h) &&
           body_y < header_region.y + header_region.height &&
           header_region.y < body_y + body_h do
        header_region.height
      else
        0
      end

    footer_h =
      if footer_region && is_number(footer_region.height) && is_number(footer_region.y) &&
           is_number(body_y) && is_number(body_h) &&
           body_y + body_h >= footer_region.y &&
           footer_region.y + footer_region.height > body_y do
        footer_region.height
      else
        0
      end

    %{
      template: template,
      body_region: body_region,
      body_capacity: body_h - header_h - footer_h,
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

  defp maybe_validate_region_fit(
         blocks,
         %Region{} = region,
         %Page{} = page,
         page_index,
         region_name
       ) do
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

  defp table_split_policy(%Rendro.Table{split_policy: :row_atomic}, _details), do: :row_atomic
  defp table_split_policy(%Rendro.Table{split_policy: :atomic}, _details), do: :row_atomic
  defp table_split_policy(%Rendro.Table{split_policy: :fragment}, _details), do: :fragment

  defp table_split_policy(%Rendro.Table{split_policy: split_policy}, details) do
    throw(
      {:error, :unsupported_table_split_policy,
       Map.merge(details, %{
         split_policy: split_policy,
         supported_split_policies: [:row_atomic, :fragment]
       })}
    )
  end
end
