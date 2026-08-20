---
status: resolved
trigger: "Plan 130-05 precondition: renderer kind and local review-path identity mismatch"
created: 2026-08-20
updated: 2026-08-20
---

# Debug Session: Candidate Review Identity Binding

## Symptoms

### Expected behavior

Plan 130-05 can prove that each of the exact twelve locally inspectable full-size PNGs is the same candidate identity produced by the authorized source/ref/run and pinned PDFium executable before any human visual judgment begins.

### Actual behavior

All ordered IDs, PNG hashes, source-PDF hashes, source SHA, run, version, and executable pin match, but candidate metadata labels the renderer kind `pdfium-render` while route provenance labels it `pdfium-cli`. The immutable identity manifest also records logical candidate paths rather than the downloaded `final/pngs/` paths used for review.

### Error messages

Plan 130-05 stopped before visual review because renderer identity was not literal-string exact and manifest paths did not directly exist in the reconciled final artifact root.

### Timeline

Observed on 2026-08-20 after Plan 130-04 completed and the independently verified candidate/final/multipage artifacts were reconciled from successful run `32417257428`.

### Reproduction

Compare `tmp/phase130-candidate/candidate-manifest.json`, `tmp/phase130-review/final/identity-manifest.json`, route provenance/inventory, and the actual files under `tmp/phase130-review/final/pngs/` for the exact twelve `review_required` IDs.

## Scope Constraints

- Determine the semantic owner of renderer kind versus executable/package name; do not declare aliases equivalent solely because version/pin match.
- Preserve immutable candidate/final artifact bytes and provenance. Prefer an explicit canonical identity schema or a local hash-bound reconciliation record over editing downloaded evidence.
- Bind every logical candidate record one-to-one to an actual local full-size path using ID, PNG SHA, source-PDF SHA, order, dimensions, and complete provenance.
- Add regression coverage so future route/candidate/review producers use one unambiguous renderer identity vocabulary and review artifacts remain locally resolvable.
- Keep the visual-review gate closed until all twelve bindings pass exactly.
- Do not fabricate scores, regenerate, redownload, push, launch CI, rewrite baselines, or mutate rubric/SIGN-OFF/launch staging.

## Current Focus

hypothesis: confirmed — Plan 130-04 emitted source-logical identity records (`pdfium-render`, candidate `png_path`) but the downloaded review artifact's route provenance and inventory expose executable/package identity (`pdfium-cli`) and locally materialized `pngs/` paths. The two schemas never define a bridge, so Plan 130-05 cannot establish literal identity from the immutable files alone.
test: completed independent ordered identity, source/run/pin, local SHA, cardinality, and dimension reconciliation for all twelve review-required rows.
expecting: no candidate/render divergence; only an unexpressed semantic/local-path bridge.
next_action: complete — the mechanical identity-binding repair is verified; visual review remains intentionally unopened and out of scope for this session.
bug_class: bohrbug
reasoning_checkpoint:
  hypothesis: "The precondition fails because the candidate and final identity schemas identify distinct renderer concepts and the downloaded artifact introduces `pngs/` materialization without recording the mapping; neither string nor source-logical path is sufficient to locate the reviewed file."
  confirming_evidence:
    - "The candidate literal is `renderer.kind: pdfium-render`, while final route provenance records `renderer.name: pdfium-cli`; `Rendro.Catalog` and `Rendro.Adapters.Pdfium` independently own those terms."
    - "All twelve final identity rows equal the twelve ordered review-required candidate identities on ID, mode, logical path, PNG/PDF SHA, renderer version/SHA, commit, and run; route source SHA/run/pin also match."
    - "All twelve real local files live only at `final/pngs/<catalog_id>_page_1.png`, hash and dimensions match their candidate row, and both immutable inventories use `pngs/` paths."
  falsification_test: "A differing row hash, geometry, ID/order, source/run/pin value, a local path outside the inventory convention, or source code defining the two renderer strings as the same field would disprove this root cause."
  fix_rationale: "No source change can rewrite already-downloaded immutable evidence. A separate reconciliation record must preserve the two renderer fields distinctly and bind each logical row to the concrete local pathname by ordered ID, SHA, source-PDF SHA, dimensions, commit, run, and route provenance."
  blind_spots: "The external artifact downloader/materializer is not represented in this repository, so its decision to use `pngs/` cannot be regression-tested here; no fresh CI run is authorized."
  candidate_causes:
    - "code: `CatalogReviewPayload.identity/2` retains logical candidate paths and omits renderer kind/local materialization information."
    - "data: the downloaded immutable inventories place all source artifacts under `pngs/`, a layout not represented by the identity manifest."
    - "environment: a distinct pinned executable could have produced the rasters; refuted by equal version and SHA plus route provenance."
  and_gate: "yes — the review stop requires both the schema ambiguity (distinct renderer concepts with no explicit bridge) and the downloader's unrecorded `pngs/` path materialization."
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-20
  checked: candidate/final manifests, route provenance, immutable inventories, `Rendro.Catalog`, `Rendro.CatalogReviewPayload`, raster-review test, and PDFium adapter
  found: `Rendro.Catalog` owns renderer-kind as the literal `pdfium-render`; `Rendro.Adapters.Pdfium` owns the executable/package identity `pdfium-cli`. The candidate carries only the former while route provenance carries only the latter. `CatalogReviewPayload.identity/2` propagates logical candidate `png_path` values into the final identity manifest and does not carry renderer kind or local-materialization paths.
  implication: the strings name different schema concepts; pin/version equality is evidence of the same executable bytes, not string equivalence. The final manifest cannot by itself identify the locally downloaded review file.

