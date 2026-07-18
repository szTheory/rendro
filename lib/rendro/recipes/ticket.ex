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

    Rendro.Document.new()
    |> Rendro.Document.add_template(template)
    |> Rendro.Document.set_template(template.name)
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
