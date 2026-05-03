# Milestone 2: Advanced Layout & Typography (Core Maturation)

## Project Description
This milestone addresses the remaining core layout and presentation needs required to support complex business documents in Rendro, while strictly maintaining the deterministic pure-Elixir rendering engine constraint. It covers advanced typography, expanded internationalization, and robust flow enhancements.

## Why This Milestone
As Rendro moves towards supporting the full spectrum of Elixir SaaS applications, the documents it generates must handle complex real-world data safely. This means proper internationalization (i18n) for diverse character sets, advanced font subsetting to keep PDF sizes manageable, and bulletproof table handling with proper pagination controls so that large reports don't break unpredictably.

## User-Visible Outcome
Users can generate PDFs with complex, multi-page data tables that handle column sharing, nested data, and explicit cell fragmentation seamlessly. They can also use diverse character sets and text directionalities without layout distortion, and the resulting PDFs will be smaller due to advanced font subsetting.

## Completion Class
Integration / Operational

## Final Integrated Acceptance
1. Generating a multi-page PDF with a complex data table spanning multiple pages, proving correct table continuation and cell fragmentation.
2. Generating a PDF containing mixed character sets (e.g., Latin, Arabic, CJK) demonstrating correct text shaping, directionality, and fallback strategies.
3. PDF artifact sizes remain within reasonable bounds despite using complex custom fonts, proving subsetting works.
4. "Widow" and "Orphan" control scenarios must render predictably without leaving isolated lines on new pages.

## Architectural Decisions
### Pure-Elixir Font Subsetting and Shaping
**Rationale:** To preserve the pure-core boundary and avoid headless Chrome dependencies, we must implement font subsetting and text shaping natively in Elixir or rely on tightly-bound, deterministic NIFs/Ports if native is not feasible. This ensures zero operational surprises for users.

### Explicit Table Continuation Semantics
**Rationale:** Relying on implicit page breaks for tables is non-deterministic. We will introduce explicit semantics for how table cells fragment across pages.

## Error Handling Strategy
- Missing glyphs during text shaping will emit structured warnings via Telemetry and fall back gracefully rather than crashing the render pipeline.
- If a table row cannot fit on a single page even after fragmentation, the engine will halt with a deterministic layout error detailing the exact constraint violation.

## Risks and Unknowns
- Native Elixir text shaping (handling complex scripts like Arabic/Indic) is notoriously difficult; we may need to evaluate Rust NIFs (e.g., using `rustler` + HarfBuzz) while ensuring it doesn't break our "no operational dependencies" promise.
- Font subsetting logic might introduce performance bottlenecks if not optimized.

## Existing Codebase / Prior Art
- `Rendro.Pipeline.Measure` and `Rendro.Text`: Currently handle basic deterministic layout and wrapping. Will need significant expansion for complex scripts.
- `Rendro.Table`: Currently handles basic continuation, but lacks nested data or explicit cell fragmentation.

## Relevant Requirements
- Core Maturation: Advanced Typography & i18n
- Core Maturation: Robust Flow Enhancements

## Scope
**In Scope:**
- Advanced font subsetting, shaping, and fallback strategies.
- Expanded i18n support (diverse character sets, text directionality).
- Advanced table handling (complex column sharing, nested data, explicit cell fragmentation).
- Expanded pagination controls and block-level break semantics (widows/orphans).

**Out of Scope:**
- Full HTML/CSS rendering engine.
- Interactive PDF elements (forms, digital signatures).

## Technical Constraints
- Core rendering MUST remain pure Elixir (or tightly-coupled Rust NIFs that do not require external service dependencies).
- Memory usage during table rendering must remain bounded.

## Integration Points
- Telemetry: Emit granular events for missing glyphs and pagination breaks.

## Testing Requirements
- **Unit:** Extensive testing of the text shaping and font subsetting algorithms.
- **Integration:** Rendering full documents using the new table and typography features.
- **Deterministic:** The same document AST must produce the exact same PDF binary checksum across multiple runs.

## Acceptance Criteria
- [ ] Table cells can explicitly fragment across page boundaries.
- [ ] Widows and orphans are prevented according to user configuration.
- [ ] Documents containing Arabic and CJK text render correctly with appropriate shaping.
- [ ] Embedded fonts are subsetted, reducing file size compared to full embedding.

## Open Questions
- Do we implement HarfBuzz via a Rust NIF, or can we achieve sufficient text shaping natively in Elixir for our target use cases?
