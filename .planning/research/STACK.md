# Stack Research

**Domain:** Quality and maintainability ratchet for a mature pure-Elixir library
**Researched:** 2026-08-26
**Confidence:** HIGH

## Recommendation

Keep the existing runtime and quality stack. Rendro already has the right baseline tools; v2.14 should improve how they are applied and how findings are recorded, not add a second lint ecosystem. New dependencies require a demonstrated gap that cannot be covered by Elixir/Mix, the installed quality tools, or a small repository-owned contract.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | v2.14 posture |
|------------|---------|---------|---------------|
| Elixir | 1.19.5 | Core language, compiler diagnostics, ExUnit, Mix tasks, xref, line-coverage diagnostics | Keep; use compiler and xref output as evidence rather than introducing a parallel analyzer |
| Erlang/OTP | 28 | Runtime, BEAM tooling, Dialyzer engine | Keep; preserve the supported CI matrix and inspect dependency direction before changing module boundaries |
| ExUnit | bundled | Behavioral, property, docs-contract, and integration verification | Keep; improve test ownership and reduce brittle evidence coupling without imposing a raw coverage quota |
| GitHub Actions | current service | Required, proof, advisory, release, and catalog-evidence automation | Keep; separate purpose-named workflows and minimize permissions/cross-trigger authority |

### Existing Quality Tools

| Tool | Version | Purpose | Recommendation |
|------|---------|---------|----------------|
| Credo | 1.7.17 | Consistency, readability, refactor, design, and warning checks | Retain `--strict`; add or tune checks only when Phase 132 demonstrates a recurring gap |
| Dialyxir | 1.4.7 | Dialyzer integration and type/spec diagnostics | Retain zero-warning policy; audit suppressions and spec value rather than maximizing spec count |
| ExDoc | 0.40.1 | Public documentation and warning gate | Retain warnings-as-errors and review skip lists for stale exemptions |
| mix_audit | 2.1.x | Dependency vulnerability audit | Retain in advisory/nightly and release surfaces; keep ignore entries evidence-backed |
| JSV / yaml_elixir | existing lock | JSON/YAML contract validation | Reuse for quality-ledger/evidence/workflow contracts where machine validation adds value |

### Built-in Diagnostic Tools

| Tool | Use | Boundary |
|------|-----|----------|
| `mix xref graph --format stats` | Baseline runtime/export/compile dependency shape and cycles | Counts and cycles are investigation signals, not automatic failures |
| `mix xref graph --format stats --label compile-connected` | Compile-health check recommended by Mix documentation | Preserve the current zero compile-connected cycle posture |
| `mix test --cover` / `mix test.coverage` | Find unexecuted areas and test-suite blind spots | Diagnostic only; line coverage cannot prove branch behavior or assertion quality |
| `mix test --slowest` | Identify high-cost tests and fixtures | Optimize only repeatable bottlenecks that affect local/CI feedback |
| `mix hex.build` | Verify package contents | Continue exact allowlist checks and explicitly exclude internal release evidence |

## GitHub Actions Design

- Keep ordinary CI responsible for committed-state validation.
- Move catalog generation/review/canonical artifact production into a purpose-named workflow with `workflow_dispatch` inputs `candidate_sha` and `operation` (`review` or `canonical`).
- Validate `candidate_sha` as exactly forty lowercase hexadecimal characters, check out that SHA, and compare `git rev-parse HEAD` literally before any renderer work.
- Keep top-level `contents: read`; grant no write permission or secret to catalog evidence generation.
- Treat caches as untrusted inputs. Restore from low-trust triggers, save only on trusted triggers, and never cache credentials or evidence claimed as authoritative.
- Use artifacts for generated evidence and caches only for reproducible dependencies/build intermediates.

## Alternatives Considered

| Recommended | Alternative | Decision |
|-------------|-------------|----------|
| Existing Credo + repository contracts | Add a broad new style/complexity tool | Defer unless Phase 132 proves a gap with a concrete false-negative example |
| Built-in line coverage as diagnostic | Enforce a global coverage percentage | Reject; the number is easy to game and does not measure assertion or branch quality |
| Evidence ledger with human disposition | Automated maintainability score | Reject; opaque composite scores would turn judgment into unsupported precision |
| Purpose-named catalog workflow | Continue accumulating phase-number branch routes in `ci.yml` | Replace after parity and security checks pass |
| Cohesive internal extraction | Split every large module by line count | Reject; size alone does not prove a better boundary |

## What Not to Add

| Avoid | Why | Use instead |
|-------|-----|-------------|
| Runtime dependencies for quality tooling | Violates the pure-core boundary and expands the shipped package for maintainer-only work | Dev/test tools or repository-owned scripts/contracts |
| Blanket Dialyzer warning flags without a trial | Some optional warning classes can be noisy and create misleading spec churn | Evaluate each flag against the current code and record false-positive cost |
| Mutation-testing or complexity services by default | Adds operational cost before a concrete coverage problem is identified | Focused regression tests, property tests, xref, and evidence-backed review |
| Hosted quality dashboards | Creates another stateful truth source and maintenance surface | `.planning/QUALITY.md` plus reproducible commands and committed evidence |

## Version Compatibility

| Component | Compatibility decision |
|-----------|------------------------|
| Elixir 1.19.5 / OTP 28 | Authoritative local and primary CI quality environment |
| Optional dependency matrix | Preserve existing supported pairs; quality refactors cannot make optional adapters mandatory |
| Credo 1.7.17 / Dialyxir 1.4.7 | Use currently locked semantics for the milestone; dependency upgrades are separate work unless required for correctness |
| GitHub Actions | Keep third-party actions SHA-pinned and validate workflow syntax through repository contracts |

## Sources

- [Mix xref documentation](https://hexdocs.pm/elixir/1.19.5/Mix.Tasks.Xref.html) — dependency labels, cycle analysis, and compile-connected health guidance
- [Mix test coverage documentation](https://hexdocs.pm/mix/1.19.5/Mix.Tasks.Test.Coverage.html) — built-in coverage and its limitations
- [Credo configuration](https://credo.hexdocs.pm/config_file.html) — strict mode, enabled checks, and custom configuration
- [Dialyxir 1.4.7 documentation](https://dialyxir.hexdocs.pm/) — warning flags, explanations, PLTs, and ignore handling
- [GitHub reusable workflow reference](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations) — workflow reuse and permission propagation
- [GitHub dependency caching reference](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching) — cache scope and poisoning guidance
- Rendro `mix.exs`, `.credo.exs`, `.github/workflows/*.yml`, and `priv/guardrails/required_status_checks.json` — repository-specific stack and authority boundaries

---
*Stack research for: v2.14 Quality & Maintainability*
*Researched: 2026-08-26*
