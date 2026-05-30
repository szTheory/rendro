---
phase: 79-public-api-contract-enforcement-lane
reviewed: 2026-05-30T18:09:48Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - lib/rendro/component.ex
  - priv/guardrails/required_status_checks.json
  - scripts/verify_docs.exs
  - test/docs_contract/public_api_contract_test.exs
  - test/docs_contract/recipes_contract_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - test/rendro/public_api_test.exs
  - test/rendro/recipes/certificate_test.exs
  - test/rendro/recipes/receipt_test.exs
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 79: Code Review Report

**Reviewed:** 2026-05-30T18:09:48Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 79 adds a five-assertion public-API contract test, two `@spec` annotations on `Rendro.Component`, and updates the guardrails triple (JSON, script, test) to register the new lane. The credo-fix diffs (`length(x) > 0` / `length(x) >= 1` → `x != []`) are all behavior-preserving: every target was confirmed to be a plain `list` return from `Enum.*` operations.

The guardrails triple is internally consistent: `verify_docs.exs` has exactly 11 lanes, the required-checks contract test asserts `== 11`, and the JSON notes now read "(11 docs-contract lanes)". The `@spec` types on `Rendro.Component` are accurate (`atom()` for `logical_name` matches `Rendro.Image.t()`'s field type; `Rendro.Block.t()` as the return is tight; `term()` on `render_component/2` is correct given dynamic dispatch).

One false-pass bug in Assertion 3a is classified as a blocker because it silently validates a missing module as "hidden." Three robustness / consistency gaps are warnings. Two pre-existing issues surfaced during review are logged as info.

## Critical Issues

### CR-01: Assertion 3a silently passes when an internal module is not compiled (false-pass)

**File:** `test/docs_contract/public_api_contract_test.exs:96-101`

**Issue:** The `{:error, _} -> :hidden` fallback in the `hidden_modules` check was added to handle BEAM-file edge cases, but it has the unintended consequence of making the assertion pass if a module is absent from the build entirely. If `Rendro.PDF.CidFont`, `Rendro.Text.Bidi`, or any other module in `hidden_modules` is renamed, deleted, or fails to compile, `Code.fetch_docs/1` returns `{:error, :module_not_found}`, the branch maps that to `:hidden`, and `assert module_doc == :hidden` passes. The test becomes a no-op for any absent module — exactly the kind of leak it is designed to prevent.

**Current code:**
```elixir
module_doc =
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, module_doc, _, _} -> module_doc
    {:error, _} -> :hidden          # <-- false-pass: absent == hidden
  end

assert module_doc == :hidden, ...
```

**Fix:** Assert the module is loaded before checking its doc. An absent module should be a test failure, not a silent pass:
```elixir
assert Code.ensure_loaded?(module),
       "Expected #{inspect(module)} to be compiled and loaded, but it was not found"

module_doc =
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, module_doc, _, _} -> module_doc
    {:error, reason} ->
      flunk("Could not fetch docs for #{inspect(module)}: #{inspect(reason)}")
  end

assert module_doc == :hidden,
       "Expected #{inspect(module)} to have @moduledoc false (:hidden), " <>
         "but module_doc is: #{inspect(module_doc)}"
```

## Warnings

### WR-01: Assertion 3b crashes with MatchError if Rendro.Sign or Rendro.Protect is absent

**File:** `test/docs_contract/public_api_contract_test.exs:115`

**Issue:** The redact-helper assertion uses a bare pattern match:
```elixir
{:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(module)
```
If `Code.fetch_docs/1` returns `{:error, reason}` (module absent, BEAM corrupt, etc.), this raises a `MatchError` instead of a clean test failure. This is inconsistent with Assertion 3a which handles `{:error, _}` (even if that handling is itself buggy — see CR-01). The resulting stack trace is confusing compared to an explicit `assert` or `flunk`.

**Fix:**
```elixir
case Code.fetch_docs(module) do
  {:docs_v1, _, _, _, _, _, docs} ->
    # ... existing for loop
  {:error, reason} ->
    flunk("Could not fetch docs for #{inspect(module)}: #{inspect(reason)}")
end
```

### WR-02: String.to_existing_atom crashes instead of failing cleanly on stale manifest entries

**File:** `test/docs_contract/public_api_contract_test.exs:147,188`

**Issue:** Assertions 4 (tier-tag) and 5 (spec coverage) both call `String.to_existing_atom(mod_key)` on every key in the on-disk manifest. If the manifest contains a module key that is no longer loaded in the runtime (stale manifest, module renamed, module deleted), `String.to_existing_atom/1` raises `ArgumentError` with a bare "argument error" message. Because ExUnit runs all tests independently (`async: false` does not stop sibling tests from running), both assertions can crash with opaque errors at the same time that Assertion 2 correctly reports the drift — producing a confusing multi-failure output.

**Fix:** Use `String.to_atom/1` for a safe conversion, or rescue/guard explicitly:
```elixir
module =
  try do
    String.to_existing_atom(mod_key)
  rescue
    ArgumentError ->
      flunk("Manifest contains #{mod_key} but this atom is not loaded. " <>
            "Run: mix rendro.api.gen")
  end
```
Alternatively, since Assertion 2's drift check already catches stale modules cleanly, document that Assertions 4 and 5 assume a non-stale manifest as a precondition.

### WR-03: Duplicate describe label "V8:" in receipt_test.exs obscures test identity

**File:** `test/rendro/recipes/receipt_test.exs:412,495`

**Issue:** There are two `describe "V8: ..."` blocks. Line 412 is `"V8: deterministic byte-identical render"` and line 495 is `"V8: validate_data!/1 rejects malformed input"`. The second should be `V11`. ExUnit does not error on duplicate describe labels, but test selectors (`--only` flags, test reporting) become ambiguous when two describe blocks share an identifier. This was pre-existing before this phase but is present in a file changed by this phase.

**Fix:** Rename the describe at line 495:
```elixir
describe "V11: validate_data!/1 rejects malformed input" do
```

## Info

### IN-01: Guardrails notes lane count not verified by the contract test

**File:** `test/guardrails/required_checks_contract_test.exs:25-27`

**Issue:** The `required_checks_contract_test.exs` asserts that the `test` context's `notes` field contains `"Phase 68 D-18"` and `"Viewer-evidence"`, but does not verify the `"(11 docs-contract lanes)"` substring. The notes in `required_status_checks.json` previously read "(8 docs-contract lanes)" through phases 73–78, jumping directly to 11 in phase 79. Nothing would fail if the notes said 10 or 8 instead of 11. This is purely informational — the actual lane count is enforced by the `length(lane_entries) == 11` assertion in the same test.

**Fix (optional):** Add a substring assertion for the lane count:
```elixir
assert test_context["notes"] =~ "(11 docs-contract lanes)"
```

### IN-02: render_component/2 @spec return type is maximally loose

**File:** `lib/rendro/component.ex:10`

**Issue:** `@spec render_component(module(), keyword()) :: term()` uses `term()`, the widest possible Elixir return type. This is not incorrect — `module.render(assigns)` is dynamic dispatch and could return anything. Dialyzer accepts it. However, if the project later establishes a contract that all renderable components return a specific type (e.g., `Rendro.Block.t() | [Rendro.Block.t()]`), this spec will silently allow violations. Flagged for awareness, not as a defect.

**Fix (optional):** Document the expected return contract in the `@doc` string so consumers understand what to expect from user-implemented `render/1` callbacks, even if the typespec cannot enforce it.

---

_Reviewed: 2026-05-30T18:09:48Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
