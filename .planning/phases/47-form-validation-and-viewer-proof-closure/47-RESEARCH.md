# Phase 47: Form Validation and Viewer-Proof Closure - Research

**Researched:** 2026-05-05
**Status:** Ready for planning

## Executive Summary

Phase 47 should close the interactive-forms milestone by tightening the authored validation contract around the existing `:text`, `:checkbox`, and `:radio` widgets, then binding those claims to a small machine-readable support matrix and equally narrow public wording. The strongest implementation path is to extend the existing validate-stage rule flow rather than introducing a second validator or pushing semantics into the writer. The strongest proof posture is also split, not unified: authored semantic validation in core, Poppler-backed structural validation as a separate optional lane, and explicit viewer-proof claims for named viewers only where reproducible evidence exists.

The narrowest truthful recommendation set is:

- Enforce supported authored semantics in `Rendro.Pipeline.Validate` through `Rendro.Rules.CheckFormFields`.
- Reject ambiguous field identity, dotted/hierarchical names, non-binary values, empty button export values, and contradictory radio defaults as typed validation failures.
- Keep `priv/support_matrix.json` small and nested under a forms-focused contract with separate `widgets`, `behaviors`, `viewers`, and `unsupported` facets.
- Limit supported viewer claims to Adobe Acrobat Reader and Apple Preview once the phase creates reproducible proof for open, visible defaults, edit/toggle behavior, and save.
- Keep every other viewer explicitly `unverified` unless a committed proof artifact exists.

## Recommended Validation Contract

### 1. Field identity should stay flat and explicit

Rendro already exposes a flat `FormField.name` string and the writer groups radios by explicit `group`. Phase 47 should preserve that authored model and reject shapes that imply unimplemented hierarchical AcroForm semantics.

Recommended rules:

- Reject duplicate field names for supported standalone fields.
- Reject duplicate checkbox names.
- Reject duplicate text field names.
- Reject dotted or hierarchical names such as `"billing.address.city"` for all currently supported widgets.
- For radio widgets, keep group identity explicit through `group` and keep widget option identity explicit through `export_value`.
- Reject duplicate radio `export_value`s within the same `group`.

Recommended posture:

- Do not attempt to normalize or split dotted names.
- Do not infer grouping from shared `name`, layout proximity, or widget order.
- Do not widen into parent/child AcroForm naming support in this phase.

Likely error tuples:

- `{:duplicate_form_field_name, name}`
- `{:unsupported_form_field_name, name}`
- `{:duplicate_radio_export_value, group, export_value}`

### 2. Validation should stay explicit and non-coercive

The current rule module already uses simple guard-based invariants. Phase 47 should continue that style and reject unsupported shapes directly rather than converting them.

Recommended rules:

- Text-field `value` must be a binary.
- Checkbox and radio `export_value` must be a non-empty binary.
- `checked` must remain a boolean.
- Text-field editing attributes that Rendro consumes for authored appearance generation should be explicitly validated as supported shapes.

Conservative recommendation for Phase 47:

- Keep `font` limited to supported Standard 14 editing-font inputs already relied on by the writer.
- Require `size` to be a positive number.
- Do not silently convert atoms to strings for `name`, `group`, `export_value`, or `value`.
- Do not silently map truthy values to booleans.

Likely error tuples:

- `{:invalid_form_field_value, value}`
- `{:invalid_form_field_font, font}`
- `{:invalid_form_field_size, size}`
- `{:invalid_form_field_export_value, export_value}`

### 3. Radio semantics should fail before serialization guesswork

The existing code already rejects multiple checked defaults in one radio group. Phase 47 should complete that story by locking the rest of the group semantics up front.

Recommended rules:

- Radio widgets must have explicit non-empty `group`.
- Radio widgets must have explicit non-empty `export_value`.
- At most one checked default may exist per radio group.
- A radio group should not mix widgets with contradictory author intent such as empty export values or duplicate export values.
- If Phase 47 keeps the current writer shape of one parent field per radio group, validation should reject any authored input that would force the writer to guess the parent identity.

Likely error tuples:

- `{:radio_group_multiple_checked_defaults, group}`
- `{:duplicate_radio_export_value, group, export_value}`
- `{:radio_group_name_mismatch, group}` only if planning decides name-level consistency is required

Recommendation on `name` for radios:

- Keep `group` as the canonical logical identity.
- Let the planner decide between:
  - requiring each radio widget name to be unique and treating `group` as the parent field name, or
  - requiring each radio widget `name` to match the shared `group`.

The safer choice is to require a single coherent rule and document it clearly, not to support multiple equivalently valid authored styles.

## Support Matrix Recommendation

The current `priv/support_matrix.json` is too coarse for the forms surface. Phase 47 should evolve it into a small nested facet map that separates product-contract axes without pretending to be a full compatibility database.

Recommended shape:

```json
{
  "validators": {
    "pdfinfo": {
      "version": "22+",
      "validates": ["structural_integrity"]
    }
  },
  "forms": {
    "widgets": {
      "text": "supported",
      "checkbox": "supported",
      "radio": "supported",
      "signature": "unsupported",
      "xfa": "unsupported"
    },
    "behaviors": {
      "prefilled_values": "supported",
      "authored_appearance": "supported",
      "need_appearances": "unsupported",
      "hierarchical_field_names": "unsupported",
      "external_pdf_filling": "unsupported"
    },
    "viewers": {
      "adobe_acrobat_reader": {
        "status": "supported",
        "proof": ["open", "default_state_visible", "edit_or_toggle", "save"]
      },
      "apple_preview": {
        "status": "supported",
        "proof": ["open", "default_state_visible", "edit_or_toggle", "save"]
      },
      "chrome_pdfium": {
        "status": "unverified"
      },
      "pdfjs": {
        "status": "unverified"
      }
    }
  },
  "unsupported": ["full_pdf_compliance", "digital_signatures"]
}
```

