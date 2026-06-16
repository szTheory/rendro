---
phase: 110-test-concurrency-determinism-cleanup
verified: 2024-05-18T12:00:00Z
status: passed
score: 13/13 must-haves verified
overrides_applied: 0
---

# Phase 110: Make the test suite faster and more trustworthy Verification Report

**Phase Goal:** Make the test suite faster and more trustworthy by safely raising concurrency, making an evidence-based partitioning call, rooting out nondeterminism instead of papering over it, and removing genuinely low-signal tests — while preserving every bit of real coverage.
**Verified:** 2024-05-18T12:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth   | Status     | Evidence       |
| --- | ------- | ---------- | -------------- |
| 1 | Docs contracts are statically verified before evaluation to ensure they do not write to the file system. | ✓ VERIFIED | `Macro.prewalk` blocks operations in `test/support/docs_contract.ex` |
| 2 | Contract snippets attempting to invoke `System.cmd` or `Mix.Task` raise an error without executing. | ✓ VERIFIED | Error raises implemented in `DocsContract.evaluate!/2` |
| 3 | Contract snippets attempting to invoke `File` mutation functions raise an error without executing. | ✓ VERIFIED | Error raises implemented in `DocsContract.evaluate!/2` |
| 4 | All docs contract tests can be safely run concurrently with `async: true`. | ✓ VERIFIED | Found `async: true` in `*_test.exs` excluding those with global states |
| 5 | Flaky tests run in a dedicated lane (`mix verify.flake`) and do not block the main PR pipeline. | ✓ VERIFIED | `verify.flake` alias present in `mix.exs` |
| 6 | The main `mix ci` alias excludes tests tagged with `:quarantine`. | ✓ VERIFIED | `ci` alias excludes quarantine in `mix.exs` |
| 7 | `RecipesFacadeDriftTest` is quarantined due to known seed dependencies. | ✓ VERIFIED | `@moduletag :quarantine` is in `recipes_facade_drift_test.exs` |
| 8 | ExUnit correctly layers test suites by excluding `:quarantine`, `:live_pdf_tools`, `:live_signing`, and `:raster_snapshot` by default (TEST-05). | ✓ VERIFIED | `ExUnit.configure` excludes in `test_helper.exs` |
| 9 | Aliases (`ci`, `verify.flake`, `test.all`) include `--slowest 10` flag to report the slowest tests (TEST-05). | ✓ VERIFIED | Flag included in all aliases in `mix.exs` |
| 10 | The decision not to use `mix test --partitions N` is documented. | ✓ VERIFIED | Decision D-01 is documented in `test_helper.exs` |
| 11 | Reasons for remaining `async: false` tests (e.g., global app state) are documented. | ✓ VERIFIED | Sequential test reasons documented in `test_helper.exs` |
| 12 | Shared `hex.build` test setup costs are mitigated via a singleton caching agent. | ✓ VERIFIED | `Rendro.Test.HexBuildCache` implemented and started in `test_helper.exs` |
| 13 | Claims tests run concurrently (`async: true`) because they no longer duplicate shared `_build` folder mutation. | ✓ VERIFIED | `branding`, `launch_artifacts`, `comparison` claims tests use `HexBuildCache` and `async: true` |

**Score:** 13/13 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `test/support/docs_contract.ex` | Safe AST-checked evaluator | ✓ VERIFIED | Module defines `DocsContract.evaluate!/2` with prewalk checks |
| `test/support/docs_contract_test.exs` | Validation tests | ✓ VERIFIED | Verifies read-only evaluation logic |
| `mix.exs` | CI and flake aliases | ✓ VERIFIED | Includes updated layered test aliases with slowest flags |
| `test/rendro/recipes_facade_drift_test.exs` | Quarantined test module | ✓ VERIFIED | Properly tagged with `@moduletag :quarantine` |
| `test/test_helper.exs` | Default exclusions & documentation | ✓ VERIFIED | Configuration layers excluded and strategy fully documented |
| `test/support/hex_build_cache.ex` | Agent cache | ✓ VERIFIED | Provides singleton caching agent over `mix hex.build` |
| `test/support/hex_build_cache_test.exs` | Cache functional tests | ✓ VERIFIED | Fully tests output and singleton properties |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `test/support/docs_contract.ex` | `Code.eval_quoted/3` | `Macro.prewalk` | ✓ WIRED | Code validates through AST prewalk before dynamic execution |
| `mix.exs` | `mix test` | `verify.flake` | ✓ WIRED | Proper isolation logic executes in the alias |
| `test/test_helper.exs` | `test/support/hex_build_cache.ex` | `Agent.start_link` | ✓ WIRED | Agent is started before the main ExUnit execution |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `HexBuildCache` | Cache entry | `System.cmd` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| DocsContract AST checks and HexBuildCache both work | `mix test test/support/docs_contract_test.exs test/support/hex_build_cache_test.exs` | 0 failures | ✓ PASS |
| Alias isolation works | `mix help verify.flake` | Expected `--only quarantine` included | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| TEST-01 | 110-01, 110-03 | Every safely-isolatable test module runs `async: true`... | ✓ SATISFIED | `async: true` mapped to all docs contracts, claims tests, and reasons documented for globals |
| TEST-02 | 110-02 | A measured decision on `mix test --partitions N` is made... | ✓ SATISFIED | Found documented rejection inside `test_helper.exs` |
| TEST-03 | 110-02 | Flaky tests fixed or explicitly quarantined with tracked remediation. | ✓ SATISFIED | `RecipesFacadeDriftTest` marked with `@moduletag :quarantine` |
| TEST-04 | 110-02 | Low-signal tests removed or rewritten with evidence. | ✓ SATISFIED | Documented in `test_helper.exs` that the audit showed no low-signal tests needed removing |
| TEST-05 | 110-02, 110-03 | Slowest tests reported, test suites correctly layered. | ✓ SATISFIED | `--slowest 10` combined with `ExUnit.configure` excludes, plus `hex.build` mitigated via cache |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| None | - | - | - | - |

### Human Verification Required

None.

### Gaps Summary

None.

---

_Verified: 2024-05-18T12:00:00Z_
_Verifier: the agent (gsd-verifier)_