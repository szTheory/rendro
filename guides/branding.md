# Branding

This guide shows how to build a branded document with the public font and asset
registration APIs that shipped in Phases 25 through 28. The branded path stays
behind the same truthful scope boundaries as the rest of Rendro: no silent
fallback, no system-font discovery, no remote asset fetching.

## Overview

Rendro ships one branded canonical recipe, `Rendro.Recipes.BrandedInvoice`, to
prove the end-to-end path for a registered font plus a registered logo asset.
The demo assets are library-owned examples, not built-in defaults for every
document you render.

## Registering brand fonts

Use `Rendro.Document.register_embedded_font/3` to register a logical font name
 against a concrete path or binary source:

```elixir
# docs-contract: branding-register-assets
doc =
  Rendro.Document.new()
  |> Rendro.Document.register_embedded_font(
    :brand_heading,
    {:path, Rendro.Branded.font_path()}
  )
  |> Rendro.Document.register_image(
    :company_logo,
    {:path, Rendro.Branded.logo_path()}
  )

assert Map.has_key?(doc.font_registry.fonts, :brand_heading)
assert match?(%{source: :embedded}, doc.font_registry.fonts[:brand_heading])
assert Map.has_key?(doc.asset_registry.assets, :company_logo)
```

## Registering logo assets

Images follow the same `{:path, _}` or `{:binary, _}` source-tuple contract as
embedded fonts. `Rendro.Branded.logo_path/0` resolves the shipped demo logo
through `Application.app_dir/2`, so the same call works in tests, doctests, and
consumer apps pulling Rendro from Hex.

```elixir-schematic
defmodule MyApp.Branding do
  def apply(doc) do
    doc
    |> Rendro.Document.register_embedded_font(:brand_heading, {:path, "/path/to/brand.ttf"})
    |> Rendro.Document.register_image(:company_logo, {:path, "/path/to/logo.png"})
  end
end
```

## BrandedInvoice tiered composition

The zero-to-one path uses the recipe directly:

```elixir
# docs-contract: branding-tiered-document
data = %{
  id: "INV-2026-101",
  date: ~D[2026-04-30],
  items: [
    %{name: "Consulting", qty: 10, price: 2500},
    %{name: "Support", qty: 1, price: 500}
  ],
  brand: %{font_name: :brand_heading, logo_name: :company_logo}
}

doc = Rendro.Recipes.BrandedInvoice.document(data)
assert doc.page_template == :branded_invoice

{:ok, pdf} = Rendro.render(doc, deterministic: true)
assert binary_part(pdf, 0, 5) == "%PDF-"
assert pdf =~ "/FontFile2"
assert pdf =~ "/Type /XObject"
```

The escape-hatch path exposes the same template and sections if you need to
compose the document manually:

```elixir
# docs-contract: branding-tiered-template
data = %{
  id: "INV-2026-102",
  date: ~D[2026-04-30],
  items: [%{name: "Consulting", qty: 1, price: 1000}],
  brand: %{font_name: :brand_heading, logo_name: :company_logo}
}

template = Rendro.Recipes.BrandedInvoice.page_template()
sections = Rendro.Recipes.BrandedInvoice.sections(data)

doc =
  Rendro.Document.new()
  |> Rendro.Document.register_embedded_font(
    data.brand.font_name,
    {:path, Rendro.Branded.font_path()}
  )
  |> Rendro.Document.register_image(
    data.brand.logo_name,
    {:path, Rendro.Branded.logo_path()}
  )
  |> Rendro.Document.add_template(template)
  |> Rendro.Document.set_template(template.name)
  |> then(fn current ->
    Enum.reduce(sections, current, &Rendro.Document.add_section(&2, &1))
  end)

assert doc.page_template == :branded_invoice
assert Enum.map(doc.sections, & &1.region) |> Enum.sort() == [:body, :footer, :header, :logo]
```

## Failure diagnostics

When a document references an image that was never registered, Rendro returns a
typed `%Rendro.Error{}` instead of silently omitting the block.

| Error tuple | When it occurs | What to check |
|---|---|---|
| `{:error, %Rendro.Error{stage: :measure, reason: {:missing_asset, logical_name}}}` | A `Rendro.Image` references a logical name that is absent from the document asset registry. | Register the image on the document before rendering, or correct the logical name used in `%Rendro.Image{}` content or `Rendro.Component.image/2`. |

```elixir
# docs-contract: branding-missing-asset-diagnostic
template = Rendro.Recipes.BrandedInvoice.page_template()

doc =
  Rendro.Document.new()
  |> Rendro.Document.add_template(template)
  |> Rendro.Document.set_template(template.name)
  |> Rendro.Document.add_section(
    Rendro.section(
      name: :missing_logo,
      region: :logo,
      content: [Rendro.Component.image(:missing_logo, fit: {64, 64})]
    )
  )

assert {:error, %Rendro.Error{stage: :measure, reason: {:missing_asset, :missing_logo}}} =
         Rendro.render(doc)
```
