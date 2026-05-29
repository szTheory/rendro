# Phase 74 Deferred Items (out-of-scope discoveries)

## Pre-existing project-wide `mix format` failures (discovered during 74-02)

`mix format --check-formatted` (project-wide) exits 1 due to formatting drift in two
**pre-existing** files unrelated to plan 74-02:

- `lib/rendro/pipeline/paginate.ex` — multiple unformatted clauses (Phase 73 era):
  the `:running_content_error` error tuple, the `%{block | content: ...}` update,
  the `throw({:error, :running_content_error, ...})`, and the `apply_suppression/3`
  case clauses.
- `test/rendro/deterministic_test.exs` — two spurious blank lines (lines ~254, ~611).

These are NOT touched by plan 74-02 (which only adds `lib/rendro/format.ex` and
`test/rendro/format_test.exs`, both of which pass `mix format --check-formatted`).
Per the executor SCOPE BOUNDARY rule, they are logged here and left unfixed.

**Recommended owner:** a follow-up `mix format` cleanup commit (or fold into 74-03/74-04,
which already touch the paginate/recipe area). The `mix ci` alias runs
`format --check-formatted` first, so this will block CI until fixed — worth addressing
before the phase gate.

Discovered: 2026-05-29 during plan 74-02 execution.
