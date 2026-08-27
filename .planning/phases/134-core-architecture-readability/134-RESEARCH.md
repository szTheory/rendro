# Phase 134: Core Architecture & Readability - Research

**Researched:** 2026-08-26
**Domain:** Conservative internal Elixir refactoring, code removal, and documentation/specification accuracy under frozen public-API and rendered-byte contracts
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Finding Authority and Intake
- **D-01:** The canonical `.planning/QUALITY.md` currently contains no accepted Phase 134 finding; `QL-001` explicitly rejects compile-connected xref topology as a repair mandate. Planning must therefore begin with a bounded evidence-validation and ledger-disposition slice before any repair slice.
- **D-02:** Candidate intake is limited to explicit historical review findings and source-verifiable current facts. A candidate becomes repair work only after the ledger records concrete impact, confidence, compatibility risk, owner, scope, focused verification, trigger, and closure evidence.
- **D-03:** If validation does not demonstrate responsibility collision, change fan-out, duplication drift, misleading ownership, unsupported behavior, or testability cost, record `reject_signal` or a trigger-backed deferral. Do not manufacture work to make the phase non-empty.
- **D-04:** If no candidate survives the evidence gate, the truthful phase result is an evidence-backed no-op/closure. Diagnostic movement, lower line counts, or unrelated green tests are never substitute closure evidence.

### Candidate Priority
- **D-05:** Validate `Rendro.I18n.Analyzer` first. Current source search finds no `lib/` caller and only its isolated test module, while the Phase 83 summary explicitly recorded it as dead after the authoritative shaper gate replaced the preflight. If that remains true under xref/compile/test evidence, remove the module and tests as one bounded dead-code repair.
- **D-06:** Next, validate still-current historical duplication findings only when they represent one cohesive responsibility and a demonstrated drift surface. The leading candidates are recipe palette resolution duplicated across recipes and shaping-adapter hint construction duplicated between the simple shaper and error guidance. Research must confirm current semantics and characterize exact outputs before accepting either repair.
- **D-07:** Treat the large `Rendro.PDF.Writer`, `Rendro.Pipeline.Paginate`, recipe modules, and xref counts as investigation signals only. Do not split them unless a specific responsibility collision or maintenance cost is proven and the extraction can preserve the one-engine pipeline and exact output.
- **D-08:** Review runtime-source phase-number narration as a bounded truthfulness candidate. Rewrite only stale implementation-history shorthand; preserve phase/date references when they are current evidence provenance or immutable-history context.

### Change and Extraction Discipline
- **D-09:** Characterization precedes change. Each accepted repair gets focused tests that fail under the recorded defect, followed by the smallest cohesive change and focused re-verification.
- **D-10:** One repair concern per change set. Do not mix dead-code removal, helper extraction, docs/spec cleanup, broad renaming, formatting sweeps, dependency upgrades, test consolidation, CI topology changes, or catalog output changes.
- **D-11:** Shared helpers are justified by ownership, semantics, and drift prevention—not deduplicated line count alone. Preserve existing call boundaries and option precedence; do not introduce a second rendering or layout path.
- **D-12:** Freeze and compare `priv/public_api.json` and affected deterministic byte goldens around every product-code repair. All unrelated rendered outputs remain byte-identical; Phase 134 has no visual-output exception.

### Specifications, Documentation, and Comments
- **D-13:** Keep accurate public/stable and boundary specs. Keep a private spec only when it documents a non-obvious contract or materially improves Dialyzer; correct or remove misleading private specs with focused behavior coverage plus a clean Dialyzer result.
- **D-14:** Public module/function documentation must describe current behavior, failure shape, stability boundary, and truthful limitations. Documentation cleanup must not silently promote an internal module, alter the public manifest, or claim unsupported capability.
- **D-15:** Names and small functions explain mechanics. Comments explain invariants, ordering constraints, compatibility reasons, security/authority boundaries, or provenance. Remove line-by-line narration and rewrite stale phase-local shorthand into present-tense intent.
- **D-16:** Preserve provenance-bearing phase/date references in viewer evidence and historical compatibility seams when the provenance itself is operationally meaningful. The cleanup target is stale narration, not historical amnesia.

