# Phase 69: Operator Recipe + First Cell End-to-End - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish `guides/viewer_evidence.md` as the operator entry point (HexDocs Policies group), register it in `mix.exs`, and walk **one** real cell — **forms × Apple Preview** — through the full public-contract cycle: committed reproducible fixture → manual checklist → evidence file → matrix promotion-complete fields → `api_stability.md` mirror → CHANGELOG entry → docs-contract green.

Out of scope: the other four legacy `supported` row consolidations (Phase 70), bulk recording and real explicit-deferral matrix rows (Phase 71), `mix rendro.viewer_evidence init` subcommand (defer to Phase 72 polish unless trivial during execution), expanding Hex `files:` to ship `priv/viewer_evidence/` (release packaging decision, not Phase 69), schema or docs-contract lane changes beyond lightweight guide pointer assertions.

</domain>

<decisions>
## Implementation Decisions

### Operator guide shape & tone (Area 1)
- **D-01:** Use **Option C — hybrid**: single-page guide with a linear **Quick-start** runbook (~8 numbered steps with copy-paste commands) plus **appendices** for per-surface checklists, deferral discipline, schema guardrails, mix-task reference, CI troubleshooting, and overclaim boundaries.
- **D-02:** Voice matches existing Rendro guides (`integrations.md`, `api_stability.md`): imperative operator tone (“Run…”, “Record…”, “Do not promote if…”), example-led, concrete, honest — not tutorial fluff.
- **D-03:** Open with **Prerequisites** stating full **repo checkout** is required for recording (Hex package omits `priv/support_matrix.json`, `priv/schemas/`, `priv/viewer_evidence/`); HexDocs is read-only documentation for the recipe.
- **D-04:** Quick-start spine: `missing` → confirm `proof[]` → prepare fixture → manual checklist → create evidence file from `_template.md` → `validate` → promote matrix row → verify (`list` + docs-contract test). Each step ends with an observable check.
- **D-05:** Register `guides/viewer_evidence.md` in `mix.exs` `extras:` and `groups_for_extras` **Policies** alongside `guides/api_stability.md`.
- **D-06:** Quick-start occupies ≤40% of guide length; appendices are skimmable tables and pass/fail pairs. Bidirectional cross-link with `Mix.Tasks.Rendro.ViewerEvidence` `@moduledoc`.

### Phase 47 consolidation — forms × Apple Preview (Area 2)
- **D-07:** Strategy name: **re-attestation consolidation** — schema migration plus mandatory spot-check, not paperwork backdating.
- **D-08:** **`recorded_at`:** use the **re-validation date** (date of spot-check when Phase 69 executes) in **both** matrix row and evidence frontmatter — must be equal. Cite original Phase 47 attestation (`2026-05-05`) in evidence **body prose only**.
- **D-09:** **Fixture:** commit `test/fixtures/forms_support_fixture.pdf` generated from `Rendro.Test.FormSupportFixture.write_fixture/1`; frontmatter uses `fixture: "test/fixtures/forms_support_fixture.pdf"`. Body documents regen command. Do **not** use `fixture_sha256` alone for the canonical first cell.
- **D-10:** **Behavior notes:** substantive, fixture-specific (C2) — reference `email`, `terms`, `contact_email`/`contact_phone` widgets and observed states; one non-empty sentence per behavior. No template stubs.
- **D-11:** **Body framing (D3):** provenance paragraph (consolidates v1.8 Phase 47) + regen instructions + boundary note (Poppler structural proof ≠ viewer proof; does not promote other viewers/surfaces).
- **D-12:** **`viewer_version` and `platform`:** read from Preview → About and macOS version at observation time — never copied from other rows or assumed.
- **D-13:** Matrix promotion adds `evidence`, `recorded_at`, `viewer_kind: "manual"` to existing `supported` row; `status` and `proof[]` unchanged.

