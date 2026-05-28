# Phase 68 Research: Viewer Evidence Schema, Mix Task, and Docs-Contract Lane

**Researched:** 2026-05-28  
**Phase:** 68 — Viewer Evidence Schema, Mix Task, and Docs-Contract Lane  
**Requirements in scope:** MATRIX-01, MATRIX-02, MATRIX-03, RECIPE-02, RECIPE-04, GUARDRAIL-01, GUARDRAIL-03, GUARDRAIL-04  
**Confidence:** HIGH on repo patterns and phase boundary; MEDIUM on JSON Schema shape details (planner discretion per D-04/D-55)

---

## 1. Summary of implementation approach

Phase 68 lands **infrastructure only**: additive matrix vocabulary (`explicit_deferral`), Draft 2020-12 JSON Schemas, a shared validation core used by both `Mix.Tasks.Rendro.ViewerEvidence` and the eighth docs-contract lane, and empty `priv/viewer_evidence/` + `priv/schemas/` scaffolding. **No matrix promotions, no evidence files beyond `_template.md`, no operator guide.**

The work follows Rendro’s established **machine-readable contract + docs-contract test** pattern (same as forms/signing/embedded/protection lanes). Validation is **dev/test-only** (JSV + YAML parse + Elixir cross-artifact rules); nothing enters the runtime `Rendro.*` public API.

**Critical phase-boundary constraint:** `priv/support_matrix.json` stays **byte-for-byte unchanged** on viewer row semantics at phase end. The validator and CI lane must **pass the current production matrix**, which today has:

- **5** `supported` rows **without** `evidence:` / `recorded_at` / `viewer_kind` (pre-v2.3 promotions)
- **21** bare `unverified` rows (no `evidence_deferred`)
- **0** `explicit_deferral` rows
- **26** total viewer cells across **8** viewer maps (see §6)

This conflicts with CONTEXT D-04/D-22 (“`supported` → require `evidence`”; “fails in `validate` + docs-contract”). **Recommended resolution for the planner:** implement **two enforcement tiers**:

| Tier | What | Phase 68 CI on production matrix |
|------|------|----------------------------------|
| **A — structural** | JSV accepts legacy `supported` (proof-only), `unverified`, new `explicit_deferral` enum; forbids forbidden keys on viewer rows; full matrix document validates | **Blocking** |
| **B — promotion-complete** | `supported` requires resolvable `evidence` + `recorded_at` + `viewer_kind`; cross-checks frontmatter | **Fixture/subtest only** until Phase 70; **`list`/`validate` report as violations** with note; **strict blocking** from Phase 70 onward |

Tier B rules are still **implemented and proven** in Phase 68 via isolated ExUnit cases (temp matrix snippets / `test/support` fixtures) so RECIPE-04 and ROADMAP success criterion 3 (“fails when operator drafts…”) are satisfied without breaking the unchanged matrix.

**Operator loop after Phase 68:**

```
mix rendro.viewer_evidence missing   → 21 silent gaps (exit 1)
mix rendro.viewer_evidence list      → table: 5 supported (legacy note), 21 unverified
mix rendro.viewer_evidence validate  → JSV OK on matrix; warnings for 5 legacy supported; exit 0 unless structural violation
mix docs.contract                    → eighth lane green on production artifacts
```

---

## 2. File inventory (create/modify with paths)

### Create

| Path | Purpose |
|------|---------|
| `priv/schemas/support_matrix.schema.json` | Draft 2020-12 schema for full matrix + `$defs/viewer_row` |
| `priv/schemas/viewer_evidence.schema.json` | Frontmatter contract (schema_version 1, D-07–D-09) |
| `priv/viewer_evidence/.gitkeep` | Keep directory in git (D-13) |
| `priv/viewer_evidence/_template.md` | Canonical empty template with valid frontmatter shape (D-13) |
| `lib/rendro/viewer_evidence/matrix.ex` | Walker: enumerate cells, surface-key mapping, JSON decode |
| `lib/rendro/viewer_evidence/frontmatter.ex` | Split `---` fences, YAML parse, path alignment |
| `lib/rendro/viewer_evidence/lint.ex` | Body lint (D-15), deferral reason lint (D-16), byte budget (D-14) |
| `lib/rendro/viewer_evidence/validator.ex` | JSV roots + cross-artifact rules; shared by Mix task + tests |
| `lib/mix/tasks/rendro/viewer_evidence.ex` | `Mix.Tasks.Rendro.ViewerEvidence` — `list` / `validate` / `missing` (D-19) |
| `test/docs_contract/viewer_evidence_claims_test.exs` | Eighth docs-contract lane (RECIPE-04) |
| `test/rendro/viewer_evidence/validator_test.exs` | Unit tests for violation fixtures (recommended) |
| `test/mix/tasks/viewer_evidence_task_test.exs` | Exit codes, `--json`, subcommand dispatch (recommended) |
| `test/support/viewer_evidence/fixtures/` | Minimal invalid matrix/evidence snippets for tier-B tests |