- timestamp: 2026-08-20
  checked: current final identity-manifest rows against `tmp/phase130-review/final/pngs/<catalog_id>_page_1.png`
  found: all 12 ordered identity rows have exactly one local full-size PNG whose SHA-256 equals the row PNG SHA; there are exactly 12 local PNGs. Local dimensions are 794x1123 for Invoice/Statement/Receipt/Payslip, 1123x794 for Certificate, and 397x560 for Ticket.
  implication: no PNG byte, cardinality, ordering, or geometry divergence was observed; the blocker is the missing explicit local projection, not a faulty render.

- timestamp: 2026-08-20
  checked: shell reconciliation of local final paths, hashes, and dimensions
  found: the independent path/hash/dimension loop passed all twelve bindings. Both immutable inventories deliberately use `./pngs/…` paths (32 candidate rows and 12 final rows), whereas every final identity-manifest `png_path` is a non-existent logical candidate path. A first JSON summary expression had a jq syntax error and produced no identity-comparison result; it did not alter evidence or affect the successful independent loop.
  implication: downloaded artifact materialization is systematically `pngs/`-prefixed, so path absence is deterministic metadata projection drift rather than a per-file corruption; the logical-row equality still needs a corrected standalone check. A second jq-only summary attempt used an unsupported aggregation expression and likewise produced no comparison result.

- timestamp: 2026-08-20
  checked: corrected standalone ordered identity and provenance comparison
  found: 12 candidate review-required rows and 12 final rows have exact order with no row mismatches on ID, mode, logical path, PNG SHA, source-PDF SHA, renderer version/SHA, commit SHA, or run ID. Candidate version/pin equal route provenance version/pin; candidate source SHA and run ID equal route provenance source/run. The remaining literal values are `pdfium-render` (renderer kind) and `pdfium-cli` (executable name).
  implication: the root cause is confirmed as a two-condition schema/materialization binding omission, not a renderer, artifact-byte, or provenance mismatch.

- timestamp: 2026-08-20
  checked: persisted `tmp/phase130-review/final/local-identity-reconciliation.json` and focused contract suite
  found: the reconciliation record has schema version 1, distinct `renderer.adapter_kind: pdfium-render` and `renderer.executable_name: pdfium-cli`, and 12 ordered, unique bindings. Every binding's local `final/pngs/` path exists and its SHA-256 matches the recorded PNG hash. `mix test test/rendro/catalog_review_payload_contract_test.exs` passed with 3 tests and 0 failures.
  implication: the authorized mechanical repair persists a complete, locally resolvable identity bridge and its focused contract checks pass. No review evidence was changed and no visual judgment was performed.

## Eliminated

## Resolution

root_cause: "Two unbridged identity schemas: candidate metadata records the renderer kind `pdfium-render`, whereas route provenance records executable/package name `pdfium-cli`; additionally, the artifact materializer stores all downloaded PNGs under `pngs/` while final identity records retain non-existent source-logical candidate paths. Both conditions prevent Plan 130-05 from literal local binding despite identical hashes, order, source SHA, run, version, pin, and dimensions."
fix: "Added `Rendro.CatalogReviewReconciliation`, a fail-closed producer/validator. The raster-review route now emits `tmp/phase130-review/final/local-identity-reconciliation.json` alongside, not in place of, immutable artifacts. It records `adapter_kind: pdfium-render` and `executable_name: pdfium-cli` separately and binds all 12 logical rows to their local `final/pngs/` files with hashes, PDF hashes, dimensions, and route/run/pin provenance."
verification: "Verified the persisted local reconciliation record: schema version 1, separate adapter/executable identities, and 12 ordered unique bindings; all 12 local `final/pngs/` paths exist and their SHA-256 values match the record. `mix test test/rendro/catalog_review_payload_contract_test.exs` passed (3 tests, 0 failures). The producer also validates candidate classification, ordered final identity fields, renderer/source/run/pin provenance, PNG hashes, and dimensions before writing. No downloaded PNG, inventory, identity manifest, rubric, SIGN-OFF, launch evidence, CI route, or review score was modified; no visual judgment was performed."
files_changed:
  - .planning/debug/candidate-review-identity.md
  - dev/rendro/catalog_review_reconciliation.ex
  - test/rendro/catalog_raster_review_test.exs
  - tmp/phase130-review/final/local-identity-reconciliation.json
