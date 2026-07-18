defmodule Rendro.Recipes.Invoice do
  @moduledoc """
  Canonical invoice recipe using the Tiered Composition pattern.

  Exposes three levels of composability:

    - `document/2`      — Batteries-included; returns a fully assembled
                          `%Rendro.Document{}` ready for `Rendro.render/1`.
    - `page_template/1` — Layout only; returns the `%Rendro.PageTemplate{}`.
    - `sections/2`      — Content only; returns a list of `%Rendro.Section{}`
                          structs mapped to named regions.

  ## Usage

  ### Zero-to-one (just works)

      data = %{id: "INV-001", date: ~D[2026-01-15], items: [...]}
      doc  = Rendro.Recipes.Invoice.document(data)
      {:ok, pdf} = Rendro.render(doc)

  ### Escape hatch — inject a custom template

      template = Rendro.Recipes.Invoice.page_template(name: :branded)
      sections = Rendro.Recipes.Invoice.sections(data)
      doc =
        Rendro.Document.new()
        |> Rendro.Document.add_template(template)
        |> Rendro.Document.set_template(:branded)
        |> then(fn d -> Enum.reduce(sections, d, &Rendro.Document.add_section(&2, &1)) end)

  """
  @moduledoc tags: [:adapter]

  @page_width 595.28
  @page_height 841.89
  @margin 72
  @content_width @page_width - 2 * @margin
  @header_height 56
  @footer_height 24
  @body_y @margin + @header_height
  @body_height @page_height - 2 * @margin - @header_height - @footer_height
  @footer_y @page_height - @margin - @footer_height

  # Default table column rules: Item | Qty | Price.
  @table_columns [{:share, 1}, {:fixed, 50}, {:fixed, 80}]

  # Conservative one-row epsilon margin: pack to capacity − epsilon so
  # sub-pixel rounding never tips a page into :content_overflow (mirrors
  # Receipt/Statement).
  @row_epsilon 2.0

  # Conservative per-line height reserved for the totals block on every page
  # (INV-03) so the LAST table page never fully exhausts its capacity — the
  # shared Rendro.Recipes.Pagination chunker only accepts one uniform
  # effective_capacity, so (mirroring how Statement reserves CF/BF rows on
  # every page) totals height is reserved on every page, guaranteeing
  # whichever page ends up last always has room for the totals block that
  # trails it. No exact text measurement exists for a plain text block, so
  # this is a conservative estimate at size: 10 (never used to change
  # rendered geometry, only chunking decisions).
  @totals_line_height 14

  @doc """
  Returns a `%Rendro.PageTemplate{}` with three named regions: `:header`, `:body`, `:footer`.

  ## Options

  All options are forwarded to `%Rendro.PageTemplate{}` as keyword overrides.
  The `name` defaults to `:invoice`.

  ## Examples

      iex> Rendro.Recipes.Invoice.page_template()
      %Rendro.PageTemplate{name: :invoice, ...}

      iex> Rendro.Recipes.Invoice.page_template(name: :branded)
      %Rendro.PageTemplate{name: :branded, ...}

  """
  @spec page_template(keyword()) :: Rendro.PageTemplate.t()
  def page_template(opts \\ []) do
    defaults = [
      name: :invoice,
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

    # page_template/1 only understands PageTemplate struct keys. Recipe-level
    # opts (:formatters, :labels, :palette, ...) are consumed by the section
    # builders via opts, not here — filter them out so they thread through to
    # sections/2 / palette/1 instead of reaching struct!/2 and raising KeyError.
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
  Returns a list of `%Rendro.Section{}` structs mapping invoice content to
  the `:header`, `:body`, and `:footer` regions.

  ## Examples

      iex> data = %{id: "INV-001", date: ~D[2026-01-15], items: []}
      iex> [header, body, footer] = Rendro.Recipes.Invoice.sections(data)
      iex> header.region
      :header

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
  Assembles and returns a fully composed `%Rendro.Document{}` using the
  pipeline builder API.

  Uses `page_template/1` and `sections/2` internally, then chains them
  through `Rendro.Document.new/0 |> add_template |> set_template |> add_section`.

  ## Examples

      iex> data = %{id: "INV-001", date: ~D[2026-01-15], items: []}
      iex> doc = Rendro.Recipes.Invoice.document(data)
      iex> doc.page_template
      :invoice

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
  # Private builders
  # ---------------------------------------------------------------------------

  defp header_section(%{id: id, date: date} = data, opts) do
    colors = palette(opts)
    fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)

    # FROZEN toy path (INV-01) — these two lines MUST stay literally
    # unchanged: no color:, no formatter. New anatomy fields render only
    # when present and are added as NEW blocks around this base pair.
    base_content = [
      Rendro.block(Rendro.text("INVOICE ##{id}", size: 18)),
      Rendro.block(Rendro.text("Date: #{date}", size: 10))
    ]

    content =
      base_content
      |> maybe_prepend(Map.get(data, :issuer), &issuer_block(&1, colors))
      |> maybe_append(Map.get(data, :customer), &customer_block(&1, colors))
      |> maybe_append(Map.get(data, :due_date), &due_date_block(&1, colors, fmt_date))
      |> maybe_append(Map.get(data, :terms), &terms_block(&1, colors))

    Rendro.section(
      name: :invoice_header,
      region: :header,
      content: content
    )
  end

  defp body_section(%{items: items} = data, opts) do
    # FROZEN toy path (INV-01) — the line-item mapping and "$#{item.price}"
    # cell MUST stay literally unchanged; the legacy bare-number price is
    # NEVER routed through Rendro.Format.money/1 (that would turn "$200"
    # into "$200.00" and break byte-compat with the toy call).
    formatted_rows =
      Enum.map(items, fn item ->
        [item.name, Integer.to_string(item.qty), "$#{item.price}"]
      end)

    table_opts = [header: ["Item", "Qty", "Price"], columns: @table_columns]

    # Measure all rows at the body region width using the engine's own font
    # metrics (D-09) — avoids recipe-local estimates that cause
    # :content_overflow. A single-page toy call (2 items) fits well within
    # capacity and yields exactly one, byte-identical table block below.
    doc_for_measure = Rendro.Document.new()

    {header_h, row_heights} =
      Rendro.measure_rows(formatted_rows, @content_width, doc_for_measure, table_opts)

    capacity = @body_height - @header_height - @footer_height

    # INV-03 "kept with the last rows" — the ONE place Invoice must exceed a
    # pure Receipt copy (Receipt appends totals without reserving space, so
    # totals can flow to a fresh page). Reserving the totals height on every
    # page (see @totals_line_height doc) guarantees the final table page
    # always has room left for the totals block that trails it.
    effective_capacity = capacity - header_h - totals_reserved_height(data) - @row_epsilon

    rows_with_meta =
      Enum.zip(formatted_rows, row_heights)
      |> Enum.map(fn {fmt_row, height} -> {fmt_row, height, nil} end)

    pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)

    # One table block per page. break_before: true on every page after the
    # first. NEVER keep_together (oversized group → :content_overflow).
    table_blocks =
      pages
      |> Enum.with_index()
      |> Enum.map(fn {{page_rows, _meta}, idx} ->
        table = Rendro.table(page_rows, table_opts)
        Rendro.block(table, break_before: idx > 0)
      end)

    # Totals are appended after the LAST table block (on the final page) —
    # never wrapped in keep_together.
    totals_blocks = build_totals_blocks(data, opts)

    Rendro.section(
      name: :invoice_body,
      region: :body,
      content: table_blocks ++ totals_blocks
    )
  end

  # Conservative reserved height for the totals block, used only to bias
  # per-page chunking capacity — never to change rendered geometry.
  defp totals_reserved_height(%{totals: totals}) when is_map(totals) do
    line_count =
      Enum.count([:subtotal, :tax, :discount, :total], fn key ->
        match?(%Decimal{}, Map.get(totals, key))
      end)

    line_count * @totals_line_height
  end

  defp totals_reserved_height(_data), do: 0

  defp footer_section(_data, opts) do
    colors = palette(opts)

    Rendro.section(
      name: :invoice_footer,
      region: :footer,
      content: [
        Rendro.block(Rendro.text("Thank you for your business!", size: 10, color: colors.ink))
      ]
    )
  end

  # ---------------------------------------------------------------------------
  # Optional anatomy blocks (INV-01) — render only when present in data
  # ---------------------------------------------------------------------------

  defp maybe_prepend(content, nil, _fun), do: content
  defp maybe_prepend(content, value, fun), do: [fun.(value) | content]

  defp maybe_append(content, nil, _fun), do: content
  defp maybe_append(content, value, fun), do: content ++ [fun.(value)]

  defp issuer_block(issuer, colors) when is_map(issuer) do
    name = Map.get(issuer, :name, "")
    address = Map.get(issuer, :address)
    text = if address in [nil, ""], do: name, else: "#{name}\n#{address}"
    Rendro.block(Rendro.text(text, size: 12, color: colors.ink))
  end

  defp customer_block(customer, colors) when is_map(customer) do
    name = Map.get(customer, :name, "")
    address = Map.get(customer, :address)
    text = if address in [nil, ""], do: "Bill To: #{name}", else: "Bill To: #{name}\n#{address}"
    Rendro.block(Rendro.text(text, size: 10, color: colors.muted))
  end

  defp due_date_block(due_date, colors, fmt_date) do
    Rendro.block(Rendro.text("Due: #{fmt_date.(due_date)}", size: 10, color: colors.muted))
  end

  defp terms_block(terms, colors) do
    Rendro.block(Rendro.text("Terms: #{terms}", size: 10, color: colors.muted))
  end

  # ---------------------------------------------------------------------------
  # Totals block builder (INV-02 / INV-03 rendering half)
  # ---------------------------------------------------------------------------

  defp build_totals_blocks(%{totals: totals} = _data, opts) when is_map(totals) do
    fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)

    lines =
      []
      |> maybe_append_totals_line("Subtotal", Map.get(totals, :subtotal), fmt_amount)
      |> maybe_append_totals_line("Tax", Map.get(totals, :tax), fmt_amount)
      |> maybe_append_totals_line("Discount", Map.get(totals, :discount), fmt_amount)
      |> maybe_append_totals_line("Total", Map.get(totals, :total), fmt_amount)

    if lines == [] do
      []
    else
      [Rendro.block(Rendro.text(Enum.join(lines, "\n"), size: 10))]
    end
  end

  defp build_totals_blocks(_data, _opts), do: []

  defp maybe_append_totals_line(acc, _label, nil, _fmt), do: acc

  defp maybe_append_totals_line(acc, label, %Decimal{} = amount, fmt) do
    acc ++ ["#{label}: #{fmt.(amount)}"]
  end

  # ---------------------------------------------------------------------------
  # Color seam (INV-07 / S1)
  # ---------------------------------------------------------------------------

  # Returns the role → RGB map for this render. Defaults reproduce today's
  # literals (all-black ink, white surfaces) so sections that read colors from
  # here stay byte-identical unless the caller supplies a `:palette` override.
  # Any section that sets a color MUST source it from here — never inline a
  # literal `{r, g, b}` tuple — so Milestone B's `Rendro.Theme` can slot in
  # without breaking rework (S1).
  defp palette(opts) do
    overrides = Keyword.get(opts, :palette, %{})

    Map.merge(
      %{
        ink: {0, 0, 0},
        muted: {0, 0, 0},
        accent: {0, 0, 0},
        on_accent: {0, 0, 0},
        background: {255, 255, 255},
        surface: {255, 255, 255},
        rule: {0, 0, 0}
      },
      overrides
    )
  end

  # ---------------------------------------------------------------------------
  # Data validation (errors-as-product, INV-06)
  # ---------------------------------------------------------------------------

  defp validate_data!(data) when not is_map(data) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid data argument.

    What:  data must be a map.
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   Received a non-map value: #{inspect(data)} (#{Rendro.Recipes.Pagination.type_name(data)}).
    Next:  Pass a map with required keys :id, :date, :items.
    """
  end

  defp validate_data!(data) do
    validate_required_keys!(data)
    maybe_validate_issuer!(data)
    maybe_validate_customer!(data)
    maybe_validate_due_date!(data)
    maybe_validate_terms!(data)
    validate_items!(data.items)
    maybe_validate_totals_types!(data)
    maybe_validate_totals!(data)
    :ok
  end

  defp validate_required_keys!(data) do
    required = [:id, :date, :items]

    missing = Enum.filter(required, fn key -> not Map.has_key?(data, key) end)

    unless missing == [] do
      raise ArgumentError, """
      Rendro.Recipes.Invoice.document/2 — missing required key(s) in data.

      What:  Required invoice data keys are missing.
      Where: Rendro.Recipes.Invoice.validate_data!/1
      Why:   Missing key(s): #{inspect(missing)}.
      Next:  Provide all required keys: :id, :date, :items. All other keys
             (:issuer, :customer, :due_date, :terms, :totals) are optional.
      """
    end
  end

  defp maybe_validate_issuer!(%{issuer: issuer})
       when not is_nil(issuer) and not is_map(issuer) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid :issuer shape.

    What:  :issuer must be a map, e.g. %{name: "Acme Corp"}.
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   Received: #{inspect(issuer)} (#{Rendro.Recipes.Pagination.type_name(issuer)}).
    Next:  Pass a map with at least a :name key, e.g. %{name: "Acme Corp"}.
    """
  end

  defp maybe_validate_issuer!(_data), do: :ok

  defp maybe_validate_customer!(%{customer: customer})
       when not is_nil(customer) and not is_map(customer) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid :customer shape.

    What:  :customer must be a map, e.g. %{name: "Acme Corp"}.
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   Received: #{inspect(customer)} (#{Rendro.Recipes.Pagination.type_name(customer)}).
    Next:  Pass a map with at least a :name key, e.g. %{name: "Acme Corp"}.
    """
  end

  defp maybe_validate_customer!(_data), do: :ok

  defp maybe_validate_due_date!(%{due_date: due_date})
       when not is_nil(due_date) and not is_struct(due_date, Date) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid :due_date type.

    What:  :due_date must be a %Date{} struct.
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   Received: #{inspect(due_date)} (#{Rendro.Recipes.Pagination.type_name(due_date)}).
    Next:  Use the ~D[YYYY-MM-DD] sigil or Date.new!/3.
    """
  end

  defp maybe_validate_due_date!(_data), do: :ok

  defp maybe_validate_terms!(%{terms: terms})
       when not is_nil(terms) and not is_binary(terms) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid :terms type.

    What:  :terms must be a string, e.g. "Net 30".
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   Received: #{inspect(terms)} (#{Rendro.Recipes.Pagination.type_name(terms)}).
    Next:  Pass a binary string, e.g. "Net 30".
    """
  end

  defp maybe_validate_terms!(_data), do: :ok

  defp validate_items!(items) when not is_list(items) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid :items value.

    What:  :items must be a list of line item maps.
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   Received: #{inspect(items)} (#{Rendro.Recipes.Pagination.type_name(items)}).
    Next:  Pass a list: [%{name: "...", qty: 1, price: 10}].
    """
  end

  defp validate_items!(items) do
    items
    |> Enum.with_index()
    |> Enum.each(fn {item, idx} ->
      validate_item_shape!(item, idx)
      validate_item_price!(Map.get(item, :price), idx)
    end)
  end

  # Every line item is unconditionally read during rendering — body_section/2
  # interpolates item.name and "$#{item.price}", calls Integer.to_string(item.qty),
  # and item_line_total/1 pattern-matches %{qty:, price:}. Validating item shape
  # up front keeps the errors-as-product contract (INV-06): a malformed item
  # raises an instructive ArgumentError here instead of leaking a raw
  # BadMapError/KeyError from deep in the render pipeline.
  defp validate_item_shape!(item, idx) when not is_map(item) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid line item at index #{idx}.

    What:  Each :items entry must be a map, e.g. %{name: "Widget", qty: 1, price: 10}.
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   items[#{idx}] = #{inspect(item)} (#{Rendro.Recipes.Pagination.type_name(item)}).
    Next:  Pass a map with :name, :qty, and :price keys.
    """
  end

  defp validate_item_shape!(item, idx) do
    validate_item_field!(item, :name, idx, &is_binary/1, "a string", ~s(name: "Widget"))
    validate_item_field!(item, :qty, idx, &is_integer/1, "an integer", "qty: 3")
    validate_item_key_present!(item, :price, idx)
  end

  defp validate_item_field!(item, key, idx, type_ok?, type_desc, example) do
    validate_item_key_present!(item, key, idx)
    value = Map.fetch!(item, key)

    unless type_ok?.(value) do
      raise ArgumentError, """
      Rendro.Recipes.Invoice.document/2 — invalid item :#{key} at index #{idx}.

      What:  A line item's :#{key} must be #{type_desc}.
      Where: Rendro.Recipes.Invoice.validate_data!/1
      Why:   items[#{idx}].#{key} = #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
      Next:  Pass #{type_desc}, e.g. #{example}.
      """
    end
  end

  defp validate_item_key_present!(item, key, idx) do
    unless Map.has_key?(item, key) do
      raise ArgumentError, """
      Rendro.Recipes.Invoice.document/2 — line item at index #{idx} missing :#{key}.

      What:  Each line item must include :#{key}.
      Where: Rendro.Recipes.Invoice.validate_data!/1
      Why:   items[#{idx}] has no :#{key} key: #{inspect(item)}.
      Next:  Add a :#{key} key to the line item map.
      """
    end
  end

  # The legacy :price slot renders via bare-number string interpolation
  # ("$#{price}") to stay byte-compatible with the toy call — a %Decimal{}
  # there would silently render as "$#Decimal<...>" instead of a dollar
  # amount, so it is rejected instructively (INV-02).
  defp validate_item_price!(%Decimal{} = price, idx) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid item :price type at index #{idx}.

    What:  A line item's legacy :price must be a bare number (Integer or Float),
           not a Decimal.
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   items[#{idx}].price = #{inspect(price)} (Decimal). The legacy :price
           field renders via bare-number string interpolation ("$\#{price}")
           to stay byte-compatible with the toy call.
    Next:  Pass a bare number, e.g. price: 79.00, or move Decimal amounts into
           :totals (formatted via Rendro.Format.money/1).
    """
  end

  defp validate_item_price!(price, _idx) when is_number(price), do: :ok

  defp validate_item_price!(price, idx) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid item :price type at index #{idx}.

    What:  A line item's :price must be a bare number (Integer or Float).
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   items[#{idx}].price = #{inspect(price)} (#{Rendro.Recipes.Pagination.type_name(price)}).
    Next:  Pass a bare number, e.g. price: 79.00.
    """
  end

  # New Decimal money fields (currently only :totals.*) must be Decimal, not
  # Float — Float arithmetic is inexact and can produce incorrect financial
  # output (INV-02). This checks TYPE only; INV-03's Decimal.equal?/2
  # caller-assertion (supplied vs. derived) is layered on top separately.
  defp maybe_validate_totals_types!(%{totals: totals}) when is_map(totals) do
    Enum.each([:subtotal, :tax, :discount, :total], fn key ->
      validate_totals_field_type!(Map.get(totals, key), key)
    end)
  end

  defp maybe_validate_totals_types!(_data), do: :ok

  defp validate_totals_field_type!(nil, _key), do: :ok
  defp validate_totals_field_type!(%Decimal{}, _key), do: :ok

  defp validate_totals_field_type!(value, key) when is_float(value) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid :totals.#{key} type.

    What:  :totals.#{key} must be a Decimal, not a Float.
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   Received a Float: #{inspect(value)}. Float arithmetic is not exact
           and can produce incorrect financial output.
    Next:  Use Decimal.new/1 — e.g. Decimal.new("#{value}") or Decimal.from_float(#{value}).
    """
  end

  defp validate_totals_field_type!(value, key) do
    raise ArgumentError, """
    Rendro.Recipes.Invoice.document/2 — invalid :totals.#{key} type.

    What:  :totals.#{key} must be a Decimal.
    Where: Rendro.Recipes.Invoice.validate_data!/1
    Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
    Next:  Use Decimal.new/1 — e.g. Decimal.new("50.00").
    """
  end

  # ---------------------------------------------------------------------------
  # Totals caller-assertion validation (INV-03)
  # ---------------------------------------------------------------------------

  # Validates caller-supplied totals against derived values using
  # Decimal.equal?/2 (numeric) — NEVER `==` (struct-field compare, where
  # 1.0 != 1.00). By the time this runs, :items has already passed
  # validate_items!/1 (no %Decimal{} in the legacy :price slot), so
  # item_line_total/1 is safe to call for every item.
  defp maybe_validate_totals!(%{totals: totals, items: items}) when is_map(totals) do
    derived_subtotal =
      Enum.reduce(items, Decimal.new(0), fn item, acc ->
        Decimal.add(acc, item_line_total(item))
      end)

    if Map.has_key?(totals, :subtotal) do
      unless Decimal.equal?(totals.subtotal, derived_subtotal) do
        raise ArgumentError, """
        Rendro.Recipes.Invoice.document/2 — :totals.subtotal mismatch.

        What:  The caller-supplied :totals.subtotal does not match the sum of
               item amounts (qty × price).
        Where: Rendro.Recipes.Invoice.validate_data!/1
        Why:   Supplied subtotal: #{inspect(totals.subtotal)},
               Derived subtotal: #{inspect(derived_subtotal)} (sum of items qty × price).
        Next:  Remove :totals.subtotal to skip this check, or correct the value.
        """
      end
    end

    if Map.has_key?(totals, :total) do
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
        Rendro.Recipes.Invoice.document/2 — :totals.total mismatch.

        What:  The caller-supplied :totals.total does not match the derived value.
        Where: Rendro.Recipes.Invoice.validate_data!/1
        Why:   Supplied total: #{inspect(totals.total)},
               Derived total: #{inspect(expected_total)}.
        Next:  Remove :totals.total to skip this check, or correct the value.
        """
      end
    end

    :ok
  end

  defp maybe_validate_totals!(_data), do: :ok

  # Converts a line item's qty (Integer) × legacy bare-number price (Integer
  # or Float) into a Decimal, for derivation/comparison purposes only — the
  # legacy :price slot itself is NEVER converted for rendering (INV-02).
  defp item_line_total(%{qty: qty, price: price}) do
    Decimal.new(qty) |> Decimal.mult(Decimal.new(to_string(price)))
  end
end
