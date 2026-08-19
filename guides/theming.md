# Theming

`Rendro.Theme` is a pure, inert design-token value: semantic color roles plus
typography, resolved once and threaded through every recipe's three-rung
pattern (`document/2` → `page_template/1` → `sections/2`). It performs no I/O
and touches no registry — it never reaches the deterministic render pipeline
directly.

For a complete preset choice and adoption route, see [Presets](presets.md).
This guide stays focused on manual theme tokens and caller-owned brand inputs.

```elixir-schematic
Rendro.Recipes.Invoice.document(data, theme: Rendro.Theme.from_brand(accent: "#0E7C76"))
```

## Start with an accent

The narrowest branded theme is a single `accent:` seed. `from_brand/2` coerces
a hex string to an integer `{r, g, b}` tuple at the authoring boundary, keeps
every other role at the unbranded default, and derives a readable `on_accent`
for you.

```elixir
# docs-contract: theming-accent-only
import ExUnit.Assertions

theme = Rendro.Theme.from_brand(accent: "#0E7C76")
resolved = Rendro.Theme.resolve(theme)

# accent seed coerced hex -> tuple
assert resolved.colors.accent == {14, 124, 118}
# on_accent derived to white: teal luminance ~0.16, greater contrast vs background
assert resolved.colors.on_accent == {255, 255, 255}
```

`on_accent` is a **sensible readable default**, picked by comparing WCAG
contrast between the accent and the theme's own neutral poles (`background`
vs `ink`) — it is **not** a WCAG-AA/AAA or PDF-UA conformance claim. Mid-tone
accents can miss 4.5:1 either way. Pass an explicit `on_accent:` to override
the derivation whenever your accent needs one.

## The heuristic proven both ways

A light accent flips the derivation to the opposite pole. Amber (luminance
~0.50) has far more contrast against dark ink than against a white background,
so `on_accent` resolves to ink instead of white:

```elixir
# docs-contract: theming-accent-contrast-both-ways
import ExUnit.Assertions

amber = Rendro.Theme.resolve(Rendro.Theme.from_brand(accent: "#E6B450"))
# ink, because amber is light (luminance ~0.50) -- again a readable default,
# not a WCAG-AA/PDF-UA guarantee, and overridable via on_accent:
assert amber.colors.on_accent == {16, 24, 39}
```

## The fuller form

Beyond `accent:`, `from_brand/2` accepts any color role plus an explicit
`on_accent:` override, and `opts` for `mode:`/`density:`:

```elixir-schematic
theme =
  Rendro.Theme.from_brand(
    accent: "#7A2E8F",
    ink: {20, 20, 24},
    surface: {245, 240, 250},
    on_accent: {255, 255, 255}
  )
```

Swap `"#7A2E8F"` for your color here — any hex string or `{r, g, b}` tuple
works; `from_brand/2` validates every resolved role via `Rendro.Color.validate/1`
and raises an instructive `ArgumentError` on an invalid token.

## `brand:` and `theme:` are orthogonal

`brand:` answers *who* (a registered font + logo asset on `data.brand`);
`theme:` answers *how* (color roles + typography). `from_brand/2` emits
tokens only — it never registers a font or an image, and reading a bare
`%Rendro.Theme{}` does not add any registry-adjacent field to the value.
`Rendro.Recipes.BrandedInvoice.document/2` composes both without either
leaking into the other:

```elixir
# docs-contract: theming-brand-orthogonal
import ExUnit.Assertions

data = %{
  id: "INV-2026-201",
  date: ~D[2026-05-01],
  items: [%{name: "Consulting", qty: 4, price: 1500}],
  brand: %{font_name: :brand_heading, logo_name: :company_logo}
}

theme = Rendro.Theme.from_brand(accent: "#0E7C76")

# from_brand/2 alone returns a bare %Theme{} -- no registry side-effect
assert %Rendro.Theme{} = theme
refute Map.has_key?(Map.from_struct(theme), :font_registry)
refute Map.has_key?(Map.from_struct(theme), :asset_registry)

doc = Rendro.Recipes.BrandedInvoice.document(data, theme: theme)

# assets registered via data.brand
assert Map.has_key?(doc.font_registry.fonts, :brand_heading)
assert Map.has_key?(doc.asset_registry.assets, :company_logo)
# accent registered via theme: -- the same coerced tuple, orthogonal to assets
assert Rendro.Theme.resolve(theme).colors.accent == {14, 124, 118}
```

## Light and dark, for free

