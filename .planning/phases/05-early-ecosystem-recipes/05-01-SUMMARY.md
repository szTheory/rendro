---
phase: 05-early-ecosystem-recipes
plan: "01"
subsystem: adapters
tags: [adapters, threadline, mailglass, swoosh, telemetry, audit, optional-deps]

# Dependency graph
requires:
  - phase: 04
    provides: "Telemetry instrumentation with [:rendro, :render] top-level span and structured stop/exception metadata"
  - phase: 04
    provides: "Optional adapter pattern (Code.ensure_loaded?/1) demonstrated by Rendro.Adapters.Oban.RenderWorker"
provides:
  - "Rendro.Audit behavior — pluggable audit logging contract for render lifecycle"
  - "Rendro.Adapters.Threadline — optional Telemetry-driven audit forwarder"
  - "Rendro.Adapters.Mailglass — optional PDF attachment helper for Swoosh emails and Mailglass messages"
  - "Test infrastructure for verifying optional adapters without adding ecosystem deps to mix.exs"
affects: [phase-05-billing-recipes, ecosystem-integration, audit-trail]

# Tech tracking
tech-stack:
  added:
    - "ETS-backed test stub strategy for cross-process telemetry capture"
  patterns:
    - "Optional adapter compile guard via Code.ensure_loaded?/1"
    - "Telemetry handler -> audit behavior delegation"
    - "Test-time adapter recompilation for guards that depend on test-only stubs"

key-files:
  created:
    - "lib/rendro/audit.ex"
    - "lib/rendro/adapters/threadline.ex"
    - "lib/rendro/adapters/mailglass.ex"
    - "test/rendro/adapters/threadline_test.exs"
    - "test/rendro/adapters/mailglass_test.exs"
    - "test/support/mocks.ex"
  modified:
    - "test/test_helper.exs"

key-decisions:
  - "Threadline adapter listens on the top-level [:rendro, :render, :stop] and [:rendro, :render, :exception] spans rather than per-stage events, so one audit row per render."
  - "Mailglass adapter accepts Swoosh.Email or Mailglass.Message and uses Mailglass.Message.update_swoosh/2 when present so it can route through Mailglass middleware without coupling."
  - "Optional adapter modules use compile-time Code.ensure_loaded?/1 guards; test stubs recompile the adapter files at runtime in test_helper.exs so the guarded module bodies are reachable."
  - "Threadline test stub captures calls in an ETS table keyed by the test pid (resolved via $callers) so cross-process telemetry handlers fired inside Pipeline.run's Task.async are still observable from the test process."

patterns-established:
  - "Optional adapter compile guard: wrap module body in `if Code.ensure_loaded?(Lib) do defmodule Rendro.Adapters.Lib do ... end end` to keep the package self-contained when the optional dep is absent."
  - "Audit behavior delegation: adapters that integrate audit backends declare `@behaviour Rendro.Audit` and implement track_render/2, then their telemetry handler delegates to that callback so users can swap implementations."
  - "PII-safe metadata forwarding: only telemetry stop/exception metadata is propagated downstream — never document bodies, attachment binaries, or rendered PDFs."

requirements-completed: [ADPT-05]

# Metrics
duration: 6min
completed: 2026-04-26
---

# Phase 05 Plan 01: Threadline + Mailglass Optional Adapters Summary

**Adds optional Threadline audit and Mailglass email-attachment adapters that wrap the existing Rendro telemetry/render APIs, with zero new core dependencies and contract-mock-driven test coverage.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-04-26T17:34:55Z
- **Completed:** 2026-04-26T17:40:50Z
- **Tasks:** 3 of 3 completed
- **Files created:** 6
- **Files modified:** 1

## Accomplishments

