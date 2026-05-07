# Phase 53: Delivery Threading and Truthful Support Contract - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Keep protected artifacts composable with existing delivery and storage seams while publishing one canonical, truthful support boundary for the `protection` surface. This phase closes delivery-threading and support-contract ambiguity around work already introduced in Phases 51 and 52. It does not add native in-core encryption, a first-party protected async orchestrator, password-bearing job args, or broader security/compliance claims.

</domain>

<decisions>
## Implementation Decisions

### Async handoff shape
- **D-01:** Keep `Rendro.Adapters.Oban.RenderWorker` render-only in Phase 53. Do not add a first-party protected async worker or queue-aware orchestrator.
- **D-02:** The canonical async protected-delivery story is application-owned: `build -> render_to_artifact -> protect -> store/deliver`, with secrets fetched at execution time inside the application boundary rather than persisted in Oban args.
- **D-03:** Rendro should ship one strong copyable recipe for protected async delivery instead of a new orchestration API: identifiers in job args, late password resolution, and explicit downstream storage/delivery handoff.

### Storage contract depth
- **D-04:** Keep `Rendro.Storage` itself narrow: protected bytes must persist and retrieve without the storage seam learning passwords.
- **D-05:** Do not widen the `Rendro.Storage` behaviour so every adapter must round-trip full artifact metadata.
- **D-06:** First-party storage examples and first-party simple adapters that support `get/2` should preserve `artifact.metadata.protection` across reload via an explicit sidecar/manifest or equivalent metadata envelope, so Rendro’s own examples do not drop protection semantics after retrieval.
- **D-07:** Docs must distinguish clearly between the narrow behaviour contract and richer first-party example patterns, so custom adapters are not over-promised while least-surprise DX is preserved.

### Delivery adapter posture
- **D-08:** Keep Mailglass transport-only. Do not add `attach_protected_pdf/4`, `protect:` options, or any delivery-adapter-owned protection policy.
- **D-09:** `attach_pdf/3` should remain the plain render-and-attach convenience path for unprotected PDFs only.
- **D-10:** The canonical protected-delivery path is `Rendro.Protect.password/2` first, then `Rendro.Adapters.Mailglass.attach_artifact/3`.
- **D-11:** Mailglass docs, moduledoc, and docs-contract tests should make the boundary explicit: Mailglass transports already-protected bytes but never accepts, persists, derives, or manages password material.

### Protection contract granularity
- **D-12:** Preserve the existing family-first `protection` support-matrix shape from Phase 50 rather than redesigning it into a larger taxonomy.
- **D-13:** Add a small explicit `protection.boundaries` subsection to the machine-readable contract for the highest-risk misreads:
  - external-hook-only posture
  - password material does not belong in persisted async job args
  - delivery/storage seams transport protected artifacts, not passwords
- **D-14:** Keep the rest of the `protection` family compact and product-facing: capabilities, algorithms, behaviors, viewers.
- **D-15:** Human docs and docs-contract tests must lock the same boundary story as the matrix: password-to-open is supported through an external artifact-first hook; advisory permissions are honor-system only; protection is not signing, tamper evidence, compliance, or native in-core encryption.

### Downstream GSD default
- **D-16:** Shift the user’s preference left into downstream GSD work for this phase and similar work: default to one cohesive recommendation set that already optimizes for least surprise, truthful boundaries, Elixir/Phoenix idioms, and strong DX rather than escalating menus of equivalent options.
- **D-17:** Escalate only if a choice would materially change product semantics, widen the public support claim, or move Rendro toward framework-like orchestration rather than a narrow library boundary.

### the agent's Discretion
- Exact naming of the new support-matrix `boundaries` leaves, as long as they remain small, explicit, and policy-level rather than seam-exhaustive.
- Exact shape of the first-party sidecar/manifest storage example, as long as it preserves `metadata.protection` without implying every storage adapter must do the same.
- Exact wording and placement of async protected-delivery recipes in guides, as long as late secret resolution and application-owned orchestration remain the normative path.

</decisions>

<specifics>
## Specific Ideas

- Preferred async protected-delivery recipe:
  - Oban job args carry business identifiers only
  - worker builds document
  - worker renders artifact
  - worker fetches passwords from app-owned secret source at execution time
  - worker protects artifact
  - worker stores or delivers the protected artifact
- Preferred Mailglass wording:
  - `attach_pdf/3` attaches a rendered unprotected PDF
  - protected delivery uses `attach_artifact/3` with a previously protected `%Rendro.Artifact{}`
  - Mailglass never knows the passwords
- Preferred storage example direction:
  - PDF bytes plus adjacent manifest/metadata record
  - `get/2` rebuilds an artifact including `metadata.deterministic` and `metadata.protection`
  - do not treat raw blob re-read as equivalent to full artifact reconstruction unless metadata is actually preserved
- Preferred support-matrix additions:
  - `protection.boundaries.external_hook_only`
  - `protection.boundaries.passwords_in_persisted_job_args`
  - `protection.boundaries.delivery_seams_transport_bytes_not_passwords`
