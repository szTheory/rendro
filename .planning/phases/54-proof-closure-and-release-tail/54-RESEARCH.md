# Phase 54: Proof Closure and Release Tail - Research

**Researched:** 2026-05-06 [VERIFIED: current session date]
**Domain:** Proof-backed viewer promotion and Hex release-tail closure for the `protection` surface [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: codebase inspection; VERIFIED: targeted tests; CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Viewer promotion policy
- **D-01:** Keep `protection` viewer promotion **per viewer**, not all-or-nothing. If Adobe Acrobat Reader independently passes the Phase 54 checklist, promote only `adobe_acrobat_reader`; keep `apple_preview` `unverified` until it independently passes.
- **D-02:** Do not require Acrobat Reader and Apple Preview to pass in the same phase before promoting either one. That would turn proof closure into parity theater instead of evidence-first support publication.
- **D-03:** Do not leave both viewers `unverified` if one independently passes the full checklist. Rendro should publish the smallest truthful proven contract, not wait for symmetry.

### Manual proof checklist shape
- **D-04:** Use one focused lifecycle checklist for `protection`, not a minimal open-only check and not a broad compatibility matrix.
- **D-05:** The named proof items should be:
  - `opens_with_open_password`
  - `displays_authored_content_correctly`
  - `advisory_print_behavior`
  - `advisory_copy_behavior`
  - `save_and_reopen_readability`
- **D-06:** Record viewer name, version when easily available, OS, fixture path/name, date checked, per-check pass/fail, and one short notes field.
- **D-07:** Treat owner-password-only success as an **observation**, not a pass condition and not a supported viewer path. The normative public story remains open-password-first.

### Failure posture and support-matrix semantics
- **D-08:** Do not invent new public support states such as `partial`, `caveated`, or `supported_with_notes` for Phase 54.
- **D-09:** If a viewer opens the protected PDF correctly but fails an advisory-permission proof item, keep that viewer row `unverified`.
- **D-10:** Record surprising behavior in the Phase 54 validation/proof notes and, where needed, in family-level guide wording. Do not promote the viewer row anyway and do not split the canonical contract across competing status vocabularies.
- **D-11:** Preserve the existing meaning of `supported`: a named viewer passed the recorded checklist for the named surface. Do not relax that meaning for the `protection` family.

### Release-tail scope
- **D-12:** Keep `54-02` narrow: changelog readiness, release-preflight readiness, and publish-tail closure remain the core of the plan.
- **D-13:** Include one thin downstream packaging layer in the release tail: a short release-note or publish-tail callout that points Phoenix/Mailglass users to the already-canonical protected-delivery recipe from Phase 53.
- **D-14:** That downstream callout must stay a pointer, not a new integration-doc expansion. It should reinforce:
  - `render_to_artifact -> Protect.password -> store/deliver`
  - no passwords in persisted Oban args
  - Mailglass transports protected artifacts, not password material
- **D-15:** Do not reopen Phase 53 by adding new Mailglass APIs, new orchestration helpers, or a broader protected-delivery tutorial surface in Phase 54.

### Recommendation posture for downstream GSD work
- **D-16:** Shift the maintainer preference left for this and future GSD work: default to one cohesive recommendation set that optimizes for truthful small contracts, least surprise DX, and high-signal proof surfaces instead of surfacing broad menus of equivalent options.
- **D-17:** Escalate only when a choice would materially change public semantics, widen the support contract, or redefine the release/security posture in a way the maintainer is likely to care about directly.

### the agent's Discretion
- Exact proof-table formatting and terminology, as long as the checklist items above remain explicit and stable.
- Exact fixture path and proof-command wiring, as long as the proof lane stays small, reproducible, and clearly separate from structural validation.
- Exact placement of the thin protected-delivery release note, as long as it points back to the canonical Phase 53 guidance instead of forking it.

### Deferred Ideas (OUT OF SCOPE)
- A broader viewer-certification matrix covering more viewers, more permission nuances, or UI-specific warning behavior.
- Any new support-matrix public state such as `partial` or `supported_with_caveats`.
- Owner-password fallback as a promoted viewer-proof path.
- Expanded Mailglass/protected-delivery tutorial work beyond a thin release-note pointer.
- Native in-core encryption, signatures, tamper-evidence, compliance/archive claims, or other security-surface widening beyond `v1.10`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRUST-03 | New viewer rows for protection default to `unverified` until manual proof is recorded. [VERIFIED: .planning/REQUIREMENTS.md] | Use the existing `protection.viewers` rows in `priv/support_matrix.json` as the canonical truth source, keep them `unverified` until the Phase 54 checklist is recorded, and sync any promotion in the same change set with guide wording and docs-contract tests. [VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md; VERIFIED: test/docs_contract/protection_claims_test.exs] |
| RELEASE-01 | The milestone closes with release-preflight guidance and changelog/readiness updates so Rendro can be published for downstream `mailglass` consumption immediately after proof closes. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the existing `mix release.preflight` task, exact-tag worktree proof script, CI `release-proof` workflow, and `CHANGELOG.md` as the release-tail closure path; add only the narrow proof-backed packaging callout required by Phase 54 context. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs; VERIFIED: .github/workflows/ci.yml; VERIFIED: CHANGELOG.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 54 is a closure phase, not a feature phase: the roadmap already splits it into `54-01` manual viewer proof and `54-02` release-tail work, and the context explicitly forbids widening scope into native encryption, new adapter APIs, or a larger integration-doc effort. [VERIFIED: .planning/milestones/v1.10-ROADMAP.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md]

The critical planning constraint is dependency truth. Phase 54 depends on Phases 52 and 53 in the roadmap, but `.planning/STATE.md` still marks Phase 52 as the next incomplete dependency even though the worktree already contains Phase-52-shaped code and tests, including `test/rendro/adapters/protected_validation_live_test.exs`. [VERIFIED: .planning/STATE.md; VERIFIED: .planning/milestones/v1.10-ROADMAP.md; VERIFIED: git status --short; VERIFIED: test/rendro/adapters/protected_validation_live_test.exs] The planner should therefore treat viewer promotion as blocked on accepted Phase 52 completion, not silently absorb any remaining `qpdf` or Poppler implementation scope into Phase 54. [ASSUMED]

The good news is that the release-tail scaffolding already exists. The repo has a strict `mix release.preflight` task, an isolated exact-tag proof helper that creates a disposable worktree and runs `mix deps.get` plus `mix release.preflight`, targeted tests for both, and a CI `release-proof` job wired to the proof script. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs; VERIFIED: test/mix/tasks/release_preflight_test.exs; VERIFIED: test/scripts/release_preflight_proof_test.exs; VERIFIED: .github/workflows/ci.yml] Planning should focus on proof-recording, contract-sync, changelog/readiness closure, and final publish guidance rather than inventing new automation. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md; VERIFIED: lib/mix/tasks/release/preflight.ex]

