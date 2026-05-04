# Domain Pitfalls

**Domain:** Async Document Generation & SaaS Integration
**Researched:** 2026-05-04

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Core Contamination
**What goes wrong:** Adding `oban`, `ecto`, or `aws` as hard dependencies in `mix.exs` to support async/storage features.
**Why it happens:** It is easier to write tightly coupled code than properly inverted interfaces.
**Consequences:** Rendro cannot be used by teams using Exq, pure ETS, or on-premise deployments. The project loses its "pure core" identity.
**Prevention:** Strictly enforce the Behavior/Adapter pattern. All integrations must live in `lib/rendro/adapters/` (if optional dependencies) or separate packages.
**Detection:** CI should fail if `mix.exs` adds non-rendering production dependencies.

### Pitfall 2: Opaque Async Failures
**What goes wrong:** A document fails to render in an Oban background job, but the error is lost or useless.
**Why it happens:** Layout errors are complex and nested; default Elixir exceptions might truncate context in Oban logs.
**Consequences:** Operators cannot debug why a specific invoice failed to generate at 2 AM.
**Prevention:** Enhance `Rendro.Error` to serialize cleanly for `threadline` audit logs. Ensure the Oban adapter explicitly catches and structures layout errors.

## Moderate Pitfalls

### Pitfall 1: Leaking Artifact State
**What goes wrong:** Re-rendering the same document asynchronously yields a different PDF hash because of timestamps.
**Prevention:** Expose deterministic timestamps and random seeds in the `Rendro.Document` construct so async workers can reproduce exact bytes.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Artifact Manifests | Manifest metadata is too tied to a specific storage backend. | Keep manifest fields purely descriptive (hash, size, MIME type). |
| Oban Worker | Worker requires entire Ecto structs as arguments. | Serialize arguments to primitive maps/IDs; refetch inside worker. |
| `threadline` Integration | Audit logs become too noisy (logging every tiny step). | Limit audit events to high-level outcomes: Start, Success, Structured Failure. |

## Sources
- `.planning/EPIC.md` ("Keep pure core and optional adapters as hard architectural boundary.")