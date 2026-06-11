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

- Source PDF SHA-256: `fc65ac5688462a77e1cc3cdfd8cb25e8ac1d61677d430615443c23f565068105`
- PNG SHA-256: `8acf5472e4c7a7ec6d04843464536b3f291e8cfc0d2c7fe8040913af4e648988`

### Branded Invoice

<a href="assets/rendro/gallery/branded_invoice.png"><img src="assets/rendro/gallery/branded_invoice.png" alt="Rendered branded invoice PDF showing Rendro logo, embedded brand font, and invoice table." width="320"></a>

Branded invoice with registered font and logo assets.

- Source PDF SHA-256: `9bc4a0ea94e2a7cb09dbeeaf5f57b24f624a34a2c7d8012343bca1c66c8e95c9`
- PNG SHA-256: `3618e386c02b622dddb785ead24843481aa963e91653614aeab22287354138b5`

### Statement

<a href="assets/rendro/gallery/statement.png"><img src="assets/rendro/gallery/statement.png" alt="Rendered account statement PDF showing transaction rows, running balances, and Page 1 of 2 footer." width="320"></a>

Multi-page statement with carried-forward balances and running page numbers.

- Source PDF SHA-256: `fa4fd6f3d84ccdccc8a1812c0212a9b17820cd25ffb615519154e9dd3792b835`
- PNG SHA-256: `ec13a842b4ea48308ec682f4765c17fa3b70f75efb58739c3f9eb1a6d8963ec0`

### Receipt / Report

<a href="assets/rendro/gallery/receipt_report.png"><img src="assets/rendro/gallery/receipt_report.png" alt="Rendered receipt report PDF showing repeated table header, line items, totals, and Page 1 of 2 footer." width="320"></a>

Receipt recipe scaled into a multi-page tabular report.

- Source PDF SHA-256: `68f3a44f655c4783bc9bd94ad3c37675edb09cfbe92009b2a54e4a35a91258b5`
- PNG SHA-256: `c2af63ac8460c85f8eb51240567d06ab71b72fd69be337bc165884f4af98c1c4`

### Certificate

<a href="assets/rendro/gallery/certificate.png"><img src="assets/rendro/gallery/certificate.png" alt="Rendered landscape certificate PDF showing recipient text and geometry-derived keyline border." width="320"></a>

Landscape certificate with a Path-backed, geometry-derived border frame.

- Source PDF SHA-256: `51b43c00c1e7afba093c6f6a682630576c639fb65912f504ddc9c6c6db0d3c95`
- PNG SHA-256: `7194ebe35228f4026cc804b0b38913545ef997335d08f6d579f5d450a5c3fcf4`


## Self-Rendered Manual

Rendro also renders its own compact launch manual: [manual.pdf](assets/rendro/manual.pdf).

SHA-256: `a9f1a241c3fb331ad5522d905af8acf26d9848b8862cb9a6f3e4033c3ee1dc94`
<!-- rendro-recipe-gallery-end -->

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
