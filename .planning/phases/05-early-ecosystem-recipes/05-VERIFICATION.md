---
phase: 05-early-ecosystem-recipes
verified: 2026-04-26T00:00:00Z
status: gaps_found
score: 4/7 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Maintainers can follow tested recipes for `threadline`, `mailglass`, and `accrue`"
    status: failed
    reason: "Only `threadline` and `mailglass` adapters exist. There is no `accrue` adapter, recipe, helper, or test in the codebase. ROADMAP Success Criterion #1 explicitly enumerates all three names and Phase 5 is the final phase of milestone v1.0 — there is no later phase to defer this to. The PLAN's must_haves silently dropped `accrue` from scope but the roadmap contract was never amended."
    artifacts:
      - path: "lib/rendro/adapters/"
        issue: "Contains only oban/, phoenix.ex, mailglass.ex, threadline.ex — no accrue.ex"
      - path: "lib/rendro/recipes.ex"
        issue: "Contains only an `invoice/1` function unrelated to Accrue billing structs; no Accrue->Document transformation recipe"
      - path: "test/rendro/adapters/"
        issue: "No accrue_test.exs — only mailglass and threadline are tested"
    missing:
      - "lib/rendro/adapters/accrue.ex (or lib/rendro/recipes/accrue.ex) implementing the Accrue billing-document recipe per RESEARCH.md table"
      - "test/rendro/adapters/accrue_test.exs verifying the recipe with a contract mock"
      - "Code.ensure_loaded?(Accrue) gate so the recipe is optional and does not introduce a hard dependency"
  - truth: "Integration documentation includes verification guidance and failure diagnostics"
    status: failed
    reason: "No integration documentation has been published. README.md is unchanged for this phase and does not mention `threadline`, `mailglass`, `accrue`, audit attach, or the PDF attachment helper. The adapter moduledocs contain a 3-line usage snippet each but provide no verification guidance (how to confirm an audit row landed, how to inspect telemetry-to-Threadline mapping in production) and no failure-diagnostics section (what to do when `Threadline.record_action/2` returns `{:error, _}`, how `attach_pdf/3` surfaces render-policy denials, what `{:error, %Rendro.Error{}}` shapes the caller will see)."
    artifacts:
      - path: "README.md"
        issue: "No section on threadline / mailglass / accrue integration; no verification or diagnostics guidance"
      - path: "lib/rendro/adapters/threadline.ex"
        issue: "Moduledoc documents attach/detach but no verification recipe, no diagnostics for audit-pipeline failures, no troubleshooting (e.g. timeouts never audit — see WR-01 in REVIEW)"
      - path: "lib/rendro/adapters/mailglass.ex"
        issue: "Moduledoc documents the happy path but no verification guidance, no failure-diagnostics section, no enumeration of error shapes returned by attach_pdf/3"
    missing:
      - "An integration guide (e.g. guides/integrations.md or extras: in mix.exs docs config) that documents threadline/mailglass/accrue setup, verification steps, and failure modes"
      - "Failure-diagnostics section per adapter listing the error tuples callers can receive and how to interpret them"
      - "A statement of which lifecycle events are NOT audited (e.g. timeout) so operators are not surprised — currently undocumented and conflicts with WR-01"
  - truth: "Mailglass adapter is optional and provides PDF attachment helper"
    status: partial
    reason: "The helper exists, is gated by Code.ensure_loaded?, and the happy paths covered by tests pass. However the helper violates its own documented contract on two non-test paths surfaced by 05-REVIEW (CR-01, CR-02). These are functional contract violations, not stylistic findings: (a) extract_swoosh/1's catchall fabricates a fresh empty %Swoosh.Email{} and silently discards the caller's original message body/recipients/subject when given an unrecognized Mailglass-like wrapper, and (b) attach_binary/3's `true ->` 'best-effort' branch calls Swoosh.Email.attachment/2 with a value already proven not to be a %Swoosh.Email{}, which raises FunctionClauseError instead of returning {:error, Rendro.Error.t()} as the moduledoc promises. is_mailglass_struct/1 (WR-03) compounds CR-01 by routing every `Elixir.Mailglass.*` struct (including non-message types) into the dangerous extract_swoosh fallback."
    artifacts:
      - path: "lib/rendro/adapters/mailglass.ex"
        issue: "Lines 64-67: `true -> Swoosh.Email.attachment(email_or_message, attachment)` will raise FunctionClauseError for any input that fails both mailglass_message? and swoosh_email? — directly contradicting the moduledoc's `{:error, Rendro.Error.t()}` contract"
      - path: "lib/rendro/adapters/mailglass.ex"
        issue: "Lines 97-100: `defp extract_swoosh(_), do: %Swoosh.Email{}` silently drops caller's message and replaces with empty email; combined with put_swoosh/2's `true ->` arm, returns the wrong email entirely"
      - path: "lib/rendro/adapters/mailglass.ex"
        issue: "Lines 81-86: is_mailglass_struct/1 admits any `Elixir.Mailglass.*` struct (e.g. Mailglass.Config) into the message-handling path"
    missing:
      - "extract_swoosh/1 must return {:error, {:unrecognized_message_shape, _}} for unknown wrapper shapes (per CR-01 fix)"
      - "attach_binary/3's catchall must return {:error, Rendro.Error.t()} not call Swoosh.Email.attachment/2 (per CR-02 fix)"
      - "Negative-path test exercising a non-Swoosh, non-Mailglass input to assert the documented error tuple is returned rather than a raise"
