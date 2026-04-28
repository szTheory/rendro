# Phase 10: Recipe Correctness + Traceability Sync - Research

**Researched:** 2026-04-28
**Domain:** Optional adapter contract hardening and requirements traceability integrity
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Mailglass wrapper contract
- **D-01:** Keep custom Mailglass-style wrapper support in scope for Phase 10. Phase 10 success criteria explicitly require the custom-wrapper path, so narrowing support to `%Mailglass.Message{}` only is not acceptable in this phase unless the roadmap changes.
- **D-02:** Treat custom-wrapper support as an intentionally narrow adapter contract, not open-ended duck typing. Supported wrappers must satisfy the existing documented shape: struct module ends in `.Message`, exports `update_swoosh/2`, and carries the wrapped `%Swoosh.Email{}` in `:swoosh` or `:email`.
- **D-03:** Re-wrap through the input struct's own module, not through hardcoded `Mailglass.Message`. This is the least-surprise fix that matches the current Phase 10 boundary and avoids `FunctionClauseError` on valid custom wrappers.
- **D-04:** Do not use bare field overwrite or "best effort" fallback as the primary contract for admitted custom wrappers. Unsupported wrapper shapes should fail with a typed error, not be silently mutated or downgraded to a raw `%Swoosh.Email{}`.
- **D-05:** Keep the custom-wrapper contract explicit in docs and tests. If Rendro later wants truly open polymorphism here, that should be a separate design with a real behaviour/protocol rather than more heuristics.

### Accrue invoice validation
- **D-06:** `Rendro.Adapters.Accrue.recipe/1` should validate nested `line_items` explicitly and fail the whole recipe on the first invalid entry.
- **D-07:** Invalid nested invoice data must return a typed `{:error, {:invalid_invoice, _}}` tuple, not raise and not partially render. This keeps invoice output deterministic and auditable.
- **D-08:** Do not silently skip invalid line items inside `recipe/1`. Silent omission is the worst DX outcome here because it can produce incorrect billing PDFs that look successful.
- **D-09:** Do not broaden `recipe/1` into a permissive coercion/parser layer in this phase. If tolerant ingestion is ever desirable, it should be a separate normalization API with its own docs and tests.

### Accrue issued_at contract
- **D-10:** Render `issued_at` as a date-only ISO 8601 string (`YYYY-MM-DD`) in the invoice header.
- **D-11:** Accepted temporal inputs for `issued_at` should be `Date`, `NaiveDateTime`, and `DateTime`; datetime inputs should normalize to their calendar date before rendering.
- **D-12:** Do not use locale-aware formatting as the default in this adapter. Locale-sensitive presentation should remain an explicit caller concern, not an implicit library default.
- **D-13:** Remove all developer-facing debug formatting from invoice output. `inspect/1` is not acceptable in user-visible PDF text.

### Traceability and docs truthfulness
- **D-14:** Requirements traceability must follow verified state, not stale status tables. Phase 10 should make `REQUIREMENTS.md` match the verified Phase 5 outcome once the recipe defects are fixed.
- **D-15:** Documentation should state exact accepted shapes and exact failure modes for these adapters. Rendro should prefer a smaller truthful contract over a broader magical contract.

