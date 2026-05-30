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
    defaults = [name: :invoice]
    Rendro.page_template(Keyword.merge(defaults, opts))
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

  defp footer_section(_data, _opts) do
    Rendro.section(
      name: :invoice_footer,
      region: :footer,
      content: [
        Rendro.block(Rendro.text("Thank you for your business!", size: 10))
      ]
    )
  end
end
