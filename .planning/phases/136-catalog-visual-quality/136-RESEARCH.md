# Phase 136: Catalog Visual Quality - Research

**Researched:** 2026-08-27
**Domain:** Bounded Elixir document-recipe visual repair with deterministic catalog evidence and human-owned review
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Treat the six catalog IDs as an exact change allowlist. The implementation must prove that those six cells changed and the other 26 catalog cells stayed byte-identical.
- **D-02:** Keep catalog identity knowledge in dev-only catalog tooling. Core recipe modules must not branch on catalog IDs, phase numbers, brands, or preset names; they may consume only generic internal presentation data such as palette, typography, column, or layout profiles selected by the catalog tooling.
- **D-03:** Reuse the existing data-first recipe option/theme seams and the unchanged `build -> compose -> measure -> paginate -> render -> validate` engine. Do not add raster overlays, PDF post-processing, a second catalog renderer, or a parallel layout path.
- **D-04:** Add no public API solely for this repair. Keep Phoenix, Plug, Ecto, Oban, databases, browsers, and new runtime/package dependencies out of the phase; none belongs in the pure document-layout or evidence problem.
- **D-05:** Preserve selectable text, caller data, existing recipe semantics outside the target profiles, deterministic measurement, and exact no-theme/unrelated-theme bytes. The exact private profile names and plumbing are implementation details, but their blast radius must remain provably limited.
- **D-06–D-09:** Repair only Corporate Classic Invoice dark and Minimal Mono Statement dark with target-selected semantic primary/secondary text treatments; retain `Total Due` and boxed `Closing Balance` as their respective sole display-size focal anchors; do not retune a global dark theme or make print/accessibility/viewer claims.
- **D-10–D-15:** Replace only the Swiss target's paired seven-column ledger with sequential full-width `Earnings | Current | YTD` and `Deductions | Current | YTD` tables. Preserve every supplied description verbatim; use measured amount widths, right-aligned atomic money, semantic palette roles, repeated headers and native pagination; retain uniquely dominant Net Pay and its final reconciliation.
- **D-16–D-19:** Preserve the Brutalist target's source-order `GA | H | 24 | B` one-row locator and tune it so labels are above atomic values and `24` cannot associate with Gate `B`. Keep the shared Aurora fixture, no placeholders/reordering/two-row capability, identical light/dark geometry, and dark `print_safety: false`.
- **D-20–D-26:** Use one validated exact-SHA `review` bundle; verify its manifest/checksums, identity, renderer/executable pin, run/attempt, roles and counts before review. Review full-size images in the specified family-paired order, record cell-specific human scores/provenance, distinguish the Phase 136 visual threshold from complete manifest `passed` arithmetic, retain actual misses, and materialize/check canonical output only after the six-ID/26-control proof and all phase thresholds pass. Human judgment is advisory and named; deterministic checks remain reproducible completion evidence.

### the agent's Discretion