- Ecosystem lessons to preserve:
  - Oban/Sidekiq style background jobs should persist small identifiers, not secrets
  - attachment helpers should transport prepared artifacts, not absorb cross-cutting crypto policy
  - storage abstractions should not pretend raw bytes automatically recreate richer domain metadata
  - security-feature docs should name unsupported narratives explicitly to avoid over-inference
- User preference to preserve:
  - downstream GSD should synthesize one coherent recommendation set by default and only escalate very impactful policy calls

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement scope
- `.planning/PROJECT.md` — v1.10 milestone goal, product posture, and non-negotiable truthful-boundary constraints.
- `.planning/REQUIREMENTS.md` — `ADAPT-03`, `TRUST-01`, and `TRUST-02` define the required Phase 53 outcomes.
- `.planning/STATE.md` — active milestone state and prior decisions already locked for v1.10.
- `.planning/milestones/v1.10-ROADMAP.md` — Phase 53 goal, dependency chain, and plan split.

### Prior locked decisions
- `.planning/METHODOLOGY.md` — truthful small contracts, boundary validation first, least-surprise DX, and shift-left recommendation posture.
- `.planning/phases/50-support-boundary-and-proof-closure/50-CONTEXT.md` — support-matrix shape, viewer-claim posture, and truthful docs-contract precedent.
- `.planning/phases/51-protection-api-contract-and-validation/51-CONTEXT.md` — artifact-first protection seam, secret redaction rules, and delivery-boundary posture.
- `.planning/phases/52-qpdf-adapter-and-structural-validation/52-CONTEXT.md` — structural-validation boundary and narrow public protection semantics that Phase 53 must preserve.

### Live contract and integration seams
- `lib/rendro/protect.ex` — public protection boundary and protected-artifact metadata contract.
- `lib/rendro/artifact.ex` — artifact wrapper seam and metadata preservation model.
- `lib/rendro/adapters/oban/render_worker.ex` — current render-only async worker boundary that Phase 53 should clarify rather than widen.
- `lib/rendro/adapters/mailglass.ex` — delivery adapter seam and existing `attach_artifact/3` path for protected artifacts.
- `lib/rendro/storage.ex` — narrow storage behaviour contract.
- `lib/rendro/storage/local.ex` — first-party simple storage example whose retrieval semantics may need alignment with protected-artifact metadata.
- `guides/integrations.md` — canonical adapter and workflow guidance for Oban and Mailglass.
- `guides/api_stability.md` — human-facing support-boundary language for the `protection` family.
- `priv/support_matrix.json` — machine-readable protection support contract to extend.

### Docs-contract and regression seams
- `test/docs_contract/protection_claims_test.exs` — support-matrix and protection wording lockstep tests.
- `test/docs_contract/integrations_claims_test.exs` — integration wording and protected-artifact transport contract tests.
- `test/rendro/adapters/mailglass_test.exs` — adapter behavior regression seam.
- `test/rendro/adapters/oban/render_worker_test.exs` — current narrow async-worker contract seam.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Protect.password/2` already establishes the real protected-artifact contract and should remain the sole protection policy owner.
- `Rendro.Adapters.Mailglass.attach_artifact/3` already transports protected artifacts without learning passwords.
- `Rendro.Adapters.Oban.RenderWorker` already models a narrow, typed, render-only async seam and should be clarified rather than widened.
- `Rendro.Artifact.wrap/3` already gives a clean place to preserve protection metadata through post-render transforms.

### Established Patterns
- Rendro prefers explicit narrow boundaries over queue magic, broad orchestration helpers, or hidden policy.
- Optional adapters stay optional and should own transport/integration shape, not absorb adjacent product semantics.
- Machine-readable support data and human docs are expected to move together in the same phase.
- Artifact metadata is meaningful product behavior; Rendro-owned examples should not silently discard it in common reload flows.

### Integration Points
- Phase 53 should primarily touch support artifacts, guides, docs-contract tests, and possibly first-party simple storage example behavior.
- Protected async workflows must compose with Oban, Mailglass, and storage patterns without passwords entering persisted job args or adapter APIs.
- Any storage-example enhancement must preserve the narrow `Rendro.Storage` behaviour while improving least-surprise semantics in Rendro’s own examples.

</code_context>

<deferred>
## Deferred Ideas

- A first-party protected async worker or queue-aware orchestrator.
- Delivery-adapter APIs such as `attach_protected_pdf/4` or `protect:` options on `attach_pdf/3`.
- Widening `Rendro.Storage` so all adapters must round-trip rich artifact metadata.
- A large support-matrix taxonomy for every protection nuance, validator mode, or delivery seam.
- Native in-core encryption, digital signatures, tamper-evidence claims, PDF/A/compliance narratives, or broader security marketing.

</deferred>

---

*Phase: 53-delivery-threading-and-truthful-support-contract*
*Context gathered: 2026-05-06*
