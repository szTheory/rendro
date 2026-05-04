# Architecture Patterns

**Domain:** Async Document Generation & SaaS Integration
**Researched:** 2026-05-04

## Recommended Architecture

Rendro will use a strict **Behavior-Driven Adapter Pattern** for all async and ecosystem integrations to maintain the pure-core constraint.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Rendro.Core` | Pure Elixir PDF generation. Takes structs, returns bytes + metadata. | Nothing external. |
| `Rendro.Artifact` | Data carrier representing a finished render (bytes, hash, layout diagnostics). | Core, Adapters |
| `Rendro.Worker` | Oban behavior defining how a render job is queued and executed. | Core, Storage, App DB |
| `Rendro.Audit` | Behavior for logging template publishes and render outcomes. | `threadline` adapter |
| `Rendro.Storage` | Behavior for persisting artifacts (e.g., S3). | `Rendro.Worker` |

### Data Flow

1. Web request constructs `Rendro.Document`.
2. App enqueues job via `Rendro.Oban.enqueue(document_params)`.
3. Oban worker executes `Rendro.render_with_diagnostics/2`.
4. Worker yields a `Rendro.Artifact`.
5. Worker passes `Artifact` to configured `Rendro.Storage` adapter.
6. Worker emits success/failure to configured `Rendro.Audit` (`threadline`) adapter.
7. (Optional) Worker passes artifact bytes to `mailglass` adapter for email delivery.

## Patterns to Follow

### Pattern 1: Optional Integration Adapters
**What:** Integrations are shipped as separate hex packages (e.g., `rendro_oban`) or as documented recipes in the host app.
**When:** Whenever side-effects (DB, Network, Queue) are required.
**Example:**
```elixir
config :rendro,
  audit_adapter: Rendro.Adapters.Threadline,
  storage_adapter: MyApp.S3Storage
```

### Pattern 2: Canonical Recipes
**What:** Providing copy-pasteable Elixir modules in the documentation instead of shipping heavily-abstracted library code.
**When:** The integration is highly dependent on the host application's specific business logic (e.g., specific `accrue` billing layouts).

## Anti-Patterns to Avoid

### Anti-Pattern 1: Side-Effects in Core
**What:** Calling `HTTPoison.post` or `Repo.insert` inside the rendering pipeline.
**Why bad:** Destroys determinism; makes unit testing the layout engine impossible without mocks.
**Instead:** Return pure data (`Artifact`) and let the outer boundary (Worker) handle side-effects.

## Sources
- `prompts/rendro-oss-dna.md`
- `prompts/rendro-integration-opportunities.md`