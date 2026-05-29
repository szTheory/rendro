# Phoenix Example App

A reference Phoenix 1.8 application demonstrating `Rendro.Adapters.Phoenix` for
PDF generation in a standard Phoenix controller setup. Every demonstrated recipe
flows through `Rendro.Adapters.Phoenix` — no manual header-juggling or
`Rendro.render/2` calls in the controller layer.

## Setup

```sh
cd examples/phoenix_example
mix deps.get
```

## Boot

```sh
mix phx.server
```

The server starts at `http://localhost:4000`. The root route (`/`) returns a
plain HTML chooser listing all available download and preview links.

## Demonstrated Recipes

The recipe download/preview routes are under the `:api` pipeline
(`plug :accepts, ["json"]`); the root chooser route (`/`) is under `:browser`
and returns plain HTML.

### Invoice

Plain invoice with line items.

- `GET /download` — renders `Rendro.Recipes.Invoice` as an attachment (`example.pdf`)
- `GET /preview` — renders inline for browser preview

### BrandedInvoice

Invoice with a registered embedded font and logo asset.

- `GET /branded/download` — renders `Rendro.Recipes.BrandedInvoice` as an attachment
- `GET /branded/preview` — renders inline for browser preview

### Statement

Multi-page billing statement with "Page X of Y" footers and running
carried-forward / brought-forward balances.

- `GET /statement/download` — renders `Rendro.Recipes.Statement` as an attachment (`statement.pdf`)
- `GET /statement/preview` — renders inline for browser preview

### Receipt / Report

Single module scaling 1 to N pages — a long tabular report is a receipt that
overflows, with repeating table headers and per-page footers.

- `GET /receipt/download` — renders `Rendro.Recipes.Receipt` as an attachment (`receipt.pdf`)
- `GET /receipt/preview` — renders inline for browser preview

### Certificate

Landscape-default certificate with all element coordinates derived from template
geometry. Renders at A4 and US Letter without hardcoded numerics. Optional
branding mirrors `BrandedInvoice`.

- `GET /certificate/download` — renders `Rendro.Recipes.Certificate` as an attachment (`certificate.pdf`)
- `GET /certificate/preview` — renders inline for browser preview

## Adapter Pattern

Each controller action follows the same two-line pattern:

```elixir
def download(conn, _params) do
  doc = Rendro.Recipes.Invoice.document(@demo_invoice)
  Rendro.Adapters.Phoenix.render_pdf(conn, doc, "example.pdf")
end

def preview(conn, _params) do
  doc = Rendro.Recipes.Invoice.document(@demo_invoice)
  Rendro.Adapters.Phoenix.preview_pdf(conn, doc)
end
```

`render_pdf/3` sets `Content-Disposition: attachment`; `preview_pdf/2` sets
`Content-Disposition: inline`. Both set `Content-Type: application/pdf` and
handle `Rendro.Error` at the adapter boundary.

## CI Note

The `example-phoenix` CI job runs `mix deps.get && mix test` as an advisory
smoke test. It is **not required** as a branch-protection check (REF-03 /
D-09) — its failure must never block `test`, `signing-live-proof`,
`long-lived-live-proof`, or `release-proof`. Do NOT add `example-phoenix` to
the required status checks.
