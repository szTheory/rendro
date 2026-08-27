# Phase 135: Test & CI/CD Simplification - Context

**Gathered:** 2026-08-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Rendro's tests and automation easier to understand and maintain without weakening observable behavior, failure-mode coverage, deterministic output, evidence authority, or the sole `ci-success` merge contract. Phase 135 may consolidate only evidence-backed test overlap, replace the Phase 126/127/130 catalog-generation routes with one purpose-named exact-SHA evidence workflow, prove old/new parity, simplify ordinary CI accordingly, and document the supported operator paths. It does not change product APIs or rendered bytes, repair catalog visuals, add a runtime dependency, make raster evidence deterministic, or turn human visual judgment into an automated pass.

</domain>

<decisions>
## Implementation Decisions

### Test Consolidation Scope and Stop Rule
- **D-01:** Use bounded candidate-only cleanup, not a suite-wide restructuring campaign. A test group is eligible only when evidence shows the tests protect the same observable behavior, failure mode, authority boundary, and deterministic-output contract, and when consolidation reduces a concrete maintenance, flake, planning-coupling, implementation-coupling, or change-fan-out cost.
- **D-02:** Treat an evidence-backed no-op as a successful result once the explicit candidates are resolved. Test count, file size, duplicated setup, coverage percentage, and phase-number prose are investigation signals; none independently authorizes deletion, macros, parameterization, or shared-fixture architecture.
- **D-03:** Bound the initial candidate set to the workflow-contract tests that must change with the generic catalog workflow and the explicit Phase 122 review findings. Retain the seven-recipe themed smoke case as the owner of the masked-middot/accented Payslip end-to-end regression; remove the identical targeted render assertion only after the inventory and teeth gate pass, while preserving the opts test's distinct threading, precedence, no-theme, and live-seam assertions. Rename the Certificate test that currently proves only that themed and unthemed section construction do not raise; do not invent a geometry-equality contract that current behavior does not satisfy.
- **D-04:** Do not introduce Phoenix, Plug, Ecto, SQL sandboxing, database fixtures, or application-case abstractions into the pure Rendro suite. Follow the ecosystem convention behind those tools—share setup only when it represents one stable responsibility—but keep core tests on ExUnit, explicit domain fixtures, existing `test/support` seams, and observable assertions.

### Replacement Tests With Teeth
- **D-05:** Before consolidating any group, record a compact durable inventory row: old tests, replacement owner, preserved behavior, preserved failure mode, authority lane, oracle, negative control, focused command, and result. The inventory is evidence for TEST-01/TEST-02, not a permanent catalog of every test in the repository.
- **D-06:** Every replacement keeps a positive assertion for each preserved contract and executes a minimal deterministic negative control that changes one in-memory fixture field, validated record, injected document state, manifest field, permission, SHA, count, digest, or expected contract value. The replacement must reject the broken state at the intended assertion with a useful error; `refute left == right`, line execution, or a source-text scan alone is not proof of teeth.
- **D-07:** Preserve exact error shapes, deterministic PDF bytes, frozen hashes, and independent end-to-end paths where they are the existing oracle. Never re-bless a golden to close consolidation. Use the existing StreamData dependency only for genuine general invariants with a strong oracle; it does not replace named regression fixtures or exact failure contracts.
- **D-08:** Do not add a mutation-testing dependency, hosted service, global mutation score, or checkout-mutating CI job. A temporary source mutation is permitted only as a bounded diagnostic when no test seam can express the original defect; it must run in isolation, leave no repository state behind, and produce a durable focused negative-control test rather than becoming the recorded authority itself.

