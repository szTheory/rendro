# Rendro Reader-Quality Rubric — Sign-Off

**Phase 123 · D-05 Commit 3 · 2026-07-28**
Companion to `rubric_scores.json` (the machine-enforced manifest) and `brand/audit/SCORECARD.md`
(house style: honest, not flattering). This is the human sign-off record for the honest
re-score of all 6 curated rubric demos against the **themed** `default/0` gallery bytes
blessed in Commit 2 (Phase 123, Plan 03) — replacing the 2026-07-19 native-scale justifications,
which no longer describe the themed rasters (theming swaps every recipe's type scale onto one
uniform scale; see Phase 123 RESEARCH §Big Finding).

**Verdict provenance:** human visual judgment over pre-computed glyph-height deltas
(`Rendro.PDF.Font.helvetica/0` metrics, engine units, 96dpi), signed off by `qiksnare13` on
2026-07-28. Every score below is recomputed by `passed?/2`
(`test/docs_contract/rubric_manifest_contract_test.exs`) from its own `dimension_scores` +
`gate_results` — no `passed` value in `rubric_scores.json` is asserted independently of its
dimensions (SHOW-01 honesty gate).

---

## Per-demo sign-off

| Demo | Passed | Content hierarchy | Themed key-fact glyph delta | Notes |
|---|:--:|:--:|---|---|
| Invoice | **true** | 5 | Phase 126 reviewed `swiss_invoice_light` and `corporate_classic_invoice_dark` as pinned-PDFium page-one rows | The legacy light-gallery score remains 5. The Phase 126 bounded review additionally found the affected dark table header and body values readable; it does not recertify the whole invoice gallery or any compliance property. |
| Statement | **true** | 5 | "$6,647.56" closing balance (display, 21pt) 25.9px vs. account title (title, 16.5pt) 20.4px — 1.27 ratio | Closing balance remains unambiguously dominant on the themed raster. |
| Receipt/Report | **true** | 5 | "Total: $30.78" (display, 21pt) 25.9px vs. merchant block (title, 16.5pt) 20.4px — 1.27 ratio | Total remains the single largest, clear focal point. |
| Certificate | **true** | 5 | "Alex Rivera" (display, 21pt) 25.9px vs. "Certificate of Completion" (title, 16.5pt) 20.4px — **1.27 ratio, down from the native-scale 1.70 measured 2026-07-19** | The theme's uniform scale compresses the recipient/title ratio from 1.70 to 1.27. This compression is real — recorded here, not hidden. Human visual judgment: "Alex Rivera" is unambiguously the focal point on the actual re-blessed raster; the compressed ratio is noted-but-acceptable, not a defect that blocks the pass. |
| Payslip | **true** | 5 (typographic_craft: 4) | Phase 126 reviewed `humanist_payslip_dark` and `brutalist_payslip_dark` as pinned-PDFium page-one rows | The bounded review found `$4,200.00` and `$25,200.00` unbroken, right-aligned, and unclipped in both affected rows. The score remains 4: this fixture-level result does not support a universal typography upgrade or a print/compliance claim. WINDOWS id 3 is fixed by the cited repair, deterministic tests, pinned rows, and approval. |
| Ticket | **true** | **5** (typographic_craft: 4) | Phase 126 reviewed `editorial_ticket_dark` and `minimal_mono_ticket_dark` as pinned-PDFium page-one rows | The bounded review found placement dominant, with the complete one-line reference subordinate and unclipped in both affected rows. This supports hierarchy 5 and craft 4 for the repaired rows, not a universal Ticket-quality or compliance certification. WINDOWS id 2 is fixed by the cited repair, deterministic tests, pinned rows, and approval. |

---

## Honesty notes

- **No score in this table was rubber-stamped.** Every dimension value above was judged against
  the actual themed raster (not the stale 2026-07-19 native-scale numbers), and `passed` in
  `rubric_scores.json` is recomputed by `passed?/2` from those dimension values — it is never an
  independently-asserted field.
- **Certificate's compression (1.70 → 1.27) is disclosed, not hidden.** The recipient name still
  reads as the single unambiguous focal point on the themed raster; the reduced margin is recorded
  above so a future regression (further compression) has a documented baseline to be judged against.
- **Phase 126 is a bounded repair review, not a universal re-score.** Its six stable rows were
  rendered by the pinned-PDFium lane and reviewed full-size one at a time. The review fixed the
  recorded Invoice dark-cell, Ticket hierarchy/reference, and Payslip money-wrap defects only;
  it does not claim WCAG, PDF/UA, print safety, or universal preset quality.
- The affected records retain the historical gallery evidence reference required by the manifest
  contract while their justifications cite the Phase 126 exact-run provenance and limited approval.