### Modify

| Path | Change |
|------|--------|
| `mix.exs` | Add `{:jsv, "~> 0.18", only: [:dev, :test], runtime: false}`; add YAML **parser** dep (see §5 — not raw `ymlr` for parse) |
| `scripts/verify_docs.exs` | Eighth lane tuple (D-18) |
| `.planning/research/ARCHITECTURE.md` | Reconcile Pattern 1 / deferral flow with D-01 (`explicit_deferral` status, not `unverified` + `evidence_deferred`) — per D-05 |

### Explicitly do **not** create/modify in Phase 68

- `priv/support_matrix.json` (unchanged)
- `guides/viewer_evidence.md`, `mix.exs` extras, family `*_claims_test.exs`
- `.github/workflows/ci.yml` (no new required job)
- `mix.exs` `aliases` `:ci` (do not add viewer task — D-24)
- `Rendro.Support.ViewerEvidence` or any runtime loader (D-25)

### Mix task path note

CONTEXT specifies `lib/mix/tasks/rendro/viewer_evidence.ex`. Existing tasks use **dot notation** (`lib/mix/tasks/rendro.visual_uat.ex`). Both compile to `Mix.Tasks.Rendro.ViewerEvidence`. Prefer **subdirectory** per CONTEXT; optionally add a one-line note in plan if matching dot-file convention is desired for consistency with `rendro.visual_uat.ex`.

---

## 3. Existing patterns to follow (with code references)

### Docs-contract lane aggregator

Copy the lane tuple pattern in `scripts/verify_docs.exs`:

```7:15:scripts/verify_docs.exs
lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  {"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]},
  {"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]},
  {"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]},
  {"Signing semantic-claims lane", ["test", "test/docs_contract/signing_claims_test.exs"]},
  {"Embedded artifact semantic-claims lane", ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]},
  {"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]}
]
```

Add:

```elixir
{"Viewer evidence semantic-claims lane", ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]}
```

Each family test also asserts its lane is registered — mirror in `viewer_evidence_claims_test.exs`:

```89:94:test/docs_contract/protection_claims_test.exs
  test "docs verification script includes the protection claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]}|
  end
```

### Family claims tests stay narrow; cross-family invariants are separate

`protection_claims_test.exs` uses **regex on raw JSON string** for family-specific promotion facts — do not merge viewer-evidence schema rules there:

```4:38:test/docs_contract/protection_claims_test.exs
  test "support matrix publishes the narrow protection family and promotes only the proven protection viewer" do
    matrix = File.read!("priv/support_matrix.json")
    ...
    assert matrix =~
             ~r/"protection".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s
```

The new file is **cross-family only** (all viewer maps, orphan evidence, deferral vocabulary).

### Mix task moduledoc and exit codes

Follow `Mix.Tasks.Rendro.VisualUat`: rich `@moduledoc`, `Mix.shell()` messaging, `exit({:shutdown, 1})` on failure:

```57:67:lib/mix/tasks/rendro.visual_uat.ex
      if verdict.overall_pass do
        :ok
      else
        Mix.shell().error("Visual UAT failed (overall_pass: false). See notes above.")
        exit({:shutdown, 1})
      end
    else
      {:error, msg} ->
        Mix.shell().error(msg)
        exit({:shutdown, 1})
```

### Docs-contract entrypoint chain

`mix docs.contract` → `scripts/verify_docs.exs` → per-lane `mix test` (unchanged):

