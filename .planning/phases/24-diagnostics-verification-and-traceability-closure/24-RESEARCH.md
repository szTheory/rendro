# Phase 24: Diagnostics Verification and Traceability Closure - Research

**Researched:** 2026-04-30 [VERIFIED: system date]
**Domain:** Diagnostics verification-chain closure, docs-contract repair, and milestone traceability normalization for `OBS-05` and `QUAL-06` [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: codebase + targeted proof commands]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Verification Framing
- **D-01:** Requirement closure should follow the same hybrid history-plus-authoritative model used for `LAY-10`: Phase 21 remains the historical implementation owner for diagnostics accumulation and inspector-based pagination proofs, while Phase 24 becomes the authoritative closure point for the missing verification chain, README alignment, and traceability synchronization.
- **D-02:** Phase 21 should receive a truthful backfilled `21-VERIFICATION.md` that records what shipped and what proof existed for `OBS-05` and `QUAL-06`; Phase 24 should carry the final closure artifact that confirms the milestone contract is now fully closed.
- **D-03:** `ROADMAP.md` and `REQUIREMENTS.md` must not flip `OBS-05` and `QUAL-06` to closed until the authoritative Phase 24 verification artifact exists on disk and cites the repaired Phase 21 history explicitly.

### Diagnostics Public Contract
- **D-04:** Rendro should keep `final_doc.diagnostics` as a list of maps, not introduce a new `%Rendro.Document.Diagnostic{}` struct in this phase.
- **D-05:** The public contract should be a documented common-fields map shape: stable shared keys such as `:level` and `:type`, with event-specific optional keys like `:message`, `:page_index`, `:reason`, `:keep_rule`, and future additive keys allowed.
- **D-06:** Documentation and typespecs should describe diagnostics as user-inspectable structured maps and explicitly preserve the separation of concerns already chosen in Phase 21: `doc.diagnostics` is the developer-facing layout-debug surface, while `:telemetry` remains the operational/render-span surface.
- **D-07:** Phase 24 should correct overstatements in README and any module docs rather than widening the runtime contract. The problem to solve is contract drift, not a missing public struct.

### Proof Depth
- **D-08:** Phase 24 proof should be milestone-level and public-surface-oriented, not just narrow unit closure and not an exhaustive new verification bureaucracy.
- **D-09:** The authoritative proof set should cover the actual supported surfaces together: `Rendro.render_with_diagnostics/2`, `Rendro.Inspector.inspect/1`, focused pagination/inspector tests, the README docs-contract lane, and the traceability artifacts that close `OBS-05` and `QUAL-06`.
- **D-10:** Keep proof deterministic, reviewable, and small enough that PR diffs remain useful. Prefer focused ExUnit/docs-contract evidence over sprawling snapshots or speculative property suites unless a later milestone materially widens the pagination state space.

### Validation Strictness
- **D-11:** Phase 21 validation metadata should be upgraded to the same structured Nyquist-compliant convention already used by the stronger phases rather than left as prose-only validation notes.
- **D-12:** Phase 22 validation metadata should also be normalized to that structured convention so Nyquist discovery no longer treats adjacent completed phases inconsistently.
- **D-13:** Do not invent a second, lighter validation convention during Phase 24. The existing structured pattern already works and is the least-surprise path for future contributors and tooling.

### Workflow Posture
- **D-14:** For this project, GSD should default to recommendation-first synthesis for routine gray areas: research first, produce one cohesive recommendation set, and ask the user to intervene only when a choice materially changes product semantics, scope, or other genuinely high-impact policy.
- **D-15:** Where supported, downstream workflows should preserve the current preference posture already visible in `.planning/config.json`: `workflow.research_before_questions: true` and `preferences.vendor_philosophy: opinionated`. Since there is no dedicated config knob today for “recommendation-first unless high-impact,” capture that preference in context and planning artifacts instead of inventing an unsupported setting.

