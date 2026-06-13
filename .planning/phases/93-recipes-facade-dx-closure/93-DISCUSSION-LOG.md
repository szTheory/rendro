# Phase 93: Recipes Facade DX Closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 93-recipes-facade-dx-closure
**Areas discussed:** Facade delegation pattern, Options threading & footgun, Drift test design, Public-API contract regeneration

---

**Process note:** Phase 93 was assessed as fully specified by ROADMAP.md success criteria SC #1–#4 (they function as a SPEC). No genuine open gray areas required user vision input. Per the user's `opinionated` / `minimal_decisive` advisor calibration, the user requested deep parallel research to one-shot a coherent, locked recommendation set for the implementation micro-choices the criteria leave open. Four parallel `gsd-advisor-researcher` agents were spawned (Elixir/ecosystem idioms, lessons from comparable libs, codebase grounding). Their decisive recommendations were synthesized and locked — no choices were bounced back to the user.

---

## Facade delegation pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Hand-written `@spec`'d wrappers; arity-1 → facade's own arity-2 | `def invoice(data), do: invoice(data, [])`; `def invoice(data, opts), do: Invoice.document(data, opts)`. Byte-identity structural by construction. | ✓ |
| `Kernel.defdelegate name(data, opts \\ [])` | One line generates both arities, but arity-1 calls target directly (not facade arity-2); emits no `@spec`/`@doc`. | |
| Macro/loop generator | Generates wrappers programmatically; contradicts "hand-written", hurts ExDoc/grep, metaprogramming footgun. | |

**User's choice:** Hand-written wrappers, arity-1 delegating to facade arity-2 (locked recommendation, accepted via "one-shot perfect recommendations" directive).
**Notes:** `defdelegate` rejected because it can't satisfy the structural arity-1→arity-2 byte-identity criterion and saves little (no spec/doc anyway). Macro rejected as anti-idiomatic for a contract-guarded stable surface.

---

## Options threading & footgun

| Option | Description | Selected |
|--------|-------------|----------|
| Transparent pass-through | `opts \\ []` at facade, forward verbatim; recipes stay single opts authority. Fix README:135. Add regression test. | ✓ |
| Validated pass-through (NimbleOptions whitelist at facade) | Self-documenting/typo-catching, but creates a second drift-prone opts authority + new dep. | |

**User's choice:** Transparent pass-through.
**Notes:** Recipes already own/tolerate their opts via `Keyword.get`; existing `*_opts_threading_test.exs` prove it. Facade-level validation would couple to per-recipe key sets and drift. Matches Req/Finch/Plug thin-wrapper idiom.

---

## Drift test design

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit `@recipes` SSOT table + `__info__` MapSet equality + Document-struct `==`, hardened with one auto-discovery sweep | Reviewed-edit guarantee + orphan-module detection; struct comparison avoids PDF determinism pitfalls. | ✓ |
| Pure auto-discovery + rendered-byte compare (`deterministic: true`) | Auto-catches orphan modules but no single reviewed source of truth; reintroduces PDF determinism surface area. | |

**User's choice:** Explicit `@recipes` table + struct-equality, plus one sweep assertion.
**Notes:** Compare on `%Rendro.Document{}` struct, not rendered bytes — exact and deterministic. `__info__(:functions)` is correct here (flat delegation module). Reuse existing recipe sample-data builders. Test starts RED (expected).

---

## Public-API contract regeneration

| Option | Description | Selected |
|--------|-------------|----------|
| Mechanical regen (`mix rendro.api.gen`) + git-diff additivity gate | Deterministic generator; additivity provable from diff (only `+` lines in `Rendro.Recipes.functions`). Author `@spec`+`@doc` before regen. | ✓ |
| Hand-edit `priv/public_api.json` | Defeats the golden-file purpose; near-certain to fail byte-compare. | |

**User's choice:** Mechanical regeneration with additivity verification.
**Notes:** `Rendro.Recipes` is `tags: [:stable]`, so all 8 new defs inherit stable tier and require `@spec`; a non-`@doc false` docstring is required or they're dropped from the surface. Author specs/docs before regenerating. Optional one-line `api_stability.md` note.

## Claude's Discretion

- Exact `@doc` wording and the README correction phrasing (keep README fix minimal).
- Whether the facade opts-threading regression test and drift test share `test/rendro/recipes_test.exs` or use separate files matching repo conventions.

## Deferred Ideas

None — discussion stayed within phase scope.
