defprotocol Rendro.Fragmentable do
  @moduledoc """
  Protocol for splitting layout components across page boundaries.
  """

  @doc """
  Splits a component given the available height on the current page.
  Returns `{fitting_component, remaining_component}`.
  If the component fits entirely, returns `{component, nil}`.
  If it cannot be split to fit, returns `{nil, component}`.
  """
  @spec split(t(), number()) :: {t() | nil, t() | nil}
  def split(component, available_height)
end

defimpl Rendro.Fragmentable, for: Rendro.Block do
  def split(%Rendro.Block{content: content} = block, available_h) do
    if (block.height || 0) <= available_h do
      {block, nil}
    else
      if Rendro.Fragmentable.impl_for(content) do
        case Rendro.Fragmentable.split(content, available_h) do
          {nil, _} ->
            {nil, block}

          {this_content, rem_content} ->
            this_block =
              if rem_content == nil do
                %{block | content: this_content}
              else
                %{block | content: this_content, height: height_for(this_content)}
              end

            rem_block =
              if rem_content,
                do: %{block | content: rem_content, height: height_for(rem_content)},
                else: nil

            {this_block, rem_block}
        end
      else
        {nil, block}
      end
    end
  end

  defp height_for(%Rendro.Table{} = table) do
    header_h = table.header_height || 0
    rows_h = if table.row_heights, do: Enum.sum(table.row_heights), else: 0
    header_h + rows_h
  end

  defp height_for(%Rendro.Link{content: content}), do: height_for(content)
  defp height_for(%{height: h}), do: h || 0
  defp height_for(_), do: 0
end

defimpl Rendro.Fragmentable, for: Rendro.Link do
  def split(%Rendro.Link{content: content} = link, available_h) do
    if Rendro.Fragmentable.impl_for(content) do
      case Rendro.Fragmentable.split(content, available_h) do
        {nil, _} ->
          {nil, link}

        {this_content, rem_content} ->
          this_link = %{link | content: this_content}
          rem_link = if rem_content, do: %{link | content: rem_content}, else: nil
          {this_link, rem_link}
      end
    else
      {nil, link}
    end
  end
end

defimpl Rendro.Fragmentable, for: Rendro.Pipeline.MeasuredText do
  def split(text, available_h) do
    total_lines = length(text.lines)

    if total_lines == 0 do
      if available_h >= text.height do
        {text, nil}
      else
        {nil, text}
      end
    else
      line_height_pt = text.height / total_lines
      lines_fitting = if line_height_pt > 0, do: floor(available_h / line_height_pt), else: 0

      lines_fitting =
        if total_lines - lines_fitting < text.widows do
          max(0, total_lines - text.widows)
        else
          lines_fitting
        end

      can_split? = lines_fitting >= max(1, text.orphans)

      if can_split? and lines_fitting < total_lines do
        {this_page_lines, remaining_lines} = Enum.split(text.lines, lines_fitting)

        this_text = %{
          text
          | lines: this_page_lines,
            height: length(this_page_lines) * line_height_pt
        }

        remaining_text = %{
          text
          | lines: remaining_lines,
            height: length(remaining_lines) * line_height_pt
        }

        {this_text, remaining_text}
      else
        if available_h >= text.height do
          {text, nil}
        else
          {nil, text}
        end
      end
    end
  end
end

defimpl Rendro.Fragmentable, for: Rendro.Table do
  def split(%Rendro.Table{split_policy: :fragment} = table, available_h) do
    header_h = table.header_height || 0
    row_heights = table.row_heights || []

    {fit_count, remaining_h} =
      Enum.reduce_while(row_heights, {0, available_h - header_h}, fn rh, {count, current_avail} ->
        if rh <= current_avail do
          {:cont, {count + 1, current_avail - rh}}
        else
          {:halt, {count, current_avail}}
        end
      end)

    if fit_count == 0 and remaining_h <= 0 do
      {nil, table}
    else
      {this_rows, rest_rows} = Enum.split(table.rows, fit_count)

      {this_rh, rest_rh} =
        if table.row_heights, do: Enum.split(table.row_heights, fit_count), else: {nil, nil}

      case rest_rows do
        [] ->
          {table, nil}

        [crossing_row | tail_rows] ->
          [crossing_rh | tail_rh] = rest_rh || [0 | []]

          {this_slice, rem_slice, this_slice_h, rem_slice_h} =
            slice_row(crossing_row, crossing_rh, remaining_h)

          if this_slice do
            this_table_rows = this_rows ++ [this_slice]
            this_table_rh = if table.row_heights, do: this_rh ++ [this_slice_h], else: nil

            rem_table_rows = if rem_slice, do: [rem_slice | tail_rows], else: tail_rows

            rem_table_rh =
              if table.row_heights,
                do: if(rem_slice, do: [rem_slice_h | tail_rh], else: tail_rh),
                else: nil

            this_table = %{table | rows: this_table_rows, row_heights: this_table_rh}

            rest_table =
              if rem_table_rows == [] do
                nil
              else
                if table.repeat_header do
                  %{table | rows: rem_table_rows, row_heights: rem_table_rh}
                else
                  %{
                    table
                    | rows: rem_table_rows,
                      row_heights: rem_table_rh,
                      header: nil,
                      header_height: 0
                  }
                end
              end

            {this_table, rest_table}
          else
            split_table_rows(table, fit_count)
          end
      end
    end
  end

  def split(%Rendro.Table{} = table, available_h) do
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

    {this_row_heights, rest_row_heights} =
      if table.row_heights, do: Enum.split(table.row_heights, fit_count), else: {nil, nil}

    case rest_rows do
      [] ->
        {table, nil}

      _ ->
        this_table = %{table | rows: this_rows, row_heights: this_row_heights}

        rest_table =
          if table.repeat_header do
            %{table | rows: rest_rows, row_heights: rest_row_heights}
          else
            %{
              table
              | rows: rest_rows,
                row_heights: rest_row_heights,
                header: nil,
                header_height: 0
            }
          end

        {this_table, rest_table}
    end
  end

  defp slice_row(%Rendro.Row{} = row, _row_h, available_h) do
    results =
      Enum.map(row.cells, fn cell ->
        if Rendro.Fragmentable.impl_for(cell.content) do
          {tb, rb} = Rendro.Fragmentable.split(cell.content, available_h)

          rem_cell =
            if rb do
              %{cell | content: rb, height: rb.height}
            else
              empty_block = %Rendro.Block{
                content: %Rendro.Text{content: ""},
                width: cell.width,
                height: 0
              }

              %{cell | content: empty_block, height: 0}
            end

          if tb do
            {%{cell | content: tb, height: tb.height}, rem_cell}
          else
            {nil, %{cell | content: cell.content, height: cell.height}}
          end
        else
          if available_h >= (cell.height || 0) do
            {cell, nil}
          else
            {nil, cell}
          end
        end
      end)

    if Enum.any?(results, fn {tb, _rb} -> tb == nil end) do
      {nil, nil, 0, 0}
    else
      this_cells = Enum.map(results, fn {tb, _rb} -> tb end)
      rem_cells = Enum.map(results, fn {_tb, rb} -> rb end)

      this_h = Enum.max(Enum.map(this_cells, &(&1.height || 0)), fn -> 0 end)
      rem_h = Enum.max(Enum.map(rem_cells, &(&1.height || 0)), fn -> 0 end)

      {
        %{row | cells: this_cells},
        %{row | cells: rem_cells},
        this_h,
        rem_h
      }
    end
  end
end
