---
phase: 130
slug: catalog-quality-evidence-ratchet
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-19
revised: 2026-08-20
---

# Phase 130 — Validation Strategy

> Deterministic checks are merge authority. Golden authorization, pinned launch generation, six-light launch review, catalog candidate generation, pinned catalog payload, and twelve-cell catalog review are distinct stages with distinct evidence authority.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit, Elixir 1.19.5 / OTP 28 |
| Quick recipe command | Modified family's structural, typography, and byte-identity suites |
| Golden command | Authorized staging bless: `MIX_GOLDEN_BLESS=true mix test test/rendro/recipes/theme_mode_background_golden_test.exs --max-failures 1`; then the same command without the environment variable |
| Launch command | In detached staging: `mix rendro.launch_artifacts.gen --pdfium "$RENDRO_PHASE130_PDFIUM"` then `mix rendro.launch_artifacts.check --pdfium "$RENDRO_PHASE130_PDFIUM"`; PDFium v0.11.0/SHA `b1e7f3...160a` |
| Launch contracts | `mix test test/rendro/launch_artifacts_test.exs test/docs_contract/launch_artifacts_claims_test.exs test/docs_contract/theming_claims_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1` |
| Catalog candidate | `mix rendro.catalog.candidate` under pinned PDFium; fixed output `tmp/phase130-candidate` |
| Pure catalog payload | `mix test test/rendro/catalog_review_payload_contract_test.exs --max-failures 1` — untagged, no PDFium |
| Catalog advisory payload | `RENDRO_CATALOG_REVIEW_DIR="$PWD/tmp/phase130-review" mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs --max-failures 1` |
| Full deterministic closure | Golden + launch/docs contracts + `mix rendro.catalog.check` + full `mix test --exclude quarantine --slowest 10` + `mix ci.fast` |

## Sampling and Ordering

1. Completed Plans 01/02 retain their focused green tests; Plan 03 establishes the pure catalog payload/CI contract.
2. Plan 07 stages exact HEAD, obtains exact two-golden authorization, blesses only in staging, and reruns assert-only.
3. Plan 08 uses one exact pinned PDFium binary for launch gen/check, gates the exact ten-change batch and byte-stable branded invoice, then obtains six separate full-size light-image decisions. Nothing canonical publishes yet.
4. Plans 04/05 create and review the separate exact twelve-image catalog payload. Launch images never enter it.
5. Plan 06 separately transcribes/publishes the legacy launch family, then transcribes twelve catalog records and runs exactly one canonical `mix rendro.catalog.gen`; final checks prove all golden/launch/catalog/docs boundaries green.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Evidence / secure behavior | Automated command or checkpoint evidence | Status |
|---|---:|---:|---|---|---|---|---|
| 130-01-01 | 01 | 1 | CATALOG-06,07 | T-130-01A/B/C | Receipt semantic cells share measure/render identity; nil-theme bytes frozen | Receipt structural/typography/byte command | ✅ complete |
| 130-01-02 | 01 | 1 | CATALOG-06 | T-130-01A/C | Invoice public-theme Total Due/due-date hierarchy | Invoice structural/typography/byte command | ✅ complete |
| 130-01-03 | 01 | 1 | CATALOG-06 | T-130-01A/C | Statement public-theme closing-balance hierarchy | Statement structural/typography/byte command | ✅ complete |
| 130-02-01 | 02 | 1 | CATALOG-06 | T-130-02A/B/C | Certificate rank and centering share exact resolved sizes | Certificate structural/typography/byte command | ✅ complete |
| 130-02-02 | 02 | 1 | CATALOG-06 | T-130-02A/B/C | Payslip Net Pay hierarchy and atomic money | Payslip structural/typography/byte command | ✅ complete |
| 130-02-03 | 02 | 1 | CATALOG-06 | T-130-02A/B/C | Ticket placement-first hierarchy and complete reference | Ticket structural/typography/byte command | ✅ complete |
| 130-03-01 | 03 | 2 | CATALOG-09 | T-130-03A/C | Exact 12-image catalog payload, separate four-image multipage proof, complete identities, no quality mutation | Pure payload contract + format check | ⬜ pending |
| 130-03-02 | 03 | 2 | CATALOG-09 | T-130-03B/C | Full-40-SHA catalog advisory route remains non-required | Required-checks contract | ⬜ pending |
| 130-07-01 | 07 | 3 | CATALOG-06,07,08 | T-130-07B/C | Exact-HEAD detached staging and canonical/evidence baseline fence | Worktree SHA equality + baseline JSON + main diff fence | ⬜ pending |
| 130-07-02 | 07 | 3 | CATALOG-06,07,08 | T-130-07A/C | Blocking exact old/new Statement and Certificate golden authorization | Human selects `authorize-exact-two` or rejects; main refs remain old before approval | ⬜ pending |
| 130-07-03 | 07 | 3 | CATALOG-06,07,08 | T-130-07A/B | Only authorized pair blessed in staging and assert-only green | Focused golden test + exact two-file staged diff | ⬜ pending |
| 130-08-01 | 08 | 4 | CATALOG-06,07,08 | T-130-08A/D | Blocking exact pinned PDFium path or exact-SHA CI action; launch gen/check in staging | v0.11.0/SHA verification + gen/check + launch/docs/theming tests | ⬜ pending |
| 130-08-02 | 08 | 4 | CATALOG-06,07,08 | T-130-08B/D | Exact ten changed PNGs, branded_invoice byte-stable, synchronized manifest/manual/docs/theming, no evidence/catalog writes | Launch check/contracts + exact diff fences | ⬜ pending |
| 130-08-03 | 08 | 4 | CATALOG-06,07 | T-130-08C/D | Blocking six-light full-size review; dark/brand deterministic-only | Six complete current hash/provenance decisions or `launch review blocked` | ⬜ pending |
| 130-04-01 | 04 | 5 | CATALOG-08,09 | T-130-04A/B/C/D | Fixed-target quality-free catalog candidate seam; atomic cleanup | Catalog and quality contracts | ⬜ pending |
| 130-04-02 | 04 | 5 | CATALOG-08,09 | T-130-04A/D | Blocking exact-SHA pinned 32-cell catalog candidate batch | Exact ref/run/pin + 32 candidate + 12 final + 4 multipage | ⬜ pending |
| 130-04-03 | 04 | 5 | CATALOG-08,09 | T-130-04A/B/C/D | Exact 32 order/hash/page/dimension and actual diff; canonical unchanged | Six-family + catalog contracts + jq partition | ⬜ pending |
| 130-05-01 | 05 | 6 | CATALOG-09 | T-130-05A/B/C | Blocking distinct twelve-cell full-size catalog review | Twelve complete integer/boolean/hash/provenance records or `review blocked` | ⬜ pending |
| 130-06-01 | 06 | 7 | CATALOG-06,07,08 | T-130-06A/B/C | Separate legacy launch transcription and atomic staged publication; authorized goldens | Golden + launch/docs/theming/rubric contracts; six legacy rows | ⬜ pending |
| 130-06-02 | 06 | 7 | CATALOG-08,09 | T-130-06A/B/C | Exact catalog transcription, one canonical catalog generation, candidate equality | 12 catalog scored + catalog check/contracts | ⬜ pending |
| 130-06-03 | 06 | 7 | CATALOG-06,07,08,09 | T-130-06A/B/C/D | Complete golden/launch/catalog/docs/source/security gate and exact cleanup | Pinned launch check + focused/full/ci.fast + cardinalities + validation flag | ⬜ pending |