### Generic Catalog Evidence Workflow
- **D-09:** Add one standalone `.github/workflows/catalog-evidence.yml` workflow named `Catalog Evidence`. It is manual `workflow_dispatch` only and accepts two closed inputs: required `candidate_sha` (exactly forty lowercase hexadecimal characters) and required `operation` (`review` or `canonical`). Ordinary `ci.yml` continues to validate committed state; the new workflow only produces evidence artifacts and remains graph-disconnected from required CI.
- **D-10:** Treat the default-branch workflow definition as the control plane and the detached candidate commit as untrusted input. Record both control SHA and candidate SHA, pass inputs through environment variables rather than interpolating them into shell source, check out the candidate with `persist-credentials: false`, and fail unless literal `git rev-parse HEAD` equals the validated input.
- **D-11:** Keep top-level permissions at `contents: read`; unspecified permissions are `none`. Use no secrets, repository writes, publication credentials, `workflow_run` privilege bridge, or cache restore/save in this workflow. Keep every third-party action pinned by full commit SHA and install PDFium only through the existing version and SHA-256 pin contract.
- **D-12:** `review` produces all candidate and reviewer-consumption evidence needed to replace the Phase 126, 127, and Phase 130 review routes. `canonical` generates and checks the exact 32-cell catalog payload. Candidate generation never records reviewer scores or approval, and canonical generation never commits or publishes repository content; materialization remains a separate human-authorized local step.

### Artifact Contract and Operator Experience
- **D-13:** Upload exactly one authoritative manifest-rooted bundle per workflow run. Do not preserve separate candidate, final, multipage, or convenience uploads. Name the artifact `rendro-catalog-evidence--{operation}--{full_candidate_sha}--run-{run_id}--attempt-{run_attempt}` so the Actions UI exposes its identity without opening it.
- **D-14:** Put schema-valid `manifest.json`, sorted `checksums.sha256`, and a short `README.md` at the bundle root. The manifest records schema version, evidence state, operation, control/workflow identity, full candidate SHA, checked-out HEAD, event, run ID/attempt, pinned PDFium version/binary SHA/DPI, generation/check commands, ordered safe relative payload roles/paths/media types/hashes/counts, and explicit authority/limit language. Missing, extra, unsafe, duplicated, or mismatched payloads fail closed.
- **D-15:** Use closed subdirectories inside the one bundle for candidate, bounded final-review, multipage/preset-review, and canonical payload roles as applicable. A reviewer starts from the README/manifest, not from filename folklore. The upload action's archive digest and artifact URL are transport facts available after upload; surface them in the job summary and logs rather than pretending they were known when the internal manifest was built.
- **D-16:** Set `retention-days: 30`. The bundle is bounded review transport, not durable authority; committed normalized parity facts, Git history, the pinned workflow definition, and eventual canonical repository content carry durable meaning. Do not add artifact attestations: they would require `id-token: write` and `attestations: write`, contradict the read-only lane, and Phase 135 has no consumer that verifies them.
- **D-17:** Write the GitHub job summary and bundle README in Rendro's what/where/why/next voice. Show operation, exact candidate and control SHAs, renderer identity, payload counts, evidence state, artifact name/link/digest, and the next supported command. Use explicit states such as `Candidate evidence only — reviewer approval is not recorded here` and `Canonical evidence — materialize only after the catalog check passes`. Text and manifests remain authoritative; color, icons, thumbnails, or screenshots never carry status alone.

