# Phase 13: docs-and-release-preflight-closure - Research

**Researched:** 2026-04-28
**Domain:** Elixir docs-contract verification and strict release preflight for a Hex package
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- A separately named branch-time release rehearsal command may be added later if maintainers want faster non-release feedback, but it is intentionally out of scope for Phase 13's strict `release.preflight` contract.
- Broader blanket execution of every markdown guide block remains out of scope unless a future phase explicitly chooses to turn docs into a full tutorial suite.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QUAL-02 | Maintainer can validate public docs/quickstart claims with docs-contract checks in CI. | Curated docs-contract lanes, explicit fence policy, direct semantic-claim tests, and targeted test gaps below close the current silent-skip blind spots. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: scripts/verify_docs.exs] [VERIFIED: README.md] [VERIFIED: guides/integrations.md] |
| QUAL-04 | Maintainer can run release preflight checks for version/tag parity and publish dry-run workflows. | Two-phase preflight design, subprocess/env isolation, exact tag parity, dirty-tree failure, package metadata/package build checks, and tagged clean-worktree proof close the current blocked release surface. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/mix/tasks/release/preflight.ex] [VERIFIED: mix hex.build --unpack] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure and avoid adding hard Phoenix, Oban, or admin-tooling dependencies to satisfy this phase. [VERIFIED: AGENTS.md]
- Preserve deterministic and advisory verification lane separation in CI and docs. [VERIFIED: AGENTS.md]
- Treat documentation claims as contracts and do not claim unsupported capabilities. [VERIFIED: AGENTS.md]
- Prefer optional-dependency guards for integrations instead of hard coupling. [VERIFIED: AGENTS.md]
- Respect the data-first pipeline boundary `build -> compose -> measure -> paginate -> render -> validate`. [VERIFIED: AGENTS.md]
- Treat errors and telemetry as product behavior, not optional afterthoughts. [VERIFIED: AGENTS.md]

## Summary

Phase 13 should be planned as two implementation slices plus a proof slice: first replace the current regex-and-skip docs checker with an explicit multi-lane docs contract, then rewrite `mix release.preflight` into a strict boundary-first release gate, then run clean tagged evidence capture for both surfaces. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] [VERIFIED: scripts/verify_docs.exs] [VERIFIED: lib/mix/tasks/release/preflight.ex]

The docs side is narrower than "execute all markdown." `README.md` is fully in contract today, `guides/integrations.md` has many `elixir` fences but only selected happy-path snippets should stay executable, and semantic claims such as adapter behavior or known limitations need direct ExUnit tests rather than compilation-only checks. The current script only scans `README.md`, compiles fenced `elixir` blocks, and silently treats the Phoenix `%{...}` example as "OK" after a compile error, so it cannot close `QUAL-02` truthfully. [VERIFIED: README.md] [VERIFIED: guides/integrations.md] [VERIFIED: scripts/verify_docs.exs] [VERIFIED: mix run scripts/verify_docs.exs]

The release side needs more than small edits to the current task. `mix release.preflight` currently prints the version, calls `Mix.Task.run("ci")`, does not fail on dirty state, and never reaches exact-tag or publish-dry-run parity. Separately, `mix hex.build --unpack` already fails in this workspace because `mix.exs` lacks Hex package metadata for `licenses` and `links`, so a truthful preflight plan must include package metadata repair before happy-path proof. [VERIFIED: lib/mix/tasks/release/preflight.ex] [VERIFIED: mix hex.build --unpack] [VERIFIED: mix.exs]

