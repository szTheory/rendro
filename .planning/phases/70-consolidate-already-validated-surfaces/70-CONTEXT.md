# Phase 70: Consolidate Already-Validated Surfaces - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Close VIEWER-01 by consolidating all five pre-v2.3 legacy `supported` viewer rows into canonical `priv/viewer_evidence/<surface>/<viewer>.md` homes with matrix `evidence:` pointers, completing the deferred `guides/api_stability.md` prose mirrors (Phase 69’s temporary 1-of-5 pattern → 5-of-5), flipping Tier-B promotion-complete enforcement when the wave closes, and preserving every published `status` (no demotions, no new matrix keys).

**Five rows:** forms × Apple Preview (v1.8 Phase 47), embedded_files × Adobe Acrobat Reader (v1.9), links × Adobe Acrobat Reader (v1.9), links × Apple Preview (v1.9), protection × Apple Preview (v1.10 Phase 54).

Out of scope: net-new viewer promotions (Phase 71), explicit deferral rows (Phase 71), `mix rendro.viewer_evidence init` polish (Phase 72 unless trivial), staleness blocking on `main` (Phase 72 GUARDRAIL-02), Hex `files:` packaging expansion, automating Preview/Acrobat rows via pdfium-cli (no credible proxy for Attachments pane, URI handoff, or password UX).

</domain>

<decisions>
## Implementation Decisions

### Re-attestation rigor (Area 1)
- **D-01:** **Re-attestation consolidation** for all five legacy rows — schema migration plus mandatory manual re-run of **every** `proof[]` behavior with substantive fixture-specific notes. Reject paperwork-only migration from milestone summaries (supersedes ARCHITECTURE.md “no manual checking” for viewer-behavioral rows).
- **D-02:** **`recorded_at`** = re-validation date (ISO `YYYY-MM-DD`) in **both** matrix row and evidence frontmatter — must be equal. Original milestone attestation dates (`2026-05-05` Phase 47, `2026-05-06` Phase 50, Phase 54 protection audit) live in evidence **body prose only** — never backdate frontmatter.
- **D-03:** ROADMAP success criterion #2 “traceable to prior milestone audit” means **provenance chain in body prose**, not backdated `recorded_at`.
- **D-04:** Read `viewer_version` and `platform` fresh at observation time — never copy from `api_stability.md`, phase summaries, or other evidence files.
- **D-05:** **protection × Apple Preview** gets a **full five-check** manual checklist (trust-sensitive surface) — not a minimal subset.
- **D-06:** **Operator batching:** run **embedded_files × Acrobat** and **links × Acrobat** in one Acrobat session on the shared embedded-artifact fixture; record separate evidence files per surface×viewer.
- **D-07:** **links × Apple Preview** remains **independent** of embedded_files × Preview — v1.9 precedent (links `supported`, embedded_files `unverified`) must not be conflated in notes or matrix edits.

### Fixture strategy (Area 2)
- **D-08:** All five evidence files use frontmatter **`fixture:`** with a **committed** repo-relative path under `test/fixtures/` — reject `fixture_sha256`-only frontmatter for Phase 70 cells (especially protection, where bytes are non-deterministic).
- **D-09:** **Commit before recording:** `test/fixtures/embedded_artifact_support_fixture.pdf` via `Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture/1` (module exists; PDF not yet committed).
- **D-10:** **Commit before recording:** `test/fixtures/protection_support_fixture.pdf` via `mix run scripts/protected_viewer_proof_fixture.exs --output test/fixtures/protection_support_fixture.pdf`.
- **D-11:** **Shared fixture (intentional):** `test/fixtures/embedded_artifact_support_fixture.pdf` for **embedded_files × Acrobat**, **links × Acrobat**, and **links × Preview** — preserves Phase 50 one-document design (embedded file + external URI + internal page link).
- **D-12:** **forms × Apple Preview** uses existing `test/fixtures/forms_support_fixture.pdf` — same canonical bytes as `forms × chrome_pdfium` (Phase 69).
- **D-13:** Evidence body documents regen one-liner per surface; protection body notes that regen produces **new bytes** and requires re-opening in Preview (not deterministic refresh).

### forms × Apple Preview vs chrome_pdfium (Area 3)
- **D-14:** **Same fixture, orthogonal evidence files** — `priv/viewer_evidence/forms/apple_preview.md` (manual) alongside existing `priv/viewer_evidence/forms/chrome_pdfium.md` (pdfium-cli proxy).
- **D-15:** Matrix: `viewer_kind: "manual"` for Preview; keep `viewer_kind: "pdfium-cli"` on chrome_pdfium unchanged.
- **D-16:** Preview `behaviors[].note` entries describe **GUI observations** (widget names, visible states, Save As behavior) — never pdfium-cli command output.
- **D-17:** Both evidence bodies include explicit cross-boundary negation: pdfium-cli does not prove Preview GUI; Preview manual checklist does not inherit pdfium automation (mirror `chrome_pdfium.md` pattern).
- **D-18:** `api_stability.md` forms section carries **two** STACK-style mirrors after Phase 70 — Preview manual path + existing chrome_pdfium sentence (do not conflate).

