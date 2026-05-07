# Phase 47: Form Validation and Viewer-Proof Closure - Pattern Map

**Mapped:** 2026-05-05
**Scope analyzed:** validation pipeline, form rules, writer proofs, Poppler proof lane, docs-contract lane, support-boundary wiring

## Reusable Patterns

### 1. Keep form validation inside the existing validate-stage walker

**Primary analog:** `lib/rendro/pipeline/validate.ex`

- `lib/rendro/pipeline/validate.ex:4-7` keeps rule modules as a flat alias list and registers them in `@default_rules`.
- `lib/rendro/pipeline/validate.ex:13-20` aggregates all rule failures into one typed `%Rendro.Error{}` from `Rendro.Error.from_stage/3`.
- `lib/rendro/pipeline/validate.ex:23-35` expects each rule module to return `:ok`, `{:error, reason}`, or `{:errors, reasons}`.
- `lib/rendro/pipeline/validate.ex:37-63` centralizes tree traversal once. Phase 47 should extend rule behavior, not add a second traversal path.

**Pattern to copy**
```elixir
@default_rules [CheckReferences, CheckBounds, CheckRequiredKeys, CheckFormFields]

case walk(doc, doc, rules) do
  [] ->
    {:ok, doc}

  errors ->
    {:error,
     Rendro.Error.from_stage(:validate, :structural_corruption, %{details: %{errors: errors}})}
end
```

**Implication for Phase 47**
- Keep authored-boundary validation in `Rendro.Pipeline.Validate`.
- Prefer additional focused rule helpers or adjacent rule modules over writer-side checks.
- Preserve `details.errors` as the aggregation surface for multi-error form semantics.

### 2. Follow the current clause-based form rule decomposition

**Primary analog:** `lib/rendro/rules/check_form_fields.ex`

- `lib/rendro/rules/check_form_fields.ex:6-11` handles document-level radio-group semantics separately from node-local checks.
- `lib/rendro/rules/check_form_fields.ex:13-30` uses one guard clause per explicit invariant.
- `lib/rendro/rules/check_form_fields.ex:34-59` uses focused recursive collectors for table-aware document scans.

**Pattern to copy**
```elixir
def check(%Document{} = doc, _root_doc) do
  case duplicate_checked_radio_groups(doc) do
    [] -> :ok
    groups -> {:errors, Enum.map(groups, &{:radio_group_multiple_checked_defaults, &1})}
  end
end

def check(%FormField{name: name}, _doc) when not (is_binary(name) and byte_size(name) > 0),
  do: {:error, {:missing_required_key, :name}}
```

**Implication for Phase 47**
- Extend `CheckFormFields` first before inventing a broader validator abstraction.
- Keep “one invariant = one typed reason tuple” style.
- Separate node-local field shape checks from document-wide identity checks.
- Reuse the existing table-aware collectors for duplicate names and radio-group identity scans.

### 3. Typed errors stay small, tuple-based, and asserted at both rule and pipeline levels

**Primary analogs:** `lib/rendro/error.ex`, `test/rendro/rules/check_form_fields_test.exs`, `test/rendro/pipeline/validate_test.exs`, `test/rendro/error_test.exs`

- `lib/rendro/error.ex:23-41` wraps stage failures without rewriting underlying reasons.
- `lib/rendro/error.ex:49-50,111-128` gives validate-stage failures stable user-facing framing while preserving machine-readable `reason` and `details`.
- `test/rendro/rules/check_form_fields_test.exs:28-67` asserts raw rule tuples directly.
- `test/rendro/rules/check_form_fields_test.exs:70-121` asserts `Validate.run/1` returns `%Rendro.Error{stage: :validate, reason: :structural_corruption, details: %{errors: errors}}`.
- `test/rendro/pipeline/validate_test.exs:28-39` follows the same aggregate-error assertion shape.
- `test/rendro/error_test.exs:48-68` treats `Rendro.Error.from_stage/3` wording as contract.

