# PAGE Primitive

The PAGE primitive adds deterministic "Page X of Y" running headers and footers
to any multi-page document. It is the engine foundation that every paginated
recipe (Statement, Receipt/Report, Certificate) builds on.

## What it does

When you author a running header or footer region, Rendro uses a single-pass
substitution to replace `{page}` and `{total}` tokens with the resolved page
number and total page count before rendering. The token substitution is
deterministic: given the same input data the same bytes are produced every time.

```elixir
# docs-contract: page-primitive-basic
import Rendro

doc =
  Rendro.Document.new()
  |> Rendro.Document.add_template(
    Rendro.PageTemplate.new(
      name: :minimal,
      width: 595,
      height: 842,
      body: Rendro.region(name: :body, x: 50, y: 100, width: 495, height: 692),
      footer:
        Rendro.region(
          name: :footer,
          x: 50,
          y: 802,
          width: 495,
          height: 30
        )
    )
  )
  |> Rendro.Document.set_template(:minimal)
  |> Rendro.Document.add_section(
    Rendro.section(
      name: :footer_section,
      region: :footer,
      content: [Rendro.page_number(format: "{page} of {total}")]
    )
  )
  |> Rendro.Document.add_section(
    Rendro.section(
      name: :body_content,
      region: :body,
      content: [Rendro.text("Account Statement")]
    )
  )

assert doc.page_template == :minimal
assert length(doc.sections) == 2
```

## Capabilities (bounded by support matrix)

The support matrix row `page_numbering` records the exact capabilities shipped
in `priv/support_matrix.json`. The following are `supported` and backed by
proof in `test/rendro/pipeline/paginate_test.exs`:

| Capability | Status |
|---|---|
| Single-pass `{page}` / `{total}` substitution | supported |
| Deterministic output (same input → same bytes) | supported |
| First-page suppression via `suppress_on` | supported |

Use `Rendro.page_number/1` to author a running footer or header. Pass
`suppress_on: [:first]` to omit the page number on the first page:

```elixir
# docs-contract: page-primitive-suppress
section =
  Rendro.section(
    name: :footer_suppress,
    region: :footer,
    content: [Rendro.page_number(format: "Page {page} of {total}", suppress_on: [:first])]
  )

assert section.name == :footer_suppress
assert section.region == :footer
[block] = section.content
assert block.suppress_on == [:first]
```

## "Page X of Y" pattern

The standard running-footer pattern for a billing statement or report:

```elixir-schematic
# Illustrative only — a real recipe assigns section content from data.
Rendro.page_number(format: "Page {page} of {total}")
```

The tokens `{page}` and `{total}` are substituted after pagination completes,
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
