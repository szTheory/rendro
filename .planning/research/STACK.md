# Stack Research

**Domain:** PDF signature fields and external signing preparation for a deterministic Elixir PDF generator
**Researched:** 2026-05-06
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir / OTP | 1.19.5 / 28 | Core authoring, validation, and adapter contracts | Matches Rendro's established runtime and keeps signature preparation inside the existing pure-Elixir core boundary. |
| PDF 1.7 / ISO 32000-1 semantics | Existing writer target | Signature field dictionaries, AcroForm wiring, widget annotations, and signature placeholder structure | Signature work is constrained by the PDF object model, so the milestone should extend Rendro's existing AcroForm writer rather than invent a higher-level abstraction detached from the spec. |
| External signing adapter boundary | New v2.0 seam | Hand off rendered bytes plus signing instructions to an external signer | Separates authored field generation from cryptographic trust operations, which aligns with the current protection and adapter philosophy. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:public_key` / OTP crypto tooling | OTP 28 | Parse certificates or validate basic signing inputs in adapters only | Use only if a first-party signing-preparation adapter needs certificate-shape checks; keep it out of the core authoring path. |
| `qpdf` | current optional external tool | Structural inspection, post-processing, and PDF transformation around protected artifacts | Use for existing protection flows only; do not use it as the signing engine for this milestone. |
| Poppler `pdfinfo` | current optional external tool | Structural validation lane | Use to prove the prepared PDF remains structurally readable; do not treat it as signature validity proof. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Docs-contract tests | Keep support claims honest | Extend `priv/support_matrix.json` and guides together so signature-prep language cannot drift. |
| Viewer proof checklist | Separate structural truth from viewer truth | Needed before promoting any signature-field viewer rows beyond `unverified`. |
| Fixture-based regression tests | Lock deterministic unsigned field serialization | Useful for object-shape assertions before any external signer is introduced. |

## Installation

```elixir
# Core milestone stays on existing Rendro dependencies.
# New external signing support should remain adapter-based and optional.

defp deps do
  [
    # existing deps only, unless a signing adapter is introduced separately
  ]
end
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Extend existing `%Rendro.FormField{}` / AcroForm path | Add a second signature-only document surface | Only choose a distinct surface if the existing form abstraction proves incapable of expressing signature widgets truthfully. |
| External signing adapter boundary | In-core cryptographic signing | Only consider in-core signing after a later milestone proves a need for first-party key custody and compliance claims. |
| Structural validation plus viewer proof | Promise generic signature compatibility | Never as a default; promote support per viewer only after recorded evidence exists. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `qpdf` as a digital-signature implementation | The official qpdf manual states digital-signature creation is not currently supported and only notes future support work in this area. | Keep qpdf for protection and structural workflows; use a separate external signer boundary for actual signing. |
| Core-managed keys, certificates, or HSM semantics in v2.0 | Expands Rendro from deterministic PDF authoring into key custody and compliance operations too early. | Accept signer-specific credentials only in optional adapters or external workflows. |
| Broad PAdES / LTV claims in the initial milestone | These require much more than field authoring and placeholder preparation. | Publish narrow "prepared for external signing" claims only. |

## Stack Patterns by Variant

**If the milestone stops at unsigned field authoring:**
- Use only core writer and validate-stage extensions.
- Because the work is still purely authored-PDF structure.

**If the milestone includes external signing preparation:**
- Add an optional adapter contract that receives the rendered artifact bytes and returns a signed or signable follow-on artifact.
- Because incremental signing and trust material should stay outside core.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Rendro core v0.2.x | Existing forms / protection surfaces | Signature prep should compose with the current AcroForm and artifact-first protection contracts instead of replacing them. |
| Optional signing adapter | External signer chosen by adopter | Keep the adapter contract narrow so signer-specific ecosystems can evolve without forcing core API churn. |

## Sources

- Adobe PDF 1.7 reference (`PDF32000_2008.pdf`) — AcroForm, signature field, signature dictionary, and incremental-update object model
- ETSI TS 102 778-6 — visible signature creation constraints and the separation between field creation and later signature value embedding
- ETSI TS 102 778-1 — PAdES baseline framing and why broad compliance claims exceed this milestone
- qpdf manual / official docs — qpdf is not currently a digital-signature creation tool
- Adobe Acrobat Sign / Electronic Seal API official docs — field visibility and document-permission concepts belong to signing workflows, not generic form authoring

---
*Stack research for: PDF signature fields and external signing preparation*
*Researched: 2026-05-06*
