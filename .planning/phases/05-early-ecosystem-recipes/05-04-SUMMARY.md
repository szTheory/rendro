---
phase: "05-early-ecosystem-recipes"
plan: "04"
subsystem: docs
tags: [docs, integrations, threadline, mailglass, accrue, gap-closure, ex-doc]
dependency_graph:
  requires:
    - "05-02 (Accrue adapter as shipped — recipe/1 contract, Accrue.Invoice fields)"
    - "05-03 (Mailglass contract fixes — two new error tuple shapes CR-01/CR-02/WR-03)"
  provides:
    - "guides/integrations.md — integration guide covering all three adapters"
    - "mix.exs :extras updated to include guides/integrations.md for ExDoc"
    - "README.md Ecosystem Integrations section pointing to guides/integrations.md"
  affects:
    - "guides/integrations.md (created)"
    - "mix.exs (extended)"
    - "README.md (extended)"
tech_stack:
  added: []
  patterns:
    - "ExDoc extras list for project guides"
key_files:
  created:
    - guides/integrations.md
  modified:
    - mix.exs
    - README.md
decisions:
  - "Integration guide created at guides/integrations.md (not moduledocs) so it is a single unified reference rendered by ExDoc"
  - "WR-01 timeout-audit gap documented as a known limitation under the exact verbatim opening sentence required by the plan"
  - "WR-02, WR-04, WR-05, WR-06, IN-01..IN-04 intentionally NOT addressed — out of scope per gap-closure directive"
metrics:
  duration_minutes: 5
  completed_date: "2026-04-26"
  tasks_completed: 2
  files_changed: 3
---

# Phase 05 Plan 04: Integration Guide for threadline/mailglass/accrue Summary

Integration guide published at `guides/integrations.md` covering setup, verification, and failure diagnostics for all three optional adapters (`threadline`, `mailglass`, `accrue`), wired into ExDoc via `mix.exs :extras`, and pointed to from `README.md`.

## Tasks Completed

| Task | Name | Commit | Type | Files |
|------|------|--------|------|-------|
| 1 | Author guides/integrations.md | `5d23f11` | docs | guides/integrations.md |
| 2 | Wire into ExDoc and add README pointer | `a023127` | docs | mix.exs, README.md |

## What Was Built

### guides/integrations.md — Section Structure

```
# Rendro Integrations
## Overview
## Threadline
   ### Setup
   ### Verification
   ### Failure diagnostics
   ### Known limitation: pipeline timeouts are not audited
## Mailglass
   ### Setup
   ### Verification
   ### Failure diagnostics
## Accrue
   ### Setup
   ### Recipe contract
   ### Verification
   ### Failure diagnostics
## Optional-dependency discipline
```

388 lines total (within the 200-400 target). All acceptance-criteria headings verified present.

### WR-01 Known Limitation Documentation

The Threadline section contains the mandatory verbatim opening sentence and a full explanation of why timeouts are not audited:

> "Render timeouts enforced by `Rendro.Pipeline.run/1` are NOT currently audited by `Rendro.Adapters.Threadline`."

It explains the `Task.async` mechanism, what callers receive vs. what audit records are created, and provides a concrete operator mitigation pattern (manual Threadline call at the call site). It notes the item is tracked as WR-01 for a future Pipeline change.

### Error Tuple Shapes Documented (cross-referenced against 05-02 and 05-03 SUMMARYs)

**Mailglass** (post 05-03 fixes):
- `{:error, %Rendro.Error{reason: {:invalid_email_target, value}}}` — non-Swoosh, non-Mailglass-message input (CR-02 fix)
- `{:error, {:unrecognized_message_shape, struct_module}}` — Mailglass-like struct with no `:swoosh` or `:email` field (CR-01 fix)
- `{:error, %Rendro.Error{}}` — propagated from `Rendro.render/1`

**Threadline**:
- `:ok` — successful audit record
- `{:error, term()}` — Threadline backend returned `{:error, reason}`
- `{:error, {:unexpected_return, term()}}` — Threadline returned unexpected shape
- `{:error, {:exception, Exception.t()}}` — Threadline raised; adapter rescued and wrapped

**Accrue** (post 05-02):
- `{:error, {:invalid_invoice, term()}}` — non-`%Accrue.Invoice{}` input
- Render-time errors flow through `Rendro.render/1` → `{:error, %Rendro.Error{}}` with `:stage` in `:build|:compose|:measure|:paginate|:render`

### ExDoc Wiring (mix.exs)

