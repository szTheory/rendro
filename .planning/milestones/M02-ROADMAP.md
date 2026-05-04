# Milestone 2: Advanced Layout & Typography (ROADMAP)

## Phases
- [ ] **Phase 35: Complex Text & i18n Foundations** - Support diverse character sets and font subsetting end-to-end.
- [ ] **Phase 36: Advanced Block Pagination** - Prevent widows and orphans in document flow.
- [ ] **Phase 37: Advanced Table Layout & Fragmentation** - Render complex multi-page tables with explicit cell fragmentation.

## Phase Details

### Phase 35: Complex Text & i18n Foundations
**Goal**: Users can render documents with mixed character sets and complex scripts correctly without bloating PDF size.
**Depends on**: Nothing
**Requirements**: Typography, i18n
**Success Criteria** (what must be TRUE):
  1. User can generate PDFs containing mixed character sets (Latin, Arabic, CJK) with correct text shaping and directionality.
  2. PDF artifact sizes remain within reasonable bounds despite using complex custom fonts, proving advanced font subsetting works.
  3. Missing glyphs emit structured warnings via Telemetry and fall back gracefully rather than crashing the render pipeline.
**Pipeline Alignment**:
  - **Build**: Register font shaping policies and load subsetting configuration.
  - **Compose**: Map character sequences to shaped glyphs and handle directionality.
  - **Measure**: Calculate exact bounding boxes for shaped text blocks.
  - **Paginate**: Apply basic text wrapping boundaries for complex scripts.
  - **Render**: Create PDF objects containing subsetted font data and shaped text.
  - **Validate**: Ensure binary checksum consistency across multi-script documents.
**Plans**: TBD

### Phase 36: Advanced Block Pagination
**Goal**: Users can control how text blocks break across page boundaries, avoiding visual artifacts.
**Depends on**: Phase 35
**Requirements**: Pagination (Widows/Orphans)
**Success Criteria** (what must be TRUE):
  1. User can configure widow and orphan prevention at the block level.
  2. System predictably shifts text blocks to new pages to avoid isolated lines, rendering without leaving orphaned lines.
  3. The same document AST must produce the exact same PDF binary checksum across multiple runs when breaking pages.
**Pipeline Alignment**:
  - **Build**: Add widow/orphan constraints to the document AST.
  - **Compose**: Cascade pagination constraints down to block elements.
  - **Measure**: Calculate exact line metrics and natural breaks for text blocks.
  - **Paginate**: Prevent break points that would result in isolated single lines (widows/orphans).
  - **Render**: Write properly broken text blocks cleanly across pages.
  - **Validate**: Verify edge-case page boundary tests pass deterministically.
**Plans**: TBD

### Phase 37: Advanced Table Layout & Fragmentation
**Goal**: Users can generate complex data tables that fragment seamlessly and predictably across multiple pages.
**Depends on**: Phase 36
**Requirements**: Advanced Layout, Pagination (Table Fragmentation)
**Success Criteria** (what must be TRUE):
  1. User can generate a multi-page PDF with a continuous data table proving correct table continuation.
  2. User can configure explicit cell fragmentation allowing nested data to span page boundaries safely.
  3. Tables with complex column sharing and nested data render without layout distortion.
  4. Engine halts with a deterministic layout error detailing the exact constraint violation if a row cannot fit on a single page even after fragmentation.
**Pipeline Alignment**:
  - **Build**: Support nested table configurations and explicit cell fragmentation in AST.
  - **Compose**: Resolve shared column spans and cell constraints.
  - **Measure**: Perform deep measurement of nested row constraints.
  - **Paginate**: Split cells explicitly across pages according to fragmentation configuration.
  - **Render**: Draw partial cells, headers, and continuation boundaries across pages.
  - **Validate**: Multi-page complex table PDF checksum verification.
**Plans**: TBD
