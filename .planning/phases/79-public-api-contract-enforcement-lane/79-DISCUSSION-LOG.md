# Phase 79: Public API Contract Enforcement Lane - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 79-public-api-contract-enforcement-lane
**Areas discussed:** CI lane wiring, Tier-1 @spec coverage strictness
**Mode:** advisor (calibration tier `minimal_decisive`, technical owner)

---

## CI lane wiring

| Option | Description | Selected |
|--------|-------------|----------|
| Fold into `test` | Test runs under `mix test`/`mix ci`; already gated by existing `test` required context. Wiring = update `test` context notes/lane-count. Matches Phase 68 D-18 precedent + all 13 existing docs-contract lanes. | ✓ |
| New required context | Separate `public-api-contract` CI job + new `required_contexts[]` entry / GitHub status check. More visible but diverges from established topology. | |

**User's choice:** Fold into `test` (recommended)
**Notes:** Consistent with the project's established "fold structural/deterministic checks into the `test` lane, don't add new required GitHub contexts" precedent. Guardrail contract test (if it asserts the lane count) updated in lockstep.

---

## Tier-1 @spec coverage strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Ratchet (no-regression) | Assert current specced stable fns keep their @spec; documented stable-spec count never decreases. No large backfill in this phase. | |
| Strict 100% now | Assert EVERY documented stable-tier public function has an @spec; fail with the unspecced list. Expands phase scope to backfill @spec across the document model. | ✓ |
| Module-level only | Assert only that every stable module has ≥1 @spec. Weakest; lets unspecced public fns slip through. | |

**User's choice:** Strict 100% now
**Notes:** Deliberate "strongest contract at 1.0" call. Scout surfaced that several Tier-1 stable modules (table.ex, section.ex, region.ex, block.ex, image.ex, cell.ex, row.ex; text.ex partial) currently carry zero/partial @spec — so Phase 79 explicitly includes a stable-surface @spec backfill until the lane goes green. dialyzer in `mix ci` checks the added specs for free. Function list authority = the manifest's per-module `functions` entries for `tier: "stable"` modules.

---

## Claude's Discretion

- Exact test module name/structure (mirror `test/docs_contract/*_contract_test.exs`, `async: false`); drift-diff failure message wording; whether @spec-coverage lives in the same file or a sibling test.
- Sequencing of spec-backfill vs. test authoring (suggested: RED test first, backfill to GREEN).
- Items pre-locked to Phase 78 precedent (not re-discussed): shared `Rendro.PublicApi` codepath reuse (D-01), conditional-adapter handling via the generator's filter (D-02), two-list drift diff (D-03), hidden-internals + one-tier-tag assertions (D-05/D-06).

## Deferred Ideas

- Scrub internal milestone/phase labels from `guides/api_stability.md` — owned by Phase 80 / STAB-04, not this phase.