### Parity Proof and Legacy-Route Retirement
- **D-18:** Require one committed four-row route-by-route parity matrix before deleting any legacy route: Phase 126 preset raster blessing to generic `review`; Phase 127 catalog blessing to generic `review`; Phase 130 candidate/final/multipage review to generic `review`; and Phase 130 canonical generation to generic `canonical`.
- **D-19:** For each row, run the legacy route and generic workflow remotely on the same full candidate SHA while both implementations still exist. Compare normalized evidence roles and per-file SHA-256 values, not archive ZIP digests or incidental filenames. Preserve candidate/HEAD identity, PDFium version and binary hash, bounded file counts, candidate-only reviewer-field absence, action pins, permission rules, run ID/attempt, and upload digest. A deliberate layout/name change is acceptable only when the normalized role set and every authority check remain equivalent.
- **D-20:** One matching old/new run per matrix row is the decisive parity gate. One optional repeat of each generic operation may corroborate reproducibility, but repeated new-workflow runs cannot substitute for legacy parity. Missing, extra, mismatched, unavailable, or unexplained evidence blocks retirement and remains recorded truthfully.
- **D-21:** Separate proof by authority. Local deterministic tests validate input enums, full-SHA binding, permissions, action pins, no-cache/no-secret rules, manifest schema, path confinement, comparator negative controls, Mix generation/check behavior, documentation, and unchanged `ci-success` topology. Remote Ubuntu/PDFium runs alone prove pinned-renderer payload identity. Neither proves human visual quality; Phase 136 retains that authority.
- **D-22:** Land the generic workflow and parity machinery before deletion. Keep old and new routes side by side until all four rows pass, then use one dedicated cutover commit to remove only the Phase 126/127/130 branch patterns, conditional generation/staging/upload steps, and legacy string assertions. Replace them with generic workflow, parity, and route-absence contracts while leaving `ci-success` and deterministic/proof/advisory membership intact. That deletion commit is the rollback unit if a post-cutover defect appears.

### Documentation and Maintainer JTBD
- **D-23:** Maintain one current repository-native runbook adjacent to the workflow and link it from any helper inventory it touches. It must let a fresh maintainer identify the candidate SHA, choose `review` or `canonical`, dispatch safely, verify control/candidate identity and renderer pin, download and validate the bundle, interpret candidate versus canonical authority, materialize approved content locally, diagnose failures, and reproduce every deterministic local check without consulting completed phase plans.
- **D-24:** Optimize the workflow for four user jobs: the maintainer requests evidence for one immutable commit; the reviewer downloads one complete package and sees exactly what is and is not approved; the Phase 136 implementer consumes one stable artifact contract; and the SRE/security reviewer can trace source, workflow, renderer, permissions, counts, hashes, run, attempt, expiry, and failure boundary. There is no product UI in this phase; accessibility, consistency, performance, security, reliability, observability, maintainability, and truthful scope apply to the GitHub Actions/operator surface through textual status, one download, bounded runtime/artifacts, least privilege, actionable diagnostics, and no hidden authority.

### the agent's Discretion
- Choose exact helper/module/schema names and whether parity normalization is implemented in Elixir or repository-owned scripting, provided it adds no runtime/package dependency and is covered through focused fail-closed tests.
- Choose exact safe subdirectory names inside the review bundle and the precise repository-native runbook path, while preserving one bundle, one manifest authority, one adjacent discoverable guide, and the vocabulary above.
- Choose plan and commit boundaries before the final dedicated route-deletion commit. Prefer small changes that separately establish schemas/comparators, workflow security, remote parity, test cleanup, documentation, and cutover.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope, Governance, and Prior Decisions
- `.planning/ROADMAP.md` — Phase 135 goal, success criteria, dependency on Phase 134, and boundary before Phase 136.
- `.planning/REQUIREMENTS.md` — TEST-01/02 and CI-01 through CI-05, plus the milestone's no-feature/no-unrelated-byte-change contract.
- `.planning/PROJECT.md` — Current milestone outcomes, pure-core constraints, evidence-lane rules, maintainer personas, and the pending purpose-named workflow decision.
- `.planning/STATE.md` — Accumulated Phase 132-134 decisions, `ci-success` and catalog-route boundaries, current blockers, and completion semantics.
- `.planning/QUALITY.md` — QL-003 authority, closure proof, risk/disposition vocabulary, and the rule that count reduction alone cannot close the finding.
- `.planning/quality/baselines/132-initial.json` — EV-TEST-001 and EV-CI-002 source-bound signals; diagnostic evidence, not cleanup quotas.
- `.planning/phases/132-quality-baseline-triage/132-CONTEXT.md` — Human-first ledger, evidence authority, owner routing, and repair/closure rules.
- `.planning/phases/133-repository-evidence-hygiene/133-CONTEXT.md` — Durable evidence, manifest, path/digest, archive-independence, package, and workflow trust patterns.
- `.planning/phases/134-core-architecture-readability/134-CONTEXT.md` — Characterization-before-change discipline, compatibility proof, evidence-backed no-op rule, and explicit deferral of test consolidation to Phase 135.

