# Phase 69 Pattern Map: Operator Recipe + First Cell End-to-End

**Mapped:** 2026-05-28  
**Sources:** `69-CONTEXT.md`, `69-RESEARCH.md`, Phase 68 patterns, existing codebase analogs  
**Phase boundary:** Publish `guides/viewer_evidence.md`, walk **one** cell (`forms × apple_preview`) through the full public-contract cycle; no schema lane changes, no other legacy row consolidations, no production deferral rows.

---

## 1. File role map

### Create

| Path | Role | Closest analog |
|------|------|----------------|
| `guides/viewer_evidence.md` | Operator entry point — hybrid quick-start (~8 steps) + appendices; Policies group | `guides/integrations.md` (imperative recipe tone); `guides/api_stability.md` (Policies contract mirror) |
| `priv/viewer_evidence/forms/apple_preview.md` | Canonical evidence for first promoted cell (RECIPE-01) | `priv/viewer_evidence/_template.md` (copy source); Phase 50 `.planning/phases/50-*/50-VALIDATION.md` (manual checklist prose) |
| `test/fixtures/forms_support_fixture.pdf` | Committed reproducible fixture for forms viewer proof | `test/fixtures/` signing fixtures (committed binary pattern); `EmbeddedArtifactSupportFixture.write_fixture/1` output |

### Modify

| Path | Role | Closest analog |
|------|------|----------------|
| `mix.exs` | Register guide in `extras:` and `Policies` group | Existing `guides/api_stability.md` registration |
| `priv/support_matrix.json` | Additive promotion keys on `forms.viewers.apple_preview` only | Phase 68 tier-B fixture shape (`evidence`, `recorded_at`, `viewer_kind`) |
| `guides/api_stability.md` | New CHANGELOG discipline section + forms × Preview mirror sentence | Existing Interactive Forms section (line 42); protection row mirror (lines 120–122) |
| `CHANGELOG.md` | `#### Viewer Evidence (v2.3)` Changed bullets | Phase 54 protection CHANGELOG pattern |
| `lib/mix/tasks/rendro/viewer_evidence.ex` | Confirm `@moduledoc` guide link resolves | Already stubbed at line 49 — verify only |
| `test/docs_contract/viewer_evidence_claims_test.exs` | Optional lightweight guide pointer assertions (D-18) | `forms_claims_test.exs` self-guard pattern |

### Optional create (discretion)

| Path | Role | Closest analog |
|------|------|----------------|
| `scripts/forms_viewer_proof_fixture.exs` | Operator ergonomics wrapper for fixture generation | `scripts/protected_viewer_proof_fixture.exs` |

### Explicitly out of scope (do not create/modify)

- `priv/schemas/*.schema.json` — no schema lane changes
- Other four legacy `supported` matrix rows — Phase 70
- Production `explicit_deferral` matrix rows — Phase 71
- `mix rendro.viewer_evidence init` subcommand — Phase 72
- `mix.exs` `package/0` `files:` — Hex priv shipping deferred
- `.github/workflows/ci.yml`, `mix.exs` `:ci` alias — no new CI jobs
- Family `*_claims_test.exs` except optional pointer test in viewer_evidence lane
- `test/rendro/forms_support_fixture_test.exs` — not required by phase boundary

---

## 2. Pattern excerpts

### 2.1 Policies-group guide registration (`mix.exs`)

**Pattern:** Register contract/process guides in `extras:` and `groups_for_extras` **Policies** — not `Guides`.

**Current registration (Phase 68 baseline):**

```103:117:mix.exs
      extras: [
        "README.md",
        "guides/integrations.md",
        "guides/branding.md",
        "guides/api_stability.md"
      ],
      groups_for_extras: [
        Guides: [
          "guides/branding.md",
          "guides/integrations.md"
        ],
        Policies: [
          "guides/api_stability.md"
        ]
      ],
```

**Phase 69 addition (same shape, D-05):**

```elixir
extras: [
  "README.md",
  "guides/integrations.md",
  "guides/branding.md",
  "guides/api_stability.md",
  "guides/viewer_evidence.md"
],
groups_for_extras: [
  Guides: ["guides/branding.md", "guides/integrations.md"],
  Policies: [
    "guides/api_stability.md",
    "guides/viewer_evidence.md"
  ]
]
```