**Primary recommendation:** Plan Phase 13 around an explicit docs-lane contract and a subprocess-driven strict preflight gate, then prove both from a clean tagged worktree rather than from the current dirty untagged branch state. [VERIFIED: git status --short] [VERIFIED: git describe --tags --exact-match] [CITED: https://hexdocs.pm/mix/Mix.html] [CITED: https://hexdocs.pm/mix/main/Mix.Project.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Executable README contract | ExUnit/docs-contract test layer | `scripts/verify_docs.exs` entrypoint | `README.md` already contains four fenced `elixir` examples, and the current script is the active contract surface; planning should keep the contract test-owned even if the script remains the CLI entrypoint. [VERIFIED: README.md] [VERIFIED: scripts/verify_docs.exs] |
| Executable guide happy paths | Curated docs verifier | Guide source curation | `guides/integrations.md` has 13 fenced `elixir` blocks, but D-03 narrows executable coverage to selected happy paths, so ownership is classification plus verification rather than blanket execution. [VERIFIED: guides/integrations.md] [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] |
| Guide semantic claims | Direct ExUnit contract tests | Docs text | Claims about adapter behavior, failure tuples, and known limitations are better enforced by tests against live code than by compiling prose snippets. [VERIFIED: guides/integrations.md] [VERIFIED: test/rendro/adapters/threadline_test.exs] |
| Release boundary blockers | `mix release.preflight` Mix task | Git/Hex CLI subprocesses | Dirty-tree state, exact tags, env assumptions, and package/publish checks are external process facts, so the Mix task should orchestrate them and report one summary rather than emulate them. [VERIFIED: lib/mix/tasks/release/preflight.ex] [CITED: https://hexdocs.pm/mix/Mix.html] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Release happy-path proof | Clean tagged worktree | Planning verification artifacts | The current workspace is dirty and `HEAD` has no exact tag, so a truthful happy-path proof must come from isolated release-like state, not the active branch. [VERIFIED: git status --short] [VERIFIED: git describe --tags --exact-match] |

## Standard Stack

### Core

| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| ExUnit + `ExUnit.DocTest.doctest_file/1` | Elixir/ExUnit 1.19.5 | Verify `iex>` examples directly from markdown files. | Official support exists for markdown doctests, including `doctest_file "README.md"`, so Rendro should use the built-in path for `iex>` lanes instead of inventing its own parser. [VERIFIED: elixir --version] [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] |
| `Code.compile_string/2` | Elixir 1.19.5 | Compile-check curated fenced `elixir` examples that are not doctest-shaped. | The current docs checker already uses compilation, and compile-only validation is the right lane for examples that must be valid Elixir but do not need asserted output. [VERIFIED: scripts/verify_docs.exs] [CITED: https://hexdocs.pm/elixir/Code.html] |
| Mix task + subprocess orchestration | Mix 1.19.5 | Implement strict release preflight with one final summary. | `Mix.Project.cli/0` config such as `preferred_envs` is CLI-scoped, and Mix tasks run once by default, so strict release checks are safer when invoked as subprocesses from the preflight task. [VERIFIED: mix --version] [CITED: https://hexdocs.pm/mix/main/Mix.Project.html] [CITED: https://hexdocs.pm/mix/Mix.html] |

### Supporting

| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| `Mix.Shell.Process` | Mix 1.19.5 | Assert output ordering and final-exit behavior in Mix task tests. | Reuse the same output-capture pattern already used in `test/mix/tasks/verify_test.exs` for preflight summary tests. [VERIFIED: test/mix/tasks/verify_test.exs] [VERIFIED: mix --version] |
| Git CLI | 2.41.0 | Exact-tag parity, dirty-worktree detection, and clean-worktree proof setup. | Use `git describe --tags --exact-match`, `git status --short`, and `git worktree` in preflight logic and evidence capture. [VERIFIED: git --version] [VERIFIED: git describe --tags --exact-match] [VERIFIED: git status --short] |
| Hex tasks | Hex 2.4.1-otp-28 | Package build inspection and publish dry-run parity. | Use `mix hex.build --unpack` before `mix hex.publish --dry-run --yes`, because Hex explicitly recommends unpack inspection for pre-publish validation. [VERIFIED: mix help hex.publish] [VERIFIED: mix hex.build --unpack] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Mixed docs harness (`doctest_file` + compile lane + semantic tests) | Blanket markdown execution | Rejected because D-01 and D-03 intentionally keep the executable surface curated, not universal. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] |
| Direct semantic ExUnit tests for guide claims | Compile every guide fence | Rejected because compilation does not prove semantic claims such as adapter return tuples or known limitations. [VERIFIED: guides/integrations.md] [VERIFIED: test/rendro/adapters/threadline_test.exs] |
| Subprocess-driven preflight checks | In-process `Mix.Task.run("ci")` | Rejected because CLI preferred environments are documented for command-line execution, while the current in-process preflight already proved brittle in prior verification. [VERIFIED: .planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md] [CITED: https://hexdocs.pm/mix/main/Mix.Project.html] |

**Installation:** No new Hex dependencies are required for the recommended implementation. [VERIFIED: mix.exs]

**Version verification:** Elixir 1.19.5 / Mix 1.19.5 / OTP 28 / Git 2.41.0 are installed locally, and the active Hex archive is `hex-2.4.1-otp-28`. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: git --version] [VERIFIED: mix help hex.publish]

## Architecture Patterns

### System Architecture Diagram

```text
README.md / selected guide blocks / semantic claims
        |
        v
  Docs contract classifier
        |
        +--> iex> lane ----------> ExUnit.DocTest.doctest_file/1 ----------+
        |                                                                   |
        +--> fenced elixir lane --> compile/eval verifier ------------------+--> docs summary -> non-zero on failure
        |                                                                   |
        +--> semantic claim lane --> direct ExUnit tests -------------------+

git status / exact tag / env prereqs
        |
        v
release.preflight phase 1 (cheap blockers)
        |
        +--> any blocker? ---- yes ---> fail fast with boundary summary
        |
        no
        v
release.preflight phase 2 (expensive checks)
        |
        +--> mix ci
        +--> docs contract
        +--> mix hex.build --unpack
        +--> mix hex.publish --dry-run --yes
        |
        v
aggregated summary -> single final exit
```

### Recommended Project Structure

```text
test/
├── docs_contract/                 # README doctests, guide snippet checks, semantic claim tests
├── mix/tasks/                     # release.preflight and verify task regression tests
└── support/                       # helper fixtures/runners for docs and shell capture

scripts/
└── verify_docs.exs                # thin CLI entrypoint that delegates to the verified docs contract

lib/mix/tasks/release/
└── preflight.ex                   # strict two-phase release gate
```

### Pattern 1: Explicit Docs Lanes

**What:** Split docs verification into three explicit lanes: `iex>` doctests, compile-checked fenced `elixir`, and ExUnit semantic-claim tests. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]

**When to use:** Use this for every public docs surface where some examples are runnable, some are compile-only, and some statements describe behavior that should be tested directly against code. [VERIFIED: README.md] [VERIFIED: guides/integrations.md]

**Example:**

```elixir
# Source: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
defmodule ReadmeDocsTest do
  use ExUnit.Case, async: true
  doctest_file "README.md"
end
```

### Pattern 2: Boundary-First Release Gate

**What:** Phase 1 validates cheap release-state blockers together, and only if they all pass does Phase 2 run the expensive commands and aggregate their results. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md]

**When to use:** Use this for strict release commands where rerunning expensive tasks after obvious tag/dirty-state failures would waste time and blur the failure cause. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-DISCUSSION-LOG.md]

