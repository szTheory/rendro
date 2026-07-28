defmodule Rendro.Recipes.Payslip do
  @moduledoc """
  Data-driven payslip recipe. Net pay is the reader-first visual anchor
  (D-11): a tinted band directly under the identity header renders "NET PAY"
  at the largest text size on the page.

  Uses the Tiered Composition pattern, mirroring `Rendro.Recipes.Invoice`:

    - `document/2`      — Batteries-included; returns a fully assembled
                          `%Rendro.Document{}` ready for `Rendro.render/2`.
    - `page_template/1` — Layout only; returns the `%Rendro.PageTemplate{}`.
                          Geometry is derived from `Rendro.PageSize.resolve/2`
                          (A4 default, portrait) — zero hardcoded numerics, so
                          both A4 and US Letter render correctly (D-14).
    - `sections/2`      — Content only; returns a list of `%Rendro.Section{}`
                          structs mapped to named regions.

  ## Required data keys

  See `validate_data!/1`'s contract (D-15):

    - `:employer` — `%{name (required), address}`
    - `:employee` — `%{name (required), id, tax_code}`
    - `:period`   — `%{from, to}` (required, `Date.t()`)
    - `:pay_date` — required, `Date.t()`
    - `:earnings` — required, non-empty list of `%{description, amount, ytd}`
    - `:deductions` — required key, list (may be empty) of the same line shape
    - `:net_pay`  — required `Decimal.t()`; must equal gross earnings minus
                    total deductions (D-13)

  ## Optional data keys

    - `:totals` — `%{gross, deductions, net, gross_ytd, deductions_ytd, net_ytd}`
      — caller assertions checked against derived values via `Decimal.equal?/2`
    - `:payment_method` — masked identifier string (e.g. `"···· 4321"`)

  ## Jurisdiction / label / formatting overrides (D-16)

  `:palette`, `:labels`, and `:formatters` are three orthogonal override maps
  merged over recipe-shipped defaults — the same convention as
  `Rendro.Recipes.Invoice`'s `palette(opts)` seam. Statutory line content
  (e.g. "PAYE Income Tax" vs "Federal Income Tax") is caller `:description`
  data, never a library-enumerated jurisdiction type (D-17).
  """
  @moduledoc tags: [:adapter]

  @default_page_size :a4
  @default_margin 72
  @default_header_h 88
  @default_summary_h 54
  @default_footer_h 24

  # D-18: recipe-owned default labels so Payslip.document(data) with zero
  # :labels/:formatters opts renders a correct jurisdiction-neutral English
  # payslip. Rendro.Format.label/1 has NO fallback clause -- every label key
  # referenced anywhere in this module's section builders MUST be a key here.
  @default_labels %{
    earnings: "Earnings",
    deductions: "Deductions",
    description: "Description",
    amount: "Current",
    ytd_amount: "YTD",
    gross_pay: "Gross Pay",
    total_deductions: "Total Deductions",
    net_pay: "NET PAY",
    year_to_date: "Year to Date",
    pay_period: "Pay Period",
    pay_date: "Pay Date",
    employer: "Employer",
    employee: "Employee"
  }

  # Test-only accessor for @default_labels — module attributes are
  # compile-time only and not otherwise runtime-inspectable. @doc false keeps
  # this out of the public API manifest (mirrors the Sign/Protect redact_*
  # @doc false convention).
  @doc false
  @spec __default_labels__() :: map()
  def __default_labels__, do: @default_labels

  @doc """
  Returns a `%Rendro.PageTemplate{}` with geometry derived from the page size
  option. Default is A4 portrait. Four named regions: `:header` (employer/
  employee identity), `:summary` (the D-11 net-pay anchor band), `:body`
  (`anchor: :flow` — combined ledger + reconciliation), `:footer`
  (`anchor: :bottom` — masked payment method + page number).

  ## Options

    - `:page_size` — `:a4` (default), `:us_letter`, or `{width, height}` tuple
    - `:margin_top` / `:margin_right` / `:margin_bottom` / `:margin_left` — margin in pt (default 72)
    - `:name` — template name atom (default `:payslip`)

  ## Examples

      iex> template = Rendro.Recipes.Payslip.page_template()
      iex> Enum.map(template.regions, & &1.name)
      [:header, :summary, :body, :footer]

  """
  @spec page_template(keyword()) :: Rendro.PageTemplate.t()
  def page_template(opts \\ []) do
    g = geometry(opts)
    colors = palette(opts)

    base_regions = [
      Rendro.region(
        name: :header,
        role: :header,
        anchor: :top,
        x: g.ml,
        y: g.header_y,
        width: g.content_w,
        height: g.header_h
      ),
      Rendro.region(
        name: :summary,
        role: :custom,
        anchor: :top,
        x: g.ml,
        y: g.summary_y,
        width: g.content_w,
        height: g.summary_h
      ),
      Rendro.region(
        name: :body,
        role: :body,
        anchor: :flow,
        x: g.ml,
        y: g.body_y,
        width: g.content_w,
        height: g.body_h
      ),
      Rendro.region(
        name: :footer,
        role: :footer,
        anchor: :bottom,
        x: g.ml,
        y: g.footer_y,
        width: g.content_w,
        height: g.footer_h
      )
    ]

    # 121-03: prepend the shared :background region FIRST (bottom of the
    # paint stack) iff the resolved palette differs from paper-white — gated
    # on the SAME palette(opts) sections/2 uses below (Pitfall 3), so region
    # and section can never disagree. The light no-theme path leaves
    # `regions` untouched (byte-identical).
    regions =
      if Rendro.Recipes.Background.emit?(colors) do
        [Rendro.Recipes.Background.region(g.pw, g.ph) | base_regions]
      else
        base_regions
      end

    defaults = [
      name: :payslip,
      width: g.pw,
      height: g.ph,
      margin_top: g.mt,
      margin_right: g.mr,
      margin_bottom: g.mb,
      margin_left: g.ml,
      regions: regions
    ]

    # Recipe-level opts (:palette, :labels, :formatters, :page_size, ...)
    # never reach struct!/2 -- only PageTemplate struct keys pass through, so
    # they thread to sections/2 / palette/1 instead of raising KeyError
    # (mirrors invoice.ex:119-131).
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
  Returns a list of `%Rendro.Section{}` structs mapping payslip content to
  the `:header`, `:summary`, `:body`, and `:footer` regions. Validates `data`
  and the `:labels`/`:formatters` opts shape (D-19) before building any
  section content.
  """
  @spec sections(map(), keyword()) :: [Rendro.Section.t()]
  def sections(data, opts \\ []) do
    validate_data!(data)
    Rendro.Recipes.Pagination.validate_labels!(opts, "Rendro.Recipes.Payslip.document/2")
    Rendro.Recipes.Pagination.validate_formatters!(opts, "Rendro.Recipes.Payslip.document/2")

    g = geometry(opts)
    colors = palette(opts)

    base_sections = [
      header_section(data, opts),
      summary_section(data, opts),
      body_section(data, opts),
      footer_section(data, opts)
    ]

    # Same predicate + same palette(opts) as page_template/1 (Pitfall 3) —
    # the region and section can never disagree.
    if Rendro.Recipes.Background.emit?(colors) do
      [Rendro.Recipes.Background.section(colors, g.pw, g.ph) | base_sections]
    else
      base_sections
    end
  end

  @doc """
  Assembles and returns a fully composed `%Rendro.Document{}`. Validates
  `data` (D-15/D-13 errors-as-product) before building the template.

  ## Examples

      iex> data = %{
      ...>   employer: %{name: "Aurora Textiles Co."},
      ...>   employee: %{name: "Jordan Rivera"},
      ...>   period: %{from: ~D[2026-06-01], to: ~D[2026-06-30]},
      ...>   pay_date: ~D[2026-07-05],
      ...>   earnings: [%{description: "Base Salary", amount: Decimal.new("1000.00")}],
      ...>   deductions: [],
      ...>   net_pay: Decimal.new("1000.00")
      ...> }
      iex> doc = Rendro.Recipes.Payslip.document(data)
      iex> doc.page_template
      :payslip

  """
  @spec document(map(), keyword()) :: Rendro.Document.t()
  def document(data, opts \\ []) do
    validate_data!(data)
    template = page_template(opts)
    secs = sections(data, opts)

    base_doc =
      Rendro.Document.new()
      |> with_unicode_fallback_font()
      |> Rendro.Document.add_template(template)
      |> Rendro.Document.set_template(template.name)

    Enum.reduce(secs, base_doc, fn section, doc ->
      Rendro.Document.add_section(doc, section)
    end)
  end

  # D-17 requires arbitrary caller `:description` content (e.g. accented
  # jurisdiction text like "Impôt sur le revenu") to render byte-for-byte
  # unchanged -- never gated or rejected. The built-in Helvetica metrics
  # table only covers the ASCII 32-126 range (lib/rendro/pdf/font.ex), so
  # without a broader fallback ANY accented character would abort rendering
  # with an :unsupported_glyph pipeline error instead of the honest
  # "never reject caller content" contract D-17 promises. The already-vendored
  # branding font (priv/branded/fonts/B612-Regular.ttf, used by
  # Certificate/BrandedInvoice) covers common Latin-1 accented characters, so
  # it is registered here as a silent, always-on fallback behind the default
  # built-in Helvetica primary (byte-identical ASCII metrics stay primary;
  # only genuinely out-of-range glyphs fall through).
  defp with_unicode_fallback_font(doc) do
    doc
    |> Rendro.Document.register_embedded_font(
      :payslip_unicode_fallback,
      {:path, Rendro.Branded.font_path()}
    )
    |> Rendro.Document.register_font(:payslip_sans,
      built_in: :helvetica,
      fallbacks: [:payslip_unicode_fallback]
    )
    |> Rendro.Document.put_default_font(:payslip_sans)
  end

  # ---------------------------------------------------------------------------
  # Geometry (D-14) — derived from Rendro.PageSize.resolve/2, zero hardcoded
  # A4 numerics, mirroring certificate.ex's geometry-from-template pattern.
  # ---------------------------------------------------------------------------

  defp geometry(opts) do
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    {pw, ph} = Rendro.PageSize.resolve(page_size, :portrait)

    ml = Keyword.get(opts, :margin_left, @default_margin)
    mr = Keyword.get(opts, :margin_right, @default_margin)
    mt = Keyword.get(opts, :margin_top, @default_margin)
    mb = Keyword.get(opts, :margin_bottom, @default_margin)

    content_w = pw - ml - mr
    header_h = @default_header_h
    summary_h = @default_summary_h
    footer_h = @default_footer_h

    header_y = mt
    summary_y = mt + header_h
    body_y = summary_y + summary_h
    footer_y = ph - mb - footer_h
    body_h = footer_y - body_y

    %{
      pw: pw,
      ph: ph,
      ml: ml,
      mr: mr,
      mt: mt,
      mb: mb,
      content_w: content_w,
      header_h: header_h,
      header_y: header_y,
      summary_h: summary_h,
      summary_y: summary_y,
      body_y: body_y,
      body_h: body_h,
      footer_h: footer_h,
      footer_y: footer_y
    }
  end

  # ---------------------------------------------------------------------------
  # Private section builders
  # ---------------------------------------------------------------------------

  defp header_section(data, opts) do
    colors = palette(opts)
    lbl = Rendro.Recipes.Pagination.label_resolver(opts, @default_labels)
    fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)

    period = data.period

    employer_text = employer_display(data.employer)
    employee_text = employee_display(data.employee)
    period_text = "#{lbl.(:pay_period)}: #{fmt_date.(period.from)} - #{fmt_date.(period.to)}"
    pay_date_text = "#{lbl.(:pay_date)}: #{fmt_date.(data.pay_date)}"

    Rendro.section(
      name: :payslip_header,
      region: :header,
      content: [
        Rendro.block(
          Rendro.text("#{lbl.(:employer)}: #{employer_text}", size: 13, color: colors.ink)
        ),
        Rendro.block(
          Rendro.text("#{lbl.(:employee)}: #{employee_text}", size: 11, color: colors.muted)
        ),
        Rendro.block(Rendro.text(period_text, size: 10, color: colors.muted)),
        Rendro.block(Rendro.text(pay_date_text, size: 10, color: colors.muted))
      ]
    )
  end

  defp employer_display(employer) do
    case Map.get(employer, :address) do
      blank when blank in [nil, ""] -> employer.name
      address -> "#{employer.name}\n#{address}"
    end
  end

  defp employee_display(employee) do
    base =
      case Map.get(employee, :id) do
        blank when blank in [nil, ""] -> employee.name
        id -> "#{employee.name} (#{glyph_safe(id)})"
      end

    case Map.get(employee, :tax_code) do
      blank when blank in [nil, ""] -> base
      tax_code -> "#{base} • #{tax_code}"
    end
  end

  # The D-14 masking token in caller/fixture DATA is the middot "·" (U+00B7)
  # exactly as specified -- but neither the built-in Helvetica metrics table
  # nor the B612 unicode fallback (see with_unicode_fallback_font/1) has a
  # glyph for it, so rendering it directly would abort with
  # :unsupported_glyph. This swaps it for the visually equivalent bullet "•"
  # (U+2022, present in the B612 fallback) ONLY for the rendered string --
  # the underlying `data` map (and fixture_data()'s D-14 masking assertions)
  # keep the literal middot untouched.
  defp glyph_safe(text) when is_binary(text), do: String.replace(text, "·", "•")

  # D-11: the net-pay anchor. Per the VERIFIED anchor_region_blocks engine
  # mechanic (lib/rendro/pipeline/paginate.ex:1092-1109), a block's y is
  # unconditionally overwritten by a running per-region cursor that advances
  # by `block.height`. Giving the backdrop path block an EXPLICIT `height: 0`
  # (independent of the rect op's own drawn `h`, which is the real band_h)
  # means it does not advance the cursor, so the label+value text blocks that
  # follow it in this SAME region's content list stack starting at the same
  # y the backdrop started at — painting on top of the full-height backdrop
  # rather than being pushed below it. This composition requires zero extra
  # regions.
  defp summary_section(data, opts) do
    colors = palette(opts)
    lbl = Rendro.Recipes.Pagination.label_resolver(opts, @default_labels)
    fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)
    g = geometry(opts)

    band_w = g.content_w
    band_h = g.summary_h

    backdrop =
      Rendro.path([{:rect, 0, 0, band_w, band_h}],
        fill: colors.surface,
        stroke: %{color: colors.rule, width: 0.75},
        x: 0,
        y: 0,
        width: band_w,
        height: 0
      )

    label_block = Rendro.block(Rendro.text(lbl.(:net_pay), size: 10, color: colors.muted))

    value_block =
      Rendro.block(Rendro.text(fmt_amount.(data.net_pay), size: 27, color: colors.ink))

    Rendro.section(
      name: :payslip_summary,
      region: :summary,
      content: [backdrop, label_block, value_block]
    )
  end

  # D-12: the combined earnings/deductions ledger table (6 columns:
  # Earnings|Current|YTD|Deductions|Current|YTD), a bold subtotal row as the
  # table's LAST data row, native multi-page pagination via
  # Pagination.chunk_rows_into_pages/2, and the D-13 kept-with-last
  # reconciliation block (reserved on every page so the final page always has
  # room for it — mirrors invoice.ex's @totals_line_height idiom).
  @row_epsilon 2.0
  @reconciliation_line_height 16

  # 118-08 gap-closure (SHOW-01): de-crowd the earnings/deductions table.
  #
  # Two compounding defects, per 118-06-FINDINGS.md:
  #
  #   1. Data rows were plain strings, so they measured at Rendro.Text's
  #      DEFAULT size (12) rather than the size 11 the subtotal row already
  #      uses explicitly — an inconsistency that also made the prior 55pt
  #      fixed amount-column width too narrow for the widest realistic YTD
  #      figure ("$25,200.00" measures 60.048pt at size 12, ~5pt over its
  #      own column, wrapping the last digit onto a second line). Making
  #      every data cell an explicit size-11 Rendro.Text (matching the
  #      subtotal row) is both a consistency fix and a de-crowding win: it
  #      shrinks every cell's measured width, freeing column budget.
  #   2. The engine has no cell-padding primitive, so the earnings and
  #      deductions column GROUPS butted directly against each other with
  #      zero gap even with `borders: :columns` (a thin rule alone, with
  #      each side's text pushed flush against it, still reads as
  #      crowded — the "YTDDeductions" header collision). A narrow empty
  #      spacer column between the two groups gives every row a genuine
  #      visual gap.
  #
  # At size 11, "$25,200.00" measures 55.044pt and "$4,200.00" measures
  # 48.928pt — @ytd_col_width and @current_col_width below give both
  # comfortable headroom while the @group_spacer_width column keeps the two
  # remaining description share-columns wide enough for the widest realistic
  # line-item description (e.g. "Pension Contribution", 102.102pt at size 11).
  @current_col_width 55
  @ytd_col_width 60
  @group_spacer_width 10
  @cell_size 11

  defp body_section(data, opts) do
    colors = palette(opts)
    lbl = Rendro.Recipes.Pagination.label_resolver(opts, @default_labels)
    fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)
    g = geometry(opts)

    totals = derive_totals(data)

    zipped = zip_pad(data.earnings, data.deductions)

    formatted_rows =
      Enum.map(zipped, fn {earn, ded} ->
        [
          cell_text(Map.get(earn, :description, ""), colors),
          cell_text(fmt_amount_or_blank(Map.get(earn, :amount), fmt_amount), colors),
          cell_text(fmt_amount_or_blank(Map.get(earn, :ytd), fmt_amount), colors),
          cell_text("", colors),
          cell_text(Map.get(ded, :description, ""), colors),
          cell_text(fmt_amount_or_blank(Map.get(ded, :amount), fmt_amount), colors),
          cell_text(fmt_amount_or_blank(Map.get(ded, :ytd), fmt_amount), colors)
        ]
      end)

    subtotal_row = subtotal_row(lbl, fmt_amount, colors, totals)
    all_rows = formatted_rows ++ [subtotal_row]

    # 118-08: column 3 is a narrow empty spacer between the earnings group
    # (0-2) and the deductions group (4-6) — see @group_spacer_width above.
    table_opts = [
      header: [
        lbl.(:earnings),
        lbl.(:amount),
        lbl.(:ytd_amount),
        "",
        lbl.(:deductions),
        lbl.(:amount),
        lbl.(:ytd_amount)
      ],
      columns: [
        {:share, 2},
        {:fixed, @current_col_width},
        {:fixed, @ytd_col_width},
        {:fixed, @group_spacer_width},
        {:share, 2},
        {:fixed, @current_col_width},
        {:fixed, @ytd_col_width}
      ],
      borders: :columns,
      cell_align: %{1 => :right, 2 => :right, 5 => :right, 6 => :right}
    ]

    # D-17: measurement must know about the unicode fallback font too (not
    # just document/2's final render), or an accented caller :description
    # would abort sections/2 itself with :unsupported_glyph before a
    # document is ever assembled.
    doc_for_measure = Rendro.Document.new() |> with_unicode_fallback_font()

    {header_h, row_heights} =
      Rendro.measure_rows(all_rows, g.content_w, doc_for_measure, table_opts)

    effective_capacity =
      g.body_h - header_h - reconciliation_reserved_height(data) - @row_epsilon

    rows_with_meta =
      Enum.zip(all_rows, row_heights)
      |> Enum.map(fn {row, height} -> {row, height, nil} end)

    pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)

    table_blocks =
      pages
      |> Enum.with_index()
      |> Enum.map(fn {{page_rows, _meta}, idx} ->
        table = Rendro.table(page_rows, table_opts)
        Rendro.block(table, break_before: idx > 0)
      end)

    reconciliation_blocks = build_reconciliation_blocks(data, colors, lbl, fmt_amount, totals)

    Rendro.section(
      name: :payslip_body,
      region: :body,
      content: table_blocks ++ reconciliation_blocks
    )
  end

  defp subtotal_row(lbl, fmt_amount, colors, totals) do
    blank = cell_text("", colors)

    [
      cell_text(lbl.(:gross_pay), colors),
      cell_text(fmt_amount.(totals.gross), colors),
      blank,
      blank,
      cell_text(lbl.(:total_deductions), colors),
      cell_text(fmt_amount.(totals.deductions), colors),
      cell_text("", colors)
    ]
  end

  # 118-08: every ledger data cell (line items AND the subtotal row) renders
  # at the SAME explicit size (@cell_size) — never the Rendro.Text default
  # (12) a bare string would silently fall back to. Consistency here is both
  # a correctness fix (predictable column-width math) and a de-crowding win
  # (a deliberately smaller, uniform cell font frees column budget).
  defp cell_text(text, colors),
    do: Rendro.block(Rendro.text(text, size: @cell_size, color: colors.ink))

  # Zips earnings/deductions to equal length, blank-padding the shorter list
  # (D-12) so the combined ledger always has one row per zipped pair.
  defp zip_pad(earnings, deductions) do
    len = max(length(earnings), length(deductions))
    blank_line = %{description: "", amount: nil, ytd: nil}

    Enum.zip(pad_to(earnings, len, blank_line), pad_to(deductions, len, blank_line))
  end

  defp pad_to(list, len, blank), do: list ++ List.duplicate(blank, len - length(list))

  defp fmt_amount_or_blank(nil, _fmt), do: ""
  defp fmt_amount_or_blank(%Decimal{} = amount, fmt), do: fmt.(amount)

  # Conservative reserved height for the trailing reconciliation block (D-13),
  # used only to bias per-page chunking capacity — never to change rendered
  # geometry (mirrors invoice.ex's @totals_line_height idiom). The equation
  # line always renders; the optional YTD trio line renders only when
  # data.totals includes at least one *_ytd field.
  defp reconciliation_reserved_height(data) do
    if has_ytd_totals?(Map.get(data, :totals)) do
      @reconciliation_line_height * 2
    else
      @reconciliation_line_height
    end
  end

  defp has_ytd_totals?(totals) when is_map(totals) do
    Enum.any?([:gross_ytd, :deductions_ytd, :net_ytd], &Map.has_key?(totals, &1))
  end

  defp has_ytd_totals?(_totals), do: false

  # Render half of D-13: the gross-to-net reconciliation equation, appended
  # ONLY after the LAST ledger table block (never keep_together — mirrors
  # Invoice's explicit anti-pattern warning, so a genuinely oversized ledger
  # still surfaces the engine's typed :content_overflow rather than an
  # artificially-forced single unbreakable group).
  defp build_reconciliation_blocks(data, colors, lbl, fmt_amount, totals) do
    equation_text =
      "#{lbl.(:gross_pay)} #{fmt_amount.(totals.gross)} - " <>
        "#{lbl.(:total_deductions)} #{fmt_amount.(totals.deductions)} = " <>
        "#{lbl.(:net_pay)} #{fmt_amount.(data.net_pay)}"

    equation_block = Rendro.block(Rendro.text(equation_text, size: 10, color: colors.ink))

    [equation_block | ytd_summary_blocks(data, colors, lbl, fmt_amount, totals)]
  end

  defp ytd_summary_blocks(data, colors, lbl, fmt_amount, totals) do
    case Map.get(data, :totals) do
      caller_totals when is_map(caller_totals) ->
        if has_ytd_totals?(caller_totals) do
          parts =
            []
            |> maybe_ytd_part(lbl.(:gross_pay), totals.gross_ytd, fmt_amount)
            |> maybe_ytd_part(lbl.(:total_deductions), totals.deductions_ytd, fmt_amount)
            |> maybe_ytd_part(lbl.(:net_pay), totals.net_ytd, fmt_amount)

          text = "#{lbl.(:year_to_date)}: " <> Enum.join(parts, " | ")
          [Rendro.block(Rendro.text(text, size: 9, color: colors.muted))]
        else
          []
        end

      _other ->
        []
    end
  end

  defp maybe_ytd_part(acc, label, amount, fmt), do: acc ++ ["#{label} #{fmt.(amount)}"]

  # ---------------------------------------------------------------------------
  # Totals derivation (D-13) — shared by validate_reconciliation!/1 (validate
  # half) and body_section/2 (render half).
  # ---------------------------------------------------------------------------

  defp derive_totals(%{earnings: earnings, deductions: deductions}) do
    gross = sum_amounts(earnings)
    total_deductions = sum_amounts(deductions)
    net = Decimal.sub(gross, total_deductions)
    gross_ytd = sum_ytd(earnings)
    deductions_ytd = sum_ytd(deductions)
    net_ytd = Decimal.sub(gross_ytd, deductions_ytd)

    %{
      gross: gross,
      deductions: total_deductions,
      net: net,
      gross_ytd: gross_ytd,
      deductions_ytd: deductions_ytd,
      net_ytd: net_ytd
    }
  end

  defp sum_amounts(lines) do
    Enum.reduce(lines, Decimal.new(0), fn %{amount: amount}, acc -> Decimal.add(acc, amount) end)
  end

  defp sum_ytd(lines) do
    Enum.reduce(lines, Decimal.new(0), fn line, acc ->
      case Map.get(line, :ytd) do
        %Decimal{} = ytd -> Decimal.add(acc, ytd)
        _other -> acc
      end
    end)
  end

  defp footer_section(data, opts) do
    colors = palette(opts)

    payment_block =
      case Map.get(data, :payment_method) do
        blank when blank in [nil, ""] -> []
        pm -> [Rendro.block(Rendro.text(glyph_safe(pm), size: 9, color: colors.muted))]
      end

    Rendro.section(
      name: :payslip_footer,
      region: :footer,
      content: payment_block ++ [Rendro.page_number(color: colors.muted, size: 9)]
    )
  end

  # ---------------------------------------------------------------------------
  # Color seam (S1 / PLUMB-02 swap)
  # ---------------------------------------------------------------------------

  # `nil` branch keeps Payslip's exact current literals (byte-identical no-theme
  # path, PLUMB-03); the `theme ->` branch reads `Rendro.Theme.resolve(theme).colors`
  # (colors ONLY — no type-scale read). `:palette` stays the winning layer (D-01).
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
  # Data validation (errors-as-product, D-15). D-13 gross-to-net
  # reconciliation is layered on separately (see validate_reconciliation!/1).
  # ---------------------------------------------------------------------------

  defp validate_data!(data) when not is_map(data) do
    raise ArgumentError, """
    Rendro.Recipes.Payslip.document/2 — invalid data argument.

    What:  data must be a map.
    Where: Rendro.Recipes.Payslip.validate_data!/1
    Why:   Received a non-map value: #{inspect(data)} (#{Rendro.Recipes.Pagination.type_name(data)}).
    Next:  Pass a map with required keys :employer, :employee, :period, :pay_date,
           :earnings, :deductions, :net_pay.
    """
  end

  defp validate_data!(data) do
    validate_required_keys!(data)
    validate_employer!(Map.get(data, :employer))
    validate_employee!(Map.get(data, :employee))
    validate_period!(Map.get(data, :period))
    validate_pay_date!(Map.get(data, :pay_date))
    validate_lines!(Map.get(data, :earnings), :earnings, require_non_empty: true)
    validate_lines!(Map.get(data, :deductions), :deductions, require_non_empty: false)
    validate_decimal_field!(Map.get(data, :net_pay), ":net_pay")
    validate_reconciliation!(data)
    :ok
  end

  # D-13: gross-to-net reconciliation, validated via Decimal.equal?/2 (never
  # `==`, which would treat 1.0 and 1.00 as unequal struct field values).
  # Runs only after every field above has already passed shape/type
  # validation, so derive_totals/1's Decimal folds are safe.
  defp validate_reconciliation!(data) do
    totals = derive_totals(data)
    net_pay = Map.get(data, :net_pay)

    unless Decimal.equal?(net_pay, totals.net) do
      raise ArgumentError, """
      Rendro.Recipes.Payslip.document/2 — :net_pay mismatch.

      What:  :net_pay must equal gross earnings minus total deductions.
      Where: Rendro.Recipes.Payslip.validate_data!/1
      Why:   Supplied net_pay: #{inspect(net_pay)},
             Derived net_pay (gross #{inspect(totals.gross)} - deductions #{inspect(totals.deductions)}): #{inspect(totals.net)}.
      Next:  Correct :net_pay, or adjust :earnings/:deductions amounts so they reconcile.
      """
    end

    maybe_validate_totals!(Map.get(data, :totals), totals)
  end

  defp maybe_validate_totals!(caller_totals, derived) when is_map(caller_totals) do
    assert_totals_field!(caller_totals, :gross, derived.gross)
    assert_totals_field!(caller_totals, :deductions, derived.deductions)
    assert_totals_field!(caller_totals, :net, derived.net)
    assert_totals_field!(caller_totals, :gross_ytd, derived.gross_ytd)
    assert_totals_field!(caller_totals, :deductions_ytd, derived.deductions_ytd)
    assert_totals_field!(caller_totals, :net_ytd, derived.net_ytd)
    :ok
  end

  defp maybe_validate_totals!(_caller_totals, _derived), do: :ok

  defp assert_totals_field!(caller_totals, key, derived_value) do
    if Map.has_key?(caller_totals, key) do
      supplied = Map.get(caller_totals, key)

      unless Decimal.equal?(supplied, derived_value) do
        raise ArgumentError, """
        Rendro.Recipes.Payslip.document/2 — :totals.#{key} mismatch.

        What:  The caller-supplied :totals.#{key} does not match the derived value.
        Where: Rendro.Recipes.Payslip.validate_data!/1
        Why:   Supplied #{key}: #{inspect(supplied)}, Derived #{key}: #{inspect(derived_value)}.
        Next:  Remove :totals.#{key} to skip this check, or correct the value.
        """
      end
    end

    :ok
  end

  defp validate_required_keys!(data) do
    required = [:employer, :employee, :period, :pay_date, :earnings, :deductions, :net_pay]
    missing = Enum.filter(required, fn key -> not Map.has_key?(data, key) end)

    unless missing == [] do
      raise ArgumentError, """
      Rendro.Recipes.Payslip.document/2 — missing required key(s) in data.

      What:  Required payslip data keys are missing.
      Where: Rendro.Recipes.Payslip.validate_data!/1
      Why:   Missing key(s): #{inspect(missing)}.
      Next:  Provide all required keys: :employer, :employee, :period, :pay_date,
             :earnings, :deductions, :net_pay. :totals and :payment_method are optional.
      """
    end
  end

  defp validate_employer!(employer) when is_map(employer) do
    validate_required_binary_field!(employer, :name, :employer)
  end

  defp validate_employer!(employer) do
    raise ArgumentError, """
    Rendro.Recipes.Payslip.document/2 — invalid :employer shape.

    What:  :employer must be a map with a required :name key, e.g. %{name: "Acme Corp"}.
    Where: Rendro.Recipes.Payslip.validate_data!/1
    Why:   Received: #{inspect(employer)} (#{Rendro.Recipes.Pagination.type_name(employer)}).
    Next:  Pass a map with at least a :name key, e.g. %{name: "Acme Corp"}.
    """
  end

  defp validate_employee!(employee) when is_map(employee) do
    validate_required_binary_field!(employee, :name, :employee)
  end

  defp validate_employee!(employee) do
    raise ArgumentError, """
    Rendro.Recipes.Payslip.document/2 — invalid :employee shape.

    What:  :employee must be a map with a required :name key, e.g. %{name: "Jordan Rivera"}.
    Where: Rendro.Recipes.Payslip.validate_data!/1
    Why:   Received: #{inspect(employee)} (#{Rendro.Recipes.Pagination.type_name(employee)}).
    Next:  Pass a map with at least a :name key, e.g. %{name: "Jordan Rivera"}.
    """
  end

  defp validate_required_binary_field!(map, key, owner) do
    unless Map.has_key?(map, key) do
      raise ArgumentError, """
      Rendro.Recipes.Payslip.document/2 — :#{owner} missing :#{key}.

      What:  :#{owner} must include a :#{key} key.
      Where: Rendro.Recipes.Payslip.validate_data!/1
      Why:   :#{owner} = #{inspect(map)} has no :#{key} key.
      Next:  Add a :#{key} key, e.g. %{#{key}: "..."}.
      """
    end

    value = Map.fetch!(map, key)

    unless is_binary(value) do
      raise ArgumentError, """
      Rendro.Recipes.Payslip.document/2 — invalid :#{owner}.#{key} type.

      What:  :#{owner}.#{key} must be a String.
      Where: Rendro.Recipes.Payslip.validate_data!/1
      Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
      Next:  Pass a binary string, e.g. #{key}: "Acme Corp".
      """
    end
  end

  defp validate_period!(period) when is_map(period) do
    validate_date_field!(period, :from, :period)
    validate_date_field!(period, :to, :period)
  end

  defp validate_period!(period) do
    raise ArgumentError, """
    Rendro.Recipes.Payslip.document/2 — invalid :period shape.

    What:  :period must be a map with :from and :to %Date{} keys.
    Where: Rendro.Recipes.Payslip.validate_data!/1
    Why:   Received: #{inspect(period)} (#{Rendro.Recipes.Pagination.type_name(period)}).
    Next:  Pass a map, e.g. %{from: ~D[2026-01-01], to: ~D[2026-01-31]}.
    """
  end

  defp validate_date_field!(map, key, owner) do
    unless Map.has_key?(map, key) do
      raise ArgumentError, """
      Rendro.Recipes.Payslip.document/2 — :#{owner} missing :#{key}.

      What:  :#{owner} must include a :#{key} key.
      Where: Rendro.Recipes.Payslip.validate_data!/1
      Why:   :#{owner} = #{inspect(map)} has no :#{key} key.
      Next:  Add a :#{key} key with a %Date{} value.
      """
    end

    value = Map.fetch!(map, key)

    unless is_struct(value, Date) do
      raise ArgumentError, """
      Rendro.Recipes.Payslip.document/2 — invalid :#{owner}.#{key} type.

      What:  :#{owner}.#{key} must be a %Date{} struct.
      Where: Rendro.Recipes.Payslip.validate_data!/1
      Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
      Next:  Use the ~D[YYYY-MM-DD] sigil or Date.new!/3.
      """
    end
  end

  defp validate_pay_date!(pay_date) when is_struct(pay_date, Date), do: :ok

  defp validate_pay_date!(pay_date) do
    raise ArgumentError, """
    Rendro.Recipes.Payslip.document/2 — invalid :pay_date type.

    What:  :pay_date must be a %Date{} struct.
    Where: Rendro.Recipes.Payslip.validate_data!/1
    Why:   Received: #{inspect(pay_date)} (#{Rendro.Recipes.Pagination.type_name(pay_date)}).
    Next:  Use the ~D[YYYY-MM-DD] sigil or Date.new!/3.
    """
  end

  defp validate_lines!(lines, field, opts) do
    require_non_empty = Keyword.get(opts, :require_non_empty, false)

    cond do
      not is_list(lines) ->
        raise ArgumentError, """
        Rendro.Recipes.Payslip.document/2 — invalid :#{field} value.

        What:  :#{field} must be a list of line maps.
        Where: Rendro.Recipes.Payslip.validate_data!/1
        Why:   Received: #{inspect(lines)} (#{Rendro.Recipes.Pagination.type_name(lines)}).
        Next:  Pass a list, e.g. [%{description: "Base Salary", amount: Decimal.new("1000.00")}].
        """

      require_non_empty and lines == [] ->
        raise ArgumentError, """
        Rendro.Recipes.Payslip.document/2 — :#{field} must not be empty.

        What:  :#{field} must contain at least one line.
        Where: Rendro.Recipes.Payslip.validate_data!/1
        Why:   Received an empty list.
        Next:  Provide at least one #{field} line, e.g. [%{description: "Base Salary", amount: Decimal.new("1000.00")}].
        """

      true ->
        lines
        |> Enum.with_index()
        |> Enum.each(fn {line, idx} -> validate_line!(line, field, idx) end)
    end
  end

  defp validate_line!(line, field, idx) when not is_map(line) do
    raise ArgumentError, """
    Rendro.Recipes.Payslip.document/2 — invalid :#{field} entry at index #{idx}.

    What:  Each :#{field} entry must be a map, e.g. %{description: "...", amount: Decimal.new("...")}.
    Where: Rendro.Recipes.Payslip.validate_data!/1
    Why:   #{field}[#{idx}] = #{inspect(line)} (#{Rendro.Recipes.Pagination.type_name(line)}).
    Next:  Pass a map with :description and :amount keys.
    """
  end

  defp validate_line!(line, field, idx) do
    validate_line_description!(line, field, idx)
    validate_line_amount!(line, field, idx)
    validate_line_ytd!(line, field, idx)
  end

  defp validate_line_description!(line, field, idx) do
    unless Map.has_key?(line, :description) do
      raise ArgumentError, """
      Rendro.Recipes.Payslip.document/2 — #{field}[#{idx}] missing :description.

      What:  Each :#{field} entry must include a :description key.
      Where: Rendro.Recipes.Payslip.validate_data!/1
      Why:   #{field}[#{idx}] = #{inspect(line)} has no :description key.
      Next:  Add a :description key, e.g. description: "Base Salary".
      """
    end

    value = Map.fetch!(line, :description)

    unless is_binary(value) do
      raise ArgumentError, """
      Rendro.Recipes.Payslip.document/2 — invalid #{field}[#{idx}].description type.

      What:  #{field}[#{idx}].description must be a String.
      Where: Rendro.Recipes.Payslip.validate_data!/1
      Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
      Next:  Pass a binary string, e.g. description: "Base Salary".
      """
    end
  end

  defp validate_line_amount!(line, field, idx) do
    unless Map.has_key?(line, :amount) do
      raise ArgumentError, """
      Rendro.Recipes.Payslip.document/2 — #{field}[#{idx}] missing :amount.

      What:  Each :#{field} entry must include an :amount key.
      Where: Rendro.Recipes.Payslip.validate_data!/1
      Why:   #{field}[#{idx}] = #{inspect(line)} has no :amount key.
      Next:  Add an :amount key, e.g. amount: Decimal.new("1000.00").
      """
    end

    validate_decimal_field!(Map.fetch!(line, :amount), "#{field}[#{idx}].amount")
  end

  defp validate_line_ytd!(line, field, idx) do
    case Map.get(line, :ytd) do
      nil -> :ok
      ytd -> validate_decimal_field!(ytd, "#{field}[#{idx}].ytd")
    end
  end

  defp validate_decimal_field!(%Decimal{}, _path), do: :ok

  defp validate_decimal_field!(value, path) when is_float(value) do
    raise ArgumentError, """
    Rendro.Recipes.Payslip.document/2 — invalid #{path} type.

    What:  #{path} must be a Decimal, not a Float.
    Where: Rendro.Recipes.Payslip.validate_data!/1
    Why:   Received a Float: #{inspect(value)}. Float arithmetic is not exact
           and can produce incorrect financial output.
    Next:  Use Decimal.new/1 — e.g. Decimal.new("#{value}").
    """
  end

  defp validate_decimal_field!(value, path) do
    raise ArgumentError, """
    Rendro.Recipes.Payslip.document/2 — invalid #{path} type.

    What:  #{path} must be a Decimal.
    Where: Rendro.Recipes.Payslip.validate_data!/1
    Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
    Next:  Use Decimal.new/1 — e.g. Decimal.new("3580.00").
    """
  end
end
