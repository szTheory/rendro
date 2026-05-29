# Viewer Evidence Recording

## Purpose

Rendro's support matrix (`priv/support_matrix.json`) is the public index of viewer compatibility per surface. Each promoted cell points at a structured evidence file under `priv/viewer_evidence/<surface>/<viewer>.md` — observation facts, behavior notes, and reproducibility metadata in frontmatter; promotion state (`evidence`, `recorded_at`, `viewer_kind`) lives on the matrix only.

Treat this like MDN BCD or Can I Use: the matrix answers "what does Rendro claim?"; the evidence file answers "what did we observe, on which fixture, with which viewer version?"

## Prerequisites

Recording requires a **full repo checkout**. The Hex package ships `guides/` but omits `priv/support_matrix.json`, `priv/schemas/`, and `priv/viewer_evidence/`. HexDocs is read-only documentation for this recipe — you cannot record promotions from the published package alone.

You need:

- Elixir/Mix from the repo root
- The target viewer installed on your workstation (macOS Preview, Adobe Acrobat Reader, etc.)
- Permission to edit `priv/support_matrix.json`, evidence files, and (when promoting) `guides/api_stability.md` and `CHANGELOG.md`

## Status vocabulary

| Matrix `status` | Meaning | Evidence file |
|-----------------|---------|---------------|
| `unverified` | Recording obligation not satisfied | Forbidden |
| `supported` | Proof-backed support; promotion keys required on the matrix row | Required at `evidence:` path |
| `explicit_deferral` | Honest "no" with named reason | Forbidden — matrix-only `evidence_deferred` |

Promotion keys on `supported` rows: `evidence`, `recorded_at`, `viewer_kind` (`manual`, `pdfium-cli`, or `pdfjs-dist`). Do not put `status`, `viewer_kind`, or promotion keys in evidence frontmatter.

### Automated path (Linux CI — pdfium-cli, pdfinfo, qpdf)

When `pdfium-cli`, `pdfinfo`, and `qpdf` are on PATH, record Phase 70 consolidated legacy rows without GUI viewers:

```bash
mix rendro.viewer_evidence record forms chrome_pdfium \
  --fixture test/fixtures/forms_support_fixture.pdf \
  --recorded-by ci:viewer-evidence-live-proof

mix rendro.viewer_evidence record forms apple_preview \
  --fixture test/fixtures/forms_support_fixture.pdf \
  --recorded-by ci:viewer-evidence-live-proof

mix rendro.viewer_evidence record embedded_files adobe_acrobat_reader \
  --fixture test/fixtures/embedded_artifact_support_fixture.pdf \
  --recorded-by ci:viewer-evidence-live-proof

mix rendro.viewer_evidence record links adobe_acrobat_reader \
  --fixture test/fixtures/embedded_artifact_support_fixture.pdf \
  --recorded-by ci:viewer-evidence-live-proof

mix rendro.viewer_evidence record links apple_preview \
  --fixture test/fixtures/embedded_artifact_support_fixture.pdf \
  --recorded-by ci:viewer-evidence-live-proof

mix rendro.viewer_evidence record protection apple_preview \
  --fixture test/fixtures/protection_support_fixture.pdf \
  --recorded-by ci:viewer-evidence-live-proof
```

Set matrix `viewer_kind` to `"pdfium-cli"`. CI validates committed fixtures via:

```bash
mix test --include live_pdf_tools \
  test/rendro/adapters/forms_viewer_evidence_live_test.exs \
  test/rendro/adapters/embedded_files_viewer_evidence_live_test.exs \
  test/rendro/adapters/links_viewer_evidence_live_test.exs \
  test/rendro/adapters/protection_viewer_evidence_live_test.exs
```

Structural automation proxies do not validate Apple Preview or Adobe Acrobat GUI behavior.

### Manual path (Preview / Acrobat)

Run these steps in order. Each step ends with an observable check.

### 1. Find backlog cells

```bash
mix rendro.viewer_evidence missing
```

