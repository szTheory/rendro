# Phase 124: Address v2.11 tech debt (stale 113 docs-contract test, formatter drift, ticket dialyzer contract) - Context

**Gathered:** 2026-07-28
**Status:** Ready for planning
**Source:** Synthesized from `.planning/v2.11-MILESTONE-AUDIT.md` (authoritative remediation scope) + live ground-truth verification, in lieu of discuss-phase. The audit is the PRD for this phase.

<domain>
## Phase Boundary

The **tech-debt remediation phase** for the v2.11 Document Theming milestone (Milestone B). The
milestone audit closed all 21 requirements as satisfied and WIRED with no blockers, but flagged
accumulated non-blocking debt worth clearing before archiving. Phase 124 was inserted as the dedicated
home for exactly three of those items — named verbatim in the phase title.

This phase is **maintenance, not feature work**: fix the failing/false-red gates so the `ci.fast` chain
runs green end-to-end, **without changing any rendered output**. The v2.11 milestone's central
regression guard is byte-identity — an un-themed call reproduces v2.10 bytes exactly for all 7 recipes.
Every change here must preserve that guarantee.

**In scope (the three titled targets — and only these):**

1. **Stale 113 docs-contract test** — `test/docs_contract/dx_local_reproducibility_claims_test.exs` has
   2 failing tests that `File.read!` deleted archived planning files:
   - `:77` "validation reports keep local and remote evidence boundaries truthful" → reads
     `@metrics_path = ".planning/phases/113-.../113-METRICS.md"` (deleted)
   - `:103` "Phase 113 UAT is completed from automated evidence..." → reads
     `@uat_path = ".planning/phases/113-.../113-UAT.md"` (deleted)
   Root cause: milestone-cleanup (commit `0de2de8`) cleared the v2.10 phase dirs; the test still hard-reads
   those paths. The other 3 tests in the file (verify_docs.exs, ci.yml, README/CONTRIBUTING) still pass.

2. **Formatter drift** — `mix format --check-formatted` fails on ~7 pre-existing files (formatter-version
   drift, e.g. `refute source =~ term` → `refute(source =~ term)`; multi-line map expansion; blank-line
   insertion). Zero logic change. Blocks the `ci.fast` alias chain at step 1 even though each downstream
   lane verifies clean individually. Confirmed affected: `test/docs_contract/theme_industry_guard_test.exs`,
   `test/docs_contract/theming_claims_test.exs`, `test/rendro/recipes/payslip_opts_threading_test.exs`
   (plus others up to the audited count of 7).

3. **Ticket dialyzer contract** — `mix dialyzer` fails on pre-existing `lib/rendro/recipes/ticket.ex`
   contract errors: `no_return` on `document/1,2` (`:224`) and `sections/1,2` (`:256`), plus a
   `Rendro.Recipes.Background.emit?/1` contract mismatch. Ground-truth diagnosis: `background.ex:25-27`
   declares `@spec emit?(%{background: {non_neg_integer, non_neg_integer, non_neg_integer}}) :: ...` — a
   **narrow** spec — while `ticket.ex:171` / `ticket.ex:273` call `Background.emit?(colors)` with the fuller
   colors map. Dialyzer treats the call as one that can never succeed, so `no_return` cascades up through
   `sections` → `document`. Fix is almost certainly a **type-spec correction only** (widen/correct the
   `emit?/1` contract, plus any genuinely-needed `ticket.ex` spec), with **no runtime/rendered change**.

**Out of scope (explicitly deferred — recorded, not dropped):**

- **Ticket visual hierarchy regression** (WINDOWS.md id 2): the themed type-scale inverts the intended
  hierarchy (reference-code display anchor 21pt themed > title role 16.5pt themed). This is an honestly-
  recorded `passed:false` design outcome tied to a **LOCKED Phase-122 non-monotone role assignment**.
  Phase 124 fixes the dialyzer *type contract* only; it does **NOT** re-map roles or alter Ticket layout.
- **`pdfium-cli` v0.11.0 tooling gap** — `mix rendro.launch_artifacts.check` (ci.advisory) fails because the
  binary isn't on PATH in this environment. Environmental/tooling, not a code or manifest defect.
- **Nyquist validation of phases 121/122/123** — coverage TODO handled by `/gsd-validate-phase {121,122,123}`,
  not this phase (119/120 already reconciled COMPLIANT).
- **Missing `from_brand/2` byte-level E2E golden** — integration warning; covered transitively today. A
  follow-up candidate, not a debt item this phase owns.
- **SUMMARY frontmatter `requirements_completed` bookkeeping** — empty across the 19 plan summaries;
  requirement satisfaction was verified via VERIFICATION evidence instead. Minor, deferred.

</domain>

<decisions>
## Implementation Decisions

Locked from the v2.11 audit + live ground-truth (test run, formatter check, spec inspection). These are
transcribed locked decisions (audit-driven), not new gray-area calls — the phase title already fixed the
scope. The dialyzer *approach* is the only item with residual investigation, delegated to research with a
firm guardrail (D-03).

### D-01 — Stale 113 docs-contract test: fix the test, do NOT resurrect deleted planning files
- The two failing cases guard **archived phase-113 planning artifacts** that were deleted by design during
  milestone cleanup. Restoring `113-METRICS.md` / `113-UAT.md` is the wrong fix (it would re-introduce
  files cleanup intentionally removed).
