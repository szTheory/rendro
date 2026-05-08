# Research Summary — v2.3 Viewer Proof & Interop Closure

**Project:** Rendro (pure-Elixir, Phoenix-first PDF/document generation library)
**Domain:** Per-viewer evidence recording for already-shipped surfaces (forms, protection, signature widgets, signing preparation, signed artifacts, long-lived signed artifacts) across Adobe Acrobat (Reader/Pro), Apple Preview, PDFium (Chromium-family), and PDF.js (Mozilla)
**Date:** 2026-05-08
**Confidence:** HIGH

## Headline

v2.3 is intentionally NARROW: a *recording-discipline* milestone, not an engineering one. Every engine surface in scope (forms v1.8, links/embedded files v1.9, protection v1.10, signature widgets + signing preparation v2.0, signed artifacts v2.1, long-lived signed artifacts v2.2) has already shipped. v2.3's job is to walk each (surface × viewer) cell, record honest per-viewer evidence at `priv/viewer_evidence/<surface>/<viewer>.md`, and promote `priv/support_matrix.json` rows only where evidence completes. The structural change is one new state in the matrix vocabulary — `explicit_deferral` joining `supported` and `unverified` — so a viewer that *cannot* implement a surface (e.g., PDF.js × signature widget; Apple Preview × signature validation) is recorded as a named non-promotion rather than confused with an un-attempted cell. Engineering effort is LOW. Manual recording effort is the dominant cost. Once shipped, every public viewer claim is either backed by a checked-in evidence file or carries a recorded named deferral; the operator-grade recipe (`guides/viewer_evidence.md` + `mix rendro.viewer_evidence`) makes the discipline durable for future surfaces.

## Stack additions

- `{:jsv, "~> 0.18", only: [:dev, :test], runtime: false}` — Draft 2020-12 JSON-Schema validator for `priv/support_matrix.json` and the new evidence frontmatter; build-time only, never a runtime dep.
- (optional) `klippa-app/pdfium-cli ~> 0.10` — PATH-discovered observer binary for additive automatable PDFium evidence; same shape as existing `qpdf` / `pdfsig` adapters; pin to **minor**, never patch.
- (optional) `pdfjs-dist ~> 5.7` — Mozilla's pre-built tarball run from a checked-in `priv/viewer_proof/pdfjs/` Node script (no Chromium); pin to **minor**, exact resolved version recorded in evidence frontmatter.
- No new runtime hard deps. No browser runtime in core. No new `Rendro.*` runtime module.
- Manual viewers (Acrobat Reader/Pro, Apple Preview) remain operator-driven; their version + OS are recorded in evidence frontmatter, never auto-detected.

## Feature table stakes (one line each)

The minimum honest behavioral checks an operator must record per (surface × viewer) cell. Match the already-shipped checklist patterns in `priv/support_matrix.json`.

- **VIEWER-EVIDENCE-FORMS** — `open` → `default_state_visible` → `edit_or_toggle` → `save` (4 checks; reuses v1.8 Phase 47 forms proof shape).
- **VIEWER-EVIDENCE-PROTECTION** — `opens_with_open_password` → `displays_authored_content_correctly` → `advisory_print_behavior` → `advisory_copy_behavior` → `save_and_reopen_readability` (5 checks; reuses v1.10 Phase 54 protection proof shape).
- **VIEWER-EVIDENCE-SIGNATURE-WIDGETS** — `opens_without_signature_warning_or_with_truthful_warning` → `widget_renders_as_unsigned_placeholder_rectangle` → `does_not_falsely_claim_signed` → `signature_panel_or_equivalent_reports_unsigned_or_silent` → `save_and_reopen_preserves_widget` (5 checks; the *negative* "does NOT claim signed" check is critical).
- **VIEWER-EVIDENCE-SIGNING-PREP** — `prepared_artifact_opens_cleanly` → `widget_renders_as_unsigned_placeholder` → `viewer_does_not_silently_re_sign_or_corrupt` → `byte_range_layout_intact_after_save_as` (4 checks; equivalent to signature-widgets at the viewer level — document the equivalence, do not double-record).
- **VIEWER-EVIDENCE-SIGNED-ARTIFACTS** — `opens_signed_artifact_without_corruption` → `appearance_renders` → `integrity_reported_truthfully` → `certificate_trust_reported_separately` → `save_and_reopen_preserves_signature_or_warns` (5 checks; integrity vs. trust must be recorded as **two separate signals** — only Acrobat fully discriminates).
- **VIEWER-EVIDENCE-LONG-LIVED** — `opens_long_lived_artifact_without_corruption` → `timestamp_recognized_or_silent` → `revocation_evidence_recognized_or_silent` → `posture_reported_truthfully` → `expiry_behavior_honest` (5 checks; only Acrobat genuinely implements LTV UI; most other viewers explicit-defer).