- Choose exact internal profile names, data shapes, module/function names, numeric column widths, font sizes within the selected theme roles, and secondary dark tones.
- Choose plan and commit boundaries, provided target-isolation proof lands before canonical materialization and visual changes remain separate from reviewer-owned score/provenance updates.
- Choose focused test filenames and fixture construction. Tests must cover the actual six IDs, representative failure controls, long labels, widest money tokens, dark semantic headers, ticket token atomicity, repeat headers/pagination, two-render determinism, and all 26 unchanged catalog controls.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope. Global dark-token retuning, recipe-wide semantic-label cleanup, generalized responsive ticket layouts, new public layout options, and broader catalog review remain outside Phase 136 rather than becoming implied follow-up work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| CATALOG-10 | Limit visual work to the six named scored cells. | Literal six-ID allowlist in dev catalog tooling plus candidate diff assertion: exactly those six changed, exactly 26 byte-stable. |
| CATALOG-11 | Obtain current exact-SHA pinned-renderer evidence and human scores of hierarchy 5 / all other dimensions >=4; keep misses truthful. | Existing `review` bundle, raster/reconciliation checks, rubric schema, and reviewer-owned dispositions establish the sequence and non-promotion rule. |
| CATALOG-12 | Preserve 32 cells, 20 explicit unscored, dark screen-only `print_safety: false`, and no new claim. | Current catalog/rubric contract tests and `Theme` boundary must remain passing after the target repair. |
| CATALOG-13 | Bind changed records to SHA, pinned renderer, artifact hashes, review, and canonical provenance. | Existing `CatalogEvidenceBundle`, review payload/reconciliation, candidate status, and canonical check provide the required chain; plan should consume, not redesign, them. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure; do not add hard Phoenix, Oban, or admin dependencies. [VERIFIED: `AGENTS.md`]
- Preserve deterministic and advisory verification lanes in CI and documentation. [VERIFIED: `AGENTS.md`]
- Classify completion evidence as deterministic, advisory, or explicit deferral; human feedback may enrich evidence but cannot block completion; unsupported objective claims are unsupported or explicitly deferred. [VERIFIED: `AGENTS.md`]
- Treat documentation claims as contracts and do not claim unsupported capability. [VERIFIED: `AGENTS.md`]
- Prefer optional dependency guards for integrations; no integration is in this phase. [VERIFIED: `AGENTS.md`]

## Summary

This is a bounded presentation-profile repair, not a catalog/evidence-system redesign. The repository already provides all required primitives: `Rendro.Catalog` owns literal ordered 32-cell membership and calls recipe `document/2` through `catalog_layout: true`; recipes accept palette/typography/layout options; the Payslip uses measured rows and pagination; and the Catalog Evidence workflow produces a closed, SHA-pinned review bundle. The planner should make dev-only catalog selection produce generic private presentation profiles, then have each recipe react solely to those profiles. [VERIFIED: `dev/rendro/catalog.ex`; recipe modules; `.github/workflows/catalog-evidence.yml`]

The main safety property is stronger than a visual diff: candidate evidence must report the six target IDs as changed and all other 26 catalog IDs as byte-stable in both source-PDF and PNG hashes. The exact-SHA bundle is necessary before any image interpretation, while scoring remains a named human record per cell. A phase-threshold success is not equivalent to manifest `passed`: dark targets keep `print_safety: false`, so their complete rubric disposition remains unpromoted unless the existing arithmetic independently permits it. [VERIFIED: `136-CONTEXT.md`; `dev/rendro/catalog.ex`; `priv/schemas/rubric_scores.schema.json`; `.github/workflows/CATALOG-EVIDENCE.md`]

Brand guidance supports the locked approach: use semantic primary/secondary roles rather than raw black in dark presentations; preserve warm-neutral dark surfaces and restrained hierarchy; avoid turning contrast improvement into accessibility or print certification. [VERIFIED: `brand/tokens/tokens.json`; `brand/README.md`; `brand/audit/AUDIT.md`]

**Primary recommendation:** Plan three bounded implementation slices: (1) dev-only six-ID profile selection plus failing isolation contracts, (2) generic recipe profile rendering and measured geometry repair, and (3) exact-SHA review/canonical evidence with reviewer-owned updates kept separate from generation code.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Six-ID allowlist and target-profile selection | API / Backend (dev-only Elixir tooling) | — | `Rendro.Catalog` already knows literal catalog identity; core recipes must not. [VERIFIED: `dev/rendro/catalog.ex`; `136-CONTEXT.md`] |
| Semantic dark labels and recipe-local hierarchy | API / Backend (pure render core) | — | Recipes construct text/table cells from generic palette/typography/profile data before the standard render pipeline. [VERIFIED: recipe modules; `lib/rendro/recipes/palette.ex`] |
| Swiss measured tables and pagination | API / Backend (pure render core) | — | Native `measure_rows`, column rules, and pagination own fit/repeat-header behavior; fixtures remain caller data. [VERIFIED: `lib/rendro/recipes/payslip.ex`; `136-CONTEXT.md`] |
| Immutable raster evidence transport | CDN / Static (GitHub Actions artifact) | API / Backend (validator) | Actions rasterizes with pinned PDFium; local Elixir validates closed roles, hashes, and provenance. [VERIFIED: `.github/workflows/catalog-evidence.yml`; `dev/rendro/catalog_evidence_bundle.ex`] |
| Visual judgment and canonical publication | Human review record | API / Backend (canonical generator/checker) | A reviewer owns subjective scores; deterministic tooling binds/protects them and publishes only verified canonical data. [VERIFIED: `priv/quality/rubric_scores.json`; `dev/rendro/catalog.ex`; `136-CONTEXT.md`] |