**Example:**

```elixir
# Source: repo pattern from lib/mix/tasks/verify.ex plus phase decisions
phase1 = [
  check_dirty_worktree(),
  check_exact_tag_matches_version(),
  check_release_prerequisites()
]

if Enum.any?(phase1, &match?({:error, _}, &1)) do
  print_boundary_summary(phase1)
  exit({:shutdown, 1})
end

phase2 = [
  run_cmd("mix", ["ci"]),
  run_cmd("mix", ["run", "scripts/verify_docs.exs"]),
  run_cmd("mix", ["hex.build", "--unpack"]),
  run_cmd("mix", ["hex.publish", "--dry-run", "--yes"])
]

print_summary(phase1 ++ phase2)
```

### Anti-Patterns to Avoid

- **Heuristic docs skipping:** Treating `...` or `%{...}` as an implicit pass keeps the docs contract partial by design. [VERIFIED: scripts/verify_docs.exs] [VERIFIED: mix run scripts/verify_docs.exs]
- **Single-lane markdown verification:** A compile-only lane cannot prove semantic claims such as return tuples or known limitations. [VERIFIED: guides/integrations.md] [VERIFIED: test/rendro/adapters/threadline_test.exs]
- **In-process release orchestration assumptions:** Calling `Mix.Task.run("ci")` from preflight should not be treated as equivalent to invoking `mix ci` from the CLI. This is an inference from the CLI-scope docs plus Rendro's prior blocked verification. [CITED: https://hexdocs.pm/mix/main/Mix.Project.html] [VERIFIED: .planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md]
- **Proving release semantics from a dirty branch:** The active workspace already has generated Phoenix example artifacts and no exact tag, so branch-local success would not prove D-16 through D-18. [VERIFIED: git status --short] [VERIFIED: git describe --tags --exact-match]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Markdown `iex>` parser | Custom transcript parser | `ExUnit.DocTest.doctest_file/1` | Elixir already supports markdown doctests and `iex>` / `...>` prompt handling. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] |
| Package publish simulation | Ad hoc tarball checks | `mix hex.build --unpack` and `mix hex.publish --dry-run --yes` | Hex already defines the pre-publish contract and explicitly points to unpack inspection for local validation. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Tag/version truth | Mocked version comparisons | Real `git describe --tags --exact-match` plus `Mix.Project.config()[:version]` | Release parity is a repository fact, not an internal guess. [VERIFIED: lib/mix/tasks/release/preflight.ex] [VERIFIED: git describe --tags --exact-match] |
| Semantic docs proof | Grep-based wording checks only | ExUnit tests against live APIs | Public claims like "never raises" or "timeout is audited/not audited" need runtime evidence, not prose matching. [VERIFIED: guides/integrations.md] [VERIFIED: test/rendro/adapters/threadline_test.exs] |

