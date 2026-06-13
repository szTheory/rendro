# Phase 88: Launch Execution & Demand Instrumentation - Pattern Map

**Mapped:** 2026-06-12
**Role:** gsd-pattern-mapper
**Inputs:** `88-CONTEXT.md`, `88-RESEARCH.md`, `88-UI-SPEC.md`, `88-VALIDATION.md`, current repo patterns
**Files analyzed:** 26 likely new/modified/no-change-guard files
**Analogs found:** 26 / 26 (24 exact or role matches, 2 partial YAML matches)

## Executive Summary

Phase 88 should copy Rendro's existing public-claim discipline:

- Public Markdown states only proof-backed or explicitly deferred claims.
- `priv/support_matrix.json` owns status; evidence files own observations.
- `guides/api_stability.md` mirrors support paths and deferral reasons.
- ExUnit docs-contract tests read files directly, assert exact paths/copy, and refute overclaims.
- Manual or external work stays outside required live CI unless it is already deterministic/static.

There is no existing GitHub issue/discussion template directory in this repo. For those YAML files, use GitHub's form schema from research and the repo's workflow YAML style only as a partial indentation/format analog.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `ADOPTION.md` | public docs / ledger | file-I/O + batch review | `guides/api_stability.md`, `guides/comparison.md` | role-match |
| `README.md` | public entry point | transform / link routing | existing `README.md` Guides section | exact |
| `guides/comparison.md` | public guide | transform / claim mirror | existing limitation block in `guides/comparison.md` | exact |
| `guides/api_stability.md` | support-boundary guide | transform / claim mirror | existing forms/signing/evidence sections | exact |
| `CHANGELOG.md` | release contract log | append-only file-I/O | existing Viewer Evidence entries | exact |
| `priv/support_matrix.json` | support contract data | transform | existing `forms.viewers.*` and `signing.viewers.*` rows | exact |
| `priv/viewer_evidence/forms/ios_files_preview.md` | evidence record | file-I/O / manual observation | `priv/viewer_evidence/forms/apple_preview.md` | exact |
| `priv/viewer_evidence/forms/android_drive_viewer.md` | evidence record | file-I/O / manual observation | `priv/viewer_evidence/forms/apple_preview.md` | exact |
| `priv/viewer_evidence/signed_artifact/ios_files_preview.md` | conditional evidence record | file-I/O / manual observation | `priv/viewer_evidence/signed_artifact/chrome_pdfium.md` | role-match; only if unexpectedly supported |
| `priv/viewer_evidence/signed_artifact/android_drive_viewer.md` | conditional evidence record | file-I/O / manual observation | `priv/viewer_evidence/signed_artifact/chrome_pdfium.md` | role-match; only if unexpectedly supported |
| `test/docs_contract/adoption_claims_test.exs` | docs-contract test | transform / static verification | `test/docs_contract/comparison_claims_test.exs`, `script_support_claims_test.exs` | role-match |
| `test/docs_contract/github_intake_claims_test.exs` | docs-contract test | transform / static YAML verification | `test/docs_contract/comparison_claims_test.exs`, `api_stability_claims_test.exs` | role-match |
| `test/docs_contract/launch_execution_claims_test.exs` | docs-contract test | transform / static + manual-gate verification | `test/docs_contract/launch_artifacts_claims_test.exs` | role-match |
| `test/docs_contract/viewer_evidence_claims_test.exs` | docs-contract test | transform / schema and mirror verification | existing same file | exact |
| `test/docs_contract/forms_claims_test.exs` | docs-contract test | transform / support claim verification | existing same file | exact |
| `test/docs_contract/signing_claims_test.exs` | docs-contract test | transform / trust-boundary verification | existing same file | exact |
| `test/docs_contract/raster_claims_test.exs` | docs-contract test | transform / boundary guard | existing same file | exact; likely guard-only |
| `scripts/verify_docs.exs` | docs-contract lane registry | batch | existing lane list | exact |
| `.github/ISSUE_TEMPLATE/01_bug.yml` | GitHub intake config | request-response | no local issue template; `.github/workflows/ci.yml` YAML style | partial |
| `.github/ISSUE_TEMPLATE/02_blocked_document.yml` | GitHub intake config | request-response | no local issue template; research issue-form schema | partial |
| `.github/ISSUE_TEMPLATE/config.yml` | GitHub intake config | request-response routing | no local issue template; research issue config schema | partial |
| `.github/DISCUSSION_TEMPLATE/use-cases.yml` | GitHub discussion config | request-response | no local discussion template; research discussion-form schema | partial; conditional |
| `.planning/phases/88-launch-execution-demand-instrumentation/88-LAUNCH-CHECKLIST.md` | planning artifact | batch / manual gates | `88-VALIDATION.md`, `88-UI-SPEC.md` | role-match; if planner chooses |
| `.planning/phases/88-launch-execution-demand-instrumentation/88-LAUNCH-COPY.md` | planning artifact | batch / external publication copy | `88-UI-SPEC.md` channel/copy contract | role-match; if planner chooses |
| `priv/guardrails/required_status_checks.json` | CI guardrail registry | batch / CI metadata | existing advisory contexts | exact; likely no mobile-required change |
| `.github/workflows/ci.yml` | CI workflow | event-driven / batch | existing advisory jobs | exact; likely no mobile-required change |

