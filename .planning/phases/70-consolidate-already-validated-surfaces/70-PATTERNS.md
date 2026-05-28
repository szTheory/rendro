# Phase 70 Pattern Map: Consolidate Already-Validated Surfaces

**Mapped:** 2026-05-28  
**Sources:** `70-CONTEXT.md`, `70-RESEARCH.md`, Phase 68–69 patterns, existing codebase analogs  
**Phase boundary:** Re-attest and re-home **five** legacy `supported` viewer rows into canonical `priv/viewer_evidence/` homes; complete deferred `api_stability.md` mirrors; flip Tier-B JSON Schema at closure; drive legacy warnings from five to zero. No net-new promotions, no deferrals, no schema lane beyond the `supported` if/then flip.

---

## 1. File role map

### Create — fixtures (Wave 1)

| Path | Role | Closest analog |
|------|------|----------------|
| `test/fixtures/embedded_artifact_support_fixture.pdf` | Committed shared PDF for embedded_files × Acrobat, links × Acrobat, links × Preview | `test/fixtures/forms_support_fixture.pdf` (Phase 69 committed binary) |
| `test/fixtures/protection_support_fixture.pdf` | Committed protected PDF for protection × Preview (non-deterministic regen) | `scripts/protected_viewer_proof_fixture.exs` output pattern |

### Create — evidence files (Wave 2, manual re-attestation)

| Path | Role | Closest analog |
|------|------|----------------|
| `priv/viewer_evidence/forms/apple_preview.md` | Manual GUI evidence; same fixture as chrome_pdfium, orthogonal observation class | `priv/viewer_evidence/forms/chrome_pdfium.md` (cross-boundary negation); `_template.md` (shape) |
| `priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md` | Manual Attachments pane checklist | Phase 50 `50-VALIDATION.md` prose; `_template.md` |
| `priv/viewer_evidence/links/adobe_acrobat_reader.md` | Manual URI handoff + internal nav; same fixture, separate file | Same session as embedded_files × Acrobat (D-06) |
| `priv/viewer_evidence/links/apple_preview.md` | Manual links-only Preview session; independent of embedded_files × Preview (D-07) | `links/adobe_acrobat_reader.md` (surface split pattern) |
| `priv/viewer_evidence/protection/apple_preview.md` | Manual full five-check; trust-sensitive surface (D-05) | Phase 54 protection audit prose; `_template.md` |

### Modify — public contract closure (Wave 3, atomic)

| Path | Role | Closest analog |
|------|------|----------------|
| `priv/support_matrix.json` | Add `evidence`, `recorded_at`, `viewer_kind` on **five** legacy rows only | Phase 69 chrome_pdfium promotion shape (lines 47–58) |
| `guides/api_stability.md` | Replace phase-summary sentences with STACK mirrors; edit Embedded Artifact Posture as one unit | Phase 69 chrome_pdfium mirror (line 50); STACK.md template |
| `CHANGELOG.md` | Five per-row `Changed` re-home bullets under Viewer Evidence (v2.3) | Phase 69 discipline + chrome_pdfium bullet pattern |
| `priv/schemas/support_matrix.schema.json` | Tier-B flip: `supported` → `required: ["evidence", "recorded_at", "viewer_kind"]` | Phase 68 deferred branch (68-PATTERNS §2.6) |
| `test/docs_contract/viewer_evidence_claims_test.exs` | Production `validate_promotion_complete/1`; path asserts; phase-summary refutes; zero legacy warnings | Phase 68 tier-B fixture subtests; Phase 69 production tier-A block |
| `test/docs_contract/forms_claims_test.exs` | Fix `chrome_pdfium` → `supported` drift (line 23) | Existing matrix regex assertions |

### Optional modify (discretion)

| Path | Role | Closest analog |
|------|------|----------------|
| `guides/viewer_evidence.md` | Appendix A expansion: embedded/links/protection checklists + regen one-liners | Phase 69 forms checklist appendix |

### Explicitly out of scope (do not create/modify)

