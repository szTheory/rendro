# Phase 47 Validation

This document defines the closure checks for Phase 47: Form Validation and Viewer-Proof Closure.

## Goal

Make Rendro's supported AcroForm contract explicit, validated, and truthfully documented without widening beyond text fields, checkboxes, radio groups, and named viewer claims backed by proof.

## Proof Lanes

### 1. Semantic validation lane

Purpose:
- Prove unsupported or ambiguous authored form state fails in core before render.

Scenarios:
- Duplicate or colliding logical field identity is rejected.
- Hierarchical or dotted field names are rejected.
- Text field values, editing-font inputs, and sizes are validated as explicit supported shapes.
- Checkbox/radio export values are non-empty binaries.
- Radio groups reject duplicate export values and multiple checked defaults.

Nyquist automation:
- `mix test test/rendro/rules/check_form_fields_test.exs test/rendro/pipeline/validate_test.exs`

Expected result:
- ExUnit passes with typed tuples for unsupported names, duplicate identity, duplicate radio exports, and contradictory checked defaults.

### 2. Structural validation lane

Purpose:
- Prove a representative supported-forms PDF is structurally acceptable to Poppler.

Scenarios:
- Generated forms PDF validates through `Rendro.Adapters.Poppler.validate/1` when `pdfinfo` is available.
- Missing `pdfinfo` remains an explicit graceful-degradation case, not a crash.

Nyquist automation:
- `mix test test/rendro/adapters/poppler_test.exs`
- `MIX_ENV=test mix run -e 'path = Path.expand("tmp/forms_support_fixture.pdf"); path = Rendro.Test.FormSupportFixture.write_fixture(path); IO.puts(path)'`

Important boundary:
- This lane proves PDF structure only. It does not prove Acrobat/Preview edit or save behavior.

Expected result:
- The test passes when `pdfinfo` is available, or explicitly skips the representative fixture assertion when it is not.
- The `mix run` command prints the generated fixture path so the same PDF can be opened in Acrobat Reader and Apple Preview for manual proof.

### 3. Docs and support-boundary lane

Purpose:
- Prove the machine-readable support matrix and human docs say the same truthful thing.

Scenarios:
- `priv/support_matrix.json` publishes explicit forms widget/behavior/viewer boundaries.
- Public docs name supported viewers narrowly and avoid “standard PDF viewers” wording.
- Unverified viewers remain unverified.

Nyquist automation:
- `mix run scripts/verify_docs.exs`

Expected result:
- The docs gate passes only when `guides/api_stability.md`, `priv/support_matrix.json`, and `test/docs_contract/forms_claims_test.exs` agree on the same supported and unverified forms posture.

### 4. Viewer-proof lane

Purpose:
- Back supported-viewer claims with manual verification for the named support contract only.

Required viewers:
- Adobe Acrobat Reader
- Apple Preview

Required checks per viewer:
- Opens successfully
- Default text, checkbox, and radio state is visible on first open
- Text field editing works
- Checkbox toggle works
- Radio selection works
- Saving preserves the edited result

Status recording:
- Record results in the table below during execution.
- If a viewer is not checked, leave it `unverified`.
- This document is the source of truth for the post-checkpoint sync back into `priv/support_matrix.json` and `guides/api_stability.md`.

## Manual Proof Record

| Viewer | Open | Default state visible | Edit/toggle | Save | Result | Notes |
|--------|------|------------------------|-------------|------|--------|-------|
| Adobe Acrobat Reader | pending | pending | pending | pending | unverified | Not yet manually checked in this phase. |
| Apple Preview | pass | pass | pass | pass | supported | Manually verified against `tmp/forms_support_fixture.pdf`. |

## Success Conditions

1. Semantic validation rejects unsupported authored states with typed errors.
2. Structural validation proves a representative supported-forms PDF is acceptable to Poppler when available.
3. `priv/support_matrix.json` and human docs expose the same narrow support contract.
4. Acrobat Reader and Apple Preview are only marked supported after the manual proof record is completed.
