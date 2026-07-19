# Canonical Recipes

Rendro ships canonical recipes on the three-rung escape-hatch pattern
(`document/2` → `page_template/1` → `sections/2`). This guide includes five rendered gallery entries, including a branded invoice variant, so you can see the launch fixtures while still using canonical recipe defaults in code.

The capabilities claimed in this guide are bounded by `priv/support_matrix.json`.
Supported capabilities are backed by on-disk proof in the corresponding evidence
test files. Claims that exceed the support matrix are not made here.

<!-- rendro-recipe-gallery-start -->
## Rendered Gallery

These previews are rendered by Rendro from curated deterministic recipe fixtures and recorded in `assets/rendro/artifacts.json`.

Source PDFs and the self-rendered manual are byte-checked by the required docs contract. PNG rasters are regenerated and hash-checked in the pinned pdfium-render advisory lane. pdfium-render rasters are render proof, not GUI-viewer proof. Launch fixtures may use opt-in table polish; canonical recipe defaults remain unchanged.

### Invoice

<a href="assets/rendro/gallery/invoice.png"><img src="assets/rendro/gallery/invoice.png" alt="Rendered invoice PDF showing invoice header, line-item table, and thank-you footer." width="320"></a>

Standard invoice from Elixir data through the canonical Invoice recipe.

- Source PDF SHA-256: `8c31b186e2693b19bec3c24bf0493f8c6816791cd2827851e957e322b0a98e14`
- PNG SHA-256: `87460b18d486e550278eb2aa02e33d2486a45a0c21ac409d799010668ca494cc`

### Branded Invoice

<a href="assets/rendro/gallery/branded_invoice.png"><img src="assets/rendro/gallery/branded_invoice.png" alt="Rendered branded invoice PDF showing Rendro logo, embedded brand font, and invoice table." width="320"></a>

Branded invoice with registered font and logo assets.

- Source PDF SHA-256: `4f82f2d66185d8c286b1abf268b34e85b3f5132f72cada55c045042e98156dd7`
- PNG SHA-256: `5c227171b94b6136fc208e068b85313b65f8a60a690622badabd84fdd2e69c87`

### Statement

<a href="assets/rendro/gallery/statement.png"><img src="assets/rendro/gallery/statement.png" alt="Rendered account statement PDF showing dated transaction rows, signed amounts, and a page-numbered footer." width="320"></a>

Account statement with opening/closing balances and per-page numbering.

- Source PDF SHA-256: `9b7466022505a475146e80b0887582554616aacd9b7b85a9d299ab10e0ac9658`
- PNG SHA-256: `fd1fd49135dc7779ac00e18310cb31bba91e4678f253ac2a73fba71e11a4e3fa`

### Receipt / Report

<a href="assets/rendro/gallery/receipt_report.png"><img src="assets/rendro/gallery/receipt_report.png" alt="Rendered sales receipt PDF showing itemized line items with a subtotal, tax, and total." width="320"></a>

Itemized sales receipt with subtotal, tax, and total through the Receipt recipe.

- Source PDF SHA-256: `104de299f0460826b02f8b9283f59ccfc5d61f71b17e69439fedb65e5678ccfe`
- PNG SHA-256: `fec336644f39bda4e97d2b12f6f46796a1e61f3d3b6453e954e75df2312f5471`

### Certificate

<a href="assets/rendro/gallery/certificate.png"><img src="assets/rendro/gallery/certificate.png" alt="Rendered landscape certificate PDF showing recipient text and geometry-derived keyline border." width="320"></a>

Landscape certificate with a Path-backed, geometry-derived border frame.

- Source PDF SHA-256: `0047fc9ca3aefe6f29cc98a0491f32051c6c0e21cd13a4cbebe586279349efc1`
- PNG SHA-256: `50377aae3ecabdeaeb66a8219c314612ba2577f8cf0872ccd7479246b5302a03`

### Payslip

<a href="assets/rendro/gallery/payslip.png"><img src="assets/rendro/gallery/payslip.png" alt="Rendered payslip PDF showing employer and employee details, earnings and deductions, and the net pay figure." width="320"></a>

Payslip with earnings, deductions, year-to-date figures, and a reconciled net pay.

- Source PDF SHA-256: `949cf2ad2739115a14c1e60c1632e58ece24e47d16d201c6cc95385231dbcef4`
- PNG SHA-256: `f62561cca5155f41241465b89d3727a5dbd9ebf11f32d71cbecd11bca1aae75c`

### Ticket

<a href="assets/rendro/gallery/ticket.png"><img src="assets/rendro/gallery/ticket.png" alt="Rendered event ticket PDF showing the event title, seat placement grid, and a human-readable reference code." width="320"></a>