- `forms.viewers.chrome_pdfium` matrix row — already promotion-complete (Phase 69)
- Net-new promotions or `explicit_deferral` rows — Phase 71
- `mix rendro.viewer_evidence init` polish — Phase 72
- Staleness blocking (`validate --strict`) — Phase 72 (GUARDRAIL-02)
- `mix.exs` `:ci` alias, `.github/workflows/ci.yml` — no new CI jobs
- `lib/rendro/viewer_evidence/validator.ex` — no logic changes unless bug found
- Hex `package/0` `files:` — release packaging decision
- Engine/writer code — viewer gaps recorded, not patched
- pdfium-cli automation for Preview/Acrobat rows — no credible GUI proxy

---

## 2. Pattern excerpts

### 2.1 Fixture commit pattern — embedded artifact (deterministic)

**Pattern:** Module → `write_fixture/1` → commit PDF **before** manual recording. One PDF, three evidence rows (intentional Phase 50 design).

**Generator module (existing):**

```100:112:test/support/embedded_artifact_support_fixture.ex
  @doc """
  Writes the representative fixture to `path` and returns `path`.

  Creates parent directories as needed. Used by both the automated
  Poppler structural proof lane and the manual viewer proof lane.
  """
  @spec write_fixture(Path.t()) :: Path.t()
  def write_fixture(path) do
    {:ok, pdf} = render_pdf()
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, pdf)
    path
  end
```

**Regeneration one-liner (evidence body + optional guide):**

```elixir
MIX_ENV=test mix run -e 'Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture("test/fixtures/embedded_artifact_support_fixture.pdf")'
```

**Fixture sharing map:**

| Fixture path | Evidence files |
|--------------|----------------|
| `test/fixtures/embedded_artifact_support_fixture.pdf` | `embedded_files/adobe_acrobat_reader.md`, `links/adobe_acrobat_reader.md`, `links/apple_preview.md` |

**Authored content markers (for substantive behavior notes):**
- Embedded file: `invoice.csv` in Attachments pane
- External link: "Rendro documentation" → `https://example.com/docs`
- Internal link: "Continued on page 2" → page 2

---

### 2.2 Fixture commit pattern — protection (non-deterministic)

**Pattern:** Script with qpdf preflight → commit PDF → re-open in Preview after any regen (D-13).

**Script usage (existing):**

```6:15:scripts/protected_viewer_proof_fixture.exs
  @usage """
  Usage:
    mix run scripts/protected_viewer_proof_fixture.exs --output PATH
    mix run scripts/protected_viewer_proof_fixture.exs --dry-run --output PATH

  Preconditions:
    - Accepted Phase 52 completion for the real protected-fixture path
    - qpdf available on the host
    - pdfinfo available on the host
  """
```

**Regeneration one-liner:**

```bash
mix run scripts/protected_viewer_proof_fixture.exs --output test/fixtures/protection_support_fixture.pdf
```

**Operator guard:** Script prints open password for viewer use — **never** record passwords in evidence notes (lint rejects `passphrase:` patterns).

**Evidence body must state:** regen produces new bytes; re-validation required after regen.

---

### 2.3 Evidence file shape — manual row (copy from `_template.md`)

**Pattern:** Copy `_template.md` → fill frontmatter + body. All five Phase 70 rows use `viewer_kind: "manual"`. Frontmatter **`fixture:`** with committed repo-relative path — reject `fixture_sha256`-only (D-08).

**Template (copy source):**

```1:22:priv/viewer_evidence/_template.md
---
schema_version: 1
surface: forms
viewer: example_viewer
viewer_version: "0.0.0"
platform: "macOS 15 (example)"
recorded_at: "2026-01-01"
fixture: "test/fixtures/example.pdf"
behaviors:
  - behavior: open
    result: pass
    note: "Opened the fixture without error."
  - behavior: default_state_visible
    result: pass
    note: "Default field state was visible on first open."
  - behavior: edit_or_toggle
    result: pass
    note: "Edited or toggled the authored field successfully."
  - behavior: save
    result: pass
    note: "Saved the edited PDF without corruption."
---
```

