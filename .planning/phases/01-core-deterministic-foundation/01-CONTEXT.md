# Phase 1: Core Deterministic Foundation - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a pure Elixir core document/render pipeline that can produce valid PDFs deterministically, while establishing lifecycle telemetry and structured render diagnostics. Optional Phoenix/job adapters, advanced pagination behavior, and ecosystem recipes stay out of this phase.

</domain>

<decisions>
## Implementation Decisions

### Core Boundary and API Contract
- **D-01:** Phase 1 stays core-only. Adapters remain deferred so the initial contract proves pure-core operation first.
- **D-02:** The phase establishes a data-first pipeline contract with explicit stage boundaries (`build -> compose -> measure -> paginate -> render -> validate`) as the canonical API shape.

### Deterministic Contract
- **D-03:** Deterministic mode normalizes ordering, object identifiers, timestamps, and metadata fields that otherwise cause fixture drift.
- **D-04:** Deterministic behavior is opt-in and explicit (for CI fixtures/tests), not hidden behind implicit environment behavior.

### Telemetry Schema
- **D-05:** Lifecycle instrumentation emits stage-level `start/stop/exception` events for each core pipeline stage.
- **D-06:** Event metadata includes `render_id`, document type, deterministic flag, status, duration, page count, and output byte size.

### Structured Error Surface
- **D-07:** Core errors use a stable envelope that communicates what failed, where it failed, why it failed, and concrete next actions.
- **D-08:** Structured errors include correlation metadata (`render_id`, stage) so operators can jump directly from failures to telemetry traces.

### Claude's Discretion
- Exact naming for modules/structs implementing the pipeline stages.
- Final telemetry event namespace shape as long as stage coverage and metadata contract remain intact.
- Error wording style and helper constructors, provided the envelope fields above remain stable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product and phase scope
- `.planning/PROJECT.md` — Product thesis, constraints, and non-negotiable core boundary.
- `.planning/REQUIREMENTS.md` — Phase-linked requirements (`CORE-01`, `CORE-02`, `CORE-05`, `OBS-01`, `OBS-03`).
- `.planning/ROADMAP.md` — Phase goals, success criteria, and plan structure.

### Research guidance
- `.planning/research/SUMMARY.md` — Recommended phase ordering and deterministic-first rationale.
- `.planning/research/ARCHITECTURE.md` — Data-first pipeline and boundary patterns.
- `.planning/research/PITFALLS.md` — Known failure modes (scope drift, non-determinism, weak observability).

### Seed context and source intent
- `prompts/rendro-gsd-seed.md` — Initial product framing and phase intent.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Deep domain constraints and architecture direction.
- `prompts/rendro-oss-dna.md` — OSS quality and release posture expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No production Elixir source modules exist yet; this phase will establish the first core implementation surface.
- Existing planning/research artifacts provide reusable contract language for pipeline stages, telemetry, and error semantics.

### Established Patterns
- Project artifacts consistently enforce pure-core boundaries with optional adapters introduced later.
- Deterministic vs advisory verification separation is already treated as a first-class quality pattern.

### Integration Points
- Phase 1 should define stable core interfaces that future Phase 2-5 work can consume without introducing adapter dependencies.
- Telemetry/error contracts created here become the integration backbone for later Phoenix/job adapters.

</code_context>

<specifics>
## Specific Ideas

- Favor predictable contracts over early breadth: lock deterministic and observability behavior now, then extend features in later phases.
- Keep phase output implementation-ready for `01-01` (core skeleton) and `01-02` (determinism + telemetry/errors) plan generation.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-core-deterministic-foundation*
*Context gathered: 2026-04-24*
