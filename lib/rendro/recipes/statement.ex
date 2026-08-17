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

  # Header reserved height (account name + period row + opening balance row,
  # plus the 118-08 dominant closing-balance summary box appended below
  # them — @closing_balance_band_h of the total). Bumped from the pre-118-08
  # 48pt (3 small text lines only) so the SHOW-01 gap-closure fix (surface
  # the closing balance as a dominant boxed summary element, mirroring
  # Payslip's Net Pay box) fits without overlapping the body region. This is
  # the frozen no-theme budget — NEVER changed by a theme (byte-identity,
  # PLUMB-03); see `header_height/1` for the themed budget.
  @header_height 88

  # 123-02 (D-01 fallout): under `Theme.default()` the 6 stacked header
  # blocks (title/body/body/backdrop(h=0)/small/display) total ~91.1pt at
  # the theme's type scale + the new 1.35 leading — a few points over the
  # frozen 88pt no-theme budget (which was sized for the SMALLER no-theme
  # literals at 1.2 leading). Rather than touch the type scale/leading (the
  # deliberate D-01 change) or the no-theme geometry (PLUMB-03), the honest
  # lever is the header capacity itself: give the themed path more room,
  # mirroring the vertical-centering-estimate lever used for Certificate's
  # single-page fit-check (RESEARCH GT-3). 96pt clears the ~91.1pt need with
  # a small safety margin (mirrors @row_epsilon's spirit).
  @themed_header_height 96

  # Height of the closing-balance backdrop box appended at the bottom of the
  # header region (118-08). Drawn via the same zero-height overlay mechanic
  # payslip.ex's summary_section/2 uses: the backdrop's block has an
  # explicit `height: 0` so it never advances the region's shared Y cursor,
  # letting the label+value text blocks that follow stack starting at the
  # SAME y the backdrop started at (painting on top of the backdrop instead
  # of being pushed below it).
  @closing_balance_band_h 40

  # Footer reserved height — MUST be non-zero so body_capacity reserves space
  # and "Page X of Y" does not overlap the last body row (D-03 / STMT-04).
  @footer_height 24

  @footer_y @page_height - @margin - @footer_height

  # Default table column rules: Date | Description | Amount | Balance
  @table_columns [{:fixed, 72}, {:share, 1}, {:fixed, 72}, {:fixed, 72}]

  # Conservative one-row epsilon margin (D-09): pack to capacity − epsilon so
  # sub-pixel rounding never tips a page into :content_overflow.
  # A blank trailing row is a far better failure mode than a render error.
  @row_epsilon 2.0

  # Fallback typical row height (pt) used when no rows have been measured yet
  # (empty statement). This is an empirical average for the default table style.
  @default_row_height 14.4

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
    colors = palette(opts)
    hh = header_height(opts)
    body_y = @margin + hh
    body_height = @page_height - 2 * @margin - hh - @footer_height

    base_regions = [
      Rendro.region(
        name: :header,
        role: :header,
        anchor: :top,
        x: @margin,
        y: @margin,
        width: @content_width,
        height: hh
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

    # 121-01 D-04/D-10: prepend the :background region FIRST (bottom of the
    # paint stack) iff the resolved palette differs from paper-white — gated
    # on the SAME palette(opts) sections/2 uses below (Pitfall 3), so the
    # region and section can never disagree. The light no-theme path leaves
    # `regions` untouched (byte-identical, PLUMB-03).
    regions =
      if Rendro.Recipes.Background.emit?(colors) do
        [Rendro.Recipes.Background.region(@page_width, @page_height) | base_regions]
      else
        base_regions
      end

    defaults = [name: :statement, regions: regions]

    # page_template/1 only understands PageTemplate struct keys. Recipe-level opts
    # (:labels, :formatters, ...) are consumed by the section builders via opts,
    # not here — filter them out so they thread through to sections/2 instead of
    # reaching struct!/2 and raising KeyError.
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

  defp header_section(%{period: period, account: account, opening_balance: ob} = data, opts) do
    fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)
    fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)
    lbl = Rendro.Recipes.Pagination.label_resolver(opts)
    colors = palette(opts)
    type = typography(opts)

    period_str = "#{fmt_date.(period.from)} to #{fmt_date.(period.to)}"
    ob_str = "#{lbl.(:opening_balance)}: #{fmt_amount.(ob)}"
    account_name = Map.get(account, :name, "")

    closing_balance = derive_closing_balance(data)

    # 118-08 gap-closure (SHOW-01): surface the closing balance as a
    # dominant boxed summary element — not merely the last cell of the
    # running-balance column — so content_hierarchy can honestly reach 5.
    # The backdrop's explicit `height: 0` means it does not advance the
    # header region's shared Y cursor (mirrors payslip.ex summary_section/2),
    # so the label+value blocks that follow it start at the same y and
    # visually overlay the drawn box.
    closing_backdrop =
      Rendro.path([{:rect, 0, 0, @content_width, @closing_balance_band_h}],
        fill: colors.surface,
        stroke: %{color: colors.rule, width: 0.75},
        x: 0,
        y: 0,
        width: @content_width,
        height: 0
      )

    closing_label =
      Rendro.block(
        Rendro.text("#{lbl.(:closing_balance)}",
          size: type.scale.small,
          font: type.fonts.body,
          line_height: type.leading,
          widows: type.widows,
          orphans: type.orphans,
          color: colors.muted
        )
      )

    # The SOLE `display`-anchored element on the Statement (D-01) — the "one
    # key fact." mono font, since it is an amount.
    closing_value =
      Rendro.block(
        Rendro.text(fmt_amount.(closing_balance),
          size: type.scale.display,
          font: type.fonts.mono,
          line_height: type.leading,
          widows: type.widows,
          orphans: type.orphans,
          color: colors.ink
        )
      )

    Rendro.section(
      name: :statement_header,
      region: :header,
      content: [
        Rendro.block(
          Rendro.text(account_name,
            size: type.scale.title,
            font: type.fonts.heading,
            line_height: type.leading,
            widows: type.widows,
            orphans: type.orphans,
            color: colors.ink
          )
        ),
        Rendro.block(
          Rendro.text(period_str,
            size: type.scale.body,
            font: type.fonts.body,
            line_height: type.leading,
            widows: type.widows,
            orphans: type.orphans,
            color: colors.muted
          )
        ),
        Rendro.block(
          Rendro.text(ob_str,
            size: type.scale.body,
            font: type.fonts.body,
            line_height: type.leading,
            widows: type.widows,
            orphans: type.orphans,
            color: colors.muted
          )
        ),
        closing_backdrop,
        closing_label,
        closing_value
      ]
    )
  end

  # ---------------------------------------------------------------------------
  # Header geometry seam (123-02 D-01 fallout) — the structural twin of
  # palette/1 and typography/1 for the ONE geometry constant that must vary
  # by theme presence. The `nil` branch is the frozen no-theme budget
  # (PLUMB-03); the themed branch is the wider budget the default theme's
  # type scale + 1.35 leading actually needs (see @themed_header_height).
  # ---------------------------------------------------------------------------
  defp header_height(opts) do
    case opts[:theme] do
      nil -> @header_height
      _theme -> @themed_header_height
    end
  end

  # ---------------------------------------------------------------------------
  # Color seam (S1 / PLUMB-01)
  # ---------------------------------------------------------------------------

  # Returns the role → RGB map for this render. When no `:theme` is supplied the
  # `nil` branch reproduces Statement's exact current literals — `surface
  # {245, 245, 245}` (closing-balance band fill) and `rule {0, 0, 0}` (band
  # stroke) — so the `closing_backdrop` path stays byte-identical (PLUMB-03).
  # `ink`/`muted` are added at today's implicit black default and `background`
  # at paper-white (121-01 D-03) so every newly-seamed text/background site
  # resolves to its current literal on the no-theme path (byte-identical) and
  # to the swapped pole under a theme. When a `:theme` is supplied the base
  # becomes `Rendro.Theme.resolve(theme).colors` (9 integer-{r,g,b} roles,
  # colors ONLY — no type-scale read). The final `Map.merge(base,
  # :palette-override)` keeps an explicit `:palette` as the winning layer
  # (D-01). Non-color numerics (band stroke `width: 0.75`) are NOT seamed.
  defp palette(opts) do
    base =
      case opts[:theme] do
        nil ->
          %{
            ink: {0, 0, 0},
            muted: {0, 0, 0},
            background: {255, 255, 255},
            surface: {245, 245, 245},
            rule: {0, 0, 0}
          }

        theme ->
          Rendro.Theme.resolve(theme).colors
      end

    Map.merge(base, Keyword.get(opts, :palette, %{}))
  end

  # ---------------------------------------------------------------------------
  # Typography seam (TYPE-01 / TYPE-02 / TYPE-03) — the exact structural twin of
  # palette/1 for the type scale, font roles, and leading/widows/orphans.
  # ---------------------------------------------------------------------------

  # Returns the resolved typography for this render. When no `:theme` is
  # supplied the `nil` branch reproduces Statement's exact CURRENT literals —
  # NEVER `Rendro.Theme.default().typography` (that would apply the frozen
  # 21/16.5/... scale and break byte-identity, RESEARCH Pitfall 1) — so every
  # `%Text{}` that reads sizes/fonts/leading from here stays byte-identical
  # (TYPE-01/TYPE-03). The literal scale mirrors Statement's current sizes:
  # closing balance 22 (display, the D-01 anchor), account name 14 (title),
  # table cells 12 (subtitle), period/opening balance 10 (body), closing-balance
  # label 9 (small); `caption` is unused on the no-theme path (any value). All
  # three font roles default to `:default`, the always-registered
  # Helvetica-compatible built-in, which the font registry normalizes
  # identically to today's implicit `"Helvetica"` default → no byte drift. When
  # a `:theme` is supplied the base becomes
  # `Rendro.Theme.resolve(theme).typography`. The final `Map.merge` keeps an
  # explicit `:typography` opt as the winning override layer (mirrors :palette).
  defp typography(opts) do
    base =
      case opts[:theme] do
        nil ->
          %{
            scale: %{display: 22, title: 14, subtitle: 12, body: 10, small: 9, caption: 8},
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

  # Derives the exact closing balance (opening_balance + Σ signed line
  # amounts) via the same Decimal fold maybe_validate_closing_balance!/1
  # already uses to validate a caller-supplied :closing_balance — so the
  # rendered dominant summary box always matches whatever value the caller
  # asserted (or, when absent, the honest derived value).
  defp derive_closing_balance(%{opening_balance: ob, lines: lines}) do
    Enum.reduce(lines, ob, fn %{amount: amt}, bal -> Decimal.add(bal, amt) end)
  end

  defp body_section(%{opening_balance: ob, lines: lines} = _data, opts) do
    colors = palette(opts)
    type = typography(opts)
    fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)
    fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)
    lbl = Rendro.Recipes.Pagination.label_resolver(opts)

    rows_with_balance = fold_balance(ob, lines)

    table_header = ["Date", "Description", "Amount", lbl.(:balance)]
    table_opts = [header: table_header, columns: @table_columns]

    # Convert balanced rows to formatted table rows, seamed to `colors.ink`
    # (D-02) via `cell_text/2` at size 12 — the implicit `Rendro.Text` default
    # a plain-string cell already normalized to (Pitfall 1). Color does not
    # affect measurement, so heights/chunking below are unchanged.
    formatted_rows =
      Enum.map(rows_with_balance, fn %{date: d, description: desc, amount: amt, balance: bal} ->
        [
          cell_text(fmt_date.(d), colors, type),
          cell_text(desc, colors, type),
          cell_text(fmt_amount.(amt), colors, type),
          cell_text(fmt_amount.(bal), colors, type)
        ]
      end)

    # D-09: measure all rows at the body region width using the engine's OWN
    # font metrics so chunking uses real heights, not recipe-local estimates.
    # Curated roles are intentionally registered only by the explicit bridge on
    # the returned document. The ephemeral measurement document needs their
    # metrics, however, so register only known curated roles here; unknown roles
    # still surface as the typed render-time failure on the returned document.
    doc_for_measure =
      Rendro.Document.new()
      |> Rendro.Theme.Presets.register_metric_fonts(Map.values(type.fonts))

    {header_h, row_heights} =
      Rendro.measure_rows(formatted_rows, @content_width, doc_for_measure, table_opts)

    # Body capacity: body_height already excludes header and footer regions
    # (it is derived as page_height − 2×margin − header_height(opts) − @footer_height,
    # mirroring page_template/1 exactly so the region and this capacity can
    # never disagree — Pitfall 3). Subtracting them again gives a conservative
    # ~8% under-pack with no overflow risk — a small blank gap at the bottom
    # is always preferable to :content_overflow.
    hh = header_height(opts)
    body_height = @page_height - 2 * @margin - hh - @footer_height
    capacity = body_height - hh - @footer_height

    # Chunk rows into pages, accounting for the repeated table header on each page
    # and the brought/carried-forward extra rows. Reserve a conservative one-row
    # epsilon margin (D-09) so sub-pixel rounding never causes :content_overflow.
    #
    # Build rows_with_meta triples for the shared chunker.
    rows_with_meta =
      Enum.zip([formatted_rows, row_heights, rows_with_balance])
      |> Enum.map(fn {fmt_row, height, row_data} -> {fmt_row, height, row_data.balance} end)

    # Average row height for CF/BF overhead reservation; fall back to the
    # module-attribute default when no rows have been measured (empty statement).
    typical_row_h =
      if Enum.empty?(row_heights) do
        @default_row_height
      else
        Enum.sum(row_heights) / length(row_heights)
      end

    # Effective capacity per page:
    # header_h (repeated on every page) + brought-forward row + carried-forward row + epsilon
    # We reserve space for at most 2 extra rows (bf + cf) and the epsilon margin.
    effective_capacity = capacity - header_h - 2 * typical_row_h - @row_epsilon

    pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)

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
            [
              cell_text(lbl.(:carried_forward), colors, type),
              cell_text("", colors, type),
              cell_text("", colors, type),
              cell_text(fmt_amount.(balance_at_break), colors, type)
            ]
          else
            nil
          end

        # brought-forward: first row of each page after page 1 (balance from previous page's break)
        bf_row =
          if idx > 0 do
            [
              cell_text(lbl.(:brought_forward), colors, type),
              cell_text("", colors, type),
              cell_text("", colors, type),
              cell_text(fmt_amount.(prev_balance), colors, type)
            ]
          else
            nil
          end

        # Page row structure: [brought_forward?, ...txns, carried_forward?]
        full_page_rows =
          ([bf_row | page_rows] ++ [cf_row])
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

  # Every body/CF/BF table cell renders through the typography seam at the
  # `subtitle` role (no-theme literal-default 12 — the implicit `Rendro.Text`
  # default a plain-string cell already normalized to, Pitfall 1), carrying a
  # swappable `color: colors.ink` (D-02). RESEARCH Pitfall 5: this shared
  # helper renders BOTH label and amount columns, so it keeps ONE font role
  # (`body`) — it is NOT mono-ised. Color/font do not affect measurement, so
  # `Rendro.measure_rows` and `Rendro.table` both fed these same cells stay
  # byte-identical on the no-theme path.
  defp cell_text(text, colors, type),
    do:
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

  defp footer_section(_data, opts) do
    colors = palette(opts)

    page_number_opts =
      Keyword.put_new(Keyword.get(opts, :page_number_opts, []), :color, colors.muted)

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
    validate_account!(data.account)
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
    Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
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

  defp validate_account!(%{name: name}) when is_binary(name), do: :ok

  defp validate_account!(value) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid :account shape.

    What:  :account must be a map with a string :name.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
    Next:  Use %{name: "Acme Corp"}.
    """
  end

  defp validate_lines!(lines) when not is_list(lines) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — invalid :lines value.

    What:  :lines must be a list of transaction maps.
    Where: Rendro.Recipes.Statement.validate_data!/1
    Why:   Received: #{inspect(lines)} (#{Rendro.Recipes.Pagination.type_name(lines)}).
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
    Why:   lines[#{idx}].amount = #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
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
    Why:   Received: #{inspect(cb)} (#{Rendro.Recipes.Pagination.type_name(cb)}).
    Next:  Use Decimal.new/1 — e.g. Decimal.new("100.00").
    """
  end

  # A well-typed top-level :closing_balance is a caller assertion: it MUST equal
  # the value derived from opening_balance + the signed line amounts (D-06). By
  # the time this runs, opening_balance and lines are already validated (see
  # validate_data!/1 ordering), so the fold is safe. Mirrors the
  # :summary.closing_balance check in maybe_validate_summary!/1.
  defp maybe_validate_closing_balance!(%{closing_balance: cb, opening_balance: ob, lines: lines})
       when is_struct(cb, Decimal) do
    derived_closing = Enum.reduce(lines, ob, fn %{amount: amt}, bal -> Decimal.add(bal, amt) end)

    unless Decimal.equal?(cb, derived_closing) do
      raise ArgumentError, """
      Rendro.Recipes.Statement.document/2 — :closing_balance mismatch.

      What:  The caller-supplied :closing_balance does not match the derived value.
      Where: Rendro.Recipes.Statement.validate_data!/1
      Why:   Supplied: #{inspect(cb)}, Derived: #{inspect(derived_closing)}.
      Next:  Remove :closing_balance to let the recipe derive it, or correct the value.
      """
    end

    :ok
  end

  defp maybe_validate_closing_balance!(_data), do: :ok

  defp maybe_validate_summary!(%{summary: summary, opening_balance: ob, lines: lines})
       when is_map(summary) do
    derived_closing =
      Enum.reduce(lines, ob, fn %{amount: amt}, bal -> Decimal.add(bal, amt) end)

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
end
