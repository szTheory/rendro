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

## Milestone 5: Document Trust & Embedded Artifact Surfaces (Next)
**Focus:** Expand the PDF engine into higher-trust document capabilities while keeping claims proof-backed and scope narrow.

* **Digital Signatures:**
  * Deterministic signing primitives and explicit support boundaries.
* **Document Encryption:**
  * Password-protected documents and encryption policy surfaces.
* **Attachments & Annotations:**
  * Embedded file attachments and annotation support that do not compromise deterministic output guarantees.

---
*Note: This roadmap is a live strategic guide. Active milestone definition still happens through dedicated milestone context, requirements, and roadmap artifacts.*