**Check:** Exit code **1** when unverified cells exist (expected today). Stdout lists `surface`, `viewer`, and `status` for each backlog cell. Pick your target cell from the table.

### 2. Confirm behavior IDs

Open `priv/support_matrix.json` and read the `proof[]` array for your target viewer row (for example `forms.viewers.apple_preview`).

**Check:** You have a fixed list of behavior IDs (`open`, `default_state_visible`, etc.) before opening the viewer.

### 3. Prepare the fixture

For **forms**, from repo root:

```bash
mix run -e 'Rendro.Test.FormSupportFixture.write_fixture("test/fixtures/forms_support_fixture.pdf")'
```

Other surfaces: see Appendix A.

**Check:** The fixture path exists on disk and is committed (or staged) before manual observation.

### 4. Manual checklist in the viewer

Open the fixture in the target viewer. For each `proof[]` behavior ID, record pass/fail and a substantive note (widget names, visible state, what you toggled, save path behavior). Read `viewer_version` from the viewer's About dialog and `platform` from the OS at observation time — never copy from another matrix row.

**Check:** You can answer pass/fail for every `proof[]` ID without guessing.

### 5. Create the evidence file

Copy the template and fill frontmatter (field semantics in the skeleton below — use your observation values, not these placeholders):

```bash
cp priv/viewer_evidence/_template.md priv/viewer_evidence/<surface>/<viewer>.md
```

Example path for forms × Apple Preview: `priv/viewer_evidence/forms/apple_preview.md`.

**Skeleton frontmatter** (field names: `schema_version`, `surface`, `viewer`, `viewer_version`, `platform`, `recorded_at`, `fixture`, `behaviors[]` with `behavior` / `result` / `note` per `proof[]` ID — use observation values in the file, not in this guide).

Add a short body: provenance, fixture regen command, and boundary notes (Appendix F).

**Check:** File path matches `priv/viewer_evidence/<surface>/<viewer>.md` and frontmatter `surface`/`viewer` match the matrix mapping.

### 6. Validate structure

```bash
mix rendro.viewer_evidence validate
```

**Check:** Exit code **0**. Fix any Tier-A errors (schema, lint, orphan scan) before promoting. Legacy-supported rows without `evidence:` may still print advisory warnings — your new file must validate cleanly.

### 7. Promote the matrix row

Add to the `supported` viewer object in `priv/support_matrix.json`:

- `"evidence": "priv/viewer_evidence/<surface>/<viewer>.md"`
- `"recorded_at": "YYYY-MM-DD"` — **must equal** `recorded_at` in evidence frontmatter
- `"viewer_kind": "manual"` (or `"pdfium-cli"` / `"pdfjs-dist"` for automated observers)

Do not change `status` or `proof[]` for re-attestation. Update `guides/api_stability.md` and `CHANGELOG.md` when closing the public contract (see plan 69-03).

**Check:** `recorded_at` matches evidence frontmatter.

### 8. Verify listing and docs-contract

```bash
mix rendro.viewer_evidence list
mix test test/docs_contract/viewer_evidence_claims_test.exs
```

**Check:** Your cell appears in the table without a "legacy: missing evidence" note. Docs-contract lane passes.

---

## Worked example — forms × chrome_pdfium

The canonical observations for the first CI-automated promoted cell live only in the repository evidence file:

