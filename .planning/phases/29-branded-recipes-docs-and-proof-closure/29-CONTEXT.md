# Phase 29: Branded Recipes, Docs, and Proof Closure - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Convert the Phase 25–28 typography and asset surfaces into one truthfully-documented branded canonical recipe with end-to-end proof. Ship a sibling `Rendro.Recipes.BrandedInvoice` recipe that uses the registered-font and asset-registry contracts; back it with regression tests, a verified `guides/branding.md`, module doctests, and a runnable Phoenix endpoint; and capture remaining first-public-release blockers so v1.3 can focus on publishability rather than re-deriving scope.

This phase closes `LAY-13` (branded canonical example combining templates/regions + registered fonts + logo assets) and `QUAL-07` (typography/asset determinism via committed regression tests + docs-contract coverage + example proof). It does NOT widen into: a second non-branded recipe, font shaping, complex-script i18n claims, marketing-grade design polish, broad PDF/A or signature claims, hex publication itself, or async artifact lifecycle work.

</domain>

<decisions>
## Implementation Decisions

### Branded recipe shape
- **D-01:** Ship the branded surface as a NEW sibling module `Rendro.Recipes.BrandedInvoice` at `lib/rendro/recipes/branded_invoice.ex`. Do NOT extend `Rendro.Recipes.Invoice` with conditional `brand:` opts — that would silently widen the v1.1-locked invoice contract and violate METHODOLOGY's "Truthful Small Contracts" lens.
- **D-02:** Mirror Phase 22's Tiered Composition surface verbatim: `BrandedInvoice.document/2`, `BrandedInvoice.page_template/1`, `BrandedInvoice.sections/2`. Differences from `Invoice` live entirely inside `page_template/1` (adds a `:logo` region) and `sections/2` (uses `Rendro.image/2` for the logo and authored brand font in the header section).
- **D-03:** Add a thin delegating shortcut `Rendro.Recipes.branded_invoice/1` alongside the existing `Rendro.Recipes.invoice/1`, calling `BrandedInvoice.document/1`. Keeps discovery symmetrical with the unbranded recipe.
- **D-04:** Drive branding inputs through the recipe's `data` argument — e.g., `%{brand: %{font_name: :brand_heading, logo_name: :company_logo}, ...}`. Validate at the recipe boundary with typed errors (per METHODOLOGY "Boundary Validation First"). The recipe MUST NOT silently render an unbranded fallback when `brand` is missing or malformed; that is a hard validation failure.
- **D-05:** Reuse `Rendro.AssetRegistry` and `Rendro.FontRegistry` directly. Do NOT invent a parallel "brand config" struct — registries already own the validated payload; the recipe just authors against logical names.
- **D-06:** `Rendro.Recipes.Invoice` is frozen for Phase 29 — no edits to its public contract, doctests, or shipped behavior. Any shared helpers must be extracted into a private module rather than mutating the canonical unbranded recipe.

### Branded asset sourcing (font + logo bytes)
- **D-07:** Commit a small open-licensed font and a tiny logo PNG into the LIBRARY's `priv/branded/` so the branded recipe runs deterministically in tests, doctests, the docs-contract harness, the Phoenix example, and downstream adopter code via Hex. No host-path discovery, no inline base64 in fixtures, no test-time generation.
- **D-08:** Font: **B612 Regular** (SIL OFL 1.1, ~52 KB), single weight only. Path: `priv/branded/fonts/B612-Regular.ttf`. Bold is OUT OF SCOPE for Phase 29 — the branded invoice uses size, not weight, for header emphasis. (B612 was designed by Airbus for cockpit legibility, latin-only coverage, hinted TTF — fits the deterministic + small-package posture without CJK bloat.)
- **D-09:** Logo: **64×64 RGBA PNG**, hand-authored geometric mark, < 2 KB compressed, committed as raw bytes. Path: `priv/branded/images/rendro-logo.png`. Logo is committed (not generated at test setup) so the branded recipe never depends on a generation pipeline at runtime; an auditable `scripts/render_logo.exs` generator MAY ship alongside for regeneration provenance, but the runtime contract is "read the committed file."
- **D-10:** Expose committed paths through a small public helper module `Rendro.Branded` (e.g., `Rendro.Branded.font_path/0`, `Rendro.Branded.logo_path/0`) that resolves via `Application.app_dir(:rendro, "priv/...")`. Same call works in tests, doctests, the docs-contract harness, and downstream adopter code that depends on `:rendro` from Hex.
- **D-11:** Document `Rendro.Branded` explicitly as "demo assets for the branded recipe and getting-started examples — NOT a built-in font or default logo." The font is NOT auto-registered by the library; the recipe (or the adopter) registers it through the existing public API. This keeps the support surface honest and avoids adopters thinking they get a free default brand identity.
- **D-12:** Update `mix.exs` `package: [files: [...]]` to explicitly enumerate shipped paths INCLUDING `priv/branded/**` and a new top-level `NOTICE` file. Once `:files` is set, Hex no longer auto-includes `priv/`, so this list must be exhaustive.
- **D-13:** Add a top-level `NOTICE` file with the verbatim B612 SIL OFL 1.1 attribution. Reference NOTICE from the README's third-party-licenses section. Assert NOTICE presence and OFL header substring in a docs-contract claims test so attribution drift is detected on CI.
- **D-14:** Estimated package delta: ~+55 KB (font ~52 KB + PNG ~2 KB + NOTICE ~1 KB). Hex tarball limit is 8 MB; current package ships ~32 KB. No size or policy concern.