**Pattern to copy**
```elixir
assert {:error,
        %Rendro.Error{
          stage: :validate,
          reason: :structural_corruption,
          details: %{errors: errors}
        }} = Validate.run(doc)

assert {:missing_required_key, :name} in errors
```

**Implication for Phase 47**
- Add new reasons as tuples in the existing style, not exception structs or broad strings.
- Test each new invariant twice:
  - raw rule-module tuple contract
  - validate-stage aggregation contract
- Avoid widening `Rendro.Error` unless Phase 47 introduces a truly new stage-level UX requirement.

### 4. Writer tests prove supported AcroForm behavior by substring assertions, not by duplicating validation logic

**Primary analog:** `test/rendro/pdf/writer_test.exs`

- `test/rendro/pdf/writer_test.exs:122-132` asserts AcroForm catalog wiring exists when form fields are present.
- `test/rendro/pdf/writer_test.exs:140-168` proves text widget serialization and deterministic appearance behavior.
- `test/rendro/pdf/writer_test.exs:171-210` proves checkbox/radio serialization and explicitly refutes `/NeedAppearances`.

**Pattern to copy**
```elixir
assert pdf =~ "/FT /Btn"
assert pdf =~ "/AS /Yes"
refute pdf =~ "/NeedAppearances"
```

**Implication for Phase 47**
- Do not recreate writer semantics in validation tests.
- Use writer tests as evidence for what the validator should protect, not as the place to enforce authored semantics.
- Preserve the current boundary: deterministic authored appearances stay a writer contract; validation rejects authored states that would force writer guesswork.

### 5. Structural validation remains a separate external proof lane

**Primary analogs:** `lib/rendro/adapters/poppler.ex`, `test/rendro/adapters/poppler_test.exs`, `.planning/phases/44-validator-backed-trust-surfaces/VALIDATION.md`

- `lib/rendro/adapters/poppler.ex:14-27` guards external binary use and returns typed tuples.
- `test/rendro/adapters/poppler_test.exs:6-74` conditionally exercises missing-executable, corrupt-file, and valid-file cases.
- `.planning/phases/44-validator-backed-trust-surfaces/VALIDATION.md:6-36` documents this as the structural integrity lane.

**Pattern to copy**
```elixir
case System.find_executable("pdfinfo") do
  nil ->
    {:error, {:missing_executable, "pdfinfo"}}

  executable ->
    case System.cmd(executable, [file_path], stderr_to_stdout: true) do
      {output, 0} -> {:ok, parse_output(output)}
      {output, _exit_code} -> {:error, {:invalid_pdf, String.trim(output)}}
    end
end
```

**Implication for Phase 47**
- Keep Poppler proof separate from viewer-behavior proof.
- If Phase 47 adds proof metadata, it should classify Poppler as structural validation only, never as evidence for Acrobat/Preview interaction support.

### 6. Docs-contract and support-boundary claims are already wired as executable contract surfaces

**Primary analogs:** `test/support/docs_contract.ex`, `test/docs_contract/integrations_contract_test.exs`, `test/docs_contract/integrations_claims_test.exs`, `scripts/verify_docs.exs`, `test/mix/tasks/docs_contract_task_test.exs`

- `test/support/docs_contract.ex:4-22` defines the verified fence contract: `elixir` fences plus `# docs-contract: <id>`.
- `test/docs_contract/integrations_contract_test.exs:12-31` asserts exact fence IDs and evaluates code.
- `test/docs_contract/integrations_claims_test.exs:39-49,82-94` uses direct file-content assertions to lock truthful wording.
- `scripts/verify_docs.exs:7-34` is the canonical docs-contract lane.
- `test/mix/tasks/docs_contract_task_test.exs:6-40` treats the `mix docs.contract` task command as stable contract.

**Pattern to copy**
```elixir
fences = DocsContract.verified_fences("guides/integrations.md")
assert Enum.map(fences, & &1.id) == [...]
Enum.each(fences, fn %{code: code} ->
  refute String.contains?(code, "...")
  DocsContract.evaluate!(code, "guides/integrations.md")
end)
```

