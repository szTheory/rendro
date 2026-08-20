---
phase: 130
slug: catalog-quality-evidence-ratchet
status: approved
shadcn_initialized: false
preset: none
created: 2026-08-19
reviewed_at: 2026-08-19
---

# Phase 130 — UI Design Contract

> Visual and interaction contract for the generated catalog documents and their pinned-raster human-review surface. This phase adds no interactive product UI.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — pure Elixir generated PDF/catalog artifacts and existing review records |
| Preset | not applicable; reuse the six shipped supplied-theme presets |
| Component library | none |
| Icon library | none |
| Document theme source | existing `Rendro.Theme` semantic roles (`ink`, `muted`, `background`, `surface`, `rule`, accent) and existing recipe typography |
| Brand/supporting-review source | living `brand/tokens/tokens.json` and `brand/copy/VOICE.md`; do not copy or fork tokens |

The project is not React, Next.js, or Vite; `components.json` and shadcn are not applicable. Do not add a recipe, preset, catalog cell, public API, dependency, or a catalog-only semantic styling path. Unthemed output remains byte-identical. The catalog may retain `catalog_layout: true` only for already-demonstrated fixture-capacity geometry; all hierarchy, typography, semantic ink, rules, labels, and colour behavior must appear through the ordinary supplied-theme recipe path.

## Evidence Boundary

- The generated document page is the consumer-facing visual surface. The pinned raster is an advisory inspection aid, not a separate, improved rendering.
- Preserve the fixed 32-cell catalog and current page geometries: Certificate remains landscape, Ticket remains native A6, and the established pagination model remains in force.
- Required deterministic artifact/schema/hash/coverage checks are merge authority. Pinned-PDFium output and human review are bounded advisory evidence. Neither lane substitutes for the other.
- A quality label must be derived from the current catalog ID, current PNG hash, current complete source-PDF hash, and current recorded evidence. A changed, unavailable, mismatched, or stale artifact is a stop condition—not a pass, zero, or inferred result.
- Dark catalog output is screen-oriented and retains `print_safety: false`. Do not describe any dark cell as print-safe or make WCAG, PDF/UA, accessibility, universal-viewer, or universal-design claims.

---

## Spacing Scale

Use the existing theme/recipe measurements for PDFs; this contract declares no new point values. For any phase-owned human-review text/record formatting, consume the existing brand 4px scale below rather than creating local values.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline evidence-label and hash-fragment gaps |
| sm | 8px | Related metadata or label/value spacing |
| md | 16px | Default review-record grouping |
| lg | 24px | Separation between a light/dark family pair and its evidence |
| xl | 32px | Separation between family pairs |
| 2xl | 48px | Major review-record sections |
| 3xl | 64px | Page-level supporting-document separation |

Exceptions: document geometry and spacing remain recipe-owned and may change only by the existing supplied-theme seam or the explicitly demonstrated catalog-capacity geometry. Do not impose web-pixel measurements on PDF layouts.

---

## Typography

The PDF type scale remains the existing supplied-theme recipe typography; do not introduce a new global type scale or font. The following existing living-brand scale is only for phase-owned review/evidence text, where it is needed; it is not a new PDF token contract.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Evidence/body | `body` — 16px | 400 | 26px |
| Evidence label | `body-s` — 14px | 400 | 22px |
| Review section heading | `h3` — 22px | 600 | 30px |
| Review title | `h2` — 28px | 600 | 36px |

Use only weights 400 and 600 in phase-owned review materials. Use the existing mono family for catalog IDs, hashes, renderer version/SHA, and exact artifact paths; never abbreviate an identity so far that it cannot be verified from the record.

### PDF hierarchy rules

Every repaired document has exactly one dominant fact or tightly bound fact-group. Typography establishes rank; proximity, whitespace, rules, and a restrained surface may clarify it. Colour may reinforce hierarchy but must never be the sole cue. Preserve equivalent hierarchy rank and geometry between light and dark siblings while allowing the supplied theme to materialize mode-appropriate semantic values.