### Current v2.14 Research
- `.planning/research/SUMMARY.md` — Phase ordering, generic workflow intent, weaker-test/authority-loss pitfalls, and the requirement for live remote parity.
- `.planning/research/ARCHITECTURE.md` — Standalone `catalog-evidence.yml`, exact-SHA data flow, artifact-only output, and ordinary-CI responsibility.
- `.planning/research/FEATURES.md` — Trustworthy-test and purpose-named catalog-evidence maintainer outcomes and anti-features.
- `.planning/research/PITFALLS.md` — Test weakening, workflow input, cache, permission, artifact, performance, and cutover footguns.
- `.planning/research/STACK.md` — ExUnit/StreamData/GitHub Actions posture, closed workflow inputs, least privilege, and decision not to add speculative mutation/quality tooling.

### Current Workflow and Catalog Surfaces
- `.github/workflows/ci.yml` — Current Phase 126/127/130 triggers, pinned PDFium install, artifact staging, ordinary advisory checks, and `ci-success` topology to preserve.
- `test/guardrails/required_checks_contract_test.exs` — Current phase-number string assertions and lane/permission/required-context contracts to replace without weakening outcomes.
- `mix.exs` — Canonical `ci.fast`, `ci.proofs`, `ci.advisory`, catalog task aliases, dev/test-only tooling, and package boundary.
- `priv/pdfium_pin.json` — Existing renderer version and binary SHA-256 authority.
- `dev/mix/tasks/rendro/catalog/candidate.ex` — Candidate-only generation semantics.
- `dev/mix/tasks/rendro/catalog/gen.ex` — Canonical catalog generation entry point.
- `dev/mix/tasks/rendro/catalog/check.ex` — Committed/canonical catalog validation entry point.
- `dev/rendro/catalog_review_payload.ex` — Existing review payload assembly and identity rules.
- `dev/rendro/catalog_review_reconciliation.ex` — Existing candidate/final review reconciliation semantics.
- `test/rendro/catalog_raster_review_test.exs` — Pinned-raster candidate/final/multipage review behavior and file-count contracts.
- `test/rendro/catalog_review_payload_contract_test.exs` — Existing fail-closed review payload contract patterns.
- `test/docs_contract/catalog_manifest_contract_test.exs` — Existing catalog manifest identity and structure checks.
- `test/docs_contract/catalog_quality_contract_test.exs` — Existing in-memory negative-control and review-authority patterns.

### Test Candidates and Ecosystem DNA
- `.planning/milestones/v2.11-phases/122-typography-type-scale-application-font-role-leading-wiring/122-REVIEW.md` — Explicit weak Certificate assertion and low-priority duplicated Payslip fixture candidate.
- `test/rendro/recipes/payslip_opts_threading_test.exs` — Distinct opts/seam contracts plus the duplicated targeted Unicode-fallback render.
- `test/rendro/recipes/themed_render_smoke_test.exs` — Seven-recipe end-to-end themed smoke matrix and retained CR-01 Payslip regression owner.
- `test/rendro/recipes/certificate_typography_test.exs` — Current no-raise assertion whose name overstates centering equality.
- `prompts/rendro-oss-dna.md` — Canonical verification entrypoints, docs-contract tests, optional-lane separation, action pinning, and cross-library lessons.
- `prompts/rendro-gsd-seed.md` — Pure-core, errors-as-product, persona/JTBD, CI/release, and deterministic/advisory defaults.
- `prompts/rendro-integration-opportunities.md` — Optional-integration and consumer-first policy; informative without widening Phase 135.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Maintainer/SRE testing, deterministic golden, visual regression, validation, artifact, and DX lessons from Elixir and mature PDF libraries.