```elixir
defp docs do
  [
    main: "Rendro",
    source_url: @source_url,
    extras: [
      "README.md",
      "guides/integrations.md"
    ]
  ]
end
```

### README.md Ecosystem Integrations Section

Added between `## Phoenix Integration` and `## Policies`:

```markdown
## Ecosystem Integrations

Rendro ships optional adapters for `threadline` (audit logging),
`mailglass` (transactional email attachments), and `accrue` (billing
recipes). None of them are hard dependencies of Rendro — each adapter is
compiled only when its target library is present in your application's
own `mix.exs`.

See [guides/integrations.md](guides/integrations.md) for setup steps,
verification recipes, and failure-diagnostics reference for each adapter.
```

## Deviations from Plan

None - plan executed exactly as written.

The `mix compile --warnings-as-errors` and `mix test` commands were run via the main project directory (deps available there) since the worktree does not have its own `_build`/`deps`. The compile step exited 0 and the full test suite passed (3 properties, 191 tests, 0 failures).

## Out of Scope (per gap-closure directive)

The following items from 05-REVIEW.md were intentionally NOT addressed in this plan:

- **WR-01:** Documented as a known limitation in the Threadline section of the guide, but NOT fixed.
- **WR-02:** Threadline `handle_event/4` defaults to `:render_succeeded` for unrecognized status values — not addressed.
- **WR-04:** `test_pid/0` only inspects head of `:"$callers"` chain — not addressed.
- **WR-05:** `track_render/2` swallows arbitrary exceptions without logging — not addressed.
- **WR-06:** `Rendro.render/1` called without options, blocking opts pass-through — not addressed.
- **IN-01..IN-04:** Info-level findings (doc discrepancy, Swoosh stub shadowing, recompile warnings, ETS race) — not addressed.

These remain available for future phases.

## Verification Results

```
test -f guides/integrations.md         → EXISTS
grep -c "^# Rendro Integrations$"       → 1
grep -c "^## Overview$"                 → 1
grep -c "^## Threadline$"               → 1
grep -c "^## Mailglass$"                → 1
grep -c "^## Accrue$"                   → 1
grep -c "^## Optional-dependency discipline$" → 1
grep -c "^### Failure diagnostics$"     → 3
grep -c "^### Verification$"            → 3
grep -c "^### Setup$"                   → 3
grep -c "Known limitation:..."          → 1
grep -c "Render timeouts enforced by..." → 1 (verbatim)
grep -c "{:invalid_email_target,"       → 1
grep -c "{:unrecognized_message_shape," → 1
grep -c "{:invalid_invoice,"            → 1
wc -l guides/integrations.md           → 388
awk docs block: guides/integrations.md → present
grep -c "## Ecosystem Integrations" README.md → 1
grep -c "guides/integrations.md" README.md    → 1
mix compile --warnings-as-errors        → exit 0
mix test                                → 3 properties, 191 tests, 0 failures
```

## Known Stubs

None. The guide is complete documentation with no placeholder text. All code snippets
use synthetic data per T-05-04-03 (accepted, no real-world secrets).

## Threat Flags

None. All three threat register items from the plan were addressed:

| Threat ID | Mitigation status |
|-----------|-------------------|
| T-05-04-01 (Repudiation — overstated audit coverage) | WR-01 is explicitly documented as a known limitation with the verbatim sentence "Render timeouts enforced by `Rendro.Pipeline.run/1` are NOT currently audited..." |
| T-05-04-02 (Tampering — doc/source drift) | Error tuple atoms `:invalid_email_target`, `:unrecognized_message_shape`, `:invalid_invoice` all appear in the guide and were verified against 05-02 and 05-03 SUMMARY post-fix contracts. |
| T-05-04-03 (Information Disclosure — code samples) | All code samples use synthetic data (`"INV-001"`, `"customer@example.test"`, `"Acme Corp"`, etc.). |

## Self-Check: PASSED

Files created/modified:
- FOUND: guides/integrations.md
- FOUND: mix.exs (contains guides/integrations.md in :extras)
- FOUND: README.md (contains ## Ecosystem Integrations and guides/integrations.md link)

Commits:
- FOUND: 5d23f11 (docs(05-04): author guides/integrations.md...)
- FOUND: a023127 (docs(05-04): publish integration guide for threadline/mailglass/accrue...)

Tests: 3 properties, 191 tests, 0 failures (mix test exit 0)
Compile: mix compile --warnings-as-errors exit 0
