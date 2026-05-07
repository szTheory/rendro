# Phase 50 Patterns: Support-Boundary and Proof Closure

**Date:** 2026-05-06
**Phase:** 50

## Existing Patterns To Reuse

### 1. Family-first support matrix

Current precedent:

- `priv/support_matrix.json` uses explicit top-level product families
- `test/docs_contract/forms_claims_test.exs` literally pins the shape and rejects the old `surfaces` wrapper

Planning implication:

- extend the existing top-level structure with `embedded_files` and `links`
- keep the JSON readable and literal rather than abstract or self-describing

### 2. Canonical policy guide

Current precedent:

- `guides/api_stability.md` carries the support contract for forms
- the guide structure is short, explicit, and policy-first

Planning implication:

- extend this file first for embedded files and links
- avoid adding a second competing support-boundary guide unless absolutely necessary

### 3. Docs-contract semantic claims test

Current precedent:

- `test/docs_contract/forms_claims_test.exs` checks:
  - exact JSON keys
  - exact wording sentences
  - exact anti-overclaim refutes
  - verify-lane registration in `scripts/verify_docs.exs`

Planning implication:

- Phase 50 should follow the same style
- prefer one literal claims test that owns matrix shape + wording + docs-lane registration
- keep executable code-fence verification separate from semantic claims

### 4. Canonical docs verification lane

Current precedent:

- `scripts/verify_docs.exs` enumerates named lanes
- repo-level `mix docs.contract` wraps that script

Planning implication:

- add a new named Phase 50 claims lane
- do not bypass `mix docs.contract`
- preserve the explicit named-lane style for clarity in CI and local runs

### 5. Support promotion after proof

Current precedent:

- Phase 47 separated:
  - matrix/docs setup
  - structural proof
  - post-proof support promotion

Planning implication:

- if Phase 50 promotes any viewer from `unverified` to `supported`, keep that in a later closure slice
- do not promote support in the same step that invents the checklist

## Likely File Touch Set

Primary:

- `priv/support_matrix.json`
- `guides/api_stability.md`
- `scripts/verify_docs.exs`
- `test/docs_contract/*claims*_test.exs`
- `.planning/phases/50-support-boundary-and-proof-closure/50-VALIDATION.md`

Secondary:

- `README.md`
- `guides/integrations.md`
- `test/mix/tasks/docs_contract_task_test.exs`
- `test/mix/tasks/verify_test.exs`

## Low-Conflict Slice Mapping

### Slice 1: Contract artifact + claims test

Files:

- `priv/support_matrix.json`
- new support-boundary claims test(s)

Reason:

- schema and its assertions can be locked before prose changes

### Slice 2: Public wording sync

Files:

- `guides/api_stability.md`
- optional terminology reinforcement in `README.md` or `guides/integrations.md`

Reason:

- prose can follow the stabilized matrix

### Slice 3: Docs gate wiring

Files:

- `scripts/verify_docs.exs`
- any affected Mix-task tests

Reason:

- small mechanical wiring once the final claims-test filename is known

### Slice 4: Proof/evidence closure

Files:

- `50-VALIDATION.md`
- possibly matrix/docs/test updates if viewer statuses are promoted

Reason:

- manual-evidence synchronization should remain a distinct closure step

## Footguns To Avoid

- Do not reintroduce a generic `"surfaces"` wrapper.
- Do not use broad wording like "standard PDF viewers".
- Do not use `attachments` as the headline term for PDF-internal payloads.
- Do not conflate Poppler/pdfinfo structural validation with viewer behavior.
- Do not build a metadata-heavy compatibility matrix with per-leaf notes/proof arrays unless strictly necessary.
- Do not hide the new docs checks inside an unrelated existing lane.

## Strong Analogs

- Phase 47 `47-02-PLAN.md`: contract artifact + docs-contract sync
- Phase 47 `47-03-PLAN.md`: proof lane + support promotion sync

Phase 50 should mirror that decomposition, adapted for embedded files and links rather than forms.