### Phoenix example demonstration
- **D-15:** Add NEW endpoints at `GET /branded/download` and `GET /branded/preview` alongside the existing `GET /download` and `GET /preview`. Existing endpoints stay unchanged so adopters still see the simplest "Rendro works without registering anything" smoke proof.
- **D-16:** Add a new `PageController` with an `index/2` action mapped to `GET /`. The index renders a hardcoded HTML chooser listing all four PDF endpoints with one-line captions ("Unbranded invoice — attachment", "Branded invoice with logo + custom font — inline preview", etc.). No `priv/static`, no LiveView, no template directory — keep the example app file count flat.
- **D-17:** Add `branded_download/2` and `branded_preview/2` actions on the existing `PDFController`. Each calls `Rendro.Recipes.BrandedInvoice.document(@demo_invoice)` then reuses `RendroPhoenix.render_pdf/3` and `preview_pdf/2`. The same `@demo_invoice` module attribute feeds both recipes — adopters see "same data, two recipes."
- **D-18:** The example app does NOT vendor or copy font/logo bytes. It calls `BrandedInvoice.document/2`, which resolves library `priv/branded/` via `Application.app_dir(:rendro, ...)` internally. The example's diff stays minimal and "branded recipe just works" becomes the demonstrated property.
- **D-19:** Extend `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` with two new `describe` blocks mirroring the existing structure: `GET /branded/download` returns `%PDF-` magic bytes; structural assertion that `BrandedInvoice.document/1` registered at least one font and one image on the returned `%Document{}`. Keep the source-level legacy-`Rendro.flow` check unchanged.

### Docs-contract & verification surface
- **D-20:** Create a new ExDoc extra: `guides/branding.md`. Mirror `guides/integrations.md` structure: Overview, Registering brand fonts, Registering logo assets, BrandedInvoice tiered composition, Failure diagnostics. Add `guides/branding.md` to `mix.exs` `extras:` so it ships on hex.pm.
- **D-21:** `guides/branding.md` ships exactly FOUR verified `elixir` fences (matching `guides/integrations.md` cardinality — proven sustainable):
  - `branding-register-assets` — registers font + image on a fresh `Rendro.Document.new/0`; asserts both registries reflect the registration.
  - `branding-tiered-document` — calls `BrandedInvoice.document/2` (zero-to-one path); asserts rendered PDF starts with `%PDF-` magic bytes and contains brand font + logo XObject references.
  - `branding-tiered-template` — composes via `page_template/1` + `sections/2` + `Rendro.Document.new |> add_template |> set_template |> add_section` (escape-hatch path); asserts active template name and section regions.
  - `branding-missing-asset-diagnostic` — references an unregistered logo or font from a section; asserts a typed `%Rendro.Error{}` (or equivalent diagnostic tuple) is returned with structural fields, NOT human-readable message strings.
