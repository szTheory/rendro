# Phase 51: Protection API Contract and Validation - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the public artifact-first protection seam and typed option validation for password-to-open PDF protection without changing `Rendro.render/2` semantics, without introducing authored protection state on the document, and without widening scope into native in-core encryption, digital signatures, or broader compliance/security claims.

</domain>

<decisions>
## Implementation Decisions

### Public API shape and composition
- **D-01:** `Rendro.Protect.password/2` is the canonical public API for Phase 51. Protection remains an artifact-first post-render transform, not a render-stage option and not authored document state.
- **D-02:** `Rendro.render_protected/3` is acceptable as thin convenience sugar, but docs and examples must present it explicitly as delegation to `render -> artifact -> protect`, not as a separate semantic path.
- **D-03:** Do not add protection options to `Rendro.render/2`, `Rendro.render_to_artifact/2`, or any document-level builder/state in Phase 51.

### Password contract
- **D-04:** Require both `open_password` and `owner_password` on the public protection API.
- **D-05:** Reject missing, empty, or non-binary passwords with typed `:protect`-stage errors. Do not derive, duplicate, randomize, or silently default one password from the other.
- **D-06:** Do not expose owner-only, open-password-only, blank-password, or other looser password combinations in Phase 51, even if lower-level tools permit them.

### Advisory permissions surface
- **D-07:** Keep `advisory_permissions` in the public API, but only as a small curated whitelist of common permission atoms.
- **D-08:** The public contract must keep calling these permissions `advisory` and must document that they are viewer-honored-at-best rather than enforced security guarantees.
- **D-09:** Do not expose broad qpdf-shaped low-level permission controls, degraded-print variants, or generic PDF permission bit mapping in Phase 51.

### Adapter selection and runtime posture
- **D-10:** `Rendro.Adapters.Qpdf` is the default first-party protection adapter in Phase 51.
- **D-11:** Callers may override the adapter per call via `adapter:`, but Rendro should not require explicit adapter selection on every invocation when qpdf is the only first-party backend.
- **D-12:** Do not introduce application-env-driven global adapter selection for this library boundary. Adapter choice should stay local to the API call and remain explicit only when callers need to deviate from the default.
- **D-13:** Missing executables and adapter failures must surface as crisp typed `:protect`-stage errors. The docs should state plainly that qpdf is the default backend rather than pretending the backend is abstract.

### Artifact metadata and redaction
- **D-14:** Protected artifacts should remain auditable, but `metadata.protection` should stay minimal and audit-safe by default.
- **D-15:** Preserve only the minimum stable metadata needed for downstream transport and inspection: protection is present, output is non-deterministic, algorithm, and the narrow permissions posture.
- **D-16:** Do not retain password values, password-derived material, tool stderr/stdout, tool version, or rich policy detail on the artifact metadata surface.
- **D-17:** Adapter identity may appear in narrowly scoped diagnostics/proof tooling when needed, but it should not become a rich default artifact metadata contract if that would widen audit/logging risk.

### Validation and error posture
- **D-18:** Protection option validation belongs at the `Rendro.Protect.password/2` public boundary, not in `Rendro.Pipeline.Validate` and not deep inside the adapter.
- **D-19:** Reject malformed or ambiguous protection input before adapter invocation with typed `Rendro.Error` tuples under stage `:protect`.
- **D-20:** Error details and audit metadata must redact password material and expose only safe booleans or similarly narrow signals when callers need to know whether a password was present.

### Downstream GSD default
- **D-21:** For this phase and similar narrow contract work, downstream GSD agents should default to one cohesive recommendation set that already balances architecture, DX, and truthful boundaries instead of presenting broad menus of equivalent options.
- **D-22:** Escalate to the user only when a choice materially changes product semantics, milestone scope, or public security/trust posture in a way the maintainer is likely to care about directly.

### the agent's Discretion
- Exact public naming of minimal protection metadata keys, as long as the metadata stays audit-safe and small.
- Exact typed error tuple names and `Rendro.Error` wording, as long as the boundary remains explicit and redacted.
- Exact curated advisory-permission atom set, as long as it stays narrow, common, and clearly advisory.
- Exact docs ordering and examples, as long as artifact-first remains the normative contract and `render_protected/3` stays framed as sugar.

</decisions>

<specifics>
## Specific Ideas

- Preferred canonical usage:
  - `{:ok, artifact} = Rendro.render_to_artifact(doc, render_opts)`
  - `{:ok, protected} = Rendro.Protect.password(artifact, open_password: ..., owner_password: ..., advisory_permissions: [:print, :copy])`
- Preferred convenience wording:
  - "`Rendro.render_protected/3` is a shortcut for rendering an artifact and then applying `Rendro.Protect.password/2`."
