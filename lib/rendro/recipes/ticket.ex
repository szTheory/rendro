defmodule Rendro.Recipes.Ticket do
  @moduledoc """
  Data-driven, archetype-agnostic ticket recipe. The visual anchor is an
  ordered placement grid (D-02) — `:placement => [%{label, value}]`, 1 to 4
  cells — whose values render in the largest type on the page.

  Ships **one** recipe (D-01): the concrete default is an event/admission
  ticket (anchor = Section/Row/Seat), but the SAME code renders a
  boarding-pass shape (Gate/Seat/Group) purely via caller data + labels —
  zero archetype branching in this file. For example:

      # Event ticket
      placement: [
        %{label: "Section", value: "GA"},
        %{label: "Row", value: "H"},
        %{label: "Seat", value: "24"}
      ]

      # Boarding pass -- SAME recipe, different data
      placement: [
        %{label: "Gate", value: "B12"},
        %{label: "Seat", value: "14C"},
        %{label: "Group", value: "2"}
      ]

  Uses the Tiered Composition pattern, mirroring `Rendro.Recipes.Certificate`:

    - `document/2`      — Batteries-included; returns a fully assembled
                          `%Rendro.Document{}` ready for `Rendro.render/2`.
    - `page_template/1` — Layout only; returns the `%Rendro.PageTemplate{}`.
                          Geometry is derived from `Rendro.PageSize.resolve/2`
                          (A6 default, portrait — the ticket's native physical
                          size, per 118-08/SHOW-01) — zero hardcoded numerics
                          (D-03), so A4, US Letter, and A6 all render correctly.
    - `sections/2`      — Content only; returns a list of `%Rendro.Section{}`
                          structs mapped to named regions.

  The ticket itself is a fixed landscape band anchored at the top of the
  page (`:main` + `:stub` regions, `anchor: :fixed`), with an optional
  `:terms` region (`anchor: :flow`) below it.

  ## Required data keys

    - `:issuer` — `%{name (required), venue}`
    - `:title` — ticket title, e.g. `"Indie Night: The Lumen Set"`
    - `:placement` — 1 to 4 `%{label, value}` entries (D-02, the anchor)
    - `:code` — `%{reference (required, non-blank), label, image}`, where
      `:image` is `{:path, Path.t()} | {:binary, binary()} | nil`

  ## Optional data keys

    - `:subtitle` — supporting text under the title
    - `:terms` — fine-print terms, rendered in the `:terms` region

  ## Code area (D-05/D-06/D-07/D-08)

  The stub always draws a bordered code box. The human-readable
  `code.reference` ALWAYS renders, even when `code.image` is supplied. With
  no image, the box shows the centered reference — never a faux
  barcode/QR pattern. With an image, it is placed fit-contain (aspect
  preserving), centered, under the fixed internal logical name
  `:ticket_code` — callers never touch the asset registry.

  ## Jurisdiction / label / formatting overrides (D-16)

  `:palette`, `:labels`, and `:formatters` are three orthogonal override maps
  merged over recipe-shipped defaults — the same convention as
  `Rendro.Recipes.Invoice`'s `palette(opts)` seam.
  """
  @moduledoc tags: [:adapter]

  # 118-08 gap-closure (SHOW-01): the ticket now defaults to its native A6
  # physical size (postcard/ticket-stock, 297.64 x 419.53pt) instead of a
  # much larger A4 canvas — the prior A6-sized content sitting on an A4
  # sheet left ~65% of the page empty (118-06-FINDINGS.md). The fixture
  # already carries `"paper": "a6"`; this makes that the recipe's own
  # default rather than requiring every caller to pass page_size: :a6.
  # @default_margin is likewise A6-appropriate (a 72pt/1in margin would
  # consume nearly half of an A6 sheet's width).
  @default_page_size :a6
  @default_margin 18

  # D-03: band height is a dimensionless RATIO of content width, never a
  # fixed-point constant, so A4/US Letter/A6 geometry falls out identically.
  # The stub split is likewise a ratio of the band's own width. 118-08:
  # lowered from 2.4 to 2.0 (taller band relative to its width) — font sizes
  # are absolute pt values that do NOT shrink with the page, so switching
  # the default to the much-narrower A6 band_w left too little band_h for a
  # realistic ticket's full main-region content (issuer + a wrapped 2-line
  # title + a wrapped 2-line subtitle + the placement grid).
  @band_ratio 2.0
  @stub_ratio 0.68
  @gap 16

  # D-05: interior padding subtracted from the smaller of (stub width, band
  # height) to compute the code box side length -- see stub_section/2.
  @box_pad 8.0

  # D-18: recipe-owned default labels so Ticket.document(data) with zero
  # :labels/:formatters opts renders correct jurisdiction-neutral English
  # chrome. Rendro.Format.label/1 has NO fallback clause -- every label key
  # referenced anywhere in this module's section builders MUST be a key here.
  @default_labels %{
    admit: "Admit One",
    seat: "Seat",
    gate: "Gate",
    section: "Section",
    row: "Row",
    reference: "Reference",
    present_code: "Present this reference at entry."
  }

  @doc """
  Returns a `%Rendro.PageTemplate{}` with geometry derived from the page size
  option. Default is A6 portrait (the ticket's native physical size). Three
  named regions: `:main` (the D-02 placement-grid anchor), `:stub` (the
  D-05/D-06/D-07/D-08/D-09 code area), and `:terms` (optional fine print).

  ## Options

    - `:page_size` — `:a6` (default), `:a4`, `:us_letter`, or `{width, height}` tuple
    - `:margin_top` / `:margin_right` / `:margin_bottom` / `:margin_left` — margin in pt (default 18)
    - `:name` — template name atom (default `:ticket`)

  ## Examples

      iex> template = Rendro.Recipes.Ticket.page_template()
      iex> Enum.map(template.regions, & &1.name)
      [:main, :stub, :terms]

  """
  @spec page_template(keyword()) :: Rendro.PageTemplate.t()
  def page_template(opts \\ []) do
    g = geometry(opts)
    colors = palette(opts)

    base_regions = [
      Rendro.region(
        name: :main,
        role: :custom,
        anchor: :fixed,
        x: g.ml,
        y: g.mt,
        width: g.stub_split,
        height: g.band_h
      ),
      Rendro.region(
        name: :stub,
        role: :custom,
        anchor: :fixed,
        x: g.ml + g.stub_split,
        y: g.mt,
        width: g.stub_width,
        height: g.band_h
      ),
      Rendro.region(
        name: :terms,
        role: :body,
        anchor: :flow,
        x: g.ml,
        y: g.terms_y,
        width: g.content_w,
        height: g.terms_h
      )
    ]

    # 121-03: prepend the shared :background region FIRST iff the resolved
    # palette differs from paper-white — gated on the SAME palette(opts)
    # sections/2 uses below (Pitfall 3). Light no-theme path is untouched.
    regions =
      if Rendro.Recipes.Background.emit?(colors) do
        [Rendro.Recipes.Background.region(g.pw, g.ph) | base_regions]
      else
        base_regions
      end

    defaults = [
      name: :ticket,
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
  Assembles and returns a fully composed `%Rendro.Document{}`. Validates
  `data` (D-04/D-10 errors-as-product) before building the template.

  ## Examples

      iex> data = %{
      ...>   issuer: %{name: "Aurora Live"},
      ...>   title: "Indie Night: The Lumen Set",
      ...>   placement: [%{label: "Seat", value: "24"}],
      ...>   code: %{reference: "AUR-88213-GA"}
      ...> }
      iex> doc = Rendro.Recipes.Ticket.document(data)
      iex> doc.page_template
      :ticket

  """
  @spec document(map(), keyword()) :: Rendro.Document.t()
  def document(data, opts \\ []) do
    validate_data!(data)
    template = page_template(opts)
    secs = sections(data, opts)

    # D-08/D-10: register the caller-supplied image ONLY after
    # validate_data!/1 (called above, and again inside sections/2) has
    # already pre-validated the bytes -- register_image/3 re-parses, but the
    # bytes are already known-good, so Rendro.AssetRegistry.InvalidAssetError
    # should never actually trigger here. image: nil and image omitted both
    # take the `else` branch, so they register nothing -- byte-identical
    # output (D-08).
    base_doc =
      if image = get_in(data, [:code, :image]) do
        Rendro.Document.new() |> Rendro.Document.register_image(:ticket_code, image)
      else
        Rendro.Document.new()
      end

    base_doc
    |> Rendro.Document.add_template(template)
    |> Rendro.Document.set_template(template.name)
    |> then(fn d -> Enum.reduce(secs, d, &Rendro.Document.add_section(&2, &1)) end)
  end

  @doc """
  Returns a list of `%Rendro.Section{}` structs mapping ticket content to the
  `:main`, `:stub`, and `:terms` regions. Validates `data` and the
  `:labels`/`:formatters` opts shape (D-19) before building any section
  content.
  """
  @spec sections(map(), keyword()) :: [Rendro.Section.t()]
  def sections(data, opts \\ []) do
    validate_data!(data)
    Rendro.Recipes.Pagination.validate_labels!(opts, "Rendro.Recipes.Ticket.document/2")
    Rendro.Recipes.Pagination.validate_formatters!(opts, "Rendro.Recipes.Ticket.document/2")

    g = geometry(opts)
    colors = palette(opts)

    base_sections = [
      main_section(data, opts),
      stub_section(data, opts),
      terms_section(data, opts)
    ]

    # Same predicate + same palette(opts) as page_template/1 (Pitfall 3) —
    # the region and section can never disagree.
    if Rendro.Recipes.Background.emit?(colors) do
      [Rendro.Recipes.Background.section(colors, g.pw, g.ph) | base_sections]
    else
      base_sections
    end
  end

  # ---------------------------------------------------------------------------
  # Private section builders
  # ---------------------------------------------------------------------------

  # D-02: the placement-grid anchor, via Rendro.table/2 (NOT manual block
  # stacking -- a hand-stacked multi-column layout would require fragile
  # height-zeroing tricks against paginate.ex's single shared per-region Y
  # cursor; a table's own column-layout logic already handles this
  # correctly). One data row of large (scale.title, 26pt default) values
  # under a header row of small caps (8pt) labels -- the values are the
  # single largest text anywhere on the page, matching D-02's dominant-anchor
  # requirement. 118-08 gap-closure (SHOW-01): bumped from 22pt so the WHOLE
  # placement-grid group reads as unambiguously the page's largest text (not
  # four equally-large-but-unremarkable fields) now that the ticket renders at
  # its smaller native A6 size. The SAME code renders any 1-4 cell :placement
  # shape (event or boarding-pass) purely via data -- zero archetype branching
  # (D-01); no individual label (e.g. "Seat") is ever singled out.
  #
  # 122-03 typography seam (Q3): the placement value's former literal 26 is now
  # `scale.title` — the LARGEST text on the page, but NOT the `display` anchor.
  # Q3 resolves the 7-distinct-sizes-vs-6-roles clash by making the reference
  # CODE (8pt) the SOLE `display` anchor (D-01, the "one key fact") via
  # non-monotone assignment, and exempting the two mono micro-sizes
  # (@caption_size 7, @present_code_size 6) from the scale seam (font-only mono).
  defp main_section(data, opts) do
    colors = palette(opts)
    type = typography(opts)
    roles = ticket_roles(opts, type)
    g = geometry(opts)

    # 118-08: the :main region is narrower now that the ticket defaults to
    # native A6 (g.stub_split, ~178pt vs. ~307pt at the prior A4 default).
    # Free-standing text blocks measure at their NATURAL (unwrapped) width
    # unless a block width is supplied (lib/rendro/pipeline/measure.ex's Text
    # clause), so any realistic issuer/title/subtitle string now needs an
    # explicit width to wrap within the region instead of raising
    # :content_overflow. The placement-grid table is unaffected — its cells
    # already wrap to their own share-column width.
    main_w = g.stub_split

    header_cells =
      Enum.map(data.placement, fn %{label: l} ->
        locator_cell(
          Rendro.block(
            Rendro.text(String.upcase(l),
              size: type.scale.caption,
              font: type.fonts.body,
              color: colors.muted,
              line_height: type.leading,
              widows: type.widows,
              orphans: type.orphans
            )
          ),
          opts
        )
      end)

    value_cells =
      Enum.map(data.placement, fn %{value: v} ->
        locator_cell(
          Rendro.block(
            Rendro.text(v,
              size: roles.placement,
              font: type.fonts.body,
              color: colors.ink,
              line_height: type.leading,
              widows: type.widows,
              orphans: type.orphans
            )
          ),
          opts
        )
      end)

    grid = Rendro.table([value_cells], locator_table_opts(header_cells, colors, opts))

    subtitle_blocks =
      case Map.get(data, :subtitle) do
        blank when blank in [nil, ""] ->
          []

        subtitle ->
          [
            Rendro.block(
              Rendro.text(subtitle,
                size: type.scale.body,
                font: type.fonts.body,
                color: colors.muted,
                line_height: type.leading,
                widows: type.widows,
                orphans: type.orphans
              ),
              width: main_w
            )
          ]
      end

    # Public supplied themes bind the placement grid with one rectilinear
    # rule. It reinforces the existing type-led rank without inventing a
    # catalog-only visual branch; the catalog path may only change band
    # capacity through geometry/1. The nil-theme path keeps its frozen bytes.
    placement_rule_blocks =
      case Keyword.get(opts, :theme) do
        nil ->
          []

        theme ->
          [
            Rendro.path([{:move, 0, 0}, {:line, main_w, 0}],
              stroke: %{color: colors.rule, width: Rendro.Theme.resolve(theme).rules.thick},
              x: 0,
              y: 0,
              width: main_w,
              height: 0
            )
          ]
      end

    Rendro.section(
      name: :ticket_main,
      region: :main,
      content:
        [
          Rendro.block(
            Rendro.text(issuer_display(data.issuer),
              size: type.scale.small,
              font: type.fonts.body,
              color: colors.muted,
              line_height: type.leading,
              widows: type.widows,
              orphans: type.orphans
            ),
            width: main_w
          ),
          Rendro.block(
            Rendro.text(data.title,
              size: roles.title,
              font: type.fonts.heading,
              color: colors.ink,
              line_height: type.leading,
              widows: type.widows,
              orphans: type.orphans
            ),
            width: main_w
          )
        ] ++
          subtitle_blocks ++
          placement_rule_blocks ++
          [Rendro.block(grid)]
    )
  end

  defp issuer_display(issuer) do
    case Map.get(issuer, :venue) do
      blank when blank in [nil, ""] -> issuer.name
      venue -> "#{issuer.name} - #{venue}"
    end
  end

  # D-05/D-06/D-07/D-08/D-09: the stub's code-area composition. Content list
  # order relies on the VERIFIED zero-height overlay mechanic
  # (paginate.ex:anchor_region_blocks/3 -- a block with explicit height: 0
  # does not advance the region's shared Y cursor, so the next block starts
  # at the SAME y, producing a visual overlay). The perforation and code-box
  # backdrop are both height: 0 so neither displaces the reference/image
  # content that follows.
  # 118-08: reference/caption text sizes were tuned for the prior A4-default
  # stub width (~144pt); the ticket's smaller native A6 stub is ~84pt. Every
  # stub text block below gets an explicit `width:` (never left to measure
  # at its natural, unwrapped width) so a too-long value safely WRAPS
  # (lib/rendro/pipeline/measure.ex's wrap_text/5 falls back to
  # per-grapheme splitting for a single unbreakable token) instead of
  # raising :content_overflow.
  # 122-03 typography seam (Q3): the reference CODE's former literal 8 is now
  # `scale.display` (the SOLE D-01 anchor) — read inline in reference_blocks/5.
  # @caption_size (7) and @present_code_size (6) are the two EXEMPT mono
  # micro-sizes: they stay LITERAL module attrs (never collapsed into a scale
  # role — 7 distinct sizes cannot fit 6 roles without a byte-changing
  # collapse, RESEARCH Q3/Pitfall 4) and their call sites seam ONLY their FONT
  # to `mono`. The `size:` on those runs stays a variable read of the attr
  # (NOT an inline literal) so byte-identity holds and the Wave-3 no-inline-size
  # teeth test does not trip.
  @caption_size 7
  @present_code_size 6

  defp stub_section(data, opts) do
    colors = palette(opts)
    type = typography(opts)
    roles = ticket_roles(opts, type)
    lbl = Rendro.Recipes.Pagination.label_resolver(opts, @default_labels)
    g = geometry(opts)

    box_size = min(g.stub_width, g.band_h) - 2 * @box_pad
    box_x = (g.stub_width - box_size) / 2
    text_x = box_x + 8
    avail_w = max(g.stub_width - text_x - 4, 1.0)

    # D-09: dashed perforation at the stub's own left edge (x=0 relative to
    # this region = the boundary with :main).
    perforation =
      Rendro.path([{:move, 0, 0}, {:line, 0, g.band_h}],
        stroke: %{color: colors.rule, width: 0.75, dash: [3, 3]},
        x: 0,
        y: 0,
        width: 1,
        height: 0
      )

    # D-05: the bordered code box backdrop -- always drawn, derived (not
    # hardcoded) from the region geometry. height: 0 so the box's own drawn
    # rectangle (real height = box_size, from the :rounded_rect op's own h
    # argument) does not push subsequent content down.
    code_box =
      Rendro.path([{:rounded_rect, box_x, 0, box_size, box_size, 6.0}],
        stroke: %{color: colors.rule, width: 1.0},
        x: 0,
        y: 0,
        width: box_x + box_size,
        height: 0
      )

    image = get_in(data, [:code, :image])
    stub_colors = if dark_atomic_locator?(opts), do: %{colors | ink: colors.muted}, else: colors

    Rendro.section(
      name: :ticket_stub,
      region: :stub,
      content:
        [perforation, code_box] ++
          code_area_blocks(
            data,
            stub_colors,
            type,
            roles,
            lbl,
            image,
            box_x,
            box_size,
            text_x,
            avail_w
          )
    )
  end

  # D-07: no image -- the box contains ONLY the centered reference (+
  # optional caption), never a faux barcode/QR stripe pattern. Reference
  # block(s) start at the SAME y as the box backdrop (height: 0), so they
  # overlay the box from its top edge.
  defp code_area_blocks(data, colors, type, roles, lbl, nil, _box_x, _box_size, text_x, avail_w) do
    reference_blocks(data, colors, type, roles, lbl, text_x, avail_w) ++
      [present_code_caption(colors, type, lbl, text_x, avail_w)]
  end

  # D-08: image supplied -- fit-contain (aspect-preserving), centered, under
  # the fixed internal logical name :ticket_code, placed IMMEDIATELY after
  # the box backdrop. Its measured height (real, per measure.ex's Image
  # clause) naturally advances the cursor past the box, so the
  # ALWAYS-VISIBLE reference (D-06) renders AFTER it -- below the image,
  # never overlaid on top of it.
  defp code_area_blocks(data, colors, type, roles, lbl, _image, box_x, box_size, text_x, avail_w) do
    image_block =
      Rendro.Component.image(:ticket_code, fit: {box_size, box_size})
      |> Map.put(:x, box_x)

    [image_block | reference_blocks(data, colors, type, roles, lbl, text_x, avail_w)]
  end

  # D-06: the human-readable reference -- REQUIRED, ALWAYS renders, even
  # when a PNG is supplied. Upper-cased, with a small muted caption above.
  defp reference_blocks(data, colors, type, roles, lbl, text_x, avail_w) do
    caption_label = Map.get(data.code, :label) || lbl.(:reference)
    reference_text = String.upcase(data.code.reference)

    [
      # EXEMPT micro-size: keep the literal @caption_size (7) attr, seam FONT
      # only to mono.
      Rendro.block(
        Rendro.text(caption_label,
          size: @caption_size,
          font: type.fonts.mono,
          color: colors.muted,
          line_height: type.leading,
          widows: type.widows,
          orphans: type.orphans
        ),
        x: text_x,
        width: avail_w
      ),
      # The reference code is a compact utility fact — mono font.
      Rendro.block(
        Rendro.text(reference_text,
          size: roles.reference,
          font: type.fonts.mono,
          color: colors.ink,
          line_height: type.leading,
          widows: type.widows,
          orphans: type.orphans
        ),
        x: text_x,
        width: avail_w
      )
    ]
  end

  # D-07: optional caption, no-image path only.
  # EXEMPT micro-size: keep the literal @present_code_size (6) attr, seam FONT
  # only to mono.
  defp present_code_caption(colors, type, lbl, text_x, avail_w) do
    Rendro.block(
      Rendro.text(lbl.(:present_code),
        size: @present_code_size,
        font: type.fonts.mono,
        color: colors.muted,
        line_height: type.leading,
        widows: type.widows,
        orphans: type.orphans
      ),
      x: text_x,
      width: avail_w
    )
  end

  defp terms_section(data, opts) do
    colors = palette(opts)
    type = typography(opts)
    g = geometry(opts)

    # 118-08: an explicit width lets long fine-print terms wrap within the
    # :terms region instead of measuring at their natural (unwrapped) width
    # and raising :content_overflow — mirrors the same fix in main_section/2.
    content =
      case Map.get(data, :terms) do
        blank when blank in [nil, ""] ->
          []

        terms ->
          [
            Rendro.block(
              Rendro.text(terms,
                size: type.scale.caption,
                font: type.fonts.body,
                color: colors.muted,
                line_height: type.leading,
                widows: type.widows,
                orphans: type.orphans
              ),
              width: g.content_w
            )
          ]
      end

    Rendro.section(name: :ticket_terms, region: :terms, content: content)
  end

  # ---------------------------------------------------------------------------
  # Geometry (D-03) — derived from Rendro.PageSize.resolve/2, zero hardcoded
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
    band_w = content_w
    # Catalog fixtures include longer titles and subtitles than the protected
    # recipe samples. Its opt-in layout capacity retains the A6 page while
    # leaving the established themed recipe geometry byte-identical.
    band_h =
      case opts[:catalog_layout] do
        true -> max(band_w / @band_ratio, 250)
        _ -> band_w / @band_ratio
      end

    stub_split = band_w * @stub_ratio
    stub_width = band_w - stub_split

    terms_y = mt + band_h + @gap
    terms_h = ph - mb - terms_y

    %{
      pw: pw,
      ph: ph,
      ml: ml,
      mr: mr,
      mt: mt,
      mb: mb,
      content_w: content_w,
      band_w: band_w,
      band_h: band_h,
      stub_split: stub_split,
      stub_width: stub_width,
      terms_y: terms_y,
      terms_h: terms_h
    }
  end

  # ---------------------------------------------------------------------------
  # Color seam (S1 / PLUMB-02 swap)
  # ---------------------------------------------------------------------------

  # `nil` branch keeps Ticket's exact current literals (byte-identical no-theme
  # path, PLUMB-03); the `theme ->` branch reads `Rendro.Theme.resolve(theme).colors`
  # (colors ONLY — no type-scale read). `:palette` stays the winning layer (D-01).
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
  # Typography seam (TYPE-01 / TYPE-02 / TYPE-03) — structural twin of palette/1.
  # ---------------------------------------------------------------------------

  # Returns the resolved typography for this render: a named type scale, three
  # font roles, and leading/widows/orphans. When no `:theme` is supplied the
  # `nil` branch reproduces Ticket's exact CURRENT size literals via a
  # NON-MONOTONE role assignment (Q3): reference code 8 -> `display` (the SOLE
  # D-01 anchor), placement value 26 -> `title` (the largest text, NOT the
  # anchor), ticket title 16 -> `subtitle`, subtitle text 10 -> `body`, issuer
  # 9 -> `small`, placement-label/terms 8 -> `caption` (same literal 8 as
  # `display`, but a distinct role key — byte-identical and NOT a second display
  # binding). The two mono micro-sizes @caption_size (7) and @present_code_size
  # (6) are EXEMPT from this map (they stay literal attrs, font-only mono) —
  # this is what drops the scale-seamed distinct set from 7 to ≤6 roles. NEVER
  # `Rendro.Theme.default().typography` in the nil branch (RESEARCH Pitfall 1).
  # All font roles default to `:default` (built-in Helvetica; Ticket never
  # overrides its document default, so byte-identical). When a `:theme` is
  # supplied the base becomes `Rendro.Theme.resolve(theme).typography`. The
  # final `Map.merge` keeps an explicit `:typography` opt as the winning layer.
  defp typography(opts) do
    base =
      case opts[:theme] do
        nil ->
          %{
            scale: %{display: 8, title: 26, subtitle: 16, body: 10, small: 9, caption: 8},
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

  defp ticket_roles(opts, type) do
    case opts[:theme] do
      nil ->
        %{placement: type.scale.title, title: type.scale.subtitle, reference: type.scale.display}

      _theme ->
        %{
          placement: locator_value_size(opts, type),
          title: type.scale.title,
          reference: type.scale.caption
        }
    end
  end

  # The private atomic locator profile preserves a dominant value role while
  # keeping the widest fixed target token ("GA") on one line in an equal-share
  # four-column row. Other themed and un-themed paths retain their exact role.
  defp locator_value_size(opts, type) do
    if atomic_locator?(opts),
      do: min(type.scale.display, type.scale.title * 1.5),
      else: type.scale.display
  end

  # Catalog tooling may opt into the existing one-row locator archetype with
  # explicit atomic cells. The profile is generic: this recipe never receives
  # a catalog ID, brand, preset, or phase identifier.
  defp atomic_locator?(opts) do
    get_in(opts[:presentation_profile] || %{}, [:locator_layout]) == :atomic_equal_share
  end

  defp dark_atomic_locator?(opts) do
    atomic_locator?(opts) and match?(%{mode: :dark}, opts[:theme])
  end

  defp locator_table_opts(header_cells, colors, opts) do
    table_opts = [
      header: header_cells,
      columns: List.duplicate({:share, 1}, length(header_cells)),
      borders: :none
    ]

    if atomic_locator?(opts),
      do: Keyword.put(table_opts, :header_fill, colors.surface),
      else: table_opts
  end

  defp locator_cell(content, opts) do
    if atomic_locator?(opts),
      do: %Rendro.Cell{content: content, split_policy: :atomic},
      else: content
  end

  # ---------------------------------------------------------------------------
  # Data validation (errors-as-product, D-04). D-10's caller-image
  # pre-validation is new plumbing -- no prior-art copy source in this
  # codebase (Certificate/BrandedInvoice only ever register trusted,
  # library-shipped images).
  # ---------------------------------------------------------------------------

  defp validate_data!(data) when not is_map(data) do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — invalid data argument.

    What:  data must be a map.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   Received a non-map value: #{inspect(data)} (#{Rendro.Recipes.Pagination.type_name(data)}).
    Next:  Pass a map with required keys :issuer, :title, :placement, :code.
    """
  end

  defp validate_data!(data) do
    validate_required_keys!(data)
    validate_issuer!(Map.get(data, :issuer))
    validate_title!(Map.get(data, :title))
    validate_optional_text!(Map.get(data, :subtitle), :subtitle, 200)
    validate_placement!(Map.get(data, :placement))
    validate_code!(Map.get(data, :code))
    validate_optional_text!(Map.get(data, :terms), :terms, 600)
    :ok
  end

  defp validate_required_keys!(data) do
    required = [:issuer, :title, :placement, :code]
    missing = Enum.filter(required, fn key -> not Map.has_key?(data, key) end)

    unless missing == [] do
      raise ArgumentError, """
      Rendro.Recipes.Ticket.document/2 — missing required key(s) in data.

      What:  Required ticket data keys are missing.
      Where: Rendro.Recipes.Ticket.validate_data!/1
      Why:   Missing key(s): #{inspect(missing)}.
      Next:  Provide all required keys: :issuer, :title, :placement, :code.
             :subtitle and :terms are optional.
      """
    end
  end

  defp validate_issuer!(issuer) when is_map(issuer) do
    unless Map.has_key?(issuer, :name) do
      raise ArgumentError, """
      Rendro.Recipes.Ticket.document/2 — :issuer missing :name.

      What:  :issuer must include a :name key.
      Where: Rendro.Recipes.Ticket.validate_data!/1
      Why:   :issuer = #{inspect(issuer)} has no :name key.
      Next:  Add a :name key, e.g. %{name: "Aurora Live"}.
      """
    end

    name = Map.fetch!(issuer, :name)

    unless is_binary(name) do
      raise ArgumentError, """
      Rendro.Recipes.Ticket.document/2 — invalid :issuer.name type.

      What:  :issuer.name must be a String.
      Where: Rendro.Recipes.Ticket.validate_data!/1
      Why:   Received: #{inspect(name)} (#{Rendro.Recipes.Pagination.type_name(name)}).
      Next:  Pass a binary string, e.g. name: "Aurora Live".
      """
    end
  end

  defp validate_issuer!(issuer) do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — invalid :issuer shape.

    What:  :issuer must be a map with a required :name key, e.g. %{name: "Aurora Live"}.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   Received: #{inspect(issuer)} (#{Rendro.Recipes.Pagination.type_name(issuer)}).
    Next:  Pass a map with at least a :name key.
    """
  end

  defp validate_title!(title) when is_binary(title) and byte_size(title) > 200 do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — :title is too long.

    What:  :title exceeds the ticket anchor's length limit.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   #{byte_size(title)} bytes (limit: 200).
    Next:  Shorten :title to 200 bytes or fewer.
    """
  end

  defp validate_title!(title) when is_binary(title), do: :ok

  defp validate_title!(title) do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — invalid :title type.

    What:  :title must be a String.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   Received: #{inspect(title)} (#{Rendro.Recipes.Pagination.type_name(title)}).
    Next:  Pass a binary string, e.g. title: "Indie Night: The Lumen Set".
    """
  end

  defp validate_optional_text!(nil, _field, _limit), do: :ok

  defp validate_optional_text!(text, field, limit)
       when is_binary(text) and byte_size(text) > limit do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — :#{field} is too long.

    What:  :#{field} exceeds its length limit.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   #{byte_size(text)} bytes (limit: #{limit}).
    Next:  Shorten :#{field} to #{limit} bytes or fewer.
    """
  end

  defp validate_optional_text!(text, _field, _limit) when is_binary(text), do: :ok

  defp validate_optional_text!(text, field, _limit) do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — invalid :#{field} type.

    What:  :#{field} must be a String.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   Received: #{inspect(text)} (#{Rendro.Recipes.Pagination.type_name(text)}).
    Next:  Pass a binary string, or omit the :#{field} key.
    """
  end

  defp validate_placement!(placement) when is_list(placement) do
    count = length(placement)

    cond do
      count == 0 ->
        raise ArgumentError, """
        Rendro.Recipes.Ticket.document/2 — :placement must not be empty.

        What:  :placement must contain 1 to 4 entries (D-02).
        Where: Rendro.Recipes.Ticket.validate_data!/1
        Why:   Received an empty list.
        Next:  Provide 1 to 4 %{label:, value:} entries, e.g. [%{label: "Seat", value: "24"}].
        """

      count > 4 ->
        raise ArgumentError, """
        Rendro.Recipes.Ticket.document/2 — :placement has too many entries.

        What:  :placement must contain 1 to 4 entries (D-02's placement-grid cap).
        Where: Rendro.Recipes.Ticket.validate_data!/1
        Why:   Received #{count} entries.
        Next:  Reduce :placement to at most 4 %{label:, value:} entries.
        """

      true ->
        placement
        |> Enum.with_index()
        |> Enum.each(fn {entry, idx} -> validate_placement_entry!(entry, idx) end)
    end
  end

  defp validate_placement!(placement) do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — invalid :placement type.

    What:  :placement must be a list of 1 to 4 %{label:, value:} maps.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   Received: #{inspect(placement)} (#{Rendro.Recipes.Pagination.type_name(placement)}).
    Next:  Pass a list, e.g. [%{label: "Seat", value: "24"}].
    """
  end

  defp validate_placement_entry!(entry, idx) when is_map(entry) do
    validate_placement_field!(entry, :label, idx)
    validate_placement_field!(entry, :value, idx)
  end

  defp validate_placement_entry!(entry, idx) do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — invalid :placement entry at index #{idx}.

    What:  Each :placement entry must be a map with :label and :value keys.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   placement[#{idx}] = #{inspect(entry)} (#{Rendro.Recipes.Pagination.type_name(entry)}).
    Next:  Pass a map, e.g. %{label: "Seat", value: "24"}.
    """
  end

  defp validate_placement_field!(entry, key, idx) do
    unless Map.has_key?(entry, key) do
      raise ArgumentError, """
      Rendro.Recipes.Ticket.document/2 — placement[#{idx}] missing :#{key}.

      What:  Each :placement entry must include a :#{key} key.
      Where: Rendro.Recipes.Ticket.validate_data!/1
      Why:   placement[#{idx}] = #{inspect(entry)} has no :#{key} key.
      Next:  Add a :#{key} key, e.g. #{key}: "24".
      """
    end

    value = Map.fetch!(entry, key)

    cond do
      not is_binary(value) ->
        raise ArgumentError, """
        Rendro.Recipes.Ticket.document/2 — invalid placement[#{idx}].#{key} type.

        What:  placement[#{idx}].#{key} must be a String.
        Where: Rendro.Recipes.Ticket.validate_data!/1
        Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
        Next:  Pass a binary string, e.g. #{key}: "24".
        """

      byte_size(value) > 40 ->
        raise ArgumentError, """
        Rendro.Recipes.Ticket.document/2 — placement[#{idx}].#{key} is too long.

        What:  placement[#{idx}].#{key} exceeds the placement-cell length limit.
        Where: Rendro.Recipes.Ticket.validate_data!/1
        Why:   #{byte_size(value)} bytes (limit: 40).
        Next:  Shorten placement[#{idx}].#{key} to 40 bytes or fewer.
        """

      true ->
        :ok
    end
  end

  defp validate_code!(code) when is_map(code) do
    validate_code_reference!(code)
    validate_code_label!(Map.get(code, :label))
    validate_code_image!(Map.get(code, :image))
  end

  defp validate_code!(code) do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — invalid :code shape.

    What:  :code must be a map with a required :reference key.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   Received: #{inspect(code)} (#{Rendro.Recipes.Pagination.type_name(code)}).
    Next:  Pass a map, e.g. %{reference: "AUR-88213-GA"}.
    """
  end

  defp validate_code_reference!(code) do
    unless Map.has_key?(code, :reference) do
      raise ArgumentError, """
      Rendro.Recipes.Ticket.document/2 — :code missing :reference.

      What:  :code must include a :reference key.
      Where: Rendro.Recipes.Ticket.validate_data!/1
      Why:   :code = #{inspect(code)} has no :reference key.
      Next:  Add a :reference key, e.g. reference: "AUR-88213-GA".
      """
    end

    reference = Map.fetch!(code, :reference)

    cond do
      not is_binary(reference) ->
        raise ArgumentError, """
        Rendro.Recipes.Ticket.document/2 — invalid :code.reference type.

        What:  :code.reference must be a String.
        Where: Rendro.Recipes.Ticket.validate_data!/1
        Why:   Received: #{inspect(reference)} (#{Rendro.Recipes.Pagination.type_name(reference)}).
        Next:  Pass a binary string, e.g. reference: "AUR-88213-GA".
        """

      reference == "" ->
        raise ArgumentError, """
        Rendro.Recipes.Ticket.document/2 — :code.reference must not be blank.

        What:  :code.reference must be a non-empty String (D-06 -- the always-visible
               human-readable code).
        Where: Rendro.Recipes.Ticket.validate_data!/1
        Why:   Received an empty string.
        Next:  Provide a non-blank reference, e.g. reference: "AUR-88213-GA".
        """

      byte_size(reference) > 80 ->
        raise ArgumentError, """
        Rendro.Recipes.Ticket.document/2 — :code.reference is too long.

        What:  :code.reference exceeds the stub code-box length limit.
        Where: Rendro.Recipes.Ticket.validate_data!/1
        Why:   #{byte_size(reference)} bytes (limit: 80).
        Next:  Shorten :code.reference to 80 bytes or fewer.
        """

      true ->
        :ok
    end
  end

  defp validate_code_label!(nil), do: :ok
  defp validate_code_label!(label) when is_binary(label), do: :ok

  defp validate_code_label!(label) do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — invalid :code.label type.

    What:  :code.label must be a String.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   Received: #{inspect(label)} (#{Rendro.Recipes.Pagination.type_name(label)}).
    Next:  Pass a binary string, or omit the :label key.
    """
  end

  # D-10: the genuinely-new plumbing. Pre-validates code.image via the pure
  # Rendro.ImageParser.parse/1, BEFORE document/2 ever calls
  # Rendro.Document.register_image/3 -- this is what guarantees
  # Rendro.AssetRegistry.InvalidAssetError never leaks past validate_data!/1.
  defp validate_code_image!(nil), do: :ok

  defp validate_code_image!(image) do
    case resolve_image_bytes(image) do
      {:ok, bytes} ->
        case Rendro.ImageParser.parse(bytes) do
          {:ok, _info} -> :ok
          {:error, reason} -> raise_invalid_image!(image, reason)
        end

      {:error, reason} ->
        raise_invalid_image!(image, reason)
    end
  end

  # Mirrors the EXACT source-resolution logic in
  # lib/rendro/asset_registry.ex:38-42, wrapped so a bad path (File.read!/1
  # raising) is folded into the same instructive ArgumentError as malformed
  # bytes -- a bad path is just as much a caller data error.
  defp resolve_image_bytes({:binary, bytes}) when is_binary(bytes), do: {:ok, bytes}

  defp resolve_image_bytes({:path, path}) when is_binary(path) do
    {:ok, File.read!(path)}
  rescue
    e -> {:error, e}
  end

  defp resolve_image_bytes(other), do: {:error, {:invalid_source, other}}

  defp raise_invalid_image!(image, reason) do
    raise ArgumentError, """
    Rendro.Recipes.Ticket.document/2 — invalid data.code.image.

    What:  data.code.image could not be read or parsed as a supported image.
    Where: Rendro.Recipes.Ticket.validate_data!/1
    Why:   Source: #{inspect(image)}. Reason: #{inspect(reason)}.
    Next:  Provide a valid PNG or JPEG as {:path, path} or {:binary, bytes}, or omit :image.
    """
  end
end
