# Feature Landscape

**Domain:** Async Document Generation & SaaS Integration
**Researched:** 2026-05-04

## Table Stakes

Features users expect for production document operations. Missing = product cannot be used for high-volume SaaS.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Artifact Manifests | Jobs need to return structured metadata (hash, byte size, diagnostics) for storage and auditing. | Low | Pure data structures. |
| Async Render Worker | Generating PDFs in the web request cycle times out; needs backgrounding. | Medium | Oban adapter with retry/idempotency logic. |
| Pluggable Storage | PDFs must be saved somewhere (S3, Disk) after async generation. | Medium | `Rendro.Storage` behavior required. |

## Differentiators

Features that set Rendro apart as an enterprise-grade ecosystem.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `threadline` Audit Adapter | "I need durable, explainable change/audit history for templates and render jobs." | Low | 5/5 user value. Emits structured audit actions. |
| `mailglass` Attachment Bridge | "I need to send transactional emails with reliable PDF attachments." | Low | 5/5 user value. Seamless PDF -> email pipeline. |
| `accrue` Billing Recipes | Deterministic layout and operator traceability for invoices. | Medium | 5/5 user value. Examples/adapters for billing docs. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Hard Dependency on Ecto/Oban | Violates the pure-core DNA. Forces database requirements on all users. | Extract into optional `rendro_oban` package or provide recipes. |
| Built-in AWS/S3 Uploads | Massive scope creep; pollutes dependency tree with AWS SDKs. | Define a simple behavior (`Rendro.Storage`) and let users implement it, or provide separate adapters. |
| Webhooks | Too much infrastructure for a rendering library. | Let the user's Oban worker or Phoenix context trigger webhooks after the adapter finishes. |

## Feature Dependencies

Artifact Manifests → Async Render Worker → Storage / Delivery Integrations

## MVP Recommendation

Prioritize:
1. Artifact Manifests & Metadata
2. Oban worker recipe / optional adapter
3. `threadline` and `mailglass` integration adapters

Defer: 
- `rulestead`, `sigra`, `lockspire` (Wait until core async and "Do Now" integrations are stable).

## Sources
- `.planning/EPIC.md` (v1.4 Async Delivery and Artifact Operations)
- `prompts/rendro-integration-opportunities.md`