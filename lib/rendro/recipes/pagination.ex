defmodule Rendro.Recipes.Pagination do
  @moduledoc false

  # ---------------------------------------------------------------------------
  # Row chunking (shared by Statement, Receipt, and future recipes)
  # ---------------------------------------------------------------------------

  # Chunks [{fmt_row, height, opaque_meta}] triples into pages.
  # `opaque_meta` is whatever the caller needs from each row (e.g. balance for
  # Statement, nil for Receipt). Returns [{[fmt_row], last_opaque_meta}] page
  # tuples.
  #
  # `effective_capacity` is pre-computed by the caller (recipe-specific formula):
  #   Statement: capacity - header_h - 2 * typical_row_h - @row_epsilon
  #   Receipt:   capacity - header_h - @row_epsilon
  @spec chunk_rows_into_pages([{any(), number(), any()}], number()) ::
          [{[any()], any()}]
  def chunk_rows_into_pages(rows_with_meta, effective_capacity) do
    do_chunk(rows_with_meta, effective_capacity, [], 0.0, [])
  end

  defp do_chunk([], _cap, [], _h, pages), do: Enum.reverse(pages)

  defp do_chunk([], _cap, current, _h, pages) do
    {rows, meta} = finalize_page(current)
    Enum.reverse([{rows, meta} | pages])
  end

  defp do_chunk([{fmt_row, height, meta} | rest], cap, current, current_h, pages) do
    new_h = current_h + height

    if new_h <= cap or current == [] do
      # Row fits (or page is empty — always add at least one row to prevent infinite loop)
      do_chunk(rest, cap, [{fmt_row, meta} | current], new_h, pages)
    else
      # Row would overflow — start a new page
      {rows, page_meta} = finalize_page(current)
      do_chunk([{fmt_row, height, meta} | rest], cap, [], 0.0, [{rows, page_meta} | pages])
    end
  end

  # Finalizes a page: reverses accumulator (rows were added head-first) and
  # returns {formatted_rows, last_meta} where last_meta is from the last row.
  defp finalize_page(acc) do
    reversed = Enum.reverse(acc)
    rows = Enum.map(reversed, fn {r, _} -> r end)
    {_, last_meta} = List.last(reversed)
    {rows, last_meta}
  end

  # ---------------------------------------------------------------------------
  # Formatting helpers (shared across all recipes)
  # ---------------------------------------------------------------------------

  # Returns the formatter function for `key` from opts[:formatters], or
  # falls back to `default_fn`.
  def formatter(opts, key, default_fn) do
    formatters = Keyword.get(opts, :formatters, [])
    Keyword.get(formatters, key, default_fn)
  end

  # Returns a function that resolves a label key, merging caller-supplied
  # :labels over the default Rendro.Format labels.
  def label_resolver(opts) do
    user_labels = Keyword.get(opts, :labels, %{})

    fn key ->
      case Map.fetch(user_labels, key) do
        {:ok, val} -> val
        :error -> Rendro.Format.label(key)
      end
    end
  end

  # Returns a human-readable type name for error messages.
  def type_name(value) when is_binary(value), do: "String"
  def type_name(value) when is_integer(value), do: "Integer"
  def type_name(value) when is_float(value), do: "Float"
  def type_name(value) when is_atom(value), do: "Atom"
  def type_name(value) when is_list(value), do: "List"
  def type_name(value) when is_map(value), do: "Map"
  def type_name(_value), do: "Unknown"
end
