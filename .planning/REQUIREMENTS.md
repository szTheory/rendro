# Requirements: Rendro v2.3 Viewer Proof & Interop Closure

**Defined:** 2026-05-08
**Status:** In progress (Phase 68 complete; gap closure phases 69–72 operationalized 2026-05-28)
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## Milestone Goal

Close the trust-sensitive viewer evidence gap surface-by-surface so public support claims for forms, protection, signature widgets, signing preparation, signed artifacts, and long-lived signed artifacts can be promoted with recorded per-viewer proof rather than deferred under blanket "unverified" rows. Establish a durable, repeatable operator-grade viewer-evidence recipe that future surfaces inherit.

This is intentionally a **recording-discipline milestone**, not an engineering one. Every engine surface in scope is already shipped (forms v1.8, embedded files + links v1.9, protection v1.10, signature widgets + signing prep v2.0, signed artifacts v2.1, long-lived v2.2). The structural change is one new state in the matrix vocabulary — `explicit_deferral` joining `supported` and `unverified` — and the manual recording workflow that produces honest evidence rows.

## In-Scope Requirements

### Support-Matrix Vocabulary & Schema

- [x] **MATRIX-01**: `priv/support_matrix.json` carries a third documented row state `explicit_deferral` (alongside `supported` and `unverified`) with a required `evidence_deferred` reason that names a specific viewer behavior or version, so cells where a viewer fundamentally does not implement a surface are recorded as named non-promotions distinct from un-attempted cells.
- [x] **MATRIX-02**: `supported` viewer rows in `priv/support_matrix.json` carry additive `evidence:` (repo-relative pointer to `priv/viewer_evidence/<surface>/<viewer>.md`), `recorded_at:` (ISO date), and `viewer_kind:` (`manual | pdfium-cli | pdfjs-dist`) fields without renaming or removing any existing field, so existing v1.5–v2.2 readers continue to pass.
- [x] **MATRIX-03**: Matrix shape is enforced by an in-tree JSON-Schema validator (Draft 2020-12) wired to the existing required `test` job, so an unevidenced `supported` row, a deferred row missing its reason, or a non-additive schema mutation fails CI before merge.

### Operator-Grade Recipe (Durability Layer)

- [x] **RECIPE-01**: A canonical home `priv/viewer_evidence/<surface>/<viewer>.md` exists for one (surface × viewer) evidence record, with YAML frontmatter (viewer, viewer_version, OS+platform, fixture path or hash, recorded_at, per-behavior result table, optional operator handle) and a Markdown body for prose context.
- [x] **RECIPE-02**: Operators can run `mix rendro.viewer_evidence` to list every (surface × viewer) cell against `priv/support_matrix.json`, validate evidence-file frontmatter against the schema, and report which cells are silently `unverified` (missing both promotion and explicit-deferral) so coverage gaps are auditable.
- [x] **RECIPE-03**: A single operator entry point `guides/viewer_evidence.md` (registered under the existing `Policies` extras group next to `guides/api_stability.md`) walks an operator end-to-end through recording one cell, including the fixture pattern, the per-behavior checklist for each surface, and the explicit-deferral discipline.
- [x] **RECIPE-04**: A new docs-contract lane `test/docs_contract/viewer_evidence_claims_test.exs` (modeled on the existing `protection_claims_test.exs`) rejects `supported` rows missing a resolvable `evidence:` pointer, rejects `explicit_deferral` rows missing a named reason, rejects forbidden vocabulary in deferral reasons (`TBD`, `not yet`, `deferred for later`, empty strings), and rejects orphan evidence files with no matching matrix row.
- [x] **RECIPE-05**: Every cell promotion (`unverified` → `supported`) and every new explicit-deferral lands in CHANGELOG as a public-contract change, with the rule documented in `guides/api_stability.md` so future surfaces inherit the discipline.

### Recorded Per-Viewer Evidence