### Guide ↔ canonical file relationship (Area 3)
- **D-14:** **Option C (hybrid embedding):** guide shows annotated frontmatter **skeleton** (field names + one-line semantics, not observation values) and path rule; **canonical observations live only** in `priv/viewer_evidence/forms/apple_preview.md`.
- **D-15:** Worked example section: GitHub `source_url` link to canonical file (not relative `priv/` link that 404s on HexDocs); optional one illustrative behaviors excerpt labeled “canonical file wins.”
- **D-16:** Guide names `priv/viewer_evidence/_template.md` as copy source; do **not** inline full `apple_preview.md` frontmatter or body (reject duplication — drift risk, no docs-contract sync lane).
- **D-17:** Include **synthetic explicit-deferral mini-example** in Phase 69 guide (hypothetical cell, e.g. `signed_artifact × apple_preview`): matrix-only `explicit_deferral` + `evidence_deferred`, forbidden vocabulary list, contrast table (`supported` vs `explicit_deferral` vs `unverified`). Do **not** add production deferral matrix rows in Phase 69.
- **D-18:** Optional lightweight docs-contract assertion: guide mentions `_template.md` path and worked-example path `priv/viewer_evidence/forms/apple_preview.md`.

### `api_stability.md` + CHANGELOG scope (Area 4)
- **D-19:** **Option C — full public-contract closure** for the worked cell: discipline section + forms prose update + CHANGELOG entry in same phase.
- **D-20:** Add new **`## Viewer Evidence and CHANGELOG Discipline`** section to `guides/api_stability.md`: promotions (`unverified` → `supported`), new `explicit_deferral`, and legacy `supported` re-homes into `priv/viewer_evidence/` are public-contract changes requiring CHANGELOG entries; re-validations refreshing `recorded_at` also recorded.
- **D-21:** Replace forms × Apple Preview phase-summary sentence with STACK.md template: viewer name, `supported`, version + platform from evidence frontmatter, path `priv/viewer_evidence/forms/apple_preview.md`, and proof behavior list (`open`, `default_state_visible`, `edit_or_toggle`, `save`).
- **D-22:** CHANGELOG under `[0.3.0] - Unreleased`, new `#### Viewer Evidence (v2.3)` subsection with **Changed** bullets: (1) discipline rule adoption, (2) forms × Apple Preview re-home with **support status unchanged** note. Use **Added** for future net-new promotions; **Changed** for re-homes and deferrals.
- **D-23:** Defer `api_stability.md` prose updates for the **other four** legacy supported rows to Phase 70 (VIEWER-01 completion). Temporary 1-of-5 pattern is acceptable when Phases 69→70 run back-to-back.

### Claude's Discretion
- Exact appendix table layout and troubleshooting row wording in the guide.
- Whether to add `scripts/forms_viewer_proof_fixture.exs` vs documenting only `FormSupportFixture.write_fixture/1` in body (prefer module one-liner unless script improves operator ergonomics).
- Exact synthetic deferral example cell choice (must remain hypothetical, not a Phase 71 production row).
- Minor docs-contract guide pointer assertion shape in `viewer_evidence_claims_test.exs`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements and roadmap
- `.planning/ROADMAP.md` — Phase 69 goal, success criteria, pitfall guardrails
- `.planning/REQUIREMENTS.md` — RECIPE-01, RECIPE-03, RECIPE-05
- `.planning/PROJECT.md` — Pure core, truthful support matrix, v2.3 milestone intent
- `.planning/v2.3-v2.3-MILESTONE-AUDIT.md` — Gap closure targets for Phase 69

### Phase 68 decisions (schema/tooling baseline)
- `.planning/phases/68-viewer-evidence-schema-mix-task-and-docs-contract-lane/68-CONTEXT.md` — Frontmatter contract, matrix statuses, mix task exit codes, enforcement thresholds
- `.planning/phases/68-viewer-evidence-schema-mix-task-and-docs-contract-lane/68-PATTERNS.md` — Implementation patterns for validator, docs-contract lane, template

### Research (v2.3 design)
- `.planning/research/SUMMARY.md` — Build order, forms checklist shape, reproducibility seven fields
- `.planning/research/ARCHITECTURE.md` — Phase 69 scope, fixture script precedent, done-means criteria
- `.planning/research/STACK.md` — One-sentence-per-row `api_stability` mirror template
- `.planning/research/PITFALLS.md` — Overclaim, date/file mismatch, honest-failure vocabulary, fixture discipline

### Project DNA and prompts
- `prompts/rendro-oss-dna.md` — Docs-contract tests, honest matrix, instructive errors, verification boundaries
- `prompts/Rendro Brand Book.txt` — Guide style (working code, common failure, production note; imperative voice)
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — ExDoc guides, support matrix honesty
- `AGENTS.md` — Pure core, documentation-as-contract

