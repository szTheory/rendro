# Roadmap: Rendro v2.3 Viewer Proof & Interop Closure

**Defined:** 2026-05-08
**Granularity:** coarse
**Coverage:** 19/19 requirements mapped
**Phase numbering:** continues from v2.2 (which closed at phase 67); v2.3 is phases 68–72.

## Milestone Goal

Close the trust-sensitive viewer evidence gap surface-by-surface so public support claims for forms, protection, signature widgets, signing preparation, signed artifacts, and long-lived signed artifacts can be promoted with recorded per-viewer proof rather than deferred under blanket "unverified" rows. Establish a durable, repeatable operator-grade viewer-evidence recipe that future surfaces inherit.

This is intentionally a **recording-discipline milestone**, not an engineering one. Every engine surface in scope is already shipped (forms v1.8, embedded files + links v1.9, protection v1.10, signature widgets + signing prep v2.0, signed artifacts v2.1, long-lived v2.2). The structural change is one new state in the matrix vocabulary — `explicit_deferral` joining `supported` and `unverified` — and the manual recording workflow that produces honest evidence rows.

## Strategic Context

- v2.2 shipped on 2026-05-08 with `Rendro.Sign.augment/2`, the first-party long-lived adapter, validator-backed posture classification, and the `long-lived-live-proof` CI lane required on `main`.
- v2.3 is the next milestone in the active "production-ready trust and adoption" arc; per `MILESTONE-ARC.md`, viewer/interop closure precedes v2.4 batteries-included adoption work.
- Engine-level proof (structural validity, signing integrity, long-lived posture) is already proof-backed; per-viewer truth is the next blocker before stronger adoption claims.

## Phases

- [x] **Phase 68: Viewer Evidence Schema, Mix Task, and Docs-Contract Lane** — Land the additive matrix vocabulary, the schema validator, the operator mix task, and the docs-contract enforcement lane that everything else depends on. (completed 2026-05-28)
- [x] **Phase 69: Operator Recipe + First Cell End-to-End** — Publish `guides/viewer_evidence.md` and walk one full cell (forms × Apple Preview) end-to-end as the canonical worked example. (completed 2026-05-28)
- [ ] **Phase 70: Consolidate Already-Validated Surfaces (Wave 1, parallel-safe)** — Move the five pre-v2.3 `supported` rows into the canonical `priv/viewer_evidence/` home with `evidence:` pointers; no regression in published support.
- [ ] **Phase 71: Record New Trust-Sensitive Surfaces and Explicit Deferrals (Wave 2, parallel-safe)** — Walk every remaining (surface × viewer) cell across forms, protection, signature widgets, signing prep, signed artifacts, and long-lived; record promotions or `explicit_deferral` rows.
- [ ] **Phase 72: Closure — Audit, Polish, and Ship** — Verify cell coverage, confirm engine-level required CI lanes remain green and required, polish guides, record the audit ledger, tag and ship.

## Phase Details

### Phase 68: Viewer Evidence Schema, Mix Task, and Docs-Contract Lane

**Goal**: Operators have a validated, additive matrix vocabulary plus the tooling and CI gate that makes recording-discipline failures visible before merge.
**Depends on**: Nothing (first phase of v2.3; builds on shipped v2.2 baseline)
**Requirements**: MATRIX-01, MATRIX-02, MATRIX-03, RECIPE-02, RECIPE-04, GUARDRAIL-01, GUARDRAIL-03, GUARDRAIL-04
**Success Criteria** (what must be TRUE):

  1. An operator can run `mix rendro.viewer_evidence list` against the unchanged matrix and see every (surface × viewer) cell categorized as `supported`, `explicit_deferral`, or `unverified` with no schema errors.
  2. An operator can run `mix rendro.viewer_evidence missing` and receive a deterministic report of every silently-`unverified` cell (no promotion, no named deferral).
  3. The new `test/docs_contract/viewer_evidence_claims_test.exs` lane fails CI when an operator drafts a `supported` row without an `evidence:` pointer, an `explicit_deferral` row without a named reason, a deferral reason containing forbidden vocabulary (`TBD`, `not yet`, `deferred for later`, empty string), or an evidence file containing image syntax / inline binaries / operational-secret tokens (`-----BEGIN`, `passphrase`, `private_key`) / absolute home-directory paths / files larger than the documented byte budget.
  4. An attempt to introduce a non-additive schema mutation on `priv/support_matrix.json` (renamed field, retyped field, removed field, or a new compliance/trust/multi-signature key on a viewer row) fails the JSON-Schema validator before merge.
  5. Existing v1.5–v2.2 docs-contract lanes still pass against the unchanged `priv/support_matrix.json` after the additive fields are introduced.

