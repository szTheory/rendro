# REQUIREMENTS — B1 Brand System & Identity Lab

Status: Complete · 2026-06-14 · All requirements met.

## Scope

Pressure-test the existing Rendro brand book and productionize it into committed, source-controllable
artifacts: a critical audit, buildable design tokens, a chosen logo system (selected by the user from
multiple options), visual specimens, refined voice/marketing copy, and a self-contained HTML brand book —
all in `brand/`, with strict anti-bloat discipline.

## Requirements

### Audit (AUD)
| ID | Requirement | Phase | Status |
|----|-------------|-------|--------|
| AUD-01 | 14-section critical audit of the existing brand book with candid executive judgment | 101 | [x] |
| AUD-02 | Brand DNA extraction (essence, audience, metaphor, traits, anti-traits, principles) | 101 | [x] |
| AUD-03 | 15-dimension 1–10 scorecard with why / risk / recommended-fix each | 101 | [x] |
| AUD-04 | ≥25-surface stress test matrix (GitHub, README, HexDocs, favicon, social, dark/light, …) | 101 | [x] |
| AUD-05 | Consolidated KEEP/TIGHTEN/REWORK/ADD/REMOVE rulings + CHILI trademark flag for human review | 101 | [x] |

### Tokens (TOK)
| ID | Requirement | Phase | Status |
|----|-------------|-------|--------|
| TOK-01 | Raw palette + semantic role tokens resolving in light AND dark | 102 | [x] |
| TOK-02 | Type, spacing, radius, and interaction-state tokens forming a closed set | 102 | [x] |
| TOK-03 | `mix brand.gen` emits `tokens.css` + `tailwind.tokens.js` with 1:1 key parity to `tokens.json` | 102 | [x] |
| TOK-04 | WCAG AA contrast documented for text/background pairings | 102 | [x] |

### Logo (LOGO)
| ID | Requirement | Phase | Status |
|----|-------------|-------|--------|
| LOGO-01 | 4–5 distinct editable SVG logo directions, each constraint-compliant (no box, integrated typemark, tight logotype, no subtitle) | 103 | [x] |
| LOGO-02 | Each direction renders at mark / lockup / favicon scale, light + dark | 103 | [x] |
| LOGO-03 | `logo-lab.html` gallery on mock surfaces + recorded user selection | 103 | [x] |
| LOGO-04 | Primary + mark + wordmark + monochrome lockups with consistent geometry | 104 | [x] |
| LOGO-05 | Dark/light variants + with-subtitle variant | 104 | [x] |
| LOGO-06 | Favicon (legible @16px) + social avatar (legible cropped to circle) | 104 | [x] |
| LOGO-07 | Logo usage sheet (clear space, min sizes, do/don't, color pairings) | 104 | [x] |

### Specimens (SPEC)
| ID | Requirement | Phase | Status |
|----|-------------|-------|--------|
| SPEC-01 | Palette specimen (raw + semantic, light/dark) | 105 | [x] |
| SPEC-02 | Typography specimen (full scale) | 105 | [x] |
| SPEC-03 | Component + callout specimens showing TOK states | 105 | [x] |
| SPEC-04 | Code-block specimen (JetBrains Mono, Elixir) | 105 | [x] |
| SPEC-05 | README-header mock + 1200×630 social card | 105 | [x] |

### Copy (COPY)
| ID | Requirement | Phase | Status |
|----|-------------|-------|--------|
| COPY-01 | Voice principles, tone-by-context, vocabulary do/don't | 106 | [x] |
| COPY-02 | Microcopy patterns for error/empty/success with before/after examples | 106 | [x] |
| COPY-03 | Marketing blocks: taglines, short/long descriptions, README intro, hero, CTAs (primary + alternates) | 106 | [x] |
| COPY-04 | Repo/Hex/HexDocs/social blurbs length-fit to each surface | 106 | [x] |

### Brand Book (BOOK)
| ID | Requirement | Phase | Status |
|----|-------------|-------|--------|
| BOOK-01 | Self-contained `brand/index.html` (inline CSS + inline SVG), opens offline | 107 | [x] |
| BOOK-02 | Covers tokens, logo system, specimens, voice/copy, audit summary | 107 | [x] |
| BOOK-03 | Light/dark both correct; all internal links resolve | 107 | [x] |

### QA / Anti-bloat (QA)
| ID | Requirement | Phase | Status |
|----|-------------|-------|--------|
| QA-01 | `.gitignore` rules block binaries under `brand/`; no PNG/woff/ttf/pdf tracked | 107 | [x] |
| QA-02 | `brand/` absent from `mix.exs` `package.files`; `mix hex.build` tarball excludes `brand/` | 107 | [x] |
| QA-03 | `du -sh brand/` under budget (≤ ~400 KB target); regeneration via `mix brand.gen` is deterministic | 107 | [x] |

## Traceability
Each requirement maps to exactly one phase. Verification recorded per-phase in `B1-phases/{NN}-{slug}/{NN}-VERIFICATION.md`.