## Pattern Assignments

### `ADOPTION.md` (public docs / ledger, file-I/O + batch review)

**Analog:** `guides/comparison.md` for decision-guide tables and limitations; `guides/api_stability.md` for support-boundary precision.

**Markdown table / bounded-copy pattern** (`guides/comparison.md:55-63`):

```markdown
## Text, Fonts, and Complex Scripts

> Limitation: Rendro does not render arbitrary HTML/CSS.
>
> Complex-script and RTL support are bounded by priv/support_matrix.json.
>
> Unsupported shaping cases fail explicitly instead of producing silent broken output.
```

**Guide link pattern** (`README.md:39-46`): add one concise link in the existing Guides section. Do not create a hero or marketing block.

**Gate-data pattern:** copy exact section order and ledger columns from Phase 88 context. Use plain Markdown tables. The first dense table should be `Gate Thresholds`, matching UI-SPEC guidance that the threshold section is the primary decision surface.

**Test pattern:** new `adoption_claims_test.exs` should assert exact section order, exact threshold text, ledger columns, empty states, README/comparison links, review cadence, and forbidden counting rules.

### `README.md` (public entry point, transform / link routing)

**Analog:** existing Guides list.

**Core pattern** (`README.md:39-46`):

```markdown
## Guides

- [Generating PDFs in Elixir without Chrome](guides/comparison.md) - an evidence-backed comparison guide for Rendro, ChromicPDF, pdf_generator, and Typst CLI.
- [First Invoice Livebook](guides/livebook/first_invoice.livemd) - a zero-friction tutorial for rendering and downloading a deterministic invoice PDF.
- [API Stability and Support Boundaries](guides/api_stability.md) - the canonical support language for trust-sensitive and proof-backed surfaces.
```

Add `ADOPTION.md` as another concise guide/resource link. Keep first-screen copy unchanged except for Phase 88's allowed claim if the planner explicitly decides to adjust wording.

**Test analog:** `test/docs_contract/comparison_claims_test.exs:160-167` extracts the Guides section and asserts links. Reuse that helper style in `adoption_claims_test.exs`.

### `guides/comparison.md` (public guide, transform / claim mirror)

**Analog:** existing limitation block and "Try Rendro In Livebook" section.

**Core pattern** (`guides/comparison.md:55-63`): limitations are blockquoted, specific, and tied to `priv/support_matrix.json`.

**Livebook/action pattern** (`guides/comparison.md:122-124`):

```markdown
Try the invoice workflow in Livebook with [`guides/livebook/first_invoice.livemd`](livebook/first_invoice.livemd).
```

Add `ADOPTION.md` to the limitation or routing area as the place for concrete unsupported document jobs and text-shaping demand signals. Do not weaken the existing comparison posture.

### `guides/api_stability.md` (support-boundary guide, transform / claim mirror)

**Analog:** forms and signing boundaries plus explicit deferral mirror.

**Supported form evidence mirror** (`guides/api_stability.md:85-91`):

```markdown
For text fields, checkboxes, and radio groups, Apple Preview is `supported` for `forms` based on the recorded viewer checklist ... (`priv/viewer_evidence/forms/apple_preview.md`).

PDF.js is `explicit_deferral` for `forms` because the four-check save-and-reopen round-trip failed ...
```

**Signed-artifact boundary pattern** (`guides/api_stability.md:113-121`):