**Plans**: 3/3 complete (68-01, 68-02, 68-03)
**Pitfall guardrails for this phase**:

  - Engine-level required lanes (`signing-live-proof`, `long-lived-live-proof`, `mix ci`, structural validation) must remain required and unchanged in semantics.
  - Schema mutations on `priv/support_matrix.json` must stay strictly additive; no compliance/trust/multi-signature keys on viewer rows.
  - The new lane is structural-only and named accordingly (`viewer-evidence-schema`-style naming, never `viewer-proof`); folds into the existing required `test` job through `scripts/verify_docs.exs` rather than introducing a new required CI lane.
  - Evidence-file linting must enforce text-only, fixtures-by-path-or-hash, no inline binaries, no operational secrets, ~64KB byte budget per file.

### Phase 69: Operator Recipe + First Cell End-to-End

**Goal**: A second operator can follow `guides/viewer_evidence.md` start-to-finish and record a new (surface × viewer) cell without asking questions, with the recipe smoke-tested on one real cell before broader recording starts.
**Depends on**: Phase 68
**Requirements**: RECIPE-01, RECIPE-03, RECIPE-05
**Gap Closure:** Closes gaps from v2.3 milestone audit (2026-05-28) — RECIPE-01/03/05, integration 68→69, flow "Operator records one cell"
**Success Criteria** (what must be TRUE):

  1. An operator opening HexDocs sees `guides/viewer_evidence.md` listed under the `Policies` extras group next to `guides/api_stability.md`, and the guide walks them end-to-end through recording one cell (frontmatter, per-behavior checklist, fixture pattern, explicit-deferral discipline).
  2. The canonical evidence template at `priv/viewer_evidence/<surface>/<viewer>.md` produces a file with YAML frontmatter (viewer, viewer_version, OS+platform, fixture path or hash, recorded_at, per-behavior result table, optional operator handle) and a Markdown body with prose context, validated by `mix rendro.viewer_evidence validate`.
  3. One full cycle has been walked end-to-end against forms × Apple Preview (consolidating the existing v1.8 Phase 47 record): operator checklist → frontmatter file → matrix promotion with `evidence:` pointer → docs-contract lane passes.
  4. `guides/api_stability.md` documents the rule that every cell promotion (`unverified` → `supported`) and every new `explicit_deferral` lands as a public-contract change in CHANGELOG so the discipline is inherited by future surfaces.

**Plans**: TBD
**Pitfall guardrails for this phase**:

  - Reproducibility: every evidence file must carry seven fields (fixture pointer, viewer version, OS+platform, per-behavior result table, one-line reason per entry, date recorded, optional operator handle).
  - Storage / PII: text-only Markdown only, no inline screenshots, fixtures referenced by checked-in path or content hash, no operational-secret vocabulary.
  - Honest-failure vocabulary baked into the recipe: deferrals must name a specific viewer behavior or version.

### Phase 70: Consolidate Already-Validated Surfaces (Wave 1, parallel-safe)

