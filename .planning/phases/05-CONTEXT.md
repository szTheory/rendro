# Phase 5 Context: Early Ecosystem Recipes

This document captures implementation decisions for Phase 5 (Early Ecosystem Recipes) based on research into sibling szTheory libraries (`threadline`, `mailglass`, `accrue`) and idiomatic Elixir patterns.

## 1. Integration Strategy: Built-in Optional Adapters

We will provide built-in modules in `lib/rendro/adapters/` for high-value integrations.

- **Decision**: Use `Code.ensure_loaded?/1` to gate these modules so they remain optional and don't introduce hard dependencies.
- **Rationale**: Built-in modules provide better discovery in HexDocs, compile-time safety for users with the dependencies, and a "batteries-included" experience for the ecosystem.
- **Locked Modules**:
  - `Rendro.Adapters.Threadline`
  - `Rendro.Adapters.Mailglass`

## 2. Validation Strategy: Contract Mocks + Recipe Example App

- **Decision**: Use "Contract Mocks" in Rendro's core test suite to verify adapter behavior without requiring sibling libraries.
- **Decision**: Create or update `examples/recipe_host/` (or similar) to act as a real-world integration testbed where sibling libraries ARE present.
- **Rationale**: Keeps the core light and portable while proving E2E correctness in a dedicated adoption proof surface.

## 3. Threadline Integration: `Rendro.Audit` Behavior

- **Decision**: Define a first-class `Rendro.Audit` behavior in `lib/rendro/audit.ex`.
- **Decision**: Implement `Rendro.Adapters.Threadline` as a reference implementation of this behavior.
- **Events to capture**:
  - `template_published` (mapping to `Threadline.record_action(:publish, ...)` )
  - `render_succeeded`
  - `render_failed` (with redacted/safe error metadata)
- **Rationale**: Decouples the "Audit" concept from the specific implementation, allowing users to swap providers while keeping the integration points standard.

## 4. Mailglass Integration: Attachment Helper

- **Decision**: Ship `Rendro.Adapters.Mailglass.attach_pdf(message, doc, filename \\ "document.pdf")`.
- **Behavior**:
  - Calls `Rendro.render(doc)`.
  - Uses `Mailglass.Message.update_swoosh/2` to pipe into `Swoosh.Email.attachment/4`.
  - Raises on render error if used in a builder context (consistent with Mailglass/Swoosh error handling).
- **Rationale**: Drastically reduces boilerplate for the most common "generate and send" workflow.

## 5. Accrue Integration: Recipe Templates

- **Decision**: Provide `Rendro.Recipes.Accrue` with standard document templates.
- **Templates**:
  - `invoice/2`: Accepts `%Accrue.Billing.Invoice{}` (or compliant map) and returns `%Rendro.Document{}`.
  - `statement/2`: Accepts a list of transactions and returns `%Rendro.Document{}`.
- **Rationale**: Accrue users often need the same layout (standard invoice). Providing a starting template that understands Accrue schemas moves them from "empty page" to "functional invoice" in minutes.

## 6. Technical Integrity & Patterns

- **Naming**: Adapters must follow `Rendro.Adapters.*` naming.
- **Errors**: Prefer raising in builder-style helpers (`Mailglass`) to allow clean piping, but return `{:ok, _} | {:error, _}` in lifecycle-style adapters (`Threadline`).
- **Telemetry**: All adapters should be PII-free in their own telemetry (already enforced by Rendro core).

---
*Generated: 2026-04-24*
