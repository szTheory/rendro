# Rendro

Pure-Elixir PDF generation with deterministic layout and pagination.

## Features

- **Pure Elixir:** No external dependencies like headless Chrome or wkhtmltopdf.
- **Deterministic:** Same input produces the same binary output (ID, timestamps, dictionary order).
- **Two APIs, One Engine:** Fixed-position for precision, Flow API for reports.
- **Production-Ready:** Built-in telemetry, structured diagnostics, and policies.

## Usage

### Flow API (Recommended for Reports)

```elixir
data = %{
  id: "123",
  date: "2026-04-24",
  items: [%{name: "Product A", qty: 2, price: 50}]
}

doc = Rendro.Recipes.invoice(data)
{:ok, pdf} = Rendro.render(doc)
```

### Fixed-Position API

```elixir
page = Rendro.page(blocks: [
  Rendro.block(Rendro.text("Fixed Position"), x: 100, y: 100)
])

doc = Rendro.fixed([page])
{:ok, pdf} = Rendro.render(doc)
```

## Phoenix Integration

Use the Phoenix adapter to serve PDFs from your controllers:

```elixir
defmodule MyAppWeb.PDFController do
  use MyAppWeb, :controller
  alias Rendro.Adapters.Phoenix, as: RendroPhoenix

  def show(conn, _params) do
    doc = Rendro.Recipes.invoice(%{...})
    RendroPhoenix.preview_pdf(conn, doc)
  end
end
```

## Policies

Protect your system from expensive render operations:

```elixir
doc = Rendro.flow([], options: %{
  policies: [
    max_pages: 50,
    max_bytes: 1_000_000,
    timeout: 5_000
  ]
})
```
