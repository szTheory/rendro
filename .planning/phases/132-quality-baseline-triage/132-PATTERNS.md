# Phase 132: Quality Baseline & Triage - Pattern Map

**Mapped:** 2026-08-26  
**Files analyzed:** 4  
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/QUALITY.md` | config / maintainer ledger | human-review | `priv/quality/SIGN-OFF.md` | data-flow match |
| `.planning/quality/schema/baseline-v1.schema.json` | config / JSON Schema | transform | `priv/schemas/rubric_scores.schema.json` | exact |
| `.planning/quality/baselines/132-initial.json` | config / immutable evidence snapshot | transform | `priv/quality/rubric_scores.json` | role-match |
| `test/quality/baseline_ledger_contract_test.exs` | test | file-I/O / transform | `test/docs_contract/rubric_manifest_contract_test.exs` | exact |

## Pattern Assignments

### `.planning/QUALITY.md` (config / maintainer ledger, human-review)

**Analog:** `priv/quality/SIGN-OFF.md` — the current concise, human-first complement to machine-enforced facts.

**Provenance and scope pattern** (lines 3-16): lead with date/scope, identify the companion machine record, name the evidence source, and state the limit beside the claim.

```markdown
**Phase 123 · D-05 Commit 3 · 2026-07-28**
Companion to `rubric_scores.json` (the machine-enforced manifest) ...

**Verdict provenance:** human visual judgment over pre-computed glyph-height deltas
...
Every score below is recomputed by `passed?/2`
(`test/docs_contract/rubric_manifest_contract_test.exs`) ...
```

**Scannable decision-table pattern** (lines 20-29): concise Markdown table carries identity, outcome, bounded evidence, and notes; detailed machine facts remain in the JSON companion.

```markdown
## Per-demo sign-off

| Demo | Passed | Content hierarchy | Themed key-fact glyph delta | Notes |
|---|:--:|:--:|---|---|
| Invoice | **true** | 5 | ... | ... it does not recertify the whole invoice gallery or any compliance property. |
```

**Truthful-boundary pattern** (lines 33-50): preserve meaningful limitations and avoid generalizing bounded evidence. Apply this to compatibility risk, local-versus-CI authority, and unavailable advisory evidence.

```markdown
- **Phase 126 is a bounded repair review, not a universal re-score.** ...
  it does not claim WCAG, PDF/UA, print safety, or universal preset quality.
- **Zero color/rendering code was touched to produce this sign-off.** ...
  this commit's diff is `priv/quality/`, `priv/schemas/`, and `test/docs_contract/` only.
```

**Implementation assignment:** use headings for the locked compatibility contract, baseline registry, lifecycle/dispositions, active findings, historical outcomes, deferred triggers, and the reserved Phase 137 before/after section. Keep prose human-owned; it must only link to `.planning/quality/` data and must not become product, package, release, or ordinary regression-test state.

---

### `.planning/quality/schema/baseline-v1.schema.json` (config / JSON Schema, transform)

**Analog:** `priv/schemas/rubric_scores.schema.json` — repository-owned Draft 2020-12 schema with strict required fields, enums, references, and conditional rules.

**Root metadata and required-field pattern** (lines 1-9): declare the JSON Schema draft, stable schema identity, a precise structural-only description, object type, required keys, and fixed schema version.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "rubric_scores.schema.json",
  "title": "Rendro Rubric Scores Manifest",
  "description": "Structural contract for priv/quality/rubric_scores.json...",
  "type": "object",
  "required": ["schema_version", "dimensions", "gates", "thresholds", "scores", "stress_exemption", "catalog_dispositions"],
  "properties": {
    "schema_version": { "const": 1 }
  }
}
```

**Named definitions plus closed evidence-record pattern** (lines 94-105, 158-199): define reusable item shapes in `$defs`, require each factual field, constrain enums/formats/hashes, and use `additionalProperties: false` for the fully controlled evidence item shape.

