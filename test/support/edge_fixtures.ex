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

  # :odd_even_running_content is not a document/2 opt on any of the six recipes —
  # it is escape-hatch composition using the public Rendro.Section{only_on:}
  # physical-page-parity filter (the v2.7 running-content mechanism). Reuse the
  # 65-row :line_items_60_plus dataset so this SINGLE fixture simultaneously
  # proves pagination + 60+ rows + odd/even parity (D-10a's combined-fixture
  # design). Each recipe's own :footer section is dropped (its region is :footer)
  # so exactly one footer is active per page — the :odd variant on physical odd
  # pages, the :even variant on physical even pages, their content differing by
  # parity.
  #
  # NOTE (deviation, see SUMMARY): the RESEARCH sketch wrapped each footer in a
  # %Rendro.RunningContent{fun: ...} closure. That primitive is a paginate-stage
  # unit-test construct — its lazily-generated inner blocks never pass through
  # the measure stage's font-registration/bounds pass, so a FULL Rendro.render/1
  # of such a document fails post-render validation with :missing_font_reference
  # + :invalid_block_bounds (verified via live probe). The recipes themselves
  # never use RunningContent funs — they emit static token-substituted blocks
  # (Rendro.page_number/1). Static only_on footer blocks are the valid, fully
  # rendering equivalent and still prove parity-differing running content with
  # zero lib/ edits.
  def document(family, :odd_even_running_content)
      when family in [:invoice, :statement, :receipt, :payslip] do
    data = build(family, :line_items_60_plus)
    template = recipe_module(family).page_template()
    all_sections = recipe_module(family).sections(data)
    base_sections = Enum.reject(all_sections, &(&1.region == :footer))

    odd_footer = Rendro.section(region: :footer, only_on: :odd, content: [parity_footer_block(:odd)])
    even_footer = Rendro.section(region: :footer, only_on: :even, content: [parity_footer_block(:even)])

    compose(template, base_sections ++ [odd_footer, even_footer])
  end

  def document(family, dimension) do
    recipe_module(family).document(build(family, dimension), opts(family, dimension))
  end

  # ---------------------------------------------------------------------------
  # EDGE-02 error fixtures (D-05/D-06) — reused by 117-05. Built from public
  # Rendro structs/functions only; each is used solely to prove an error path.
  # ---------------------------------------------------------------------------

  # Generic block-overflow: a single block whose explicit :height far exceeds any
  # page's body capacity, guaranteeing the generic check_overflow!/4 path whose
  # error details carry a :block map.
  @spec overflow_document() :: Rendro.Document.t()
  def overflow_document do
    Rendro.flow([Rendro.block(Rendro.text("overflow probe"), height: 5000)])
  end

  # Table-row overflow: a table with exactly ONE row and ONE narrow {:fixed, N}
  # column whose long cell text wraps to a row taller than body capacity, wrapped
  # as the FIRST and ONLY block (so current_h == 0 at the row-overflow check
  # site). Its error details carry :row_height and NOT :block.
  @spec tall_row_document() :: Rendro.Document.t()
  def tall_row_document do
    table = Rendro.table([[long_text(600)]], columns: [{:fixed, 20}])
    Rendro.flow([Rendro.block(table)])
  end

  # RTL default font: Hebrew "shalom olam" with no custom font/shaper config —
  # glyph resolution fails first → {:unsupported_glyph, char} at :measure.
  @spec rtl_default_font_document() :: Rendro.Document.t()
  def rtl_default_font_document do
    Rendro.flow([Rendro.block(Rendro.text("שלום עולם"))])
  end

  # RTL shaping-required: an Arabic-glyph-capable synthetic font clears glyph
  # resolution, so Shaper.Simple gates :arab → {:shaping_required, :arab, hint}
  # at :measure. Clones the fake-font-registry technique from
  # test/rendro/pipeline/measure_test.exs (no vendored font, no lib/ change).
  @spec rtl_shaping_required_document() :: Rendro.Document.t()
  def rtl_shaping_required_document, do: doc_with_arabic_text()

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

  # --- structural pagination dimensions (invoice/statement/receipt/payslip)
  def build(family, :line_items_page_boundary)
      when family in [:invoice, :statement, :receipt, :payslip] do
    with_big_rows(family, rows_per_page(family) + 1)
  end

  def build(family, :pagination_boundary)
      when family in [:invoice, :statement, :receipt, :payslip] do
    with_big_rows(family, 2 * rows_per_page(family) + 1)
  end

  def build(family, :line_items_60_plus)
      when family in [:invoice, :statement, :receipt, :payslip] do
    with_big_rows(family, 65)
  end

  # --- :page_size_a4_letter (certificate/payslip/ticket) — variation is in opts/2
  def build(family, :page_size_a4_letter)
      when family in [:certificate, :payslip, :ticket] do
    base_data(family)
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

  def opts(family, :page_size_a4_letter) when family in [:certificate, :payslip, :ticket] do
    [page_size: :us_letter]
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

  # --- structural-dimension helpers -----------------------------------------

  # `count` synthetic line-item/earnings entries per family's line shape, each
  # with a distinct sequential description and a modest fixed amount.
  defp big_line_items(:invoice, n), do: Enum.map(1..n//1, &invoice_item/1)
  defp big_line_items(:statement, n), do: Enum.map(1..n//1, &statement_line/1)
  defp big_line_items(:receipt, n), do: Enum.map(1..n//1, &receipt_line/1)

  defp big_line_items(:payslip, n),
    do: Enum.map(1..n//1, fn i -> %{description: "Line item #{i}", amount: Decimal.new("100.00"), ytd: Decimal.new("100.00")} end)

  defp with_big_rows(:invoice, n), do: %{base_data(:invoice) | items: big_line_items(:invoice, n)}
  defp with_big_rows(:statement, n), do: %{base_data(:statement) | lines: big_line_items(:statement, n)}
  defp with_big_rows(:receipt, n), do: %{base_data(:receipt) | lines: big_line_items(:receipt, n)}
  # Grow the paginating :earnings ledger (max(len(earnings), len(deductions))
  # rows drive Payslip pagination), keeping the base single deduction and
  # re-deriving :net_pay.
  defp with_big_rows(:payslip, n),
    do: payslip_with(big_line_items(:payslip, n), base_data(:payslip).deductions)

  # Exact per-page row capacity, computed via Rendro.measure_rows/4, mirroring
  # each recipe's own rows_per_page/0 test helper verbatim (their formulas
  # differ). Payslip has no published rows_per_page/0 analog, so its capacity is
  # derived from the recipe's own geometry attributes as a close approximation
  # (no test in this plan asserts payslip's exact page boundary; the fixtures
  # only need to render and, for :line_items_60_plus, span multiple pages).
  @content_width 595.28 - 2 * 72

  defp rows_per_page(:statement) do
    table_opts = [
      header: ["Date", "Description", "Amount", "Balance"],
      columns: [{:fixed, 72}, {:share, 1}, {:fixed, 72}, {:fixed, 72}]
    ]

    row = ["2026-05-01", "Transaction 1", "$100.00", "$1,100.00"]
    {header_h, [row_h | _]} = Rendro.measure_rows([row], @content_width, Rendro.Document.new(), table_opts)
    body_height = 841.89 - 2 * 72 - 48 - 24
    capacity = body_height - 48 - 24
    effective_cap = capacity - header_h - 2 * row_h - 2.0
    trunc(effective_cap / row_h)
  end

  defp rows_per_page(:receipt) do
    table_opts = [header: ["Description", "Amount"], columns: [{:share, 1}, {:fixed, 72}]]
    row = ["Item 1", "$10.00"]
    {header_h, [row_h | _]} = Rendro.measure_rows([row], @content_width, Rendro.Document.new(), table_opts)
    body_height = 841.89 - 2 * 72 - 48 - 24
    capacity = body_height - 48 - 24
    effective_cap = capacity - header_h - 2.0
    trunc(effective_cap / row_h)
  end

  defp rows_per_page(:invoice) do
    table_opts = [header: ["Item", "Qty", "Price"], columns: [{:share, 1}, {:fixed, 50}, {:fixed, 80}]]
    row = ["Widget", "1", "$10.00"]
    {header_h, [row_h | _]} = Rendro.measure_rows([row], @content_width, Rendro.Document.new(), table_opts)
    body_height = 841.89 - 2 * 72 - 56 - 24
    capacity = body_height - 56 - 24
    # No :totals block in the pagination fixtures, so no totals reservation.
    effective_cap = capacity - header_h - 2.0
    trunc(effective_cap / row_h)
  end

  defp rows_per_page(:payslip) do
    # Payslip's ledger is a 6-column earnings/deductions table with a trailing
    # subtotal row and a reconciliation reserve; geometry mirrors the recipe's
    # own module attributes (header 88, summary 54, footer 24, margin 72,
    # reconciliation_line_height 16, row_epsilon 2.0).
    content_w = 595.28 - 2 * 72

    table_opts = [
      header: ["Earnings", "Amount", "YTD", "Deductions", "Amount", "YTD"],
      columns: [{:share, 2}, {:fixed, 55}, {:fixed, 55}, {:share, 2}, {:fixed, 55}, {:fixed, 55}]
    ]

    row = ["Base Salary", "$100.00", "$100.00", "Federal Tax", "$10.00", "$10.00"]
    {header_h, [row_h | _]} = Rendro.measure_rows([row], content_w, Rendro.Document.new(), table_opts)
    body_h = 841.89 - 72 - 24 - (72 + 88 + 54)
    effective_cap = body_h - header_h - 16 - 2.0
    # Reserve one row for the always-appended subtotal row.
    trunc(effective_cap / row_h) - 1
  end

  # A per-parity static footer block; only_on filtering selects which one renders
  # on each physical page, so their differing text proves parity-varying content.
  defp parity_footer_block(:odd), do: Rendro.block(Rendro.text("Odd-page footer", size: 10))
  defp parity_footer_block(:even), do: Rendro.block(Rendro.text("Even-page footer", size: 10))

  # --- EDGE-02 RTL shaping-required fake font (cloned verbatim from
  # test/rendro/pipeline/measure_test.exs:617-672 — synthetic %Rendro.PDF.Font{}
  # + hand-built %Rendro.Document{}, public structs only, no vendored font).

  defp arabic_capable_fake_font do
    arabic_widths =
      [32, 1575, 1576, 1581, 1585, 1605, 1576, 1575]
      |> Enum.uniq()
      |> Map.new(fn cp -> {cp, 500} end)

    %Rendro.PDF.Font{
      source: :built_in,
      logical_name: :fake_arabic,
      name: "F_FAKE_ARABIC",
      base_font: "FakeArabic",
      subtype: :type1,
      units_per_em: 1000,
      ascent: 800,
      descent: -200,
      default_width: 500,
      widths: arabic_widths,
      cmap: nil,
      font_bytes: nil
    }
  end

  defp doc_with_arabic_text do
    fake_font = arabic_capable_fake_font()

    fake_descriptor = %{
      source: :embedded,
      source_kind: :binary,
      variant: :regular,
      source_data: %{status: :ok, kind: :binary, bytes: <<>>, byte_size: 0},
      pdf_font: fake_font
    }

    base_registry = Rendro.FontRegistry.new()

    custom_registry = %Rendro.FontRegistry{
      base_registry
      | fonts: Map.put(base_registry.fonts, :fake_arabic, fake_descriptor),
        default_font: :fake_arabic
    }

    text = %Rendro.Text{content: "مرحبا", font: :fake_arabic, size: 12, color: {0, 0, 0}}
    block = %Rendro.Block{content: text, x: 0, y: 0, width: nil, height: nil}
    page = %Rendro.Page{blocks: [block]}

    %Rendro.Document{
      pages: [page],
      font_registry: custom_registry,
      default_font: :fake_arabic,
      metadata: %Rendro.Metadata{}
    }
  end
end
