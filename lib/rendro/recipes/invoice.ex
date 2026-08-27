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
  # FROZEN toy default (INV-01) — the pre-Phase-115 header region height.
  # A toy call (no :issuer/:customer/:due_date/:terms) always gets exactly
  # this height, keeping @toy_golden_sha256 byte-identical. 118-08
  # gap-closure: an invoice with anatomy fields present needs MORE header
  # room than the frozen 2-line (title+date) toy path was ever sized for —
  # see computed_header_height/1 below, which grows the header only when
  # those optional fields are actually present in `data`.
  @default_header_height 56
  @footer_height 24
  @footer_y @page_height - @margin - @footer_height

  # Default table column rules: Item | Qty | Price.
  @table_columns [{:share, 1}, {:fixed, 50}, {:fixed, 80}]
  @curated_metric_fonts [
    :rendro_preset_grotesque,
    :rendro_preset_humanist_sans,
    :rendro_preset_text_serif,
    :rendro_preset_mono
  ]

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

  118-08: `:header_height` sizes the `:header` region (default: the frozen
  56pt toy height). `document/2` computes and threads a data-appropriate
  value automatically (see `computed_header_height/1`) — callers using the
  escape hatch (`page_template/1` + `sections/2` directly, without
  `document/2`) with anatomy fields present in `data` (`:issuer`,
  `:customer`, `:due_date`, `:terms`) should pass the SAME `:header_height`
  to both calls, or the header content may overflow its region.

  ## Examples

      iex> Rendro.Recipes.Invoice.page_template()
      %Rendro.PageTemplate{name: :invoice, ...}

      iex> Rendro.Recipes.Invoice.page_template(name: :branded)
      %Rendro.PageTemplate{name: :branded, ...}

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
      name: :invoice,
      regions: regions
    ]

    # page_template/1 only understands PageTemplate struct keys. Recipe-level
    # opts (:formatters, :labels, :palette, :header_height, ...) are consumed
    # by the section builders / this function locally, not by struct!/2 --
    # filter them out so they thread through to sections/2 / palette/1
    # instead of reaching struct!/2 and raising KeyError.
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
  Assembles and returns a fully composed `%Rendro.Document{}` using the
  pipeline builder API.

  Uses `page_template/1` and `sections/2` internally, then chains them
  through `Rendro.Document.new/0 |> add_template |> set_template |> add_section`.

  Pass `font_registry: registry` when typography uses a custom logical font
  role. The registry is used for both table measurement and the returned
  document, ensuring pagination uses the same font metrics as rendering.

  ## Examples

      iex> data = %{id: "INV-001", date: ~D[2026-01-15], items: []}
      iex> doc = Rendro.Recipes.Invoice.document(data)
      iex> doc.page_template
      :invoice

  """
  @spec document(map(), keyword()) :: Rendro.Document.t()
  def document(data, opts \\ []) do
    validate_data!(data)
    # 118-08: thread ONE resolved :header_height through both page_template/1
    # and sections/2 so the header region is always tall enough for
    # whichever anatomy fields `data` actually carries (never just the
    # frozen 2-line toy height) — see computed_header_height/1.
    opts = Keyword.put_new(opts, :header_height, computed_header_height(data))
    template = page_template(opts)
    secs = sections(data, opts)

    base_doc =
      Rendro.Document.new()
      |> put_font_registry(opts)
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
    type = typography(opts)
    fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)

    # 122-01: the INV-01 header pair is now typography-seamed (title/body roles,
    # mono/body fonts, leading/widows/orphans). This preserves the INV-01
    # byte-identity golden because the no-theme literal defaults are exactly
    # this recipe's prior values (title == 18, body == 10, fonts == :default,
    # leading/widows/orphans == 1.2/2/2 == %Text{} struct defaults). New
    # anatomy fields still render only when present, as NEW blocks around this
    # base pair.
    base_content = [
      Rendro.block(
        Rendro.text("INVOICE ##{id}",
          size: type.scale.title,
          font: type.fonts.mono,
          line_height: type.leading,
          widows: type.widows,
          orphans: type.orphans
        )
      ),
      Rendro.block(
        Rendro.text("Date: #{date}",
          size: type.scale.body,
          font: type.fonts.body,
          line_height: type.leading,
          widows: type.widows,
          orphans: type.orphans
        )
      )
    ]

    content =
      base_content
      |> maybe_prepend(Map.get(data, :issuer), &issuer_block(&1, colors, type))
      |> maybe_append(Map.get(data, :customer), &customer_block(&1, colors, type))
      |> maybe_append(header_due_date(data, opts), &due_date_block(&1, colors, type, fmt_date))
      |> maybe_append(Map.get(data, :terms), &terms_block(&1, colors, type))

    Rendro.section(
      name: :invoice_header,
      region: :header,
      content: content
    )
  end

  defp body_section(%{items: items} = data, opts) do
    colors = palette(opts)
    type = typography(opts)
    theme = opts[:theme]

    # FROZEN toy path (INV-01) for a bare-number :price — the "$#{price}"
    # interpolation MUST stay literally unchanged for the toy call's
    # byte-identity golden. 118-08 gap-closure: a %Decimal{} :price (never
    # accepted before) is now ALSO honored and formatted via
    # Rendro.Format.money/1 for faithful, always-2-decimal cents — this is
    # what a realistic demo fixture uses to eliminate the `$79.0`
    # one-decimal money defect, without touching the frozen bare-number path.
    formatted_rows =
      Enum.map(items, fn item ->
        [item.name, Integer.to_string(item.qty), format_price(item.price)]
      end)

    rows = Enum.map(formatted_rows, &table_row(&1, theme, colors, type))

    header = ["Item", "Qty", "Price"]

    table_opts = [
      header: table_row(header, theme, colors, type),
      columns: @table_columns
    ]

    # Measure all rows at the body region width using the engine's own font
    # metrics (D-09) — avoids recipe-local estimates that cause
    # :content_overflow. A single-page toy call (2 items) fits well within
    # capacity and yields exactly one, byte-identical table block below.
    measurement_fonts = Map.take(type.fonts, [:body, :mono])

    doc_for_measure =
      opts
      |> measurement_document(measurement_fonts)
      |> Rendro.Theme.Presets.register_metric_fonts(Map.values(measurement_fonts))

    {header_h, row_heights} =
      Rendro.measure_rows(
        Enum.map(formatted_rows, &table_row(&1, theme, colors, type)),
        @content_width,
        doc_for_measure,
        table_opts_for_measure(header, theme, colors, type)
      )

    # 118-08: resolve the SAME header height page_template/1 uses for this
    # call (explicit opts override, or computed_header_height/1's
    # data-derived default) so body capacity accounting matches the actual
    # rendered header region — never the stale frozen constant.
    resolved_header_height = Keyword.get(opts, :header_height, computed_header_height(data))
    body_height = @page_height - 2 * @margin - resolved_header_height - @footer_height

    # INV-03 "kept with the last rows" — the ONE place Invoice must exceed a
    # pure Receipt copy (Receipt appends totals without reserving space, so
    # totals can flow to a fresh page). Reserving the totals height on every
    # page (see @totals_line_height doc) guarantees the final table page
    # always has room left for the totals block that trails it.
    effective_capacity = body_height - header_h - totals_reserved_height(data) - @row_epsilon

    rows_with_meta =
      Enum.zip(rows, row_heights)
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

  defp table_row(values, theme, colors, type) do
    Enum.map(values, &Rendro.Recipes.TableCell.content(&1, theme, colors, type, :ink))
  end

  defp table_opts_for_measure(header, theme, colors, type) do
    [header: table_row(header, theme, colors, type), columns: @table_columns]
  end

  defp put_font_registry(document, opts) do
    registry = font_registry(opts)
    %{document | font_registry: registry, default_font: registry.default_font}
  end

  defp measurement_document(opts, fonts) do
    registry = font_registry(opts)
    validate_measurement_fonts!(registry, fonts)
    %{Rendro.Document.new() | font_registry: registry, default_font: registry.default_font}
  end

  defp font_registry(opts) do
    case Keyword.get(opts, :font_registry) do
      nil ->
        Rendro.FontRegistry.new()

      %Rendro.FontRegistry{} = registry ->
        registry

      invalid ->
        raise ArgumentError,
              "Invoice :font_registry must be a %Rendro.FontRegistry{}, got: #{inspect(invalid)}"
    end
  end

  defp validate_measurement_fonts!(registry, fonts) do
    fonts
    |> Map.values()
    |> Enum.uniq()
    |> Enum.reject(&(&1 == :default or &1 in @curated_metric_fonts))
    |> Enum.each(fn role ->
      if Rendro.FontRegistry.fetch(registry, role) == :error do
        raise ArgumentError,
              "Invoice typography font #{inspect(role)} is not registered in :font_registry. " <>
                "Register the font before calling Invoice.document/2 so table measurement " <>
                "uses the same metrics as rendering."
      end
    end)
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

  # 118-08 gap-closure (SHOW-01): the frozen INV-01 toy header (56pt) was
  # sized for exactly 2 lines (title + date) — a real invoice with issuer/
  # customer/due_date/terms present needs a taller header region or its
  # content raises :content_overflow (discovered rendering the enriched
  # acme-phoenix-saas fixture end-to-end). Grows the header ONLY when the
  # corresponding optional field is present, so a toy call (none present)
  # still computes exactly @default_header_height — byte-identical geometry,
  # preserving INV-01. Conservative flat per-field budgets (not exact text
  # measurement) mirror totals_reserved_height/1's idiom: issuer/customer
  # can each render 2 lines (name + address), due_date/terms are always 1.
  @spec computed_header_height(map()) :: number()
  defp computed_header_height(data) do
    @default_header_height
    |> add_if_present(Map.get(data, :issuer), 30)
    |> add_if_present(Map.get(data, :customer), 30)
    |> add_if_present(Map.get(data, :due_date), 14)
    |> add_if_present(Map.get(data, :terms), 14)
  end

  defp add_if_present(height, nil, _extra), do: height
  defp add_if_present(height, _present, extra), do: height + extra

  # 118-08: legacy bare-number :price renders unchanged ("$#{price}", the
  # frozen INV-01 toy path); a %Decimal{} :price is formatted via
  # Rendro.Format.money/1 for faithful 2-decimal cents (never a lossy
  # float/integer coercion upstream — see examples_data.ex).
  defp format_price(%Decimal{} = price), do: Rendro.Format.money(price)
  defp format_price(price) when is_number(price), do: "$#{price}"

  defp footer_section(_data, opts) do
    colors = palette(opts)
    type = typography(opts)

    Rendro.section(
      name: :invoice_footer,
      region: :footer,
      content: [
        Rendro.block(
          Rendro.text("Thank you for your business!",
            size: type.scale.body,
            font: type.fonts.body,
            line_height: type.leading,
            widows: type.widows,
            orphans: type.orphans,
            color: colors.ink
          )
        )
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

  defp issuer_block(issuer, colors, type) when is_map(issuer) do
    name = Map.get(issuer, :name, "")
    address = Map.get(issuer, :address)
    text = if address in [nil, ""], do: name, else: "#{name}\n#{address}"

    Rendro.block(
      Rendro.text(text,
        size: type.scale.subtitle,
        font: type.fonts.body,
        line_height: type.leading,
        widows: type.widows,
        orphans: type.orphans,
        color: colors.ink
      )
    )
  end

  defp customer_block(customer, colors, type) when is_map(customer) do
    name = Map.get(customer, :name, "")
    address = Map.get(customer, :address)
    text = if address in [nil, ""], do: "Bill To: #{name}", else: "Bill To: #{name}\n#{address}"

    Rendro.block(
      Rendro.text(text,
        size: type.scale.body,
        font: type.fonts.body,
        line_height: type.leading,
        widows: type.widows,
        orphans: type.orphans,
        color: colors.muted
      )
    )
  end

  defp due_date_block(due_date, colors, type, fmt_date) do
    Rendro.block(
      Rendro.text("Due: #{fmt_date.(due_date)}",
        size: type.scale.body,
        font: type.fonts.body,
        line_height: type.leading,
        widows: type.widows,
        orphans: type.orphans,
        color: colors.muted
      )
    )
  end

  defp terms_block(terms, colors, type) do
    Rendro.block(
      Rendro.text("Terms: #{terms}",
        size: type.scale.body,
        font: type.fonts.body,
        line_height: type.leading,
        widows: type.widows,
        orphans: type.orphans,
        color: colors.muted
      )
    )
  end

  # ---------------------------------------------------------------------------
  # Totals block builder (INV-02 / INV-03 rendering half)
  # ---------------------------------------------------------------------------

  # 118-08 gap-closure (SHOW-01): amount due (Total) must be the single
  # dominant element on the invoice (content_hierarchy=5 anchor, mirrors
  # Payslip's Net Pay box). Subtotal/Tax/Discount render small and muted in
  # one block; Total renders alone, much larger, in its own trailing block —
  # every other element recedes in proportion. 122-01: the former
  # @minor_totals_size (9) and @dominant_total_size (20) literals are now the
  # `small` and `display` steps of the typography/1 seam (no-theme
  # literal-defaults preserve those exact values).

  defp build_totals_blocks(%{totals: totals} = data, opts) when is_map(totals) do
    fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)
    fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)
    colors = palette(opts)
    type = typography(opts)

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
              size: type.scale.small,
              font: type.fonts.mono,
              line_height: type.leading,
              widows: type.widows,
              orphans: type.orphans,
              color: colors.muted
            )
          )
        ]
      end

    total_block =
      case Map.get(totals, :total) do
        %Decimal{} = total ->
          [
            Rendro.block(
              # The SOLE `display`-anchored element on the Invoice (D-01) — the
              # "one key fact." mono font, since it is an amount.
              Rendro.text("Total Due: #{fmt_amount.(total)}",
                size: type.scale.display,
                font: type.fonts.mono,
                line_height: type.leading,
                widows: type.widows,
                orphans: type.orphans,
                color: colors.accent
              )
            )
          ]

        _ ->
          []
      end

    minor_block ++ total_block ++ totals_due_date(data, opts, colors, type, fmt_date, total_block)
  end

  defp build_totals_blocks(_data, _opts), do: []

  defp maybe_append_totals_line(acc, _label, nil, _fmt), do: acc

  defp maybe_append_totals_line(acc, label, %Decimal{} = amount, fmt) do
    acc ++ ["#{label}: #{fmt.(amount)}"]
  end

  # A supplied theme makes the payment-summary relationship explicit without
  # changing the frozen nil-theme layout: move an available due date next to
  # the dominant Total Due only when the summary has a total to bind it to.
  defp header_due_date(data, opts) do
    if themed_payment_summary?(data, opts), do: nil, else: Map.get(data, :due_date)
  end

  defp totals_due_date(data, opts, colors, type, fmt_date, total_block) do
    if themed_payment_summary?(data, opts) and total_block != [] do
      [due_date_block(Map.fetch!(data, :due_date), colors, type, fmt_date)]
    else
      []
    end
  end

  defp themed_payment_summary?(%{totals: totals} = data, opts) when is_map(totals) do
    not is_nil(opts[:theme]) and match?(%Decimal{}, Map.get(totals, :total)) and
      match?(%Date{}, Map.get(data, :due_date))
  end

  defp themed_payment_summary?(_data, _opts), do: false

  # ---------------------------------------------------------------------------
  # Color seam (INV-07 / S1)
  # ---------------------------------------------------------------------------

  # Returns the role → RGB map for this render. When no `:theme` is supplied the
  # `nil` branch reproduces Invoice's exact current literals (all-black ink,
  # white surfaces) so every section that reads colors from here stays
  # byte-identical (PLUMB-03). When a `:theme` is supplied the base becomes
  # `Rendro.Theme.resolve(theme).colors` (9 integer-{r,g,b} roles, colors ONLY
  # — no type-scale read). The final `Map.merge(base, :palette-override)` keeps
  # an explicit `:palette` as the winning layer (D-01). Any section that sets a
  # color MUST source it from here — never inline a literal `{r, g, b}` tuple.
  defp palette(opts) do
    Rendro.Recipes.Palette.resolve(opts, %{
      ink: {0, 0, 0},
      muted: {0, 0, 0},
      accent: {0, 0, 0},
      on_accent: {0, 0, 0},
      background: {255, 255, 255},
      surface: {255, 255, 255},
      rule: {0, 0, 0}
    })
  end

  # ---------------------------------------------------------------------------
  # Typography seam (TYPE-01 / TYPE-02 / TYPE-03) — the exact structural twin of
  # palette/1 for the type scale, font roles, and leading/widows/orphans.
  # ---------------------------------------------------------------------------

  # Returns the resolved typography for this render: a named type scale, three
  # font roles, and leading/widows/orphans. When no `:theme` is supplied the
  # `nil` branch reproduces Invoice's exact CURRENT literals — NEVER
  # `Rendro.Theme.default().typography` (that would apply the frozen
  # 21/16.5/... scale and break byte-identity, RESEARCH Pitfall 1) — so every
  # `%Text{}` that reads sizes/fonts/leading from here stays byte-identical
  # (TYPE-01/TYPE-03). All three font roles default to `:default`, the
  # always-registered Helvetica-compatible built-in, which the font registry
  # normalizes identically to today's implicit `"Helvetica"` default → no byte
  # drift. When a `:theme` is supplied the base becomes
  # `Rendro.Theme.resolve(theme).typography`. The final `Map.merge` keeps an
  # explicit `:typography` opt as the winning override layer (mirrors :palette).
  # Any `%Text{}` size/font/leading MUST source from here.
  defp typography(opts) do
    base =
      case opts[:theme] do
        nil ->
          %{
            scale: %{display: 20, title: 18, subtitle: 12, body: 10, small: 9, caption: 8},
            fonts: %{heading: :default, body: :default, mono: :default},
            leading: 1.2,
            widows: 2,
            orphans: 2
          }

        theme ->
          Rendro.Theme.resolve(theme).typography
      end

    Map.merge(base, Keyword.get(opts, :typography, %{}))
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
  # ("$#{price}") to stay byte-compatible with the toy call. 118-08
  # gap-closure: a %Decimal{} :price is ALSO honored (never rejected) and
  # formatted via Rendro.Format.money/1 for faithful, always-2-decimal
  # cents — see format_price/1 in body_section/2. This is what a realistic
  # invoice demo fixture uses to eliminate the `$79.0` one-decimal money
  # defect without a lossy float/integer coercion upstream.
  defp validate_item_price!(%Decimal{}, _idx), do: :ok

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