- **D-22:** Add up to one `elixir-schematic` (compile-only, not evaluated) fence in `guides/branding.md` showing where to drop a `MyApp.Branding` setup module — same precedent `integrations.md` uses for app-specific scaffolding that must compile but not run during docs-contract.
- **D-23:** Add THREE module doctests on `Rendro.Recipes.BrandedInvoice` mirroring `Rendro.Recipes.Invoice` style: `page_template/1` returns the expected `%Rendro.PageTemplate{}` with the four expected regions (`:logo`, `:header`, `:body`, `:footer`); `sections/2` returns the expected `[%Rendro.Section{}]` with correct region mapping; `document/2` returns a `%Rendro.Document{page_template: :branded_invoice}` given minimal data + a registered font + registered image.
- **D-24:** README change is BOUNDED to a ≤2-sentence pointer subsection ("Branded Documents") between "Tiered Composition" and Phoenix integration, linking to `guides/branding.md` and naming `Rendro.Recipes.BrandedInvoice` as the entry point. Do NOT add new verified fences to the README — README stays orientation-grade, guide stays narrative+proof-grade. This honors the README hygiene precedent of Phoenix/Ecto/Oban.
- **D-25:** Add two new test files mirroring the integrations precedent:
  - `test/docs_contract/branding_contract_test.exs` — asserts the four fence IDs from D-21 exist in `guides/branding.md` and `evaluate!/2`s each.
  - `test/docs_contract/branding_claims_test.exs` — asserts README pointer text, `mix.exs` `extras:` includes `guides/branding.md`, NOTICE presence and OFL substring, and a deterministic byte-identical regression: rendering `BrandedInvoice.document(@sample)` twice produces identical PDF binaries (this is a narrow internal regression test, NOT a public byte-stability promise per Phase 26 D-15/D-16).
- **D-26:** Match `integrations_claims_test.exs` precedent: assert structurally on `%Rendro.Error{reason: ...}` field shape rather than message strings, so fence 4 (missing-asset diagnostic) does not drift as ASSET-03 / FONT-04 wording evolves.
- **D-27:** Add deterministic regression coverage for branded layout parity: run `BrandedInvoice.document(@sample)` through the full pipeline and assert page count, line breaks for the header text, image XObject inclusion, and font dictionary structure. This satisfies QUAL-07's "committed regression tests" arm without elevating whole-PDF byte identity to a public contract (Phase 26 D-15/D-16 stance preserved).

### v1.3 release-blocker capture
- **D-28:** Capture remaining first-public-release blockers in TWO places:
  1. Append a "v1.3 readiness blockers" subsection to the existing `Phase 999.1: First Hex Release Readiness (BACKLOG)` entry in `.planning/ROADMAP.md`, listing concrete items (e.g., `mix hex.publish` dry-run preflight already covered, hex.pm metadata/license fields, README badge state, `:docs` extras audit, `usage_rules.md` decision, deprecation policy doc, public-API stability scan, NOTICE file shipping).
  2. Mirror the same list as a "Pending v1.3 work" section in the eventual `29-VERIFICATION.md` once the phase verifies, so the milestone-close artifact has the blockers inline for audit.
- **D-29:** Do NOT create a separate top-level `RELEASE-CHECKLIST.md` or new docs artifact. The capture lives in existing planning surfaces only — no new schema, no new file conventions for this phase.

### Determinism & verification posture (carried forward, restated for downstream agents)
- **D-30:** Determinism contract for branded artifacts is identical to Phase 26 D-13/D-14/D-15: measurement, pagination, and writer must consume the same resolved font descriptor; structural assertions on font dictionary entries and image XObject presence are the public proof; whole-file byte identity stays a narrow internal regression tool only.
- **D-31:** No system-font discovery, no remote asset fetching, no ambient OS state — re-asserted for the branded recipe path. `priv/branded/` resolution via `Application.app_dir/2` is library-owned pure data, not host discovery.

