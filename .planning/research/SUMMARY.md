# Research Summary: Rendro Async Delivery & Ecosystem Expansion

**Domain:** Async Document Generation & SaaS Integration
**Researched:** 2026-05-04
**Overall confidence:** HIGH

## Executive Summary

Rendro's pure-Elixir layout and typography core has been hardened in milestones v1.4 and v1.5. The next major adoption hurdle for SaaS teams is operationalizing PDF generation—specifically, how to reliably enqueue generation jobs, store the resulting artifacts, and hand them off to delivery pipelines (like email) while maintaining a strict audit trail. 

This research focuses on the **Async Delivery and Artifact Operations** milestone. It naturally incorporates the high-priority "Do Now" integrations from the `szTheory` ecosystem (`threadline`, `mailglass`, `accrue`). By defining strict adapter boundaries, Rendro can support complex production workflows (billing batches, audited statements, email attachments) without polluting its pure core.

## Key Findings

**Stack:** Optional Oban adapters for async work; `threadline`, `mailglass`, and `accrue` for ecosystem capabilities.
**Architecture:** Strict Adapter/Behavior pattern where core emits pure data (Artifacts/Manifests) and optional packages handle side-effects (storage, queues, delivery).
**Critical pitfall:** Core contamination—accidentally adding `ecto`, `oban`, or `aws` as hard dependencies instead of leveraging optional adapter boundaries.

## Implications for Roadmap

Based on research and existing Epic constraints, suggested phase structure for this milestone:

1. **Phase: Artifact Operations & Manifests** - Define the pure data structures for generation results (hashes, metadata, diagnostics) to allow safe handoffs.
2. **Phase: Async Worker Boundaries (Oban)** - Establish the standard pattern and optional adapter for enqueueing idempotent render jobs.
3. **Phase: Ecosystem Integrations (Do Now)** - Implement the `threadline` audit behavior, `mailglass` attachment recipe, and `accrue` billing document patterns.

**Phase ordering rationale:**
- Artifact structure must exist before we can safely queue it.
- Async boundaries must be defined before we can build robust billing/delivery integrations that rely on them.

**Research flags for phases:**
- Phase 2: Needs careful design to ensure the Oban worker adapter doesn't force a specific storage backend.
- Phase 3: Integration with `threadline` requires defining a clear `Rendro.Audit` behavior.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Elixir/Oban ecosystem is standard and well-understood. |
| Features | HIGH | JTBD clearly mapped in `rendro-integration-opportunities.md`. |
| Architecture | HIGH | Adapter pattern is well-established in Elixir (e.g., Swoosh). |
| Pitfalls | HIGH | Core contamination is a known risk in library design. |

## Gaps to Address

- **Storage Interfaces:** How should the Oban worker hand off the PDF bytes to long-term storage (S3/GCS) without making AWS/GCP a dependency? (Likely requires a simple `Rendro.Storage` behavior).