- Defined `Rendro.Audit` behavior so any audit backend can plug in via a single `track_render/2` callback.
- Shipped `Rendro.Adapters.Threadline` that subscribes to the `[:rendro, :render, :stop]` and `[:rendro, :render, :exception]` telemetry spans and forwards `:render_succeeded` / `:render_failed` actions with PII-safe metadata.
- Shipped `Rendro.Adapters.Mailglass.attach_pdf/3` that renders a Rendro document and attaches the resulting PDF to a Swoosh email or a Mailglass message (preserving Mailglass's wrapper via `update_swoosh/2`).
- Built a reusable test-stub harness (`test/support/mocks.ex` + `test_helper.exs` recompile hook) that lets optional adapters be exercised without dragging Threadline, Mailglass, or Swoosh into `mix.exs` — preserving the "core has no ecosystem deps" guarantee.

## Task Commits

1. **Task 1: Define Rendro.Audit behavior and Threadline adapter** — `e5575b3` (feat)
2. **Task 2: Implement Mailglass attachment helper** — `cd17151` (feat)
3. **Task 3: Verify adapters with contract mocks (TDD)** — `c600e8e` (test)

## Files Created/Modified

- `lib/rendro/audit.ex` — Defines the `Rendro.Audit` behavior (`track_render/2`) with PII-safety guidance.
- `lib/rendro/adapters/threadline.ex` — Optional Threadline adapter; `attach/0`, `detach/0`, telemetry handler, and `track_render/2` impl.
- `lib/rendro/adapters/mailglass.ex` — Optional Mailglass adapter; `attach_pdf/3` renders the doc and attaches the PDF binary, supporting Swoosh and Mailglass inputs.
- `test/rendro/adapters/threadline_test.exs` — 11 tests covering telemetry-to-audit mapping, PII safety, attach/detach idempotence, render_id propagation, duration forwarding, and `track_render/2` direct invocation.
- `test/rendro/adapters/mailglass_test.exs` — 7 tests covering Swoosh email attachment, default filename, field preservation, PDF binary payload (with `%PDF-` magic check), Mailglass message wrapping, and render-failure error path.
- `test/support/mocks.ex` — In-test stand-ins for `Threadline`, `Mailglass.Message`, `Mailglass`, `Swoosh.Email`, and `Swoosh.Attachment`; ETS-backed call recorder; adapter recompilation helper.
- `test/test_helper.exs` — Added `ensure_table!/0` and `AdapterReloader.recompile/0` calls after `ExUnit.start()`.

## Decisions Made

1. **Listen on the top-level render span only.** Phoenix-style audit trails want one row per render, so the Threadline handler subscribes to `[:rendro, :render, :stop]` (and `:exception`) rather than per-stage events. Per-stage detail is still available via the existing telemetry stream.
2. **ETS-backed test stub instead of process dictionary.** `Rendro.Pipeline.run/1` runs the render inside `Task.async`, so telemetry handlers fire in the Task process — not the test process. The Threadline mock therefore writes to a named ETS table and resolves the "owning" test pid via the `:"$callers"` ancestry chain that `Task` populates.
3. **Test-time adapter recompilation.** The optional adapters in `lib/` use `if Code.ensure_loaded?(Mailglass) do ... end` style compile guards. Because `lib/` compiles before `test/support/`, those guards evaluate to `false` at first compile, so the module bodies would never be defined. `test_helper.exs` calls `AdapterReloader.recompile/0` after the stubs are loaded, re-evaluating the guards so the test environment exercises the real adapter code paths.
4. **PII-safe metadata projection.** The Threadline handler only forwards keys from a fixed allowlist (`:render_id`, `:stage`, `:status`, `:page_count`, `:byte_size`, `:document_type`, `:deterministic`, `:kind`, `:reason`) plus `:duration` from measurements. It never forwards document bodies, blocks, or rendered binaries — addressing T-05-01 in the plan's threat register.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Test infrastructure] Adapter modules invisible at test time due to compile-order**

- **Found during:** Task 3 — the first test run reported `Rendro.Adapters.Threadline.attach/0 is undefined (module ... is not available)`.
- **Issue:** Optional adapters in `lib/` are wrapped in `if Code.ensure_loaded?(Threadline)` etc. Because Mix compiles `lib/` before `test/support/`, the stub modules in `test/support/mocks.ex` did not exist when the adapter files were first compiled, so the guarded module bodies were skipped entirely.
- **Fix:** Added `Rendro.Test.Mocks.AdapterReloader.recompile/0` (called from `test_helper.exs` after `ExUnit.start()`) which calls `Code.compile_file/1` on each adapter file with the stubs already loaded, re-evaluating the guards.
- **Files modified:** `test/support/mocks.ex`, `test/test_helper.exs`.
- **Verification:** All 14 adapter tests pass; full suite remains green (3 properties, 182 tests, 0 failures).
- **Committed in:** `c600e8e` (Task 3 commit).

**2. [Rule 1 - Bug] Process-dictionary stub lost telemetry events fired inside Pipeline's Task**

- **Found during:** Task 3 — Threadline mapping tests reported empty call lists even though the handler was attached.
- **Issue:** `Rendro.Pipeline.run/1` wraps execution in `Task.async`, so telemetry handlers (and therefore `Threadline.record_action/2`) execute inside the spawned Task process. The first version of the stub used `Process.put` keyed on `self()`, which was the Task's pid — its dict was discarded at the end of the render and the test process saw nothing.
- **Fix:** Rewrote the Threadline stub to write to a named ETS table (`:rendro_threadline_calls`) keyed by the "owning" test pid, resolved via the `:"$callers"` ancestry chain that `Task` populates on spawned processes.
- **Files modified:** `test/support/mocks.ex`.
- **Verification:** Threadline mapping, render_id propagation, duration, and detach-suppression tests now pass.
- **Committed in:** `c600e8e` (Task 3 commit).

**3. [Rule 1 - Test correctness] Over-specified PII metadata assertion**

- **Found during:** Task 3 — final test run reported `missing metadata key :document_type`.
- **Issue:** The initial test asserted `:document_type` would be present on the audit metadata, but the existing Pipeline only includes `:document_type` in *start* event metadata; *stop* events carry `:status`, `:page_count`, and `:byte_size`. The Threadline handler only sees stop/exception metadata, so `:document_type` is not available.
- **Fix:** Tightened the test assertion to the keys actually emitted on stop events (`:render_id`, `:status`, `:page_count`, `:byte_size`).
- **Files modified:** `test/rendro/adapters/threadline_test.exs`.
- **Verification:** All 14 adapter tests now pass; assertion accurately reflects the emitted metadata.
- **Committed in:** `c600e8e` (Task 3 commit; not separately committed because it was part of the same TDD iteration).

## Verification

- `mix compile` — clean.
- `mix test test/rendro/adapters/` — 14 tests, 0 failures.
- `mix test` (full suite) — 3 properties, 182 tests, 0 failures.

### Note on type-checker output

In test mode the Elixir 1.19 type-checker emits an informational "typing violation" for `Rendro.Adapters.Threadline.track_render/2` because the Threadline *stub* always returns `:ok`, making the `{:error, _} -> err` fallback look unreachable. This is a test-environment artifact only; in production `Threadline.record_action/2` may return `{:ok, _}`, `:ok`, or `{:error, _}`, and the fallback clauses are intentional. The message is informational and does not fail `mix compile --warnings-as-errors`.

## Threat Surface Recap

The plan's `<threat_model>` listed two `mitigate` items; both are addressed:

| Threat ID | Mitigation status |
|-----------|-------------------|
| T-05-01 (Threadline information disclosure) | Adapter forwards only allowlisted telemetry keys + `:duration`; tests assert no document/binary leakage. |
| T-05-02 (Mailglass DoS via large attachments) | `attach_pdf/3` calls `Rendro.render/1`, which is bound by the existing `policies` (max_pages, max_bytes) on the document — no new bypass introduced. |

No new threat surface emerged outside the plan's threat model.

## Success Criteria

- [x] `Rendro.Audit` behavior exists.
- [x] `Rendro.Adapters.Threadline` attaches to telemetry and calls `Threadline.record_action`.
- [x] `Rendro.Adapters.Mailglass.attach_pdf` correctly attaches rendered PDFs to Swoosh emails.
- [x] All tests pass without requiring external libraries to be installed in `mix.exs`.

## Self-Check: PASSED

- All listed key files exist on disk (`lib/rendro/audit.ex`, `lib/rendro/adapters/threadline.ex`, `lib/rendro/adapters/mailglass.ex`, `test/rendro/adapters/threadline_test.exs`, `test/rendro/adapters/mailglass_test.exs`, `test/support/mocks.ex`).
- All listed task commits exist in git history (`e5575b3`, `cd17151`, `c600e8e`).
- Full test suite passes (182 tests, 0 failures).
