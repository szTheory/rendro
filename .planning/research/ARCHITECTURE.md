# Architecture Research

**Domain:** v2.13 Quality Ratchet & Adoption Readiness for Rendro
**Researched:** 2026-08-19
**Confidence:** HIGH for existing seams; MEDIUM for the exact amount of visual-review automation needed.

## Standard Architecture

### System Overview

```text
                         existing pure Rendro product boundary
 fixture data -> recipe/theme -> build/compose/measure/paginate/render -> deterministic PDF
                                      |                                      |
                                      |                                      +-- source-PDF SHA + page count (required)
                                      v
                          dev-only Rendro.Catalog literal registry (32 fixed cells)
                                      |
                                      +-- pinned PDFium v0.11.0, page-one PNG (advisory evidence)
                                      |       -> PNG SHA/dimensions -> assets/rendro/catalog.json
                                      v
                        reviewer-owned rubric_scores.json catalog_dispositions
                                      | exact catalog_id + source/PNG-hash join
                                      v
                     derived quality projection in catalog.json / static configurator

 ADOPTION.md public ledger ----> dated source evidence ----> HOLD | ACCUMULATING | TRIGGER
 README/discovery -> Livebook/recipe -> Phoenix example app -> controller response -> verified PDF
```

v2.13 should strengthen these three existing evidence loops; it should not create a renderer, a service, a database, telemetry, or a new core capability. The core render pipeline remains the single producer of PDFs. `Rendro.Catalog` remains dev/test-only (`dev/`), so catalog review mechanics do not widen the Hex runtime surface.

### Component Responsibilities

| Component | v2.13 disposition | Responsibility |
|---|---|---|
| Recipes, `Theme`, font registration, render pipeline | Modified only where a named cell's underlying defect requires it | Produce deterministic source PDFs through the established engine; no catalog-specific rendering path. |
| `dev/rendro/catalog.ex` + catalog Mix tasks | Modify, not replace | Keep the literal 32-cell registry, generate/check source-PDF and pinned-PDFium artifacts, and project reviewer dispositions into the manifest. |
| `assets/rendro/catalog.json` + PNG tree | Regenerated evidence | Carry the exact artifact identity, dimensions, page-count disclosure, dark-mode boundary text, and derived `quality` display state. |
| `priv/quality/rubric_scores.json` + schema | Modify | Remain the reviewer-owned record: one exact disposition per catalog ID, tied to current PNG/source hashes. Passing entries require `supersedes_evidence_ref` and `resolution_ref`. |
| `test/rendro/catalog*`, docs contracts, guardrails | Extend selectively | Fail closed on stale artifacts, stale review records, invalid quality projection, or any claim that exceeds the evidence. |
| `ADOPTION.md` + adoption docs-contract | Modify | Record refreshed, source-backed demand/download/contributor evidence and an explicit gate decision without introducing analytics. |
| README, Livebook, `examples/phoenix_example` | Modify/extend as one journey | Form the newcomer journey from discovery to an actual Phoenix controller response; the existing example app is the executable end-to-end anchor. |

## Recommended Project Structure

Keep the current ownership; do not introduce a generic “quality service” or a runtime visual-review module.

```text
lib/                         # unchanged pure render core and optional adapters
dev/rendro/catalog.ex         # catalog registry, generation, required consistency checks
dev/mix/tasks/rendro/catalog/ # write-only gen and read-only check entry points
assets/rendro/catalog*/       # checked-in, hash-identified public artifacts
priv/quality/                 # reviewer rubric/dispositions and bounded sign-off evidence
ADOPTION.md                   # public, append-only-ish adoption decision ledger
guides/, README.md            # discovery and truthful route selection
guides/livebook/              # executable no-server learning path
examples/phoenix_example/     # real optional-adapter integration and HTTP/PDF smoke proof
test/                         # deterministic contracts; tagged advisory raster/human review support
```

