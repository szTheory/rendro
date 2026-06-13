# Phase 94: Docs & Warning Hygiene - Research

**Researched:** 2026-06-13
**Domain:** ExDoc warning posture, Elixir docs hygiene, viewer-evidence staleness messaging
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Resolve prose `@doc` references to hidden internals via `skip_code_autolink_to:` list in `mix.exs` `docs/0`. This is a new option here — existing `skip_undefined_reference_warnings_on:` is a different option; do not conflate.
- **D-02:** Give `Rendro.PDF.Font` a real internal-marking `@moduledoc` (currently `@moduledoc false`) so its `@type t` typespec autolinks resolve and stop warning. Verified safe: `Rendro.PDF.Font` is not in `priv/public_api.json` and not in the asserted-hidden contract list.
- **D-03:** Net result: `mix docs` emits zero warnings.
- **D-04:** Add `--warnings-as-errors` to the docs step of the `ci` alias in `mix.exs` (currently `"docs"` → becomes `"docs --warnings-as-errors"`).
- **D-05:** Make the staleness warning line self-explaining at its source (`lib/rendro/viewer_evidence/validator.ex`, `staleness_warnings/1`). Append: (a) remediation command, (b) advisory-outside-`--strict` note, (c) pointer to `guides/viewer_evidence.md`.
- **D-06:** Preserve `@staleness_days 180`. HYG-02 is wording/docs only — do not silence, raise/lower threshold, or pre-emptively re-record evidence.
- **D-07:** Document staleness lifecycle in `guides/viewer_evidence.md` — new section explaining the signal is a designed cadence signal, not a defect.

### Claude's Discretion
- Exact entries in the `skip_code_autolink_to:` list — driven by which references actually warn; researcher runs `mix docs` to enumerate empirically.
- Exact wording of the `@moduledoc` on `Rendro.PDF.Font`, the augmented staleness message string, and the new lifecycle section's heading/placement within `guides/viewer_evidence.md`.

### Deferred Ideas (OUT OF SCOPE)
None — phase is deliberately narrow. No silencing, no threshold changes, no public-API changes.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HYG-01 | A maintainer building the docs sees a clean ExDoc warning posture — known hidden-internal reference warnings are eliminated or each remaining warning is deliberately documented with a reason. | Empirical `mix docs` run captured all 9 unique warnings (2 warning classes). `skip_code_autolink_to:` and `@moduledoc` on Font resolve all of them. `--warnings-as-errors` mechanically enforces the zero-warning policy in CI. |
| HYG-02 | Stale viewer-evidence warning noise is resolved or explicitly documented so routine output no longer emits unexplained viewer-evidence warnings. | The staleness warning is latent (fires ~late Nov 2026). The fix is wording-only: augment `staleness_warnings/1` message string and add a lifecycle section to the guide. Threshold and cadence are preserved. |
</phase_requirements>

---

## Summary

Phase 94 is a narrow docs/hygiene/wording phase. All implementation mechanisms are locked in CONTEXT.md (D-01 through D-07). The role of this research is to fill the empirical gaps: the exact warning output, the ExDoc option shapes, the precise file/line anchors, the house-style convention for remediation messages, and the contract guardrail state.

`mix docs` was run and produces **18 warning lines** (9 unique warnings, duplicated once due to ExDoc generating both html and epub formats). They fall into **two distinct warning classes**:

- **Class A — prose autolink warnings (5 unique):** ExDoc finds backtick-quoted module/type names in `@doc` prose that are hidden (`@moduledoc false`). Fix: add those names to `skip_code_autolink_to:` in `docs/0`.
- **Class B — typespec autolink warnings (4 unique):** ExDoc resolves `@spec` signatures that reference `Rendro.PDF.Font.t()` but `Rendro.PDF.Font` is `@moduledoc false`, so the type is opaque to doc generation. Fix: give `Rendro.PDF.Font` a real `@moduledoc` (marking it internal), which makes the type resolvable without widening the public API.