**Hex package boundary (Prerequisites D-03):** `package/0` `files:` ships `guides/` but **not** `priv/support_matrix.json`, `priv/schemas/`, or `priv/viewer_evidence/`. Guide must state full repo checkout required for recording.

```74:89:mix.exs
  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(
        lib
        priv/branded
        guides
        .formatter.exs
        mix.exs
        README.md
        LICENSE
        NOTICE
        CHANGELOG.md
      )
    ]
  end
```

**GitHub canonical links in guide:** Use `@source_url` pattern — `https://github.com/szTheory/rendro/blob/main/priv/viewer_evidence/forms/apple_preview.md` — not relative `priv/` links (404 on HexDocs).

---

### 2.2 Operator guide tone and shape (`guides/viewer_evidence.md`)

**Pattern:** Match `integrations.md` and `api_stability.md` — imperative operator voice, example-led, honest boundaries. Not tutorial fluff.

**Tone analog (integrations — imperative setup + verification):**

```158:186:guides/integrations.md
### Setup

1. Add `threadline` to your application's `mix.exs`:

   ```elixir-schematic
   defp deps do
     [
       {:rendro, "~> 0.1"},
       {:threadline, "~> 0.2"},
       # ...
     ]
   end
   ```

2. Attach the handler once at application start (e.g. from `Application.start/2`):

   ```elixir-schematic
   defmodule MyApp.Application do
     use Application

     def start(_type, _args) do
       Rendro.Adapters.Threadline.attach()
       # ... supervise children
     end
   end
   ```

   `attach/0` is idempotent — calling it more than once returns `:ok` without
   registering a duplicate handler.
```

**Tone analog (api_stability — honest boundary prose):**

```30:44:guides/api_stability.md
Structural validation through `pdfinfo`/Poppler proves PDF structure only. It does not prove interactive viewer behavior.

Rendro can author an unsigned placeholder, render an artifact, prepare that final artifact for a lower-level external workflow, or sign the original unsigned artifact through a narrow optional adapter boundary.
...
For text fields, checkboxes, and radio groups, Apple Preview is supported for this phase based on the recorded Phase 47 viewer checklist. Adobe Acrobat Reader remains `unverified` until the same checklist records passing open, visible default state, edit/toggle, and save behavior.

Other viewers are not part of Rendro's supported contract unless `priv/support_matrix.json` later records proof-backed support for them.
```

**Phase 69 guide structure (Option C hybrid, D-01):**

| Section | Content |
|---------|---------|
| Purpose | Matrix index + evidence file as structured compat data |
| Prerequisites | Repo clone required; HexDocs read-only |
| Status vocabulary | `supported` / `unverified` / `explicit_deferral` |
| Quick-start (8 steps) | Each step ends with observable check |
| Worked example | GitHub link to canonical file; skeleton frontmatter only |
| Appendices A–F | Checklists, deferral, schema, mix task, CI, boundaries |

**Length discipline:** Quick-start ≤ ~40% of guide; appendices skimmable tables and pass/fail pairs.

**Guide ↔ canonical file (Option C hybrid, D-14–D-16):**
- Guide shows annotated frontmatter **skeleton** (field names + one-line semantics)
- Canonical observations live **only** in `priv/viewer_evidence/forms/apple_preview.md`
- Guide names `_template.md` as copy source; do **not** inline full evidence content

**Quick-start spine (D-04):**

```
missing → confirm proof[] → prepare fixture → manual checklist →
create evidence from _template.md → validate → promote matrix row →
verify (list + docs-contract)
```

---

### 2.3 Evidence template and canonical cell (`priv/viewer_evidence/`)

**Pattern:** Copy `_template.md` → fill frontmatter + body; matrix holds promotion state; frontmatter holds observation facts only.

**Template (copy source, D-16):**

```1:29:priv/viewer_evidence/_template.md
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

This template documents the canonical viewer-evidence shape for Phase 68.

Use it when recording a promoted matrix cell. Keep bodies short, factual, and free of
secrets, home-directory paths, embedded images, or PEM material. Promotion state belongs
on the support matrix only; frontmatter carries observation facts and behavior notes.
```

**Target path rule:** `priv/viewer_evidence/<surface>/<viewer>.md` → `priv/viewer_evidence/forms/apple_preview.md`

**Frontmatter skeleton for guide (semantics only — values in canonical file):**