### Verification and Closure
- **D-17:** Each accepted ledger finding closes only with its predeclared focused proof, relevant full gate, compatibility evidence, before/after statement, and resolution reference. Update `.planning/QUALITY.md` through the finding lifecycle rather than treating a code commit as self-proving.
- **D-18:** The terminal deterministic evidence includes focused characterization tests, public API manifest byte identity, relevant recipe/render byte-identity tests, documentation warnings-as-errors, Credo, Dialyzer, and `mix ci.fast`. Advisory or human feedback may enrich evidence but cannot block or substitute for deterministic closure.
- **D-19:** Planning must explicitly map each proposed task to ARCH-01 through ARCH-04 and to a ledger finding/disposition. Unaccepted observations may be investigated, rejected, or deferred, but not repaired opportunistically.

### the agent's Discretion
- Choose exact internal helper names and plan boundaries after current-code research, provided every code-changing task names its accepted ledger finding, cohesive responsibility, characterization proof, and compatibility proof.
- Decide whether a validated duplication candidate merits extraction or documented rejection. Prefer no change when the maintenance benefit is not demonstrable.

### Deferred Ideas (OUT OF SCOPE)
- Behavior-changing fixes to custom-typography geometry budgets from the Phase 123 review require a new ledger finding and separately authorized rendered-byte scope; Phase 134 may not change those outputs.
- Test-fixture/test-suite consolidation, including the Phase 122 Payslip fixture duplication, belongs to Phase 135.
- Catalog visual changes and renderer-backed human review remain Phase 136 work and are not bundled with architecture cleanup.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ARCH-01 | The supported public API manifest and rendered bytes outside explicitly approved catalog targets remain unchanged throughout internal cleanup. | Existing public-manifest byte contract and the seven recipe byte-identity suites are the required compatibility boundary. [VERIFIED: repository tests] |
| ARCH-02 | Every accepted high-impact architecture, dead-code, dependency, duplication, and readability finding is repaired or rejected with evidence; bounded medium-impact findings follow the ledger disposition rules. | Begin with `.planning/QUALITY.md` lifecycle entries; the analyzer and palette candidates have concrete validation evidence, while xref, shaping fallback, large-module, and phase-narration signals need rejection/defer dispositions unless a specific defect is proven. [VERIFIED: `.planning/QUALITY.md`, current source] |
| ARCH-03 | A module or function is extracted only when the change creates a cohesive responsibility or measurable maintenance benefit, with characterization coverage; size alone is not sufficient justification. | The palette algorithm is an exact seven-call-site responsibility with frozen precedence; `Writer` and `Paginate` size/xref signals remain non-actionable. [VERIFIED: recipe source, Mix xref] |
| ARCH-04 | Public and boundary specs, module documentation, and explanatory comments accurately describe current behavior; stale narration and misleading private specifications are removed or corrected with documentation and Dialyzer proof. | Use a line-specific docs/spec/comment audit, preserve meaningful provenance, and treat ExDoc warnings-as-errors plus Dialyzer as the final proof. [VERIFIED: `134-CONTEXT.md`, `mix.exs`] |
</phase_requirements>

## Summary

[VERIFIED: repository ledger and source] Phase 134 is a conservative evidence-and-closure phase, not a general cleanup. The current canonical ledger has no accepted Phase 134 finding: `QL-001` rejects compile-connected xref topology as repair authority, and all current accepted findings belong to later phases. The first plan slice must therefore re-run the bounded evidence checks and record each candidate’s lifecycle disposition before product edits.

[VERIFIED: current source, xref, and focused tests] One removal candidate survives the evidence gate: `Rendro.I18n.Analyzer` has only its defining source file and isolated test references; it is absent from `priv/public_api.json`; `mix xref callers Rendro.I18n.Analyzer` produced no callers; and the Phase 83 summary records the active shaper gate as its replacement. The focused analyzer/public-contract suite passed (18 tests), so removal of the module and its test as one concern is supportable after the ledger accepts it.

[VERIFIED: current source] One extraction candidate is supportable only after characterization: five recipe `palette/1` bodies hash identically, while Statement and Certificate use the identical `theme`/override algorithm with recipe-specific no-theme defaults. The cohesive responsibility is palette resolution: `nil` uses the caller-provided legacy defaults, a supplied `:theme` resolves to `theme.colors`, and `:palette` wins via `Map.merge/2`. Extracting that algorithm into a private-by-documentation `Rendro.Recipes.Palette` helper prevents seven future precedence changes from drifting, without creating a render/layout path.