### the agent's Discretion
- Exact frontmatter fields and report wording for the repaired `21-VALIDATION.md`, as long as it becomes machine-discoverable and aligns with the repo’s established Nyquist pattern.
- Exact phrasing of the diagnostics common-fields contract, as long as it stays honest to the shipped map-based surface and explicitly allows additive event-specific keys.
- Exact test/file selection for the public proof slice, as long as it covers the public diagnostics API, inspector output, docs-contract lane, and traceability closure.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OBS-05 | Operator can inspect structured diagnostics that explain why content moved, split, or overflowed during pagination. [VERIFIED: .planning/REQUIREMENTS.md] | Keep the existing map-based `doc.diagnostics` contract, prove it through `Rendro.render_with_diagnostics/2`, `test/rendro/pipeline/paginate_test.exs`, `test/rendro/pipeline_test.exs`, README docs-contract coverage, and the historical + authoritative verification artifacts. [VERIFIED: lib/rendro/document.ex] [VERIFIED: lib/rendro.ex] [VERIFIED: test/rendro/pipeline/paginate_test.exs] [VERIFIED: test/rendro/pipeline_test.exs] [VERIFIED: README.md] |
| QUAL-06 | Maintainer can verify pagination invariants and deterministic break decisions with committed regression fixtures and docs-contract proof. [VERIFIED: .planning/REQUIREMENTS.md] | Use the existing deterministic inspector/test surfaces and docs-contract lane as the minimal proof set, then attach them to `21-VERIFICATION.md`, normalized validation metadata, and the Phase 24 authoritative closure artifact. [VERIFIED: lib/rendro/inspector.ex] [VERIFIED: test/rendro/inspector_test.exs] [VERIFIED: mix run scripts/verify_docs.exs] [VERIFIED: .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md] |
</phase_requirements>

## Summary

Phase 24 does not need new diagnostics runtime behavior to close `OBS-05` and `QUAL-06`. The shipped code already exposes `diagnostics: [map()]` on `%Rendro.Document{}`, returns the final document from `Rendro.render_with_diagnostics/2`, keeps telemetry in the pipeline layer, and renders deterministic ASCII inspection output through `Rendro.Inspector.inspect/1`. [VERIFIED: lib/rendro/document.ex] [VERIFIED: lib/rendro.ex] [VERIFIED: lib/rendro/pipeline.ex] [VERIFIED: lib/rendro/inspector.ex]

The real gap is verification-chain truth. The v1.1 audit marks `OBS-05` and `QUAL-06` orphaned because Phase 21 has no `21-VERIFICATION.md`, `21-VALIDATION.md` is prose-only, `22-VALIDATION.md` is also unstructured, and README still claims a `%Rendro.Document.Diagnostic{}` struct that does not exist. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md] [VERIFIED: .planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md] [VERIFIED: README.md] [VERIFIED: lib/rendro/document.ex]

