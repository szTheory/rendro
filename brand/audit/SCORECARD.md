# Rendro Brand Book — Scorecard

**Phase 101 · GSD milestone B1 · 2026-06-14**
Companion to `AUDIT.md`. Scores are 1–10 (10 = production-ready, no further work needed). Honest, not flattering.

---

## 15-dimension scorecard

| Dimension | Score | Why | Risk | Recommended fix |
|---|:--:|---|---|---|
| Distinctiveness | 7 | Strong *strategic* position (warm ink/paper, "explain the failure", anti-Chrome) genuinely differs from devtool-neon norm. | Distinctiveness lives in prose; no visual artifact proves it yet. Generic wordmark advice could flatten it. | Land the integrated typemark; let the mark carry the distinctiveness words currently carry. |
| Developer credibility | 9 | Voice, error pattern, honesty block, "production is a feature" all read as a real senior maintainer. Matches the shipped README. | Slight over-reach into admin/UI surfaces not yet shipped. | Keep voice verbatim; label speculative UI as future. |
| Elixir ecosystem fit | 9 | Phoenix-first, Hex/HexDocs/ExDoc-aware, telemetry/Oban language, OFL fonts, idiomatic naming. | `rendro-dev` org + v0.1 framing are stale vs shipped `szTheory/rendro` v1.0.0. | Reconcile naming/version/org to reality. |
| Visual coherence | 6 | Palette + type + grid + radius + metaphor cohere on paper. | Untested across real surfaces; dark mode undefined; purple badge contradicts palette. | Build specimens; define dark; fix badge. |
| **Logo readiness** | **2** | Four concepts, no asset. Wordmark guidance is generic and conflicts with user's hard constraints. | **Gating blocker** for ~8 visual surfaces and Phases 103/104. | Produce integrated typemark per constraints (no box, motif in letterforms, tight, no subtitle). |
| Color-system readiness | 7 | Complete primitive palette, ratios, role split, CSS vars, named pairings. | No semantic/state/dark layer; contrast asserted not computed. | Add semantic+state+dark tokens; verify contrast. |
| Typography readiness | 9 | Inter + JetBrains Mono + Noto, full weights, complete scale w/ line-heights, clear usage rules. | No fluid/responsive scale notes; no OFL attribution boilerplate. | Add responsive ramp + license/NOTICE note. |
| **Design-token readiness** | **4** | Raw values + JSON exist. | No semantic roles, no states, no focus ring, no dark — not buildable as a real token set. | Phase 102 semantic layer over primitives. |
| UI component readiness | 5 | Buttons/callouts/code-block/document-preview described in prose with colors. | Prose, not specs; no states/sizes/focus; targets surfaces not shipped. | Spec only the components B1 needs; defer admin UI. |
| Docs/README usefulness | 9 | Docs structure, guide template, recipe names, docs-voice verbs are excellent and already in use. | Minor drift from shipped README structure (recipes/contracts). | Light reconcile; otherwise keep. |
| Marketing usefulness | 8 | Strong taglines, landing sections, hero spec, launch/limitations copy, LLM context block. | Hero visual + comparison surface need the (missing) logo and specimens. | Pair with logo/specimens; keep copy. |
| Voice/microcopy usefulness | 9 | Best section in the book: concrete, anti-hype, executable; CTAs, status, empty, error patterns all ready. | Could be over-applied to color-only callouts. | Keep; ensure non-color cues in feedback. |
| Accessibility | 5 | WCAG 2.2 AA named as the bar; some pairings pre-screened; "avoid for small text" instincts good. | Contrast unverified; **no focus states/ring**; no reduced-motion; dark undefined; callouts risk color-only. | Verify ratios; add focus + reduced-motion + non-color cues. |
| Repo/source-control readiness | 6 | README/badges/structure strong; mix.exs mature (CI, dialyzer, docs-contract). | Org strategy unresolved (personal namespace vs recommended org); purple badge; no brand-asset dir convention. | Decide org; rebrand badge; add `brand/` asset conventions. |
| Long-term maintainability | 8 | Token JSON, LLM context block, ratios, and clear rules make the system reproducible and AI-portable. | Speculative sections age fast; no versioning policy for the brand book itself. | Version the book; date speculative sections. |

