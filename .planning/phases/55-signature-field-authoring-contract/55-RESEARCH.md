# Phase 55: Signature Field Authoring Contract - Research

**Researched:** 2026-05-06
**Domain:** Unsigned AcroForm signature-field authoring boundaries, shared form-model reuse, and validate-stage scope enforcement
**Confidence:** HIGH

## Summary

Phase 55 should extend Rendro's existing interactive-forms authoring surface with a narrow unsigned signature-field contract without widening into writer serialization or external signing semantics. The local codebase already has the correct seams for this:

- `Rendro.form_field/3` and `%Rendro.FormField{}` are the current shared authoring and normalization path for interactive widgets.
- `Rendro.Rules.CheckFormFields` already owns field-local and document-wide form validation and is the natural place to add signature-specific rejection rules.
- `Rendro.Pipeline.Validate` already aggregates rule failures into one validate-stage typed error envelope before any writer work begins.
- `guides/api_stability.md` and `priv/support_matrix.json` already act as the canonical truthful support contract for forms and trust-sensitive surfaces.

The key planning constraint is scope discipline. Phase 55 is not the phase for `/Sig` widget serialization, `/V` dictionaries, `/ByteRange`, `/Contents`, lock dictionaries, signer metadata, or any artifact-first signing-preparation workflow. It exists to lock the public authored shape first so Phase 56 only has to serialize a supported, truthful contract.

**Primary recommendation:** split Phase 55 into two plans:
1. Public API, shared form-model, and validate-stage contract updates for `Rendro.signature_field/2` and internal `type: :signature` normalization.
2. Regression/docs/support-boundary updates that prove the narrow contract and keep `signature` visibly unsupported at the writer/viewer level until later phases land.

<user_constraints>
## User Constraints (from Phase Context)

### Locked Decisions
- Expose `Rendro.signature_field/2` as the canonical public API for unsigned signature fields.
- Reuse `%Rendro.FormField{}` with `type: :signature`; do not create a second form model or render subsystem.
- Support only visible unsigned placeholders with explicit field identity and explicit geometry.
- Reject authored `value`, signer metadata, signing dictionaries, lock policy, and other cryptographic/signing attrs in `Rendro.Pipeline.Validate`.
- Keep the initial appearance deterministic and Rendro-owned; do not rely on `NeedAppearances`.
- Do not claim viewer behavior, digital-signature behavior, tamper evidence, or compliance outcomes in this phase.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Public unsigned signature DX | `Rendro` | `Rendro.FormField` | The user-facing contract should be an explicit dedicated helper instead of generic `form_field(..., type: :signature)` guidance. |
| Shared authored widget model | `Rendro.FormField` | builder normalization | The internal engine already has one form-field carrier; Phase 55 should extend it, not fork it. |
| Unsupported-state rejection | `Rendro.Rules.CheckFormFields` | `Rendro.Pipeline.Validate` | Validate-stage rejection is already the truthful boundary for authored form semantics. |
| Measurement and geometry ownership | existing block / measure pipeline | builder defaults | Signature fields should obey the same explicit block geometry owner as other widgets. |
| Support-boundary truth | `priv/support_matrix.json` | `guides/api_stability.md`, docs-contract tests | Signature support must remain visibly narrow and non-cryptographic across machine-readable and human-readable claims. |

## Recommended Modeling

### Public API
- Add `Rendro.signature_field/2` as a dedicated helper that accepts `name` and block geometry attrs.
- Internally build a `%Rendro.FormField{type: :signature}` inside a normal `%Rendro.Block{}`.
- Keep `Rendro.form_field/3` working for internal normalization, but do not position `type: :signature` as the primary public DX in docs/examples.

### Internal Shared Model
- Extend `Rendro.FormField.field_type` to include `:signature`.
- Keep the struct shared across widget families so the writer and validator continue to consume one field carrier.
- Preserve the current explicit attrs surface; Phase 55 should reject unsupported signature semantics rather than adding a permissive options bag.

### Validation Posture
- Signature fields should reject authored `value` or default-value semantics.
- Signature fields should reject button-family carryover attrs such as `checked`, `group`, and `export_value`.
- Signature fields should reject invisible/zero-rect intent through the same explicit geometry boundary used for supported widgets.
- Signature fields should reject signing-specific metadata and low-level PDF-signing keys before render rather than letting downstream code ignore them.

## Architecture Patterns

### Pattern 1: Dedicated Public Helper, Shared Internal Carrier
Use a dedicated builder function for a feature that changes product semantics while still normalizing into the existing `%Rendro.FormField{}` path. This matches Rendro's "truthful small contract" lens: explicit public DX, one internal engine.

### Pattern 2: Validate the Unsupported Surface Explicitly
Do not silently ignore signature-specific attrs. Encode the unsupported authored states as typed validate-stage errors in `CheckFormFields` so the boundary remains obvious and testable.

### Pattern 3: Keep Phase 55 Writer-Neutral
Phase 55 should not promise serialized `/Sig` widgets or appearance objects yet. Plans should touch builder/model/validation/docs/test seams and leave actual PDF object work for Phase 56.

