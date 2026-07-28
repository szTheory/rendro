defmodule Rendro.Recipes.BrandedInvoice do
  @moduledoc """
  Branded canonical invoice recipe using the Tiered Composition pattern.

  Branding inputs are supplied through `data.brand`:

      data = %{
        id: "INV-001",
        date: ~D[2026-01-15],
        items: [],
        brand: %{font_name: :brand_heading, logo_name: :company_logo}
      }

  `font_name` and `logo_name` must be atoms. Missing or invalid branding data
  raises `ArgumentError` instead of silently falling back to the unbranded
  recipe.

  ## Examples

      iex> template = Rendro.Recipes.BrandedInvoice.page_template()
      iex> template.name
      :branded_invoice
      iex> Enum.map(template.regions, & &1.name) |> Enum.sort()
      [:body, :footer, :header, :logo]

      iex> data = %{id: "INV-001", date: ~D[2026-01-15], items: [], brand: %{font_name: :brand_heading, logo_name: :company_logo}}
      iex> sections = Rendro.Recipes.BrandedInvoice.sections(data)
      iex> length(sections)
      4
      iex> Enum.map(sections, & &1.region) |> Enum.sort()
      [:body, :footer, :header, :logo]

      iex> data = %{id: "INV-001", date: ~D[2026-01-15], items: [], brand: %{font_name: :brand_heading, logo_name: :company_logo}}
      iex> doc = Rendro.Recipes.BrandedInvoice.document(data)
      iex> doc.page_template
      :branded_invoice
      iex> Map.has_key?(doc.font_registry.fonts, :brand_heading)
      true
      iex> Map.has_key?(doc.asset_registry.assets, :company_logo)
      true
  """
  @moduledoc tags: [:adapter]

  # BrandedInvoice never overrides %Rendro.PageTemplate{}'s :width/:height --
  # it renders at the struct's own A4 default (lib/rendro/page_template.ex:
  # @default_width 595.28, @default_height 841.89). These mirror that default
  # verbatim (never invented content-box numbers) so the shared :background
  # region/section below always cover the FULL rendered page, not the
  # 451.28pt content column the :body region happens to use.
  @page_width 595.28
  @page_height 841.89

  @doc """
  Returns a `%Rendro.PageTemplate{}` with four named regions:
  `:logo`, `:header`, `:body`, and `:footer`.
  """
  @spec page_template(keyword()) :: Rendro.PageTemplate.t()
  def page_template(opts \\ []) do
    colors = palette(opts)

    base_regions = [
      Rendro.region(
        name: :logo,
        role: :custom,
        anchor: :fixed,
        x: 72,
        y: 72,
        width: 64,
        height: 64
      ),
      Rendro.region(
        name: :header,
        role: :header,
        anchor: :top,
        x: 152,
        y: 72,
        width: 371.28,
        height: 112
      ),
      Rendro.region(
        name: :body,
        role: :body,
        anchor: :flow,
        x: 72,
        y: 200,
        width: 451.28,
        height: 569.89
      ),
      Rendro.region(
        name: :footer,
        role: :footer,
        anchor: :bottom,
        x: 72,
        y: 769.89,
        width: 451.28,
        height: 0
      )
    ]

    # 121-03: prepend the shared :background region FIRST iff the resolved
    # palette differs from paper-white — gated on the SAME palette(opts)
    # sections/2 uses below (Pitfall 3). Uses the recipe's own full A4 page
    # dims (@page_width/@page_height), NOT the 451.28pt content-box width.
    regions =
      if Rendro.Recipes.Background.emit?(colors) do
        [Rendro.Recipes.Background.region(@page_width, @page_height) | base_regions]
      else
        base_regions
      end

    defaults = [
      name: :branded_invoice,
      regions: regions
    ]

    # page_template/1 only understands PageTemplate struct keys. Recipe-level
    # opts (:palette, :theme, ...) must be dropped here with a struct-key
    # whitelist so they thread through to sections/2 / palette/1 instead of
    # reaching struct!/2 and raising KeyError. Do NOT add :palette/:theme to
    # this list — dropping them is what lets palette/1 read them.
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
  Returns a list of `%Rendro.Section{}` structs mapping branded invoice content
  to the `:logo`, `:header`, `:body`, and `:footer` regions.
  """
  @spec sections(map(), keyword()) :: [Rendro.Section.t()]
  def sections(data, opts \\ []) do
    validate_data!(data)

    colors = palette(opts)

    base_sections = [
      logo_section(data, opts),
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
  Assembles and returns a fully composed branded `%Rendro.Document{}`.
  """
  @spec document(map(), keyword()) :: Rendro.Document.t()
  def document(data, opts \\ []) do
    validate_data!(data)
    template = page_template(opts)
    secs = sections(data, opts)
    brand = Map.fetch!(data, :brand)

    base_doc =
      Rendro.Document.new()
      |> Rendro.Document.register_embedded_font(
        brand.font_name,
        {:path, Rendro.Branded.font_path()}
      )
      |> Rendro.Document.register_image(
        brand.logo_name,
        {:path, Rendro.Branded.logo_path()}
      )
      |> Rendro.Document.add_template(template)
      |> Rendro.Document.set_template(template.name)

    Enum.reduce(secs, base_doc, fn section, doc ->
      Rendro.Document.add_section(doc, section)
    end)
  end

  defp logo_section(%{brand: %{logo_name: logo_name}}, _opts) do
    Rendro.section(
      name: :branded_invoice_logo,
      region: :logo,
      content: [
        Rendro.Component.image(logo_name, fit: {64, 64})
      ]
    )
  end

  defp header_section(%{brand: %{font_name: font_name}, id: id, date: date}, opts) do
    colors = palette(opts)
    type = typography(opts)

    # Industry-standard invoice typography: brand is the heading, invoice id
    # is subordinate metadata. Stacking brand/id/date as three independent
    # blocks lets each size to its natural text width — `Rendro.Pipeline.Paginate`
    # fit-validates each block against the `:header` region (371.28pt) so any
    # future regression (longer id, new locale label) surfaces as a typed
    # `:content_overflow` error rather than a silent grapheme split.
    #
    # 122-03 typography seam (Q1 + Q2): the brand name is BrandedInvoice's SOLE
    # `display` anchor (Q1) — a branded invoice leads with the brand, and there
    # is no Total-Due `%Text{}` run to anchor (its totals live inside the body
    # `Rendro.table/2`, never promoted to a text run — byte-risk). The two brand
    # runs (name + id) KEEP `font: font_name` on BOTH the no-theme AND themed
    # paths (Q2, brand ⊥ theme) — the data-driven embedded brand font is the
    # SOLE non-`:default` literal-default in this milestone. Only Date (and the
    # footer thank-you) are seamed to a theme font role. No-theme literal
    # defaults are exactly this recipe's prior sizes (18/12/10) so the
    # branded-invoice byte-identity golden stays byte-identical (zero re-bless).
    Rendro.section(
      name: :branded_invoice_header,
      region: :header,
      content: [
        Rendro.block(
          Rendro.text("Rendro, Inc.",
            font: font_name,
            size: type.scale.display,
            color: colors.ink,
            line_height: type.leading,
            widows: type.widows,
            orphans: type.orphans
          )
        ),
        Rendro.block(
          Rendro.text("Invoice ##{id}",
            font: font_name,
            size: type.scale.title,
            color: colors.ink,
            line_height: type.leading,
            widows: type.widows,
            orphans: type.orphans
          )
        ),
        Rendro.block(
          Rendro.text("Date: #{date}",
            size: type.scale.body,
            font: type.fonts.body,
            color: colors.ink,
            line_height: type.leading,
            widows: type.widows,
            orphans: type.orphans
          )
        )
      ]
    )
  end

  defp body_section(%{items: items}, _opts) do
    table_rows =
      Enum.map(items, fn item ->
        [item.name, Integer.to_string(item.qty), "$#{item.price}"]
      end)

    table =
      Rendro.table(table_rows,
        header: ["Item", "Qty", "Price"],
        columns: [{:share, 1}, {:fixed, 50}, {:fixed, 80}]
      )

    Rendro.section(
      name: :branded_invoice_body,
      region: :body,
      content: [Rendro.block(table)]
    )
  end

  defp footer_section(_data, opts) do
    colors = palette(opts)
    type = typography(opts)

    Rendro.section(
      name: :branded_invoice_footer,
      region: :footer,
      content: [
        Rendro.block(
          Rendro.text("Thank you for your business!",
            size: type.scale.body,
            font: type.fonts.body,
            color: colors.ink,
            line_height: type.leading,
            widows: type.widows,
            orphans: type.orphans
          )
        )
      ]
    )
  end

  # ---------------------------------------------------------------------------
  # Color seam (S1 / PLUMB-01)
  # ---------------------------------------------------------------------------

  # Returns the role → RGB map for this render. When no `:theme` is supplied the
  # `nil` branch reproduces today's implicit black ink / white surfaces
  # (`ink {0, 0, 0}`, which renders identically to no color arg) so every text
  # run stays byte-identical (PLUMB-03). When a `:theme` is supplied the base
  # becomes `Rendro.Theme.resolve(theme).colors` (9 integer-{r,g,b} roles,
  # colors ONLY — no type-scale read) and a themed `ink` recolors the header /
  # footer text. The final `Map.merge(base, :palette-override)` keeps an
  # explicit `:palette` as the winning layer (D-01).
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
  # Typography seam (TYPE-01 / TYPE-02 / TYPE-03) — structural twin of palette/1.
  # ---------------------------------------------------------------------------

  # Returns the resolved typography for this render: a named type scale, three
  # font roles, and leading/widows/orphans. When no `:theme` is supplied the
  # `nil` branch reproduces BrandedInvoice's exact CURRENT size literals
  # (display 18 = brand name, title 12 = invoice id, body 10 = date/thank-you)
  # — NEVER `Rendro.Theme.default().typography` (that would apply the frozen
  # 21/16.5/... scale and break byte-identity, RESEARCH Pitfall 1). The three
  # font roles default to `:default` (the always-registered Helvetica-compatible
  # built-in, which normalizes identically to today's implicit `"Helvetica"`),
  # but note the two BRAND runs bypass this map entirely and keep `font_name`
  # on both paths (Q2, brand ⊥ theme). When a `:theme` is supplied the base
  # becomes `Rendro.Theme.resolve(theme).typography`. The final `Map.merge`
  # keeps an explicit `:typography` opt as the winning override layer (mirrors
  # :palette). `subtitle`/`small`/`caption` are unused by this recipe.
  defp typography(opts) do
    base =
      case opts[:theme] do
        nil ->
          %{
            scale: %{display: 18, title: 12, subtitle: 11, body: 10, small: 9, caption: 8},
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

  defp validate_data!(%{brand: %{font_name: font_name, logo_name: logo_name}})
       when is_atom(font_name) and is_atom(logo_name),
       do: :ok

  defp validate_data!(%{brand: %{font_name: font_name}}) when not is_atom(font_name) do
    raise ArgumentError, "data.brand.font_name must be an atom"
  end

  defp validate_data!(%{brand: %{logo_name: logo_name}}) when not is_atom(logo_name) do
    raise ArgumentError, "data.brand.logo_name must be an atom"
  end

  defp validate_data!(%{brand: _brand}) do
    raise ArgumentError, "data.brand must include atom :font_name and :logo_name keys"
  end

  defp validate_data!(_data) do
    raise ArgumentError,
          "data.brand is required and must include atom :font_name and :logo_name keys"
  end
end
