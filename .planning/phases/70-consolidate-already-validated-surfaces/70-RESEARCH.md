# Phase 70 Research: Consolidate Already-Validated Surfaces

**Researched:** 2026-05-28  
**Phase:** 70-consolidate-already-validated-surfaces  
**Requirements:** VIEWER-01  
**Depends on:** Phase 69 (complete)  
**Purpose:** Answer “What do I need to know to PLAN this phase well?” — not task breakdown.

---

## 1. Executive Summary

Phase 70 closes **VIEWER-01** by re-attesting and re-homing the **five pre-v2.3 legacy `supported` viewer rows** into canonical `priv/viewer_evidence/<surface>/<viewer>.md` files with matrix `evidence:` pointers, completing the deferred `guides/api_stability.md` prose mirrors (Phase 69 landed **1-of-6** promotion-complete rows via `forms × chrome_pdfium`; Phase 70 finishes the remaining **5-of-6** manual legacy rows), flipping **Tier-B JSON Schema** promotion-complete enforcement at phase closure, and driving `mix rendro.viewer_evidence validate` legacy warnings from **five to zero**.

**Critical planner insight:** This is **re-attestation consolidation**, not paperwork migration. Every `proof[]` behavior must be manually re-run with substantive fixture-specific notes. Original milestone dates (`2026-05-05` Phase 47 forms, `2026-05-06` Phase 50 embedded/links, Phase 54 protection) belong in evidence **body prose only** — never backdated in `recorded_at`. All five rows are **manual-only** (`viewer_kind: "manual"`); no pdfium-cli proxy exists for Acrobat Attachments pane, Preview password UX, or URI handoff GUI.

**Single atomic public-contract wave (D-19):** One PR lands evidence files → matrix pointers → `api_stability.md` mirrors → CHANGELOG → Tier-B schema flip → docs-contract asserts → `validate` with zero legacy warnings. Schema flip **only at closure** — flipping at phase start would break CI while four+ rows remain pointerless.

**Three unique PDFs, five evidence files, five matrix pointers:**

| Fixture | Rows sharing it |
|---------|-----------------|
| `test/fixtures/forms_support_fixture.pdf` | forms × Apple Preview |
| `test/fixtures/embedded_artifact_support_fixture.pdf` | embedded_files × Acrobat, links × Acrobat, links × Preview |
| `test/fixtures/protection_support_fixture.pdf` | protection × Apple Preview |

---

## 2. Current State Audit

### 2.1 Production matrix — six `supported` rows today

| Matrix path | Status | `evidence` | `recorded_at` | `viewer_kind` | Legacy warning |
|-------------|--------|------------|---------------|---------------|----------------|
| `forms.viewers.apple_preview` | supported | **missing** | — | — | yes |
| `forms.viewers.chrome_pdfium` | supported | `priv/viewer_evidence/forms/chrome_pdfium.md` | 2026-05-28 | pdfium-cli | no |
| `embedded_files.viewers.adobe_acrobat_reader` | supported | **missing** | — | — | yes |
| `links.viewers.adobe_acrobat_reader` | supported | **missing** | — | — | yes |
| `links.viewers.apple_preview` | supported | **missing** | — | — | yes |
| `protection.viewers.apple_preview` | supported | **missing** | — | — | yes |

**Operator confirmation (2026-05-28):**

```bash
mix rendro.viewer_evidence validate   # 5 legacy warnings, exit 0
mix rendro.viewer_evidence list       # supported=6, notes: 5× "legacy: missing evidence pointer"
```

Phase 69 delivered `forms × chrome_pdfium` as the recipe smoke test (pdfium-cli automation path). Phase 70 scope explicitly includes **`forms × Apple Preview`** alongside the four embedded/links/protection legacy rows — not a duplicate of Phase 69’s chrome cell.

### 2.2 Evidence files — what exists vs what Phase 70 creates

| Path | Status |
|------|--------|
| `priv/viewer_evidence/_template.md` | exists (Phase 68) |
| `priv/viewer_evidence/forms/chrome_pdfium.md` | exists (Phase 69) |
| `priv/viewer_evidence/forms/apple_preview.md` | **create** |
| `priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md` | **create** |
| `priv/viewer_evidence/links/adobe_acrobat_reader.md` | **create** |
| `priv/viewer_evidence/links/apple_preview.md` | **create** |
| `priv/viewer_evidence/protection/apple_preview.md` | **create** |

### 2.3 Fixtures — committed vs missing