## Wave 0 Ownership

Completed recipe assertions remain owned by 130-01-01 through 130-02-03. Remaining test-first gaps are owned as follows:

| Gap | Owning task | Proof created before behavior/publication |
|---|---|---|
| Candidate-driven twelve-image/multipage split | 130-03-01 | Untagged `Rendro.CatalogReviewPayloadContractTest` drives pure classification |
| Full-SHA catalog route and deterministic/advisory separation | 130-03-02 | Guardrail assertions precede workflow change |
| Golden authorization and exact staged diff | 130-07-01/02/03 | Existing Golden helper plus baseline/diff gate; no new production seam needed |
| Launch fail-closed staging | 130-07-01, 130-08-02 | Detached worktree baseline and exact generated-path fence; no broad target/force flag |
| Six legacy current-image evidence binding | 130-08-03, 130-06-01 | Human records precede rubric/SIGN-OFF publication; rubric contract closes current evidence refs |
| Candidate-only catalog generation and actual-diff partition | 130-04-01 | Catalog/quality contract assertions precede dev-only seam |

`wave_0_complete` becomes true only when 130-03-01/02, 130-07-01/03, 130-08-02, and 130-04-01 have committed their automated contracts and pass green. Human checkpoints remain evidence prerequisites, not Wave 0 substitutes.

## Manual / External Evidence

| Task | Why non-automated | Required evidence |
|---|---|---|
| 130-07-02 | Golden baseline movement requires explicit human authority | Exact two old/new SHA pairs and affirmative authorization |
| 130-08-01 | Pinned PDFium is unavailable locally | Exact absolute v0.11.0/SHA binary or exact-full-SHA CI ref/run/job/artifact provenance |
| 130-08-03 | Six legacy passed rows cite changed light images | Six separate full-size current-hash decisions; no dark/brand quality inference |
| 130-04-02 | Pinned catalog candidate run requires exact external identity | Full SHA/ref/run/pin plus complete candidate/final/multipage artifacts |
| 130-05-01 | Catalog aesthetic hierarchy/craft are human judgments | Twelve separate full-size catalog records; every miss/dark remains needs_work |

## Final Contract Checklist

- [ ] Two authorized golden hashes pass assert-only.
- [ ] Pinned launch gen/check is green; exactly ten PNGs changed and branded_invoice is byte-stable.
- [ ] Six legacy launch records are current and separately human-authorized; dark/brand rows are deterministic-only.
- [ ] Launch generation did not invoke or count as catalog generation.
- [ ] Exact twelve-image catalog review remains a separate payload and evidence set.
- [ ] Exactly one final canonical `mix rendro.catalog.gen` runs after catalog review transcription.
- [ ] Launch/golden/catalog/docs contracts, full suite, and `mix ci.fast` are green.
- [ ] No D-01..D-26, CATALOG-06..09, UI consideration, spec-less edge, prohibition, no-theme freeze, public/dependency/preset/catalog boundary, or deterministic/advisory separation is missing.
- [ ] `nyquist_compliant: true` is set only after 130-06-03 evidence exists.

**Approval:** pending execution evidence