[priv/viewer_evidence/forms/chrome_pdfium.md](https://github.com/szTheory/rendro/blob/main/priv/viewer_evidence/forms/chrome_pdfium.md)

The guide shows structure and commands; **the canonical file wins** for version strings, platform, behavior notes, and dates.

Apple Preview consolidated evidence (`priv/viewer_evidence/forms/apple_preview.md`) uses the same pdfium-cli structural proxy lane as Phase 70 automation — GUI Preview is not re-run in CI.

Copy source for new cells: `priv/viewer_evidence/_template.md`.

## Appendix A — Per-surface manual checklists

### Forms (`forms`)

Representative fixture: `test/fixtures/forms_support_fixture.pdf` (widgets: `email` prefilled `jon@example.test`, `terms` checkbox, `contact_email` / `contact_phone` radio group).

| Behavior ID | Pass criteria (Apple Preview + forms fixture) |
|-------------|-----------------------------------------------|
| `open` | PDF opens without error dialog |
| `default_state_visible` | Email shows prefilled value; terms checked; contact email radio selected |
| `edit_or_toggle` | Change email text; toggle terms; switch radio to phone |
| `save` | Save As to a new path; reopen; edited state persists |

Other surfaces use the same automated record commands when `pdfium-cli`, `pdfinfo`, and `qpdf` are available:

| Surface | Fixture | Regeneration |
|---------|---------|--------------|
| `embedded_files` / `links` | `test/fixtures/embedded_artifact_support_fixture.pdf` | `MIX_ENV=test mix run -e 'Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture("test/fixtures/embedded_artifact_support_fixture.pdf")'` |
| `protection` | `test/fixtures/protection_support_fixture.pdf` | `mix run scripts/protected_viewer_proof_fixture.exs --output test/fixtures/protection_support_fixture.pdf` |

Protection regen produces **new bytes** — re-run the structural proof lane after regeneration.

## Appendix B — Explicit deferral discipline

Use `explicit_deferral` when a viewer cannot satisfy a behavior and you can name **why** in ≥40 characters. Do not create an evidence file. Do not use vague deferral vocabulary: `TBD`, `not yet`, `deferred for later`, or empty strings — CI lint rejects them.

### Template: UPSTREAM_ISSUE

Use when promotion is blocked by missing upstream viewer capability (not a Rendro authoring gap).

```json
"pdfjs": {
  "status": "explicit_deferral",
  "evidence_deferred": "PDF.js does not implement AcroForm signature widget editing or unsigned placeholder rendering per mozilla/pdf.js#4202; promotion requires upstream signature-field support."
}
```

Example surfaces: `forms.viewers.pdfjs`, `forms.signature_widget_viewers.pdfjs`, `signing_preparation.viewers.pdfjs`.

### Template: NO_SIG_VALIDATION

Use when the viewer cannot validate `/Sig` digital signatures or signed-artifact integrity UI.

```json
"apple_preview": {
  "status": "explicit_deferral",
  "evidence_deferred": "Apple Preview does not validate /Sig digital signatures and append-save invalidates signature dictionaries; signed-artifact viewer promotion requires Acrobat or pdfium-cli structural lanes."
}
```

Example surfaces: `signing.viewers.apple_preview`, `signing.viewers.pdfjs`.

### Template: NO_LTV_INDICATORS

Use when long-term-validation timestamp, revocation, or expiry indicators are absent.

```json
"chrome_pdfium": {
  "status": "explicit_deferral",
  "evidence_deferred": "pdfium-cli structural open and form extraction do not expose long-term-validation timestamp, revocation, or expiry indicators; LTV posture remains Acrobat-only for viewer promotion."
}
```

Example surfaces: `signing.long_lived.viewers.{apple_preview,chrome_pdfium,pdfjs}`.

### Template: SURFACE_EQUIVALENCE (supported inheritance, not deferral)

Use when two surfaces share identical viewer behavior — record once on the primary surface and inherit pointers on the secondary surface.

```json
"apple_preview": {
  "status": "supported",
  "proof": ["prepared_artifact_opens_cleanly", "widget_renders_as_unsigned_placeholder", "viewer_does_not_silently_re_sign_or_corrupt", "byte_range_layout_intact_after_save_as"],
  "evidence": "priv/viewer_evidence/signature_widget/apple_preview.md",
  "recorded_at": "2026-05-29",
  "viewer_kind": "pdfium-cli"
}
```

Applies to `signing_preparation` non-Acrobat rows inheriting `signature_widget` evidence (D-15). Adobe Acrobat Reader requires independent `signing_preparation` evidence because byte-range layout is viewer-discriminable.

### Hypothetical teaching example (non-production)

*Do not add orphan rows — teaching contrast only.*

`signed_artifact` × `apple_preview` deferral JSON:

```json
"apple_preview": {
  "status": "explicit_deferral",
  "evidence_deferred": "Apple Preview renders signature appearance but does not implement /Sig cryptographic validation as of Preview 11.0 on macOS 15 — integrity UI absent."
}
```

### Contrast table

| Status | Matrix keys | Evidence file |
|--------|-------------|---------------|
| `supported` | `evidence`, `recorded_at`, `viewer_kind`, `proof[]` | Required |
| `explicit_deferral` | `evidence_deferred` only | Forbidden |
| `unverified` | `proof[]` optional | Forbidden |

## Appendix C — Frontmatter schema guardrails

- **Byte budget:** 65_536 bytes per evidence file (`byte_size/1` on disk).
- **Forbidden frontmatter keys:** `status`, `viewer_kind`, and other promotion fields — matrix only.
- **Fixture:** Provide `fixture` (repo-relative path) **or** `fixture_sha256`; prefer committed path for reproducibility (`test/fixtures/...`).
- **Behaviors:** Each `behaviors[].behavior` must be a valid ID for the surface; include every `proof[]` entry from the matrix row even though the validator currently allows subsets.
- **Lint:** No embedded images, PEM blocks, home-directory paths (`/Users/...`), or secrets in body or notes.

Schema: `priv/schemas/viewer_evidence.schema.json`. Template: `priv/viewer_evidence/_template.md`.

## Appendix D — Mix task reference

Module: `Mix.Tasks.Rendro.ViewerEvidence`

| Subcommand | Exit code | Purpose |
|------------|-----------|---------|
| `list` | 0 | Summary counts + table (`surface`, `viewer`, `status`, `notes`) |
| `missing` | 1 if any `unverified`; 0 if none | Backlog filter |
| `validate` | 1 on Tier-A errors; 0 with legacy/staleness warnings only | Schema + evidence files + orphan scan |

Add `--json` for machine-readable stdout.

Full API and CI notes: see `Mix.Tasks.Rendro.ViewerEvidence` moduledoc (`mix help rendro.viewer_evidence`).

## Appendix E — CI and docs-contract troubleshooting

| Symptom | Likely cause | Action |
|---------|--------------|--------|
| `mix docs.contract` fails lane 8 | Orphan evidence, schema error, bad frontmatter | Run `mix rendro.viewer_evidence validate`; fix paths and lint |
| Promotion-complete test fails in fixtures only | Tier-B fixture matrix missing `evidence` | Production tier-A still passes until promotion; add keys when recording |
| `forms_claims_test` fails after `api_stability` edit | Broke Adobe `unverified` wording or refute guards | Preserve narrow claims; see Phase 69 plan 03 |

Docs-contract proves **structural** alignment (matrix JSON, evidence schema, path references, lint). The `viewer-evidence-live-proof` GitHub Actions lane runs pdfium-cli, pdfsig, pyhanko, and poppler structural-proxy proofs that regenerate committed evidence files — no GUI viewer sessions required for Phase 71 trust-sensitive closures.

## Appendix F — Overclaim boundaries

- **Poppler / `pdfinfo` structural proof ≠ viewer proof.** Passing structural tests does not promote a viewer row.
- **One cell ≠ other surfaces or viewers.** Promoting `forms × apple_preview` does not promote Acrobat, PDFium, PDF.js, protection, links, or signature surfaces.
- **Re-attestation ≠ net-new support.** Legacy `supported` re-homes keep `status: supported`; refresh `recorded_at` to the spot-check date; cite older attestation dates in body prose only.
- **Signing recipe ≠ viewer interop.** `Rendro.Sign` integrity validation is a separate lane from interactive form evidence.

Do not promote if manual checks failed, notes are template stubs, or `recorded_at` does not match the matrix row.
