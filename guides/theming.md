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
| Invoice | `Rendro.Recipes.Invoice` | Unbranded `default/0`. | `8808fcf899c5ac5897e5fa1bf7316924edca275ce85f8ec3410f5576f3d5fc22` | `6a7dfd0c963c2bfaddf2bf3e8dedc7f7deef3848a5d91478dae40cc310f49a47` |
| Branded Invoice | `Rendro.Recipes.BrandedInvoice` | Registered brand font + logo. | `c6ce32b449060f8cd7b01744697ad8fe90ee779cae6c039415935fc239be3a64` | `2b075ca9a95b63726863a388057895e7edcadbd09bb68f62a1d4fd184b1de804` |
| Statement | `Rendro.Recipes.Statement` | Unbranded `default/0`. | `d3380c80468ce7a384ac2a54c2b2500a6b8f14b65c3751c12d6b7bf406e445d5` | `b0475e73540b93bcae88f925228a0c7fe31b17d25e1ccd154b62e699308cb31b` |
| Receipt / Report | `Rendro.Recipes.Receipt` | Unbranded `default/0`. | `67902b82dcf1bbd597490ce0d701a040a82604bd19dd1ce3ff53352b0a0b15ad` | `38225439998b6944e309238894df7cf10bc4eef771164fd3018ee7837b89b122` |
| Certificate | `Rendro.Recipes.Certificate` | Unbranded `default/0`. | `9f004ab50efe37c45308ee51ff4dc90ffe252dba765e6c92c4604a0b9a2c0231` | `d6ad49a6829936a81d271df029dad36bf5d2ab62d7af6558e408eded2fad643e` |
| Payslip | `Rendro.Recipes.Payslip` | Unbranded `default/0`. | `fe6943472202526c46647eb65275a3385e570b6d0fd8aee05d3ade4b5620425a` | `bf764cd92cc9775fdd9f03901dba47de0c2108769dbaf4e02dcbc699586f4274` |
| Ticket | `Rendro.Recipes.Ticket` | Unbranded `default/0`. | `d6dc6fa81d1a4884d4a47b7966d261e4da2adb9152c0085fd9c69ebd75324e91` | `b67e1668a9c1cc659a5232220fbf07236f1c516d9dd9ef16662957f07346e990` |
| Invoice (Dark) | `Rendro.Recipes.Invoice` | `Theme.dark/1` — screen-oriented, not print-recommended. | `e4b00000d86a1407f888aa7e5b445b2b0d249056e1590f05d14aaca901137f23` | `49f5d8fafc8a375706b6dfae0ec996337d8283cf791baac6ec42437b761eaa10` |
| Certificate (Dark) | `Rendro.Recipes.Certificate` | `Theme.dark/1` — screen-oriented, not print-recommended. | `3d29d79189480e5b5c29a3ae9d40de88374ef999b22a46402ae8696398ca4517` | `11344160431217ad4279adfa90351efd0a654cdd2e82c32f937db0b604fca3d7` |
| Ticket (Dark) | `Rendro.Recipes.Ticket` | `Theme.dark/1` — screen-oriented, not print-recommended. | `d885fd259e1e20a15cdc3365a94101f6cd693f8e86ca9671f57d380d4089c11c` | `6801b88f27d55418c04d4fb38741b7fc90f4314319ba7dee8cc4562b108fc23d` |
| Invoice (Branded Accent) | `Rendro.Recipes.Invoice` | `from_brand(accent: "#0E7C76")` — accent-only, no assets. | `5dc1eecd7e94e3db0e674bf937dfe678d3c283043cb6a4f157cf192d6348eec4` | `444a532a42110943ebb0f2dc94bac0442447fe9c9d9a12b368dc71de1cd90a5c` |

Every hash is generated and verified by `mix rendro.launch_artifacts.gen` /
`mix rendro.launch_artifacts.check` against
`assets/rendro/artifacts.json` — the same pinned pdfium lane the reader-quality
sign-off evidence uses.
