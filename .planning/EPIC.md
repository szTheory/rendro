# Rendro Post-v1.0 Epic Plan

**Purpose:** Provide a durable multi-milestone expansion arc after v1.0 so future milestone planning can start from the current product delta instead of re-deriving strategy from scratch.

**Primary reader:** Future maintainer starting a new milestone.
**Post-read action:** Choose the next milestone from this arc, then scope that milestone in `/gsd-new-milestone` without redoing the whole product strategy discussion.

## Current Product Truth

Rendro v1.0 proved the core thesis:

- Pure-Elixir PDF generation works.
- Deterministic rendering is real, not just marketing.
- The pipeline and error/telemetry contract are trustworthy.
- Optional adapter boundaries are disciplined.
- CI, docs-contract, and release verification are significantly stronger than the average young OSS library.

That means the main problem is no longer "can Rendro render a reliable PDF?" The main problem is "what must exist for a Phoenix or SaaS team to adopt Rendro broadly without rebuilding half the document layer themselves?"

## The Real Delta

Rendro is strong in engine trust and weak in authoring depth.

The biggest gaps between the current library and the target product are:

1. Richer authoring primitives and layout controls.
2. Real typography, branding, and asset support.
3. Truthful first public release packaging once the product surface is ready.
4. First-class async artifact workflows for production operations.
5. Stronger validation and support-surface clarity for trust-sensitive buyers.
6. Broader ecosystem expansion only after the core authoring and trust layers are stable.

In practice, this means future milestones should favor meaningful capability layers over scattered feature additions.

## Prioritization Rules

Use these rules when deciding what belongs in the next milestone:

1. Prefer capability layers over isolated features.
2. Prefer work that reduces how much application teams must build around Rendro.
3. Preserve the pure-core and optional-adapter boundary at all times.
4. Do not broaden outward before the layer underneath is solid.
5. Do not claim support for typography, validation, compliance, or signatures beyond what tests and docs can prove.
6. Treat trust and adoption as equal concerns: a feature that is powerful but operationally unclear is incomplete.

## Milestone Arc

### v1.1 Layout Authoring Maturity

**Why this comes first**

The library already proves deterministic rendering, but the current authoring surface is still too thin for real business documents. Teams need better control over how content stays together, breaks across pages, and composes into reusable document structure.

**Primary objective**

Make Rendro capable of building serious business layouts without forcing each adopter to invent their own pagination rules and composition conventions.

**Core capability themes**

- Keep-together, keep-with-next, and stronger break semantics.
- Richer table behavior, especially row splitting and table-region control.
- Reusable layout structures such as page templates, sections, regions, or frames.
- Better overflow and break diagnostics that explain why a page break happened.
- Cleaner authoring ergonomics for common page composition patterns.

**What this milestone unlocks**

- More realistic invoices, statements, reports, and certificates.
- Less app-specific layout glue in downstream Phoenix apps.
- A stable base for fonts and assets, which otherwise become chaos layered on top of a too-simple layout model.

**Keep out**

- HTML/CSS parity.
- WYSIWYG builders.
- One-off app-specific layout hacks in core.

### v1.2 Fonts, Assets, and Honest I18n Baseline

**Why this comes second**

Once layout composition is stronger, the next adoption blocker is branding and typography. Real teams need logos, custom fonts, predictable asset handling, and a truthful baseline for what scripts and language scenarios are supported.

**Primary objective**

Make Rendro capable of producing branded, customer-facing documents without lying about typography depth.

**Core capability themes**

- Deterministic custom font registration and embedding.
- Fallback font chains and missing-glyph diagnostics.
- Image and logo embedding with clear asset constraints.
- Honest Unicode and script support boundaries.
- Measurement and pagination behavior that remains deterministic once fonts and assets are involved.

**What this milestone unlocks**

- Production-grade customer documents instead of bare technical PDFs.
- Branded invoice, statement, receipt, and certificate use cases.
- A realistic base for later validation and trust work.

**Keep out**

- Broad shaping or RTL claims without proof.
- Remote asset fetching as a default behavior.
- "Supports every language" positioning.

### v1.3 First Public Hex Release Readiness

**Why this comes third**

After layout maturity and branded-document support exist, the fastest path to adoption is a truthful first public release. Packaging and support boundaries should follow real capability proof, but they should not wait for richer async workflow machinery that external evaluators do not need on day one.

**Primary objective**

Make Rendro publishable to Hex.pm with package metadata, guides, proofs, and support boundaries that accurately reflect the now-shipped engine surface.

**Core capability themes**

- First public package metadata, versioning, and release docs that match the true support surface.
- Explicit release-readiness review against examples, diagnostics, and verification evidence.
- Support-boundary tightening where docs still outrun proof.
- RC-style confidence checks against realistic branded document paths.

**What this milestone unlocks**