Event ticket with a placement grid and a quotable, human-readable reference code.

- Source PDF SHA-256: `9267806a46b3793d83b24423d819ab5e6f89766b42b08e12fec3107fc69cbc74`
- PNG SHA-256: `66889a6850e980f19b71b4c765eb32531ac8ad323c965ce158f6febc30be3d1c`


## Self-Rendered Manual

Rendro also renders its own compact launch manual: [manual.pdf](assets/rendro/manual.pdf).

SHA-256: `79bc2117272d7e8d2c7de275e06672a236fd9e84ecc6a736ee43585fba5a45e4`
<!-- rendro-recipe-gallery-end -->

## Realistic Example Library

Rendro ships a small library of realistic, fictional business-document fixtures
under `priv/examples/`, one directory per family. These are the same curated
fixtures the Rendered Gallery above renders, so what the gallery shows is what
these fixtures produce — rendered deterministically and byte-checked by the
required source-PDF SHA-256 docs contract.

| Family | Fixture | Domain notes |
|---|---|---|
| Invoice | `priv/examples/invoice/acme-phoenix-saas/invoice.json` | `priv/examples/invoice/DOMAIN.md` |
| Statement | `priv/examples/statement/northwind-ledger-co/statement.json` | `priv/examples/statement/DOMAIN.md` |
| Receipt | `priv/examples/receipt/harbor-and-oak-cafe/receipt.json` | `priv/examples/receipt/DOMAIN.md` |
| Certificate | `priv/examples/certificate/summit-training-institute/certificate.json` | `priv/examples/certificate/DOMAIN.md` |
| Payslip | `priv/examples/payslip/aurora-live/payslip.json` | `priv/examples/payslip/DOMAIN.md` |
| Ticket | `priv/examples/ticket/aurora-live/ticket.json` | `priv/examples/ticket/DOMAIN.md` |

Each fixture is plain JSON: money is carried as a decimal string (never a float)
and dates as ISO-8601 strings. Internally, Rendro loads these fixtures through the
`Rendro.Examples` helper and coerces them to the atom-keyed, `Decimal`-faithful,
`Date`-typed shape each recipe expects through `Rendro.ExamplesData`. Both are
`@moduledoc false` internal helpers for the shipped demonstration set — in your own
app you build the recipe data map directly (as shown in each recipe section below)
and call the recipe's `document/2`.

These fixtures demonstrate each family rendered deterministically; they are not a
claim of visual polish, and Rendro makes no accessibility-standard claim about the
rendered output. Each family's supported capabilities are bounded by
`priv/support_matrix.json` and backed by the recipe's evidence test.

Loading a shipped fixture through the internal helpers looks like this:

```elixir-schematic
raw = Rendro.Examples.load!("invoice/acme-phoenix-saas/invoice.json")
data = Rendro.ExamplesData.transform_invoice(raw)
doc = Rendro.Recipes.Invoice.document(data)
{:ok, _pdf} = Rendro.render(doc, deterministic: true)
```

## Statement

A multi-page billing statement with running "Page X of Y" footers and automatic
carried-forward / brought-forward running balances.

**Support matrix row:** `statement` (backed by `test/rendro/recipes/statement_test.exs`)

**Supported capabilities:**

| Capability | Status |
|---|---|
| Multi-page table continuation (carried-forward / brought-forward rows) | supported |
| Running footer "Page X of Y" on every page | supported |
| Deterministic output | supported |

### Zero-to-one

```elixir
# docs-contract: recipes-statement-document
data = %{
  period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
  account: %{name: "Acme Corp"},
  opening_balance: Decimal.new("1000.00"),
  lines: [
    %{date: ~D[2026-05-02], description: "Invoice #1", amount: Decimal.new("500.00")},
    %{date: ~D[2026-05-15], description: "Payment", amount: Decimal.new("-200.00")}
  ]
}

doc = Rendro.Recipes.Statement.document(data)
assert doc.page_template == :statement
assert %Rendro.Document{} = doc

{:ok, pdf} = Rendro.render(doc, deterministic: true)
assert binary_part(pdf, 0, 5) == "%PDF-"
```

### Escape-hatch (page_template + sections)

```elixir
# docs-contract: recipes-statement-escape-hatch
data = %{
  period: %{from: ~D[2026-06-01], to: ~D[2026-06-30]},
  account: %{name: "Beta LLC"},
  opening_balance: Decimal.new("500.00"),
  lines: [
    %{date: ~D[2026-06-05], description: "Service fee", amount: Decimal.new("150.00")}
  ]
}

template = Rendro.Recipes.Statement.page_template()
sections = Rendro.Recipes.Statement.sections(data)

assert template.name == :statement
assert is_list(sections)
assert length(sections) > 0
```

