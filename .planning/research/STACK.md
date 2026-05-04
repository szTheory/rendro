# Technology Stack

**Project:** Rendro
**Researched:** 2026-05-04

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | 1.15+ | Core Rendering | Maintained project constraint. Pure core, no NIFs. |

### Async & Operations (Optional Adapters)
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Oban | ~> 2.17 | Async Job Queue | The standard for Elixir background jobs. Idempotent and reliable. |
| Threadline | latest | Audit Trails | "Do Now" integration for tracking template changes and render outcomes. |

### Ecosystem Integrations (Optional Adapters / Recipes)
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Mailglass | latest | Transactional Email | "Do Now" integration for attaching generated PDFs to emails. |
| Accrue | latest | Billing & Invoicing | "Do Now" integration for deterministic financial document generation. |

## Installation

Rendro's philosophy mandates that these dependencies remain **optional**.

```elixir
# In a user's mix.exs
defp deps do
  [
    {:rendro, "~> 1.x"},
    # Optional extensions chosen by the consumer
    {:rendro_oban, "~> 0.1"},
    {:threadline, "~> x.x"},
    {:mailglass, "~> x.x"}
  ]
end
```

## Sources
- `prompts/rendro-integration-opportunities.md`
- `prompts/rendro-oss-dna.md`
- `.planning/EPIC.md`