```markdown
This lane does not prove signer trust, certificate policy, or compliance posture.

... Apple Preview and PDF.js are `explicit_deferral` because Preview does not validate `/Sig` digital signatures and PDF.js exposes no signed-artifact integrity panel.
```

**Deferral mirror pattern** (`guides/api_stability.md:181-188`): every `explicit_deferral` reason from the matrix is mirrored in the guide with surface x viewer wording. Add mobile signed deferrals here verbatim enough to satisfy substring mirror tests.

### `CHANGELOG.md` (release contract log, append-only file-I/O)

**Analog:** Viewer Evidence release entries.

**Promotion/deferral entry pattern** (`CHANGELOG.md:53-68`):

```markdown
#### Viewer Evidence (v2.3)

- Promoted `forms.viewers.chrome_pdfium` to `supported` with evidence at `priv/viewer_evidence/forms/chrome_pdfium.md` (`viewer_kind: pdfium-cli`).
- Explicit deferrals for ... with named reasons in `priv/support_matrix.json`.
```

Add an `[Unreleased]` entry for mobile support-matrix changes. Use "promoted" only for supported rows with evidence. Use "explicit deferral" for signed mobile rows unless full signed-artifact proof passes.

### `priv/support_matrix.json` (support contract data, transform)

**Analog:** existing `forms.viewers` and `signing.viewers` rows.

**Supported form-row pattern** (`priv/support_matrix.json:29-40`):

```json
"adobe_acrobat_reader": {
  "status": "supported",
  "proof": ["open", "default_state_visible", "edit_or_toggle", "save"],
  "evidence": "priv/viewer_evidence/forms/adobe_acrobat_reader.md",
  "recorded_at": "2026-05-29",
  "viewer_kind": "pdfium-cli"
}
```

For mobile form rows, use keys:

- `forms.viewers.ios_files_preview`
- `forms.viewers.android_drive_viewer`

Use `viewer_kind: "manual"` and the exact operator `recorded_at` when all four proof IDs pass.

**Explicit deferral pattern** (`priv/support_matrix.json:250-252`):

```json
"apple_preview": {
  "status": "explicit_deferral",
  "evidence_deferred": "Apple Preview does not validate /Sig digital signatures ..."
}
```

For signed mobile rows, add under `signing.viewers.*`, not a new top-level `signed_artifact` key. Use `explicit_deferral` unless a real `/Sig` validation surface is observed.

**Schema guardrails** (`priv/schemas/support_matrix.schema.json:99-117`, `:119-159`):

- `viewer_kind` enum is only `manual`, `pdfium-cli`, `pdfjs-dist`.
- `supported` rows require `evidence`, `recorded_at`, and `viewer_kind`.
- `explicit_deferral` rows require `evidence_deferred` and forbid `evidence`, `recorded_at`, and `viewer_kind`.

### `priv/viewer_evidence/forms/ios_files_preview.md` and `forms/android_drive_viewer.md` (evidence record, file-I/O / manual observation)

**Analog:** `priv/viewer_evidence/forms/apple_preview.md`.

**Frontmatter pattern** (`priv/viewer_evidence/forms/apple_preview.md:1-23`):

```yaml
---
schema_version: 1
surface: forms
viewer: apple_preview
viewer_version: "v0.10.3"
platform: "macOS (arm64)"
recorded_at: "2026-05-29"
recorded_by: "ci:viewer-evidence-live-proof"
fixture: "test/fixtures/forms_support_fixture.pdf"
behaviors:
  - behavior: open
    result: pass
    note: "..."
---
```

For mobile rows:

- `surface: forms`
- `viewer: ios_files_preview` or `android_drive_viewer`
- `viewer_kind` does not belong in frontmatter; it belongs in matrix only.
- Include all four proof IDs from the row.
- Body should state delivery/handoff facts only when relevant. Mail delivery may be a note inside iOS Files/Preview evidence; do not add `ios_mail_preview`.

**Manual recipe pattern** (`guides/viewer_evidence.md:129-167`): observe every `proof[]` behavior, record version/platform at observation time, validate, then promote the matrix row.

### Conditional `priv/viewer_evidence/signed_artifact/ios_files_preview.md` and `signed_artifact/android_drive_viewer.md`

**Analog:** `priv/viewer_evidence/signed_artifact/chrome_pdfium.md`.

**Trust-sensitive evidence pattern** (`priv/viewer_evidence/signed_artifact/chrome_pdfium.md:17-25`):