| Family / exact cell pair | Required visual reading order |
|--------------------------|-------------------------------|
| Corporate-Classic Invoice | `Total Due` is unambiguously dominant; the due date is adjacent and subordinate. Keep the formal subtotal/tax/total arithmetic ladder. |
| Minimal-Mono Statement | Preserve the austere full-width closing-balance band. The mono closing amount is the isolated focal fact through measured whitespace and rule contrast; do not turn it into a card/dashboard. |
| Humanist Receipt | `Total` is the sole display-scale fact. Separate the arithmetic ladder from itemization with a quiet rule/whitespace break; do not add a large narrow-receipt panel. |
| Editorial Certificate | Recipient is the largest ceremonial fact; credential is nearby and clearly second; issuer, body, and signatory remain quiet. Use centred whitespace and editorial typography, not business-form bands or cards. |
| Swiss Payslip | `Net Pay` is a sharp grid-aligned summary band with dominant atomic amount and subordinate label, followed by denser earnings/deductions reconciliation tables. Preserve right alignment and indivisible money values. |
| Brutalist Ticket | The placement grid is the bounded visual anchor through scale plus hard-edged grouping/rule. Event title is secondary; the complete reference is compact, legible, and subordinate. |

### Humanist dark Receipt treatment

- Preserve the warm-neutral dark page. Do not lighten the whole page/table surface to hide a semantic foreground failure.
- Table headers, descriptions, and amounts use materialized semantic `ink`; page number and genuinely secondary labels use semantic `muted`. Measurement and render paths must use the same styles.
- Enclose the subtotal/tax/total sequence in one restrained semantic `surface` + `rule` treatment. It reads as warm paper translated to dark mode, never as a rounded SaaS card; `Total` remains the only display-scale element.
- The Poppy & Grain accent is decorative or restrained emphasis only, never routine or essential foreground text.

---

## Color

PDF values are supplied by the selected existing theme/preset. Reuse semantic roles; do not introduce a fixed hex palette, a new theme role, or per-catalog-ID colour branch.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (about 60%) | supplied-theme `background` | Page field / largest quiet surface |
| Secondary (about 30%) | supplied-theme `surface` and `rule` | Boundaries, restrained arithmetic treatment, and genre-appropriate grouping |
| Accent (at most 10%) | existing supplied-theme accent | Existing recipe emphasis only; never the only hierarchy cue or routine body text |
| Destructive | not applicable | No destructive action or consumer-facing destructive control is introduced |

For supporting review records, inherit `brand/tokens/tokens.json` semantic light/dark values rather than re-specifying them. Treat the recorded contrast pairs as a screen-legibility design lens: essential foreground/background pairings, grayscale resilience, and full-size readability must be inspected. This is not a compliance claim.

Accent reserved for: the existing recipe’s non-essential emphasis and already-established genre treatment. It must not recolour review status, replace semantic `ink`/`muted`, or convey a verdict by colour alone.

---

## Review Flow and Interaction Contract

- Make no consumer-facing control, CTA, form, loading state, animation, or reviewer product. Generated pages are static. Reduced motion is therefore not applicable.
- After each family pair repair, show only the focused deterministic and semantic engineering checkpoint. Its role is diagnostic; it cannot update a disposition, `rubric_scores.json`, `SIGN-OFF.md`, a `passed` value, or a public quality projection.
- When all six pairs stabilize, regenerate the complete ordered 32-cell catalog exactly once and check all deterministic artifacts. Any mechanically changed unscored cell requires an explicit current hash/reason rebind without scoring or mass-blessing it.
- The final advisory payload contains exactly the twelve page-one full-size pinned raster images in this order: Corporate-Classic Invoice light/dark; Minimal-Mono Statement light/dark; Humanist Receipt light/dark; Editorial Certificate light/dark; Swiss Payslip light/dark; Brutalist Ticket light/dark. A contact sheet may index the set but never replaces full-size sequential inspection.
- Each inspected pair presents or records the catalog ID, light/dark mode, pinned renderer version/SHA, PNG hash, and complete source-PDF hash. Reviewers record observed dimension scores and concise bounded justifications for that artifact—never an expected verdict.
- A light record may project `passes` only when current evidence satisfies the unchanged arithmetic: `content_hierarchy == 5`, every other core dimension `>= 4`, both gates true, hashes current, and signer/date plus concrete `supersedes_evidence_ref` and `resolution_ref` are present. Any miss remains `needs_work`.
- All dark records retain `needs_work` under the unchanged `print_safety: false` boundary, even when on-screen hierarchy or craft improves. Humanist dark Receipt improvement is a success only as truthful evidence, not automatic promotion.
- Stop fail-closed on missing/changed pairs, hash drift, deterministic contract failure, unavailable/mismatched pinned renderer, stale disposition, or missed threshold. Repair and regenerate only the affected checkpoint/payload.