**Key insight:** Phase 13 should only hand-roll the curation layer that maps docs content into the right verification lane; the verification engines themselves already exist in ExUnit, Mix, Git, and Hex. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] [CITED: https://hexdocs.pm/mix/Mix.html] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

## Common Pitfalls

### Pitfall 1: Compile Success Masquerading as Contract Coverage

**What goes wrong:** A snippet compiles, but the public claim it illustrates is still untested. [VERIFIED: scripts/verify_docs.exs] [VERIFIED: guides/integrations.md]

**Why it happens:** `Code.compile_string/2` only proves syntax and compile-time availability, not runtime return shapes, telemetry effects, or documented failure tuples. [CITED: https://hexdocs.pm/elixir/Code.html]

**How to avoid:** Reserve compile-checking for fenced `elixir` validity and move claim-heavy guide sections into direct ExUnit tests. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md]

**Warning signs:** Snippets pass while docs still contain unsupported or unproven behavior statements. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]

### Pitfall 2: Treating Narrative Placeholders as Verified Examples

**What goes wrong:** `%{...}` or `...` placeholders stay in verified `elixir` fences and silently pass. [VERIFIED: README.md] [VERIFIED: scripts/verify_docs.exs] [VERIFIED: mix run scripts/verify_docs.exs]

**Why it happens:** The current script rescues compile failures and converts certain tokens into an "OK" path. [VERIFIED: scripts/verify_docs.exs]

**How to avoid:** Reclassify such snippets into `text`, `elixir-schematic`, or an explicit skip marker with a required reason, and fail if a verified fence still contains placeholders. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md]

**Warning signs:** Output includes "Code block (partial) skipped: OK" or its equivalent. [VERIFIED: mix run scripts/verify_docs.exs]

### Pitfall 3: CLI Environment Assumptions Leaking Into In-Process Mix Tasks

**What goes wrong:** `release.preflight` behaves differently from `mix ci` because it calls tasks in-process and assumes CLI env remapping still applies. [VERIFIED: lib/mix/tasks/release/preflight.ex] [VERIFIED: mix.exs]

