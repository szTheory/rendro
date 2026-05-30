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

  @doc """
  Returns a `%Rendro.PageTemplate{}` with four named regions:
  `:logo`, `:header`, `:body`, and `:footer`.
  """
  @spec page_template(keyword()) :: Rendro.PageTemplate.t()
  def page_template(opts \\ []) do
    defaults = [
      name: :branded_invoice,
      regions: [
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
    ]

    Rendro.page_template(Keyword.merge(defaults, opts))
  end

  @doc """
  Returns a list of `%Rendro.Section{}` structs mapping branded invoice content
  to the `:logo`, `:header`, `:body`, and `:footer` regions.
  """
  @spec sections(map(), keyword()) :: [Rendro.Section.t()]
  def sections(data, opts \\ []) do
    validate_data!(data)

    [
      logo_section(data, opts),
      header_section(data, opts),
      body_section(data, opts),
      footer_section(data, opts)
    ]
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

  defp header_section(%{brand: %{font_name: font_name}, id: id, date: date}, _opts) do
    # Industry-standard invoice typography: brand is the heading, invoice id
    # is subordinate metadata. Stacking brand/id/date as three independent
    # blocks lets each size to its natural text width — `Rendro.Pipeline.Paginate`
    # fit-validates each block against the `:header` region (371.28pt) so any
    # future regression (longer id, new locale label) surfaces as a typed
    # `:content_overflow` error rather than a silent grapheme split.
    Rendro.section(
      name: :branded_invoice_header,
      region: :header,
      content: [
        Rendro.block(Rendro.text("Rendro, Inc.", font: font_name, size: 18)),
        Rendro.block(Rendro.text("Invoice ##{id}", font: font_name, size: 12)),
        Rendro.block(Rendro.text("Date: #{date}", size: 10))
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

  defp footer_section(_data, _opts) do
    Rendro.section(
      name: :branded_invoice_footer,
      region: :footer,
      content: [
        Rendro.block(Rendro.text("Thank you for your business!", size: 10))
      ]
    )
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