**Primary recommendation:** Close this phase with a four-part repair only: backfill `21-VERIFICATION.md`, normalize `21-VALIDATION.md` and `22-VALIDATION.md` to the existing Nyquist frontmatter pattern, correct the README diagnostics contract to “structured maps with stable common keys and event-specific optional keys,” and update `ROADMAP.md` plus `REQUIREMENTS.md` only after a Phase 24 authoritative verification artifact exists. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-VALIDATION.md] [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-VALIDATION.md] [VERIFIED: .planning/phases/20-table-layout-maturity/20-VALIDATION.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Historical diagnostics requirement closure | Planning / Verification artifacts | Test suite | The missing gap is milestone proof and traceability, not runtime computation. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] |
| Public diagnostics contract wording | Docs / public API surface | Typespecs | README currently overstates a struct that the runtime does not define; wording must align with actual types. [VERIFIED: README.md] [VERIFIED: lib/rendro/document.ex] |
| Diagnostics payload generation | API / backend pipeline | — | `Measure`/`Paginate` accumulate non-fatal layout events on `%Rendro.Document{}` and the public API returns the final document. [VERIFIED: lib/rendro/document.ex] [VERIFIED: lib/rendro.ex] [VERIFIED: test/rendro/pipeline/paginate_test.exs] |
| Deterministic pagination proof | Test suite | Verification artifacts | Existing ExUnit and docs-contract lanes already prove the behavior that Phase 24 needs to certify. [VERIFIED: test/rendro/inspector_test.exs] [VERIFIED: test/rendro/pipeline/paginate_test.exs] [VERIFIED: mix run scripts/verify_docs.exs] |
| Milestone state synchronization | Planning docs | Verification artifacts | `ROADMAP.md` and `REQUIREMENTS.md` must change only after authoritative proof exists. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 / 1.19.5 | Runtime, test execution, docs verification, and artifact generation | This repo’s closure workflow already runs through Mix commands and ExUnit-backed proof surfaces; no new toolchain is required. [VERIFIED: mix --version] [VERIFIED: mix.exs] |
| ExUnit | bundled with Elixir 1.19.5 | Deterministic regression proof for inspector, pipeline, and docs-contract tests | The required Phase 24 proof surfaces are already expressed as ExUnit tests and passed in the targeted slice. [VERIFIED: test/rendro/inspector_test.exs] [VERIFIED: test/rendro/pipeline/paginate_test.exs] [VERIFIED: test/rendro/pipeline_test.exs] [VERIFIED: mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs] |
| Telemetry | 1.4.1 | Operational span/events surface kept separate from developer-facing diagnostics | The pipeline emits telemetry spans while diagnostics remain on `%Rendro.Document{}`; Phase 24 should preserve that separation. [VERIFIED: mix deps] [VERIFIED: lib/rendro/pipeline.ex] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `ex_doc` | 0.40.1 | Docs generation inside the existing `mix ci` lane | Use to keep README/docs buildable while docs-contract wording is corrected. [VERIFIED: mix deps] [VERIFIED: mix.exs] |
| `stream_data` | 1.3.0 | Existing property-test support in repo | Keep available, but Phase 24 does not need new property suites because the user asked for the smallest closure path. [VERIFIED: mix deps] [VERIFIED: test/support/generators.ex] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Backfilled Phase 21 + authoritative Phase 24 closure | Rewrite history by marking Phase 21 complete directly | Contradicts the repo’s recent hybrid closure precedent and would hide the fact that the verification chain was repaired later. [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] |
| Map-based documented diagnostics | New `%Rendro.Document.Diagnostic{}` struct | Widens runtime scope for no requirement gain and conflicts with the locked Phase 24 decision to keep diagnostics as maps. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] [VERIFIED: lib/rendro/document.ex] |
| Existing focused ExUnit + docs-contract proof | New snapshot framework or broad property-test expansion | Adds tooling and review noise without addressing the actual missing artifact chain. [VERIFIED: test/rendro/inspector_test.exs] [VERIFIED: mix run scripts/verify_docs.exs] |

**Installation:** No new packages recommended for Phase 24. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]

**Version verification:** `mix --version` reports `Mix 1.19.5` on `Erlang/OTP 28`, and `mix deps` reports `telemetry 1.4.1`, `stream_data 1.3.0`, `dialyxir 1.4.7`, `ex_doc 0.40.1`, `oban 2.21.1`, and `phoenix 1.8.5`. [VERIFIED: mix --version] [VERIFIED: mix deps]

## Architecture Patterns

### System Architecture Diagram
```text
Historical Phase 21 code/test surfaces
  -> 21-VERIFICATION.md backfill
Current Nyquist prose-only validation files
  -> 21-VALIDATION.md / 22-VALIDATION.md normalization
Current public docs contract drift
  -> README diagnostics wording repair
All repaired evidence
  -> 24-VERIFICATION.md authoritative closure
24-VERIFICATION.md authoritative closure
  -> REQUIREMENTS.md + ROADMAP.md resync
```

