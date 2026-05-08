# Project Research — Features for v2.3 Viewer Proof & Interop Closure

**Domain:** Per-viewer evidence recording for shipped PDF surfaces (forms, protection, signatures) across Adobe Acrobat Reader, Apple Preview, PDFium, PDF.js
**Researched:** 2026-05-08
**Confidence:** HIGH (engine-side surfaces all already shipped; this is a recording milestone, not an engineering one)

## Cell Topology — The Real Numbers

Six surfaces × four viewers = **24 cells**, but the genuinely-open count is much smaller once you net out what's already promoted and what's known not implementable by a viewer:

| Status | Count | Notes |
|--------|-------|-------|
| Already promoted (`supported`, recorded proof) | 5 | Apple Preview × forms (v1.8 P47), Acrobat × embedded_files (v1.9), Acrobat × links (v1.9), Apple Preview × links (v1.9), Apple Preview × protection (v1.10 P54). These are out of v2.3 scope. |
| Open `unverified` cells targeted by v2.3 | 19 | The full surface×viewer matrix below |
| Of those 19, expected to **promote** in v2.3 | ~6-8 | Forms, protection, signature widgets, signed artifacts on the viewers that actually implement the surface |
| Of those 19, expected to land as **explicit-deferral** rows | ~10-12 | Preview × signature validation, PDF.js × signature widgets, etc. — promotion not possible because the viewer does not implement the surface |
| Cells that may stay `unverified` if operator capacity is the bottleneck | residual | Acceptable as long as the recipe stays in place |