```yaml
- behavior: integrity_reported_truthfully
  result: pass
  note: "pdfium-cli provides no signature validation panel; pdfsig lane reports integrity valid ..."
- behavior: certificate_trust_reported_separately
  result: pass
  note: "pdfsig lane reports certificate trust skipped separately from integrity valid ..."
```

Only create these mobile signed-artifact evidence files if the physical viewer exposes enough real signed-artifact behavior to satisfy the signed proof IDs. If not, use matrix-only `explicit_deferral` rows and no evidence file.

### `test/docs_contract/adoption_claims_test.exs` (docs-contract test, static verification)

**Analogs:** `comparison_claims_test.exs`, `script_support_claims_test.exs`.

**Section-order pattern** (`test/docs_contract/comparison_claims_test.exs:90-114`): define required sections, assert each exists, then assert positions are sorted.

**Deferral-threshold pattern** (`test/docs_contract/script_support_claims_test.exs:4-35`): read `priv/support_matrix.json`, assert exact text-shaping deferral keys, and refute unsupported overclaims.

Recommended assertions:

- `ADOPTION.md` exists at repo root.
- Required section order exactly matches D-25.
- Demand/download/contributor threshold sentences match UI-SPEC text.
- Signal ledger columns match D-26 exactly.
- Empty states from UI-SPEC are present.
- Review cadence includes `L+30`, `L+60`, `L+90`, monthly, and "cannot trigger before L+45".
- README Guides and comparison limitation/routing blocks link to `ADOPTION.md`.
- Refute `stars count`, `+1 counts`, `generic i18n`, and `adoption:counted` as default counting language.

### `test/docs_contract/github_intake_claims_test.exs` (docs-contract test, static YAML verification)

**Analogs:** docs-contract file reads and exact string assertions in `api_stability_claims_test.exs:5-26`; YAML style partial analog in `.github/workflows/ci.yml:1-29`.

Recommended assertions:

- `.github/ISSUE_TEMPLATE/01_bug.yml`, `02_blocked_document.yml`, and `config.yml` exist.
- `config.yml` contains `blank_issues_enabled: false` and contact links to Discussions and ElixirForum.
- Bug template defaults to `state:triage` and `kind:bug`.
- Blocked-document template defaults to `state:triage` and `adoption:signal`.
- Blocked-document template does not default to `adoption:counted`.
- Required fields cover document job, expected behavior, blocker, script/language, production/evaluation blocked, workaround, fixture/repro notes, source URL/private-report note, and permission to quote/anonymize.
- If `.github/DISCUSSION_TEMPLATE/use-cases.yml` exists, assert it asks for document type, Phoenix/Elixir context, blocker, script/language, workaround, and production/evaluation impact.

Use `YamlElixir` or direct string assertions consistently with existing test dependency availability. If parsing YAML, keep exact string guards for labels and CTAs so accidental copy changes fail visibly.

### `test/docs_contract/launch_execution_claims_test.exs` (docs-contract test, static + manual-gate verification)

**Analog:** `launch_artifacts_claims_test.exs`.

**Forbidden claim pattern** (`test/docs_contract/launch_artifacts_claims_test.exs:84-118`):

```elixir
for claim <- forbidden_claims do
  refute public_copy =~ claim
end
```

Recommended assertions:

- Launch checklist/copy artifact, if stored, contains the required channel order.
- It records a CMP-03/public URL readiness gate before any publication step.
- It includes exact title `Rendro: Elixir-native PDF layout without Chrome`.
- It includes maintainer disclosure for demand-thread replies.
- It bans `Prawn equivalent`, `HTML-to-PDF`, `PDF/A compliant`, `PDF/UA compliant`, `works in every viewer`, `mobile PDF support`, and broad complex-script claims.
- It enforces link budgets as static copy checks where drafts are stored.

If final external posts are not source-tracked, keep this test scoped to any checked-in checklist/draft and leave final publication as manual verification per `88-VALIDATION.md:60-67`.

### Existing docs-contract tests to update

**`test/docs_contract/viewer_evidence_claims_test.exs`**

Analog is the existing same file. Add supported mobile evidence paths to the hard-coded guide mirror list only when corresponding supported rows/evidence files exist.

Current path mirror loop (`test/docs_contract/viewer_evidence_claims_test.exs:49-70`):