### Recommended Project Structure
```text
.planning/phases/24-diagnostics-verification-and-traceability-closure/
├── 24-CONTEXT.md          # locked closure policy
├── 24-RESEARCH.md         # recommendation-first implementation guidance
└── 24-VERIFICATION.md     # authoritative closure artifact

.planning/phases/21-break-diagnostics-and-pagination-proofs/
├── 21-VALIDATION.md       # normalize to Nyquist frontmatter pattern
└── 21-VERIFICATION.md     # historical implementation proof

test/
├── rendro/pipeline/paginate_test.exs
├── rendro/pipeline_test.exs
└── rendro/inspector_test.exs
```

### Pattern 1: Hybrid Historical + Authoritative Closure
**What:** Treat Phase 21 as the historical implementation owner and Phase 24 as the authoritative milestone closure point, mirroring the `LAY-10` repair pattern already used in Phase 23. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md]
**When to use:** When the implementation shipped earlier but the requirement remained open because verification artifacts, validation metadata, or traceability synchronization were missing. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**Example:**
```markdown
<!-- Source: .planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md -->
21-VERIFICATION.md  -> records what Phase 21 actually shipped and what tests/docs existed
24-VERIFICATION.md  -> verifies repaired chain, then closes OBS-05 and QUAL-06 authoritatively
REQUIREMENTS.md     -> flips to closed only after 24-VERIFICATION.md exists
```

### Pattern 2: Documented Common-Fields Map Contract
**What:** Keep `final_doc.diagnostics` as `list(map())` and document stable shared keys plus event-specific optional keys instead of inventing a dedicated struct. [VERIFIED: lib/rendro/document.ex] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
**When to use:** When the runtime payload is already additive and the phase goal is contract truth, not type-system expansion. [VERIFIED: README.md] [VERIFIED: lib/rendro/inspector.ex]
**Example:**
```elixir
# Source: lib/rendro/document.ex + 24-CONTEXT.md
@type diagnostics_entry :: %{
  required(:level) => atom(),
  required(:type) => atom() | String.t(),
  optional(:message) => String.t(),
  optional(:page_index) => pos_integer(),
  optional(:reason) => atom() | String.t(),
  optional(:keep_rule) => atom(),
  optional(atom()) => term()
}
```

### Pattern 3: Normalize Validation Metadata to the Existing Nyquist Shape
**What:** Reuse the structured frontmatter and validation tables already present in Phases 18-20. [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-VALIDATION.md] [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-VALIDATION.md] [VERIFIED: .planning/phases/20-table-layout-maturity/20-VALIDATION.md]
**When to use:** When a phase has validation content but tooling cannot discover it consistently because the file is prose-only. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md] [VERIFIED: .planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md]
**Example:**
```yaml
# Source: 18-VALIDATION.md / 19-VALIDATION.md / 20-VALIDATION.md
---
phase: 21
slug: break-diagnostics-and-pagination-proofs
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
updated: 2026-04-30
---
```

### Anti-Patterns to Avoid
- **Do not add a diagnostics struct:** The phase boundary is trust closure, not runtime widening. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
- **Do not move layout-debug payloads into telemetry:** Telemetry is already the operational surface and the code/docs separate it from `doc.diagnostics`. [VERIFIED: lib/rendro/pipeline.ex] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
- **Do not mark roadmap/requirements complete before Phase 24 verification exists:** That would repeat the traceability drift the audit flagged. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
- **Do not grow proof scope into new snapshot/property infrastructure:** Existing focused tests and docs-contract lanes already pass. [VERIFIED: mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs] [VERIFIED: mix run scripts/verify_docs.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Historical closure model | Ad hoc one-off wording for Phase 24 | The same hybrid closure pattern used by Phase 23 | The repo already has a truthful precedent for “historical implementation + later authoritative closure.” [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md] |
| Validation normalization | A second lighter metadata convention | The existing Nyquist frontmatter/table pattern from Phases 18-20 | Tooling already recognizes that shape; Phase 21/22 are partial because they do not use it. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-VALIDATION.md] |
| Docs proof | Manual README inspection only | `mix run scripts/verify_docs.exs` plus docs-contract tests | The docs-contract lane already verifies README snippets and passed in this session. [VERIFIED: mix run scripts/verify_docs.exs] [VERIFIED: README.md] |
| Pagination proof | New PDF binary diffing | Existing inspector and focused paginate tests | These are deterministic, reviewable, and already green. [VERIFIED: test/rendro/inspector_test.exs] [VERIFIED: test/rendro/pipeline/paginate_test.exs] [VERIFIED: mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs] |

