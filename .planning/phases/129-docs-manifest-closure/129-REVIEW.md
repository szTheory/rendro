---
phase: 129-docs-manifest-closure
reviewed: 2026-08-19T17:53:13Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - README.md
  - guides/presets.md
  - guides/theming.md
  - mix.exs
  - priv/guardrails/required_status_checks.json
  - priv/support_matrix.json
  - scripts/verify_docs.exs
  - test/docs_contract/branding_claims_test.exs
  - test/docs_contract/comparison_claims_test.exs
  - test/docs_contract/examples_schema_contract_test.exs
  - test/docs_contract/launch_artifacts_claims_test.exs
  - test/docs_contract/preset_fonts_package_contract_test.exs
  - test/docs_contract/presets_claims_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - test/support/hex_build_cache.ex
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 129: Code Review Report

**Reviewed:** 2026-08-19T17:53:13Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Reviewed the Phase 129 docs/public-contract additions, package allowlist and ExDoc wiring, docs-contract runner, manifest updates, and the shared Hex-build cache. The focused contract suite passes, but the new cache does not actually isolate concurrent BEAM test VMs: its archive basename is unique only within one VM.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Hex archive cache filename collides across concurrent BEAM VMs

**File:** `test/support/hex_build_cache.ex:56`
**Issue:** `System.unique_integer/1` is scoped to the current BEAM runtime, not the host. Every fresh VM starts its monotonic sequence at `1`; two concurrent `mix test` processes therefore both select `/tmp/rendro-hex-build-1.tar`. They can overwrite the same archive while another process is listing it, producing corrupted reads or flaky package-contract failures. This contradicts the per-test-VM isolation asserted by the module documentation. I verified that two separate `mix run` VMs each return `1` for `System.unique_integer([:positive, :monotonic])`.

**Fix:** Include process-external entropy in the filename (and retain the VM-local counter), such as a cryptographically random suffix:

```elixir
suffix = Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)

tarball_path =
  Path.join(
    System.tmp_dir!(),
    "rendro-hex-build-#{System.unique_integer([:positive, :monotonic])}-#{suffix}.tar"
  )
```

Add a regression test that starts two separate BEAM VMs (or extracts the naming helper and injects independent VM identifiers) and asserts distinct archive paths.

---

_Reviewed: 2026-08-19T17:53:13Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