### Data contract

Required keys:

- `:period` — `%{from: Date.t(), to: Date.t()}`
- `:account` — `%{name: String.t()}`
- `:opening_balance` — `Decimal.t()` (Float raises an instructive `ArgumentError`)
- `:lines` — `[%{date: Date.t(), description: String.t(), amount: Decimal.t()}]`

Optional keys:

- `:closing_balance` — `Decimal.t()` (validated against the running fold)
- `:summary` — caller-supplied summary map

---

## Receipt / Report

A payment receipt that scales from one page to N pages. Multi-page is just a
receipt whose line items overflow — column headers repeat on every page via
per-page table blocks; "Page X of Y" appears in the running footer.

**Support matrix row:** `receipt_report` (backed by `test/rendro/recipes/receipt_test.exs`)

**Supported capabilities:**

| Capability | Status |
|---|---|
| Multi-page table continuation with repeating column headers | supported |
| Running footer "Page X of Y" on every page | supported |
| Deterministic output | supported |

### Zero-to-one

```elixir
# docs-contract: recipes-receipt-document
data = %{
  title: "Payment Receipt",
  date: ~D[2026-05-29],
  customer: %{name: "Acme Corp"},
  lines: [
    %{description: "Widget A", amount: Decimal.new("29.99")},
    %{description: "Widget B", amount: Decimal.new("49.99")}
  ],
  totals: %{subtotal: Decimal.new("79.98"), total: Decimal.new("79.98")}
}

doc = Rendro.Recipes.Receipt.document(data)
assert doc.page_template == :receipt
assert %Rendro.Document{} = doc

{:ok, pdf} = Rendro.render(doc, deterministic: true)
assert binary_part(pdf, 0, 5) == "%PDF-"
```

### Escape-hatch (page_template + sections)

```elixir
# docs-contract: recipes-receipt-escape-hatch
data = %{
  title: "Service Invoice",
  date: ~D[2026-06-01],
  customer: %{name: "Beta LLC"},
  lines: [
    %{description: "Consulting", amount: Decimal.new("1200.00")}
  ]
}

template = Rendro.Recipes.Receipt.page_template()
sections = Rendro.Recipes.Receipt.sections(data)

assert template.name == :receipt
assert is_list(sections)
assert length(sections) > 0
```

### Data contract

Required keys:

- `:title` — `String.t()`
- `:date` — `Date.t()`
- `:customer` — `%{name: String.t()}`
- `:lines` — `[%{description: String.t(), amount: Decimal.t()}]`

Optional keys:

- `:totals` — `%{subtotal: Decimal.t(), total: Decimal.t()}` (validated when present)

---

## Certificate

A geometry-derived completion, compliance, or award certificate. All region
coordinates are computed from template geometry — zero hardcoded A4 numerics.
The default orientation is landscape A4 (classic diploma look). Portrait is
reachable via `orientation: :portrait`. Branding is optional.

**Support matrix row:** `certificate` (backed by `test/rendro/recipes/certificate_test.exs`)

**Supported capabilities:**

| Capability | Status |
|---|---|
| Geometry-derived layout (all coordinates from page dimensions) | supported |
| Multiple page sizes (A4 and US Letter via geometry) | supported |
| Branded output (optional font + logo registration) | supported |
| Deterministic output | supported |

### Zero-to-one

```elixir
# docs-contract: recipes-certificate-document
data = %{
  title: "Certificate of Completion",
  recipient: "Jane Smith",
  date: ~D[2026-05-29],
  body: "For outstanding contribution to deterministic PDF generation.",
  seal_line: "Authorized Signature"
}

doc = Rendro.Recipes.Certificate.document(data)
assert doc.page_template == :certificate
assert %Rendro.Document{} = doc

{:ok, pdf} = Rendro.render(doc, deterministic: true)
assert binary_part(pdf, 0, 5) == "%PDF-"
```

### Escape-hatch (page_template + sections)

```elixir
# docs-contract: recipes-certificate-escape-hatch
data = %{
  title: "Award of Excellence",
  recipient: "Alex Chen",
  date: ~D[2026-06-15]
}

template = Rendro.Recipes.Certificate.page_template()
sections = Rendro.Recipes.Certificate.sections(data)

# Certificate uses geometry-derived layout with a single body region
assert template.name == :certificate
assert template.width > template.height
assert is_list(sections)
assert length(sections) > 0
```

### Data contract

Required keys:

- `:title` — `String.t()`
- `:recipient` — `String.t()`
- `:date` — `Date.t()`

Optional keys:

- `:body` — `String.t()` (body statement, default `""`, must be ≤ 2000 bytes)
- `:seal_line` — `String.t()` (signature / seal line, default `""`)
- `:brand` — `%{font_name: atom(), logo_name: atom()}` (branded output)

