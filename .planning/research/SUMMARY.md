# Project Research Summary

**Project:** Rendro v2.13 — Quality Ratchet & Adoption Readiness
**Domain:** Pure-Elixir, Phoenix-first PDF library stewardship: evidence-bound catalog quality, adoption review, and newcomer validation
**Researched:** 2026-08-19
**Confidence:** HIGH

## Executive Summary

Rendro v2.13 is a stewardship milestone, not a rendering-feature release. The product already has the required machinery: a deterministic PDF pipeline, a fixed 32-cell catalog with a generator/checker, SHA-bound reviewer dispositions, a pinned advisory PDFium raster lane, a pull-based `ADOPTION.md` ledger, and a Phoenix 1.8 reference app. The recommendation is to strengthen those three existing evidence loops only: repair and re-review the twelve explicitly named `needs_work` catalog cells, record a dated adoption decision from live public sources, and prove one clean Phoenix newcomer journey from discovery through a customized verified PDF.

The correct quality unit is an evidence-bound vertical slice: repair the underlying recipe/theme/fixture behavior, regenerate artifacts, verify deterministic identities, review the exact pinned-raster assets at readable size, then promote only with a human record tied to the current PDF/PNG hashes. Deterministic contracts prove artifact identity and completeness; advisory raster/network evidence and bounded human judgment remain distinct and must not become claims of accessibility, print safety, PDF/UA, WCAG, universal viewer compatibility, or general design certification. Dark cells remain screen-oriented and retain `print_safety: false`.

The main risks are score laundering or provenance drift, treating environment-specific tools as required truth, stale/miscounted adoption data, and a newcomer check that only proves the maintainer checkout. Mitigate them with hash joins and fail-closed contracts, the existing pinned advisory lane, dated read-only Hex/GitHub snapshots with an explicit `HOLD`/`ACCUMULATING`/`TRIGGER`, and a clean public path anchored to the existing Phoenix example. Do not add a runtime dependency, analytics, outreach, a new core capability family, a service/database, or a second tutorial application.

## Key Findings

### Recommended Stack

No new runtime dependency is warranted. Keep Elixir 1.19.5/OTP 28, the existing dev-only `Rendro.Catalog` generator/checker and rubric schema, pinned `pdfium-cli` v0.11.0 for advisory raster evidence, and the existing Phoenix `~> 1.8` reference application. The static catalog and Phoenix example are evidence consumers of the one pure render engine, not alternate rendering paths.

**Core technologies:**

- `Rendro.Catalog`, `mix rendro.catalog.gen`, and `mix rendro.catalog.check` — regenerate and verify all 32 catalog cells, exact hashes, renderer pin, dispositions, and promotion evidence.
- `priv/quality/rubric_scores.json` — reviewer-owned, SHA-bound record; a repaired cell passes only with supersession and concrete resolution references.
- `pdfium-cli` v0.11.0 with the existing SHA pin — advisory, renderer-specific review PNGs; never a deterministic or universal-viewer authority.
- `mix ci.fast` and existing docs/schema contracts — required deterministic verification without external visual tools.
- `ADOPTION.md`, Hex API, and read-only `gh issue list` / `gh pr list` — dated snapshot evidence only; no polling, telemetry, or GitHub writes.
- `examples/phoenix_example` — the sole repeatable Phoenix 1.8 integration anchor; a disposable `mix phx.new` run is acceptance evidence only, never another maintained app.

### Expected Features

**Must have (table stakes):**

- Repair, regenerate, and re-score the exact twelve named cells: Invoice/Cedar Mutual/Corporate Classic, Statement/Signal Ledger/Minimal Mono, Receipt/Poppy & Grain/Humanist, Certificate/Meridian Arts Fellowship/Editorial, Payslip/Northline Logistics/Swiss, and Ticket/Aurora Live/Brutalist — each in light and dark.
- Address the Humanist dark Receipt’s additional affordance, typography, and cohesion deficits; every target must reach hierarchy 5 and all applicable rubric gates while dark cells keep their screen-only/false-print-safety boundary.
- Add or strengthen a fail-loud provenance/coverage guard so catalog ID, current PDF/PNG hashes, rubric scores, disposition, and human review cannot drift.
- Refresh the existing adoption gate in one live review window and append source, timestamp, raw outcome, and explicit decisions for demand, downloads, contributor evidence, and the composite gate.
- Prove one public Phoenix newcomer path: discover → install → choose Swiss/light Invoice → copy/configure canonical code → controller response → `application/pdf` and `%PDF-` verification; repair only the existing handoffs found broken.
- Preserve truthful scope language in catalog, docs, configurator, and ledger.