```yaml
---
schema_version: 1
surface: forms                    # must match matrix surface mapping
viewer: apple_preview             # must match filename stem
viewer_version: "<from Preview About>"   # read at spot-check — never copy from other rows
platform: "<macOS version at observation>"
recorded_at: "YYYY-MM-DD"         # re-validation date; must equal matrix recorded_at
fixture: "test/fixtures/forms_support_fixture.pdf"
behaviors:
  - behavior: open
    result: pass
    note: "<substantive widget-specific observation>"
  # ... all four proof[] IDs from matrix
---
```

**Body prose framing (D-11):**
- Provenance paragraph (consolidates v1.8 Phase 47; original date **2026-05-05** in body only)
- Regen command: `Rendro.Test.FormSupportFixture.write_fixture/1`
- Boundary note: Poppler structural proof ≠ viewer proof; does not promote other viewers/surfaces

**Re-attestation dates (D-08):**
- `recorded_at` = re-validation date (execution day) in **both** matrix and frontmatter — must be equal
- Phase 47 date (`2026-05-05`) cited in evidence **body prose only** — never backdated in frontmatter

---

### 2.4 Forms fixture generator (`test/support/form_support_fixture.ex`)

**Pattern:** Module → `document/0` → `render_pdf/0` → `write_fixture/1` → committed PDF. Mirrors `EmbeddedArtifactSupportFixture`.

**Forms fixture module:**

```1:58:test/support/form_support_fixture.ex
defmodule Rendro.Test.FormSupportFixture do
  @moduledoc false

  def document do
    %Rendro.Document{
      pages: [
        %Rendro.Page{
          width: 612,
          height: 792,
          margin_left: 72,
          margin_top: 72,
          blocks: [
            Rendro.form_field("email", "jon@example.test", x: 72, y: 96, width: 220, height: 24),
            Rendro.form_field("terms", "",
              type: :checkbox,
              checked: true,
              x: 72,
              y: 136,
              width: 20,
              height: 20
            ),
            Rendro.form_field("contact_email", "",
              type: :radio,
              group: "contact",
              export_value: "email",
              checked: true,
              x: 72,
              y: 176,
              width: 20,
              height: 20
            ),
            Rendro.form_field("contact_phone", "",
              type: :radio,
              group: "contact",
              export_value: "phone",
              x: 112,
              y: 176,
              width: 20,
              height: 20
            )
          ]
        }
      ],
      metadata: %Rendro.Metadata{title: "Rendro Forms Support Fixture"}
    }
  end

  def render_pdf do
    Rendro.render(document(), deterministic: true)
  end

  def write_fixture(path) do
    {:ok, pdf} = render_pdf()
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, pdf)
    path
  end
end
```

**Embedded-artifact precedent (richer `@moduledoc`, same API shape):**

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

**Regeneration one-liner (for evidence body + guide, D-09):**

```elixir
Rendro.Test.FormSupportFixture.write_fixture("test/fixtures/forms_support_fixture.pdf")
```

**Manual checklist (matrix `proof[]` → operator actions):**

| Behavior ID | Operator action (Apple Preview + forms fixture) |
|-------------|--------------------------------------------------|
| `open` | Open `test/fixtures/forms_support_fixture.pdf` without error dialog |
| `default_state_visible` | `email` shows `jon@example.test`; `terms` checked; `contact_email` selected |
| `edit_or_toggle` | Change email text; toggle terms; switch radio to phone |
| `save` | Save As to new path; reopen; edited state persists |

**Behavior notes (D-10):** Substantive, fixture-specific — reference `email`, `terms`, `contact_email`/`contact_phone` widgets; one non-empty sentence per behavior. No template stubs.

**Optional script precedent (`scripts/protected_viewer_proof_fixture.exs`):**

