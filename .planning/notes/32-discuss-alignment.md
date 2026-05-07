# Phase 32: Documentation and Support Boundaries - Discuss Phase Alignment

**Date:** 2026-05-03
**Status:** Approved

## Key Decisions

1. **Policy Document Location ("Hybrid Anchor" Strategy)**
   - Create a dedicated file at `guides/policies/stability_guarantee.md`.
   - Add a succinct "Stability & Versioning" section to `README.md` that links to the detailed HexDocs guide.

2. **ExDoc Groupings (`groups_for_extras`)**
   - Configure `mix.exs` to use ExDoc groupings.
   - **"Guides"**: For instructional content (`guides/branding.md`, `guides/integrations.md`).
   - **"Policies & Architecture"**: For operational rules and contracts (`guides/policies/stability_guarantee.md`).

3. **Release Stability Guarantee ("0.x.x with a Core Promise")**
   - The initial public release will remain in the `0.x.x` series (e.g., `0.1.0` or `0.2.0`).
   - **Core Stable, Adapters Beta**: The core PDF engine (`Rendro.Document`, `Rendro.Page`, pipeline) is considered stable and will not break without a minor version bump. Adapters (Phoenix, Oban) are treated as Beta and may evolve more rapidly. This promise must be explicitly written in the stability guarantee document.