## Don’t Hand-Roll

| Problem | Don’t Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public signature DX | Docs telling users to call `Rendro.form_field(..., type: :signature)` directly | `Rendro.signature_field/2` | Narrower, clearer, and aligns with the locked public API decision. |
| Unsupported signing options | Raw `opts` passthrough or generic metadata bags | Explicit validate-stage rejection tuples | Silent acceptance would overstate the contract and create future writer ambiguity. |
| Signature rendering claims | Writer placeholders or viewer support prose in this phase | Keep serialization/viewer claims deferred | Phase 55 is authoring-contract work only. |
| Parallel form subsystem | New signature-specific struct or render path | Reuse `%Rendro.FormField{}` and existing validation pipeline | One-engine architecture is a locked constraint. |

## Common Pitfalls

### Pitfall 1: Treating `:signature` Like a Supported Writer Surface
**What goes wrong:** A plan starts editing `lib/rendro/pdf/writer.ex` in Phase 55 and implicitly widens scope into `/Sig` serialization.
**How to avoid:** Keep writer/object-allocation work out of Phase 55 plans except for assertions that current writer-dependent claims remain deferred.

### Pitfall 2: Accepting Signature Attrs and Ignoring Them Later
**What goes wrong:** Callers can pass `value`, `reason`, `location`, `/Filter`, or other signing keys, and the engine quietly drops them.
**How to avoid:** Reject those attrs with focused validate-stage tuples so authored intent cannot silently exceed the contract.

### Pitfall 3: Leaving Docs and Support Matrix in a Contradictory State
**What goes wrong:** Code starts accepting `type: :signature`, but docs/support matrix still imply either total lack of signature work or actual digital-signature support.
**How to avoid:** Update the forms and trust-boundary contract in the same phase while keeping `digital_signatures` unsupported and Phase 55 visibly limited to unsigned authored placeholders.

### Pitfall 4: Splitting Geometry Ownership
**What goes wrong:** The signature helper invents special positioning semantics or an invisible placement mode.
**How to avoid:** Reuse the normal block geometry owner and reject zero-rect/invisible intent instead of adding a second placement story.

## Codebase Facts

- `lib/rendro.ex` currently exposes `Rendro.form_field/3` but no dedicated signature-field helper.
- `lib/rendro/form_field.ex` currently limits `field_type` to `:text | :checkbox | :radio`.
- `test/rendro/rules/check_form_fields_test.exs` currently asserts that `type: :signature` is invalid, so Phase 55 must intentionally replace that old boundary with the new narrowed contract.
- `test/rendro_builders_test.exs` currently covers builder semantics and is the natural regression home for `Rendro.signature_field/2`.
- `test/docs_contract/forms_claims_test.exs`, `guides/api_stability.md`, and `priv/support_matrix.json` currently state that forms support text/checkbox/radio only and signature remains unsupported.

## State of the Art

| Existing State | Phase 55 Target | Impact |
|----------------|-----------------|--------|
| Signature widgets are fully unsupported and rejected as invalid form-field types | Unsigned signature fields become a supported authored input contract with strict boundary rejection for unsupported semantics | Locks the public shape early while preserving truthful deferral of serialization and signing workflows. |

## Open Questions (RESOLVED)

1. **Should Phase 55 create a second signature-field struct or pipeline?**
   - Recommendation: no. Reuse `%Rendro.FormField{}` with `type: :signature` and keep one engine path.

2. **Should `Rendro.form_field(..., type: :signature)` be the public guidance?**
   - Recommendation: no. Add `Rendro.signature_field/2` as the explicit public helper and treat the generic form-field path as internal normalization detail.

3. **Should unsupported signing attrs be ignored for forward compatibility?**
   - Recommendation: no. Reject them now with typed validate-stage errors so the support boundary stays truthful and least-surprise.

## Validation Architecture

### Test Framework
- ExUnit builder tests for the new public helper and shared internal normalization.
- Rule tests in `test/rendro/rules/check_form_fields_test.exs` for signature-specific rejections.
- Validate-stage aggregation tests in `test/rendro/pipeline/validate_test.exs`.
- Docs-contract tests in `test/docs_contract/forms_claims_test.exs` for support-matrix and wording drift.

### Phase Requirements → Test Map
- `SIGN-01` -> `test/rendro_builders_test.exs`, `test/rendro/rules/check_form_fields_test.exs`
- `SIGN-02` -> `test/rendro/rules/check_form_fields_test.exs`, `test/rendro/pipeline/validate_test.exs`
- truthful support-boundary sync -> `test/docs_contract/forms_claims_test.exs`

## RESEARCH COMPLETE

### Key Findings
- The existing builder/model/validate seams are sufficient; Phase 55 does not need a second form subsystem.
- The highest-risk regression is boundary ambiguity: the plans must explicitly replace the old “signature is invalid type” rule with a new “signature is valid only within a narrow unsigned contract” rule set.
- The phase naturally decomposes into one code-facing contract slice and one docs/support/regression slice.

### Ready for Planning
Yes. The scope is locked, the seams are concrete, and the writer/signing-preparation work remains clearly deferred to Phase 56.
