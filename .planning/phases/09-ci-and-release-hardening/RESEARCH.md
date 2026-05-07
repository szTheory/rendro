# Phase 9: CI Scheduler + Release Hardening - Research

**Researched:** [date]
**Domain:** CI/CD and Release Process
**Confidence:** HIGH

## Summary

This phase establishes a robust Continuous Integration (CI) pipeline and hardens the release process. Currently, CI relies on local execution of `mix ci` which is incomplete. Verification steps have brittle assertions causing unhandled MatchErrors, and the docs contract silently ignores partial code snippets. Furthermore, the `release.preflight` task skips actual tag checks and publish dry-runs. We need to implement a GitHub Actions workflow, enhance `mix ci`, handle verification errors gracefully, warn for partial snippets in docs, and lock down the preflight release workflow.

**Primary recommendation:** Use GitHub Actions with `erlef/setup-beam` for CI, patch local Mix tasks to safely handle exit codes, and enforce version control and registry publish dry-runs on releases.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CI Pipeline | External (GitHub) | — | Code verification and quality gates |
| Core Validation | Mix Tasks | — | Elixir standard tooling (`mix ci`) for compile, test, format, docs, hex |
| Advisory Validation | Mix Tasks | Scripts | Integration tests (`mix verify`, `verify_docs.exs`) |
| Release Guarding | Mix Tasks | Git/Hex | Preflight hooks before finalizing release |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GitHub Actions | v4 | CI Runner | Industry standard, free for open source, native repository integration |
| erlef/setup-beam | v1.18+ | OTP/Elixir setup | Standard GitHub Action for provisioning Erlang/Elixir environments |
| mix | 1.19 | Build Tool | Native build tool for Elixir, owns `mix ci`, `compile`, `test`, `format`, `docs`, `hex.build` |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | All tasks | ✓ | 1.19.5 | — |
| Git | Release preflight | ✓ | — | — |
| GitHub Actions | CI Scheduler | ✓ (Remote) | — | — |

## Architecture Patterns

### Recommended Project Structure
```
.github/workflows/
└── ci.yml           # Runs `mix ci` on push and PRs
```

### Pattern 1: CI Workflow Execution
**What:** Automating standard checks on every commit via `.github/workflows/ci.yml`.
**When to use:** On `push` and `pull_request` to `main`.
**Example:**
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: '28'
          elixir-version: '1.19.5'
      - run: mix deps.get
      - run: mix ci
```

### Pattern 2: Graceful Subprocess Execution in Mix
**What:** Capturing exit codes instead of exact matching `{_, 0} = System.cmd(...)`.
**When to use:** When running dependent commands in `mix verify` or `release.preflight` that may fail and should result in informative errors.
**Example:**
```elixir
case System.cmd("mix", ["compile"]) do
  {_output, 0} -> :ok
  {_output, code} -> exit({:shutdown, code})
