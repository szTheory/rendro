# Phase 135: Test & CI/CD Simplification - Research

**Researched:** 2026-08-27  
**Domain:** ExUnit test consolidation and GitHub Actions exact-SHA catalog evidence automation  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Test Consolidation Scope and Stop Rule
- **D-01:** Use bounded candidate-only cleanup, not a suite-wide restructuring campaign. A test group is eligible only when evidence shows the tests protect the same observable behavior, failure mode, authority boundary, and deterministic-output contract, and when consolidation reduces a concrete maintenance, flake, planning-coupling, implementation-coupling, or change-fan-out cost.
- **D-02:** Treat an evidence-backed no-op as a successful result once the explicit candidates are resolved. Test count, file size, duplicated setup, coverage percentage, and phase-number prose are investigation signals; none independently authorizes deletion, macros, parameterization, or shared-fixture architecture.
- **D-03:** Bound the initial candidate set to the workflow-contract tests that must change with the generic catalog workflow and the explicit Phase 122 review findings. Retain the seven-recipe themed smoke case as the owner of the masked-middot/accented Payslip end-to-end regression; remove the identical targeted render assertion only after the inventory and teeth gate pass, while preserving the opts test's distinct threading, precedence, no-theme, and live-seam assertions. Rename the Certificate test that currently proves only that themed and unthemed section construction do not raise; do not invent a geometry-equality contract that current behavior does not satisfy.
- **D-04:** Do not introduce Phoenix, Plug, Ecto, SQL sandboxing, database fixtures, or application-case abstractions into the pure Rendro suite. Follow the ecosystem convention behind those tools—share setup only when it represents one stable responsibility—but keep core tests on ExUnit, explicit domain fixtures, existing `test/support` seams, and observable assertions.

#### Replacement Tests With Teeth
- **D-05:** Before consolidating any group, record a compact durable inventory row: old tests, replacement owner, preserved behavior, preserved failure mode, authority lane, oracle, negative control, focused command, and result. The inventory is evidence for TEST-01/TEST-02, not a permanent catalog of every test in the repository.
- **D-06:** Every replacement keeps a positive assertion for each preserved contract and executes a minimal deterministic negative control that changes one in-memory fixture field, validated record, injected document state, manifest field, permission, SHA, count, digest, or expected contract value. The replacement must reject the broken state at the intended assertion with a useful error; `refute left == right`, line execution, or a source-text scan alone is not proof of teeth.
- **D-07:** Preserve exact error shapes, deterministic PDF bytes, frozen hashes, and independent end-to-end paths where they are the existing oracle. Never re-bless a golden to close consolidation. Use the existing StreamData dependency only for genuine general invariants with a strong oracle; it does not replace named regression fixtures or exact failure contracts.
- **D-08:** Do not add a mutation-testing dependency, hosted service, global mutation score, or checkout-mutating CI job. A temporary source mutation is permitted only as a bounded diagnostic when no test seam can express the original defect; it must run in isolation, leave no repository state behind, and produce a durable focused negative-control test rather than becoming the recorded authority itself.

#### Generic Catalog Evidence Workflow
- **D-09:** Add one standalone `.github/workflows/catalog-evidence.yml` workflow named `Catalog Evidence`. It is manual `workflow_dispatch` only and accepts two closed inputs: required `candidate_sha` (exactly forty lowercase hexadecimal characters) and required `operation` (`review` or `canonical`). Ordinary `ci.yml` continues to validate committed state; the new workflow only produces evidence artifacts and remains graph-disconnected from required CI.
- **D-10:** Treat the default-branch workflow definition as the control plane and the detached candidate commit as untrusted input. Record both control SHA and candidate SHA, pass inputs through environment variables rather than interpolating them into shell source, check out the candidate with `persist-credentials: false`, and fail unless literal `git rev-parse HEAD` equals the validated input.
- **D-11:** Keep top-level permissions at `contents: read`; unspecified permissions are `none`. Use no secrets, repository writes, publication credentials, `workflow_run` privilege bridge, or cache restore/save in this workflow. Keep every third-party action pinned by full commit SHA and install PDFium only through the existing version and SHA-256 pin contract.
- **D-12:** `review` produces all candidate and reviewer-consumption evidence needed to replace the Phase 126, 127, and Phase 130 review routes. `canonical` generates and checks the exact 32-cell catalog payload. Candidate generation never records reviewer scores or approval, and canonical generation never commits or publishes repository content; materialization remains a separate human-authorized local step.

