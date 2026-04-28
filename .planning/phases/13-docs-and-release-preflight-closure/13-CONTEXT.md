# Phase 13: docs-and-release-preflight-closure - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the remaining docs-contract and release-safety gaps so public claims and release automation are enforced by executable checks. This phase hardens the docs verification surface and the release preflight contract; it does not add new release features or broaden Rendro's public scope.

</domain>

<decisions>
## Implementation Decisions

### Docs contract boundary
- **D-01:** Use a curated docs-contract surface, not blanket markdown execution.
- **D-02:** `README.md` is part of the executable docs contract.
- **D-03:** Only selected happy-path blocks in `guides/integrations.md` are part of the executable docs contract.
- **D-04:** Guide-level semantic claims are enforced by direct ExUnit contract tests instead of treating every guide snippet as runnable code.

### Docs snippet policy
- **D-05:** Adopt an explicit multi-lane docs policy with no heuristic skips.
- **D-06:** `iex>` examples are doctested or evaluated where output or error shape matters.
- **D-07:** `elixir` fenced blocks must be valid Elixir and compile cleanly.
- **D-08:** Schematic snippets must not remain in verified `elixir` fences; move them to `text`, `elixir-schematic`, or an explicit skip marker with a required reason.
- **D-09:** Remove the current silent-pass behavior for `...` and `%{...}` snippets from `scripts/verify_docs.exs`.

### Release preflight enforcement
- **D-10:** `mix release.preflight` uses a two-phase hybrid flow.
- **D-11:** Phase 1 checks cheap boundary blockers together and exits non-zero before expensive work when any blocker exists.
- **D-12:** Boundary blockers include dirty worktree, tag/version mismatch, missing strict prerequisites, and wrong environment assumptions.
- **D-13:** Phase 2 runs only after Phase 1 passes and aggregates the expensive runnable checks into one final summary before a single final exit.
- **D-14:** The Phase 2 check set should include `mix ci`, docs-contract verification, package build or unpack verification, and `mix hex.publish --dry-run --yes`.

### Release parity contract
- **D-15:** `mix release.preflight` is a strict release gate, not a loose branch-time sanity helper.
- **D-16:** The task must fail on dirty worktrees.
- **D-17:** The task must require exact parity between `Mix.Project.config()[:version]` and the checked-out `vX.Y.Z` tag.
- **D-18:** The task must reach full publish dry-run parity from that immutable release ref.
- **D-19:** If a weaker branch-time rehearsal is desirable later, it must be a separately named command rather than a watered-down default `release.preflight`.

### Agent posture for this phase
- **D-20:** Downstream agents should default to research-backed recommendations and make routine implementation-discipline choices without escalating them.
- **D-21:** Escalate only if a decision changes product semantics, revises a documented public contract outside this phase's scope, or presents a genuinely high-impact user-visible tradeoff.

### the agent's Discretion
- Exact naming for docs-verification markers or lane labels, as long as verified versus narrative snippets remain explicit.
- Whether the docs contract is implemented through `ExUnit.DocTest`, `doctest_file/1`, a custom markdown verifier, or a mixed harness, as long as D-01 through D-09 remain true.
- Exact summary formatting and result structs for `mix release.preflight`, as long as Phase 1 is boundary-first and Phase 2 aggregates runnable checks before a single final exit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirement truth
- `.planning/ROADMAP.md` — Phase 13 goal, success criteria, and requirement mapping for `QUAL-02` and `QUAL-04`.
- `.planning/REQUIREMENTS.md` — central requirement rows for docs-contract truthfulness and release preflight parity.
- `.planning/PROJECT.md` — product thesis, quality posture, and truthful-scope constraints.
- `.planning/METHODOLOGY.md` — decision lenses: truthful small contracts, boundary validation first, deterministic standard formatting, least surprise DX.
- `.planning/v1.0-MILESTONE-AUDIT.md` — current gap statements for docs-contract verification and release preflight.

### Existing verification and planning evidence
- `.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md` — current `QUAL-02` partial and `QUAL-04` blocked evidence ceiling.
- `.planning/phases/09-ci-and-release-hardening/09-02-SUMMARY.md` — prior release-preflight hardening intent that must be reconciled with live behavior.
- `.planning/phases/11-reconstruct-phase-1-4-artifacts/11-CONTEXT.md` — recommendation-first verification posture carried into this phase.

### Live implementation surfaces
- `scripts/verify_docs.exs` — current docs-contract checker with heuristic partial-snippet skipping.
- `README.md` — public quickstart and API examples that must stay truthful and executable where marked.
- `guides/integrations.md` — public adapter and recipe guide that contains selected contract-worthy happy paths plus semantic claims requiring dedicated tests.
- `lib/mix/tasks/release/preflight.ex` — current release gate implementation to harden.
- `lib/mix/tasks/verify.ex` — adjacent summary-and-single-final-exit style to stay consistent with where appropriate.
- `mix.exs` — `mix ci`, `preferred_envs`, docs extras, and release/package metadata surface.
- `CHANGELOG.md` — release artifact that must remain consistent with strict release parity posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/verify.ex`: already implements summary-first reporting with one final non-zero exit; release preflight can reuse the same operator-facing style for Phase 2.
- `mix.exs`: already defines `preferred_envs` for `ci` and `verify`, and includes both `README.md` and `guides/integrations.md` in ExDoc extras.
- Existing adapter tests in `test/rendro/adapters/*.exs`: good place to enforce guide-level semantic claims directly instead of overloading markdown compilation.

### Established Patterns
- Rendro treats docs claims as contracts and prefers smaller truthful surfaces over broader magical behavior.
- Recent phases favor explicit typed boundaries and recommendation-first decision making.
- Verification commands should produce evidence-backed output and avoid crashing or implying success when important checks were skipped.

### Integration Points
- The docs contract likely connects to `mix verify` through the existing "Docs Contract" step.
- The release gate connects to Mix task behavior, git state, Hex package validation, and package metadata in `mix.exs`.
- Planning should expect edits across docs, tests, and Mix tasks together so code, docs, and release semantics land in one coherent slice.

</code_context>

<specifics>
## Specific Ideas

- Preserve the user-facing rule: if Rendro labels a block as Elixir, it is real Elixir; if a snippet is schematic, Rendro should say so explicitly.
- Keep `mix release.preflight` semantically strict. Do not let a task with that name pass in states that are not actually publishable.
- Shift recommendation-first behavior left within GSD for this project: default to researched coherent recommendations and avoid escalating routine implementation choices unless they materially affect semantics or policy.

</specifics>

<deferred>
## Deferred Ideas

- A separately named branch-time release rehearsal command may be added later if maintainers want faster non-release feedback, but it is intentionally out of scope for Phase 13's strict `release.preflight` contract.
- Broader blanket execution of every markdown guide block remains out of scope unless a future phase explicitly chooses to turn docs into a full tutorial suite.

</deferred>

---

*Phase: 13-docs-and-release-preflight-closure*
*Context gathered: 2026-04-28*
