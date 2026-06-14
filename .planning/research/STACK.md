# Technology Stack

**Project:** Rendro
**Researched:** 2026-06-14

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir (Native) | Existing | PDF Object Generation (`/Outlines`, `/Dests`, `/Annots`) | Core constraint: pure-Elixir core without external rendering dependencies. Outlines, anchors, and cross-references are standard PDF dictionary objects that can be natively serialized within the existing engine. |

### Database
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| N/A | N/A | N/A | No database required for deterministic PDF generation. |

### Infrastructure
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Poppler | Existing | Structural Validation | Existing `poppler` adapter will be used to validate the structural integrity of generated `/Outlines` and `/Dests` PDF catalogs in CI without adding new tools. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| *None* | N/A | Zero new dependencies | TOC and document navigation must be implemented purely within the existing deterministic pipeline to avoid widening the deployment footprint. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| PDF Manipulation | **Native Elixir PDF Serialization** | Hex packages like `pdf_generator`, `wkhtmltopdf` wrappers | **Explicitly forbidden** by project constraints. Rendro avoids browser runtimes and external binaries for core generation to guarantee determinism. |
| Pipeline State | **Stateless Post-Layout Resolution** | Stateful accumulator variables, multi-pass agents | **Explicitly forbidden**. Breaking the `build -> compose -> measure -> paginate -> render` deterministic pipeline with statefulness would violate core architecture. Anchors and TOC references must be resolved purely during/after pagination. |

## Installation

No new installation steps are required for this milestone.

```bash
# Existing dependencies only
mix deps.get
```

## Anti-Additions (What NOT to add)

To preserve the pure-Elixir, Phoenix-first engine constraint, explicitly **do not add**:
- **Browser runtimes** (Puppeteer, Playwright)
- **External CLI tools** for TOC injection (e.g., ghostscript, pdftk)
- **Stateful GenServers or agents** for collecting TOC entries during layout passes (violates determinism)

## Sources

- `.planning/PROJECT.md` (Constraints: "Keep the core pure Elixir with no hard dependency on Phoenix, Oban, browser runtimes, Python packages... Extend the existing `build -> compose -> measure -> paginate -> render -> validate` pipeline instead of creating an alternate rendering path")