#### Artifact Contract and Operator Experience
- **D-13:** Upload exactly one authoritative manifest-rooted bundle per workflow run. Do not preserve separate candidate, final, multipage, or convenience uploads. Name the artifact `rendro-catalog-evidence--{operation}--{full_candidate_sha}--run-{run_id}--attempt-{run_attempt}` so the Actions UI exposes its identity without opening it.
- **D-14:** Put schema-valid `manifest.json`, sorted `checksums.sha256`, and a short `README.md` at the bundle root. The manifest records schema version, evidence state, operation, control/workflow identity, full candidate SHA, checked-out HEAD, event, run ID/attempt, pinned PDFium version/binary SHA/DPI, generation/check commands, ordered safe relative payload roles/paths/media types/hashes/counts, and explicit authority/limit language. Missing, extra, unsafe, duplicated, or mismatched payloads fail closed.
- **D-15:** Use closed subdirectories inside the one bundle for candidate, bounded final-review, multipage/preset-review, and canonical payload roles as applicable. A reviewer starts from the README/manifest, not from filename folklore. The upload action's archive digest and artifact URL are transport facts available after upload; surface them in the job summary and logs rather than pretending they were known when the internal manifest was built.
- **D-16:** Set `retention-days: 30`. The bundle is bounded review transport, not durable authority; committed normalized parity facts, Git history, the pinned workflow definition, and eventual canonical repository content carry durable meaning. Do not add artifact attestations: they would require `id-token: write` and `attestations: write`, contradict the read-only lane, and Phase 135 has no consumer that verifies them.
- **D-17:** Write the GitHub job summary and bundle README in Rendro's what/where/why/next voice. Show operation, exact candidate and control SHAs, renderer identity, payload counts, evidence state, artifact name/link/digest, and the next supported command. Use explicit states such as `Candidate evidence only — reviewer approval is not recorded here` and `Canonical evidence — materialize only after the catalog check passes`. Text and manifests remain authoritative; color, icons, thumbnails, or screenshots never carry status alone.

#### Parity Proof and Legacy-Route Retirement
- **D-18:** Require one committed four-row route-by-route parity matrix before deleting any legacy route: Phase 126 preset raster blessing to generic `review`; Phase 127 catalog blessing to generic `review`; Phase 130 candidate/final/multipage review to generic `review`; and Phase 130 canonical generation to generic `canonical`.
- **D-19:** For each row, run the legacy route and generic workflow remotely on the same full candidate SHA while both implementations still exist. Compare normalized evidence roles and per-file SHA-256 values, not archive ZIP digests or incidental filenames. Preserve candidate/HEAD identity, PDFium version and binary hash, bounded file counts, candidate-only reviewer-field absence, action pins, permission rules, run ID/attempt, and upload digest. A deliberate layout/name change is acceptable only when the normalized role set and every authority check remain equivalent.
- **D-20:** One matching old/new run per matrix row is the decisive parity gate. One optional repeat of each generic operation may corroborate reproducibility, but repeated new-workflow runs cannot substitute for legacy parity. Missing, extra, mismatched, unavailable, or unexplained evidence blocks retirement and remains recorded truthfully.
- **D-21:** Separate proof by authority. Local deterministic tests validate input enums, full-SHA binding, permissions, action pins, no-cache/no-secret rules, manifest schema, path confinement, comparator negative controls, Mix generation/check behavior, documentation, and unchanged `ci-success` topology. Remote Ubuntu/PDFium runs alone prove pinned-renderer payload identity. Neither proves human visual quality; Phase 136 retains that authority.
- **D-22:** Land the generic workflow and parity machinery before deletion. Keep old and new routes side by side until all four rows pass, then use one dedicated cutover commit to remove only the Phase 126/127/130 branch patterns, conditional generation/staging/upload steps, and legacy string assertions. Replace them with generic workflow, parity, and route-absence contracts while leaving `ci-success` and deterministic/proof/advisory membership intact. That deletion commit is the rollback unit if a post-cutover defect appears.

#### Documentation and Maintainer JTBD
- **D-23:** Maintain one current repository-native runbook adjacent to the workflow and link it from any helper inventory it touches. It must let a fresh maintainer identify the candidate SHA, choose `review` or `canonical`, dispatch safely, verify control/candidate identity and renderer pin, download and validate the bundle, interpret candidate versus canonical authority, materialize approved content locally, diagnose failures, and reproduce every deterministic local check without consulting completed phase plans.
- **D-24:** Optimize the workflow for four user jobs: the maintainer requests evidence for one immutable commit; the reviewer downloads one complete package and sees exactly what is and is not approved; the Phase 136 implementer consumes one stable artifact contract; and the SRE/security reviewer can trace source, workflow, renderer, permissions, counts, hashes, run, attempt, expiry, and failure boundary. There is no product UI in this phase; accessibility, consistency, performance, security, reliability, observability, maintainability, and truthful scope apply to the GitHub Actions/operator surface through textual status, one download, bounded runtime/artifacts, least privilege, actionable diagnostics, and no hidden authority.

### the agent's Discretion
- Choose exact helper/module/schema names and whether parity normalization is implemented in Elixir or repository-owned scripting, provided it adds no runtime/package dependency and is covered through focused fail-closed tests.
- Choose exact safe subdirectory names inside the review bundle and the precise repository-native runbook path, while preserving one bundle, one manifest authority, one adjacent discoverable guide, and the vocabulary above.
- Choose plan and commit boundaries before the final dedicated route-deletion commit. Prefer small changes that separately establish schemas/comparators, workflow security, remote parity, test cleanup, documentation, and cutover.