**Why it happens:** `preferred_envs` is documented as CLI configuration, and Mix tasks are also designed to run only once unless reenabled. [CITED: https://hexdocs.pm/mix/main/Mix.Project.html] [CITED: https://hexdocs.pm/mix/Mix.html]

**How to avoid:** Run expensive release checks as subprocesses or explicitly control `MIX_ENV`/task reenabling instead of assuming task aliases behave identically in-process. [CITED: https://hexdocs.pm/mix/Mix.html]

**Warning signs:** Preflight fails before the intended parity checks or produces different behavior than direct CLI invocation. [VERIFIED: .planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md]

### Pitfall 4: Planning for a Release Happy Path Without Release State

**What goes wrong:** The implementation lands, but no truthful happy-path proof exists because the workspace is dirty or untagged. [VERIFIED: git status --short] [VERIFIED: git describe --tags --exact-match]

**Why it happens:** The repo's active branch is not a release ref, but `release.preflight` is defined as a strict tagged-release gate. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md]

**How to avoid:** Make clean tagged proof an explicit task in the plan, likely using a disposable worktree or CI release ref. [ASSUMED]

**Warning signs:** Verification only demonstrates failure modes and never exercises `mix hex.publish --dry-run --yes` from a matching `vX.Y.Z` ref. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]

## Code Examples

Verified patterns from official sources:

### Markdown Doctest Entry Point

```elixir
# Source: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html
defmodule ReadmeTest do
  use ExUnit.Case
  doctest_file "README.md"
end
```

### CLI Preferred Environments

```elixir
# Source: https://hexdocs.pm/mix/main/Mix.Project.html
def cli do
  [
    preferred_envs: [docs: :docs]
  ]
end
```

### Mix Task Output-Capture Pattern Already Used In Rendro

```elixir
# Source: test/mix/tasks/verify_test.exs
original_shell = Mix.shell()
Mix.shell(Mix.Shell.Process)

result =
  try do
    fun.()
  after
    Mix.shell(original_shell)
  end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Regex-scan fenced `elixir` blocks and silently skip partials | Explicit docs lanes: markdown doctests, curated compile/eval, semantic ExUnit tests | `doctest_file/1` available since Elixir 1.15.0. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] | Lets Rendro verify only the truthful contract surface without token heuristics. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] |
| Release task as best-effort helper | Strict tagged-release gate with boundary-first blockers and aggregated expensive checks | Locked in D-10 through D-19 on 2026-04-28. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] | Makes `mix release.preflight` meaningful evidence instead of branch-time reassurance. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-DISCUSSION-LOG.md] |
| Inspect package creation indirectly | Run `mix hex.build --unpack` before publish dry-run | Current Hex docs. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | Exposes missing package metadata and package-content drift before publish. [VERIFIED: mix hex.build --unpack] |

**Deprecated/outdated:**

- Silent "partial snippet skipped: OK" behavior is outdated for this phase and conflicts with D-05 through D-09. [VERIFIED: scripts/verify_docs.exs] [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md]
- Treating `mix release.preflight` as a loose branch helper is explicitly out of contract for Phase 13. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md]
- The current task body in `lib/mix/tasks/release/preflight.ex` is outdated relative to the locked Phase 13 release contract. [VERIFIED: lib/mix/tasks/release/preflight.ex] [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A disposable local tag in a temporary clean worktree is an acceptable way to prove the strict happy path when the active branch has no exact release tag. | Common Pitfalls / Open Questions / Environment Availability | The plan may include a proof method the maintainer does not want to use locally. |

## Open Questions (RESOLVED)

1. **Tagged happy-path proof strategy**
   - Decision: local automated verification in Phase 13 will cover the proof helper's argument validation, isolation behavior, and refusal path from the current untagged workspace. The true strict happy-path proof remains a release-grade verification step that runs only from a real exact `vX.Y.Z` ref in an isolated clean worktree or CI/release-ref context. [RESOLVED]
   - Why: `git describe --tags --exact-match` currently fails on `HEAD`, so the active workspace cannot truthfully prove D-17 or D-18. The helper should therefore make the proof path rerunnable without pretending the current branch is a release ref. [VERIFIED: git describe --tags --exact-match] [VERIFIED: git status --short]

2. **Docs-contract command surface**
   - Decision: Phase 13 should promote docs verification to a dedicated Mix task as the canonical command surface, while preserving the existing script as an implementation entrypoint or thin compatibility layer if that keeps churn low. [RESOLVED]
   - Why: both `mix verify` and `mix release.preflight` need one stable rerunnable docs gate so milestone evidence cannot drift across command paths. [VERIFIED: lib/mix/tasks/verify.ex] [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md]

3. **Threadline timeout-audit mismatch**
   - Decision: trust live code plus current guide text for Phase 13 docs-contract tests and do not reopen runtime semantics here. Any milestone-audit drift should be corrected as artifact/process follow-up rather than by broadening Phase 13 scope. [RESOLVED]
   - Why: Phase 13 is a docs/release-closure phase, and the live implementation/docs pair is the truthful contract surface to pin unless a separate runtime-fix phase is explicitly reopened. [VERIFIED: guides/integrations.md] [VERIFIED: lib/rendro/pipeline.ex] [VERIFIED: lib/rendro/adapters/threadline.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | docs verifier, Mix tasks, ExUnit tests | ✓ | 1.19.5 / OTP 28 | — [VERIFIED: elixir --version] |
| Mix | `mix verify`, `mix release.preflight`, `mix ci` | ✓ | 1.19.5 | — [VERIFIED: mix --version] |
| Git | dirty-tree and exact-tag checks | ✓ | 2.41.0 | — [VERIFIED: git --version] |
| Hex archive | `mix hex.build --unpack`, `mix hex.publish --dry-run --yes` | ✓ | 2.4.1-otp-28 | — [VERIFIED: mix help hex.publish] |
| Exact `vX.Y.Z` tag on checked-out ref | strict happy-path release proof | ✗ | — | temp clean worktree + disposable local tag, or CI release ref [ASSUMED] [VERIFIED: git describe --tags --exact-match] |
| Clean worktree | D-16 and truthful preflight proof | ✗ | — | temporary clean worktree for proof runs [ASSUMED] [VERIFIED: git status --short] |

**Missing dependencies with no fallback:**

- None at the tool level. Elixir, Mix, Git, and Hex are available. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: git --version] [VERIFIED: mix help hex.publish]

**Missing dependencies with fallback:**

- Exact release-state proof inputs are missing in the active workspace: clean tree and exact tag. Both can be supplied by an isolated worktree or CI release ref. [ASSUMED] [VERIFIED: git status --short] [VERIFIED: git describe --tags --exact-match]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit 1.19.5 [VERIFIED: elixir --version] |
| Config file | none; standard Mix/ExUnit setup via `test/test_helper.exs` [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/mix/tasks/verify_test.exs test/mix/tasks/ci_alias_contract_test.exs` for existing task patterns; add targeted Phase 13 test files and run them similarly. [VERIFIED: test/mix/tasks/verify_test.exs] [VERIFIED: test/mix/tasks/ci_alias_contract_test.exs] |
| Full suite command | `mix test` plus task proofs such as `mix run scripts/verify_docs.exs` and `mix release.preflight` from controlled worktree state. [VERIFIED: lib/mix/tasks/verify.ex] [VERIFIED: .planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QUAL-02 | README `iex>` and selected guide happy paths execute in the correct lane; schematic snippets fail or are reclassified; semantic claims stay truthful. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] | doctest + unit + integration | `mix test test/docs_contract/readme_doctest_test.exs test/docs_contract/integrations_contract_test.exs test/docs_contract/integrations_claims_test.exs -x` | ❌ Wave 0 |
| QUAL-04 | Preflight fails on dirty tree/tag mismatch/prereq gaps, then aggregates `mix ci`, docs contract, package build, and publish dry-run behind one final exit. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] | unit + task regression + manual tagged proof | `mix test test/mix/tasks/release_preflight_test.exs -x` plus controlled `mix release.preflight` proof from clean tagged worktree | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** targeted Phase 13 tests for the files being changed, plus `mix run scripts/verify_docs.exs` when docs logic or contract docs move. [VERIFIED: scripts/verify_docs.exs]
- **Per wave merge:** `mix test` and `mix release.preflight` failure-mode checks from a disposable clean worktree. [VERIFIED: .planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md]
- **Phase gate:** strict preflight happy-path proof from a clean exact-tag ref before `/gsd-verify-work`. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] [ASSUMED]

