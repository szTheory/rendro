# Canonical Recipes

Rendro ships four canonical recipes on the three-rung escape-hatch pattern
(`document/2` → `page_template/1` → `sections/2`). Each recipe accepts a
validated data map and returns a fully assembled `%Rendro.Document{}` ready
for `Rendro.render/1`.

The capabilities claimed in this guide are bounded by `priv/support_matrix.json`.
Supported capabilities are backed by on-disk proof in the corresponding evidence
test files. The `unsupported` array in the matrix (`full_pdf_compliance`,
`digital_signatures`) names capabilities this library does **not** claim.

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

- Digital signatures or signing preparation — see `Rendro.Sign`
- Blanket PDF compliance (full_pdf_compliance) — see `priv/support_matrix.json` `unsupported` array
- Viewer-specific rendering guarantees — see `guides/viewer_evidence.md` for recorded per-viewer behavior