### Deferred Ideas (OUT OF SCOPE)
- Whole-suite test architecture, shared recipe-fixture frameworks, and global mutation scoring — revisit only after a concrete recurring false-negative, flake, or maintenance-cost finding establishes a cohesive owner and measurable benefit.
- Artifact attestations — revisit only when a real downstream consumer verifies them and the additional write permissions are explicitly authorized.
- Catalog visual changes, score updates, and human approval — Phase 136 only.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| TEST-01 | Inventory distinct behavior/failure modes and prove replacements reject broken contracts. | Compact test-inventory artifact, positive/negative-control contract tests, focused commands. |
| TEST-02 | Consolidate only brittle overlap without losing behavior, failures, public contracts, or deterministic-output protection. | Bounded Payslip/Certificate and workflow-contract candidate set with no-op stop rule. |
| CI-01 | One exact-SHA, read-only, pinned-renderer catalog evidence workflow. | Standalone dispatch workflow, input/HEAD gates, existing candidate/gen/check task seams, one bundle. |
| CI-02 | Prove parity before removing Phase 126/127/130 routes. | Four-row normalized remote parity matrix and fail-closed comparator. |
| CI-03 | Retain deterministic/proof/advisory separation and sole `ci-success`. | Existing CI topology and guardrail/baseline contracts; workflow remains disconnected. |
| CI-04 | Keep cache trust, pins, permissions, and secret boundaries. | Static workflow contract tests for no cache/secrets/writes and full SHA pins. |
| CI-05 | Document supported local/remote paths, authority checks, artifacts, and failure boundaries. | Workflow-adjacent runbook plus helper-inventory link and docs-contract tests. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep the `rendro` core pure: no hard dependency on Phoenix, Oban, or admin tooling. [VERIFIED: `AGENTS.md`]
- Preserve deterministic and advisory verification-lane separation in CI and documentation. [VERIFIED: `AGENTS.md`; `.github/workflows/ci.yml`]
- Classify coverage as deterministic, advisory, or explicit deferral; optional human feedback cannot block completion. [VERIFIED: `AGENTS.md`]
- Treat documentation claims as contracts and do not claim unsupported capabilities. [VERIFIED: `AGENTS.md`]
- Use optional dependency guards for integrations; this phase adds no dependency or integration. [VERIFIED: `AGENTS.md`; `mix.exs`]

## Summary

Rendro already has the essential catalog-generation seams: `mix rendro.catalog.candidate` creates an isolated candidate root, `mix rendro.catalog.gen` writes canonical artifacts, and `mix rendro.catalog.check` validates the committed canonical tree. The current advisory CI job embeds four legacy, branch-name-controlled routes for Phases 126, 127, and 130; the required pipeline remains the `test` → `integration-proofs`/other required jobs → sole `ci-success` roll-up. [VERIFIED: `dev/rendro/catalog.ex`; `mix.exs`; `.github/workflows/ci.yml`; `priv/guardrails/required_status_checks.json`]

Implement this phase as additive evidence tooling first: a dev/test-only manifest/bundle builder and normalized parity comparator, static ExUnit/docs contracts, then a manually dispatched `Catalog Evidence` workflow. The remote Ubuntu/PDFium route produces payload-identity evidence; local tests prove workflow structure, content security, schema/path/hash closure, and route topology. Keep the generic workflow graph-disconnected from `ci-success`, then delete legacy routes in a dedicated rollback commit only after the four-row remote matrix is committed. [VERIFIED: `135-CONTEXT.md`; `.github/workflows/ci.yml`; `test/guardrails/required_checks_contract_test.exs`]

The test cleanup has one narrow, evidence-backed candidate: the themed Payslip target-render assertion may be removed only after the seven-recipe smoke test demonstrably owns the same masked-middot/accented full-render regression; `payslip_opts_threading_test.exs` stays because it owns threading, precedence, no-theme, and live-seam contracts. The Certificate "does not raise" construction test should be renamed to describe its actual construction contract rather than upgraded to unsupported geometry equality. [VERIFIED: `135-CONTEXT.md`; `test/rendro/recipes/themed_render_smoke_test.exs`; `test/rendro/recipes/payslip_opts_threading_test.exs`; `test/rendro/recipes/certificate_opts_threading_test.exs`]

**Primary recommendation:** Build one fail-closed, manifest-rooted evidence-bundle/parity boundary around the existing catalog Mix tasks; retain all current CI lane membership and make cutover a final, separate commit.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Candidate SHA validation, manifest schema, payload path/hash/count validation | API / Backend (dev/test Elixir tooling) | Database / Storage (artifact filesystem) | Pure Elixir owns deterministic interpretation and rejects malformed evidence before file reads/copies. [VERIFIED: `dev/rendro/catalog.ex`; `135-CONTEXT.md`] |
| Exact candidate checkout, pinned PDFium execution, upload | CDN / Static (GitHub Actions runner/artifact transport) | API / Backend | GitHub Actions materializes untrusted candidate bytes and transports one generated bundle; it must not become product runtime code. [VERIFIED: `.github/workflows/ci.yml`; `135-CONTEXT.md`] |
| Required merge contract | CDN / Static (CI orchestration) | API / Backend | `ci-success` is the only required context and aggregates required deterministic/proof jobs, not advisory evidence. [VERIFIED: `.github/workflows/ci.yml`; `priv/guardrails/required_status_checks.json`] |
| Catalog visual judgment | Browser / Client (human reviewer) | CDN / Static | Review PNGs are evidence for a human decision; neither ExUnit nor the workflow records approval. [VERIFIED: `135-CONTEXT.md`] |
| Operator instructions and status | CDN / Static (workflow summary + repository runbook) | Browser / Client | Textual summary/readme provides accessible, inspectable state without encoding authority in thumbnails or color. [VERIFIED: `135-CONTEXT.md`] |