- Make the suite green by removing the dependency on the deleted archived paths. Research/plan determines the
  precise mechanism from what each test actually asserts: (a) delete the two now-obsolete cases if the claim
  they guarded pertains only to archived 113 planning docs; (b) skip/guard-on-absence if the guarded claim is
  still live but the evidence file is legitimately gone; or (c) re-point at the current source of truth if the
  claim must still be enforced.
- **Guardrail:** the 3 currently-passing tests in the file MUST stay green. Do not silently weaken a
  still-relevant docs-contract guarantee — if a case is removed, record why (the claim is 113-archive-specific).

### D-02 — Formatter drift: apply `mix format`; formatting-only, bounded
- Run `mix format` on the affected files so `mix format --check-formatted` exits 0 and unblocks `ci.fast`
  step 1.
- **Guardrail:** the diff must be **formatting-only** (whitespace / parens / layout — verify via `git diff`
  shows no token or logic changes) and **bounded** to the known ~7-file set. If `mix format` would touch a
  large swath beyond the known set, STOP and treat it as a formatter config/version mismatch to investigate,
  not a mass reformat to commit.

### D-03 — Ticket dialyzer contract: spec-only fix, zero rendered-output change
- Make `mix dialyzer` pass by correcting the type contract(s) causing the cascade — primarily the narrow
  `@spec emit?/1` in `lib/rendro/recipes/background.ex` so it matches the `colors` argument all callers pass,
  plus any genuinely-required `ticket.ex` `@spec`, so the `no_return` on `sections/1,2` and `document/1,2`
  clears.
- **Guardrail (hard):** the fix MUST NOT change runtime behavior or rendered bytes. The full golden /
  byte-identity regression suite MUST remain byte-identical after the change (this is the milestone's central
  guard). If the true root cause turns out to be a genuine always-raises code path rather than a spec
  mismatch, surface it as a decision rather than silently altering behavior.
- Research confirms the exact `mix dialyzer` output and root cause against the already-built PLT
  (`_build/dev/dialyxir_erlang-28.4.1_elixir-1.19.5_deps-dev.plt`) before the fix is planned.

### D-04 — Ticket visual hierarchy regression stays OUT (locked Phase-122 decision)
- The type-scale hierarchy inversion (WINDOWS.md id 2) is a locked, documented design outcome. This phase
  does not touch Ticket role mapping, type scale, or layout. Dialyzer-type-only.

### D-05 — Scope fence: only the three titled targets
- IN: stale-113 test, formatter drift, ticket dialyzer contract. OUT (deferred, per <domain>): pdfium-cli
  tooling gap, Nyquist 121/122/123 validation, from_brand byte-level E2E golden, SUMMARY frontmatter
  bookkeeping. Do not expand scope into any of these; note them as deferred so the milestone audit stays honest.

### D-06 — Success bar: green gates + preserved byte-identity
- Acceptance is gate-level and objectively checkable (see Success Criteria). No new feature behavior; the
  only observable delta is that previously-red/false-red gates now pass and the un-themed golden bytes are
  unchanged.
</decisions>

<canonical_refs>
- `.planning/v2.11-MILESTONE-AUDIT.md` — authoritative scope & tech-debt enumeration (the PRD)
- `.planning/WINDOWS.md` — regression/deviation register (Ticket id 2, dialyzer id 6, pdfium id 7)
- `lib/rendro/recipes/ticket.ex` — `document/2` (:224), `sections/2` (:256), `Background.emit?` calls (:171, :273)
- `lib/rendro/recipes/background.ex` — `emit?/1` spec+impl (:25-27)
- `test/docs_contract/dx_local_reproducibility_claims_test.exs` — stale test (:77, :103; @metrics_path/@uat_path/@audit_path)
- `test/docs_contract/theme_industry_guard_test.exs`, `test/docs_contract/theming_claims_test.exs`, `test/rendro/recipes/payslip_opts_threading_test.exs` — confirmed formatter-drift files
- `mix.exs` — `ci.fast` / `ci.advisory` aliases (map exact step order + which lane blocks)
- The golden / byte-identity regression suite — the guard D-03 must preserve
</canonical_refs>

<success_criteria>
- `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` → 0 failures (was 2)
- `mix format --check-formatted` → exit 0 (was: fails on ~7 files)
- `mix dialyzer` → 0 errors on `ticket.ex` / `background.ex` (was: no_return cascade + emit?/1 mismatch)
- Full golden / byte-identity regression suite → unchanged (byte-identical; the milestone guard holds)
- `mix ci.fast` chain no longer blocked at step 1 (runs green end-to-end, or each lane individually clean with the blocker removed)
- No change to Ticket rendered output, role mapping, or type scale (D-04 respected)
- Deferred items (D-05) explicitly recorded as deferred, not silently dropped
</success_criteria>

<deferred>
- Ticket visual hierarchy re-mapping (locked Phase-122 architectural call) → future milestone
- `pdfium-cli` install / PATH provisioning → environment setup, not code
- `/gsd-validate-phase 121`, `122`, `123` → Nyquist coverage completion
- `from_brand/2` byte-level E2E golden → integration hardening follow-up
- SUMMARY frontmatter `requirements_completed` backfill → bookkeeping follow-up
</deferred>
