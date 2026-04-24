# Architecture Research

**Domain:** Elixir-native PDF/document generation
**Researched:** 2026-04-24
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Public API Layer                         │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Fixed API    │  │ Flow API     │  │ Phoenix Adapter  │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                 │                    │            │
├─────────┴─────────────────┴────────────────────┴────────────┤
│                  Composition + Layout Core                  │
├─────────────────────────────────────────────────────────────┤
│  Document AST -> Measure -> Paginate -> Render Plan        │
│  Tables/Frames/Templates -> Overflow Diagnostics            │
├─────────────────────────────────────────────────────────────┤
│                    Rendering + Validation                   │
│  PDF Serializer | Resource Embedding | Deterministic Mode   │
│  Validation Hooks | Structured Errors | Telemetry Events    │
├─────────────────────────────────────────────────────────────┤
│                     Optional Adapters                        │
│  Oban jobs | Threadline audit | Mailglass | Accrue recipes  │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Document AST / Composition | Represent document intent as Elixir data | Structs + builder APIs + component-like macros |
| Layout Engine | Measure and place content into pages/frames | Pure transformation pipeline with explicit overflow handling |
| Pagination Engine | Compute page breaks and repeatable layout outcomes | Deterministic algorithms + repeat-header table logic |
| Renderer/Serializer | Produce valid PDF bytes from layout plan | Object graph writer + stream serialization |
| Validation/Policy Layer | Enforce bounded execution and quality checks | Hooks, policy limits, and optional external validators |
| Adapter Layer | Integrate with Phoenix/jobs/external ecosystem | Optional packages/modules with compile/runtime guards |

## Recommended Project Structure

```
apps/
├── rendro/                    # Pure core library
│   ├── lib/rendro/            # Public API + document model
│   ├── lib/rendro/layout/     # Measure/flow/paginate logic
│   ├── lib/rendro/render/     # PDF serialization and resources
│   ├── lib/rendro/validate/   # Validation hooks and policies
│   └── test/                  # Unit, property, deterministic fixture tests
├── rendro_phoenix/            # Optional Phoenix adapter
│   ├── lib/rendro/phoenix/
│   └── test/
├── rendro_oban/               # Optional job adapter
│   ├── lib/rendro/oban/
│   └── test/
└── rendro_integrations/       # Optional recipes/adapters (threadline/mailglass/accrue)
    ├── lib/rendro/integrations/
    └── test/
examples/
└── rendro_phoenix/            # CI-verified host app
```

### Structure Rationale

- **`apps/rendro`:** Protects pure-core guarantees and keeps runtime dependencies minimal.
- **Adapter packages:** Enforces optional coupling boundaries and keeps integration surface explicit.
- **`examples/`:** Maintains executable docs and adoption proof as part of release quality.

## Architectural Patterns

### Pattern 1: Data-First Document Pipeline

**What:** Documents are represented as Elixir data before rendering.
**When to use:** Always; this is the core architecture contract.
**Trade-offs:** Strong testability and determinism, but requires deliberate API design up front.

**Example:**
```elixir
doc
|> Rendro.compose(assigns)
|> Rendro.measure()
|> Rendro.paginate()
|> Rendro.render()
```

### Pattern 2: Two APIs, One Engine

**What:** Fixed-position and flow APIs feed the same underlying layout/render core.
**When to use:** Needed for both exact forms and report-style documents.
**Trade-offs:** Requires careful normalization layer to avoid duplicated behavior.

**Example:**
```elixir
Rendro.fixed(...)
|> Rendro.to_plan()
|> Rendro.render()
```

### Pattern 3: Optional Adapter Boundaries

**What:** Integrations are isolated modules/packages guarded by optional deps.
**When to use:** Any ecosystem integration (Phoenix, Oban, threadline, mailglass, accrue).
**Trade-offs:** More packaging overhead, but avoids long-term architectural debt.

## Data Flow

### Request Flow

```
[User Data + Template]
    ↓
[Compose AST] → [Measure/Layout] → [Paginate] → [Render PDF]
    ↓                 ↓               ↓             ↓
[Diagnostics] ← [Overflow Info] ← [Break Rules] ← [Artifact + Metadata]
```

### State Management

```
[Document Input]
    ↓
[Immutable AST] → [Immutable Layout Plan] → [Immutable Render Artifact]
```

### Key Data Flows

1. **Document generation flow:** Input data + template primitives -> AST -> paginated layout -> PDF bytes + metadata.
2. **Operational observability flow:** Render lifecycle emits telemetry and structured errors with correlation metadata.
3. **Adapter orchestration flow:** Phoenix/Oban/adapters call core APIs and consume artifact outputs without mutating core internals.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k docs/day | Single node + synchronous render path is acceptable |
| 1k-100k docs/day | Introduce Oban adapter, bounded concurrency, and artifact storage policies |
| 100k+ docs/day | Dedicated render workers, backpressure policies, aggressive observability, and optional split of adapter packages into deploy-specific services |

### Scaling Priorities

1. **First bottleneck:** Pagination/memory pressure for large tables -> solve with bounded policies and iterative layout primitives.
2. **Second bottleneck:** Operational failure diagnosis -> solve with lifecycle telemetry and strict structured errors.

## Anti-Patterns

### Anti-Pattern 1: Browser-Renderer Scope Drift

**What people do:** Add HTML/CSS parity requirements to core.
**Why it's wrong:** Replaces product differentiation with unwinnable browser-engine scope.
**Do this instead:** Keep native AST engine primary; provide optional adapter bridges when needed.

### Anti-Pattern 2: Adapter Leakage into Core

**What people do:** Let Phoenix/Oban or integration concerns shape core compile/runtime dependencies.
**Why it's wrong:** Breaks pure-core promise and makes reuse harder.
**Do this instead:** Keep adapters optional with explicit boundaries and interfaces.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| threadline | Optional audit adapter | Track template lifecycle and render event audit trails |
| mailglass | Optional attachment recipe | Attach rendered bytes in transactional workflows |
| accrue | Optional billing recipe | Generate deterministic invoice/statement artifacts |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| API layer <-> layout/render core | Pure function calls / structs | Core remains source of truth |
| Core <-> adapters | Behavior contracts / explicit API | No reverse dependency into core |
| Core <-> validation tools | Hook interface | External validator execution stays optional |

## Sources

- `prompts/rendro-gsd-seed.md`
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md`
- `prompts/rendro-oss-dna.md`
- `prompts/rendro-integration-opportunities.md`

---
*Architecture research for: Elixir-native PDF generation*
*Researched: 2026-04-24*
