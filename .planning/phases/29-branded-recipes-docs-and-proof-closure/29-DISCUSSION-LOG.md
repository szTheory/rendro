# Phase 29: Branded Recipes, Docs, and Proof Closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered and the research that informed each lock.

**Date:** 2026-05-01
**Phase:** 29-branded-recipes-docs-and-proof-closure
**Areas discussed:** Branded recipe shape, Asset sourcing, Phoenix demo scope, Docs-contract surface
**Mode:** Research-first one-shot recommendation set (per saved feedback memory). The user requested deep parallel-subagent research per area, then a single coherent locked recommendation per area. No interactive Q&A on alternatives — locks are written into CONTEXT.md and the user retains override authority.

---

## Pre-locked carry-forward (no discussion needed)

These decisions were inherited from prior phases or methodology and not re-asked:

- Tiered Composition (`document/2`, `page_template/1`, `sections/2`) preserved verbatim from Phase 22.
- No system-font discovery, no remote fetching, no ambient OS state (Phase 26 D-04).
- Path-or-binary sourcing for fonts and assets; eagerly normalized at registration (Phase 26 D-02/D-03).
- Determinism contract = structural assertions on font dictionary + image XObject + measurement parity. NOT whole-file byte identity as a public contract (Phase 26 D-15/D-16).
- Pure-core boundary preserved (no Phoenix/Plug hard dependency in core).
- Coherent recommendation set per `.planning/METHODOLOGY.md`.
- v1.3 release blockers captured in `Phase 999.1` notes + a "Pending v1.3 work" section in the eventual `29-VERIFICATION.md` (no new top-level checklist file).

---

## Branded recipe shape

| Option | Description | Selected |
|--------|-------------|----------|
| 1. New `Rendro.Recipes.BrandedInvoice` (sibling) | Sibling module to `Rendro.Recipes.Invoice` mirroring Tiered Composition. Cleanest separation, escape-hatch promise demonstrated. | ✓ |
| 2. Extend `Rendro.Recipes.Invoice` with `brand:` opts | Single recipe with optional brand options; conditional code paths. | |
| 3. Ship a different doc-type recipe (Statement, Certificate) | Branded by default; v1.2 ships TWO canonical recipes. | |

**Decision:** Option 1 (sibling `Rendro.Recipes.BrandedInvoice`).
**Research basis:** Bamboo/Swoosh "one module per templated artifact" idiom; React-PDF/PDFKit composition-over-configuration; Typst import-not-parameter-overload; Prawn's stateful-cursor footgun (avoided); ReportLab's "one giant config object" footgun (avoided); ChromicPDF narrow-public-contract precedent.
**Rationale (≤120 words):** Phase 29 must prove the branded surface (LAY-13/QUAL-07) without re-opening the canonical invoice contract that v1.1 already shipped. A sibling `BrandedInvoice` module preserves Phase 22's Tiered Composition verbatim, keeps `Rendro.Recipes.Invoice` a stable doc-locked example for unbranded paths, and gives v1.3 Hex release a second comparable recipe demonstrating fonts (Phase 26) and assets (Phase 28) cooperating. Option 2 forces conditional branches inside one recipe and silently widens the canonical example's contract, violating "Truthful Small Contracts." Option 3 ships a brand-new doc type before the branding pattern itself is proven.

---

## Asset sourcing (font + logo bytes)

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Commit small open-licensed font + tiny PNG to library `priv/branded/` | Self-contained, runnable everywhere, hex-shipped. | ✓ |
| 2. Reuse `test/support/font_fixture.ex` host-path discovery | Host-system path lookup; works for tests only. | |
| 3. Inline base64 binaries in fixtures + BYO bytes in example | No commit-size hit; ugly fixtures and stub-only Phoenix example. | |
| 4. Hybrid: commit font, generate PNG at test setup | Smaller commit; generation determinism is a liability. | |

**Decision:** Option 1.
**Concrete picks:** B612 Regular (SIL OFL 1.1, ~52 KB), single weight, `priv/branded/fonts/B612-Regular.ttf`. Logo: 64×64 RGBA PNG, hand-authored geometric mark, <2 KB compressed, committed, `priv/branded/images/rendro-logo.png`. Helper module: `Rendro.Branded.font_path/0`, `Rendro.Branded.logo_path/0` resolving via `Application.app_dir(:rendro, "priv/...")`. New top-level `NOTICE` file with verbatim OFL attribution.
**Research basis:** ReportLab ships small TTF inside `reportlab/fonts/` precisely so tutorials run anywhere — direct precedent. `tzdata`, `gettext`, `cldr_*` all ship binary data via `priv/`. Prawn's "we expect you to bring fonts" is the #1 friction point in its issue history — avoided. Typst/WeasyPrint rely on `fontconfig` — not viable under Rendro's D-04 posture. Hex tarball limit is 8 MB; +55 KB is unremarkable; `tzdata` ships ~1 MB.
**Rationale (≤150 words):** The branded recipe must run in four places — Phoenix example, doctests, `verified_fences` evaluation, and regression tests — without ambient OS state. D-04 explicitly forbids host-path discovery as a runtime contract; reusing `font_fixture.ex` violates that for adopters and breaks doctests on minimal CI images. Inline base64 would require ~70 KB of base64 garbage in fixtures and still leaves the Phoenix example needing real bytes. Hybrid generation is fragile and doesn't help the font, which is the bigger asset by 25×. Committing genuine bytes under `priv/` is the only option that's self-contained, works for adopters via `Application.app_dir`, mirrors how `tzdata`/`cldr_*`/`gettext` ship binary data, and holds D-02/D-03 invariants.

---

