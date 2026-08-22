---
status: resolved
trigger: "Protected v1.3.1 release run 32539594278 hung in Run Release Preflight until GitHub's six-hour job cancellation, immediately after Mix.Tasks.RendroGenThemeTest repeatedly created lib/generated_theme.ex."
created: 2026-08-22
updated: 2026-08-22
---

# Debug Session: Release Preflight Theme Hang

## Symptoms

### Expected behavior

The protected tag-driven v1.3.1 release workflow should complete `mix release.preflight`, complete its separate Hex dry run, publish the exact approved package only after all protected gates pass, and then permit the exact protected HexDocs dispatch.

### Actual behavior

Run `32539594278` passed version matching and its first full CI lane. During `Run Release Preflight`, the repeated `mix ci.fast` suite stopped producing output inside `Mix.Tasks.RendroGenThemeTest`, after the conflict-handling test repeatedly logged creation of `lib/generated_theme.ex`. The job made no further progress and GitHub automatically cancelled it at the six-hour limit. The publish job was skipped; Hex 1.3.1 remains absent and HexDocs was never dispatched.

### Error messages

The last test output was `* creating lib/generated_theme.ex` from `uses Mix conflict handling and keeps check mode read-only`. At `2026-08-22T06:13:17Z`, GitHub reported `The operation was canceled.` and terminated orphan BEAM processes. No application assertion or Hex error occurred.

### Timeline

The release job began at `2026-08-22T00:13:04Z`; preflight began at `00:23:14Z`; the last test output occurred around `00:24:35Z`; GitHub cancelled the job at `06:13:17Z`. A prior isolated preflight for the same candidate passed locally, so the defect is environment/order-sensitive.

### Reproduction

At approved source SHA `7afb1dd056bba234d1bd4ec1c4487f2ea8e308f1`, run the theme-generator conflict-handling test in a non-interactive CI environment, especially after an earlier full `mix ci` in the same runner and as part of the subsequent `mix release.preflight` / `mix ci.fast` pass. Determine why the existing output path reaches a blocking Mix conflict prompt rather than a deterministic return.

## Scope Constraints

- Preserve immutable public tags v1.3.0 and v1.3.1; do not move, delete, or recreate them.
- Do not use a local or alternate Hex publisher and do not dispatch HexDocs before Hex publication is independently verified.
- Produce the smallest deterministic regression fix with non-interactive CI behavior and bounded workflow timeouts.
- Treat release and docs claims as contracts; preserve the pure-Elixir core and optional integration boundaries.
- Do not touch the unrelated orchestrator-owned `.planning/config.json` modification.

## Current Focus

bug_class: bohrbug (deterministic with an open stdin)
hypothesis: `Mix.Tasks.RendroGenThemeTest` selects the default interactive Mix shell for its divergent-file conflict assertion, so its mailbox answer is ignored; an open CI stdin blocks the overwrite prompt, while the release workflow has no explicit timeout to cap the resulting stuck preflight.
test: use the already-run FIFO reproduction (open stdin, no answer) and the unit test's differing shell setup to verify causation; then run the identical test with Mix.Shell.Process under the same FIFO as the counterfactual.
expecting: the original test times out at `overwrite? [Yn]`; the process-shell-scoped test returns `Skipped` without reading stdin, and release workflow job timeouts bound any future unexpected wait.
next_action: plan and execute a separate v1.3.2 recovery candidate; v1.3.1 remains immutable and must not be repushed.
reasoning_checkpoint:
  hypothesis: "The conflict unit test hangs because it sends a response to the process mailbox while Mix.Generator asks the default Mix.Shell.IO shell for stdin; a CI stdin pipe that is open but silent then blocks indefinitely."
  confirming_evidence:
    - "The test sends {:mix_shell_input, :yes?, false} without setting Mix.Shell.Process, whereas the fresh-consumer test sets that shell first."
    - "With stdin held open by a FIFO and no input, the original focused test stopped at `overwrite? [Yn]` and gtimeout terminated it with status 124."
    - "With ordinary local stdin EOF, the same original test skipped instead, proving EOF masks rather than resolves the shell mismatch."
  falsification_test: "If wrapping only the divergent invocation in Mix.Shell.Process still blocks with the FIFO open, the prompt does not use Mix.shell/1 and this hypothesis is false."
  fix_rationale: "Scoping Mix.Shell.Process makes the existing mailbox answer deterministic for the exact conflict assertion while restoring the previous shell; explicit workflow timeouts independently cap future unexpected waits."
  blind_spots: "The historical GitHub runner cannot be rerun; local FIFO faithfully models an open silent stdin but not all GitHub runner details."
  candidate_causes:
    - "code: the unit test injects a process-shell reply without selecting Mix.Shell.Process."
    - "environment: CI supplies an open stdin rather than immediate EOF."
    - "config: release.yml omits job timeout-minutes, leaving GitHub's six-hour default cap."
  and_gate: "yes — the hang requires the code defect and an open silent stdin; the missing workflow timeout independently turns that hang into a six-hour blocked release."
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-22
  checked: protected release run 32539594278 and job 96946828155
  found: version matching and the first CI lane passed; preflight's second CI pass stopped inside the theme-generator conflict-handling test and GitHub cancelled the job after six hours; publish was skipped.
  implication: the failure is a deterministic or environment-sensitive test deadlock before all Hex publication boundaries.

