# Rendro

Pure-Elixir PDF generation with deterministic layout and pagination.

## Features

- **Pure Elixir:** No external dependencies like headless Chrome or wkhtmltopdf.
- **Deterministic:** Same input produces the same binary output (ID, timestamps, dictionary order).
- **Two APIs, One Engine:** Fixed-position for precision, Flow API for reports.
- **Production-Ready:** Built-in telemetry, structured diagnostics, and policies.

## Usage

### Flow API (Recommended for Reports)

Verified by the README compile/eval lane in `mix docs.contract`.

```elixir
# docs-contract: readme-flow-compile
data = %{
  id: "123",
  date: "2026-04-24",
  items: [%{name: "Product A", qty: 2, price: 50}]
}

doc = Rendro.Recipes.invoice(data)
{:ok, _pdf} = Rendro.render(doc)
```

When you want asserted output instead of compile-only validation, use the doctest
lane:

```iex
iex> doc =
...>   Rendro.fixed([
...>     Rendro.page(blocks: [Rendro.block(Rendro.text("Receipt", size: 12), x: 36, y: 72)])
...>   ])
iex> {:ok, pdf} = Rendro.render(doc)
iex> binary_part(pdf, 0, 4)
"%PDF"
```

### Fixed-Position API

Verified by the README compile/eval lane in `mix docs.contract`.

```elixir
# docs-contract: readme-fixed-compile
page = Rendro.page(blocks: [
  Rendro.block(Rendro.text("Fixed Position"), x: 100, y: 100)
])

doc = Rendro.fixed([page])
{:ok, _pdf} = Rendro.render(doc)
```

## Phoenix Integration

Use the Phoenix adapter to serve PDFs from your controllers:

This controller example is schematic and intentionally outside the executable
docs-contract lane because it depends on your application's Phoenix module and
connection setup.

```elixir-schematic
defmodule MyAppWeb.PDFController do
  use MyAppWeb, :controller
  alias Rendro.Adapters.Phoenix, as: RendroPhoenix

  def show(conn, _params) do
    doc =
      Rendro.Recipes.invoice(%{
        id: "INV-001",
        date: "2026-04-24",
        items: [%{name: "Consulting", qty: 1, price: 1_500}]
      })

    RendroPhoenix.preview_pdf(conn, doc)
  end
end
```

## Ecosystem Integrations

Rendro ships optional adapters for `threadline` (audit logging),
`mailglass` (transactional email attachments), and `accrue` (billing
recipes). None of them are hard dependencies of Rendro — each adapter is
compiled only when its target library is present in your application's
own `mix.exs`.

See [guides/integrations.md](guides/integrations.md) for setup steps,
verification recipes, and failure-diagnostics reference for each adapter.

## Policies

Protect your system from expensive render operations:

Verified by the README compile/eval lane in `mix docs.contract`.

```elixir
# docs-contract: readme-policies-compile
_doc = Rendro.flow([], options: %{
  policies: [
    max_pages: 50,
    max_bytes: 1_000_000,
    timeout: 5_000
  ]
})
```