| Path | Generator | Status |
|------|-----------|--------|
| `test/fixtures/forms_support_fixture.pdf` | `Rendro.Test.FormSupportFixture.write_fixture/1` | **committed** |
| `test/fixtures/embedded_artifact_support_fixture.pdf` | `Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture/1` | **missing** — module + structural test exist; PDF not committed (D-09) |
| `test/fixtures/protection_support_fixture.pdf` | `mix run scripts/protected_viewer_proof_fixture.exs --output test/fixtures/protection_support_fixture.pdf` | **missing** — script exists with qpdf preflight (D-10) |

**Regeneration one-liners (for evidence bodies + optional guide appendix expansion):**

```elixir
# embedded + links (deterministic bytes)
MIX_ENV=test mix run -e 'Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture("test/fixtures/embedded_artifact_support_fixture.pdf")'
```

```bash
# protection (non-deterministic bytes — regen requires re-opening in Preview)
mix run scripts/protected_viewer_proof_fixture.exs --output test/fixtures/protection_support_fixture.pdf
```

Protection script prints open password `open-secret` for operator use; **do not** record passwords in evidence notes (GUARDRAIL-04).

### 2.4 `proof[]` behavior IDs per surface (from `priv/support_matrix.json`)

**forms × apple_preview** (`forms.viewers.apple_preview`, lines 38–45):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `open` | Open fixture without error dialog |
| `default_state_visible` | Email prefilled; terms checked; contact radio selected |
| `edit_or_toggle` | Edit email; toggle terms; switch radio |
| `save` | Save As; reopen; state persists |

**embedded_files × adobe_acrobat_reader** (`embedded_files.viewers.adobe_acrobat_reader`, lines 182–188):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `discoverable` | Embedded file visible in Attachments pane |
| `open_or_extract` | Listed entry opens or extracts |
| `save_or_extract` | Save to disk succeeds |

**links × adobe_acrobat_reader** (`links.viewers.adobe_acrobat_reader`, lines 210–215):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `external_uri_handoff` | External `https://example.com/docs` link hands off to browser/app |
| `internal_page_navigation` | Internal “Continued on page 2” navigates to page 2 |

**links × apple_preview** (`links.viewers.apple_preview`, lines 217–223):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `external_uri_handoff` | Same external link behavior in Preview |
| `internal_page_navigation` | Same internal page link in Preview |

**protection × apple_preview** (`protection.viewers.apple_preview`, lines 260–268):

| Behavior ID | Operator meaning |
|-------------|------------------|
| `opens_with_open_password` | Prompt accepts open password; document opens |
| `displays_authored_content_correctly` | “Protected validation” / fixture body text visible |
| `advisory_print_behavior` | Print UI reflects advisory posture (observational) |
| `advisory_copy_behavior` | Copy UI reflects advisory posture (observational) |
| `save_and_reopen_readability` | Save As + reopen remains readable with password |

**Validator note:** `validate_behaviors/2` rejects unknown IDs but does **not** require every `proof[]` entry be present. Recipe and re-attestation policy (D-01, D-05) still mandate **all** behaviors with substantive notes — especially protection’s full five-check (trust-sensitive surface).

### 2.5 `api_stability.md` — sentences to replace (with line refs)

Phase 69 left a **1-of-5 manual mirror gap** on forms Preview and **phase-summary language** on embedded/links/protection. Phase 70 replaces these with STACK.md one-sentence-per-row templates sourcing `viewer_version`, `platform`, and evidence path from each file’s frontmatter.

| Location | Current prose (summary) | Action |
|----------|-------------------------|--------|
| **Line 48** | “Apple Preview is supported for this phase based on the recorded **Phase 47** viewer checklist.” | Replace with STACK mirror → `priv/viewer_evidence/forms/apple_preview.md` |
| **Line 50** | chrome_pdfium STACK mirror (already canonical) | **Keep unchanged** — forms section carries **two** mirrors after Phase 70 (D-18) |
| **Lines 100–108** | “Embedded Artifact Viewer Posture” — intro references “**phase validation record**”; Acrobat/Preview sentences lack evidence paths | Edit **as one unit** (D-22): intro + Acrobat sentence + Preview sentence |
| **Line 128** | “Apple Preview is `supported` for the `protection` surface based on the recorded **Phase 54 checklist for version 11.0 on macOS 26.4.1**.” | Replace with STACK mirror → `priv/viewer_evidence/protection/apple_preview.md`; read version/platform fresh at re-attestation (D-04) |

**STACK.md template (line 218):**

> {Viewer} is `supported` for `{surface}` based on the recorded viewer checklist for version **{viewer_version}** on **{platform}** (`priv/viewer_evidence/{surface}/{viewer}.md`). That proof confirms `{proof_ids...}` for the representative {surface} fixture.