**Target path rule:** `priv/viewer_evidence/<surface>/<viewer>.md`

**Re-attestation date discipline (D-02, D-03):**
- `recorded_at` = re-validation date (execution day) in **both** matrix row and evidence frontmatter — must be equal
- Original milestone dates (`2026-05-05` Phase 47, `2026-05-06` Phase 50, Phase 54 protection) in evidence **body prose only** — never backdated in frontmatter
- `viewer_version` and `platform` read fresh at observation — never copy from `api_stability.md` or other evidence files (D-04)

**Matrix `proof[]` → behavior coverage (mandatory re-run, D-01):**

| Row | `proof[]` IDs | Count |
|-----|---------------|-------|
| forms × apple_preview | `open`, `default_state_visible`, `edit_or_toggle`, `save` | 4 |
| embedded_files × adobe_acrobat_reader | `discoverable`, `open_or_extract`, `save_or_extract` | 3 |
| links × adobe_acrobat_reader | `external_uri_handoff`, `internal_page_navigation` | 2 |
| links × apple_preview | `external_uri_handoff`, `internal_page_navigation` | 2 |
| protection × apple_preview | `opens_with_open_password`, `displays_authored_content_correctly`, `advisory_print_behavior`, `advisory_copy_behavior`, `save_and_reopen_readability` | 5 (full checklist, D-05) |

**Validator gap:** `validate_behaviors/2` rejects unknown IDs but does **not** require every `proof[]` entry — recipe + substantive notes + optional docs-contract assert close the gap.

---

### 2.4 forms × Apple Preview vs chrome_pdfium (orthogonal cells, D-14–D-18)

**Pattern:** Same fixture, different evidence files and observation classes. Both bodies include cross-boundary negation.

**Existing chrome_pdfium reference (do not conflate):**

```1:37:priv/viewer_evidence/forms/chrome_pdfium.md
---
schema_version: 1
surface: forms
viewer: chrome_pdfium
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-28"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/forms_support_fixture.pdf"
behaviors:
  - behavior: open
    result: pass
    note: "pdfium-cli info opened test/fixtures/forms_support_fixture.pdf without parse errors (PDFium CLI open proxy, not GUI Apple Preview)."
  ...
---

This evidence records **forms × chrome_pdfium** using pdfium-cli on Linux/macOS CI.
PDFium CLI structural and form-field extraction is an automation proxy — it does not
validate GUI Apple Preview or Adobe Acrobat behavior.
...
Boundary: Poppler/pdfinfo structural proof and pdfium-cli form extraction prove authored
AcroForm bytes and field values only. Promoting this cell does not promote other viewers
or surfaces.
```

**apple_preview frontmatter skeleton:**

```yaml
---
schema_version: 1
surface: forms
viewer: apple_preview
viewer_version: "<from Preview → About>"
platform: "<macOS version at observation>"
recorded_at: "YYYY-MM-DD"
fixture: "test/fixtures/forms_support_fixture.pdf"
behaviors:
  - behavior: open
    result: pass
    note: "<GUI: opened without error dialog>"
  # ... all four proof[] IDs — widget names (email, terms, contact_email/contact_phone)
---
```

**apple_preview body framing:**
- Provenance: v1.8 Phase 47 original attestation **2026-05-05** (body only)
- Regen: `Rendro.Test.FormSupportFixture.write_fixture/1`
- Cross-boundary negation: Preview manual does not inherit pdfium-cli automation; pdfium-cli does not prove Preview GUI (mirror chrome_pdfium.md)

**Matrix distinction:**

| Row | `viewer_kind` | Evidence path |
|-----|---------------|---------------|
| forms × apple_preview | `"manual"` | `priv/viewer_evidence/forms/apple_preview.md` |
| forms × chrome_pdfium | `"pdfium-cli"` | `priv/viewer_evidence/forms/chrome_pdfium.md` (unchanged) |

---

