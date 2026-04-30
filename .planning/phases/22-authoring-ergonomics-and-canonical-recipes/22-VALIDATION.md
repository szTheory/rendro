# Phase 22 Validation Plan

## Goal
Convert the stronger engine surface into an adoption-ready authoring experience: pipeable builder API, tiered-composition recipes, and a Phoenix example serving a canonical invoice via the new APIs.

## Success Criteria Verification
1. **Canonical invoice/report recipes use the new layout primitives rather than ad hoc block stacking.**
   - Verified by: `test/rendro/document_test.exs` covering the builder API; `test/rendro/recipes/invoice_test.exs` asserting tiered-composition output (page_template + sections, no `header:`/`footer:` kwargs); `test/rendro/adapters/accrue_test.exs` asserting Accrue adapter migrated to explicit sections.
2. **README and guides show how to compose serious business documents with the supported authoring surface.**
   - Verified by: `grep` checks on `README.md` for the builder API (`Rendro.Document.new`), the "Tiered Composition" concept, and absence of legacy `header:`/`footer:` kwargs in primary flow documentation. Phoenix example test (`examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs`) verifies the canonical recipe drives the rendered PDF.

## Requirement → Test Map

| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| LAY-12 | Pipeable builder API on `Rendro.Document` accumulates metadata, templates, sections, options deterministically | unit | `mix test test/rendro/document_test.exs` |
| LAY-12 | Canonical invoice recipe exposes tiered composition (`document/2`, `page_template/1`, `sections/2`) with named regions | unit | `mix test test/rendro/recipes/invoice_test.exs` |
| LAY-12 | Accrue adapter recipe replaces `header:`/`footer:` kwargs with explicit `page_template` regions and sections | unit | `mix test test/rendro/adapters/accrue_test.exs` |
| LAY-12 | Phoenix example controller serves a canonical invoice PDF via `Rendro.Recipes.Invoice` rather than a trivial single-block flow | integration | `cd examples/phoenix_example && mix test test/phoenix_example_web/controllers/pdf_controller_test.exs` |
| LAY-12 | README documents the builder API and tiered composition; legacy `header:`/`footer:` kwargs no longer presented as primary | docs | `grep -q "Rendro.Document.new" README.md && grep -q "Tiered Composition" README.md` |

## Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix ci`
- **Phase gate:** Full suite green plus `cd examples/phoenix_example && mix test` before `/gsd-verify-work`.

## Verification Command
`mix test test/rendro/document_test.exs test/rendro/recipes/invoice_test.exs test/rendro/adapters/accrue_test.exs && cd examples/phoenix_example && mix test test/phoenix_example_web/controllers/pdf_controller_test.exs`