```6:14:scripts/protected_viewer_proof_fixture.exs
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

Default: module one-liner sufficient unless operator ergonomics need `--output` / preflight printing.

---

### 2.5 Matrix promotion (additive only, D-13)

**Pattern:** Add `evidence`, `recorded_at`, `viewer_kind` to existing `supported` row; `status` and `proof[]` unchanged.

**Before (current production):**

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

**After Phase 69 (additive only):**

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

**Critical invariants:**
- `recorded_at` in matrix **must equal** `recorded_at` in evidence frontmatter
- `viewer_version` and `platform` live **only** in evidence frontmatter — never on matrix row
- `status` remains `"supported"` — re-home, not net-new promotion

**Post-promotion operator check:**

```bash
mix rendro.viewer_evidence list    # forms/apple_preview: notes column empty (has evidence)
mix rendro.viewer_evidence validate # 4 legacy warnings remain (not forms/apple_preview)
```

**Expected legacy warnings (unchanged until Phase 70):**
- `embedded_files.viewers.adobe_acrobat_reader`
- `links.viewers.adobe_acrobat_reader`
- `links.viewers.apple_preview`
- `protection.viewers.apple_preview`

---

### 2.6 Mix task ↔ guide bidirectional link

**Pattern:** Mix task `@moduledoc` forward-links to guide; guide links back to `@moduledoc`.

**Existing forward link (verify resolves after guide created):**

```43:49:lib/mix/tasks/rendro/viewer_evidence.ex
  ## CI enforcement

  Merge-blocking checks run through `mix docs.contract` (eighth lane:
  `test/docs_contract/viewer_evidence_claims_test.exs`). This task is **not** part
  of the `mix ci` alias in Phase 68 — use it locally before recording promotions.

  Human workflow guide: `guides/viewer_evidence.md` (Phase 69).
```

**Subcommand contract (unchanged from Phase 68):**

| Subcommand | Exit | Notes for Phase 69 |
|------------|------|-------------------|
| `missing` | 1 (21 unverified cells) | Quick-start step 1; count unchanged |
| `list` | 0 | Post-promotion: `forms/apple_preview` notes empty |
| `validate` | 0 with stderr warnings | 4 legacy warnings; 0 fatals if evidence valid |

---

### 2.7 `api_stability.md` mirror + CHANGELOG discipline (RECIPE-05)

**Pattern:** Policies guide mirrors matrix facts; new discipline section defines CHANGELOG obligations.

**Current forms sentence to replace (line 42):**

```42:42:guides/api_stability.md
For text fields, checkboxes, and radio groups, Apple Preview is supported for this phase based on the recorded Phase 47 viewer checklist. Adobe Acrobat Reader remains `unverified` until the same checklist records passing open, visible default state, edit/toggle, and save behavior.
```

**Target sentence (STACK.md template, D-21):**

```markdown
Apple Preview is `supported` for `forms` based on the recorded viewer checklist for version **{viewer_version}** on **{platform}** (`priv/viewer_evidence/forms/apple_preview.md`). That proof confirms `open`, `default_state_visible`, `edit_or_toggle`, and `save` for the representative forms fixture.
```

**Protection row mirror precedent (version + platform + path + proof list):**

```120:122:guides/api_stability.md
Apple Preview is `supported` for the `protection` surface based on the recorded Phase 54 checklist for version 11.0 on macOS 26.4.1. That proof confirms `opens_with_open_password`, `displays_authored_content_correctly`, `advisory_print_behavior`, `advisory_copy_behavior`, and `save_and_reopen_readability` for the representative protected fixture.
```

**New discipline section (D-20):**

```markdown
## Viewer Evidence and CHANGELOG Discipline

Promotions (`unverified` → `supported`), new `explicit_deferral` rows, and legacy `supported` re-homes into `priv/viewer_evidence/` are public-contract changes requiring CHANGELOG entries. Re-validations that refresh `recorded_at` are also recorded.

See `guides/viewer_evidence.md` for the operator recording recipe.
```

**Preserve `forms_claims_test.exs` guards — do not break refute assertions:**

```37:67:test/docs_contract/forms_claims_test.exs
  test "public forms wording stays narrow and matches the provisional matrix posture" do
    guide = File.read!("guides/api_stability.md")

    assert guide =~
             "Rendro supports authored AcroForm text fields, checkboxes, radio groups, and the explicit `Rendro.signature_field/2` helper for unsigned signature placeholders."
    ...
    refute guide =~ "standard PDF viewers"
    refute guide =~ "Adobe Acrobat Reader is supported"
    refute guide =~ "digital signatures are supported"
    refute guide =~ "viewer support for signature fields"
    refute guide =~ "PAdES is supported"
    refute guide =~ "viewer-proofed digital signatures"
  end
```

**CHANGELOG entry (D-22) under `[0.3.0] - Unreleased`:**

```markdown
#### Viewer Evidence (v2.3)

##### Changed