- **Zero color/rendering code was touched to produce this sign-off.** All 6 verdicts above are
  recorded against bytes already blessed in Commit 2 (Phase 123, Plan 03); this commit's diff is
  `priv/quality/`, `priv/schemas/`, and `test/docs_contract/` only.

---

## Composite

**6 of 6 demos currently pass** the unchanged Milestone-A threshold arithmetic
(`content_hierarchy == 5`, every other core `>= 4`, both gates `true`). The Phase 126 change is
limited to six exact repaired rows and their evidence; it is not a uniformly-green claim about
all presets, future fixtures, accessibility, PDF/UA, or print safety.

---

## Phase 127 catalog flagship review · 2026-08-17

Jon reviewed the twelve full-size catalog inputs in canonical family order, with each light cell
immediately followed by its dark sibling. The catalog PNG and complete source-PDF hashes below
identify the evidence exactly. Scores are transcribed from the bounded human review record in
Phase 127 Plan 04; they are not generated by the catalog task. The computed verdict is false for
every record because `content_hierarchy` is 4, below the unchanged required 5. Dark cells also
retain `print_safety: false` as a screen-oriented boundary, not an accessibility, PDF/UA, WCAG,
arbitrary-print, all-page-viewer, or production-readiness conclusion.

| Catalog ID | PNG / PDF SHA-256 | Scores (IA/CH/DF/RA/TC/RC) | Gates | Computed verdict | Bounded finding |
|---|---|---|---|---|---|
| `invoice--cedar-mutual--corporate-classic--light` | `a7965f9a…ca98e97` / `d1e94191…7c370` | 4/4/4/4/4/4 | reading order true; print safety true | false | Credible invoice scan; total/due does not clear the strict focal-dominance bar. |
| `invoice--cedar-mutual--corporate-classic--dark` | `46d25706…90d20` / `28350fcc…8fd57` | 4/4/4/4/4/4 | true; false | false | Credible screen-oriented invoice; further color/type ratchet reserved. |
| `statement--signal-ledger--minimal-mono--light` | `93d064d7…7cea8` / `de2f5c6a…20ef8` | 4/4/4/4/4/4 | true; true | false | Account, balance, and ledger scan coheres; balance is below the strict focal bar. |
| `statement--signal-ledger--minimal-mono--dark` | `91882346…1d7ed` / `79a1b48d…9a968` | 4/4/4/4/4/4 | true; false | false | Named screen rendition is intelligible; no print claim. |
| `receipt--poppy-and-grain--humanist--light` | `ababe224…fae86` / `99e9394a…202c7` | 4/4/4/4/4/4 | true; true | false | Compact receipt scan is credible; total is not rated at the 5-level bar. |
| `receipt--poppy-and-grain--humanist--dark` | `fe1ca525…b0804` / `5743bb95…d0ae0` | 4/4/4/2/2/3 | true; false | false | Dark-on-brown/black-ish description areas impair the observed on-screen affordance. |
| `certificate--meridian-arts-fellowship--editorial--light` | `6080b2f2…27c5a` / `2ff095bd…271d9` | 4/4/4/4/4/4 | true; true | false | Ceremonial sequence is coherent; recipient/credential is not awarded strict 5-level dominance. |
| `certificate--meridian-arts-fellowship--editorial--dark` | `7ef31ce0…20f72` / `74419f42…afad1` | 4/4/4/4/4/4 | true; false | false | Named screen composition remains coherent without a print/compliance assertion. |
| `payslip--northline-logistics--swiss--light` | `bbc2c898…3cf56` / `4223e712…a0746` | 4/4/4/4/4/4 | true; true | false | Pay-stub anatomy and money columns are credible; net pay is below the exact hierarchy threshold. |
| `payslip--northline-logistics--swiss--dark` | `bd154733…02c5` / `c62440f6…c4d70` | 4/4/4/4/4/4 | true; false | false | Named screen cell is readable; no broader access or print conclusion. |
| `ticket--aurora-live--brutalist--light` | `183d2f48…064d3` / `477e5ed8…ec016` | 4/4/4/4/4/4 | true; true | false | Ticket scan and locator anatomy are credible; placement is below the strict focal bar. |
| `ticket--aurora-live--brutalist--dark` | `3f2421ca…d5a94` / `4ffcba4c…65b14` | 4/4/4/4/4/4 | true; false | false | Named screen cell is cohesive without a universal usability or print claim. |

The full, cell-specific dimension justifications live in `priv/quality/rubric_scores.json`; this
sign-off table deliberately remains a concise, hash-addressed index rather than a second source
of rubric data.

### Bounded multipage review

The supplied first/final proof images for representative Invoice and Statement `:line_items_60_plus`
fixtures were reviewed in first-then-final order. For both, no truncation, overflow, or broken
continuation was observed in those four images. This is bounded evidence for those supplied images,
not an all-page or universal pagination guarantee.