```10:19:lib/mix/tasks/docs.contract.ex
  def run(_args) do
    runner = Application.get_env(:rendro, :docs_contract_command_runner, &System.cmd/3)
    {output, status} = runner.("mix", ["run", "scripts/verify_docs.exs"], stderr_to_stdout: true)
    ...
```

### Dev/test-only deps in `mix.exs`

Match existing optional dev tools pattern:

```50:55:mix.exs
      {:stream_data, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:req, "~> 0.5", only: [:dev, :test]}
```

### Current matrix viewer shapes (must remain valid)

Representative rows from live `priv/support_matrix.json`:

```28:52:priv/support_matrix.json
    "viewers": {
      "adobe_acrobat_reader": {
        "status": "unverified",
        "proof": ["open", "default_state_visible", "edit_or_toggle", "save"]
      },
      "apple_preview": {
        "status": "supported",
        "proof": ["open", "default_state_visible", "edit_or_toggle", "save"]
      },
      "chrome_pdfium": {
        "status": "unverified"
      },
```

Nested maps the walker **must** include (D-23):

- `forms.viewers`, `forms.signature_widget_viewers`
- `signing_preparation.viewers`
- `signing.viewers`, `signing.long_lived.viewers`
- `embedded_files.viewers`, `links.viewers`, `protection.viewers`

---

## 4. Technical decisions and tradeoffs

| Decision | Choice | Rationale | Tradeoff |
|----------|--------|-----------|----------|
| Validation location | Shared `lib/rendro/viewer_evidence/*` modules | Mix task + docs-contract must not drift (PITFALLS § scaling) | Adds `lib/rendro/` modules; mitigated by `@moduledoc false` and no public API (D-25) |
| JSON Schema engine | JSV ~> 0.18, dev/test only | Draft 2020-12, compile-time precompile, offline file refs (STACK.md) | Heavier than hand-rolled validator; pays off as published contract |
| Matrix validation scope | Full-document JSV + Elixir cell walker | MATRIX-03, GUARDRAIL-03 | Large schema authoring effort; use `$defs/viewer_row` reused everywhere |
| Legacy `supported` rows | Tier A/B split (§1) | Phase boundary vs D-04/D-22 | Temporary dual behavior; document flip date (Phase 70) |
| `explicit_deferral` vs overloaded `unverified` | Third status enum (D-01) | `missing` counts only bare `unverified`; Can I Use-style honest negatives | Requires updating stale ARCHITECTURE deferral flow (D-05) |
| Promotion fields on matrix | `evidence`, `recorded_at`, `viewer_kind` only on matrix; `viewer_version` in file only (D-10–D-11) | Viewer auto-update must not invalidate matrix | Operators must keep file + matrix dates aligned manually |
| Staleness | 180-day warning in `validate`, exit 0 (D-17) | Advisory in v2.3; blocking deferred to Phase 72 | Docs-contract must **not** fail on stale rows in Phase 68 |
| CI surface | Eighth lane in existing `test` job only (D-18) | No new required check; preserves GUARDRAIL-02 spirit | All enforcement must stay fast and offline |
| YAML frontmatter parse | **`yaml_elixir`** (see §5) | CONTEXT lists `ymlr`; **`ymlr` is encode-only on Hex** | CONTEXT D-12 needs correction in plan |
| Mix task in `mix ci` | Omit (D-24) | Task is operator tooling; CI runs docs-contract test directly | Operators must discover task via `mix help` |

---

## 5. Dependency additions (jsv, ymlr)

### Required

```elixir
# mix.exs — defp deps/0
{:jsv, "~> 0.18", only: [:dev, :test], runtime: false}
```

Usage pattern:

```elixir
schema_path = "priv/schemas/support_matrix.schema.json"
schema = schema_path |> File.read!() |> JSON.decode!()
root = JSV.build!(schema, base_uri: "file://" <> Path.absname("priv/schemas/"))

case JSV.validate(matrix_map, root) do
  {:ok, _} -> :ok
  {:error, err} -> {:error, JSV.normalize_error(err)}
end
```

Elixir 1.19 ships `JSON` module; JSV docs also show Jason compatibility for older versions — Rendro can use `JSON.decode!/1` on the matrix file.

