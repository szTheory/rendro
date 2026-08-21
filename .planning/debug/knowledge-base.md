# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## launch-source-pdf-identity — publication plan checked an unpaired manifest
- **Date:** 2026-08-20
- **Error patterns:** source-PDF hash drift, static launch contract, canonical manifest, staged artifact
- **Root cause(s):** Plan 130-06 ran source-PDF validation against the canonical prior manifest before it overlaid the accepted staged launch family.
- **Fix:** Validate staging identity first; overlay only the explicit staged launch/golden family; then run existing launch/contracts checks on the paired uncommitted batch before its sole publication commit.
- **Files changed:** .planning/phases/130-catalog-quality-evidence-ratchet/130-06-PLAN.md
- **Why not caught:** no gate existed for publication-plan ordering against an intentionally unpaired canonical manifest.
- **Recurrence guard:** explicit Plan 130-06 sequencing clause plus its executor post-copy launch/contracts gate.
---

## catalog-canonical-pdfium-route — macOS canonical generation lacked the approved renderer route
- **Date:** 2026-08-21
- **Error patterns:** missing pdfium-cli, Linux-only renderer, macOS checkout, canonical catalog generation, exact-SHA CI route
- **Root cause(s):** The approved renderer is Linux-only on a macOS canonical checkout, and ci.yml lacked an exact-SHA post-review canonical-generation route even though its advisory Linux job already installed and hash-verified that renderer.
- **Fix:** Added an isolated full-SHA advisory CI route that verifies the pinned Linux PDFium executable, generates the catalog once, checks it, and uploads the bundle for checksum and 32-cell identity verification before local atomic materialization.
- **Files changed:** .github/workflows/ci.yml, test/guardrails/required_checks_contract_test.exs, assets/rendro/catalog.json, assets/rendro/catalog
- **Why not caught:** no gate existed for routing a post-review canonical writer to the approved renderer platform.
- **Recurrence guard:** `test/guardrails/required_checks_contract_test.exs` enforces the full-SHA advisory route, renderer digest verification, one writer invocation, catalog check, and bounded artifact handoff; this knowledge-base entry also surfaces the platform-route pattern.
---