**Primary recommendation:** Plan Phase 54 as two narrow slices: `54-01` records one protection-specific manual checklist and synchronizes any per-viewer promotion across `priv/support_matrix.json`, `guides/api_stability.md`, and protection docs-contract tests; `54-02` closes `CHANGELOG.md`, validates the existing release-preflight/proof path, and adds only a thin publish-note pointer back to the canonical Phase 53 integration recipe. [VERIFIED: .planning/milestones/v1.10-ROADMAP.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md; VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: CHANGELOG.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Protected fixture generation for manual proof | API / Backend | Database / Storage | Fixtures are authored and produced by Rendro runtime/test code, and may be written to disk only as proof artifacts. [VERIFIED: test/rendro/adapters/protected_validation_live_test.exs; VERIFIED: lib/rendro/protect.ex] |
| Manual viewer proof execution | Browser / Client | API / Backend | The pass/fail evidence happens in Adobe Acrobat Reader or Apple Preview, but the fixture, checklist, and resulting support-contract updates originate in the repo. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md; VERIFIED: .planning/phases/47-form-validation-and-viewer-proof-closure/47-VALIDATION.md] |
| Support-matrix and public wording sync | API / Backend | CDN / Static | `priv/support_matrix.json` and guide markdown are repo-owned contract surfaces that publish the proof result. [VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md] |
| Release preflight and tag-proof execution | API / Backend | CDN / Static | The checks are Mix tasks/scripts in the repo, while the outcome governs packaged docs and Hex artifact contents. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs; CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html; CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Publish-tail pointer for downstream users | CDN / Static | API / Backend | The release note/changelog surface is published documentation that points back to existing integration guidance rather than changing runtime behavior. [VERIFIED: CHANGELOG.md; VERIFIED: guides/integrations.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 [VERIFIED: mix --version] | Runs ExUnit, Mix tasks, docs generation, and release-preflight automation. [VERIFIED: mix --version; VERIFIED: mix.exs] | All current proof, docs-contract, and release-tail machinery in this repo is Mix-native. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: lib/mix/tasks/docs.contract.ex] |
| ExUnit | bundled with Elixir 1.19.5 [VERIFIED: mix --version; VERIFIED: test files] | Regression coverage for docs-contract, release preflight, and release-proof scripts. [VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: test/mix/tasks/release_preflight_test.exs; VERIFIED: test/scripts/release_preflight_proof_test.exs] | Existing proof lanes are already expressed as focused ExUnit slices, including opt-in live-tool tests. [VERIFIED: test/test_helper.exs; VERIFIED: test/rendro/adapters/protected_validation_live_test.exs] |
| Hex publishing tasks | Hex v2.2.1 docs current as opened [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html; CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | Defines `mix hex.build --unpack` inspection and `mix hex.publish --dry-run --yes` behavior used by release preflight. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html; CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | The repo’s `release.preflight` task directly uses the documented Hex commands rather than a custom tarball checker. [VERIFIED: lib/mix/tasks/release/preflight.ex] |
| Poppler `pdfinfo` | 26.04.0 on host [VERIFIED: pdfinfo -v] | Structural validation lane for protected PDFs and a prerequisite for Phase-52/54 proof readiness. [VERIFIED: pdfinfo -v; VERIFIED: lib/rendro/adapters/poppler.ex; VERIFIED: guides/api_stability.md] | The project’s structural lane, docs wording, and live proof path already center `pdfinfo`. [VERIFIED: guides/api_stability.md; VERIFIED: test/rendro/adapters/protected_validation_live_test.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `qpdf` CLI | not installed on this host; current manual opened at 12.3.2 docs [VERIFIED: command -v qpdf; CITED: https://qpdf.readthedocs.io/_/downloads/en/stable/pdf/] | Required to generate/viewer-proof real protected artifacts and to back the `Rendro.Adapters.Qpdf` path. [VERIFIED: lib/rendro/adapters/qpdf.ex; VERIFIED: test/rendro/adapters/protected_validation_live_test.exs] | Use in Phase 54 execution only after Phase 52 is accepted and `qpdf` is installed; otherwise plan can prepare proof docs but not execute final viewer closure. [VERIFIED: .planning/STATE.md; VERIFIED: command -v qpdf] |
| `priv/support_matrix.json` contract | repo-local [VERIFIED: priv/support_matrix.json] | Canonical machine-readable support state for `protection.viewers`. [VERIFIED: priv/support_matrix.json] | Update only when manual proof is recorded and sync the guide/tests in the same change set. [VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: guides/api_stability.md] |
| `guides/api_stability.md` + docs-contract tests | repo-local [VERIFIED: guides/api_stability.md; VERIFIED: test/docs_contract/protection_claims_test.exs] | Canonical human-readable wording for protection semantics and viewer posture. [VERIFIED: guides/api_stability.md] | Use whenever a viewer status or support boundary claim changes. [VERIFIED: test/docs_contract/protection_claims_test.exs] |
| `Mix.Tasks.Release.Preflight` + `release_preflight_proof.exs` | repo-local [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs] | Enforces clean-worktree, exact-tag, package-metadata, artifact-content, CI, docs-contract, and dry-run publish checks. [VERIFIED: lib/mix/tasks/release/preflight.ex] | Use for release-tail closure instead of inventing a separate checklist script. [VERIFIED: lib/mix/tasks/release/preflight.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing small support matrix plus per-viewer proof | A broader compatibility database or new `partial` state | Rejected by locked scope because it widens semantics and turns proof closure into taxonomy work. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md] |
| Existing `mix release.preflight` plus isolated proof script | A manual release checklist in markdown only | Worse because the repo already has executable checks and tests for them. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: test/mix/tasks/release_preflight_test.exs] |
| Runtime-generated protected proof fixtures | Checked-in protected binaries | Rejected by Phase 52 precedent because protected output is intentionally generated during proof execution, not committed as fixtures. [VERIFIED: .planning/phases/52-qpdf-adapter-and-structural-validation/52-CONTEXT.md; VERIFIED: test/rendro/adapters/protected_validation_live_test.exs] |

**Installation:**
```bash
mix deps.get
# plus host tools for execution-time proof
brew install qpdf poppler
```
[VERIFIED: mix.exs; VERIFIED: command -v pdfinfo; VERIFIED: command -v qpdf]

**Version verification:** Elixir/Mix `1.19.5` and Poppler `pdfinfo 26.04.0` were verified locally; current Hex task docs opened as `Hex v2.2.1`; `qpdf` is absent locally so only its current official manual was cited, not a host install. [VERIFIED: mix --version; VERIFIED: pdfinfo -v; VERIFIED: command -v qpdf; CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html; CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html; CITED: https://qpdf.readthedocs.io/_/downloads/en/stable/pdf/]

## Architecture Patterns

### System Architecture Diagram

```text
Rendered doc/artifact
    |
    v
Phase 52 structural proof base
(`Rendro.Protect` + qpdf + Poppler)
    |
    +--> If ADAPT-01/02 not accepted -> Phase 54 plans only; no viewer promotion
    |
    v
Representative protected fixture
    |
    v
Manual viewer checklist
(Acrobat / Preview, per viewer, per check)
    |
    +--> Any checklist failure -> keep viewer row `unverified`, record notes
    |
    +--> Full checklist pass -> promote that viewer only
    |
    v
Contract sync
(`priv/support_matrix.json` <-> `guides/api_stability.md` <-> docs-contract tests)
    |
    v
Release tail
(`CHANGELOG.md` + thin integration pointer + `mix release.preflight`)
    |
    v
Exact-tag proof in isolated worktree
(`scripts/release_preflight_proof.exs`)
    |
    v
Hex publish readiness
```
[VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md; VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs]

### Recommended Project Structure
```text
.planning/phases/54-proof-closure-and-release-tail/
├── 54-RESEARCH.md        # phase research
├── 54-VALIDATION.md      # proof lanes and manual record
└── 54-VERIFICATION.md    # final execution evidence
priv/
└── support_matrix.json   # canonical machine-readable viewer status
guides/
├── api_stability.md      # canonical protection wording
└── integrations.md       # canonical protected-delivery recipe
test/
├── docs_contract/protection_claims_test.exs
├── mix/tasks/release_preflight_test.exs
└── scripts/release_preflight_proof_test.exs
```
[VERIFIED: current repo tree; VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md; VERIFIED: guides/integrations.md]

### Pattern 1: Proof-Backed Per-Viewer Promotion
**What:** Promote `protection` support one viewer at a time, only after the full named Phase 54 checklist passes for that viewer. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md]
**When to use:** Whenever a `protection.viewers.*.status` change is proposed. [VERIFIED: priv/support_matrix.json; VERIFIED: test/docs_contract/protection_claims_test.exs]
**Example:**
```elixir
# Source: repo pattern from support_matrix + docs-contract sync
# 1. Run/record the manual checklist for one named viewer.
# 2. Promote only that viewer row in priv/support_matrix.json.
# 3. Update guides/api_stability.md wording to match.
# 4. Update protection docs-contract assertions in the same change set.
```
[VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md; VERIFIED: test/docs_contract/protection_claims_test.exs]

### Pattern 2: Executable Release Tail, Not Narrative-Only Release Notes
**What:** Treat release readiness as an executable gate using `mix release.preflight` and the isolated exact-tag proof script. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs]
**When to use:** After viewer-proof closure and before any actual tag/publish step. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md]
**Example:**
```bash
# Source: repo release-proof path
mix release.preflight
mix run scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-release-proof
```
[VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs]