**Concrete target shapes (placeholders filled from evidence frontmatter at execution time):**

```markdown
<!-- forms × apple_preview — replace line 48 only -->
Apple Preview is `supported` for `forms` based on the recorded viewer checklist for version **{viewer_version}** on **{platform}** (`priv/viewer_evidence/forms/apple_preview.md`). That proof confirms `open`, `default_state_visible`, `edit_or_toggle`, and `save` for the representative forms fixture.

<!-- embedded artifact section — replace lines 102–106 as a unit -->
Viewer support is tracked per surface and per viewer in `priv/support_matrix.json`, with each `supported` claim backed by a recorded checklist in `priv/viewer_evidence/`. Promotion requires recorded evidence (viewer name, version when easily available, OS, fixture, date checked, and per-behavior pass/fail); a pass for one surface does not imply a pass for another on the same viewer, and no viewer is implicitly supported by structural validity alone.

Adobe Acrobat Reader is `supported` for `embedded_files` based on the recorded viewer checklist for version **{viewer_version}** on **{platform}** (`priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md`). That proof confirms `discoverable`, `open_or_extract`, and `save_or_extract` for the representative embedded-artifact fixture. Adobe Acrobat Reader is `supported` for `links` based on the recorded viewer checklist for version **{viewer_version}** on **{platform}** (`priv/viewer_evidence/links/adobe_acrobat_reader.md`). That proof confirms `external_uri_handoff` and `internal_page_navigation` for the same fixture.

Apple Preview is `supported` for `links` based on the recorded viewer checklist for version **{viewer_version}** on **{platform}** (`priv/viewer_evidence/links/apple_preview.md`). That proof confirms `external_uri_handoff` and `internal_page_navigation` for the representative embedded-artifact fixture. Apple Preview remains `unverified` for `embedded_files` — Preview did not surface the document-level embedded file in its UI under the version checked; embedded file discoverability stays `unverified` until a future checklist records the behavior.

<!-- protection — replace line 128 -->
Apple Preview is `supported` for the `protection` surface based on the recorded viewer checklist for version **{viewer_version}** on **{platform}** (`priv/viewer_evidence/protection/apple_preview.md`). That proof confirms `opens_with_open_password`, `displays_authored_content_correctly`, `advisory_print_behavior`, `advisory_copy_behavior`, and `save_and_reopen_readability` for the representative protected fixture.
```

**Preserve unchanged:**

- Line 49: Adobe Acrobat Reader `unverified` for forms
- Line 130: Adobe Acrobat Reader `unverified` for protection
- Embedded artifact high-level status facts: Acrobat supported both surfaces; Preview supported links / unverified embedded_files (D-07 independence)
- All `forms_claims_test.exs` / `embedded_artifact_claims_test.exs` / `protection_claims_test.exs` **positive** substring guards where still accurate

**Refute targets for new docs-contract asserts (D-23):**

- `Phase 47 viewer checklist`
- `Phase 54 checklist`
- `phase validation record`
- `recorded checklist confirms` without `priv/viewer_evidence/` path (optional tightening)

### 2.6 Known docs-contract drift (must fix in Phase 70)

**`forms_claims_test.exs` line 23** — expects `chrome_pdfium` → `unverified`; production matrix has `supported` with evidence:

```elixir
# CURRENT (broken against matrix):
assert matrix =~ ~r/"chrome_pdfium"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

# TARGET:
assert matrix =~ ~r/"chrome_pdfium"\s*:\s*\{\s*"status"\s*:\s*"supported"/s
```

Optional: assert `evidence` pointer substring for chrome_pdfium and apple_preview after consolidation.

### 2.7 Tier-A vs Tier-B validation today

| Check | Production matrix | Fixture subtests |
|-------|-------------------|------------------|
| JSV tier-A (`validate_matrix_structure`) | passes (legacy `supported` without evidence allowed) | same |
| `validate_promotion_complete/1` | **not enforced** | tier-B only |
| `run_full/3` legacy warnings | 5 advisory stderr lines | N/A |
| Orphan scan | passes (only `_template.md` + `chrome_pdfium.md`) | tier-B orphan fixture |

Phase 70 closure adds production `validate_promotion_complete/1` assert (D-25) and JSON Schema tier-B flip (D-24).

---

## 3. Implementation Approach

### 3.1 Re-attestation operator loop (all five rows)

