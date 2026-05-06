# Architecture Research

**Domain:** Signature-field authoring and external signing preparation inside Rendro
**Researched:** 2026-05-06
**Confidence:** HIGH

## Standard Architecture

### System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                     Authored Input Layer                    │
├─────────────────────────────────────────────────────────────┤
│  Rendro.form_field/3  Signature field opts  Support claims │
└──────────────┬──────────────────────┬───────────────────────┘
               │                      │
├─────────────────────────────────────────────────────────────┤
│                 Validation / Normalization                 │
├─────────────────────────────────────────────────────────────┤
│  CheckFormFields  Signature-specific rule checks  Errors   │
└──────────────┬──────────────────────┬───────────────────────┘
               │                      │
├─────────────────────────────────────────────────────────────┤
│                       Core PDF Writer                       │
├─────────────────────────────────────────────────────────────┤
│  AcroForm catalog  Widget annotations  Signature objects   │
└──────────────┬──────────────────────┬───────────────────────┘
               │                      │
├─────────────────────────────────────────────────────────────┤
│                Artifact / External Trust Layer             │
├─────────────────────────────────────────────────────────────┤
│  %Rendro.Artifact{}  signing prep seam  optional adapters  │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `%Rendro.FormField{}` | Own authored widget intent | Extend the existing form field type system rather than add a second signature DSL |
| `Rendro.Pipeline.Validate` + form rules | Reject unsupported field semantics early | Add signature-specific checks to the existing validate-stage envelope |
| `Rendro.PDF.Writer` | Serialize AcroForm, widget, and signature-related PDF objects deterministically | Extend existing form allocations and catalog injection seams |
| Artifact-first signing prep API | Hand off rendered bytes to a signer-specific workflow | Parallel the existing `Rendro.Protect` pattern |
| Support matrix + docs-contract | Publish the truthful product boundary | Keep `signature` / `digital_signatures` claims synchronized with proof |

## Recommended Project Structure

```text
lib/
├── rendro/
│   ├── form_field.ex            # authored field model, extended carefully
│   ├── pipeline/
│   │   └── validate.ex          # existing validation pipeline
│   ├── rules/
│   │   └── check_form_fields.ex # signature-field validation semantics
│   ├── pdf/
│   │   └── writer.ex            # AcroForm and signature object serialization
│   └── sign/                    # optional new artifact-first signing prep boundary
├── rendro/adapters/             # optional signer-specific adapter(s), if any
priv/
│   └── support_matrix.json      # truthful support boundary
guides/
│   └── api_stability.md         # public support language
```

### Structure Rationale

- **Existing form path first:** the current code already centralizes field semantics in `FormField`, validation rules, and `writer.ex`.
- **Artifact-first sign module:** keeps post-render signing prep separate from authored layout/render responsibilities.
- **Optional adapters:** signer-specific integration belongs beside the existing adapter family, not in core.

## Architectural Patterns

### Pattern 1: Extend the Existing Form Surface

**What:** Add signature widgets as one more authored field family if the current struct can express them without lying.
**When to use:** When signature fields behave like authored AcroForm widgets with additional signing metadata.
**Trade-offs:** Public API stays small, but validation and writer logic become more nuanced.

### Pattern 2: Artifact-First Trust Operations

**What:** Render first, then pass `%Rendro.Artifact{}` into a signing-preparation seam.
**When to use:** For any operation that depends on final bytes, incremental updates, or external credentials.
**Trade-offs:** Clear separation of concerns, but the API surface must be explicit about deterministic core vs non-deterministic post-processing.

### Pattern 3: Proof-Gated Capability Promotion

**What:** Treat support-matrix rows and docs as product behavior that must be backed by tests and recorded evidence.
**When to use:** Always, especially for signature and viewer claims.
**Trade-offs:** Slower marketing surface, much stronger trust posture.

## Data Flow

### Request Flow

```text
Author document
    ↓
form_field(type: :signature, ...)
    ↓
Validate.run(document)
    ↓
PDF writer emits unsigned signature field structures
    ↓
%Rendro.Artifact{}
    ↓
optional signing-prep API / adapter
    ↓
prepared or externally signed artifact
```

### Key Data Flows

1. **Unsigned field authoring:** authored field input -> validate-stage semantics -> AcroForm/widget serialization.
2. **External signing preparation:** rendered artifact bytes -> signer-specific handoff contract -> updated artifact metadata and outputs.
3. **Truth boundary publication:** structural tests + docs-contract + viewer notes -> support matrix and guide claims.

## Anti-Patterns

### Anti-Pattern 1: Sign During Render

**What people do:** Thread signing credentials or byte-range logic directly into the core render pipeline.
**Why it's wrong:** It entangles layout generation with trust operations and makes core behavior environment-specific.
**Do this instead:** Render the unsigned PDF first, then hand off artifact bytes through a separate signing-prep seam.

### Anti-Pattern 2: Parallel Signature Architecture

**What people do:** Build a separate signature authoring subsystem unrelated to forms.
**Why it's wrong:** Duplicates AcroForm/writer concepts Rendro already has and increases drift risk.
**Do this instead:** Reuse the existing form-field normalization and writer seams unless the spec forces a true divergence.

### Anti-Pattern 3: Support Claim Inflation

**What people do:** Market "digital signatures" once a field exists in the PDF.
**Why it's wrong:** A visible field is not a cryptographically valid signature workflow.
**Do this instead:** Publish narrow `signature field` and `external signing preparation` claims only.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| External signer / HSM / SaaS signing platform | Artifact-first adapter boundary | Accept rendered bytes and signer-specific inputs outside core |
| Poppler `pdfinfo` | Structural verification lane | Useful for readability, not signature validity proof |
| qpdf | Adjacent post-processing tool | Keep separate from signing responsibilities |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `FormField` -> `CheckFormFields` | Struct validation | Add narrow signature semantics here first |
| `CheckFormFields` -> `PDF.Writer` | Normalized authored state | Writer should only receive supported shapes |
| `PDF.Writer` -> signing prep seam | `%Rendro.Artifact{}` bytes and metadata | Mirrors existing protection architecture |

## Sources

- Adobe PDF 1.7 reference (`PDF32000_2008.pdf`)
- ETSI TS 102 778-6
- ETSI TS 102 778-1
- qpdf official documentation
- Rendro local architecture: `lib/rendro/form_field.ex`, `lib/rendro/pipeline/validate.ex`, `lib/rendro/pdf/writer.ex`, `priv/support_matrix.json`

---
*Architecture research for: Signature-field authoring and external signing preparation*
*Researched: 2026-05-06*