**Key insight:** The smallest truthful closure path is mostly artifact normalization around already-green proof surfaces, not new engine work. [VERIFIED: mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs] [VERIFIED: mix run scripts/verify_docs.exs] [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

## Common Pitfalls

### Pitfall 1: Closing traceability from code presence instead of verification presence
**What goes wrong:** `OBS-05` and `QUAL-06` get marked complete because runtime/tests exist, even though the authoritative verification artifact chain is still incomplete. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**Why it happens:** Phase 21 shipped code and tests, but no `21-VERIFICATION.md` was created and validation metadata stayed prose-only. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md]
**How to avoid:** Create `21-VERIFICATION.md` first, normalize validation files second, create `24-VERIFICATION.md` third, and update `REQUIREMENTS.md`/`ROADMAP.md` last. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
**Warning signs:** Requirement rows are still pending or phase rows still open even though unit tests pass. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md]

### Pitfall 2: Fixing docs by widening runtime semantics
**What goes wrong:** A new diagnostics struct or richer diagnostics API is added just to make the old README wording true. [VERIFIED: README.md] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
**Why it happens:** The docs drift looks like a missing feature instead of a contract overstatement. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
**How to avoid:** Update docs and any relevant typespec wording to the current supported map-based contract only. [VERIFIED: lib/rendro/document.ex] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
**Warning signs:** Proposed changes mention new structs, macros, or telemetry schemas. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]

### Pitfall 3: Normalizing only Phase 21 validation
**What goes wrong:** Nyquist stays partially inconsistent because Phase 22 remains on the old prose-only format. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md]
**Why it happens:** Phase 24 is focused on diagnostics, so adjacent validation drift looks unrelated. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
**How to avoid:** Normalize both `21-VALIDATION.md` and `22-VALIDATION.md` in the same phase. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
**Warning signs:** Audit output still lists partial Nyquist phases after the closure artifact lands. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]

## Code Examples

Verified patterns from the current codebase and phase decisions:

### Public Diagnostics Boundary
```elixir
# Source: lib/rendro.ex + lib/rendro/document.ex
{:ok, pdf_binary, final_doc} = Rendro.render_with_diagnostics(doc)

is_binary(pdf_binary)
is_list(final_doc.diagnostics)
```

### Deterministic Inspector Proof Surface
```elixir
# Source: test/rendro/inspector_test.exs
assert Rendro.Inspector.inspect(doc) == """
Page 1 (595.28x841.89)
├── Block: Text (x: 72, y: 72, w: 451.28, h: 20)

Diagnostics:
- [info] table_split: table_split on page 2
""" |> String.trim_trailing()
```

