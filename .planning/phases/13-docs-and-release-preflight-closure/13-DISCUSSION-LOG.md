# Phase 13: docs-and-release-preflight-closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `13-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 13-docs-and-release-preflight-closure
**Areas discussed:** Docs coverage boundary, Partial snippet policy, Release-preflight enforcement style, Release parity boundary

---

## Docs coverage boundary

| Option | Description | Selected |
|--------|-------------|----------|
| API-docs only contract | Keep docs contract narrow to README/module docs only; guides stay mostly narrative | |
| Curated contract surface | Verify README plus selected guide happy paths; enforce semantic claims via direct tests | ✓ |
| Blanket markdown verification | Treat README and guides as broadly executable markdown | |
| Claims-first verification | Focus primarily on semantic contract tests, minimal example execution | |

**User's choice:** Research-backed recommendation accepted.
**Notes:** Chosen because it best fits truthful small contracts and least-surprise DX for a library with optional integrations.

---

## Partial snippet policy

| Option | Description | Selected |
|--------|-------------|----------|
| Strict executable-only `elixir` fences | Any `elixir` block must be complete runnable Elixir | |
| Explicit opt-out marker | Allow narrative partials only with explicit skip annotations and reasons | |
| Explicit multi-lane policy | `iex>` doctest/eval, `elixir` compile-check, schematic snippets moved out of verified Elixir fences | ✓ |
| Heuristic permissive skip | Keep token-based skipping, just surface it more loudly | |

**User's choice:** Research-backed recommendation accepted.
**Notes:** No more silent passes for `...` or `%{...}`. Verified status must be obvious from the syntax and/or marker.

---

## Release-preflight enforcement style

| Option | Description | Selected |
|--------|-------------|----------|
| Pure fail-fast sequential | Stop on the first failure | |
| Full aggregation | Always run everything, then summarize | |
| Hybrid boundary-first then aggregate | Cheap blockers first; expensive runnable checks only after boundary validity | ✓ |
| Severity lanes with distinct exit codes | Multi-lane severity model with more policy surface | |

**User's choice:** Research-backed recommendation accepted.
**Notes:** Keep maintainers out of rerun churn while still refusing obviously invalid release state.

---

## Release parity boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Strict tagged-release gate | `release.preflight` proves this exact tagged ref is publishable | ✓ |
| Split boundary | Separate branch-time sanity and strict tagged release workflows | |
| Hybrid dual-mode | One command with strict and branch modes | |
| Loose branch-time sanity only | Fast local checks without truthful release proof | |

**User's choice:** Research-backed recommendation accepted.
**Notes:** If a weaker branch-time helper is added later, it must have a different name so `mix release.preflight` remains semantically strict.

---

## the agent's Discretion

- Exact docs-verification marker naming and result formatting.
- Exact implementation strategy for executable docs (`doctest_file/1`, markdown verifier, or mixed approach).
- Exact release-preflight summary formatting and internal result structs.

## Deferred Ideas

- Add a separately named branch-time release rehearsal command in a future phase if maintainer ergonomics justify it.
- Consider broader executable coverage for guides only in a future explicit docs-as-tutorial phase.