### Existing implementation and patterns
- `priv/viewer_evidence/_template.md` — Canonical evidence shape
- `priv/schemas/viewer_evidence.schema.json` — Frontmatter JSON Schema
- `priv/support_matrix.json` — Matrix row to promote (`forms.viewers.apple_preview`)
- `test/support/form_support_fixture.ex` — Deterministic forms PDF generator
- `test/support/embedded_artifact_support_fixture.ex` — Precedent for `write_fixture/1` + committed PDF pattern
- `scripts/protected_viewer_proof_fixture.exs` — Script-based fixture precedent (protection surface)
- `lib/mix/tasks/rendro/viewer_evidence.ex` — Operator mix task (forward-link target for guide)
- `guides/api_stability.md` — Policies mirror + CHANGELOG discipline insertion point
- `guides/integrations.md` — Existing guide tone/recipe pattern
- `test/docs_contract/viewer_evidence_claims_test.exs` — Merge-blocking enforcement lane
- `mix.exs` — `extras:` / `groups_for_extras` registration; `@source_url` for GitHub links in guide

### Historical provenance
- `.planning/milestones/v1.8-ROADMAP.md` — Phase 47 forms × Apple Preview original validation
- `.planning/milestones/v1.8-MILESTONE-AUDIT.md` — Original Apple Preview supported / Acrobat unverified boundary

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Test.FormSupportFixture`: `document/0`, `render_pdf/0`, `write_fixture/1` — generate committed `test/fixtures/forms_support_fixture.pdf`
- `priv/viewer_evidence/_template.md`: copy source for new evidence files
- `Mix.Tasks.Rendro.ViewerEvidence`: `list`, `validate`, `missing` with documented exit codes
- `test/docs_contract/viewer_evidence_claims_test.exs`: promotion-complete and lint enforcement

### Established Patterns
- Machine-readable contract in `priv/` + human mirror in `guides/` + docs-contract test (Phase 68)
- Embedded/protection fixtures: module → `write_fixture/1` → committed PDF → manual viewer checklist
- Policies-group guides (`api_stability.md`) for contract/process, not getting-started tutorials
- Matrix holds promotion state; evidence frontmatter holds observation facts only (D-10 from Phase 68)

### Integration Points
- `mix.exs` `docs:` — add guide to `extras` and `Policies` group
- `priv/support_matrix.json` — additive fields on `forms.viewers.apple_preview`
- `guides/api_stability.md` — Interactive Forms section + new discipline section
- `CHANGELOG.md` — `[0.3.0] - Unreleased` Viewer Evidence subsection
- `lib/mix/tasks/rendro/viewer_evidence.ex` — `@moduledoc` forward link already stubbed

</code_context>

<specifics>
## Specific Ideas

- Treat viewer interop like **MDN BCD / Can I Use**: matrix is the index, evidence file is structured compat data with per-behavior notes — consolidation must upgrade data quality, not relocate a boolean.
- Operator loop mirrors **npm audit / brew audit**: `missing` informs backlog → record → `validate` gates → docs-contract is merge authority.
- Guide quick-start outline (section headings): Purpose → Prerequisites → Status vocabulary → Quick-start steps 1–8 → Worked example (forms × Apple Preview) → Appendices A–F (checklists, deferral, schema, mix task, CI failures, boundaries).
- Synthetic deferral example teaches “no with reason” as first-class state (Phase 68 `explicit_deferral` vocabulary).
- HexDocs readers without repo checkout can read the recipe; recording requires clone — state this upfront to avoid surprise.

</specifics>

<deferred>
## Deferred Ideas

- `mix rendro.viewer_evidence init` scaffold subcommand — Phase 72 polish (manual `cp _template.md` sufficient for Phase 69 recipe smoke test)
- Expand Hex `files:` to include `priv/support_matrix.json`, `priv/schemas/`, `priv/viewer_evidence/` — v2.3 release packaging / operator-from-Hex story (milestone audit flagged; not Phase 69)
- `api_stability.md` prose for embedded_files, links (×2), protection legacy rows — Phase 70 (VIEWER-01)
- Production explicit-deferral matrix rows — Phase 71
- Full guide↔evidence-file content equality docs-contract lane — unnecessary; pointer + skeleton discipline sufficient
- Staleness blocking on `main` — Phase 72 (GUARDRAIL-02)

</deferred>

---

*Phase: 69-operator-recipe-and-first-cell-end-to-end*
*Context gathered: 2026-05-28*