**Implication for Phase 47**
- If form/viewer support docs include runnable examples, wire them through `DocsContract`.
- If the main need is truthful wording rather than executable samples, use claims tests that read the rendered markdown and assert exact supported/unsupported language.
- Prefer extending `scripts/verify_docs.exs` only if a new docs-contract test file is added.

### 7. Support-boundary artifacts are already tied into release gating

**Primary analogs:** `priv/support_matrix.json`, `guides/api_stability.md`, `lib/mix/tasks/release/preflight.ex`, `test/mix/tasks/release_preflight_test.exs`

- `priv/support_matrix.json:1-19` is the current machine-readable contract surface.
- `guides/api_stability.md:13-24` sets the tone for explicit core-vs-adapter boundaries.
- `lib/mix/tasks/release/preflight.ex:120-149` verifies required guide files in the Hex artifact.
- `test/mix/tasks/release_preflight_test.exs:81-108` proves those files are part of the release surface.

**Pattern to copy**
```elixir
required_files = [
  "LICENSE",
  "README.md",
  "CHANGELOG.md",
  "guides/api_stability.md",
  "guides/branding.md",
  "guides/integrations.md"
]
```

**Implication for Phase 47**
- If support-boundary prose moves into a new guide, it likely needs release-preflight coverage.
- If claims remain in existing docs plus `priv/support_matrix.json`, preserve the current release gate and add tests around content rather than packaging.

## Candidate File Targets

| File | Role | Data Flow | Best Analog | Notes |
|------|------|-----------|-------------|-------|
| `lib/rendro/rules/check_form_fields.ex` | validator | transform | `lib/rendro/rules/check_form_fields.ex` | First place to add duplicate-name, dotted-name, text-value, and widget-shape semantics. |
| `test/rendro/rules/check_form_fields_test.exs` | test | contract | `test/rendro/rules/check_form_fields_test.exs` | Add raw tuple assertions and validate-stage aggregation assertions for each new invariant. |
| `lib/rendro/form_field.ex` | domain struct | transform | `lib/rendro/form_field.ex` | Only touch if supported authored attributes need tighter type/default documentation. Avoid widening the struct beyond current widget families. |
| `priv/support_matrix.json` | contract artifact | static | `priv/support_matrix.json` | Evolve from flat validator/surface lists into nested forms facets without bloating it into a full compatibility matrix. |
| `test/docs_contract/*_claims_test.exs` | docs contract test | static | `test/docs_contract/integrations_claims_test.exs` | Best analog for asserting exact supported-viewer wording and explicit `unverified` posture. |
| `test/docs_contract/*_contract_test.exs` | docs executable-snippet test | static | `test/docs_contract/integrations_contract_test.exs` | Only needed if new/updated guides contain runnable examples. |
| `scripts/verify_docs.exs` | docs gate | batch | `scripts/verify_docs.exs` | Update only if new docs-contract test files should become part of the canonical lane. |
| `guides/api_stability.md` or another existing guide/README surface | docs | static | `guides/api_stability.md` and wording-claim tests | Best place for support-boundary tone; keep named support claims narrow and explicit. |
| `lib/mix/tasks/release/preflight.ex` | release gate | batch | `lib/mix/tasks/release/preflight.ex` | Only update if Phase 47 introduces a new guide file that must ship in the Hex artifact. |

## File-Level Analog Notes

### JSON contract tests

There is no existing dedicated ExUnit test file for `priv/support_matrix.json`.

Closest reusable patterns:
- `test/docs_contract/integrations_claims_test.exs:39-49,86-94` for reading a public contract file and asserting narrow wording/content.
- `test/mix/tasks/release_preflight_test.exs:87-104` for treating support-boundary artifacts as release-shipping files.
- `.planning/phases/44-validator-backed-trust-surfaces/VALIDATION.md:28-36` for the current minimal parse-level gate (`jq . priv/support_matrix.json`).

Recommendation:
- Add a focused ExUnit contract test for `priv/support_matrix.json` rather than relying only on `jq`.
- Keep it content-oriented and stable-path oriented, similar to claims tests, not schema-framework heavy.

