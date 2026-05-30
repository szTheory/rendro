# Phase 77: v2.4 Closure — Format Gate, Nyquist Drafts, Recipe Input-Validation Polish - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning
**Source:** Milestone audit (`.planning/v2.4-MILESTONE-AUDIT.md`, audited 2026-05-29). This is a closure/cleanup phase — its scope is the audit's `tech_debt` list, not new requirements.

<domain>
## Phase Boundary

v2.4 (Batteries-Included Workflow & Adoption Closure) passed all 19 requirements, 4/4 phase verifications, integration, and 5/5 E2E flows with 920 green tests. The milestone is functionally done. This phase closes the **hygiene/tech-debt** items the audit flagged so v2.4 is shippable with a green required CI lane and clean traceability — no behavior changes to shipped recipes beyond hardening malformed-input error messages.

**In scope (4 success criteria):**
1. Green the `mix ci` format gate (required `test` branch-protection lane is currently RED).
2. Resolve the audit-flagged uncommitted/untracked working-tree changes with intent.
3. Fill the Phase 73/74/75 Nyquist VALIDATION drafts to `nyquist_compliant: true`.
4. Structured `ArgumentError` (not `BadMapError`/`FunctionClauseError`) on malformed recipe input, plus cosmetic dead-binding / misleading-comment cleanup.

**Out of scope:** any new recipe, new public surface, or new requirement. No changes to engine-critical proof lanes. The 920-test suite must stay green; the only test additions are negative-path ArgumentError assertions.
</domain>

<decisions>
## Implementation Decisions

### D-01 — Format gate (Criterion 1)
- Run `mix format` so `mix format --check-formatted` exits 0 on a clean tree. The two committed offenders are `test/docs_contract/recipes_claims_test.exs` and `test/guardrails/required_checks_contract_test.exs` (long `assert`/`Enum.find` lines that must wrap).
- The terminal proof for this criterion is `mix ci` reaching/passing its `format --check-formatted` step (the first step) from a clean working tree — not merely formatting the two files in isolation. Any code edited in D-08/D-09 must also be left formatted.

### D-02 — Working-tree change resolution (Criterion 2)
- The already-applied edits to `lib/rendro/pipeline/paginate.ex`, `test/rendro/deterministic_test.exs`, and `test/rendro/recipes/statement_test.exs` are pure `mix format` normalizations (line-wrapping, blank-line insertion, `& &1.x` → `&(&1.x)`). They are correct and intentional — **commit them with intent**, do not revert.
- `guides/recipes.md` carries a CONTRACT-02 doc-language tightening (removes the explicit `unsupported`-array enumeration in favor of "claims that exceed the support matrix are not made here"). This is intentional — commit it. It must still pass the docs-contract tests in `test/docs_contract/`.
- The untracked `guides/user_flows_and_jtbd.md` (173-line JTBD guide for Phoenix engineers) is a real, useful artifact — **commit it with intent.**

### D-03 — Wire the JTBD guide into HexDocs (Criterion 2 follow-through)
- `guides/user_flows_and_jtbd.md` is currently NOT referenced in `mix.exs` ExDoc `extras`. Wire it into the `extras`/`groups_for_extras` block consistent with the existing guides (`guides/recipes.md`, `guides/page_primitive.md`, `guides/viewer_evidence.md`) so it ships in docs rather than rotting untracked. If wiring it would trip a docs-contract test (claims beyond the support matrix), tighten the guide's language to stay within the matrix instead of dropping the wiring.

### D-04 — Nyquist VALIDATION drafts for 73/74/75 (Criterion 3)
- Phases 73, 74, 75 have VALIDATION.md drafts with `status: draft` / `nyquist_compliant: false|absent`. Phase 76 is already compliant. This is a Nyquist-validation **documentation** gap, not a test-coverage gap (all three carry full green ExUnit suites + PASSED verifications).
- **Fill them by running `/gsd-validate-phase 73`, `/gsd-validate-phase 74`, `/gsd-validate-phase 75`** — do NOT hand-edit the VALIDATION.md frontmatter to flip the flag. `/gsd-validate-phase` is a top-level GSD workflow that spawns `gsd-nyquist-auditor` and may generate/verify coverage; it must run as a top-level command (nested AskUserQuestion does not work, same constraint as discuss-phase). Plan these as **`autonomous: false`** manual-gate tasks the operator runs, each with acceptance criterion "`<N>-VALIDATION.md` frontmatter shows `nyquist_compliant: true` / `status:` no longer `draft`".

### D-05 — Statement `:account`/`:customer` shape validation (Criterion 4)
- `statement.ex` (around lines 505-523) does not validate the `:account`/`:customer` shape — a non-map raises `BadMapError`. Add a `validate_*!/1` clause that raises structured `ArgumentError` following the **existing in-file pattern** (`validate_period!/1`, `validate_lines!/1`: a guard-failing clause that raises with the `What:`/`Where:`/`Why:`/`Next:` body). Reuse `Rendro.Recipes.Pagination.type_name/1` for the received-type message as the existing clauses do.

### D-06 — Receipt input validation (Criterion 4, 75-REVIEW WR-01..06)
- `Rendro.Recipes.Receipt`: malformed `:customer` (non-map) and non-`%Date{}` `:date` raise raw `BadMapError`/`FunctionClauseError`. Add structured `ArgumentError` clauses matching the Statement pattern. Address the asymmetric `:totals.total` validation and the fragile brand-validation clause ordering noted in WR-01..06.