### Current Brand and Operator Voice
- `brand/README.md` — Current brand source hierarchy; supersedes the older prompt-era brand book for presentation decisions.
- `brand/copy/VOICE.md` — Concrete what/where/why/next diagnostics, honest limits, status microcopy, and maintainer/SRE tone.

No external specification or ADR was referenced. Web research informed these decisions, but the repository-local contracts above remain authoritative for planning and implementation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing catalog Mix tasks and review payload/reconciliation modules already separate candidate generation, canonical generation/checking, raster review, identity, and review reconciliation; the workflow should orchestrate these seams rather than create a second catalog engine.
- `priv/pdfium_pin.json`, full-SHA guards, per-file SHA-256 manifests, safe-relative path checks, schema-backed evidence, and `if-no-files-found: error` provide the authority vocabulary for the generic artifact contract.
- `test/guardrails/required_checks_contract_test.exs` already parses workflow structure and protects lane membership, permissions, action pins, and `ci-success`; its phase-specific assertions can become outcome-focused generic workflow and route-absence contracts.
- Existing tests mutate in-memory catalog/manifest facts, exercise broken font registries, and use isolated temporary directories. These are the preferred teeth mechanisms.

### Established Patterns
- Core stays pure; catalog/evidence tooling remains dev/test/repository-only and excluded from the runtime/package surface unless deliberately documented otherwise.
- Ordinary CI validates committed state. Exact-SHA pinned rendering and human review are separate advisory authorities, and expiring workflow artifacts are transport rather than durable truth.
- Machine facts, human judgment, and publication remain separate: generation records identity, reviewers own visual disposition, and a human-authorized local step materializes verified canonical content.
- Fail-closed manifests use explicit schema versions, closed roles/enums, exact counts, safe relative paths, stable ordering, lower-case SHA-256 values, and concrete diagnostics.

### Integration Points
- `.github/workflows/catalog-evidence.yml` becomes the only remote catalog generation/evidence entry point after parity; `.github/workflows/ci.yml` loses only phase-number triggers and conditional generation/staging/upload machinery.
- Required-check guardrails gain static contracts for the new workflow, parity evidence, legacy-route absence, and unchanged `ci-success`; they do not read remote artifacts as if they were local deterministic authority.
- The quality ledger and a bounded committed companion record carry TEST/CI inventories, parity facts, run identities, and QL-003 closure without making product code consume planning.
- Phase 136 consumes the stable `review`/`canonical` bundle contract and still performs the six-cell visual repair and human review defined by its own scope.

</code_context>

<specifics>
## Specific Ideas

- The operator experience should feel like a sealed evidence packet: one exact request, one complete download, one manifest, explicit limits, and one next command.
- The four parity rows are semantic roles, not names to preserve forever. Phase-number filenames may disappear only after their hashes, counts, candidate identity, renderer identity, and authority rules have a generic home.
- A useful test inventory names why two similar-looking tests are actually the same or different. Independent end-to-end paths, distinct error contracts, and authority lanes are reasons to retain overlap; copied setup alone is not a reason to delete it.
- GitHub Actions is the only UI surface in this phase. Make summaries keyboard/screen-reader-friendly through real headings and textual facts, never color-only status, while preserving full-size PNGs for the separately authorized visual review.

</specifics>

<deferred>
## Deferred Ideas

- Whole-suite test architecture, shared recipe-fixture frameworks, and global mutation scoring — revisit only after a concrete recurring false-negative, flake, or maintenance-cost finding establishes a cohesive owner and measurable benefit.
- Artifact attestations — revisit only when a real downstream consumer verifies them and the additional write permissions are explicitly authorized.
- Catalog visual changes, score updates, and human approval — Phase 136 only.

</deferred>

---

*Phase: 135-test-ci-cd-simplification*
*Context gathered: 2026-08-27*
