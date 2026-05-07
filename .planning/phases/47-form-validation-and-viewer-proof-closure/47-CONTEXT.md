# Phase 47: Form Validation and Viewer-Proof Closure - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the interactive-forms milestone by making Rendro's supported AcroForm contract explicit, validated, and truthfully documented. This phase does not add new widget families. It hardens the existing text, checkbox, and radio surface with stronger semantic validation, clear viewer-support boundaries, and a machine-readable support matrix that matches real proof.

</domain>

<decisions>
## Implementation Decisions

### Validation scope
- **D-01:** Phase 47 should add **supported-surface semantic validation in core**, not just thin required-key checks and not a full PDF-compliance validator.
- **D-02:** Validation should stay at the authored boundary, following the existing `Rendro.Pipeline.Validate` + focused rule-module pattern from Phase 43.
- **D-03:** The validator should reject unsupported or ambiguous authored states early with typed errors rather than relying on writer behavior or viewer quirks to expose them later.
- **D-04:** The supported validation contract is only for Rendro's currently claimed form surface: `:text`, `:checkbox`, and `:radio`.
- **D-05:** Validation should remain explicit and non-coercive. No magical conversion of booleans, strings, names, or values.

### Form semantics to enforce
- **D-06:** Reject duplicate or ambiguous field identity within the supported surface. Downstream research/planning should define the narrowest truthful rule set for full field-name uniqueness and radio-group identity without widening into hierarchical AcroForm naming.
- **D-07:** Reject unsupported hierarchical or dotted field names unless Phase 47 intentionally adds and proves them. Default stance: unsupported.
- **D-08:** Text-field values must be binaries, and form-editing attributes consumed by authored appearance generation must be validated as explicit supported shapes rather than passed through permissively.
- **D-09:** Checkbox and radio export values must be non-empty binaries.
- **D-10:** Radio widgets must keep explicit group identity, explicit export values, and deterministic single-default semantics. Contradictory checked defaults must fail in validation.
- **D-11:** Validation should reject mixed or contradictory authored states that would force the writer to guess intent.

### Viewer support claims
- **D-12:** Do **not** claim that forms work in "standard PDF viewers" broadly. That wording is too vague and too easy to overclaim.
- **D-13:** Viewer claims must be separated into explicit buckets rather than treated as one blanket support statement.
- **D-14:** Initial **supported** viewer contract should be narrow and named: Adobe Acrobat Reader and Apple Preview, contingent on committed proof for open, visible default state, edit/toggle behavior, and save.
- **D-15:** Other viewers must not be silently implied. If they are not covered by committed proof, classify them as `unverified` rather than "probably works".
- **D-16:** "Observed" behavior is only acceptable if it is backed by a reproducible proof artifact. Anecdotal local testing is not enough for a public support claim.
- **D-17:** Poppler-backed structural validation remains valuable but must be documented as a **different proof lane** from viewer-interaction proof.

### Support matrix shape
- **D-18:** Evolve `priv/support_matrix.json` from the current coarse shape into a **nested facet map** for forms rather than a flat string list or a giant compatibility matrix.
- **D-19:** The matrix should separate at least three axes:
  - widget capabilities
  - behavior/contract claims
  - viewer support posture
- **D-20:** The matrix should remain small, stable, and versionable. It is a support-boundary artifact, not a web-scale browser-compat product.
- **D-21:** The matrix should be able to express both supported and explicitly unsupported forms surfaces, including future signatures/XFA, without requiring prose exceptions everywhere.
- **D-22:** Human docs should mirror or render from the same matrix so docs claims and machine-readable claims cannot drift.

### Cohesive recommendation set
- **D-23:** The overall Phase 47 posture is:
  - strong semantic validation in core
  - optional external structural validation adapters kept separate
  - narrow named-viewer support claims
  - machine-readable boundary metadata that reflects all three cleanly
- **D-24:** Downstream agents should prefer one coherent recommendation set over presenting menus unless they hit a truly high-impact product-semantic decision.

### the agent's Discretion
- Exact error tuple shapes and rule-module decomposition, provided the contract stays explicit and typed.
- The exact nested JSON schema for `support_matrix.json`, provided it preserves small truthful contracts and stable access paths.
- Whether unverified viewers appear only in the JSON, or in both JSON and human docs, provided public wording never implies support.

</decisions>

<specifics>
## Specific Ideas

