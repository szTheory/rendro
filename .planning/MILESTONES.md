# Milestones

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