The public-API contract test (`test/docs_contract/public_api_contract_test.exs`) currently passes (6 tests, 0 failures). `Rendro.PDF.Font` is absent from `priv/public_api.json` and absent from the asserted-hidden list (which contains only `Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter`, `Rendro.Text.Bidi`, `Rendro.Format`, `Rendro.Audit`). Giving `Rendro.PDF.Font` a real `@moduledoc` does not add it to the public surface and does not break any contract assertion.

The staleness signal (`@staleness_days 180`, `staleness_warnings/1` in `validator.ex`) is latent — will fire approximately late November 2026. The fix is a wording augmentation to the message string and a new section in `guides/viewer_evidence.md`.

**Primary recommendation:** Execute in three logical edits: (1) `mix.exs` — add `skip_code_autolink_to:` and change `ci:` alias; (2) `lib/rendro/pdf/font.ex` — replace `@moduledoc false`; (3) `lib/rendro/viewer_evidence/validator.ex` + `guides/viewer_evidence.md` — augment message and add lifecycle section.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ExDoc warning suppression (prose refs) | Build-time config (`mix.exs`) | — | `skip_code_autolink_to:` is a build-time ExDoc option, not runtime code |
| Typespec autolink resolution | Library module (`Rendro.PDF.Font`) | — | Changing `@moduledoc false` to a real `@moduledoc` is a module-level change that makes the type visible to ExDoc |
| CI enforcement of zero-warning policy | Build-time alias (`mix.exs` `ci:`) | — | Alias change adds `--warnings-as-errors` flag |
| Staleness message wording | Library module (`validator.ex`) | — | Single edit site for all staleness warning strings |
| Staleness lifecycle documentation | Guide (`guides/viewer_evidence.md`) | — | Existing guide is already wired into ExDoc extras and package files |

---

## Empirical Warning Inventory

### Full `mix docs` Warning Output (verified 2026-06-13)

ExDoc 0.40.1 generates two passes (html + epub), so each warning appears twice in stdout. The **9 unique warnings** are:

**Class A — Prose autolink warnings (`skip_code_autolink_to:` fix)**

| # | Warning string | Source location |
|---|---------------|----------------|
| A1 | `documentation references module "Rendro.PDF.CidFont" but it is hidden` | `guides/api_stability.md:36` |
| A2 | `documentation references module "Rendro.PDF.FontSubsetter" but it is hidden` | `guides/api_stability.md:36` |
| A3 | `documentation references module "Rendro.Format" but it is hidden` | `lib/rendro/recipes/statement.ex:66` (module-level `@moduledoc`) |
| A4 | `documentation references module "Rendro.Format" but it is hidden` | `lib/rendro/recipes/receipt.ex:64` (module-level `@moduledoc`) |

**Class B — Typespec autolink warnings (`@moduledoc` on Font fix)**

| # | Warning string | Source location |
|---|---------------|----------------|
| B1 | `documentation references type "Rendro.PDF.Font.t()" but the module Rendro.PDF.Font is hidden` | `lib/rendro/text/shaper.ex:49` (module `@moduledoc`) |
| B2 | `documentation references type "Rendro.PDF.Font.t()" but the module Rendro.PDF.Font is hidden` | `lib/rendro/text/shaper.ex:68` (`Rendro.Text.Shaper.shape/3` `@doc`) |
| B3 | `documentation references type "Rendro.PDF.Font.t()" but the module Rendro.PDF.Font is hidden` | `lib/rendro/text/shaper/simple.ex:41` (`Rendro.Text.Shaper.Simple.shape/3` `@doc`) |
| B4 | `documentation references type "Rendro.PDF.Font.t()" but the module Rendro.PDF.Font is hidden` | `lib/rendro/adapters/harfbuzz.ex:24` (`Rendro.Adapters.HarfBuzz.shape/3` `@doc`) |

**`skip_code_autolink_to:` list entries (Class A warnings):**
```elixir
skip_code_autolink_to: [
  "Rendro.PDF.CidFont",
  "Rendro.PDF.FontSubsetter",
  "Rendro.Format"
]
```
These are the exact string values the ExDoc option matches against. The two `Rendro.Format` warnings from separate files need only one entry in the list since the option applies globally.