```
commit fixtures (embedded_artifact + protection PDFs)
  → manual checklist per row (re-run every proof[] behavior)
  → cp _template.md → priv/viewer_evidence/<surface>/<viewer>.md
  → fill frontmatter (fixture:, viewer_version, platform, recorded_at, behaviors[])
  → body: provenance date in prose, regen command, cross-boundary negation
  → mix rendro.viewer_evidence validate  (local; still 5 warnings until matrix updated)
  → ATOMIC WAVE: matrix pointers + api_stability + CHANGELOG + schema flip + docs-contract
  → mix rendro.viewer_evidence validate  (0 legacy warnings)
```

**Operator batching (D-06):** Run **embedded_files × Acrobat** and **links × Acrobat** in one Acrobat session on `embedded_artifact_support_fixture.pdf`; write **separate** evidence files per surface×viewer.

**Independence guard (D-07):** **links × Apple Preview** evidence must not claim embedded_files discoverability; matrix keeps `embedded_files.viewers.apple_preview` at `unverified`.

### 3.2 forms × Apple Preview vs chrome_pdfium (orthogonal cells)

Same fixture (`test/fixtures/forms_support_fixture.pdf`), different evidence files and observation classes:

| Row | Evidence path | `viewer_kind` | Observation source |
|-----|---------------|---------------|-------------------|
| forms × apple_preview | `priv/viewer_evidence/forms/apple_preview.md` | `manual` | GUI widget names, Save As |
| forms × chrome_pdfium | `priv/viewer_evidence/forms/chrome_pdfium.md` | `pdfium-cli` | pdfium-cli form/info output |

Both bodies include cross-boundary negation mirroring `chrome_pdfium.md` lines 26–37 (D-17): pdfium-cli does not prove Preview GUI; Preview manual does not inherit pdfium automation.

### 3.3 Matrix additive promotion shape (per row)

Example target for `forms.viewers.apple_preview`:

```json
"apple_preview": {
  "status": "supported",
  "proof": ["open", "default_state_visible", "edit_or_toggle", "save"],
  "evidence": "priv/viewer_evidence/forms/apple_preview.md",
  "recorded_at": "YYYY-MM-DD",
  "viewer_kind": "manual"
}
```

Apply same additive pattern to all five legacy rows. **`status` and `proof[]` unchanged** — no demotions, no new matrix keys (ROADMAP pitfall guardrails).

### 3.4 Tier-B JSON Schema flip (exact change)

**File:** `priv/schemas/support_matrix.schema.json`  
**Location:** `$defs/viewer_row/allOf` — add **third** branch after existing `explicit_deferral` and `unverified` branches (lines 119–151).

```json
{
  "if": {
    "properties": { "status": { "const": "supported" } },
    "required": ["status"]
  },
  "then": {
    "required": ["evidence", "recorded_at", "viewer_kind"]
  }
}
```

**Timing (D-24):** Land in the **same commit** as the last matrix pointer — not at phase start. After flip, any `supported` row without promotion keys fails `Validator.validate_matrix_structure/1` at CI.

**Post-flip state:** All six production `supported` rows promotion-complete → `legacy_supported_warnings/1` returns `[]`.

### 3.5 CHANGELOG (D-20)

Under existing `[0.3.0] - Unreleased` → `#### Viewer Evidence (v2.3)` → **`Changed`** — add **five per-row bullets** (not one vague bullet; not `Added`):

```markdown
##### Changed

- Re-home forms × Apple Preview viewer evidence to `priv/viewer_evidence/forms/apple_preview.md` with matrix `evidence:` pointer (**support status unchanged** since v1.8 Phase 47).
- Re-home embedded_files × Adobe Acrobat Reader viewer evidence to `priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md` with matrix `evidence:` pointer (**support status unchanged** since v1.9 Phase 50).
- Re-home links × Adobe Acrobat Reader viewer evidence to `priv/viewer_evidence/links/adobe_acrobat_reader.md` with matrix `evidence:` pointer (**support status unchanged** since v1.9 Phase 50).
- Re-home links × Apple Preview viewer evidence to `priv/viewer_evidence/links/apple_preview.md` with matrix `evidence:` pointer (**support status unchanged** since v1.9 Phase 50).
- Re-home protection × Apple Preview viewer evidence to `priv/viewer_evidence/protection/apple_preview.md` with matrix `evidence:` pointer (**support status unchanged** since v1.10 Phase 54).
```

---

## 4. File-by-File Change Map

