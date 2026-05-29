# Phase 71 Research: Record New Trust-Sensitive Surfaces and Explicit Deferrals

**Researched:** 2026-05-28  
**Phase:** 71-record-new-trust-sensitive-surfaces-and-explicit-deferrals  
**Requirements:** VIEWER-02, VIEWER-03, VIEWER-04, VIEWER-05, VIEWER-06, VIEWER-07  
**Depends on:** Phase 69 (complete), Phase 70 (complete — disjoint files)  
**Purpose:** Answer “What do I need to know to PLAN this phase well?” — not task breakdown.

---

## 1. Executive Summary

Phase 71 closes **VIEWER-02 through VIEWER-07** by recording every remaining trust-sensitive `(surface × viewer)` cell to a **terminal state**: `supported` (evidence file + matrix promotion keys) or `explicit_deferral` (matrix-only `evidence_deferred` with named reason). **Twenty** bare `"status": "unverified"` cells exist in production `priv/support_matrix.json` today; Phase 71 target is **zero** silent unverified at close (~11 `supported`, ~9 `explicit_deferral` per 71-CONTEXT D-11).

**Critical planner insight:** This is **net-new recording**, not re-attestation. Unlike Phase 70 (legacy rows already `supported`), Phase 71 **promotes** unverified cells and **introduces** `explicit_deferral` rows for the first time in production. Signing surfaces need **new fixtures**, **new evidence directories**, **new proof[] behavior IDs** on matrix rows, and **signing-prep equivalence inheritance** for non-Acrobat viewers (71-CONTEXT D-15–D-17).

**Single atomic public-contract wave (D-01):** One PR lands all ~20 cell closures — evidence files → matrix promotions/deferrals → `guides/api_stability.md` equivalence note + STACK mirrors → `guides/viewer_evidence.md` Appendix B deferral templates → CHANGELOG → docs-contract green → `mix rendro.viewer_evidence missing` empty. Internal operator work may split across waves (71-01 fixtures → 71-02 recording → 71-03 closure); **must not merge 71-02 without 71-03** (D-24, mirror Phase 70 D-19).

**Acrobat session discipline (D-06–D-07):** One Acrobat session, **six isolated PDFs**, **six evidence files** — forms, protection, signature_widget, signing_preparation, signed_artifact, long_lived_signed_artifact. Destructiveness-aware order: About once → forms (Save As) → protection (password + Save As) → signature_widget → signing_preparation → signed_artifact (read-only first) → long_lived (read-only LTV UI).

---

## 2. Current State Audit

### 2.1 Production matrix — twenty `unverified` cells