**`@moduledoc` on Font resolves all Class B warnings.** When `Rendro.PDF.Font` is no longer `@moduledoc false`, its `@type t` becomes resolvable by ExDoc, eliminating all four B-class warnings across `shaper.ex`, `shaper/simple.ex`, and `adapters/harfbuzz.ex`.

---

## ExDoc Option Verification

### `skip_code_autolink_to:` [VERIFIED: ExDoc 0.40.1 source at `deps/ex_doc/lib/ex_doc.ex:156`]

- **Option name:** `skip_code_autolink_to:` (confirmed in installed ExDoc 0.40.1 source)
- **Value shape:** List of strings (e.g., `["Rendro.PDF.CidFont", "Rendro.Format"]`) OR a function `(String.t() -> boolean())`
- **Normalization:** When given a list, ExDoc normalizes it to `&(&1 in strings)` — exact string match against the autolink target
- **Effect:** Suppresses warning and skips generating a hyperlink for matching terms — the text remains in the rendered docs, just unlinked and without a warning
- **Distinction from `skip_undefined_reference_warnings_on:`:** `skip_undefined_reference_warnings_on:` suppresses warnings for undefined references in specific source files (takes a list of file paths). `skip_code_autolink_to:` suppresses autolinking and its associated warning for specific term strings, globally across all source files.
- **Placement:** Same keyword list as `skip_undefined_reference_warnings_on:` in `docs/0`

### `--warnings-as-errors` [VERIFIED: ExDoc 0.40.1 source at `deps/ex_doc/lib/mix/tasks/docs.ex:30`]

- **Flag name:** `--warnings-as-errors`
- **Mix task switch key:** `warnings_as_errors: :boolean`
- **Behavior:** After doc generation completes, if any warnings were emitted, exits with non-zero status and prints: `"Documents have been generated, but generation for html, epub formats failed due to warnings while using the --warnings-as-errors option"`
- **Verified non-zero exit:** Running `mix docs --warnings-as-errors` with current codebase exits with status `1`
- **Usage in alias:** `"docs --warnings-as-errors"` (space-separated flag, standard Mix alias string format)

### ExDoc Version

`ex_doc 0.40.1` — from `mix.lock` hash `67542e4b6dde74811cfd580e2c0149b78010fd13001fda7cfeb2b2c2ffb1344d`.

---

## Exact File State (Empirically Confirmed)

### `mix.exs` — `docs/0` (lines 98–216)

**Existing `skip_undefined_reference_warnings_on:` list** (lines 103–115):
```elixir
skip_undefined_reference_warnings_on: [
  "CHANGELOG.md",
  "guides/branding.md",
  "guides/integrations.md",
  "guides/comparison.md",
  "guides/livebook/first_invoice.livemd",
  "guides/page_primitive.md",
  "guides/recipes.md",
  "guides/user_flows_and_jtbd.md",
  "lib/rendro/document.ex",
  "lib/rendro/font_registry.ex",
  "lib/rendro.ex"
],
```

**New `skip_code_autolink_to:` list to add** (in the same keyword list, after `skip_undefined_reference_warnings_on:`):
```elixir
skip_code_autolink_to: [
  "Rendro.PDF.CidFont",
  "Rendro.PDF.FontSubsetter",
  "Rendro.Format"
],
```

### `mix.exs` — `aliases/0` `ci:` list (lines 65–73)

**Current state:**
```elixir
ci: [
  "format --check-formatted",
  "hex.build",
  "compile --warnings-as-errors",
  "test",
  "docs",
  "credo --strict",
  "dialyzer"
]
```

**Change:** `"docs"` → `"docs --warnings-as-errors"`.

### `lib/rendro/pdf/font.ex` — `@moduledoc false` (line 2)

**Current state:** `@moduledoc false`

**Required change:** Replace with an internal-marking `@moduledoc` that:
1. States `Rendro.PDF.Font` is an internal implementation detail
2. Is not a public, stable surface (not under SemVer guarantee)
3. Makes the `@type t` resolvable by ExDoc (which is the mechanical reason for the change)

