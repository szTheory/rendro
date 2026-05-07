# Phase 10: recipe-correctness-and-traceability - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the remaining Phase 5 recipe defects without widening Rendro's product scope: make the Mailglass attachment helper honor its documented custom-wrapper path, make the Accrue recipe return typed errors instead of raising on bad nested input, normalize the Accrue invoice date so PDFs show user-facing values instead of Elixir debug syntax, and resync REQUIREMENTS.md traceability so ADPT-05 tells the truth.

</domain>

<decisions>
## Implementation Decisions

### Mailglass wrapper contract
- **D-01:** Keep custom Mailglass-style wrapper support in scope for Phase 10. Phase 10 success criteria explicitly require the custom-wrapper path, so narrowing support to `%Mailglass.Message{}` only is not acceptable in this phase unless the roadmap changes.
- **D-02:** Treat custom-wrapper support as an intentionally narrow adapter contract, not open-ended duck typing. Supported wrappers must satisfy the existing documented shape: struct module ends in `.Message`, exports `update_swoosh/2`, and carries the wrapped `%Swoosh.Email{}` in `:swoosh` or `:email`.
- **D-03:** Re-wrap through the input struct's own module, not through hardcoded `Mailglass.Message`. This is the least-surprise fix that matches the current Phase 10 boundary and avoids `FunctionClauseError` on valid custom wrappers.
- **D-04:** Do not use bare field overwrite or "best effort" fallback as the primary contract for admitted custom wrappers. Unsupported wrapper shapes should fail with a typed error, not be silently mutated or downgraded to a raw `%Swoosh.Email{}`.
- **D-05:** Keep the custom-wrapper contract explicit in docs and tests. If Rendro later wants truly open polymorphism here, that should be a separate design with a real behaviour/protocol rather than more heuristics.

### Accrue invoice validation
- **D-06:** `Rendro.Adapters.Accrue.recipe/1` should validate nested `line_items` explicitly and fail the whole recipe on the first invalid entry.
- **D-07:** Invalid nested invoice data must return a typed `{:error, {:invalid_invoice, _}}` tuple, not raise and not partially render. This keeps invoice output deterministic and auditable.
- **D-08:** Do not silently skip invalid line items inside `recipe/1`. Silent omission is the worst DX outcome here because it can produce incorrect billing PDFs that look successful.
- **D-09:** Do not broaden `recipe/1` into a permissive coercion/parser layer in this phase. If tolerant ingestion is ever desirable, it should be a separate normalization API with its own docs and tests.

### Accrue issued_at contract
- **D-10:** Render `issued_at` as a date-only ISO 8601 string (`YYYY-MM-DD`) in the invoice header.
- **D-11:** Accepted temporal inputs for `issued_at` should be `Date`, `NaiveDateTime`, and `DateTime`; datetime inputs should normalize to their calendar date before rendering.
- **D-12:** Do not use locale-aware formatting as the default in this adapter. Locale-sensitive presentation should remain an explicit caller concern, not an implicit library default.
- **D-13:** Remove all developer-facing debug formatting from invoice output. `inspect/1` is not acceptable in user-visible PDF text.

### Traceability and docs truthfulness
- **D-14:** Requirements traceability must follow verified state, not stale status tables. Phase 10 should make `REQUIREMENTS.md` match the verified Phase 5 outcome once the recipe defects are fixed.
- **D-15:** Documentation should state exact accepted shapes and exact failure modes for these adapters. Rendro should prefer a smaller truthful contract over a broader magical contract.

### the agent's Discretion
- Exact error payload shape for nested line-item failures, as long as it stays under `{:error, {:invalid_invoice, _}}` and points callers to the offending nested data.
- Whether the invoice omits the `Issued:` line entirely when `issued_at` is `nil`, or renders a blank/placeholder line, as long as the behavior is consistent and documented.
- Whether to add a compatibility fallback for non-temporal `issued_at` values. Preferred direction is strict typed handling, but a documented `to_string/1` compatibility path is acceptable if planning determines that tightening the contract would be too breaking for this phase.

</decisions>

<specifics>
## Specific Ideas

- Primary synthesis principle for this phase: validate at the adapter boundary, return typed tuples, and never silently fabricate or drop user-facing billing data.
- For Mailglass, the cleanest ideal recommendation from ecosystem norms would be "support only `%Mailglass.Message{}` and `%Swoosh.Email{}`", but that conflicts with Phase 10's locked scope. Within this phase, the coherent move is to keep the custom-wrapper path and make it honest and explicit.
- For Accrue, invoice correctness matters more than permissive ingestion. A strict whole-invoice failure is preferred over a "best effort" PDF missing rows.
- For invoice dates, "Issued:" reads as a calendar date, not a timestamp. Date-only ISO 8601 is the preferred least-surprise presentation.
- Future GSD bias for similar phases should lean toward: truthful smaller contracts, explicit boundary validation, deterministic standard formatting, and only escalate to the user when the decision changes product semantics rather than implementation discipline.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary and traceability
- `.planning/ROADMAP.md` — Phase 10 goal, locked success criteria, and requirement mapping for ADPT-05 / QUAL-04.
- `.planning/REQUIREMENTS.md` — ADPT-05 and QUAL-04 traceability rows that Phase 10 must resync truthfully.

### Prior phase evidence
- `.planning/phases/05-early-ecosystem-recipes/05-REVIEW.md` — CR-01, WR-06, and IN-04 findings that Phase 10 explicitly closes.
- `.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md` — existing Phase 5 verification state, human-needed Mailglass note, and traceability mismatch evidence.
- `.planning/phases/05-early-ecosystem-recipes/05-HUMAN-UAT.md` — the unresolved Mailglass custom-wrapper path that Phase 10 must resolve in code/tests instead of leaving as advisory human verification.
- `.planning/phases/05-CONTEXT.md` — original Phase 5 integration intent and optional-adapter boundary decisions.

### Public contract docs
- `guides/integrations.md` — current documented Mailglass and Accrue contracts; must be kept truthful with any code change in this phase.
- `README.md` — public ecosystem-recipe claims that must remain aligned with implementation and traceability status.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/rendro/adapters/mailglass.ex`: Existing optional Mailglass adapter with typed-error pattern already in place for invalid targets and render failures.
- `lib/rendro/adapters/accrue.ex`: Existing optional Accrue recipe surface; Phase 10 can tighten validation and formatting without changing the broader pipeline architecture.
- `test/support/mocks.ex`: Optional-dependency harness for Mailglass, Swoosh, and Accrue; likely needs adjustment if the real Mailglass contract is aligned more closely.

### Established Patterns
- Optional integrations are compile-guarded with `Code.ensure_loaded?/1`; Phase 10 should preserve that boundary.
- Rendro prefers tuple-returning error surfaces instead of raising for recoverable adapter misuse.
- Documentation claims are treated as contracts and must be corrected when the implementation or verification state changes.

### Integration Points
- `test/rendro/adapters/mailglass_test.exs`: Primary place to add the previously missing custom-wrapper success case and tighten negative-path expectations.
- `test/rendro/adapters/accrue_test.exs`: Primary place to add nested line-item failure tests and issued_at presentation tests.
- `guides/integrations.md` and `.planning/REQUIREMENTS.md`: Required follow-through points so code, docs, and traceability land together.

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within the Phase 10 boundary.

</deferred>

---

*Phase: 10-recipe-correctness-and-traceability*
*Context gathered: 2026-04-28*
