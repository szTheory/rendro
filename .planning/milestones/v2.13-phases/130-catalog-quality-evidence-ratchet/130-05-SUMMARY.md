---
phase: 130-catalog-quality-evidence-ratchet
plan: 05
subsystem: quality-evidence
tags: [catalog, human-review, pdfium, provenance, rubric]
requires:
  - phase: 130-04
    provides: Hash-bound candidate, final review, and multipage evidence payloads
provides:
  - Twelve complete, human-observed candidate verdict records bound to reconciled local PNG identities
  - Bounded multipage endpoint observation separated from the cell verdicts
affects: [130-06, catalog-quality, rubric-transcription]
tech-stack:
  added: []
  patterns:
    - Human review records bind to local reconciliation SHA rather than mutable or logical artifact paths
key-files:
  created:
    - .planning/phases/130-catalog-quality-evidence-ratchet/130-05-SUMMARY.md
  modified: []
key-decisions:
  - "Only the reconciliation record SHA 1646eeb8875cc67d7d452d3f28bc2b0d6503f943a2a6775f7e256a3e51bb3f22 binds the reviewed local files."
  - "Dark cells remain needs_work because print_safety is false, including otherwise threshold-satisfying Receipt and Certificate rows."
requirements-completed: [CATALOG-09]
coverage:
  - id: D1
    description: Twelve full-size, current-identity human review records
    requirement: CATALOG-09
    verification:
      - kind: manual_procedural
        ref: tmp/phase130-review/final/local-identity-reconciliation.json
        status: pass
    human_judgment: true
    rationale: Full-size visual hierarchy, legibility, and restrained composition require an accountable human observation.
duration: 32min
completed: 2026-08-20
status: complete
---

# Phase 130 Plan 05: Final Candidate Review Summary

**Jon's full-size review records twelve exact, pinned-PDFium candidate cells, promoting four light cells while preserving all threshold and dark-screen boundaries.**

## Performance

- **Duration:** 32 min
- **Completed:** 2026-08-20
- **Tasks:** 1/1
- **Files modified:** 1

## Identity Binding

- **Reconciliation authority:** `tmp/phase130-review/final/local-identity-reconciliation.json`
- **Reconciliation SHA-256:** `1646eeb8875cc67d7d452d3f28bc2b0d6503f943a2a6775f7e256a3e51bb3f22`
- **Candidate/source SHA:** `411cdcafa5d3090f3d0ec144c0cba59d991ba99f`
- **Route/ref:** `30657d92cf8be49f30094c57aaf163b76bd0ad9c` / `gsd/phase130-candidate-route-411cdcafa5d3090f3d0ec144c0cba59d991ba99f`
- **Run:** `32417257428`, attempt `1`, job `candidate-evidence`
- **Renderer adapter / executable:** `pdfium-render` / `pdfium-cli v0.11.0`
- **Pinned executable SHA-256:** `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`

Frozen arithmetic is exact: `passed = content_hierarchy == 5 AND every other dimension >= 4 AND reading_order == true AND print_safety == true`. Every dark row remains `needs_work` because `print_safety` is false.

## Reviewer Records

Reviewer and signed date for every record: **Jon, 2026-08-20**. Every record uses its listed prior canonical `evidence_ref` as `supersedes_evidence_ref`; scores are ordered `information_architecture/content_hierarchy/domain_fit/reader_affordances/typographic_craft/restraint_cohesion`.

### Invoice — Cedar Mutual Corporate-Classic