**Composite (unweighted mean): ≈ 6.5 / 10.** Strong strategy + voice + type, dragged down by logo (2), tokens (4), accessibility/UI (5).

---

## Stress-test matrix (≥25 surfaces)

| Surface | Guidance exists? | What's missing / needed |
|---|:--:|---|
| GitHub repo header | Partial | Repo name/desc/topics covered in prose; no social header image or pinned brand visual. |
| README hero | Yes | Tagline, honesty block, first-mention rule all present and already shipped. Needs hero logo + specimen image. |
| README badges | Partial | Badge concept exists; `hex--docs-purple` badge contradicts ink/paper/blue palette — rebrand. |
| Hex.pm package page | Partial | Description + first-mention covered; **needs the Hex package icon (logo derivation)** which does not exist. |
| HexDocs page | Partial | Voice/structure excellent; **dark-mode + logo + favicon undefined**; head-tag dark CSS is ad hoc. |
| Docs sidebar | Partial | Doc structure + groups defined (mix.exs); no active/hover/focus token guidance for nav. |
| Code-block styling | Yes | `sand-200`/`ink-900` bg, JetBrains Mono, copy button, language label, no fake prompt — fully specified. |
| Terminal snippet | Yes | "No fake terminal prompt unless actual CLI" rule + status-message lexicon present. |
| API reference page | Partial | Docs voice verbs ready; no spec for type/signature styling or cross-ref state colors. |
| Landing hero | Yes | Headline, subhead, CTAs, hero visual spec, hero code snippet all present. Needs logo + rendered specimen art. |
| Feature section | Yes | Six landing sections enumerated with intent; ready for copy. |
| Comparison section | Partial | "Compare renderers" CTA + honesty stance exist; needs visual comparison-table token/styling (shipped comparison guide exists). |
| Blog post header | No | No blog/article header template, byline, or share-image guidance. |
| Release announcement | Partial | "Transparent, factual" tone + release-notes voice given; no announcement template/layout. |
| Social preview card (OG 1200×630) | No | No OG card spec, dimensions, safe-area, or text/logo composition. |
| Favicon | Partial | 16px "simplified mark" minimum named — but **no mark exists to simplify**. |
| App icon | No | No app/PWA icon spec (sizes, padding, maskable safe area). |
| Small monochrome logo | Partial | One-color need implied by "dark logo" + minimum sizes; **no actual monochrome asset or construction**. |
| Dark-mode page | No | **Critical gap.** Warm-paper brand has no defined dark behavior; only an ad-hoc head-tag CSS patch. |
| Light-mode page | Yes | Paper/sheet/ink system fully specified; this is the brand's home context. |
| Conference slide | No | No slide template, title/section layout, or projector-contrast guidance. |
| Architecture diagram | Yes | Diagram style + engineering-artifact labels (`Frame: body / Available: 420pt`) explicitly specified — a brand highlight. |
| Error / empty / success states | Yes | Four-part error pattern, empty-state copy, callout colors all specified; needs focus/non-color cue tightening. |
| Example UI component | Partial | Button/callout/preview described in prose with colors; missing states, sizes, focus-ring, real specs. |
| Mobile landing | Partial | Responsive 12-col grid + max-widths given; no mobile-specific hero/logo/nav breakpoint guidance. |
| Sticker / swag | Partial | Print min size (0.75in) given; **no mark**, no sticker-safe one-color/knockout art, no die-cut shape. |
| Conference badge / avatar (GitHub org/user) | Partial | Avatar use named in logo concepts; **no avatar-cropped mark derivation exists**. |

**Surfaces fully ready: 9. Partial: 13. Not started: 5.** The "No" cluster (dark mode, OG card, app icon, blog header, slide, conference) plus every "needs the mark" partial all trace to the same two root causes: **no logo asset** and **no dark-mode system**.

---

## Overall readiness verdict

**Rendro's brand book is a strategically excellent, voice-led, type-and-color-complete foundation that is genuinely ready to build from on text surfaces — but it is not yet shippable as a visual identity because the headline logo asset does not exist, the warm palette has no dark-mode definition, and tokens stop at raw values; close those three (Phases 102–104) and the brand goes from ~6.5 on paper to production-ready, while the CHILI/`rendro` name collision stays open as a human/legal item that no brand work can resolve.**
