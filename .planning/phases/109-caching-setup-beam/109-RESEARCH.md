# Phase 109: Caching & setup-beam Foundation - Research

**Researched:** 2026-06-15
**Domain:** CI/CD Pipeline Performance (GitHub Actions, Elixir/Mix)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** **`CACHE_BUSTER` Strategy**: Use a hardcoded environment variable in the workflow YAML files (`env: CACHE_BUSTER: v1`). This provides visibility in PRs, reproducibility across historical commits, and simplicity for OSS contributors.
- **D-02:** **Dialyzer PLT Isolation and Save/Restore Split (CACHE-03)**: Configure `mix.exs` to place the PLT in `priv/plts/`. Use `actions/cache/restore@v4` and `actions/cache/save@v4` specifically targeting `priv/plts` in the workflow. The `actions/cache/save` step for the PLT will use `if: always()` after `mix ci`, successfully capturing the PLT even if Dialyzer finds type errors.
- **D-03:** **Workflow Topology & `mix ci`**: Defer `mix ci` decomposition to Phase 111. Phase 109 focuses solely on establishing the caching primitives. `run: mix ci` remains intact to avoid entangling cache logic with `test/guardrails/required_checks_contract_test.exs` rewrites.
- **D-04:** **`erlef/setup-beam` SHA Pinning (CACHE-04)**: Unify all occurrences of `erlef/setup-beam` to the pinned SHA currently found in `release.yml` (`8251c48667b97e88a0a24ec512f5b72a039fcea7 # v1`).

### the agent's Discretion
- [None specified]

### Deferred Ideas (OUT OF SCOPE)
- Decomposing the `mix ci` monolith (Deferred to Phase 111).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CACHE-01 | Hex deps are cached on a precise key; `mix deps.get` still runs on cache miss. | Standard `actions/cache@v4` block configured with `deps-${{ env.CACHE_BUSTER }}-${{ runner.os }}-${{ steps.setup-beam.outputs.otp-version }}-${{ steps.setup-beam.outputs.elixir-version }}-${{ env.MIX_ENV || 'test' }}-${{ hashFiles('**/mix.lock') }}` key. |
| CACHE-02 | `_build` is cached and never restored across incompatible OTP / Elixir / MIX_ENV. | Standard `actions/cache@v4` using same precise key prefix; restoring across `mix.lock` is safe *because* OTP/Elixir/MIX_ENV are strictly locked in the restore-keys prefix. |
| CACHE-03 | Dialyzer PLTs are cached with a restore/save split to persist on failure. | Configured via `actions/cache/restore@v4` and `actions/cache/save@v4` using `if: always()`. `mix.exs` dialyzer config updated to use `:plt_core_path` and `:plt_local_path`. |
| CACHE-04 | `setup-beam` is SHA-pinned; cache-bust documented. | Unification to `erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7 # v1` across all workflow files (`ci.yml`, `hexdocs.yml`, `release.yml`). |
| CACHE-05 | Cache hit/miss observable in CI summaries; does not mask warnings. | Addressed by mapping `steps.<id>.outputs.cache-hit` to summary environment variables. Elixir v1.15+ natively replays compiler warnings, preventing masking. |
</phase_requirements>

## Summary

This research confirms the standard patterns for fully caching an Elixir Mix pipeline in GitHub Actions without sacrificing correctness or diagnostic value. `deps` and `_build` can be safely cached using the standard `actions/cache@v4` action, provided the cache keys are extremely precise (locking OS, OTP, Elixir, and `MIX_ENV` versions). 

Crucially, Dialyzer's PLT generation is notorious for being discarded if the static analysis fails, causing cache-thrashing on PRs that introduce type errors. This is solved by splitting the Dialyzer cache step: `actions/cache/restore@v4` runs before tests, and `actions/cache/save@v4` runs `if: always()` at the end, targeting `priv/plts` exclusively. Elixir v1.15+ guarantees that restoring a compiled `_build` directory will accurately replay all compilation warnings, satisfying the strict requirements around visibility.

**Primary recommendation:** Use explicit `MIX_ENV: test` job-level environment variables in CI to ensure key consistency, update `mix.exs` to point Dialyzer paths to `priv/plts`, and replace `erlef/setup-beam@v1` with the exact pinned SHA everywhere.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency Fetching (`deps`) | CI Runner Cache | Mix | `mix deps.get` checks the local directory; standard `actions/cache` handles state across runs. |
| Compilation (`_build`) | CI Runner Cache | Mix Compiler | Cache avoids recompilation; Mix 1.15+ ensures warnings are replayed from AST. |
| Static Analysis (`priv/plts`) | CI Runner Cache | Dialyzer | Split restore/save handles Dialyzer's slow PLT generation while isolating failures. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `actions/cache` | `v4` | General caching (`deps`, `_build`) | Native GitHub action, minimal latency. |
| `actions/cache/restore` | `v4` | Pre-flight PLT lookup | Allows separating cache retrieval from saving. |
| `actions/cache/save` | `v4` | Guaranteed PLT persistence | Triggers `if: always()` to capture PLT even on failure. |
| `erlef/setup-beam` | `8251c486...` | Beam environment | The standard for installing Erlang/Elixir in GH Actions. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit `MIX_ENV` in keys | Omitting `MIX_ENV` | Omitting it conflates `dev` and `test` environments in `_build`, potentially causing mysterious cache misses or thrashing. |
| Split PLT steps | Single `actions/cache` | Single cache won't save if `mix ci` fails, meaning developers rewriting types have to wait for cold PLT rebuilds on every push. |

