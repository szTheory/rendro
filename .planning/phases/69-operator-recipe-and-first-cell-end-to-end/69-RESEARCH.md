# Phase 69 Research: Operator Recipe + First Cell End-to-End

**Researched:** 2026-05-28  
**Phase:** 69-operator-recipe-and-first-cell-end-to-end  
**Requirements:** RECIPE-01, RECIPE-03, RECIPE-05  
**Depends on:** Phase 68 (complete)  
**Purpose:** Answer “What do I need to know to PLAN this phase well?” — not task breakdown.

---

## 1. Executive Summary

Phase 69 closes the **operator durability layer** for v2.3 by publishing `guides/viewer_evidence.md` and walking **one real cell** — **`forms.viewers.apple_preview`** — through the full public-contract cycle. Phase 68 shipped the machine contract (schemas, `Mix.Tasks.Rendro.ViewerEvidence`, eighth docs-contract lane, `_template.md`); Phase 69 adds the **human mirror** and proves the loop works before Phases 70–71 record the remaining cells.

**Current repo state (pre-Phase 69):**

| Artifact | Status |
|----------|--------|
| `guides/viewer_evidence.md` | **Does not exist** |
| `priv/viewer_evidence/forms/apple_preview.md` | **Does not exist** (only `_template.md` + `.gitkeep`) |
| `test/fixtures/forms_support_fixture.pdf` | **Does not exist** (`FormSupportFixture` module exists; PDF not committed) |
| `forms.viewers.apple_preview` matrix row | `supported` with `proof[]` only — **no** `evidence`, `recorded_at`, `viewer_kind` |
| `mix.exs` Policies extras | Only `guides/api_stability.md` — viewer guide **not registered** |
| Production `run_full/3` | Passes tier-A; **4 legacy supported rows** still emit advisory “missing promotion-complete” warnings |

**Phase 69 delivers three requirements:**

- **RECIPE-01:** Canonical evidence home for one cell (`priv/viewer_evidence/forms/apple_preview.md`) with schema-valid frontmatter + prose body.
- **RECIPE-03:** Operator entry point `guides/viewer_evidence.md` in HexDocs **Policies** group — hybrid quick-start (~8 steps) + appendices; bidirectional link with mix task `@moduledoc`.
- **RECIPE-05:** CHANGELOG discipline rule in `guides/api_stability.md` plus a **demonstrated** entry for the worked cell (re-home, status unchanged).

**Recommended first cell:** `forms × apple_preview` — re-attestation consolidation of v1.8 Phase 47 (not net-new promotion). Strategy: mandatory spot-check + schema migration; `recorded_at` = re-validation date (2026-05-28 execution day); Phase 47 date (`2026-05-05`) cited in body prose only.

**Critical planner insight:** Phase 68 intentionally split **tier A** (production matrix passes without promotion-complete fields) from **tier B** (`validate_promotion_complete/2` in fixture tests only). Phase 69 is the first production promotion — after merge, `run_full` must validate the referenced evidence file, and `mix rendro.viewer_evidence list` must show `forms/apple_preview` **without** “legacy: missing evidence pointer”. Four other legacy rows keep warnings until Phase 70.

---

## 2. Current State Analysis (Phase 68 Baseline)

### 2.1 Infrastructure shipped in Phase 68

| Component | Path | Role |
|-----------|------|------|
| Evidence template | `priv/viewer_evidence/_template.md` | Valid example frontmatter (`schema_version: 1`, four `behaviors[]`) |
| Frontmatter schema | `priv/schemas/viewer_evidence.schema.json` | Required keys: `schema_version`, `surface`, `viewer`, `viewer_version`, `platform`, `recorded_at`, `behaviors[]`; `fixture` **or** `fixture_sha256`; forbids `status`, `viewer_kind`, promotion keys |
| Matrix schema | `priv/schemas/support_matrix.schema.json` | `explicit_deferral` + `evidence_deferred`; additive `evidence`, `recorded_at`, `viewer_kind` on supported rows |
| Validator | `lib/rendro/viewer_evidence/validator.ex` | JSV tier-A + Elixir tier-B; `run_full/3`, `validate_evidence_file/3`, orphan scan |
| Mix task | `lib/mix/tasks/rendro/viewer_evidence.ex` | `list`, `missing`, `validate`; forward link stub to Phase 69 guide |
| Docs-contract lane | `test/docs_contract/viewer_evidence_claims_test.exs` | Eighth lane in `scripts/verify_docs.exs`; production tier-A + tier-B fixtures |
| Surface mapping | `Rendro.ViewerEvidence.Matrix` | `forms.viewers.*` → evidence surface `forms`, path `priv/viewer_evidence/forms/<viewer>.md` |