### Anti-Patterns to Avoid
- **Absorbing Phase 52 into Phase 54:** Do not treat missing `qpdf` setup or unfinished ADAPT-01/02 acceptance as hidden Phase 54 work. [VERIFIED: .planning/STATE.md; VERIFIED: command -v qpdf]
- **Open-only viewer promotion:** Passing “opens with password” alone is explicitly insufficient; advisory print/copy behavior failures keep the row `unverified`. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md]
- **Forking the integration story:** Do not create a second protected-delivery tutorial in the release tail; point back to `guides/integrations.md`. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md; VERIFIED: guides/integrations.md]
- **Manual release checklist drift:** Do not replace executable release preflight with prose-only instructions. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: test/mix/tasks/release_preflight_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Viewer support taxonomy | New `partial` / caveated status model | Existing `supported | unsupported | unverified` matrix shape | Locked scope explicitly forbids widening the vocabulary. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md; VERIFIED: priv/support_matrix.json] |
| Release package inspection | Custom tarball parsing script | `mix hex.build --unpack` inside `mix release.preflight` | Hex already documents unpack inspection, and the repo already tests this path. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html; VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: test/mix/tasks/release_preflight_test.exs] |
| Dry-run publish logic | Ad hoc shell publish simulation | `mix hex.publish --dry-run --yes` inside `mix release.preflight` | Hex documents dry-run local checks, and the repo already codifies them. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html; VERIFIED: lib/mix/tasks/release/preflight.ex] |
| Release isolation | Running preflight against the dirty active workspace | `scripts/release_preflight_proof.exs` exact-tag worktree proof | The existing proof script already guards against active-workspace reuse and restores tag state. [VERIFIED: scripts/release_preflight_proof.exs; VERIFIED: test/scripts/release_preflight_proof_test.exs] |
| Protected proof fixture storage | Checked-in protected PDFs | Runtime-generated protected fixtures | Phase 52 precedent keeps protected outputs generated during proof execution because the protected surface is not the committed source artifact. [VERIFIED: .planning/phases/52-qpdf-adapter-and-structural-validation/52-CONTEXT.md; VERIFIED: test/rendro/adapters/protected_validation_live_test.exs] |

