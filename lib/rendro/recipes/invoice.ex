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

  defp header_section(%{id: id, date: date} = _data, _opts) do
    Rendro.section(
      name: :invoice_header,
      region: :header,
      content: [
        Rendro.block(Rendro.text("INVOICE ##{id}", size: 18)),
        Rendro.block(Rendro.text("Date: #{date}", size: 10))
      ]
    )
  end

  defp body_section(%{items: items} = _data, _opts) do
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
      name: :invoice_body,
      region: :body,
      content: [Rendro.block(table)]
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
end