The catalog remains a sibling of launch-gallery assets; `Theme` remains a thin preset delegation rather than a catalog registry. Phoenix stays an optional adapter/application boundary: the core must not gain Phoenix, Oban, browser, server, or Node runtime dependencies.

## Architectural Patterns

### Pattern 1: Repair -> regenerate -> rebind -> review -> promote

**What:** Treat each of the twelve `needs_work` cells as an evidence-bound vertical slice, not as a manifest-label edit. The current target pairs are Invoice/Cedar Mutual, Statement/Signal Ledger, Receipt/Poppy & Grain, Certificate/Meridian Arts Fellowship, Payslip/Northline Logistics, and Ticket/Aurora Live, each in light and dark mode.

**Flow:**

```text
named recipe/theme/fixture repair
  -> deterministic source-PDF tests and relevant pagination/type/recipe regression tests
  -> mix rendro.catalog.gen (regenerate all committed artifacts)
  -> mix rendro.catalog.check (exact registry, source hashes, PNG hashes/dimensions, page counts)
  -> generate the bounded 12-page-one raster review set using pinned PDFium
  -> human reviewer records dimensions/gates/justifications against the new hashes
  -> disposition becomes passes only with supersession + behavioral resolution references
```

**Why:** Existing `Catalog.check/1` already blocks a stale rubric record when either the source PDF or PNG hash changes, and the schema already blocks an unproved `passed: true`. Preserve that join rather than adding a second quality registry.

**Trade-off:** A full artifact regeneration is broader than the targeted visual work, but it is the truthful way to prove that the fixed cells still live in the same bounded catalog. Keep the review scope bounded to the twelve target cells plus the existing multipage first/final-page proof; do not silently turn all 32 cells into a new review obligation.

### Pattern 2: Deterministic contracts versus advisory visual evidence

**What:** Maintain two lanes with an explicit handoff, never collapsing a visual result into a runtime guarantee.

| Lane | Mechanism | What it can prove | What it must not claim |
|---|---|---|---|
| Required deterministic | recipe/render tests, `mix rendro.catalog.check`, docs/schema contracts | input-to-PDF repeatability, source/PNG identity, page count, artifact presence/dimensions, disposition completeness and promotion evidence fields | visual quality, accessibility, PDF/UA, WCAG, print safety, universal viewer fidelity |
| Advisory pinned-raster + human review | pinned PDFium v0.11.0 page-one files, bounded human rubric/sign-off | reviewer assessment of these exact rasterized cells; concrete visual defects and their closure | a general design-quality or compliance guarantee |

**When to use:** Every catalog repair. The acceptance unit is “this exact fixed artifact has deterministic identity and bounded reviewer evidence,” not “PDFium says it looks good.” Dark cells retain their existing screen-oriented disclosure and must never be promoted into a print-safety claim merely because a visual reviewer approves them.

### Pattern 3: Evidence ledger, not instrumentation

**What:** Refresh the existing `ADOPTION.md` demand gate by collecting the current public evidence using the documented commands, then append a dated review-log decision and supporting rows.

**Required decision protocol:** calculate each threshold family first; then write exactly one explicit outcome:

- **HOLD** — no qualifying new evidence or still clearly below a threshold.
- **ACCUMULATING** — qualifying evidence exists but all trigger conditions are not met.
- **TRIGGER** — all three existing threshold families are met in the same review window; route a future capability decision into planning rather than auto-starting implementation.

Keep the current threshold copy and counting exclusions contract-tested. A refresh is evidence maintenance, not a reason to add product analytics, social counters, scheduled polling, a dashboard, or a new gate. If live sources are unreachable, record that limitation and HOLD rather than infer adoption.

### Pattern 4: Executable Phoenix newcomer journey

**What:** Validate the narrative route using the existing seams, in order:

```text
README discovery / support boundaries
  -> choose recipe or first-invoice Livebook
  -> build document from application data
  -> optional Rendro.Adapters.Phoenix controller helper
  -> real Phoenix example route
  -> HTTP 200 + application/pdf + %PDF- response evidence
```

