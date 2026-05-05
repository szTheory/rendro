import re

with open('lib/rendro/pipeline/paginate.ex', 'r') as f:
    content = f.read()

# Replace paginate_block
old_paginate_block = """  defp paginate_block(
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

    case block.content do
      %Rendro.Table{} = table ->
        case table_split_policy(table, failure_details) do
          policy when policy in [:row_atomic, :fragment] and current_h + block_h > max_h ->
            handle_table_split(
              block,
              table,
              current_page,
              rest,
              template,
              max_h,
              current_h,
              block_h,
              failure_details,
              diagnostics
            )

          policy when policy in [:row_atomic, :fragment] ->
            {[%{current_page | blocks: current_page.blocks ++ [block]} | rest], diagnostics}
        end

      %Rendro.Pipeline.MeasuredText{} = text ->
        if current_h + block_h > max_h do
          handle_text_split(
            block,
            text,
            current_page,
            rest,
            template,
            max_h,
            current_h,
            block_h,
            failure_details,
            diagnostics
          )
        else
          {[%{current_page | blocks: current_page.blocks ++ [block]} | rest], diagnostics}
        end

      _ ->
        if current_h + block_h <= max_h do
          {[%{current_page | blocks: current_page.blocks ++ [block]} | rest], diagnostics}
        else
          check_overflow!(block, block_h, max_h, failure_details)
          {[%{template | blocks: [block]}, current_page | rest], diagnostics}
        end
    end
  end"""

new_paginate_block = """  defp paginate_block(
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

    if current_h + block_h <= max_h do
      {[%{current_page | blocks: current_page.blocks ++ [block]} | rest], diagnostics}
    else
      case block.content do
        %Rendro.Table{} = table ->
          table_split_policy(table, failure_details)
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

        _ ->
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
  end"""

content = content.replace(old_paginate_block, new_paginate_block)

# Remove handle_table_split to end of file, except the stuff that we need.
# Wait, handle_table_split is before check_overflow!
old_handle_splits = content[content.find("  defp handle_table_split("):content.find("  defp check_overflow!(")]
content = content.replace(old_handle_splits, "")

# Remove table_height down to the end of file (these are split_table, split_block, slice_row)
# Wait, table_height is used by nothing? Wait, we need to check if table_height is used.
# It was used in handle_table_split. It is not used anymore.
table_height_start = content.find("  defp table_height(%Rendro.Table{} = table) do")
if table_height_start != -1:
    content = content[:table_height_start] + "end\n" # assuming table_split_policy was the last thing before table_height

with open('lib/rendro/pipeline/paginate.ex', 'w') as f:
    f.write(content)
