# Phase 71 Pattern Map

**Mapped:** 2026-05-28  
**Phase:** 71-record-new-trust-sensitive-surfaces-and-explicit-deferrals  
**Sources:** 71-CONTEXT.md, 71-RESEARCH.md

---

## 1. File Role Classification

| File | Role | Data flow |
|------|------|-----------|
| `test/support/signing_viewer_support_fixture.ex` | Fixture generator | Elixir API → committed PDF bytes |
| `scripts/signing_viewer_proof_fixtures.exs` | Operator regen entrypoint | CLI → fixture module |
| `scripts/signed_artifact_viewer_proof_fixture.exs` | Signed PDF generator | live_signer PEM → committed PDF |
| `scripts/long_lived_viewer_proof_fixture.exs` | LTV PDF generator | certomancer chain → committed PDF |
| `priv/viewer_evidence/<surface>/<viewer>.md` | Observation record | Operator → matrix `evidence:` pointer |
| `priv/support_matrix.json` | Public contract index | Evidence/deferrals → docs-contract |
| `lib/rendro/adapters/*_pdfium_proof.ex` | CI structural proxy | pdfium-cli → live test lane |
| `guides/api_stability.md` | Human-readable mirror | Matrix rows → prose |
| `test/docs_contract/viewer_evidence_claims_test.exs` | Merge gate | Matrix + evidence → CI |

---

## 2. Closest Analog Files

### 2.1 Fixture module — mirror `FormSupportFixture`

**Analog:** `test/support/form_support_fixture.ex`

```elixir
# Pattern: write_fixture/1 generates deterministic PDF to path
defmodule Rendro.Test.FormSupportFixture do
  def write_fixture(path) do
    path |> Path.dirname() |> File.mkdir_p!()
    render_pdf() |> then(&File.write!(path, &1))
  end
end
```

**Phase 71 extension:** `Rendro.Test.SigningViewerSupportFixture` with `write_signature_widget_fixture/1` and `write_signing_preparation_fixture/1`.

### 2.2 Fixture script — mirror `protected_viewer_proof_fixture.exs`

**Analog:** `scripts/protected_viewer_proof_fixture.exs`

```elixir
# Pattern: --output PATH, qpdf/pdfinfo preflight, blocking_prerequisites/1
def main(argv) do
  {opts, args, invalid} = OptionParser.parse(argv, strict: [output: :string, dry_run: :boolean, help: :boolean])
  # ... readiness check → write_fixture!(opts[:output])
end
```

**Phase 71 extension:** `signed_artifact_viewer_proof_fixture.exs` and `long_lived_viewer_proof_fixture.exs` with certomancer/pyhanko preflight.

### 2.3 pdfium-cli live proof — mirror `FormsPdfiumProof`

**Analog:** `test/rendro/adapters/forms_viewer_evidence_live_test.exs` + `lib/rendro/adapters/forms_pdfium_proof.ex` (if exists)

```elixir
@tag live_pdf_tools: true
test "pdfium-cli proves forms viewer evidence behaviors on the committed fixture" do
  assert {:ok, _result} = FormsPdfiumProof.run(@fixture)
end
```

**Phase 71 extension:** `SignatureWidgetPdfiumProof.run/1`, `SignedArtifactPdfiumProof.run/1`.

### 2.4 Evidence file — mirror `forms/chrome_pdfium.md`

**Analog:** `priv/viewer_evidence/forms/chrome_pdfium.md`

Key patterns:
- Frontmatter: `schema_version`, `surface`, `viewer`, `viewer_version`, `platform`, `recorded_at`, `fixture`, `behaviors[]`
- Body: regen command, cross-boundary negation ("pdfium-cli does not prove GUI Acrobat")
- Matrix carries `viewer_kind: "pdfium-cli"` — not in evidence frontmatter

### 2.5 Atomic closure wave — mirror Phase 70-03

**Analog:** `.planning/phases/70-consolidate-already-validated-surfaces/70-03-PLAN.md`

Pattern: evidence files from Wave 2 + matrix pointers + api_stability + CHANGELOG + docs-contract in **one merge unit**.

### 2.6 Explicit deferral — mirror Phase 68 synthetic example

**Analog:** Phase 69 guide synthetic deferral (not production row); Phase 68 deferral lint in `viewer_evidence_claims_test.exs`

```json
"pdfjs": {
  "status": "explicit_deferral",
  "evidence_deferred": "Named reason ≥40 chars, no forbidden vocabulary"
}
```

---

## 3. Integration Points

```
SigningViewerSupportFixture
  → test/fixtures/signature_widget_support_fixture.pdf
  → test/fixtures/signing_preparation_support_fixture.pdf
  → priv/viewer_evidence/signature_widget/*.md
  → priv/viewer_evidence/signing_preparation/adobe_acrobat_reader.md

signed_artifact_viewer_proof_fixture.exs
  → test/fixtures/signed_artifact_viewer_proof.pdf
  → priv/viewer_evidence/signed_artifact/*.md

long_lived_viewer_proof_fixture.exs
  → test/fixtures/long_lived_viewer_proof.pdf
  → priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md

Matrix.ex surface mapping
  → mix rendro.viewer_evidence record <surface> <viewer>
  → Validator.validate_evidence_file/3

71-03 closure
  → priv/support_matrix.json (20 terminal cells)
  → guides/api_stability.md
  → CHANGELOG.md
  → viewer_evidence_claims_test.exs
```

---

## 4. Anti-Patterns to Avoid

| Don't | Do instead |
|-------|------------|
| Merge Wave 2 evidence without Wave 3 matrix | Stack 71-02+71-03 in one PR |
| Backdate `recorded_at` to v1.x phases | Provenance in body prose only |
| Use pdfium-cli for Preview sig_widget promotion | Manual GUI (D-19) |
| Defer signed_artifact × chrome_pdfium | Promote per ROADMAP SC#2 (D-14) |
| Double-record signing_prep for Preview/PDFium | Inherit signature_widget status (D-15) |
| Put passwords in evidence notes | Reference script stdout only (GUARDRAIL-04) |

---

## PATTERN MAPPING COMPLETE