**Goal**: Every viewer row that was already `supported` before v2.3 carries a checked-in `evidence:` pointer in the canonical home, with no regression in published support.
**Depends on**: Phase 69
**Parallel-safe with**: Phase 71 (disjoint files; no merge conflicts)
**Requirements**: VIEWER-01
**Gap Closure:** Closes gaps from v2.3 milestone audit (2026-05-28) — VIEWER-01, integration 68→70, flow "Consolidate 5 legacy supported rows"
**Success Criteria** (what must be TRUE):

  1. Each of the five pre-v2.3 `supported` viewer rows — forms × Apple Preview (v1.8 Phase 47), embedded_files × Adobe Acrobat Reader (v1.9), links × Adobe Acrobat Reader (v1.9), links × Apple Preview (v1.9), protection × Apple Preview (v1.10 Phase 54) — has a recorded evidence file at `priv/viewer_evidence/<surface>/<viewer>.md` referenced by an `evidence:` pointer in `priv/support_matrix.json`.
  2. `mix rendro.viewer_evidence list` reports each of those five rows as `supported` with a resolvable `evidence:` pointer and a `recorded_at` date traceable to the prior milestone audit.
  3. Re-running every existing v1.5–v2.2 docs-contract lane (forms claims, signing claims, embedded artifact claims, protection claims, integrations claims/contract, README doctest) passes unchanged — no regression in published support.
  4. `guides/api_stability.md` prose for each of the five rows points at the canonical `priv/viewer_evidence/` evidence file rather than referring back to phase summaries.

**Plans**: TBD
**Pitfall guardrails for this phase**:

  - No regression in published support — a row's `status` cannot demote during consolidation.
  - All five evidence files must use the Phase 69 template; no shape drift across the wave.
  - No new top-level keys, no new row families, no compliance/trust language smuggled in alongside consolidation.

### Phase 71: Record New Trust-Sensitive Surfaces and Explicit Deferrals (Wave 2, parallel-safe)

**Goal**: Every (shipped-surface × named-viewer) cell that was `unverified` at v2.3 start ends in either `supported` (with recorded evidence) or `explicit_deferral` (with a named reason); no silent `unverified` cells remain across the trust-sensitive surfaces.
**Depends on**: Phase 69
**Parallel-safe with**: Phase 70 (disjoint files; no merge conflicts)
**Requirements**: VIEWER-02, VIEWER-03, VIEWER-04, VIEWER-05, VIEWER-06, VIEWER-07
**Gap Closure:** Closes gaps from v2.3 milestone audit (2026-05-28) — VIEWER-02 through VIEWER-07, integration 68→71, flow "Record remaining trust-sensitive cells"
**Success Criteria** (what must be TRUE):

  1. An operator can run `mix rendro.viewer_evidence list` and see Adobe Acrobat Reader rows recorded as `supported` with evidence files for `forms` (4-check checklist), `protection` (5-check checklist), `signature_widget`, `signing_preparation`, `signed_artifact` (with integrity and certificate-trust captured as separate signals), and `long_lived_signed_artifact` (using the certomancer-backed long-lived fixture chain).
  2. Apple Preview × signature_widget and PDFium × {forms, signature_widget, signed_artifact} are recorded as `supported` with evidence files where the viewer renders/handles the surface truthfully; PDFium evidence files pin exact host app + host-app version + PDFium version.
  3. PDF.js × signature_widget is recorded as `explicit_deferral` with the Mozilla `#4202` non-implementation as the named reason; Apple Preview × signed_artifact and PDF.js × signed_artifact are recorded as `explicit_deferral` naming each viewer's lack of `/Sig` validation (and Preview's append-save invalidation behavior); Apple Preview × long_lived, PDFium × long_lived, and PDF.js × long_lived are recorded as `explicit_deferral` naming "viewer does not implement long-term-validation indicators."
  4. `guides/api_stability.md` documents the signing-preparation × signature-widget equivalence note for viewers where the cells are behaviorally indistinguishable, so operators do not double-record.
  5. The docs-contract lane passes against every newly-recorded cell — every `supported` row resolves to an evidence file, every `explicit_deferral` row carries a named reason that does not match the forbidden-vocabulary list, and no orphan evidence file exists without a matching matrix row.