deferred: []
---

# Phase 05: Early Ecosystem Recipes Verification Report

**Phase Goal:** Provide validated do-now integration recipes for high-value ecosystem workflows while preserving architecture boundaries.
**Verified:** 2026-04-26T00:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Merged from ROADMAP Success Criteria (authoritative) and PLAN frontmatter must_haves.

| #   | Truth                                                                                                | Source           | Status        | Evidence                                                                                                                                                                                                                                                          |
| --- | ---------------------------------------------------------------------------------------------------- | ---------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Maintainers can follow tested recipes for `threadline`, `mailglass`, and `accrue`                    | Roadmap SC #1    | ✗ FAILED      | `lib/rendro/adapters/` contains threadline.ex and mailglass.ex but no accrue adapter; `lib/rendro/recipes.ex` only has `invoice/1`; no `test/rendro/adapters/accrue_test.exs`                                                                                     |
| 2   | Recipes remain optional and do not introduce hard dependencies into core                             | Roadmap SC #2    | ✓ VERIFIED    | `mix.exs` lines 40-51 contain no `:threadline`, `:mailglass`, or `:accrue` entries; both shipped adapters wrap their bodies in `if Code.ensure_loaded?(...) do ... end` (threadline.ex:1, mailglass.ex:1)                                                         |
| 3   | Integration documentation includes verification guidance and failure diagnostics                     | Roadmap SC #3    | ✗ FAILED      | `README.md` does not mention threadline/mailglass/accrue/audit/attach_pdf; no `guides/`, `extras/`, or other integration doc file exists; adapter moduledocs cover usage but not verification or failure diagnostics                                              |
| 4   | Rendro.Audit behavior is defined and documented                                                      | PLAN must_have   | ✓ VERIFIED    | `lib/rendro/audit.ex:1-48` defines `@callback track_render(render_id, metadata) :: :ok | {:error, term()}` with moduledoc, PII safety section, and Adopting example                                                                                                |
| 5   | Threadline adapter is optional and gated by Code.ensure_loaded?                                      | PLAN must_have   | ✓ VERIFIED    | `lib/rendro/adapters/threadline.ex:1` wraps the entire module in `if Code.ensure_loaded?(Threadline) do ... end`; mix.exs has no `:threadline` dep                                                                                                                |
| 6   | Threadline adapter attaches to Telemetry and records render events                                   | PLAN must_have   | ✓ VERIFIED    | `attach/0` calls `:telemetry.attach_many` for `[:rendro, :render, :stop]` and `[:rendro, :render, :exception]` (threadline.ex:54-60); `handle_event/4` dispatches to `track_render/2` which calls `Threadline.record_action/2`; 11 passing tests confirm wiring   |
| 7   | Mailglass adapter is optional and provides PDF attachment helper                                     | PLAN must_have   | ⚠️ PARTIAL    | Module is gated by Code.ensure_loaded?(Mailglass), `attach_pdf/3` exists and 7 happy-path tests pass — but the implementation contains two contract violations (CR-01 silent data loss, CR-02 raises instead of returning {:error, _}); see Anti-Patterns table   |

**Score:** 4/7 truths verified (2 failed, 1 partial)

### Required Artifacts