```json
"$defs": {
  "catalog_disposition": {
    "type": "object",
    "required": ["catalog_id", "family", "brand", "preset", "mode", "evidence_ref", "png_sha256", "source_pdf_sha256", "recorded_at", "review_status"],
    "properties": {
      "mode": { "enum": ["light", "dark"] },
      "png_sha256": { "type": "string", "pattern": "^[a-f0-9]{64}$" },
      "recorded_at": { "type": "string", "format": "date" }
    },
    "additionalProperties": false
  }
}
```

**Conditional validation pattern** (lines 185-198): model factual conditional requirements in schema rather than manually parsing JSON in Elixir. For this phase, use `if`/`then` to require a non-empty `unavailability_reason` only for `status: "unavailable"`; constrain status to `passed | failed | unavailable`.

```json
"allOf": [
  {
    "if": { "properties": { "review_status": { "const": "scored" } }, "required": ["review_status"] },
    "then": { "required": ["dimension_scores", "gate_results", "passed"] }
  }
]
```

**Implementation assignment:** preserve human disposition/rationale in `QUALITY.md`; schema only the repeatable snapshot provenance specified by D-11 (IDs, SHA/source, capture/environment, command/lane/result/status, raw-artifact facts, redaction). Do not add an application/runtime dependency; JSV is dev/test-only already (`mix.exs:70-73`).

---

### `.planning/quality/baselines/132-initial.json` (config / immutable evidence snapshot, transform)

**Analog:** `priv/quality/rubric_scores.json` — checked-in JSON starts with its version and stores stable, independently reviewable facts; its schema keeps subjective decision prose separate.

**Versioned, named-record pattern** (lines 1-12): snapshot begins with `schema_version`, followed by stable named collections; individual records use clear identifiers and human labels rather than deriving meaning from filename/order.

```json
{
  "schema_version": 1,
  "dimensions": [
    {
      "id": "information_architecture",
      "label": "Information architecture",
      "anchors": { ... }
    }
  ]
}
```

**Explicit authority/boundary facts pattern** (lines 77-87): encode factual scope and reasons directly instead of treating omitted data as a conclusion.

```json
"stress_exemption": {
  "exempt": true,
  "reason": "... deliberately excluded ...",
  "fixture_source": "test/rendro/edge_matrix_test.exs",
  "gate_scope": "scores"
}
```

**Implementation assignment:** make `132-initial.json` append-only/immutable after capture. It should include `snapshot_id`, schema version, exact source SHA, UTC time, worktree state, environment identity, and `evidence_items`; each item has its own stable `EV-*` ID, registered command, lane, normalized result, status, applicable identities, redaction, and hash/byte-count/location/expiry metadata for raw output. Represent a missing PDFium/remote artifact as `status: "unavailable"` plus reason and rerun trigger — never as omitted, passed, or failed. Do not commit raw logs, PDFs, PNGs, reports, or caches.

---

### `test/quality/baseline_ledger_contract_test.exs` (test, file-I/O / transform)

**Analog:** `test/docs_contract/rubric_manifest_contract_test.exs` — isolated `ExUnit` contract test that reads checked-in artifacts, builds JSV schema, validates the real record, and proves mutations fail loudly.

**Test module, paths, and decoder/schema helper pattern** (lines 7-15, 81-100): hard-code repository-relative artifact paths in module attributes; use tiny private readers and build the JSV schema once per test call.

```elixir
defmodule Rendro.DocsContract.RubricManifestContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @manifest_path "priv/quality/rubric_scores.json"
  @schema_path "priv/schemas/rubric_scores.schema.json"

  defp manifest do
    @manifest_path
    |> File.read!()
    |> JSON.decode!()
  end

  defp rubric_schema do
    @schema_path
    |> File.read!()
    |> JSON.decode!()
    |> JSV.build!()
  end
end
```

**Schema + mutation-test pattern** (lines 166-193): first validate committed data, then mutate individual required fields and assert validation no longer succeeds. Follow this for required evidence fields, allowed enums, SHA formats, and unavailable-only reason rules.

