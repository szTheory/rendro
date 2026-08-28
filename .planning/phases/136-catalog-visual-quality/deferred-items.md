# Phase 136 Deferred Items

## Plan 136-09

- `mix ci.fast` stops during `quality.hygiene` because the tracked pre-existing file `.planning/todos/pending/2026-08-28-unify-catalog-recipe-visual-design-system.md` is outside an active phase directory or milestone archive. The file and its introducing commit (`744b8d3`) predate Plan 136-09 and were present at the plan's starting HEAD. Plan-owned targeted tests, formatting, package build, warnings-as-errors compilation, the full non-quarantined test suite, ExDoc, Credo, and Dialyzer all pass. Move or archive the TODO through its owning workflow, then rerun `mix ci.fast`.
