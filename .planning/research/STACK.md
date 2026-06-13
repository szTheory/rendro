# Stack Research — v2.7 Page Context & Browser Proof Hardening

**Researched:** 2026-06-13
**Confidence:** HIGH

## Core Stack

No new core runtime dependencies are required for Phases 89-90.

- Elixir/OTP only.
- Extend existing section, pagination, and PAGE/running-content code.
- Preserve optional adapter boundaries and existing deterministic CI lanes.

## PDF.js Advisory Tooling

Phase 91 may add Node tooling, but only for advisory observation:

- `pdfjs-dist` pinned exactly through a lockfile or equivalent local tooling pin.
- Node version recorded in every observation artifact.
- Tooling scoped to scripts/tests/advisory CI, not `mix.exs` runtime deps.
- No Hex package dependency and no required-CI dependency.

## Release/Workflow Hygiene

Elixir ecosystem precedent still favors human-controlled or tag-gated releases for libraries like Rendro. v2.7 should not add release-please or PAT-driven release automation.

Acceptable v2.7 hardening:

- Minimize workflow permissions.
- Make docs publishing wording precise about unreleased vs Hex-published docs.
- Keep advisory contexts listed separately from required branch-protection contexts.

## Version/Pin Summary

| Component | Action | Pin Discipline |
|-----------|--------|----------------|
| Core Elixir deps | No new deps for page context/duplex | Existing lock discipline |
| pdfjs-dist | Advisory-only tooling | Exact pin plus observation metadata |
| Node | Advisory-only tooling | Record version in evidence |
| release-please | Do not adopt | Reconsider only if manual release friction becomes concrete |