---

## Copywriting Contract

Use concise, operational copy in the living brand voice. Evidence language describes what was observed and what authority it has; it must not expose implementation details to document readers or imply a consumer-facing backend.

| Element | Copy |
|---------|------|
| Primary CTA | Not applicable — no consumer-facing interactive surface is introduced. |
| Engineering checkpoint label | `Engineering checkpoint — not a human-quality disposition.` |
| Candidate state label | `Candidate catalog state — deterministic checks passed; advisory review pending.` |
| Final review instruction | `Final human review — inspect this exact light/dark pair; record observed evidence, not an assumed pass.` |
| Current-identity label | `Disposition bound to current artifact identity.` |
| Needs-work state | `Scored — needs work` — retain when any threshold, gate, or current-evidence requirement is unmet. |
| Evidence unavailable/failure state | `Current review evidence is unavailable or does not match this artifact. Do not promote this cell; rerun the affected evidence checkpoint.` |
| Dark boundary disclosure | Use the catalog cell’s exact `boundary_disclosure` verbatim; retain its screen-oriented/non-print-safe scope without expanding it into accessibility or compliance claims. |
| Destructive confirmation | None — Phase 130 creates no destructive UI action or persisted user interaction. |

---

## UI Considerations

Probe-confirmed elements (authored kind overrides, because prose cue matching is intentionally lossy):

- E1 Generated catalog page: `static-content`
- E2 Pinned full-size raster review sequence: `media`, `static-content`
- E3 Hash-bound disposition/evidence record: `static-content`

Applicable state considerations resolved: 10 covered, 0 backstop, 0 unresolved.

| Element | Category | Status | Resolution / Reason |
|---------|----------|--------|---------------------|
| E1 | overflow | ✅ covered | Preserve recipe-owned page geometry, pagination, Certificate landscape, Ticket A6, atomic money, and full text/reference integrity; do not crop, truncate, or replace overlong content with an ellipsis. |
| E1 | long-text | ✅ covered | Long business content follows the existing recipe/pagination behavior. Complete Ticket reference and monetary values remain legible, whole, and semantically subordinate where specified. |
| E2 | empty | ✅ covered | An absent image or incomplete twelve-image set stops final review fail-closed; the evidence-failure copy above is emitted and no disposition is promoted. |
| E2 | loading | ✅ covered | There is no asynchronous review UI: final review begins only after the complete pinned-renderer payload and identity manifest exist, so a partially generated payload is never presented as reviewable. |
| E2 | error | ✅ covered | Missing, changed, stale, renderer-unavailable, or renderer-mismatched raster evidence emits the evidence-failure state, stops the review flow, and retains the non-promoted disposition. |
| E2 | populated | ✅ covered | Final advisory review is exactly twelve full-size, sequential page-one raster images in canonical light-then-dark family order; a contact sheet is index-only. |
| E2 | overflow | ✅ covered | Full-size inspection is required; scaled contact sheets cannot stand in for the review surface. |
| E2 | long-text | ✅ covered | Catalog IDs, renderer version/SHA, PNG hashes, complete source-PDF hashes, review justifications, and boundary disclosures remain complete beside or directly traceable from each full-size image. |
| E3 | overflow | ✅ covered | Evidence records wrap or expand without clipping fields; canonical identifiers and scope-limiting disclosures remain machine- and human-readable. |
| E3 | long-text | ✅ covered | IDs, hashes, renderer identity, justifications, and boundary disclosures remain complete and attributable; never truncate a scope-limiting statement or hash identity into ambiguity. |

Form, navigation, and interactive-control states are not applicable: this phase introduces no asynchronously loaded product UI, form, or control. Media absence, incomplete generation, and evidence errors are handled explicitly above rather than being dismissed as non-interactive.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable — no shadcn, third-party registry, frontend component, or external block is introduced; reviewed 2026-08-19 |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-08-19; 6/6 dimensions passed with no recommendations.