**Key insight:** Phase 54 already has the right closure primitives; planning quality depends on sequencing and contract sync, not on adding new mechanisms. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md]

## Common Pitfalls

### Pitfall 1: Treating Nearby Code as Accepted Dependency Closure
**What goes wrong:** A planner sees Phase-52-shaped code/tests in the worktree and assumes Phase 54 can promote viewers immediately. [VERIFIED: git status --short; VERIFIED: test/rendro/adapters/protected_validation_live_test.exs]
**Why it happens:** `.planning/STATE.md` still records Phase 52 as incomplete while the working tree contains in-progress implementation. [VERIFIED: .planning/STATE.md; VERIFIED: git status --short]
**How to avoid:** Add an explicit dependency gate in the plan: no proof-backed promotion until ADAPT-01/02 are accepted and the protected fixture path is trustworthy. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: .planning/milestones/v1.10-ROADMAP.md]
**Warning signs:** `qpdf` missing locally, dirty working tree, or proof commands described as “future” rather than accepted. [VERIFIED: command -v qpdf; VERIFIED: git status --short]

### Pitfall 2: Promoting a Viewer on Open Success Alone
**What goes wrong:** A viewer opens the file but ignores advisory permission behavior, and the plan still marks it supported. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md]
**Why it happens:** Teams collapse password-to-open, advisory permissions, and general viewer compatibility into one “works” outcome. [CITED: https://qpdf.readthedocs.io/_/downloads/en/stable/pdf/; VERIFIED: guides/api_stability.md]
**How to avoid:** Record all five named checks and keep any failing viewer `unverified`. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md]
**Warning signs:** Notes mention “opened fine” but omit print/copy/save behavior, or propose a `partial` state. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md]