### 2.5 Embedded/links manual evidence — session batching and independence

**Operator batching (D-06):** Run **embedded_files × Acrobat** and **links × Acrobat** in one Acrobat session on `embedded_artifact_support_fixture.pdf`; write **separate** evidence files per surface×viewer.

**Independence guard (D-07):** **links × Apple Preview** must not claim embedded_files discoverability. Matrix keeps `embedded_files.viewers.apple_preview` at `unverified`:

```190:197:priv/support_matrix.json
      "apple_preview": {
        "status": "unverified",
        "proof": [
          "discoverable",
          "open_or_extract",
          "save_or_extract"
        ]
      }
```

**links × apple_preview body must note:** Preview links supported / embedded_files unverified — v1.9 precedent; do not conflate in notes or matrix edits.

**embedded_files × adobe_acrobat_reader frontmatter skeleton:**

```yaml
---
schema_version: 1
surface: embedded_files
viewer: adobe_acrobat_reader
viewer_version: "<from Acrobat About>"
platform: "<OS at observation>"
recorded_at: "YYYY-MM-DD"
fixture: "test/fixtures/embedded_artifact_support_fixture.pdf"
behaviors:
  - behavior: discoverable
    result: pass
    note: "<invoice.csv visible in Attachments pane>"
  - behavior: open_or_extract
    result: pass
    note: "<attachment opens or extracts>"
  - behavior: save_or_extract
    result: pass
    note: "<save to disk succeeds>"
---
```

**Provenance (body only):** v1.9 Phase 50 manual validation **2026-05-06**

---

### 2.6 Matrix promotion — five legacy rows (additive only)

**Pattern:** Add `evidence`, `recorded_at`, `viewer_kind` to existing `supported` rows; `status` and `proof[]` unchanged. Do **not** touch `forms.viewers.chrome_pdfium`.

**Before (all five legacy rows today):**

```38:46:priv/support_matrix.json
      "apple_preview": {
        "status": "supported",
        "proof": [
          "open",
          "default_state_visible",
          "edit_or_toggle",
          "save"
        ]
      },
```

```182:189:priv/support_matrix.json
      "adobe_acrobat_reader": {
        "status": "supported",
        "proof": [
          "discoverable",
          "open_or_extract",
          "save_or_extract"
        ]
      },
```

**After (per-row target — `viewer_kind` always `"manual"` for Phase 70):**

```json
"apple_preview": {
  "status": "supported",
  "proof": ["open", "default_state_visible", "edit_or_toggle", "save"],
  "evidence": "priv/viewer_evidence/forms/apple_preview.md",
  "recorded_at": "YYYY-MM-DD",
  "viewer_kind": "manual"
}
```

**Reference promotion-complete row (do not modify):**

```47:58:priv/support_matrix.json
      "chrome_pdfium": {
        "status": "supported",
        "proof": [
          "open",
          "default_state_visible",
          "edit_or_toggle",
          "save"
        ],
        "evidence": "priv/viewer_evidence/forms/chrome_pdfium.md",
        "recorded_at": "2026-05-28",
        "viewer_kind": "pdfium-cli"
      },
```

**Post-closure operator check:**

```bash
mix rendro.viewer_evidence validate   # 0 legacy warnings (was 5)
mix rendro.viewer_evidence list       # supported=6, all notes empty
```

**Production matrix sanity (post-Phase 70):**

| Metric | Before | After |
|--------|--------|-------|
| `supported` rows | 6 | 6 |
| Promotion-complete | 1 (chrome_pdfium) | 6 |
| Legacy warnings | 5 | 0 |

---

### 2.7 Tier-B JSON Schema flip (closure only, D-24)

**Pattern:** Add third `allOf` branch to `$defs/viewer_row` in the **same commit** as the last matrix pointer — not at phase start.

**Current schema (Phase 68 — no `supported` branch):**

