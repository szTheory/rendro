# Milestones

## v1.9 Embedded Artifact Surfaces (Shipped: 2026-05-06)

**Phases completed:** 3 phases (48, 49, 50)

**Key accomplishments:**

- Added a deterministic authored boundary for document-level embedded files with explicit metadata and validate-stage rejection of ambiguous state.
- Extended the writer to emit deterministic `/EmbeddedFile`, `/Filespec`, `/Names`, and `/AF` catalog wiring sorted by stable authored keys.
- Added curated link annotations limited to `http`/`https` URIs and in-document page targets through the existing page `/Annots` seam — no named destinations, no `/GoToR`, no generic action dictionaries.
- Published the proof-backed support contract: family-first matrix entries for `embedded_files` and `links`, canonical guide wording that distinguishes PDF-internal embedded files from delivery attachments, and a new `Embedded artifact semantic-claims` docs-contract lane.
- Recorded manual viewer evidence in Adobe Acrobat Reader and Apple Preview; promoted only proof-backed pairs (Adobe: both surfaces; Preview: links supported, embedded files unverified per D-09).

**Audit status:** `tech_debt` — all 7 requirements satisfied; debt is documentation/tracking-artifact only (missing `49-VERIFICATION.md`, stale `wave_0_complete: false` flags, inconsistent SUMMARY frontmatter shape). See `milestones/v1.9-MILESTONE-AUDIT.md`.

---

## v1.8 Interactive PDF Forms (Shipped: 2026-05-05)

**Phases completed:** 3 phases (45, 46, 47)

**Key accomplishments:**

- Added deterministic AcroForm text-field authoring and serialization to the core pipeline.
- Extended the same authored boundary to checkbox and radio widgets with explicit validation and deterministic button appearances.
- Added form-specific support boundaries in `priv/support_matrix.json` and docs-contract coverage to keep public claims truthful.
- Proved representative forms output structurally through the Poppler lane and recorded Apple Preview viewer proof.

---

## v1.5 Validation and Trust Surfaces (Shipped: 2026-05-05)

**Phases completed:** 4 phases (41, 42, 43, 44)

**Key accomplishments:**

- Implemented `Rendro.Adapters.Poppler` to provide structural validation for generated PDFs via `pdfinfo`.
- Added a machine-readable `support_matrix.json` for clear operational boundaries.
- Introduced advanced layout controls for widow/orphan management.
- Extended layout capabilities with robust nested layout structures.

---

## v1.4 Async Delivery and Artifact Operations (Shipped: 2026-05-05)

**Phases completed:** 5 phases

**Key accomplishments:**

- Implemented table fragmentation DSL, grid projection, and cell fragmentation in the measure and paginate phases.
- Introduced `Rendro.Artifact` to encapsulate generated PDF binaries, deterministic hashes, and metadata.
- Added `Rendro.Storage` and `Rendro.Audit` behaviors for external persistence and logging.
- Implemented optional integrations (`Accrue`, `Mailglass`, `Oban.RenderWorker`) to power production async/delivery workflows.

---

## v1.3 First Public Hex Release Readiness (Shipped: 2026-05-03)

**Phases completed:** 3 phases

**Key accomplishments:**

- Added licensing, package metadata, API stability guidance, and release preflight proof lanes for the first public package boundary.

---