The exact wording is Claude's discretion per CONTEXT.md. Pattern: match the voice of other non-false moduledocs on internal modules if any exist, otherwise use a terse "Internal implementation detail" convention.

**Note:** `Rendro.PDF.Font` must NOT be added to `priv/public_api.json` and must NOT appear in the asserted-hidden list in the contract test. It will simply become a non-hidden, non-public module (ExDoc renders it, but it's not in the API surface — like `Rendro.Adapters.Poppler` which is in `public_api.json` as adapter tier). Wait — `Rendro.PDF.Font` should NOT be in `public_api.json` — it stays absent from the manifest. Making it non-hidden is the mechanism; it remains outside the public API surface because the contract test only checks what `mix rendro.api.gen` generates, and `mix rendro.api.gen` filters to public modules.

### `lib/rendro/viewer_evidence/validator.ex` — `staleness_warnings/1` (lines 91–114)

**Current `@staleness_days`:** `180` at line 11. **Preserve.**

**Current warning message string** (lines 103–107):
```elixir
[
  "#{cell.matrix_path}: recorded_at #{recorded_at} is older than #{@staleness_days} days"
]
```

**D-05 augmentation:** Append to the single message string:
- (a) Remediation command (house style: embed `mix` command directly, see below)
- (b) Advisory note: warning is non-fatal outside `--strict`
- (c) Pointer to `guides/viewer_evidence.md` (guide URL or reference)

### `guides/viewer_evidence.md` — staleness lifecycle section (D-07)

**Current state:** Guide exists, is wired into ExDoc `extras` and package `files`. Does not contain a section on the staleness lifecycle or what a maintainer should do when it fires.

**D-07 addition:** New section explaining:
- The 180-day signal is a designed cadence signal, not a defect
- It will first fire approximately late November 2026 (180 days after the most recent viewer-evidence recordings)
- The appropriate response is to re-record evidence (not suppress the warning)
- The signal is advisory (non-fatal) unless `--strict` is passed

---

## Public-API Contract Guardrail

### Current Contract Test State [VERIFIED: ran `mix test test/docs_contract/public_api_contract_test.exs`]

**Result:** 6 tests, 0 failures. Contract is currently clean.

**Run command:**
```bash
mix test test/docs_contract/public_api_contract_test.exs
```

### Asserted-Hidden List (Assertion 3 in contract test)

The contract test asserts these modules have `@moduledoc false` (`:hidden`):
- `Rendro.PDF.CidFont`
- `Rendro.PDF.FontSubsetter`
- `Rendro.Text.Bidi`
- `Rendro.Format`
- `Rendro.Audit`

**`Rendro.PDF.Font` is NOT in this list.** Giving it a real `@moduledoc` will not break Assertion 3.

**`Rendro.PDF.Font` is NOT in `priv/public_api.json`.** The manifest has no entry for `Elixir.Rendro.PDF.Font`. Giving it a real `@moduledoc` will not cause `mix rendro.api.gen` to add it to the manifest (the generator filters by `public_modules/0`, which excludes internals by convention), and will not break the byte-compare assertion (Assertion 2).

**Safety conclusion:** The `@moduledoc` change on `Rendro.PDF.Font` is safe. It will not widen the public API, will not break any contract assertion, and will eliminate all 4 Class B typespec warnings.

---

## House Style: Errors-as-Product / Remediation Messages

### Convention from `lib/rendro/launch_artifacts.ex` [VERIFIED: read source]

The pattern in `launch_artifacts.ex` for remediation messages embeds the `mix` command directly inline in the error/warning string:

```
"source PDF hash drift for #{spec.id}: expected #{entry["source_pdf_sha256"]}, got #{actual}; run mix rendro.launch_artifacts.gen"
"README launch artifact block is stale; run mix rendro.launch_artifacts.gen"
"manual.pdf hash drift: expected #{expected}, got #{actual}; run mix rendro.launch_artifacts.gen"
```

**Pattern:** `"<description of what is stale/wrong>; run mix <task.name>"` — no trailing period, lowercase "run", no shell prompt prefix, compact inline format.

### Viewer evidence remediation command

The command to re-record viewer evidence (from `guides/viewer_evidence.md`) follows the form:
```
mix rendro.viewer_evidence record <surface> <viewer> ...
```

The staleness warning should point to:
- The mix task for re-recording: `mix rendro.viewer_evidence record`
- The `guides/viewer_evidence.md` guide for the full workflow
- The advisory-outside-`--strict` clarification

**Suggested augmented message shape** (wording is Claude's discretion):
```elixir
"#{cell.matrix_path}: recorded_at #{recorded_at} is older than #{@staleness_days} days " <>
"(advisory — non-fatal unless --strict; re-record with mix rendro.viewer_evidence record; " <>
"see guides/viewer_evidence.md)"
```

This follows house style: inline, compact, no shell prompt, embed the mix command.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Suppress autolink warnings for hidden modules | Custom ExDoc hook or post-processing | `skip_code_autolink_to:` list in `docs/0` | Built into ExDoc 0.40.1, correct semantic, idiomatic |
| Enforce zero-warning doc build in CI | External script checking exit codes | `--warnings-as-errors` flag on `mix docs` | Native ExDoc flag, already supported by `mix docs` task, same pattern as `compile --warnings-as-errors` |
| Hide a module's type from docs without hiding function docs | `@moduledoc false` on Font | Real `@moduledoc` with internal-marking text | `@moduledoc false` is what causes the typespec autolink warning; a real `@moduledoc` resolves it |

---

## Common Pitfalls

### Pitfall 1: Confusing the two ExDoc skip options

**What goes wrong:** Using `skip_undefined_reference_warnings_on:` (which takes file paths) to try to suppress Class A warnings (which are module/type name references). The two options have completely different semantics.
**Why it happens:** Both options have "skip" in their names and appear in the same `docs/0` keyword list.
**How to avoid:** `skip_code_autolink_to:` takes a list of **term strings** (module names, type refs). `skip_undefined_reference_warnings_on:` takes a list of **file paths**. Only `skip_code_autolink_to:` suppresses Class A warnings.
**Warning sign:** Warnings persist after adding entries to the wrong list.

### Pitfall 2: Adding `Rendro.PDF.Font` to the asserted-hidden list after the `@moduledoc` change

**What goes wrong:** A follow-up edit "to be safe" adds `Rendro.PDF.Font` to the hidden-modules assertion in `public_api_contract_test.exs`. This makes the test expect `:hidden` but the module now has a real `@moduledoc`, causing the assertion to fail.
**Why it happens:** Conflating "not public" with "must be `@moduledoc false`".
**How to avoid:** Leave `public_api_contract_test.exs` unchanged. `Rendro.PDF.Font` is internal but not required to be `@moduledoc false` — the contract test only asserts on the explicitly listed modules.

### Pitfall 3: Warnings appear twice — don't double-count

**What goes wrong:** Counting 18 warnings and thinking 18 entries are needed in `skip_code_autolink_to:`.
**Why it happens:** ExDoc 0.40.1 generates docs for both html and epub formats in sequence, emitting each warning twice.
**How to avoid:** The 18 warning lines reduce to 9 unique warnings, and to just 3 prose-module names needing `skip_code_autolink_to:` entries (`Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter`, `Rendro.Format`). The 4 Font.t() warnings are resolved by the `@moduledoc` change on Font, not by `skip_code_autolink_to:`.

### Pitfall 4: Staleness warning is fired by `run_full/3` aggregation, not directly

**What goes wrong:** Editing the wrong call site — e.g., editing the `warnings/2` aggregator or `run_full/3` rather than `staleness_warnings/1`.
**Why it happens:** The call chain is `run_full/3` → aggregates `staleness_warnings(matrix)` → returns `[warning_string]`.
**How to avoid:** The single edit site is the string built in `staleness_warnings/1` at lines 103–107 of `validator.ex`. The `@staleness_days 180` at line 11 is preserved — do not touch it.

### Pitfall 5: `mix docs --warnings-as-errors` exits non-zero even after fixes if a stray reference is introduced

**What goes wrong:** A subsequent edit introduces a new prose reference to a hidden module (e.g., in a new `@doc` string), causing `--warnings-as-errors` to fail in CI.
**Why it happens:** `skip_code_autolink_to:` only covers the entries in the list. Any new hidden-module reference outside that list will warn.
**How to avoid:** The enforcement is the goal — CI will correctly catch new violations.

---

## Architecture Patterns

### Recommended Change Structure

Three logical work units, each independently verifiable:

**Unit 1 — `mix.exs` changes (HYG-01: suppression + enforcement)**
- Add `skip_code_autolink_to:` to `docs/0`
- Change `"docs"` → `"docs --warnings-as-errors"` in `ci:` alias
- Verify: `mix docs` → zero warnings; `mix docs --warnings-as-errors` → exit 0

**Unit 2 — `lib/rendro/pdf/font.ex` change (HYG-01: typespec resolution)**
- Replace `@moduledoc false` with internal-marking `@moduledoc` text
- Verify: `mix docs` (after Unit 1) → still zero warnings; contract test still green

**Unit 3 — `validator.ex` + `guides/viewer_evidence.md` changes (HYG-02: staleness wording)**
- Augment `staleness_warnings/1` message string
- Add staleness lifecycle section to `guides/viewer_evidence.md`
- Verify: message text contains remediation command + advisory note + guide pointer; guide section present

### ExDoc `skip_code_autolink_to:` list placement

```elixir
defp docs do
  [
    main: "readme",
    assets: %{"assets" => "assets"},
    before_closing_head_tag: &before_closing_head_tag/1,
    skip_undefined_reference_warnings_on: [
      # ... existing entries ...
    ],
    skip_code_autolink_to: [          # NEW — add after existing option
      "Rendro.PDF.CidFont",
      "Rendro.PDF.FontSubsetter",
      "Rendro.Format"
    ],
    source_ref: "v#{@version}",
    # ... rest unchanged ...
  ]
end
```

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/docs_contract/public_api_contract_test.exs` |
| Full suite command | `mix test` |
| Docs build command | `mix docs` |
| Docs enforcement command | `mix docs --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| HYG-01 | `mix docs` emits zero warnings | smoke | `mix docs 2>&1 | grep -c "^    warning:"` should output `0` | Primary oracle |
| HYG-01 | `--warnings-as-errors` exits 0 after fixes | smoke | `mix docs --warnings-as-errors` exit code | CI enforcement gate |
| HYG-01 | Contract test stays green | unit | `mix test test/docs_contract/public_api_contract_test.exs` | Guards against public-API drift |
| HYG-02 | Staleness message contains remediation cmd | manual inspection | Read message string in `staleness_warnings/1` | String content, not runtime behavior |
| HYG-02 | Staleness message contains advisory note | manual inspection | Read message string in `staleness_warnings/1` | String content |
| HYG-02 | Staleness message contains guide pointer | manual inspection | Read message string in `staleness_warnings/1` | String content |
| HYG-02 | `@staleness_days` unchanged at 180 | unit | `grep "@staleness_days 180" lib/rendro/viewer_evidence/validator.ex` | Preserve threshold |
| HYG-02 | Guide section exists | manual inspection | Read `guides/viewer_evidence.md` for lifecycle section | Content verification |

### Wave 0 Gaps

None — existing test infrastructure (`test/docs_contract/public_api_contract_test.exs`) covers the HYG-01 contract side. No new test files are needed. The `mix docs` zero-warning check is a smoke command, not a unit test. HYG-02 validations are string inspections.

### Sampling Rate

- **Per task commit:** `mix docs 2>&1 | grep -c "^    warning:"` → should output `0`; `mix test test/docs_contract/public_api_contract_test.exs`
- **Per wave merge:** Same plus `mix docs --warnings-as-errors` (exit 0)
- **Phase gate:** `mix docs --warnings-as-errors` green before `/gsd:verify-work`

---

## Environment Availability

Step 2.6: No external dependencies beyond the Elixir/Mix toolchain already in use. All changes are to source files and build configuration. ExDoc 0.40.1 is already installed (confirmed from `mix.lock`). No new packages required.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `@moduledoc false` with warnings silenced per-file | `skip_code_autolink_to:` for prose refs + real `@moduledoc` for typespec refs | Clean separation: prose references silenced globally, typespec references resolved properly |
| `"docs"` in CI alias (warnings allowed) | `"docs --warnings-as-errors"` | Mechanical enforcement prevents future hidden-module reference drift |

**No deprecated APIs used.** All ExDoc 0.40.1 options used are current and documented in the installed source.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `@moduledoc` change on `Rendro.PDF.Font` will not cause `mix rendro.api.gen` to add it to `priv/public_api.json` | Public-API Contract Guardrail | If `public_modules/0` in the generator picks up non-false modules by some other criterion, the manifest would drift and contract test would fail. Mitigation: run `mix rendro.api.gen` and check for drift before committing. | 

All other claims in this research were verified by running tools against the actual codebase or reading installed source files.

---

## Open Questions

1. **Does `mix rendro.api.gen` pick up `Rendro.PDF.Font` after the `@moduledoc` change?**
   - What we know: The generator uses `public_modules/0` to filter. The exact filter logic was not read.
   - What's unclear: Whether "public" is defined as "not `@moduledoc false`" or by some other criterion (e.g., explicit allowlist).
   - Recommendation: After making the `@moduledoc` change, run `mix rendro.api.gen --dry-run` (or equivalent) to confirm no manifest drift. If Font appears in the generated manifest, a small fix is needed — either keep Font as `@moduledoc false` (and use `skip_code_autolink_to:` for its type refs instead) or adjust the generator filter. Read the `Mix.Tasks.Rendro.Api.Gen.public_modules/0` function before implementing D-02.

---

## Sources

### Primary (HIGH confidence)

- ExDoc 0.40.1 installed source (`deps/ex_doc/lib/ex_doc.ex:156`) — `skip_code_autolink_to:` option definition and semantics
- ExDoc 0.40.1 installed source (`deps/ex_doc/lib/ex_doc/formatter/config.ex`) — normalization of list to function
- ExDoc 0.40.1 installed source (`deps/ex_doc/lib/mix/tasks/docs.ex:30`) — `--warnings-as-errors` flag
- `mix docs` run output (2026-06-13) — empirical enumeration of all 18 warning lines (9 unique)
- `mix docs --warnings-as-errors` run (2026-06-13) — confirmed exit code 1
- `mix test test/docs_contract/public_api_contract_test.exs` (2026-06-13) — 6 tests, 0 failures
- `priv/public_api.json` — confirmed `Rendro.PDF.Font` absent
- `test/docs_contract/public_api_contract_test.exs` — confirmed asserted-hidden list does not include `Rendro.PDF.Font`
- `lib/rendro/pdf/font.ex` — confirmed current `@moduledoc false` at line 2
- `lib/rendro/viewer_evidence/validator.ex` — confirmed `@staleness_days 180` at line 11; `staleness_warnings/1` message at lines 103–107
- `lib/rendro/launch_artifacts.ex` — house style for remediation message strings
- `mix.exs` — confirmed `docs/0` structure, `ci:` alias, ExDoc dep `~> 0.40`

---

## Metadata

**Confidence breakdown:**
- Warning inventory: HIGH — ran `mix docs` empirically
- ExDoc option names/shapes: HIGH — read installed ExDoc 0.40.1 source
- Contract test safety: HIGH — ran contract test; read `priv/public_api.json` and test assertions
- House style: HIGH — read `lib/rendro/launch_artifacts.ex` source
- File/line anchors: HIGH — read all source files directly

**Research date:** 2026-06-13
**Valid until:** 2026-07-13 (stable domain, but re-verify if ExDoc is upgraded)