| Artifact                                            | Expected                              | Status      | Details                                                                              |
| --------------------------------------------------- | ------------------------------------- | ----------- | ------------------------------------------------------------------------------------ |
| `lib/rendro/audit.ex`                               | Audit behavior definition             | ✓ VERIFIED  | 48 LOC; defines `@callback track_render/2`; moduledoc with adoption + PII guidance   |
| `lib/rendro/adapters/threadline.ex`                 | Optional Threadline integration       | ✓ VERIFIED  | 117 LOC; gated; attach/detach/handle_event/track_render all present                  |
| `lib/rendro/adapters/mailglass.ex`                  | Optional Mailglass integration        | ⚠️ STUB-ish | 118 LOC; functions present, but extract_swoosh fallback and best-effort branch break documented contract (see CR-01/CR-02) |
| `lib/rendro/adapters/accrue.ex` (implied by SC #1)  | Optional Accrue billing recipe        | ✗ MISSING   | File does not exist anywhere in lib/                                                 |
| `test/rendro/adapters/threadline_test.exs`          | Threadline adapter tests              | ✓ VERIFIED  | 11 tests, all pass                                                                   |
| `test/rendro/adapters/mailglass_test.exs`           | Mailglass adapter tests               | ✓ VERIFIED  | 7 tests, all pass — but no negative-path tests for CR-01/CR-02 input shapes          |
| `test/rendro/adapters/accrue_test.exs` (implied)    | Accrue adapter tests                  | ✗ MISSING   | File does not exist                                                                  |
| `test/support/mocks.ex`                             | Test stubs for optional libs          | ✓ VERIFIED  | Threadline + Mailglass.Message + Swoosh.Email + Swoosh.Attachment stubs present      |

### Key Link Verification

| From                                  | To                              | Via                                                | Status     | Details                                                                                                                              |
| ------------------------------------- | ------------------------------- | -------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `lib/rendro/adapters/threadline.ex`   | `Threadline.record_action/2`    | Telemetry `attach_many` -> handle_event -> track_render | ✓ WIRED    | `:telemetry.attach_many(@handler_id, @events, &__MODULE__.handle_event/4, nil)` (threadline.ex:56); `Threadline.record_action(action, payload)` (threadline.ex:90); ETS-backed test stub confirms cross-process delivery |
| `lib/rendro/adapters/mailglass.ex`    | `Swoosh.Email.attachment/2`     | Mailglass pipe                                     | ⚠️ PARTIAL | Direct call exists at line 62 (swoosh path) and 93 (mailglass path); but the line-66 "best-effort" branch calls Swoosh.Email.attachment/2 with a non-Swoosh value, which raises (CR-02)                                  |
| `lib/rendro/adapters/mailglass.ex`    | `Mailglass.Message.update_swoosh/2` | put_swoosh/2 with function_exported? guard       | ✓ WIRED    | Line 104-105 uses `apply(Mailglass.Message, :update_swoosh, ...)` when exported; mailglass_test.exs:67-78 confirms re-wrapping       |
| (missing) accrue adapter              | `Accrue.*`                      | (none)                                             | ✗ NOT_WIRED | No accrue adapter exists                                                                                                            |

### Data-Flow Trace (Level 4)

| Artifact                            | Data Variable                            | Source                                                                          | Produces Real Data | Status       |
| ----------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------- | ------------------ | ------------ |
| `Rendro.Adapters.Threadline`        | telemetry `metadata` map at `[:rendro, :render, :stop]` | `Pipeline.build_stop_meta/3` populates `:render_id, :status, :page_count, :byte_size, :duration` | Yes — verified by `metadata.byte_size > 0`, `metadata.page_count == 1`, UUID render_id (threadline_test.exs:38-64) | ✓ FLOWING    |
| `Rendro.Adapters.Mailglass`         | rendered PDF binary                      | `Rendro.render(document)` -> `Pipeline.run/1`                                   | Yes — `<<"%PDF-", _::binary>>` magic-byte assertion at mailglass_test.exs:62 | ✓ FLOWING    |

### Behavioral Spot-Checks

| Behavior                                                                  | Command                                                            | Result                                       | Status   |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------ | -------------------------------------------- | -------- |
| Adapter test suite passes                                                 | `mix test test/rendro/adapters/`                                   | "14 tests, 0 failures"                       | ✓ PASS   |
| Mix project has no hard ecosystem deps                                    | `grep -n "threadline\|mailglass\|accrue" mix.exs`                  | (no output)                                  | ✓ PASS   |
| `Rendro.Audit` behavior compiles                                          | included in `mix test` above; module loads                         | confirmed via test run                       | ✓ PASS   |
| Threadline adapter is absent when stub absent (optional gating works)     | confirmed in test_helper.exs comment trail; recompile hook required| works as designed                            | ✓ PASS   |
| Negative-path attach_pdf returns documented `{:error, _}` for bad input   | not testable — no test exists                                      | n/a                                          | ? SKIP   |

### Requirements Coverage

| Requirement | Source Plan       | Description                                                                                       | Status     | Evidence                                                                                                                                                                                            |
| ----------- | ----------------- | ------------------------------------------------------------------------------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ADPT-05     | 05-01-PLAN.md     | Maintainer can provide do-now integration recipes for `threadline`, `mailglass`, and `accrue` without hard coupling | ✗ BLOCKED  | Threadline + Mailglass: shipped, optional, tested. Accrue: no adapter, no recipe, no tests. The requirement names three libraries; only two are delivered. Cross-checked REQUIREMENTS.md:32 and ROADMAP.md:90 |

No additional requirements are mapped to Phase 5 in REQUIREMENTS.md, so there are no orphaned requirements.

### Anti-Patterns Found

| File                                  | Line    | Pattern                                                                                          | Severity     | Impact                                                                                                                                                                                                              |
| ------------------------------------- | ------- | ------------------------------------------------------------------------------------------------ | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/rendro/adapters/mailglass.ex`    | 64-67   | "Best-effort" cond branch that will raise `FunctionClauseError` for any non-Swoosh, non-Mailglass input (CR-02 from REVIEW) | ⚠️ Warning  | Public API violates documented `{:error, Rendro.Error.t()}` contract; raises instead. Not blocking happy-path adoption, but is a functional contract violation against PLAN must-have #4 ("provides PDF attachment helper") |
| `lib/rendro/adapters/mailglass.ex`    | 97-100  | `extract_swoosh(_)` returns fresh empty %Swoosh.Email{}, silently discarding caller data (CR-01 from REVIEW) | ⚠️ Warning  | Silent data loss on unknown Mailglass.* wrapper shapes; reachable today via WR-03 (any `Elixir.Mailglass.*` struct routes here)                                                                                       |
| `lib/rendro/adapters/threadline.ex`   | 75      | `if status == :error, do: :render_failed, else: :render_succeeded` defaults missing/unknown to success (WR-02) | ℹ️ Info     | Latent today (Pipeline always sets :status); audit-layer should fail closed                                                                                                                                          |
| `lib/rendro/adapters/threadline.ex`   | 89-98   | Unscoped `try/rescue e ->` swallows all exceptions silently (WR-05)                              | ℹ️ Info     | Audit-pipeline failures are invisible; not a goal blocker                                                                                                                                                            |
| (Pipeline + Threadline) timeout path  | n/a     | Render timeouts never emit a `:stop` or `:exception` event, so they are never audited (WR-01)    | ⚠️ Warning  | Most-important-to-audit failure class is silently dropped — directly relevant to SC #3 "verification guidance and failure diagnostics" since the gap is undocumented                                                  |
| `test/support/mocks.ex`               | 76-81   | `test_pid/0` returns head of $callers chain instead of last (WR-04)                              | ℹ️ Info     | Latent — only one Task layer today; future nested Tasks would mis-route                                                                                                                                              |
| `test/support/mocks.ex`               | 31-40   | Non-atomic `:ets.info` -> `:ets.new` (IN-04)                                                     | ℹ️ Info     | Defensive only                                                                                                                                                                                                       |

### Human Verification Required

None. All gaps identified are programmatically verifiable (missing files, missing docs, code-path contract violations).

### Gaps Summary

The shipped work delivers a clean Threadline adapter and a working-on-the-happy-path Mailglass adapter, but the phase falls short of its roadmap contract on two counts and partially on a third:

1. **`accrue` is entirely missing.** Roadmap Success Criterion #1 names three ecosystem libraries; only two are implemented. The PLAN's must_haves silently descoped accrue (it lists only Threadline and Mailglass truths), but a plan cannot subtract from roadmap SCs. Phase 5 is the final phase of milestone v1.0 — there is no later phase that addresses accrue, so this gap cannot be deferred. The REQUIREMENTS.md mapping of ADPT-05 to Phase 5 is "Pending" and remains blocked.

2. **No integration documentation exists.** Roadmap Success Criterion #3 requires "verification guidance and failure diagnostics." The README.md is unchanged and has no integration section; the adapter moduledocs document usage but not verification recipes or failure modes. Without this, maintainers cannot follow the recipes — the moduledoc tells them how to call `attach/0` but not how to verify the audit row landed, what error tuples to handle, or that timeouts are not audited (WR-01).

3. **Mailglass adapter contract violations.** PLAN must-have "provides PDF attachment helper" is partially satisfied: the helper exists and the documented happy paths work, but two non-test code paths (CR-01, CR-02) violate the helper's own moduledoc contract — silently dropping data and raising FunctionClauseError instead of returning the documented `{:error, %Rendro.Error{}}`. These are functional contract violations, not pure code-quality findings, so they qualify as gaps against the must-have. Severity is WARNING, not BLOCKER, because the happy-path tests pass and the bugs only surface on inputs the adapter says it accepts.

The Threadline path, the Audit behavior, and the optional-gating discipline (no hard deps in mix.exs) are all in solid shape.

---

_Verified: 2026-04-26T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
