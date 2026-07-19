---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
plan: 05
subsystem: launch-artifacts
tags: [gallery, pdfium, rebless, artifacts, sha256, s6-seam, wasm, elixir]

# Dependency graph
requires:
  - phase: 118-04
    provides: "Rendro.LaunchArtifacts repointed to priv/examples with 7 tiles + S6 seams; provisional payslip/ticket @expected_gallery_dimensions"
provides:
  - "assets/rendro/artifacts.json re-blessed to 7 entries with realistic re-baselined source_pdf_sha256/png_sha256 + S6 theme/mode/preset tags (D-08)"
  - "New gallery rasters assets/rendro/gallery/payslip.png + ticket.png"
  - "Re-blessed assets/rendro/manual.pdf and regenerated README + guides/recipes.md generated blocks (7 tiles)"
  - "launch_artifacts_claims_test re-greened to the 7-tile gallery"
affects: [118-06, 118-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cross-platform pdfium re-bless: mac-arm64 wasm pdfium build produces byte-identical rasters to CI amd64 (proven via forms_support_fixture raster snapshot), enabling a local D-08 re-bless faithful to CI"
key-files:
  created:
    - assets/rendro/gallery/payslip.png
    - assets/rendro/gallery/ticket.png
  modified:
    - assets/rendro/artifacts.json
    - assets/rendro/manual.pdf
    - assets/rendro/gallery/{invoice,branded_invoice,statement,receipt_report,certificate}.png
    - README.md
    - guides/recipes.md
    - test/docs_contract/launch_artifacts_claims_test.exs

key-decisions:
  - "D-08 re-bless authorized: repointing the gallery to the realistic example library legitimately changes every source-PDF/PNG/manual hash. Not a determinism regression."
  - "@expected_gallery_dimensions required NO correction — payslip AND ticket both render at 794x1123 (the gallery previews tiles on an A4 canvas), so the provisional values were already correct. The 118-04 handoff's expectation that ticket (A6) dims would differ did not materialize at the gallery-preview layer."
  - "Ran the re-bless locally (not in CI) after empirically proving cross-platform raster determinism — the forms_support_fixture raster snapshot (the only committed CI-blessed amd64 reference) matched byte-for-byte under the native mac-arm64 pdfium wasm build."

patterns-established:
  - "Determinism gate before any local re-bless: run the committed raster snapshot ref; only re-bless if the local raster hash matches the CI-blessed reference."

requirements-completed: [SHOW-03]
---

## Accomplishments

- **D-08 gallery re-bless (SHOW-03).** Ran `mix rendro.launch_artifacts.gen` with the pinned pdfium (klippa-app pdfium-cli wasm v0.11.0). `assets/rendro/artifacts.json` now holds exactly 7 entries (adds `payslip`, `ticket`) with re-baselined `source_pdf_sha256` + `png_sha256` and the S6 `theme`/`mode`/`preset` seam keys. `manual.pdf` re-blessed; README `@readme_start` and `guides/recipes.md` `@recipes_start` generated blocks regenerated via `replace_block!` (never hand-edited).
- **`mix rendro.launch_artifacts.check` → "Launch artifacts VERIFIED"** — zero drift (required source-PDF + manual SHA-256 lane green; PNG lane green).
- **Two new rasters visually confirmed.** `payslip.png` shows Employer Aurora Live, masked employee, boxed **Net Pay $3,292.50**, earnings/deductions with YTD, and a gross→net reconciliation line. `ticket.png` shows Aurora Live – The Foundry Hall, "Indie Night: The Lumen Set", SECTION GA / ROW H / SEAT 24 / GATE B, and a perforated reference stub (AUR-88213-GA) — no barcode (reference-number by design).
- **Claims test re-greened** (Rule 3 blocking fix, required by this plan's own "docs_contract green" verification): updated the exact-id assertion 5→7 and added payslip/ticket to the hex-package asset list. The two cases that 118-04 left expected-red are now green.

## Verification

- `mix rendro.launch_artifacts.check` — VERIFIED (zero drift).
- `mix test test/docs_contract/` — 271 tests + 1 doctest, 0 failures.
- `mix test test/docs_contract/launch_artifacts_claims_test.exs` — 9 tests, 0 failures.
- `mix test test/rendro/launch_artifacts_test.exs` — 12 tests, 0 failures.
- **Determinism proof:** `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs:31` (forms_support_fixture) — 1 test, 0 failures; the native mac-arm64 pdfium raster SHA-256 matched the committed CI-blessed (amd64) reference `73e33ed6…`.

## Environment note (how the container gate was satisfied locally)

`pdfium-cli` is pinned to `pdfium-webassembly-linux-amd64` and absent on this macOS host. Rather than emulate: OTP 28's `prim_tty` NIF crashes under Docker amd64 (Rosetta) with `nouser`, and `harfbuzz_ex` ships no precompiled NIF for `aarch64-linux`. Both blockers were sidestepped by running **natively** — this Mac's `aarch64-apple-darwin` is a first-class harfbuzz precompiled target, and klippa ships an equivalent `pdfium-webassembly-mac-arm64` build that executes the identical pdfium **wasm module**. Because wasm rasterization is host-independent and harfbuzz shaping is deterministic at a pinned version, the render pipeline is byte-identical to CI — proven, not assumed, by the raster-snapshot gate above.

## Human re-bless checkpoint (D-08)

This plan carries a blocking `checkpoint:human-verify` for the D-08 re-bless. It was executed under explicit user delegation to "do the wave 4 commit / follow ur recs." Evidence for review is committed in `5696030`: `git diff` shows all 24 hash lines re-baselined, 7 entries each carrying S6 tags, `check` VERIFIED, and both new PNGs render as a recognizable payslip and ticket. The user will review the committed diff after context-clear.

## Notes for downstream (118-06 / 118-07)

- Rubric-relevant composition observations for 118-06: the payslip earnings/deductions header crowds ("YTDDeductions" run together) and the base-salary YTD "$25,200.00" wraps a digit; the ticket content sits in the top ~third of an A4 canvas (large lower whitespace). Score honestly against these actual renders.
- Gallery ids/order are locked: invoice, branded_invoice, statement, receipt_report, certificate, payslip, ticket.