## Package Legitimacy Audit

> **Step 2.6: SKIPPED (no external packages/libraries installed)**
> Only GitHub Actions definitions and `mix.exs` project configurations are modified. `setup-beam` and `actions/cache` are standard actions provided by their official repositories.

## Architecture Patterns

### Dialyzer PLT Split Save/Restore Pattern
**What:** Decouples fetching the Dialyzer PLT cache from saving it. 
**When to use:** For static analysis tools that are both expensive to run and likely to fail CI checks.
**Example:**
```yaml
      - name: Restore PLT
        uses: actions/cache/restore@v4
        id: plt-cache
        with:
          path: priv/plts
          key: ${{ runner.os }}-plt-${{ env.CACHE_BUSTER }}-${{ steps.setup-beam.outputs.otp-version }}-${{ steps.setup-beam.outputs.elixir-version }}-${{ env.MIX_ENV || 'test' }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-plt-${{ env.CACHE_BUSTER }}-${{ steps.setup-beam.outputs.otp-version }}-${{ steps.setup-beam.outputs.elixir-version }}-${{ env.MIX_ENV || 'test' }}-

      - name: Run CI
        run: mix ci # Dialyzer might fail here

      - name: Save PLT
        uses: actions/cache/save@v4
        if: always() && steps.plt-cache.outputs.cache-hit != 'true'
        with:
          path: priv/plts
          key: ${{ steps.plt-cache.outputs.cache-primary-key }}
```

### Anti-Patterns to Avoid
- **Implicit Environment Keys:** Caching `_build` without `MIX_ENV` in the key. `_build` contains subfolders for each environment, and the cached artifact size will grow unnecessarily while causing potential collisions.
- **Restoring `_build` with wildcards across OTP versions:** Elixir NIFs and macros are highly sensitive to the OTP/Elixir version. Dropping OTP/Elixir from the cache key prefix will cause the CI to randomly fail compiling C-extensions or beam files.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Caching conditional logic | Bash scripts checking directory existence | `actions/cache` | It automatically handles compression, eviction, and cache backend communication. |
| Fallback dependency restore | Manual zip/unzip | `restore-keys` array | GitHub caches naturally cascade through prefix matching if a strict hash miss occurs. |

## Runtime State Inventory

> Step 2.5: SKIPPED (not a rename/refactor phase, purely CI config additions)

## Common Pitfalls

### Pitfall 1: Dialyxir Warnings on PLT File Paths
**What goes wrong:** Using the deprecated `plt_file` option without a tuple causes Mix compiler warnings.
**Why it happens:** Dialyxir deprecated direct `plt_file` strings.
**How to avoid:** Use `plt_core_path` and `plt_local_path` targeted to the same directory (`priv/plts`).
**Warning signs:** Warning output in CI summaries: `[warn] dialyxir: :plt_file is deprecated...`

### Pitfall 2: `actions/cache/save` primary key mismatch
**What goes wrong:** Hardcoding the key twice, potentially causing a mismatch if the hash changes during the run.
**Why it happens:** A `mix.lock` update command (if any) running between restore and save alters the `hashFiles` outcome.
**How to avoid:** Use `${{ steps.plt-cache.outputs.cache-primary-key }}` directly in the save step instead of repeating the string evaluation.

## Code Examples

### `mix.exs` Dialyzer Config
```elixir
  def project do
    [
      # ...
      dialyzer: [
        plt_core_path: "priv/plts",
        plt_local_path: "priv/plts",
        plt_add_apps: [:mix, :stream_data, :jsv, :yaml_elixir, :livebook]
      ]
    ]
  end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `actions/cache` | `actions/cache/restore` & `save` | 2022 (actions/cache v3.2+) | Allows saving expensive caches even when intermediate steps fail, vastly improving DX for type-checking PRs. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Elixir v1.15+ compiler warning replay mechanism satisfies the "never masks warnings" requirement. | Phase Requirements | If Elixir fails to replay warnings for a specific macro, a PR could pass with warnings when cached but fail locally. Very low risk given project enforces `>= 1.17`. |
| A2 | `MIX_ENV` defaulting to `test` is acceptable for the main `test` job cache keys. | Architecture Patterns | If `mix deps.get` fails to fetch dependencies for `test` (due to missing explicit `MIX_ENV: test` config), cache might miss. Mitigated by explicit `env: MIX_ENV: test` mapping. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| GitHub Actions Cache | Performance | ✓ | Native | — |

## Security Domain

> Security domain omitted: Phase focuses strictly on CI cache optimizations. SHA-pinning of `setup-beam` directly implements supply-chain security guidelines.

## Sources

### Primary (HIGH confidence)
- `109-CONTEXT.md` - Explicit decisions around SHA unification, PLT split, and workflow topology.
- `REQUIREMENTS.md` - CACHE-01 through CACHE-05 constraints.
- Elixir Core Documentation - Compiler warning replay functionality introduced in v1.15.

### Secondary (MEDIUM confidence)
- GitHub Actions Cache Documentation - Outputs format for `cache-primary-key` and `cache-hit` bindings.
- Dialyxir HexDocs - `plt_core_path` and `plt_local_path` configuration API.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `actions/cache` is the undisputed standard.
- Architecture: HIGH - PLT restore/save split is the recognized canonical solution for Dialyzer.
- Pitfalls: HIGH - Elixir caching gotchas are well documented.

**Research date:** 2026-06-15
**Valid until:** Stable