### Validation Normalization Shape
```markdown
<!-- Source: 18-VALIDATION.md / 19-VALIDATION.md / 20-VALIDATION.md -->
---
phase: 22
slug: authoring-ergonomics-and-canonical-recipes
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
updated: 2026-04-30
---
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 21 code/tests exist but closure is inferred manually | Phase 21 history is backfilled and Phase 24 closes requirements authoritatively | Phase 24 recommendation | Restores truthful milestone closure without rewriting history. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] |
| README claims diagnostics are `%Rendro.Document.Diagnostic{}` | README should describe structured maps with stable common keys and event-specific optional fields | Phase 24 recommendation | Aligns public docs with the actual supported runtime surface. [VERIFIED: README.md] [VERIFIED: lib/rendro/document.ex] |
| Phase 21/22 validation files are prose-only | Validation files should use Nyquist frontmatter/table metadata like Phases 18-20 | Existing repo pattern as of 2026-04-30 | Removes partial discovery state for adjacent completed phases. [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-VALIDATION.md] [VERIFIED: .planning/phases/19-deterministic-text-flow-and-break-semantics/19-VALIDATION.md] [VERIFIED: .planning/phases/20-table-layout-maturity/20-VALIDATION.md] [VERIFIED: .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md] [VERIFIED: .planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md] |

**Deprecated/outdated:**
- `%Rendro.Document.Diagnostic{}` as README contract wording is outdated and unsupported by the current codebase. [VERIFIED: README.md] [VERIFIED: lib/rendro/document.ex]

## Assumptions Log

All claims in this research were verified in the current session from repo artifacts or local commands. [VERIFIED: codebase + commands in Sources]

## Open Questions (RESOLVED)

1. **Should Phase 24 touch module docs beyond README?**
   - What we know: The explicit incorrect struct wording was found in README, and the locked decision says to correct README and any module docs that overstate the contract. [VERIFIED: README.md] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
   - Resolution: The required-read surfaces do not currently show a second explicit `%Rendro.Document.Diagnostic{}` overstatement in module docs, so Phase 24 should correct README plus any module-doc match found by a single targeted implementation-time search, and otherwise avoid opportunistic doc churn. [VERIFIED: rg -n "Document\\.Diagnostic|structured diagnostics|diagnostics is a list|render_with_diagnostics|Rendro.Inspector" lib README.md test .planning/phases/24-diagnostics-verification-and-traceability-closure .planning/v1.1-MILESTONE-AUDIT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang / OTP | Mix/test/docs execution | ✓ | 28 | — [VERIFIED: mix --version] |
| Mix | targeted test and docs-contract commands | ✓ | 1.19.5 | — [VERIFIED: mix --version] |
| ExUnit test suite | diagnostics/inspector proof | ✓ | bundled with Elixir 1.19.5 | — [VERIFIED: mix --version] [VERIFIED: test/test_helper.exs] |

**Missing dependencies with no fallback:** None for this phase’s closure scope. [VERIFIED: mix --version] [VERIFIED: mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs] [VERIFIED: mix run scripts/verify_docs.exs]

**Missing dependencies with fallback:** None. [VERIFIED: mix --version]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + docs-contract lanes driven by `scripts/verify_docs.exs` [VERIFIED: test/test_helper.exs] [VERIFIED: README.md] |
| Config file | `test/test_helper.exs` [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs && mix run scripts/verify_docs.exs` [VERIFIED: mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs] [VERIFIED: mix run scripts/verify_docs.exs] |
| Full suite command | `mix ci` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OBS-05 | `render_with_diagnostics/2` returns a final `%Rendro.Document{}` carrying inspectable structured diagnostics for pagination events. [VERIFIED: lib/rendro.ex] [VERIFIED: lib/rendro/document.ex] | unit + integration | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs` [VERIFIED: test/rendro/pipeline/paginate_test.exs] [VERIFIED: test/rendro/pipeline_test.exs] | ✅ [VERIFIED: test/rendro/pipeline/paginate_test.exs] [VERIFIED: test/rendro/pipeline_test.exs] |
| QUAL-06 | Maintainers can review deterministic layout/diagnostic output via `Rendro.Inspector.inspect/1`. [VERIFIED: lib/rendro/inspector.ex] | unit | `mix test test/rendro/inspector_test.exs` [VERIFIED: test/rendro/inspector_test.exs] | ✅ [VERIFIED: test/rendro/inspector_test.exs] |
| OBS-05, QUAL-06 | Public docs describe the supported diagnostics contract truthfully. [VERIFIED: README.md] | docs-contract | `mix run scripts/verify_docs.exs` [VERIFIED: mix run scripts/verify_docs.exs] | ✅ [VERIFIED: README.md] |
| OBS-05, QUAL-06 | Historical and authoritative closure artifacts remain aligned with roadmap/requirements state. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] | artifact verification | `rg -n "OBS-05|QUAL-06|authoritative|historical|21-VERIFICATION|24-VERIFICATION" .planning/phases/21-break-diagnostics-and-pagination-proofs .planning/phases/24-diagnostics-verification-and-traceability-closure .planning/REQUIREMENTS.md .planning/ROADMAP.md` [VERIFIED: repo artifact paths] | ❌ Wave 0 [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs`
- **Per wave merge:** `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs && mix run scripts/verify_docs.exs`
- **Phase gate:** `mix ci` plus artifact grep/readback before `/gsd-verify-work` [VERIFIED: mix.exs] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]