| # | Matrix path | Surface | Viewer | Existing `proof[]` | Phase 71 disposition (default) |
|---|-------------|---------|--------|-------------------|--------------------------------|
| 1 | `forms.viewers.adobe_acrobat_reader` | forms | Acrobat | yes (4-check) | **supported** (VIEWER-02) |
| 2 | `forms.viewers.pdfjs` | forms | PDF.js | no | **attempt supported**; defer if 4-check fails (D-13) |
| 3 | `protection.viewers.adobe_acrobat_reader` | protection | Acrobat | yes (5-check) | **supported** (VIEWER-03) |
| 4 | `forms.signature_widget_viewers.adobe_acrobat_reader` | signature_widget | Acrobat | no — add 5-check | **supported** (VIEWER-04) |
| 5 | `forms.signature_widget_viewers.apple_preview` | signature_widget | Preview | no | **supported** manual GUI (D-19) |
| 6 | `forms.signature_widget_viewers.chrome_pdfium` | signature_widget | PDFium | no | **supported** pdfium-cli (D-18) |
| 7 | `forms.signature_widget_viewers.pdfjs` | signature_widget | PDF.js | no | **explicit_deferral** mozilla/pdf.js#4202 (D-23) |
| 8 | `signing_preparation.viewers.adobe_acrobat_reader` | signing_preparation | Acrobat | no — add 4-check | **supported** separate manual (D-16) |
| 9 | `signing_preparation.viewers.apple_preview` | signing_preparation | Preview | no | **inherit** signature_widget (D-15) |
| 10 | `signing_preparation.viewers.chrome_pdfium` | signing_preparation | PDFium | no | **inherit** signature_widget (D-15) |
| 11 | `signing_preparation.viewers.pdfjs` | signing_preparation | PDF.js | no | **inherit** signature_widget deferral (D-15) |
| 12 | `signing.viewers.adobe_acrobat_reader` | signed_artifact | Acrobat | no — add 5-check | **supported** (VIEWER-06) |
| 13 | `signing.viewers.apple_preview` | signed_artifact | Preview | no | **explicit_deferral** no /Sig validation (D-23) |
| 14 | `signing.viewers.chrome_pdfium` | signed_artifact | PDFium | no | **supported** pdfium-cli + pdfsig notes (D-14) |
| 15 | `signing.viewers.pdfjs` | signed_artifact | PDF.js | no | **explicit_deferral** no /Sig validation UI (D-23) |
| 16 | `signing.long_lived.viewers.adobe_acrobat_reader` | long_lived_signed_artifact | Acrobat | no — add 5-check | **supported** certomancer fixture (VIEWER-07) |
| 17 | `signing.long_lived.viewers.apple_preview` | long_lived_signed_artifact | Preview | no | **explicit_deferral** no LTV indicators (D-23) |
| 18 | `signing.long_lived.viewers.chrome_pdfium` | long_lived_signed_artifact | PDFium | no | **explicit_deferral** no LTV indicators (D-23) |
| 19 | `signing.long_lived.viewers.pdfjs` | long_lived_signed_artifact | PDF.js | no | **explicit_deferral** no LTV indicators (D-23) |
| 20 | `embedded_files.viewers.apple_preview` | embedded_files | Preview | yes (3-check) | **re-verify**; default defer if Attachments UI absent (D-12) |

**Operator confirmation (2026-05-28):**

```bash
grep -c '"status": "unverified"' priv/support_matrix.json   # 20
mix rendro.viewer_evidence missing                            # lists all 20 backlog cells
```

### 2.2 Evidence files — what exists vs what Phase 71 creates

| Path | Status |
|------|--------|
| `priv/viewer_evidence/_template.md` | exists (Phase 68) |
| `priv/viewer_evidence/forms/chrome_pdfium.md` | exists (Phase 69) |
| `priv/viewer_evidence/forms/apple_preview.md` | exists (Phase 70) |
| `priv/viewer_evidence/forms/adobe_acrobat_reader.md` | **create** (VIEWER-02) |
| `priv/viewer_evidence/forms/pdfjs.md` | **create if promoted** |
| `priv/viewer_evidence/protection/adobe_acrobat_reader.md` | **create** (VIEWER-03) |
| `priv/viewer_evidence/signature_widget/{adobe_acrobat_reader,apple_preview,chrome_pdfium}.md` | **create** (3 files) |
| `priv/viewer_evidence/signing_preparation/adobe_acrobat_reader.md` | **create** (Acrobat only; others inherit pointer) |
| `priv/viewer_evidence/signing_preparation/{apple_preview,chrome_pdfium}.md` | **optional thin cross-ref stub** OR direct `evidence:` to signature_widget file (D discretion) |
| `priv/viewer_evidence/signed_artifact/{adobe_acrobat_reader,chrome_pdfium}.md` | **create** (2 files) |
| `priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md` | **create** (1 file) |

**No evidence files** for `explicit_deferral` rows — matrix-only `evidence_deferred` prose (Phase 68 contract).

### 2.3 Fixtures — committed vs missing

| Path | Generator | Status |
|------|-----------|--------|
| `test/fixtures/forms_support_fixture.pdf` | `Rendro.Test.FormSupportFixture.write_fixture/1` | **committed** (Phase 69) |
| `test/fixtures/protection_support_fixture.pdf` | `scripts/protected_viewer_proof_fixture.exs` | **committed** (Phase 70) |
| `test/fixtures/embedded_artifact_support_fixture.pdf` | `Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture/1` | **committed** (Phase 70) |
| `test/fixtures/signature_widget_support_fixture.pdf` | `Rendro.Test.SigningViewerSupportFixture` (new) | **missing** — create in 71-01 |
| `test/fixtures/signing_preparation_support_fixture.pdf` | `Sign.prepare/2` via new module/script | **missing** — create in 71-01 |
| `test/fixtures/signed_artifact_viewer_proof.pdf` | `scripts/signed_artifact_viewer_proof_fixture.exs` (new) | **missing** — D-09 carve-out |
| `test/fixtures/long_lived_viewer_proof.pdf` | `scripts/long_lived_viewer_proof_fixture.exs` (new) | **missing** — D-20 certomancer chain |

