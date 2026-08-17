# Theming

`Rendro.Theme` is a pure, inert design-token value: semantic color roles plus
typography, resolved once and threaded through every recipe's three-rung
pattern (`document/2` → `page_template/1` → `sections/2`). It performs no I/O
and touches no registry — it never reaches the deterministic render pipeline
directly.

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
| Invoice | `Rendro.Recipes.Invoice` | Unbranded `default/0`. | `75b4a52522ae2e6e47a23e1bb29a9e18ca0092a9c76935185cbad4873ab3ae64` | `b95aceb15c479874e0b2170f568031c159bb0b73d6a1fd05d5f66f70b4e2c4a8` |
| Branded Invoice | `Rendro.Recipes.BrandedInvoice` | Registered brand font + logo. | `c6ce32b449060f8cd7b01744697ad8fe90ee779cae6c039415935fc239be3a64` | `2b075ca9a95b63726863a388057895e7edcadbd09bb68f62a1d4fd184b1de804` |
| Statement | `Rendro.Recipes.Statement` | Unbranded `default/0`. | `12518fdaaf4e1735d15a22d928562d33a49bc9e756472e5fe21cd44f2ec5cc8f` | `829bd3bad9f5da1d0b4a54bad19e6e049300aac18b1023fcdff215fab12bf571` |
| Receipt / Report | `Rendro.Recipes.Receipt` | Unbranded `default/0`. | `7894948c059892721a528efad2048ce49642645e2831d959b574c0306d5b2c02` | `bfaf2a1b3011591144b4ba3d16ab5dc8c37abba6e358e569547ba3e56dd94fa1` |
| Certificate | `Rendro.Recipes.Certificate` | Unbranded `default/0`. | `68b35b1f80b9121fa23dd0737f473b37aa8f5647a4243fcfb7ddddb71a1e5c82` | `476a251c30890bf15c3fdc5b7a7e17999abcc98060307ea761d043a846ef4555` |
| Payslip | `Rendro.Recipes.Payslip` | Unbranded `default/0`. | `19a1813b36fde337a3d7e941fca5c83fb8584540a2b1211fb801e8ae66814d9e` | `44ee6ec59d7b0593c75175203be2b31745cec5d6e5e73180293c27dd665d0e26` |
| Ticket | `Rendro.Recipes.Ticket` | Unbranded `default/0`. | `37c617953b5562baf2ceefdefe54af04756bb0c937d0e4902dd889299246b0f9` | `336fa3629eb5cb735a7ee2fd8dba3a903a13683f7efa2190afd46439b4b21496` |
| Invoice (Dark) | `Rendro.Recipes.Invoice` | `Theme.dark/1` — screen-oriented, not print-recommended. | `40d79ddfc79b3ae7bec6a9036c2543122e835a7ef517ec8ec9ea767e74e14629` | `29e9dcd8fb21c89a39d0fc67246895da0834eba9ee32dd1758c201b774a1cc57` |
| Certificate (Dark) | `Rendro.Recipes.Certificate` | `Theme.dark/1` — screen-oriented, not print-recommended. | `01e78fa1960986b5a7691d24aa2dac3b0b6aba10d98391576ff8beda8c34cf85` | `095cfdc71bebd46237f645af71fc1900874387b7777d051caa59c25e472bf53b` |
| Ticket (Dark) | `Rendro.Recipes.Ticket` | `Theme.dark/1` — screen-oriented, not print-recommended. | `2806d73e8f1ae1dea5e90d9a1b571b0684369207eca636d9de7992137e4a90c4` | `ff10a3283f349ec69dfe57531cb3c45b44b34366d9993d35a432ac58b3dc7771` |
| Invoice (Branded Accent) | `Rendro.Recipes.Invoice` | `from_brand(accent: "#0E7C76")` — accent-only, no assets. | `af285aeacdb28f024cf749b93a86a7f35dd82efc5942b2083411c1790c2431b5` | `764d0cc841d7c429e216011d614b14dce2de144c888165d33c7a1bb87db2f233` |

Every hash is generated and verified by `mix rendro.launch_artifacts.gen` /
`mix rendro.launch_artifacts.check` against
`assets/rendro/artifacts.json` — the same pinned pdfium lane the reader-quality
sign-off evidence uses.