- timestamp: 2026-08-22
  checked: Hex package API and workflow dispatch state
  found: Hex release 1.3.1 returns 404 and no HexDocs workflow was dispatched.
  implication: recovery can remain fail-closed; no partial registry/docs publication needs repair.

- timestamp: 2026-08-22
  checked: theme task and its conflict-handling unit/fresh-consumer tests
  found: the unit test sends `{:mix_shell_input, :yes?, false}` but does not call `Mix.shell(Mix.Shell.Process)` before its divergent existing-file invocation; by contrast, the fresh-consumer subprocess explicitly sets `Mix.Shell.Process` before sending that message.
  implication: only the fresh-consumer test supplies a usable noninteractive answer; the unit test can invoke the default interactive `Mix.Shell.IO` conflict prompt in CI.

- timestamp: 2026-08-22
  checked: focused theme-generator test with the normal local stdin pipe
  found: it prints `lib/generated_theme.ex already exists, overwrite? [Yn]` and then skips successfully because the local process receives immediate stdin EOF.
  implication: local EOF masks the missing process-shell setup; a reproduction must retain an open stdin without providing an answer.

- timestamp: 2026-08-22
  checked: focused theme-generator test with stdin held open by a FIFO and no input
  found: after the divergent output was written, the test stopped at `lib/generated_theme.ex already exists, overwrite? [Yn]`; `gtimeout 5` sent SIGTERM and returned status 124.
  implication: the proposed code/environment AND-gate is directly reproduced; the mailbox answer does not control the default interactive shell.

- timestamp: 2026-08-22
  checked: fixed focused theme-generator test with stdin held open by a FIFO and no input
  found: it completed with zero failures in 0.07 seconds under the same five-second bound; the conflict invocation printed no overwrite prompt and returned the asserted `Skipped` result through Mix.Shell.Process.
  implication: the scoped shell change is a direct counterfactual confirmation that it removes the blocking stdin read.

- timestamp: 2026-08-22
  checked: complete theme-generator, fresh-consumer, and release workflow contract suites plus formatter
  found: `mix test test/mix/tasks/rendro_gen_theme_test.exs test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs test/guardrails/required_checks_contract_test.exs` passed 26 tests; `mix format --check-formatted` passed.
  implication: the fix preserves adjacent generator behavior and the new timeout contract parses successfully.

- timestamp: 2026-08-22
  checked: controlled revert and reapply of the scoped Mix.Shell.Process test hunk with the open silent FIFO stdin
  found: reverting the hunk reproduced the overwrite-prompt hang and timed out with status 124; reapplying it completed the identical focused test in 0.07 seconds with status 0.
  implication: the changed hunk, rather than another environmental change, causally fixes the reproduced deadlock.

- timestamp: 2026-08-22
  checked: full `mix ci.fast` under `gtimeout 2700`
  found: the full required fast lane completed successfully after the fixed theme-generator test, along with package build, compilation, docs, Credo, and Dialyzer.
  implication: the second CI pass invoked by release preflight no longer hangs in this repository environment, and the bounded command returned successfully before its 45-minute limit.

## Eliminated

## Resolution

root_cause: The conflict-handling unit test sends a process-shell answer without selecting Mix.Shell.Process, so Mix.Generator reads the default interactive shell's stdin; an open silent CI stdin blocks indefinitely. release.yml also lacks explicit job timeouts, allowing GitHub's six-hour default to govern the stuck preflight.
fix: Scoped the divergent-file unit-test invocation through `Mix.Shell.Process` using the existing capture helper, and set release validation/publish job limits to 45/15 minutes with workflow contract assertions.
files_changed:
  - .github/workflows/release.yml
  - .planning/debug/release-preflight-theme-hang.md
  - test/guardrails/required_checks_contract_test.exs
  - test/mix/tasks/rendro_gen_theme_test.exs
verification:
  target_test: {result: pass, command: "gtimeout 5 mix test test/mix/tasks/rendro_gen_theme_test.exs:82 --trace < open-silent-fifo", result_detail: "0 failures in 0.07s"}
  mutation_check: {result: skipped, reason_if_skipped: "No Stryker or Elixir mutation-testing configuration exists in this repository."}
  no_op_deletion: {result: pass, deletion_justified_by_rca: false, detail: "The diff only adds deterministic test-shell scoping, a concrete `Skipped` assertion, and workflow timeout caps."}
  adjacent_tests: {result: pass, suites_run: ["theme generator unit", "fresh-consumer integration", "required workflow contract", "formatter", "mix ci.fast"]}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true}
  guardrail_verdict: accepted
oracle_type: specified — the test contract requires a conflict answer to skip the divergent application-owned file without stdin interaction; timeout values are explicit release workflow policy.
postmortem: "why not caught: the conflict unit test ran with stdin EOF locally, which masked its unselected interactive shell; guard: an open-silent-stdin regression test path plus explicit release job timeout contract."
