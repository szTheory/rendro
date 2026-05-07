# Phase 51: Protection API Contract and Validation - Research

**Researched:** 2026-05-06
**Domain:** Artifact-first PDF protection API, typed validation, and password-safe metadata in Rendro core
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- `Rendro.Protect.password/2` is the canonical public boundary. Protection stays post-render and artifact-first.
- `Rendro.render_protected/3` is allowed only as thin sugar over `render -> artifact -> protect`.
- Phase 51 must not add protection options to `Rendro.render/2`, `Rendro.render_to_artifact/2`, or document-authored state.
- Both `open_password` and `owner_password` are required, must be non-empty binaries, and must not be defaulted from each other.
- The public algorithm surface stays locked to `:aes_256`.
- Advisory permissions stay curated, narrow, and explicitly non-security-enforcing.
- qpdf is the default first-party backend, but it remains an optional runtime executable rather than a hard dependency.
- Validation and redaction belong at the public protection boundary, not in the render pipeline validate stage.
- Errors and metadata must redact password material and expose only safe booleans or similarly narrow signals.

### Discretion
- Exact naming of minimal metadata keys.
- Exact `Rendro.Error` reason tuples and wording.
- Whether option normalization remains inline in `Rendro.Protect` or is extracted into a helper module, provided the public contract stays unchanged.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROTECT-01 | Engineers can apply password-to-open protection to a rendered `%Rendro.Artifact{}` through a first-party external adapter boundary without widening the core render pipeline. | Keep `Rendro.Protect.password/2` as the normative API, keep qpdf behind `Rendro.Protect.Adapter`, and keep all protection behavior artifact-side rather than pipeline-side. |
| PROTECT-02 | The public protection surface accepts only AES-256 and rejects weaker or legacy algorithms with typed errors. | Normalize `:algorithm` at the public boundary, accept only `:aes_256`, and prove rejection of `:aes_128`, `:rc4`, and non-atom garbage through focused tests. |
| PROTECT-03 | Protection option validation rejects malformed or ambiguous authored state before any adapter invocation, and redacts password material from error details and audit metadata. | Validate passwords and permissions before calling the adapter, route failures through `Rendro.Error.from_stage(:protect, ...)`, and keep only safe booleans plus curated metadata in artifacts and audit-facing maps. |

</phase_requirements>

## Summary

Phase 51 is not greenfield anymore. The repository already contains the essential protection seam in `lib/rendro/protect.ex`, the qpdf adapter in `lib/rendro/adapters/qpdf.ex`, typed `:protect` error messaging in `lib/rendro/error.ex`, docs-contract coverage, and passing focused tests for the API and adapter boundary. Planning should therefore treat the phase as contract hardening and reconciliation work, not as first implementation.

The strongest current shape is already aligned with the locked decisions: `Rendro.Protect.password/2` is artifact-first, `Rendro.render_protected/3` is only convenience composition, the adapter is injectable per call, AES-256 is the only public algorithm, and password validation happens before adapter invocation. The plan should preserve that shape rather than reopen the product decision.

The main planning risk is drift between milestone artifacts and the live repo. `51-CONTEXT.md` still points at `lib/rendro/protect/opts.ex`, but the current code keeps normalization and redaction inside `Rendro.Protect`. The support matrix and guides also already include protection claims that the roadmap assigns partly to later phases. Phase 51 plans should therefore focus on finishing the contract truthfully, tightening metadata/audit guarantees, and updating the planning artifacts to reflect the real code seams.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public protection API | API / Backend | — | The artifact-first seam is a library boundary concern and must remain explicit rather than configuration-driven. |
| Password/permission validation | API / Backend | — | The caller contract must fail before any qpdf invocation or file-system side effects. |
| Encryption execution | External runtime tool | API / Backend | qpdf performs the protection work; Rendro only prepares safe inputs and wraps outputs. |
| Password redaction | API / Backend | Audit / Docs | Redaction policy must be enforced in code first, then reflected in metadata, audit, and docs claims. |
| Viewer/security narrative | Docs / Support contract | — | Phase 51 must stay narrow and truthful about advisory permissions and non-deterministic output. |

## Project Constraints (from AGENTS.md and planning artifacts)

- Keep core Rendro pure: no hard dependency on Phoenix, Oban, or external PDF packages.
- Preserve deterministic render semantics. Protection may produce non-deterministic bytes, but only after the artifact boundary.
- Documentation claims are contracts and must not get ahead of what the code or proof lanes can support.
- Prefer explicit optional runtime seams and typed errors over hidden config, implicit defaults, or silent fallback behavior.

## Existing Repo State

### Confirmed live seams
- `lib/rendro/protect.ex` already implements `password/2`, `render_protected/3`, option normalization, password presence checks, curated permissions, and redacted error details.
- `lib/rendro/protect/adapter.ex` already defines the minimal adapter behavior.
- `lib/rendro/adapters/qpdf.ex` already shells out through an `@argfile`, keeps qpdf optional at runtime, and returns typed missing-executable errors.
- `lib/rendro/error.ex` already includes `:protect` stage wording and next-step guidance.
- `test/rendro/protect_test.exs`, `test/rendro/adapters/qpdf_test.exs`, and `test/docs_contract/protection_claims_test.exs` all pass as of 2026-05-06.

