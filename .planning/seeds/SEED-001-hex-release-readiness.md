---
id: SEED-001
status: complete
planted: 2026-04-30T21:50:00Z
planted_during: v1.0 / Phase 24 planning boundary
trigger_when: when Rendro is battle-tested enough for a truthful first public Hex release
scope: Medium
resolved: 2026-04-30T00:00:00Z
resolution: promoted to ROADMAP backlog as Phase 999.1 during v1.1 milestone-close preflight
---

# SEED-001: Publish Rendro to Hex.pm when release readiness is real

## Why This Matters

Rendro is solving a high-risk problem surface: deterministic PDF generation, pagination,
and operationally trustworthy failure behavior. A premature Hex release would create
the wrong public contract and push users toward a library that may still be maturing
faster than its support boundaries and verification story.

This should surface when the team is ready to decide whether Rendro now delivers enough
real production value, battle-tested behavior, and truthful documentation to justify a
public Hex package release.

## When to Surface

**Trigger:** when Rendro is battle-tested enough for a truthful first public Hex release

This seed should be presented during `$gsd-new-milestone` when the milestone scope matches
any of these conditions:
- release planning starts for a first public Hex.pm package
- the core layout, pagination, diagnostics, and verification contracts are considered stable
- real-world document workloads have been exercised enough to judge whether the library is production-valuable
- documentation and support boundaries are strong enough that a public release would not overclaim capability

## Scope Estimate

**Medium** — likely a dedicated phase or two for release readiness, packaging, docs, proof,
and possibly an RC-style validation pass against real app workloads before publishing.

## Breadcrumbs

Related code and decisions found in the current codebase:

- [lib/mix/tasks/release/preflight.ex](/Users/jon/projects/rendro/lib/mix/tasks/release/preflight.ex:1) — existing release preflight task already includes `hex.build --unpack` and `hex.publish --dry-run --yes`
- [test/scripts/release_preflight_proof_test.exs](/Users/jon/projects/rendro/test/scripts/release_preflight_proof_test.exs:1) — proof coverage around release preflight workflow
- [lib/mix/tasks/verify.ex](/Users/jon/projects/rendro/lib/mix/tasks/verify.ex:1) — verification lanes reinforce the “truth before release” posture
- [.planning/STATE.md](/Users/jon/projects/rendro/.planning/STATE.md:16) — core value emphasizes reliable, auditable, deterministic PDFs with production-grade observability
- [.planning/ROADMAP.md](/Users/jon/projects/rendro/.planning/ROADMAP.md:25) — current roadmap still has open verification/traceability work before broader release confidence
- [.planning/phases/06-pipeline-telemetry-contract/06-CONTEXT.md](/Users/jon/projects/rendro/.planning/phases/06-pipeline-telemetry-contract/06-CONTEXT.md:81) — earlier reasoning explicitly noted there were no published Hex releases yet

## Notes

Captured from session discussion: do not publish just because the package can be built.
The release should wait until Rendro is battle-tested by the project’s own standards:
deterministic layout behavior, truthful verification artifacts, realistic example value,
and support boundaries that are honest enough for external users.

## Resolution

Resolved on 2026-04-30 by promoting this seed into the roadmap backlog as
`Phase 999.1: First Hex Release Readiness (BACKLOG)`.

This keeps the release-readiness work explicit for the next milestone-definition pass
without leaving it as an unowned dormant seed that blocks milestone close.