### Pitfall 3: Letting Contract Surfaces Drift After Manual Proof
**What goes wrong:** Validation notes are updated but `priv/support_matrix.json`, `guides/api_stability.md`, and protection docs-contract tests disagree. [VERIFIED: priv/support_matrix.json; VERIFIED: guides/api_stability.md; VERIFIED: test/docs_contract/protection_claims_test.exs]
**Why it happens:** Manual proof feels “outside the code,” so the planner under-specifies the sync work. [ASSUMED]
**How to avoid:** Make contract sync a required same-slice task with docs-contract verification. [VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: scripts/verify_docs.exs]
**Warning signs:** Validation record shows a pass but tests still assert both protection viewers remain `unverified`. [VERIFIED: test/docs_contract/protection_claims_test.exs]

### Pitfall 4: Running Release Proof from the Active Workspace
**What goes wrong:** Dirty files or the wrong ref invalidate release confidence. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs]
**Why it happens:** Preflight is run manually on the current checkout instead of through the exact-tag isolated-worktree path. [VERIFIED: scripts/release_preflight_proof.exs]
**How to avoid:** Use `--current-version-tag` with an isolated worktree only after the changelog and proof closure are ready. [VERIFIED: scripts/release_preflight_proof.exs; VERIFIED: test/scripts/release_preflight_proof_test.exs]
**Warning signs:** `git status --short` is non-empty or `git describe --tags --exact-match` would fail. [VERIFIED: git status --short; VERIFIED: lib/mix/tasks/release/preflight.ex]