The full v2.3-in-scope grid (after netting out what's already shipped):

| Surface | Acrobat | Preview | PDFium | PDF.js |
|---------|---------|---------|--------|--------|
| forms (text/checkbox/radio) | unverified — promotable | **already supported** | unverified — promotable | unverified — promotable (with caveats) |
| protection (password-to-open) | unverified — promotable | **already supported** | unverified — promotable | unverified — known-not-supported (PDF.js does not handle encrypted PDFs in most embeds; explicit-deferral) |
| signature widgets (unsigned `/Sig` placeholder) | unverified — promotable (renders as placeholder) | unverified — promotable (renders as placeholder, no validation UI) | unverified — promotable (renders as placeholder, no validation UI) | unverified — known-gap (`Unimplemented annotation type (Widget signature)` — historical PDF.js behavior; explicit-deferral) |
| signing preparation (artifact-first prepared bytes) | unverified — promotable as "opens like an unsigned signature widget" | same | same | same |
| signed artifacts (cryptographically signed) | unverified — promotable (full integrity + trust UI) | unverified — known-gap (Preview ignores signatures and append-saves; explicit-deferral) | unverified — promotable (renders artifact, no signature UI) | unverified — explicit-deferral (no signature UI; renders as widget) |
| long-lived signed artifacts (timestamp + revocation evidence) | unverified — promotable (LTV indicator) | unverified — explicit-deferral (no validation UI) | unverified — explicit-deferral (no LTV UI) | unverified — explicit-deferral (no LTV UI) |

This is the "categories clear" answer: **the milestone has roughly 6-8 promotable cells and 10-12 explicit-deferral cells. It is a recording-discipline milestone, not a code-engineering milestone.**

## Feature Landscape

### Table Stakes (Per-Viewer Evidence Checklists — One Per Surface)

The minimum honest behavioral checks an operator must record per (surface × viewer) cell. These match the already-shipped checklist patterns in `priv/support_matrix.json` (e.g., `forms.viewers.apple_preview.proof`, `protection.viewers.apple_preview.proof`).

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **VIEWER-EVIDENCE-FORMS** — checklist: `open` (no error/prompt), `default_state_visible` (placeholder text + checked state render correctly), `edit_or_toggle` (text typeable, checkbox togglable, radio mutually exclusive), `save` (Save As round-trips state) | Established by Phase 47 (`forms.viewers.apple_preview.proof`); already canonical | LOW (engineering); MEDIUM (manual recording per viewer) | Reuse existing 4-item proof array. Acrobat × forms is the headline gap |
| **VIEWER-EVIDENCE-PROTECTION** — checklist: `opens_with_open_password`, `displays_authored_content_correctly`, `advisory_print_behavior` (flag honored or honestly disclaimed), `advisory_copy_behavior`, `save_and_reopen_readability` | Established by Phase 54 (`protection.viewers.apple_preview.proof`); already canonical | LOW (engineering); MEDIUM (manual recording) | Reuse existing 5-item proof array. Acrobat × protection is the headline gap |
| **VIEWER-EVIDENCE-SIGNATURE-WIDGETS** — checklist: `opens_without_signature_warning_or_with_truthful_warning`, `widget_renders_as_unsigned_placeholder_rectangle`, `does_not_falsely_claim_signed`, `signature_panel_or_equivalent_reports_unsigned_or_silent`, `save_and_reopen_preserves_widget` | Brand-new surface — checklist must be authored in this milestone | LOW (engineering); MEDIUM (recording) | The discriminating check is "does NOT claim signed" — this is a negative-evidence requirement. Critical |
| **VIEWER-EVIDENCE-SIGNING-PREP** — checklist: `prepared_artifact_opens_cleanly`, `widget_renders_as_unsigned_placeholder`, `viewer_does_not_silently_re_sign_or_corrupt`, `byte_range_layout_intact_after_save_as` | Brand-new surface | LOW (engineering); MEDIUM (recording) | Largely identical to signature-widgets at the viewer level — most viewers cannot tell the difference. That's fine. Document the equivalence |
| **VIEWER-EVIDENCE-SIGNED-ARTIFACTS** — checklist: `opens_signed_artifact_without_corruption`, `appearance_renders` (widget visible), `integrity_reported_truthfully` (or silent-but-not-falsely-valid), `certificate_trust_reported_separately` (per-viewer; trust may be untrusted-but-integrity-OK and that is a passing record), `save_and_reopen_preserves_signature_or_warns` | Brand-new surface | LOW (engineering); MEDIUM-HIGH (recording — requires fixture chain, possibly trust anchor pinning) | **The integrity vs. trust split must be recorded as two separate per-viewer signals.** A pass = "integrity reported truthfully and trust reported separately," not "Signed and all signatures are valid." Acrobat is the only viewer that fully discriminates these |
| **VIEWER-EVIDENCE-LONG-LIVED** — checklist: `opens_long_lived_artifact_without_corruption`, `timestamp_recognized_or_silent` (Acrobat-only: LTV indicator surfaces), `revocation_evidence_recognized_or_silent`, `posture_reported_truthfully` (no false LT/LTA brand), `expiry_behavior_honest` (signature still verifiable past signer-cert expiry, when the viewer supports the concept) | Brand-new surface; only Acrobat genuinely implements LTV UI | LOW (engineering); HIGH (recording — full certomancer fixture chain, expiry simulation) | Most viewers will land as explicit-deferral. Acrobat × long-lived is the only cell that can promote on the strong signal |

### Differentiators (Nice-to-Have Per-Viewer Signals — Recorded but Never Block Promotion)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **DIFF-LTV-INDICATOR** — record Acrobat's exact "Signature is LTV enabled" UI string and screenshot | Strongest possible evidence that Acrobat agrees with our long-lived posture | LOW | Acrobat-specific; do not gate other viewers on equivalent UI |
| **DIFF-PREVIEW-SIG-GAP-NOTE** — record Apple Preview's known append-save behavior on signed PDFs as a recorded disclaimer in the proof entry | Closes a known integrity hazard transparently | LOW | This is a disclaimer field, not a pass/fail check |
| **DIFF-PDFJS-APPEARANCE-PARITY** — record whether PDF.js rendered the form-field appearance stream identically to Acrobat (visual) vs. fell back to its own renderer | Differentiates "looks identical" from "looks different but functional" | LOW-MEDIUM | Visual diff is informational; functional pass is what gates promotion |
| **DIFF-PDFIUM-CHROMIUM-CHANNEL** — record exact Chromium build + PDFium version | PDFium ships embedded in many Chromium variants and behavior can drift | LOW | Capture once per checklist; do not re-test every channel |
| **DIFF-VIEWER-VERSION** — record viewer version + OS version next to every cell | Enables future regression detection when a Reader update changes form/signing behavior | LOW | Already canonical; reinforce |
| **DIFF-NEGATIVE-PROOF-SCREENSHOT** — for explicit-deferral cells, capture a screenshot of the viewer's actual behavior so the deferral is concrete, not hand-waved | Future-auditable; defends against "but it might work now" pressure | LOW-MEDIUM | High-leverage for the durability of the recipe |

### Anti-Features (Tempting for v2.3, Should Stay Out)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Automated PDF.js / PDFium headless test suite** | "Manual recording feels primitive; CI would catch regressions" | Moves milestone scope from "recorded honest viewer evidence" to "automated viewer-rendering CI." Brittle (Chromium channel drift); rendered artifacts still need human judgment | Stay manual for v2.3. Make the recipe so durable that automation can land later as a separate milestone |
| **A blanket "works in standard viewers" support row** | Marketing parity with browser-based PDF libs | Directly contradicts the milestone thesis. PROJECT.md and MILESTONE-ARC.md both name this as out-of-scope | Per-(surface × viewer) rows only |
| **Promoting cells based on third-party screenshots, blog posts, or community claims** | "Other people have already verified this" | Promotion-grade evidence must include `viewer + version + OS + fixture + date checked + per-behavior pass/fail`, recorded in-repo. Anything else is hearsay | Treat external claims as differentiator-tier signal at most |
| **Compliance-tier viewer claims (PDF/A, PDF/UA, ETSI EN 319 142 PAdES)** | "While we're recording viewer behavior, why not record compliance UI?" | Conflates viewer behavior with compliance. PROJECT.md explicitly defers compliance branding | Stay narrow. LTV is the closest v2.3 gets and only via the recorded indicator as a differentiator |
| **Multi-signature workflow viewer behavior** | "Acrobat shows nice multi-sig timelines; let's record them" | Multi-signature is a separate signing surface that has not shipped. Recording its viewer behavior would create a public expectation of a feature that does not exist | Out of scope. Surface boundary first, viewer evidence second |
| **Per-viewer remediation/troubleshooting code (e.g., shipping a PDF.js polyfill, monkey-patching the writer to please specific viewers)** | "We discovered PDF.js renders X badly — let's fix it" | Widening engine code on viewer feedback is exactly the wrong direction | Record the gap as an explicit-deferral row |
| **Promoting "signing preparation" cells separately from "signature widget" cells when the viewer cannot tell them apart** | "We have two surfaces, so we need two viewer rows" | For most viewers, a prepared artifact and an unsigned signature-widget artifact look identical and carry the same proof. Forcing two rows manufactures recording busywork | Document the equivalence in `guides/api_stability.md` and either share a checklist or note "see signature-widget proof" on the prep row |

## Promotion-Gating Logic (Rubric)

A (surface × viewer) cell promotes from `unverified` to `supported` when **all** of:

1. The full **table-stakes checklist** for the surface passes end-to-end against a specific viewer version on a specific OS, with each check recorded as pass/fail.
2. The recorded entry includes: `viewer name`, `viewer version` (when easily available), `OS + version`, `fixture path`, `date checked`, and `per-behavior pass/fail` (this matches the v1.10 Phase 54 record shape).
3. The fixture used is in-repo or reproducible from `priv/support/`.
4. **Differentiator items are noted but never block promotion.** A missing LTV screenshot does not block Acrobat × long-lived from promoting if the table-stakes checks all pass.

A cell lands as **explicit-deferral** (a new third state distinct from `unverified`) when:

1. The viewer demonstrably does not implement the surface.
2. A recorded entry captures the negative-evidence (ideally with a screenshot per `DIFF-NEGATIVE-PROOF-SCREENSHOT`) and a one-line rationale.
3. The matrix entry uses a distinct status string (recommend `explicit_deferral` or `not_implemented_by_viewer`) so it is auditable against a silent `unverified`.

A cell stays at **`unverified`** only when neither promotion nor explicit-deferral has been completed (operator capacity gap, not a permanent disclaimer).

This three-state model (`supported` / `explicit_deferral` / `unverified`) is the most important piece of v2.3's discipline.

## Operator-Grade Recipe (Smallest Repeatable Workflow)

| Component | Description | Complexity |
|-----------|-------------|------------|
| **RECIPE-TEMPLATE** — `priv/viewer_evidence/<surface>/<viewer>.md` template | One markdown file per cell, fixed frontmatter (viewer, version, OS, fixture, date, checklist items) + body for screenshots/notes | LOW |
| **RECIPE-MIXTASK** — `mix viewer_evidence` | Lists every cell from `priv/support_matrix.json`, cross-references `priv/viewer_evidence/<surface>/<viewer>.md`, prints coverage report (promoted / explicit-deferred / silently unverified). Exits non-zero when an `unverified` row has no companion evidence file at all | MEDIUM |
| **RECIPE-CHANGELOG-RULE** — every cell promotion or explicit-deferral lands one CHANGELOG entry | Documented rule in `guides/api_stability.md`: promoting a viewer row is a public-contract change | LOW |
| **RECIPE-FIXTURE-DIRECTORY** — `priv/viewer_evidence/fixtures/` for canonical PDFs | One fixture per surface, reused across viewers so cells compare apples to apples | LOW |
| **RECIPE-SUPPORT-MATRIX-SCHEMA** — extend matrix JSON shape to allow `status: explicit_deferral` and a required `reason` field | One-line JSON-shape change + tests | LOW |
| **RECIPE-DOCS-CONTRACT-LANE** — extend the existing docs-contract lane to assert that every `supported` viewer row has a matching evidence file and that every `explicit_deferral` row has a recorded reason | Reuses the existing pattern from v1.5/v1.9; not new infrastructure | LOW-MEDIUM |

This is the **dominant cost of the milestone**: not the recipe code (a few hundred lines), but the **manual recording labor** for ~16-19 open cells. The engineering effort is small; the testing labor is the gating constraint.

## Surface-Specific Landmines

These are known, documented behaviors where the viewer simply does not implement the surface or implements it in a way that would invalidate a `supported` claim. They must be captured as explicit-deferral entries with recorded negative evidence.

| Surface × Viewer | Known Landmine | Required Action |
|------------------|----------------|-----------------|
| signature widgets × PDF.js | `Unimplemented annotation type (Widget signature)` historical; rendering remains incomplete in current builds | Explicit-deferral row with recorded version and screenshot. Do NOT promote even if a recent build incidentally renders the widget |
| signed artifacts × Apple Preview | Preview ignores signature permissions and does an append-save that visually appears to leave the document signed but actually invalidates the signature; Preview does not validate signatures at all | Explicit-deferral row. Reason: "Apple Preview does not validate PDF digital signatures and may invalidate them through append-save." |
| long-lived × Apple Preview / PDFium / PDF.js | None display LTV indicators; Preview/PDF.js do not validate signatures | Explicit-deferral row for all three |
| protection × PDF.js | PDF.js / Firefox built-in viewer historically does not handle encrypted PDFs in most embed contexts | Explicit-deferral row. Verify on current Firefox; capture exact version |
| forms × PDF.js | PDF.js renders form-field appearance streams but parity with Acrobat is incomplete. Rendro emits explicit appearance streams (no `NeedAppearances`), favorable for promotion | Likely promotable, record parity caveat as `DIFF-PDFJS-APPEARANCE-PARITY` |
| forms × PDFium | PDFium supports AcroForms; embedded-in-Chromium presentation lacks some Acrobat affordances; signature widgets render but no validation UI | Forms promotable; signature widgets promotable on narrow checklist |
| signed artifacts × PDFium | PDFium supports signatures structurally but Chrome/Edge embedded viewers do not surface validation panel | Promotable on narrow checklist; differentiator note captures missing trust UI |
| signed artifacts × Acrobat with untrusted signer | "At least one signature has problems" is a **pass** for integrity-reported-truthfully | Document explicitly in the recipe so operators don't fail this check |
| protection × Acrobat | Fully supports password-to-open and advisory permissions; no known landmines | Promotable. Headline cell alongside Acrobat × forms |

## Feature Dependencies

```
[Every v2.3 cell] ──requires──> [Surface itself already shipped]
                                       │
                                       ↓
                          (already true for all six surfaces)

[VIEWER-EVIDENCE-* checklists]
        ├──requires──> [RECIPE-FIXTURE-DIRECTORY]
        ├──requires──> [RECIPE-TEMPLATE]
        └──enables──> [MATRIX-PROMOTE-* row promotions]

[MATRIX-PROMOTE-* row promotions]
        ├──requires──> [RECIPE-SUPPORT-MATRIX-SCHEMA] (for explicit_deferral)
        └──requires──> [GUARDRAIL-NEGATIVE-EVIDENCE] (for explicit-deferral rows)

[RECIPE-MIXTASK]
        └──enables──> [RECIPE-DOCS-CONTRACT-LANE]
```

## MVP Definition

This is a recording milestone, so MVP = **the minimum set of cells that, once promoted, materially change the public support story**, plus the recipe.

### Launch With (v2.3 ship)

- [ ] **RECIPE-TEMPLATE + RECIPE-FIXTURE-DIRECTORY + RECIPE-MIXTASK + RECIPE-SUPPORT-MATRIX-SCHEMA** — durability layer
- [ ] **RECIPE-DOCS-CONTRACT-LANE** — enforces it
- [ ] **VIEWER-EVIDENCE-FORMS / Adobe Acrobat Reader** — closes the most-asked existing gap
- [ ] **VIEWER-EVIDENCE-PROTECTION / Adobe Acrobat Reader** — closes the second most-asked gap
- [ ] **VIEWER-EVIDENCE-SIGNATURE-WIDGETS / Adobe Acrobat Reader, Apple Preview, PDFium** — promotable on narrow checklist
- [ ] **VIEWER-EVIDENCE-SIGNED-ARTIFACTS / Adobe Acrobat Reader** — validates the v2.1 thesis
- [ ] **VIEWER-EVIDENCE-LONG-LIVED / Adobe Acrobat Reader** — validates the v2.2 thesis
- [ ] **GUARDRAIL: Explicit-deferral rows recorded** for: signature-widgets × PDF.js, signed-artifacts × Apple Preview / PDF.js, long-lived × Preview/PDFium/PDF.js, protection × PDF.js (if confirmed)
- [ ] **CHANGELOG entries** for each promotion and each new explicit-deferral

### Add After Validation (within v2.3 if capacity allows)

- [ ] **VIEWER-EVIDENCE-FORMS / PDFium, PDF.js** — likely-promotable rows that strengthen breadth
- [ ] **VIEWER-EVIDENCE-PROTECTION / PDFium** — promotable
- [ ] **VIEWER-EVIDENCE-SIGNED-ARTIFACTS / PDFium** — narrow checklist
- [ ] **VIEWER-EVIDENCE-SIGNING-PREP / Acrobat** (and equivalence note for the others)

### Future Consideration (post-v2.3)

- [ ] Headless-browser automated viewer CI
- [ ] Per-platform variants (Acrobat Windows vs macOS, Edge vs Chrome PDFium specifically)
- [ ] Mobile viewer evidence (iOS Files, Android default)
- [ ] Re-verification cadence (annual recheck)

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| RECIPE-TEMPLATE / FIXTURE-DIR / MIXTASK / SCHEMA / DOCS-CONTRACT-LANE | HIGH | LOW–MEDIUM | P1 |
| VIEWER-EVIDENCE-FORMS / Acrobat | HIGH | LOW eng / MEDIUM record | P1 |
| VIEWER-EVIDENCE-PROTECTION / Acrobat | HIGH | LOW eng / MEDIUM record | P1 |
| VIEWER-EVIDENCE-SIGNED-ARTIFACTS / Acrobat | HIGH | LOW eng / MEDIUM-HIGH record | P1 |
| VIEWER-EVIDENCE-LONG-LIVED / Acrobat | HIGH | LOW eng / HIGH record | P1 |
| VIEWER-EVIDENCE-SIGNATURE-WIDGETS / Acrobat, Preview, PDFium | MEDIUM | LOW eng / MEDIUM record | P1 |
| GUARDRAIL: Explicit-deferral rows | HIGH | LOW | P1 |
| DIFF-LTV-INDICATOR / DIFF-PREVIEW-SIG-GAP / DIFF-NEGATIVE-PROOF-SCREENSHOT | MEDIUM | LOW | P2 |
| VIEWER-EVIDENCE-FORMS / PDFium + PDF.js | MEDIUM | LOW eng / MEDIUM record | P2 |
| VIEWER-EVIDENCE-PROTECTION / PDFium | MEDIUM | LOW eng / MEDIUM record | P2 |
| VIEWER-EVIDENCE-SIGNED-ARTIFACTS / PDFium (narrow) | MEDIUM | LOW eng / MEDIUM record | P2 |
| VIEWER-EVIDENCE-SIGNING-PREP cells | LOW | LOW eng / LOW record | P3 |
| Headless-browser automation | LOW for v2.3 (HIGH later) | HIGH | P3 (defer) |
| Mobile viewer evidence | LOW for v2.3 | MEDIUM | P3 |

## Roadmap Implications for the Requirement-Definition Step

Suggested REQ-ID groupings:

- **VIEWER-EVIDENCE-XX** — one per (surface × viewer) checklist; trim to P1 set for v2.3 commit
- **MATRIX-PROMOTE-XX** — one per actual promotion event from `unverified` → `supported`
- **RECIPE-XX** — RECIPE-TEMPLATE, RECIPE-FIXTURE-DIRECTORY, RECIPE-MIXTASK, RECIPE-SCHEMA, RECIPE-DOCS-CONTRACT, RECIPE-CHANGELOG-RULE
- **GUARDRAIL-XX** — GUARDRAIL-EXPLICIT-DEFERRAL, GUARDRAIL-NEGATIVE-EVIDENCE, GUARDRAIL-NO-BLANKET-CLAIMS, GUARDRAIL-NO-THIRD-PARTY-PROMOTION

## Sources

- `.planning/PROJECT.md`, `.planning/MILESTONE-ARC.md`, `priv/support_matrix.json`, `guides/api_stability.md`
- `.planning/milestones/v1.9-MILESTONE-AUDIT.md`, `v1.10-MILESTONE-AUDIT.md`, `v2.2-MILESTONE-AUDIT.md`
- Apple Preview signature-validation gap (Adobe Community + discussions.apple.com)
- PDF.js signature widget unimplemented (Mozilla #4202), AcroForm support (#7613)
- PDFium SDK form/security docs (Patagames + googlesource)
- Adobe Acrobat LTV indicator (SSL.com + PDF Association)