- Document viewer-evidence CHANGELOG discipline in `guides/api_stability.md` — promotions, explicit deferrals, and legacy re-homes require CHANGELOG entries; re-validations refresh `recorded_at` in the log.
- Re-home forms × Apple Preview viewer evidence to `priv/viewer_evidence/forms/apple_preview.md` with matrix `evidence:` pointer (**support status unchanged** since v1.8 Phase 47).
```

Use **Changed** for re-homes; reserve **Added** for net-new promotions (Phase 71).

---

### 2.8 Synthetic explicit-deferral mini-example (guide only, D-17)

**Pattern:** Teach deferral discipline with hypothetical cell — **no** production matrix row.

**Synthetic JSON (guide appendix only):**

```json
"apple_preview": {
  "status": "explicit_deferral",
  "evidence_deferred": "Apple Preview renders signature appearance but does not implement /Sig cryptographic validation as of Preview X on macOS Y — integrity UI absent."
}
```

**Contrast table (guide appendix):**

| Status | Matrix keys | Evidence file |
|--------|-------------|---------------|
| `supported` | `evidence`, `recorded_at`, `viewer_kind` | Required |
| `explicit_deferral` | `evidence_deferred` only | Forbidden |
| `unverified` | Neither | Forbidden |

**Forbidden deferral vocabulary (from Phase 68 lint):**

```73:80:test/docs_contract/viewer_evidence_claims_test.exs
    test "deferral reason lint rejects TBD, vague, short, and deferred-for-later vocabulary" do
      ...
      assert {:error, _} = Lint.deferral_reason("not yet")
      assert {:error, _} = Lint.deferral_reason("deferred for later")
      assert {:error, _} = Lint.deferral_reason("short deferral reason under forty chars")
```

---

### 2.9 Docs-contract lane (existing + optional pointer asserts)

**Pattern:** Production tier-A passes after promotion; optional lightweight guide pointer test (D-18).

**Production tests (unchanged structure — must stay green):**

```8:39:test/docs_contract/viewer_evidence_claims_test.exs
  describe "production tier-A artifacts" do
    test "production support matrix passes structural JSV validation" do
      matrix = Matrix.load!()
      assert :ok = Validator.validate_matrix_structure(matrix)
    end

    test "production evidence tree has no orphan markdown files" do
      orphans = Validator.list_orphan_evidence()

      assert orphans == []
    end
    ...
    test "run_full succeeds on production matrix and does not treat staleness as blocking" do
      matrix = Matrix.load!()

      assert {:ok, warnings} = Validator.run_full()
      assert is_list(warnings)
      ...
    end
  end
```

**Post-Phase 69 expectations:**
- `apple_preview.md` referenced by matrix → no orphan
- `run_full()` validates referenced evidence file
- 4 legacy supported rows still emit advisory warnings (tier-A allows legacy)

**Optional pointer assert (D-18):**

```elixir
test "viewer evidence guide references canonical template and worked example paths" do
  guide = File.read!("guides/viewer_evidence.md")

  assert guide =~ "priv/viewer_evidence/_template.md"
  assert guide =~ "priv/viewer_evidence/forms/apple_preview.md"
