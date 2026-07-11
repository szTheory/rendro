# Phase 110: Test Concurrency, Determinism & Cleanup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 110-Test Concurrency, Determinism & Cleanup
**Areas discussed:** Test Partitioning Strategy, Flake Quarantine vs Fixing, Docs Contract Concurrency

---

## Test Partitioning Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Adopt `mix test --partitions N` | Adopt `mix test --partitions N` across parallel CI jobs. | |
| Maximize `async: true` | Rely entirely on maximizing `async: true` modules. | |
| Other | User custom input | ✓ |

**User's choice:** Deep-dive research utilizing generalist OSS DNA and best practices.
**Notes:** Research concluded that for a pure-Elixir library without heavy Ecto, `async: true` maximization is idiomatic and performant; `partitions N` adds runner boot overhead and unnecessary CI cost.

---

## Flake Quarantine vs Fixing

| Option | Description | Selected |
|--------|-------------|----------|
| Fix known flake | Fix the known `RecipesFacadeDriftTest` seed failure now. | |
| Establish quarantine lane | Establish a `mix verify.flake` nightly quarantine lane first per the threadline convention. | |
| Other | User custom input | ✓ |

**User's choice:** Deep-dive research utilizing generalist OSS DNA and best practices.
**Notes:** Research concluded that building the structural quarantine lane (`mix verify.flake`) first, per the `threadline` OSS DNA, is the priority to prevent future flakes from blocking PRs. The known issue will be fixed within that new structure.

---

## Docs Contract Concurrency

| Option | Description | Selected |
|--------|-------------|----------|
| Refactor to `async: true` | Refactor `DocsContract.evaluate!/2` to support `async: true` across the 10+ contract tests. | |
| Keep serial | Keep them serial to avoid filesystem read overlap issues. | |
| Other | User custom input | ✓ |

**User's choice:** Deep-dive research utilizing generalist OSS DNA and best practices.
**Notes:** Research concluded that since evaluating a contract should be functionally pure (reading only), it is highly idiomatic and performant to refactor `DocsContract.evaluate!/2` to guarantee safety, enabling `async: true` across all contract tests for free parallelization.

---

## Claude's Discretion

All recommendations were delegated to Claude's expert synthesis.

## Deferred Ideas

None