```119:152:priv/schemas/support_matrix.schema.json
      "allOf": [
        {
          "if": {
            "properties": { "status": { "const": "explicit_deferral" } },
            "required": ["status"]
          },
          "then": {
            "required": ["evidence_deferred"],
            "not": {
              "anyOf": [
                { "required": ["evidence"] },
                { "required": ["recorded_at"] },
                { "required": ["viewer_kind"] }
              ]
            }
          }
        },
        {
          "if": {
            "properties": { "status": { "const": "unverified" } },
            "required": ["status"]
          },
          "then": {
            "not": {
              "anyOf": [
                { "required": ["evidence"] },
                { "required": ["recorded_at"] },
                { "required": ["viewer_kind"] },
                { "required": ["evidence_deferred"] }
              ]
            }
          }
        }
      ]
```

**Phase 70 addition (third branch):**

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

**Elixir promotion-complete (already implemented — promote to production assert):**

```35:46:lib/rendro/viewer_evidence/validator.ex
  @spec validate_promotion_complete(map(), keyword()) :: :ok | {:error, [String.t()]}
  def validate_promotion_complete(matrix, opts \\ []) do
    strict? = Keyword.get(opts, :strict, true)

    matrix
    |> Matrix.enumerate_viewer_cells()
    |> Enum.flat_map(&promotion_violations(&1, matrix, strict?))
    |> case do
      [] -> :ok
      violations -> {:error, violations}
    end
  end
```

**Legacy warning source (drops to zero after closure):**

```150:162:lib/rendro/viewer_evidence/validator.ex
  defp legacy_supported_warnings(matrix) do
    matrix
    |> Matrix.enumerate_viewer_cells()
    |> Enum.flat_map(fn cell ->
      row = fetch_row(matrix, cell)

      if cell.status == "supported" and not promotion_complete_row?(row) do
        ["#{cell.matrix_path}: supported row missing promotion-complete evidence metadata"]
      else
        []
      end
    end)
  end
```

---

### 2.8 `api_stability.md` mirrors — atomic wave (D-19, D-21, D-22)

**Pattern:** Single PR lands evidence → matrix → guide mirrors → CHANGELOG → schema flip → docs-contract. Forms section carries **two** STACK mirrors after Phase 70 (Preview manual + chrome_pdfium — D-18).

**Replace line 48 (forms × Preview — phase-summary language):**

```48:48:guides/api_stability.md
For text fields, checkboxes, and radio groups, Apple Preview is supported for this phase based on the recorded Phase 47 viewer checklist. Adobe Acrobat Reader remains `unverified` until the same checklist records passing open, visible default state, edit/toggle, and save behavior.
```

**Target (STACK template — fill from evidence frontmatter at execution):**

```markdown
Apple Preview is `supported` for `forms` based on the recorded viewer checklist for version **{viewer_version}** on **{platform}** (`priv/viewer_evidence/forms/apple_preview.md`). That proof confirms `open`, `default_state_visible`, `edit_or_toggle`, and `save` for the representative forms fixture.
```

**Keep unchanged — line 50 chrome_pdfium mirror:**

```50:50:guides/api_stability.md
Chrome PDFium is `supported` for `forms` based on the recorded viewer checklist for version **v0.10.3** on **macOS (arm64)** (`priv/viewer_evidence/forms/chrome_pdfium.md`). That proof confirms `open`, `default_state_visible`, `edit_or_toggle`, and `save` for the representative forms fixture via pdfium-cli automation proxy.
```

**Replace Embedded Artifact Posture as one unit (lines 100–106):**

```100:106:guides/api_stability.md
## Embedded Artifact Viewer Posture

Viewer support is tracked per surface and per viewer in `priv/support_matrix.json`, with each `supported` claim backed by a recorded checklist in the phase validation record. Promotion requires recorded evidence (viewer name, version when easily available, OS, fixture, date checked, and per-behavior pass/fail); a pass for one surface does not imply a pass for another on the same viewer, and no viewer is implicitly supported by structural validity alone.

Adobe Acrobat Reader is `supported` for both `embedded_files` and `links`. The recorded checklist confirms that the embedded file is discoverable in the Attachments pane and that the listed entry can be opened and saved to disk, and that both external `http`/`https` link handoff and internal page navigation work as authored.

Apple Preview is `supported` for `links` and `unverified` for `embedded_files`. The recorded checklist confirms external URI handoff and internal page navigation work in Preview, but Preview did not surface the document-level embedded file in its UI under the version checked. Embedded file discoverability stays `unverified` for Apple Preview until a future checklist records the behavior; the surface is not marked `unsupported`, since Rendro continues to author it correctly per the structural proof lane.
```

