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
                          (A4 default, portrait) — zero hardcoded numerics
                          (D-03), so both A4 and US Letter render correctly.
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

  @default_page_size :a4
  @default_margin 72

  # D-03: band height is a dimensionless RATIO of content width (~2.4:1),
  # never a fixed-point constant, so A4/US Letter geometry falls out
  # identically. The stub split is likewise a ratio of the band's own width.
  @band_ratio 2.4
  @stub_ratio 0.68
  @gap 16

  # D-05: interior padding subtracted from the smaller of (stub width, band
  # height) to compute the code box side length -- see stub_section/2.
  @box_pad 12.0

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
  option. Default is A4 portrait. Three named regions: `:main` (the D-02
  placement-grid anchor), `:stub` (the D-05/D-06/D-07/D-08/D-09 code area),
  and `:terms` (optional fine print).

  ## Options

    - `:page_size` — `:a4` (default), `:us_letter`, or `{width, height}` tuple
    - `:margin_top` / `:margin_right` / `:margin_bottom` / `:margin_left` — margin in pt (default 72)
    - `:name` — template name atom (default `:ticket`)

  ## Examples

      iex> template = Rendro.Recipes.Ticket.page_template()
      iex> Enum.map(template.regions, & &1.name)
      [:main, :stub, :terms]

  """
  @spec page_template(keyword()) :: Rendro.PageTemplate.t()
  def page_template(opts \\ []) do
    g = geometry(opts)

    defaults = [
      name: :ticket,
      width: g.pw,
      height: g.ph,
      margin_top: g.mt,
      margin_right: g.mr,
      margin_bottom: g.mb,
      margin_left: g.ml,
      regions: [
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

    [main_section(data, opts), stub_section(data, opts), terms_section(data, opts)]
  end

  # ---------------------------------------------------------------------------
  # Private section builders
  # ---------------------------------------------------------------------------

  # D-02: the placement-grid anchor, via Rendro.table/2 (NOT manual block
  # stacking -- a hand-stacked multi-column layout would require fragile
  # height-zeroing tricks against paginate.ex's single shared per-region Y
  # cursor; a table's own column-layout logic already handles this
  # correctly). One data row of large (22pt) values under a header row of
  # small caps (8pt) labels -- the values are the single largest text
  # anywhere on the page, matching D-02's dominant-anchor requirement. The
  # SAME code renders any 1-4 cell :placement shape (event or boarding-pass)
  # purely via data -- zero archetype branching (D-01).
  defp main_section(data, opts) do
    colors = palette(opts)

    header_cells =
      Enum.map(data.placement, fn %{label: l} ->
        Rendro.block(Rendro.text(String.upcase(l), size: 8, color: colors.muted))
      end)

    value_cells =
      Enum.map(data.placement, fn %{value: v} ->
        Rendro.block(Rendro.text(v, size: 22, color: colors.ink))
      end)

    grid =
      Rendro.table([value_cells],
        header: header_cells,
        columns: List.duplicate({:share, 1}, length(data.placement)),
        borders: :none
      )

    subtitle_blocks =
      case Map.get(data, :subtitle) do
        blank when blank in [nil, ""] -> []
        subtitle -> [Rendro.block(Rendro.text(subtitle, size: 10, color: colors.muted))]
      end

    Rendro.section(
      name: :ticket_main,
      region: :main,
      content:
        [
          Rendro.block(Rendro.text(issuer_display(data.issuer), size: 9, color: colors.muted)),
          Rendro.block(Rendro.text(data.title, size: 16, color: colors.ink))
        ] ++
          subtitle_blocks ++
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
  defp stub_section(data, opts) do
    colors = palette(opts)
    lbl = Rendro.Recipes.Pagination.label_resolver(opts, @default_labels)
    g = geometry(opts)

    box_size = min(g.stub_width, g.band_h) - 2 * @box_pad
    box_x = (g.stub_width - box_size) / 2

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

    # D-05: the bordered code box backdrop -- always drawn, >= ~100x100pt at
    # A4-default geometry (derived, not hardcoded). height: 0 so the box's
    # own drawn rectangle (real height = box_size, from the :rounded_rect
    # op's own h argument) does not push subsequent content down.
    code_box =
      Rendro.path([{:rounded_rect, box_x, 0, box_size, box_size, 6.0}],
        stroke: %{color: colors.rule, width: 1.0},
        x: 0,
        y: 0,
        width: box_x + box_size,
        height: 0
      )

    image = get_in(data, [:code, :image])

    Rendro.section(
      name: :ticket_stub,
      region: :stub,
      content: [perforation, code_box] ++ code_area_blocks(data, colors, lbl, image, box_x, box_size)
    )
  end

  # D-07: no image -- the box contains ONLY the centered reference (+
  # optional caption), never a faux barcode/QR stripe pattern. Reference
  # block(s) start at the SAME y as the box backdrop (height: 0), so they
  # overlay the box from its top edge.
  defp code_area_blocks(data, colors, lbl, nil, box_x, _box_size) do
    reference_blocks(data, colors, lbl, box_x) ++ [present_code_caption(colors, lbl, box_x)]
  end

  # D-08: image supplied -- fit-contain (aspect-preserving), centered, under
  # the fixed internal logical name :ticket_code, placed IMMEDIATELY after
  # the box backdrop. Its measured height (real, per measure.ex's Image
  # clause) naturally advances the cursor past the box, so the
  # ALWAYS-VISIBLE reference (D-06) renders AFTER it -- below the image,
  # never overlaid on top of it.
  defp code_area_blocks(data, colors, lbl, _image, box_x, box_size) do
    image_block =
      Rendro.Component.image(:ticket_code, fit: {box_size, box_size})
      |> Map.put(:x, box_x)

    [image_block | reference_blocks(data, colors, lbl, box_x)]
  end

  # D-06: the human-readable reference -- REQUIRED, ALWAYS renders, even
  # when a PNG is supplied. Upper-cased, with a small muted caption above.
  defp reference_blocks(data, colors, lbl, box_x) do
    caption_label = Map.get(data.code, :label) || lbl.(:reference)
    reference_text = String.upcase(data.code.reference)

    [
      Rendro.block(Rendro.text(caption_label, size: 8, color: colors.muted))
      |> Map.put(:x, box_x + 8),
      Rendro.block(Rendro.text(reference_text, size: 15, color: colors.ink))
      |> Map.put(:x, box_x + 8)
    ]
  end

  # D-07: optional 1-line caption, no-image path only.
  defp present_code_caption(colors, lbl, box_x) do
    Rendro.block(Rendro.text(lbl.(:present_code), size: 7, color: colors.muted))
    |> Map.put(:x, box_x + 8)
  end

  defp terms_section(data, opts) do
    colors = palette(opts)

    content =
      case Map.get(data, :terms) do
        blank when blank in [nil, ""] -> []
        terms -> [Rendro.block(Rendro.text(terms, size: 8, color: colors.muted))]
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
    band_h = band_w / @band_ratio
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
  # Color seam (S1) — verbatim from invoice.ex:371-386
  # ---------------------------------------------------------------------------

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
