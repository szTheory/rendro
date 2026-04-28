---
phase: 05-early-ecosystem-recipes
verified: 2026-04-26T20:00:00Z
status: passed
score: 7/7 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/7
  gaps_closed:
    - "Accrue adapter missing — lib/rendro/adapters/accrue.ex now exists and is fully implemented"
    - "Integration documentation missing — guides/integrations.md published with Setup/Verification/Failure diagnostics per adapter"
    - "Mailglass CR-01/CR-02/WR-03 contract violations — extract_swoosh, attach_binary fallback, mailglass_message? all corrected"
    - "Phase 10 closes REVIEW CR-01, WR-06, and IN-04 with automated regression coverage in the Mailglass and Accrue adapter tests"
  gaps_remaining: []
  regressions: []
human_verification: []
---

# Phase 05: Early Ecosystem Recipes — Re-Verification Report

**Phase Goal:** Provide validated do-now integration recipes for high-value ecosystem workflows while preserving architecture boundaries.
**Verified:** 2026-04-26T20:00:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (05-02, 05-03, 05-04) and Phase 10 recipe regressions

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                                                 | Status      | Evidence                                                                                                                                           |
|----|-----------------------------------------------------------------------------------------------------------------------|-------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| 1  | Maintainers can follow tested recipes for `threadline`, `mailglass`, and `accrue`                                     | ✓ VERIFIED  | All three adapters exist with `Code.ensure_loaded?` guard, contract-mock tests pass; 191 tests, 0 failures                                         |
| 2  | Recipes remain optional and do not introduce hard dependencies into core                                              | ✓ VERIFIED  | `defp deps do` block contains no `:threadline`, `:mailglass`, `:accrue`, or `:swoosh` entries; each adapter wrapped in `if Code.ensure_loaded?`    |
| 3  | Integration documentation includes verification guidance and failure diagnostics                                      | ✓ VERIFIED  | `guides/integrations.md` (388 lines): Setup/Verification/Failure diagnostics per adapter; wired into ExDoc extras; README links to it              |
| 4  | `Rendro.Audit` behavior is defined and documented                                                                     | ✓ VERIFIED  | `lib/rendro/audit.ex` defines `@callback track_render(render_id, metadata) :: :ok | {:error, term()}` with full moduledoc and PII guidance         |
| 5  | Threadline adapter is optional and gated by `Code.ensure_loaded?(Threadline)`                                         | ✓ VERIFIED  | Line 1 of `lib/rendro/adapters/threadline.ex`; module absent when Threadline not loaded                                                            |
| 6  | Threadline adapter attaches to Telemetry and records render events                                                    | ✓ VERIFIED  | `attach/0` registers `[:rendro, :render, :stop]` and `[:rendro, :render, :exception]`; delegates to `Threadline.record_action/2` via `track_render/2` |
| 7  | Mailglass adapter is optional and provides PDF attachment helper with correct error-tuple contract                    | ✓ VERIFIED  | Gated by `Code.ensure_loaded?(Mailglass)`; CR-01/CR-02/WR-03 fixes confirmed in source; 10 tests pass (6 happy + 4 negative-path)                 |

**Score:** 7/7 truths verified

### Roadmap Success Criteria Coverage

| SC  | Criterion                                                                          | Status     | Evidence                                                                                |
|-----|------------------------------------------------------------------------------------|------------|-----------------------------------------------------------------------------------------|
| SC1 | Maintainers can follow tested recipes for `threadline`, `mailglass`, and `accrue` | ✓ VERIFIED | Adapters at `lib/rendro/adapters/{threadline,mailglass,accrue}.ex`; all test suites pass |
| SC2 | Recipes remain optional and do not introduce hard dependencies into core           | ✓ VERIFIED | `mix.exs` deps block — zero ecosystem lib entries; `Code.ensure_loaded?` guards on all three |
| SC3 | Integration documentation includes verification guidance and failure diagnostics   | ✓ VERIFIED | `guides/integrations.md` with all required sections; ExDoc wired; README pointer        |

### Required Artifacts

