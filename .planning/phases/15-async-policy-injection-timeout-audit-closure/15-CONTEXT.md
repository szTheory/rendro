# Phase 15: async-policy-injection-timeout-audit-closure - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Restore the two remaining Phase 08/14 audit seams without widening Rendro's product scope:

1. Make `Rendro.Adapters.Oban.RenderWorker` inject bounded-render policies from job args into the document before render so async rendering truthfully closes `ADPT-04`.
2. Make pipeline timeouts reach the top-level render telemetry/audit surface so Threadline can observe them, truthfully closing the timeout side of `OBS-04` and removing the remaining recipe-level audit gap contributing to `ADPT-05`.

This phase closes contract drift. It does not introduce a richer async orchestration API, generic option pass-through, new audit event families, or a broader adapter abstraction.

</domain>

<decisions>
## Implementation Decisions

### Async policy precedence
- **D-01:** Document-authored policies remain the primary contract. The Oban adapter may inject `max_pages`, `max_bytes`, and `timeout` from job args only when those policies are missing from the document.
- **D-02:** Job args do not silently override document policies by default. Silent override would make the same document behave differently between sync and async paths and would weaken Rendro's least-surprise DX.
- **D-03:** Conflict-fail-fast semantics are not the default for this phase. They are more truthful than silent override, but they add operational friction and retry noise for a closure phase whose primary goal is to restore the originally claimed bounded-async behavior.
- **D-04:** If stricter precedence modes are ever needed later, they must be explicit adapter policy, not hidden default behavior. A future adapter option such as `policy_precedence: :fill_missing | :override | :error_on_conflict` is acceptable as a separate design, not part of this closure phase.

### Async worker boundary contract
- **D-05:** The Oban adapter exposes a small explicit policy surface: `max_pages`, `max_bytes`, and `timeout`. No generic pass-through from job args into `doc.options` or `Rendro.render/2`.
- **D-06:** Known policy keys are validated strictly at the worker boundary. Invalid values or shapes must fail with a typed adapter error rather than raising or being silently ignored.
- **D-07:** Unknown policy keys fail fast if they are presented as Rendro policy input. This protects operators from typo-driven loss of safety bounds.
- **D-08:** Unrelated top-level job metadata is not part of Rendro's policy contract. The worker should stay narrow about what it consumes and should not claim ownership of arbitrary producer metadata beyond the documented required keys.
- **D-09:** The worker boundary should match the stricter, typed-error posture used by other optional adapters. Raw `FunctionClauseError` and `String.to_existing_atom/1` crashes are not acceptable as the primary misuse contract after this phase.

### Timeout audit semantics
- **D-10:** A timeout is a normal failed render, not a synthetic crash class. The primary top-level timeout signal is `[:rendro, :render, :stop]` with `status: :error`, not a custom timeout event or a fake top-level `:exception`.
- **D-11:** Timeout classification lives in metadata, not in a new action or event family. The top-level stop metadata should include the same low-cardinality error shape used elsewhere, with timeout represented as `error.kind: :timeout` and stage `:render`.
- **D-12:** Threadline continues to map timeout to the existing `:render_failed` audit action. Operators should be able to query all failed renders in one place and then filter by timeout subtype when needed.
- **D-13:** Do not introduce `:render_timed_out` or `[:rendro, :render, :timeout]` as the primary public contract in this phase. That would split failure semantics, increase consumer complexity, and violate the project's preference for smaller truthful surfaces.
- **D-14:** The timeout path must close the top-level telemetry lifecycle cleanly. A render timeout should no longer leave a top-level `[:rendro, :render, :start]` without a matching terminal event.

### Telemetry and measurement discipline
- **D-15:** Synthetic timeout stop metadata must preserve the established top-level schema (`render_id`, `document_type`, `deterministic`, `stage`, `status`, `page_count`, `byte_size`, optional `error`) so downstream handlers do not need a timeout-specific parser.
- **D-16:** Any timeout measurement emitted on the synthetic top-level stop must respect telemetry conventions. Do not publish raw millisecond timeout values as if they were native monotonic duration measurements.

### Downstream agent posture
- **D-17:** For this phase, downstream agents should default to recommendation-first synthesis: collapse the researched trade space into one coherent default unless a choice would materially change public semantics beyond the locked closure target.
- **D-18:** The preferred decision lens for this phase is: smallest truthful contract, boundary validation first, deterministic behavior, and least surprise for both library users and operators.

### the agent's Discretion
- Exact typed-error tuple shapes for invalid Oban worker inputs, as long as they are explicit, non-raising, and document the offending policy key or field.
- Whether policy input lives at the top level or under a nested `"policies"` key, as long as the public docs and tests make the accepted shape explicit and the final contract remains narrow.
- Whether Threadline should additionally forward a convenience `reason: :timeout` field alongside the nested `error` map, as long as `:render_failed` remains the primary action and the top-level stop metadata stays stable.

</decisions>

<specifics>
## Specific Ideas

- Recommendation-first synthesis from the discussion:
  - Preserve document policies when present; async job args fill missing bounds only.
  - Treat timeout as an ordinary failed render with timeout subtype metadata.
  - Tighten the Oban worker boundary instead of making it more permissive or magical.
