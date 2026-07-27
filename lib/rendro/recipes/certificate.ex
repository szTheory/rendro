defmodule Rendro.Recipes.Certificate do
  @moduledoc """
  Data-driven certificate recipe for completion, compliance, and award certificates.

  All region coordinates are derived from template geometry — zero hardcoded A4
  numerics. The default orientation is landscape (classic diploma/award look).
  Portrait is reachable by passing `orientation: :portrait`.

  Branding is **optional**: an unbranded certificate renders fine with default
  fonts and no logo. When `data.brand` is present, the font and image are
  registered via `Rendro.Document.register_embedded_font/3` and
  `Rendro.Document.register_image/3`, mirroring `BrandedInvoice`.

  ## Required data keys

    - `:title` — certificate title, e.g. `"Certificate of Completion"`
    - `:recipient` — recipient name, e.g. `"Jane Smith"`
    - `:date` — issue date (`Date.t()`)

  ## Optional data keys

    - `:body` — body statement text (default `""`)
    - `:seal_line` — signature / seal line (default `""`)
    - `:brand` — `%{font_name: atom(), logo_name: atom()}` for branded output

  ## Border frame option

  The `border:` option adds a decorative keyline frame to the certificate.
  All frame geometry is derived from page dimensions and margins — zero
  hardcoded numerics.

    - `border: false` (default) — no frame; output is byte-identical to prior output
    - `border: true` — single near-ink keyline (`{34, 34, 34}`), geometry-derived
    - `border: %{...}` — map with any subset of override keys:
        - `:color` — `{r, g, b}` integer tuple (0–255), default `{34, 34, 34}`
        - `:style` — `:single` (default) or `:double`
        - `:inset` — float in pt, default `0.5 * min(margins)`
        - `:weight` — line width in pt, default `max(1.0, short / 400)`
        - `:gap` — gap between rules for `:double` style, default `0`

  ## Examples

      iex> template = Rendro.Recipes.Certificate.page_template()
      iex> template.width > template.height   # landscape default
      true

      iex> data = %{title: "Certificate of Completion", recipient: "Jane Smith", date: ~D[2026-05-29]}
      iex> doc = Rendro.Recipes.Certificate.document(data)
      iex> doc.page_template
      :certificate

  """
  @moduledoc tags: [:adapter]

  # Non-dimensional defaults only — NO geometry constants.
  # All x/y/width/height values are computed at runtime from PageSize.resolve/2.
  @default_page_size :a4
  @default_orientation :landscape
  @default_margin 72

  # Closed allowlist for border map keys (D-21)
  @border_allowed_keys [:style, :color, :inset, :gap, :weight]

  @doc """
  Returns a `%Rendro.PageTemplate{}` with geometry derived from the page size
  and orientation options. Default is A4 landscape.

  ## Options

    - `:page_size` — `:a4` (default) or `:us_letter`, or `{width, height}` tuple
    - `:orientation` — `:landscape` (default) or `:portrait`
    - `:margin_top` / `:margin_right` / `:margin_bottom` / `:margin_left` — margin in pt (default 72)
    - `:name` — template name atom (default `:certificate`)
    - `:border` — `false` (default), `true`, or a border options map

  ## Examples

      iex> t = Rendro.Recipes.Certificate.page_template()
      iex> t.width > t.height
      true

      iex> t = Rendro.Recipes.Certificate.page_template(orientation: :portrait)
      iex> t.height > t.width
      true

  """
  @spec page_template(keyword()) :: Rendro.PageTemplate.t()
  def page_template(opts \\ []) do
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    orientation = Keyword.get(opts, :orientation, @default_orientation)
    {pw, ph} = Rendro.PageSize.resolve(page_size, orientation)

    ml = Keyword.get(opts, :margin_left, @default_margin)
    mr = Keyword.get(opts, :margin_right, @default_margin)
    mt = Keyword.get(opts, :margin_top, @default_margin)
    mb = Keyword.get(opts, :margin_bottom, @default_margin)

    content_w = pw - ml - mr
    content_h = ph - mt - mb

    border = Keyword.get(opts, :border, false)

    body_region =
      Rendro.region(
        name: :body,
        role: :body,
        anchor: :flow,
        x: ml,
        y: mt,
        width: content_w,
        height: content_h
      )

    regions =
      if border do
        frame_opts = resolve_frame_opts(border, pw, ph, ml, mr, mt, mb, palette(opts))
        inset = frame_opts.inset

        frame_region =
          Rendro.region(
            name: :frame,
            role: :custom,
            anchor: :fixed,
            x: inset,
            y: inset,
            width: pw - 2 * inset,
            height: ph - 2 * inset
          )

        [body_region, frame_region]
      else
        [body_region]
      end

    Rendro.page_template(
      name: Keyword.get(opts, :name, :certificate),
      width: pw,
      height: ph,
      margin_top: mt,
      margin_right: mr,
      margin_bottom: mb,
      margin_left: ml,
      regions: regions
    )
  end

  @doc """
  Returns a list of `%Rendro.Section{}` structs for the certificate body.

  ## Examples

      iex> data = %{title: "Certificate of Completion", recipient: "Jane Smith", date: ~D[2026-05-29]}
      iex> sections = Rendro.Recipes.Certificate.sections(data)
      iex> length(sections) > 0
      true

  """
  @spec sections(map(), keyword()) :: [Rendro.Section.t()]
  def sections(data, opts \\ []) do
    template = page_template(opts)
    body = body_section(data, opts, template)

    border = Keyword.get(opts, :border, false)

    if border do
      page_size = Keyword.get(opts, :page_size, @default_page_size)
      orientation = Keyword.get(opts, :orientation, @default_orientation)
      {pw, ph} = Rendro.PageSize.resolve(page_size, orientation)

      ml = Keyword.get(opts, :margin_left, @default_margin)
      mr = Keyword.get(opts, :margin_right, @default_margin)
      mt = Keyword.get(opts, :margin_top, @default_margin)
      mb = Keyword.get(opts, :margin_bottom, @default_margin)

      colors = palette(opts)
      frame_opts = resolve_frame_opts(border, pw, ph, ml, mr, mt, mb, colors)
      inset = frame_opts.inset
      region_w = pw - 2 * inset
      region_h = ph - 2 * inset

      frame_block = %Rendro.Block{
        width: region_w,
        height: region_h,
        x: 0,
        y: 0,
        content: %Rendro.Path{
          ops: [{:rect, 0, 0, region_w, region_h}],
          stroke: %{color: frame_opts.color, width: frame_opts.weight}
        }
      }

      frame_section =
        Rendro.section(
          name: :certificate_frame,
          region: :frame,
          content: [frame_block]
        )

      [body, frame_section]
    else
      [body]
    end
  end

  @doc """
  Assembles and returns a fully composed `%Rendro.Document{}` ready for
  `Rendro.render/2`.

  ## Options

  All options from `page_template/1` are supported. Additionally:

    - `:page_number_opts` — options forwarded to `Rendro.page_number/1` (unused
      for single-page certificates; included for API consistency)
    - `:border` — `false` (default), `true`, or a border options map (see module docs)

  ## Examples

      iex> data = %{title: "Certificate of Completion", recipient: "Jane Smith", date: ~D[2026-05-29]}
      iex> doc = Rendro.Recipes.Certificate.document(data)
      iex> doc.page_template
      :certificate

  """
  @spec document(map(), keyword()) :: Rendro.Document.t()
  def document(data, opts \\ []) do
    validate_data!(data)

    border = Keyword.get(opts, :border, false)

    if border do
      page_size = Keyword.get(opts, :page_size, @default_page_size)
      orientation = Keyword.get(opts, :orientation, @default_orientation)
      {_pw, _ph} = Rendro.PageSize.resolve(page_size, orientation)

      ml = Keyword.get(opts, :margin_left, @default_margin)
      mr = Keyword.get(opts, :margin_right, @default_margin)
      mt = Keyword.get(opts, :margin_top, @default_margin)
      mb = Keyword.get(opts, :margin_bottom, @default_margin)

      min_margin = Enum.min([ml, mr, mt, mb])
      border_map = if is_map(border), do: border, else: %{}
      validate_border!(border_map, min_margin)
    end

    template = page_template(opts)
    secs = sections(data, opts)

    base_doc = Rendro.Document.new()

    base_doc =
      if brand = Map.get(data, :brand) do
        base_doc
        |> Rendro.Document.register_embedded_font(
          brand.font_name,
          {:path, Rendro.Branded.font_path()}
        )
        |> Rendro.Document.register_image(
          brand.logo_name,
          {:path, Rendro.Branded.logo_path()}
        )
      else
        base_doc
      end

    base_doc
    |> Rendro.Document.add_template(template)
    |> Rendro.Document.set_template(template.name)
    |> then(fn d -> Enum.reduce(secs, d, &Rendro.Document.add_section(&2, &1)) end)
  end

  # ---------------------------------------------------------------------------
  # Private section builders
  # ---------------------------------------------------------------------------

  # 118-08 gap-closure (SHOW-01): recipient name must be the dominant
  # element (larger than the title, mirrors Payslip's Net Pay box) — the
  # title now recedes so the recipient reads as the one key fact.
  @title_size 20
  @subtitle_size 12
  @recipient_size 34
  @body_size 11
  @meta_size 10
  @line_height 1.2
  # Body paragraph measure — a fraction of the body region width so the
  # paragraph never runs edge-to-edge (118-06-FINDINGS.md certificate gap).
  @body_measure_fraction 0.68

  defp body_section(data, opts, template) do
    fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)

    body_text = Map.get(data, :body, "")
    seal_text = Map.get(data, :seal_line, "")

    body_region = Enum.find(template.regions, &(&1.role == :body))
    region_w = body_region.width
    region_h = body_region.height

    # Only "Helvetica" is ever used for this recipe's text runs (the
    # optional `brand` font is registered for embedding but never applied to
    # a text block here), so built-in Helvetica metrics are always the
    # correct font to measure against for centering.
    font = Rendro.PDF.Font.helvetica()

    body_measure_w = region_w * @body_measure_fraction

    # 118-08: center content vertically within the border. No generic
    # per-block measurement API is exposed publicly, so the total content
    # height is estimated from known font metrics (line_height * size per
    # line, with the wrapped body paragraph's line count approximated from
    # its measured full-line width against the constrained measure). This is
    # an honest approximation, not exact typesetting — good enough to move
    # the certificate's content out of the cramped top ~20% into a visually
    # balanced middle band.
    body_full_w = Rendro.PDF.Font.text_width(font, body_text, @body_size)
    body_lines = if body_full_w <= 0, do: 1, else: max(1, ceil(body_full_w / body_measure_w))

    content_height_estimate =
      line_h(@title_size) + line_h(@subtitle_size) + line_h(@recipient_size) +
        body_lines * line_h(@body_size) + line_h(@meta_size) + line_h(@meta_size)

    top_spacer_h = max((region_h - content_height_estimate) / 2, 0)

    spacer = Rendro.block(Rendro.text("", size: 1), height: top_spacer_h)

    content = [
      spacer,
      centered_line(font, data.title, @title_size, region_w),
      centered_line(font, "This certifies that", @subtitle_size, region_w),
      centered_line(font, data.recipient, @recipient_size, region_w),
      centered_paragraph(body_text, @body_size, body_measure_w, region_w),
      centered_line(font, fmt_date.(data.date), @meta_size, region_w),
      centered_line(font, seal_text, @meta_size, region_w)
    ]

    Rendro.section(
      name: :certificate_body,
      region: :body,
      content: content
    )
  end

  defp line_h(size), do: size * @line_height

  # Horizontally centers a single line of text within the body region by
  # measuring its exact rendered width against built-in Helvetica metrics.
  defp centered_line(font, text, size, region_w) do
    width = Rendro.PDF.Font.text_width(font, text, size)
    x = max((region_w - width) / 2, 0)
    Rendro.block(Rendro.text(text, size: size), x: x, width: width)
  end

  # Constrains the body paragraph to `measure_w` (never edge-to-edge) and
  # centers the constrained block horizontally within the region.
  defp centered_paragraph(text, size, measure_w, region_w) do
    x = max((region_w - measure_w) / 2, 0)
    Rendro.block(Rendro.text(text, size: size), x: x, width: measure_w)
  end

  # ---------------------------------------------------------------------------
  # Frame geometry helpers
  # ---------------------------------------------------------------------------

  # Returns the role → RGB map for this render. The `rule` default reproduces
  # Certificate's exact current frame literal `{34, 34, 34}` — the NON-BLACK
  # stress case (D-02): it is deliberately NOT `{0, 0, 0}` and NOT the theme's
  # `rule`. The frame color sources from here so Milestone B's design-token
  # layer can slot in later without breaking rework (S1); an explicit
  # `border: %{color: ...}` override still wins over this default.
  defp palette(opts) do
    overrides = Keyword.get(opts, :palette, %{})

    Map.merge(
      %{
        rule: {34, 34, 34}
      },
      overrides
    )
  end

  # Resolves frame opts, computing geometry-derived defaults.
  # Returns a fully resolved map with :style, :color, :inset, :weight, :gap.
  defp resolve_frame_opts(border, pw, ph, ml, mr, mt, mb, colors) do
    border_map = if is_map(border), do: border, else: %{}

    short = min(pw, ph)
    default_inset = 0.5 * Enum.min([ml, mr, mt, mb])
    default_weight = max(1.0, short / 400)

    %{
      style: Map.get(border_map, :style, :single),
      color: Map.get(border_map, :color, colors.rule),
      inset: Map.get(border_map, :inset, default_inset),
      weight: Map.get(border_map, :weight, default_weight),
      gap: Map.get(border_map, :gap, 0)
    }
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  defp validate_border!(border_map, min_margin) do
    # Closed key allowlist check
    unknown_keys = Map.keys(border_map) -- @border_allowed_keys

    unless unknown_keys == [] do
      raise ArgumentError, """
      Rendro.Recipes.Certificate.document/2 — unknown border option key(s).

      What:  The border: map contains unrecognised keys.
      Where: Rendro.Recipes.Certificate.validate_border!/2
      Why:   Unknown key(s): #{inspect(unknown_keys)}.
      Next:  Valid border keys are: #{inspect(@border_allowed_keys)}.
      """
    end

    # :style must be :single or :double
    if style = Map.get(border_map, :style) do
      unless style in [:single, :double] do
        raise ArgumentError, """
        Rendro.Recipes.Certificate.document/2 — invalid :style value.

        What:  :style must be :single or :double.
        Where: Rendro.Recipes.Certificate.validate_border!/2
        Why:   Got #{inspect(style)}.
        Next:  Use border: %{style: :single} or border: %{style: :double}.
        """
      end
    end

    # :color must be a valid {r,g,b} tuple — delegate to Rendro.Color
    if color = Map.get(border_map, :color) do
      case Rendro.Color.validate(color) do
        :ok -> :ok
        {:error, msg} -> raise ArgumentError, msg
      end
    end

    # :inset must be numeric and < min_margin
    if Map.has_key?(border_map, :inset) do
      inset = Map.get(border_map, :inset)

      unless is_number(inset) do
        raise ArgumentError, """
        Rendro.Recipes.Certificate.document/2 — invalid :inset value.

        What:  :inset must be a number.
        Where: Rendro.Recipes.Certificate.validate_border!/2
        Why:   Got #{inspect(inset)}.
        Next:  Provide a numeric value in points, e.g. border: %{inset: 36}.
        """
      end

      if inset >= min_margin do
        raise ArgumentError, """
        Rendro.Recipes.Certificate.document/2 — :inset too large.

        What:  :inset would cross into the content area.
        Where: Rendro.Recipes.Certificate.validate_border!/2
        Why:   inset #{inset} would cross into content area. Safe maximum: less than #{min_margin}.
        Next:  Use an inset value less than #{min_margin} (the smallest page margin).
        """
      end
    end

    # :weight must be numeric
    if Map.has_key?(border_map, :weight) do
      weight = Map.get(border_map, :weight)

      unless is_number(weight) do
        raise ArgumentError, """
        Rendro.Recipes.Certificate.document/2 — invalid :weight value.

        What:  :weight must be a number.
        Where: Rendro.Recipes.Certificate.validate_border!/2
        Why:   Got #{inspect(weight)}.
        Next:  Provide a numeric value in points, e.g. border: %{weight: 1.5}.
        """
      end
    end

    # :gap must be numeric
    if Map.has_key?(border_map, :gap) do
      gap = Map.get(border_map, :gap)

      unless is_number(gap) do
        raise ArgumentError, """
        Rendro.Recipes.Certificate.document/2 — invalid :gap value.

        What:  :gap must be a number.
        Where: Rendro.Recipes.Certificate.validate_border!/2
        Why:   Got #{inspect(gap)}.
        Next:  Provide a numeric value in points, e.g. border: %{gap: 4}.
        """
      end
    end

    :ok
  end

  defp validate_data!(data) do
    required = [:title, :recipient, :date]

    missing =
      Enum.reject(required, fn key ->
        case Map.fetch(data, key) do
          {:ok, val} when not is_nil(val) -> true
          _ -> false
        end
      end)

    unless missing == [] do
      raise ArgumentError, """
      Rendro.Recipes.Certificate.document/2 — missing required key(s) in data.

      What:  Required certificate data keys are missing.
      Where: Rendro.Recipes.Certificate.validate_data!/1
      Why:   Missing key(s): #{inspect(missing)}.
      Next:  Provide all required keys: #{Enum.map_join(required, ", ", &inspect/1)}.
      """
    end

    validate_date!(data.date)
    validate_body!(Map.get(data, :body, ""))
    validate_brand!(Map.get(data, :brand))
  end

  defp validate_date!(%Date{}), do: :ok

  defp validate_date!(value) do
    raise ArgumentError, """
    Rendro.Recipes.Certificate.document/2 — invalid :date type.

    What:  :date must be a %Date{} struct.
    Where: Rendro.Recipes.Certificate.validate_data!/1
    Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
    Next:  Use the ~D[YYYY-MM-DD] sigil or Date.new!/3.
    """
  end

  defp validate_body!(body) when is_binary(body) and byte_size(body) > 2000 do
    raise ArgumentError, """
    Rendro.Recipes.Certificate.document/2 — data.body is too long.

    What:  data.body exceeds the single-page body-length limit.
    Where: Rendro.Recipes.Certificate.validate_data!/1
    Why:   #{byte_size(body)} bytes (limit: 2000). Certificate is a single-page recipe;
           very long body text would overflow the page and split across multiple pages.
    Next:  Shorten data.body to 2000 bytes or fewer.
    """
  end

  defp validate_body!(body) when is_binary(body), do: :ok

  defp validate_body!(value) do
    raise ArgumentError, """
    Rendro.Recipes.Certificate.document/2 — invalid :body type.

    What:  :body must be a string.
    Where: Rendro.Recipes.Certificate.validate_data!/1
    Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
    Next:  Pass a binary string (max 2000 bytes).
    """
  end

  defp validate_brand!(nil), do: :ok

  defp validate_brand!(%{font_name: f, logo_name: l}) when is_atom(f) and is_atom(l), do: :ok

  defp validate_brand!(%{font_name: f}) when not is_atom(f) do
    raise ArgumentError,
          "data.brand.font_name must be an atom — got #{Rendro.Recipes.Pagination.type_name(f)}"
  end

  defp validate_brand!(%{logo_name: l}) when not is_atom(l) do
    raise ArgumentError,
          "data.brand.logo_name must be an atom — got #{Rendro.Recipes.Pagination.type_name(l)}"
  end

  defp validate_brand!(_brand) do
    raise ArgumentError,
          "data.brand must include atom :font_name and :logo_name keys — got unexpected brand shape"
  end
end