| File | Action | Details |
|------|--------|---------|
| `test/fixtures/embedded_artifact_support_fixture.pdf` | **Create** | Commit before recording; shared by 3 evidence rows |
| `test/fixtures/protection_support_fixture.pdf` | **Create** | Commit before recording; non-deterministic regen |
| `priv/viewer_evidence/forms/apple_preview.md` | **Create** | Manual re-attestation; Phase 47 provenance in body |
| `priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md` | **Create** | Manual; Attachments pane behaviors |
| `priv/viewer_evidence/links/adobe_acrobat_reader.md` | **Create** | Manual; same fixture, separate file |
| `priv/viewer_evidence/links/apple_preview.md` | **Create** | Manual; independent of embedded_files × Preview |
| `priv/viewer_evidence/protection/apple_preview.md` | **Create** | Manual; full five-check; trust-sensitive |
| `priv/support_matrix.json` | **Modify** | Add `evidence`, `recorded_at`, `viewer_kind` on **five** legacy rows only |
| `guides/api_stability.md` | **Modify** | Lines 48, 102–106, 128 per §2.5; preserve chrome_pdfium line 50 |
| `CHANGELOG.md` | **Modify** | Five `Changed` re-home bullets under Viewer Evidence (v2.3) |
| `priv/schemas/support_matrix.schema.json` | **Modify** | Tier-B `supported` → `required: ["evidence", "recorded_at", "viewer_kind"]` at closure |
| `test/docs_contract/viewer_evidence_claims_test.exs` | **Modify** | Production `validate_promotion_complete/1`; path asserts; phase-summary refutes |
| `test/docs_contract/forms_claims_test.exs` | **Modify** | Fix `chrome_pdfium` supported drift (line 23) |
| `guides/viewer_evidence.md` | **Modify** (optional) | Expand Appendix A with embedded/links/protection checklists + regen commands (D discretion) |

**Explicitly do NOT modify (Phase 70 boundary):**

- `forms.viewers.chrome_pdfium` matrix row (already promotion-complete)
- Net-new promotions or `explicit_deferral` rows — Phase 71
- `mix.exs` `:ci` alias, `.github/workflows/ci.yml` — no new required jobs
- Staleness blocking (`validate --strict`) — Phase 72 (D-26)
- `mix rendro.viewer_evidence init` — Phase 72 polish
- Hex `package/0` `files:` — release packaging decision
- Engine code / writer changes — viewer gaps are recorded, not patched

---

## 5. Operator Checklists (per row)

### 5.1 forms × Apple Preview

**Fixture:** `test/fixtures/forms_support_fixture.pdf`  
**Viewer:** Apple Preview (manual)  
**Provenance (body only):** v1.8 Phase 47 original attestation **2026-05-05**  
**Session prerequisites:** macOS with Apple Preview; read version from Preview → About

| Step | Behavior | Pass criteria |
|------|----------|---------------|
| 1 | `open` | Opens without error |
| 2 | `default_state_visible` | `email` = `jon@example.test`; `terms` checked; `contact_email` selected |
| 3 | `edit_or_toggle` | Change email; toggle terms; select `contact_phone` |
| 4 | `save` | Save As new path; reopen; edits persist |

**Evidence path:** `priv/viewer_evidence/forms/apple_preview.md`  
**Matrix path:** `forms.viewers.apple_preview`

### 5.2 embedded_files × Adobe Acrobat Reader (+ batch with 5.3)

**Fixture:** `test/fixtures/embedded_artifact_support_fixture.pdf`  
**Provenance (body only):** v1.9 Phase 50 manual validation **2026-05-06**

| Step | Behavior | Pass criteria |
|------|----------|---------------|
| 1 | `discoverable` | `invoice.csv` (or authored filename) visible in Attachments pane |
| 2 | `open_or_extract` | Attachment opens or extracts successfully |
| 3 | `save_or_extract` | Save attachment to disk succeeds |

**Evidence path:** `priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md`  
**Matrix path:** `embedded_files.viewers.adobe_acrobat_reader`

### 5.3 links × Adobe Acrobat Reader (same Acrobat session as 5.2)

**Fixture:** same `embedded_artifact_support_fixture.pdf`

| Step | Behavior | Pass criteria |
|------|----------|---------------|
| 1 | `external_uri_handoff` | “Rendro documentation” link opens `https://example.com/docs` |
| 2 | `internal_page_navigation` | “Continued on page 2” navigates to page 2 content |

**Evidence path:** `priv/viewer_evidence/links/adobe_acrobat_reader.md`  
**Matrix path:** `links.viewers.adobe_acrobat_reader`

### 5.4 links × Apple Preview (independent session — not conflated with embedded_files)

**Fixture:** same `embedded_artifact_support_fixture.pdf`  
**Provenance (body only):** v1.9 Phase 50; note Preview **links supported / embedded_files unverified** independence

| Step | Behavior | Pass criteria |
|------|----------|---------------|
| 1 | `external_uri_handoff` | External link hands off from Preview |
| 2 | `internal_page_navigation` | Internal link navigates to page 2 |

