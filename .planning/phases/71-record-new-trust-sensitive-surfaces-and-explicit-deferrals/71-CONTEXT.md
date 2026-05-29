# Phase 71: Record New Trust-Sensitive Surfaces and Explicit Deferrals - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Close VIEWER-02 through VIEWER-07 by recording every remaining trust-sensitive `(surface × viewer)` cell to a terminal state: `supported` (with evidence file + matrix promotion keys) or `explicit_deferral` (with named `evidence_deferred`). Zero silent `unverified` cells remain at Phase 71 close (~20 cells today).

Surfaces: forms (Acrobat), protection (Acrobat), signature widgets, signing preparation, signed artifacts, long-lived signed artifacts — plus disposition of ambiguous cells (`forms × pdfjs`, `embedded_files × apple_preview`, signing-prep non-Acrobat inheritance).

Out of scope: engine widening for viewers, headless-browser GUI automation, Hex `files:` packaging, staleness blocking on `main` (Phase 72), net-new matrix keys, demoting Phase 70 consolidated rows.

</domain>

<decisions>
## Implementation Decisions

### Wave batching & public-contract closure (Area 1)
- **D-01:** **Single atomic Phase 71 PR** for all ~20 cell closures — mirror Phase 70 D-19. Internal operator recording may use waves (fixtures → Acrobat session → Preview/PDFium/PDF.js → closure); **merge to main is one public-contract unit** (evidence + matrix + `api_stability.md` + CHANGELOG + docs-contract).
- **D-02:** Reject surface-by-surface PRs and promotions-without-deferrals splits — interim silent `unverified` violates Phase 71 success criteria and recreates v2.3-start honesty gap (Pitfall 6).
- **D-03:** CHANGELOG under `[0.3.0] - Unreleased` → `#### Viewer Evidence (v2.3)`: **`Added`** = net-new `unverified` → `supported`; **`Changed`** = new `explicit_deferral`, equivalence-note additions, inherited signing_prep rows. One bullet per `(surface × viewer)` row.
- **D-04:** `api_stability.md` closure order: (1) signing-prep × signature-widget equivalence section first, (2) surface family mirrors bottom-up, (3) docs-contract green before merge. Run `mix rendro.viewer_evidence missing` → empty immediately before PR open.

### Acrobat operator session & fixture chain (Area 2)
- **D-05:** **Option C — fixture reuse + signing chain:** Keep `test/fixtures/forms_support_fixture.pdf` and `test/fixtures/protection_support_fixture.pdf`. Add `Rendro.Test.SigningViewerSupportFixture` + `scripts/signing_viewer_proof_fixtures.exs` for signing surfaces.
- **D-06:** **One Acrobat session, six isolated PDFs, six evidence files** — batch observation by viewer, not by mutating one PDF lineage. Reject single-chain fixture (Option A) and six separate Acrobat launches (Option B).
- **D-07:** **Session order (destructiveness-aware):** Read About once → forms (Save As copy) → protection (password + Save As copy) → signature_widget (Save As copy only for preserve check) → signing_preparation (Save As required for byte-range check) → signed_artifact (read-only first; Save As copy) → long_lived_signed_artifact (read-only LTV UI).
- **D-08:** **Committed fixtures:** `test/fixtures/signature_widget_support_fixture.pdf` (unsigned widget), `test/fixtures/signing_preparation_support_fixture.pdf` (`Sign.prepare/2` output). **Runtime-only (not committed):** signed and long-lived PDFs — generate via scripts; evidence uses `fixture_sha256` + regen command in body (honor `test/fixtures/signing/README.md` for signed bytes in `signing/` dir).
- **D-09:** **Viewer-evidence carve-out:** Allow script-generated committed PDFs at `test/fixtures/signed_artifact_viewer_proof.pdf` and `test/fixtures/long_lived_viewer_proof.pdf` (outside `signing/` tree) with documented regen — signing CI lane stays ephemeral; viewer-evidence lane needs portable `fixture:` paths (Phase 70 protection precedent).
- **D-10:** Evidence paths: `priv/viewer_evidence/{forms,protection,signature_widget,signing_preparation,signed_artifact,long_lived_signed_artifact}/adobe_acrobat_reader.md`. Matrix `viewer_kind: "manual"` for all Acrobat rows. Integrity and certificate trust are **separate behavior notes** on signed_artifact row.