| Artifact                                     | Expected                                              | Status     | Details                                                                                                           |
|----------------------------------------------|-------------------------------------------------------|------------|-------------------------------------------------------------------------------------------------------------------|
| `lib/rendro/audit.ex`                        | Audit behavior definition                             | ✓ VERIFIED | Defines `Rendro.Audit` behavior with `track_render/2` callback                                                   |
| `lib/rendro/adapters/threadline.ex`          | Optional Threadline integration                       | ✓ VERIFIED | `if Code.ensure_loaded?(Threadline)` guard; `attach/0`, `detach/0`, `handle_event/4`, `track_render/2` present   |
| `lib/rendro/adapters/mailglass.ex`           | Optional Mailglass integration (with CR-01/02/WR-03 fixes) | ✓ VERIFIED | `if Code.ensure_loaded?(Mailglass)` guard; CR-02 `true ->` arm returns error tuple (not raises); CR-01 `extract_swoosh/1` returns `{:ok, _}` or `{:error, {:unrecognized_message_shape, _}}`; WR-03 `mailglass_message?/1` narrowed to `.Message` suffix + `function_exported?(mod, :update_swoosh, 2)` |
| `lib/rendro/adapters/accrue.ex`              | Optional Accrue billing-document recipe               | ✓ VERIFIED | `if Code.ensure_loaded?(Accrue)` guard; `recipe/1` returns `{:ok, %Rendro.Document{}}` or `{:error, {:invalid_invoice, _}}` |
| `test/rendro/adapters/threadline_test.exs`   | Threadline adapter tests                              | ✓ VERIFIED | 11 tests: telemetry mapping, PII safety, attach/detach idempotence, render_id propagation                        |
| `test/rendro/adapters/mailglass_test.exs`    | Mailglass adapter tests including negative paths       | ✓ VERIFIED | 10 tests: 6 happy-path + 4 negative-path; `describe "attach_pdf/3 negative paths"` confirmed present            |
| `test/rendro/adapters/accrue_test.exs`       | Accrue adapter tests                                  | ✓ VERIFIED | 5 tests across 3 describe blocks: happy path, render integration, optional-gating proof, input validation        |
| `test/support/mocks.ex`                      | Test stubs including Accrue modules                   | ✓ VERIFIED | `Accrue.LineItem`, `Accrue.Invoice`, `Accrue` marker modules present; `AdapterReloader` includes `accrue.ex`     |
| `guides/integrations.md`                     | Integration guide with all required sections          | ✓ VERIFIED | 388 lines; H2: Overview/Threadline/Mailglass/Accrue/Optional-dependency discipline; 3x H3 Setup/Verification/Failure diagnostics; WR-01 known limitation documented with verbatim opening sentence |
| `mix.exs` docs extras                        | ExDoc config includes `guides/integrations.md`        | ✓ VERIFIED | `extras: ["README.md", "guides/integrations.md"]` confirmed in `defp docs do`                                    |
| `README.md`                                  | Pointer to integration guide                          | ✓ VERIFIED | `## Ecosystem Integrations` section names all three adapters with link to `guides/integrations.md`               |

### Key Link Verification

| From                                     | To                                                              | Via                         | Status     | Details                                                                                               |
|------------------------------------------|-----------------------------------------------------------------|-----------------------------|------------|-------------------------------------------------------------------------------------------------------|
| `threadline.ex`                          | `Threadline.record_action/2`                                    | Telemetry attachment        | ✓ WIRED    | `handle_event/4` -> `track_render/2` -> `Threadline.record_action(action, payload)`                  |
| `mailglass.ex attach_binary/3 true arm`  | `Rendro.Error.from_stage(:render, {:invalid_email_target, _})` | CR-02 fix (line 82)         | ✓ WIRED    | Grep confirms 1 match; test covers atom and plain map inputs without raising                          |
| `mailglass.ex extract_swoosh/1 catchall` | `{:error, {:unrecognized_message_shape, mod}}`                 | CR-01 fix (lines 123-126)   | ✓ WIRED    | `attach_to_mailglass/2` propagates via `case extract_swoosh(message) do`; test confirms               |
| `accrue.ex recipe/1`                     | `%Rendro.Document{}`                                            | `Rendro.flow/2`             | ✓ WIRED    | `build_header/1`, `build_content/1`, `build_footer/1` feed into `Rendro.flow(content, header:, footer:)` |
| `mix.exs docs[:extras]`                  | `guides/integrations.md`                                        | ExDoc extras list           | ✓ WIRED    | `awk '/defp docs do/,/^  end$/' mix.exs` contains `"guides/integrations.md"`                        |
| `README.md`                              | `guides/integrations.md`                                        | Markdown link               | ✓ WIRED    | `## Ecosystem Integrations` section contains link to `guides/integrations.md`                         |

### Data-Flow Trace (Level 4)