```elixir
test "schema validation: checked-in manifest validates against rubric_scores.schema.json" do
  assert {:ok, _} = JSV.validate(manifest(), rubric_schema())
end

for mutation <- scored_evidence_mutations() do
  mutated_record = mutate_scored_record(record, mutation)
  mutated = put_in(m, ["catalog_dispositions"], replace_catalog_disposition(m["catalog_dispositions"], mutated_record))

  refute match?({:ok, _}, JSV.validate(mutated, rubric_schema()))
end
```

**Fail-loud reference and non-vacuity pattern** (lines 372-405): assert a reference is non-empty, exists, and is covered by the relevant authoritative manifest. Apply this to snapshot references from the ledger; avoid a test that can pass merely because there are no evidence items/findings.

```elixir
assert is_binary(evidence_ref) and evidence_ref != ""
assert File.exists?(evidence_ref)
assert MapSet.member?(known_png_paths, evidence_ref)
```

**Scope guard:** this test is intentionally file-I/O only and must not parse all ledger prose into a database or change runtime/package behavior. Test fixed Markdown headings and required finding-field labels with bounded static checks; validate machine facts and conditional rules through JSV.

## Shared Patterns

### Evidence-authority lanes

**Source:** `mix.exs:77-111`  
**Apply to:** baseline registry, snapshot evidence items, and ledger wording.

```elixir
"ci.fast": [
  "format --check-formatted",
  "hex.build",
  "compile --warnings-as-errors",
  "test --exclude quarantine --slowest 10",
  "docs --warnings-as-errors",
  "credo --strict",
  "dialyzer"
],
"ci.proofs": [ ... ],
"ci.advisory": [ ... ]
```

Keep deterministic, proof, and advisory outcomes distinct. A local advisory absence is an explicit `unavailable` record with reason/trigger, not a green or zero-result claim. Reuse these commands; do not introduce parallel quality commands.

### Schema-backed, fail-loud contracts

**Source:** `test/docs_contract/rubric_manifest_contract_test.exs:166-193`; `priv/schemas/rubric_scores.schema.json:185-199`  
**Apply to:** snapshot schema and focused maintenance test.

Use JSON + `JSV.build!` / `JSV.validate` for machine-factual structure, then mutation cases for failures. Encode conditional requirements in the schema, retain a readable test failure message, and do not create `lib/` code for this control-plane-only validation.

### Human record beside bounded machine facts

**Source:** `priv/quality/SIGN-OFF.md:3-16, 33-50, 136-138`  
**Apply to:** `.planning/QUALITY.md` and its relation to `.planning/quality/`.

The Markdown ledger gives maintainer context, disposition, limits, and closure proof; normalized JSON gives stable identity/provenance. The human record must link to the companion instead of duplicating all machine data or making sweeping claims.

### Exact identity and reproducibility

**Source:** `test/rendro/public_api/manifest_test.exs:72-104`; `priv/quality/SIGN-OFF.md:63-84`  
**Apply to:** source SHA, raw-artifact hashes, renderer identity, and snapshot capture state.

```elixir
fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"
checked_in = File.read!("priv/public_api.json")
assert fresh_json == checked_in
```

Store/validate exact identities where this phase claims reproducibility. Keep the local/CI authority and platform limit explicit (the sign-off record names the accepted CI artifact when the renderer cannot execute locally).

## No Analog Found

None. The repository has no current durable `.planning/` ledger, so `priv/quality/SIGN-OFF.md` is a partial (human-review) analog only. The phase should combine it with the exact existing JSV/schema contract pattern, not copy the catalog’s scoring arithmetic.

## Metadata

**Analog search scope:** `.planning/`, `priv/quality/`, `priv/schemas/`, `test/docs_contract/`, `test/rendro/public_api/`, `mix.exs`  
**Files scanned:** 8 focused analog/configuration files  
**Pattern extraction date:** 2026-08-26
