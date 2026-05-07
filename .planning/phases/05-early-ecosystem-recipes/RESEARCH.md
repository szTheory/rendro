# Phase 05: Early Ecosystem Recipes - Research

**Researched:** 2026-04-24
**Domain:** Ecosystem Integrations & Document Recipes
**Confidence:** HIGH

## Summary

This phase focuses on integrating Rendro with the wider Elixir/Phoenix ecosystem, specifically targeting three libraries maintained by szTheory: `threadline` (auditing), `mailglass` (email), and `accrue` (billing). The goal is to provide "batteries-included" recipes and adapters that make Rendro the natural choice for applications already using these tools.

**Primary recommendation:** Use optional dependency guards (`Code.ensure_loaded?/1`) to provide adapters within the core Rendro package without forcing users to install the integration libraries unless needed.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Audit Logging | API / Backend | Database | `threadline` uses PG triggers but requires application-level intent. |
| Email Attachments | API / Backend | — | Constructing multipart emails with PDF binaries. |
| Billing Recipes | API / Backend | — | Transforming `Accrue` structs into `Rendro` documents. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `threadline` | `~> 0.2` | Audit logging | Standard for szTheory ecosystem auditing. |
| `mailglass` | `~> 0.1` | Email previews | Standard for szTheory transactional email. |
| `accrue` | `~> 0.3` | Billing engine | Standard for szTheory SaaS billing. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|--------------|
| `swoosh` | `~> 1.0` | Email delivery | Required by `mailglass` for actual sending. |

## Architecture Patterns

### Optional Adapters Pattern
Follow the pattern established in `Rendro.Adapters.Oban.RenderWorker`:
```elixir
if Code.ensure_loaded?(SomeLib) do
  defmodule Rendro.Adapters.SomeLib do
    # Implementation
  end
end
```

### `Rendro.Audit` Behavior
Define a behavior for audit logging that allows switching between `Threadline` and other backends.
```elixir
defmodule Rendro.Audit do
  @callback track_render(render_id :: String.t(), metadata :: map()) :: :ok | {:error, term()}
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Email Composition | Raw SMTP/MIME | `Swoosh` / `Mail` | Complex RFC standards. |
| Audit Triggering | Manual Log Tables | `threadline` | Trigger-based auditing is more reliable for row changes. |

## Common Pitfalls

### Pitfall 1: Binary Bloat in Audits
**What goes wrong:** Storing full PDF binaries in audit logs.
**Why it happens:** Wanting a "perfect" history of what was sent.
**How to avoid:** Store the `render_id` and metadata, but store the artifact in S3/Object storage, not the audit DB.

### Pitfall 2: Compile-time Dependency Leaks
**What goes wrong:** `mix compile` failing for users who don't have `accrue` installed.
**How to avoid:** Use `Code.ensure_loaded?/1` inside modules and avoid top-level `alias` or `import` of optional libraries.

## Code Examples

### `Mailglass.attach_pdf/3`
```elixir
def attach_pdf(email, pdf_binary, filename) do
  email
  |> Swoosh.Email.attachment(
    Swoosh.Attachment.new(pdf_binary, filename: filename, content_type: "application/pdf")
  )
end
```

## Open Questions

1. **`mailglass` versioning:** The package is visible on GitHub but was not found on Hex during initial search. Need to verify if it's published under a different name or if it should be treated as a GitHub dependency for the example app.
2. **`Rendro.Audit` triggers:** Should auditing happen automatically via Telemetry, or require explicit calls? *Recommendation:* Provide a Telemetry-based auditor that users can opt into.

## Sources

### Primary (HIGH confidence)
- `szTheory` GitHub Repositories (Accrue, Threadline, Mailglass)
- `Rendro` existing codebase (Adapters, Telemetry)

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH
- Architecture: HIGH
- Pitfalls: MEDIUM

**Research date:** 2026-04-24
**Valid until:** 2026-05-24