## Phoenix example demonstration scope

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Add new `/branded/*` endpoints alongside existing | Both surfaces visible; minimum diff to user perception. | ✓ |
| 2. Replace existing endpoints with the branded recipe | Cleaner narrative; loses the unbranded smoke proof. | |
| 3. Keep example unchanged; demonstrate branded only via README + guides | Smaller diff; loses the strongest adopter-facing proof. | |

**Decision:** Option 1.
**Concrete plan:** Routes — `GET /download` (unchanged), `GET /preview` (unchanged), `GET /branded/download` (new), `GET /branded/preview` (new), `GET /` (new index page chooser, hardcoded HTML in a small `PageController`). Both branded actions live on the existing `PDFController`; the `@demo_invoice` module attribute feeds both recipes. Example app calls `Rendro.Recipes.BrandedInvoice.document/1`, which resolves library `priv/branded/` via `Application.app_dir/2` internally — no asset duplication into the example.
**Research basis:** Oban demo and Phoenix LiveView examples ship a tiny index listing endpoints — copy. Bamboo example app keeps both branded and plain mailers — copy. React-PDF playground defaults to branded but loses zero-from-fresh story — avoid. Prawn ships fonts/images inside library `data/` not the example — copy (use `priv/branded/` in `:rendro`, not in `:phoenix_example`).
**Rationale (≤120 words):** Phase 29's job is to convert the new font/asset surface into an adoption-ready, truthfully-documented path — which means the demo must show the support boundary, not hide it. Replacing the unbranded path deletes the simplest "Rendro works without registering anything" proof. README-only violates Least-Surprise DX: a Phoenix adopter who runs `mix phx.server` expects to see the headline feature live. Additive route preserves both narratives, costs ~40 lines of controller/router code.

---

## Docs-contract & verification surface

| Option | Description | Selected |
|--------|-------------|----------|
| 1. `guides/branding.md` (verified) + module doctests + brief README pointer | Mirrors `guides/integrations.md` precedent; balanced surface. | ✓ |
| 2. README-only verified fences | Simpler; bloats README; no navigable guide. | |
| 3. Module `@doc` doctests only on `BrandedInvoice` | Minimal; insufficient for QUAL-07. | |
| 4. `guides/branding.md` + `integrations.md` update + README pointer | Maximum surface; conflates branding with optional adapters. | |

**Decision:** Option 1.
**Concrete plan:** New ExDoc extra `guides/branding.md` (added to `mix.exs` `extras:`) with five sections (Overview, Registering brand fonts, Registering logo assets, BrandedInvoice tiered composition, Failure diagnostics). Four verified `elixir` fences with IDs `branding-register-assets`, `branding-tiered-document`, `branding-tiered-template`, `branding-missing-asset-diagnostic`. One optional `elixir-schematic` (compile-only) fence for app-scaffolding pattern. Three module doctests on `Rendro.Recipes.BrandedInvoice` (`page_template/1`, `sections/2`, `document/2`). README adds a ≤2-sentence "Branded Documents" pointer subsection between Tiered Composition and Phoenix integration. Two new test files: `test/docs_contract/branding_contract_test.exs` and `test/docs_contract/branding_claims_test.exs`. New regression test file `test/rendro/recipes/branded_invoice_test.exs`. Diagnostic fence asserts structurally on `%Rendro.Error{reason: ...}` field shape, NOT message strings.
**Research basis:** Phoenix splits README (intro) from `guides/` (how-tos) — copy. Ecto README-as-orientation discipline — copy. Oban heavy `@moduledoc` doctests + `extras:` guides — copy doctest density. NimbleOptions extreme of "tiny README + exhaustive @moduledoc" — avoid; need narrative landing for branding. Prawn's separately-generated `manual/` — avoid tooling cost; ExDoc + verified fences gives same property natively.
**Rationale (≤120 words):** `guides/integrations.md` is the locked precedent for a "verified narrative guide that ships on hex.pm." Branding is the same shape: app-spanning setup + recipe entry point + diagnostics. The README is already substantial and overloading it with branded examples violates README-hygiene principles Phoenix and Ecto follow. Module doctests guarantee the public API stays callable; the verified guide guarantees the narrative stays truthful. Four fences match the integrations cardinality — proven sustainable. Option 4 conflates branding with optional adapters and doubles maintenance.

---

## Claude's Discretion

The following are explicitly delegated for downstream agents to decide during planning/execution:

- Internal module split between `Rendro.Branded` (path resolver) and any private branded-recipe helpers.
- Exact field names inside the `data.brand` map (`:font_name` vs `:brand_font` vs `:font` etc.).
- Exact bytes of the hand-authored 64×64 PNG logo (deterministic and committed; aesthetic is the agent's call within byte budget).
- Whether the `scripts/render_logo.exs` generator ships or is omitted.
- Internal organization of `guides/branding.md` subsections beyond the five named.
- Whether the chooser index page embeds a one-line "what is Rendro" header above the route list.
- Telemetry/diagnostic field naming consistent with existing surfaces.

## Deferred Ideas

Captured in CONTEXT.md `<deferred>` section for explicit out-of-scope status:

- Second branded canonical recipe for a different doc type (Statement, Certificate, Report) — v1.3+.
- Bold/italic variants of the brand font.
- Auto-registering a default brand font/logo on `Rendro.Document.new/0` (explicitly rejected — D-11).
- Runtime/test-setup PNG generation pipeline.
- Validator-backed PDF/A or signature claims for branded artifacts (v1.5+).
- Whole-file byte-identity public guarantee for branded PDFs.
- Live LiveView playground for the Phoenix demo.
- `usage_rules.md` artifact — captured as a v1.3 release-readiness blocker, not implemented here.
