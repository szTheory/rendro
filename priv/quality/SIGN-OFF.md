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

## Phase 130 launch reauthorization · 2026-08-20

Jon reviewed the six changed **light** launch images at full size after the accepted exact-SHA
PDFium v0.11.0 CI artifact was reconciled in the detached staging worktree. The legacy
`scores[]` values are retained without re-scoring; each record is now bound to its current PNG
and source-PDF SHA-256 identities, reviewer, and date in `rubric_scores.json`.

| Launch image | PNG SHA-256 | Source-PDF SHA-256 | Decision |
|---|---|---|---|
| Invoice | `6a7dfd0c963c2bfaddf2bf3e8dedc7f7deef3848a5d91478dae40cc310f49a47` | `8808fcf899c5ac5897e5fa1bf7316924edca275ce85f8ec3410f5576f3d5fc22` | Approved — Total Due, table, and pagination remain clear. |
| Statement | `b0475e73540b93bcae88f925228a0c7fe31b17d25e1ccd154b62e699308cb31b` | `d3380c80468ce7a384ac2a54c2b2500a6b8f14b65c3751c12d6b7bf406e445d5` | Approved — closing balance and ledger remain readable. |
| Receipt / Report | `38225439998b6944e309238894df7cf10bc4eef771164fd3018ee7837b89b122` | `67902b82dcf1bbd597490ce0d701a040a82604bd19dd1ce3ff53352b0a0b15ad` | Approved — total and line items remain clear. |
| Certificate | `d6ad49a6829936a81d271df029dad36bf5d2ab62d7af6558e408eded2fad643e` | `9f004ab50efe37c45308ee51ff4dc90ffe252dba765e6c92c4604a0b9a2c0231` | Approved — recipient hierarchy and signatures remain coherent. |
| Payslip | `bf764cd92cc9775fdd9f03901dba47de0c2108769dbaf4e02dcbc699586f4274` | `fe6943472202526c46647eb65275a3385e570b6d0fd8aee05d3ade4b5620425a` | Approved — net pay and deductions remain aligned. |
| Ticket | `b67e1668a9c1cc659a5232220fbf07236f1c516d9dd9ef16662957f07346e990` | `d6dc6fa81d1a4884d4a47b7966d261e4da2adb9152c0085fd9c69ebd75324e91` | Approved — placement and reference remain clear. |

This is a bounded launch reauthorization, not catalog evidence. `invoice_dark`,
`certificate_dark`, `ticket_dark`, and `invoice_brand` remain deterministic-only; no
`catalog_dispositions` entry changes and no print, accessibility, PDF/UA, WCAG, or GUI-viewer
claim is added. Renderer provenance remains the accepted exact-SHA CI PDFium v0.11.0 artifact
(`b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`), because its Linux
binary is not executable on this macOS host.

---

## Phase 130 catalog review · 2026-08-20 (current)

This is the current catalog-review authority, reconciled to SHA-256 `1646eeb8875cc67d7d452d3f28bc2b0d6503f943a2a6775f7e256a3e51bb3f22`. Candidate/source SHA is `411cdcafa5d3090f3d0ec144c0cba59d991ba99f`; route/ref is `30657d92cf8be49f30094c57aaf163b76bd0ad9c` / `gsd/phase130-candidate-route-411cdcafa5d3090f3d0ec144c0cba59d991ba99f`; candidate run `32417257428`, attempt `1`, job `candidate-evidence`; advisory job `96581121473`. The review used adapter `pdfium-render`, executable `pdfium-cli v0.11.0`, executable SHA-256 `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`.

`passed = content_hierarchy == 5 AND every other dimension >= 4 AND reading_order == true AND print_safety == true`. Four light rows pass; eight rows remain `needs_work`. Every dark row is screen-oriented and non-print-safe because `print_safety: false`; this makes no print, accessibility, PDF/UA, or WCAG claim.