### YAML: correction to CONTEXT D-12

**`ymlr` (~> 5.x) is a YAML encoder, not a parser.** For frontmatter **decoding**, add:

```elixir
{:yaml_elixir, "~> 2.12", only: [:dev, :test], runtime: false}
```

Optional: keep `ymlr` only if `_template.md` generation wants programmatic YAML emission — **not required** for Phase 68 if `_template.md` is static.

Parse flow:

```elixir
["" | yaml_and_body] = String.split(content, "---", parts: 3)
{:ok, frontmatter} = YamlElixir.read_from_string(yaml)
body = yaml_and_body |> List.last()
```

### No runtime deps

No changes to `application/0`, no new Hex package files for schemas beyond git (schemas live under `priv/`; note `mix.exs` `package/0` `files` currently omits `priv/support_matrix.json` — out of scope for Phase 68 but relevant before v2.3 release).

---

## 6. JSON Schema design notes for support_matrix and viewer_evidence

### `$defs/viewer_row` (core contract — MATRIX-01, MATRIX-02, GUARDRAIL-03)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "viewer_row": {
      "type": "object",
      "additionalProperties": false,
      "required": ["status"],
      "properties": {
        "status": {
          "enum": ["supported", "unverified", "explicit_deferral"]
        },
        "proof": {
          "type": "array",
          "items": { "type": "string", "minLength": 1 },
          "uniqueItems": true
        },
        "evidence": {
          "type": "string",
          "pattern": "^priv/viewer_evidence/[a-z0-9_]+/[a-z0-9_]+\\.md$"
        },
        "recorded_at": { "type": "string", "format": "date" },
        "viewer_kind": {
          "enum": ["manual", "pdfium-cli", "pdfjs-dist"]
        },
        "evidence_deferred": { "type": "string", "minLength": 40 }
      },
      "allOf": [
        {
          "if": { "properties": { "status": { "const": "explicit_deferral" } }, "required": ["status"] },
          "then": {
            "required": ["evidence_deferred"],
            "not": { "required": ["evidence", "recorded_at", "viewer_kind"] }
          }
        },
        {
          "if": { "properties": { "status": { "const": "unverified" } }, "required": ["status"] },
          "then": {
            "not": { "anyRequired": ["evidence", "recorded_at", "viewer_kind", "evidence_deferred"] }
          }
        }
      ]
    }
  }
}
```

**Phase 68 tier-A carve-out for `supported`:** do **not** put tier-B `required: ["evidence", "recorded_at", "viewer_kind"]` in the JSON Schema `then` block yet; enforce tier B in Elixir (`Validator.promotion_complete?/1`) so the unchanged matrix passes JSV. Flip schema `if/then` in Phase 70 when the five legacy rows gain pointers.

**Forbidden on viewer rows (GUARDRAIL-03):** `additionalProperties: false` on `viewer_row` blocks `compliance`, `signer_trust`, `multi_signature`, etc. Top-level matrix families remain permissive (`validators`, `unsupported`, capability maps) — only viewer row objects get the strict def.

### Full matrix document schema

Strategy:

1. **`type: object`** with known top-level keys (`forms`, `signing`, …) each referencing family schemas.
2. Viewer maps reference `"$ref": "#/$defs/viewer_row"` for every entry under `viewers` / `signature_widget_viewers`.
3. **`signing.long_lived.viewers`** nested the same way.
4. Do **not** require new top-level keys (GUARDRAIL-03).

### Surface key → evidence path mapping (Elixir, not JSON Schema)

| Matrix path | Evidence `<surface>` segment |
|-------------|-------------------------------|
| `forms.viewers.*` | `forms` |
| `forms.signature_widget_viewers.*` | `signature_widget` |
| `signing_preparation.viewers.*` | `signing_preparation` |
| `signing.viewers.*` | `signed_artifact` |
| `signing.long_lived.viewers.*` | `long_lived_signed_artifact` |
| `embedded_files.viewers.*` | `embedded_files` |
| `links.viewers.*` | `links` |
| `protection.viewers.*` | `protection` |

Canonical evidence pointer for a promoted cell:

`priv/viewer_evidence/<surface>/<viewer>.md`

### `viewer_evidence.schema.json` (frontmatter — D-07–D-09)

- `schema_version`: const `1`
- Required: `surface`, `viewer`, `viewer_version`, `platform`, `recorded_at`, `behaviors`
- `recorded_at`: `format: date`
- Fixture: `oneOf` — `{ required: ["fixture"] }` | `{ required: ["fixture_sha256"], properties: { fixture_sha256: { pattern: "^sha256:[a-f0-9]{64}$" } } }`
- `behaviors`: array of objects with required `behavior`, `result` (`pass|fail|skip|na`), `note` (`minLength: 1`)
- **`not` allowed:** `status`, `viewer_kind`, `checks`, `date_checked` (forbid via `additionalProperties` + explicit `not`/`unevaluatedProperties` pattern)
- Optional: `recorded_by` string
- Document byte budget **65536** in schema `description` fields (D-14)

### Elixir cross-artifact rules (beyond JSV)

| Rule | Source |
|------|--------|
| Frontmatter `surface`/`viewer` match path | D-06 |
| Every `behaviors[].behavior` ∈ matrix `proof[]` for that cell | D-09 |
| Orphan `.md` files under `priv/viewer_evidence/**/*.md` (exclude `_template.md`) | RECIPE-04 |
| `recorded_at` matrix ≡ frontmatter when both present | Discretion — recommend equality |
| Deferral reason lint | D-16, GUARDRAIL-01 |
| Body lint + byte size | D-14, D-15, GUARDRAIL-04 |

---

## 7. Mix task architecture

**Module:** `Mix.Tasks.Rendro.ViewerEvidence`  
**Invocation:** `mix rendro.viewer_evidence list|validate|missing [--json]`

### Subcommand behavior

| Command | stdout | stderr | Exit |
|---------|--------|--------|------|
| `list` | Summary counts + fixed-width table (`surface`, `viewer`, `status`, notes) sorted by surface→viewer; legacy supported without `evidence:` gets note column | — | 0 if matrix parses |
| `list --json` | `{"summary": {...}, "cells": [...]}` only | errors | 0 on parse success |
| `missing` | Same shape, filtered to `status == "unverified"` only | — | 1 if any row (expect **21** today) |
| `missing --json` | JSON only | errors | same |
| `validate` | Summary; print violations; staleness **warnings** to stderr | warnings + errors | 1 on tier-A **or** tier-B violation per planner’s tier split; **0** with warnings only (D-17) |

### Implementation sketch

```
run/1
  parse argv → {cmd, opts}
  Mix.Task.run("app.start")
  matrix = Matrix.load!()
  cells = Matrix.enumerate_viewer_cells(matrix)

  case cmd do
    :list -> List.run(cells, opts)
    :missing -> Missing.run(cells, opts)
    :validate -> Validator.run_full(matrix, cells, opts)
  end