---

## Payslip

A payslip with an earnings/deductions ledger and a reconciled **net pay** figure
rendered as the page's visual anchor. Money is `Decimal`-faithful, and the net pay
is validated to reconcile against earnings minus deductions. The realistic fixture
lives at `priv/examples/payslip/aurora-live/payslip.json`.

**Support matrix row:** `payslip` (backed by `test/rendro/recipes/payslip_test.exs`)

**Supported capabilities:**

| Capability | Status |
|---|---|
| Net pay visual anchor | supported |
| Multi-page ledger continuation | supported |
| Jurisdiction carried as data (no hardcoded tax logic) | supported |
| Deterministic output | supported |

### Zero-to-one

```elixir-schematic
data = %{
  employer: %{name: "Aurora Live", address: "500 Harbor Blvd, Portland, OR"},
  employee: %{name: "Jordan Reyes", id: "E-1042", tax_code: "1257L"},
  period: %{from: ~D[2026-06-01], to: ~D[2026-06-30]},
  pay_date: ~D[2026-07-05],
  earnings: [
    %{description: "Base salary", amount: Decimal.new("4200.00"), ytd: Decimal.new("25200.00")}
  ],
  deductions: [
    %{description: "Income tax", amount: Decimal.new("907.50"), ytd: Decimal.new("5445.00")}
  ],
  net_pay: Decimal.new("3292.50")
}

doc = Rendro.Recipes.Payslip.document(data)
{:ok, _pdf} = Rendro.render(doc, deterministic: true)
```

### Data contract

Required keys:

- `:employer` — `%{name: String.t(), address: String.t()}`
- `:employee` — `%{name: String.t(), id: String.t(), tax_code: String.t()}`
- `:period` — `%{from: Date.t(), to: Date.t()}`
- `:pay_date` — `Date.t()`
- `:earnings` / `:deductions` — `[%{description: String.t(), amount: Decimal.t(), ytd: Decimal.t()}]`
- `:net_pay` — `Decimal.t()` (validated to reconcile: earnings − deductions)

Optional keys:

- `:payment_method` — masked account string (e.g. `···· 4321`)

---

## Ticket

An event ticket with a placement grid (section / row / seat / gate) and a quotable,
human-readable reference code. Rendro renders the caller-supplied reference text
as-is and never synthesizes a faux barcode; supply your own code image if you need
a scannable one. The realistic fixture lives at
`priv/examples/ticket/aurora-live/ticket.json`.

**Support matrix row:** `ticket` (backed by `test/rendro/recipes/ticket_test.exs`)

**Supported capabilities:**

| Capability | Status |
|---|---|
| Geometry-derived layout | supported |
| Caller-supplied code image | supported |
| No faux barcode (human-readable reference unless you supply an image) | supported |
| Deterministic output | supported |

### Zero-to-one

```elixir-schematic
data = %{
  issuer: %{name: "Aurora Live"},
  title: "Midsummer Night Concert",
  placement: [
    %{label: "Section", value: "GA"},
    %{label: "Row", value: "H"},
    %{label: "Seat", value: "24"},
    %{label: "Gate", value: "B"}
  ],
  code: %{reference: "AUR-88213-GA"}
}

doc = Rendro.Recipes.Ticket.document(data)
{:ok, _pdf} = Rendro.render(doc, deterministic: true)
```

### Data contract

Required keys:

- `:issuer` — `%{name: String.t()}`
- `:title` — `String.t()`
- `:placement` — `[%{label: String.t(), value: String.t()}]`
- `:code` — `%{reference: String.t()}` (optional `:image` registers a caller-supplied code asset as `:ticket_code`)

Optional keys:

- `:subtitle` — `String.t()` (≤ 200 bytes)
- `:terms` — `String.t()` (≤ 600 bytes)

---

## Invoice and Branded Invoice

Invoice and BrandedInvoice are the foundational Rendro recipes covering standard
invoice and branded invoice generation with a registered font and logo asset.

For full documentation on Invoice and BrandedInvoice — including font/asset
registration, the three-rung composition pattern, failure diagnostics, and
verified runnable examples — see `guides/branding.md`.

The support matrix has no separate `invoice` or `branded_invoice` rows because
the branding surface is already covered by the guide and recipe moduledocs.

---

## Scope boundaries

None of the recipes in this guide claim:

- Signing or signing preparation — see `Rendro.Sign` for the supported signing path
- Blanket compliance or viewer-promotion narratives — see `priv/support_matrix.json` for the exact supported surface
- Viewer-specific rendering guarantees — see `guides/viewer_evidence.md` for recorded per-viewer behavior
