# Phase 54: Proof Closure and Release Tail - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Close `v1.10` by recording the proof needed to promote any `protection` viewer claims truthfully and by finishing the narrow release tail for the next Hex publish. This phase does not widen the protection product surface, add new adapter APIs, redefine support-matrix semantics, or broaden the release workflow into a larger integration-doc effort.

</domain>

<decisions>
## Implementation Decisions

### Viewer promotion policy
- **D-01:** Keep `protection` viewer promotion **per viewer**, not all-or-nothing. If Adobe Acrobat Reader independently passes the Phase 54 checklist, promote only `adobe_acrobat_reader`; keep `apple_preview` `unverified` until it independently passes.
- **D-02:** Do not require Acrobat Reader and Apple Preview to pass in the same phase before promoting either one. That would turn proof closure into parity theater instead of evidence-first support publication.
- **D-03:** Do not leave both viewers `unverified` if one independently passes the full checklist. Rendro should publish the smallest truthful proven contract, not wait for symmetry.

### Manual proof checklist shape
- **D-04:** Use one focused lifecycle checklist for `protection`, not a minimal open-only check and not a broad compatibility matrix.
- **D-05:** The named proof items should be:
  - `opens_with_open_password`
  - `displays_authored_content_correctly`
  - `advisory_print_behavior`
  - `advisory_copy_behavior`
  - `save_and_reopen_readability`
- **D-06:** Record viewer name, version when easily available, OS, fixture path/name, date checked, per-check pass/fail, and one short notes field.
- **D-07:** Treat owner-password-only success as an **observation**, not a pass condition and not a supported viewer path. The normative public story remains open-password-first.

### Failure posture and support-matrix semantics
- **D-08:** Do not invent new public support states such as `partial`, `caveated`, or `supported_with_notes` for Phase 54.
- **D-09:** If a viewer opens the protected PDF correctly but fails an advisory-permission proof item, keep that viewer row `unverified`.
- **D-10:** Record surprising behavior in the Phase 54 validation/proof notes and, where needed, in family-level guide wording. Do not promote the viewer row anyway and do not split the canonical contract across competing status vocabularies.
- **D-11:** Preserve the existing meaning of `supported`: a named viewer passed the recorded checklist for the named surface. Do not relax that meaning for the `protection` family.

### Release-tail scope
- **D-12:** Keep `54-02` narrow: changelog readiness, release-preflight readiness, and publish-tail closure remain the core of the plan.
- **D-13:** Include one thin downstream packaging layer in the release tail: a short release-note or publish-tail callout that points Phoenix/Mailglass users to the already-canonical protected-delivery recipe from Phase 53.
- **D-14:** That downstream callout must stay a pointer, not a new integration-doc expansion. It should reinforce:
  - `render_to_artifact -> Protect.password -> store/deliver`
  - no passwords in persisted Oban args
  - Mailglass transports protected artifacts, not password material
- **D-15:** Do not reopen Phase 53 by adding new Mailglass APIs, new orchestration helpers, or a broader protected-delivery tutorial surface in Phase 54.

### Recommendation posture for downstream GSD work
- **D-16:** Shift the maintainer preference left for this and future GSD work: default to one cohesive recommendation set that optimizes for truthful small contracts, least surprise DX, and high-signal proof surfaces instead of surfacing broad menus of equivalent options.
- **D-17:** Escalate only when a choice would materially change public semantics, widen the support contract, or redefine the release/security posture in a way the maintainer is likely to care about directly.

### the agent's Discretion
- Exact proof-table formatting and terminology, as long as the checklist items above remain explicit and stable.
- Exact fixture path and proof-command wiring, as long as the proof lane stays small, reproducible, and clearly separate from structural validation.
- Exact placement of the thin protected-delivery release note, as long as it points back to the canonical Phase 53 guidance instead of forking it.

</decisions>

<specifics>
## Specific Ideas

- Recommended viewer-promotion posture:
  - promote `adobe_acrobat_reader` as soon as it independently passes
  - keep `apple_preview` `unverified` until it independently passes
  - continue treating `unverified` as distinct from `unsupported`
- Recommended checklist wording:
  - “opens with open password”
  - “authored content renders correctly after open”
  - “viewer’s print UI/behavior reflects the advisory print flag”
  - “viewer’s copy/select behavior reflects the advisory copy flag”
  - “saved output reopens and remains readable”
- Recommended failure-note posture:
  - if advisory flags are ignored, note that behavior explicitly in validation notes
  - do not create a `partial` public state
  - do not promote the viewer row on open-only success
