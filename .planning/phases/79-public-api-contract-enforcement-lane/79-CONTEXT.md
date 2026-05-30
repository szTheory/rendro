# Phase 79: Public API Contract Enforcement Lane - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase **ENFORCES** the public API surface that Phase 78 **defined and cleaned**. It adds an introspection-based docs-contract test (`test/docs_contract/public_api_contract_test.exs`) that mechanically pins the documented surface to the checked-in `priv/public_api.json` manifest and gates merges to `main`, so API drift (a stray public function, a re-exposed internal, a removed `@spec`, a missing/duplicate tier tag) fails CI with an errors-as-product diff.

**In scope:** the contract test; the `@spec`-coverage backfill it requires (see D-04 — chosen Strict 100% pulls spec-writing into this phase); wiring the lane into `priv/guardrails/required_status_checks.json`.

**Out of scope:** changing the surface definition, the manifest shape, the tier assignments, or the generator (all locked in Phase 78). Scrubbing internal labels from `guides/api_stability.md` (that is Phase 80 / STAB-04).
</domain>

<decisions>
## Implementation Decisions

### A. Manifest-equality assertion mechanism
- **D-01:** **Reuse the Phase 78 `Rendro.PublicApi` introspection codepath** — the contract test regenerates the manifest in-memory via the same `Rendro.PublicApi.build_manifest/1` the `mix rendro.api.gen` task uses, then asserts equality against the checked-in `priv/public_api.json`. Same codepath → test and generator can never disagree (Phase 78 D-15). The test also validates the on-disk manifest against `priv/schemas/public_api.schema.json` via the existing JSV validator stack.
- **D-02:** **Conditional-adapter footgun handled by the shared codepath, not re-solved.** The 5 conditionally-compiled adapters (`Adapters.Phoenix`, `Oban.RenderWorker`, `Threadline`, `Mailglass`, `Accrue`) are present in `Code.fetch_docs/1` only when their optional deps are compiled. The test inherits the generator's BEAM-availability filter / `public_modules/0` exactly (Phase 78 78-05). The test must run in the dev/test env where optional deps are loaded — i.e. the normal `mix test` env — so the introspected surface matches the manifest. Do NOT add a parallel filtering implementation in the test.
- **D-03:** **Drift surfacing = two human-readable lists** — "in code but not manifested" and "manifested but not in code" — not one opaque `assert ==` (Phase 78 D-18; cf. Roslyn `RS0016`/`RS0017`). The failure message must tell the developer to run `mix rendro.api.gen` to regenerate the manifest when the change is intentional (the cargo-public-api `UPDATE_EXPECT=1` ergonomic).

### B. Hidden-internals assertion
- **D-05:** The test asserts the known internals report `:hidden` from `Code.fetch_docs/1` and fails if any becomes visible again: modules `Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter` (plus the other Phase 78 D-01 hides — `Text.Bidi`, `Text.Shaper`, `Format`, `Audit`), and the `@doc false` `redact_*` helpers (`Rendro.Sign.redact_opts/1`, `redact_prepare_opts/1`, `redact_sign_opts/1`, `redact_augment_opts/1`, `Rendro.Protect.redact_opts/2`). Assert against an explicit hidden-list so re-exposure is caught even if the manifest also changes.

### C. Tier-tag assertion
- **D-06:** Assert every public (manifested) module carries **exactly one** tier tag (`:stable` xor `:adapter`) in `Code.fetch_docs/1` metadata — zero tags or two tags fails. This is the structural invariant behind the manifest's per-module tier.