end
```

**Self-guard pattern analog (from forms):**

```76:86:test/docs_contract/forms_claims_test.exs
  test "signature docs-contract lane keeps explicit negative claim guards" do
    source = File.read!(__ENV__.file)

    [wording_test] =
      Regex.run(~r/test "public forms wording stays narrow.*?\n  end/s, source)

    assert wording_test =~ ~s|refute guide =~ "digital signatures are supported"|
    ...
  end
```

---

## 3. Integration points

```
Operator workflow (Phase 69)
  └── guides/viewer_evidence.md (Policies, HexDocs)
        ├── mix rendro.viewer_evidence {missing|validate|list}
        ├── cp priv/viewer_evidence/_template.md → priv/viewer_evidence/forms/apple_preview.md
        ├── FormSupportFixture.write_fixture/1 → test/fixtures/forms_support_fixture.pdf
        ├── Manual Apple Preview checklist (4 proof[] behaviors)
        ├── priv/support_matrix.json (additive promotion keys)
        ├── guides/api_stability.md (discipline + mirror sentence)
        └── CHANGELOG.md (Viewer Evidence subsection)

mix ci
  └── mix test
        └── test/docs_contract/viewer_evidence_claims_test.exs  (lane 8, unchanged wiring)
        └── test/docs_contract/forms_claims_test.exs  (must preserve refute guards)

mix docs.contract
  └── scripts/verify_docs.exs
        └── lane 8: viewer_evidence_claims_test.exs

mix docs
  └── guides/viewer_evidence.md in Policies group
```

| Integration | Phase 69 touch | Must remain stable |
|-------------|----------------|-------------------|
| `scripts/verify_docs.exs` | **No edits** | Eighth lane already registered |
| `mix.exs` `:ci` alias | **No viewer task** | D-24 from Phase 68 |
| Family `*_claims_test.exs` | **No edits** (except optional pointer) | Lane registration assertions |
| `priv/schemas/*.schema.json` | **No edits** | Tier A/B split unchanged |
| Other 4 legacy supported rows | **No edits** | Phase 70 |
| `Validator.validate_promotion_complete/2` | **Not on production yet** | Tier-B fixture subtests only |

**Production matrix sanity (post-Phase 69):**

| Metric | Before | After |
|--------|--------|-------|
| Total viewer cells | 26 | 26 |
| `supported` with promotion-complete evidence | 0 | 1 (`forms/apple_preview`) |
| `supported` legacy (no `evidence:`) | 5 | 4 |
| `unverified` | 21 | 21 |
| `explicit_deferral` | 0 | 0 |
| `missing` exit code | 1 | 1 |

**Implementer verification sequence:**

```bash
# 1. Generate fixture
mix run -e 'Rendro.Test.FormSupportFixture.write_fixture("test/fixtures/forms_support_fixture.pdf")'

# 2. Manual Preview checklist (human)

# 3. Structural validation
mix rendro.viewer_evidence validate
mix rendro.viewer_evidence list

# 4. Docs contract
mix test test/docs_contract/viewer_evidence_claims_test.exs
mix test test/docs_contract/forms_claims_test.exs
mix docs.contract

# 5. ExDoc build
mix docs
```

---

## 4. Anti-patterns to avoid

| Anti-pattern | Why it fails | Correct pattern |
|--------------|--------------|-----------------|
| Duplicate full evidence content in guide | Drift risk; no docs-contract sync lane (D-14–D-16) | Skeleton frontmatter in guide; canonical observations in evidence file only |
| Inline relative `priv/` links on HexDocs | 404 for HexDocs readers (D-15) | GitHub `source_url` link to canonical file |
| Backdate `recorded_at` to Phase 47 date | Stale dates pitfall #2 (D-08) | Re-validation date in frontmatter + matrix; Phase 47 date body-only |
| Copy `viewer_version` from protection row | Schema coupling pitfall #4 (D-12) | Read from Preview → About at observation time |
| Use `fixture_sha256` alone for first cell | Loses reproducibility path (D-09) | Commit `test/fixtures/forms_support_fixture.pdf`; frontmatter `fixture:` key |
| Template stub behavior notes | Overclaim pitfall #1 (D-10) | Substantive widget-specific sentences per behavior |
| Add production deferral matrix rows | Scope creep — Phase 71 (D-17) | Synthetic deferral example in guide only |
| Consolidate other four legacy rows | Phase 70 boundary (D-23) | Only `forms.viewers.apple_preview` in Phase 69 |
| Change `status` from `supported` | Regression in published support | Re-attestation consolidation — status unchanged |
| Put `viewer_version` on matrix row | Phase 68 D-11 / PITFALLS #4 | Evidence frontmatter only |
| Require all four behaviors in JSON Schema | Not enforced yet; validator gap | Include all four in evidence; optional docs-contract assert |
| Add `mix rendro.viewer_evidence` to `:ci` | D-24 from Phase 68 | CI runs test file via `mix test` |
| Expand Hex `files:` for priv shipping | Release packaging decision deferred | Prerequisites state repo checkout required |
| Create `mix rendro.viewer_evidence init` | Phase 72 polish | Manual `cp _template.md` sufficient |
| Modify `priv/schemas/*.schema.json` | Phase boundary — no schema lane changes | Use existing Phase 68 schemas |
| Break `forms_claims_test.exs` refute guards | Merge-blocking regression | Preserve Adobe Acrobat `unverified` and negative claim refutes |
| Claim mix task validates viewer behavior | CI dilution pitfall #7 | Guide Appendix E: docs-contract = structural; manual checklist = behavioral |
| Screenshots, home paths, secrets in evidence | GUARDRAIL-04 / PITFALLS #8 | Text-only; lint rejects images/PEM/home paths |

---

## PATTERN MAPPING COMPLETE