**Primary recommendation:** Plan a ledger-first slice, then only (1) remove the validated unused analyzer and (2) extract recipe palette resolution behind characterization tests; explicitly reject or defer all other current signals unless their bounded audit produces new evidence. [VERIFIED: repository ledger and source]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Finding intake, disposition, and closure | Repository governance | CI/test tooling | The quality ledger owns maintainer judgment; product code must not consume it. [VERIFIED: `.planning/QUALITY.md`, `134-CONTEXT.md`] |
| Dead-code removal | Core library | Test suite | The module and its isolated test are internal Elixir source; removal must preserve declared surface. [VERIFIED: current source and public manifest] |
| Palette resolution ownership | Core library recipe layer | Deterministic render tests | Recipes own legacy defaults; one internal helper owns resolution/precedence only. [VERIFIED: recipe source] |
| Public/spec/docs/comment accuracy | Core library and guides | ExDoc/Dialyzer | Documentation and type contracts describe the API boundary; tooling verifies they do not drift. [VERIFIED: `mix.exs`] |
| API and rendered-byte compatibility | Contract artifacts/tests | CI aggregate | `priv/public_api.json` and deterministic recipe goldens are the compatibility proof, not xref counts. [VERIFIED: repository tests, `134-CONTEXT.md`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Compile, xref, ExUnit, docs, and Mix aliases | The project’s declared runtime and verified local toolchain. [VERIFIED: `mix.exs`, `elixir --version`] |
| OTP | 28 | BEAM runtime | Project-declared runtime and verified local toolchain. [VERIFIED: `AGENTS.md`, `elixir --version`] |
| ExUnit | bundled with Elixir 1.19.5 | Focused characterization and compatibility tests | Existing test framework. [VERIFIED: existing test suite] |
| Credo / Dialyxir / ExDoc | project-locked Mix dependencies | Readability, type/spec, and documentation gates | Already present in `mix.exs` and the `ci.fast` alias. [VERIFIED: `mix.exs`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Rendro.Recipes.Pagination` | internal module | Existing pattern for a small cross-recipe helper | Use as the organizational analogue for a palette-only helper; do not extend it with unrelated layout behavior. [VERIFIED: `lib/rendro/recipes/pagination.ex`] |
| `mix xref` | Mix 1.19.5 | Caller and compile-dependency diagnostics | Use to corroborate source scans; it does not itself establish repair authority. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| A palette-only helper | General recipe base module or a renderer abstraction | Rejected: it would broaden responsibility and risks a second recipe/render path. [VERIFIED: `134-CONTEXT.md`] |
| Remove the analyzer | Retain it as a hidden future preflight utility | Rejected unless a current caller/contract is found: no production caller or manifest entry currently supports retention. [VERIFIED: current source, xref, public manifest] |
| Focused candidate dispositions | Module-size/xref cleanup quota | Rejected: `QL-001` and Mix documentation make xref a diagnostic input, not sufficient repair evidence. [VERIFIED: `.planning/QUALITY.md`; CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html] |

**Installation:** No package installation is authorized or required for Phase 134. [VERIFIED: `134-CONTEXT.md`, `mix.exs`]

## Architecture Patterns

### System Architecture Diagram

```text
Historical reviews + current source/xref/tests
                |
                v
      bounded candidate validation
                |
        +-------+--------+
        |                |
   insufficient       accepted finding
    evidence          in QUALITY.md
        |                |
        v                v
reject_signal /   characterization test
triggered defer           |
                            v
                  one cohesive repair
                            |
                            v
 public manifest + affected recipe byte goldens
                            |
                            v
 docs --warnings-as-errors + Credo + Dialyzer + mix ci.fast
                            |
                            v
       ledger closure with before/after and resolution reference
```

[VERIFIED: `.planning/QUALITY.md`, `134-CONTEXT.md`, `mix.exs`] This flow keeps the data-first render pipeline unchanged: both fixed-position and flow APIs continue to normalize into `build -> compose -> measure -> paginate -> render -> validate` and Phase 134 introduces no alternate rendering route.

### Recommended Project Structure

```text
lib/rendro/
├── recipes/
│   ├── palette.ex          # candidate internal resolution owner; only if ledger accepts extraction
│   ├── pagination.ex       # existing shared recipe helper analogue
│   └── *.ex                # recipe-specific defaults and call boundaries
├── text/shaper/simple.ex   # existing shaping producer; do not alter without accepted evidence
└── i18n/analyzer.ex        # candidate for removal with its isolated test
test/rendro/
├── recipes/palette_test.exs # Wave 0 characterization if extraction is accepted
└── i18n/analyzer_test.exs   # remove with Analyzer if dead-code proof holds
```

### Pattern 1: Ledger-gated, characterization-first repair

**What:** Record the candidate’s impact, scope, compatibility risk, focused proof, trigger, and closure evidence before changing product code. [VERIFIED: `.planning/QUALITY.md`]

**When to use:** Every candidate in this phase, including an evidence-backed no-op. [VERIFIED: `134-CONTEXT.md`]

**Example:**

```elixir
# Pseudocode pattern: the test proves old semantics before the extraction.
assert Palette.resolve([], legacy_defaults) == legacy_defaults
assert Palette.resolve(theme: theme, palette: %{ink: override}, legacy_defaults).ink == override
```

### Pattern 2: Recipe-owned defaults, shared resolution algorithm

**What:** Each recipe retains its legacy no-theme default map; one helper resolves theme colors and applies the current `:palette` override last. [VERIFIED: seven current `palette/1` implementations]

**When to use:** Only if the ledger accepts the demonstrated seven-site precedence-drift risk. [VERIFIED: `134-CONTEXT.md`]

**Example:**

```elixir
defp palette(opts), do: Rendro.Recipes.Palette.resolve(opts, @legacy_palette)

# Helper behavior, intentionally limited to resolution—not rendering or validation.
def resolve(opts, defaults) do
  base = if opts[:theme], do: Rendro.Theme.resolve(opts[:theme]).colors, else: defaults
  Map.merge(base, Keyword.get(opts, :palette, %{}))
end
```

### Pattern 3: Remove isolated dead code as an atomic concern

**What:** Delete the implementation and the test that solely specifies its unsupported private behavior, after proving no source, xref, public-manifest, guide, or package contract reference remains. [VERIFIED: current Analyzer scan]

**When to use:** `Rendro.I18n.Analyzer` only, unless a new finding passes the ledger gate. [VERIFIED: `134-CONTEXT.md`]

### Anti-Patterns to Avoid

- **Size-driven split:** Do not split `Rendro.PDF.Writer`, `Rendro.Pipeline.Paginate`, or recipes because they are large; neither xref nor line count proves an ownership failure. [VERIFIED: `QL-001`, `134-CONTEXT.md`]
- **Semantics “improvement” during extraction:** Do not normalize keyword-list palettes, validate new shapes, change `Map.merge/2` precedence, or alter theme defaults. Those are behavior changes outside the byte-frozen scope. [VERIFIED: current palette implementations, `134-CONTEXT.md`]
- **Broad history erasure:** Do not remove phase/date references that carry evidence provenance or compatibility rationale. [VERIFIED: `134-CONTEXT.md`, viewer-evidence source]
- **Helper as a new API:** Keep the candidate helper undocumented/internal and verify the checked-in public manifest remains byte-identical. [VERIFIED: public API contract tests]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Caller/dependency discovery | A custom source-only call graph | `rg` plus `mix xref callers` and xref graph as corroboration | Mix tracks compile/export/runtime references; source scan catches noncompiled/documentation references. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html] |
| Public API drift detection | An ad hoc API list | Existing `priv/public_api.json` regeneration/byte-equality contracts | The project has an authoritative manifest already. [VERIFIED: `lib/mix/tasks/rendro/api.gen.ex`, public API tests] |
| Render regression comparison | New PDF visual baseline tooling | Existing deterministic recipe byte-identity suites | The phase freezes unrelated rendered bytes and has no visual exception. [VERIFIED: `134-CONTEXT.md`, recipe tests] |
| Palette resolution | A new render abstraction | A narrow internal helper, if accepted | The only shared responsibility is pure option resolution. [VERIFIED: recipe source] |

**Key insight:** The valuable abstraction boundary here is evidence and pure resolution semantics—not a larger rendering architecture. [VERIFIED: `134-CONTEXT.md`, recipe source]

## Candidate Dispositions and Plan Boundaries

| Candidate | Current evidence | Recommended ledger disposition | Plan boundary and proof |
|-----------|------------------|--------------------------------|-------------------------|
| `Rendro.I18n.Analyzer` | No `lib/`, guide, or public-manifest reference beyond definition/test; compiled xref callers output is empty; Phase 83 records that the shaper gate replaced it. [VERIFIED: source scan, `mix xref callers`, Phase 83 summary] | Accept a bounded dead-code repair after re-checking the next permanent QL ID. | Remove `lib/rendro/i18n/analyzer.ex` and `test/rendro/i18n/analyzer_test.exs` together; prove no references, public-manifest byte identity, and focused shaping/error coverage. |
| Recipe `palette/1` | Invoice, Receipt, BrandedInvoice, Payslip, and Ticket bodies have the same SHA-256; Statement and Certificate preserve the same algorithm with different defaults. [VERIFIED: source-body hashes] | Accept only after Wave 0 characterization proves nil/theme/override behavior for every default-map shape. | Add a pure helper and migrate only the seven palette functions; run helper characterization plus every affected recipe byte-identity suite. |
| Simple-shaper/error fallback guidance | `Simple` is the only `lib/` producer and always returns the three-tuple with its context-sensitive hint; `Error` retains a two-tuple fallback that tests invoke directly. [VERIFIED: `simple.ex`, `error.ex`, tests] | `reject_signal` unless a current two-tuple producer or an inconsistent user-facing error is demonstrated. | Record the producer scan, relevant existing tests, and trigger: new producer or mismatch between emitted reason and guidance. No code edit. |
| Writer/Paginate/recipe size and five compile-connected edges | Current xref reports five compile dependencies and zero cycles; current ledger already rejects topology alone. [VERIFIED: `mix xref graph`; `.planning/QUALITY.md`] | Keep `QL-001` rejected; no new repair. | Record rerun evidence only. Trigger: a specific responsibility collision, compatibility break, or measured maintenance cost. |
| Runtime source phase-number narration | Current matches include feature/provenance comments, including viewer-evidence historical dates; no line-specific stale behavior claim was demonstrated in this research. [VERIFIED: current source scan] | Bounded audit then `reject_signal`/trigger-backed deferral unless it identifies a concrete misleading line. | Do not schedule a narration sweep. Each accepted line needs its own truthfulness assertion and docs/Dialyzer proof. |

## Common Pitfalls

### Pitfall 1: Treating diagnostic movement as closure

**What goes wrong:** A lower module count, fewer xref edges, or a green broad test suite is mistaken for architecture evidence. [VERIFIED: `.planning/QUALITY.md`]

**Why it happens:** Xref exposes recompilation relationships and line counts expose size; neither establishes a public-contract or maintenance harm by itself. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html]

**How to avoid:** Create/close a finding only with the predeclared impact and focused proof, then record the compatibility proof and before/after statement. [VERIFIED: `.planning/QUALITY.md`]

**Warning signs:** A task cannot name its QL finding, defect-specific test, or trigger for future reconsideration. [VERIFIED: `134-CONTEXT.md`]

### Pitfall 2: Palette extraction silently changes precedence or output

**What goes wrong:** The helper changes the nil default, resolves typography accidentally, or validates/converts `:palette`; rendered bytes or error behavior drift. [VERIFIED: current palette implementations]

**How to avoid:** Characterize default, supplied-theme, and supplied-override behavior first; pass each recipe’s existing map unchanged; retain `Map.merge(base, Keyword.get(opts, :palette, %{}))`. [VERIFIED: recipe source]

**Warning signs:** Any golden hash changes, a new public-manifest module/function appears, or `:palette` errors change. [VERIFIED: recipe/public-manifest contracts]

### Pitfall 3: Deleting a private module without checking indirect contract surfaces

**What goes wrong:** A compiled caller is absent but a guide, manifest, task, dynamic invocation, or package artifact still expects the module. [VERIFIED: Phase 134 constraints]

**How to avoid:** Combine `rg`, `mix xref callers`, manifest inspection, focused tests, and the full relevant deterministic gate. [VERIFIED: current validation results, `134-CONTEXT.md`]

### Pitfall 4: Removing useful provenance while “cleaning” comments

**What goes wrong:** A date/phase citation that explains an evidence boundary is erased, weakening documentation truthfulness. [VERIFIED: `134-CONTEXT.md`]

**How to avoid:** Edit only a demonstrated stale shorthand line; preserve provenance-bearing references in viewer evidence and compatibility seams. [VERIFIED: `134-CONTEXT.md`]

## Code Examples

### Analyzer removal characterization checklist

```bash
rg -n 'Rendro\.I18n\.Analyzer|I18n\.Analyzer' lib test guides README.md priv/public_api.json
mix xref callers Rendro.I18n.Analyzer
mix test test/rendro/public_api/manifest_test.exs test/docs_contract/public_api_contract_test.exs
```

[VERIFIED: current phase validation] At research time, the source scan found only the analyzer definition and its own test; xref printed no callers; the focused public-contract suite passed.

### Palette behavior matrix

```elixir
# Characterize before extraction for each legacy defaults map.
assert resolve([], defaults) == defaults
assert resolve(theme: theme, defaults) == Rendro.Theme.resolve(theme).colors
assert resolve([theme: theme, palette: %{ink: {1, 2, 3}}], defaults).ink == {1, 2, 3}
```

[VERIFIED: current recipe source] This matrix captures the existing branch and merge order. It intentionally does not alter invalid-palette behavior.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Preflight script analysis by `Rendro.I18n.Analyzer` | Authoritative shaping gate in `Rendro.Text.Shaper.Simple` / pipeline measurement | Phase 83 historical record | Analyzer is a removal candidate only after today’s reference proof. [VERIFIED: Phase 83 summary, current source] |
| Per-recipe pagination logic | `Rendro.Recipes.Pagination` owns existing shared row/format helper responsibilities | Existing repository pattern | Palette extraction should be similarly narrow, not a general recipe base class. [VERIFIED: `pagination.ex`, git history] |

**Deprecated/outdated:** The analyzer’s preflight role is obsolete if the current no-caller/public-surface proof remains true at execution. [VERIFIED: Phase 83 summary, current source]

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure; do not add a Phoenix, Oban, or admin-tooling dependency. [VERIFIED: `AGENTS.md`]
- Preserve deterministic and advisory verification-lane separation in CI and documentation. [VERIFIED: `AGENTS.md`]
- Completion coverage must be deterministic, advisory, or explicitly deferred; optional human feedback cannot block completion or substitute for objective evidence. [VERIFIED: `AGENTS.md`]
- Treat documentation claims as contracts; do not claim unsupported capabilities. [VERIFIED: `AGENTS.md`]
- Use optional dependency guards for integrations. [VERIFIED: `AGENTS.md`]
- Preserve the one-engine data-first pipeline and treat errors/telemetry as product behavior. [VERIFIED: `AGENTS.md`]
- File-changing implementation must run through the appropriate GSD execution workflow. [VERIFIED: `AGENTS.md`]

## Assumptions Log

All material recommendations are verified against repository-local evidence or cited official Mix documentation; no execution decision depends on an unverified assumption.

## Open Questions

1. **Does the palette characterization expose a recipe-specific behavior beyond the current resolution matrix?**
   - What we know: five bodies are byte-identical and the two variants differ only in legacy defaults. [VERIFIED: source-body hashes]
   - What's unclear: whether a focused test reveals an implicit caller reliance not represented by existing golden fixtures.
   - Recommendation: make this the first extraction Wave 0 gate; reject the extraction if characterization cannot be stated uniformly.

2. **Does the phase-number audit find a concrete misleading runtime claim?**
   - What we know: source matches include legitimate feature history and viewer-evidence provenance. [VERIFIED: current source scan]
   - What's unclear: whether any individual line is stale rather than provenance.
   - Recommendation: audit with a bounded ledger entry; do not create a broad doc/comment cleanup task without a line-specific defect.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | compile, test, xref, docs, CI aliases | ✓ | 1.19.5 | — [VERIFIED: local toolchain] |
| OTP | Elixir runtime | ✓ | 28 | — [VERIFIED: local toolchain] |
| Git | source/reference and manifest comparison | ✓ | repository `60164bb` at research | — [VERIFIED: local toolchain] |
| `pdfium-cli` | advisory/proof viewer work | ✗ | — | Not required for Phase 134 deterministic closure; retain deferred evidence lane. [VERIFIED: local command probe, `.planning/QUALITY.md`] |
| Poppler `pdftoppm` | existing local PDF tooling | ✓ | installed | Not required for Phase 134. [VERIFIED: local command probe] |

**Missing dependencies with no fallback:** None for the Phase 134 deterministic scope. [VERIFIED: phase constraints and local probes]

**Missing dependencies with fallback:** `pdfium-cli` remains explicitly unavailable advisory/proof evidence; it cannot block this phase or be substituted for deterministic closure. [VERIFIED: `.planning/QUALITY.md`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with Elixir 1.19.5 [VERIFIED: local toolchain and tests] |
| Config file | `test/test_helper.exs` [VERIFIED: repository] |
| Quick run command | `mix test <focused-files>` [VERIFIED: existing Mix setup] |
| Full suite command | `mix ci.fast` [VERIFIED: `mix.exs`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ARCH-01 | Public manifest is byte-identical and affected recipe bytes remain frozen | contract / deterministic render | `mix test test/rendro/public_api/manifest_test.exs test/docs_contract/public_api_contract_test.exs test/rendro/recipes/*_byte_identity_test.exs` | ✅ |
| ARCH-02 | Every candidate has a durable ledger disposition and accepted repairs have focused proof | governance / focused | `mix quality.governance` plus candidate-specific tests | ✅ governance; candidate tests vary |
| ARCH-03 | Palette resolution preserves all legacy defaults, theme resolution, and override precedence | unit + deterministic render | `mix test test/rendro/recipes/palette_test.exs test/rendro/recipes/*_byte_identity_test.exs` | ❌ Wave 0 palette test |
| ARCH-04 | Docs/specs/comments are truthful and type contracts remain sound | docs/static/type | `mix docs --warnings-as-errors && mix credo --strict && mix dialyzer` | ✅ |

### Sampling Rate

- **Per task commit:** relevant focused ExUnit files plus `mix quality.governance` for ledger edits. [VERIFIED: `mix.exs`]
- **Per wave merge:** public-manifest contract and affected byte-identity files. [VERIFIED: existing tests]
- **Phase gate:** `mix ci.fast` green before `$gsd-verify-work`. [VERIFIED: `mix.exs`, `134-CONTEXT.md`]

### Wave 0 Gaps

- [ ] `test/rendro/recipes/palette_test.exs` — characterize all seven recipe default maps, `:theme` resolution, and `:palette` last-wins precedence before accepting extraction.
- [ ] Ledger records for each historical candidate — add only after the first evidence slice declares its permanent IDs/dispositions; do not invent repair work.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase has no authentication surface. [VERIFIED: phase scope] |
| V3 Session Management | no | Phase has no session surface. [VERIFIED: phase scope] |
| V4 Access Control | no | Phase has no authorization surface. [VERIFIED: phase scope] |
| V5 Input Validation | yes, compatibility-sensitive | Preserve existing option behavior exactly; no new coercion or validation in a palette extraction. [VERIFIED: current palette source, `134-CONTEXT.md`] |
| V6 Cryptography | no | No cryptographic behavior changes are in scope. [VERIFIED: phase scope] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Palette helper changes caller override precedence or default colors | Tampering | Characterization tests plus all affected byte-identity tests; no behavior “cleanup.” [VERIFIED: phase constraints] |
| Dead-code removal deletes a public/dynamic dependency | Denial of service | Source, xref, manifest, documentation, and focused-test checks before deletion. [VERIFIED: current candidate protocol] |
| Comment cleanup removes operational provenance | Repudiation | Preserve evidence-bearing phase/date citations and require a line-specific stale-claim finding. [VERIFIED: `134-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/134-core-architecture-readability/134-CONTEXT.md` — locked scope, candidate order, compatibility, and closure requirements. [VERIFIED: repository]
- `.planning/QUALITY.md` and `.planning/quality/baselines/132-initial.json` — canonical finding authority and diagnostic limits. [VERIFIED: repository]
- Current `lib/`, `test/`, `priv/public_api.json`, and `mix.exs` scans — candidate call/reference, helper, test, and gate facts. [VERIFIED: repository]
- `mix xref callers Rendro.I18n.Analyzer`, xref stats/cycles, focused tests, and `mix quality.governance` — current validation evidence. [VERIFIED: local commands]

### Secondary (MEDIUM confidence)

- [Mix xref documentation](https://hexdocs.pm/mix/Mix.Tasks.Xref.html) — meaning and limits of `compile-connected`, graph, and caller analysis. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Xref.html]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified local runtime and existing locked dependencies. [VERIFIED: `mix.exs`, local toolchain]
- Architecture: HIGH — driven by locked ledger rules and current source/call graph evidence. [VERIFIED: repository]
- Pitfalls: HIGH — derived from explicit phase constraints and current semantic boundaries. [VERIFIED: `134-CONTEXT.md`, source]

**Research date:** 2026-08-26
**Valid until:** 2026-09-25, provided the ledger, source SHA, and candidate surfaces remain unchanged.