**Regeneration one-liners (for evidence bodies):**

```elixir
# signature widget (unsigned placeholder)
MIX_ENV=test mix run -e 'Rendro.Test.SigningViewerSupportFixture.write_signature_widget_fixture("test/fixtures/signature_widget_support_fixture.pdf")'

# signing preparation (Sign.prepare/2 output)
MIX_ENV=test mix run -e 'Rendro.Test.SigningViewerSupportFixture.write_signing_preparation_fixture("test/fixtures/signing_preparation_support_fixture.pdf")'
```

```bash
# signed artifact viewer proof (live_signer_*.pem path)
mix run scripts/signed_artifact_viewer_proof_fixture.exs --output test/fixtures/signed_artifact_viewer_proof.pdf

# long-lived viewer proof (certomancer + pyhanko preflight)
mix run scripts/long_lived_viewer_proof_fixture.exs --output test/fixtures/long_lived_viewer_proof.pdf
```

### 2.4 `proof[]` behavior IDs per surface (from REQUIREMENTS.md + research)

**forms × adobe_acrobat_reader / pdfjs** (already on matrix for Acrobat):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `open` | Open fixture without error dialog |
| `default_state_visible` | Email prefilled; terms checked; contact radio selected |
| `edit_or_toggle` | Edit email; toggle terms; switch radio |
| `save` | Save As; reopen; state persists |

**protection × adobe_acrobat_reader** (already on matrix):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `opens_with_open_password` | Prompt accepts open password; document opens |
| `displays_authored_content_correctly` | Fixture body text visible |
| `advisory_print_behavior` | Print UI reflects advisory posture |
| `advisory_copy_behavior` | Copy UI reflects advisory posture |
| `save_and_reopen_readability` | Save As + reopen remains readable with password |

**signature_widget** (add to matrix on promotion — VIEWER-04):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `opens_without_signature_warning_or_with_truthful_warning` | No false "signed" banner on unsigned widget |
| `widget_renders_as_unsigned_placeholder_rectangle` | Visible unsigned placeholder |
| `does_not_falsely_claim_signed` | **Negative check** — viewer must not claim signed |
| `signature_panel_or_equivalent_reports_unsigned_or_silent` | Panel honest or absent |
| `save_and_reopen_preserves_widget` | Save As preserves widget state |

**signing_preparation** (add on promotion — VIEWER-05; Acrobat only gets full checklist):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `prepared_artifact_opens_cleanly` | Prepared PDF opens without corruption |
| `widget_renders_as_unsigned_placeholder` | Widget visible as unsigned |
| `viewer_does_not_silently_re_sign_or_corrupt` | No silent mutation |
| `byte_range_layout_intact_after_save_as` | Byte-range preserved after Save As (Acrobat-discriminable) |

**signed_artifact** (add on promotion — VIEWER-06):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `opens_signed_artifact_without_corruption` | Signed PDF opens |
| `appearance_renders` | Signature appearance visible |
| `integrity_reported_truthfully` | Integrity signal honest (separate from trust) |
| `certificate_trust_reported_separately` | Trust signal separate from integrity |
| `save_and_reopen_preserves_signature_or_warns` | Save behavior honest |

**long_lived_signed_artifact** (add on promotion — VIEWER-07):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `opens_long_lived_artifact_without_corruption` | LTV PDF opens |
| `timestamp_recognized_or_silent` | Timestamp UI or honest silence |
| `revocation_evidence_recognized_or_silent` | Revocation UI or honest silence |
| `posture_reported_truthfully` | No false LT/LTA branding |
| `expiry_behavior_honest` | Expiry handling honest when supported |

**embedded_files × apple_preview** (existing `proof[]` on matrix):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `discoverable` | Embedded file visible in UI |
| `open_or_extract` | Listed entry opens or extracts |
| `save_or_extract` | Save to disk succeeds |