## Standard Stack

### Core

| Library / facility | Version | Purpose | Why Standard |
|---|---:|---|---|
| Elixir + ExUnit | Elixir 1.19.5 / OTP 28 | Deterministic unit, integration, docs, and workflow-text contract tests | Existing pure-core testing stack; no fixture-framework addition is authorized. [VERIFIED: `AGENTS.md`; `mix.exs`; `test/test_helper.exs`] |
| Existing Rendro catalog Mix tasks | repository-owned | Candidate generation, canonical generation, canonical check | Existing narrow interfaces already separate candidate and canonical behavior. [VERIFIED: `mix.exs`; `dev/rendro/catalog.ex`; `dev/mix/tasks/rendro/catalog/*.ex`] |
| GitHub Actions YAML | existing pinned actions | Manual exact-SHA execution and artifact transport | Existing CI uses immutable action commit pins and top-level read permissions. [VERIFIED: `.github/workflows/ci.yml`] |
| PDFium pin contract | `v0.11.0` / pinned SHA-256 | Ubuntu raster evidence | Existing advisory lane downloads, checks, and uses the pinned executable; local macOS has no `pdfium-cli`. [VERIFIED: `.github/workflows/ci.yml`; local environment probe] |

### Supporting

| Facility | Version | Purpose | When to Use |
|---|---:|---|---|
| `JSON` / `Jason` already in project | existing | Serialize/parse manifest and comparator facts | Bundle manifest, checksum index, and normalized parity record only. [VERIFIED: `dev/rendro/catalog.ex`; `test/rendro/catalog_review_payload_contract_test.exs`] |
| `:crypto.hash(:sha256, ...)` | OTP built-in | Per-file evidence identity | Build/verify checksums and compare normalized payloads; do not compare ZIP digests. [VERIFIED: `test/rendro/catalog_raster_review_test.exs`; `135-CONTEXT.md`] |
| `jq`, `git`, `sha256sum` | GitHub Ubuntu runner tools | Workflow-side pin/HEAD/manifest checks | Use only with values delivered through environment variables and explicit fail-closed checks. [VERIFIED: `.github/workflows/ci.yml`; `135-CONTEXT.md`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Repository-owned comparator | Hosted mutation/parity service | Rejected: violates D-08/D-11 dependency, authority, and checkout-mutation limits. [VERIFIED: `135-CONTEXT.md`] |
| Explicit ExUnit fixtures | Phoenix/Ecto application fixtures | Rejected: introduces irrelevant dependency and hides domain responsibility. [VERIFIED: `135-CONTEXT.md`; `AGENTS.md`] |
| Internal role/path manifest | Archive ZIP checksum or filename matching | Rejected: archive/filename details are transport/incidental rather than payload authority. [VERIFIED: `135-CONTEXT.md`] |

**Installation:** None — Phase 135 must add no runtime, test, mutation-testing, hosted-service, or adapter dependency. [VERIFIED: `135-CONTEXT.md`; `mix.exs`]

## Architecture Patterns

### System Architecture Diagram

```text
default-branch catalog-evidence.yml (trusted control SHA)
             │ workflow_dispatch: candidate_sha + operation
             ▼
validate closed inputs ──reject──> actionable failure summary
             │
             ▼
checkout detached candidate SHA (credentials disabled)
             │                │
             │                └─ literal HEAD mismatch ──> fail closed
             ▼
install pinned PDFium + verify binary SHA
             │
     ┌───────┴─────────────────────────┐
     ▼                                 ▼
 review: candidate + bounded review    canonical: generate + check 32 cells
     └──────────────┬──────────────────┘
                    ▼
  bundle builder: manifest.json + sorted checksums + README + closed payload dirs
                    │
             validate exact role/path/hash/count contract
                    │
                    ▼
 one upload-artifact bundle ──> post-upload URL/digest in summary/logs

local ExUnit/docs contracts ──> workflow/security/schema/topology proof
remote Ubuntu/PDFium parity ──> normalized old/new payload identity proof
human Phase 136 review ───────> visual-quality decision (separate authority)
```

### Recommended Project Structure

```text
.github/workflows/
├── catalog-evidence.yml                 # manual, read-only, exact-SHA evidence transport
└── CATALOG-EVIDENCE.md                  # adjacent maintainer runbook
dev/rendro/
├── catalog_evidence_bundle.ex            # build + validate one bundle contract
└── catalog_evidence_parity.ex            # normalize and compare old/new route evidence
test/rendro/
├── catalog_evidence_bundle_test.exs      # manifest/path/hash/count negative controls
└── catalog_evidence_parity_test.exs      # normalized comparison negative controls
test/guardrails/
└── required_checks_contract_test.exs     # CI topology and generic-workflow contracts
test/docs_contract/
└── catalog_evidence_runbook_test.exs     # current operator claims and commands
.planning/phases/135-test-ci-cd-simplification/
└── 135-test-inventory.md                 # compact, durable TEST-01/02 inventory + parity matrix
```

### Pattern 1: Additive sealed evidence packet

**What:** Generate into a fresh temporary root, calculate sorted checksums from a literal role registry, write manifest/readme, validate the completed root, then upload that root exactly once. [VERIFIED: `135-CONTEXT.md`; `dev/rendro/catalog.ex`]

**When to use:** Both operations, using closed role sets: candidate/final-review/multipage/preset-review for `review`, canonical catalog for `canonical`. [VERIFIED: `135-CONTEXT.md`]

**Example:**

```elixir
# Source: repository pattern in dev/rendro/catalog.ex; Phase 135 contract
with :ok <- validate_operation(operation),
     :ok <- validate_candidate_sha(candidate_sha),
     {:ok, entries} <- collect_literal_role_entries(root, operation),
     :ok <- validate_entries(entries),
     :ok <- write_sorted_checksums(root, entries),
     :ok <- write_manifest(root, entries, provenance),
     :ok <- validate_bundle(root, operation) do
  :ok
end
```

### Pattern 2: Control-plane/candidate-plane separation

**What:** The workflow on the default branch validates input first, passes values as environment variables, checks out the requested SHA detached without persisted credentials, and checks literal `HEAD` equality before executing candidate code. [VERIFIED: `135-CONTEXT.md`; [CITED: https://github.com/actions/checkout/blob/main/action.yml]]

**When to use:** Every manual evidence dispatch; never use branch-name routes, `workflow_run`, a write token, secrets, or caches for this path. [VERIFIED: `135-CONTEXT.md`]

**Example:**

```yaml
# Source: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
on:
  workflow_dispatch:
    inputs:
      candidate_sha: {required: true, type: string}
      operation: {required: true, type: choice, options: [review, canonical]}
permissions:
  contents: read
```

### Pattern 3: Authority-separated parity

**What:** Persist one four-row matrix that compares normalized roles and SHA-256 values from paired legacy/generic remote runs of the same SHA. A local comparator proves comparator behavior; one matched remote pair per row proves renderer output parity. [VERIFIED: `135-CONTEXT.md`]

**Anti-Patterns to Avoid**

- **String-only workflow proof:** workflow-text tests are necessary for security/topology but cannot prove Ubuntu/PDFium payload equality; retain the remote matrix. [VERIFIED: `135-CONTEXT.md`]
- **New-run reproducibility mistaken for legacy parity:** repeated generic runs cannot replace one old/new comparison for each legacy route. [VERIFIED: `135-CONTEXT.md`]
- **ZIP-digest equality:** the transport archive digest must be surfaced after upload, but does not substitute for normalized payload checksums. [VERIFIED: `135-CONTEXT.md`; [CITED: https://github.com/actions/upload-artifact/blob/main/action.yml]]
- **Accidental test-factory migration:** copied setup alone does not justify shared fixtures, macros, parameterization, or a suite-wide reorganization. [VERIFIED: `135-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Product/runtime catalog service | New runtime evidence subsystem | Existing dev-only catalog tasks and a dev/test bundle helper | Catalog tooling is already isolated from `lib/` runtime compilation. [VERIFIED: `mix.exs`; `dev/rendro/catalog.ex`] |
| Generic test framework | Phoenix/Ecto fixtures, SQL sandbox, application case | ExUnit + explicit domain fixtures + `test/support` | Preserves pure core and makes the observable contract owner explicit. [VERIFIED: `135-CONTEXT.md`; `AGENTS.md`] |
| Mutation platform | Global score/hosted/check-out mutating job | Minimal in-memory negative controls beside replacement contracts | Proves intended assertion failure deterministically without authority sprawl. [VERIFIED: `135-CONTEXT.md`] |
| Artifact provenance mechanism | Attestations / `id-token: write` | Manifest-rooted bundle, checksums, Git history, workflow pins | Attestations conflict with the locked read-only permissions and have no verified consumer. [VERIFIED: `135-CONTEXT.md`] |

**Key insight:** The difficult work is not raster generation; it is preserving which system has authority for each assertion. The bundle and comparator must make that boundary machine-checkable without making advisory raster or human review part of the required merge gate. [VERIFIED: `AGENTS.md`; `135-CONTEXT.md`; `.github/workflows/ci.yml`]

## Common Pitfalls

### Pitfall 1: Deleting a similarly worded test with a different oracle

**What goes wrong:** A targeted Payslip or Certificate test is removed because it looks duplicative, but it owns byte identity, option precedence, a live seam, or an independent render path. [VERIFIED: `test/rendro/recipes/themed_render_smoke_test.exs`; `test/rendro/recipes/*_opts_threading_test.exs`; `135-CONTEXT.md`]

**How to avoid:** Complete the D-05 inventory and execute a positive assertion plus fixture/manifest mutation that makes the retained owner fail before deletion. Preserve `payslip_opts_threading_test.exs`; only remove the target render assertion if the seven-recipe smoke test is demonstrated to own the same masked-middot/accented full-render contract. [VERIFIED: `135-CONTEXT.md`; `.planning/milestones/v2.11-phases/122-typography-type-scale-application-font-role-leading-wiring/122-VERIFICATION.md`]

### Pitfall 2: Checking out untrusted candidate code with trusted workflow assumptions

**What goes wrong:** A branch/ref is used as candidate identity, credentials remain configured, or `${{ inputs.* }}` is interpolated into shell source. [VERIFIED: `135-CONTEXT.md`; [CITED: https://github.com/actions/checkout/blob/main/action.yml]]

**How to avoid:** Regex-validate exactly forty lowercase hex characters, use env variables, pass `ref` as that SHA, set `persist-credentials: false`, and fail unless `git rev-parse HEAD` is the same literal value. [VERIFIED: `135-CONTEXT.md`; [CITED: https://github.com/actions/checkout/blob/main/action.yml]]

### Pitfall 3: Promoting remote raster evidence into CI authority

**What goes wrong:** A generic workflow is wired into `needs`, `ci-success`, or the deterministic `test` job, turning runner/PDFium variation into merge authority. [VERIFIED: `.github/workflows/ci.yml`; `135-CONTEXT.md`]

**How to avoid:** Keep `catalog-evidence.yml` standalone/manual and keep its job graph disconnected; guard with topology tests that `ci-success` has unchanged dependencies and ordinary CI retains deterministic/proof/advisory membership. [VERIFIED: `135-CONTEXT.md`; `test/guardrails/required_checks_contract_test.exs`]

### Pitfall 4: Treating artifact transport metadata as internal evidence

**What goes wrong:** The pre-upload manifest claims an artifact URL or archive digest it cannot know, or parity compares the ZIP digest. [VERIFIED: `135-CONTEXT.md`; [CITED: https://github.com/actions/upload-artifact/blob/main/action.yml]]

**How to avoid:** Keep manifest authority to internal roles/files/hashes and write upload outputs to summary/logs after the upload step. [VERIFIED: `135-CONTEXT.md`; [CITED: https://github.com/actions/upload-artifact/blob/main/action.yml]]

## Code Examples

### Local negative-control comparator

```elixir
# Source: Phase 135 D-06/D-19 contract
test "parity comparator rejects one changed normalized payload SHA" do
  left = valid_normalized_evidence()
  right = put_in(valid_normalized_evidence(), ["payload", Access.at(0), "sha256"], String.duplicate("0", 64))

  assert {:error, errors} = CatalogEvidenceParity.compare(left, right)
  assert Enum.any?(errors, &String.contains?(&1, "sha256"))
end
```

### Workflow post-upload transport facts

```yaml
# Source: https://github.com/actions/upload-artifact/blob/main/action.yml
- name: Upload evidence packet
  id: evidence_upload
  uses: actions/upload-artifact@<full-immutable-commit-sha>
  with:
    name: rendro-catalog-evidence--${{ inputs.operation }}--${{ inputs.candidate_sha }}--run-${{ github.run_id }}--attempt-${{ github.run_attempt }}
    path: ${{ runner.temp }}/rendro-catalog-evidence
    if-no-files-found: error
    retention-days: 30
- name: Summarize transport facts
  env:
    ARTIFACT_URL: ${{ steps.evidence_upload.outputs.artifact-url }}
    ARTIFACT_DIGEST: ${{ steps.evidence_upload.outputs.artifact-digest }}
  run: |
    printf '%s\n' "Artifact URL: ${ARTIFACT_URL}" >> "$GITHUB_STEP_SUMMARY"
    printf '%s\n' "Archive digest: ${ARTIFACT_DIGEST}" >> "$GITHUB_STEP_SUMMARY"
```

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Phase-specific push branch patterns and multiple uploads in `ci.yml` | One manual exact-SHA workflow with one manifest-rooted bundle | Removes milestone naming/control flow after parity while making candidate identity and authority explicit. [VERIFIED: `.github/workflows/ci.yml`; `135-CONTEXT.md`] |
| Contract tests assert legacy strings | Contract tests assert generic workflow security/topology plus legacy-route absence only after cutover | Avoids a deletion-first migration and preserves test teeth. [VERIFIED: `test/guardrails/required_checks_contract_test.exs`; `135-CONTEXT.md`] |

**Deprecated/outdated:** The Phase 126/127/130 push-ref routes are temporary migration routes, not supported operator interfaces after the dedicated cutover passes. [VERIFIED: `135-CONTEXT.md`; `.github/workflows/ci.yml`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | `CatalogEvidenceBundle`, `CatalogEvidenceParity`, and `.github/workflows/CATALOG-EVIDENCE.md` are the selected final names. | Open Questions | Naming churn only; behavior-first tests and the locked adjacent-runbook requirement remain valid. |
| A2 | Thirty days is an appropriate research freshness interval for the repository architecture; action metadata should be rechecked at implementation. | Metadata | A changed third-party action contract could invalidate a pin/output assumption. |

No unverified package or platform claim is required for planning.

## Open Questions

1. **Exact chosen helper and runbook names**
   - What we know: names are delegated but must be repository-owned, dependency-free, and workflow-adjacent/discoverable. [VERIFIED: `135-CONTEXT.md`]
   - What's unclear: final module/file naming.
   - Recommendation: select names matching `CatalogEvidenceBundle`, `CatalogEvidenceParity`, and `.github/workflows/CATALOG-EVIDENCE.md`; test behavior rather than names. [ASSUMED]

2. **Remote parity availability during execution**
   - What we know: local macOS has no `pdfium-cli`, while the current Ubuntu workflow installs the pinned binary. [VERIFIED: local environment probe; `.github/workflows/ci.yml`]
   - What's unclear: whether all four paired historic routes can be dispatched/accessed when implementation reaches the parity step.
   - Recommendation: retain unavailable rows as explicit blocked evidence and do not execute D-22 cutover until all four are matching. [VERIFIED: `135-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Elixir/Mix | Local ExUnit and Mix-task contracts | ✓ | 1.19.5 / OTP 28 | — [VERIFIED: local environment probe] |
| Node/npm | Existing governance and browser-adjacent checks | ✓ | Node 24.19.0 / npm 11.17.0 | — [VERIFIED: local environment probe] |
| Git/jq/sha256sum/curl | Local static validation and workflow implementation | ✓ | installed | — [VERIFIED: local environment probe] |
| `pdfium-cli` | Remote payload identity / parity | ✗ locally | — | GitHub Ubuntu workflow installs the existing pinned binary; local deterministic checks intentionally do not claim payload identity. [VERIFIED: local environment probe; `.github/workflows/ci.yml`] |
| GitHub Actions remote dispatch/artifacts | Decisive parity matrix | not probed | — | No local substitute for Ubuntu/PDFium parity; record remote unavailability truthfully and block legacy deletion. [VERIFIED: `135-CONTEXT.md`] |

**Missing dependencies with no fallback:** GitHub Ubuntu/PDFium execution is required for decisive old/new payload parity. [VERIFIED: `135-CONTEXT.md`]

**Missing dependencies with fallback:** Local `pdfium-cli` is intentionally absent; use deterministic ExUnit/docs contracts locally, not a different renderer. [VERIFIED: `135-CONTEXT.md`; local environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit, bundled with Elixir 1.19.5. [VERIFIED: local `mix help test`; `test/test_helper.exs`] |
| Config file | `test/test_helper.exs`. [VERIFIED: `test/test_helper.exs`] |
| Quick run command | `mix test test/rendro/catalog_review_payload_contract_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1`. [VERIFIED: existing files; local focused run] |
| Full deterministic suite | `mix ci.fast`. [VERIFIED: `mix.exs`] |
| Full lane-aware suite | `mix ci` (fast + proof aliases); remote catalog parity remains separately advisory. [VERIFIED: `mix.exs`; `135-CONTEXT.md`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| TEST-01 | Inventory records owner/oracle/failure/negative control; replacement fails on one broken fixture/field | contract + unit | `mix test test/rendro/recipes/themed_render_smoke_test.exs test/rendro/recipes/payslip_opts_threading_test.exs --max-failures 1` | ⚠️ inventory Wave 0 |
| TEST-02 | Only proven duplicate target assertion removed; retained smoke/opts/byte contracts stay green | focused regression | `mix test test/rendro/recipes/themed_render_smoke_test.exs test/rendro/recipes/payslip*_test.exs test/rendro/recipes/certificate*_test.exs --max-failures 1` | ✅ source owners; ⚠️ inventory test/report |
| CI-01 | Closed inputs, full-SHA/HEAD binding, read-only pins/no secrets/caches, one valid bundle | static workflow + bundle integration | `mix test test/rendro/catalog_evidence_bundle_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` | ❌ Wave 0 |
| CI-02 | Four normalized legacy/generic pairs compare roles/hashes/authority facts; mismatch fails | comparator unit + remote evidence | `mix test test/rendro/catalog_evidence_parity_test.exs --max-failures 1`; remote paired dispatches | ❌ Wave 0 + remote matrix |
| CI-03 | `ci-success` dependencies and lane separation unchanged | guardrail | `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` | ✅ extend |
| CI-04 | No cache/secrets/writes/privilege bridge; full SHA pins, safe paths | security workflow + bundle contracts | `mix test test/rendro/catalog_evidence_bundle_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` | ❌/✅ Wave 0 |
| CI-05 | Runbook contains supported commands, identities, artifact/authority/failure language | docs contract | `mix test test/docs_contract/catalog_evidence_runbook_test.exs --max-failures 1` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** narrowest affected ExUnit command above, plus `mix format --check-formatted` for Elixir/YAML-adjacent changes. [VERIFIED: `mix.exs`]
- **Per wave merge:** `mix ci.fast`; run `mix ci` before terminal verification when the changed aliases/guardrails warrant it. [VERIFIED: `mix.exs`]
- **Parity gate:** execute the paired legacy and generic remote routes on the same full SHA, then commit the normalized four-row matrix before the deletion plan. [VERIFIED: `135-CONTEXT.md`]
- **Phase gate:** full deterministic suite green, focused negative controls demonstrated, all four remote rows matched, then dedicated cutover commit. [VERIFIED: `135-CONTEXT.md`]

### Wave 0 Gaps

- [ ] `test/rendro/catalog_evidence_bundle_test.exs` — bundle schema/path/checksum/count/duplicate/unsafe-path and operation-negative controls for CI-01/CI-04.
- [ ] `test/rendro/catalog_evidence_parity_test.exs` — normalized role/hash/authority comparator plus mismatch fixtures for CI-02.
- [ ] `test/docs_contract/catalog_evidence_runbook_test.exs` — supported operator commands and truthful authority/limit claims for CI-05.
- [ ] Extend `test/guardrails/required_checks_contract_test.exs` — generic-workflow security, `ci-success` topology, and post-cutover route absence.
- [ ] `135-test-inventory.md` — compact TEST-01/02 inventory and four-row remote parity matrix, updated only for this bounded candidate set.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | No user authentication surface. [VERIFIED: phase scope; `AGENTS.md`] |
| V3 Session Management | No | Manual GitHub dispatch uses platform authorization; no Rendro session implementation. [VERIFIED: phase scope] |
| V4 Access Control | Yes | Top-level `contents: read`, no write/secrets/privilege bridge, and graph-disconnected evidence workflow. [VERIFIED: `135-CONTEXT.md`; [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]] |
| V5 Input Validation | Yes | Closed operation enum, strict 40-lowercase-hex candidate SHA, safe relative bundle paths, exact role/count/hash validation. [VERIFIED: `135-CONTEXT.md`] |
| V6 Cryptography | Yes | OTP SHA-256 identifies payload files and pinned binary; do not hand-roll cryptography or represent hashes as signatures. [VERIFIED: `test/rendro/catalog_raster_review_test.exs`; `135-CONTEXT.md`] |

### Known Threat Patterns for GitHub Actions evidence tooling

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Candidate ref switches after dispatch | Tampering | Full SHA regex + detached checkout + literal HEAD equality. [VERIFIED: `135-CONTEXT.md`] |
| Candidate code uses persisted token/secrets | Elevation / Information disclosure | `contents: read`, `persist-credentials: false`, no secrets, no `workflow_run`, no writes. [VERIFIED: `135-CONTEXT.md`; [CITED: https://github.com/actions/checkout/blob/main/action.yml]] |
| Path traversal or extra payload injection | Tampering / Information disclosure | Closed role registry, safe-relative paths, exact uniqueness/count/hash checks, fail closed. [VERIFIED: `135-CONTEXT.md`] |
| Cache poisoning or cache-derived authority | Tampering | No cache restore/save in the manual candidate workflow; preserve ordinary CI cache trust rules separately. [VERIFIED: `135-CONTEXT.md`; `.github/workflows/ci.yml`] |
| Visual status mistaken for approval | Repudiation | Explicit candidate/canonical authority text; no scores/approval in candidate evidence; Phase 136 owns human review. [VERIFIED: `135-CONTEXT.md`] |

## Sources

### Primary (HIGH confidence)

- Repository: `.github/workflows/ci.yml`, `mix.exs`, `dev/rendro/catalog.ex`, catalog Mix tasks, `test/guardrails/required_checks_contract_test.exs`, catalog and recipe tests — implementation seams and current contract. [VERIFIED: local codebase]
- Phase 135 context, requirements, roadmap, and state — locked scope, authority boundaries, and acceptance conditions. [VERIFIED: local planning artifacts]
- Phase 122 verification — exact provenance of the themed seven-recipe smoke regression and Certificate/Payslip boundaries. [VERIFIED: local planning artifacts]

### Secondary (MEDIUM confidence)

- [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — dispatch input and permissions semantics. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
- [actions/checkout metadata](https://github.com/actions/checkout/blob/main/action.yml) — SHA `ref` and `persist-credentials` behavior. [CITED: https://github.com/actions/checkout/blob/main/action.yml]
- [actions/upload-artifact metadata](https://github.com/actions/upload-artifact/blob/main/action.yml) — retention and post-upload URL/digest outputs. [CITED: https://github.com/actions/upload-artifact/blob/main/action.yml]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing repository-owned components and no dependency additions. [VERIFIED: local codebase]
- Architecture: HIGH — locked decisions map directly to current catalog/CI seams. [VERIFIED: `135-CONTEXT.md`; local codebase]
- Pitfalls: HIGH — prior Phase 122 incident/verification plus concrete legacy workflow controls. [VERIFIED: local planning artifacts; local codebase]

**Research date:** 2026-08-27  
**Valid until:** 2026-09-26 for repository architecture; re-check GitHub Actions action metadata immediately before changing action pins. [ASSUMED]
