# Upgrading to 1.0

1.0 is a stability commitment, not a rewrite — if you're on 0.3.x no code changes are required. The public library surface is the same as the 0.3.x releases; this version formalizes the promise with an explicit two-tier stability contract, a soft-deprecation-first policy, and a formal release.

## What 1.0 Means for You

Rendro's public surface is organized into two tiers:

**Tier-1 Stable — strict SemVer:** Breaking changes only in a major version (`1.x.x` → `2.0.0`). Additive changes are allowed in any minor. This tier covers the core document model and signing/protection APIs:

- Core document model: `Rendro.Document`, `Rendro.PageTemplate`, `Rendro.Section`, `Rendro.Metadata`
- Artifact struct: `Rendro.Artifact` (the `%Rendro.Artifact{}` struct and its documented fields)
- Signing surface: `Rendro.Sign` — `prepare/2`, `sign/2`, `augment/2`, `validate/2`
- Protection surface: `Rendro.Protect` — `password/2`
- Top-level pipeline functions: `Rendro.flow/2`, `Rendro.signature_field/2`, `Rendro.render_signed/3`, `Rendro.render_protected/3`
- Diagnostics map common keys: `:level` and `:type` are stable for adopters consuming `:diagnostics` maps

**Tier-2 Evolving — additive-only within a major:** These may break to follow upstream library majors, but will not introduce breaking changes within a major otherwise:

- Adapter modules: `Rendro.Adapters.PyHanko`, `Rendro.Adapters.Qpdf`, and all other `Rendro.Adapters.*` modules
- Extended diagnostics shape beyond the documented common keys (`:level`, `:type`)

For the full two-tier contract, the byte-output carve-out, the "NOT covered by SemVer" list, and the deprecation policy, see `guides/api_stability.md`.

## What's New Since 0.3.0

The 1.0.0 release consolidates all unreleased work from the 0.3.x → 1.0.0 period into a single public hex release:

**Viewer evidence and CHANGELOG discipline:** Every (surface × viewer) cell across forms, protection, signature widgets, signing preparation, signed artifacts, and long-lived signed artifacts is now terminal — recorded `supported` with a checked-in evidence file, or `explicit_deferral` with a named viewer-behavior reason. No cell is silently unverified. Evidence files live in `priv/viewer_evidence/` and the operator recording recipe is in `guides/viewer_evidence.md`.

**Batteries-included workflow features:** Five data-driven recipes now ship on the three-rung escape hatch — `Rendro.Recipes.Statement`, `Rendro.Recipes.Receipt`, and `Rendro.Recipes.Certificate` alongside the existing `Invoice`/`BrandedInvoice`, with a deterministic page-numbering primitive ("Page X of Y" running headers/footers) and an executable reference Phoenix application. Optional adapter wiring for Oban/Threadline workflows and branding updates are included.

**Formal API tiers and deprecation policy:** The public surface is now machine-checked: a tiered manifest (`priv/public_api.json`) is verified by a docs-contract enforcement lane that fails CI on surface drift. The two-tier contract, soft-deprecation-first policy, and a formal Deprecations table (currently `_None as of 1.0.0_`) are published in `guides/api_stability.md`. Internal milestone labels are scrubbed from public guides.

## Support Matrix

Viewer support posture is tracked per surface and per viewer. For the detailed per-surface support boundaries — interactive forms, signing preparation, signed artifacts, long-lived evidence, embedded files, curated links, protection, and viewer posture — see the `## Per-Surface Support Boundaries` section of `guides/api_stability.md`.

The machine-readable index is `priv/support_matrix.json`, with each `supported` cell pointing to a recorded evidence file under `priv/viewer_evidence/`.

---

For full change history, see [CHANGELOG.md](../CHANGELOG.md).