### the agent's Discretion
- Exact error payload shape for nested line-item failures, as long as it stays under `{:error, {:invalid_invoice, _}}` and points callers to the offending nested data.
- Whether the invoice omits the `Issued:` line entirely when `issued_at` is `nil`, or renders a blank/placeholder line, as long as the behavior is consistent and documented.
- Whether to add a compatibility fallback for non-temporal `issued_at` values. Preferred direction is strict typed handling, but a documented `to_string/1` compatibility path is acceptable if planning determines that tightening the contract would be too breaking for this phase.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within the Phase 10 boundary.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADPT-05 | Maintainer can provide do-now integration recipes for `threadline`, `mailglass`, and `accrue` without hard coupling. | Fix the two remaining adapter contract defects, add regression tests for the custom Mailglass wrapper and invalid nested Accrue line items, and keep optional-dependency gating/test harness unchanged. [VERIFIED: codebase grep + live repro] |
| QUAL-04 | Maintainer can run release preflight checks for version/tag parity and publish dry-run workflows. | Phase 10 only contributes the traceability-truth part of QUAL-04 by syncing `REQUIREMENTS.md` with verified phase evidence after the code defects are actually closed; release-preflight mechanics already live in `lib/mix/tasks/release/preflight.ex`. [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep `rendro` core pure; do not add hard dependencies on Phoenix, Oban, Mailglass, Swoosh, or Accrue to `mix.exs`. [VERIFIED: AGENTS.md + mix.exs]
- Preserve deterministic/advisory verification-lane separation in docs and CI language. [VERIFIED: AGENTS.md]
- Treat documentation claims as contracts; Phase 10 must update docs/traceability only to match actual verified behavior. [VERIFIED: AGENTS.md + 10-CONTEXT.md]
- Preserve the architecture boundary `build -> compose -> measure -> paginate -> render -> validate`; this phase is adapter/docs hardening, not pipeline redesign. [VERIFIED: AGENTS.md]

## Summary

Phase 10 is a narrow correctness pass in the existing optional-adapter layer, not a stack-selection phase. The current tree already contains both target defects in live code: `Rendro.Adapters.Mailglass.put_swoosh/2` still hardcodes `Mailglass.Message.update_swoosh/2`, and `Rendro.Adapters.Accrue.build_content/1` still pattern-matches `%Accrue.LineItem{}` inside `Enum.map/2`, which raises on invalid nested entries. Both issues are reproducible today in the repo’s test harness. [VERIFIED: lib/rendro/adapters/mailglass.ex; lib/rendro/adapters/accrue.ex; live repro via `MIX_ENV=test mix run -e ...`]

The current tests do not catch either defect because the Mailglass fixture deliberately lacks a `:swoosh` field, so the code never reaches `put_swoosh/2`, and the Accrue suite validates only outer non-invoice input. The focused implementation strategy is therefore: keep the existing optional-adapter/test-harness architecture, add the missing regression cases, fix the adapter logic without adding dependencies, then update `guides/integrations.md` and `REQUIREMENTS.md` together so ADPT-05 is marked done only after the code/tests/docs all agree. [VERIFIED: test/rendro/adapters/mailglass_test.exs; test/rendro/adapters/accrue_test.exs; test/test_helper.exs; test/support/mocks.ex; .planning/REQUIREMENTS.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md]

**Primary recommendation:** Use the existing pure-Elixir adapter surface and test harness, add two regression tests first, then harden Mailglass dispatch, harden Accrue nested validation/date formatting, and flip traceability only in the same change set after behavior is proven. [VERIFIED: codebase grep + live repro]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Mailglass wrapper dispatch correctness | API / Backend | — | `attach_pdf/3`, `extract_swoosh/1`, and `put_swoosh/2` live in `lib/rendro/adapters/mailglass.ex`; the bug is server-side adapter logic, not caller-side UI behavior. [VERIFIED: lib/rendro/adapters/mailglass.ex] |
| Accrue invoice nested validation | API / Backend | — | `recipe/1` and `build_content/1` transform billing structs into a `Rendro.Document`; invalid nested input must be rejected at the adapter boundary. [VERIFIED: lib/rendro/adapters/accrue.ex] |
| Accrue `issued_at` normalization | API / Backend | — | The rendered header string is assembled inside `build_header/1`; date normalization belongs where the adapter maps domain structs to document content. [VERIFIED: lib/rendro/adapters/accrue.ex] |
| ADPT-05 / QUAL-04 traceability truth | CDN / Static | API / Backend | The status drift is in Markdown planning artifacts, but the correct status depends on backend adapter behavior and verification evidence. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md] |

## Standard Stack