### Wave 0 Gaps
- [ ] `.planning/phases/21-break-diagnostics-and-pagination-proofs/21-VERIFICATION.md` — historical proof artifact required before authoritative closure. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
- [ ] `.planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md` — normalize to Nyquist frontmatter/table pattern. [VERIFIED: .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md] [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-VALIDATION.md]
- [ ] `.planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md` — normalize to Nyquist frontmatter/table pattern. [VERIFIED: .planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md] [VERIFIED: .planning/phases/18-layout-contract-and-page-template-model/18-VALIDATION.md]
- [ ] `.planning/phases/24-diagnostics-verification-and-traceability-closure/24-VERIFICATION.md` — authoritative closure artifact that gates roadmap/requirements updates. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not in scope for a docs/verification closure phase. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | Not in scope for a pure library closure phase. [VERIFIED: .planning/PROJECT.md] |
| V4 Access Control | no | Not in scope for this phase. [VERIFIED: .planning/ROADMAP.md] |
| V5 Input Validation | yes | Preserve explicit public contract wording and existing typed `%Rendro.Error{}` boundaries instead of widening accepted diagnostics shapes implicitly. [VERIFIED: lib/rendro/error.ex] [VERIFIED: README.md] [VERIFIED: .planning/METHODOLOGY.md] |
| V6 Cryptography | no | No cryptographic behavior is introduced or changed here. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs overclaim unsupported diagnostics shape | Tampering | Keep README/typespecs aligned to `diagnostics: [map()]` and verify through docs-contract lanes. [VERIFIED: README.md] [VERIFIED: lib/rendro/document.ex] [VERIFIED: mix run scripts/verify_docs.exs] |
| Requirement state marked closed before proof exists | Repudiation | Update `REQUIREMENTS.md` and `ROADMAP.md` only after `24-VERIFICATION.md` lands and cites the repaired history. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] |
| Telemetry and diagnostics responsibilities get conflated | Information Disclosure | Preserve `doc.diagnostics` for developer-facing layout facts and `:telemetry` for operational spans/events. [VERIFIED: lib/rendro/pipeline.ex] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/ROADMAP.md` - Phase 24 goal, success criteria, and closure scope. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - open `OBS-05` and `QUAL-06` traceability rows. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/v1.1-MILESTONE-AUDIT.md` - authoritative audit description of the missing Phase 21 verification artifact, partial Nyquist state, and README drift. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md]
- `.planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md` - locked closure policy for Phase 24. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
- `.planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md` - precedent for hybrid historical + authoritative closure. [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md]
- `lib/rendro/document.ex`, `lib/rendro.ex`, `lib/rendro/pipeline.ex`, `lib/rendro/error.ex`, `lib/rendro/inspector.ex` - current runtime and public diagnostics contract. [VERIFIED: local code]
- `README.md` - current public diagnostics wording and docs-contract surface. [VERIFIED: README.md]
- `test/rendro/pipeline/paginate_test.exs`, `test/rendro/pipeline_test.exs`, `test/rendro/inspector_test.exs` - existing proof surfaces. [VERIFIED: local tests]
- `mix --version`, `mix deps`, `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs`, `mix run scripts/verify_docs.exs` - current environment and proof confirmation. [VERIFIED: local commands]

