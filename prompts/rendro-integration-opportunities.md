# Rendro Integration Opportunities (JTBD-Prioritized)

Purpose: map high-value integrations between Rendro and recent `szTheory` Elixir OSS libraries so decisions stay intentional across roadmap phases.

## Scoring model

Scale: 1 (low) to 5 (high)
- **Rendro user value:** impact on Rendro primary personas/JTBD.
- **Peer-lib synergy:** value back to the peer library's persona/JTBD.
- **Implementation risk:** complexity and coupling risk (higher is worse).
- **Timing fit:** suitability for early Rendro lifecycle.

Priority heuristic:
- **Do Now:** high value + high timing fit + manageable risk.
- **Soon:** strong value but needs core stabilization first.
- **Track:** strategic adjacency; keep visible, do not force into early scope.

## Candidate matrix

| Library | Rendro user-value JTBD | Peer-lib JTBD synergy | Integration shape | Scores (value/synergy/risk/timing) | Priority |
|---|---|---|---|---|---|
| `threadline` | "I need durable, explainable change/audit history for templates and render jobs." | Strengthens `threadline` audit platform story with document-generation domain examples. | Optional adapter emitting structured audit actions for template publish, render start/stop, validation failures. | 5 / 5 / 2 / 5 | **Do Now** |
| `mailglass` | "I need to send transactional emails with reliable PDF attachments and previews." | Strengthens `mailglass` transactional pipeline with first-class document attachment flow. | Optional `rendro_mailglass` bridge (`render_to_binary` + attachment helper + preview recipe). | 5 / 5 / 2 / 5 | **Do Now** |
| `accrue` | "I need production invoices/statements with deterministic layout and operator traceability." | Gives `accrue` stronger document-generation story for billing artifacts. | Official guide + adapter examples for invoice PDFs and downloadable statements. | 5 / 4 / 3 / 4 | **Do Now** |
| `rulestead` | "I need controlled rollout of template/runtime behavior changes." | Adds a concrete runtime-governance use case for `rulestead`. | Feature-flag hooks for renderer version rollout, fallback behavior, expensive feature toggles. | 4 / 4 / 2 / 4 | **Soon** |
| `sigra` | "I need secure admin/operator workflows for template management and approvals." | Demonstrates `sigra` in high-trust operational tooling. | Cookbook for admin auth, MFA, step-up flows around Rendro admin surfaces. | 4 / 4 / 3 / 3 | **Soon** |
| `lockspire` | "I need delegated OAuth/OIDC for document services in embedded product contexts." | Creates a credible embedded-OAuth provider use case for docs APIs. | Future optional OAuth/OIDC integration recipe for Rendro API mode. | 3 / 4 / 4 / 2 | **Track** |
| `scrypath` | "I need searchable render/template artifacts and operational lookup." | Expands `scrypath` adoption to document operations indexing. | Optional indexing adapter for render artifacts/metadata and admin search UX. | 3 / 4 / 3 / 2 | **Track** |
| `lattice_stripe` | "I need Stripe-adjacent customer docs (receipts, statements, dispute packs)." | Adds applied examples for Stripe users needing generated docs. | Example integrations for Stripe payment/billing narratives rendered by Rendro. | 4 / 3 / 3 / 3 | **Soon** |
| `kiln` | "I need autonomous generation/testing of document fixtures and template evolutions." | Dogfooding path for Kiln's software-factory positioning. | Optional internal workflow references for automated Rendro template regression loops. | 2 / 3 / 4 / 2 | **Track** |

## Why these priorities

### Do Now
- `threadline`, `mailglass`, and `accrue` are the strongest immediate fit:
  - clear shared personas (Phoenix SaaS/dev+ops)
  - direct JTBD overlap with Rendro v1 use cases (invoices, statements, transactional docs, auditable operations)
  - integration can be adapter/guides-first without hard dependency coupling.

### Soon
- `rulestead`, `sigra`, and `lattice_stripe` are high-value once Rendro's core rendering contract is stable:
  - rollout controls, auth hardening, and Stripe ecosystem examples become stronger after core API freeze.

### Track
- `lockspire`, `scrypath`, and `kiln` are strategic:
  - valuable longer-term adjacency
  - higher coupling or later-stage platform concerns.

## Recommended implementation policy

- Keep all cross-lib integrations **optional** and adapter-driven.
- No hard dependency from `rendro` core to sibling libs.
- Ship integration as:
  1. Guide/recipe first.
  2. Tiny adapter package if needed.
  3. Contract tests proving adapter behavior.

## Do-Now starter slices

1. **`threadline` starter**
- Add a `Rendro.Audit` behavior and one `Threadline` adapter example:
  - template published
  - render succeeded
  - render failed (with redacted error class metadata).

2. **`mailglass` starter**
- Add an attachments recipe:
  - generate PDF bytes from Rendro
  - attach through Mailglass mailable flow
  - include fallback error path and telemetry notes.

3. **`accrue` starter**
- Add billing-document recipe:
  - invoice/statement render template
  - deterministic naming/hash for artifacts
  - operator verification checklist.

## Source anchors used

- `threadline/README.md`, `threadline/.planning/RETROSPECTIVE.md`, `threadline/.github/workflows/ci.yml`
- `mailglass/README.md`, `mailglass/mix.exs`, `mailglass/.github/workflows/ci.yml`
- `accrue/README.md`, `accrue/.planning/RETROSPECTIVE.md`, `accrue/.github/workflows/ci.yml`
- `rulestead/README.md`, `rulestead/.planning/PROJECT.md`
- `sigra/README.md`, `sigra/.planning/RETROSPECTIVE.md`
- `lockspire/README.md`, `lockspire/.planning/STATE.md`
- `scrypath/README.md`, `scrypath/.planning/PROJECT.md`
- `lattice_stripe/README.md`, `lattice_stripe/.planning/STATE.md`
- `kiln/README.md`, `kiln/.planning/PROJECT.md`