| Field | Light | Dark |
|---|---|---|
| Catalog ID | `invoice--cedar-mutual--corporate-classic--light` | `invoice--cedar-mutual--corporate-classic--dark` |
| Local full-size PNG | `tmp/phase130-review/final/pngs/invoice--cedar-mutual--corporate-classic--light_page_1.png` | `tmp/phase130-review/final/pngs/invoice--cedar-mutual--corporate-classic--dark_page_1.png` |
| PNG SHA-256 | `aa6245724dfb8c7a5ff63dcddf4033504f6484e893aa6908b2d199dc91b33f8d` | `7a8fd547fdab8314b3d5c092aa231b1c93432ddbb0371f7180c871866c81d3b2` |
| Source PDF SHA-256 | `09d1d39d49912fd2dcb33f0a55e55bc3903cf233dc6e8abe66e16cc0db1483a3` | `50a4515a7ba347900a3ec784d98db27a58880c01f13a23c35dd1de093664ceef` |
| Resolution ref | `8250056f0cfb2e69e11f68e5b45629fd82a7e2b1` | `8250056f0cfb2e69e11f68e5b45629fd82a7e2b1` |
| Supersedes evidence ref | `assets/rendro/catalog/invoice/cedar-mutual/corporate-classic-light.png` | `assets/rendro/catalog/invoice/cedar-mutual/corporate-classic-dark.png` |
| Scores | `4/5/4/4/4/4` | `4/5/4/3/3/3` |
| Gates | `reading_order: true`, `print_safety: true` | `reading_order: true`, `print_safety: false` |
| Computed disposition | `passed: true` | `passed: false; needs_work` |

- **Light justifications:** IA — issuer/invoice/bill-to, items, amount ladder, and due date form expected top-down groups. CH — blue Total Due is uniquely largest and due date recedes immediately below. DF — invoice number/date/bill-to/terms/qty/price/subtotal/tax/total/due are conventional. RA — labels and money columns align and description wraps stay contained. TC — type scale and numeric treatment are consistent with no clipping, intentionally plain. RC — one accent and sparse composition stay coherent and payment-focused.
- **Dark justifications:** IA — same groups remain understandable. CH — Total Due remains the unambiguous focal amount. DF — full invoice anatomy remains present. RA — Item/Qty/Price plus invoice/bill/date/subtotal labels are low-contrast against black and slow scanning. TC — multiple muted/label tones approach the background despite intact alignment. RC — layout/accent are consistent but uneven contrast weakens cohesion.

### Statement — Signal Ledger Minimal-Mono

| Field | Light | Dark |
|---|---|---|
| Catalog ID | `statement--signal-ledger--minimal-mono--light` | `statement--signal-ledger--minimal-mono--dark` |
| Local full-size PNG | `tmp/phase130-review/final/pngs/statement--signal-ledger--minimal-mono--light_page_1.png` | `tmp/phase130-review/final/pngs/statement--signal-ledger--minimal-mono--dark_page_1.png` |
| PNG SHA-256 | `526f0891bab69935419f7039d3dd4d5e20a21ad4b5e37efd70102ee3f0c38017` | `63d945425634be00fb4b655f408795fd8558f01f44b8d286760fb76777a73815` |
| Source PDF SHA-256 | `79f6fe32659321db254670bbbdcd9db392cdfe323125e98905d6df2e9bfa44b9` | `c0ee94af4cb7faa19e5a7b68152a65db20e4fd944a9101ec9ace64576b0c229d` |
| Resolution ref | `8fa8d0aca830e207c14d68cefcafa65e020644ca` | `8fa8d0aca830e207c14d68cefcafa65e020644ca` |
| Supersedes evidence ref | `assets/rendro/catalog/statement/signal-ledger/minimal-mono-light.png` | `assets/rendro/catalog/statement/signal-ledger/minimal-mono-dark.png` |
| Scores | `5/5/4/4/4/5` | `4/5/4/3/3/3` |
| Gates | `reading_order: true`, `print_safety: true` | `reading_order: true`, `print_safety: false` |
| Computed disposition | `passed: true` | `passed: false; needs_work` |

- **Light justifications:** IA — account/period/opening/closing/ledger follow the reconciliation path without backtracking. CH — closing balance is uniquely dominant in the full-width band. DF — masked account, period, balances, signed transactions, and running balance are conventional. RA — aligned headers/amounts and parenthesized withdrawals support tracing. TC — mono focal amount and body typography are clean; the compact context remains readable. RC — austere rules/band are cohesive and every element supports reconciliation.
- **Dark justifications:** IA — account-to-balance-to-ledger structure remains understandable. CH — closing balance remains uniquely dominant. DF — statement anatomy remains complete. RA — Date/Description/Amount/Balance headings and some context text are near-background, reducing scan support. TC — muted context and header contrast are visibly uneven. RC — minimal structure remains consistent but contrast inconsistency prevents full cohesion.