The root README controller code is deliberately schematic; it cannot be the final validation target. The `examples/phoenix_example` app is the authoritative executable target because it pins Phoenix 1.8, uses the optional adapter, tests actual routes/responses, and already runs as an advisory CI smoke job. The Livebook is complementary: it validates no-server learning and generated PDF behavior, not Phoenix integration.

**Recommendation:** add a journey contract only where the present handoffs are unverified (for example, README link/path -> example setup -> one chosen controller route), then run the actual example suite. Do not make the example job a required branch gate; its current advisory role protects the deterministic core lane from ecosystem/tooling availability.

## Integration Points

### Internal Boundaries

| From -> To | Communication | v2.13 rule |
|---|---|---|
| recipe/theme/fixture -> `Rendro.render` | existing data-first document API | Repair source behavior first; catalog never gets an alternate renderer or recipe fork. |
| render -> `Rendro.Catalog` | deterministic PDF bytes | Recompute source SHA and page count; a changed hash requires artifact regeneration/review rebind. |
| catalog -> pinned PDFium -> artifact tree | dev/test generation only | Rasterize physical page one at the pinned DPI/version; retain full-document disclosure and existing bounded multipage proof. |
| manifest cell <-> rubric disposition | exact `catalog_id` plus source-PDF and PNG SHA | One record per cell; no manual display-status mutation. A passing projection follows a valid scored disposition only. |
| rubric disposition -> public catalog/configurator | derived `quality` field in manifest | Public status follows reviewer evidence; it is not an independent source of truth. |
| live public sources -> `ADOPTION.md` | dated Markdown rows and review decision | Preserve source URLs/commands and the existing semantic thresholds; no background collector. |
| docs/Livebook -> Phoenix example -> adapter | links, code paths, executable tests | Assert a newcomer can traverse the actual optional-adapter handoff, while core stays integration-agnostic. |

### New versus Modified Components

| Needed | Recommendation |
|---|---|
| New core renderer/runtime dependency | **No.** Explicitly out of scope. |
| New catalog registry or new quality database | **No.** Use the existing literal registry and `catalog_dispositions` join. |
| New visual-review helper | Only if it automates the existing bounded review directory/manifest handoff; it must be dev/test-only, pinned, and advisory. Prefer extending `catalog_raster_review_test.exs`/its task over a new rendering subsystem. |
| Recipe/theme/fixture changes | **Yes, targeted.** Only where a particular failed disposition identifies a concrete behavior or visual composition issue. |
| Catalog manifest, PNGs, rubric records | **Yes, regenerated and re-signed.** These are the canonical evidence updates. |
| Adoption ledger and docs contract | **Yes, additive refresh.** Record current evidence and the decision; preserve gate definitions. |
| Phoenix example/journey contract | **Yes, narrow.** Close the documented-to-executable handoff, using the existing example application and optional adapter. |

## Dependency-Aware Build Order

1. **Evidence baseline and acceptance contract** — freeze the exact 12 target IDs, their current dispositions, current hash bindings, and the rubric thresholds. Decide the required promotion evidence shape before changes. This prevents relabeling a known failure as success.
2. **Targeted recipe/theme/fixture repair plus deterministic regression tests** — make the smallest product changes that correct identified defects. Run normal core tests before catalog work, so catalog generation is not the first signal of a regression.
3. **Regenerate catalog artifacts and required integrity checks** — run catalog generation then its read-only check; commit updated PNGs/manifest/rubric hashes as one coherent evidence unit. Regeneration cannot be deferred because the rubric is hash-bound.
4. **Pinned-raster review and human disposition closure** — generate the fixed 12-page review set from the regenerated sources, perform bounded human review, and update each disposition with scores/gates/justifications. Only after this may `quality.status` project from `needs_work` to `passes`; keep any unresolved cell explicitly `needs_work`.
5. **Adoption refresh** — independently collect and append current public signals plus HOLD/ACCUMULATING/TRIGGER. It can proceed in parallel with steps 2–4, but must complete before docs make freshness claims.
6. **Phoenix newcomer journey validation and documentation closure** — validate discovery/install/example/controller/output handoffs against the final docs and product state. This comes after catalog evidence and adoption records so public routes cite final, truthful artifacts and current gate posture.
7. **Lane/guardrail reconciliation** — run `mix ci.fast` and the relevant catalog check as deterministic gates; run Livebook, Phoenix example, and pinned-raster work in their established advisory contexts. Update required-status/docs-lane contracts only if an added deterministic check is genuinely required; do not promote advisory integrations to required status by accident.

