# Phase 53 Discussion Log

**Phase:** 53 - Delivery Threading and Truthful Support Contract
**Date:** 2026-05-06
**Mode:** Discuss all gray areas with advisor-style parallel research

## Summary

All identified gray areas were discussed through parallel subagent research and collapsed into one cohesive recommendation set optimized for:

- truthful small contracts
- least-surprise DX
- Elixir/Phoenix ecosystem fit
- application-owned secret boundaries
- compact but explicit support claims

## Areas Discussed

### Async handoff shape

**Options considered**

| Option | Description | Outcome |
|---|---|---|
| Keep Oban render-only | App owns `render -> protect -> store/deliver` and fetches secrets at execution time | Chosen |
| Add a narrow post-render helper/behaviour | Rendro standardizes a small handoff helper without owning the queue | Rejected |
| Add a first-party protected async worker/orchestrator | Rendro owns protected async orchestration | Rejected |

**Reasoning**

- Render-only Oban is the most idiomatic library posture for Elixir/Phoenix.
- Persisted job args should carry identifiers, not passwords or password refs that become part of Rendro’s public async contract.
- The best DX improvement is a strong documented recipe, not a wider orchestration API.

**Locked decision**

- Phase 53 keeps async protected delivery application-owned and recipe-driven.

### Storage contract depth

**Options considered**

| Option | Description | Outcome |
|---|---|---|
| Transport-only retrieval | Storage may reload bytes without protection metadata | Rejected |
| Narrow behaviour plus richer first-party example | Keep behaviour small, but first-party examples preserve `metadata.protection` through a sidecar/manifest | Chosen |
| Full round-trip storage contract | Require all storage adapters to round-trip artifact metadata | Rejected |

**Reasoning**

- Silent metadata loss in Rendro-owned examples would violate least surprise.
- Forcing all storage adapters to persist rich metadata would overreach the library boundary.
- The best balance is a narrow behaviour with richer first-party example semantics.

**Locked decision**

- Phase 53 keeps `Rendro.Storage` narrow while improving first-party retrieval examples to preserve protection metadata.

### Delivery adapter posture

**Options considered**

| Option | Description | Outcome |
|---|---|---|
| Keep Mailglass fully agnostic with no further guidance | No code/docs clarification beyond current state | Rejected |
| Keep Mailglass transport-only but clarify `attach_pdf/3` vs `attach_artifact/3` | Protected path stays artifact-first and explicit | Chosen |
| Add protected-delivery convenience API | Adapter accepts protection options or adds a protected helper | Rejected |

**Reasoning**

- Optional adapters should transport artifacts, not absorb crypto policy.
- `attach_artifact/3` is already the honest protected-delivery seam.
- The ambiguity to fix is documentation and contract clarity, not missing delivery functionality.

**Locked decision**

- Mailglass remains transport-only; protected delivery is `Protect.password/2` followed by `attach_artifact/3`.

### Protection contract granularity

**Options considered**

| Option | Description | Outcome |
|---|---|---|
| Keep current compact contract only | Rely mostly on guide prose for nuance | Rejected |
| Add a small explicit `boundaries` subsection | Keep family compact, add first-class anti-misread leaves | Chosen |
| Expand into a large taxonomy | Detailed matrix for every protection nuance | Rejected |

**Reasoning**

- The current matrix is directionally right but still leaves key boundary rules too implicit.
- A small `boundaries` block preserves the Phase 50 family-first pattern without turning the contract into a compatibility database.
- The machine-readable and human-readable stories should stay in lockstep.

**Locked decision**

- Extend `protection` with a small explicit `boundaries` subsection and keep the rest compact.

## Cross-Area Synthesis

The chosen directions are intentionally cohesive:

- protection policy stays at the artifact boundary
- async orchestration stays application-owned
- delivery adapters transport protected bytes but never secrets
- storage behaviour stays small, while first-party examples avoid semantic surprise
- support artifacts name the boundary rules explicitly without widening scope into framework features or security overclaims

## User Preference Captured

The user explicitly requested that future GSD work shift this decision posture left:

- default to one coherent recommendation set
- optimize for principle of least surprise, strong DX, and good architecture
- escalate only for truly high-impact product-semantic decisions

This preference was captured in `53-CONTEXT.md` as a downstream default for research and planning.

## Deferred Ideas

- First-party protected async worker/orchestrator
- Mailglass protected convenience APIs
- Universal storage round-trip metadata requirement
- Large protection taxonomy or compatibility-database-style matrix

---

Decisions are captured in `53-CONTEXT.md`. This log preserves the alternatives considered and why they were accepted or rejected.