```elixir
for path <- [
  "priv/viewer_evidence/forms/apple_preview.md",
  "priv/viewer_evidence/forms/adobe_acrobat_reader.md",
  ...
] do
  assert guide =~ path
end
```

Deferral reasons are already collected dynamically from the matrix and checked against `guides/api_stability.md` (`test/docs_contract/viewer_evidence_claims_test.exs:73-84`). That pattern should catch new signed mobile deferrals once the guide mirrors them.

**`test/docs_contract/forms_claims_test.exs`**

Current terminal-status pattern (`test/docs_contract/forms_claims_test.exs:21-39`) asserts supported and explicit-deferral rows by regex. Add mobile forms rows here, branching to supported or explicit deferral based on operator result.

Current narrow-copy refutes (`test/docs_contract/forms_claims_test.exs:70-75`) should gain `mobile PDF support` if not covered by launch tests.

**`test/docs_contract/signing_claims_test.exs`**

Current trust-boundary pattern (`test/docs_contract/signing_claims_test.exs:54-93`) asserts separation of signing, long-lived, trust, and compliance claims. Add signed mobile deferrals here and refute any copy that treats drawn/Markup signatures as `/Sig` validation.

**`test/docs_contract/raster_claims_test.exs`**

Likely no source change needed except possibly a negative guard. Existing boundary pattern (`test/docs_contract/raster_claims_test.exs:47-68`) proves GUI-viewer rows do not carry `pdfium-render`. Use it as the model for ensuring mobile manual rows do not blur into raster or GUI-fidelity claims.

### `scripts/verify_docs.exs` (docs-contract lane registry, batch)

**Analog:** existing lane list.

**Core pattern** (`scripts/verify_docs.exs:7-31`):

```elixir
# formatter: off
lanes = [
  {"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]},
  {"Viewer evidence semantic-claims lane",
   ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]},
  {"Comparison claims lane", ["test", "test/docs_contract/comparison_claims_test.exs"]}
]
# formatter: on
```

Add new static lanes for adoption, GitHub intake, and launch execution. Then add self-registration assertions in each new test file, matching existing lane assertions such as `forms_claims_test.exs:78-83` and `comparison_claims_test.exs:137-144`.

### GitHub issue and discussion templates (YAML config, request-response)

**Local analog:** none exact. `.github/ISSUE_TEMPLATE/` and `.github/DISCUSSION_TEMPLATE/` do not exist. Use the repo's workflow YAML formatting only for indentation, short strings, and array style.

**Workflow YAML style analog** (`.github/workflows/ci.yml:1-29`):

```yaml
name: CI

on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
```

**Issue-form shape from research:** use `name`, `description`, `title`, `labels`, and `body` with `type`, `id`, `attributes`, and `validations`.

Template-specific requirements:

- `01_bug.yml`: labels `["state:triage", "kind:bug"]`; CTA/copy should use `Open bug report`.
- `02_blocked_document.yml`: labels `["state:triage", "adoption:signal"]`; CTA/copy should use `Describe blocked document`; never default `adoption:counted`.
- `config.yml`: `blank_issues_enabled: false`; contact links route discovery to Discussions and ElixirForum.
- `use-cases.yml`: conditional on Discussions/category enablement; category slug must match `use-cases`; copy should use `Start use-case discussion`.

### Optional launch checklist/copy artifacts under the phase directory

**Analogs:** `88-UI-SPEC.md` and `88-VALIDATION.md`, not source docs.

**Readiness checklist pattern** (`88-UI-SPEC.md:63-78`): show blocked gates first, use `Ready`, `Blocked`, and `Deferred with reason`, and do not use celebratory launch copy until all gates pass.

**Manual publication pattern** (`88-VALIDATION.md:60-67`): public URL checks, Discussions enablement, mobile observations, and community publication are manual-only and should record final URLs in a launch checklist or the `ADOPTION.md` launch snapshot.

If the planner chooses planning-artifact storage, keep final external post drafts under the phase directory, not root source docs. Source-tracked public files should remain `ADOPTION.md`, docs/guides, matrix/evidence, tests, and GitHub templates.

### `priv/guardrails/required_status_checks.json` and `.github/workflows/ci.yml`

**Analog:** existing advisory contexts.

**Guardrail pattern** (`priv/guardrails/required_status_checks.json:40-75`): advisory contexts live in `advisory_contexts`, not `required_contexts`.

