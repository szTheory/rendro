# Phase 11: Reconstruct Phase 1-4 GSD Artifacts - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce evidence-based `PLAN.md`, `SUMMARY.md`, and `VERIFICATION.md` artifacts for Phases 1, 2, 3, and 4 against the live fixed codebase, then reconcile Phase 1-4 requirement traceability in `.planning/REQUIREMENTS.md` from that evidence.

This phase reconstructs proof and traceability. It does not reopen product scope, quietly broaden contracts, or smuggle runtime remediation under the guise of verification work.

</domain>

<decisions>
## Implementation Decisions

### Evidence Bar
- **D-01:** A requirement may be marked verified only when it has one primary executable proof at the requirement's public boundary in the live fixed codebase.
- **D-02:** Supporting evidence may include source links, docs links, and prior phase artifacts, but supporting evidence never substitutes for the primary proof.
- **D-03:** Source inspection, file presence, historical intent, or narrative confidence alone are never sufficient to flip a requirement to verified.
- **D-04:** Default primary-proof types by requirement class are locked:
  - Core/layout/determinism/telemetry/error requirements: ExUnit, property, or integration tests at the public API boundary.
  - Phoenix/Plug adapter requirements: connection- or endpoint-level proof where practical, not helper-only proof by default.
  - Optional dependency discipline requirements: guarded compilation/runtime proof such as `mix compile --no-optional-deps --warnings-as-errors` or equivalent.
  - Docs-contract claims: executable doctests, markdown doctests, or docs-contract verification.
  - CI/release claims: runnable command or workflow proof, not config-file presence alone.
- **D-05:** If a requirement cannot be tied to executable proof or a clearly named manual check, it stays non-verified and the gap is stated explicitly.

### Gap Handling
- **D-06:** Phase 11 is a read-mostly reconstruction phase against the fixed codebase.
- **D-07:** Targeted test, docs, and traceability edits are allowed only when they prove an already-existing contract and do not change public behavior, accepted input shapes, telemetry semantics, optional-dependency boundaries, or release semantics.
- **D-08:** Runtime code changes are out of scope for Phase 11 unless the phase is explicitly re-scoped by the user.
- **D-09:** If reconstruction discovers a real behavior gap rather than a proof gap, the requirement is recorded as partial/blocked in the phase verification artifact and routed to a separate remediation plan or gap-closure phase.
- **D-10:** When in doubt, prefer a narrower truthful status over a broader verified claim.

### Verification Document Shape
- **D-11:** Each reconstructed `VERIFICATION.md` uses a hybrid structure: short success-criteria summary first, requirement-first body second, artifact appendix last.
- **D-12:** Requirement-level sections are the traceability backbone. Success criteria are a reader aid, not the proof model. Artifact inventory is supporting evidence, not the primary verification structure.
- **D-13:** Verification documents must describe the live fixed codebase and current executable proof, not historical implementation intent from the original Phase 1-4 execution window.
- **D-14:** Repeated evidence should be cited once and cross-referenced, not duplicated across summary, requirement matrix, and artifact appendix.

### Requirements Traceability Updates
- **D-15:** `.planning/REQUIREMENTS.md` traceability rows update only from a completed reconstructed `VERIFICATION.md`, never from source mapping, planning, or summary writing alone.
- **D-16:** Rows remain `Pending` until the relevant reconstructed phase verification closes, then update immediately row-by-row from that finished verdict.
- **D-17:** Mixed outcomes must remain mixed. The default status vocabulary for the traceability table is `Pending`, `Done`, `Partial`, and `Blocked`.
- **D-18:** If a requirement was fixed by a later gap-closure phase but Phase 11 is the formal verification point, do not mark it `Done` until Phase 11 closes it with explicit evidence.

### Recommendation-First Agent Posture
- **D-19:** Downstream agents should default to research-backed recommendations and make routine implementation-discipline choices without escalating them to the user.
- **D-20:** Escalate only when a decision changes product semantics, revises a documented public contract, or presents a genuinely high-impact user-visible tradeoff.
- **D-21:** For this phase, the least-surprise default is evidence-first, requirement-first, and recommendation-first. Avoid menus of equivalent options when one clearly better default fits Rendro's methodology.

### the agent's Discretion
- Exact subsection names and table layouts inside reconstructed `PLAN.md`, `SUMMARY.md`, and `VERIFICATION.md`, as long as D-11 through D-14 stay intact.
- Whether a proof is best expressed as an existing test mapping, a targeted new proving test, or a runnable command, as long as D-01 through D-05 remain satisfied.
- Whether to keep nuanced mixed outcomes only in `VERIFICATION.md` or also mirror them in additional summary text, as long as `.planning/REQUIREMENTS.md` remains truthful and aligned.

</decisions>

<specifics>
## Specific Ideas

