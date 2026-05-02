# Roadmap: Rendro

## Overview

Rendro has shipped two verified milestones. `v1.0` proved the pure-core rendering and trust contract; `v1.1` shipped the layout-authoring maturity needed for serious document composition. The active milestone is now `v1.2`, which turns that authoring base into a truthful branded-document surface through deterministic typography, assets, and honest Unicode/i18n boundaries. If `v1.2` closes cleanly, the next milestone should promote first public Hex release readiness ahead of async artifact expansion.

## Active Milestone

### Milestone v1.2: Deterministic Typography, Assets, and Honest I18n Baseline

**Status:** Active
**Planned Phases:** 25-30

`v1.2` should make Rendro capable of producing branded, customer-facing PDFs without weakening the deterministic layout contract. The milestone is intentionally about capability truth, not broad internationalization claims or release mechanics.

#### Phase 25: Font Registry and Public Typography Contract
**Goal**: Establish the document-level font registry, logical font selection API, and pure-core contract that later font work depends on.
**Depends on**: Phase 24
**Requirements**: [FONT-01]

Planned work:

- Define document-level font registration and logical naming surfaces.
- Route authored text/component font references through the registry instead of implicit writer defaults.
- Keep public APIs independent from PDF object internals and preserve pure-core boundaries.

#### Phase 26: Deterministic Font Metrics and PDF Embedding
**Goal**: Make resolved font selection drive both measurement/pagination and final PDF embedding deterministically.
**Depends on**: Phase 25
**Requirements**: [FONT-02, FONT-03]
**Progress**: 3/3 plans complete (`26-01-SUMMARY.md`, `26-02-SUMMARY.md`, `26-03-SUMMARY.md`)

Planned work:

- Teach measurement to use resolved font metrics instead of a single hard-coded built-in font.
- Add supported custom-font embedding through the writer/render path.
- Lock deterministic pagination and PDF output behavior with focused regression coverage.

#### Phase 27: Fallback Chains and Honest I18n Diagnostics
**Goal**: Turn typography support boundaries into explicit product behavior instead of implied best effort.
**Depends on**: Phase 26
**Requirements**: [FONT-04, I18N-01, I18N-02]

**Plans:** 3 plans

Plans:
- [ ] 27-01-PLAN.md — Introduce font fallback chain registration and I18n script analysis capabilities.
- [ ] 27-02-PLAN.md — Apply fallback chains during text measurement, breaking text into font-specific runs and collecting honest i18n diagnostics.
- [ ] 27-03-PLAN.md — Update the PDF Writer to output multi-font text runs and establish the end-to-end verification of the honest I18n matrix.

#### Phase 28: Asset Registry and Deterministic Image Rendering
**Goal**: Add first-class bounded asset support for logos and document imagery without introducing runtime fetch policy into core.
**Depends on**: Phase 27
**Requirements**: [ASSET-01, ASSET-02, ASSET-03]
**Progress**: 3/3 plans complete (`28-01-SUMMARY.md`, `28-02-SUMMARY.md`, `28-03-SUMMARY.md`)

Planned work:

- Introduce first-class asset registration for local or in-memory assets.
- Render bounded images/logos deterministically inside existing layout primitives.
- Fail unsupported references, formats, or invalid sizing through typed validation or diagnostics.

#### Phase 29: Branded Recipes, Docs, and Proof Closure
**Goal**: Convert the new font/asset surface into an adoption-ready, truthfully documented branded document path.
**Depends on**: Phase 28
**Requirements**: [LAY-13, QUAL-07]

Planned work:

- Add a branded canonical recipe/example that uses registered fonts and logo assets.
- Extend docs-contract, regression, and example-proof coverage around the public support surface.
- Capture the remaining first-public-release blockers so `v1.3` can focus on publishability rather than re-deriving scope.

Gap-closure plans (added during 2026-05-01 visual UAT):

- [ ] 29-08-header-wrap-gap-fix-PLAN.md — Close UAT Gap 2 by widening the branded invoice header block (B612 Regular at size 18) so the invoice id stays on a single line. Logo gap (Gap 1) deferred to Phase 30.

#### Phase 30: Visually Correct PNG Image Rendering
**Goal**: Make registered PNG image assets actually render visibly on the page so the asset surface delivered in `v1.2` is truthful, not just structurally present.
**Depends on**: Phase 29
**Requirements**: [ASSET-04]