Why this shape fits Rendro:

- `widgets` answers what authored surfaces exist.
- `behaviors` answers what claims Rendro makes about runtime behavior.
- `viewers` answers where those claims are supported or merely unverified.
- top-level `validators` preserves the existing separate structural proof lane.
- top-level `unsupported` still works for broad cross-cutting non-goals.

Constraints for planning:

- Keep stable access paths; tests should assert exact nested keys.
- Avoid versioned per-viewer freeform prose inside JSON.
- Prefer status enums such as `supported`, `unsupported`, and `unverified`.
- Keep future additions additive.

## Proof Lanes and Evidence Strategy

Phase 47 should formalize three distinct proof lanes and keep them separate in both code and docs.

### 1. Core validation lane

Purpose:

- Prove Rendro rejects unsupported authored form states before render.

Artifacts:

- `test/rendro/rules/check_form_fields_test.exs`
- `test/rendro/pipeline/validate_test.exs`

Evidence:

- raw tuple assertions for each invariant
- aggregate validate-stage assertions through `%Rendro.Error{details: %{errors: ...}}`

### 2. Structural validation lane

Purpose:

- Prove rendered PDFs are structurally acceptable to the optional Poppler adapter.

Artifacts:

- existing `lib/rendro/adapters/poppler.ex`
- existing `test/rendro/adapters/poppler_test.exs`
- possibly one integration test that renders a forms PDF and runs `Poppler.validate/1` when available

Evidence:

- `{:ok, metadata}` for a generated valid PDF
- typed graceful degradation when `pdfinfo` is unavailable

Important boundary:

- This lane proves structure, not interactive behavior inside Acrobat or Preview.

### 3. Viewer-proof lane

Purpose:

- Back public claims about named viewers with reproducible evidence.

Recommended artifacts:

- a committed verification doc in the phase directory, likely `47-VALIDATION.md`
- a small committed proof checklist for Acrobat Reader and Apple Preview
- optionally fixture PDFs or deterministic generation commands used to reproduce the checks

Recommended supported proof points per named viewer:

- opens successfully
- default field state is visible immediately on open
- user can type into text fields
- user can toggle checkboxes / select radio buttons
- user can save the modified file

Important caution:

- The repo currently has no established viewer-proof artifact storage pattern. Planning should introduce the smallest durable pattern possible rather than inventing a large evidence system.

## Documentation and Contract Wiring

Phase 47 should avoid scattering claims across many prose surfaces. The safest path is one authoritative docs surface plus tests plus `priv/support_matrix.json`.

Recommended docs posture:

- Keep the public support wording narrow and named.
- Avoid phrases like “works in standard PDF viewers”.
- Explicitly state that other viewers may work but are not part of the supported contract unless listed in the support matrix.
- Preserve the existing support-boundary tone from `guides/api_stability.md`.

Recommended testing approach:

- Add a claims-style ExUnit test that reads the relevant public docs surface and asserts exact supported/unverified wording.
- Add an ExUnit contract test for `priv/support_matrix.json` instead of relying only on `jq`.
- Extend release-preflight only if a new guide file is introduced.

## Likely File Targets

Primary implementation files:

- `lib/rendro/rules/check_form_fields.ex`
- `test/rendro/rules/check_form_fields_test.exs`
- `test/rendro/pipeline/validate_test.exs`
- `priv/support_matrix.json`

Likely contract and docs files:

- `README.md` and/or a forms-focused guide if one already exists
- `guides/api_stability.md` only if support-boundary language belongs there
- `test/docs_contract/*claims*_test.exs`
- `scripts/verify_docs.exs` only if new docs-contract tests need to join the standard lane

Likely planning-owned verification artifacts:

- `.planning/phases/47-form-validation-and-viewer-proof-closure/47-VALIDATION.md`
- possibly a viewer-proof checklist file if the plan splits evidence capture from validation criteria

## Planning Implications

The cleanest Phase 47 breakdown is three plans, not one giant plan:

1. Core form validation hardening
2. Support matrix and docs contract wiring
3. Viewer-proof and milestone closure verification

Why this split is better:

- validation changes are core behavior and test-heavy
- support-matrix/docs changes are contract-surface work
- viewer-proof is a separate evidence lane with different verification steps and possible manual checks

Recommended planner constraints:

- Keep every plan scoped to one dominant responsibility.
- Preserve separation between automated validation and manual viewer verification.
- Prefer additive tests over broad refactors.
- Do not plan new widget families, hierarchical field support, or full compliance claims.

## Open Design Choice To Resolve In Planning

The main remaining product-semantic choice is how strict to be about radio naming relative to `group`.

Recommended default:

- choose one authored rule and make it explicit
- reject mixed styles
- document it in both tests and support matrix wording

This is the only area where the planner may need to make a narrow contract choice instead of merely executing the phase context.

## Research Conclusion

Phase 47 does not need new PDF surface area. It needs stronger authored validation, a better machine-readable contract, and truthful proof-backed support language. The current codebase already has the right architectural seams for that work: validate-stage rule modules, typed error aggregation, docs-contract tests, and a separate optional structural validator. The phase should close the milestone by tightening those seams rather than widening the product.