- Truthful public discoverability and installability.
- A cleaner evaluation path for adopters before deeper ops features land.
- A stronger base for subsequent async and trust work.

**Keep out**

- Shipping features whose only purpose is to make the release announcement look larger.
- Async artifact lifecycle expansion unless it blocks truthful publication.
- Broad ecosystem-expansion scope.

### v1.4 Async Delivery and Artifact Operations

**Why this comes fourth**

The current Oban boundary is intentionally narrow and good as a proof surface, but real SaaS workloads need stronger async workflow contracts, artifact metadata, and operational handoff patterns.

**Primary objective**

Make Rendro operationally usable for queued, persisted, retried, and audited document workflows at application scale.

**Core capability themes**

- A render manifest or equivalent artifact summary with stable metadata.
- Idempotent async job contracts and retry/cancellation semantics.
- Pluggable artifact sink or persistence boundaries without making storage part of core.
- Better telemetry for queued, rendered, failed, timed out, and persisted states.
- Clear conventions for Phoenix and background-job workflows.

**What this milestone unlocks**

- Nightly billing batches.
- Statement generation pipelines.
- Attachment workflows with traceable artifact lifecycles.
- Stronger operational adoption for SaaS apps.

**Keep out**

- Making Oban mandatory.
- Turning Rendro into a storage product.
- Hosted platform concerns.

### v1.5 Validation and Trust Surfaces

**Why this comes fifth**

After authoring, assets, and operations are materially stronger, the next leverage point is trust. Rendro's identity depends on truthful capability boundaries. This milestone should make support claims more explicit and more machine-checkable.

**Primary objective**

Strengthen the evidence and support surface around produced PDFs without pretending to offer universal compliance.

**Core capability themes**

- Optional validator adapters and advisory verification lanes.
- Stronger structural validation and preflight reporting.
- Machine-readable support matrix for validated, experimental, and unsupported surfaces.
- Validation reports that attach cleanly to artifact metadata and release docs.

**What this milestone unlocks**

- Better enterprise evaluation conversations.
- Cleaner procurement and security review posture.
- A safer path toward future compliance-oriented work.

**Keep out**

- Blanket PDF/A or PDF/UA claims.
- Hard dependencies on external validator binaries.
- Documentation that outruns proof.

### v1.6 Demand-Led Ecosystem Expansion

**Why this comes last**

Only after the product is materially stronger in authoring, branding, operations, and trust should the project widen its ecosystem surface. Otherwise new integrations just multiply unstable boundaries.

**Primary objective**

Expand integrations and extension patterns only where real demand exists and the underlying contracts are already stable.

**Core capability themes**

- Stable extension contracts for optional adapters.
- Compatibility harnesses for ecosystem integrations.
- Selected new workflow integrations that follow proven demand.
- Community-contribution-friendly extension boundaries.

**What this milestone unlocks**

- Broader adoption without contaminating core.
- Safer third-party integration growth.
- More leverage from ecosystem contributions.

**Keep out**

- Adapter sprawl for its own sake.
- Hidden dependencies in core.
- Feature-checklist expansion without user pull.

## Recommended Next Milestone

If there is no strong new external constraint, choose the next milestone in this order:

1. **v1.2 Fonts, Assets, and Honest I18n Baseline**
2. **v1.3 First Public Hex Release Readiness**

That ordering is highest leverage because:

- It attacks the biggest remaining adoption gap first.
- It makes the first public release reflect branded real-world document capability instead of a thinner engine-only story.
- It avoids waiting on async artifact operations that are valuable but not prerequisite for initial public adoption.

## Recalibration Rules

Re-evaluate this arc when one of these becomes true:

- A real adopter or pilot user needs a workflow that changes the priority order.
- Core layout assumptions prove too weak to support the planned font/asset layer.
- A packaging, licensing, or release-distribution issue becomes a near-term adoption blocker before `v1.2` closes.
- A trust-sensitive opportunity requires pulling some `v1.5` work earlier.

If none of those are true, keep the order stable. Avoid re-triangulating from zero every milestone.

## Permanent Boundaries

These are strategic boundaries across the whole arc:

- Rendro core is not a browser renderer.
- Rendro is not a general PDF editing/parsing suite.
- Phoenix, Oban, and ecosystem libraries remain optional.
- Compliance and signature claims require validator-backed proof.
- Hosted template editing, remote asset services, and unrelated SaaS platform concerns are not default product scope.

## How To Use This Document

When starting a future milestone:

1. Read this epic first.
2. Confirm whether the ordering still holds.
3. Choose the next milestone from this arc unless a real constraint justifies deviation.
4. Scope only one milestone at a time in `/gsd-new-milestone`.
5. If priorities changed, update this document before planning the new milestone so future work inherits the new reasoning.

---
*Created: 2026-04-28 after v1.0 archival and post-MVP strategic planning*
*Last updated: 2026-04-30 after v1.2 milestone definition and release-order recalibration*
