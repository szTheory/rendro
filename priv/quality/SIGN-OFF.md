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
| Invoice | **true** | 5 | "Total Due: $696.60" (display, 21pt) 25.9px vs. "INVOICE #INV-CMP-2026-001" (title, 16.5pt) 20.4px — 1.27 ratio | Total Due remains the single, accent-colored dominant element; issuer/customer/totals anatomy (Phase-115 DATA fix) survived theming. SHOW-01/DEFAULT-02 gap honestly closed. |
| Statement | **true** | 5 | "$6,647.56" closing balance (display, 21pt) 25.9px vs. account title (title, 16.5pt) 20.4px — 1.27 ratio | Closing balance remains unambiguously dominant on the themed raster. |
| Receipt/Report | **true** | 5 | "Total: $30.78" (display, 21pt) 25.9px vs. merchant block (title, 16.5pt) 20.4px — 1.27 ratio | Total remains the single largest, clear focal point. |
| Certificate | **true** | 5 | "Alex Rivera" (display, 21pt) 25.9px vs. "Certificate of Completion" (title, 16.5pt) 20.4px — **1.27 ratio, down from the native-scale 1.70 measured 2026-07-19** | The theme's uniform scale compresses the recipient/title ratio from 1.70 to 1.27. This compression is real — recorded here, not hidden. Human visual judgment: "Alex Rivera" is unambiguously the focal point on the actual re-blessed raster; the compressed ratio is noted-but-acceptable, not a defect that blocks the pass. |
| Payslip | **true** | 5 (typographic_craft: 4) | "NET PAY $3,292.50" (display, 21pt) 25.9px vs. header block (title, 16.5pt) 20.4px — 1.27 ratio | NET PAY is dominant and honest. **Open finding (not fixed here):** the earnings/deductions table's Current/YTD numeric cells wrap mid-number onto a second line (e.g. "$4,200.0" / "0") at the themed 10.5pt body scale + 1.35 leading — a real typographic_craft awkward-break regression. Recorded at 4, not silently raised to 5. Tracked as **`.planning/WINDOWS.md` id 3 — remains OPEN.** |
| Ticket | **false** | **3** (typographic_craft: 3) | Reference code "AUR-88213-GA" (display, 21pt) 25.9px vs. placement-grid "GA H 24 B" (title, 16.5pt) 20.4px — 1.27 ratio, **but INVERTED**: display is now larger than title, whereas natively title (26pt) was 3.25x larger than display (8pt) and was the element the 2026-07-19 rubric scored as dominant. | **HONEST FINDING, intentional `passed: false`.** The themed uniform type scale inverts Ticket's intended visual hierarchy: the reference-code display anchor now dominates over the placement-grid title the original rubric scored as the key fact, and the reference code wraps mid-token across 3 lines ("AUR-8" / "8213-" / "GA") in its narrow stub column. This is a genuine content_hierarchy and typographic_craft regression, not rubber-stamped to pass. Re-mapping Ticket's display/title role assignment is a locked Phase-122 (Q3) architectural decision, out of this plan's scope. Tracked as **`.planning/WINDOWS.md` id 2 — remains OPEN.** |

---

## Honesty notes

- **No score in this table was rubber-stamped.** Every dimension value above was judged against
  the actual themed raster (not the stale 2026-07-19 native-scale numbers), and `passed` in
  `rubric_scores.json` is recomputed by `passed?/2` from those dimension values — it is never an
  independently-asserted field.
- **Certificate's compression (1.70 → 1.27) is disclosed, not hidden.** The recipient name still
  reads as the single unambiguous focal point on the themed raster; the reduced margin is recorded
  above so a future regression (further compression) has a documented baseline to be judged against.
- **Payslip's numeric-cell wrap is a real, open defect** — `.planning/WINDOWS.md` id 3 — and is
  intentionally left open. It does not block Payslip's `passed: true` (NET PAY's dominance and the
  five other core dimensions all honestly clear their thresholds), but it is not silently fixed here
  either; a column-width retune is deferred to a follow-up plan.
- **Ticket's `passed: false` is the honest culmination of this phase's discipline.** The themed
  gallery regenerated in Commit 2 surfaced a genuine hierarchy inversion the 2026-07-19 rubric never
  saw (the native per-recipe scale hid it). Rather than flip Ticket to a passing score to make the
  gallery look uniformly green, this sign-off records the honest finding and leaves
  `.planning/WINDOWS.md` id 2 open for a future architectural fix (re-mapping Ticket's
  `scale.display`/`scale.title` role assignment).
- Invoice dark-mode table illegibility (`.planning/WINDOWS.md` id 1) affects the `invoice_dark`
  gallery row, not the `invoice` (light, default) row scored in this rubric, and remains open
  independently of this sign-off.
- **Zero color/rendering code was touched to produce this sign-off.** All 6 verdicts above are
  recorded against bytes already blessed in Commit 2 (Phase 123, Plan 03); this commit's diff is
  `priv/quality/`, `priv/schemas/`, and `test/docs_contract/` only.

---

## Composite

**5 of 6 demos honestly pass** (Invoice, Statement, Receipt/Report, Certificate, Payslip).
**1 of 6 honestly fails** (Ticket — content_hierarchy inversion + mid-token wrap, `.planning/WINDOWS.md`
id 2, open). Two additional out-of-band findings (Invoice dark-mode table illegibility id 1;
Payslip numeric wrap id 3, does not block Payslip's own pass) remain open in the same ledger. This
is the honest result of scoring the themed default/0 rasters against the unchanged Milestone-A
thresholds (`content_hierarchy == 5`, every other core `>= 4`, both gates `true`) — not a
uniformly-green rubber stamp.