### Complete cell disposition (Area 3)
- **D-11:** **All 20 cells close in Phase 71** (Strategy A) — Phase 72 audits; it does not rescue silent `unverified`. Target: ~11 `supported`, ~9 `explicit_deferral`, 0 bare `unverified`.
- **D-12:** **`embedded_files × apple_preview`:** Mandatory 5-minute re-verify on `embedded_artifact_support_fixture.pdf` in Phase 71. Default deferral if Attachments UI still absent (v1.9 outcome); promote only if discover/open/extract UI now works. Independent of links × Preview (Phase 70 D-07).
- **D-13:** **`forms × pdfjs`:** Attempt promotion in PDF.js operator session using forms fixture; defer only if 4-check fails (`edit_or_toggle` / `save` round-trip). Do not defer without opening current PDF.js.
- **D-14:** **`signed_artifact × chrome_pdfium`:** **Promote** per ROADMAP success criterion #2 — pdfium-cli structural open + appearance; integrity/trust via pdfsig signals in live test lane with honest "no validation panel" notes in evidence. **Do not defer** (ARCHITECTURE.md defer-PDFium-signed line is superseded by ROADMAP).

### Signing-prep equivalence & PDFium path (Area 4)
- **D-15:** **Equivalence Option A (with Acrobat exception):** Non-Acrobat `signing_preparation` rows **inherit** sibling `signature_widget` status — same `status`, `recorded_at`, `viewer_kind`, and `evidence:` pointer (to signature_widget evidence file or thin cross-ref stub at `signing_preparation/<viewer>.md`). **Not** `explicit_deferral` (deferral misstates capability when widget row is supported).
- **D-16:** **Acrobat exception:** Full separate manual evidence for both `signature_widget` and `signing_preparation` — byte-range checklist is viewer-discriminable on Acrobat.
- **D-17:** **`api_stability.md` equivalence note** (ROADMAP #4): Document recording rule — Acrobat independent; Preview/PDFium/PDF.js inherit from signature_widget; PDF.js inherits deferral when sig_widget deferred. STACK one-sentence mirrors per inherited row.
- **D-18:** **New `chrome_pdfium` promotions via pdfium-cli** (extend Phase 70 pattern): `signature_widget`, `signed_artifact` (+ forms already done). Matrix `viewer_kind: "pdfium-cli"`. Body prose pins observation substrate: pdfium-cli version + embedded PDFium build + platform — explicit GUI negation; not fake "Chrome stable" claims.
- **D-19:** **`apple_preview × signature_widget`:** Manual GUI session (`viewer_kind: "manual"`) — ROADMAP SC#2 requires truthful widget rendering checklist; do not reuse Phase 70 pdfium-cli proxy for this net-new GUI promotion.

### Long-lived fixtures & deferral templates (Area 5)
- **D-20:** **`scripts/long_lived_viewer_proof_fixture.exs`** mirroring `protected_viewer_proof_fixture.exs` — certomancer + pyhanko preflight, writes `test/fixtures/long_lived_viewer_proof.pdf`. Reuse `test/fixtures/signing/certomancer/` chain from `signing_live_test.exs`.
- **D-21:** **`scripts/signed_artifact_viewer_proof_fixture.exs`** → `test/fixtures/signed_artifact_viewer_proof.pdf` using checked-in `live_signer_*.pem` (first live-test path, not augment path).
- **D-22:** **Deferral prose — hybrid templates (Appendix B in `guides/viewer_evidence.md`):** Four skeletons (`UPSTREAM_ISSUE`, `NO_SIG_VALIDATION`, `NO_LTV_INDICATORS`, `SURFACE_EQUIVALENCE`) + viewer-specific clause per cell. Pre-validate each string against deferral lint (≥40 chars, no forbidden vocabulary).
- **D-23:** **Mandated deferral rows (matrix-only, no evidence file):**
  - `signature_widget × pdfjs` → mozilla/pdf.js#4202
  - `signed_artifact × apple_preview` → no /Sig validation + append-save invalidation
  - `signed_artifact × pdfjs` → no /Sig validation UI
  - `long_lived × {apple_preview, chrome_pdfium, pdfjs}` → viewer does not implement long-term-validation indicators
  - Plus Area 3 deferrals as applicable (`embedded_files × apple_preview`, `forms × pdfjs` if checklist fails)

### Internal plan split (allowed)
- **D-24:** Plans may split as 71-01 (fixtures + scripts), 71-02 (evidence recording waves), 71-03 (atomic public-contract closure) — **must not merge 71-02 without 71-03** (Phase 70 merge guard).

### Claude's Discretion
- Exact deferral clause wording within hybrid templates (lint-validated).
- Thin cross-ref stub vs direct `evidence:` pointer to signature_widget file for inherited signing_prep rows.
- `SignatureWidgetPdfiumProof` / signed-artifact pdfium live-test module naming and behavior note phrasing.
- Whether forms × pdfjs promotes or defers based on observed checklist outcome.
- embedded_files × Preview promote vs defer based on re-verify outcome.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements and roadmap
- `.planning/ROADMAP.md` — Phase 71 goal, success criteria, pitfall guardrails, out-of-scope equivalence rule
- `.planning/REQUIREMENTS.md` — VIEWER-02 through VIEWER-07
- `.planning/PROJECT.md` — Truthful support matrix, v2.3 milestone intent
- `.planning/v2.3-v2.3-MILESTONE-AUDIT.md` — VIEWER-02–07 gap closure

### Phase 68–70 decisions (baseline)
- `.planning/phases/68-viewer-evidence-schema-mix-task-and-docs-contract-lane/68-CONTEXT.md` — Deferral lint, frontmatter contract, three matrix states
- `.planning/phases/69-operator-recipe-and-first-cell-end-to-end/69-CONTEXT.md` — Operator recipe, CHANGELOG discipline, re-attestation vocabulary
- `.planning/phases/70-consolidate-already-validated-surfaces/70-CONTEXT.md` — Atomic wave D-19, pdfium-cli precedent, Tier-B flip complete

### Research and pitfalls
- `.planning/research/SUMMARY.md` — Wave 2 recording scope, BCD-style matrix discipline
- `.planning/research/ARCHITECTURE.md` — Phase 71 cell inventory (reconcile signed_artifact×pdfium with ROADMAP)
- `.planning/research/STACK.md` — api_stability mirror template, pdfium-cli bounds
- `.planning/research/PITFALLS.md` — Overclaim, fixture drift, honest-failure vocabulary, deferral boilerplate

### Project DNA and prompts
- `prompts/rendro-oss-dna.md` — Docs-as-contract, honest matrix, single verify entrypoint, verification classification
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Honest scope, production observability, no compliance overclaim
- `AGENTS.md` — Pure core, documentation-as-contract

### Operator recipe and fixtures
- `guides/viewer_evidence.md` — Recording recipe; extend with Appendix B deferral templates
- `guides/api_stability.md` — Equivalence note insertion point (Signing Preparation section)
- `test/fixtures/signing/README.md` — Signed-PDF policy; add viewer-evidence carve-out
- `test/rendro/adapters/signing_live_test.exs` — Certomancer long-lived chain reference
- `scripts/protected_viewer_proof_fixture.exs` — Script pattern for long_lived/signed viewer fixtures

### Existing implementation
- `priv/support_matrix.json` — 20 unverified cells to close
- `priv/viewer_evidence/_template.md` — Evidence shape
- `priv/viewer_evidence/forms/chrome_pdfium.md` — pdfium-cli promotion pattern
- `lib/mix/tasks/rendro/viewer_evidence.ex` — list / validate / missing / record
- `lib/rendro/viewer_evidence/validator.ex` — Surface path mapping (signature_widget vs forms)
- `test/docs_contract/viewer_evidence_claims_test.exs` — Merge-blocking enforcement
- `test/support/form_support_fixture.ex` — Forms fixture generator precedent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Test.FormSupportFixture.write_fixture/1` — forms PDF (Acrobat + pdfjs attempt)
- `scripts/protected_viewer_proof_fixture.exs` — protection PDF + preflight pattern for new signing scripts
- `test/fixtures/signing/certomancer/` — Offline PKI for long-lived viewer fixture script
- `test/fixtures/signing/live_signer_*.pem` — Signed-artifact viewer fixture script inputs
- `Mix.Tasks.Rendro.ViewerEvidence` — `record` subcommand (extend for new pdfium-cli surfaces)
- Phase 70 live tests: `forms_viewer_evidence_live_test.exs`, protection/embedded/links adapters — pattern for new SignatureWidgetPdfiumProof

### Established Patterns
- Collection incremental, publication atomic (Phase 70 D-19; BCD/browserslist snapshot model)
- Matrix promotion state + evidence observation facts separated (Phase 68 D-10)
- pdfium-cli structural proxy with explicit GUI negation (Phase 70 D-16, D-17)
- Runtime signed bytes in CI; committed viewer fixtures via script + regen docs (protection precedent)

### Integration Points
- `priv/viewer_evidence/{signature_widget,signing_preparation,signed_artifact,long_lived_signed_artifact}/` — new evidence files
- `priv/support_matrix.json` — promotions + deferrals + inherited signing_prep rows
- `guides/api_stability.md` — equivalence section + per-row STACK mirrors
- `guides/viewer_evidence.md` — Appendix B deferral templates
- `CHANGELOG.md` — Phase 71 closure bullets
- `test/fixtures/` — new committed PDFs + README carve-out

</code_context>

<specifics>
## Specific Ideas

- Treat Phase 71 like **browserslist's single snapshot PR** — compat data publishes atomically; operators may collect over days, but the public contract never shows half-updated viewer posture.
- **Acrobat session** follows PAdES staged testing: distinct artifacts per surface, not one mutating document across all checklists (ETSI TS 119 144-3 lesson).
- **Signing-prep equivalence** follows ROADMAP out-of-scope rule literally: document inheritance in api_stability, do not manufacture three duplicate Preview/PDFium/PDF.js prep checklists when viewers cannot discriminate bytes.
- **PDFium host pinning** follows BCD discipline: matrix key `chrome_pdfium` is a family bucket; evidence pins exact observation substrate (pdfium-cli + embedded PDFium build), not vague "works in Chrome."
- **Deferral templates** follow Phase 68 honest-failure vocabulary — "no with reason" is first-class (Can I Use / BCD `false` + notes), not silent unknown.
- Internal recording waves: W1 fixtures/scripts → W2 Acrobat session → W3 Preview + pdfium-cli + PDF.js deferrals → W4 atomic closure commit.

</specifics>

<deferred>
## Deferred Ideas

- Headless-browser automated Acrobat/Preview GUI CI — separate future milestone (ROADMAP out of scope)
- Optional `host_app` / `embedded_pdfium_version` frontmatter schema fields — document in body prose for v2.3
- Chrome stable GUI pinning as differentiator from pdfium-cli substrate — future re-validation story
- Staleness blocking (`validate --strict`) — Phase 72 GUARDRAIL-02
- Hex `files:` expansion to ship `priv/viewer_evidence/` — release packaging decision

</deferred>

---

*Phase: 71-record-new-trust-sensitive-surfaces-and-explicit-deferrals*
*Context gathered: 2026-05-28*
