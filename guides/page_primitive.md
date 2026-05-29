# PAGE Primitive

The PAGE primitive adds deterministic "Page X of Y" running headers and footers
to any multi-page document. It is the engine foundation that every paginated
recipe (Statement, Receipt/Report, Certificate) builds on.

## What it does

When you author a running header or footer region, Rendro uses a single-pass
substitution to replace `{{page_number}}` and `{{total_pages}}` tokens with the
resolved page number and total page count before rendering. The token substitution is
deterministic: given the same input data the same bytes are produced every time.

```elixir
# docs-contract: page-primitive-basic
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

# The statement recipe wires the PAGE primitive into the running footer region.
# Page X of Y substitution is single-pass and deterministic.
{:ok, pdf} = Rendro.render(doc, deterministic: true)
assert binary_part(pdf, 0, 5) == "%PDF-"
```

## Capabilities (bounded by support matrix)

The support matrix row `page_numbering` records the exact capabilities shipped
in `priv/support_matrix.json`. The following are `supported` and backed by
proof in `test/rendro/pipeline/paginate_test.exs`:

| Capability | Status |
|---|---|
| Single-pass `{{page_number}}` / `{{total_pages}}` substitution | supported |
| Deterministic output (same input → same bytes) | supported |
| First-page suppression via `suppress_on` | supported |

Use `Rendro.page_number/1` to author a running footer or header. Pass
`suppress_on: :first` to omit the page number on the first page:

```elixir
# docs-contract: page-primitive-suppress
block = Rendro.page_number(format: "Page {{page_number}} of {{total_pages}}")

# page_number/1 returns a %Rendro.Block{} wrapping a %Rendro.Text{}
assert %Rendro.Block{} = block
assert %Rendro.Text{} = block.content
assert block.content.content =~ "{{page_number}}"

# First-page suppression is applied on the Section level via suppress_on:
section =
  Rendro.section(
    name: :footer_suppressed,
    region: :footer,
    suppress_on: :first,
    content: [block]
  )

assert section.suppress_on == :first
```

## "Page X of Y" pattern

The standard running-footer pattern for a billing statement or report:

```elixir-schematic
# Illustrative only — a real recipe assigns section content from data.
Rendro.page_number(format: "Page {{page_number}} of {{total_pages}}")
```

The tokens `{{page_number}}` and `{{total_pages}}` are substituted after pagination completes,
so the total page count is always accurate. A single rendering pass is sufficient
— no two-pass layout or back-patching is required.

## Scope boundaries

The PAGE primitive does **not** support:

- Digital signatures or signing preparation (see `priv/support_matrix.json` `unsupported` array)
- Blanket compliance claims (see `unsupported` array)

These are outside the supported surface. If you need cryptographic signing,
see `Rendro.Sign`.

## Integration with recipes

Every paginated recipe composes the PAGE primitive through the same
`Rendro.page_number/1` helper:

- `Rendro.Recipes.Statement` — running footer "Page X of Y" on each statement page
- `Rendro.Recipes.Receipt` — running footer on each report page
- `Rendro.Recipes.Certificate` — geometry-derived layout; no header/footer regions

See `guides/recipes.md` for the full per-recipe documentation.