- [x] **VIEWER-01**: The five existing `supported` viewer rows shipped before v2.3 (forms × Apple Preview from v1.8 Phase 47; embedded_files × Acrobat, links × Acrobat, links × Apple Preview from v1.9; protection × Apple Preview from v1.10 Phase 54) are consolidated into the canonical `priv/viewer_evidence/<surface>/<viewer>.md` home with `evidence:` pointers added to their matrix entries, with no regression in published support.
- [ ] **VIEWER-02**: A `forms` per-viewer behavioral checklist (`open` → `default_state_visible` → `edit_or_toggle` → `save`) is recorded against Adobe Acrobat Reader; the matrix `forms.viewers.acrobat_reader` row is promoted to `supported` with an `evidence:` pointer.
- [ ] **VIEWER-03**: A `protection` per-viewer behavioral checklist (`opens_with_open_password` → `displays_authored_content_correctly` → `advisory_print_behavior` → `advisory_copy_behavior` → `save_and_reopen_readability`) is recorded against Adobe Acrobat Reader; the matrix `protection.viewers.acrobat_reader` row is promoted to `supported` with an `evidence:` pointer.
- [ ] **VIEWER-04**: A `signature widgets` per-viewer behavioral checklist (`opens_without_signature_warning_or_with_truthful_warning` → `widget_renders_as_unsigned_placeholder_rectangle` → `does_not_falsely_claim_signed` → `signature_panel_or_equivalent_reports_unsigned_or_silent` → `save_and_reopen_preserves_widget`) is recorded against Adobe Acrobat Reader, Apple Preview, and PDFium where the viewer renders the placeholder truthfully; PDF.js × signature widgets is recorded as `explicit_deferral` with the Mozilla `#4202` non-implementation as the named reason.
- [ ] **VIEWER-05**: A `signing preparation` per-viewer behavioral checklist (`prepared_artifact_opens_cleanly` → `widget_renders_as_unsigned_placeholder` → `viewer_does_not_silently_re_sign_or_corrupt` → `byte_range_layout_intact_after_save_as`) is recorded against Adobe Acrobat Reader, with a documented equivalence note in `guides/api_stability.md` for viewers where signing-prep and signature-widget cells are behaviorally indistinguishable.
- [ ] **VIEWER-06**: A `signed artifacts` per-viewer behavioral checklist (`opens_signed_artifact_without_corruption` → `appearance_renders` → `integrity_reported_truthfully` → `certificate_trust_reported_separately` → `save_and_reopen_preserves_signature_or_warns`) is recorded against Adobe Acrobat Reader with integrity and trust captured as separate signals; Apple Preview × signed artifacts and PDF.js × signed artifacts are recorded as `explicit_deferral` rows naming the viewer's lack of `/Sig` validation (and Preview's append-save invalidation behavior) as the reason.
- [ ] **VIEWER-07**: A `long-lived signed artifacts` per-viewer behavioral checklist (`opens_long_lived_artifact_without_corruption` → `timestamp_recognized_or_silent` → `revocation_evidence_recognized_or_silent` → `posture_reported_truthfully` → `expiry_behavior_honest`) is recorded against Adobe Acrobat Reader using the certomancer-backed long-lived fixture chain; Apple Preview, PDFium, and PDF.js × long-lived rows are recorded as `explicit_deferral` with "viewer does not implement long-term-validation indicators" as the named reason.

### Discipline Guardrails

- [x] **GUARDRAIL-01**: Explicit-deferral rows must name a specific viewer behavior or version; the forbidden-vocabulary scan in the docs-contract lane prevents `TBD`, `not yet`, `deferred for later`, empty strings, and unspecified-viewer language from landing on `main`.
- [ ] **GUARDRAIL-02**: The engine-level required CI lanes shipped before v2.3 (`signing-live-proof`, `long-lived-live-proof`, `mix ci`, structural validation) remain required on `main` and unchanged in semantics; the milestone-close audit verifies the required-check list grew, never shrank, and that no behavioral lane was diluted by viewer-evidence work.
- [x] **GUARDRAIL-03**: `priv/support_matrix.json` extensions are strictly additive; no new top-level keys, no compliance/signer-trust/multi-signature keys on viewer rows, no field renames, no field retypes — schema-coupling pitfalls are blocked at the schema-validator level rather than caught in review.
- [x] **GUARDRAIL-04**: Evidence files are text-only and within a documented byte budget (default ~64KB), embed fixtures by repo-path or content hash rather than inline binaries, and reject operational-secret tokens (`-----BEGIN`, `passphrase`, `private_key`) and absolute home-directory paths via the docs-contract scan.

## Future Requirements

Deferred to later milestones; tracked but not in v2.3 scope.