**Do not** record embedded_files discoverability in this file.  
**Evidence path:** `priv/viewer_evidence/links/apple_preview.md`  
**Matrix path:** `links.viewers.apple_preview`

### 5.5 protection × Apple Preview (full five-check — D-05)

**Fixture:** `test/fixtures/protection_support_fixture.pdf`  
**Open password:** `open-secret` (from script output — use in viewer, not in committed evidence)  
**Provenance (body only):** v1.10 Phase 54 protection audit  
**Regen note:** Script produces **new bytes** each run; re-open in Preview after regen

| Step | Behavior | Pass criteria |
|------|----------|---------------|
| 1 | `opens_with_open_password` | Password prompt; document opens |
| 2 | `displays_authored_content_correctly` | Fixture body text visible |
| 3 | `advisory_print_behavior` | Observe print restriction UI (advisory) |
| 4 | `advisory_copy_behavior` | Observe copy restriction UI (advisory) |
| 5 | `save_and_reopen_readability` | Save As + reopen with password |

**Evidence path:** `priv/viewer_evidence/protection/apple_preview.md`  
**Matrix path:** `protection.viewers.apple_preview`

---

## 6. Docs-Contract Test Changes

### 6.1 `viewer_evidence_claims_test.exs` (primary Phase 70 lane)

**Add — production tier-A promotion-complete (D-25):**

```elixir
test "production support matrix is promotion-complete for all supported rows" do
  matrix = Matrix.load!()
  assert :ok = Validator.validate_promotion_complete(matrix)
end
```

**Add — canonical evidence paths referenced in `api_stability.md`:**

```elixir
test "api stability guide mirrors all consolidated viewer evidence paths" do
  guide = File.read!("guides/api_stability.md")

  for path <- [
        "priv/viewer_evidence/forms/apple_preview.md",
        "priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md",
        "priv/viewer_evidence/links/adobe_acrobat_reader.md",
        "priv/viewer_evidence/links/apple_preview.md",
        "priv/viewer_evidence/protection/apple_preview.md"
      ] do
    assert guide =~ path
  end
end
```

**Add — refute phase-summary phrasing (D-23):**

```elixir
test "viewer claim sentences do not reference phase summaries instead of evidence files" do
  guide = File.read!("guides/api_stability.md")

  refute guide =~ "Phase 47 viewer checklist"
  refute guide =~ "Phase 54 checklist"
  refute guide =~ "phase validation record"
end
```

**Update — `run_full` test expectation:** After consolidation, legacy warnings list should be empty (or assert no `"missing promotion-complete"` substring).

**Optional low-cost asserts:**

- Each evidence file lists all matrix `proof[]` IDs (behaviors completeness — closes Phase 69 open question for legacy rows)
- `recorded_at` in matrix matches frontmatter for each referenced evidence file

### 6.2 `forms_claims_test.exs`

| Change | Reason |
|--------|--------|
| Line 23: `chrome_pdfium` → `supported` | Known drift (D-23) |
| Preserve all `refute` guards in wording test | Adobe forms still `unverified`; no signature overclaim |
| Optional: assert `priv/viewer_evidence/forms/apple_preview.md` in guide if forms section gains path |

### 6.3 `embedded_artifact_claims_test.exs`

Matrix regex assertions (Acrobat embedded supported, Preview embedded unverified, both links supported) **unchanged** — status values do not move.

Guide test `"public embedded files wording matches the recorded viewer evidence"` should still pass if high-level sentences preserved:

- `Adobe Acrobat Reader is \`supported\` for both \`embedded_files\` and \`links\`.`
- `Apple Preview is \`supported\` for \`links\` and \`unverified\` for \`embedded_files\`.`

Optional addition: refute `phase validation record` in embedded section.

### 6.4 `protection_claims_test.exs`

Line 59 `Apple Preview is \`supported\` for the \`protection\` surface` — still valid with STACK template.

Optional: assert evidence path substring; refute hardcoded `Phase 54` / `11.0` / `macOS 26.4.1` if those literals removed from guide (forces frontmatter-driven mirror).

---

## 7. Risks and Pitfalls