### Claude's discretion
- Internal module split between `Rendro.Branded` (path resolver) and any private branded-recipe helpers.
- Exact field names inside the `data.brand` map (e.g., `:font_name` vs `:brand_font` vs `:font`); choose what reads best in doctests.
- Exact bytes of the hand-authored 64×64 PNG logo (must be deterministic and committed; aesthetic is the agent's call within the byte budget).
- Whether the `scripts/render_logo.exs` generator ships or is omitted — D-09 makes it optional.
- Internal organization of `guides/branding.md` subsections beyond the five named in D-20.
- Whether the `index/2` chooser page also embeds a one-line "what is Rendro" header above the route list.
- Telemetry/diagnostic field naming consistent with existing surfaces.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone, requirement, and methodology truth
- `.planning/PROJECT.md` — v1.2 milestone intent, truthful support-boundary rules, pure-core constraints.
- `.planning/REQUIREMENTS.md` — `LAY-13` and `QUAL-07` definitions, v1.3 candidate context, out-of-scope rules.
- `.planning/ROADMAP.md` — Phase 29 goal, planned work, milestone sequencing, `Phase 999.1` backlog entry.
- `.planning/STATE.md` — current execution state and accumulated decisions.
- `.planning/METHODOLOGY.md` — "Truthful Small Contracts", "Boundary Validation First", "Least Surprise DX", "Deterministic Standard Formatting" lenses; coherent recommendation-set bias.

### Prior phase contracts
- `.planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-CONTEXT.md` — Tiered Composition pattern (`document/2`, `page_template/1`, `sections/2`); pipeline builder API conventions.
- `.planning/phases/25-font-registry-and-public-typography-contract/25-RESEARCH.md` and `25-PATTERNS.md` — document-owned font registry, shared resolver pattern.
- `.planning/phases/26-deterministic-font-metrics-and-pdf-embedding/26-CONTEXT.md` — embedded-font source contract (D-02/D-03 path/binary normalization), no system-font lookup (D-04), determinism contract (D-13/D-14/D-15/D-16).
- `.planning/phases/28-asset-registry-and-deterministic-image-rendering/28-DISCUSSION-LOG.md` — asset registry shape, `Rendro.image/2` AST, fail-fast sizing.

### Public surface to mirror / preserve
- `lib/rendro/recipes.ex` and `lib/rendro/recipes/invoice.ex` — Tiered Composition reference implementation; the new `BrandedInvoice` MUST mirror this exact API shape.
- `lib/rendro/font_registry.ex` — public font registration/resolution API.
- `lib/rendro/asset_registry.ex` and `lib/rendro/image.ex` — public asset registration and AST.
- `lib/rendro/document.ex` and `lib/rendro.ex` — pipeline builder API used by the recipe.
- `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` and `lib/rendro/adapters/phoenix.ex` — Phoenix wiring to mirror for branded endpoints.
- `guides/integrations.md` — verified-guide precedent: structure, fence cardinality (4), evaluation harness pattern.
- `test/docs_contract/integrations_contract_test.exs` and `test/docs_contract/integrations_claims_test.exs` — docs-contract test harness precedent for the new `branding_contract_test.exs` and `branding_claims_test.exs`.
- `test/support/docs_contract.ex` — `verified_fences/1` and `evaluate!/2` helpers.
- `README.md` — current structure; the ≤2-sentence "Branded Documents" pointer slots between Tiered Composition and Phoenix integration sections.
- `mix.exs` — `package:` and `extras:` lists to update.

### External licensing
- B612 font SIL Open Font License 1.1 — verbatim license text must ship in the new top-level `NOTICE` file.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Recipes.Invoice` (`lib/rendro/recipes/invoice.ex`): structural template for `BrandedInvoice` — function signatures, `@spec` shape, doctest style, private-builder layout. Copy the file as the starting scaffold; mutate the body, keep the surface.
- `Rendro.Recipes` (`lib/rendro/recipes.ex`): convention for top-level shortcut delegates (`Rendro.Recipes.invoice/1` → `Rendro.Recipes.Invoice.document/1`); add `branded_invoice/1` here.
- `Rendro.FontRegistry` (`lib/rendro/font_registry.ex`): public registration and resolution; `BrandedInvoice` registers brand font through this, no parallel store.
- `Rendro.AssetRegistry` (`lib/rendro/asset_registry.ex`): public image registration with intrinsic-bounds extraction; `BrandedInvoice` registers logo through this, no parallel store.
- `Rendro.Document` (`lib/rendro/document.ex`) builder API: `new/0`, `add_template/2`, `set_template/2`, `add_section/2`, `register_font/3`, `register_image/3`. Branded recipe composes through these only.
- `Rendro.image/2`, `Rendro.text/2`, `Rendro.block/1`, `Rendro.section/1`, `Rendro.region/1`, `Rendro.page_template/1`, `Rendro.table/2`: public authoring helpers — branded recipe authors content through these without touching internals.
- `Rendro.Adapters.Phoenix` (`lib/rendro/adapters/phoenix.ex`): `render_pdf/3` and `preview_pdf/2` — example controller reuses these for branded endpoints.
- `test/support/docs_contract.ex` (`Rendro.Test.DocsContract`): `verified_fences/1` and `evaluate!/2` — `branding_contract_test.exs` consumes these the same way `integrations_contract_test.exs` does.
- `test/support/font_fixture.ex`: NOT REUSED for the branded recipe path — that helper is host-discovery and contradicts D-31 when applied beyond test-only contexts. Branded recipe uses `Rendro.Branded.font_path/0`.

### Established Patterns
- One module per templated artifact (`Rendro.Recipes.Invoice`, soon `Rendro.Recipes.BrandedInvoice`) — same idiom Phoenix Bamboo/Swoosh use for email templates. Each module owns a small truthful contract.
- Tiered Composition (`document/2`, `page_template/1`, `sections/2`) is locked since Phase 22 — replicate exactly.
- Builder-API composition (`Rendro.Document.new |> add_template |> set_template |> add_section`) is the canonical pipeline shape for advanced/escape-hatch usage; document this in fence 3.
- Verified fences in `guides/*.md` carry an `id` declared inside the fence body and pass through `Rendro.Test.DocsContract.evaluate!/2`.
- Public APIs talk in logical font/asset names (atoms); writer-level resource allocation stays private.
- Invalid explicit references fail fast with typed errors; no silent fallback.
- Library binary data ships in `priv/` and is resolved via `Application.app_dir(:app, "priv/...")` — established Elixir convention used by `tzdata`, `gettext`, `cldr_*`.

### Integration Points
- New file `lib/rendro/recipes/branded_invoice.ex` — sibling of `invoice.ex`.
- New file `lib/rendro/branded.ex` — small public helper for committed asset path resolution.
- New shortcut delegate added to `lib/rendro/recipes.ex` (`branded_invoice/1`).
- New file `guides/branding.md` — added to `mix.exs` `extras:`.
- New files `priv/branded/fonts/B612-Regular.ttf`, `priv/branded/images/rendro-logo.png`.
- New top-level `NOTICE` file (B612 OFL attribution).
- New files `test/docs_contract/branding_contract_test.exs`, `test/docs_contract/branding_claims_test.exs`.
- New file `test/rendro/recipes/branded_invoice_test.exs` (regression coverage for D-27).
- Updated files: `README.md` (≤2-sentence pointer), `mix.exs` (`package: [files: ...]`, `extras:`, `licenses` audit, `NOTICE` inclusion), `lib/rendro/recipes.ex` (delegate), `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` (two new actions), `examples/phoenix_example/lib/phoenix_example_web/router.ex` (new routes + index route), `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` (two new describe blocks), `.planning/ROADMAP.md` (Phase 999.1 v1.3-readiness-blockers subsection).
- New file in example app: `examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` (chooser index, hardcoded HTML).

</code_context>

<specifics>
## Specific Ideas

- API shape mental model: "two truthful small recipes side-by-side" — `Invoice` is the zero-to-one minimal proof; `BrandedInvoice` is the registered-font + logo-asset proof. They share data shape so docs and the Phoenix demo can show "same data, two recipes."
- Favor Bamboo/Swoosh's "one module per templated artifact" idiom over ReportLab's "one giant config object" pattern (the latter is the rejected Option 2 and a known footgun).
- Favor React-PDF and Typst's compose-via-import philosophy: branded variants are separate composed trees, not flags.
- Avoid Prawn's first-time-user friction ("we expect you to bring a font"): commit a tiny font so adopters who try the recipe in a fresh Phoenix app see a real branded PDF on first run.
- Mirror ReportLab's `reportlab/fonts/` precedent (small TTF inside the lib) but expose it explicitly as "demo asset, not default" to avoid the Prawn/ReportLab confusion about what is built-in.
- Mirror `tzdata`/`gettext`/`cldr_*`'s `priv/` + `Application.app_dir/2` pattern for shipped binary data.
- Mirror Oban and Phoenix's split: README is orientation, `guides/` is how-to, `@moduledoc` is reference. Don't blow up the README with branded content.
- Mirror NimbleOptions' doctest density on the recipe module — public API correctness is asserted by the doctests, not by the guide.
- Phoenix demo site convention (LiveView examples, Bamboo example app, Oban demo): tiny index page listing demo routes; copy the chooser pattern.

</specifics>

<deferred>
## Deferred Ideas

- A second branded canonical recipe for a different doc type (Statement, Certificate, Report) — out of scope for v1.2; revisit in v1.3+ if adopter demand surfaces.
- Bold or italic variants of the brand font — out of scope for Phase 29 (D-08); add only if a future phase requires bold rendering proof.
- Rendro auto-registering a default brand font/logo on `Rendro.Document.new/0` — explicitly rejected (D-11). Could be reconsidered in v1.4+ if a strong DX case emerges and does not weaken truthful boundaries.
- Generation pipeline for the demo logo PNG at runtime/test-setup — rejected (D-09). The optional `scripts/render_logo.exs` is for auditability, not runtime.
- Validator-backed PDF/A or signature claims around branded artifacts — milestone v1.5+ scope per PROJECT.md evolution path.
- Whole-file byte-identity public guarantee for branded PDFs — explicitly NOT a public contract (D-30); narrow internal regression only.
- Hosting branded docs on hex.pm sidebar with an automated extras index — handled by ExDoc's existing `extras:` mechanism; revisit if guides count exceeds 4–5.
- Live LiveView playground for the Phoenix demo — out of scope; static HTML chooser is sufficient (D-16).
- A hex `usage_rules.md` artifact — captured as a v1.3 release-readiness blocker (D-28), not implemented in this phase.

</deferred>

---

*Phase: 29-branded-recipes-docs-and-proof-closure*
*Context gathered: 2026-05-01*