- Preferred API and docs posture:
  - artifact-first is the real contract
  - qpdf is the default first-party backend
  - AES-256 only
  - advisory permissions are not enforcement, DRM, compliance, tamper evidence, or signing
- Ecosystem lessons to preserve:
  - follow Elixir/Phoenix-style explicit boundary APIs over global config or hidden policy
  - avoid pypdf-style convenience defaults that blur owner/user password semantics
  - avoid qpdf/PDF-spec parity surfaces that leak low-level complexity and widen footguns
- User preference to preserve:
  - shift routine tradeoff resolution left inside GSD so agents synthesize one coherent recommendation set by default and only escalate the high-impact policy calls

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement scope
- `.planning/PROJECT.md` — v1.10 milestone goal, product posture, and non-negotiable truthful-boundary constraints.
- `.planning/REQUIREMENTS.md` — `PROTECT-01`, `PROTECT-02`, and `PROTECT-03` define Phase 51 scope.
- `.planning/STATE.md` — active milestone/phase positioning for v1.10.
- `.planning/milestones/v1.10-ROADMAP.md` — Phase 51 goal, dependency, and plan split.
- `.planning/milestones/v1.10-CONTEXT.md` — locked milestone posture: artifact-first, AES-256 only, no secret persistence, no native encryption.

### Methodology and prior precedent
- `.planning/METHODOLOGY.md` — truthful small contracts, boundary validation first, least-surprise DX, and collapse-to-one-recommendation defaults.
- `.planning/phases/49-curated-link-annotation-surface/49-CONTEXT.md` — precedent for explicit authored/public contract shaping and rejecting broader escape hatches.
- `.planning/phases/50-support-boundary-and-proof-closure/50-CONTEXT.md` — precedent for narrow truthful support language, advisory-claim posture, and downstream GSD recommendation style.

### Research inputs
- `.planning/research/SUMMARY.md` — milestone-level recommendation for external-hook-first protection.
- `.planning/research/ARCHITECTURE.md` — Phase 51 architecture recommendations, public seam rationale, and protect-stage error posture.

### Core code seams
- `lib/rendro.ex` — convenience wrapper boundary and public render/protect composition surface.
- `lib/rendro/protect.ex` — primary Phase 51 public API, option normalization, and redaction behavior.
- `lib/rendro/protect/adapter.ex` — adapter behavior boundary.
- `lib/rendro/adapters/qpdf.ex` — first-party external executable boundary and permission mapping.
- `lib/rendro/artifact.ex` — artifact metadata/wrap seam used by protection.
- `lib/rendro/audit.ex` — metadata scrubbing posture for audit boundaries.
- `lib/rendro/error.ex` — `:protect`-stage typed error contract.
- `guides/api_stability.md` — public support-boundary language that Phase 51 must stay consistent with.
- `priv/support_matrix.json` — machine-readable support contract for the protection family.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/rendro/protect.ex`: already implements the artifact-first boundary, dual-password validation, and redacted error details.
- `lib/rendro/adapters/qpdf.ex`: already models the runtime executable seam and argfile-based qpdf invocation.
- `lib/rendro/artifact.ex`: already provides the thin transform/wrap seam that protection should reuse.
- `lib/rendro/audit.ex`: already establishes the need to scrub password-related metadata before audit/logging boundaries.
- `lib/rendro/error.ex`: already has a dedicated `:protect` stage and should remain the typed error envelope for this work.

### Established Patterns
- Rendro prefers explicit narrow public helpers over hidden attrs, overloaded behavior, or global mutable config.
- Optional integrations remain optional at runtime and fail with typed errors rather than widening core dependencies.
- Truthful support claims are intentionally narrower than what a low-level PDF tool might technically permit.
- Rich operational/debug information belongs in proof artifacts, docs, or explicit diagnostics rather than in broad default metadata blobs.

### Integration Points
- Phase 51 should stay entirely on the artifact side of the pipeline and must not modify the deterministic render pipeline contract.
- The protection API must compose cleanly with existing Mailglass/storage/async artifact seams while keeping password material out of transport and persisted job payloads.
- The docs-contract and support-matrix lanes must be able to describe the chosen API without implying broader viewer/security guarantees than the implementation and proof lanes support.

</code_context>

<deferred>
## Deferred Ideas

- Protection options on `Rendro.render/2` or document-authored protection state.
- Global app-env-driven default adapter configuration.
- Broad qpdf/PDF-spec parity for permission flags or low-level permission bit mapping.
- Owner-only, blank-password, or single-password convenience modes.
- Rich artifact metadata with tool version, password-shape detail, or verbose security-policy blobs.
- Native in-core encryption, digital signatures, compliance/archive claims, and any broader trust/security narratives outside the locked v1.10 boundary.

</deferred>

---

*Phase: 51-protection-api-contract-and-validation*
*Context gathered: 2026-05-06*
