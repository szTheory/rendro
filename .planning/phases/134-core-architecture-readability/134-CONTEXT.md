# Phase 134: Core Architecture & Readability - Context

**Gathered:** 2026-08-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Close only evidence-backed internal architecture, dead-code, dependency, duplication, readability, specification, documentation, and comment findings while preserving Rendro's public API and every rendered byte outside the six Phase 136 catalog targets. Phase 134 may validate and disposition explicit historical candidates, but it does not gain blanket cleanup authority from a file size, dependency count, xref shape, style preference, or roadmap category. It does not consolidate tests or CI, change catalog visuals, add capabilities, or create an alternate render pipeline.

</domain>

<decisions>
## Implementation Decisions

### Finding Authority and Intake
- **D-01:** The canonical `.planning/QUALITY.md` currently contains no accepted Phase 134 finding; `QL-001` explicitly rejects compile-connected xref topology as a repair mandate. Planning must therefore begin with a bounded evidence-validation and ledger-disposition slice before any repair slice.
- **D-02:** Candidate intake is limited to explicit historical review findings and source-verifiable current facts. A candidate becomes repair work only after the ledger records concrete impact, confidence, compatibility risk, owner, scope, focused verification, trigger, and closure evidence.
- **D-03:** If validation does not demonstrate responsibility collision, change fan-out, duplication drift, misleading ownership, unsupported behavior, or testability cost, record `reject_signal` or a trigger-backed deferral. Do not manufacture work to make the phase non-empty.
- **D-04:** If no candidate survives the evidence gate, the truthful phase result is an evidence-backed no-op/closure. Diagnostic movement, lower line counts, or unrelated green tests are never substitute closure evidence.

### Candidate Priority
- **D-05:** Validate `Rendro.I18n.Analyzer` first. Current source search finds no `lib/` caller and only its isolated test module, while the Phase 83 summary explicitly recorded it as dead after the authoritative shaper gate replaced the preflight. If that remains true under xref/compile/test evidence, remove the module and tests as one bounded dead-code repair.
- **D-06:** Next, validate still-current historical duplication findings only when they represent one cohesive responsibility and a demonstrated drift surface. The leading candidates are recipe palette resolution duplicated across recipes and shaping-adapter hint construction duplicated between the simple shaper and error guidance. Research must confirm current semantics and characterize exact outputs before accepting either repair.
- **D-07:** Treat the large `Rendro.PDF.Writer`, `Rendro.Pipeline.Paginate`, recipe modules, and xref counts as investigation signals only. Do not split them unless a specific responsibility collision or maintenance cost is proven and the extraction can preserve the one-engine pipeline and exact output.
- **D-08:** Review runtime-source phase-number narration as a bounded truthfulness candidate. Rewrite only stale implementation-history shorthand; preserve phase/date references when they are current evidence provenance or immutable-history context.

### Change and Extraction Discipline
- **D-09:** Characterization precedes change. Each accepted repair gets focused tests that fail under the recorded defect, followed by the smallest cohesive change and focused re-verification.
- **D-10:** One repair concern per change set. Do not mix dead-code removal, helper extraction, docs/spec cleanup, broad renaming, formatting sweeps, dependency upgrades, test consolidation, CI topology changes, or catalog output changes.
- **D-11:** Shared helpers are justified by ownership, semantics, and drift prevention—not deduplicated line count alone. Preserve existing call boundaries and option precedence; do not introduce a second rendering or layout path.
- **D-12:** Freeze and compare `priv/public_api.json` and affected deterministic byte goldens around every product-code repair. All unrelated rendered outputs remain byte-identical; Phase 134 has no visual-output exception.

### Specifications, Documentation, and Comments
- **D-13:** Keep accurate public/stable and boundary specs. Keep a private spec only when it documents a non-obvious contract or materially improves Dialyzer; correct or remove misleading private specs with focused behavior coverage plus a clean Dialyzer result.
- **D-14:** Public module/function documentation must describe current behavior, failure shape, stability boundary, and truthful limitations. Documentation cleanup must not silently promote an internal module, alter the public manifest, or claim unsupported capability.
- **D-15:** Names and small functions explain mechanics. Comments explain invariants, ordering constraints, compatibility reasons, security/authority boundaries, or provenance. Remove line-by-line narration and rewrite stale phase-local shorthand into present-tense intent.
- **D-16:** Preserve provenance-bearing phase/date references in viewer evidence and historical compatibility seams when the provenance itself is operationally meaningful. The cleanup target is stale narration, not historical amnesia.

### Verification and Closure
- **D-17:** Each accepted ledger finding closes only with its predeclared focused proof, relevant full gate, compatibility evidence, before/after statement, and resolution reference. Update `.planning/QUALITY.md` through the finding lifecycle rather than treating a code commit as self-proving.
- **D-18:** The terminal deterministic evidence includes focused characterization tests, public API manifest byte identity, relevant recipe/render byte-identity tests, documentation warnings-as-errors, Credo, Dialyzer, and `mix ci.fast`. Advisory or human feedback may enrich evidence but cannot block or substitute for deterministic closure.
- **D-19:** Planning must explicitly map each proposed task to ARCH-01 through ARCH-04 and to a ledger finding/disposition. Unaccepted observations may be investigated, rejected, or deferred, but not repaired opportunistically.

