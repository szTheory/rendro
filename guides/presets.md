# Presets

Choose a document direction, supply an accent, and render a real PDF with the
same explicit font-registration step used by Rendro's shipped recipes.

## Start with a Swiss invoice

This Invoice/Swiss/`#2C6BED`/light path is the canonical first success. It uses
the formatter-owned source shared by the configurator and Livebook, so the
selection you copy stays aligned with Rendro's supported preset syntax.

```elixir
# rendro-theme-snippet:start
preset = :swiss

theme =
  Rendro.Theme.preset(preset, accent: {44, 107, 237}, mode: :light)

document =
  invoice
  |> Rendro.Recipes.Invoice.document(theme: theme)
  |> Rendro.Theme.Presets.register_fonts(preset)
# rendro-theme-snippet:end
```

Each preset is a strong starting point: choose a style, supply your accent, and review the rendered document for your content. Presets are not design-quality, accessibility, PDF/UA, WCAG, or print-safety guarantees.

`Rendro.render/2` can now render `document` deterministically. The explicit
`register_fonts/2` call keeps the document responsible for the curated fonts it
embeds; it is not a global registration step.

## Choose a direction

Rendro provides six strict preset constructors. They are starting directions,
not a ranking or an approval of a document's final visual quality.

| Preset | Direction | Useful for |
| --- | --- | --- |
| Swiss | compact grotesque structure | product and SaaS invoices |
| Humanist | open humanist sans | readable service documents |
| Editorial | text-serif emphasis | reports and correspondence |
| Corporate Classic | formal serif-and-sans balance | traditional business records |
| Minimal Mono | restrained monospace geometry | operational and technical artifacts |
| Brutalist | high-contrast geometric treatment | deliberate, direct internal artifacts |

## Continue by job

- [Browse bounded previews](../assets/rendro/configurator/index.html) in the
  static configurator, then copy the requested selection's canonical snippet.
  A catalog preview is bounded evidence: it is not complete-document or
  universal-viewer proof, and a representative accent preview is disclosed as
  representative rather than your requested accent.
- Generate an application-owned module with `mix rendro.gen.theme`, then use
  `--check` to keep the committed source from drifting.
- [Try a rendered invoice](livebook/first_invoice.livemd) to execute, inspect,
  and download real bytes in Livebook.
- See [Theming](theming.md) for manual tokens and `from_brand/2`, or
  [API Stability and Support Boundaries](api_stability.md) for the support
  contract.

Deterministic bytes, bounded catalog previews, human quality dispositions, and
documentation claims are separate evidence levels. A valid snippet vocabulary
or a page-one raster does not establish broad visual, accessibility, PDF/UA,
WCAG, print-safety, or universal-viewer guarantees.
