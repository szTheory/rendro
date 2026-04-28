# Phase 16: phoenix-error-boundary-proof - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Convert the Phoenix adapter's structured error response from inferred behavior into a committed operator-facing boundary contract, then close `OBS-03` from current executable proof.

This phase is about proving and tightening the Phoenix adapter boundary. It does not broaden Rendro into a full app-level exception framework, redesign the core `Rendro.Error` model, or add unrelated Phoenix integration features.

</domain>

<decisions>
## Implementation Decisions

### Phoenix HTTP error contract
- **D-01:** Phase 16 should keep the Phoenix adapter responsible for an explicit operator-facing HTTP error response. Do not defer this contract to host-app-only fallback handling in this phase.
- **D-02:** For Phoenix requests resolved to `json` format, the adapter should return a structured JSON error response with HTTP status `500`, not `text/plain`.
- **D-03:** The JSON contract should expose the stable operator-facing envelope fields that Rendro already promises: `what`, `where`, `why`, `next`, `stage`, and `render_id`. Keep the wire contract small and truthful.
- **D-04:** Do not expose raw internal `reason` terms or the full `details` map as committed HTTP contract fields by default. They are useful internally, but too unstable and implementation-shaped for a durable library boundary.
- **D-05:** For non-JSON requests, retain an explicit plain-text fallback using the existing `%Rendro.Error{}` string rendering. This keeps browser/manual debugging ergonomic without forcing JSON onto every route.
- **D-06:** Request-format branching should follow Phoenix format semantics, not ad hoc raw `Accept` parsing. Use the resolved request format as the contract switch so API routes and browser-style routes behave predictably.
- **D-07:** Keep the implementation dependency-light. Do not add a new direct JSON dependency just to format this response; use the Phoenix-side facilities already present at the adapter boundary.

### Boundary proof surface
- **D-08:** The primary committed proof for `OBS-03` should live at the library-owned conn boundary in `test/rendro/adapters/phoenix_test.exs`, directly exercising `Rendro.Adapters.Phoenix`.
- **D-09:** Do not make the example Phoenix app the sole or primary proof surface for this requirement. The example app is useful supporting evidence, but the contract belongs to the library adapter.
- **D-10:** A route-level/example-app smoke proof is acceptable only as thin supporting evidence if it is cheap and non-duplicative. It is not required to close the phase.

### Canonical proving failure
- **D-11:** The canonical failure used to prove the boundary should be a deterministic paginate-stage overflow (`:content_overflow`), not timeout and not a flaky runtime path.
- **D-12:** Force the overflow with explicit geometry, such as an oversized block height, rather than text-measurement drift or long-content heuristics. The fixture should stay deterministic across environments.
- **D-13:** The boundary proof should assert the operator-facing contract, not internal implementation trivia. Assert sent state, status code, content type, and stable envelope fields/body content. Avoid brittle full-body golden assertions when shorter field-level assertions close the contract more truthfully.

### Recommendation-first downstream posture
- **D-14:** Downstream agents should treat this context as recommendation-first and locked unless a later decision would materially change public semantics beyond this phase boundary.
- **D-15:** Carry forward the user's explicit preference to shift routine implementation choices left within GSD. For similar future phases, default to one coherent recommendation set and escalate only when a decision is truly high-impact or policy-significant.

### the agent's Discretion
- Exact JSON body nesting, as long as the stable operator-facing fields remain explicit and documented.
- Whether the thin optional smoke proof lives in the example app or a tiny Phoenix harness, if planning concludes the extra witness is worth the maintenance cost.
- Exact assertion style in the tests, as long as the proof stays stable, deterministic, and boundary-focused.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and traceability
- `.planning/ROADMAP.md` — Phase 16 goal, success criteria, and requirement mapping for closing `OBS-03`.
- `.planning/REQUIREMENTS.md` — Central truth for `OBS-03` and the evidence bar for closing it.
- `.planning/v1.0-v1.0-MILESTONE-AUDIT.md` — Records `INT-PHOENIX-ERROR-BOUNDARY` and the broken `Phoenix operator-facing error response` flow this phase must close.
- `.planning/STATE.md` — Current milestone state and the fact that Phase 16 is the next remaining observability closure.