**Target intro:** Replace "phase validation record" with `priv/viewer_evidence/` canonical path language. Per-viewer sentences gain STACK mirrors with evidence paths for Acrobat embedded, Acrobat links, Preview links — preserve high-level status facts (Acrobat both surfaces; Preview links / embedded unverified).

**Replace line 128 (protection — hardcoded version copy):**

```128:128:guides/api_stability.md
Apple Preview is `supported` for the `protection` surface based on the recorded Phase 54 checklist for version 11.0 on macOS 26.4.1. That proof confirms `opens_with_open_password`, `displays_authored_content_correctly`, `advisory_print_behavior`, `advisory_copy_behavior`, and `save_and_reopen_readability` for the representative protected fixture.
```

**Target:**

```markdown
Apple Preview is `supported` for the `protection` surface based on the recorded viewer checklist for version **{viewer_version}** on **{platform}** (`priv/viewer_evidence/protection/apple_preview.md`). That proof confirms `opens_with_open_password`, `displays_authored_content_correctly`, `advisory_print_behavior`, `advisory_copy_behavior`, and `save_and_reopen_readability` for the representative protected fixture.
```

**Preserve unchanged:**
- Line 49: Adobe Acrobat Reader `unverified` for forms
- Line 130: Adobe Acrobat Reader `unverified` for protection
- Embedded artifact high-level sentences tested by `embedded_artifact_claims_test.exs` (lines 102–106)

---

### 2.9 CHANGELOG — five per-row `Changed` bullets (D-20)

**Pattern:** Under existing `[0.3.0] - Unreleased` → `#### Viewer Evidence (v2.3)` → **`Changed`** — five bullets, not one vague bullet; not `Added` (re-homes, not net-new promotions).

**Existing subsection (Phase 69 baseline):**

```14:24:CHANGELOG.md
#### Viewer Evidence (v2.3)

##### Added

- `Rendro.Adapters.Pdfium` optional PATH-discovered adapter for pdfium-cli form/info observation used by the viewer-evidence live-proof lane.
- `mix rendro.viewer_evidence record forms chrome_pdfium` to autogenerate evidence files from pdfium-cli observations.
- Promoted `forms.viewers.chrome_pdfium` to `supported` with evidence at `priv/viewer_evidence/forms/chrome_pdfium.md` (`viewer_kind: pdfium-cli`).

##### Changed

- Document viewer-evidence CHANGELOG discipline in `guides/api_stability.md` — promotions, explicit deferrals, and legacy re-homes require CHANGELOG entries; re-validations refresh `recorded_at` in the log.
```

**Phase 70 append under `##### Changed`:**

```markdown
- Re-home forms × Apple Preview viewer evidence to `priv/viewer_evidence/forms/apple_preview.md` with matrix `evidence:` pointer (**support status unchanged** since v1.8 Phase 47).
- Re-home embedded_files × Adobe Acrobat Reader viewer evidence to `priv/viewer_evidence/embedded_files/adobe_acrobat_reader.md` with matrix `evidence:` pointer (**support status unchanged** since v1.9 Phase 50).
- Re-home links × Adobe Acrobat Reader viewer evidence to `priv/viewer_evidence/links/adobe_acrobat_reader.md` with matrix `evidence:` pointer (**support status unchanged** since v1.9 Phase 50).
- Re-home links × Apple Preview viewer evidence to `priv/viewer_evidence/links/apple_preview.md` with matrix `evidence:` pointer (**support status unchanged** since v1.9 Phase 50).
- Re-home protection × Apple Preview viewer evidence to `priv/viewer_evidence/protection/apple_preview.md` with matrix `evidence:` pointer (**support status unchanged** since v1.10 Phase 54).
```