- The key DX risk to avoid is async-only semantic drift: a document that behaves one way synchronously and another way asynchronously without explicit opt-in.
- The key operator UX risk to avoid is split failure classification: timeouts should appear in the same failed-render surfaces as other failures, with subtype metadata for filtering.
- If the worker contract can still be shaped without roadmap conflict, a nested `"policies"` map is cleaner than scattering policy keys at the job-arg top level. This is a quality preference, not a locked requirement.
- User preference to shift left within GSD: future work should default more strongly toward researched recommendations and only escalate menus of options when the policy itself is likely to matter to the user.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary and milestone closure
- `.planning/ROADMAP.md` — Phase 15 goal, requirements, and success criteria for async policy injection and timeout audit closure.
- `.planning/REQUIREMENTS.md` — Central truth for `ADPT-04`, `ADPT-05`, and `OBS-04`.
- `.planning/v1.0-MILESTONE-AUDIT.md` — Authoritative statement of the two active seams: `INT-ASYNC-POLICY-INJECTION` and `INT-TIMEOUT-AUDIT-HANDOFF`.
- `.planning/STATE.md` — Current milestone state and later-phase traceability posture.

### Prior decisions that constrain this phase
- `.planning/PROJECT.md` — Pure-core boundary, data-first pipeline shape, and observability-as-product stance.
- `.planning/METHODOLOGY.md` — Truthful small contracts, boundary validation first, deterministic formatting, least-surprise DX, and recommendation-first escalation posture.
- `.planning/phases/06-pipeline-telemetry-contract/06-CONTEXT.md` — Stable telemetry schema and stage/error semantics that timeout closure must preserve.
- `.planning/phases/08-bounded-async-timeout-telemetry/08-VERIFICATION.md` — Current truthful partial verdict for bounded async and timeout audit behavior.
- `.planning/phases/10-recipe-correctness-and-traceability/10-CONTEXT.md` — Recent explicit preference for narrow truthful contracts and typed adapter boundary failures.
- `.planning/phases/14-milestone-verification-artifact-backfill/14-VERIFICATION.md` — Central precedence and the later-phase confirmation that the async/audit seams remain open.

### Live implementation surfaces
- `lib/rendro/adapters/oban/render_worker.ex` — Current worker gap: no policy injection and brittle boundary behavior.
- `lib/rendro/pipeline.ex` — Current timeout path and top-level telemetry lifecycle.
- `lib/rendro/adapters/threadline.ex` — Current top-level telemetry subscription and failure mapping.
- `test/rendro/policy_test.exs` — Existing proof that policy enforcement works only when policies already live on the document.
- `test/rendro/adapters/threadline_test.exs` — Existing proof for success and non-timeout failure audit mapping.
- `test/docs_contract/integrations_claims_test.exs` — Current docs-contract proof that timeout does not yet reach Threadline.
- `guides/integrations.md` — Public adapter contract surface that must stay truthful after closure.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Pipeline` already has the canonical render-policy enforcement points for `max_pages`, `max_bytes`, and `timeout`; Phase 15 should restore the missing async handoff into those existing core semantics rather than inventing new policy logic.
- `Rendro.Adapters.Threadline` already exposes the right failure action (`:render_failed`) and forwards enough metadata to classify failures by subtype once timeout reaches the top-level stop path.
- Existing adapter tests and docs-contract tests already define the truth surfaces that Phase 15 needs to flip from partial to closed.

### Established Patterns
- Optional adapters are compile-guarded and should expose small explicit contracts, not generic magic.
- Adapter misuse should resolve to typed failures where feasible, not incidental runtime crashes.
- Top-level telemetry should keep a stable stop/exception surface with low-cardinality metadata, not proliferate custom event names.
- Later planning artifacts in this repo prefer recommendation-first synthesis over asking the user to choose among equivalent implementation-discipline options.

### Integration Points
- `lib/rendro/adapters/oban/render_worker.ex`: add the normalization/validation layer that maps documented job-arg policies into `doc.options[:policies]`.
- `lib/rendro/pipeline.ex`: close the timeout lifecycle with a top-level terminal telemetry event that matches existing stop metadata conventions.
- `lib/rendro/adapters/threadline.ex`: ensure timeout metadata forwarded from the top-level stop is sufficient for audit filtering without creating a new action family.
- `test/rendro/adapters/`: add dedicated worker-path coverage for policy injection and boundary validation.
- `test/docs_contract/integrations_claims_test.exs`: flip the timeout limitation proof into timeout audit closure proof.
- `guides/integrations.md` and `.planning/REQUIREMENTS.md`: keep public docs and verification truth aligned to the narrowed final contract.

</code_context>

<deferred>
## Deferred Ideas

- Explicit configurable precedence modes for async policy conflicts (`:override`, `:error_on_conflict`) — useful, but broader than this closure phase.
- A dedicated timeout-specific audit action or event family — only worth considering if future operators demonstrate a real need that metadata filtering cannot satisfy.
- Generalized job-arg schema or a behavior/protocol for async adapter input normalization — out of scope for this closure phase.

</deferred>

---

*Phase: 15-async-policy-injection-timeout-audit-closure*
*Context gathered: 2026-04-28*
