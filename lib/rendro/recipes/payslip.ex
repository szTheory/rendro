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
  @default_header_h 64
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

    defaults = [
      name: :payslip,
      width: g.pw,
      height: g.ph,
      margin_top: g.mt,
      margin_right: g.mr,
      margin_bottom: g.mb,
      margin_left: g.ml,
      regions: [
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
  `data` (D-15/D-13 errors-as-product) before building the template.
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