### Drift and gap observations
- `.planning/phases/51-protection-api-contract-and-validation/51-CONTEXT.md` references `lib/rendro/protect/opts.ex`, but that file does not exist. Normalization currently lives inline in `Rendro.Protect`.
- `priv/support_matrix.json` and `guides/api_stability.md` already contain protection-family wording and claims, which means later-phase roadmap slices are partly pre-landed and plans must avoid duplicating or contradicting them.
- `lib/rendro/adapters/qpdf.ex` removes its temp directory only on the happy path. Cleanup behavior on error paths is the main implementation hardening gap visible from the current code.
- Audit redaction exists generically in `lib/rendro/audit.ex`, but Phase 51 still needs plan coverage that proves protection-specific metadata entering audit-facing seams stays password-safe.

## Standard Stack

### Core
| Component | Purpose | Recommendation |
|----------|---------|----------------|
| `Rendro.Protect` | Public artifact-first API | Keep as the single normative entrypoint. |
| `Rendro.Protect.Adapter` | Adapter seam | Keep minimal: one `protect/2` callback returning `{:ok, binary}` or `{:error, term()}`. |
| `Rendro.Adapters.Qpdf` | First-party external backend | Keep runtime-optional; do not add Hex deps. |
| `Rendro.Error` | Typed failure envelope | Use `:protect` stage consistently for all public boundary failures. |

### Supporting
| Component | Purpose | When to Use |
|----------|---------|-------------|
| `Rendro.Artifact.wrap/3` | Preserve artifact diagnostics and merge metadata | Use for all protected-output wrapping so protection stays artifact-side. |
| `Rendro.Audit.scrub_metadata/1` | Generic password-key scrubbing | Reuse in tests and proof cases to verify protection metadata remains safe across audit boundaries. |
| `priv/support_matrix.json` + `guides/api_stability.md` | Truthful support contract | Touch only when needed to align code truth, not to broaden scope. |

## Architecture Patterns

### Pattern 1: Explicit artifact-first seam
Keep the public surface centered on:

```elixir
{:ok, artifact} = Rendro.render_to_artifact(doc, render_opts)
{:ok, protected} =
  Rendro.Protect.password(artifact,
    open_password: "...",
    owner_password: "...",
    advisory_permissions: [:print, :copy]
  )
```

`Rendro.render_protected/3` should remain a delegating shortcut and must not become a second semantic path with different defaults or metadata behavior.

### Pattern 2: Validate and redact before adapter invocation
Current code already follows the right boundary:
- resolve adapter
- validate algorithm
- validate both passwords
- validate curated permissions
- call adapter only after normalization succeeds

This pattern should be preserved. Any follow-on refactor such as extracting a helper module is acceptable only if it does not move validation deeper into qpdf or into pipeline validate.

### Pattern 3: External executable seam mirrors Poppler posture
The qpdf adapter is correctly modeled as a peer to other optional executable-backed integrations:
- executable lookup is injectable for tests
- command runner is injectable for tests
- missing executable returns a typed runtime error
- the library does not declare qpdf as a dependency

That posture should remain intact throughout the phase.

### Pattern 4: Minimal, audit-safe metadata
Protected artifacts should expose only narrow metadata such as:
- `protected: true`
- `algorithm: :aes_256`
- curated `advisory_permissions`
- booleans indicating whether passwords were present
- `deterministic: false`

Do not persist actual password values, stderr/stdout blobs, tool versions, or rich policy detail on default artifact metadata.

## Recommended Plan Split

### Plan 51-01
Center on the public contract and boundary hardening:
- keep `Rendro.Protect.password/2` and `Rendro.render_protected/3` contract stable
- tighten typed `Rendro.Error` coverage
- verify invalid options never reach adapter execution
- harden qpdf adapter operational behavior such as cleanup and failure wrapping where needed

### Plan 51-02
Center on metadata, redaction, and regression proof:
- lock the minimal `metadata.protection` shape
- prove password material never leaks through error details or audit-facing metadata
- reconcile docs/tests/planning artifacts with the current phase boundary without widening claims

## Anti-Patterns to Avoid

- Adding protection options to `Rendro.render/2` or document state in Phase 51.
- Relaxing the password contract into single-password, blank-password, or derived-password modes.
- Exposing raw qpdf flags or a generic permission-bit surface.
- Turning docs/support-matrix work into broader security, compliance, or viewer-proof claims.
- Forcing the codebase to create `lib/rendro/protect/opts.ex` solely to match stale planning prose if the current inline structure stays clear and testable.

---
*Phase: 51-protection-api-contract-and-validation*
*Research completed: 2026-05-06*
