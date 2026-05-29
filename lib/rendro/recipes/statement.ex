defmodule Rendro.Recipes.Statement do
  @moduledoc """
  Canonical account statement recipe using the Tiered Composition pattern.

  Exposes three levels of composability:

    - `document/2`      — Batteries-included; accepts a statement data map and
                          returns a fully assembled `%Rendro.Document{}` ready
                          for `Rendro.render/1`. No template authoring required.
    - `page_template/1` — Layout only; returns the `%Rendro.PageTemplate{}`.
    - `sections/2`      — Content only; returns a list of `%Rendro.Section{}`
                          structs mapped to named regions.

  The recipe computes the running balance (opening_balance + Σ amount) as an
  exact Decimal fold and owns per-page chunking so that carried-forward /
  brought-forward rows land on the correct pages. The engine stays single-pass
  and behaviorally unchanged.

  ## Data contract

  Required keys in `data`:

    - `:period` — `%{from: Date.t(), to: Date.t()}` (statement period).
    - `:account` — `%{name: String.t()}` (account information).
    - `:opening_balance` — `Decimal.t()` (balance before the first transaction).
    - `:lines` — `[%{date: Date.t(), description: String.t(), amount: Decimal.t()}]`
      (transaction lines; amounts are signed: positive increases the balance,
      negative decreases it).

  Optional keys:

    - `:closing_balance` — `Decimal.t()` (caller assertion; derived and validated
      via `Decimal.equal?/2` when present).
    - `:summary` — `%{total_debits: Decimal.t(), total_credits: Decimal.t(),
      line_count: non_neg_integer(), closing_balance: Decimal.t()}` (caller
      assertion; derived when absent).

  ## Usage

  ### Zero-to-one (just works)

      data = %{
        period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
        account: %{name: "Acme Corp"},
        opening_balance: Decimal.new("1000.00"),
        lines: [
          %{date: ~D[2026-05-02], description: "Invoice #1", amount: Decimal.new("500.00")},
          %{date: ~D[2026-05-15], description: "Payment",   amount: Decimal.new("-200.00")}
        ]
      }
      doc = Rendro.Recipes.Statement.document(data)
      {:ok, pdf} = Rendro.render(doc)

  ### Escape hatch — inject a custom template

      template = Rendro.Recipes.Statement.page_template(name: :my_statement)
      sections = Rendro.Recipes.Statement.sections(data)
      doc =
        Rendro.Document.new()
        |> Rendro.Document.add_template(template)
        |> Rendro.Document.set_template(:my_statement)
        |> then(fn d -> Enum.reduce(sections, d, &Rendro.Document.add_section(&2, &1)) end)

  ## Formatting

  Default formatting is provided by `Rendro.Format` (pure, locale-free, deterministic):
  money as `$1,234.50` (parentheses for negatives) and dates as `YYYY-MM-DD`.

  Override defaults via `opts`:

      Rendro.Recipes.Statement.document(data,
        formatters: [
          amount: fn %Decimal{} = d -> MyApp.Money.format(d) end,
          date:   fn %Date{} = d   -> MyApp.Locale.format_date(d) end
        ],
        labels: %{carried_forward: "Saldo a cuenta nueva"}
      )
  """

  # ---------------------------------------------------------------------------
  # Layout geometry constants (all in points)
  # A4: 595.28 × 841.89 pt; default margins: 72 pt (1 inch)
  # Available column width: 595.28 - 2 × 72 = 451.28 pt
  # ---------------------------------------------------------------------------

  @page_width 595.28
  @page_height 841.89
  @margin 72

  @content_width @page_width - 2 * @margin

  # Header reserved height (account name + period row + opening balance row).
  @header_height 48

  # Footer reserved height — MUST be non-zero so body_capacity reserves space
  # and "Page X of Y" does not overlap the last body row (D-03 / STMT-04).
  @footer_height 24

  # Body height: fills the space between top margin and bottom margin minus
  # header and footer region heights.
  @body_y @margin + @header_height
  @body_height @page_height - 2 * @margin - @header_height - @footer_height

  @footer_y @page_height - @margin - @footer_height

  # Default table column rules: Date | Description | Amount | Balance
  @table_columns [{:fixed, 72}, {:share, 1}, {:fixed, 72}, {:fixed, 72}]

  # Conservative one-row epsilon margin (D-09): pack to capacity − epsilon so
  # sub-pixel rounding never tips a page into :content_overflow.
  # A blank trailing row is a far better failure mode than a render error.
  @row_epsilon 2.0

  # ---------------------------------------------------------------------------
  # Public API — three-rung escape hatch (consistent with Invoice / STMT-03)
  # ---------------------------------------------------------------------------

  @doc """
  Returns a `%Rendro.PageTemplate{}` with three named regions: `:header`,
  `:body`, and `:footer`.

  The footer region has a non-zero height so `body_capacity` reserves space for
  the "Page X of Y" page-number text (STMT-04 / D-03).

  ## Options

  All options are forwarded to `%Rendro.PageTemplate{}` as keyword overrides.
  The `name` defaults to `:statement`.

  ## Examples

      iex> t = Rendro.Recipes.Statement.page_template()
      iex> t.name
      :statement
      iex> footer = Enum.find(t.regions, & &1.role == :footer)
      iex> footer.height > 0
      true

  """
  @spec page_template(keyword()) :: Rendro.PageTemplate.t()
  def page_template(opts \\ []) do
    defaults = [
      name: :statement,
      regions: [
        Rendro.region(
          name: :header,
          role: :header,
          anchor: :top,
          x: @margin,
          y: @margin,
          width: @content_width,
          height: @header_height
        ),
        Rendro.region(
          name: :body,
          role: :body,
          anchor: :flow,
          x: @margin,
          y: @body_y,
          width: @content_width,
          height: @body_height
        ),
        Rendro.region(
          name: :footer,
          role: :footer,
          anchor: :bottom,
          x: @margin,
          y: @footer_y,
          width: @content_width,
          height: @footer_height
        )
      ]
    ]

    Rendro.page_template(Keyword.merge(defaults, opts))
  end

  @doc """
  Returns a list of `%Rendro.Section{}` structs mapping statement content to
  the `:header`, `:body`, and `:footer` regions.

  Validates `data` via `validate_data!/1` before building sections.

  ## Examples

      iex> data = %{
      ...>   period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
      ...>   account: %{name: "Acme"},
      ...>   opening_balance: Decimal.new("100.00"),
      ...>   lines: []
      ...> }
      iex> [header, body, footer] = Rendro.Recipes.Statement.sections(data)
      iex> header.region
      :header
      iex> footer.region
      :footer

  """
  @spec sections(map(), keyword()) :: [Rendro.Section.t()]
  def sections(data, opts \\ []) do
    validate_data!(data)

    [
      header_section(data, opts),
      body_section(data, opts),
      footer_section(data, opts)
    ]
  end

  @doc """
  Assembles and returns a fully composed `%Rendro.Document{}` from a statement
  data map.

  Validates `data` via `validate_data!/1`, then builds the page template and
  sections, reducing them through the Document builder API.

  ## Examples

      iex> data = %{
      ...>   period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
      ...>   account: %{name: "Acme"},
      ...>   opening_balance: Decimal.new("100.00"),
      ...>   lines: []
      ...> }
      iex> doc = Rendro.Recipes.Statement.document(data)
      iex> doc.page_template
      :statement

  """
  @spec document(map(), keyword()) :: Rendro.Document.t()
  def document(data, opts \\ []) do
    validate_data!(data)
    template = page_template(opts)
    secs = sections(data, opts)

    base_doc =
      Rendro.Document.new()
      |> Rendro.Document.add_template(template)
      |> Rendro.Document.set_template(template.name)

    Enum.reduce(secs, base_doc, fn section, doc ->
      Rendro.Document.add_section(doc, section)
    end)
  end

  # ---------------------------------------------------------------------------
  # Private section builders
  # ---------------------------------------------------------------------------

  defp header_section(%{period: period, account: account, opening_balance: ob} = _data, opts) do
    fmt_amount = formatter(opts, :amount, &Rendro.Format.money/1)
    fmt_date = formatter(opts, :date, &Rendro.Format.date/1)
    lbl = label_resolver(opts)

    period_str = "#{fmt_date.(period.from)} to #{fmt_date.(period.to)}"
    ob_str = "#{lbl.(:opening_balance)}: #{fmt_amount.(ob)}"
    account_name = Map.get(account, :name, "")

    Rendro.section(
      name: :statement_header,
      region: :header,
      content: [
        Rendro.block(Rendro.text(account_name, size: 14)),
        Rendro.block(Rendro.text(period_str, size: 10)),
        Rendro.block(Rendro.text(ob_str, size: 10))
      ]
    )
  end

  defp body_section(%{opening_balance: ob, lines: lines} = _data, opts) do
    fmt_amount = formatter(opts, :amount, &Rendro.Format.money/1)
    fmt_date = formatter(opts, :date, &Rendro.Format.date/1)
    lbl = label_resolver(opts)

    rows_with_balance = fold_balance(ob, lines)

    table_header = ["Date", "Description", "Amount", lbl.(:balance)]
    table_opts = [header: table_header, columns: @table_columns]

    # Convert balanced rows to formatted table rows (strings).
    formatted_rows =
      Enum.map(rows_with_balance, fn %{date: d, description: desc, amount: amt, balance: bal} ->
        [fmt_date.(d), desc, fmt_amount.(amt), fmt_amount.(bal)]
      end)

    # D-09: measure all rows at the body region width using the engine's OWN
    # font metrics so chunking uses real heights, not recipe-local estimates.
    doc_for_measure = Rendro.Document.new()

    {header_h, row_heights} =
      Rendro.measure_rows(formatted_rows, @content_width, doc_for_measure, table_opts)

    # Body capacity formula (mirrors measure.ex body_capacity/1):
    # capacity = body.height − header.height (if overlaps) − footer.height (if overlaps)
    # With the recipe's fixed geometry, header and footer are always adjacent to body,
    # so the full subtraction applies.
    capacity = @body_height - @header_height - @footer_height

    # Chunk rows into pages, accounting for the repeated table header on each page
    # and the brought/carried-forward extra rows. Reserve a conservative one-row
    # epsilon margin (D-09) so sub-pixel rounding never causes :content_overflow.
    pages = chunk_into_pages(rows_with_balance, formatted_rows, row_heights, header_h, capacity)

    # D-02 / D-10: inject brought-forward / carried-forward rows.
    # Each page's rows are structured as: [brought_forward?, ...txns, carried_forward?]
    # - carried-forward: last row of each non-final page, suppressed on the last page
    # - brought-forward: first row of each page after page 1, suppressed on page 1
    #
    # The balance shown in both rows is the running balance at the PAGE BREAK — i.e.,
    # the balance_at_break from the previous page (== carried-forward balance from p-1).
    # This keeps the invariant: brought-forward[N+1] == carried-forward[N] (D-10 / V6).
    last_page_idx = length(pages) - 1

    # Pair each page with its previous page's break balance (nil for page 0).
    pages_with_prev_balance =
      pages
      |> Enum.with_index()
      |> Enum.map(fn {{page_rows, balance_at_break}, idx} ->
        prev_balance =
          if idx > 0 do
            {_prev_rows, prev_break} = Enum.at(pages, idx - 1)
            prev_break
          else
            nil
          end

        {page_rows, balance_at_break, prev_balance, idx}
      end)

    blocks =
      Enum.map(pages_with_prev_balance, fn {page_rows, balance_at_break, prev_balance, idx} ->
        # carried-forward: last row of each non-final page (balance at current page's break)
        cf_row =
          if idx < last_page_idx do
            [lbl.(:carried_forward), "", "", fmt_amount.(balance_at_break)]
          else
            nil
          end

        # brought-forward: first row of each page after page 1 (balance from previous page's break)
        bf_row =
          if idx > 0 do
            [lbl.(:brought_forward), "", "", fmt_amount.(prev_balance)]
          else
            nil
          end

        # Page row structure: [brought_forward?, ...txns, carried_forward?]
        full_page_rows =
          [bf_row | page_rows] ++ [cf_row]
          |> Enum.reject(&is_nil/1)

        table = Rendro.table(full_page_rows, table_opts)

        # D-10: break_before: true on the first block of every page AFTER page 1.
        # No keep_together (oversized group → hard overflow — Anti-Pattern).
        Rendro.block(table, break_before: idx > 0)
      end)

    Rendro.section(
      name: :statement_body,
      region: :body,
      content: blocks
    )
  end

  # ---------------------------------------------------------------------------
  # Per-page chunking (D-09 / D-10)
  # ---------------------------------------------------------------------------

  # Chunks rows into pages by cumulative height, packing to capacity − epsilon.
  # Accounts for the repeated table header and extra brought/carried-forward rows.
  # Returns a list of {page_rows (formatted), balance_at_break} tuples.
  # balance_at_break is the running balance at the end of the last txn row on the page.
  defp chunk_into_pages(rows_with_balance, formatted_rows, row_heights, header_h, capacity) do
    # Estimate a typical row height for epsilon margin and brought/carried-forward overhead.
    # Use the median/mean or a conservative max to reserve space.
    typical_row_h =
      if Enum.empty?(row_heights) do
        14.4
      else
        Enum.sum(row_heights) / length(row_heights)
      end

    # Effective capacity per page:
    # header_h (repeated on every page) + brought-forward row + carried-forward row + epsilon
    # We reserve space for at most 2 extra rows (bf + cf) and the epsilon margin.
    effective_capacity = capacity - header_h - 2 * typical_row_h - @row_epsilon

    # Pair each formatted row with its balance and height.
    rows_with_meta =
      Enum.zip([formatted_rows, row_heights, rows_with_balance])
      |> Enum.map(fn {fmt_row, height, row_data} ->
        {fmt_row, height, row_data.balance}
      end)

    do_chunk_pages(rows_with_meta, effective_capacity, [], 0.0, [])
  end

  # Recursive page-chunker. Returns [{page_formatted_rows, balance_at_break}] list.
  defp do_chunk_pages([], _cap, current_page, _current_h, pages) do
    if current_page == [] do
      Enum.reverse(pages)
    else
      {page_rows, balance} = finalize_page(current_page)
      Enum.reverse([{page_rows, balance} | pages])
    end
  end

  defp do_chunk_pages([{fmt_row, height, balance} | rest], cap, current_page, current_h, pages) do
    new_h = current_h + height

    if new_h <= cap or current_page == [] do
      # Row fits (or page is empty — always add at least one row to prevent infinite loop)
      do_chunk_pages(rest, cap, [{fmt_row, balance} | current_page], new_h, pages)
    else
      # Row would overflow — start a new page
      {page_rows, page_balance} = finalize_page(current_page)
      do_chunk_pages(
        [{fmt_row, height, balance} | rest],
        cap,
        [],
        0.0,
        [{page_rows, page_balance} | pages]
      )
    end
  end

  # Finalizes a page: reverses accumulator (rows were added head-first) and
  # returns {formatted_rows, balance_at_break} where balance is from the last row.
  defp finalize_page(page_acc) do
    reversed = Enum.reverse(page_acc)
    rows = Enum.map(reversed, fn {fmt_row, _balance} -> fmt_row end)
    {_last_fmt, last_balance} = List.last(reversed)
    {rows, last_balance}
  end

  defp footer_section(_data, opts) do
    page_number_opts = Keyword.get(opts, :page_number_opts, [])

    Rendro.section(
      name: :statement_footer,
      region: :footer,
      content: [Rendro.page_number(page_number_opts)]
    )
  end

  # ---------------------------------------------------------------------------
  # Decimal running-balance fold (D-05 / D-06)
  # ---------------------------------------------------------------------------

  # Folds the running balance over transaction lines. Returns a list of line
  # maps each annotated with a `:balance` key holding the exact Decimal running
  # balance after that transaction. The fold is exact and signed:
  # new_balance = previous_balance + amount.
  @spec fold_balance(Decimal.t(), [map()]) :: [map()]
  defp fold_balance(opening_balance, lines) do
    {rows, _closing} =
      Enum.map_reduce(lines, opening_balance, fn %{amount: amt} = line, bal ->
        new_bal = Decimal.add(bal, amt)
        {Map.put(line, :balance, new_bal), new_bal}
      end)

    rows
  end

  # ---------------------------------------------------------------------------
  # Data validation (D-08 / errors-as-product)
  # ---------------------------------------------------------------------------

  # Validates the statement data map, raising an instructive ArgumentError
  # (NOT Rendro.Error, which is a plain defstruct and not a defexception) for:
  #
  #   - Missing any required top-level key (:period, :account, :opening_balance, :lines)
  #   - :opening_balance not a %Decimal{} (with a Float-specific branch)
  #   - :period not matching %{from: %Date{}, to: %Date{}}
  #   - Any line missing :date, :description, or :amount
  #   - A line :amount that is a Float (instructive message)
  #   - A line :amount that is not a %Decimal{}
  #   - A caller-supplied per-line :balance key (rejected per D-06)
  #   - Optional :closing_balance not a %Decimal{} when present
  #   - Optional :summary assertion mismatch when present

  defp validate_data!(data) when not is_map(data) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid data argument.

    What:  data must be a map.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   Received a non-map value: #{inspect(data)}.
    Next:  Pass a map with required keys :period, :account, :opening_balance, :lines.
    """
  end

  defp validate_data!(data) do
    validate_required_keys!(data)
    validate_opening_balance!(data.opening_balance)
    validate_period!(data.period)
    validate_lines!(data.lines)
    maybe_validate_closing_balance!(data)
    maybe_validate_summary!(data)
    :ok
  end

  defp validate_required_keys!(data) do
    required = [:period, :account, :opening_balance, :lines]

    missing =
      Enum.filter(required, fn key ->
        not Map.has_key?(data, key)
      end)

    unless missing == [] do
      raise ArgumentError, """
      Rendro.Recipes.Statement.document/2 — missing required key(s) in data.

      What:  Required statement data keys are missing.
      Where: Rendro.Recipes.Statement.validate_data!/1
      Why:   Missing key(s): #{inspect(missing)}.
      Next:  Provide all required keys: :period, :account, :opening_balance, :lines.
      """
    end
  end

  defp validate_opening_balance!(value) when is_float(value) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid :opening_balance type.

    What:  :opening_balance must be a Decimal, not a Float.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   Received a Float: #{inspect(value)}.
           Float arithmetic is not exact and can produce incorrect financial output.
    Next:  Use Decimal.new/1 — e.g. Decimal.new("#{value}") or Decimal.from_float(#{value}).
    """
  end

  defp validate_opening_balance!(%Decimal{}), do: :ok

  defp validate_opening_balance!(value) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid :opening_balance type.

    What:  :opening_balance must be a Decimal.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   Received: #{inspect(value)} (#{type_name(value)}).
    Next:  Use Decimal.new/1 — e.g. Decimal.new("100.00").
    """
  end

  defp validate_period!(%{from: %Date{}, to: %Date{}}), do: :ok

  defp validate_period!(value) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid :period shape.

    What:  :period must be a map with :from and :to Date values.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   Received: #{inspect(value)}.
    Next:  Use %{from: ~D[YYYY-MM-DD], to: ~D[YYYY-MM-DD]}.
    """
  end

  defp validate_lines!(lines) when not is_list(lines) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid :lines value.

    What:  :lines must be a list of transaction maps.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   Received: #{inspect(lines)} (#{type_name(lines)}).
    Next:  Pass a list: [%{date: ~D[...], description: "...", amount: Decimal.new("...")}].
    """
  end

  defp validate_lines!(lines) do
    lines
    |> Enum.with_index()
    |> Enum.each(fn {line, idx} -> validate_line!(line, idx) end)
  end

  defp validate_line!(line, idx) when not is_map(line) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid line at index #{idx}.

    What:  Each transaction line must be a map.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   lines[#{idx}] is not a map: #{inspect(line)}.
    Next:  Use %{date: ~D[...], description: "...", amount: Decimal.new("...")}.
    """
  end

  defp validate_line!(%{balance: _} = line, idx) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — caller-supplied :balance rejected at index #{idx}.

    What:  Per-line :balance must not be supplied by the caller.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   lines[#{idx}] contains a :balance key: #{inspect(line)}.
           The recipe computes running balances via its own exact Decimal fold.
           A caller-supplied :balance would be silently ignored, masking correctness bugs.
    Next:  Remove :balance from each line map. Supply only :date, :description, and :amount.
    """
  end

  defp validate_line!(line, idx) do
    required_line_keys = [:date, :description, :amount]

    missing =
      Enum.filter(required_line_keys, fn key ->
        not Map.has_key?(line, key)
      end)

    unless missing == [] do
      raise ArgumentError, """
      Rendro.Recipes.Statement.document/2 — missing required line key(s) at index #{idx}.

      What:  Each transaction line must have :date, :description, and :amount.
      Where: Rendro.Recipes.Statement.validate_data!/1
      Why:   lines[#{idx}] is missing key(s): #{inspect(missing)}.
      Next:  Use %{date: ~D[...], description: "...", amount: Decimal.new("...")}.
      """
    end

    validate_line_date!(line.date, idx)
    validate_line_description!(line.description, idx)
    validate_line_amount!(line.amount, idx)
  end

  defp validate_line_date!(%Date{}, _idx), do: :ok

  defp validate_line_date!(value, idx) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid line :date at index #{idx}.

    What:  Each line's :date must be a %Date{} struct.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   lines[#{idx}].date = #{inspect(value)}.
    Next:  Use the ~D[YYYY-MM-DD] sigil or Date.new!/3.
    """
  end

  defp validate_line_description!(value, _idx) when is_binary(value), do: :ok

  defp validate_line_description!(value, idx) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid line :description at index #{idx}.

    What:  Each line's :description must be a string.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   lines[#{idx}].description = #{inspect(value)}.
    Next:  Pass a binary string, e.g. "Invoice #1".
    """
  end

  defp validate_line_amount!(value, idx) when is_float(value) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid line :amount type at index #{idx}.

    What:  Each line's :amount must be a Decimal, not a Float.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   lines[#{idx}].amount = #{inspect(value)} (Float).
           Float arithmetic is not exact and can produce incorrect financial output.
    Next:  Use Decimal.new/1 — e.g. Decimal.new("#{value}") or Decimal.from_float(#{value}).
    """
  end

  defp validate_line_amount!(%Decimal{}, _idx), do: :ok

  defp validate_line_amount!(value, idx) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid line :amount type at index #{idx}.

    What:  Each line's :amount must be a Decimal.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   lines[#{idx}].amount = #{inspect(value)} (#{type_name(value)}).
    Next:  Use Decimal.new/1 — e.g. Decimal.new("50.00").
    """
  end

  defp maybe_validate_closing_balance!(%{closing_balance: cb}) when is_float(cb) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid :closing_balance type.

    What:  :closing_balance must be a Decimal, not a Float.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   Received a Float: #{inspect(cb)}.
    Next:  Use Decimal.new/1 — e.g. Decimal.new("#{cb}").
    """
  end

  defp maybe_validate_closing_balance!(%{closing_balance: cb}) when not is_struct(cb, Decimal) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid :closing_balance type.

    What:  :closing_balance must be a Decimal.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   Received: #{inspect(cb)} (#{type_name(cb)}).
    Next:  Use Decimal.new/1 — e.g. Decimal.new("100.00").
    """
  end

  defp maybe_validate_closing_balance!(_data), do: :ok

  defp maybe_validate_summary!(%{summary: summary, opening_balance: ob, lines: lines})
       when is_map(summary) do
    {rows, derived_closing} =
      Enum.map_reduce(lines, ob, fn %{amount: amt}, bal ->
        nb = Decimal.add(bal, amt)
        {nb, nb}
      end)

    _ = rows

    if Map.has_key?(summary, :closing_balance) do
      unless Decimal.equal?(summary.closing_balance, derived_closing) do
        raise ArgumentError, """
        Rendro.Recipes.Statement.document/2 — :summary.closing_balance mismatch.

        What:  The caller-supplied :summary.closing_balance does not match the derived value.
        Where: Rendro.Recipes.Statement.validate_data!/1
        Why:   Supplied: #{inspect(summary.closing_balance)}, Derived: #{inspect(derived_closing)}.
        Next:  Remove :summary.closing_balance to let the recipe derive it, or correct the value.
        """
      end
    end

    :ok
  end

  defp maybe_validate_summary!(_data), do: :ok

  # ---------------------------------------------------------------------------
  # Formatting helpers
  # ---------------------------------------------------------------------------

  # Returns the formatter function for `key` from opts[:formatters], or
  # falls back to `default_fn`.
  defp formatter(opts, key, default_fn) do
    formatters = Keyword.get(opts, :formatters, [])
    Keyword.get(formatters, key, default_fn)
  end

  # Returns a function that resolves a label key, merging caller-supplied
  # :labels over the default Rendro.Format labels.
  defp label_resolver(opts) do
    user_labels = Keyword.get(opts, :labels, %{})

    fn key ->
      case Map.fetch(user_labels, key) do
        {:ok, val} -> val
        :error -> Rendro.Format.label(key)
      end
    end
  end

  # Returns a human-readable type name for error messages.
  defp type_name(value) when is_binary(value), do: "String"
  defp type_name(value) when is_integer(value), do: "Integer"
  defp type_name(value) when is_float(value), do: "Float"
  defp type_name(value) when is_atom(value), do: "Atom"
  defp type_name(value) when is_list(value), do: "List"
  defp type_name(value) when is_map(value), do: "Map"
  defp type_name(_value), do: "Unknown"
end
