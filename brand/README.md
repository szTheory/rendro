# Rendro brand kit

Everything that defines how Rendro looks and sounds. Self-contained, source-controllable, and
**excluded from the published Hex package** (this folder is not in `mix.exs` `:files`), so brand
assets live in git without shipping in the library tarball.

> **Start here:** open [`index.html`](index.html) in a browser — the full brand book, offline,
> light/dark with your OS.

## Contents

| Path | What |
|------|------|
| [`index.html`](index.html) | The brand book — logo, color, type, components, voice, copy, in one self-contained page. |
| [`tokens/tokens.json`](tokens/tokens.json) | **Single source of truth** for all design tokens (raw + semantic + dark + states + contrast). |
| `tokens/tokens.css` | Generated CSS custom properties (`--rendro-*`), light + dark. |
| `tokens/tailwind.tokens.js` | Generated Tailwind `theme.extend` excerpt. |
| [`logo/`](logo/) | The logo system + [`logo/README.md`](logo/README.md) usage sheet. |
| [`specimens/`](specimens/) | Reusable SVG specimens: palette, typography, components, code-block, README header, social card. |
| [`copy/VOICE.md`](copy/VOICE.md) | Voice principles, tone, microcopy patterns. |
| [`copy/marketing-copy.md`](copy/marketing-copy.md) | Ready-to-paste taglines, descriptions, hero, CTAs, states. |
| [`audit/AUDIT.md`](audit/AUDIT.md) · [`audit/SCORECARD.md`](audit/SCORECARD.md) | The brand pressure-test this kit was built from. |
| `logo/options/`, `logo/lab/` | Logo exploration provenance (rejected directions, selection galleries). |

## The system in one breath

**Native PDF layout for Elixir.** A page-frame **R** (folded corner + structural seam) reading into a
geometric stencil "endro". Warm **ink/paper/blue** palette, warm-neutral dark mode. **Inter** for UI/marketing,
**JetBrains Mono** for code (both SIL OFL). Voice: a senior maintainer who explains the failure and never claims magic.

## Regenerating tokens

`tokens.css` and `tailwind.tokens.js` are generated. Edit only `tokens/tokens.json`, then:

```sh
mix brand.gen          # rewrite tokens.css + tailwind.tokens.js
mix brand.gen --check  # CI/QA: fail if committed outputs are stale
```

## Rules

- **Text-only folder.** SVG / JSON / CSS / JS / Markdown / HTML. No font or raster binaries — they're
  blocked by `.gitignore`. If a raster (PNG OG image, etc.) is ever needed, generate it on demand from the SVG; don't commit it.
- **Fonts** are referenced by name with a system fallback; nothing is embedded. The brand book works offline.
- **Logo** letterforms are geometric vector paths (no font dependency); only the tagline in `rendro-subtitle.svg` uses live text.

## Open item

The name collides with a commercial PDF SDK ("CHILI rendro") and an existing `rendro` GitHub/NPM user.
**Trademark clearance is a human/legal decision** and is not resolved here — see `audit/AUDIT.md` §4 (C1).