Planned work:

- Replace the current `build_image_objects` path in `lib/rendro/pdf/writer.ex` so PNG XObject streams contain valid `/FlateDecode` payloads (decoded RGB samples, or IDAT pass-through with explicit `/DecodeParms /Predictor 15 /Colors N /BitsPerComponent 8 /Columns W`).
- Honor PNG color types correctly: RGB → `/DeviceRGB`; RGBA → `/DeviceRGB` + `/SMask`; Gray/Gray+α → `/DeviceGray` (+ `/SMask`); Indexed → `/Indexed [/DeviceRGB N <palette>]`.
- Add a rasterize-and-decode regression class (e.g. via `pdftoppm` + targeted pixel sampling) so the existing structural/byte-substring tests are paired with at least one test that proves the image actually paints. This closes the test-class blind spot that allowed the bug to ship through phases 28 and 29.
- Re-run the phase 29 visual UAT (`mix rendro.visual_uat 29`) and confirm the branded preview now passes the logo criterion before closing.

**Source**: Surfaced 2026-05-01 during Phase 29 visual UAT (Claude vision verdict on `29-branded-preview.png`). See [`.planning/phases/29-branded-recipes-docs-and-proof-closure/29-HUMAN-UAT.md`](/Users/jon/projects/rendro/.planning/phases/29-branded-recipes-docs-and-proof-closure/29-HUMAN-UAT.md) Gap 1 for the full root cause and fix direction.

## Milestones

- <details><summary><b>Milestone v1.2</b> (Planned)</summary>
  Deterministic typography, assets, and honest Unicode/i18n boundaries for branded business documents. Planned phases: 25-30.
  </details>

- <details><summary><b>Milestone v1.0</b> (Shipped 2026-04-28)</summary>
  MVP delivered. Core pure rendering, layout primitives, Phoenix adapters, rigorous CI verification.
  See [.planning/milestones/v1.0-ROADMAP.md](/Users/jon/projects/rendro/.planning/milestones/v1.0-ROADMAP.md) for full phase details.
  </details>
- <details><summary><b>Milestone v1.1</b> (Shipped 2026-04-30)</summary>
  Layout authoring maturity delivered: explicit page templates and regions, deterministic wrapped text and keep/break semantics, stronger table continuation, public diagnostics/proof surfaces, and canonical recipes.
  See [.planning/milestones/v1.1-ROADMAP.md](/Users/jon/projects/rendro/.planning/milestones/v1.1-ROADMAP.md) for full phase details.
  </details>

## Next Milestones

- **Milestone v1.3: First Public Hex Release Readiness** — Promote `Phase 999.1` into active milestone scope after `v1.2` proves the branded-document support boundary.
- **Milestone v1.4: Async Delivery and Artifact Operations** — Add queued render lifecycle, artifact metadata, and persistence/sink contracts after the public release boundary is defined.
- **Milestone v1.5: Validation and Trust Surfaces** — Add validator-backed support evidence and stronger machine-readable trust/reporting surfaces.

## Backlog

### Phase 999.1: First Hex Release Readiness (BACKLOG)
**Goal**: Decide whether Rendro is ready for a truthful first public Hex.pm release and close the remaining packaging, proof, and support-boundary work required to publish.
**Source**: `SEED-001`
**Deferred at**: 2026-04-30 during `v1.1` milestone-close preflight
**Notes**:
- Existing release preflight coverage already exercises `mix hex.build --unpack` and `mix hex.publish --dry-run --yes`.
- This is now the intended `v1.3` milestone theme if `v1.2` closes truthfully.

**v1.3 readiness blockers** (captured during Phase 29 closure):
- `mix.exs` `:licenses` is `["UNLICENSED"]`; pick an SPDX-valid value and ship a matching top-level `LICENSE` file.
- Hex package metadata audit: `:description`, `:source_url`, `:links`, and maintainer-facing release copy.
- README badge state for CI, Hex.pm, and HexDocs.
- ExDoc `groups_for_extras` decision now that the guide count exceeds two.
- `usage_rules.md` artifact decision for first public release support boundaries.
- Public API stability scan and deprecation-policy document before publication.
- `mix hex.publish --dry-run` preflight remains part of the release proof path.