### D-07 — Certificate input validation (Criterion 4, 75-REVIEW WR-01..06)
- `Rendro.Recipes.Certificate`: non-binary `:body` and non-`%Date{}` `:date` raise raw errors. Add structured `ArgumentError` clauses matching the Statement pattern.

### D-08 — Negative-path tests for D-05..D-07
- For each new validation clause, add an ExUnit test asserting `assert_raise ArgumentError, ~r/.../, fn -> Recipe.document(bad_data) end`. Follow the existing negative-path test style in `test/rendro/recipes/statement_test.exs` (e.g. the "Float line amount raises ArgumentError" test). These additions must keep the full suite green and the tree formatted.

### D-09 — Cosmetic cleanup (Criterion 4, info-tier audit items)
- `statement.ex:293-297` — capacity comment is factually wrong (claims double-subtract of header/footer; behavior is a conservative ~8% under-pack with no overflow risk). Correct the comment; do not change the numeric behavior unless a plan proves it safe.
- `statement.ex:376-383/380` — misleading mean-vs-median comment; magic number `14.4` should become a named module attribute.
- `statement.ex:705-711` — `Enum.map_reduce` whose mapped result is discarded → replace with `Enum.reduce`.
- `certificate.ex:180` — `_content_w` computed and discarded (dead binding) → remove.
- These are cosmetic/clarity only and must not alter rendered output (determinism + existing tests stay green).

### D-10 — Terminal gate
- The phase is done only when, from a clean committed tree: `mix format --check-formatted` exits 0, the full `mix test` suite is green (920+ tests, new negative-path tests included), and `mix ci` passes its format step. 73/74/75 VALIDATION.md are `nyquist_compliant: true`.

### Claude's Discretion
- Plan/wave breakdown and how many PLAN.md files to emit.
- Exact module-attribute name for the `14.4` constant and exact `ArgumentError` message wording (must follow the existing `What:`/`Where:`/`Why:`/`Next:` template).
- Whether the cosmetic fixes (D-09) ride along in the same plan as the validation work (D-05..D-08) or a separate plan.
- The `groups_for_extras` group the JTBD guide lands in.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit source (authoritative scope)
- `.planning/v2.4-MILESTONE-AUDIT.md` — the tech-debt list this phase closes; per-item file:line pointers and severities.

### Phase 75 review (input-validation gaps)
- `.planning/phases/75-*/75-REVIEW.md` — WR-01..06 receipt/certificate input-validation findings.

### Code to modify
- `lib/rendro/recipes/statement.ex` — existing `validate_data!/1` / `validate_period!/1` / `validate_lines!/1` pattern to extend (D-05, D-09).
- `lib/rendro/recipes/receipt.ex` — receipt validation surface (D-06).
- `lib/rendro/recipes/certificate.ex` — certificate validation surface + dead binding (D-07, D-09).
- `lib/rendro/recipes/pagination.ex` — `type_name/1` helper reused in error messages.

### Tests / contracts
- `test/rendro/recipes/statement_test.exs` — negative-path ArgumentError test style to follow (D-08); already format-normalized in working tree.
- `test/docs_contract/recipes_claims_test.exs` — format offender (D-01); also binds guide claims to the support matrix (relevant to D-02/D-03 guide language).
- `test/guardrails/required_checks_contract_test.exs` — format offender (D-01).
- `priv/support_matrix.json` — bounds what guides may claim (D-02/D-03).
- `mix.exs` — ExDoc `extras`/`groups_for_extras` to wire the JTBD guide (D-03); `mix ci` / `mix format` aliases (D-01/D-10).

### Existing VALIDATION drafts to fill
- `.planning/phases/73-*/73-VALIDATION.md`, `74-*/74-VALIDATION.md`, `75-*/75-VALIDATION.md` (D-04).
</canonical_refs>

<specifics>
## Specific Ideas

- The structured-error template already in `statement.ex` is the canonical shape for ALL new validation clauses:
  ```
  Rendro.Recipes.<Recipe>.document/2 — invalid :<key> shape.

  What:  <what the value must be>
  Where: Rendro.Recipes.<Recipe>.validate_data!/1
  Why:   Received: #{inspect(value)} (#{Rendro.Recipes.Pagination.type_name(value)}).
  Next:  <how to fix>
  ```
- `mix format` should be the LAST mechanical step before the final commit so D-08 test additions and D-05..D-09 code edits don't reintroduce format-gate failures.
- Nyquist (`/gsd-validate-phase`) and the format gate are independent; the Nyquist tasks touch only `.planning/` VALIDATION.md files and can run in parallel with the code work.
</specifics>

<deferred>
## Deferred Ideas

- **Traceability frontmatter backfill** (audit item #4, info-tier): the 9 SUMMARY.md files missing `requirements-completed:` entries. VERIFICATION.md is the authoritative per-requirement source and already confirms all 19 — this is metadata drift only. **Deferred** from Phase 77 (not in any success criterion). Record only; do not plan unless explicitly pulled in.
</deferred>

---

*Phase: 77-v2-4-closure-format-gate-nyquist-drafts-recipe-input-validat*
*Context synthesized 2026-05-29 from milestone audit (closure phase — no discuss-phase; no new REQ-IDs).*