### Secondary (MEDIUM confidence)
- `.planning/phases/18-layout-contract-and-page-template-model/18-VALIDATION.md`, `.planning/phases/19-deterministic-text-flow-and-break-semantics/19-VALIDATION.md`, `.planning/phases/20-table-layout-maturity/20-VALIDATION.md` - established Nyquist validation shape to reuse. [VERIFIED: local files]

### Tertiary (LOW confidence)
- None. [VERIFIED: session research scope]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and commands were verified locally, and no new dependencies are recommended. [VERIFIED: mix --version] [VERIFIED: mix deps] [VERIFIED: mix.exs]
- Architecture: HIGH - the closure path is driven by locked Phase 24 decisions plus existing Phase 23 precedent and current code/test surfaces. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md] [VERIFIED: local code]
- Pitfalls: HIGH - each pitfall is directly evidenced by the v1.1 audit or current file state. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: README.md] [VERIFIED: .planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md] [VERIFIED: .planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md]

**Research date:** 2026-04-30 [VERIFIED: system date]
**Valid until:** 2026-05-30 for repo-local closure guidance unless Phase 24 artifacts land sooner and supersede this research. [VERIFIED: phase-local scope]

## RESEARCH COMPLETE

**Phase:** 24 - diagnostics-verification-and-traceability-closure [VERIFIED: gsd-sdk query init.phase-op 24]
**Confidence:** HIGH [VERIFIED: codebase + targeted proof commands]

### Key Findings
- The current runtime already satisfies the narrow diagnostics surface Phase 24 needs to prove: `%Rendro.Document{diagnostics: [map()]}`, `Rendro.render_with_diagnostics/2`, and deterministic `Rendro.Inspector.inspect/1` are all present. [VERIFIED: lib/rendro/document.ex] [VERIFIED: lib/rendro.ex] [VERIFIED: lib/rendro/inspector.ex]
- The remaining gap is the verification chain: no `21-VERIFICATION.md`, partial Nyquist metadata in `21-VALIDATION.md` and `22-VALIDATION.md`, and pending requirement/roadmap state. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md]
- README currently overstates the diagnostics contract by naming a nonexistent `%Rendro.Document.Diagnostic{}` struct; the truthful closure path is to document map-shaped diagnostics, not add runtime types. [VERIFIED: README.md] [VERIFIED: lib/rendro/document.ex] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
- The smallest authoritative proof slice is already green: `paginate_test`, `pipeline_test`, `inspector_test`, and the docs-contract lane all passed in this session. [VERIFIED: mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs] [VERIFIED: mix run scripts/verify_docs.exs]
- Phase 24 should follow the same hybrid closure precedent as Phase 23: backfill the historical phase artifact, then close the requirement authoritatively in the new phase. [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md] [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]

### File Created
`.planning/phases/24-diagnostics-verification-and-traceability-closure/24-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Versions, commands, and no-new-dependency recommendation were verified locally. [VERIFIED: mix --version] [VERIFIED: mix deps] |
| Architecture | HIGH | The recommendation is constrained by locked Phase 24 decisions, existing repo precedent, and current code/test surfaces. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md] [VERIFIED: .planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md] |
| Pitfalls | HIGH | The listed failure modes are the exact gaps documented by the audit and current files. [VERIFIED: .planning/v1.1-MILESTONE-AUDIT.md] |

### Open Questions (RESOLVED)
- Module-doc drift beyond README was checked across the required-read surfaces; no second explicit `%Rendro.Document.Diagnostic{}` claim was found, so the implementation should fix README and only touch module docs if the single targeted search finds another real overstatement. [VERIFIED: rg -n "Document\\.Diagnostic|structured diagnostics|diagnostics is a list|render_with_diagnostics|Rendro.Inspector" lib README.md test .planning/phases/24-diagnostics-verification-and-traceability-closure .planning/v1.1-MILESTONE-AUDIT.md]

### Ready for Planning
Research complete. Planner can now create PLAN.md files around proof/doc/traceability closure rather than new diagnostics runtime work. [VERIFIED: .planning/phases/24-diagnostics-verification-and-traceability-closure/24-CONTEXT.md]