### Prior decisions that constrain this phase
- `.planning/PROJECT.md` — Product thesis, observability-as-product stance, and truthful scope boundaries.
- `.planning/METHODOLOGY.md` — Locked lenses for truthful small contracts, boundary validation first, least-surprise DX, and recommendation-first synthesis.
- `.planning/phases/01-core-deterministic-foundation/01-CONTEXT.md` — Original structured-error intent for `what/where/why/next` plus correlation metadata.
- `.planning/phases/06-pipeline-telemetry-contract/06-CONTEXT.md` — Later recommendation-first context style and stable observability contract discipline.
- `.planning/phases/10-recipe-correctness-and-traceability/10-CONTEXT.md` — Recent explicit preference to shift routine implementation decisions left and prefer narrow truthful adapter contracts.
- `.planning/phases/07-phoenix-adapter-hardening/07-VERIFICATION.md` — Existing truthful partial verdict for `OBS-03` and the exact proof gap this phase must close.
- `.planning/phases/14-milestone-verification-artifact-backfill/14-VERIFICATION.md` — Later authoritative confirmation that `OBS-03` remains open until a live Phoenix error-response proof exists.

### Live implementation surfaces
- `lib/rendro/adapters/phoenix.ex` — Current Phoenix adapter boundary, including the success branches and the existing error branch.
- `lib/rendro/error.ex` — Structured `%Rendro.Error{}` envelope and current plain-text rendering.
- `test/rendro/adapters/phoenix_test.exs` — Current success-only adapter proof surface; primary location for the new conn-boundary error proof.
- `test/rendro/flow_test.exs` — Existing deterministic overflow fixture that can anchor the canonical failing document.
- `lib/rendro/pipeline/paginate.ex` — Source of the deterministic `:content_overflow` path and its explicit geometry-based failure behavior.
- `examples/phoenix_example/lib/phoenix_example_web/router.ex` — Example app route format context; currently uses an API pipeline that accepts JSON.
- `examples/phoenix_example/config/config.exs` — Example app Phoenix error/render configuration context.
- `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` — Example controller surface if a thin supporting smoke proof is added.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `String.Chars` for `%Rendro.Error{}` already provides a usable plain-text fallback for non-JSON routes.
- `test/rendro/adapters/phoenix_test.exs` already proves the success boundary and can be extended without introducing a new test harness.
- `test/rendro/flow_test.exs` already contains a deterministic oversized-block overflow fixture that aligns with the recommended proving failure.

### Established Patterns
- Optional adapters stay narrow and compile-guarded; this phase should preserve that posture rather than inventing a broad host-app integration abstraction.
- Rendro treats documentation and verification claims as product contracts; the HTTP error boundary should therefore be explicit, small, and directly tested.
- The example Phoenix app already routes through an `:api` pipeline with `plug :accepts, ["json"]`, which makes unconditional `text/plain` error responses a least-surprise mismatch for that surface.

### Integration Points
- `lib/rendro/adapters/phoenix.ex`: add the format-aware error response mapping while preserving the existing success branches.
- `test/rendro/adapters/phoenix_test.exs`: add the committed conn-boundary proof for the error path.
- `examples/phoenix_example/...`: optionally add only a thin supporting smoke witness if planning decides it is worth the cost.
- Verification and traceability artifacts for Phase 16 must close `OBS-03` from the new boundary proof, not from source inspection alone.

</code_context>

<specifics>
## Specific Ideas

- User preference for this phase: research in parallel, synthesize one coherent recommendation set, and avoid bouncing equivalent options back unless the policy itself is truly high-impact.
- Recommended synthesis for this phase:
  - JSON error envelope for `json` format requests.
  - Plain-text fallback for non-JSON requests.
  - Primary proof at the adapter conn boundary.
  - Deterministic `:content_overflow` as the canonical failing scenario.
- Ecosystem lesson to preserve: successful Phoenix-facing libraries usually prove the contract at the seam they own, while full app routing remains secondary evidence.
- Footguns to avoid:
  - making `to_string(error)` the only public HTTP contract,
  - exposing raw internal `reason` values as stable wire data,
  - relying on raw `Accept` parsing instead of resolved Phoenix format,
  - using timeout as the canonical proof path,
  - asserting brittle full-body strings when field-level assertions are enough.

</specifics>

<deferred>
## Deferred Ideas

- Full app-owned exception/fallback integration for Rendro Phoenix consumers — valid future design space, but broader than this boundary-proof phase.
- Standardizing on RFC 9457 `application/problem+json` — potentially valuable later if Rendro needs a broader cross-language HTTP API contract, but heavier than needed for this closure phase.
- Rich example-app route smoke coverage beyond a minimal witness — useful only if it stays clearly secondary to the library-owned contract proof.

</deferred>

---

*Phase: 16-phoenix-error-boundary-proof*
*Context gathered: 2026-04-28*