### D. Tier-1 `@spec` coverage — **STRICT 100%** (scope-expanding decision)
- **D-04:** **The test asserts that EVERY documented stable-tier public function (every `"name/arity"` entry in a `stable` module's `functions` list in `priv/public_api.json`) has an `@spec`.** Failure emits the list of unspecced stable functions.
  - **Scope consequence (intentional, eyes open):** scout found several Tier-1 stable modules currently carry **zero** `@spec` on their public builder functions — at minimum `table.ex`, `section.ex`, `region.ex`, `block.ex`, `image.ex`, `cell.ex`, `row.ex` (and partial coverage elsewhere, e.g. `text.ex` 2 specs / 3 public fns). **Phase 79 therefore includes backfilling `@spec` across the entire documented stable surface** until the lane goes green. The planner MUST scope this spec-backfill as explicit work, not assume it is incidental.
  - **Rationale:** the user wants the strongest contract — specs are part of the Tier-1 promise a 1.0 consumer builds against. `mix ci` already runs dialyzer, so added specs are dialyzer-checked for free. Rejected the "ratchet / no-regression" and "module-level only" weaker variants in favor of a complete, enforceable Tier-1 spec surface at 1.0.
  - **Definition anchor:** "documented stable public function" = a `functions` entry under a `tier: "stable"` module in the manifest. Use the manifest as the authoritative function list so the spec assertion and the surface-equality assertion share one definition. Functions on `adapter`-tier modules are NOT required to carry `@spec` by this assertion (only stable tier).

### E. CI lane wiring — **fold into the existing `test` required context**
- **D-07:** The public-api contract test runs inside `mix test` (hence inside `mix ci`), so it is **already gated by the existing `test` required GitHub status context**. Wiring into `priv/guardrails/required_status_checks.json` means **updating the `test` context's `notes`** (bump the docs-contract lane count and name the public-api lane) — **NOT** adding a new entry to `required_contexts[]` or a new GitHub CI job.
  - **Rationale:** matches the Phase 68 D-18 precedent (viewer-evidence structural checks folded into `test`, no extra required GitHub context) and all 13 existing `test/docs_contract/*` lanes. Rejected a separate `public-api-contract` required context — it would diverge from the established "fold structural/deterministic checks into `test`" topology and add a redundant GitHub status check. The guardrail contract test (if one asserts the lane count) must be updated in lockstep with the `notes` bump.

### Claude's Discretion
- Exact test module name/structure (mirror `test/docs_contract/*_contract_test.exs`, `async: false`), the precise wording of the drift-diff failure message, and whether the `@spec`-coverage assertion lives in the same test file or a sibling `public_api_spec_coverage_test.exs`.
- Order of spec-backfill work vs. test authoring (a sensible path: write the test RED, then backfill specs until GREEN).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap (authoritative scope)
- `.planning/REQUIREMENTS.md` — API-04 is this phase's sole requirement (verbatim: introspect `Code.fetch_docs/1`, assert documented surface == manifest, assert internals `:hidden`, assert Tier-1 `@spec` coverage, assert one tier tag per module, wire into guardrails).
- `.planning/ROADMAP.md` §"Phase 79" — goal + 4 success criteria (the authoritative acceptance list).

### Phase 78 decisions this phase builds on (binding)
- `.planning/phases/78-public-api-surface-definition-cleanup/78-CONTEXT.md` — especially **D-15** (shared `Rendro.PublicApi` introspection reused by this test), **D-16** (manifest granularity: per-function `"name/arity"` grouped by module — the function list this phase's `@spec` and equality assertions key off), **D-17** (schema-versioning via sibling schema, no inline version), **D-18** (two-list drift diff), and the **conditional-adapter footgun** note in Existing Code Insights.
- `.planning/phases/78-public-api-surface-definition-cleanup/78-05-SUMMARY.md` — the `mix rendro.api.gen` task, `Rendro.PublicApi.public_modules/0`, the BEAM-availability filter, and the `Jason.OrderedObject` deterministic encoding the test's in-memory regeneration must match for byte-equality.
- `.planning/phases/78-public-api-surface-definition-cleanup/78-04-SUMMARY.md` — `Rendro.PublicApi` / `Loader` / `Validator` APIs and the existing `test/rendro/public_api_test.exs` sweep-closure test (this phase's contract test is the CI-gating sibling).

### Code/pattern touch-points
- `lib/rendro/public_api.ex` (+ `loader.ex`, `validator.ex`) — the introspection module to reuse, not reimplement.
- `priv/public_api.json` + `priv/schemas/public_api.schema.json` — the manifest and schema the test asserts against.
- `lib/mix/tasks/rendro/api.gen.ex` — the generator whose in-memory build the test mirrors; its failure message should point developers back here.
- `test/docs_contract/recipes_contract_test.exs` (and siblings) — the existing docs-contract test shape to mirror (`async: false`, `Rendro.Test.DocsContract` helpers where applicable).
- `priv/guardrails/required_status_checks.json` — the `test` context whose `notes` get the lane-count bump (D-07). Check for a guardrails contract test that asserts the lane count and update it in lockstep.
- Tier-1 stable modules needing `@spec` backfill (D-04): `lib/rendro/table.ex`, `section.ex`, `region.ex`, `block.ex`, `image.ex`, `cell.ex`, `row.ex`, `page.ex`, `page_template.ex`, `component.ex`, `text.ex` (partial), plus any other `tier: "stable"` module in the manifest with unspecced public functions — the manifest is the authoritative list.

### Existing surface contract (do not contradict)
- `guides/api_stability.md` — the shipped stability promise the manifest formalizes. (Its internal-label leakage scrub is Phase 80/STAB-04, not here.)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Rendro.PublicApi.build_manifest/1` + `public_modules/0`** (Phase 78): the single introspection codepath both the generator and this test consume — reuse verbatim for in-memory regeneration (D-01/D-02).
- **JSV validation stack** (`Rendro.PublicApi.Validator` / `viewer_evidence/validator.ex` pattern): validate the on-disk manifest against its schema in-test.
- **`test/docs_contract/*_contract_test.exs`**: 13 existing lanes establishing the `async: false`, ExUnit docs-contract pattern this test mirrors.
- **`Jason.OrderedObject` deterministic encoding** (`api.gen.ex`): the in-memory regeneration must encode identically for byte-equality comparison against the checked-in manifest.

### Established Patterns
- **Conditionally-compiled adapters inside `if Code.ensure_loaded?` guards** — the CRITICAL footgun; the test must run where optional deps are loaded and reuse the generator's filter (D-02).
- **Structural/deterministic checks fold into the `test` CI lane** (Phase 68 D-18 precedent) rather than spawning new required GitHub contexts (D-07).
- **`mix ci` runs dialyzer** — added `@spec`s from the D-04 backfill are dialyzer-verified for free.

### Integration Points
- New `test/docs_contract/public_api_contract_test.exs` → consumes `Rendro.PublicApi` + `priv/public_api.json` + `priv/schemas/public_api.schema.json`.
- `priv/guardrails/required_status_checks.json` `test` context `notes` updated; guardrail contract test (if present) updated in lockstep.
</code_context>

<specifics>
## Specific Ideas

- Errors-as-product failure UX: the drift-diff message should read like a Roslyn `RS0016`/`RS0017` report (two named lists) and explicitly instruct `mix rendro.api.gen` for intentional changes — the cargo-public-api `UPDATE_EXPECT=1` ergonomic, adapted to the existing mix task.
- Strict 100% `@spec` was a deliberate "strongest contract at 1.0" call by the user, accepting the in-phase spec-backfill cost.
</specifics>

<deferred>
## Deferred Ideas

- **Scrub internal milestone/phase labels from `guides/api_stability.md`** ("Phase 53", "Phase 71", "Rendro v1.10") — already owned by Phase 80 / STAB-04. Noted, not in scope here.
- None other — discussion stayed within phase scope.
</deferred>

---

*Phase: 79-public-api-contract-enforcement-lane*
*Context gathered: 2026-05-30*