## Code Examples

Verified patterns from official and repo sources:

### Protection Contract Sync Gate
```bash
# Source: repo docs-contract lane
mix test test/docs_contract/protection_claims_test.exs
mix docs.contract
```
[VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: lib/mix/tasks/docs.contract.ex; VERIFIED: scripts/verify_docs.exs]

### Release-Tail Proof Gate
```bash
# Source: repo release-proof path
mix test test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs
mix run scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-release-proof
```
[VERIFIED: test/mix/tasks/release_preflight_test.exs; VERIFIED: test/scripts/release_preflight_proof_test.exs; VERIFIED: scripts/release_preflight_proof.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Blanket or implied viewer support | Per-surface, per-viewer promotion backed by recorded checklists | Established by Phases 47, 50, and 53 proof surfaces. [VERIFIED: .planning/phases/47-form-validation-and-viewer-proof-closure/47-VALIDATION.md; VERIFIED: .planning/phases/50-support-boundary-and-proof-closure/50-CONTEXT.md; VERIFIED: .planning/phases/53-delivery-threading-and-truthful-support-contract/53-VALIDATION.md] | Phase 54 should promote only independently proven viewers, not seek parity. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md] |
| Manual release checklist only | Executable `release.preflight` plus exact-tag isolated worktree proof | Present in repo on 2026-05-06. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs] | Release-tail planning can focus on readiness inputs rather than inventing new checks. [VERIFIED: lib/mix/tasks/release/preflight.ex] |
| Broad “secure PDF” shorthand | Narrow password-to-open plus advisory-permissions wording | Current public guide explicitly uses narrow protection language. [VERIFIED: guides/api_stability.md] | Phase 54 proof notes and release notes must preserve this wording discipline. [VERIFIED: guides/api_stability.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md] |

**Deprecated/outdated:**
- “All protection viewers remain `unverified`” becomes outdated the moment a Phase 54 checklist promotes a viewer; the plan must update both the docs-contract assertion and guide wording in the same slice. [VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: guides/api_stability.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phase 54 should create/update `54-VALIDATION.md` and likely `54-VERIFICATION.md` following the repo’s prior phase pattern. [ASSUMED] | Recommended Project Structure / Validation Architecture | Low; if the project uses a different closure artifact, only the planning-document path changes. |

## Open Questions (RESOLVED)

1. **What is the accepted Phase 52 truth at plan time?**
   - What we know: `.planning/STATE.md` says Phase 52 is still incomplete, but the worktree includes Phase-52-shaped code and a live-tool test file. [VERIFIED: .planning/STATE.md; VERIFIED: git status --short; VERIFIED: test/rendro/adapters/protected_validation_live_test.exs]
   - Resolved: The plans do **not** assume Phase 52 is already accepted. `54-01-PLAN.md` carries an explicit dependency gate: no viewer-promotion execution proceeds until ADAPT-01/02 are accepted and the protected-fixture path is live, including `qpdf` availability. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-01-PLAN.md]