### the agent's Discretion
- Choose exact internal helper names and plan boundaries after current-code research, provided every code-changing task names its accepted ledger finding, cohesive responsibility, characterization proof, and compatibility proof.
- Decide whether a validated duplication candidate merits extraction or documented rejection. Prefer no change when the maintenance benefit is not demonstrable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Governance
- `.planning/ROADMAP.md` — Phase 134 goal, success criteria, sequencing, and strict separation from Phases 135-137.
- `.planning/REQUIREMENTS.md` — ARCH-01 through ARCH-04 and the milestone's no-feature/no-byte-churn boundary.
- `.planning/PROJECT.md` — Current milestone posture, pure-core architecture, one-engine pipeline, documentation honesty, and frozen public contracts.
- `.planning/STATE.md` — Accumulated v2.14 decisions, explicit concern that extractions remain undecided, and deferred capability gates.
- `.planning/QUALITY.md` — Canonical finding authority, compatibility contract, `QL-001` rejection, lifecycle rules, and closure evidence requirements.
- `.planning/quality/baselines/132-initial.json` — Source-bound architecture/dependency baseline signals; diagnostic evidence rather than repair authority.
- `.planning/phases/132-quality-baseline-triage/132-CONTEXT.md` — Locked risk vocabulary, evidence lanes, owner routing, and prohibition on signal-driven churn.
- `.planning/phases/133-repository-evidence-hygiene/133-CONTEXT.md` — Current repository/evidence boundaries and the completed predecessor's compatibility constraints.

### Current v2.14 Research
- `.planning/research/SUMMARY.md` — Phase 134 ordering rationale and the warning not to preselect splits from file size.
- `.planning/research/ARCHITECTURE.md` — Evidence-before-extraction sequence, one-engine architecture, and docs/spec/comment policy.
- `.planning/research/FEATURES.md` — Readable-architecture outcome and proof-of-non-churn expectations.
- `.planning/research/PITFALLS.md` — Metric gaming, speculative refactors, weaker proof, and misleading-spec failure modes.
- `.planning/research/STACK.md` — Existing Elixir quality tools and prohibition on speculative dependencies/tooling.

### Historical Candidate Evidence
- `.planning/milestones/v2.6-phases/83-claim-accuracy-shaping-hygiene/83-03-SUMMARY.md` — Records `Rendro.I18n.Analyzer` as uncalled dead code after removal of the redundant preflight.
- `.planning/milestones/v2.6-phases/83-claim-accuracy-shaping-hygiene/83-REVIEW.md` — Records and distinguishes resolved script-tag issues from the remaining shaping-hint duplication candidate.
- `.planning/milestones/v2.11-phases/120-s1-seam-retrofit-full-theme-swap-across-all-7-recipes/120-REVIEW.md` — Records the cross-recipe palette-resolution duplication and frozen-golden constraint.
- `.planning/milestones/v2.11-phases/123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani/123-REVIEW.md` — Records geometry-budget and duplication observations whose behavior-changing portions are outside Phase 134's byte-frozen scope.

No external specifications or ADRs were referenced; the authoritative inputs are the repository-local contracts above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `priv/public_api.json` with `test/rendro/public_api/manifest_test.exs` and `test/docs_contract/public_api_contract_test.exs`: existing fail-loud public-surface byte-identity contract.
- Recipe byte-identity and theme golden tests under `test/rendro/recipes/`: existing characterization for no-theme and themed render paths.
- `mix ci.fast`: existing deterministic aggregate for format, repository/package hygiene, compile warnings, tests, docs, Credo, and Dialyzer.
- `.planning/QUALITY.md` plus `mix quality.governance`: established finding identity, disposition, and validation surface.
- `Rendro.Recipes.Pagination`: existing example of a small shared recipe helper; reuse or extend only if the responsibility genuinely matches.

### Established Patterns
- `build -> compose -> measure -> paginate -> render -> validate` remains the single data-first engine for fixed and flow APIs.
- Core stays pure and optional adapters remain compile/runtime guarded; Phase 134 adds no dependency or adapter coupling.
- Public API and deterministic byte goldens are contract tests, while xref, line counts, and coverage are diagnostics.
- `Rendro.I18n.Analyzer` currently has references only from `test/rendro/i18n/analyzer_test.exs`; the active shaping path lives under `Rendro.Text.Shaper` and pipeline measurement.
- Palette and typography seams currently live per recipe with frozen option precedence; any shared helper must preserve those exact semantics.

### Integration Points
- Candidate triage and closure update `.planning/QUALITY.md`; product code and ordinary regression tests must not consume the ledger.
- Dead-code validation touches `lib/rendro/i18n/analyzer.ex`, its isolated test, xref/compile evidence, and the active shaper characterization surface.
- Palette or shaping-hint extraction, if accepted, connects to the existing recipe/shaper call sites and their focused byte/error tests without changing public signatures.
- Docs/spec/comment cleanup connects to ExDoc warnings, public manifest contracts, Dialyzer, and source-focused assertions rather than new runtime behavior.

</code_context>

<specifics>
## Specific Ideas

- Runtime source should read as current engineering intent, not require maintainers to reconstruct old phase history.
- Historical provenance remains visible where it is the reason a viewer-evidence, release, or compatibility boundary exists.
- A clean, evidence-backed decision not to split a large module is a successful Phase 134 outcome.

</specifics>

<deferred>
## Deferred Ideas

- Behavior-changing fixes to custom-typography geometry budgets from the Phase 123 review require a new ledger finding and separately authorized rendered-byte scope; Phase 134 may not change those outputs.
- Test-fixture/test-suite consolidation, including the Phase 122 Payslip fixture duplication, belongs to Phase 135.
- Catalog visual changes and renderer-backed human review remain Phase 136 work and are not bundled with architecture cleanup.

</deferred>

---

*Phase: 134-core-architecture-readability*
*Context gathered: 2026-08-26*