| Pitfall | Phase 70 risk | Mitigation |
|---------|---------------|------------|
| **#1 Paperwork migration** | Copying Phase 50/54 validation prose without re-running checklists | D-01 mandatory re-attestation; substantive per-behavior notes |
| **#2 Backdating** | Setting `recorded_at` to 2026-05-05/06/54 audit dates | Re-validation date in frontmatter + matrix; provenance in body only (D-02, D-03) |
| **#3 Conflation** | links × Preview evidence implies embedded_files pass | D-07 independence; matrix `embedded_files.apple_preview` stays `unverified` |
| **#4 Version copy** | Copying `11.0` / `macOS 26.4.1` from old api_stability into frontmatter | D-04 read fresh at observation |
| **#5 Fixture drift** | Recording against uncommitted local PDFs | D-08/D-09 commit fixtures before evidence; frontmatter `fixture:` paths |
| **#6 Schema flip timing** | Flipping JSON Schema at phase start | D-24 flip only when all five pointers land; single atomic wave |
| **#7 Partial api_stability edit** | Updating line 128 but leaving “phase validation record” on line 102 | D-22 edit Embedded Artifact Posture as one unit |
| **#8 Protection secrets** | Recording open password in evidence | Script prints password for operator; lint rejects `passphrase:` patterns |
| **#9 chrome_pdfium regression** | Breaking Phase 69 cell while editing forms section | Do not modify `forms.viewers.chrome_pdfium` row; keep line 50 mirror |
| **#10 forms_claims drift** | CI fails on chrome_pdfium unverified assert | Fix line 23 in same wave as matrix closure |
| **#11 pdfium-cli scope creep** | Automating Preview/Acrobat rows | Manual-only for all five rows (CONTEXT out of scope) |
| **#12 Non-deterministic protection fixture** | Treating regen as byte-identical refresh | D-13 body note; re-open after regen |

**Validator gap (carry forward):** Behavior **completeness** (all `proof[]` present) not enforced by `validate_behaviors/2` — recipe + optional docs-contract assert closes the gap for Phase 70.

---

## 8. Recommended Plan Split

Phase 70 can use **multiple plans** internally as long as **merge remains one atomic public-contract wave** (D-19, D-64 discretion).

| Wave | Plans | Deliverable | Blocking? |
|------|-------|-------------|-----------|
| **W1 — Fixtures** | 70-01 | Commit `embedded_artifact_support_fixture.pdf` + `protection_support_fixture.pdf` | Blocks manual recording |
| **W2 — Manual recording** | 70-02 (Acrobat batch), 70-03 (Preview rows) | Five evidence files with valid frontmatter (matrix pointers **not** yet added) | Blocks public-contract wave |
| **W3 — Public contract closure** | 70-04 | Matrix + api_stability + CHANGELOG + schema flip + docs-contract + zero legacy warnings | Single PR merge unit |

**Alternative thin split:** One plan per surface family (forms, embedded+links, protection) for operator parallelism, then one **closure plan** that must land atomically.

**Verification gate before W3 merge:**

```bash
# Evidence files validate in isolation (use tier-B fixture matrix shape locally OR temp matrix patch)
mix rendro.viewer_evidence validate   # still warns until matrix updated — expected pre-W3

# After W3:
mix rendro.viewer_evidence validate   # 0 legacy warnings
mix test test/docs_contract/viewer_evidence_claims_test.exs
mix test test/docs_contract/forms_claims_test.exs
mix test test/docs_contract/embedded_artifact_claims_test.exs
mix test test/docs_contract/protection_claims_test.exs
mix docs.contract
```

---

## 9. Validation Architecture

Nyquist-oriented verification map: **how each deliverable is verified**, sampling, CI lanes.

| Deliverable | Verification method | Blocking? | CI lane |
|-------------|---------------------|-----------|---------|
| Committed embedded-artifact fixture | `EmbeddedArtifactSupportFixtureTest` (deterministic `%PDF` + structure markers) | Yes (existing test) | `mix test` |
| Committed protection fixture | Human review + optional `pdfinfo` with password; **not** JSV | Process gate | Review |
| Five evidence files — schema | `Validator.validate_evidence_file/3` via `run_full` | Yes | `viewer_evidence_claims_test.exs` |
| Five evidence files — lint | Body lint (no secrets/home paths/images) | Yes | Same lane |
| Matrix promotion keys | `validate_promotion_complete/1` on production matrix (new) | Yes | Same lane |
| JSON Schema tier-B flip | `validate_matrix_structure/1` rejects unsupported without evidence | Yes | Same lane |
| Zero legacy warnings | `run_full` stderr / warnings list | Yes (operator + test) | Same lane + manual `validate` |
| `api_stability.md` mirrors | Path presence asserts; phase-summary refutes; family tests regression | Yes | Multiple docs-contract lanes |
| CHANGELOG five bullets | Human review | Yes (RECIPE-05) | Review |
| Manual behavioral truth | Operator re-attestation checklists (§5) | **Human-only by design** | — |
| Signing / long-lived lanes | Unchanged semantics | Yes | Existing GH Actions (GUARDRAIL-02 deferred Phase 72) |
| Staleness advisory | Still exit 0 | Advisory | Phase 72 blocking |