The planner should introduce no new packages for Phase 10; the repo already has the runtime, test runner, and optional-adapter harness needed for this work. [VERIFIED: mix.exs; mix.lock; test/test_helper.exs; test/support/mocks.ex]

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Language/runtime for adapter and tests. | This is the repo’s declared runtime and the locally installed version. [VERIFIED: mix.exs + `elixir --version`] |
| OTP | 28 | BEAM runtime underneath Elixir. | Matches the local runtime and the repo’s documented stack. [VERIFIED: `elixir --version` + AGENTS.md] |
| ExUnit | built into Elixir 1.19.5 | Unit-test framework for regression coverage. | Existing adapter suites already use `ExUnit.Case`; no extra test framework is required. [VERIFIED: test/rendro/adapters/mailglass_test.exs; test/rendro/adapters/accrue_test.exs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:telemetry` | 1.4.1 | Existing project runtime dependency; not directly changed here. | Keep untouched; Phase 10 does not need new instrumentation to close its scope. [VERIFIED: mix.lock; https://hex.pm/packages/telemetry/versions] |
| Phoenix | 1.8.5 (optional) | Existing optional adapter ecosystem dependency. | Out of scope for Phase 10; do not pull it into the core path. [VERIFIED: mix.lock; https://hex.pm/packages/phoenix/versions] |
| Oban | 2.21.1 (optional) | Existing optional async adapter ecosystem dependency. | Out of scope for Phase 10; traceability work must not widen into Oban changes. [VERIFIED: mix.lock; https://hex.pm/packages/oban] |
| Repo-local adapter stubs | repo-local | Mailglass/Swoosh/Accrue stand-ins plus adapter recompilation for tests. | Use these for regression tests instead of adding real ecosystem deps to `mix.exs`. [VERIFIED: test/test_helper.exs; test/support/mocks.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing wrapper contract + module-local `update_swoosh/2` dispatch | Introduce a new behaviour/protocol for wrappers | Cleaner long-term polymorphism, but violates the locked scope for this phase and adds design work unrelated to the defect closure. [VERIFIED: 10-CONTEXT.md] |
| Strict nested `line_items` validation with typed error | Coerce maps/keywords into `%Accrue.LineItem{}` | More permissive ingestion, but conflicts with the locked “fail whole recipe deterministically” decision. [VERIFIED: 10-CONTEXT.md] |
| Date-only ISO 8601 header | Locale-aware or datetime-preserving output | Broader presentation flexibility, but conflicts with the locked `YYYY-MM-DD` contract and keeps user-visible variability. [VERIFIED: 10-CONTEXT.md; https://hexdocs.pm/elixir/Date.html; https://hexdocs.pm/elixir/DateTime.html; https://hexdocs.pm/elixir/NaiveDateTime.html] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** No new packages are recommended for Phase 10. The planner should use the repo-locked versions already present in `mix.exs`/`mix.lock`; `:telemetry`, Phoenix, and Oban versions above were cross-checked against current Hex package pages on 2026-04-28. [VERIFIED: mix.exs; mix.lock; https://hex.pm/packages/telemetry/versions; https://hex.pm/packages/phoenix/versions; https://hex.pm/packages/oban]

## Architecture Patterns

### System Architecture Diagram

```text
Caller input
  |
  +--> Mailglass path ------------------------------+
  |      struct admitted by `mailglass_message?/1`  |
  |      -> `extract_swoosh/1`                      |
  |      -> attach PDF to `%Swoosh.Email{}`         |
  |      -> `put_swoosh/2` via wrapper module       |
  |      -> updated wrapper or typed error          |
  |                                                 |
  +--> Accrue path ---------------------------------+
         `%Accrue.Invoice{}`                        |
         -> validate `line_items` + `issued_at`     |
         -> build header/content/footer             |
         -> `Rendro.flow/2`                         |
         -> `{:ok, %Rendro.Document{}}` or typed error

Verification/data-truth path
  code + tests + docs evidence
    -> Phase verification artifacts
    -> REQUIREMENTS traceability row update
```

This diagram reflects the current conceptual data flow already present in the codebase; Phase 10 only hardens the decision points and error exits. [VERIFIED: lib/rendro/adapters/mailglass.ex; lib/rendro/adapters/accrue.ex; .planning/REQUIREMENTS.md]

### Recommended Project Structure

```text
lib/rendro/adapters/        # Mailglass and Accrue adapter logic
test/rendro/adapters/       # Adapter regression/unit tests
test/support/               # Optional-dependency stubs and adapter recompilation
guides/                     # Public integration contract docs
.planning/                  # Requirement + verification traceability artifacts
```

The phase should stay inside these existing boundaries. [VERIFIED: repo tree + codebase grep]

### Pattern 1: Optional-Adapter Boundary With Test-Time Recompilation
**What:** Adapter files stay behind `Code.ensure_loaded?/1` in `lib/`, while `test/support/mocks.ex` defines stand-ins and `test/test_helper.exs` recompiles adapter files so the guarded modules exist in test. [VERIFIED: lib/rendro/adapters/mailglass.ex; lib/rendro/adapters/accrue.ex; test/test_helper.exs; test/support/mocks.ex]
**When to use:** For all Phase 10 tests; do not add real Mailglass/Swoosh/Accrue dependencies to core. [VERIFIED: AGENTS.md; mix.exs]
**Example:**
```elixir
# Source: test/test_helper.exs
ExUnit.start()
Rendro.Test.Mocks.ensure_table!()
Rendro.Test.Mocks.AdapterReloader.recompile()
```

### Pattern 2: Validate Before Building Document Content
**What:** `recipe/1` should reject invalid nested invoice data before `Enum.map/2` builds rows, returning `{:error, {:invalid_invoice, detail}}` instead of raising. [VERIFIED: lib/rendro/adapters/accrue.ex; .planning/phases/05-early-ecosystem-recipes/05-REVIEW.md]
**When to use:** Before any header/content/footer generation that assumes `%Accrue.LineItem{}` or temporal `issued_at` shapes. [VERIFIED: lib/rendro/adapters/accrue.ex]
**Example:**
```elixir
# Source: recommended from current adapter contract + review evidence
def recipe(%Accrue.Invoice{line_items: items} = invoice) when is_list(items) do
  case Enum.find(items, &(not match?(%Accrue.LineItem{}, &1))) do
    nil -> {:ok, build_document(invoice)}
    bad_item -> {:error, {:invalid_invoice, {:invalid_line_item, bad_item}}}
  end
end
```

### Pattern 3: Normalize Temporal Inputs to Date-Only ISO Text
**What:** Convert `DateTime` and `NaiveDateTime` to `Date` first, then render with `Date.to_iso8601/1`; use `Date.to_iso8601/1` directly for `Date`. [CITED: https://hexdocs.pm/elixir/Date.html] [CITED: https://hexdocs.pm/elixir/DateTime.html] [CITED: https://hexdocs.pm/elixir/NaiveDateTime.html]
**When to use:** Any user-visible invoice header text for `issued_at`. [VERIFIED: 10-CONTEXT.md]
**Example:**
```elixir
# Source: Elixir docs + Phase 10 decisions
defp format_issued_at(nil), do: nil
defp format_issued_at(%Date{} = d), do: Date.to_iso8601(d)
defp format_issued_at(%NaiveDateTime{} = ndt), do: ndt |> NaiveDateTime.to_date() |> Date.to_iso8601()
defp format_issued_at(%DateTime{} = dt), do: dt |> DateTime.to_date() |> Date.to_iso8601()
```

### Anti-Patterns to Avoid

- **Hardcoded canonical-module dispatch:** `put_swoosh/2` must not call `Mailglass.Message.update_swoosh/2` for every wrapper. Dispatch through `message.__struct__` first. [VERIFIED: lib/rendro/adapters/mailglass.ex; live repro via `MIX_ENV=test mix run -e ...`]
- **Outer-struct-only validation:** validating `%Accrue.Invoice{}` but not its nested `line_items` leaves a runtime crash path. [VERIFIED: lib/rendro/adapters/accrue.ex; live repro via `MIX_ENV=test mix run -e ...`]
- **`inspect/1` in user-facing PDF text:** debug formatting leaks Elixir syntax into invoices. [VERIFIED: lib/rendro/adapters/accrue.ex]
- **Traceability flip before evidence:** updating `REQUIREMENTS.md` without closing the code/test defects would preserve the same “docs say one thing, code says another” failure mode this phase exists to fix. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md; .planning/ROADMAP.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mailglass wrapper polymorphism | A new protocol/behaviour layer in Phase 10 | The admitted wrapper’s own `update_swoosh/2` plus existing `.Message` suffix gate | The phase already has a narrow locked contract; a new abstraction would expand scope without being required to fix the crash. [VERIFIED: 10-CONTEXT.md; lib/rendro/adapters/mailglass.ex] |
| Date formatting | Custom string interpolation with `inspect/1` or manual string slicing | `Date.to_iso8601/1`, `DateTime.to_date/1`, `NaiveDateTime.to_date/1` | The standard library already provides the exact date-only ISO conversion the phase requires. [CITED: https://hexdocs.pm/elixir/Date.html] [CITED: https://hexdocs.pm/elixir/DateTime.html] [CITED: https://hexdocs.pm/elixir/NaiveDateTime.html] |
| Optional dependency integration tests | Adding real Mailglass/Swoosh/Accrue deps to core `mix.exs` | Existing stubs + `AdapterReloader.recompile/0` harness | The project explicitly requires optional integrations to stay optional; the harness already exists and is working. [VERIFIED: mix.exs; test/test_helper.exs; test/support/mocks.ex; AGENTS.md] |
| Traceability validation | A new release-audit subsystem | Existing verification artifacts and direct `REQUIREMENTS.md` update | Phase 10 only needs to make the current traceability table truthful, not invent a new governance framework. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md] |

**Key insight:** The difficult parts of this phase are contract discipline and missing regression coverage, not missing infrastructure. Reuse the current adapter/test/planning scaffolding and only tighten the decision points that are currently lying or crashing. [VERIFIED: codebase grep + live repro]

## Common Pitfalls

### Pitfall 1: `function_exported?/3` Checked on the Wrong Module
**What goes wrong:** A valid custom wrapper reaches `put_swoosh/2`, but the code calls `Mailglass.Message.update_swoosh/2` instead of the wrapper’s own module, causing `FunctionClauseError`. [VERIFIED: lib/rendro/adapters/mailglass.ex; live repro via `MIX_ENV=test mix run -e ...`]
**Why it happens:** `mailglass_message?/1` admits any `.Message` module exporting `update_swoosh/2`, but `put_swoosh/2` ignores that module identity and hardcodes the canonical one. [VERIFIED: lib/rendro/adapters/mailglass.ex]
**How to avoid:** Derive `mod = message.__struct__`, dispatch through `apply(mod, :update_swoosh, ...)` first, and only fall back to field replacement/typed error according to the locked contract. [VERIFIED: 10-CONTEXT.md; .planning/phases/05-early-ecosystem-recipes/05-REVIEW.md]
**Warning signs:** A wrapper with a `:swoosh` field raises instead of returning an updated wrapper, while the canonical `%Mailglass.Message{}` path still passes tests. [VERIFIED: live repro + current test file]

### Pitfall 2: Nested Invalid Invoice Data Slips Past the Public Spec
**What goes wrong:** `recipe/1` claims a typed error contract but raises when any `line_items` entry is not `%Accrue.LineItem{}`. [VERIFIED: lib/rendro/adapters/accrue.ex; live repro via `MIX_ENV=test mix run -e ...`]
**Why it happens:** The validation exists only at the outer `%Accrue.Invoice{}` match; `Enum.map/2` enforces the nested shape by pattern-match exception. [VERIFIED: lib/rendro/adapters/accrue.ex]
**How to avoid:** Validate `line_items` before row construction and return the first offending item inside `{:error, {:invalid_invoice, ...}}`. [VERIFIED: 10-CONTEXT.md; .planning/phases/05-early-ecosystem-recipes/05-REVIEW.md]
**Warning signs:** Targeted `mix test` remains green, but a one-off `%Accrue.Invoice{line_items: [%{}]}` call raises a `FunctionClauseError`. [VERIFIED: current tests + live repro]

### Pitfall 3: Debug Rendering Bleeds Into User PDFs
**What goes wrong:** `Issued: ~D[2026-04-26]` appears in rendered invoice content. [VERIFIED: lib/rendro/adapters/accrue.ex; sample fixture in test/rendro/adapters/accrue_test.exs]
**Why it happens:** `build_header/1` interpolates `inspect(issued_at)` directly. [VERIFIED: lib/rendro/adapters/accrue.ex]
**How to avoid:** Normalize accepted temporal values to `Date` and render with `Date.to_iso8601/1`; document the exact accepted types. [CITED: https://hexdocs.pm/elixir/Date.html] [CITED: https://hexdocs.pm/elixir/DateTime.html] [CITED: https://hexdocs.pm/elixir/NaiveDateTime.html]
**Warning signs:** Tests only assert that `"INV-001"` and line-item names appear in inspected document output, not the exact `Issued:` string. [VERIFIED: test/rendro/adapters/accrue_test.exs]

### Pitfall 4: Requirements Status Updated Out of Order
**What goes wrong:** `REQUIREMENTS.md` says ADPT-05 is done while code/tests still reproduce Phase 5 defects, or stays pending after the defects are closed. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md; live repro]
**Why it happens:** The current traceability row is maintained manually and drifted away from the verification artifact. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md]
**How to avoid:** Treat the requirements-row change as the last task in the implementation sequence, gated on passing new regression tests and updated docs. [VERIFIED: .planning/ROADMAP.md; 10-CONTEXT.md]
**Warning signs:** A docs-only commit changes ADPT-05 status without any adapter/test updates in the same diff. [ASSUMED]

## Code Examples

Verified patterns from official sources and current repo patterns:

### Wrapper-Module Dispatch
```elixir
# Source: current Mailglass adapter contract + REVIEW CR-01
defp put_swoosh(message, swoosh_email) when is_struct(message) do
  mod = message.__struct__

  cond do
    function_exported?(mod, :update_swoosh, 2) ->
      apply(mod, :update_swoosh, [message, swoosh_email])

    Map.has_key?(message, :swoosh) ->
      %{message | swoosh: swoosh_email}

    Map.has_key?(message, :email) ->
      %{message | email: swoosh_email}

    true ->
      {:error, {:unrecognized_message_shape, mod}}
  end
end
```

### Date-Only ISO Formatting
```elixir
# Source: Elixir Date / DateTime / NaiveDateTime docs
defp format_issued_at(%Date{} = d), do: Date.to_iso8601(d)
defp format_issued_at(%NaiveDateTime{} = ndt), do: ndt |> NaiveDateTime.to_date() |> Date.to_iso8601()
defp format_issued_at(%DateTime{} = dt), do: dt |> DateTime.to_date() |> Date.to_iso8601()
```

### Regression Test Shape
```elixir
# Source: existing adapter test structure in this repo
test "returns typed error for invalid nested line item" do
  invoice = %Accrue.Invoice{sample_invoice() | line_items: [%{description: "bad"}]}

  assert {:error, {:invalid_invoice, {:invalid_line_item, %{description: "bad"}}}} =
           Adapter.recipe(invoice)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded `Mailglass.Message.update_swoosh/2` after generic wrapper admission | Dispatch through the admitted wrapper module first | Phase 10 target; defect still live on 2026-04-28 | Removes the last custom-wrapper crash path and makes the documented contract truthful. [VERIFIED: lib/rendro/adapters/mailglass.ex; live repro; .planning/phases/05-early-ecosystem-recipes/05-REVIEW.md] |
| `inspect(issued_at)` in invoice header | Normalize to `Date` and render as ISO 8601 date string | Phase 10 target; defect still live on 2026-04-28 | Eliminates Elixir syntax leakage from user-facing PDFs. [VERIFIED: lib/rendro/adapters/accrue.ex] [CITED: https://hexdocs.pm/elixir/Date.html] |
| Outer-struct-only invoice validation | Whole-invoice validation including nested `line_items` | Phase 10 target; defect still live on 2026-04-28 | Makes the `recipe/1` error contract deterministic and testable. [VERIFIED: lib/rendro/adapters/accrue.ex; live repro] |

**Deprecated/outdated:**
- `inspect/1` for user-facing invoice dates is outdated for this adapter contract and should be replaced in Phase 10. [VERIFIED: lib/rendro/adapters/accrue.ex]
- Treating ADPT-05 as either fully pending or fully satisfied without reconciling the remaining defect evidence is outdated; Phase 10 exists to reconcile that truthfully. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A docs-only ADPT-05 status flip without code/test closure would be considered process failure for this phase. | Common Pitfalls | Low; the roadmap and context strongly imply atomic closure, but the exact sequencing rule is process guidance rather than an explicit code contract. |

## Open Questions

1. **What exact nested error payload should Accrue return?**
   - What we know: It must remain under `{:error, {:invalid_invoice, _}}` and should point callers to the offending nested data. [VERIFIED: 10-CONTEXT.md]
   - What's unclear: Whether the payload should carry the bad item only, the full `line_items` list, or a tagged tuple such as `{:invalid_line_item, bad_item}`. [VERIFIED: 10-CONTEXT.md]
   - Recommendation: Prefer `{:invalid_line_item, bad_item}` because it is precise, minimal, and easy to test. [ASSUMED]

2. **What should happen when `issued_at` is `nil`?**
   - What we know: The date contract is locked for `Date`, `NaiveDateTime`, and `DateTime`; nil handling is discretionary. [VERIFIED: 10-CONTEXT.md]
   - What's unclear: Whether the header should omit the `Issued:` line entirely or keep a stable blank/placeholder row. [VERIFIED: 10-CONTEXT.md]
   - Recommendation: Omit the line entirely to avoid empty user-facing chrome, unless layout consistency tests show the extra row is required. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile and run adapter tests/repros | ✓ | 1.19.5 | — |
| OTP | Runtime for Elixir/Mix | ✓ | 28 | — |
| Mix | `mix test` / `mix run` verification | ✓ | 1.19.5 | — |
| Git | Traceability file diff/review and optional commit step | ✓ | available | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: `elixir --version`; `mix --version`; `git status --short`]

**Missing dependencies with fallback:**
- None. [VERIFIED: local environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5; repo also has `ExUnitProperties` via `:stream_data`, but this phase only needs example-based regression tests. [VERIFIED: mix.exs; test/support/generators.ex; `elixir --version`] |
| Config file | `mix.exs` plus `test/test_helper.exs`. [VERIFIED: mix.exs; test/test_helper.exs] |
| Quick run command | `MIX_ENV=test mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/accrue_test.exs` [VERIFIED: local command run] |
| Full suite command | `mix test` [VERIFIED: mix.exs + repo test tree] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADPT-05 | Custom `.Message` wrapper with `:swoosh` and own `update_swoosh/2` returns updated wrapper, not `FunctionClauseError`. [VERIFIED: .planning/ROADMAP.md; live repro] | unit | `MIX_ENV=test mix test test/rendro/adapters/mailglass_test.exs` | ✅ |
| ADPT-05 | Invalid nested `line_items` entry returns `{:error, {:invalid_invoice, _}}`, not raise. [VERIFIED: .planning/ROADMAP.md; live repro] | unit | `MIX_ENV=test mix test test/rendro/adapters/accrue_test.exs` | ✅ |
| ADPT-05 | `issued_at` renders as `YYYY-MM-DD`, not `~D[...]`. [VERIFIED: .planning/ROADMAP.md; lib/rendro/adapters/accrue.ex] | unit | `MIX_ENV=test mix test test/rendro/adapters/accrue_test.exs` | ✅ |
| QUAL-04 | `REQUIREMENTS.md` ADPT-05 traceability row reads done and matches verification artifact after code closure. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md] | doc consistency | `rg -n \"ADPT-05\" .planning/REQUIREMENTS.md .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md` | ✅ |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/accrue_test.exs` [VERIFIED: local command run]
- **Per wave merge:** `mix test` [VERIFIED: repo test tree]
- **Phase gate:** targeted adapter tests green, docs updated, and traceability row reconciled before `/gsd-verify-work`. [VERIFIED: .planning/ROADMAP.md; 10-CONTEXT.md]

### Wave 0 Gaps

- [ ] `test/rendro/adapters/mailglass_test.exs` needs one success-path regression for a non-canonical wrapper that has both `:swoosh` and its own `update_swoosh/2`. [VERIFIED: current test file + live repro]
- [ ] `test/rendro/adapters/accrue_test.exs` needs one negative-path regression for invalid nested `line_items`. [VERIFIED: current test file + live repro]
- [ ] `test/rendro/adapters/accrue_test.exs` needs one assertion on exact `Issued:` rendering for `Date`, and likely coverage for `NaiveDateTime`/`DateTime` if Phase 10 adopts the locked multi-type contract. [VERIFIED: current test file; 10-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not in scope for these pure adapter/doc changes. [VERIFIED: phase scope in .planning/ROADMAP.md] |
| V3 Session Management | no | Not in scope for these pure adapter/doc changes. [VERIFIED: phase scope in .planning/ROADMAP.md] |
| V4 Access Control | no | Not in scope for these pure adapter/doc changes. [VERIFIED: phase scope in .planning/ROADMAP.md] |
| V5 Input Validation | yes | Validate wrapper shape and nested invoice contents at the adapter boundary; return typed tuples instead of raising. [VERIFIED: lib/rendro/adapters/mailglass.ex; lib/rendro/adapters/accrue.ex; 10-CONTEXT.md] |
| V6 Cryptography | no | Phase 10 touches no crypto or signing behavior. [VERIFIED: phase scope in .planning/ROADMAP.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed adapter payload causes process crash (`FunctionClauseError`) | Denial of Service | Boundary validation plus tuple-returning error surfaces. [VERIFIED: live repro; 10-CONTEXT.md] |
| User-visible invoice content includes debug syntax or unexpected coercions | Tampering | Normalize accepted temporal inputs explicitly and reject unsupported nested data rather than guessing. [VERIFIED: lib/rendro/adapters/accrue.ex; 10-CONTEXT.md] |
| Requirements table misstates verified behavior | Repudiation | Update traceability only from current verification evidence and keep docs/tests/code aligned in one phase. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md; .planning/ROADMAP.md] |

## Sources

### Primary (HIGH confidence)

- Repo source files: `lib/rendro/adapters/mailglass.ex`, `lib/rendro/adapters/accrue.ex`, `test/rendro/adapters/mailglass_test.exs`, `test/rendro/adapters/accrue_test.exs`, `test/test_helper.exs`, `test/support/mocks.ex` - current behavior, current coverage gaps, and existing test harness. [VERIFIED: codebase grep]
- Planning artifacts: `.planning/phases/10-recipe-correctness-and-traceability/10-CONTEXT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/05-early-ecosystem-recipes/05-REVIEW.md`, `.planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md`, `.planning/phases/05-early-ecosystem-recipes/05-HUMAN-UAT.md` - locked scope, prior findings, and traceability drift. [VERIFIED: codebase grep]
- Local command evidence: `MIX_ENV=test mix run -e ...` repros for Mailglass wrapper crash and Accrue nested validation crash; `MIX_ENV=test mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/accrue_test.exs` - current behavior reproduced and current tests still passing. [VERIFIED: local command output]
- Elixir docs: `Date.to_iso8601/1`, `DateTime.to_date/1`, `NaiveDateTime.to_date/1`, `function_exported?/3` docs. [CITED: https://hexdocs.pm/elixir/Date.html] [CITED: https://hexdocs.pm/elixir/DateTime.html] [CITED: https://hexdocs.pm/elixir/NaiveDateTime.html] [CITED: https://hexdocs.pm/elixir/Kernel.html]
- Hex package pages: current package version pages for `:telemetry`, Phoenix, and Oban. [CITED: https://hex.pm/packages/telemetry/versions] [CITED: https://hex.pm/packages/phoenix/versions] [CITED: https://hex.pm/packages/oban]

### Secondary (MEDIUM confidence)

- None. All critical claims above were verified against code, local repros, or official docs. [VERIFIED: research session evidence]

### Tertiary (LOW confidence)

- None beyond the explicit assumptions listed in `## Assumptions Log`. [VERIFIED: research session evidence]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies are needed and the relevant runtime/test stack is directly verifiable from `mix.exs`, `mix.lock`, and local tooling. [VERIFIED: mix.exs; mix.lock; local environment probes]
- Architecture: HIGH - both defects and the required fix boundaries are directly visible in current source and reinforced by locked phase decisions. [VERIFIED: codebase grep; 10-CONTEXT.md]
- Pitfalls: HIGH - the two runtime crashes were reproduced locally and the doc drift is explicit in planning artifacts. [VERIFIED: live repro; .planning/REQUIREMENTS.md; .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md]

**Research date:** 2026-04-28
**Valid until:** 2026-05-28
