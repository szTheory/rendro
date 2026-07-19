---
status: paused-finding
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
plan: 06
reason: "Rendered demos do not honestly clear the rubric gate (content_hierarchy==5 + all cores>=4 + both gates). Per D-11 scores were NOT inflated and NOT committed. Awaiting user decision on remediation vs. accepting gaps."
recorded: 2026-07-19
scored_against: assets/rendro/gallery/*.png (the 96-dpi rasterized demo renders produced by 118-05)
---

# 118-06 Findings — rubric self-scoring paused (D-11 honesty)

## Summary

I rasterized and genuinely assessed all six demos against the six rubric dimensions and two
gates. **None of the six honestly reaches the passing bar** (`content_hierarchy == 5` AND every
other core dimension `>= 4` AND both gates true). Per D-11 ("passing is EARNED, not assigned; a
demo that cannot honestly reach the thresholds is a finding to surface, never scored up") I did
**not** inflate any score and did **not** commit any score entries. 118-05 (the gallery re-bless)
is committed and complete; 118-06 is paused here for your decision.

The single largest issue is the **invoice demo**, which is under-built relative to both its own
fixture and the recipe's capability (details below). The other demos are realistic and clean but
do not make their one key fact *visually dominant*, which the rubric requires for a passing
`content_hierarchy` of 5.

## Proposed honest scores (NOT committed)

Bar: `passed = (content_hierarchy == 5) AND (other 5 dims >= 4) AND reading_order AND print_safety`.
Dimensions: information_architecture (IA), content_hierarchy (CH), domain_fit (DF),
reader_affordances (RA), typographic_craft (TC), restraint_cohesion (RC).

| demo_id | IA | CH | DF | RA | TC | RC | reading_order | print_safety | passed |
|---------|----|----|----|----|----|----|---------------|--------------|--------|
| invoice-acme-phoenix-saas | 2 | 2 | 2 | 3 | 3 | 3 | true | true | **false** |
| statement-northwind-ledger-co | 4 | 3 | 4 | 4 | 4 | 4 | true | true | **false** |
| receipt-harbor-and-oak-cafe | 3 | 3 | 3 | 4 | 4 | 4 | true | true | **false** |
| certificate-summit-training-institute | 3 | 3 | 3 | 3 | 3 | 2 | true | true | **false** |
| payslip-aurora-live | 3 | **5** | 4 | 3 | 3 | 4 | true | true | **false** |
| ticket-aurora-live | 4 | 4 | 4 | 4 | 4 | 3 | true | true | **false** |

Closest to passing: **payslip** (its Net Pay box genuinely earns CH=5) — blocked only by the
crowded earnings/deductions table dragging three cores to 3. **ticket** is uniformly ~4 but no
field is singularly dominant, so CH is 4 not 5.

## Per-demo evidence & what it would take to pass

### invoice-acme-phoenix-saas — under-built (biggest gap)
Render shows only: title `INVOICE #INV-CMP-2026-001`, date, a 36-row table of identical
"Invoice line NNN — Monthly platform service | 1 | $79.0", and "Thank you for your business!".
Missing: **no total / amount due anywhere**, no issuer block (Rendro Systems), no customer block
(Acme Phoenix SaaS), no due-date/terms display. Money renders as `$79.0` (one decimal).
- The fixture DOES contain `issuer`, `customer`, `invoice` (due_date, terms), and `totals`.
- `Rendro.Recipes.Invoice` DOES render `issuer_block`, `customer_block`, and `build_totals_blocks`.
- So the gap is in the **`transform_invoice` / LaunchArtifacts source-document path** (118-03/118-04):
  it feeds the recipe only items + header, dropping parties and totals. This is a lib/transform
  fix, outside 118-06's declared files_modified.
- Fixture realism: 36 identical "$79.00 Monthly platform service" lines is not a realistic SaaS
  invoice (expect a few distinct lines: plan, seats, add-ons, with subtotal/tax/total).
- To pass: enrich `transform_invoice` to pass issuer/customer/totals; fix the `$79.0` money
  formatting (the 118-03 `Decimal.to_float` price path); make the **amount due** the dominant
  element; give the invoice a realistic handful of line items.

### statement-northwind-ledger-co — realistic, key fact not dominant
Clean, conventional bank statement (masked account ****8140, period, opening balance, ledger with
running balance, parenthesized debits, correct money). Its DOMAIN.md key fact is the **closing
balance**, which is only the last cell of the Balance column — not a focal point. To reach CH=5,
surface the closing balance as a dominant summary element (e.g. a boxed "Closing balance
$6,647.56" like the payslip's Net Pay box).

### receipt-harbor-and-oak-cafe — total not dominant, no merchant identity
Clean item table with Subtotal/Tax/Total. Two gaps: the **Total ($30.78)** is small text at the
bottom (not dominant → CH=3), and the **merchant name** (Harbor & Oak Cafe) is absent — the render
says only "Sales Receipt / Walk-in Guest" (→ DF=3). To pass: show the merchant identity; make the
total the dominant element.

### certificate-summit-training-institute — layout imbalance
All content (title, recipient, body, date, signer) is packed into the top ~20% of a bordered
landscape A4; the lower ~80% is empty (→ RC=2). The title dominates the **recipient name** (the key
fact) (→ CH=3), and the body paragraph runs edge-to-edge. To pass: center the content vertically
and horizontally within the border; make the recipient name the dominant element; constrain the
body measure.

### payslip-aurora-live — closest; blocked by a crowded table
Net Pay $3,292.50 in a large box is genuinely dominant (CH=5, honestly earned). But the
earnings/deductions header collides ("YTDDeductions" run together), the base-salary YTD
"$25,200.00" wraps a digit onto a second line, and the two-column earnings-vs-deductions layout is
cramped (→ IA/RA/TC all 3). To pass: widen/space the earnings & deductions columns so headers and
figures don't collide or wrap.

### ticket-aurora-live — clean but no single dominant fact + whitespace
Event header, SECTION GA / ROW H / SEAT 24 / GATE B, and a perforated reference stub (AUR-88213-GA).
Four equally-large fields means none is singularly dominant (CH=4). A6 content sits on an A4 canvas,
leaving ~65% empty (→ RC=3). To pass: render the ticket at its native A6 (or size the canvas to
content) and make the seat (or the whole seat-locator group) the clear focal point.

## Recommended remediation (if you want the demos to actually pass SHOW-01)

1. Fix `transform_invoice` (+ money formatting) so the invoice renders parties + totals with the
   amount due dominant, over a realistic handful of lines. (lib/fixtures — reaches back into
   118-03/118-04 scope.)
2. Add a dominant "key-fact" summary element to statement (closing balance), receipt (total), and
   emphasize recipient (certificate) — recipe/composition work.
3. De-crowd the payslip earnings/deductions table.
4. Size the ticket to its content (A6) or make the seat-locator dominant.
5. Then re-render (118-05 gen), re-run this rubric scoring honestly, and expect passing marks.

This is genuine recipe/fixture/transform work spanning several files and is arguably prior-plan
(118-03/118-04) rework, not a 118-06 "score-only" task — which is why it's surfaced for your
decision rather than done unilaterally.

## State at pause

- **118-05: complete & committed** (`5696030`, `520518c`, `56557c5`) — gallery re-blessed to 7 tiles
  with realistic hashes, S6 tags, docs blocks; `mix rendro.launch_artifacts.check` VERIFIED; cross-
  platform raster determinism proven (forms_support_fixture snapshot matched the CI-blessed hash).
- **118-06: not started in git** — no citation test, no score entries committed. Clean to resume.
- The pinned pdfium worked locally via the mac-arm64 wasm build (see 118-05-SUMMARY "Environment
  note"); the same setup can re-score once demos are improved.
