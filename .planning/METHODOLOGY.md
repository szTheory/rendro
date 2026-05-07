# Rendro Methodology

Purpose: shift routine implementation decisions left so GSD agents default toward Rendro's preferred engineering posture without repeatedly escalating the same class of questions to the user.

Use these lenses during discuss, assumptions, research, planning, execution, review, and docs updates.

## Lens: Truthful Small Contracts

### Diagnoses
- A proposal broadens the public contract beyond what tests, docs, or integration evidence can support.
- A design relies on heuristics, "best effort" behavior, or implicit polymorphism where an explicit smaller contract would be clearer.
- A docs claim would become broader than the implementation and verification actually prove.

### Recommendations
- Prefer the smallest truthful public contract that still satisfies the locked phase boundary.
- Prefer explicit accepted shapes, explicit error tuples, and explicit unsupported cases.
- If true extensibility is needed, prefer a real behaviour/protocol or a separate API over heuristic duck typing.
- If a broader contract is required by a locked phase, implement it narrowly and document the exact supported shape.
- For new authored PDF features, prefer an explicit dedicated builder/node over hiding behavior inside generic content attrs when the feature changes product semantics or support boundaries.

### Triggering Conditions
- Optional adapters, integrations, and recipes
- Public helper functions
- Docs-contract wording
- Any code path where "supporting more" would increase surprise or maintenance burden

## Lens: Boundary Validation First

### Diagnoses
- Nested input can crash late instead of returning a typed error at the boundary.
- A helper silently skips, fabricates, or partially applies invalid user data.
- A feature mixes parsing/coercion concerns into a rendering or execution API.

### Recommendations
- Validate at the adapter or public API boundary before doing work.
- Prefer failing the whole operation with a typed tuple over silently dropping invalid business data.
- Keep normalization/coercion separate from deterministic recipe/render APIs unless the API is explicitly designed as an ingestion layer.
- Include enough error detail for callers to identify the offending nested field or shape.

### Triggering Conditions
- Recipe builders
- Adapters around external structs
- Nested input collections
- Any public function returning `{:ok, value} | {:error, reason}`

## Lens: Deterministic Standard Formatting

### Diagnoses
- User-visible output contains debug syntax (`inspect/1`, struct dumps, sigils).
- Formatting depends on locale, host settings, or ambient timezone without explicit caller opt-in.
- A reusable library helper chooses presentation formats that are pleasant in one app but unstable across environments.

### Recommendations
- Default to deterministic standard-library formatting such as ISO 8601 for dates/times when no explicit locale contract exists.
- Treat locale-aware formatting as an opt-in caller concern, not a hidden library default.
- Use human-facing labels with machine-stable values when that best matches the domain.
- Never use debug formatting in rendered user-facing artifacts.

### Triggering Conditions
- Billing/report document text
- Metadata serialization
- Adapter-generated display strings
- Tests asserting rendered output

## Lens: Least Surprise DX

### Diagnoses
- A library helper appears convenient but hides failure, mutates data unexpectedly, or returns a surprising shape.
- A proposal saves a caller one line while making debugging materially worse.
- The likely "happy path" in docs differs from the real supported contract.

### Recommendations
- Prefer explicit tuples, preserved wrapper types, and stable return shapes.
- Prefer docs and examples that mirror the real supported path exactly.
- Prefer making callers opt into unusual behavior rather than discovering it accidentally.
- When a tradeoff exists between permissiveness and trustworthy behavior, favor trustworthy behavior by default.
- When a feature depends on geometry or ownership semantics, lock the geometry owner first and keep the public API aligned with that owner instead of splitting authority across multiple surfaces.

### Triggering Conditions
- Public examples in guides/README
- Error and return-value design
- Wrapper-preserving helper functions
- Any phase where the user did not explicitly request a broader/more magical contract

## Escalation Rule

Default behavior: apply these lenses automatically and do not escalate routine implementation choices to the user.
Default synthesis style: when multiple viable options exist, collapse them into one coherent recommendation set rather than presenting a menu, unless the user explicitly asks for open-ended exploration.
Default API-shaping bias: prefer explicit narrow public helpers over hidden attrs, overloaded strings, or raw escape hatches unless the broader surface is itself a locked product requirement.

Escalate only when at least one of the following is true:
- The choice changes product semantics or roadmap scope rather than implementation discipline.
- The choice would knowingly break an already documented or verified contract that the phase is not intended to revise.
- Two materially different options both fit the methodology and have real user-visible tradeoffs.
- The decision is high-impact enough that the user is likely to care about the policy itself, not just the implementation.

Otherwise, choose the recommendation that is most consistent with:
1. locked phase scope
2. truthful docs
3. deterministic behavior
4. explicit boundary validation
5. least-surprise DX
6. one coherent recommendation set over multiple equivalent options

## Notes For Future Agents

- Apply this methodology as a bias, not as permission to ignore locked roadmap requirements.
- If a locked phase conflicts with the ideal smaller contract, satisfy the locked phase narrowly and document the exact boundary.
- When updating docs, examples, tests, and traceability, keep them aligned with the chosen contract in the same phase whenever feasible.