**Should have (only if it enables the required work):**

- A dev/test-only full-size reviewer packet for the exact twelve cells, extending the existing raster review seam rather than creating a review product.

**Defer (v2+):**

- Global text shaping, RTL/bidi/cluster support unless the pre-existing conjunctive gate actually triggers.
- Catalog expansion, new recipes/presets/document families, live Studio/server previews/accounts, automated/AI aesthetic scoring, compliance/accessibility/print certification, analytics, campaigns, and outreach.

### Architecture Approach

Keep three existing evidence flows and one render engine. Recipes/themes feed `build -> compose -> measure -> paginate -> render -> validate`, producing deterministic PDFs. The dev-only catalog binds those PDFs to pinned advisory PNGs and projects only hash-bound reviewer dispositions into the public manifest/configurator. Independently, dated public observations flow to `ADOPTION.md` and an explicit gate outcome; README/Livebook/recipe links flow to the optional Phoenix adapter and the executable example route. No new renderer, database, service, telemetry, or runtime integration belongs in this milestone.

**Major components:**

1. Recipes/themes/fixtures and the render pipeline — make the smallest targeted behavior repair; never add a catalog-specific rendering fork.
2. Catalog tasks, artifact tree, and rubric manifest — regenerate/check exact artifacts and bind public quality state to reviewer-owned evidence.
3. Deterministic tests/docs contracts plus advisory review support — fail closed on identity/provenance/claim drift while keeping visual review advisory and human.
4. `ADOPTION.md` — immutable, reviewable public evidence snapshots and decision logic, without instrumentation.
5. README, Livebook, and `examples/phoenix_example` — one connected, optional-adapter newcomer journey.

### Critical Pitfalls

1. **Score laundering** — never edit a visible status or `passed` assertion; freeze thresholds, regenerate bytes, and require per-cell, hash-addressed human review.
2. **Artifact/provenance drift** — generator output, rubric, sign-off, and configurator must join on current IDs/hashes; generated catalog fields are never hand-edited.
3. **Advisory tools treated as portable truth** — Linux/pinned PDFium output is advisory evidence; tool absence is `SKIPPED`/unavailable, not core failure, and never supports compliance claims.
4. **Stale or miscounted adoption evidence** — collect live Hex and GitHub inputs in the same window; record query/date/pagination/result and `UNAVAILABLE`, never infer zero or trigger from a partial family.
5. **Scope/outreach creep and maintainer-only onboarding** — perform only read-only inbound review; prove a clean public Phoenix install/copy/customize/render path without widening core dependencies or relying on checkout/cache state.

## Implications for Roadmap

Based on research, use two phases with a hard evidence handoff.

### Phase 130: Catalog Quality & Evidence Ratchet

**Rationale:** Catalog repair is the dependency root: the Phoenix journey must consume a stable, truthful catalog choice, and no label may be promoted before its deterministic artifact identity and human evidence agree.

**Delivers:** Targeted recipe/theme/fixture fixes for the twelve frozen cells; focused regressions; deterministic artifact regeneration; catalog/rubric/provenance contracts; a bounded pinned-raster reviewer packet if the existing seam is insufficient; per-cell human re-review and promotion only where thresholds/gates truly pass.

**Addresses:** All twelve `needs_work` cells, especially Humanist dark Receipt; durable quality-evidence linkage.

**Avoids:** Score laundering, provenance drift, host-specific raster baselines, broad catalog cleanup, and dark-mode/print-safety overclaims.

### Phase 131: Adoption Snapshot & Phoenix Newcomer Proof

**Rationale:** This phase is independent of the repairs operationally but must use their final public state. It closes the evidence-to-adoption and documentation-to-working-app handoffs without inventing a growth program or new product surface.