**Advisory workflow pattern** (`.github/workflows/ci.yml:84-122`): advisory jobs have `continue-on-error: true`, no `needs:`, and run static/advisory checks without blocking engine merges.

Phase 88 probably should not add a mobile manual evidence live CI job. If a new advisory job is added for launch URL checks, keep it advisory and graph-disconnected. Do not add physical mobile viewer proof to required CI.

## Shared Patterns

### Docs-Contract Tests

Use ExUnit files under `test/docs_contract` with `use ExUnit.Case, async: true` unless the test shells out or builds a Hex tarball. Existing patterns:

- Direct file reads and exact assertions: `api_stability_claims_test.exs:5-26`.
- Section order by string position: `comparison_claims_test.exs:90-114`.
- Banned phrase loops: `launch_artifacts_claims_test.exs:102-117`.
- Lane self-registration: `scripts/verify_docs.exs` assertion in each lane test.

Prefer static file assertions over runtime calls to external GitHub/Hex APIs. Public URL checks and Discussions enablement are manual/operator gates.

### Support Matrix JSON and Evidence

Source patterns:

- Matrix vs evidence split: `guides/viewer_evidence.md:5-7`.
- Status vocabulary: `guides/viewer_evidence.md:19-27`.
- Contrast table: `guides/viewer_evidence.md:288-294`.
- Overclaim boundaries: `guides/viewer_evidence.md:331-338`.

Rules to preserve:

- `supported` means proof-backed and requires an evidence file.
- `explicit_deferral` is matrix-only with a named reason.
- Evidence frontmatter records observation facts only.
- Manual mobile observations must not become broad "mobile PDF support".
- One viewer/surface cell never promotes another viewer or surface.

### Guide Mirror Language

Use the same support-boundary rhythm already present in `guides/api_stability.md`:

1. "Supported surface: ..."
2. "Proof lane: ..."
3. "Unsupported narratives: ..."
4. Per-viewer supported evidence path or explicit deferral reason.
5. "Other viewers are not part of Rendro's supported contract unless ..."

This style is especially important for mobile:

- forms can be supported per viewer only after the four proof IDs pass;
- signed mobile rows are deferrals unless `/Sig` integrity, certificate trust, and timestamp/trust UI are observed;
- drawn/Markup signature UX is not cryptographic validation.

### CI Guardrail Registration

Static docs-contract tests belong in `mix docs.contract` via `scripts/verify_docs.exs`. Manual mobile and public launch checks do not belong in required live CI.

Existing required/advisory split:

- Required `test` context runs `mix ci` (`priv/guardrails/required_status_checks.json:13-20`).
- Viewer evidence live proof is advisory metadata (`priv/guardrails/required_status_checks.json:40-47`).
- Raster/comparison/livebook advisory jobs are graph-disconnected and non-blocking (`.github/workflows/ci.yml:50-122`).

### YAML Template Style

Because there is no local issue/discussion template analog, keep YAML conservative:

- two-space indentation;
- lower-case snake or kebab IDs;
- labels as explicit arrays;
- one helper sentence per field;
- `validations.required` for required fields;
- no marketing copy inside form bodies;
- no default `adoption:counted`.

### Launch Copy Boundaries

Use UI-SPEC copy constraints as source of truth:

- required phrases include `for future readers`, `Disclosure: I maintain Rendro.`, `bounded by priv/support_matrix.json`, `explicit deferral`, `not HTML-to-PDF`, and `without Chrome` (`88-UI-SPEC.md:402-410`);
- avoid `Submit`, `OK`, `Click here`, `mobile PDF support`, `Prawn equivalent`, `browserless viewer`, and `works everywhere` (`88-UI-SPEC.md:412-422`);
- links must be meaningful out of context and status cannot be color-only (`88-UI-SPEC.md:426-438`).

## Planner Notes

- Plan Wave 0 around docs-contract tests for adoption, GitHub intake, and launch execution before adding public docs/templates.
- Reconcile the `CMP-03` state mismatch before launch publication. Treat it as a launch gate, not a copy-edit detail.
- Create GitHub labels before relying on issue-form default labels.
- Do not commit `.github/DISCUSSION_TEMPLATE/use-cases.yml` as an assumed working intake path unless Discussions and the `Use cases` category are enabled or the plan records the manual dependency.
- Keep source changes limited to public docs, support matrix/evidence, tests, YAML templates, and lane registration. No rendering capability or core pipeline changes are implied by Phase 88.
