defmodule Rendro.Recipes.Receipt do
  @moduledoc """
  Payment receipt and tabular report recipe using the Tiered Composition pattern.

  A single-page receipt and a multi-page tabular "report" are the same recipe —
  multi-page is just a receipt whose line items overflow one page. Column headers
  repeat on every page via per-page table blocks; "Page X of Y" appears in the
  footer via `Rendro.page_number/1`.

  Exposes three levels of composability:

    - `document/2`      — Batteries-included; accepts a receipt data map and
                          returns a fully assembled `%Rendro.Document{}` ready
                          for `Rendro.render/1`. No template authoring required.
    - `page_template/1` — Layout only; returns the `%Rendro.PageTemplate{}`.
    - `sections/2`      — Content only; returns a list of `%Rendro.Section{}`
                          structs mapped to named regions.

  ## Data contract

  Required keys in `data`:

    - `:title`    — `String.t()` (e.g. "Payment Receipt").
    - `:date`     — `Date.t()` (issue date).
    - `:customer` — `%{name: String.t()}` (customer information).
    - `:lines`    — `[%{description: String.t(), amount: Decimal.t()}]`
      (line items; amounts must be Decimal, not Float).

  Optional keys:

    - `:totals` — `%{subtotal: Decimal.t(), total: Decimal.t()}` (caller
      assertions; `subtotal` is validated against the sum of line amounts via
      `Decimal.equal?/2` when present).

  ## Usage

  ### Zero-to-one (just works)

      data = %{
        title: "Payment Receipt",
        date: ~D[2026-05-29],
        customer: %{name: "Acme Corp"},
        lines: [
          %{description: "Widget A", amount: Decimal.new("29.99")},
          %{description: "Widget B", amount: Decimal.new("49.99")}
        ],
        totals: %{subtotal: Decimal.new("79.98"), total: Decimal.new("79.98")}
      }
      doc = Rendro.Recipes.Receipt.document(data)
      {:ok, pdf} = Rendro.render(doc)

  ### Escape hatch — inject a custom template

      template = Rendro.Recipes.Receipt.page_template(name: :my_receipt)
      sections = Rendro.Recipes.Receipt.sections(data)
      doc =
        Rendro.Document.new()
        |> Rendro.Document.add_template(template)
        |> Rendro.Document.set_template(:my_receipt)
        |> then(fn d -> Enum.reduce(sections, d, &Rendro.Document.add_section(&2, &1)) end)

  ## Formatting

  Default formatting is provided by `Rendro.Format` (pure, locale-free, deterministic):
  money as `$1,234.50` (parentheses for negatives) and dates as `YYYY-MM-DD`.

  Override defaults via `opts`:

      Rendro.Recipes.Receipt.document(data,
        formatters: [
          amount: fn %Decimal{} = d -> MyApp.Money.format(d) end,
          date:   fn %Date{} = d   -> MyApp.Locale.format_date(d) end
        ]
      )
  """
  @moduledoc tags: [:adapter]

  # ---------------------------------------------------------------------------
  # Layout geometry constants (all in points)
  # A4: 595.28 × 841.89 pt; default margins: 72 pt (1 inch)
  # Available column width: 595.28 - 2 × 72 = 451.28 pt
  # ---------------------------------------------------------------------------

  @page_width 595.28
  @page_height 841.89
  @margin 72

  @content_width @page_width - 2 * @margin

  # Header reserved height (title + customer name + date rows). 118-08
  # gap-closure: this is the DEFAULT used when no :merchant is present in
  # `data` — an optional merchant identity block adds a line and needs a
  # taller header, computed per-call by computed_header_height/1 below (never
  # a stale constant, which previously caused :content_overflow rendering
  # the realistic harbor-and-oak-cafe fixture end-to-end).
  @default_header_height 48

  # Footer reserved height — MUST be non-zero so body_capacity reserves space
  # and "Page X of Y" does not overlap the last body row (PAGE-03).
  @footer_height 24

  @footer_y @page_height - @margin - @footer_height

  # Default table column rules: Description | Amount
  @table_columns [{:share, 1}, {:fixed, 72}]

  # Conservative one-row epsilon margin: pack to capacity − epsilon so
  # sub-pixel rounding never tips a page into :content_overflow.
  @row_epsilon 2.0

  # ---------------------------------------------------------------------------
  # Public API — three-rung escape hatch (consistent with Invoice / RCPT-02)
  # ---------------------------------------------------------------------------

  @doc """
  Returns a `%Rendro.PageTemplate{}` with three named regions: `:header`,
  `:body`, and `:footer`.

  The footer region has a non-zero height so `body_capacity` reserves space for
  the "Page X of Y" page-number text (PAGE-03).

  ## Options

  All options are forwarded to `%Rendro.PageTemplate{}` as keyword overrides.
  The `name` defaults to `:receipt`.

  ## Examples

      iex> t = Rendro.Recipes.Receipt.page_template()
      iex> t.name
      :receipt
      iex> footer = Enum.find(t.regions, & &1.role == :footer)
      iex> footer.height > 0
      true

  """
  @spec page_template(keyword()) :: Rendro.PageTemplate.t()
  def page_template(opts \\ []) do
    header_height = Keyword.get(opts, :header_height, @default_header_height)
    body_y = @margin + header_height
    body_height = @page_height - 2 * @margin - header_height - @footer_height
    colors = palette(opts)

    base_regions = [
      Rendro.region(
        name: :header,
        role: :header,
        anchor: :top,
        x: @margin,
        y: @margin,
        width: @content_width,
        height: header_height
      ),
      Rendro.region(
        name: :body,
        role: :body,
        anchor: :flow,
        x: @margin,
        y: body_y,
        width: @content_width,
        height: body_height
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

    # 121-03: prepend the shared :background region FIRST iff the resolved
    # palette differs from paper-white — gated on the SAME palette(opts)
    # sections/2 uses below (Pitfall 3). Light no-theme path is untouched.
    regions =
      if Rendro.Recipes.Background.emit?(colors) do
        [Rendro.Recipes.Background.region(@page_width, @page_height) | base_regions]
      else
        base_regions
      end

    defaults = [
      name: :receipt,
      regions: regions
    ]

    # page_template/1 only understands PageTemplate struct keys. Recipe-level
    # opts (:header_height, :palette, :theme, :formatters, :labels, ...) are
    # consumed locally by this function / the section builders / palette/1 --
    # filter them out with a struct-key whitelist so they thread through to
    # sections/2 / palette/1 instead of reaching struct!/2 and raising
    # KeyError. :header_height stays consumed locally above; :palette/:theme
    # must NOT be added here -- dropping them lets them reach palette/1.
    template_opts =
      Keyword.take(opts, [
        :name,
        :width,
        :height,
        :margin_top,
        :margin_right,
        :margin_bottom,
        :margin_left,
        :regions
      ])

    Rendro.page_template(Keyword.merge(defaults, template_opts))
  end

  @doc """
  Returns a list of `%Rendro.Section{}` structs mapping receipt content to
  the `:header`, `:body`, and `:footer` regions.

  Validates `data` via `validate_data!/1` before building sections.

  ## Examples

      iex> data = %{
      ...>   title: "Payment Receipt",
      ...>   date: ~D[2026-05-29],
      ...>   customer: %{name: "Acme Corp"},
      ...>   lines: []
      ...> }
      iex> [header, body, footer] = Rendro.Recipes.Receipt.sections(data)
      iex> header.region
      :header
      iex> footer.region
      :footer

  """
  @spec sections(map(), keyword()) :: [Rendro.Section.t()]
  def sections(data, opts \\ []) do
    validate_data!(data)

    colors = palette(opts)

    base_sections = [
      header_section(data, opts),
      body_section(data, opts),
      footer_section(data, opts)
    ]

    # Same predicate + same palette(opts) as page_template/1 (Pitfall 3) —
    # the region and section can never disagree.
    if Rendro.Recipes.Background.emit?(colors) do
      [Rendro.Recipes.Background.section(colors, @page_width, @page_height) | base_sections]
    else
      base_sections
    end
  end

  @doc """
  Assembles and returns a fully composed `%Rendro.Document{}` from a receipt
  data map.

  Validates `data` via `validate_data!/1`, then builds the page template and
  sections, reducing them through the Document builder API.

  ## Examples

      iex> data = %{
      ...>   title: "Payment Receipt",
      ...>   date: ~D[2026-05-29],
      ...>   customer: %{name: "Acme Corp"},
      ...>   lines: []
      ...> }
      iex> doc = Rendro.Recipes.Receipt.document(data)
      iex> doc.page_template
      :receipt

  """
  @spec document(map(), keyword()) :: Rendro.Document.t()
  def document(data, opts \\ []) do
    validate_data!(data)
    # 118-08: thread ONE resolved :header_height through both page_template/1
    # and sections/2 so the header region is tall enough for an optional
    # :merchant identity block — see computed_header_height/1.
    opts = Keyword.put_new(opts, :header_height, computed_header_height(data))
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

  defp header_section(%{title: title, date: date, customer: customer} = data, opts) do
    colors = palette(opts)
    fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)
    customer_name = Map.get(customer, :name, "")

    base_content = [
      Rendro.block(Rendro.text(title, size: 14, color: colors.ink)),
      Rendro.block(Rendro.text(customer_name, size: 12, color: colors.ink)),
      Rendro.block(Rendro.text(fmt_date.(date), size: 10, color: colors.ink))
    ]

    # 118-08 gap-closure (SHOW-01): render the merchant identity (previously
    # absent from the data path entirely — see transform_receipt/1). Prepend
    # so the merchant reads as the issuer of the receipt, ahead of the title.
    content =
      base_content
      |> maybe_prepend(Map.get(data, :merchant), &merchant_block(&1, colors))

    Rendro.section(
      name: :receipt_header,
      region: :header,
      content: content
    )
  end

  defp maybe_prepend(content, nil, _fun), do: content
  defp maybe_prepend(content, value, fun), do: [fun.(value) | content]

  defp merchant_block(merchant, colors) when is_map(merchant) do
    name = Map.get(merchant, :name, "")
    address = Map.get(merchant, :address)
    text = if address in [nil, ""], do: name, else: "#{name}\n#{address}"
    Rendro.block(Rendro.text(text, size: 16, color: colors.ink))
  end

  defp body_section(%{lines: lines} = data, opts) do
    fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)

    table_header = ["Description", "Amount"]
    table_opts = [header: table_header, columns: @table_columns]

    # Format all rows as strings for measurement and display
    formatted_rows =
      Enum.map(lines, fn %{description: desc, amount: amt} ->
        [desc, fmt_amount.(amt)]
      end)

    # Measure all rows at the body region width using engine's own font metrics.
    # This avoids recipe-local estimates that cause :content_overflow (D-09).
    doc_for_measure = Rendro.Document.new()

    {header_h, row_heights} =
      Rendro.measure_rows(formatted_rows, @content_width, doc_for_measure, table_opts)

    # 118-08: resolve the SAME header height page_template/1 uses for this
    # call so body capacity accounting matches the actual rendered header
    # region — never a stale constant.
    resolved_header_height = Keyword.get(opts, :header_height, computed_header_height(data))
    body_height = @page_height - 2 * @margin - resolved_header_height - @footer_height

    # Body capacity (mirrors body_capacity formula for this template's geometry):
    # capacity = body.height − header_region.height − footer_region.height
    capacity = body_height - resolved_header_height - @footer_height

    # Receipt effective_capacity: no CF/BF overhead.
    # Statement subtracts 2 * typical_row_h for brought/carried-forward rows;
    # Receipt has no such rows — only subtract the table header and epsilon.
    effective_capacity = capacity - header_h - @row_epsilon

    # Build rows_with_meta triples: [{fmt_row, height, nil}]
    # nil meta — Receipt has no per-row balance tracking.
    rows_with_meta =
      Enum.zip(formatted_rows, row_heights)
      |> Enum.map(fn {fmt_row, height} -> {fmt_row, height, nil} end)

    pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)

    # Emit one table block per page. break_before: true on every page after the first.
    # NEVER use keep_together (oversized group → :content_overflow anti-pattern).
    table_blocks =
      pages
      |> Enum.with_index()
      |> Enum.map(fn {{page_rows, _meta}, idx} ->
        table = Rendro.table(page_rows, table_opts)
        Rendro.block(table, break_before: idx > 0)
      end)

    # Append totals block after the last table block (on the final page).
    totals_blocks = build_totals_blocks(data, opts)
    all_blocks = table_blocks ++ totals_blocks

    Rendro.section(
      name: :receipt_body,
      region: :body,
      content: all_blocks
    )
  end

  defp footer_section(_data, opts) do
    page_number_opts = Keyword.get(opts, :page_number_opts, [])

    Rendro.section(
      name: :receipt_footer,
      region: :footer,
      content: [Rendro.page_number(page_number_opts)]
    )
  end

  # ---------------------------------------------------------------------------
  # Totals block builder
  # ---------------------------------------------------------------------------

  # 118-08 gap-closure (SHOW-01): the Total must be the single dominant
  # element on the receipt (content_hierarchy=5 anchor) — not small bottom
  # text alongside Subtotal/Tax. Subtotal/Tax/Discount render small in one
  # block; Total renders alone, much larger, in its own trailing block.
  @minor_totals_size 9
  @dominant_total_size 18

  defp build_totals_blocks(%{totals: totals} = _data, opts) when is_map(totals) do
    fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)
    colors = palette(opts)

    minor_lines =
      []
      |> maybe_append_totals_line("Subtotal", Map.get(totals, :subtotal), fmt_amount)
      |> maybe_append_totals_line("Tax", Map.get(totals, :tax), fmt_amount)
      |> maybe_append_totals_line("Discount", Map.get(totals, :discount), fmt_amount)

    minor_block =
      if minor_lines == [] do
        []
      else
        [
          Rendro.block(
            Rendro.text(Enum.join(minor_lines, "\n"),
              size: @minor_totals_size,
              color: colors.ink
            )
          )
        ]
      end

    total_block =
      case Map.get(totals, :total) do
        %Decimal{} = total ->
          [
            Rendro.block(
              Rendro.text("Total: #{fmt_amount.(total)}",
                size: @dominant_total_size,
                color: colors.ink
              )
            )
          ]

        _ ->
          []
      end

    minor_block ++ total_block
  end

  defp build_totals_blocks(_data, _opts), do: []

  defp maybe_append_totals_line(acc, _label, nil, _fmt), do: acc

  defp maybe_append_totals_line(acc, label, %Decimal{} = amount, fmt) do
    acc ++ ["#{label}: #{fmt.(amount)}"]
  end

  # 118-08 gap-closure (SHOW-01): the default header height was sized for
  # exactly 3 lines (title + customer + date) — an optional :merchant block
  # adds a line (2 if it carries an address) and needs a taller header
  # region or its content raises :content_overflow (discovered rendering
  # the enriched harbor-and-oak-cafe fixture end-to-end). Grows the header
  # ONLY when :merchant is present, so a caller without one still computes
  # exactly @default_header_height — unchanged geometry otherwise.
  @spec computed_header_height(map()) :: number()
  defp computed_header_height(data) do
    case Map.get(data, :merchant) do
      nil -> @default_header_height
      # merchant_block/1 renders at size 16 (2 lines when an address is
      # present: 16 * 1.2 * 2 = 38.4pt) -- +40 comfortably covers both the
      # 1-line (name only) and 2-line (name + address) cases.
      _present -> @default_header_height + 40
    end
  end

  # ---------------------------------------------------------------------------
  # Color seam (S1 / PLUMB-01)
  # ---------------------------------------------------------------------------

  # Returns the role → RGB map for this render. When no `:theme` is supplied the
  # `nil` branch reproduces today's implicit black ink / white surfaces
  # (`ink {0, 0, 0}`, which renders identically to no color arg) so every text
  # run stays byte-identical (PLUMB-03). When a `:theme` is supplied the base
  # becomes `Rendro.Theme.resolve(theme).colors` (9 integer-{r,g,b} roles,
  # colors ONLY — no type-scale read) and a themed `ink` recolors the primary
  # text. The final `Map.merge(base, :palette-override)` keeps an explicit
  # `:palette` as the winning layer (D-01).
  defp palette(opts) do
    base =
      case opts[:theme] do
        nil ->
          %{
            ink: {0, 0, 0},
            muted: {0, 0, 0},
            accent: {0, 0, 0},
            on_accent: {0, 0, 0},
            background: {255, 255, 255},
            surface: {255, 255, 255},
            rule: {0, 0, 0}
          }

        theme ->
          Rendro.Theme.resolve(theme).colors
      end

    Map.merge(base, Keyword.get(opts, :palette, %{}))
  end

  # ---------------------------------------------------------------------------
  # Data validation (errors-as-product)
  # ---------------------------------------------------------------------------

  defp validate_data!(data) when not is_map(data) do
    raise ArgumentError, """
    Rendro.Recipes.Receipt.document/2 — invalid data argument.

    What:  data must be a map.
    Where: Rendro.Recipes.Receipt.validate_data!/1
    Why:   Received a non-map value: #{inspect(data)}.
    Next:  Pass a map with required keys :title, :date, :customer, :lines.
    """
  end

  defp validate_data!(data) do
    validate_required_keys!(data)
    validate_customer!(data.customer)
    validate_date!(data.date)
    validate_lines!(data.lines)
    maybe_validate_totals!(data)
    :ok
  end

  defp validate_required_keys!(data) do
    required = [:title, :date, :customer, :lines]

    missing =
      Enum.filter(required, fn key ->
        not Map.has_key?(data, key)
      end)

    unless missing == [] do
      raise ArgumentError, """
      Rendro.Recipes.Receipt.document/2 — missing required key(s) in data.

      What:  Required receipt data keys are missing.
      Where: Rendro.Recipes.Receipt.validate_data!/1
      Why:   Missing key(s): #{inspect(missing)}.
      Next:  Provide all required keys: :title, :date, :customer, :lines.
      """
    end
  end

  defp validate_customer!(%{name: name}) when is_binary(name), do: :ok

  defp validate_customer!(value) do
    raise ArgumentError, """
    Rendro.Recipes.Receipt.document/2 — invalid :customer shape.

    What:  :customer must be a map with a string :name.
    Where: Rendro.Recipes.Receipt.validate_data!/1
    Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
    Next:  Use %{name: "Acme Corp"}.
    """
  end

  defp validate_date!(%Date{}), do: :ok

  defp validate_date!(value) do
    raise ArgumentError, """
    Rendro.Recipes.Receipt.document/2 — invalid :date type.

    What:  :date must be a %Date{} struct.
    Where: Rendro.Recipes.Receipt.validate_data!/1
    Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
    Next:  Use the ~D[YYYY-MM-DD] sigil or Date.new!/3.
    """
  end

  defp validate_lines!(lines) when not is_list(lines) do
    raise ArgumentError, """
    Rendro.Recipes.Receipt.document/2 — invalid :lines value.

    What:  :lines must be a list of line item maps.
    Where: Rendro.Recipes.Receipt.validate_data!/1
    Why:   Received: #{inspect(lines)} (#{Rendro.Recipes.Pagination.type_name(lines)}).
    Next:  Pass a list: [%{description: "...", amount: Decimal.new("...")}].
    """
  end

  defp validate_lines!(lines) do
    lines
    |> Enum.with_index()
    |> Enum.each(fn {line, idx} -> validate_line!(line, idx) end)
  end

  defp validate_line!(line, idx) when not is_map(line) do
    raise ArgumentError, """
    Rendro.Recipes.Receipt.document/2 — invalid line at index #{idx}.

    What:  Each line item must be a map.
    Where: Rendro.Recipes.Receipt.validate_data!/1
    Why:   lines[#{idx}] is not a map: #{inspect(line)}.
    Next:  Use %{description: "...", amount: Decimal.new("...")}.
    """
  end

  defp validate_line!(line, idx) do
    required_line_keys = [:description, :amount]

    missing =
      Enum.filter(required_line_keys, fn key ->
        not Map.has_key?(line, key)
      end)

    unless missing == [] do
      raise ArgumentError, """
      Rendro.Recipes.Receipt.document/2 — missing required line key(s) at index #{idx}.

      What:  Each line item must have :description and :amount.
      Where: Rendro.Recipes.Receipt.validate_data!/1
      Why:   lines[#{idx}] is missing key(s): #{inspect(missing)}.
      Next:  Use %{description: "...", amount: Decimal.new("...")}.
      """
    end

    validate_line_amount!(line.amount, idx)
  end

  defp validate_line_amount!(value, idx) when is_float(value) do
    raise ArgumentError, """
    Rendro.Recipes.Receipt.document/2 — invalid line :amount type at index #{idx}.

    What:  Each line's :amount must be a Decimal, not a Float.
    Where: Rendro.Recipes.Receipt.validate_data!/1
    Why:   lines[#{idx}].amount = #{inspect(value)} (Float).
           Float arithmetic is not exact and can produce incorrect financial output.
    Next:  Use Decimal.new/1 — e.g. Decimal.new("#{value}") or Decimal.from_float(#{value}).
    """
  end

  defp validate_line_amount!(%Decimal{}, _idx), do: :ok

  defp validate_line_amount!(value, idx) do
    raise ArgumentError, """
    Rendro.Recipes.Receipt.document/2 — invalid line :amount type at index #{idx}.

    What:  Each line's :amount must be a Decimal.
    Where: Rendro.Recipes.Receipt.validate_data!/1
    Why:   lines[#{idx}].amount = #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
    Next:  Use Decimal.new/1 — e.g. Decimal.new("50.00").
    """
  end

  # Validates caller-supplied totals against derived values using Decimal.equal?/2.
  defp maybe_validate_totals!(%{totals: totals, lines: lines}) when is_map(totals) do
    derived_subtotal =
      Enum.reduce(lines, Decimal.new(0), fn %{amount: amt}, acc ->
        Decimal.add(acc, amt)
      end)

    if Map.has_key?(totals, :subtotal) do
      unless Decimal.equal?(totals.subtotal, derived_subtotal) do
        raise ArgumentError, """
        Rendro.Recipes.Receipt.document/2 — :totals.subtotal mismatch.

        What:  The caller-supplied :totals.subtotal does not match the sum of line amounts.
        Where: Rendro.Recipes.Receipt.validate_data!/1
        Why:   Supplied subtotal: #{inspect(totals.subtotal)},
               Derived subtotal: #{inspect(derived_subtotal)} (sum of lines.amount).
        Next:  Remove :totals.subtotal to skip this check, or correct the value.
        """
      end
    end

    if Map.has_key?(totals, :total) do
      # total must equal subtotal (possibly including tax - discount)
      # Here we validate total == derived_subtotal for the simple case.
      # If tax/discount are present, we compute: total == subtotal + tax - discount
      base = derived_subtotal
      tax = Map.get(totals, :tax)
      discount = Map.get(totals, :discount)

      expected_total =
        base
        |> then(fn t -> if is_struct(tax, Decimal), do: Decimal.add(t, tax), else: t end)
        |> then(fn t ->
          if is_struct(discount, Decimal), do: Decimal.sub(t, discount), else: t
        end)

      unless Decimal.equal?(totals.total, expected_total) do
        raise ArgumentError, """
        Rendro.Recipes.Receipt.document/2 — :totals.total mismatch.

        What:  The caller-supplied :totals.total does not match the derived value.
        Where: Rendro.Recipes.Receipt.validate_data!/1
        Why:   Supplied total: #{inspect(totals.total)},
               Derived total: #{inspect(expected_total)}.
        Next:  Remove :totals.total to skip this check, or correct the value.
        """
      end
    end

    :ok
  end

  defp maybe_validate_totals!(_data), do: :ok
end