- Recommended release-tail wording direction:
  - “v1.10 closes the external protected-delivery story for downstream Phoenix apps.”
  - “Use `Rendro.Protect.password/2` on a rendered artifact, then pass the protected artifact through storage or Mailglass transport seams.”
  - “Protection remains password-to-open plus advisory permissions; it is not signing, tamper evidence, or compliance support.”
- Ecosystem lessons to preserve:
  - publish the smallest independently proven contract, not a parity badge
  - avoid “secure PDF” shorthand that collapses encryption, permissions, integrity, and compliance into one claim
  - keep release notes concise and feature-scoped, with pointers to canonical guides instead of duplicative tutorials

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement scope
- `.planning/PROJECT.md` — v1.10 product posture, truthful-boundary constraints, and release goals.
- `.planning/REQUIREMENTS.md` — `TRUST-03` and `RELEASE-01` define the required Phase 54 outcomes.
- `.planning/STATE.md` — active milestone status and locked upstream decisions.
- `.planning/milestones/v1.10-ROADMAP.md` — Phase 54 goal and plan split.

### Prior proof and support-boundary precedent
- `.planning/METHODOLOGY.md` — truthful small contracts, boundary validation first, least surprise DX, and recommendation-first posture.
- `.planning/phases/47-form-validation-and-viewer-proof-closure/47-CONTEXT.md` — named-viewer proof philosophy and small support-matrix posture.
- `.planning/phases/47-form-validation-and-viewer-proof-closure/47-VALIDATION.md` — prior manual viewer-proof lane shape.
- `.planning/phases/50-support-boundary-and-proof-closure/50-CONTEXT.md` — per-surface viewer-claim posture and split proof lanes.
- `.planning/phases/52-qpdf-adapter-and-structural-validation/52-CONTEXT.md` — open-password-first contract and owner-password fallback boundary.
- `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-CONTEXT.md` — protected-delivery recipe and narrow support-contract wording.
- `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-VALIDATION.md` — latest protection docs/runtime closure posture.
- `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md` — verified transport/storage truth that Phase 54 should package, not reopen.

### Live contract and release surfaces
- `priv/support_matrix.json` — current `protection` family shape and viewer rows.
- `guides/api_stability.md` — current public wording for protection boundaries and viewer posture.
- `guides/integrations.md` — canonical protected-delivery recipe for Oban/Mailglass-facing users.
- `lib/mix/tasks/release/preflight.ex` — strict release-tail gate.
- `scripts/release_preflight_proof.exs` — exact-tag proof helper for release parity.
- `.github/workflows/ci.yml` — existing CI and release-proof automation.
- `.github/workflows/release.yml` — current tag-triggered publish workflow.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `priv/support_matrix.json`: already has the exact `supported | unsupported | unverified` posture and `protection.viewers` rows that Phase 54 should preserve.
- `guides/api_stability.md`: already distinguishes password-to-open, advisory permissions, and unsupported security/compliance narratives; Phase 54 should only sync proof-backed viewer wording into this surface.
- `guides/integrations.md`: already carries the canonical protected-delivery recipe, so the release tail should point to it rather than duplicate it.
- `lib/mix/tasks/release/preflight.ex` and `scripts/release_preflight_proof.exs`: already define the strict publish-tail contract and isolated proof path.

### Established Patterns
- Rendro promotes viewer claims independently per viewer and per surface.
- Structural proof and manual viewer proof are separate lanes and should stay separate.
- Support matrices and human docs move together when public claims change.
- Release-tail work should close truth surfaces and publish readiness, not reopen product scope.

### Integration Points
- Phase 54 will primarily touch validation/proof artifacts, support-matrix viewer rows, public wording, changelog/release-tail surfaces, and docs-contract or proof checks that freeze those claims.
- Viewer-proof outcomes must feed back into `priv/support_matrix.json` and `guides/api_stability.md` in the same change set.
- Release-tail packaging should connect Phase 53’s protected-delivery story to the Hex publish surface without creating a second canonical integration guide.

</code_context>

<deferred>
## Deferred Ideas

- A broader viewer-certification matrix covering more viewers, more permission nuances, or UI-specific warning behavior.
- Any new support-matrix public state such as `partial` or `supported_with_caveats`.
- Owner-password fallback as a promoted viewer-proof path.
- Expanded Mailglass/protected-delivery tutorial work beyond a thin release-note pointer.
- Native in-core encryption, signatures, tamper-evidence, compliance/archive claims, or other security-surface widening beyond `v1.10`.

</deferred>

---

*Phase: 54-proof-closure-and-release-tail*
*Context gathered: 2026-05-06*
