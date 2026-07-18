defmodule Rendro.Pipeline.Paginate do
  @moduledoc false

  alias Rendro.{Document, Page, PageTemplate, Region}

  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Document{pages: pages, content: content} = doc) do
    result =
      cond do
        pages != [] -> validate_fixed_pages(doc)
        content != [] or has_flow_layout?(doc) -> paginate_flow(doc)
        true -> {:error, :no_content}
      end

    case result do
      {:ok, paginated_doc} ->
        with {:ok, doc1} <- collect_anchors(paginated_doc),
             {:ok, doc2} <- collect_outlines(doc1),
             {:ok, doc3} <- resolve_toc_tokens(doc2) do
          {:ok, doc3}
        end

      error ->
        error
    end
  end

  defp resolve_toc_tokens(%Document{} = doc) do
    anchors = Map.get(doc.metadata, :anchors, %{})

    pages =
      Enum.map(doc.pages, fn page ->
        %{page | blocks: replace_toc_tokens_in_blocks(page.blocks, anchors)}
      end)

    {:ok, %{doc | pages: pages}}
  end

  defp replace_toc_tokens_in_blocks(blocks, anchors) when is_list(blocks) do
    Enum.map(blocks, &replace_toc_tokens(&1, anchors))
  end

  defp replace_toc_tokens(%Rendro.Block{} = block, anchors) do
    new_content =
      case block.content do
        %Rendro.Text{content: text} = t ->
          %{t | content: substitute_anchor_tokens(text, anchors)}

        %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text} = source} = measured ->
          new_source_text = substitute_anchor_tokens(text, anchors)

          new_lines =
            Enum.map(measured.lines, fn line ->
              Enum.map(line, fn run ->
                %{run | text: substitute_anchor_tokens(run.text, anchors)}
              end)
            end)

          %{measured | source: %{source | content: new_source_text}, lines: new_lines}

        %Rendro.Table{} = table ->
          new_header =
            if table.header,
              do: %{
                table.header
                | cells: replace_toc_tokens_in_cells(table.header.cells, anchors)
              },
              else: nil

          new_rows =
            Enum.map(table.rows || [], fn row ->
              %{row | cells: replace_toc_tokens_in_cells(row.cells, anchors)}
            end)

          %{table | header: new_header, rows: new_rows}

        other ->
          other
      end

    %{block | content: new_content}
  end

  defp replace_toc_tokens_in_cells(cells, anchors) do
    Enum.map(cells, fn cell ->
      case cell.content do
        %Rendro.Block{} = nested_block ->
          %{cell | content: replace_toc_tokens(nested_block, anchors)}

        _ ->
          cell
      end
    end)
  end

  defp substitute_anchor_tokens(text, anchors) when is_binary(text) do
    Regex.replace(~r/\{\{anchor_page:([^}]+)\}\}/, text, fn match, id ->
      case Map.get(anchors, id) do
        [page_idx | _] -> Integer.to_string(page_idx)
        # Fallback: keep original token if not found
        _ -> match
      end
    end)
  end

  defp substitute_anchor_tokens(other, _anchors), do: other

  defp collect_anchors(%Document{} = doc) do
    anchors = collect_page_anchors(doc.pages)
    metadata = Map.put(doc.metadata, :anchors, anchors)
    {:ok, %{doc | metadata: metadata}}
  catch
    {:error, :duplicate_anchor_id, id} ->
      {:error, Rendro.Error.from_stage(:paginate, :duplicate_anchor_id, %{details: %{id: id}})}
  end

  defp collect_page_anchors(pages) do
    pages
    |> Enum.with_index(1)
    |> Enum.reduce(%{}, fn {page, page_idx}, acc ->
      collect_block_anchors(page.blocks, page_idx, acc)
    end)
  end

  defp collect_block_anchors(blocks, page_idx, acc) when is_list(blocks) do
    Enum.reduce(blocks, acc, fn block, current_acc ->
      collect_single_anchor(block, page_idx, current_acc, 0, 0)
    end)
  end

  defp collect_single_anchor(%Rendro.Block{} = block, page_idx, acc, offset_x, offset_y) do
    x = offset_x + (block.x || 0)
    y = offset_y + (block.y || 0)

    acc1 =
      case block.id do
        nil ->
          acc

        id ->
          if Map.has_key?(acc, id) do
            throw({:error, :duplicate_anchor_id, id})
          else
            Map.put(acc, id, [page_idx, :XYZ, x, y, nil])
          end
      end

    case block.content do
      %Rendro.Table{} = table ->
        acc2 =
          if table.header do
            collect_row_anchors([table.header], page_idx, acc1, offset_x, offset_y)
          else
            acc1
          end

        collect_row_anchors(table.rows || [], page_idx, acc2, offset_x, offset_y)

      _ ->
        acc1
    end
  end

  defp collect_single_anchor(_other, _page_idx, acc, _offset_x, _offset_y), do: acc

  defp collect_row_anchors(rows, page_idx, acc, offset_x, offset_y) do
    Enum.reduce(rows, acc, fn row, row_acc ->
      cells =
        case row do
          %Rendro.Row{cells: c} -> c
          list when is_list(list) -> list
          _ -> []
        end

      Enum.reduce(cells, row_acc, fn
        %Rendro.Cell{content: %Rendro.Block{} = nested_block, x: cell_x, y: cell_y}, cell_acc ->
          collect_single_anchor(
            nested_block,
            page_idx,
            cell_acc,
            offset_x + (cell_x || 0),
            offset_y + (cell_y || 0)
          )

        cell_content, cell_acc ->
          case cell_content do
            %Rendro.Block{} = nested_block ->
              collect_single_anchor(nested_block, page_idx, cell_acc, offset_x, offset_y)

            _ ->
              cell_acc
          end
      end)
    end)
  end

  defp collect_outlines(%Document{} = doc) do
    flat_outlines = collect_page_outlines(doc.pages)
    tree = build_outline_tree(flat_outlines)
    metadata = Map.put(doc.metadata, :outlines, tree)
    {:ok, %{doc | metadata: metadata}}
  end

  defp collect_page_outlines(pages) do
    pages
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {page, page_idx} ->
      collect_block_outlines(page.blocks, page_idx)
    end)
  end

  defp collect_block_outlines(blocks, page_idx) when is_list(blocks) do
    Enum.flat_map(blocks, fn block ->
      collect_single_outline(block, page_idx, 0, 0)
    end)
  end

  defp collect_single_outline(%Rendro.Block{} = block, page_idx, offset_x, offset_y) do
    x = offset_x + (block.x || 0)
    y = offset_y + (block.y || 0)

    extracted =
      if block.outline do
        title = extract_outline_title(block)

        if title do
          [
            %{
              title: title,
              level: block.outline_level || 1,
              dest: [page_idx, :XYZ, x, y, nil]
            }
          ]
        else
          []
        end
      else
        []
      end

    nested =
      case block.content do
        %Rendro.Table{} = table ->
          header_outlines =
            if table.header,
              do: collect_row_outlines([table.header], page_idx, offset_x, offset_y),
              else: []

          row_outlines = collect_row_outlines(table.rows || [], page_idx, offset_x, offset_y)
          header_outlines ++ row_outlines

        _ ->
          []
      end

    extracted ++ nested
  end

  defp collect_single_outline(_other, _page_idx, _offset_x, _offset_y), do: []

  defp collect_row_outlines(rows, page_idx, offset_x, offset_y) do
    Enum.flat_map(rows, fn row ->
      cells =
        case row do
          %Rendro.Row{cells: c} -> c
          list when is_list(list) -> list
          _ -> []
        end

      Enum.flat_map(cells, fn
        %Rendro.Cell{content: %Rendro.Block{} = nested_block, x: cell_x, y: cell_y} ->
          collect_single_outline(
            nested_block,
            page_idx,
            offset_x + (cell_x || 0),
            offset_y + (cell_y || 0)
          )

        cell_content ->
          case cell_content do
            %Rendro.Block{} = nested_block ->
              collect_single_outline(nested_block, page_idx, offset_x, offset_y)

            _ ->
              []
          end
      end)
    end)
  end

  defp extract_outline_title(%Rendro.Block{outline: title}) when is_binary(title), do: title
  defp extract_outline_title(%Rendro.Block{content: %Rendro.Text{content: content}}), do: content

  defp extract_outline_title(%Rendro.Block{
         content: %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: content}}
       }),
       do: content

  defp extract_outline_title(_), do: "Section"

  defp build_outline_tree(flat_outlines) do
    {forest, _} = do_build_outline_tree(flat_outlines, 0)
    forest
  end

  defp do_build_outline_tree([], _parent_level), do: {[], []}

  defp do_build_outline_tree([%{level: level} | _] = outlines, parent_level)
       when level <= parent_level,
       do: {[], outlines}

  defp do_build_outline_tree([first | rest], parent_level) do
    node = %{title: first.title, dest: first.dest, children: []}
    {children, remaining} = do_build_outline_tree(rest, first.level)
    node = %{node | children: children}
    {siblings, remaining_after_siblings} = do_build_outline_tree(remaining, parent_level)
    {[node | siblings], remaining_after_siblings}
  end

  defp paginate_flow(%Document{} = doc) do
    layout = flow_layout(doc)
    template = layout.template
    page_template = page_from_template(template)
    body_entries = body_entries(layout, doc)
    max_h = layout.body_capacity

    try do
      {pages, diagnostics, section_starts} =
        paginate_body_entries(
          body_entries,
          {[%{page_template | blocks: []}], [], []},
          page_template,
          max_h,
          %{overflow_source: :bounded_region, region: :body}
        )

      pages = Enum.reverse(pages)
      total = length(pages)
      page_contexts = page_contexts(total, section_starts)

      pages =
        pages
        |> Enum.with_index(1)
        |> Enum.map(fn {page, idx} ->
          page
          |> stack_body_blocks(layout.body_region)
          |> validate_body_region_fit!(layout.body_region, idx)
          |> apply_page_template(idx, layout, total, Map.fetch!(page_contexts, idx))
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

  defp paginate_body_entries(
         [],
         {pages, diagnostics, section_starts},
         _template,
         _max_h,
         _overflow_details
       ),
       do: {pages, diagnostics, section_starts}

  defp paginate_body_entries(
         [entry | rest],
         {pages, diagnostics, section_starts},
         template,
         max_h,
         overflow_details
       ) do
    {pages, diagnostics} =
      if section_numbering_restart?(entry) do
        maybe_section_page_break({pages, diagnostics}, template)
      else
        {pages, diagnostics}
      end

    section_starts =
      if section_numbering_restart?(entry) do
        section_starts ++
          [
            %{
              name: Map.get(entry, :name),
              start_page: current_page_index(pages)
            }
          ]
      else
        section_starts
      end

    {pages, diagnostics} =
      paginate_blocks(
        Map.get(entry, :blocks, []),
        {pages, diagnostics},
        template,
        max_h,
        overflow_details
      )

    paginate_body_entries(
      rest,
      {pages, diagnostics, section_starts},
      template,
      max_h,
      overflow_details
    )
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

  defp body_entries(layout, %Document{} = doc) do
    measured_body_blocks = Map.get(layout.region_blocks, :body, doc.content)

    case Map.get(layout, :entries) do
      entries when is_list(entries) ->
        entries
        |> Enum.filter(&(Map.get(&1, :region) == :body))
        |> case do
          [] -> fallback_body_entries(measured_body_blocks)
          body_entries -> measured_body_entries(body_entries, measured_body_blocks)
        end

      _ ->
        fallback_body_entries(measured_body_blocks)
    end
  end

  defp fallback_body_entries(measured_body_blocks) do
    [%{name: :content, region: :body, blocks: measured_body_blocks, page_numbering: []}]
  end

  defp measured_body_entries(entries, measured_body_blocks) do
    {measured_entries, remaining_blocks} =
      Enum.map_reduce(entries, measured_body_blocks, fn entry, remaining ->
        {entry_blocks, rest} = Enum.split(remaining, length(Map.get(entry, :blocks, [])))
        {%{entry | blocks: entry_blocks}, rest}
      end)

    case {measured_entries, remaining_blocks} do
      {[], _} ->
        fallback_body_entries(measured_body_blocks)

      {entries, []} ->
        entries

      {entries, rest} ->
        List.update_at(entries, -1, fn entry -> %{entry | blocks: entry.blocks ++ rest} end)
    end
  end

  defp section_numbering_restart?(%{page_numbering: [restart: true]}), do: true
  defp section_numbering_restart?(_entry), do: false

  defp maybe_section_page_break({[%Page{blocks: []} | _] = pages, diagnostics}, _template),
    do: {pages, diagnostics}

  defp maybe_section_page_break({pages, diagnostics}, template),
    do: {[%{template | blocks: []} | pages], diagnostics}

  defp current_page_index([_current_page | prior_pages]), do: length(prior_pages) + 1

  defp page_contexts(total, section_starts) do
    explicit_starts =
      section_starts
      |> Enum.filter(fn %{start_page: start_page} -> start_page >= 1 and start_page <= total end)
      |> Enum.reduce(%{}, fn start, acc -> Map.put(acc, start.start_page, start) end)

    starts_by_page =
      if total > 0 and not Map.has_key?(explicit_starts, 1) do
        Map.put(explicit_starts, 1, %{name: :document, start_page: 1})
      else
        explicit_starts
      end

    starts =
      starts_by_page
      |> Map.values()
      |> Enum.sort_by(& &1.start_page)

    ranges =
      starts
      |> Enum.with_index()
      |> Enum.map(fn {start, index} ->
        next_start = Enum.at(starts, index + 1)
        end_page = if next_start, do: next_start.start_page - 1, else: total

        %{
          name: start.name,
          start_page: start.start_page,
          end_page: end_page,
          total_pages: end_page - start.start_page + 1
        }
      end)

    Map.new(1..total, fn page_number ->
      section =
        Enum.find(ranges, fn range ->
          page_number >= range.start_page and page_number <= range.end_page
        end)

      {page_number,
       %{
         page_number: page_number,
         total_pages: total,
         section_name: section.name,
         section_page_number: page_number - section.start_page + 1,
         section_total_pages: section.total_pages
       }}
    end)
  end

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
    cell_align = table.cell_align || %{}

    stacked_header =
      if table.header,
        do: stack_cells(table.header, start_x, header_y, col_widths, cell_align),
        else: nil

    header_offset = table.header_height || 0

    {stacked_rows, _} =
      Enum.reduce(
        Enum.zip(table.rows, table.row_heights || []),
        {[], header_y + header_offset},
        fn {row, row_h}, {acc, y} ->
          stacked_row = stack_cells(row, start_x, y, col_widths, cell_align)
          {acc ++ [stacked_row], y + row_h}
        end
      )

    %{block | content: %{table | header: stacked_header, rows: stacked_rows}}
  end

  defp stack_table_cells(block), do: block

  defp stack_cells(%Rendro.Row{} = row, start_x, y, col_widths, cell_align) do
    %{row | cells: stack_cells(row.cells, start_x, y, col_widths, cell_align)}
  end

  defp stack_cells(row, start_x, y, col_widths, cell_align) when is_list(row) do
    {cells, _} =
      row
      |> Enum.zip(col_widths)
      |> Enum.with_index()
      |> Enum.reduce({[], start_x}, fn {{cell, col_w}, col_index}, {acc, x} ->
        # Cell already has its width set by Measure, but its x needs stacking.
        # INV-05: the right-align offset is gated STRICTLY on the cell's
        # effective alignment resolving to :right — every other value
        # (including the default :left) takes this exact unchanged
        # left-flush path, so no-cell_align tables stay byte-identical.
        stacked_cell =
          case cell_effective_align(cell, cell_align, col_index) do
            :right -> %{cell | x: x + right_align_offset(cell), y: y}
            :left -> %{cell | x: x, y: y}
          end

        {acc ++ [stacked_cell], x + col_w}
      end)

    cells
  end

  # Per-cell `cell_align: :right` (set directly on an authored `%Rendro.Cell{}`)
  # takes precedence; otherwise fall back to the table's column-level
  # `cell_align` map (`Rendro.table/2` `cell_align:` option). Default is
  # :left for both, so an untouched table resolves :left for every cell.
  defp cell_effective_align(%Rendro.Cell{cell_align: :right}, _cell_align_map, _col_index),
    do: :right

  defp cell_effective_align(_cell, cell_align_map, col_index) do
    Map.get(cell_align_map, col_index, :left)
  end

  # Right-align slack = column width minus the already-measured content
  # width (post-Measure; no re-measuring). Negative slack (content wider
  # than the column) falls back to zero offset rather than shifting left
  # (T-115-03-03).
  defp right_align_offset(%Rendro.Cell{width: col_w} = cell) do
    max((col_w || 0) - measured_content_width(cell), 0)
  end

  defp measured_content_width(%Rendro.Cell{
         content: %Rendro.Block{content: %Rendro.Pipeline.MeasuredText{width: width}}
       }),
       do: width

  defp measured_content_width(%Rendro.Cell{content: %Rendro.Block{width: width}})
       when is_number(width),
       do: width

  defp measured_content_width(_cell), do: 0

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

  defp apply_page_template(%Page{} = page, idx, layout, total, page_context) do
    anchored_blocks =
      layout.template.regions
      |> Enum.reject(&(&1.name == :body))
      |> Enum.flat_map(fn region ->
        anchored_region_blocks =
          layout
          |> running_region_entries(region.name)
          |> Enum.flat_map(&running_entry_blocks(&1, idx, total, page_context))
          |> anchor_region_blocks(region, page)

        maybe_validate_region_fit(anchored_region_blocks, region, page, idx, region.name)
      end)

    %{page | blocks: anchored_blocks ++ page.blocks}
  end

  defp running_region_entries(layout, region_name) do
    measured_blocks = Map.get(layout.region_blocks, region_name, [])

    entries =
      case Map.get(layout, :region_entries) do
        region_entries when is_map(region_entries) ->
          Map.get(region_entries, region_name, [])

        _ ->
          fallback_running_region_entries(layout, region_name, measured_blocks)
      end

    measured_running_entries(entries, measured_blocks, region_name, layout)
  end

  defp fallback_running_region_entries(layout, region_name, measured_blocks) do
    suppress_on = layout |> Map.get(:region_suppress_on, %{}) |> Map.get(region_name)

    [
      %{
        name: region_name,
        region: region_name,
        blocks: measured_blocks,
        suppress_on: suppress_on,
        only_on: nil
      }
    ]
  end

  defp measured_running_entries([], _measured_blocks, _region_name, _layout), do: []

  defp measured_running_entries(entries, measured_blocks, region_name, layout) do
    {measured_entries, remaining_blocks} =
      Enum.map_reduce(entries, measured_blocks, fn entry, remaining ->
        {entry_blocks, rest} = Enum.split(remaining, length(Map.get(entry, :blocks, [])))
        {%{entry | blocks: entry_blocks}, rest}
      end)

    case {measured_entries, remaining_blocks} do
      {[], _} ->
        fallback_running_region_entries(layout, region_name, measured_blocks)

      {entries, []} ->
        entries

      {entries, rest} ->
        List.update_at(entries, -1, fn entry -> %{entry | blocks: entry.blocks ++ rest} end)
    end
  end

  defp running_entry_blocks(entry, page_idx, total, page_context) do
    entry
    |> Map.get(:blocks, [])
    |> apply_suppression(Map.get(entry, :suppress_on), page_idx)
    |> apply_only_on(Map.get(entry, :only_on), page_idx)
    |> evaluate_fn_blocks(page_idx, total)
    |> replace_page_numbers(page_context)
  end

  defp replace_page_numbers(blocks, page_context) do
    Enum.map(blocks, fn block ->
      case block.content do
        %Rendro.Text{content: text} = t ->
          new_text = replace_page_number_tokens(text, page_context)

          %{block | content: %{t | content: new_text}}

        %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text} = source} = measured ->
          new_source_text = replace_page_number_tokens(text, page_context)

          new_lines =
            Enum.map(measured.lines, fn line ->
              Enum.map(line, fn run ->
                new_run_text = replace_page_number_tokens(run.text, page_context)

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

  defp replace_page_number_tokens(text, page_context) do
    text
    |> String.replace("{{page_number}}", Integer.to_string(page_context.page_number))
    |> String.replace("{{total_pages}}", Integer.to_string(page_context.total_pages))
    |> String.replace(
      "{{section_page_number}}",
      Integer.to_string(page_context.section_page_number)
    )
    |> String.replace(
      "{{section_total_pages}}",
      Integer.to_string(page_context.section_total_pages)
    )
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

  defp apply_only_on(blocks, nil, _page_idx), do: blocks

  defp apply_only_on(blocks, :odd, page_idx) do
    if rem(page_idx, 2) == 1, do: blocks, else: []
  end

  defp apply_only_on(blocks, :even, page_idx) do
    if rem(page_idx, 2) == 0, do: blocks, else: []
  end

  defp apply_only_on(_blocks, _unknown, _page_idx), do: []

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
    Enum.find_value(List.wrap(header), &invalid_table_row_directive/1) ||
      Enum.find_value(rows, &invalid_table_row_directive/1)
  end

  defp invalid_table_row_directive(%Rendro.Row{cells: cells}) do
    Enum.find_value(cells, fn %Rendro.Cell{content: content} ->
      case content do
        %Rendro.Block{} = block -> invalid_fixed_page_directive(block)
        _ -> nil
      end
    end)
  end

  defp invalid_table_row_directive(cells) when is_list(cells) do
    Enum.find_value(cells, fn content ->
      case content do
        %Rendro.Block{} = block -> invalid_fixed_page_directive(block)
        _ -> nil
      end
    end)
  end

  defp invalid_table_row_directive(_), do: nil

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