**Plans**: TBD
**Pitfall guardrails for this phase**:

  - Per-behavior promotion only: behavioral verbs (`edit_or_toggle`, `save_and_reopen`), never `looks_correct` or `displays_without_error`; integrity and trust must be recorded as separate signals on signed-artifact rows.
  - PDFium rows must record exact host app + version + platform — `chrome_pdfium` is not one viewer.
  - No widening of engine code to please specific viewers: viewer gaps are recorded as `explicit_deferral`, never patched into the writer.
  - Explicit-deferral reasons must name a specific viewer behavior or version; forbidden vocabulary (`TBD`, `not yet`, `deferred for later`, empty string) blocked at docs-contract level.
  - Text-only evidence files with fixtures by path-or-hash; no inline binaries; no operational secrets.

### Phase 72: Closure — Audit, Polish, and Ship

**Goal**: The milestone ships with every viewer claim either backed by a checked-in evidence file or carrying a recorded named deferral, the engine-level trust spine is verified unchanged, and the operator-grade recipe is durable for future surfaces.
**Depends on**: Phase 70 and Phase 71
**Requirements**: GUARDRAIL-02
**Gap Closure:** Closes gaps from v2.3 milestone audit (2026-05-28) — GUARDRAIL-02, integration 69→72, flow "Milestone closure audit"
**Success Criteria** (what must be TRUE):

  1. The milestone-close audit verifies the GitHub branch protection on `main` still requires every engine-level lane shipped before v2.3 (`signing-live-proof`, `long-lived-live-proof`, `mix ci`, structural validation, all v1.5–v2.2 docs-contract lanes) — the required-check list grew or stayed flat, never shrank, and no behavioral lane was diluted by viewer-evidence work.
  2. `mix rendro.viewer_evidence list` confirms every (shipped-surface × named-viewer) cell is in one of `supported`, `explicit_deferral`, or expected-empty `unverified`; `mix rendro.viewer_evidence missing` is empty (or expected-empty per recorded operator-capacity disclaimer).
  3. `guides/api_stability.md` prose mirrors every promoted row and every explicit-deferral row by pointer or named reason; `guides/viewer_evidence.md` worked example is current.
  4. `72-VERIFICATION.md` records the final cell-by-cell ledger and the verified required-check list; the milestone is tagged and shipped.

**Plans**: TBD
**Pitfall guardrails for this phase**:

  - The required-check audit is the load-bearing closure step: confirm `signing-live-proof` and `long-lived-live-proof` remain required and unchanged in semantics; confirm any new lane added in v2.3 is structural-only and additive.
  - No new top-level keys or row families in `priv/support_matrix.json`; close-out audit verifies scope guardrail held end-to-end.
  - Closure must not flip any cell from `supported` to `unverified` without a recorded `not_promoted_reason`-style audit trail; demotion is a public-contract change.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 68. Viewer Evidence Schema, Mix Task, and Docs-Contract Lane | 3/3 | Complete    | 2026-05-28 |
| 69. Operator Recipe + First Cell End-to-End | 3/3 | Complete    | 2026-05-28 |
| 70. Consolidate Already-Validated Surfaces | 0/0 | Not started | - |
| 71. Record New Trust-Sensitive Surfaces and Explicit Deferrals | 0/0 | Not started | - |
| 72. Closure — Audit, Polish, and Ship | 0/0 | Not started | - |

## Requirement Coverage

| Phase | Requirements |
|-------|--------------|
| 68 | MATRIX-01, MATRIX-02, MATRIX-03, RECIPE-02, RECIPE-04, GUARDRAIL-01, GUARDRAIL-03, GUARDRAIL-04 |
| 69 | RECIPE-01, RECIPE-03, RECIPE-05 |
| 70 | VIEWER-01 |
| 71 | VIEWER-02, VIEWER-03, VIEWER-04, VIEWER-05, VIEWER-06, VIEWER-07 |
| 72 | GUARDRAIL-02 |