end
```

### Anti-Patterns to Avoid
- **Uncaught `MatchError`:** Expecting `{_, 0}` from `System.cmd` without a `case` or `try` block crashes the VM and masks the actual command failure logic.
- **Silently Skipping Warnings:** Ignoring bad or partial code blocks in documentation silently reduces coverage without notifying the author.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CI System | Local git hooks | GitHub Actions | Centralized, reproducible, prevents "works on my machine" bypass |
| Hex Publishing Prep | Custom zipping | `mix hex.build` / `mix hex.publish --dry-run` | Native hex tooling covers all validation and package metadata checks |

## Common Pitfalls

### Pitfall 1: Incomplete Advisory Verification (`mix verify`)
**What goes wrong:** `mix compile` in the Phoenix example fails because dependencies are not fetched, or crashes with a `MatchError` on failure.
**Why it happens:** Subdirectories need their own `deps.get` context. Pattern matching exact successful returns crashes unexpectedly on failure.
**How to avoid:** Run `System.cmd("mix", ["deps.get"])` before `mix compile`, and explicitly handle the non-zero tuple instead of doing `{_, 0} = ...`.

### Pitfall 2: Silently Skipping Documentation Validation
**What goes wrong:** `verify_docs.exs` silently ignores blocks with `...` or `%{...}`.
**Why it happens:** Elixir compiler fails on `...` as incomplete syntax. The rescue block just logs "Code block (partial) skipped: OK".
**How to avoid:** Instead of completely ignoring it, print a warning to standard output so developers know which blocks are unverified, or replace `...` and `%{...}` with valid syntax before compilation (e.g. `String.replace(code, "...", "nil")`). At minimum, `Mix.shell().info("  - Warning: Code block (partial) skipped")` should be used.

### Pitfall 3: Git Tag Mismatches During Release
**What goes wrong:** Releasing version `0.1.0` while git is tagged `0.1.1` or untagged.
**Why it happens:** Missing explicit check.
**How to avoid:** Use `git describe --tags --exact-match` or similar to get the current tag and assert it matches `"v" <> Mix.Project.config()[:version]`.

## Code Examples

### Graceful System Command in Elixir
```elixir
# lib/mix/tasks/verify.ex
File.cd!("examples/phoenix_example", fn ->
  {_, 0} = System.cmd("mix", ["deps.get"])
  case System.cmd("mix", ["compile"]) do
    {_, 0} -> :ok
    {_, code} -> exit({:shutdown, code})
  end
end)
```

### Checking Git Tag
```elixir
# lib/mix/tasks/release/preflight.ex
version = Mix.Project.config()[:version]
expected_tag = "v" <> version
case System.cmd("git", ["describe", "--tags", "--exact-match"]) do
  {output, 0} ->
    tag = String.trim(output)
    if tag != expected_tag, do: Mix.raise("Git tag #{tag} does not match version #{expected_tag}!")
  {_, _} ->
    Mix.raise("No matching git tag found for version #{expected_tag}!")
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Local `mix ci` alone | GitHub Actions + `mix ci` | Now | Forces CI checks on all collaborative PRs |
| Exact matching `{_, 0}` | Graceful tuple checking | Now | Prevents raw Erlang exit codes, allows formatted error messages |

## Open Questions (RESOLVED)

1. **GitHub Actions Elixir version:** RESOLVED: Use single-runner Ubuntu with Elixir 1.19
   - What we know: Current version is `1.19.5-otp-28`.
   - What's unclear: If `.github/workflows/ci.yml` needs a matrix or just a single version.
   - Recommendation: Use a single version for now based on `elixir: "~> 1.19"` in `mix.exs` unless multiple are desired.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix verify` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CI-01 | GitHub Actions runs `mix ci` | CI / YAML | n/a (runs in CI) | ❌ Wave 0 |
| CI-02 | `mix ci` runs all required tasks | Unit/Bash | `mix ci` | ✅ Wave 0 |
| VER-01 | `mix verify` does not crash with MatchError | Integration | `mix verify` | ✅ Wave 0 |
| VER-02 | `verify_docs.exs` warns on skipped blocks | Integration | `mix run scripts/verify_docs.exs` | ✅ Wave 0 |
| REL-01 | `release.preflight` guards against mis-tags | Integration | `mix release.preflight` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix ci`
- **Per wave merge:** `mix verify`
- **Phase gate:** GitHub CI passing

### Wave 0 Gaps
- [ ] `.github/workflows/ci.yml` — missing CI configuration file

## Sources

### Primary (HIGH confidence)
- Checked `mix.exs` - local repo contents
- Checked `lib/mix/tasks/verify.ex` - local repo contents
- Checked `lib/mix/tasks/release/preflight.ex` - local repo contents
- Checked `scripts/verify_docs.exs` - local repo contents

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Industry standard approach
- Architecture: HIGH - Defined explicitly in the prompt requirements
- Pitfalls: HIGH - Directly observed in the provided codebase files

**Research date:** 2024-05
**Valid until:** 2025-05