### Docs contract tests

Best analogs:
- `test/support/docs_contract.ex:7-22` for fence discovery and evaluation.
- `test/docs_contract/integrations_contract_test.exs:12-31` for asserting exact fence IDs.
- `test/docs_contract/integrations_claims_test.exs:39-49,82-94` for locking non-runnable support wording.

Recommendation:
- Use a claims-style test if Phase 47 mostly changes support wording.
- Use `DocsContract.verified_fences/1` only if new form/viewer docs contain executable examples.

### Viewer-proof artifact storage

No close analog found in the repo for committed viewer-proof artifacts or viewer-specific evidence directories.

What exists instead:
- structural proof lane: `lib/rendro/adapters/poppler.ex` + `test/rendro/adapters/poppler_test.exs`
- docs/prose proof lane: `test/docs_contract/*`
- release-shipping proof lane: `lib/mix/tasks/release/preflight.ex`

Recommendation:
- Treat viewer-proof storage as a new pattern if Phase 47 requires committed Acrobat/Preview evidence.
- Keep it clearly separate from `priv/support_matrix.json`; the matrix is the contract surface, not the artifact dump.
- Do not force viewer artifacts into core runtime paths under `lib/`.

## Cautions

- Do not duplicate document traversal. `Rendro.Pipeline.Validate` already owns the single-pass walk.
- Do not move authored semantic validation into `Rendro.PDF.Writer`. Writer tests describe supported serialization; validation should reject states that would make serialization ambiguous.
- Do not widen supported widget families beyond `:text`, `:checkbox`, and `:radio`. `lib/rendro/form_field.ex:6-20` and current rule tests encode that boundary already.
- Do not introduce coercive validation. Phase context explicitly rejects magical conversion of booleans, strings, names, or values; keep guard-based explicit failures.
- Do not broaden public wording back to “standard viewers.” Current repo patterns favor explicit, narrow support language and negative assertions against overclaiming.
- Do not conflate structural validation with viewer support. Poppler proves PDF structure, not edit/toggle/save behavior in Acrobat or Preview.
- Do not turn `priv/support_matrix.json` into a sprawling compatibility matrix. Keep stable nested facets and explicit unsupported/unverified entries.
- Do not add new docs files casually. If a new guide is introduced, it likely needs docs-contract coverage and release-preflight packaging updates.
- Do not duplicate support claims across too many prose surfaces without tests. Prefer one authoritative docs surface plus `priv/support_matrix.json`, then lock them together with claims tests.

## What Not To Duplicate Or Widen

- Existing `/NeedAppearances` rejection in writer proofs: reuse `test/rendro/pdf/writer_test.exs:140-210`; do not create a second appearance-strategy story.
- Existing typed validate-stage error envelope: reuse `%Rendro.Error{reason: :structural_corruption, details: %{errors: errors}}`; do not invent a forms-only exception wrapper.
- Existing Poppler adapter behavior: reuse it as the structural proof lane; do not duplicate pdfinfo shelling inside form tests or docs checks.
- Existing docs-contract harness: reuse `Rendro.Test.DocsContract`; do not create a second markdown-evaluation mechanism.
- Existing support-boundary tone in `guides/api_stability.md:13-24`; do not widen claims from narrow named support to vague ecosystem-wide assurances.

## Summary

Phase 47 should primarily reuse:
- `lib/rendro/pipeline/validate.ex` for single-pass rule aggregation
- `lib/rendro/rules/check_form_fields.ex` for explicit invariant clauses plus document-level collectors
- `test/rendro/rules/check_form_fields_test.exs` for raw tuple and aggregated `%Rendro.Error{}` assertions
- `test/docs_contract/integrations_claims_test.exs` for truthful wording locks
- `test/support/docs_contract.ex` plus `test/docs_contract/integrations_contract_test.exs` for executable guide fences
- `priv/support_matrix.json` as the machine-readable contract surface

There is no current in-repo analog for viewer-proof artifact storage. Planner should treat that as new work and keep it isolated from both core runtime code and the existing Poppler structural-validation lane.