- Preserve the existing Rendro posture that authored appearances are generated by Rendro itself; do not backslide into `NeedAppearances` or viewer-managed appearance regeneration.
- Treat this phase like `Ecto.Changeset` / `NimbleOptions` style boundary enforcement for Rendro forms: explicit accepted shapes, explicit failures, no permissive coercion.
- Preferred public wording direction:
  - "Rendro supports authored AcroForm text fields, checkboxes, and radio groups."
  - "Supported viewers: Adobe Acrobat Reader and Apple Preview."
  - "Other viewers may render or interact successfully, but they are not part of the supported contract unless listed in the support matrix."
- Preferred matrix direction:
  - `forms.widgets.text`
  - `forms.widgets.checkbox`
  - `forms.widgets.radio`
  - `forms.widgets.signature`
  - `forms.behaviors.prefilled_values`
  - `forms.behaviors.authored_appearance`
  - `forms.behaviors.need_appearances`
  - `forms.viewers.acrobat_reader`
  - `forms.viewers.apple_preview`
  - optional future `forms.viewers.chrome_pdfium` / `forms.viewers.pdfjs`
- Shift-left preference from discussion:
  - Default to opinionated, research-backed, cohesive recommendations in GSD workflows.
  - Escalate only when a choice materially changes product semantics, breaks an existing documented contract, or carries a user-visible policy tradeoff the maintainer is likely to care about.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope
- `.planning/milestones/v1.8-ROADMAP.md` — Phase 47 boundary, risks, proof strategy, and milestone definition of done.
- `.planning/milestones/v1.8-CONTEXT.md` — Interactive forms milestone intent, prior architectural constraints, and acceptance language.
- `.planning/phases/45-CONTEXT.md` — Locked text-field foundation decisions, especially authored appearances and Standard 14 editing-font boundary.
- `.planning/phases/46-checkbox-and-radio-button-widgets/46-CONTEXT.md` — Locked checkbox/radio decisions, explicit radio grouping, and current validation expectations.

### Trust surfaces and support boundaries
- `.planning/phases/43-structural-validation/43-CONTEXT.md` — Existing validate-stage architecture and rule-module pattern to extend.
- `.planning/phases/44-validator-backed-trust-surfaces/44-CONTEXT.md` — External validator adapter posture and support-boundary philosophy.
- `.planning/phases/44-validator-backed-trust-surfaces/VALIDATION.md` — Existing validation-lane expectations and support-matrix baseline.
- `guides/api_stability.md` — Public support-boundary and stability-policy tone to preserve.
- `priv/support_matrix.json` — Current machine-readable contract that Phase 47 will evolve.
- `.planning/METHODOLOGY.md` — Active lenses: truthful small contracts, boundary validation first, deterministic standard formatting, least surprise DX.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/rendro/rules/check_form_fields.ex`: current focused form-rule entry point; the natural place to deepen authored validation or split into adjacent form rule modules.
- `lib/rendro/pipeline/validate.ex`: existing single-pass walker with rule-module dispatch; Phase 47 should extend this pattern rather than invent a parallel validation path.
- `lib/rendro/form_field.ex`: current authored data carrier for the supported widget surface.
- `lib/rendro/pdf/writer.ex`: already encodes the actual supported AcroForm serialization behavior; planning should treat writer invariants as evidence and avoid duplicating broad compliance logic in the validator.
- `lib/rendro/adapters/poppler.ex`: existing optional structural validator adapter; useful as a separate proof lane, not as the primary source of form-semantics truth.

### Established Patterns
- Narrow explicit contracts beat permissive magic throughout Rendro.
- Optional trust surfaces live behind adapters instead of coupling core to external binaries.
- Support claims are expected to be machine-readable and intentionally smaller than the universe of theoretically possible PDF behavior.

### Integration Points
- Validation changes connect primarily through `Rendro.Pipeline.Validate` and form-focused rule modules.
- Viewer-proof and support-matrix closure will likely touch docs, tests, and `priv/support_matrix.json` together as one contract surface.
- Any new viewer-proof lane must remain clearly distinct from structural `pdfinfo` validation.

</code_context>

<deferred>
## Deferred Ideas

- Signature widgets and digital-signature behavior — separate future phase.
- XFA support — out of scope.
- Broad "standard viewer" marketing claims — explicitly rejected for this phase.
- Full viewer × widget × behavior compatibility matrix — too expensive and too easy to let drift.
- Full AcroForm/PDF compliance certification claims — out of scope for Rendro's current trust surface.
- Hierarchical/dotted form naming, unless Phase 47 planning finds a narrow and fully proven contract worth adding.

</deferred>

---

*Phase: 47-form-validation-and-viewer-proof-closure*
*Context gathered: 2026-05-05*