- Use existing strong verification artifacts as style anchors, especially the evidence-forward structure in `.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md` and `.planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md`.
- Treat `.planning/v1.0-MILESTONE-AUDIT.md` as the orphaned-requirements starting point, not as proof. It defines what must be closed, but it does not itself close anything.
- Prefer Elixir-style executable examples and boundary tests over narrative attestation. The project should feel closer to ExUnit/Phoenix/Ecto proof discipline than to release-note storytelling.
- The user preference for this phase is recommendation-first: think deeply, collapse the tradeoffs, and surface only the locked default unless a truly high-impact choice needs escalation.
- Project methodology already points in this direction (`Truthful Small Contracts`, `Boundary Validation First`, `Deterministic Standard Formatting`, `Least Surprise DX`). Phase 11 should apply those lenses automatically rather than re-asking them.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and traceability
- `.planning/ROADMAP.md` — Phase 11 goal, locked success criteria, and requirement list for the reconstruction.
- `.planning/REQUIREMENTS.md` — The central traceability table that Phase 11 must reconcile truthfully.
- `.planning/v1.0-MILESTONE-AUDIT.md` — Source of the formal orphan/unsatisfied status for Phase 1-4 requirements and the closure target for this phase.

### Project-level methodology and constraints
- `.planning/PROJECT.md` — Product thesis, truthful-scope constraints, and deterministic/observability priorities.
- `.planning/METHODOLOGY.md` — Locked decision lenses for truthful contracts, boundary validation, deterministic formatting, and least-surprise DX.

### Prior verification exemplars
- `.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md` — Strong evidence-forward verification pattern for optional integrations, docs, and traceability closure.
- `.planning/phases/06-pipeline-telemetry-contract/06-VERIFICATION.md` — Strong requirement/evidence mapping pattern for telemetry, stage order, and runtime verification.
- `.planning/phases/10-recipe-correctness-and-traceability/10-CONTEXT.md` — Recent example of recommendation-first context capture and traceability truthfulness decisions.

### Core implementation surfaces likely to anchor Phase 1-2 evidence
- `lib/rendro.ex` — Public API surface for `render/2`, `fixed/2`, `flow/2`, `page/1`, `block/2`, `text/2`, `table/2`, and document builders.
- `lib/rendro/document.ex`
- `lib/rendro/page.ex`
- `lib/rendro/block.ex`
- `lib/rendro/table.ex`
- `lib/rendro/pipeline.ex`
- `lib/rendro/error.ex`
- `lib/rendro/pdf/writer.ex`
- `test/rendro_test.exs`
- `test/rendro/deterministic_test.exs`
- `test/rendro/flow_test.exs`
- `test/rendro/telemetry_test.exs`
- `test/rendro/error_test.exs`
- `test/rendro/pipeline/*.exs` — Stage-level evidence for build/compose/measure/paginate/render/validate behavior.

### Adapter and ops surfaces likely to anchor Phase 3 evidence
- `lib/rendro/adapters/phoenix.ex`
- `lib/rendro/adapters/oban/render_worker.ex`
- `lib/rendro/audit.ex`
- `lib/rendro/adapters/threadline.ex`
- `test/rendro/adapters/*.exs`
- `examples/phoenix_example/` — Example app and adoption-proof surface.

### Quality and release surfaces likely to anchor Phase 4 evidence
- `mix.exs` — `mix ci` alias, optional dependency declarations, docs extras.
- `.github/workflows/ci.yml` — CI scheduler proof surface.
- `lib/mix/tasks/verify.ex`
- `lib/mix/tasks/release/preflight.ex`
- `README.md`
- `guides/integrations.md`
- `scripts/verify_docs.exs`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing verification artifacts in Phases 05 and 06 already demonstrate the repo's preferred evidence language: observable truths, required artifacts, key link verification, behavioral spot-checks, and requirement coverage.
- The source tree already exposes clean public boundaries for many Phase 1-4 requirements: `Rendro.render/2`, `Rendro.fixed/2`, `Rendro.flow/2`, adapters, telemetry events, and Mix tasks.
- The test suite already contains useful proving surfaces for deterministic rendering, telemetry, pipeline stages, adapter behavior, and release/CI support work.

### Established Patterns
- Optional integrations are guarded with `Code.ensure_loaded?/1`, and recent phases treat optional-dependency discipline as executable behavior, not just architecture prose.
- Telemetry and structured errors are first-class product behavior, with current verification already preferring live proof over source claims.
- Documentation claims are treated as contracts and must stay synchronized with executable evidence and traceability state.

### Integration Points
- Phase 11 should map requirements directly to the public modules and tests that already prove them, then add only narrowly scoped proof gaps where existing behavior lacks a trustworthy executable trail.
- `.planning/REQUIREMENTS.md` must be updated in lockstep with each reconstructed phase `VERIFICATION.md` so the central table and per-phase evidence cannot drift apart again.
- The reconstructed Phase 1-4 artifacts should converge stylistically with the existing Phase 05/06 verification reports so maintainers see one verification language across the project.

</code_context>

<deferred>
## Deferred Ideas

- If Phase 11 uncovers real runtime defects rather than missing proof, queue those as separate remediation work instead of broadening this reconstruction phase.
- If the new `Pending`/`Done`/`Partial`/`Blocked` status vocabulary proves too heavy for the central table, simplify later only after Phase 11 lands and the tradeoff is visible in real repo usage.

</deferred>

---

*Phase: 11-reconstruct-phase-1-4-artifacts*
*Context gathered: 2026-04-28*