| Catalog ID | PNG SHA-256 | Source-PDF SHA-256 | Scores | Gates / verdict |
|---|---|---|---|---|
| `invoice--cedar-mutual--corporate-classic--light` | `aa6245724dfb8c7a5ff63dcddf4033504f6484e893aa6908b2d199dc91b33f8d` | `09d1d39d49912fd2dcb33f0a55e55bc3903cf233dc6e8abe66e16cc0db1483a3` | 4/5/4/4/4/4 | true/true; pass |
| `invoice--cedar-mutual--corporate-classic--dark` | `7a8fd547fdab8314b3d5c092aa231b1c93432ddbb0371f7180c871866c81d3b2` | `50a4515a7ba347900a3ec784d98db27a58880c01f13a23c35dd1de093664ceef` | 4/5/4/3/3/3 | true/false; needs_work |
| `statement--signal-ledger--minimal-mono--light` | `526f0891bab69935419f7039d3dd4d5e20a21ad4b5e37efd70102ee3f0c38017` | `79f6fe32659321db254670bbbdcd9db392cdfe323125e98905d6df2e9bfa44b9` | 5/5/4/4/4/5 | true/true; pass |
| `statement--signal-ledger--minimal-mono--dark` | `63d945425634be00fb4b655f408795fd8558f01f44b8d286760fb76777a73815` | `c0ee94af4cb7faa19e5a7b68152a65db20e4fd944a9101ec9ace64576b0c229d` | 4/5/4/3/3/3 | true/false; needs_work |
| `receipt--poppy-and-grain--humanist--light` | `8ee9808a5d2edd9e292941ef01b63c16cc3488a816f7a206815ecd5c7a0a719e` | `940a09cf42373afa043727508a6e1e0bd84f673d7ce92a69131cfac8ff791a4b` | 5/5/4/5/4/5 | true/true; pass |
| `receipt--poppy-and-grain--humanist--dark` | `9431349b4908cbe3e38b5649ffc1a67c3bb9b2261ccb9f89b22e976f676b84ac` | `4612d45d09df7d1b8aa9f8dddf288cc8c8ca2058d8fddcf7f518cfdd0d6171ae` | 5/5/4/5/4/5 | true/false; needs_work |
| `certificate--meridian-arts-fellowship--editorial--light` | `4db36148da0951f38062ceafbe506f7c0044dc69351a5e186b4fd9ca98e9d066` | `3171693135a99bf63583f61fff72c8b67f2e98cdef164d5c5ad4d8c96fc17e7b` | 5/5/4/4/4/5 | true/true; pass |
| `certificate--meridian-arts-fellowship--editorial--dark` | `c8e33580ef93c5c27b128a490a9b5799ee0256f1e1500a48db692e825c437d52` | `c0ac38e0024857c528bbeddc3733f5d7fdbb24daeeb795e8110b931ad21f8634` | 5/5/4/4/4/5 | true/false; needs_work |
| `payslip--northline-logistics--swiss--light` | `ccaa718c49a3a9cddc3f9923b6310cb4c225481ba6d10353849f1e90d19f7be8` | `a88be1778ffec799223b147566151ab86d4b8b37871fbe8c739329b73519004e` | 4/5/4/3/3/4 | true/true; needs_work |
| `payslip--northline-logistics--swiss--dark` | `7e49c55c2f72b47c01dd0e98f6b9094ad3772a6c1cdb3118e303ede299783184` | `f3bc9896b4491a2f9168aa62e7ea7fbbbf3eead99fbb154f16011cd5e73b2dd0` | 4/5/4/2/3/3 | true/false; needs_work |
| `ticket--aurora-live--brutalist--light` | `d75ab8b5cfabc26cb93f724353dacb3710c7fc5d191efc1655a428b6a56d4170` | `c3d1baf2d32881534aafdbb41ee931ef1d67dbe3647f084c4221c56bea7139f9` | 4/5/4/3/3/4 | true/true; needs_work |
| `ticket--aurora-live--brutalist--dark` | `69184d72986d30ce089484f83b0b92397c51716e10c6c6d52b8ea4fbfe1669e6` | `a6e49f1477d9394b16cab1045da47fc433e1459a1ac3c2e33cdc900785c4ee9a` | 4/5/4/2/3/3 | true/false; needs_work |

Bounded multipage review: Statement endpoints close at `$7,500`. Supplied Invoice endpoints show lines 1–40 and 42–65; line 41 is neither asserted nor denied and remains deterministic-test evidence only.

## Phase 127 catalog flagship review · 2026-08-17 (historical; superseded by Phase 130 above)

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