### api_stability + CHANGELOG batching (Area 4)
- **D-19:** **Single atomic wave (one PR):** five evidence files → matrix pointers → `api_stability.md` mirrors → CHANGELOG → Tier-B flip + docs-contract asserts → `mix rendro.viewer_evidence validate` with **zero** legacy warnings. Reject matrix-first / prose-later split (conflicts with ROADMAP #4 and Phase 69 D-19 public-contract closure).
- **D-20:** CHANGELOG under existing `[0.3.0] - Unreleased` → `#### Viewer Evidence (v2.3)` → **`Changed`** subsection with **five per-row bullets** (re-home, support status unchanged) — not one vague bullet; not `Added` (these are re-homes, not net-new promotions).
- **D-21:** Replace Phase 47 / Phase 54 / “recorded checklist” / “phase validation record” viewer sentences with **STACK.md one-sentence-per-row template** sourcing `viewer_version`, `platform`, and `priv/viewer_evidence/...` path from each evidence frontmatter.
- **D-22:** Edit **Embedded Artifact Viewer Posture** as one unit: shared intro (line ~102) + Acrobat two-surface sentence + Preview links sentence — avoid partial updates that leave “phase validation record” language.
- **D-23:** Extend `viewer_evidence_claims_test.exs`: assert all five canonical paths in guide; `refute` phase-summary phrasing in viewer-claim sentences. Fix known `forms_claims_test.exs` drift (`chrome_pdfium` regex still expects `unverified`).

### Tier-B JSON Schema flip (Area 5)
- **D-24:** Add `supported` → `required: ["evidence", "recorded_at", "viewer_kind"]` **`if/then`** branch to `priv/schemas/support_matrix.schema.json` at **Phase 70 closure** — same change set as the last legacy pointer lands. Do **not** flip at phase start (would break CI with four+ legacy rows still pointerless).
- **D-25:** Add production **tier-A** assertion: `Validator.validate_promotion_complete/1` on loaded production matrix in `viewer_evidence_claims_test.exs` (today tier-B fixture-only).
- **D-26:** Keep **staleness advisory** (180-day warning, exit 0) until Phase 72 — do not bundle `--strict` staleness blocking into Phase 70.
- **D-27:** After consolidation, `mix rendro.viewer_evidence validate` legacy warnings drop from **five to zero** (six supported viewer rows all promotion-complete including chrome_pdfium).

### Claude's Discretion
- Exact evidence body prose wording and appendix cross-links in `guides/viewer_evidence.md` for embedded/links/protection fixture regen commands.
- Whether to add thin `Rendro.Test.ProtectionSupportFixture` wrapper vs documenting script-only regen (script is sufficient).
- Optional `scripts/embedded_artifact_viewer_proof_fixture.exs` operator wrapper — module one-liner is sufficient per Phase 69 precedent.
- Exact docs-contract assert shapes beyond path presence and phase-summary refute guards.
- Plan split (one plan vs per-surface plans) as long as merge remains one atomic public-contract wave.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements and roadmap
- `.planning/ROADMAP.md` — Phase 70 goal, success criteria, pitfall guardrails
- `.planning/REQUIREMENTS.md` — VIEWER-01
- `.planning/PROJECT.md` — Truthful support matrix, pure core, v2.3 milestone intent
- `.planning/v2.3-v2.3-MILESTONE-AUDIT.md` — VIEWER-01 gap closure target

### Phase 68–69 decisions (baseline)
- `.planning/phases/68-viewer-evidence-schema-mix-task-and-docs-contract-lane/68-CONTEXT.md` — Frontmatter contract, Tier A/B split, promotion-complete rules
- `.planning/phases/68-viewer-evidence-schema-mix-task-and-docs-contract-lane/68-PATTERNS.md` — Schema flip timing (Tier-B in JSON Schema at Phase 70)
- `.planning/phases/69-operator-recipe-and-first-cell-end-to-end/69-CONTEXT.md` — Re-attestation D-07/D-08, api_stability deferral D-23, CHANGELOG discipline D-19–D-22
- `.planning/phases/69-operator-recipe-and-first-cell-end-to-end/69-PATTERNS.md` — Fixture module pattern, evidence file shape

### Research and pitfalls
- `.planning/research/SUMMARY.md` — Wave 1 consolidation scope, BCD-style matrix discipline
- `.planning/research/ARCHITECTURE.md` — Phase 70 file targets (reconcile with re-attestation decisions above)
- `.planning/research/STACK.md` — One-sentence-per-row `api_stability` mirror template
- `.planning/research/PITFALLS.md` — Backdating, fixture drift, overclaim, per-surface independence

### Project DNA and operator recipe
- `prompts/rendro-oss-dna.md` — Docs-as-contract, honest matrix, single verify entrypoint
- `guides/viewer_evidence.md` — Operator recording recipe (manual path + re-attestation vocabulary)
- `guides/api_stability.md` — Prose mirror targets (forms, embedded artifact, protection sections)
- `AGENTS.md` — Pure core, documentation-as-contract

### Historical provenance (body prose citations only)
- `.planning/milestones/v1.8-ROADMAP.md` — Phase 47 forms × Apple Preview original validation
- `.planning/milestones/v1.9-ROADMAP.md` — Phase 50 embedded/links viewer promotions
- `.planning/milestones/v1.10-ROADMAP.md` — Phase 54 protection × Apple Preview

### Existing implementation
- `priv/viewer_evidence/_template.md` — Canonical evidence shape
- `priv/viewer_evidence/forms/chrome_pdfium.md` — pdfium-cli proxy pattern (do not conflate with Preview)
- `priv/schemas/support_matrix.schema.json` — Tier-B flip target
- `priv/schemas/viewer_evidence.schema.json` — Frontmatter validation
- `priv/support_matrix.json` — Five legacy rows to promote-complete
- `test/support/form_support_fixture.ex` — forms fixture generator
- `test/support/embedded_artifact_support_fixture.ex` — embedded/links fixture generator
- `scripts/protected_viewer_proof_fixture.exs` — protection fixture generator
- `test/fixtures/forms_support_fixture.pdf` — Already committed
- `lib/rendro/viewer_evidence/validator.ex` — Tier A/B validation
- `test/docs_contract/viewer_evidence_claims_test.exs` — Docs-contract enforcement lane
- `test/docs_contract/forms_claims_test.exs` — Forms mirror lane (fix chrome_pdfium drift)
- `test/docs_contract/embedded_artifact_claims_test.exs` — Embedded/links posture lane
- `test/docs_contract/protection_claims_test.exs` — Protection mirror lane
- `CHANGELOG.md` — `[0.3.0] - Unreleased` Viewer Evidence subsection

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Test.FormSupportFixture.write_fixture/1` — committed `test/fixtures/forms_support_fixture.pdf` (forms × Preview + chrome_pdfium)
- `Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture/1` — generates embedded+links representative PDF (needs commit)
- `scripts/protected_viewer_proof_fixture.exs` — qpdf-backed protection fixture with preflight checks
- `priv/viewer_evidence/forms/chrome_pdfium.md` — reference evidence file for frontmatter/body/lint patterns
- `Mix.Tasks.Rendro.ViewerEvidence` — `list` / `validate` / `missing` / `record` (forms×chrome_pdfium only today)

### Established Patterns
- Machine-readable `priv/` contract + human `guides/` mirror + docs-contract test (Phase 68)
- Module → `write_fixture/1` → committed PDF → manual checklist → evidence file (Phase 69 forms precedent)
- Promotion state on matrix only; observation facts in evidence frontmatter (Phase 68 D-10)
- Tier A JSV accepts legacy shape until Phase 70 flip; Tier B Elixir promotion-complete (Phase 68 D-25)

### Integration Points
- `priv/support_matrix.json` — add `evidence`, `recorded_at`, `viewer_kind` on five legacy rows
- `priv/viewer_evidence/{forms,embedded_files,links,protection}/` — five new markdown files (forms/apple_preview + four others)
- `test/fixtures/` — commit embedded_artifact + protection PDFs
- `guides/api_stability.md` — replace phase-summary viewer sentences with canonical paths
- `CHANGELOG.md` — five `Changed` re-home bullets
- `priv/schemas/support_matrix.schema.json` — Tier-B `supported` if/then branch
- `test/docs_contract/viewer_evidence_claims_test.exs` — production promotion-complete + path asserts

</code_context>

<specifics>
## Specific Ideas

- Treat consolidation like **MDN BCD / Can I Use**: upgrade structured compat data quality, not boolean relocation — matrix index + evidence file observations (Phase 69 guide framing).
- Operator loop: commit fixtures → manual checklist per row → evidence file → matrix pointer → atomic public-contract closure → Tier-B flip → `validate` shows zero legacy warnings.
- **Three unique PDFs, five evidence files, five matrix pointers** — shared embedded-artifact PDF is intentional Phase 50 design, not lazy duplication.
- pdfium-cli automation proved the Phase 69 recipe smoke test; Phase 70 is **manual-only** for all five legacy rows (no GUI proxy exists for Acrobat Attachments pane or Preview password UX).
- User delegated full decision package via discuss-phase research request — recommendations are coherent across all five gray areas.

</specifics>

<deferred>
## Deferred Ideas

- Net-new viewer promotions and explicit deferrals — Phase 71 (VIEWER-02 through VIEWER-07)
- Staleness blocking (`validate --strict`) — Phase 72 (GUARDRAIL-02)
- `mix rendro.viewer_evidence init` scaffold — Phase 72 polish
- Hex `files:` expansion to ship `priv/viewer_evidence/` — release packaging decision, not Phase 70
- Optional CI assert that every `fixture:` path resolves on disk — low-cost polish, not blocking
- Automating embedded/links/protection rows via pdfium-cli — out of scope (no credible behavioral proxy)

</deferred>

---

*Phase: 70-consolidate-already-validated-surfaces*
*Context gathered: 2026-05-28*
