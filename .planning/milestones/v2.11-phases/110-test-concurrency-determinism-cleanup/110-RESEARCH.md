# Phase 110: Test Concurrency, Determinism & Cleanup - Research

**Researched:** 2026-06-15
**Domain:** Elixir/ExUnit Test Concurrency, Determinism & Pipeline
**Confidence:** HIGH

## Summary

The Phase 110 boundary focuses on safely maximizing `async: true` across the test suite, rejecting the overhead of multi-runner partitioning (`mix test --partitions N`), and establishing a dedicated nightly quarantine lane (`mix verify.flake`) for non-deterministic tests. A critical blocker to maximizing `async: true` is `DocsContract.evaluate!/2`, which evaluates docstrings and requires a structural guarantee that it cannot write to the filesystem. Additionally, `RecipesFacadeDriftTest` (a known ordering-dependent test) will be moved into the quarantine lane to unblock the PR gate.

**Primary recommendation:** Convert `DocsContract.evaluate!/2` to parse the Elixir AST and explicitly block `File`, `System.cmd`, and `Mix.Task` mutations before evaluation, thereby safely unlocking `async: true` for the contract suites.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** **Rely entirely on maximizing `async: true` modules.** Do NOT adopt `mix test --partitions N`. For a pure-Elixir library without heavy Ecto sandboxing, partitioning across multiple CI runners adds overhead (booting BEAM/downloading deps) without sufficient wall-clock benefit.
- **D-02:** **Establish the `mix verify.flake` nightly quarantine lane first**, adhering strictly to the `threadline` OSS DNA pattern.
- **D-03:** Once the nightly lane is in place, move the known `RecipesFacadeDriftTest` seed failure into it to quarantine it safely. The flake is seed-dependent and ordering-artifact related, not a random failure. It will be fixed within the structure of that lane, rather than holding up the main PR gate or relying on blind retries.
- **D-04:** **Refactor `DocsContract.evaluate!/2` to guarantee it only reads, then flip all 10+ contract tests to `async: true`.** Reading `priv/` json and markdown files is inherently parallelizable. Enforce a structural guarantee that the contract evaluator never writes to disk during test execution to prevent race conditions.

### the agent's Discretion
None - instructions were prescriptive based on the C1 audit.

### Deferred Ideas
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEST-01 | Every safely-isolatable test module runs `async: true`; non-async carries a documented reason. | AST-checking `DocsContract.evaluate!/2` allows flipping doc-contract tests. Analysis of `IntegrationsContractTest` confirms its PID-keyed ETS table is safe for `async: true`. |
| TEST-02 | A measured decision on `mix test --partitions N` is made. | Locked decision D-01 explicitly rejects partitions in favor of maximizing `async: true` for pure-Elixir. |
| TEST-03 | Flaky / nondeterministic tests are fixed or explicitly quarantined with tracked remediation. | D-02 and D-03 dictate moving `RecipesFacadeDriftTest` into a new `mix verify.flake` quarantine lane. |
| TEST-04 | Low-signal tests are removed or rewritten with evidence. | Phase 108 found no low-signal filler tests; all run meaningful code/assertions. |
| TEST-05 | Slowest tests are reported, and the live-proof suites are correctly layered. | Phase 108 identified `release-proof` and docs tests as the slowest. Phase 110 will re-evaluate shared hex.build costs in setups. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Concurrency Isolation | ExUnit Runner | Test Setup | `async: true` relies on ExUnit isolation; setups must avoid global app env state and fixed filesystem paths. |
| Docs Contract Safety | `DocsContract.evaluate!/2` | `Code` (Elixir) | The evaluator is uniquely responsible for assuring evaluated snippets don't mutate state. |
| Flake Quarantine | CI Topology / Mix Aliases | ExUnit Tags | The nightly `mix verify.flake` lane provides a structural location for `moduletag :quarantine`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | ~> 1.15 | Test Execution | Standard Elixir testing framework; provides robust concurrent running via `async: true`. |
| Mix | ~> 1.15 | Task Aliases | Using `mix verify.flake` allows defining custom test entrypoints easily. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Live service config | ETS Table `:rendro_threadline_calls` | **No action / Safe**. Verified that access is completely PID-keyed to the calling test process, meaning `IntegrationsContractTest` can be safely flipped to `async: true`. |
| Secrets/env vars | `Application.put_env(:rendro, ...)` in adapter tests | **Keep `async: false`**. Setting global config (e.g. `pdfium-cli` paths) affects the whole VM. |
| Build artifacts | `System.cmd("mix", ["hex.build"])` in claims tests | **Keep `async: false`** or serialize. `mix hex.build` writes to `_build`/`_hex` project-wide and is fundamentally concurrency-unsafe. |

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages.
*No external packages are installed in this phase.*

## Code Examples

### DocsContract Structural Guarantee (AST Check)
To satisfy D-04 ("guarantee it only reads"), the contract evaluator must parse Elixir AST to block file system writes before running `Code.eval_quoted`:

