# Rendro Long-Term Roadmap: "Batteries Included" Production PDF Platform

This roadmap defines the strategic arcs that turn Rendro into the production-ready document generation standard for Elixir teams. It is intentionally milestone-sized rather than phase-sized so active milestone artifacts can stay small while this file preserves product direction.

## Core Mandates & DNA
- **Pure Elixir:** No browser runtime or hard dependency on external layout engines in core.
- **Deterministic Layout:** Layout, pagination, and output bytes must remain reproducible for identical inputs.
- **Operational Trust:** Errors, verification, and support boundaries are product behavior, not afterthoughts.
- **Integration over Coupling:** Ecosystem value is delivered through optional adapters and canonical recipes, not core entanglement.

---

## Milestone 1: Core Ecosystem Integrations (Completed)
**Focus:** Make Rendro fit naturally into Phoenix SaaS operational flows.

* **Audit and Delivery Adapters:**
  * `Rendro.Audit` and optional adapters for external lifecycle logging.
  * Attachment and delivery recipes for operational handoff into surrounding app infrastructure.
* **Billing-Document Recipes:**
  * Deterministic invoice and statement flows that prove downstream business-document fit.

## Milestone 2: Advanced Layout & Typography (Completed)
**Focus:** Mature the layout engine so complex business documents remain deterministic under real-world content pressure.

* **Typography & Assets:**
  * Font registration, embedding, fallback, and honest Unicode boundaries.
* **Flow Layout Depth:**
  * Table fragmentation, nested structures, and widow/orphan pagination controls.
* **Proof Surfaces:**
  * Regression and docs-contract coverage that keeps layout claims truthful.

## Milestone 3: Validation and Trust Surfaces (Completed)
**Focus:** Strengthen evidence around produced PDFs without pretending to provide blanket compliance guarantees.

* **Optional Validator Adapters:**
  * Structural validation through advisory lanes such as `pdfinfo`/Poppler.
* **Support Matrix:**
  * Machine-readable boundaries for validated, experimental, and unsupported surfaces.
* **Preflight Reporting:**
  * Stronger structural diagnostics and clearer operator-facing proof.

## Milestone 4: Interactive PDF Forms (Completed)
**Focus:** Extend the core engine from static documents into deterministic authored AcroForm output.

* **Authored Form Widgets:**
  * Text fields, checkboxes, and radio groups authored through Rendro primitives.
* **Deterministic Serialization:**
  * AcroForm catalogs, widget annotations, and appearance streams emitted without `NeedAppearances`.
* **Truthful Viewer Boundaries:**
  * Structural validation plus proof-backed viewer claims instead of generic "works everywhere" positioning.

## Milestone 5: Embedded Artifact Surfaces (Next)
**Focus:** Extend Rendro's authored PDF surface with embedded related artifacts while keeping the public contract deterministic, narrow, and proof-backed.

* **Document-Level Embedded Files:**
  * Embedded related artifacts in the PDF binary with explicit metadata and deterministic serialization.
* **Curated Link Annotations:**
  * External-URI and internal-destination links only, reusing the existing annotation seam without opening a generic review/comment API.
* **Truthful Artifact Boundaries:**
  * Support-matrix and proof updates that distinguish structural validity from viewer discoverability and policy behavior.

## Milestone 6: Protected Delivery Hooks & Encryption Boundaries
**Focus:** Add a truthful PDF protection story without overclaiming permissions-based security or destabilizing deterministic core rendering.

* **External Protection Hooks First:**
  * Optional post-processing or adapter seams for encryption/protection workflows.
* **Narrow Security Claims:**
  * Explicit distinction between password-to-open, advisory permissions, and unsupported compliance/archive narratives.
* **Support-Boundary Discipline:**
  * Proof-backed validation before any native encryption story expands.

## Milestone 7: Signature Fields & External Signing Preparation
**Focus:** Add narrow signing preparation surfaces while keeping actual cryptographic trust operations explicit and separately bounded.

* **Unsigned Signature Fields:**
  * Core-authored signature-field surfaces only if they fit the existing form model truthfully.
* **External Signing Preparation:**
  * Deterministic preparation seams for append/incremental external signing workflows.
* **Deferred Compliance Surface:**
  * PAdES, LTV, TSA/OCSP/CRL, and broad compliance claims remain later work.

---
*Note: This roadmap is a live strategic guide. Active milestone definition still happens through dedicated milestone context, requirements, and roadmap artifacts.*