**Test mapping (requirement → proof):**

| Requirement | Automated proof | Manual proof |
|-------------|-----------------|--------------|
| VIEWER-01 row 1 (forms × Preview) | Orphan scan + frontmatter JSV + promotion-complete + guide path assert | §5.1 checklist |
| VIEWER-01 row 2 (embedded × Acrobat) | Same + embedded_files proof IDs valid | §5.2 checklist |
| VIEWER-01 row 3 (links × Acrobat) | Same + links proof IDs valid | §5.3 checklist |
| VIEWER-01 row 4 (links × Preview) | Same; matrix still shows embedded_files Preview unverified | §5.4 checklist |
| VIEWER-01 row 5 (protection × Preview) | Same + five protection proof IDs | §5.5 full five-check |
| No support regression | Matrix regex tests unchanged statuses; git diff review | — |
| ROADMAP #3 v1.5–v2.2 lanes green | `mix docs.contract` all eight lanes | — |

**CI lane topology (unchanged from Phase 68–69):**

```
mix ci
  └── mix test
        ├── test/docs_contract/viewer_evidence_claims_test.exs  (lane 8 — primary Phase 70 gate)
        ├── test/docs_contract/forms_claims_test.exs
        ├── test/docs_contract/embedded_artifact_claims_test.exs
        └── test/docs_contract/protection_claims_test.exs

mix docs.contract → scripts/verify_docs.exs → lane 8 + family lanes

mix rendro.viewer_evidence validate  # operator-local; NOT in :ci alias
```

**Sampling strategy:**

- **100% automated** for machine-checkable artifacts: matrix JSON, evidence frontmatter, orphan scan, promotion-complete, schema flip, path mirrors.
- **100% manual** for viewer GUI behavioral truth — by design; CI never runs Preview/Acrobat.
- **Spot-check** that `recorded_at` equals between matrix and each evidence frontmatter (optional assert closes D-02).

**Nyquist gap note:** Re-attestation rigor (D-01) has no automated substitute — closed by operator checklist discipline + substantive notes review in plan verify/UAT, not by CI viewers.

---

## 10. Open Questions

1. **Evidence completeness assert:** Add production test that each of the five evidence files lists **all** matrix `proof[]` behaviors? *Recommendation:* yes — low cost, aligns with D-01/D-05 and closes validator gap.*

2. **`guides/viewer_evidence.md` Appendix A expansion:** Add embedded/links/protection checklist tables now vs Phase 72 polish? *Default:* expand in Phase 70 closure plan — operators need regen one-liners for three new fixtures (CONTEXT discretion).*

3. **`scripts/embedded_artifact_viewer_proof_fixture.exs`:** Module one-liner sufficient per Phase 69 precedent — skip unless operator ergonomics demand `--output` wrapper.*

4. **`Rendro.Test.ProtectionSupportFixture` wrapper:** Script-only regen sufficient (D discretion); do not block Phase 70 on wrapper module.*

5. **Parallel Phase 71:** Disjoint files — safe to run in parallel after Phase 69; Phase 70 closure must not wait on Phase 71, but coordinate if shared `api_stability.md` edits conflict (embedded/links/protection sections are Phase 70; signing surfaces Phase 71).*

6. **Guide worked example:** Phase 69 cites `chrome_pdfium.md`; after Phase 70 optionally add sentence that five manual legacy rows now have canonical homes — not required for VIEWER-01 closure.*

---

## Canonical References for Planner

| Document | Use |
|----------|-----|
| `70-CONTEXT.md` | User decisions D-01–D-27 (binding) |
| `69-RESEARCH.md` / `69-PATTERNS.md` | Re-attestation, fixture module pattern, atomic wave precedent |
| `68-PATTERNS.md` | Tier A/B split, schema flip timing, docs-contract lane |
| `.planning/ROADMAP.md` | Phase 70 success criteria, pitfall guardrails |
| `.planning/REQUIREMENTS.md` | VIEWER-01 definition |
| `.planning/research/STACK.md` | api_stability one-sentence mirror template (line 218) |
| `.planning/research/PITFALLS.md` | Backdating, fixture drift, overclaim, independence |
| `priv/viewer_evidence/forms/chrome_pdfium.md` | pdfium-cli proxy pattern + cross-boundary negation |
| `guides/viewer_evidence.md` | Operator recipe; Appendix A forms checklist baseline |

---

## RESEARCH COMPLETE