**Delivers:** One dated, source-backed, read-only Hex/GitHub adoption refresh and explicit composite decision; deterministic ledger/claim guards as needed; a clean, reproducible Phoenix newcomer evaluation anchored to the existing example; documentation/integration fixes limited to proven handoff failures; recorded deterministic versus advisory boundaries.

**Addresses:** Current adoption decision and one Swiss/light Invoice discover-to-customized-PDF path.

**Avoids:** Stale/miscounted signals, accidental outreach/telemetry, core Phoenix coupling, cache/checkout-only success, and exaggerated public claims.

### Phase Ordering Rationale

- Freeze the twelve IDs and evidence shape before modifying recipes; repair → regenerate → rebind → human-review → promote is non-negotiable.
- The full 32-cell generation/check confirms catalog-wide integrity, but human review remains bounded to the twelve targets plus existing multipage evidence; do not expand the review obligation.
- Adoption collection may run in parallel with Phase 130 preparation, but its final ledger/docs closure and the newcomer journey should consume the final catalog state.
- Required deterministic checks (`mix rendro.catalog.check`, focused regressions, `mix ci.fast`, docs/schema contracts) remain separate from advisory PDFium, Livebook, and Phoenix integration lanes.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 130:** Medium research need — inspect the exact current catalog/rubric test seams and the pinned Linux-review workflow before deciding whether a narrow reviewer-packet helper is necessary; preserve renderer pin and historical-evidence semantics.
- **Phase 131:** Medium research need — live Hex/GitHub data is time-sensitive and Phoenix clean-room validation must confirm current dependency/setup behavior. Research only the specific public APIs and released package path, then commit a dated snapshot.

Phases with standard patterns (skip broad research-phase):

- **Phase 130 deterministic repair/check work:** Existing repository generator, hash join, schema contracts, and focused recipe regression patterns are authoritative.
- **Phase 131 ledger/docs contracts:** Existing `ADOPTION.md` rules and docs-contract patterns define the decision model; no analytics or external platform evaluation is required.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Existing pinned toolchain, catalog tasks, and Phoenix fixture are repository-verified; external documentation is supplementary. |
| Features | HIGH | Exact target cells, scores, deferred scope, and evidence gates are committed project facts. |
| Architecture | HIGH | Existing component boundaries and data/evidence flows are directly documented in repository seams. |
| Pitfalls | HIGH | Controls arise from current contracts, prior milestones, and known host/evidence boundaries; external API behavior is MEDIUM. |

**Overall confidence:** HIGH

### Gaps to Address

- **Exact visual fixes:** Research identifies the failing scores, not the final design edits. Phase 130 must validate each minimal change against current artifacts and preserve unresolved status when evidence falls short.
- **Review automation extent:** Only add a reviewer-packet helper if the existing raster-review test cannot produce the twelve exact full-size assets; keep it dev/test-only and advisory.
- **Live adoption facts:** Download/issue/PR values are snapshots, not durable facts. Phase 131 must fetch and record raw dated observations; network failure is `UNAVAILABLE`, not a zero.
- **Clean-room Phoenix evidence:** The committed example is repeatable evidence, while a disposable generated-app check validates public onboarding. Record versions/prerequisites/results without committing generated application code.

## Sources

### Primary (HIGH confidence)

- [STACK.md](STACK.md) — existing toolchain, pins, commands, adoption-snapshot and Phoenix-fixture recommendations.
- [FEATURES.md](FEATURES.md) — exact twelve-cell scope, rubric outcomes, anti-features, and adoption/journey acceptance boundaries.
- [ARCHITECTURE.md](ARCHITECTURE.md) — data/evidence flows, ownership boundaries, and dependency-aware build order.
- [PITFALLS.md](PITFALLS.md) — failure modes, lane separation, scope controls, and verification hooks.
- [PROJECT.md](../PROJECT.md), `ADOPTION.md`, `priv/quality/rubric_scores.json`, `assets/rendro/catalog.json`, and `examples/phoenix_example/` — project-authoritative constraints and existing evidence seams.

### Secondary (MEDIUM confidence)

- Phoenix official `mix phx.new` and setup documentation — clean-room validation guidance.
- GitHub CLI documentation and GitHub REST pagination/rate-limit documentation — read-only snapshot collection behavior.
- Hex Rendro package API — time-stamped download observation only.

---
*Research completed: 2026-08-19*
*Ready for roadmap: yes*