---

### 2.10 Docs-contract lane extensions

**Pattern:** Promote tier-B `validate_promotion_complete/1` to production assert; add path presence and phase-summary refutes; fix known drift.

**Production tier-A block (existing — extend):**

```8:47:test/docs_contract/viewer_evidence_claims_test.exs
  describe "production tier-A artifacts" do
    test "production support matrix passes structural JSV validation" do
      matrix = Matrix.load!()
      assert :ok = Validator.validate_matrix_structure(matrix)
    end
    ...
    test "viewer evidence guide references canonical template and worked example paths" do
      guide = File.read!("guides/viewer_evidence.md")

      assert guide =~ "priv/viewer_evidence/_template.md"
      assert guide =~ "priv/viewer_evidence/forms/chrome_pdfium.md"
    end
  end
```

**Add — production promotion-complete (D-25):**

```elixir
test "production support matrix is promotion-complete for all supported rows" do
  matrix = Matrix.load!()
  assert :ok = Validator.validate_promotion_complete(matrix)
end
```

**Add — canonical evidence paths in guide:**

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

**Update `run_full` test:** After consolidation, assert legacy warnings empty or refute `"missing promotion-complete"`.

**Fix forms_claims drift (line 23):**

```21:24:test/docs_contract/forms_claims_test.exs
    assert matrix =~ ~r/"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
    assert matrix =~ ~r/"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s
    assert matrix =~ ~r/"chrome_pdfium"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
    assert matrix =~ ~r/"pdfjs"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
```

**Target line 23:**

```elixir
assert matrix =~ ~r/"chrome_pdfium"\s*:\s*\{\s*"status"\s*:\s*"supported"/s
```

**Preserve family lane guards — do not break:**

```102:106:test/docs_contract/embedded_artifact_claims_test.exs
    assert guide =~
             "Adobe Acrobat Reader is `supported` for both `embedded_files` and `links`."

    assert guide =~
             "Apple Preview is `supported` for `links` and `unverified` for `embedded_files`."
```

```58:61:test/docs_contract/protection_claims_test.exs
    assert guide =~ "Apple Preview is `supported` for the `protection` surface"
    assert guide =~ "`save_and_reopen_readability`"
    assert guide =~ "Adobe Acrobat Reader remains `unverified`"
```

---

## 3. Integration points

```
Operator workflow (Phase 70)
  W1: commit fixtures
        ├── EmbeddedArtifactSupportFixture.write_fixture/1 → embedded_artifact_support_fixture.pdf
        └── protected_viewer_proof_fixture.exs → protection_support_fixture.pdf
  W2: manual re-attestation (five rows, all viewer_kind: manual)
        ├── cp _template.md → five priv/viewer_evidence/<surface>/<viewer>.md
        ├── Acrobat batch: embedded_files + links (same session, separate files)
        ├── Preview sessions: forms, links (independent of embedded_files), protection (five-check)
        └── mix rendro.viewer_evidence validate  (still 5 legacy warnings until W3)
  W3: atomic public-contract closure (single PR)
        ├── priv/support_matrix.json (five rows)
        ├── guides/api_stability.md (lines 48, 100–106, 128)
        ├── CHANGELOG.md (five Changed bullets)
        ├── priv/schemas/support_matrix.schema.json (supported if/then)
        ├── test/docs_contract/viewer_evidence_claims_test.exs
        ├── test/docs_contract/forms_claims_test.exs
        └── mix rendro.viewer_evidence validate  (0 legacy warnings)

mix ci
  └── mix test
        ├── test/docs_contract/viewer_evidence_claims_test.exs  (lane 8 — primary gate)
        ├── test/docs_contract/forms_claims_test.exs
        ├── test/docs_contract/embedded_artifact_claims_test.exs
        └── test/docs_contract/protection_claims_test.exs

mix docs.contract → scripts/verify_docs.exs → all eight lanes
```