### Receipt — Poppy & Grain Humanist

| Field | Light | Dark |
|---|---|---|
| Catalog ID | `receipt--poppy-and-grain--humanist--light` | `receipt--poppy-and-grain--humanist--dark` |
| Local full-size PNG | `tmp/phase130-review/final/pngs/receipt--poppy-and-grain--humanist--light_page_1.png` | `tmp/phase130-review/final/pngs/receipt--poppy-and-grain--humanist--dark_page_1.png` |
| PNG SHA-256 | `8ee9808a5d2edd9e292941ef01b63c16cc3488a816f7a206815ecd5c7a0a719e` | `9431349b4908cbe3e38b5649ffc1a67c3bb9b2261ccb9f89b22e976f676b84ac` |
| Source PDF SHA-256 | `940a09cf42373afa043727508a6e1e0bd84f673d7ce92a69131cfac8ff791a4b` | `4612d45d09df7d1b8aa9f8dddf288cc8c8ca2058d8fddcf7f518cfdd0d6171ae` |
| Resolution ref | `d75e72bf521503183a7a5d4382b3dcd8cf2b0cf7` | `d75e72bf521503183a7a5d4382b3dcd8cf2b0cf7` |
| Supersedes evidence ref | `assets/rendro/catalog/receipt/poppy-and-grain/humanist-light.png` | `assets/rendro/catalog/receipt/poppy-and-grain/humanist-dark.png` |
| Scores | `5/5/4/5/4/5` | `5/5/4/5/4/5` |
| Gates | `reading_order: true`, `print_safety: true` | `reading_order: true`, `print_safety: false` |
| Computed disposition | `passed: true` | `passed: false; needs_work (print_safety boundary only)` |

- **Light justifications:** IA — merchant/date/items/arithmetic/total match the point-of-sale scan. CH — Total is the sole display-scale fact. DF — merchant/date/itemization/subtotal/tax/paid total are credible receipt anatomy. RA — compact labels and right-aligned amounts actively lead to the total. TC — sizing/weight/spacing are consistent with no awkward breaks. RC — the quiet warm band/rule earns its place and the slip remains restrained.
- **Dark justifications:** IA — same compact transaction sequence is immediate. CH — Total is the sole focal fact. DF — receipt anatomy is complete. RA — all descriptions/amounts/arithmetic are legible and aligned; the prior dark contrast deficit is visibly repaired. TC — type scale and contrast are consistent with no awkward breaks. RC — the restrained dark surface/rule is cohesive. `passed` remains false solely because the locked `print_safety: false` boundary applies.

### Certificate — Meridian Arts Fellowship Editorial

| Field | Light | Dark |
|---|---|---|
| Catalog ID | `certificate--meridian-arts-fellowship--editorial--light` | `certificate--meridian-arts-fellowship--editorial--dark` |
| Local full-size PNG | `tmp/phase130-review/final/pngs/certificate--meridian-arts-fellowship--editorial--light_page_1.png` | `tmp/phase130-review/final/pngs/certificate--meridian-arts-fellowship--editorial--dark_page_1.png` |
| PNG SHA-256 | `4db36148da0951f38062ceafbe506f7c0044dc69351a5e186b4fd9ca98e9d066` | `c8e33580ef93c5c27b128a490a9b5799ee0256f1e1500a48db692e825c437d52` |
| Source PDF SHA-256 | `3171693135a99bf63583f61fff72c8b67f2e98cdef164d5c5ad4d8c96fc17e7b` | `c0ac38e0024857c528bbeddc3733f5d7fdbb24daeeb795e8110b931ad21f8634` |
| Resolution ref | `704a58b1747e2dfeb506490c4ade9424737e924a` | `704a58b1747e2dfeb506490c4ade9424737e924a` |
| Supersedes evidence ref | `assets/rendro/catalog/certificate/meridian-arts-fellowship/editorial-light.png` | `assets/rendro/catalog/certificate/meridian-arts-fellowship/editorial-dark.png` |
| Scores | `5/5/4/4/4/5` | `5/5/4/4/4/5` |
| Gates | `reading_order: true`, `print_safety: true` | `reading_order: true`, `print_safety: false` |
| Computed disposition | `passed: true` | `passed: false; needs_work (print_safety boundary only)` |