Every recipe reads color roles, never literals, so `Rendro.Theme.dark/1`
gives every recipe a full-page dark background with zero recipe-level dark
code. Dark is a screen-oriented convenience: it carries no print,
accessibility, PDF-UA, or WCAG-contrast support claim — see
`priv/support_matrix.json`'s `theming.dark` boundaries.

## Gallery

Eleven rendered rows prove the theming contract end to end: the unbranded
default, dark mode, and a branded accent, each rendered through the pinned
deterministic pdfium lane and hash-checked against
`assets/rendro/artifacts.json`.

| Row | Recipe | Notes | `source_pdf_sha256` | `png_sha256` |
|---|---|---|---|---|
| Invoice | `Rendro.Recipes.Invoice` | Unbranded `default/0`. | `77ab05206c06e2d593d299ead319175328b3e5482d99a2c0abac52f7311b6804` | `6e46e7605a2fb0d8f7fd06ff4194e355f8d672f0100fecaf682080926539d626` |
| Branded Invoice | `Rendro.Recipes.BrandedInvoice` | Registered brand font + logo. | `c6ce32b449060f8cd7b01744697ad8fe90ee779cae6c039415935fc239be3a64` | `2b075ca9a95b63726863a388057895e7edcadbd09bb68f62a1d4fd184b1de804` |
| Statement | `Rendro.Recipes.Statement` | Unbranded `default/0`. | `12518fdaaf4e1735d15a22d928562d33a49bc9e756472e5fe21cd44f2ec5cc8f` | `829bd3bad9f5da1d0b4a54bad19e6e049300aac18b1023fcdff215fab12bf571` |
| Receipt / Report | `Rendro.Recipes.Receipt` | Unbranded `default/0`. | `7894948c059892721a528efad2048ce49642645e2831d959b574c0306d5b2c02` | `bfaf2a1b3011591144b4ba3d16ab5dc8c37abba6e358e569547ba3e56dd94fa1` |
| Certificate | `Rendro.Recipes.Certificate` | Unbranded `default/0`. | `4f41898b232ee078e20d89ae3698d4d709a612b24efc53c37b40e957e559d682` | `25f3c8c7218cd98b558d60a4556ad5be98ced6776f56a25251f04f2b6bbb232c` |
| Payslip | `Rendro.Recipes.Payslip` | Unbranded `default/0`. | `5aa06d26d40e9ab8a9c06c1fef595c7f3adfa94d900e2eac92f2c1b803b0c1e3` | `e56136b7f24d7da25c18e3de2dd4e25a52aacdc69d0263144990e8615e8c3e84` |
| Ticket | `Rendro.Recipes.Ticket` | Unbranded `default/0`. | `e147f01a6529b1ce98581b8fc1c606e56408f069e445eca152059b3de7b826cd` | `6ebba79147efa6a94ebfff046308eff5da9db6e3e4731210610062e063d4c928` |
| Invoice (Dark) | `Rendro.Recipes.Invoice` | `Theme.dark/1` — screen-oriented, not print-recommended. | `8f08b3e1fe69c6d06d91189eee1a4574942076cfa190b1e8338959f45b3adc1d` | `cae4ded56bdfa0b9414cfdfbd72329a64659876846f75eebf16c923db771c2f2` |
| Certificate (Dark) | `Rendro.Recipes.Certificate` | `Theme.dark/1` — screen-oriented, not print-recommended. | `88ca30f44b02c5836f6c848712486d3d06ad28f8347ad9c8603ab92cf26d295e` | `a7cf6d31fd0afebd7a73070d10c0d03849d385a08097ef87b9537e64288cf1dd` |
| Ticket (Dark) | `Rendro.Recipes.Ticket` | `Theme.dark/1` — screen-oriented, not print-recommended. | `b663620145f1daf2b45ebbbe6314af38fbb2cd030b3fb6023caa401db9deba39` | `de76ebd8ebdfe1a5f68e36da6fc413cd0371a953682671fb39fc5a7dd46a67c0` |
| Invoice (Branded Accent) | `Rendro.Recipes.Invoice` | `from_brand(accent: "#0E7C76")` — accent-only, no assets. | `10c1f38f3bb59c466957feb998cbdcd4193e1261e28532b2f7b4f413eb00d567` | `76d669aea32fd212d4ff81e87c14dd0a2232707da401e428ee30a41f90a24bdd` |

Every hash is generated and verified by `mix rendro.launch_artifacts.gen` /
`mix rendro.launch_artifacts.check` against
`assets/rendro/artifacts.json` — the same pinned pdfium lane the reader-quality
sign-off evidence uses.