```

- **No TTY detection** (D-20).
- **Do not register in `mix ci`** (D-24).
- **`@moduledoc`:** three states, subcommands, exit codes, byte budget, CI truth (`mix docs.contract` + lane path), forward link to future `guides/viewer_evidence.md`.

### Expected output against unchanged matrix (sanity checks for planner)

| Metric | Expected |
|--------|----------|
| Total cells | **26** |
| `supported` | **5** (all legacy, no `evidence:`) |
| `unverified` | **21** |
| `explicit_deferral` | **0** |
| `missing` exit code | **1** |

---

## 8. Docs-contract test design

**File:** `test/docs_contract/viewer_evidence_claims_test.exs`  
**Module:** `Rendro.DocsContract.ViewerEvidenceClaimsTest`  
**Style:** `async: true` where tests only read fixtures / production files without temp dir races; use `async: false` if sharing temp directories.

### Test categories

1. **Lane registration** — `scripts/verify_docs.exs` includes eighth lane tuple (mirror protection test).

2. **Production matrix structural pass (tier A)** — load `priv/support_matrix.json`, `Validator.validate_matrix_structure!/1` succeeds; JSV passes.

3. **Production evidence directory** — only `_template.md` + `.gitkeep`; no orphan promotion files; template validates against frontmatter schema.

4. **Violation fixtures (tier B — RECIPE-04, GUARDRAIL-01, GUARDRAIL-04)** — use snippets under `test/support/viewer_evidence/fixtures/`:
   - `supported` without `evidence` → fails promotion validator
   - `explicit_deferral` without `evidence_deferred` → fail
   - deferral with `TBD`, `not yet`, `deferred for later`, `< 40` chars → fail
   - evidence file with `![`, `-----BEGIN`, `/Users/`, `passphrase: secret` → fail
   - file `byte_size > 65536` → fail
   - orphan `priv/viewer_evidence/forms/foo.md` unreferenced → fail
   - forbidden viewer-row key (`compliance_tier`) → JSV fail

5. **Cross-family isolation** — test file must **not** assert family-specific regexes (forms/protection/signing stay in their own tests).

6. **Optional self-guard** — read own source for `docs-contract:viewer_evidence_*` ids if adding verified fences later (forms test pattern).

Call shared `Rendro.ViewerEvidence.Validator` — **never duplicate** lint/schema logic inline.

---

## 9. Risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| D-04/D-22 vs unchanged matrix | Phase 68 blocked on day one | Tier A/B split (§1); document Phase 70 strict flip |
| `ymlr` cannot parse YAML | Broken frontmatter validation | Use `yaml_elixir`; update plan vs D-12 |
| JSV schema too strict on legacy matrix | CI red on merge | Acceptance tests against **actual** `priv/support_matrix.json` before merge |
| Walker misses nested maps | Wrong `missing` report | Unit test enumerates exactly **26** cells; compare to manual inventory |
| Surface name mismatch (`signing` vs `signed_artifact`) | Wrong canonical paths at promotion | Central `Matrix.surface/2` mapping table (§6) |
| Duplicated validation in Mix task vs test | Drift (PITFALLS #2 post-v2.3) | Single `Rendro.ViewerEvidence.Validator` module |
| Family tests break on additive keys | False regressions | JSON Schema only constrains viewer row objects; family tests use regex on unchanged strings |
| Staleness blocking in docs-contract | Violates D-17 | Staleness only in `validate` Mix task, not ExUnit |
| Hex package missing `priv/schemas` | Schema not shipped | Track for release phase; not Phase 68 blocker |
| ARCHITECTURE doc stale deferral pattern | Wrong implementation | Update Pattern 1 during Phase 68 (D-05) |

---

## 10. Validation Architecture

Nyquist mapping: how each success criterion and requirement is verified.

### ROADMAP Phase 68 success criteria

| # | Criterion | Verification | Command / evidence |
|---|-----------|--------------|-------------------|
| 1 | `list` categorizes all cells, no schema errors | Mix task test + manual | `mix rendro.viewer_evidence list` → 26 rows, 5/21/0 split; `mix test test/mix/tasks/viewer_evidence_task_test.exs` |
| 2 | `missing` reports silent `unverified` | Exit code + count | `mix rendro.viewer_evidence missing; echo $?` → **1**; output lists **21** cells |
| 3 | Docs-contract fails on drafted violations | Fixture subtests | `mix test test/docs_contract/viewer_evidence_claims_test.exs` includes negative cases |
| 4 | Non-additive matrix mutation fails JSV | Fixture subtest | Inject row with forbidden key → `Validator` returns error |
| 5 | Existing lanes still pass | Full docs contract | `mix docs.contract` → 8/8 PASS |

### Requirement traceability

| ID | Verification |
|----|----------------|
| **MATRIX-01** | JSV enum includes `explicit_deferral`; fixture test: deferral row requires `evidence_deferred`, forbids `evidence` |
| **MATRIX-02** | Schema allows optional `evidence`, `recorded_at`, `viewer_kind` on `supported`; fixture promotion-complete test |
| **MATRIX-03** | JSV validates production matrix + negative fixture tests; lane in CI via `verify_docs.exs` |
| **RECIPE-02** | `mix rendro.viewer_evidence` subcommands + task tests; manual smoke: list/validate/missing |
| **RECIPE-04** | `viewer_evidence_claims_test.exs` negative fixtures + orphan scan on production tree |
| **GUARDRAIL-01** | `Lint.deferral_reason/1` + docs-contract forbidden vocabulary cases |
| **GUARDRAIL-03** | `viewer_row.additionalProperties: false` + JSV negative test for extra keys |
| **GUARDRAIL-04** | `Lint.evidence_body/1`, byte size check, docs-contract secret/path/image cases |

### Test commands (phase completion checklist)

```bash
# Dependencies
mix deps.get

# Unit + integration
mix test test/rendro/viewer_evidence/
mix test test/mix/tasks/viewer_evidence_task_test.exs
mix test test/docs_contract/viewer_evidence_claims_test.exs

# Eighth lane + full docs contract
mix run scripts/verify_docs.exs
mix docs.contract

# Operator smoke (unchanged matrix)
mix rendro.viewer_evidence list
mix rendro.viewer_evidence missing; test $? -eq 1
mix rendro.viewer_evidence validate; test $? -eq 0

# Regression: prior lanes untouched
mix test test/docs_contract/protection_claims_test.exs
mix test test/docs_contract/forms_claims_test.exs
mix test test/docs_contract/signing_claims_test.exs
mix test test/docs_contract/embedded_artifact_claims_test.exs

# CI-shaped (optional local)
mix ci
```

### Grep patterns (audit / code review)

| Intent | Pattern |
|--------|---------|
| Eighth lane registered | `Viewer evidence semantic-claims lane` in `scripts/verify_docs.exs` |
| No new CI job | absence of `viewer-evidence` in `.github/workflows/ci.yml` |
| JSV dep scoped | `{:jsv, "~> 0.18", only: [:dev, :test], runtime: false}` in `mix.exs` |
| No runtime viewer module | absence of `Rendro.Support.ViewerEvidence` |
| Shared validator | `Rendro.ViewerEvidence.Validator` referenced from mix task **and** docs-contract test |
| Matrix unchanged | `git diff priv/support_matrix.json` empty at phase end |
| explicit_deferral enum | `"explicit_deferral"` in `priv/schemas/support_matrix.schema.json` |
| Byte budget documented | `65536` in schema description, `@moduledoc`, or `Lint` |
| Task not in mix ci | absence of `rendro.viewer_evidence` in `mix.exs` `:ci` alias |

---

## 11. Open questions for planner

1. **Tier A/B enforcement split (BLOCKER):** Confirm phased strictness for `supported` without `evidence` — recommended: advisory on production matrix in Phase 68, strict in Phase 70 when five legacy rows are consolidated. Reconcile explicit wording in D-04/D-22 vs phase boundary.

2. **`ymlr` vs `yaml_elixir` (BLOCKER):** D-12 says `ymlr` for parse; Hex shows encode-only. Plan should specify `yaml_elixir` for decode; drop or repurpose `ymlr`.

3. **`mix validate` exit code on legacy supported rows:** D-22 says fail; phase boundary says pass unchanged matrix. Pick: warnings + exit 0 (recommended) vs hard fail with grandfather allowlist of five cells.

4. **`recorded_at` equality:** When both matrix and frontmatter present, require exact match (recommended in D discretion) or allow matrix ≥ frontmatter?

5. **Mix task file path:** `lib/mix/tasks/rendro/viewer_evidence.ex` (CONTEXT) vs `lib/mix/tasks/rendro.viewer_evidence.ex` (existing convention)?

6. **JSV schema authoring style:** Raw JSON files vs `use JSV.Schema` modules — JSON files match “schema as published contract” from STACK.md.

7. **Cell count documentation:** Research counts **26** viewer cells (includes `signature_widget_viewers`); SUMMARY.md says 24 — align docs when updating ARCHITECTURE.

8. **`_template.md` in orphan scan:** Confirm exclusion pattern (`_`-prefixed paths or explicit allowlist).

9. **Deferral vague-viewer lint (D-16):** “vague viewer phrases without named viewer/issue token” needs concrete regex/heuristic list in plan — e.g. require `\b(pdf\.js|Preview|Acrobat|PDFium|#\d+|mozilla/)\b` case-insensitive or similar.

10. **Package `files` for `priv/schemas` and `priv/viewer_evidence`:** Defer to release Phase 72 or handle when first evidence ships in Phase 69?

---

## RESEARCH COMPLETE