```elixir
def evaluate!(code, file) do
  ast = Code.string_to_quoted!("import ExUnit.Assertions\n#{code}")

  # Walk the AST and reject any nodes that look like File.write or System.cmd
  Macro.prewalk(ast, fn
    {{:., _, [{:__aliases__, _, [:File]}, func]}, _, _} = node
      when func in [:write, :write!, :rm, :rm!, :rm_rf, :mkdir, :mkdir!, :cp, :cp!] ->
      raise "Docs contract evaluator cannot perform File.#{func} writes"

    {{:., _, [{:__aliases__, _, [:System]}, cmd]}, _, _} = node
      when cmd in [:cmd] ->
      raise "Docs contract evaluator cannot run System.#{cmd}"

    {{:., _, [{:__aliases__, _, [:Mix, :Task]}, run]}, _, _} = node
      when run in [:run, :clear] ->
      raise "Docs contract evaluator cannot invoke Mix.Task.#{run}"

    node ->
      node
  end)

  Code.eval_quoted(ast, [], file: file)
end
```

## Architecture Patterns

### Threadline Pattern: Flake Quarantine Lane
Instead of using `mix test --repeat-until-failure` blindly in PRs to hide flakes, Rendro adopts the `threadline` OSS DNA:
1. Flaky tests receive `@moduletag :quarantine`.
2. The main CI gate (`mix ci`) excludes them via `mix test --exclude quarantine`.
3. A separate GitHub Action (nightly) runs `mix verify.flake` to intentionally stress the quarantined tests and gather metrics.
4. `RecipesFacadeDriftTest` will be the first test to enter this lane.

### Anti-Patterns to Avoid
- **Anti-pattern:** Firing `mix test --partitions 4` on GitHub Actions runners for a fast-compiling Elixir project.
  - **Why it's bad:** Booting 4 VMs, fetching deps 4 times, and compiling the app 4 times costs more wall-clock than it saves. ExUnit `async: true` provides superior intra-VM concurrency with zero duplicate setup cost.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Enforcing Read-Only Evaluation | Mocking the `File` module globally | `Macro.prewalk/2` on the Elixir AST | Global mocks break concurrent tests. AST introspection strictly statically verifies the snippet code before running it. |
| Test Concurrency | CI Partitioning Scripts | ExUnit `async: true` | In a pure Elixir project, intra-node concurrency leverages BEAM schedulers correctly without duplicating repo checkout/compile overhead. |

## Common Pitfalls

### Pitfall 1: Assuming `function_exported?/3` is safe for async
**What goes wrong:** `function_exported?/3` returns `false` if the module hasn't been loaded into the BEAM yet. In ExUnit, tests are randomized (seeded).
**Why it happens:** If a test runs first, the module isn't loaded. If it runs later, another test loaded it.
**How to avoid:** Always use `Code.ensure_loaded!(Module)` before checking `function_exported?`. (For `RecipesFacadeDriftTest`, we quarantine first per D-03, then fix).

### Pitfall 2: Confusing PID-keyed ETS with Global State Risk
**What goes wrong:** Leaving tests `async: false` because they use a named ETS table.
**Why it happens:** A named ETS table is technically a global resource.
**How to avoid:** Check if the table access strictly filters by the caller's PID (e.g., `test_pid()`). If so (as in `Rendro.Test.Mocks`), the test is safe to run `async: true`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / OTP | Core Execution | ✓ | >= 1.15 | — |
| pdfium-cli | Raster snapshot tests | ✓ | 1.x | Skip snapshot tests |
| poppler | Comparison tests | ✓ | 22.x | Skip comparison tests |

*All non-Elixir dependencies are isolated in `continue-on-error: true` advisory workflows, meaning they do not affect the main concurrent test suite.*

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test --include quarantine` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEST-01 | Evaluate! enforces read-only | unit | `mix test test/support/docs_contract.ex` | ❌ Wave 0 (needs test) |
| TEST-03 | RecipesFacade drift quarantined | smoke | `mix verify.flake` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/support/docs_contract_test.exs` — covers TEST-01 (must verify that the AST blocker properly throws on `File.write`, etc.)
- [ ] `mix verify.flake` alias definition in `mix.exs`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | AST-checking `Code.eval_quoted` |

### Known Threat Patterns for Testing

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Code execution escapes bounds in docs | Elevation of Privilege | AST validation explicitly denying `System.cmd` and `File.write` before `eval_quoted`. |

## Assumptions Log
| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | None - all facts gathered | All | N/A |

## Sources

### Primary (HIGH confidence)
- `108-EVIDENCE.md` and `108-RESEARCH.md` — Test baseline and residue `async: false` human readings.
- `.planning/phases/110-test-concurrency-determinism-cleanup/110-CONTEXT.md` — Provided strict phase boundaries and explicit constraints (D-01 to D-04).
- `test/support/mocks.ex` — Verified that `:rendro_threadline_calls` ETS table is keyed entirely by test PIDs.