**Coverage:** 19/19 v2.3 requirements mapped (no orphans, no duplicates).

## Dependency Graph

```
Phase 68 (schema/task/test)  ─────► Phase 69 (recipe + first cell)
                                          │
                                          ├────► Phase 70 (consolidate already-validated)
                                          │              │
                                          │              ├────► Phase 72 (closure & ship)
                                          │              │
                                          └────► Phase 71 (record new + defer rest)
                                                         │
                                                         └────────────────┘
```

Phase 68 is the only blocker. Phase 69 is the recipe smoke test. Phases 70 and 71 are independent and can execute in parallel waves (disjoint files, no merge conflicts). Phase 72 is the standard milestone-close ritual.

## Cross-Milestone Guardrails (apply to every phase)

These five guardrails must hold across the entire milestone and are referenced from each phase's pitfall-guardrail block:

1. **Engine-level required CI lanes preserved.** `signing-live-proof` and `long-lived-live-proof` remain required on `main` and unchanged in semantics. The required-check list grows additively, never shrinks. `mix ci`, structural validation, and v1.5–v2.2 docs-contract lanes stay green throughout.
2. **Additive-only schema discipline.** `priv/support_matrix.json` extensions are strictly additive. No new top-level keys, no compliance/signer-trust/multi-signature keys on viewer rows, no field renames, no field retypes.
3. **Explicit-deferral vocabulary discipline.** Deferral reasons must name a specific viewer behavior or version; forbidden vocabulary (`TBD`, `not yet`, `deferred for later`, empty strings, unspecified-viewer language) is blocked at docs-contract level.
4. **Evidence file safety.** Text-only Markdown, fixtures by repo-path or content hash, no inline binaries, no operational-secret tokens (`-----BEGIN`, `passphrase`, `private_key`), no absolute home-directory paths, default ~64KB per file.
5. **No engine widening on viewer feedback.** Per-viewer engine workarounds and polyfills are out of scope; viewer gaps are recorded as `explicit_deferral`, never patched into the writer.

## Out of Scope (held from `MILESTONE-ARC.md` and `REQUIREMENTS.md`)

- Blanket "works in standard viewers" support row — directly contradicts the milestone thesis.
- Compliance-tier viewer claims (PDF/A, PDF/UA, ETSI EN 319 142 PAdES) — conflates viewer behavior with compliance.
- Multi-signature workflow viewer behavior — not a shipped engine surface.
- Per-viewer engine workarounds or polyfills — record gaps as `explicit_deferral` instead.
- Promoting cells based on third-party screenshots, blog posts, or community claims — promotion-grade evidence requires recorded in-repo proof.
- Headless-browser automated viewer CI — smuggles a browser runtime into core; deferred to a separate future automation milestone if at all.
- In-core key custody, certificate-store management, HSM orchestration — trust operations remain optional adapters or external infrastructure.
- Splitting `signing_preparation` from `signature_widget` rows when the viewer cannot tell them apart — document the equivalence in `guides/api_stability.md` instead.

## Sources

- `.planning/PROJECT.md` (v2.3 milestone definition, constraints, key decisions)
- `.planning/REQUIREMENTS.md` (the 19 v2.3 requirements mapped above)
- `.planning/MILESTONE-ARC.md` (active strategic arc; v2.3 ordering logic)
- `.planning/MILESTONES.md` (v2.2 closed at phase 67; v2.3 starts at 68)
- `.planning/research/SUMMARY.md` (HIGH-confidence synthesis of stack/features/architecture/pitfalls)
- `.planning/research/ARCHITECTURE.md` (5-phase build order with parallel-safe waves)
- `.planning/research/PITFALLS.md` (8 named pitfalls each mapped to a guardrail phase)

---
*Roadmap created: 2026-05-08 from v2.3 requirements + research synthesis.*
