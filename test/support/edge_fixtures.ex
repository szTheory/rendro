defmodule Rendro.Test.EdgeFixtures do
  @moduledoc false
  #
  # Single fixture-construction module for the family × stress-dimension edge
  # matrix (117-04 goldens), the EDGE-02 error matrix (117-05), and the curated
  # raster set (117-06). Pure test-support composition of already-shipped `lib/`
  # recipes and public primitives — ZERO `lib/` edits.
  #
  # Shape mirrors `test/support/pdfium_cli.ex`: `@moduledoc false`, pure
  # `@spec`-annotated functions, no GenServer/Agent/state.
  #
  # `build/2` returns the recipe-shaped `data` map for one {family, dimension}
  # `:applies` cell; it raises `ArgumentError` (loudly, never silently) for any
  # pair that is not a recognized `:applies` cell in
  # `test/rendro/edge_matrix_test.exs`'s `@matrix`. `opts/2` returns the
  # `document/2` opts for a pair. `document/2` is the single entry point every
  # Wave-2 test file calls.

  # ---------------------------------------------------------------------------
  # recipe_module/1 — family atom -> Rendro.Recipes.* module
  # ---------------------------------------------------------------------------

  @spec recipe_module(atom()) :: module()
  def recipe_module(:invoice), do: Rendro.Recipes.Invoice
  def recipe_module(:statement), do: Rendro.Recipes.Statement
  def recipe_module(:receipt), do: Rendro.Recipes.Receipt
  def recipe_module(:certificate), do: Rendro.Recipes.Certificate
  def recipe_module(:payslip), do: Rendro.Recipes.Payslip
  def recipe_module(:ticket), do: Rendro.Recipes.Ticket

  # ---------------------------------------------------------------------------
  # document/2 — the single Wave-2 entry point
  # ---------------------------------------------------------------------------

  @spec document(atom(), atom()) :: Rendro.Document.t()
  # Receipt's page_template/1 forwards recipe-level opts (`:formatters`) straight
  # into struct!(PageTemplate, ...) via Keyword.merge (unlike Invoice/Statement,
  # which Keyword.take only the template keys) — so passing a :formatters opt to
  # Receipt.document/2 raises KeyError before any section is built. Thread the
  # override through sections/2 only (where the body formatter is actually
  # consumed) via escape-hatch composition, giving page_template/1 no opts. This
  # keeps the currency_format cell a valid rendering fixture with zero lib/ edits.
  def document(:receipt, :currency_format) do
    data = build(:receipt, :currency_format)
    sec_opts = opts(:receipt, :currency_format)
    compose(Rendro.Recipes.Receipt.page_template(), Rendro.Recipes.Receipt.sections(data, sec_opts))
  end

  def document(family, dimension) do
    recipe_module(family).document(build(family, dimension), opts(family, dimension))
  end

  # Assembles a document from an unmodified template plus a list of sections
  # (escape-hatch composition, mirroring each recipe's own moduledoc example).
  defp compose(template, sections) do
    Rendro.Document.new()
    |> Rendro.Document.add_template(template)
    |> Rendro.Document.set_template(template.name)
    |> then(fn d -> Enum.reduce(sections, d, &Rendro.Document.add_section(&2, &1)) end)
  end

  # ---------------------------------------------------------------------------
  # Per-family minimal happy-path base data (exact required-key shapes,
  # verified against each recipe's validate_required_keys!/1).
  # ---------------------------------------------------------------------------

  defp base_data(:invoice) do
    %{id: "INV-1001", date: ~D[2026-01-15], items: [%{name: "Consulting Services", qty: 2, price: 150}]}
  end

  defp base_data(:statement) do
    %{
      period: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
      account: %{name: "Acme Corp"},
      opening_balance: Decimal.new("1000.00"),
      lines: [%{date: ~D[2026-01-05], description: "Invoice #1001", amount: Decimal.new("250.00")}]
    }
  end

  defp base_data(:receipt) do
    %{
      title: "Receipt",
      date: ~D[2026-01-15],
      customer: %{name: "Jane Doe"},
      lines: [%{description: "Widget", amount: Decimal.new("10.00")}]
    }
  end

  defp base_data(:certificate) do
    %{title: "Certificate of Completion", recipient: "Jane Smith", date: ~D[2026-01-15]}
  end

  defp base_data(:payslip) do
    %{
      employer: %{name: "Acme Corp"},
      employee: %{name: "Jordan Rivera"},
      period: %{from: ~D[2026-01-01], to: ~D[2026-01-31]},
      pay_date: ~D[2026-02-01],
      earnings: [%{description: "Base Salary", amount: Decimal.new("4000.00"), ytd: Decimal.new("4000.00")}],
      deductions: [%{description: "Federal Income Tax", amount: Decimal.new("450.00"), ytd: Decimal.new("450.00")}],
      net_pay: Decimal.new("3550.00")
    }
  end

  defp base_data(:ticket) do
    %{
      issuer: %{name: "Aurora Live"},
      title: "Concert Pass",
      placement: [%{label: "Seat", value: "24"}],
      code: %{reference: "AB123456"}
    }
  end

  # ---------------------------------------------------------------------------
  # build/2 — recipe-shaped data for one {family, dimension} :applies cell.
  # ---------------------------------------------------------------------------

  @spec build(atom(), atom()) :: map()

  # --- :missing_optional_fields (all 6 families) — base data is already minimal
  def build(family, :missing_optional_fields)
      when family in [:invoice, :statement, :receipt, :certificate, :payslip, :ticket] do
    base_data(family)
  end

  # --- :text_wrap (all 6 families) — extreme text in a free-text field
  def build(:invoice, :text_wrap) do
    %{base_data(:invoice) | items: [%{name: long_text(220), qty: 2, price: 150}]}
  end

  def build(:statement, :text_wrap) do
    base = base_data(:statement)
    [line] = base.lines
    %{base | lines: [%{line | description: long_text(220)}]}
  end

  def build(:receipt, :text_wrap) do
    base = base_data(:receipt)
    [line] = base.lines
    %{base | lines: [%{line | description: long_text(220)}]}
  end

  def build(:certificate, :text_wrap) do
    # Certificate's :body region is vertically tight (title/recipient/date/seal
    # consume most of the single landscape page); a wrapping body of ~120 bytes
    # fills multiple lines yet fits — 160+ overflows (verified via live probe).
    Map.put(base_data(:certificate), :body, long_text(120))
  end

  def build(:payslip, :text_wrap) do
    base = base_data(:payslip)
    [earn] = base.earnings
    payslip_with([%{earn | description: long_text(220)}], base.deductions)
  end

  def build(:ticket, :text_wrap) do
    # Ticket's :terms region is a fixed fine-print box: a wrapping ~120-byte
    # string fills multiple lines yet fits (160+ overflows, verified via live
    # probe) — well under validate_optional_text!'s 600-byte hard cap.
    Map.put(base_data(:ticket), :terms, long_text(120))
  end

  # --- :line_items_zero / :line_items_one / :line_items_few (invoice/statement/receipt/payslip)
  def build(:invoice, dim) when dim in [:line_items_zero, :line_items_one, :line_items_few] do
    %{base_data(:invoice) | items: Enum.map(1..line_count(dim)//1, &invoice_item/1)}
  end

  def build(:statement, dim) when dim in [:line_items_zero, :line_items_one, :line_items_few] do
    %{base_data(:statement) | lines: Enum.map(1..line_count(dim)//1, &statement_line/1)}
  end

  def build(:receipt, dim) when dim in [:line_items_zero, :line_items_one, :line_items_few] do
    %{base_data(:receipt) | lines: Enum.map(1..line_count(dim)//1, &receipt_line/1)}
  end

  def build(:payslip, dim) when dim in [:line_items_zero, :line_items_one, :line_items_few] do
    # :earnings must stay non-empty (validate_lines!(earnings, require_non_empty: true));
    # vary :deductions (empty allowed) and re-derive :net_pay.
    base = base_data(:payslip)
    payslip_with(base.earnings, Enum.map(1..line_count(dim)//1, &deduction_line/1))
  end

  # --- :money_zero / :money_large / :money_cents_rounding
  def build(:invoice, :money_zero) do
    # :totals is an optional key absent from base_data — add it with Map.put
    # (map-update `|` syntax requires the key to already exist).
    base_data(:invoice)
    |> Map.put(:items, [%{name: "Consulting Services", qty: 1, price: 0}])
    |> Map.put(:totals, %{subtotal: Decimal.new("0.00"), total: Decimal.new("0.00")})
  end

  def build(:invoice, :money_large) do
    base_data(:invoice)
    |> Map.put(:items, [%{name: "Consulting Services", qty: 1, price: 1_250_000}])
    |> Map.put(:totals, %{subtotal: Decimal.new("1250000.00"), total: Decimal.new("1250000.00")})
  end

  def build(:invoice, :money_cents_rounding) do
    base_data(:invoice)
    |> Map.put(:items, [%{name: "Consulting Services", qty: 1, price: 300}])
    |> Map.put(:totals, %{
      subtotal: Decimal.new("300.00"),
      tax: Decimal.new("19.995"),
      total: Decimal.new("319.995")
    })
  end

  def build(:statement, :money_zero), do: statement_amount("0.00")
  def build(:statement, :money_large), do: statement_amount("1250000.00")
  def build(:statement, :money_cents_rounding), do: statement_amount("19.995")

  def build(:statement, :money_negative_parens) do
    base = base_data(:statement)
    [line] = base.lines
    %{base | lines: [%{line | amount: Decimal.new("-200.00"), description: "Refund"}]}
  end

  def build(:receipt, :money_zero), do: receipt_amount("0.00")
  def build(:receipt, :money_large), do: receipt_amount("1250000.00")
  def build(:receipt, :money_cents_rounding), do: receipt_amount("19.995")

  def build(:payslip, :money_zero), do: payslip_deduction_amount("0.00")
  def build(:payslip, :money_cents_rounding), do: payslip_deduction_amount("19.995")

  def build(:payslip, :money_large) do
    # Vary an :earnings amount (deductions stay at the base 450), re-derive net.
    payslip_with(
      [%{description: "Base Salary", amount: Decimal.new("1250000.00"), ytd: Decimal.new("1250000.00")}],
      base_data(:payslip).deductions
    )
  end

  # --- :qty_zero (invoice only — only family with a :qty concept)
  def build(:invoice, :qty_zero) do
    %{base_data(:invoice) | items: [%{name: "Free Sample", qty: 0, price: 25}]}
  end

  # --- :currency_format (invoice/statement/receipt/payslip) — variation is in opts/2
  def build(:invoice, :currency_format) do
    # Per INV-02 the legacy :price never routes through Format.money, so a :totals
    # block must be present for the :formatters override to have any visible effect.
    base_data(:invoice)
    |> Map.put(:items, [%{name: "Consulting Services", qty: 2, price: 150}])
    |> Map.put(:totals, %{subtotal: Decimal.new("300.00"), total: Decimal.new("300.00")})
  end

  def build(family, :currency_format) when family in [:statement, :receipt, :payslip] do
    base_data(family)
  end

  # --- :tax_label (payslip only — deduction :description is caller DATA)
  def build(:payslip, :tax_label) do
    base = base_data(:payslip)
    # The 450 deduction still reconciles against the 4000/3550 base.
    payslip_with(
      base.earnings,
      [%{description: "PAYE Income Tax", amount: Decimal.new("450.00"), ytd: Decimal.new("450.00")}]
    )
  end

  # --- catch-all: any unrecognized {family, dimension} pair is a genuine N/A
  # cell (or a document-level-only concern like :odd_even_running_content) —
  # raise loudly, never return a nonsense map.
  def build(family, dimension) do
    raise ArgumentError, """
    Rendro.Test.EdgeFixtures.build/2 — unrecognized {family, dimension} pair.

    What:  {#{inspect(family)}, #{inspect(dimension)}} is not a recognized :applies
           data cell that build/2 knows how to construct.
    Where: Rendro.Test.EdgeFixtures.build/2
    Why:   Either this pair is a genuine N/A cell, or it is a document-level-only
           dimension (e.g. :odd_even_running_content) that document/2 composes
           without calling build/2.
    Next:  Consult @matrix in test/rendro/edge_matrix_test.exs — the single source
           of truth for which {family, dimension} cells are :applies.
    """
  end

  # ---------------------------------------------------------------------------
  # opts/2 — document/2 opts for a {family, dimension} pair; [] when none apply.
  # ---------------------------------------------------------------------------

  @spec opts(atom(), atom()) :: keyword()
  def opts(family, :currency_format) when family in [:invoice, :statement, :receipt, :payslip] do
    # GBP override, reusing Rendro.Format.money/1's grouping/rounding — never
    # reimplement either. Uses an ASCII "GBP " prefix rather than the "£" sign
    # because the engine's built-in font metrics table is ASCII-only; a "£"
    # (U+00A3) raises {:unsupported_glyph, "£"} at measure (no lib/ font change
    # is in scope for this test-only phase). The override still proves the
    # caller-supplied :formatters[:amount] function replaces the default USD "$".
    [formatters: [amount: fn d -> "GBP " <> String.trim_leading(Rendro.Format.money(d), "$") end]]
  end

  def opts(_family, _dimension), do: []

  # ---------------------------------------------------------------------------
  # Private construction helpers
  # ---------------------------------------------------------------------------

  # A deterministic long string of exactly `n` bytes (ASCII words).
  defp long_text(n) do
    "Lorem ipsum dolor sit amet consectetur adipiscing elit "
    |> String.duplicate(div(n, 55) + 1)
    |> binary_part(0, n)
  end

  defp line_count(:line_items_zero), do: 0
  defp line_count(:line_items_one), do: 1
  defp line_count(:line_items_few), do: 3

  defp invoice_item(i), do: %{name: "Line item #{i}", qty: 1, price: 100}
  defp statement_line(i), do: %{date: ~D[2026-01-05], description: "Line item #{i}", amount: Decimal.new("100.00")}
  defp receipt_line(i), do: %{description: "Line item #{i}", amount: Decimal.new("100.00")}

  defp deduction_line(i),
    do: %{description: "Deduction #{i}", amount: Decimal.new("10.00"), ytd: Decimal.new("10.00")}

  defp statement_amount(str) do
    base = base_data(:statement)
    [line] = base.lines
    %{base | lines: [%{line | amount: Decimal.new(str)}]}
  end

  defp receipt_amount(str) do
    base = base_data(:receipt)
    [line] = base.lines
    %{base | lines: [%{line | amount: Decimal.new(str)}]}
  end

  defp payslip_deduction_amount(str) do
    base = base_data(:payslip)
    payslip_with(
      base.earnings,
      [%{description: "Federal Income Tax", amount: Decimal.new(str), ytd: Decimal.new(str)}]
    )
  end

  # Builds a payslip data map from earnings/deductions lists, always deriving
  # :net_pay as the exact Decimal.sub/2 of gross minus total deductions so
  # Payslip's validate_reconciliation!/1 never raises.
  defp payslip_with(earnings, deductions) do
    gross = sum_amounts(earnings)
    ded = sum_amounts(deductions)
    net = Decimal.sub(gross, ded)
    %{base_data(:payslip) | earnings: earnings, deductions: deductions, net_pay: net}
  end

  defp sum_amounts(lines) do
    Enum.reduce(lines, Decimal.new(0), fn %{amount: amount}, acc -> Decimal.add(acc, amount) end)
  end
end