- **Light justifications:** IA — recipient/credential/body/date/signatory form a centered ceremonial sequence. CH — Elena Morales is largest, credential clearly second, all else recedes. DF — landscape attestation and signatory read as a credible certificate, though deliberately minimal. RA — centered symmetry supports a deliberate ceremonial read. TC — serif hierarchy plus compact sans body/signatory are consistent and clean. RC — generous whitespace and symmetry are fully restrained.
- **Dark justifications:** The same IA/CH/DF/RA/TC/RC observations hold on screen with clear contrast. `passed` remains false solely because `print_safety: false`; this makes no print or accessibility claim.

### Payslip — Northline Logistics Swiss

| Field | Light | Dark |
|---|---|---|
| Catalog ID | `payslip--northline-logistics--swiss--light` | `payslip--northline-logistics--swiss--dark` |
| Local full-size PNG | `tmp/phase130-review/final/pngs/payslip--northline-logistics--swiss--light_page_1.png` | `tmp/phase130-review/final/pngs/payslip--northline-logistics--swiss--dark_page_1.png` |
| PNG SHA-256 | `ccaa718c49a3a9cddc3f9923b6310cb4c225481ba6d10353849f1e90d19f7be8` | `7e49c55c2f72b47c01dd0e98f6b9094ad3772a6c1cdb3118e303ede299783184` |
| Source PDF SHA-256 | `a88be1778ffec799223b147566151ab86d4b8b37871fbe8c739329b73519004e` | `f3bc9896b4491a2f9168aa62e7ea7fbbbf3eead99fbb154f16011cd5e73b2dd0` |
| Resolution ref | `3e50a86604cd87be0d963e53741c1c4babaeca1f` | `3e50a86604cd87be0d963e53741c1c4babaeca1f` |
| Supersedes evidence ref | `assets/rendro/catalog/payslip/northline-logistics/swiss-light.png` | `assets/rendro/catalog/payslip/northline-logistics/swiss-dark.png` |
| Scores | `4/5/4/3/3/4` | `4/5/4/2/3/3` |
| Gates | `reading_order: true`, `print_safety: true` | `reading_order: true`, `print_safety: false` |
| Computed disposition | `passed: false; needs_work` | `passed: false; needs_work` |

- **Light justifications:** IA — employer/employee/period/net-pay/tables/reconciliation are correctly grouped. CH — $3,253.50 in the Net Pay band is uniquely dominant. DF — employer/employee/pay dates/earnings/deductions/current/YTD/gross/net are conventional. RA — cramped Current/YTD values and multi-line labels slow reconciliation. TC — Operations salary, Route coverage premium, Social insurance, Retirement contribution, and Total Deductions wrap awkwardly; adjacent amounts are tight. RC — treatment is restrained, though table density prevents top cohesion.
- **Dark justifications:** IA and CH/DF remain as above. RA — column headings become near-background while the same cramped/wrapped table remains, materially impairing scanning. TC — label wraps and uneven contrast remain visible. RC — the palette is generally consistent but low-contrast table chrome weakens cohesion. `print_safety: false`.

### Ticket — Aurora Live Brutalist

