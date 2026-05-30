---
phase: 80-stability-contract-migration-docs
plan: "04"
subsystem: docs-contract
tags: [docs-contract, claims-test, api-stability, stab-05, lane-registration]
dependency_graph:
  requires:
    - 80-01  # guides/api_stability.md rewrite (headers + promise sentences)
    - 80-03  # guides/upgrading_to_1.0.md (upgrade-guide existence assertion)
  provides:
    - STAB-05 docs-contract claims test (test/docs_contract/api_stability_claims_test.exs)
    - Lane 12 in scripts/verify_docs.exs
  affects:
    - mix docs.contract (12 lanes, previously 11)
tech_stack:
  added: []
  patterns:
    - ExUnit claims-test idiom (guide = File.read! + guide =~ substring)
    - False-pass-guard pattern (assert Code.ensure_loaded? + function_exported? with message)
    - Lane self-registration lockstep triple (test self-asserts own verify_docs.exs entry)
key_files:
  created:
    - test/docs_contract/api_stability_claims_test.exs
  modified:
    - scripts/verify_docs.exs
decisions:
  - "D-09: Rendro.Inspector NOT asserted (adapter tier); comment removed to satisfy grep acceptance criterion"
  - "Deviation: added Code.ensure_loaded?(Rendro) before function_exported? calls to ensure module is loaded in async test process"
metrics:
  duration: ~10 minutes
  completed: "2026-05-30"
  tasks: 1
  files: 2
---

# Phase 80 Plan 04: API Stability Claims Test (STAB-05) Summary

**One-liner:** ExUnit docs-contract claims test asserting Tier-1 symbol existence (false-pass-guarded), tier headers, key promise sentences, upgrade-guide presence, and lane self-registration — closes STAB-05 with lane 12 in verify_docs.exs.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create api_stability_claims_test.exs + register lane 12 | b5498fe, 39ba37f | test/docs_contract/api_stability_claims_test.exs, scripts/verify_docs.exs |

## What Was Built

### test/docs_contract/api_stability_claims_test.exs (NEW)

The STAB-05 claims test with all five D-10 assertion categories:

**Category 1 — Guide prose (tier headers + key promise sentences):**
- Asserts all five section headers verbatim: `## Tier-1 Stable`, `## Tier-2 Evolving`, `## NOT covered by SemVer`, `## Deprecation Policy`, `## Deprecations`
- Asserts key promise sentence: `"deterministic within a version, not frozen across versions"`
- Asserts deprecations table: `"| Symbol |"` and `"None as of 1.0.0"`
- Refutes banned overclaim phrases: `"secure PDF"` and `"PAdES is supported"` (D-03)

**Category 2 — Symbol existence (false-pass-guarded):**
- 7 stable-tier modules: `Rendro.Document`, `Rendro.PageTemplate`, `Rendro.Section`, `Rendro.Metadata`, `Rendro.Artifact`, `Rendro.Sign`, `Rendro.Protect`
- 2 adapter-tier modules: `Rendro.Adapters.PyHanko`, `Rendro.Adapters.Qpdf`
- 4 top-level functions: `Rendro.flow/2`, `Rendro.signature_field/2`, `Rendro.render_signed/3`, `Rendro.render_protected/3`
- 4 `Rendro.Sign` functions: `prepare/2`, `sign/2`, `augment/2`, `validate/2`
- 1 `Rendro.Protect` function: `password/2`
- Struct existence: `match?(%Rendro.Artifact{}, struct(Rendro.Artifact))`
- `Rendro.Inspector` NOT asserted (adapter tier, D-09 landmine)

**Category 3 — Upgrade guide existence:** `File.exists?("guides/upgrading_to_1.0.md")`

**Category 4 — Lane self-registration:** Asserts the exact lane entry byte-identical to scripts/verify_docs.exs

### scripts/verify_docs.exs (MODIFIED)

Added lane 12 after the existing 11 lanes:
```
{"API stability claims lane", ["test", "test/docs_contract/api_stability_claims_test.exs"]}
```

## Verification Results

- `mix test test/docs_contract/api_stability_claims_test.exs` — 4 tests, 0 failures
- `mix test test/docs_contract/` — 108 tests (1 doctest + 107 tests), 0 failures (all 12 lanes)
- `mix docs.contract` — all 12 lanes PASS, exits 0
- `grep "Inspector" test/docs_contract/api_stability_claims_test.exs` — returns nothing (exit 1)
- `mix ci` — exits 0 (compile --warnings-as-errors + format + credo + dialyzer + full test suite)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `function_exported?` returned false in async ExUnit test process**

- **Found during:** Task 1, first test run
- **Issue:** `function_exported?(Rendro, :flow, 2)` returned false when called without first loading the `Rendro` module via `Code.ensure_loaded?` in the async test process. The original symbol list only called `Code.ensure_loaded?` for `Rendro.Document`, `Rendro.PageTemplate`, etc., but NOT for the top-level `Rendro` module itself. `mix run` (non-async) worked fine, but async ExUnit spawns a separate process where the module may not be loaded.
- **Fix:** Added `assert Code.ensure_loaded?(Rendro)` before the `function_exported?(Rendro, ...)` calls. This ensures the module is loaded in the test process context before querying its exports.
- **Files modified:** test/docs_contract/api_stability_claims_test.exs
- **Commit:** b5498fe

**2. [Rule 3 - Blocking] Formatter rejected 2-space indentation for assert messages**

- **Found during:** Task 1, `mix ci` format check
- **Issue:** `mix format --check-formatted` required 11-space alignment (matching call site) for assert message strings, not 2-space indentation.
- **Fix:** Ran `mix format` on the file; reformatted automatically.
- **Files modified:** test/docs_contract/api_stability_claims_test.exs
- **Commit:** b5498fe (formatted before commit)

**3. [Rule 1 - Correctness] Inspector comment violated acceptance criterion**

- **Found during:** Self-check
- **Issue:** A `# DO NOT assert Code.ensure_loaded?(Rendro.Inspector)` comment caused `grep "Inspector"` to return a match, violating the acceptance criterion that requires no Inspector reference.
- **Fix:** Removed the comment. The intent is already enforced by the absence of any Inspector assertion.
- **Files modified:** test/docs_contract/api_stability_claims_test.exs
- **Commit:** 39ba37f

## Known Stubs

None. All assertions are grounded in real guide content (read verbatim from guides/api_stability.md) and real module/function exports.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes introduced — this plan adds only a test file and a lane registration line.

## Self-Check: PASSED

- FOUND: test/docs_contract/api_stability_claims_test.exs
- FOUND: scripts/verify_docs.exs (modified with lane 12)
- FOUND: b5498fe (feat(80-04): create api_stability_claims_test.exs + register lane 12)
- FOUND: 39ba37f (refactor(80-04): remove DO NOT comment)
- Inspector grep: returns nothing (exit 1) — PASS
- `mix test test/docs_contract/` — 0 failures — PASS
- `mix docs.contract` — 12 lanes PASS — PASS
- `mix ci` — exits 0 — PASS