## Standard Stack

### Core

| Library / facility | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing Rendro render pipeline | repository-owned | Build, compose, measure, paginate, render, and validate target PDFs | It is the product engine and preserves selectable text/deterministic measurement; a parallel renderer is forbidden. [VERIFIED: `AGENTS.md`; `136-CONTEXT.md`] |
| Elixir + ExUnit | Elixir 1.19.5 / OTP 28 | Profile, compatibility, candidate-diff, and negative-control contracts | Existing test stack; `mix test` runs `*_test.exs` tests. [VERIFIED: `AGENTS.md`; [CITED: https://hexdocs.pm/ex_unit/ExUnit.html]] |
| Existing PDFium adapter/pin | repository pin (`priv/pdfium_pin.json`) | Exact raster generation and PNG/PDF hash identity | PDFium's standalone test program rasterizes PDF pages, matching Rendro's current closed evidence design. [VERIFIED: `priv/pdfium_pin.json`; `.github/workflows/catalog-evidence.yml`; [CITED: https://pdfium.googlesource.com/pdfium/]] |

### Supporting

| Facility | Purpose | When to Use |
|---|---|---|
| `Rendro.Recipes.Palette` and `TableCell` | Resolve semantic ink/surface/header roles without raw color call sites | Invoice/Statement labels and dark table headings. [VERIFIED: `lib/rendro/recipes/palette.ex`; `lib/rendro/recipes/table_cell.ex`] |
| `Rendro.measure_rows/4` and shared Pagination | Measure real fonts/rows, calculate safe capacities, repeat headers | Swiss sequential ledger; never use estimated row capacity. [VERIFIED: `lib/rendro/recipes/payslip.ex`] |
| Catalog candidate/review/reconciliation/bundle facilities | Fail-closed candidate status, full-size review identity, SHA/hash/provenance validation | Before visual review and before canonical materialization. [VERIFIED: `dev/rendro/catalog.ex`; `dev/rendro/catalog_review_payload.ex`; `dev/rendro/catalog_review_reconciliation.ex`; `dev/rendro/catalog_evidence_bundle.ex`] |

**Installation:** None. This phase adds no package, runtime, integration, or public API. [VERIFIED: `136-CONTEXT.md`; `mix.exs`]

## Architecture Patterns

### System Architecture Diagram

```text
literal six-ID allowlist (dev/Rendro.Catalog)
                |
                v
generic private profile data (palette / typography / ledger / locator)
                |
                v
Invoice | Statement | Payslip | Ticket recipes (no catalog-ID branches)
                |
                v
build -> compose -> measure -> paginate -> render -> validate
                |
                +--> candidate manifest: 6 changed / 26 byte_stable
                |
                v
exact-SHA pinned-PDFium `review` bundle -> validate hashes/roles/identity -> full-size human review
                                                                  |
                     reviewer-owned per-cell scores + provenance --+
                                                                  v
only after thresholds + isolation proof: `canonical` generate/check -> 32-cell publication
```

### Recommended Project Structure

```text
dev/rendro/catalog.ex                       # six-ID allowlist -> generic private profiles
lib/rendro/recipes/{invoice,statement}.ex   # semantic label/header treatment
lib/rendro/recipes/payslip.ex               # sequential measured ledger profile
lib/rendro/recipes/ticket.ex                # one-row atomic locator profile
test/rendro/                                # focused profile + catalog isolation contracts
test/docs_contract/                         # rubric/claim/reviewer-authority contracts
priv/quality/rubric_scores.json             # reviewer-owned records only, after review
assets/rendro/catalog{,.json}               # canonical output only after authorization
```

### Pattern 1: Identity-to-generic-profile boundary

**What:** Create one private catalog helper mapping only the six exact IDs to generic recipe options. Recipes may pattern-match profile fields such as `:semantic_labels`, `:sequential_ledger`, or `:atomic_locator`, never IDs/brands/presets/phases. [VERIFIED: `136-CONTEXT.md`; `dev/rendro/catalog.ex`]

**When to use:** At `source_document_for/1`, before its existing recipe `document/2` call; omit profile data for every non-target. This creates the narrowest possible byte blast radius. [VERIFIED: `dev/rendro/catalog.ex`]

### Pattern 2: Measure first, paginate second

**What:** Build both Swiss tables from the unaltered fixture rows, measure each row using the document's registered font metrics and explicit numeric columns, then chunk with the existing pagination utility. Headers belong to each table block so a continued table repeats its own header. [VERIFIED: `lib/rendro/recipes/payslip.ex`; `136-CONTEXT.md`]

**Anti-patterns to avoid**

- **Catalog-ID branches inside recipes:** leaks dev catalog knowledge into public/core behavior and makes unrelated byte protection unprovable. Use generic profile values selected in `Rendro.Catalog`. [VERIFIED: `136-CONTEXT.md`]
- **Global `Theme.dark/1` / preset retuning:** changes unscored/non-target dark cells and cannot repair raw-black call sites consistently. Use target-profile semantic roles. [VERIFIED: `136-CONTEXT.md`]
- **Text shortening, font shrinkage, or guessed capacity:** violates caller-data/fidelity rules and risks overflow. Use measured flexible description widths and fixed money widths. [VERIFIED: `136-CONTEXT.md`; `lib/rendro/recipes/payslip.ex`]
- **Raster overlays or PDF post-processing:** would break selectable text and add an unreviewable render path. [VERIFIED: `136-CONTEXT.md`]
- **Generated approval or score update during candidate creation:** candidate artifacts must not contain quality fields; review truth stays human-owned. [VERIFIED: `test/rendro/catalog_review_payload_contract_test.exs`; `136-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Row fit/pagination | Character-count width or fixed rows-per-page rule | `Rendro.measure_rows/4` + existing Pagination | Font metrics, wrapping, and continued-table headers are already handled by the engine. [VERIFIED: `lib/rendro/recipes/payslip.ex`] |
| Color repair | Inline hex/raw black patches | Recipe palette roles and theme-aware `TableCell` | Semantic light/dark roles prevent header/body divergence while preserving generic recipes. [VERIFIED: `lib/rendro/recipes/palette.ex`; `lib/rendro/recipes/table_cell.ex`; `brand/tokens/tokens.json`] |
| Scope evidence | Screenshot comparison or informal assertions | Candidate manifest's PDF/PNG hashes and changed/byte-stable partitions | Hash partitions prove exact membership and unchanged controls. [VERIFIED: `dev/rendro/catalog.ex`; `test/rendro/catalog_test.exs`] |
| Review provenance | New reviewer system or CI status | Existing `review` bundle, reconciliation, rubric schema, canonical check | The authority separation is already fail-closed and Phase 135's intended handoff. [VERIFIED: `.github/workflows/CATALOG-EVIDENCE.md`; `dev/rendro/catalog_review_reconciliation.ex`] |

## Common Pitfalls

### Pitfall 1: Equating the phase target with complete rubric `passed`

**What goes wrong:** A dark cell that achieves hierarchy 5 and the other visual scores >=4 is marked `passed: true` despite `print_safety: false`.

**Avoidance:** Record the actual review scores and retain `print_safety: false`; explicitly describe the phase threshold separately from schema arithmetic. [VERIFIED: `136-CONTEXT.md`; `priv/schemas/rubric_scores.schema.json`]

### Pitfall 2: Reviewing stale/thumbnail evidence

**What goes wrong:** Review is based on old hashes, thumbnails, or an unvalidated artifact.

**Avoidance:** Validate root manifest/checksums, candidate/HEAD/control identity, renderer executable pin, run/attempt, roles/counts; then inspect full-size images in locked family-paired order. [VERIFIED: `.github/workflows/CATALOG-EVIDENCE.md`; `136-CONTEXT.md`]

### Pitfall 3: Changing non-target bytes accidentally

**What goes wrong:** A shared palette/preset or generic geometry change alters any of the other 26 cells.

**Avoidance:** Add focused tests that render/catalog-classify twice and assert six changed IDs exactly plus 26 exact PDF/PNG hash controls; test a representative profile omission and no-theme/default path. [VERIFIED: `dev/rendro/catalog.ex`; `test/rendro/catalog_test.exs`; `136-CONTEXT.md`]

### Pitfall 4: Solving Payslip density in fixture text

**What goes wrong:** Descriptions are abbreviated or amount columns can wrap/clip.

**Avoidance:** Retain fixture strings byte-for-byte, make description flexible, fix measured Current/YTD width, keep money atomic/right-aligned, and use native continuation rather than a hand-set page capacity. [VERIFIED: `136-CONTEXT.md`; `priv/examples/payslip/northline-logistics/payslip.json`]

### Pitfall 5: Weakening Ticket semantics to fix `GA`

**What goes wrong:** Gate disappears, fields reorder, or a responsive two-row layout changes the shared archetype.

**Avoidance:** Retain source order and one locator row; assert `GA`, `H`, `24`, and `B` remain distinct atomic values with labels above them in both modes. [VERIFIED: `136-CONTEXT.md`; `priv/examples/ticket/aurora-live/ticket.json`]

## Code Examples

### Dev-only profile selection boundary

```elixir
# Repository pattern; exact private names are planner discretion.
defp catalog_profile(%{id: id}) when id in @visual_target_ids do
  Map.fetch!(@visual_profiles, id)
end

defp catalog_profile(_spec), do: []

# source_document_for/1 retains its one recipe entry point.
profile = catalog_profile(spec)
doc = spec.recipe_module.document(data, [theme: theme, catalog_layout: true] ++ profile)
```

The test must prove the profile map contains exactly the locked IDs; the profile value, not catalog identity, is the only new recipe input. [VERIFIED: `dev/rendro/catalog.ex`; `136-CONTEXT.md`]

### Candidate isolation assertion

```elixir
assert candidate["diff"]["changed_scored"] == @six_target_ids
assert candidate["diff"]["changed_unscored"] == []
assert candidate["diff"]["byte_stable"] == @twenty_six_control_ids
```

Keep ordering literal and compare both candidate PDF and PNG identity through the existing manifest classification, not only a rendered image list. [VERIFIED: `dev/rendro/catalog.ex`; `test/rendro/catalog_test.exs`; `136-CONTEXT.md`]

## State of the Art

| Old approach | Current approach | Impact |
|---|---|---|
| Retired milestone-specific catalog routes | One manual `Catalog Evidence` exact-SHA workflow with closed review/canonical bundle roles | Phase 136 consumes one generic evidence lane and must not resurrect legacy routes. [VERIFIED: `.github/workflows/catalog-evidence.yml`; Phase 135 verification] |
| Raw/implicit dark text treatments | Semantic palette roles selected by internal presentation profile | Bounded contrast repair without global theme/preset byte churn. [VERIFIED: `136-CONTEXT.md`; `brand/tokens/tokens.json`] |

## Assumptions Log

All plan-relevant claims were verified against the local codebase, locked context, current brand guidance, or cited primary documentation; no user confirmation is needed for an assumed implementation decision.

## Open Questions (RESOLVED)

1. **Exact numeric widths/tones/font sizes**
   - What we know: the decisions intentionally delegate these values; the engine can measure rows and themes expose semantic roles.
   - Resolution: exact values remain profile-private implementation details and are tuned only against one deterministically validated exact-SHA candidate bundle. ExUnit must first enforce the locked typography roles, measured geometry, default/no-profile bytes, target-pair parity, and six/26 scope. Raster iteration may change only the six target profiles; it may not alter public API, default/no-theme behavior, unrelated themes, global Theme/preset tokens, caller data, the render pipeline, or the 26 controls. A reviewer miss triggers another bounded candidate SHA rather than widening the blast radius.
   - Status: RESOLVED — Plans 01-04 own invariant-safe profile tuning; Plans 05-06 own exact-SHA validation and promotion gates.

2. **Human score/provenance authoring after the first candidate**
   - What we know: candidate evidence cannot carry reviewer fields; current rubric schema/projection accepts reviewer-owned binding fields.
   - Resolution: score values, reviewer/date, rationale, and artifact URL/digest are authored only by the named advisory human record after deterministic validation of the exact candidate SHA, renderer, run/attempt, PDF/PNG hashes, closed roles, and counts. Generator/candidate code never creates, rounds, clamps, infers, or edits those values. If review is absent, incomplete, or misses, the cell stays unreviewed/unpromoted with an explicit deferral and next action; deterministic execution continues and canonical artifacts remain unchanged. Canonical materialization is a later task and requires six complete threshold-meeting records plus exact six/26 proof.
   - Status: RESOLVED — Plan 05 owns non-blocking advisory intake/deferral; Plan 06 owns deterministic eligibility and conditional canonical materialization.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir / Mix | Local recipe and ExUnit contracts | ✓ | OTP 28; project pins Elixir 1.19.5 | — |
| Git | Immutable SHA binding and local reproduction | ✓ | 2.41.0 | — |
| `jq` | Local manifest inspection / workflow commands | ✓ | 1.7.1 | Elixir JSON checks for test coverage |
| `actionlint` | Workflow guardrails if workflow docs are touched | ✓ | 1.7.12 | Existing workflow-text contracts |
| `pdfium-cli` | Full local raster review | ✗ | — | Use the pinned Ubuntu `Catalog Evidence` workflow; it downloads and verifies the executable. [VERIFIED: local probe; `.github/workflows/catalog-evidence.yml`] |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** Local PDFium review — remote exact-SHA pinned workflow is the designed evidence route.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit under Elixir 1.19.5 / OTP 28 |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/catalog_test.exs test/rendro/catalog_review_payload_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1` |
| Full deterministic command | `mix ci.fast` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| CATALOG-10 | Literal target allowlist is exactly six and every other catalog cell is byte-stable across PDF/PNG candidate classification | integration/contract | focused catalog tests above | Partial — add focused six/26 isolation cases |
| CATALOG-11 | Target profiles retain anchor hierarchy, semantic dark headers/labels, long-label/widest-money/atomic-ticket/repeat-header invariants, and two-render determinism | recipe unit + deterministic render | `mix test test/rendro/recipes/{invoice,statement,payslip,ticket}_*_test.exs --max-failures 1` (choose actual files in Wave 0) | Partial — profile-specific tests needed |
| CATALOG-11 | Exact renderer identity is reconciled before human full-size review; reviewer score is not generated | raster/advisory + contract | `RENDRO_CATALOG_REVIEW_DIR=tmp/catalog-evidence-review mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs` | Yes; remote PDFium required |
| CATALOG-12 | 32 cells, 20 unscored, dark `print_safety: false`, and no overclaim/projected-quality drift | docs/schema/contract | focused rubric/catalog-quality tests above | Yes; extend only for Phase 136 threshold distinction if absent |
| CATALOG-13 | Candidate SHA, PDFium pin, PDF/PNG hashes, run/attempt, role counts, reconciliation, and canonical publication path stay bound | bundle/reconciliation/workflow contract | `mix test test/rendro/catalog_review_payload_contract_test.exs test/rendro/catalog_raster_review_test.exs --max-failures 1` plus remote `review`/`canonical` dispatch | Yes |

### Sampling Rate

- **Per recipe/profile task:** the focused catalog + affected recipe test command, plus deterministic double-render checks.
- **Per wave merge:** `mix ci.fast` and `mix quality.governance`.
- **Evidence gate:** dispatch one full-SHA `review` workflow; validate bundle before review; only after documented review threshold and six/26 proof, dispatch/check `canonical`.
- **Phase gate:** `mix rendro.catalog.check`, `mix ci.fast`, and `mix quality.uat 136 --check`; human review remains advisory evidence, not a hidden blocking state. [VERIFIED: `AGENTS.md`; `.github/workflows/CATALOG-EVIDENCE.md`; `mix.exs`]

### Wave 0 Gaps

- [ ] Focused tests (new file or nearest existing recipe tests) for generic profile omission/activation, semantic dark header/label colors, anchor hierarchy, and no-theme/non-target byte identities.
- [ ] Payslip fixtures/tests for verbatim long descriptions, widest money token, sequential table headers, native continuation, reconciliation adjacency, and two-render identity.
- [ ] Ticket tests for `GA`, `H`, `24`, `B` source order, atomic values, label/value association, and light/dark identical geometry.
- [ ] Catalog candidate test asserting exact ordered six changed IDs and all 26 controls byte-stable; negative controls for an extra/missing/reordered target profile.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | No runtime auth/surface is added. [VERIFIED: `136-CONTEXT.md`] |
| V3 Session Management | No | No runtime session/surface is added. [VERIFIED: `136-CONTEXT.md`] |
| V4 Access Control | Yes, evidence control plane | Existing manual workflow's read-only permissions, detached SHA checkouts, and no credential persistence. [VERIFIED: `.github/workflows/catalog-evidence.yml`] |
| V5 Input Validation | Yes, evidence/file inputs | Existing closed role/path/count/hash/SHA validators; do not weaken them. [VERIFIED: `dev/rendro/catalog_evidence_bundle.ex`; `dev/rendro/catalog_review_payload.ex`] |
| V6 Cryptography | Yes, integrity only | Existing SHA-256 verification through OTP `:crypto`; do not hand-roll another scheme. [VERIFIED: catalog/evidence modules] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Candidate ref changes after dispatch | Tampering | Full lowercase SHA input, detached checkout, and literal HEAD equality. [VERIFIED: `.github/workflows/catalog-evidence.yml`] |
| Malformed/artifact-injected review payload | Tampering / Information disclosure | Closed names/roles/counts, safe relative paths, regular-file limit, checksum and manifest validation before interpretation. [VERIFIED: `.github/workflows/catalog-evidence.yml`; `dev/rendro/catalog_evidence_bundle.ex`] |
| Raster run mistaken for visual approval | Repudiation | Candidate bundle contains no scores; named per-cell reviewer record is separate. [VERIFIED: `test/rendro/catalog_review_payload_contract_test.exs`; `136-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)

- Repository implementation: `dev/rendro/catalog.ex`, evidence modules, four target recipes, palette/table-cell/theme, test contracts, catalog workflow/runbook, current rubric/schema/sign-off, and target fixtures — exact seams and current behavior. [VERIFIED: local codebase]
- Phase 136 context, requirements, roadmap, state, and Phase 135 verification — locked scope, target threshold, and inherited evidence authority. [VERIFIED: local planning artifacts]
- `brand/README.md`, `brand/tokens/tokens.json`, `brand/audit/AUDIT.md` — current brand precedence, semantic dark role and truthful-claim constraints. [VERIFIED: local codebase]

### Secondary (MEDIUM confidence)

- [ExUnit documentation](https://hexdocs.pm/ex_unit/ExUnit.html) — `mix test` / ExUnit test-discovery behavior (accessed 2026-08-27). [CITED: https://hexdocs.pm/ex_unit/ExUnit.html]
- [PDFium official repository documentation](https://pdfium.googlesource.com/pdfium/) — standalone rasterization/pixel-test context (accessed 2026-08-27). [CITED: https://pdfium.googlesource.com/pdfium/]

### Tertiary (LOW confidence)

- None used for decisions.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new stack; all facilities are repository-owned and inspected.
- Architecture: HIGH — locked context and exact existing call/evidence paths agree.
- Pitfalls: HIGH — directly reflected in current failed score justifications, immutable constraints, and contract tests.

**Research date:** 2026-08-27
**Valid until:** 2026-09-26 (repository state is the authority; refresh if the catalog/evidence implementation changes first).
