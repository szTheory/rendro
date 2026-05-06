# Phase 50 Research: Support-Boundary and Proof Closure

**Date:** 2026-05-06
**Phase:** 50
**Domain:** Support contract publication, docs-contract closure, and proof-lane design for embedded files and links

## Summary

Phase 50 should close `TRUST-01` and `TRUST-02` by extending Rendro's existing family-first support contract rather than inventing a new abstraction layer. The strongest fit is the same overall model used in Phase 47: one small machine-readable matrix, one canonical public support-boundary guide, one explicit docs-contract lane, and a strict split between automated structural proof and separately recorded viewer evidence.

The planning bias should stay conservative and explicit:

- extend `priv/support_matrix.json` with sibling `embedded_files` and `links` families
- keep simple status leaves (`supported`, `unsupported`, `unverified`) rather than metadata-heavy statement objects
- keep viewer status per surface, not one blanket `v1.9` viewer bucket
- keep `guides/api_stability.md` as the canonical public support-boundary surface
- keep `scripts/verify_docs.exs` as the canonical docs gate via `mix docs.contract`
- keep automated structural proof merge-blocking and viewer proof separate/manual unless a named support claim is being promoted

## Locked Recommendations

### 1. Support matrix shape

Use the existing family-first top-level shape:

```json
{
  "validators": { "...": "..." },
  "forms": { "...": "..." },
  "embedded_files": {
    "capabilities": {},
    "behaviors": {},
    "viewers": {}
  },
  "links": {
    "targets": {},
    "behaviors": {},
    "viewers": {}
  },
  "unsupported": []
}
```

Reasons:

- matches the current `forms` contract and avoids churn
- aligns with the Phase 47 decision that the matrix stay small, stable, and versionable
- is readable by humans and easy to pin in literal ExUnit claims tests
- avoids a premature `surfaces` meta-wrapper or BCD-style compatibility-database drift

Recommended leaf direction:

- `embedded_files.capabilities.document_level`
- `embedded_files.behaviors.explicit_metadata`
- `embedded_files.behaviors.authored_timestamps`
- `embedded_files.behaviors.page_attachment_annotations`
- `links.targets.external_uri_http_https`
- `links.targets.internal_page`
- `links.behaviors.fragment_rectangles`
- `links.behaviors.named_destinations`

### 2. Viewer-claim posture

Viewer status should be tracked separately under `embedded_files.viewers.*` and `links.viewers.*`.

Reasons:

- embedded files and links expose different viewer behaviors
- a viewer can plausibly support one surface and not the other
- one shared viewer bucket would overclaim and violate least surprise

Status meaning:

- `supported`: recorded checklist proof exists for that viewer and surface
- `unverified`: Rendro authors the surface structurally, but no proof-backed viewer claim exists yet
- `unsupported`: Rendro does not author that surface or explicitly rejects it

### 3. Proof model

Use a minimal two-lane model:

- automated structural proof lane
- separate viewer-evidence lane

Structural proof should remain the real merge-blocking contract. It should cover:

- support-matrix shape
- docs wording parity
- docs lane registration
- existing writer/validation/determinism proof from Phases 48 and 49

Viewer evidence should be the smallest durable artifact needed to justify named support claims. Record:

- viewer name
- version if easily available
- OS
- fixture used
- date checked
- pass/fail/unverified per named behavior
- a short note only when needed

Recommended checklist scope:

- embedded files: discoverable, open/extract, save/extract
- links: external URI handoff, internal page navigation

Do not treat security warnings or policy prompts as support unless they block the basic workflow.

### 4. Public wording and DX posture

Use:

- `embedded files` as the canonical PDF-internal term
- plain `links` in public API/docs prose
- `curated` only in support-boundary prose when scope fencing matters

Reasons:

- `attachments` already means delivery/email attachment in existing adapter docs
- `Rendro.link/2` is already the idiomatic API noun
- this balances user friendliness with truthful scope boundaries

Recommended wording direction:

- "Rendro supports document-level embedded files with explicit metadata."
- "Rendro supports authored links for external `http`/`https` URIs and internal page destinations."
- "Structural validation proves PDF structure only. Viewer behavior is tracked separately and only named as supported when recorded proof exists."

## Repo-Specific Implications

- `guides/api_stability.md` is the best canonical public surface to extend because it already holds support-boundary prose and is published in ExDoc under `Policies`.
- `test/docs_contract/forms_claims_test.exs` is the closest contract-test precedent: literal string assertions for JSON shape, exact wording, and anti-overclaim refutes.
- `scripts/verify_docs.exs` should gain a new named docs-contract lane for Phase 50 claims tests rather than hiding the checks inside another suite.
- `README.md` and `guides/integrations.md` are secondary-only surfaces unless planning decides terminology reinforcement is necessary.

## Recommended Plan Shape

The lowest-risk planning decomposition is:

1. Contract artifact reshape
2. Public wording + docs-contract sync
3. Proof-record and validation closure

That decomposition keeps matrix/schema work, prose work, and manual-proof synchronization separated enough to reduce merge risk while still preserving one coherent support story.

## Adjacent-Library Lessons

- Favor the small explicit contract style common in Elixir libraries and configuration tooling over compatibility-database complexity.
- Learn from PDF libraries that broader link/action/attachment surfaces create semantic footguns and misleading expectations.
- Keep the support artifact optimized for maintainers first: readable diffs, literal tests, stable keys, and minimal policy ambiguity.

## Planning Guidance

- Do not re-open the support-matrix family-first decision.
- Do not propose a generic annotations story, named destinations, extra URI schemes, or page file-attachment annotations.
- Do not collapse structural proof into viewer proof.
- Prefer one combined support-boundary claims test if it keeps the contract easier to read and wire into `mix docs.contract`.

## RESEARCH COMPLETE