### 2.5 Validator surface path mapping

From `lib/rendro/viewer_evidence/matrix.ex`:

| Evidence directory | Matrix JSON path |
|--------------------|------------------|
| `signature_widget/` | `forms.signature_widget_viewers` |
| `signing_preparation/` | `signing_preparation.viewers` |
| `signed_artifact/` | `signing.viewers` |
| `long_lived_signed_artifact/` | `signing.long_lived.viewers` |

Planner must use these paths in `mix rendro.viewer_evidence record` commands and matrix edits.

### 2.6 `api_stability.md` — insertion targets

Phase 71 adds:

1. **Signing-preparation × signature-widget equivalence section** (ROADMAP SC#4, D-17) — before per-viewer STACK mirrors for signing surfaces.
2. **STACK mirrors** for every newly `supported` row (Acrobat forms/protection/signing surfaces, Preview sig widget, PDFium promotions).
3. **`explicit_deferral` prose** for every deferred row — named reason, no forbidden vocabulary.

Phase 70 already left Acrobat forms/protection as `unverified` in api_stability — Phase 71 replaces with evidence-backed mirrors.

### 2.7 Explicit-deferral mandated rows (D-23)

| Matrix path | Template | Named reason (minimum) |
|-------------|----------|------------------------|
| `forms.signature_widget_viewers.pdfjs` | UPSTREAM_ISSUE | mozilla/pdf.js#4202 — no signature widget UI |
| `signing.viewers.apple_preview` | NO_SIG_VALIDATION | No /Sig validation; append-save invalidates |
| `signing.viewers.pdfjs` | NO_SIG_VALIDATION | No /Sig validation UI |
| `signing.long_lived.viewers.apple_preview` | NO_LTV_INDICATORS | Viewer does not implement long-term-validation indicators |
| `signing.long_lived.viewers.chrome_pdfium` | NO_LTV_INDICATORS | Same |
| `signing.long_lived.viewers.pdfjs` | NO_LTV_INDICATORS | Same |
| `embedded_files.viewers.apple_preview` | (conditional) | Attachments UI absent — if re-verify fails (D-12) |
| `forms.viewers.pdfjs` | (conditional) | 4-check failure — if promotion attempt fails (D-13) |

Deferral strings must pass docs-contract lint: ≥40 chars, no `TBD` / `not yet` / `deferred for later` / empty.

---

## 3. Implementation Approach

### 3.1 Internal wave structure (D-24)

```
Wave 1 (71-01): fixtures + scripts
  → signature_widget_support_fixture.pdf
  → signing_preparation_support_fixture.pdf
  → signed_artifact_viewer_proof.pdf + long_lived_viewer_proof.pdf (committed carve-out)
  → SigningViewerSupportFixture module + regen scripts

Wave 2 (71-02): evidence recording (autonomous: false — manual checkpoints)
  → Acrobat one-session six-PDF recording
  → Preview signature_widget manual GUI
  → pdfium-cli signature_widget + signed_artifact promotions
  → PDF.js forms attempt + deferrals prose draft
  → embedded_files × Preview re-verify

Wave 3 (71-03): atomic public-contract closure
  → priv/support_matrix.json (all 20 cells terminal)
  → guides/api_stability.md equivalence + mirrors
  → guides/viewer_evidence.md Appendix B deferral templates
  → CHANGELOG [0.3.0] Viewer Evidence bullets
  → docs-contract asserts for new surfaces
  → mix rendro.viewer_evidence missing → empty
```

**Merge guard:** 71-02 artifacts must not merge without 71-03 (orphan evidence + silent unverified).

### 3.2 Signing-prep equivalence inheritance (D-15–D-17)

For **non-Acrobat** viewers where signing_prep and signature_widget are behaviorally indistinguishable:

```json
"signing_preparation.viewers.apple_preview": {
  "status": "supported",
  "proof": ["prepared_artifact_opens_cleanly", "widget_renders_as_unsigned_placeholder", "viewer_does_not_silently_re_sign_or_corrupt", "byte_range_layout_intact_after_save_as"],
  "evidence": "priv/viewer_evidence/signature_widget/apple_preview.md",
  "recorded_at": "{same as sig_widget}",
  "viewer_kind": "manual"
}
```

**Acrobat exception:** Separate evidence at `priv/viewer_evidence/signing_preparation/adobe_acrobat_reader.md` with byte-range checklist.

**PDF.js signing_prep:** Inherits `explicit_deferral` from signature_widget pdfjs row — same `evidence_deferred` reason chain.

### 3.3 PDFium promotion path (D-18, D-14)

Extend Phase 70 pdfium-cli pattern to:

- `signature_widget × chrome_pdfium` — structural open + widget field detection
- `signed_artifact × chrome_pdfium` — pdfium-cli open + appearance; pdfsig integrity/trust in live test lane with honest "no validation panel" notes

Evidence body must pin: pdfium-cli version + embedded PDFium build + platform — **not** vague "Chrome stable" claims.

New live test module pattern: mirror `FormsPdfiumProof` → `SignatureWidgetPdfiumProof`, `SignedArtifactPdfiumProof`.

### 3.4 Acrobat session fixture map (D-06–D-08)

| Evidence file | Fixture | Save As required? |
|---------------|---------|-------------------|
| `forms/adobe_acrobat_reader.md` | `forms_support_fixture.pdf` | yes (copy) |
| `protection/adobe_acrobat_reader.md` | `protection_support_fixture.pdf` | yes (copy) |
| `signature_widget/adobe_acrobat_reader.md` | `signature_widget_support_fixture.pdf` | yes (preserve check only) |
| `signing_preparation/adobe_acrobat_reader.md` | `signing_preparation_support_fixture.pdf` | yes (byte-range) |
| `signed_artifact/adobe_acrobat_reader.md` | `signed_artifact_viewer_proof.pdf` | read-only first; copy for save check |
| `long_lived_signed_artifact/adobe_acrobat_reader.md` | `long_lived_viewer_proof.pdf` | read-only LTV UI |

### 3.5 Matrix promotion vs deferral shapes

**Supported promotion (additive keys):**

```json
"adobe_acrobat_reader": {
  "status": "supported",
  "proof": ["open", "default_state_visible", "edit_or_toggle", "save"],
  "evidence": "priv/viewer_evidence/forms/adobe_acrobat_reader.md",
  "recorded_at": "YYYY-MM-DD",
  "viewer_kind": "manual"
}
```

**Explicit deferral (no evidence file):**

```json
"pdfjs": {
  "status": "explicit_deferral",
  "evidence_deferred": "Mozilla PDF.js does not implement AcroForm signature widget UI (mozilla/pdf.js#4202); unsigned placeholder fields are not rendered as interactive signature widgets in the viewer."
}
```

### 3.6 CHANGELOG discipline (D-03)

Under `[0.3.0] - Unreleased` → `#### Viewer Evidence (v2.3)`:

- **`Added`** — net-new `unverified` → `supported` (one bullet per row)
- **`Changed`** — new `explicit_deferral`, equivalence-note additions, inherited signing_prep rows

---

## 4. Pitfall Guardrails (from ROADMAP + PITFALLS.md)

| Pitfall | Guard |
|---------|-------|
| Overclaim (`looks_correct`) | Per-behavior promotion only; behavioral verbs in notes |
| PDFium host vagueness | Pin pdfium-cli + PDFium build + platform in evidence body |
| Engine widening for viewers | Gaps → `explicit_deferral`, never writer patches |
| Forbidden deferral vocabulary | Pre-validate against docs-contract lint |
| Fixture drift | Committed paths + regen commands in evidence bodies |
| Signing-prep double-recording | Equivalence note + inheritance for non-Acrobat |
| Interim silent unverified | Atomic 71-02+71-03 merge (D-01) |

---

## 5. Manual Operator Checklists (Wave 2 reference)

### 5.1 Acrobat session (six PDFs, one session)

1. Record About dialog → `viewer_version`, `platform` for all six evidence frontmatters.
2. Open `forms_support_fixture.pdf` → run 4-check → write `forms/adobe_acrobat_reader.md`.
3. Open `protection_support_fixture.pdf` (password from script stdout, not in evidence) → 5-check → `protection/adobe_acrobat_reader.md`.
4. Open `signature_widget_support_fixture.pdf` → 5-check → `signature_widget/adobe_acrobat_reader.md`.
5. Open `signing_preparation_support_fixture.pdf` → 4-check including byte-range → `signing_preparation/adobe_acrobat_reader.md`.
6. Open `signed_artifact_viewer_proof.pdf` → 5-check with **separate** integrity vs trust notes → `signed_artifact/adobe_acrobat_reader.md`.
7. Open `long_lived_viewer_proof.pdf` → 5-check LTV UI → `long_lived_signed_artifact/adobe_acrobat_reader.md`.

### 5.2 Preview signature_widget (D-19)

Manual GUI on `signature_widget_support_fixture.pdf` — do **not** reuse pdfium-cli proxy from Phase 70 forms Preview row.

### 5.3 embedded_files × Preview re-verify (D-12)

5-minute re-open of `embedded_artifact_support_fixture.pdf` in Preview Attachments UI. Promote only if discover/open/extract works; else defer with v1.9-aligned reason.

### 5.4 PDF.js forms attempt (D-13)

Open `forms_support_fixture.pdf` in PDF.js; run 4-check. Defer only on observed failure.

---

## 6. Files to Create/Modify (Planner inventory)

### Wave 1 — fixtures/scripts

| File | Action |
|------|--------|
| `test/support/signing_viewer_support_fixture.ex` | create module |
| `scripts/signing_viewer_proof_fixtures.exs` | create regen script |
| `scripts/signed_artifact_viewer_proof_fixture.exs` | create (mirror protected script) |
| `scripts/long_lived_viewer_proof_fixture.exs` | create (certomancer chain) |
| `test/fixtures/signature_widget_support_fixture.pdf` | commit |
| `test/fixtures/signing_preparation_support_fixture.pdf` | commit |
| `test/fixtures/signed_artifact_viewer_proof.pdf` | commit (D-09 carve-out) |
| `test/fixtures/long_lived_viewer_proof.pdf` | commit |
| `test/fixtures/signing/README.md` | add viewer-evidence carve-out note |

### Wave 2 — evidence + live tests

| File | Action |
|------|--------|
| `priv/viewer_evidence/forms/adobe_acrobat_reader.md` | create |
| `priv/viewer_evidence/forms/pdfjs.md` | create if promoted |
| `priv/viewer_evidence/protection/adobe_acrobat_reader.md` | create |
| `priv/viewer_evidence/signature_widget/*.md` | create 3 supported |
| `priv/viewer_evidence/signing_preparation/adobe_acrobat_reader.md` | create |
| `priv/viewer_evidence/signed_artifact/*.md` | create 2 supported |
| `priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md` | create |
| `lib/rendro/adapters/signature_widget_pdfium_proof.ex` | create (or test/support) |
| `lib/rendro/adapters/signed_artifact_pdfium_proof.ex` | create (or test/support) |
| `test/rendro/adapters/signature_widget_viewer_evidence_live_test.exs` | create |
| `test/rendro/adapters/signed_artifact_viewer_evidence_live_test.exs` | create |

### Wave 3 — public contract

| File | Action |
|------|--------|
| `priv/support_matrix.json` | all 20 cells terminal |
| `guides/api_stability.md` | equivalence section + mirrors + deferrals |
| `guides/viewer_evidence.md` | Appendix B deferral templates |
| `CHANGELOG.md` | ~20 bullets |
| `test/docs_contract/viewer_evidence_claims_test.exs` | extend for signing surfaces + deferrals |
| `test/docs_contract/signing_claims_test.exs` | optional mirror asserts |

---

## 7. Standard Stack

No new runtime dependencies. Reuses:

- **pdfium-cli** — structural proxy (Phase 69–70 pattern)
- **qpdf / pdfinfo** — fixture preflight (protected script pattern)
- **certomancer + pyhanko** — long-lived fixture chain (`signing_live_test.exs` reference)
- **pdfsig** — signed-artifact integrity signals in live test lane

---

## 8. Don't Hand-Roll

| Need | Use instead |
|------|-------------|
| Evidence frontmatter shape | `priv/viewer_evidence/_template.md` + `Validator.validate_evidence_file/3` |
| Matrix edits | `Mix.Tasks.Rendro.ViewerEvidence` record subcommand where applicable |
| pdfium-cli promotion | `FormsPdfiumProof` / `FormsApplePreviewProof` pattern in `test/rendro/adapters/` |
| Protected fixture script | `scripts/protected_viewer_proof_fixture.exs` structure |
| Deferral lint | `test/docs_contract/viewer_evidence_claims_test.exs` forbidden vocabulary |
| Long-lived PKI | `test/fixtures/signing/certomancer/` chain from `signing_live_test.exs` |

---

## 9. Validation Architecture

Nyquist-oriented verification map: **how each deliverable is verified**, sampling, CI lanes.

| Deliverable | Verification method | Automated? | Test file / command |
|-------------|---------------------|--------------|---------------------|
| Four committed signing fixtures | `%PDF` header + structural tests | Yes | `mix test test/rendro/signing_viewer_support_fixture_test.exs` (new) |
| Evidence files — schema | `Validator.validate_evidence_file/3` | Yes | `viewer_evidence_claims_test.exs` |
| Matrix terminal states | no bare `unverified` in trust surfaces | Yes | `viewer_evidence_claims_test.exs` + grep |
| Explicit deferral lint | forbidden vocabulary + min length | Yes | `viewer_evidence_claims_test.exs` |
| `mix rendro.viewer_evidence missing` | empty output | Yes | manual + test hook |
| pdfium-cli live proofs | `live_pdf_tools` tag | Yes (when tools present) | new live test modules |
| Acrobat/Preview GUI truth | operator checklists §5 | **Human-only** | checkpoint tasks |
| api_stability mirrors | path + deferral prose asserts | Yes | docs-contract lanes |
| CHANGELOG bullets | human review | Review | UAT |

**CI lane topology (unchanged):**

```
mix ci → mix test → test/docs_contract/viewer_evidence_claims_test.exs (lane 8)
mix docs.contract → scripts/verify_docs.exs
mix rendro.viewer_evidence validate  # operator-local
```

**Sampling strategy:**

- **100% automated** for matrix JSON, evidence frontmatter, deferral lint, orphan scan, missing empty.
- **100% manual** for Acrobat/Preview GUI behavioral truth.
- **Conditional** for forms×pdfjs and embedded×Preview — outcome determines promote vs defer at recording time.

**Nyquist gap note:** GUI re-attestation has no CI substitute — closed by checkpoint tasks + substantive notes review in UAT.

---

## 10. Open Questions

1. **Thin cross-ref stub vs direct pointer** for inherited signing_prep rows — planner discretion (D-15); either passes docs-contract if `evidence:` resolves.
2. **forms × pdfjs** promote vs defer — decided at Wave 2 observation, not planning time.
3. **embedded_files × Preview** promote vs defer — decided at 5-minute re-verify (D-12).
4. **New docs-contract surface modules** — extend `viewer_evidence_claims_test.exs` vs add `signing_viewer_evidence_claims_test.exs` — prefer single lane extension unless file exceeds maintainability.
5. **Parallel Phase 70 merge conflicts** — Phase 70 complete; `api_stability.md` embedded/links/protection sections stable; Phase 71 edits signing sections primarily.

---

## Canonical References for Planner

| Document | Use |
|----------|-----|
| `71-CONTEXT.md` | User decisions D-01–D-24 (binding) |
| `70-RESEARCH.md` / `70-PATTERNS.md` | Atomic wave, pdfium-cli proxy, merge guard |
| `69-RESEARCH.md` | Operator recipe, CHANGELOG discipline |
| `68-CONTEXT.md` | Deferral lint, three matrix states |
| `.planning/ROADMAP.md` | Phase 71 success criteria, pitfall guardrails |
| `.planning/REQUIREMENTS.md` | VIEWER-02–07 definitions |
| `.planning/research/SUMMARY.md` | Behavior ID checklists |
| `priv/support_matrix.json` | 20 unverified cells (source of truth) |
| `lib/rendro/viewer_evidence/matrix.ex` | Surface path mapping |
| `guides/viewer_evidence.md` | Operator recipe; extend Appendix B |
| `scripts/protected_viewer_proof_fixture.exs` | Script pattern for signing fixtures |

---

## RESEARCH COMPLETE
