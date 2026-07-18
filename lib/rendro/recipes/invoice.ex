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
    table_rows =
      Enum.map(items, fn item ->
        [item.name, Integer.to_string(item.qty), "$#{item.price}"]
      end)

    table =
      Rendro.table(table_rows,
        header: ["Item", "Qty", "Price"],
        columns: [{:share, 1}, {:fixed, 50}, {:fixed, 80}]
      )

    content = [Rendro.block(table)] ++ build_totals_blocks(data, opts)

    Rendro.section(
      name: :invoice_body,
      region: :body,
      content: content
    )
  end

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
    |> Enum.each(fn {item, idx} -> validate_item_price!(Map.get(item, :price), idx) end)
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

  defp validate_item_price!(_price, _idx), do: :ok

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
end