- Optional first-party `Rendro.Adapters.Pdfium` and `Rendro.Adapters.PdfJs` automatable observer adapters (force multipliers for evidence recording; v2.3 ships manual-only)
- Headless-browser PDF.js / PDFium rendering CI lanes (own automation milestone)
- Mobile viewer evidence (iOS Files, Android default viewer) — likely v2.4 adoption work
- Annual or semi-annual re-verification cadence enforcement (advisory in v2.3, possibly blocking later)
- Per-platform Acrobat variants (Acrobat Pro on Windows vs macOS, Reader vs Pro) as separate matrix rows, only if drift bites
- Promotion of viewer rows for surfaces not yet shipped (e.g., multi-signature workflows)

## Out of Scope

Explicit exclusions; documented to prevent scope creep mid-milestone.

| Feature | Reason |
|---------|--------|
| Blanket "works in standard viewers" support row | Directly contradicts the milestone thesis; PROJECT.md and MILESTONE-ARC.md name it out-of-scope. Per-(surface × viewer) rows only. |
| Compliance-tier viewer claims (PDF/A, PDF/UA, ETSI EN 319 142 PAdES) | Conflates viewer behavior with compliance. v2.2's `signing.long_lived` taxonomy was carefully kept separate; v2.3 must not re-conflate. |
| Multi-signature workflow viewer behavior | Multi-signature has not shipped as an engine surface; recording its viewer behavior would manufacture a public expectation of a feature that does not exist. |
| Per-viewer engine workarounds or polyfills | Widening engine code on viewer feedback (e.g., monkey-patching the writer to please PDF.js) is the wrong direction; record the gap as `explicit_deferral` instead. |
| Promoting cells based on third-party screenshots, blog posts, or community claims | Promotion-grade evidence requires `viewer + version + OS + fixture + date checked + per-behavior pass/fail`, recorded in-repo. Anything else is hearsay. |
| Headless-browser automated viewer CI | Smuggles a browser runtime into core; explicitly forbidden by project constraints. Belongs to a separate future automation milestone if at all. |
| In-core key custody, certificate-store management, HSM orchestration | Trust operations remain optional adapters or external infrastructure; v2.3 records viewer behavior, not trust posture. |
| Splitting `signing_preparation` from `signature_widget` rows when the viewer cannot tell them apart | Manufactured recording busywork; document the equivalence in `guides/api_stability.md` instead. |

## Traceability

Populated by gsd-roadmapper on 2026-05-08 from the v2.3 roadmap (phases 68–72).

| Requirement | Phase | Status |
|-------------|-------|--------|
| MATRIX-01 | 68 | Complete |
| MATRIX-02 | 68 | Complete |
| MATRIX-03 | 68 | Complete |
| RECIPE-01 | 69 | Complete |
| RECIPE-02 | 68 | Complete |
| RECIPE-03 | 69 | Complete |
| RECIPE-04 | 68 | Complete |
| RECIPE-05 | 69 | Complete |
| VIEWER-01 | 70 | Complete |
| VIEWER-02 | 71 | Pending |
| VIEWER-03 | 71 | Pending |
| VIEWER-04 | 71 | Pending |
| VIEWER-05 | 71 | Pending |
| VIEWER-06 | 71 | Pending |
| VIEWER-07 | 71 | Pending |
| GUARDRAIL-01 | 68 | Complete |
| GUARDRAIL-02 | 72 | Pending |
| GUARDRAIL-03 | 68 | Complete |
| GUARDRAIL-04 | 68 | Complete |

**Coverage:**

- v2.3 requirements: 19 total
- Mapped to phases: 19 (phases 68–72)
- Unmapped: 0

**Phase distribution:**

- Phase 68 (schema/task/docs-contract lane): 8 requirements (MATRIX-01, MATRIX-02, MATRIX-03, RECIPE-02, RECIPE-04, GUARDRAIL-01, GUARDRAIL-03, GUARDRAIL-04)
- Phase 69 (operator recipe + first cell): 3 requirements (RECIPE-01, RECIPE-03, RECIPE-05)
- Phase 70 (consolidate already-validated, parallel-safe with 71): 1 requirement (VIEWER-01)
- Phase 71 (record new + explicit deferrals, parallel-safe with 70): 6 requirements (VIEWER-02 through VIEWER-07)
- Phase 72 (closure / audit / ship): 1 requirement (GUARDRAIL-02)

---
*Requirements defined: 2026-05-08*
*Last updated: 2026-05-28 after v2.3 milestone audit gap closure (phases 69–72 confirmed; 11 requirements pending).*