2. **Which protection viewer, if any, is expected to promote in this phase?**
   - What we know: Locked decisions allow per-viewer promotion and explicitly reject all-or-nothing parity. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md]
   - Resolved: The plans intentionally leave the execution outcome open. They require independent per-viewer checklist recording and same-change-set contract sync so Phase 54 can truthfully end with Acrobat only, Preview only, both, or neither promoted, depending on the recorded evidence. [VERIFIED: priv/support_matrix.json; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-01-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, tests, scripts | ✓ [VERIFIED: elixir/mix probe] | 1.19.5 [VERIFIED: mix --version] | — |
| Mix | Release preflight, docs-contract, tests | ✓ [VERIFIED: mix --version] | 1.19.5 [VERIFIED: mix --version] | — |
| Poppler `pdfinfo` | Structural validation readiness and live protected proof | ✓ [VERIFIED: pdfinfo -v] | 26.04.0 [VERIFIED: pdfinfo -v] | For planning only, structural-lane details can still be documented without rerunning the tool. [VERIFIED: .planning/phases/52-qpdf-adapter-and-structural-validation/52-CONTEXT.md] |
| `qpdf` | Real protected artifact generation and viewer-proof execution | ✗ [VERIFIED: command -v qpdf] | — | No execution fallback for real protected viewer proof; planner must preserve this as a precondition or dependency on Phase 52 completion. [VERIFIED: command -v qpdf; VERIFIED: .planning/STATE.md] |
| Git worktree/tag support | Isolated release proof | ✓ [VERIFIED: git status --short; VERIFIED: test/scripts/release_preflight_proof_test.exs] | repo-local git available [VERIFIED: git status --short] | — |

**Missing dependencies with no fallback:**
- `qpdf` is missing locally, so the final protected viewer-proof execution path cannot run on this machine until it is installed. [VERIFIED: command -v qpdf]

**Missing dependencies with fallback:**
- None. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Mix task/script tests + docs-contract task. [VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: test/mix/tasks/release_preflight_test.exs; VERIFIED: lib/mix/tasks/docs.contract.ex] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/docs_contract/protection_claims_test.exs test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs`. [VERIFIED: current session targeted test run passed] |
| Full suite command | `mix test test/docs_contract/protection_claims_test.exs test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs && mix docs.contract`. [VERIFIED: scripts/verify_docs.exs; VERIFIED: lib/mix/tasks/docs.contract.ex] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TRUST-03 | Protection viewer rows stay `unverified` until a recorded manual checklist justifies promotion, and guide wording stays in sync. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: test/docs_contract/protection_claims_test.exs] | docs-contract + manual proof | `mix test test/docs_contract/protection_claims_test.exs` for automated contract drift, plus manual checklist execution recorded in `54-VALIDATION.md`. [VERIFIED: test/docs_contract/protection_claims_test.exs; ASSUMED: 54-VALIDATION.md path] | ✅ automated file exists / ❌ phase record not yet created. [VERIFIED: test/docs_contract/protection_claims_test.exs; VERIFIED: ls .planning/phases/54-proof-closure-and-release-tail] |
| RELEASE-01 | Release-preflight guidance, changelog readiness, and exact-tag proof path are correct before publish. [VERIFIED: .planning/REQUIREMENTS.md] | unit/script + manual exact-tag proof | `mix test test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs` during implementation, then `mix run scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-release-proof` at phase gate on a clean exact-tag state. [VERIFIED: test/mix/tasks/release_preflight_test.exs; VERIFIED: test/scripts/release_preflight_proof_test.exs; VERIFIED: scripts/release_preflight_proof.exs] | ✅ |

### Sampling Rate
- **Per task commit:** `mix test test/docs_contract/protection_claims_test.exs test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs`. [VERIFIED: current session targeted test run passed]
- **Per wave merge:** `mix docs.contract` after any contract-surface edits. [VERIFIED: scripts/verify_docs.exs]
- **Phase gate:** Run the exact-tag isolated release proof only after the worktree is clean and the current version tag exists or is synthesized by the script. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs]

### Wave 0 Gaps
- [ ] Create `54-VALIDATION.md` with the five required protection checks and per-viewer evidence table. [VERIFIED: ls .planning/phases/54-proof-closure-and-release-tail; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md]
- [ ] Add/update docs-contract assertions for the post-proof viewer state instead of the current “both unverified” baseline. [VERIFIED: test/docs_contract/protection_claims_test.exs]
- [ ] Decide whether to add a small test locking the Phase 54 changelog/publish-tail pointer wording if release-note drift risk is considered high. [ASSUMED]
- [ ] `qpdf` install or confirmed upstream Phase 52 completion before execution of the live protected viewer-proof lane. [VERIFIED: command -v qpdf; VERIFIED: .planning/STATE.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: phase scope] | Not part of this library release-tail phase. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md] |
| V3 Session Management | no [VERIFIED: phase scope] | Not part of this library release-tail phase. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md] |
| V4 Access Control | no [VERIFIED: phase scope] | No server-side authorization surface is introduced here. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md] |
| V5 Input Validation | yes [VERIFIED: scripts/release_preflight_proof.exs; VERIFIED: lib/mix/tasks/release/preflight.ex] | Keep exact-tag/ref and worktree validation in the existing release-proof script; do not bypass clean-worktree or exact-tag checks. [VERIFIED: scripts/release_preflight_proof.exs; VERIFIED: lib/mix/tasks/release/preflight.ex] |
| V6 Cryptography | yes [VERIFIED: phase domain] | Preserve the narrow artifact-first `qpdf` protection contract and the guide’s distinction between password-to-open, advisory permissions, and unsupported narratives. [VERIFIED: guides/api_stability.md; CITED: https://qpdf.readthedocs.io/_/downloads/en/stable/pdf/] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overclaiming advisory permissions as hard security | Spoofing | Keep guide wording narrow and require the full five-check viewer checklist before promotion. [VERIFIED: guides/api_stability.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md] |
| Secret leakage in proof notes or release docs | Information Disclosure | Reuse the existing password-redaction posture; record only viewer/version/OS/fixture/date/check results/short notes. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md; VERIFIED: .planning/phases/52-qpdf-adapter-and-structural-validation/52-CONTEXT.md] |
| Dirty-worktree or wrong-tag release proof | Tampering | Keep `mix release.preflight` clean-worktree and exact-tag checks, then run the isolated worktree proof helper. [VERIFIED: lib/mix/tasks/release/preflight.ex; VERIFIED: scripts/release_preflight_proof.exs] |
| Owner-password fallback misread as normative support | Repudiation | Treat owner-only success as observation only, never as a supported viewer path. [VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md; VERIFIED: guides/api_stability.md; CITED: https://qpdf.readthedocs.io/_/downloads/en/stable/pdf/] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md` - locked scope, proof checklist, release-tail constraints. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - `TRUST-03` and `RELEASE-01`. [VERIFIED: local file]
- `.planning/STATE.md` - dependency status showing Phase 52 still incomplete. [VERIFIED: local file]
- `.planning/milestones/v1.10-ROADMAP.md` - phase split and dependencies. [VERIFIED: local file]
- `priv/support_matrix.json` - current `protection` family and `unverified` viewer rows. [VERIFIED: local file]
- `guides/api_stability.md` and `guides/integrations.md` - current public protection and delivery wording. [VERIFIED: local files]
- `lib/mix/tasks/release/preflight.ex` and `scripts/release_preflight_proof.exs` - executable release-tail machinery. [VERIFIED: local files]
- `test/docs_contract/protection_claims_test.exs`, `test/mix/tasks/release_preflight_test.exs`, `test/scripts/release_preflight_proof_test.exs` - current automated guardrails. [VERIFIED: local files]
- Current targeted run: `mix test test/docs_contract/protection_claims_test.exs test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs` -> `13 tests, 0 failures` on 2026-05-06. [VERIFIED: current session targeted test run]

### Secondary (MEDIUM confidence)
- Hex `mix hex.build` docs - documented `--unpack` inspection workflow. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html]
- Hex `mix hex.publish` docs - documented `--dry-run`, docs generation, and publish behavior. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- Hex publish guide - recommends local docs build before publishing and explains package/doc publish flow. [CITED: https://hex.pm/docs/publish]
- qpdf stable manual - current password semantics and advisory-permission caveats. [CITED: https://qpdf.readthedocs.io/_/downloads/en/stable/pdf/]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - mostly repo-local and locally probed, with Hex/qpdf behavior cross-checked against official docs. [VERIFIED: mix.exs; VERIFIED: mix.lock; VERIFIED: environment probe; CITED: official docs above]
- Architecture: HIGH - Phase 54 follows established repo proof/release patterns visible across Phases 47, 50, 53 and current release tooling. [VERIFIED: 47-VALIDATION.md; VERIFIED: 50-CONTEXT.md; VERIFIED: 53-VALIDATION.md; VERIFIED: lib/mix/tasks/release/preflight.ex]
- Pitfalls: HIGH - derived from explicit state mismatch, locked scope, and existing test/contract surfaces. [VERIFIED: .planning/STATE.md; VERIFIED: .planning/phases/54-proof-closure-and-release-tail/54-CONTEXT.md; VERIFIED: test/docs_contract/protection_claims_test.exs]

**Research date:** 2026-05-06 [VERIFIED: current session date]
**Valid until:** 2026-06-05 for repo-local planning assumptions; re-check official Hex/qpdf docs if release-tail work starts later or if host-tool availability changes. [VERIFIED: stable local sources; CITED: official docs above]
