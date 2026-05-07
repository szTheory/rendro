# Phase 24: Diagnostics Verification and Traceability Closure - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the remaining diagnostics verification-chain gaps for `OBS-05` and `QUAL-06`, align the public diagnostics contract with the shipped code, and restore truthful milestone traceability only after authoritative proof exists. This phase is a closure-and-trust pass, not a new diagnostics feature phase: it should not add a richer telemetry model, a broad new diagnostics DSL, or a speculative verification framework beyond what Rendro already needs to prove the public contract.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<specifics>
## Specific Ideas

- Comparable ecosystem lesson:
  - Ecto/Plug-style ergonomics favor explicit, inspectable data structures with documented common fields over prematurely freezing every evolving payload into a dedicated struct.
  - Telemetry-style metadata maps are a good fit for additive operational payloads, but user-facing contracts still need clear documented guarantees about which keys are stable.
  - Snapshot-style proof is valuable when it stays small, deterministic, and reviewable; it becomes a footgun when it turns into a large opaque artifact wall.
- Recommended closure story:
  - Phase 21 = historical implementation and backfilled verification truth.
  - Phase 24 = authoritative milestone closure for `OBS-05` and `QUAL-06`.
- Recommended diagnostics wording:
  - “`final_doc.diagnostics` is a list of structured maps with stable common keys and event-specific optional fields.”
  - Not: “`final_doc.diagnostics` is a list of `%Rendro.Document.Diagnostic{}`.”
- Recommendation-first user preference:
  - prefer a cohesive proposed direction by default
  - preserve tradeoff summaries
  - escalate only for truly high-impact semantic decisions

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirement State
- `.planning/ROADMAP.md` — Phase 24 goal, success criteria, and milestone closure scope.
- `.planning/REQUIREMENTS.md` — current pending traceability for `OBS-05` and `QUAL-06`.
- `.planning/PROJECT.md` — core constraints: pure core, deterministic behavior, truthful docs/contracts.
- `.planning/METHODOLOGY.md` — project-level philosophy around small truthful contracts and least-surprise engineering.

### Historical Diagnostics Context
- `.planning/phases/21-break-diagnostics-and-pagination-proofs/21-CONTEXT.md` — locked Phase 21 decisions for diagnostics accumulation and ASCII inspector proofs.
- `.planning/phases/21-break-diagnostics-and-pagination-proofs/21-RESEARCH.md` — original rationale for diagnostics on `%Rendro.Document{}` and deterministic proof surfaces.
- `.planning/phases/21-break-diagnostics-and-pagination-proofs/21-VALIDATION.md` — current unstructured validation artifact that must be normalized.
- `.planning/v1.1-MILESTONE-AUDIT.md` — authoritative audit gap description for `OBS-05`, `QUAL-06`, README drift, and partial Nyquist state.

### Historical Closure Precedent
- `.planning/phases/20-table-layout-maturity/20-VERIFICATION.md` — model for truthful historical repair without rewriting milestone history.
- `.planning/phases/23-table-split-policy-runtime-wiring/23-CONTEXT.md` — recent workflow posture and hybrid closure decision precedent.
- `.planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md` — model for authoritative later closure artifact and traceability synchronization.
- `.planning/phases/22-authoring-ergonomics-and-canonical-recipes/22-VALIDATION.md` — adjacent validation artifact that should be normalized alongside Phase 21 for consistency.

### Existing Runtime and Public Contract
- `lib/rendro/document.ex` — actual `diagnostics: [map()]` document contract.
- `lib/rendro.ex` — `render_with_diagnostics/2` public API boundary.
- `lib/rendro/pipeline.ex` — pipeline execution and telemetry separation.
- `lib/rendro/error.ex` — existing typed failure contract for fatal render issues.
- `lib/rendro/inspector.ex` — public structural inspection surface for deterministic snapshot-style proof.
- `README.md` — current public diagnostics wording that must be corrected to match shipped behavior.
- `test/rendro/pipeline/paginate_test.exs` — current diagnostics accumulation proof surface.
- `test/rendro/inspector_test.exs` — current inspector snapshot proof surface.
- `test/rendro/pipeline_test.exs` — top-level pipeline diagnostics boundary proof surface.

### Workflow Posture
- `.planning/config.json` — current GSD preferences already favor research-before-questions and an opinionated recommendation posture where supported.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/rendro.ex`: `render_with_diagnostics/2` already exposes the public boundary that Phase 24 should prove and document.
- `lib/rendro/document.ex`: the real data contract already says `diagnostics: [map()]`, giving Phase 24 a truthful base to standardize rather than replace.
- `lib/rendro/inspector.ex`: the ASCII inspector already renders diagnostics deterministically; this is the right public proof surface for `QUAL-06`.
- `test/rendro/pipeline/paginate_test.exs`, `test/rendro/inspector_test.exs`, and `test/rendro/pipeline_test.exs`: existing focused tests already cover the important seams and can be elevated into milestone proof rather than duplicated.

### Established Patterns
- Rendro keeps user-facing failures as typed `%Rendro.Error{}` values and non-fatal layout/debug information as structured data on `%Rendro.Document{}`.
- Docs are treated as contracts and should never claim a richer surface than the code actually ships.
- Historical repair artifacts are acceptable when they preserve truth and clearly point to the authoritative closure point.
- GSD artifacts in this repo already reward structured, machine-discoverable metadata over prose-only status notes.

### Integration Points
- Phase 21 planning artifacts need repair so Nyquist and milestone verification can discover them consistently.
- README, `REQUIREMENTS.md`, and `ROADMAP.md` must be synchronized only after the authoritative verification artifact exists.
- Phase 24 planning should treat workflow posture as part of the project contract: recommendation-first for routine decisions, escalation only for truly consequential branches.

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 24-diagnostics-verification-and-traceability-closure*
*Context gathered: 2026-04-30*