## Differentiators

Recorded but never block promotion.

- **DIFF-LTV-INDICATOR** — capture Acrobat's exact "Signature is LTV enabled" UI string and screenshot for long-lived (Acrobat-only).
- **DIFF-PREVIEW-SIG-GAP-NOTE** — record Apple Preview's known append-save behavior on signed PDFs as a recorded disclaimer (closes a known integrity hazard transparently).
- **DIFF-PDFJS-APPEARANCE-PARITY** — record whether PDF.js rendered the form-field appearance stream identically to Acrobat (visual signal only; functional pass is what gates promotion).
- **DIFF-PDFIUM-CHROMIUM-CHANNEL** — record exact host app + host-app version + PDFium version (Chrome stable / canary / Edge / Brave / WebView2 all differ).
- **DIFF-VIEWER-VERSION** — viewer version + OS version next to every cell (already canonical; reinforce).
- **DIFF-NEGATIVE-PROOF-SCREENSHOT** — for explicit-deferral cells, capture a screenshot of the viewer's actual non-implementation so the deferral is concrete, not hand-waved.

## Anti-features (must reject in v2.3)

| Anti-feature | Why rejected |
|---|---|
| Automated headless-Chromium / Puppeteer / Playwright PDF.js CI | Smuggles a browser runtime into core; explicitly forbidden by project constraints. Belongs to a separate future automation milestone if at all. |
| A blanket "works in standard viewers" support row | Directly contradicts the milestone thesis; PROJECT.md and MILESTONE-ARC.md both name it out-of-scope. Per-(surface × viewer) rows only. |
| Promoting cells based on third-party screenshots, blog posts, or community claims | Promotion-grade evidence requires `viewer + version + OS + fixture + date checked + per-behavior pass/fail`, recorded in-repo. Anything else is hearsay. |
| Compliance-tier viewer claims (PDF/A, PDF/UA, ETSI EN 319 142 PAdES) | Conflates viewer behavior with compliance. v2.2's `signing.long_lived` taxonomy was carefully kept separate; v2.3 must not re-conflate. |
| Multi-signature workflow viewer behavior | Multi-signature has not shipped as an engine surface; recording its viewer behavior would manufacture a public expectation of a feature that does not exist. |
| Per-viewer engine workarounds / polyfills (e.g., monkey-patch the writer to please PDF.js) | Widening engine code on viewer feedback is exactly the wrong direction. Record the gap as an `explicit_deferral` row. |
| Splitting `signing_preparation` from `signature_widget` rows when the viewer cannot tell them apart | Manufactured recording busywork; document the equivalence in `guides/api_stability.md` instead. |

## Cell topology

Six surfaces × four viewers = **24 cells**. Net counts:

| State | Count | Notes |
|---|---|---|
| Already promoted (`supported`, recorded proof) | **5** | forms × Apple Preview (v1.8 P47); embedded_files × Acrobat (v1.9); links × Acrobat (v1.9); links × Apple Preview (v1.9); protection × Apple Preview (v1.10 P54). Out of v2.3 scope; v2.3 only consolidates these into the canonical home. |
| Open `unverified` cells targeted by v2.3 | **19** | The full v2.3 work surface. |
| Of those 19, expected to **promote** in v2.3 | **~6–8** | Acrobat × {forms, protection, signature widgets, signed artifacts, long-lived}; PDFium × {forms, signature widgets, signed artifacts}; Apple Preview × signature widgets. |
| Of those 19, expected to land as **`explicit_deferral`** | **~10–12** | E.g., PDF.js × signature widgets (mozilla/pdf.js#4202); Apple Preview × signed artifacts (no `/Sig` validation); Preview/PDFium/PDF.js × long-lived (no LTV UI); PDF.js × protection. |
| Residual silent `unverified` | acceptable | Only if operator capacity is the bottleneck; the recipe stays in place to close them later. |

## Architecture

```
priv/
├── support_matrix.json                  # MODIFIED — additive: evidence, recorded_at, viewer_kind, evidence_deferred
├── schemas/
│   ├── support_matrix.schema.json       # NEW — JSV-validated (Draft 2020-12)
│   └── viewer_evidence.schema.json      # NEW — frontmatter contract
└── viewer_evidence/                     # NEW directory; one file per (surface × viewer) cell
    └── <surface>/<viewer>.md            # YAML frontmatter + Markdown checklist body

guides/
├── api_stability.md                     # MODIFIED — per-promoted-row prose pointing at evidence files
└── viewer_evidence.md                   # NEW — single operator-grade recipe entry point (Policies group)

lib/mix/tasks/rendro/
└── viewer_evidence.ex                   # NEW — Mix.Tasks.Rendro.ViewerEvidence: list / validate / missing

test/docs_contract/
└── viewer_evidence_claims_test.exs      # NEW — eighth lane

scripts/verify_docs.exs                  # MODIFIED — one-line lane addition
mix.exs                                  # MODIFIED — extras: + jsv dev/test dep
```

- **No new `Rendro.*` runtime module.** Nothing inside the running library reads viewer evidence at runtime; the contract is build-time + audit-time only. A `Rendro.Support.ViewerEvidence` loader is over-engineering for v2.3.
- **No new required CI lane.** The schema check is deterministic in-Elixir validation; it folds correctly into the existing required `test` job through `scripts/verify_docs.exs`. A separate `viewer-evidence-schema` lane would be theatre.
- **`priv/support_matrix.json` extension is strictly additive.** A `supported` row gains `evidence:` (path), `recorded_at:` (ISO date), `viewer_kind:` (`manual | pdfium-cli | pdfjs-dist`); an `explicit_deferral` row gains `evidence_deferred:` (named prose). No field renamed, no field retyped, no field removed. `viewer_version` lives only inside the evidence file frontmatter so a viewer auto-update does not silently invalidate matrix rows.

## Watch out for (Pitfalls)

8 named pitfalls, each mapped to a guardrail phase.

1. **Overclaim** ("looks fine" promotion) — per-behavior promotion only; behavioral verbs (`edit_or_toggle`, `save_and_reopen`), never `looks_correct`; PDFium rows must record exact host app + version. Addressed in every recording phase + Phase 68 docs-contract test.
2. **Viewer-version drift** — record `recorded_at` per row; record exact `viewer_version` in evidence file (not in matrix); operator-grade re-validation discipline; `mix rendro.viewer_evidence` flags stale rows. Addressed in Phase 68 (schema) + Phase 69 (recipe).
3. **Scope creep** (compliance, signer trust, multi-sig, headless CI, new surfaces) — `MILESTONE-ARC.md` non-goals copied verbatim into every phase context; close-out audit verifies no new top-level matrix keys. Addressed across all phases + Phase 72.
4. **Schema coupling** — additive-and-optional only; no compliance/trust/multi-sig keys on viewer rows; `evidence:` is a pointer, not a frozen viewer version. Addressed in Phase 68.
5. **Reproducibility** — every evidence file MUST carry seven fields (fixture pointer, viewer version, OS+platform, per-behavior result table, one-line reason per entry, date recorded, optional operator handle). Addressed in Phase 69 (template) + Phases 70–71 (use template).
6. **Honest-failure vocabulary** — `not_promoted_reason` / `evidence_deferred` must name a viewer or version; forbidden vocabulary list (`TBD`, `not yet`, `deferred for later`, empty string) rejected by docs-contract test. Addressed in Phase 68 + Phases 70–71.
7. **CI dilution** — new lane is structural-only and named accordingly (`viewer-evidence-schema`, never `viewer-proof`); `signing-live-proof` and `long-lived-live-proof` remain required and unchanged; required-check list grows, never shrinks. Addressed in Phase 68 + Phase 72 audit.
8. **Storage / PII** — text-only evidence files (no inline images, no base64); fixtures by checked-in path or content hash; absolute home-directory paths and operational-secret tokens (`-----BEGIN`, `passphrase`, `private_key`) rejected by docs-contract scan; per-file byte budget (default ~64KB). Addressed in Phase 68 (lints) + Phase 69 (template) + Phases 70–71.

## Phase build order (68–72)

Phase 68 is the only blocker. Phases 70 and 71 are independent and **parallel-safe** (disjoint files, no merge conflicts).

- **Phase 68 — Schema, mix task, docs-contract lane (PREREQUISITE).** Create `priv/viewer_evidence/` (with `.gitkeep`), the two JSON schemas under `priv/schemas/`, `Mix.Tasks.Rendro.ViewerEvidence` (`list` / `validate` / `missing`), `test/docs_contract/viewer_evidence_claims_test.exs`, and the one-line addition to `scripts/verify_docs.exs`. Goal: validator passes against unchanged matrix; missing-cells report works.
- **Phase 69 — Operator recipe + first cell end-to-end.** Add `guides/viewer_evidence.md` (operator-grade recipe) + `mix.exs` `extras:` entry; record exactly **one cell** (recommended: forms × Apple Preview, consolidating the existing v1.8 Phase 47 record). Goal: full cycle walked once; recipe smoke-tested before broader recording starts.
- **Phase 70 — Consolidate already-validated surfaces (Wave 1, parallel-safe).** Move existing v1.9/v1.10 evidence into the canonical home: `embedded_files × acrobat`, `links × acrobat`, `links × apple_preview`, `protection × apple_preview`. Promote each row's matrix entry with `evidence:` pointer. Goal: every previously-`supported` viewer row carries a checked-in pointer; **no regression in published support**.
- **Phase 71 — Record new trust-sensitive surfaces + explicit deferrals (Wave 2, parallel-safe).** Walk every remaining (surface × viewer) cell: record evidence where promotable (Acrobat × {forms, protection, signed, long-lived}; PDFium × {forms, signature widgets, signed}); record `explicit_deferral` with named reason where the viewer fundamentally does not implement the surface (PDF.js × signature widgets; Apple Preview × signed/long-lived; etc.). Goal: every shipped-surface × named-viewer cell is in one of the three states; bulk of milestone manual labor lives here.
- **Phase 72 — Closure: audit, polish, ship.** `mix rendro.viewer_evidence list` confirms every cell is in a documented state; `mix rendro.viewer_evidence missing` is empty (or expected-empty); `guides/api_stability.md` prose mirrors every promoted row; `guides/viewer_evidence.md` worked example is current; required-check list on `main` is verified unchanged-plus-additive; `72-VERIFICATION.md` records the final cell-by-cell ledger; tag and ship.

## Open questions (surface during phase planning)

- **Exact viewer versions to pin in evidence files** — Acrobat Reader/Pro builds, Preview macOS version, Chrome/Edge stable channel, Firefox PDF.js bundle. Recommendation: capture each operator's actual installation; do not pre-prescribe.
- **Per-evidence-file byte budget** — research recommends default ~64KB; final number to be set in Phase 68 schema.
- **Staleness threshold for `recorded_at`** — research recommends 6 months as advisory; whether to make this blocking in the closure phase or only advisory is a Phase 68/72 decision.
- **Whether to ship the optional `Rendro.Adapters.Pdfium` and `Rendro.Adapters.PdfJs` automatable observers in v2.3 or defer to v2.4** — STACK.md and ARCHITECTURE.md agree the manual-only path is fully sufficient for v2.3 ship; the two automatable observers are a force multiplier, not a prerequisite. Decision belongs to roadmap step.
- **Re-evaluation of the v1.9 `embedded_files × apple_preview` outcome** — Preview did not surface the embedded file in its UI at v1.9 close; record as `explicit_deferral` in Phase 71 unless re-verification on current Preview shows changed behavior.

## Confidence assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All recommended deps (JSV 0.18.3 / pdfium-cli 0.10.3 / pdfjs-dist 5.7.284) verified against live Hex/GitHub/npm release pages; pure-core / optional-adapter posture preserves the existing v1.0–v2.2 architectural contract. |
| Features | HIGH | Cell topology (5 promoted / 19 in-scope / ~6–8 promotions / ~10–12 deferrals) derived directly from existing `priv/support_matrix.json` rows + verified viewer-implementation gaps (Mozilla #4202, Apple Preview no-`/Sig`-validation, PDFium fragmentation). |
| Architecture | HIGH | Every recommendation maps to an existing code-resident pattern verified in repo on 2026-05-08. |
| Pitfalls | HIGH | All 8 pitfalls anchored to existing v1.5–v2.2 precedents; each has a named guardrail phase. |

**Overall confidence:** HIGH. The four research files agree across every load-bearing decision: 5-phase build order (68–72), three-state matrix vocabulary, additive-only schema, no new required CI lane, no new runtime module, manual recording as primary mechanism, automatable observers as additive force multiplier. **No disagreements to resolve.**

## Sources

### Primary (HIGH confidence; verified 2026-05-08)

- `priv/support_matrix.json`, `guides/api_stability.md`
- `test/docs_contract/protection_claims_test.exs`, `embedded_artifact_claims_test.exs`
- `scripts/verify_docs.exs`, `.github/workflows/ci.yml`
- `.planning/PROJECT.md`, `.planning/MILESTONE-ARC.md`
- `.planning/milestones/v1.9-MILESTONE-AUDIT.md`, `v1.10-MILESTONE-AUDIT.md`, `v2.2-MILESTONE-AUDIT.md`
- `lib/rendro/adapters/poppler.ex`, `pdfsig.ex`, `py_hanko.ex`, `qpdf.ex`
- klippa-app/pdfium-cli v0.10.3 (2026-04-14, PDFium 1.19.1)
- bblanchon/pdfium-binaries (PDFium 149.0.7825.0, 2026-05-04)
- mozilla/pdf.js / pdfjs-dist 5.7.284 (2026-04-27)
- mozilla/pdf.js#4202 — PDF.js does not display empty signature widgets
- JSV 0.18.3 on hex.pm (2026-04-21)

---
*Research completed: 2026-05-08. Ready for roadmap.*
