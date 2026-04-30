# Phase 22: Authoring Ergonomics and Canonical Recipes - Research

**Researched:** 2025-05-18
**Domain:** Elixir, Layout Primitives, Developer Ergonomics
**Confidence:** HIGH

## Summary
The core layout primitives (`Rendro.page_template/1`, `Rendro.section/1`, and named regions) exist in the engine (`Rendro.Pipeline.Compose.normalize_flow_layout/1`), but they are currently ignored by our canonical examples and recipes. `Rendro.Recipes.invoice/1`, `Rendro.Adapters.Accrue.recipe/1`, and the Flow API documentation in `README.md` all fallback to the legacy `header:` and `footer:` ad hoc block stacking approach on `Rendro.flow/2`. Additionally, the Phoenix example controller uses a trivial single-block document rather than a real business template.

To deliver on LAY-12, we must refactor these recipes to map content strictly through `sections: [...]` tied to explicitly defined `page_template` regions. This demonstrates serious report composition without relying on implicit pagination defaults, showing engineers how to build maintainable documents.

**Primary recommendation:** Convert all `header:`/`footer:` usages in recipes, adapters, and docs to explicit `sections:` mapped to `page_template` regions, and upgrade the Phoenix example to use a canonical invoice recipe.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Layout Composition | API / Backend | — | The document AST and template definitions execute deterministically in Elixir prior to rendering |
| Pagination & Regions | API / Backend | — | `Rendro.Pipeline` manages region distribution entirely server-side |
| Examples / Controllers | API / Backend | — | Phoenix controllers orchestrate data fetching and recipe dispatch |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| rendro | core | Document rendering | Phase focus is native Rendro layout APIs |

## Architecture Patterns

### Pattern 1: Explicit Template and Section Mapping
**What:** Instead of passing raw `header:` or `footer:` kwargs to `Rendro.flow/2`, define a named `page_template` and assign blocks to its regions via `Rendro.section/1`.
**When to use:** All business documents (invoices, reports) that require a consistent header/footer or multi-region layout.
**Example:**
```elixir
template = Rendro.page_template(
  name: :invoice,
  regions: [
    Rendro.region(name: :header, anchor: :top, ...),
    Rendro.region(name: :body, anchor: :flow, ...),
    Rendro.region(name: :footer, anchor: :bottom, ...)
  ]
)

Rendro.flow([],
  page_template: :invoice,
  page_templates: [template],
  sections: [
    Rendro.section(region: :header, content: [...]),
    Rendro.section(region: :body, content: [...]),
    Rendro.section(region: :footer, content: [...])
  ]
)
```

### Anti-Patterns to Avoid
- **Legacy Keyword Props:** Using `header: [blocks]` and `footer: [blocks]` directly on `Rendro.flow/2`. While supported for backward compatibility, it hides the powerful region system and relies on ad hoc pagination glue.

## Runtime State Inventory
Step 2.5: SKIPPED (Phase is pure code refactoring, no runtime state, secrets, or OS-level configurations modified)

## Common Pitfalls

### Pitfall 1: Mixing Content Assignment Types
**What goes wrong:** A document uses both `sections: [...]` and `header: [...]` kwargs, leading to confusing overlap in the composed document.
**Why it happens:** `Rendro.Pipeline.Compose.normalize_flow_layout/1` concatenates `doc.header` blocks and `:header` section blocks together sequentially.
**How to avoid:** Completely remove `header:` and `footer:` keyword arguments when adopting the explicit section pattern.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `header:`/`footer:` list kwargs | `sections:` targeting explicitly named `page_template` regions | Now (Phase 22) | Forces adopters to reason about geometries, yielding predictable and debuggable outputs |

## Open Questions (RESOLVED)

1. **Section Content in the Body**
   - What we know: `Rendro.flow/2` takes a primary `content` list, but `sections: [Rendro.section(region: :body, content: [])]` is also valid and processed.
   - What's unclear: Should canonical recipes pass body content as the primary argument to `flow(content, ...)` or exclusively through the `sections` list for symmetry?
   - Recommendation: For absolute symmetry and clarity in canonical recipes, prefer placing all regions (including body) in the `sections` list exclusively, passing `[]` as the primary flow content.

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | test/test_helper.exs |
| Quick run command | `mix test` |
| Full suite command | `mix ci` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LAY-12 | Canonical invoice recipe uses explicit sections and template | unit | `mix test test/rendro_test.exs` | ✅ |
| LAY-12 | Accrue adapter recipe uses explicit sections | unit | `mix test test/rendro/adapters/accrue_test.exs` | ✅ |
| LAY-12 | Phoenix example controller outputs valid pdf via recipe | unit | `mix test examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` | ❌ |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix ci`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` — needs coverage for the Phoenix example updates.

## Sources
### Primary (HIGH confidence)
- `lib/rendro/recipes.ex` - Verified legacy `header`/`footer` kwargs usage.
- `lib/rendro/adapters/accrue.ex` - Verified legacy `header`/`footer` kwargs usage.
- `README.md` - Verified mixed template/legacy kwargs documentation.
- `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` - Verified trivial block usage instead of realistic recipes.

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir codebase inspection.
- Architecture: HIGH - Direct verification of `Rendro.Pipeline.Compose`.
- Pitfalls: HIGH - Behavior confirmed from `compose.ex` source.

**Research date:** 2025-05-18
**Valid until:** 30 days