| Integration | Phase 70 touch | Must remain stable |
|-------------|----------------|-------------------|
| `forms.viewers.chrome_pdfium` | **No edits** | Phase 69 promotion-complete cell |
| `embedded_files.viewers.apple_preview` | **Status stays `unverified`** | D-07 independence |
| `Validator.run_full/3` | Warnings drop 5→0 | Staleness still advisory (exit 0) |
| `scripts/verify_docs.exs` | **No edits** | Lane registration unchanged |
| `mix.exs` `:ci` alias | **No viewer task** | Phase 68 D-24 |
| Family `embedded_artifact_claims_test.exs` | **Matrix regex unchanged** | Status values do not move |
| Family `protection_claims_test.exs` | **Matrix regex unchanged** | Optional path assert only |

**Implementer verification sequence (post-W3):**

```bash
mix rendro.viewer_evidence validate
mix test test/docs_contract/viewer_evidence_claims_test.exs
mix test test/docs_contract/forms_claims_test.exs
mix test test/docs_contract/embedded_artifact_claims_test.exs
mix test test/docs_contract/protection_claims_test.exs
mix docs.contract
```

---

## 4. Anti-patterns to avoid

| Anti-pattern | Why it fails | Correct pattern |
|--------------|--------------|-----------------|
| Paperwork migration without re-running checklists | PITFALLS #1; VIEWER-01 requires behavioral truth | Mandatory re-attestation with substantive per-behavior notes (D-01) |
| Backdate `recorded_at` to Phase 47/50/54 dates | PITFALLS #2 | Re-validation date in frontmatter + matrix; provenance in body only (D-02, D-03) |
| Copy `11.0` / `macOS 26.4.1` from old api_stability into frontmatter | PITFALLS #4 (D-04) | Read `viewer_version` and `platform` fresh at observation |
| Record against uncommitted local PDFs | PITFALLS #5 (D-08, D-09) | Commit fixtures before evidence; frontmatter `fixture:` paths |
| Conflate links × Preview with embedded_files pass | PITFALLS #3 (D-07) | Separate evidence file; matrix `embedded_files.apple_preview` stays `unverified` |
| Flip JSON Schema at phase start | Breaks CI with four+ pointerless rows (D-24) | Schema flip in same commit as last matrix pointer |
| Partial api_stability edit (line 128 only) | Leaves "phase validation record" on line 102 (D-22) | Edit Embedded Artifact Posture as one unit |
| Record open password in evidence | GUARDRAIL-04 / lint rejection | Use password in viewer only; never in committed notes |
| Modify `forms.viewers.chrome_pdfium` row | Phase 69 regression (D-09 chrome) | Leave chrome_pdfium unchanged |
| One vague CHANGELOG bullet for five rows | RECIPE-05 / D-20 | Five per-row `Changed` bullets with provenance |
| Use `Added` for re-homes | Misclassifies consolidation | `Changed` with "**support status unchanged**" |
| pdfium-cli automation for Preview/Acrobat | No credible GUI proxy | All five rows `viewer_kind: "manual"` |
| `fixture_sha256`-only frontmatter | Loses reproducibility path (D-08) | Committed `test/fixtures/*.pdf` + `fixture:` key |
| Matrix-first / prose-later split PR | Conflicts with ROADMAP #4 (D-19) | Single atomic public-contract wave |
| Bundle staleness `--strict` blocking | Phase 72 scope (D-26) | Keep 180-day advisory until Phase 72 |
| Demote any `status` or add matrix keys | ROADMAP pitfall guardrails | Re-home only — status and `proof[]` unchanged |
| Template stub behavior notes | Overclaim pitfall | Widget/pane-specific GUI observations per behavior |
| Claim pdfium-cli output in Preview evidence notes | Cross-boundary conflation (D-16, D-17) | GUI observations only in manual files |

---

## PATTERN MAPPING COMPLETE
