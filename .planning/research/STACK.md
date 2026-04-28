# Research: Stack for v1.1 Layout Authoring Maturity

## Recommendation

Keep v1.1 on the current Elixir/Phoenix-first stack. Do not introduce Phoenix, Oban, browser, or native-layout dependencies into core. Treat this milestone as an internal layout-contract and engine-refactor milestone, not a dependency-expansion milestone.

## Current Stack Truth

- Core runtime already matches the product boundary: pure Elixir rendering with optional adapters only.
- The current measurement path uses built-in Helvetica metrics from `Rendro.PDF.Font`.
- The current layout gaps are in internal data modeling and pipeline behavior, not in missing integration libraries.

## Suggested Stack Posture

- **Core runtime**: stay on Elixir 1.19.5 / OTP 28 contract already documented for the project.
- **Layout engine**: extend internal structs and pipeline modules (`Build`, `Compose`, `Measure`, `Paginate`, `Render`) rather than pulling in third-party layout engines.
- **Testing**: increase deterministic regression fixtures in ExUnit around pagination invariants, break decisions, and layout diagnostics.
- **Optional tooling**: only add helper modules if they preserve pure-core determinism and are justified by repeated internal complexity, not by feature marketing.

## What Not To Add In v1.1

- Browser/HTML renderers
- Font/image runtime dependencies
- Storage, queue, or persistence abstractions in core
- External validator binaries

## Why

The milestone's leverage is in stabilizing layout semantics. Extra dependencies would widen surface area without solving the core problem that current measurement and pagination still depend on hard-coded assumptions.