### Wave 0 Gaps

- [ ] `test/docs_contract/readme_doctest_test.exs` — proves `iex>` markdown lane for `README.md`. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]
- [ ] `test/docs_contract/integrations_contract_test.exs` — proves curated compile/eval coverage for selected `guides/integrations.md` happy paths. [VERIFIED: guides/integrations.md]
- [ ] `test/docs_contract/integrations_claims_test.exs` — proves guide semantic claims directly against adapters/runtime behavior. [VERIFIED: guides/integrations.md] [VERIFIED: test/rendro/adapters/threadline_test.exs]
- [ ] `test/mix/tasks/release_preflight_test.exs` — proves phase-1 boundary failures and phase-2 aggregated summary behavior. [VERIFIED: lib/mix/tasks/release/preflight.ex] [VERIFIED: test/mix/tasks/verify_test.exs]
- [ ] A small command-runner seam or fixture helper for preflight task tests — needed to avoid invoking real `mix hex.publish` in unit tests. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not a user-auth phase. [VERIFIED: .planning/REQUIREMENTS.md] |
| V3 Session Management | no | Not a session-bearing phase. [VERIFIED: .planning/REQUIREMENTS.md] |
| V4 Access Control | no | Scope is docs/release tooling, not runtime authorization. [VERIFIED: .planning/REQUIREMENTS.md] |
| V5 Input Validation | yes | Explicit docs-lane classification, fail on unsupported verified fences, boundary validation for release prerequisites. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] |
| V6 Cryptography | no | No new crypto surface is introduced. [VERIFIED: .planning/PROJECT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dirty worktree released as if immutable | Tampering | Fail immediately on `git status --short` output before expensive checks. [VERIFIED: lib/mix/tasks/release/preflight.ex] [VERIFIED: git status --short] |
| Tag/version spoofing | Spoofing | Require exact `git describe --tags --exact-match` parity with `Mix.Project.config()[:version]`. [VERIFIED: mix.exs] [VERIFIED: git describe --tags --exact-match] |
| Package-content drift | Tampering | Run `mix hex.build --unpack` and `mix hex.publish --dry-run --yes` from the tagged ref. [VERIFIED: mix hex.build --unpack] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Docs overclaiming unsupported behavior | Repudiation | Back public claims with explicit contract tests and keep schematic snippets out of verified `elixir` fences. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] |
| Executing broader-than-intended markdown code | Elevation of Privilege | Keep the docs contract curated; `Code.compile_string/2` and any eval lane must run only against repo-owned selected files. [CITED: https://hexdocs.pm/elixir/Code.html] [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project constraints and workflow boundaries. [VERIFIED: AGENTS.md]
- `.planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md` - locked decisions D-01 through D-21. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - `QUAL-02` and `QUAL-04` definitions. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/ROADMAP.md` - Phase 13 goal and success criteria. [VERIFIED: .planning/ROADMAP.md]
- `.planning/v1.0-MILESTONE-AUDIT.md` and `.planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md` - current gap statements and earlier proof ceiling. [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/04-quality-and-release-hardening/04-VERIFICATION.md]
- `scripts/verify_docs.exs`, `README.md`, `guides/integrations.md`, `lib/mix/tasks/release/preflight.ex`, `lib/mix/tasks/verify.ex`, `mix.exs`, `CHANGELOG.md`, `test/mix/tasks/verify_test.exs`, `test/rendro/adapters/threadline_test.exs` - live implementation surfaces. [VERIFIED: codebase grep]
- https://hexdocs.pm/ex_unit/ExUnit.DocTest.html - official doctest and `doctest_file/1` behavior. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]
- https://hexdocs.pm/mix/Mix.html - official Mix task behavior and environment docs. [CITED: https://hexdocs.pm/mix/Mix.html]
- https://hexdocs.pm/mix/main/Mix.Project.html - official `cli/0` and `preferred_envs` docs. [CITED: https://hexdocs.pm/mix/main/Mix.Project.html]
- https://hexdocs.pm/elixir/Code.html - official compile/eval semantics. [CITED: https://hexdocs.pm/elixir/Code.html]
- https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html - official Hex publish dry-run guidance. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

### Secondary (MEDIUM confidence)

- None.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - the recommended tools are either built into Elixir/Mix or already live in the repo, and official docs cover the critical behavior. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] [CITED: https://hexdocs.pm/mix/Mix.html]
- Architecture: MEDIUM - the docs-lane and two-phase preflight recommendations are strongly supported by repo state and locked decisions, but tagged happy-path proof mechanics still need a maintainer choice. [VERIFIED: .planning/phases/13-docs-and-release-preflight-closure/13-CONTEXT.md] [ASSUMED]
- Pitfalls: MEDIUM - the docs blind spots and preflight shortcomings are directly verified, but one cross-phase timeout-audit inconsistency remains unresolved between code/docs and milestone audit text. [VERIFIED: guides/integrations.md] [VERIFIED: lib/rendro/pipeline.ex] [VERIFIED: .planning/v1.0-MILESTONE-AUDIT.md]

**Research date:** 2026-04-28
**Valid until:** 2026-05-05