| Artifact                   | Data Variable | Source                                                | Produces Real Data | Status    |
|----------------------------|---------------|-------------------------------------------------------|--------------------|-----------|
| `accrue.ex recipe/1`       | `doc`         | `build_header/build_content/build_footer` from live `%Accrue.Invoice{}` fields -> `Rendro.flow/2` | Yes | ✓ FLOWING |
| `mailglass.ex attach_pdf/3` | `binary`      | `Rendro.render(document)` -> PDF binary               | Yes                | ✓ FLOWING |
| `threadline.ex track_render/2` | `payload` | `build_audit_metadata/2` from live telemetry measurements + metadata | Yes          | ✓ FLOWING |

### Behavioral Spot-Checks

Step 7b SKIPPED for app runtime (no local server). Code-level checks completed via grep.

| Behavior                                           | Check                                                                              | Result            | Status  |
|----------------------------------------------------|------------------------------------------------------------------------------------|-------------------|---------|
| CR-02 "best-effort" branch removed                 | `grep "Best-effort" lib/rendro/adapters/mailglass.ex`                             | 0 matches         | ✓ PASS  |
| CR-02 typed error tuple present                    | `grep "Rendro.Error.from_stage(:render, {:invalid_email_target," mailglass.ex`    | 1 match           | ✓ PASS  |
| CR-01 unrecognized_message_shape tuples            | `grep "{:unrecognized_message_shape," mailglass.ex`                                | 2 matches         | ✓ PASS  |
| CR-01 silent empty-email fabrication removed       | `grep "defp extract_swoosh(_), do: %Swoosh.Email{}" mailglass.ex`                 | 0 matches         | ✓ PASS  |
| WR-03 over-broad starts_with check removed         | `grep "String.starts_with?(mod_str, \"Elixir.Mailglass.\")" mailglass.ex`         | 0 matches         | ✓ PASS  |
| WR-03 narrowed predicate (mod-level function check)| `grep "function_exported?(mod, :update_swoosh, 2)" mailglass.ex`                  | 1 match           | ✓ PASS  |
| WR-03 explicit %Mailglass.Message{} positive case  | `grep "defp mailglass_message?(%Mailglass.Message{})" mailglass.ex`               | 1 match           | ✓ PASS  |
| No hard ecosystem deps in production build         | `grep -E "accrue\|threadline\|mailglass\|swoosh" inside defp deps do`             | 0 matches         | ✓ PASS  |
| Integration guide is substantive                   | `wc -l guides/integrations.md`                                                     | 388 lines         | ✓ PASS  |

### Requirements Coverage

| Requirement | Source Plans        | Description                                                                          | Status      | Evidence                                                                 |
|-------------|---------------------|--------------------------------------------------------------------------------------|-------------|--------------------------------------------------------------------------|
| ADPT-05     | 05-01, 05-02, 05-03, 05-04 | Maintainer can provide do-now integration recipes for `threadline`, `mailglass`, and `accrue` without hard coupling | ✓ SATISFIED | All three adapters implemented with `Code.ensure_loaded?` guards; integration guide published; no ecosystem deps in `mix.exs`; 191 tests pass |

**Note:** Later Phase 10 artifact backfill now carries the decisive regression proof for the old Mailglass custom-wrapper and Accrue warning paths, so this Phase 05 report no longer treats those as open manual checkpoints.

### Anti-Patterns Found

| File                                       | Line | Pattern                                                                           | Severity | Impact                                                                                                                                                                                                        |
|--------------------------------------------|------|-----------------------------------------------------------------------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `test/rendro/adapters/mailglass_test.exs`  | 1    | Former manual wrapper proof replaced by executable regression coverage            | INFO     | Phase 10 now proves the admitted custom-wrapper path directly in CI with an automated regression. |
| `test/rendro/adapters/accrue_test.exs`     | 1    | Former Accrue warning paths replaced by executable regression coverage            | INFO     | Phase 10 now proves typed invalid nested line-item failures and normalized issued-at rendering directly in CI. |
| `test/rendro/adapters/mailglass_test.exs`  | 7    | `defmodule Mailglass.UnrecognizedFixture` defined, never used in any test         | INFO     | Dead test code; the `Mailglass.ConfigFixture` already covers WR-03. REVIEW IN-01.                                                                                                                            |

No blocker anti-patterns remain against the recipe success criteria. Phase 10 closes REVIEW CR-01, WR-06, and IN-04 and replaces the old manual-wrapper concern with automated regression evidence.

### Human Verification Required

(none — the former Mailglass custom-wrapper checkpoint is now covered by automated regression proof in Phase 10 and referenced here as later closure evidence)

---

_Verified: 2026-04-26T20:00:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes (after gap closure plans 05-02, 05-03, 05-04)_
