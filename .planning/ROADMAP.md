# Rendro Long-Term Roadmap: "Batteries Included" Production PDF Platform

This roadmap defines the overarching epic arcs required to make Rendro the feature-complete, production-ready document generation standard for Elixir SaaS applications. It acts as the strategic memory for planning future milestones.

## Core Mandates & DNA (The "Why")
- **Pure Elixir:** No headless Chrome/Chromium dependency in core.
- **Deterministic Layout:** Reliable layout, pagination, and reproducible output bytes.
- **Operational Trust:** Telemetry, bounded execution (policies), and structured diagnostic errors.
- **Integration over Coupling:** Core remains pure; ecosystem value is delivered through optional adapters and canonical recipes.

---

## Milestone 1: Core Ecosystem Integrations (Do Now)
**Focus:** Bridge Rendro into the standard operational and communication flows of a Phoenix SaaS app. Prove that Rendro fits seamlessly into existing business requirements.

* **Threadline (Audit Trail):**
  * Implement `Rendro.Audit` behaviors and an optional `threadline` adapter.
  * Capture and persist lifecycle events: template published, render succeeded, render failed (with redacted error metadata).
* **Mailglass (Transactional Email):**
  * Create a reliable attachments recipe.
  * Build a `rendro_mailglass` bridge (`render_to_binary` + attachment helper + preview flow).
* **Accrue (Billing & Invoicing):**
  * Develop robust billing-document recipes (invoices, statements).
  * Ensure deterministic artifact hashing, naming, and operator verification checklists.

## Milestone 2: Advanced Layout & Typography (Core Maturation)
**Focus:** Address remaining core layout and presentation needs to support complex business documents, while strictly maintaining the deterministic pure-Elixir rendering engine constraint.

* **Typography & i18n:**
  * Advanced font subsetting, shaping, and fallback strategies.
  * Expanded internationalization (i18n) support for diverse character sets and text directionality.
* **Robust Flow Enhancements:**
  * Advanced table handling (complex column sharing, nested data, explicit cell fragmentation).
  * Expanded pagination controls and block-level break semantics (widow/orphan management).
* **Core Hardening:**
  * Extensive edge-case testing for nested flows and fixed-position hybrid documents.

## Milestone 3: Operational Tooling & Admin UX (Soon)
**Focus:** Provide high-trust operational governance and operator tooling for managing document generation at scale, leveraging sibling `szTheory` libraries.

* **Rulestead (Rollouts & Governance):**
  * Feature-flag hooks for template version rollouts and graceful degradation.
  * Controlled fallback behaviors and runtime renderer toggles for expensive features.
* **Sigra (Admin Security):**
  * Cookbooks for secure admin/operator workflows.
  * MFA and step-up auth patterns for template management, approvals, and overrides.
* **Lattice_Stripe (Billing Narratives):**
  * Applied examples and integrations for Stripe-adjacent customer documents (receipts, statements, dispute packs).

## Milestone 4: Strategic Adjacencies & Ecosystem Tooling (Track)
**Focus:** Expand the footprint of Rendro into specialized domains and automated development workflows.

* **Scrypath (Artifact Indexing):**
  * Searchable render and template artifact indexing.
  * Operational lookup and admin search UX.
* **Kiln (Automated Quality):**
  * Autonomous generation and testing of document fixtures.
  * Automated template regression loops and visual tracking.
* **Lockspire (API Auth):**
  * Delegated OAuth/OIDC for document services in embedded product contexts.
  * Future optional API mode for headless document generation as a service.

---
*Note: This roadmap is intended to be a live document to guide future milestones. Refer to `prompts/rendro-integration-opportunities.md`, `prompts/rendro-gsd-seed.md`, and `prompts/rendro-oss-dna.md` for deeper context on decision weightings and architectural constraints.*