### 2.2 Target matrix row (unchanged status, additive fields only)

**Path:** `forms.viewers.apple_preview` in `priv/support_matrix.json`

**Today (lines 38–44):**

```json
"apple_preview": {
  "status": "supported",
  "proof": [
    "open",
    "default_state_visible",
    "edit_or_toggle",
    "save"
  ]
}
```

**After Phase 69 (additive only — D-13):**

```json
"apple_preview": {
  "status": "supported",
  "proof": [
    "open",
    "default_state_visible",
    "edit_or_toggle",
    "save"
  ],
  "evidence": "priv/viewer_evidence/forms/apple_preview.md",
  "recorded_at": "YYYY-MM-DD",
  "viewer_kind": "manual"
}
```

- `status` and `proof[]` **unchanged** (no regression in published support).
- `recorded_at` in matrix **must equal** `recorded_at` in evidence frontmatter (D-08).
- `viewer_version` and `platform` live **only** in evidence frontmatter (Phase 68 D-11 / PITFALLS #4).

### 2.3 Mix task behavior relevant to operators

| Command | Exit | Notes for Phase 69 |
|---------|------|-------------------|
| `mix rendro.viewer_evidence missing` | 1 (21 unverified cells today) | Quick-start step 1; unchanged count after Phase 69 |
| `mix rendro.viewer_evidence list` | 0 | Post-promotion: `forms/apple_preview` notes column empty (has `evidence`) |
| `mix rendro.viewer_evidence validate` | 0 with stderr warnings | Still **4** legacy warnings until Phase 70; **0** fatals if evidence file valid |
| `mix docs.contract` | 0 | Eighth lane must stay green |

**Legacy warning text (Phase 68 pattern):** `"forms.viewers.<viewer>: supported row missing promotion-complete evidence metadata"` — only for rows lacking `evidence` + `recorded_at` + `viewer_kind`.

### 2.4 Fixture generator (exists, PDF not committed)

`Rendro.Test.FormSupportFixture` (`test/support/form_support_fixture.ex`):

- **Widgets:** `email` (text, prefilled `jon@example.test`), `terms` (checkbox, checked), `contact_email` / `contact_phone` (radio group `contact`, email selected).
- **API:** `document/0`, `render_pdf/0`, `write_fixture/1` — mirrors `EmbeddedArtifactSupportFixture` committed-PDF pattern (Phase 50).
- **Target path (D-09):** `test/fixtures/forms_support_fixture.pdf` — directory exists (signing fixtures present); forms PDF **missing**.

**Regeneration one-liner (for evidence body + guide):**

```elixir
Rendro.Test.FormSupportFixture.write_fixture("test/fixtures/forms_support_fixture.pdf")
```

Optional `scripts/forms_viewer_proof_fixture.exs` (precedent: `scripts/protected_viewer_proof_fixture.exs`) — discretion per D-51; module one-liner is sufficient unless operator ergonomics need `--output` / preflight printing.

### 2.5 Docs-contract enforcement today

**Production (`viewer_evidence_claims_test.exs`):**

- Matrix passes JSV tier-A.
- Orphan scan: only `_template.md` excluded; **any** unreferenced `.md` fails.
- `_template.md` validates against schema + forms proof IDs.
- `run_full()` succeeds; staleness advisory only.

**Not enforced on production matrix yet:**

- `validate_promotion_complete/2` — tier-B fixture subtests only (Phase 68 boundary).
- Full `proof[]` coverage in evidence `behaviors[]` — validator rejects **unknown** behavior IDs but does **not** require every `proof[]` entry be present (`validate_behaviors/2` in `validator.ex`). Recipe and PITFALLS #1 expect all four; Phase 69 evidence should include all four even though CI won't fail on omission today.

**Family tests unchanged in Phase 69 scope:**

- `forms_claims_test.exs` asserts matrix regexes (`apple_preview` → `supported`) and narrow `api_stability.md` wording — **does not** assert Phase 47 sentence or evidence path. Phase 69 `api_stability.md` edit must preserve existing positive/negative assertions (lines 40–66).

### 2.6 Hex / package boundary (operator prerequisite)

`mix.exs` `package/0` `files:` includes `guides/` but **not** `priv/support_matrix.json`, `priv/schemas/`, or `priv/viewer_evidence/`. Guide **Prerequisites** (D-03) must state: **full repo checkout required for recording**; HexDocs is read-only recipe documentation.

---

## 3. Implementation Approach

### 3.1 Guide structure (`guides/viewer_evidence.md`) — Option C hybrid (D-01)

**Tone:** Match `guides/integrations.md` and `guides/api_stability.md` — imperative (“Run…”, “Record…”, “Do not promote if…”), example-led, honest boundaries. Not tutorial fluff.

**Length discipline:** Quick-start ≤ ~40% of guide; appendices skimmable (tables, pass/fail pairs).

**Proposed outline (from 69-CONTEXT specifics + ROADMAP success criteria):**

1. **Purpose** — Matrix index + evidence file as structured compat data (MDN BCD / Can I Use mental model).
2. **Prerequisites** — Repo clone; macOS/Windows/Linux with target viewer; no Hex-only recording.
3. **Status vocabulary** — `supported` vs `unverified` vs `explicit_deferral`; promotion keys vs `evidence_deferred`.
4. **Quick-start (8 steps, each with observable check):**
   1. `mix rendro.viewer_evidence missing` — identify backlog cell.
   2. Read matrix `proof[]` for target cell — confirm behavior IDs.
   3. Prepare/commit fixture (`FormSupportFixture.write_fixture/1` for forms).
   4. Manual checklist in viewer (per-behavior pass/fail + notes).
   5. `cp priv/viewer_evidence/_template.md priv/viewer_evidence/<surface>/<viewer>.md` — fill frontmatter skeleton (field semantics, not observation values in guide).
   6. `mix rendro.viewer_evidence validate` — schema + lint green.
   7. Add `evidence`, `recorded_at`, `viewer_kind` to matrix row; update `guides/api_stability.md` + `CHANGELOG.md`.
   8. `mix rendro.viewer_evidence list` + `mix test test/docs_contract/viewer_evidence_claims_test.exs` (or `mix docs.contract`).
5. **Worked example — forms × Apple Preview** — GitHub `source_url` link to canonical file (`https://github.com/szTheory/rendro/blob/main/priv/viewer_evidence/forms/apple_preview.md`); optional short behaviors excerpt labeled “canonical file wins”; **no** full frontmatter/body inline (D-14–D-16).
6. **Appendix A** — Per-surface checklist tables (forms four-check as reference; others pointer-only for Phases 70–71).
7. **Appendix B** — Explicit-deferral discipline + **synthetic** example (`signed_artifact × apple_preview` hypothetical — matrix-only JSON, **no** production row) (D-17).
8. **Appendix C** — Frontmatter schema guardrails (forbidden keys, byte budget 65536, fixture path rule).
9. **Appendix D** — Mix task reference (exit codes, `--json`, link to `@moduledoc`).
10. **Appendix E** — CI / docs-contract troubleshooting (structural vs behavioral lanes).
11. **Appendix F** — Overclaim boundaries (Poppler ≠ viewer proof; one cell ≠ other surfaces/viewers).

**Cross-links:**

- Guide → `Mix.Tasks.Rendro.ViewerEvidence` (already stubbed line 49 in `@moduledoc`).
- Mix task `@moduledoc` → guide (verify link after guide exists).

**HexDocs registration (D-05):**

```elixir
# mix.exs docs/0
extras: [
  "README.md",
  "guides/integrations.md",
  "guides/branding.md",
  "guides/api_stability.md",
  "guides/viewer_evidence.md"   # NEW
],
groups_for_extras: [
  Guides: ["guides/branding.md", "guides/integrations.md"],
  Policies: [
    "guides/api_stability.md",
    "guides/viewer_evidence.md"  # NEW
  ]
]
```

### 3.2 First cell walkthrough — forms × Apple Preview (re-attestation)

**Manual checklist (matrix `proof[]`):**

| Behavior ID | Operator action (Apple Preview + forms fixture) |
|-------------|--------------------------------------------------|
| `open` | Open `test/fixtures/forms_support_fixture.pdf` without error dialog |
| `default_state_visible` | `email` shows `jon@example.test`; `terms` checked; `contact_email` selected in radio group |
| `edit_or_toggle` | Change email text; toggle terms; switch radio to phone |
| `save` | Save As to new path; reopen; edited state persists |

**Observation capture (D-10, D-12):**

- `viewer_version`: from Preview → About (read at spot-check time — never copy from protection row “11.0”).
- `platform`: macOS version string at observation time (e.g. `"macOS 15.x (arm64)"`).
- `recorded_at`: ISO date of spot-check (execution date); **same** in matrix and frontmatter.
- Each `behaviors[].note`: substantive, widget-specific sentence (not template stubs).

**Evidence frontmatter skeleton (guide shows semantics; canonical file holds values):**

```yaml
---
schema_version: 1
surface: forms
viewer: apple_preview
viewer_version: "<from Preview About>"
platform: "<macOS version at observation>"
recorded_at: "YYYY-MM-DD"
fixture: "test/fixtures/forms_support_fixture.pdf"
behaviors:
  - behavior: open
    result: pass
    note: "<observation>"
  - behavior: default_state_visible
    result: pass
    note: "<email, terms, contact_email/contact_phone>"
  - behavior: edit_or_toggle
    result: pass
    note: "<what was toggled>"
  - behavior: save
    result: pass
    note: "<Save As path behavior>"
---
```

**Body prose (D-11):**

- Provenance: consolidates v1.8 Phase 47 attestation (original date **2026-05-05** in body only).
- Regen: `FormSupportFixture.write_fixture/1` command.
- Boundary: Poppler/forms structural tests ≠ viewer proof; does not promote Acrobat, PDFium, PDF.js, or signature surfaces.

**Synthetic deferral mini-example (guide only, D-17):**

```json
"apple_preview": {
  "status": "explicit_deferral",
  "evidence_deferred": "Apple Preview renders signature appearance but does not implement /Sig cryptographic validation as of Preview X on macOS Y — integrity UI absent."
}
```

Include forbidden vocabulary list (`TBD`, `not yet`, `deferred for later`, empty) and contrast table: `supported` (evidence file + promotion keys) vs `explicit_deferral` (`evidence_deferred` only) vs `unverified` (neither).

### 3.3 `api_stability.md` updates (D-19–D-21)

**New section:** `## Viewer Evidence and CHANGELOG Discipline` (placement: after SemVer / before surface sections, or end of policy preamble — planner chooses; must be discoverable).

**Content:**

- Promotions (`unverified` → `supported`), new `explicit_deferral`, and legacy `supported` re-homes into `priv/viewer_evidence/` are **public-contract changes** requiring CHANGELOG entries.
- Re-validations refreshing `recorded_at` also recorded.
- Pointer to `guides/viewer_evidence.md` as operator recipe.

**Replace Interactive Forms paragraph (current line 42):**

From:

> For text fields, checkboxes, and radio groups, Apple Preview is supported for this phase based on the recorded Phase 47 viewer checklist.

To STACK.md one-sentence template (D-21):

> Apple Preview is `supported` for `forms` based on the recorded viewer checklist for version **{viewer_version}** on **{platform}** (`priv/viewer_evidence/forms/apple_preview.md`). That proof confirms `open`, `default_state_visible`, `edit_or_toggle`, and `save` for the representative forms fixture.

**Preserve:** Adobe Acrobat Reader `unverified` sentence; all `forms_claims_test.exs` refute guards.

**Defer:** Prose updates for embedded_files, links (×2), protection legacy rows → Phase 70 (D-23). Temporary 1-of-5 mirror pattern acceptable when 69→70 run back-to-back.

### 3.4 CHANGELOG (D-22)

Under `[0.3.0] - Unreleased`, add subsection:

```markdown
#### Viewer Evidence (v2.3)

##### Changed

- Document viewer-evidence CHANGELOG discipline in `guides/api_stability.md` — promotions, explicit deferrals, and legacy re-homes require CHANGELOG entries; re-validations refresh `recorded_at` in the log.
- Re-home forms × Apple Preview viewer evidence to `priv/viewer_evidence/forms/apple_preview.md` with matrix `evidence:` pointer (**support status unchanged** since v1.8 Phase 47).
```

Use **Changed** (not Added) for re-homes; reserve **Added** for net-new promotions in Phase 71.

---

## 4. File-by-File Change Map

| File | Action | Details |
|------|--------|---------|
| `guides/viewer_evidence.md` | **Create** | Full hybrid recipe (RECIPE-03); prerequisites, 8-step quick-start, appendices, synthetic deferral, skeleton frontmatter |
| `mix.exs` | **Modify** | Add guide to `extras:` and `Policies` in `groups_for_extras` |
| `priv/viewer_evidence/forms/apple_preview.md` | **Create** | RECIPE-01 canonical cell; copy from `_template.md`; valid frontmatter + body |
| `test/fixtures/forms_support_fixture.pdf` | **Create** | Binary from `FormSupportFixture.write_fixture/1`; committed for reproducibility |
| `priv/support_matrix.json` | **Modify** | Add `evidence`, `recorded_at`, `viewer_kind` to `forms.viewers.apple_preview` only |
| `guides/api_stability.md` | **Modify** | New discipline section + forms × Preview sentence (RECIPE-05) |
| `CHANGELOG.md` | **Modify** | `#### Viewer Evidence (v2.3)` Changed bullets |
| `lib/mix/tasks/rendro/viewer_evidence.ex` | **Modify** (minor) | Confirm `@moduledoc` link to guide resolves; optional back-link polish |
| `test/docs_contract/viewer_evidence_claims_test.exs` | **Modify** (optional) | D-18 lightweight assertions: guide mentions `_template.md` and `priv/viewer_evidence/forms/apple_preview.md` |
| `scripts/forms_viewer_proof_fixture.exs` | **Optional create** | Only if discretion favors script over module one-liner |
| `test/rendro/forms_support_fixture_test.exs` | **Out of scope** unless planner adds structural smoke test (not required by phase boundary) |

**Explicitly do NOT modify (Phase 69 boundary):**

- `priv/schemas/*.schema.json` — no schema lane changes
- Other four legacy supported matrix rows — Phase 70
- Production `explicit_deferral` rows — Phase 71
- `.github/workflows/ci.yml`, `mix.exs` `:ci` alias — no new required jobs (Phase 68 D-24)
- `package/0` `files:` — Hex priv shipping deferred
- Family `*_claims_test.exs` except optional pointer test in viewer_evidence lane

---

## 5. Risks and Pitfalls

Mapped from `.planning/research/PITFALLS.md` and phase guardrails (ROADMAP + 69-CONTEXT).

| Pitfall | Phase 69 risk | Mitigation |
|---------|---------------|------------|
| **#1 Overclaim** | Re-attestation treated as paperwork without spot-check; stub behavior notes | Mandatory manual re-run of all four `proof[]` behaviors; substantive notes per widget (D-10) |
| **#2 Stale dates** | Backdating `recorded_at` to 2026-05-05 without re-check | Re-validation date in frontmatter + matrix; Phase 47 date body-only (D-08) |
| **#3 Scope creep** | Adding production deferral rows, other four consolidations, `init` subcommand, Hex priv packaging | Phase boundary in 69-CONTEXT; synthetic deferral example only |
| **#4 Schema coupling** | Putting `viewer_version` on matrix row; non-additive matrix edits | Promotion keys only on matrix; version in evidence file |
| **#5 Reproducibility** | PDF not committed; fixture path missing; “my local PDF” | Commit `test/fixtures/forms_support_fixture.pdf`; document regen (D-09) |
| **#6 Vague deferral** | Teaching deferral with TBD vocabulary | Guide lists forbidden terms; synthetic example uses named behavior (≥40 chars) |
| **#7 CI dilution** | Claiming mix task validates viewer behavior | Guide Appendix E: docs-contract = structural; signing/long-lived lanes unchanged |
| **#8 Storage / PII** | Screenshots, home paths, secrets in evidence | Text-only; lint rejects images/PEM/home paths; fictional fixture email domain |

**Phase-specific guardrails (ROADMAP):**

- Seven reproducibility fields in every evidence file (fixture, viewer_version, platform, behaviors table, note per entry, recorded_at, optional recorded_by).
- Guide must enable **second operator, zero questions** (UAT criterion in discussion log).

**Validator gap (planner awareness):**

- `validate_behaviors/2` does not require **all** `proof[]` IDs present — only that listed IDs are valid. Recipe should still mandate four rows; consider future tier-B tightening in Phase 70/72, not Phase 69 scope.

**Anti-patterns from 68-PATTERNS.md §4:**

- Do not duplicate full evidence content in guide (drift).
- Do not inline relative `priv/` links on HexDocs (404) — use GitHub `source_url` (D-15).
- Do not add `mix rendro.viewer_evidence` to `:ci` alias.
- Do not require promotion-complete on all supported rows in JSON Schema yet (Phase 70 flip).

---

## 6. Testing & Verification Strategy

### 6.1 Operator smoke test (definition of done)

A second operator with repo clone follows **only** `guides/viewer_evidence.md` to record a **hypothetical second cell** is out of scope for Phase 69 delivery — success criterion is that the guide + worked example make that plausible. Phase 69 **implements** the forms × Preview cell once as the reference implementation.

**Implementer verification sequence (post-change):**

```bash
# 1. Generate fixture (once)
mix run -e 'Rendro.Test.FormSupportFixture.write_fixture("test/fixtures/forms_support_fixture.pdf")'

# 2. Manual Preview checklist (human)

# 3. Structural validation
mix rendro.viewer_evidence validate
mix rendro.viewer_evidence list    # forms/apple_preview: no legacy note

# 4. Docs contract
mix test test/docs_contract/viewer_evidence_claims_test.exs
mix docs.contract

# 5. Regression lanes (unchanged semantics)
mix test test/docs_contract/forms_claims_test.exs
mix ci   # or project-standard verify
```

**Expected `validate` stderr:** 4 advisory warnings (embedded_files × acrobat, links × acrobat, links × apple_preview, protection × apple_preview) — **not** forms/apple_preview.

### 6.2 Docs-contract assertions (existing + optional)

| Test | What it proves post-Phase 69 |
|------|------------------------------|
| `production support matrix passes structural JSV validation` | Additive fields valid |
| `production evidence tree has no orphan markdown files` | `apple_preview.md` referenced |
| `run_full succeeds on production matrix` | Referenced evidence validates |
| `forms_claims_test` | Matrix still `apple_preview` supported; api_stability narrow guards hold |
| Optional new test (D-18) | `File.read!("guides/viewer_evidence.md") =~ "priv/viewer_evidence/_template.md"` and `=~ "priv/viewer_evidence/forms/apple_preview.md"` |

### 6.3 ExDoc build

`mix docs` in `:ci` alias — new guide must build without broken references. Use `skip_undefined_reference_warnings_on` only if needed (prefer valid `@doc` links).

---

## 7. Validation Architecture

Nyquist-oriented verification map: **how each deliverable is verified**, sampling, CI lanes.

| Deliverable | Verification method | Blocking? | CI lane |
|-------------|---------------------|-----------|---------|
| `guides/viewer_evidence.md` exists | ExDoc `mix docs`; optional docs-contract path string asserts | Yes (docs build) | `mix ci` → `docs` |
| Guide in Policies group | Manual/`mix.exs` review; HexDocs group output | Yes (success criterion #1) | `mix docs` |
| Recipe completeness (8 steps, appendices) | **UAT / human** — second-operator read-through; not automated in Phase 69 | Advisory at plan time | — |
| `priv/viewer_evidence/forms/apple_preview.md` | `Validator.validate_evidence_file/3` via `run_full`; JSV + lint + path alignment | Yes | `test/docs_contract/viewer_evidence_claims_test.exs` |
| Matrix promotion fields | `run_full` legacy warnings cleared for forms row; tier-B fixture pattern matches production shape | Yes (operator `list`) | Same docs-contract lane |
| Committed fixture | Operator reproducibility; **not** validated by JSV (no fixture-exists check in validator) | Process gate | Human review |
| `guides/api_stability.md` discipline | Human + preserved `forms_claims_test` guards | Yes | `forms_claims_test.exs` + docs-contract |
| CHANGELOG entry | Human review; release-readiness pattern from Phase 54 | Yes (RECIPE-05) | Review / future release gate |
| Mix task ↔ guide links | `@moduledoc` string match | Low | Code review |
| No scope regression | Matrix diff: only `forms.viewers.apple_preview` gains keys; status unchanged | Yes | Git diff + forms_claims regex |
| Signing / long-lived lanes | Unchanged | Yes | Existing GH Actions (GUARDRAIL-02 deferred to Phase 72 audit) |

**Sampling strategy:**

- **100% automated** for machine-checkable artifacts: matrix JSON, evidence frontmatter, orphan scan, body lint, byte budget.
- **100% manual** for viewer behavioral truth (Preview spot-check) — by design; CI never runs viewers (PITFALLS #7).
- **Spot-check** ExDoc rendered guide for link rot (GitHub canonical URL, Policies navigation).

**CI lane topology (unchanged from Phase 68):**

```
mix ci
  └── mix test
        └── test/docs_contract/viewer_evidence_claims_test.exs  (lane 8)

mix docs.contract
  └── scripts/verify_docs.exs
        └── lane 8 tuple

mix rendro.viewer_evidence validate  # operator-local; NOT in :ci
```

**Nyquist gap note:** Recipe prose quality (RECIPE-03 “zero questions”) has **no** automated linter — closed by worked example + UAT in plan/verify phases. Optional D-18 pointer asserts are **partial** contract only.

---

## 8. Open Questions

1. **Proof-behavior completeness enforcement:** Should Phase 69 add a production docs-contract assert that `apple_preview.md` lists all four `proof[]` behaviors, or rely on recipe discipline until Phase 70/72? Validator currently allows subset. *Recommendation:* include all four in evidence; optional assert in viewer_evidence_claims_test is low-cost and aligns with PITFALLS #1.*

2. **Fixture structural test:** `EmbeddedArtifactSupportFixture` has `embedded_artifact_support_fixture_test.exs`; forms fixture has none. Phase 69 does not require it, but a minimal deterministic `%PDF` test would guard fixture drift. *Defer unless planner wants belt-and-suspenders.*

3. **`scripts/forms_viewer_proof_fixture.exs`:** Module one-liner vs script with preflight output (protected fixture precedent). *Default: module one-liner per D-51 discretion.*

4. **Exact synthetic deferral cell:** Context suggests `signed_artifact × apple_preview`; any hypothetical ≥40-char `evidence_deferred` works if clearly labeled non-production.

5. **Discipline section placement in `api_stability.md`:** Early (policy) vs before Interactive Forms — stylistic; must not break existing section anchors used by other docs-contract tests.

6. **`recorded_by` frontmatter:** Optional in schema; Phase 69 may omit or include operator handle — no requirement conflict.

---

## Canonical References for Planner

| Document | Use |
|----------|-----|
| `69-CONTEXT.md` | User decisions D-01–D-23 (binding) |
| `68-PATTERNS.md` | Docs-contract, mix task, tier A/B, anti-patterns |
| `.planning/ROADMAP.md` | Success criteria, pitfall guardrails |
| `.planning/research/PITFALLS.md` | Risks #1–#8 |
| `.planning/research/STACK.md` | api_stability one-sentence mirror template (line 218) |
| `.planning/research/ARCHITECTURE.md` | Phase 69 scope, done-means |

---

## RESEARCH COMPLETE