## Anti-Patterns

### Treating a quality label as the fix

**What people do:** Edit `catalog.json` from `needs_work` to `passes`, or edit a rubric `passed` flag without regenerated evidence.

**Why it is wrong:** The catalog's quality state is a derived projection. Existing contracts intentionally require a one-to-one disposition, current source/PNG hashes, and supersession/resolution references for a pass.

**Do this instead:** Repair behavior, regenerate deterministic artifacts, review the exact raster, then update the reviewer-owned record.

### Making PDFium or reviewer approval a universal product claim

**What people do:** Describe a pinned raster review as proof of design quality, WCAG, PDF/UA, print safety, or cross-viewer fidelity.

**Why it is wrong:** It violates both the advisory/deterministic lane separation and the dark-mode disclosure contract.

**Do this instead:** State the bounded artifact, renderer/version, review date, and non-guarantees. Keep rendering correctness proof in the deterministic lane.

### Adding a Phoenix dependency to solve onboarding

**What people do:** Pull Phoenix into Rendro core or introduce a server-backed tutorial/configurator to make the path feel integrated.

**Why it is wrong:** It breaks Rendro's pure-core and optional-adapter contract while duplicating the existing executable Phoenix reference app.

**Do this instead:** Verify and tighten the current README -> Livebook/recipe -> optional adapter -> example-app journey.

### Replacing the adoption ledger with telemetry or a scheduled dashboard

**What people do:** Add runtime tracking, polls, or social metrics to make evidence refresh automatic.

**Why it is wrong:** The project deliberately uses pull-based, public, reviewable evidence and excludes social counters from the gate.

**Do this instead:** Add dated source-backed rows and a decision at meaningful review points only.

## Scaling Considerations

| Concern | Current bounded scale | v2.13 action |
|---|---|---|
| Catalog volume | fixed 32-cell literal registry | Preserve exact membership and ceiling; do not expand the grid to obtain more evidence. |
| Human review | 12 named failed cells plus bounded multipage proof | Keep review material deterministic and limited; use explicit unresolved status rather than review debt hidden by automation. |
| CI reliability | deterministic core required; raster/Livebook/example integration advisory | Preserve lane separation. The likely first bottleneck is external tool/environment availability, not render throughput. |
| Adoption evidence | infrequent, pull-based snapshots | Append low-volume source-backed records; no operational service is justified. |

## Sources

- Repository primary source: `dev/rendro/catalog.ex`, `test/rendro/catalog_test.exs`, `test/rendro/catalog_raster_review_test.exs`, `test/docs_contract/catalog_*`.
- Repository primary source: `priv/quality/rubric_scores.json` and `priv/schemas/rubric_scores.schema.json`.
- Repository primary source: `ADOPTION.md` and `test/docs_contract/adoption_claims_test.exs`.
- Repository primary source: `README.md`, `guides/livebook/first_invoice.livemd`, `lib/rendro/adapters/phoenix.ex`, and `examples/phoenix_example/`.
- Milestone integration evidence: `.planning/milestones/v2.12-MILESTONE-AUDIT.md`.

---
*Architecture research for: Rendro v2.13 Quality Ratchet & Adoption Readiness*
*Researched: 2026-08-19*
