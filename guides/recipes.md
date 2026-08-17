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

- Source PDF SHA-256: `77ab05206c06e2d593d299ead319175328b3e5482d99a2c0abac52f7311b6804`
- PNG SHA-256: `6e46e7605a2fb0d8f7fd06ff4194e355f8d672f0100fecaf682080926539d626`

### Branded Invoice

<a href="assets/rendro/gallery/branded_invoice.png"><img src="assets/rendro/gallery/branded_invoice.png" alt="Rendered branded invoice PDF showing Rendro logo, embedded brand font, and invoice table." width="320"></a>

Branded invoice with registered font and logo assets.

- Source PDF SHA-256: `c6ce32b449060f8cd7b01744697ad8fe90ee779cae6c039415935fc239be3a64`
- PNG SHA-256: `2b075ca9a95b63726863a388057895e7edcadbd09bb68f62a1d4fd184b1de804`

### Statement

<a href="assets/rendro/gallery/statement.png"><img src="assets/rendro/gallery/statement.png" alt="Rendered account statement PDF showing dated transaction rows, signed amounts, and a page-numbered footer." width="320"></a>

Account statement with opening/closing balances and per-page numbering.

- Source PDF SHA-256: `12518fdaaf4e1735d15a22d928562d33a49bc9e756472e5fe21cd44f2ec5cc8f`
- PNG SHA-256: `829bd3bad9f5da1d0b4a54bad19e6e049300aac18b1023fcdff215fab12bf571`

### Receipt / Report

<a href="assets/rendro/gallery/receipt_report.png"><img src="assets/rendro/gallery/receipt_report.png" alt="Rendered sales receipt PDF showing itemized line items with a subtotal, tax, and total." width="320"></a>

Itemized sales receipt with subtotal, tax, and total through the Receipt recipe.

- Source PDF SHA-256: `7894948c059892721a528efad2048ce49642645e2831d959b574c0306d5b2c02`
- PNG SHA-256: `bfaf2a1b3011591144b4ba3d16ab5dc8c37abba6e358e569547ba3e56dd94fa1`

### Certificate

<a href="assets/rendro/gallery/certificate.png"><img src="assets/rendro/gallery/certificate.png" alt="Rendered landscape certificate PDF showing recipient text and geometry-derived keyline border." width="320"></a>

Landscape certificate with a Path-backed, geometry-derived border frame.

- Source PDF SHA-256: `4f41898b232ee078e20d89ae3698d4d709a612b24efc53c37b40e957e559d682`
- PNG SHA-256: `25f3c8c7218cd98b558d60a4556ad5be98ced6776f56a25251f04f2b6bbb232c`

### Payslip

<a href="assets/rendro/gallery/payslip.png"><img src="assets/rendro/gallery/payslip.png" alt="Rendered payslip PDF showing employer and employee details, earnings and deductions, and the net pay figure." width="320"></a>

Payslip with earnings, deductions, year-to-date figures, and a reconciled net pay.

- Source PDF SHA-256: `5aa06d26d40e9ab8a9c06c1fef595c7f3adfa94d900e2eac92f2c1b803b0c1e3`
- PNG SHA-256: `e56136b7f24d7da25c18e3de2dd4e25a52aacdc69d0263144990e8615e8c3e84`

### Ticket

<a href="assets/rendro/gallery/ticket.png"><img src="assets/rendro/gallery/ticket.png" alt="Rendered event ticket PDF showing the event title, seat placement grid, and a human-readable reference code." width="320"></a>

Event ticket with a placement grid and a quotable, human-readable reference code.

- Source PDF SHA-256: `e147f01a6529b1ce98581b8fc1c606e56408f069e445eca152059b3de7b826cd`
- PNG SHA-256: `6ebba79147efa6a94ebfff046308eff5da9db6e3e4731210610062e063d4c928`

### Invoice (Dark)

<a href="assets/rendro/gallery/invoice_dark.png"><img src="assets/rendro/gallery/invoice_dark.png" alt="Rendered invoice PDF in dark mode, showing the themed dark background applied to the header, line-item table, and thank-you footer. Dark mode is screen-oriented, not recommended for print." width="320"></a>

Invoice in dark mode via Theme.dark/1 - screen-oriented, not print-recommended.

- Source PDF SHA-256: `8f08b3e1fe69c6d06d91189eee1a4574942076cfa190b1e8338959f45b3adc1d`
- PNG SHA-256: `cae4ded56bdfa0b9414cfdfbd72329a64659876846f75eebf16c923db771c2f2`

### Certificate (Dark)

<a href="assets/rendro/gallery/certificate_dark.png"><img src="assets/rendro/gallery/certificate_dark.png" alt="Rendered landscape certificate PDF in dark mode, showing the themed dark background behind the geometry-derived keyline border. Dark mode is screen-oriented, not recommended for print." width="320"></a>

Certificate in dark mode via Theme.dark/1 - screen-oriented, not for print.

- Source PDF SHA-256: `88ca30f44b02c5836f6c848712486d3d06ad28f8347ad9c8603ab92cf26d295e`
- PNG SHA-256: `a7cf6d31fd0afebd7a73070d10c0d03849d385a08097ef87b9537e64288cf1dd`

### Ticket (Dark)

<a href="assets/rendro/gallery/ticket_dark.png"><img src="assets/rendro/gallery/ticket_dark.png" alt="Rendered event ticket PDF in dark mode, showing the themed dark background behind the seat placement grid and reference code. Dark mode is screen-oriented, not recommended for print." width="320"></a>

Ticket in dark mode via Theme.dark/1 - screen-oriented, not print-recommended.

- Source PDF SHA-256: `b663620145f1daf2b45ebbbe6314af38fbb2cd030b3fb6023caa401db9deba39`
- PNG SHA-256: `de76ebd8ebdfe1a5f68e36da6fc413cd0371a953682671fb39fc5a7dd46a67c0`

### Invoice (Branded Accent)

<a href="assets/rendro/gallery/invoice_brand.png"><img src="assets/rendro/gallery/invoice_brand.png" alt="Rendered invoice PDF themed with a teal brand accent color via from_brand, showing the accent applied to the dominant Total Due figure. No logo or brand font assets are used." width="320"></a>

Invoice themed via from_brand(accent: "#0E7C76") - accent-only, no assets.

- Source PDF SHA-256: `10c1f38f3bb59c466957feb998cbdcd4193e1261e28532b2f7b4f413eb00d567`
- PNG SHA-256: `76d669aea32fd212d4ff81e87c14dd0a2232707da401e428ee30a41f90a24bdd`


## Self-Rendered Manual

Rendro also renders its own compact launch manual: [manual.pdf](assets/rendro/manual.pdf).

SHA-256: `107c047878308448d2dec7f5022c440ebf73054efe133749014a856ef4f77be6`
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