| Field | Light | Dark |
|---|---|---|
| Catalog ID | `ticket--aurora-live--brutalist--light` | `ticket--aurora-live--brutalist--dark` |
| Local full-size PNG | `tmp/phase130-review/final/pngs/ticket--aurora-live--brutalist--light_page_1.png` | `tmp/phase130-review/final/pngs/ticket--aurora-live--brutalist--dark_page_1.png` |
| PNG SHA-256 | `d75ab8b5cfabc26cb93f724353dacb3710c7fc5d191efc1655a428b6a56d4170` | `69184d72986d30ce089484f83b0b92397c51716e10c6c6d52b8ea4fbfe1669e6` |
| Source PDF SHA-256 | `c3d1baf2d32881534aafdbb41ee931ef1d67dbe3647f084c4221c56bea7139f9` | `a6e49f1477d9394b16cab1045da47fc433e1459a1ac3c2e33cdc900785c4ee9a` |
| Resolution ref | `b972f194f2edd3925eda71c0cf5f363e8b3ee94b` | `b972f194f2edd3925eda71c0cf5f363e8b3ee94b` |
| Supersedes evidence ref | `assets/rendro/catalog/ticket/aurora-live/brutalist-light.png` | `assets/rendro/catalog/ticket/aurora-live/brutalist-dark.png` |
| Scores | `4/5/4/3/3/4` | `4/5/4/2/3/3` |
| Gates | `reading_order: true`, `print_safety: true` | `reading_order: true`, `print_safety: false` |
| Computed disposition | `passed: false; needs_work` | `passed: false; needs_work` |

- **Light justifications:** IA — event, placement, reference/stub, and terms are distinct expected groups. CH — oversized placement dominates title and reference. DF — event/time/placement/seam/reference/terms read as a real admission ticket. RA — the primary Section value `GA` wraps into separate `G`/`A` lines and the empty Gate column/subtitle wrap slow a gate scan. TC — the key placement token's awkward break prevents polished type craft. RC — the hard rule/stub/Brutalist geometry remain coherent.
- **Dark justifications:** IA/CH/DF remain as above. RA — the `GA` wrap combines with low-contrast labels/reference/terms to impair fast use. TC — primary-token wrapping and muted text remain visibly uneven. RC — geometry remains coherent but the contrast imbalance lowers cohesion. `print_safety: false`.

## Bounded Multipage Observation

Separate from the twelve cell verdicts, Jon observed all four supplied endpoints as unclipped with expected headers, columns, and footer space:

- `tmp/phase130-review/multipage/pngs/invoice-line-items-60-plus-page-first.png`
- `tmp/phase130-review/multipage/pngs/invoice-line-items-60-plus-page-final.png`
- `tmp/phase130-review/multipage/pngs/statement-line-items-60-plus-page-first.png`
- `tmp/phase130-review/multipage/pngs/statement-line-items-60-plus-page-final.png`

The Statement first/final endpoints show carried/brought-forward arithmetic and close at `$7,500`. The Invoice first endpoint shows lines 1–40 and its final endpoint shows lines 42–65. As only endpoints were supplied, this is bounded endpoint evidence: it neither asserts nor denies intermediate line-41 continuity, which remains covered by deterministic tests. Multipage evidence is not a substitute for any of the twelve visual records.

## Decisions Made

- Bound review records only through the immutable reconciliation SHA, which separates adapter and executable identities and maps every logical candidate record to its local full-size PNG.
- Promote only Invoice, Statement, Receipt, and Certificate light cells; preserve all other threshold misses as `needs_work`.
- Preserve the dark screen-oriented boundary even where every dimension and reading-order gate meets the numeric threshold.

## Deviations from Plan

None - Plan 05 transcribed the approved, complete records after the separately committed identity reconciliation repair.

## Known Stubs

None.

## Self-Check: PASSED

- Summary file exists and task commit `ec44cd7` exists in git history.
- All twelve reconciliation-bound local review PNGs exist and their SHA-256 values match the approved reconciliation record.

## Next Phase Readiness

Plan 06 may transcribe only these complete candidate-identity records into reviewer-owned evidence. It must retain the four light promotions, all other `needs_work` outcomes, and the explicit dark print-safety boundary.

---
*Phase: 130-catalog-quality-evidence-ratchet*
*Completed: 2026-08-20*
