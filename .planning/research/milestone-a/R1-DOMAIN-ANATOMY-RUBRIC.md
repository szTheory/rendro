# R1 — Business-Document Domain Anatomy + Reader-Quality Rubric

**Milestone:** A (SEED-002) — Realistic Business-Document Examples & Anatomy
**Lens:** Domain content · graphic design · JTBD / reader-experience
**Phase served:** A0 (the durable artifact other phases build fixtures and templates against)
**Author:** research agent · **Date:** 2026-07-10
**Confidence:** HIGH on domain anatomy and rubric design; MEDIUM on a few locale-specific edge conventions (flagged inline)

> This report is the primary input to A0's per-domain `DOMAIN.md` files and the standing reader-quality
> rubric reused across Milestones A–D. It answers, per family: domain language, personas + JTBD, required
> vs conventional fields, layout/typographic conventions, and what "award-quality within functional
> bounds" means. Then it specifies the rubric and gives A0/A1 recommendations and a sanity-check verdict.

---

## 0. Grounding: Rendro's rendering-capability envelope (read this first)

Every recommendation below is bounded by what a **deterministic, locale-free, browser-free** Elixir engine
can actually put on a page. Confirmed by reading the engine (`lib/rendro/{text,table,path,row,format}.ex`,
`lib/rendro.ex`, and the five shipped recipes). The rubric scores documents **against this envelope**, not
against what a browser or InDesign could do.

**Rendro CAN render (use freely):**

- **Text** — `%Rendro.Text{content, font, size, color, line_height, widows, orphans}`. `Helvetica` (built-in
  standard-14) plus embedded TrueType via `register_embedded_font/3`. Color is `{r,g,b}` 0–255.
- **Tables** — `%Rendro.Table{}` with `columns: [{:fixed, pt} | {:share, n}]`, `header`, `repeat_header:
  true`, `header_fill`, `header_height`, borders (`:all | :rows | :columns | …`), and row split policies.
  This is the workhorse for every money grid.
- **Paths** — `%Rendro.Path{ops, fill, stroke}` with `{:rect}`, `{:rounded_rect, …, radius}`, `{:move}`,
  `{:line}`, `{:curve}`. This draws boxes, rules, keylines, frames, tint panels, ticket stubs.
- **Pagination** — automatic body-flow pagination; `Rendro.page_number/1` substitutes
  `{{page_number}}` / `{{total_pages}}` (and section-local `{{section_page_number}}`); repeating table
  headers; `break_before` / `keep_together` / `keep_with_next`; `only_on: :odd|:even` running content.
- **Money/dates** — `Rendro.Format.money/1` (`$1,234.50`, negatives as `($1,234.50)`, comma-grouped,
  half-up 2dp) and `Rendro.Format.date/1` (`YYYY-MM-DD`), both pure and byte-deterministic. Money is
  authored as `Decimal`, never Float (recipes raise on Float — see `statement.ex`).
- **Regions / fixed layout** — named regions with `anchor: :top|:bottom|:flow|:fixed`, geometry derived
  from page size (`Rendro.PageSize.resolve/2`), A4 and US Letter, portrait and landscape.
- **Images** — PNG/JPEG logos via `register_image/3` (the `brand:` seam in `BrandedInvoice`/`Certificate`).

**Rendro CANNOT do (design AROUND these — they bound the rubric):**

- **No text or cell alignment.** There is **no `align` field** on `Text`, `Cell`, or `Row`. Cell text is
  left-set. **Consequence for money:** the conventional "right-aligned figures" cannot be done as text
  alignment today. The honest affordance is a **dedicated fixed-width Amount/Balance column** whose values
  are all `Rendro.Format`-normalized (equal decimal places, `$` prefix, comma grouping) so the decimal
  points and `$` line up **visually by construction** within a narrow column. This reads as columnar money
  even though the glyphs are left-set. *(A small additive `cell_align: :right` on the table primitive is
  the single highest-leverage typographic upgrade the engine could make for financial documents — flagged
  as an optional A2 micro-enhancement, NOT assumed by this rubric.)*
- **No barcode / QR primitive.** Critical for the Ticket family (see §6). Tickets must read as tickets
  **without a live scannable code** — solved via a fixed "code panel" convention.
- **No shadow / gradient / opacity / elevation / z-index / rotation.** Elevation is expressed flatly:
  a tint `{:rect}` fill + a hairline `{:line}`/`stroke`. No angled text, no watermarks-by-opacity.
- **No monospaced built-in font.** `Helvetica` is proportional. Tabular figures do not advance uniformly
  unless an embedded mono/tabular-figures TTF is registered. (Fixed-width columns + consistent formatting
  still give a clean money column; true digit-grid alignment needs a tabular-figures font — a Milestone C
  curated-font concern, not A.)
- **No RTL / complex shaping** in core (instructive raise only). Locale differences below are **data**
  (labels, tax words, date formatter overrides), never engine locale-awareness.

**Design principle that follows:** hierarchy and scan-path must be carried by **type size, weight (via
embedded font choice), whitespace/region geometry, rule lines, and tint panels** — never by alignment,
color gradients, or effects. Every family section states its anchor fact and how to make it dominant
**within this envelope**.

---

## 1. Invoice (+ VAT variant)

### 1.1 Domain language

| Term | Meaning |
|---|---|
| Issuer / "From" / Bill-from | The party owed money (seller/supplier). Name, address, contact, tax id. |
| Bill-to / Customer / "To" | The party who owes. Name + billing address. |
| Ship-to | Delivery address when different from bill-to (conventional, often omitted). |
| Invoice number | Unique, **sequential** identifier (`INV-2026-0042`). Legally must be unique. |
| Invoice date / Issue date | Date the invoice is raised. |
| Due date | When payment is due; derived from terms. |
| Terms | Payment terms — **Net 30 / Net 15 / Due on receipt / 2/10 Net 30**. |
| Line item | A billable row: description, qty, unit price, line amount (qty × unit price). |
| Subtotal | Sum of line amounts before tax. |
| Tax / Sales tax / **VAT** | Tax applied. US = sales tax (rate varies by jurisdiction, applied to subtotal). UK/EU = **VAT** (Value Added Tax), shown **per rate**. |
| Total / Amount due / Balance due | **THE anchor fact.** What must be paid. |
| PO number | Purchaser's purchase-order reference (B2B). |
| Remit-to / Payment instructions | Bank details, "Pay to", accepted methods. |
| VAT-specific | **VAT registration number** (issuer), **tax point** (date of supply), **VAT rate**, **VAT amount per rate**, net/VAT/gross breakdown, and a **reason if VAT not charged** (reverse charge, zero-rated). |

### 1.2 Personas + JTBD

- **Who reads it:** (1) an **Accounts-Payable clerk** at the customer, (2) the **business owner/founder**
  approving payment, (3) the **issuer's own bookkeeper** reconciling, (4) increasingly, an **automated
  parser** (OCR/AP-automation).
- **Where/when/lens:** overwhelmingly **on-screen first** (PDF email attachment), often **printed** for
  filing or physical AP workflows. A **glance** ("what do I owe, by when, to whom?") then an **audit** if
  a line looks wrong. Must survive **B/W laser print** (no color-only signals).
- **The ONE fact they need FIRST (visual anchor):** **Amount due** (+ its **due date** as the immediate
  second). Everything else is supporting.
- **Why:** to pay the right amount to the right party by the right date, and to file/reconcile it.

### 1.3 Required vs conventional fields

**MUST have (production-grade):** issuer name+address, customer name+address, unique invoice number,
invoice date, at least one line item with description + amount, **total / amount due**. For **VAT**:
issuer VAT number, tax point, VAT rate + VAT amount, and net/VAT/gross totals ([HMRC full-VAT-invoice
rules require ~14 fields incl. VAT number, unique sequential number, tax point, per-rate VAT breakdown](https://www.gov.uk/hmrc-internal-manuals/vat-trader-records/vatrec5010)).

**Commonly has (conventional):** due date, payment terms, qty + unit price columns (not just line amount),
subtotal + tax lines, PO number, remit-to/payment instructions, notes/thank-you, issuer logo.

**US vs UK/EU (DATA differences, engine stays locale-free):**
- US: "Sales Tax", single tax line, no supplier tax-id requirement on the face, `$`, `MM/DD/YYYY`
  colloquially (Rendro default `YYYY-MM-DD`).
- UK/EU: "VAT", VAT number mandatory, **VAT shown per rate**, "Tax point", `£`/`€`, often
  amounts in words for large sums. All expressible as fixture data + `labels`/`formatters` overrides.

### 1.4 Layout / typographic conventions

- **Scan path:** issuer/logo top-left or top-band → invoice number + dates top-right → bill-to block →
  line-item table (full width) → totals block **bottom-right** → payment terms/notes footer.
- **Money:** all figures in a **narrow fixed-width Amount column**; `Rendro.Format` normalization gives a
  clean column (see §0 — no true right-align). Totals block: label + value pairs, **Total** row emphasized
  by larger size / heavier embedded weight / a hairline rule above it.
- **Totals kept with last rows:** the totals block must not orphan onto a page alone — use `break_before:
  false` + `keep_with_next` on the final line-item block (the shipped Receipt recipe already appends totals
  after the last table block; the Invoice upgrade should replicate this).
- **"Page X of Y"** in footer for multi-page (60+ line items — the quarantined fixture is exactly this).
- **Anchor dominance:** make **Amount Due** the largest number on the page (e.g. body 10pt, line totals
  10pt, **Amount Due 16–18pt** + heavier weight + a tint panel `{:rect}` behind it or a rule above).

### 1.5 "Award-quality within functional bounds"

A restrained, Swiss-clean invoice where the eye lands on **Amount Due** within one second; a single
disciplined type scale (heading / subhead / body / caption); one hairline rule system; generous margins;
the line-item table quiet and legible with a subtly filled header band (`header_fill`); the totals block
visually weighted and unambiguous; nothing decorative competing with the money. VAT variant adds a clear
per-rate tax breakdown without clutter.

### 1.6 Rendering notes for A2 (the only `lib/` change in Milestone A)

The current `Invoice` recipe is a stub (id/date + 3-col table + "Thank you"). A2 additively adds optional
`:issuer`, `:customer`, `:due_date`, `:terms`, `:totals` (Decimal) and a totals section with keep-with-last
behavior, promoting `Rendro.Format` to public adapter tier — **the richer `Statement`/`Receipt` recipes are
the proven pattern to copy** (Decimal money, `customer`, `totals`, `maybe_validate_totals!` with
`Decimal.equal?` assertions). The toy `%{id, date, items}` call must keep working (additive optional keys).

---

## 2. Statement (account / billing / AR-aging / bank)

### 2.1 Domain language

| Term | Meaning |
|---|---|
| Statement period | `from`–`to` date range the statement covers. |
| Account / Account holder | Whose account (name, number — mask all but last 4). |
| Opening balance / Brought-forward | Balance at period start. |
| Closing balance | **THE anchor fact.** Balance at period end. |
| Transaction / Activity line | Date, description, amount (**signed**), running balance. |
| Debit / Credit | Charges vs payments. Bank convention: separate Debit / Credit / Balance columns. |
| Running balance | Balance after each transaction (recipe computes as exact Decimal fold). |
| Carried-forward / Brought-forward | Page-break continuity rows (already implemented in `Statement`). |
| Amount due / Minimum payment / Payment due date | Billing statements (credit-card style). |
| **AR aging** | Current / 1–30 / 31–60 / 61–90 / 90+ buckets of outstanding invoices. |
| **EOB** (insurance) | Explanation of Benefits: billed / allowed / plan-paid / patient-responsibility. Statement-shaped but NOT a bill ("This is not a bill"). |

### 2.2 Personas + JTBD

- **Who:** account holder (customer), an AP/AR clerk (business AR statements), a bank customer, an
  insured member (EOB).
- **Where/when/lens:** screen + print; **glance** for closing balance / amount due, **audit** line-by-line
  when reconciling a discrepancy. Multi-page is normal (bank statements, 60+ transactions).
- **The ONE fact first:** **Closing balance** (billing statement: **amount due + due date**; AR aging:
  **total outstanding**; EOB: **patient responsibility**).
- **Why:** confirm the balance is right, spot unexpected charges, know what/when to pay.

### 2.3 Required vs conventional

**MUST:** account identity, statement period, opening balance, transaction lines (date/description/signed
amount), closing balance (the recipe validates a caller-supplied `closing_balance` via `Decimal.equal?`).
**Conventional:** running-balance column, debit/credit split, summary box (total debits/credits/count),
amount-due + due-date (billing), aging buckets (AR), "not a bill" disclaimer + benefit columns (EOB),
carried/brought-forward on page breaks, "Page X of Y".

**US/UK differences (data):** date/label formatting, "Statement"/"Account statement", currency symbol —
all `labels`/`formatters` overrides. EOB is US-specific; AR aging is universal.

### 2.4 Layout / typographic conventions

- **Scan path:** account + period header → **summary/closing-balance box top-right** → transaction table
  (Date · Description · Amount · Balance) → carried/brought-forward at page breaks → footer "Page X of Y".
- **Money column:** fixed-width Amount + Balance columns, `Rendro.Format` normalized; negatives as
  parentheses (already the `Format` behavior) so debits read cleanly in mono-tone print.
- **Anchor dominance:** closing balance / amount due in a tint-panel box, larger + heavier, top-right,
  where the eye lands after the account name.
- The shipped `Statement` recipe already nails pagination continuity — A1 fixtures just feed it realistic
  multi-page data (Cedar Mutual bank, Halden & Roe AR aging, Vantage Health EOB).

### 2.5 "Award-quality within functional bounds"

Calm ledger typography; alternating-row restraint via a very light `header_fill`/tint (no zebra circus);
the closing balance unmistakably dominant; carried/brought-forward rows visually distinct (a light rule or
label) so page continuity is obvious; a summary box that answers "what's my balance and what do I owe"
before any scrolling.

---

## 3. Receipt / Report (POS · payment · order confirmation · operational report)

### 3.1 Domain language

| Term | Meaning |
|---|---|
| Receipt | Proof a payment was **received** (past tense — money already changed hands). |
| Payment received / Amount paid | **THE anchor fact** for a receipt. |
| Transaction / Reference / Confirmation number | Ties the receipt to a payment/order. |
| Payment method | Card (last 4), ACH, cash, "Visa ····4242". |
| Order confirmation | E-commerce/ticketing: items ordered + total + fulfillment info. |
| Report | A multi-page tabular listing (operational/financial). Rendro's insight: **a report is just a receipt whose rows overflow** (one recipe, N pages). |
| Subtotal / Tax / Tip / Total / Amount tendered / Change | POS-specific lines. |
| Column headers repeat | On every page of a multi-page report (already implemented). |

### 3.2 Personas + JTBD

- **Who:** a customer keeping proof of payment; a finance user attaching a receipt to an expense; an
  operator reading a 60+-row operational report.
- **Where/when/lens:** receipt = **glance + archive** ("did it go through? how much? when?"); report =
  **scan + audit** across many rows/pages. Receipts are frequently **email attachments** (Stripe-style).
- **The ONE fact first:** **Amount paid** (receipt) / the report's **key total or the row you're hunting**
  (report — here the anchor is the *repeating column header* + a clear total).
- **Why:** proof, reconciliation, operational review.

### 3.3 Required vs conventional

**Receipt MUST:** title ("Payment Receipt"), date, payer/customer, line item(s), **amount paid/total**.
**Conventional:** transaction/confirmation number, payment method (masked), subtotal/tax/tip, merchant
info, "PAID" affordance. **Report MUST:** title, column headers, rows, repeating headers on overflow,
"Page X of Y". The shipped `Receipt` recipe already covers title/date/customer/lines/optional totals with
`Decimal.equal?` subtotal validation and per-page table blocks — A1 supplies realistic data across the
four domains (Northwind POS, Nimbus payment, Aurora order confirmation, Meridian 60+-row report).

### 3.4 Layout / typographic conventions

- **Receipt:** narrow, top-anchored; "PAID" / amount-paid prominent; method + reference small under the
  total. **Report:** full-width table, filled header band, repeating headers, right-hand numeric columns
  fixed-width, "Page X of Y" footer, optional total row kept with last rows.
- **Anchor dominance (receipt):** the paid amount is the largest element; a hairline-bordered tint panel
  or a rule reinforces "settled."

### 3.5 "Award-quality within functional bounds"

Receipt: quiet, confidence-inspiring, unmistakable "paid" state, no marketing noise. Report: a dense-but-
legible table that stays readable at 60+ rows across pages — consistent column widths, a persistent header
band, honest page numbering, and totals that never orphan.

---

## 4. Certificate (completion · compliance/attestation · COI · award)

### 4.1 Domain language

| Term | Meaning |
|---|---|
| Certificate title | "Certificate of Completion / Achievement / Compliance". |
| Recipient | **THE anchor fact** — whose name the certificate honors. |
| Body statement / Recital | "This certifies that … has completed …". |
| Issue date / Award date | When granted. |
| Issuer / Authority | Granting body. |
| Seal / Signature line | Authority mark; signatory name + title. |
| Credential id / Serial | Verification reference (compliance/COI). |
| COI | Certificate of Insurance: insured, policy number, coverage limits, effective/expiry, carrier. |
| Attestation | Compliance: standard/scope met, auditor, valid-through date. |

### 4.2 Personas + JTBD

- **Who:** the recipient (pride/proof); a verifier (HR, auditor, procurement checking a COI or credential).
- **Where/when/lens:** frequently **printed / framed** (award, completion) → **landscape**, generous
  margins, print-safe; or **filed/verified** (COI, attestation) → data-forward. **Glance** to confirm the
  name + what it certifies; **audit** the policy/credential details for COI/compliance.
- **The ONE fact first:** the **recipient name** (award/completion) or, for COI/attestation, **what is
  covered/attested + valid-through**.
- **Why:** recognition, or verification of coverage/credential validity.

### 4.3 Required vs conventional

**MUST:** title, recipient, date (the shipped `Certificate` recipe requires exactly these). **Conventional:**
body/recital, seal/signature line, issuer, credential id; **COI:** policy number, limits, effective/expiry,
carrier, insured; **compliance:** standard, scope, auditor, valid-through. Certificate is a **single-page,
landscape-default** recipe with an optional geometry-derived `border:` frame and optional `brand:` logo/font
— A1 feeds four domain flavors (Ironwood training, Sentinel attestation, Beacon COI, Aurora award).

### 4.4 Layout / typographic conventions

- **Scan path (award):** centered vertical rhythm — title (large) → "this certifies that" (small) →
  **recipient (very large)** → body → date + seal line. **Symmetry and whitespace carry the ceremony.**
- **Anchor dominance:** recipient name is the largest text on the page (the recipe already sets title 28pt,
  recipient 20pt — award-quality wants recipient ≥ title or a clearly distinct display size).
- **Frame:** the optional keyline `border:` (single/double, geometry-derived) is the primary "certificate"
  affordance within the envelope — no ornamental engraving, but a disciplined double keyline reads formal.
- COI/compliance are **less ceremonial, more tabular** — a labeled key/value block + a coverage table.

### 4.5 "Award-quality within functional bounds"

Award/completion: balanced, symmetric, framed, the name unmistakably the hero, restrained type contrast
(one display face + one text face), print-safe margins. COI/attestation: clean labeled data blocks, a
coverage table, a verification id — legible and audit-ready rather than decorative.

---

## 5. Payslip (NEW family) — *Rivet Payroll*

### 5.1 Domain language

| Term | Meaning |
|---|---|
| Employer / Employee | Parties. Employee: name, id, sometimes NI/SSN (masked), tax code. |
| Pay period / Pay date | The period worked and the date paid (e.g. "1–31 May 2026", paid 2026-05-31). |
| Earnings / Gross pay | All pay before deductions (basic + overtime + bonus + allowances). |
| Deductions | Amounts withheld: **income tax (PAYE / federal+state), National Insurance / FICA, pension, student loan, other**. |
| **Net pay / Take-home** | **THE anchor fact** — what actually lands in the bank. |
| YTD (Year-to-date) | Cumulative gross, tax, NI, net for the tax year. |
| Tax code | UK: e.g. `1257L`. US: filing status / allowances. |
| Payment method | BACS / direct deposit / cheque. |
| Hours | Where pay varies by hours, hours paid must be shown. |

### 5.2 Personas + JTBD

- **Who:** the **employee** (primary — checking they were paid correctly), and secondarily HR/payroll,
  a mortgage/loan verifier, an accountant.
- **Where/when/lens:** **screen first** (payroll portal / email), sometimes printed for loan applications.
  A **glance** at net pay, then a **check** of the tax/pension deductions and YTD.
- **The ONE fact first:** **Net pay** (take-home). Gross and deductions are the supporting audit trail.
- **Why:** confirm correct pay, understand deductions, prove income.

### 5.3 Required vs conventional

**MUST (production-grade, and statutory in the UK):** employer + employee identity, pay period + pay date,
**gross pay, itemized deductions (variable deductions as amounts), net pay**; hours where pay varies
([UK Employment Rights Act 1996 s.8 itemised pay statement: gross pay, amounts+purposes of variable
deductions, net pay, and hours where pay varies](https://www.acas.org.uk/payslips)).
**Conventional:** two-column **Earnings | Deductions** layout, **YTD column** beside period column,
tax code, NI/SSN (masked), payment method, employer address, a net-pay summary box.

**US vs UK (DATA only):**
- UK: PAYE income tax, **National Insurance**, tax code (`1257L`), pension (auto-enrolment), student loan.
- US: **federal + state income tax**, **FICA (Social Security + Medicare)**, 401(k), often
  **pre-tax vs post-tax** deduction grouping, filing status.
- Both fit the same **Earnings/Deductions/Net + YTD** skeleton — the difference is deduction *labels* and
  which lines appear, i.e. fixture data. Engine stays locale-free.

### 5.4 Layout / typographic conventions

- **Scan path:** employer + employee + pay-period header → **two side-by-side tables: Earnings (left) /
  Deductions (right)** → **Net Pay summary box (prominent)** → YTD strip → payment method footer.
- **Two-column earnings/deductions** is the defining payslip affordance. In Rendro this is **two fixed-
  width regions side by side** (fixed `x`/`width` regions in the page template) OR a single table with an
  Earnings block above a Deductions block if side-by-side regions are awkward — side-by-side is more
  domain-true and fully doable with two `anchor: :fixed`/`:top` regions.
- **Period vs YTD:** each amount typically shows this-period and YTD — a 3-column mini-table
  (Description · This period · YTD) per side, or a 4-column combined grid.
- **Anchor dominance:** **Net Pay** in a tint-panel box, largest number on the page, visually separated
  from the earnings/deductions detail.
- **Privacy:** mask NI/SSN and bank details in fixtures (`··· 4321`).

### 5.5 "Award-quality within functional bounds"

A payslip where an employee finds **net pay in under a second**, then can trace every deduction without
squinting; balanced Earnings/Deductions columns; a quiet YTD strip; masked identifiers; consistent money
formatting so the two columns visually reconcile to the net-pay box. No color needed — hierarchy via size,
weight, whitespace, one tint panel, and hairline rules.

### 5.6 Recipe-build notes (A3)

Model on `Receipt`/`Statement`: `Decimal` money, `validate_data!` errors-as-product, `Decimal.equal?`
assertions (gross − Σdeductions == net; period + prior-YTD == YTD if supplied). Two-region template
(earnings/deductions) + a net-pay summary block. Single-page default; overflow (many deduction lines) →
typed `:content_overflow`, never silent truncation.

---

## 6. Ticket / Boarding-pass (NEW family) — *Aurora Live*

> **The hard question:** Rendro has **no barcode/QR primitive**. Real tickets and boarding passes are
> dominated by a scannable code (the IATA **BCBP** PDF417/Aztec on a boarding pass encodes name, PNR,
> flight, seat, sequence, cabin, security flags —
> [IATA BCBP implementation guide, Resolution 792](https://www.iata.org/contentassets/1dccc9ed041b4f3bbdcf8ee8682e75c4/2021_03_02-bcbp-implementation-guide-version-7-.pdf)).
> **How does a ticket still read as a ticket without a live code?** Answer below.

### 6.1 Domain language

| Term | Meaning |
|---|---|
| Event / Flight | What the ticket admits you to (concert/flight/match). |
| Passenger / Holder / Attendee | **Part of the anchor.** Name. |
| Seat / Section / Row / Zone / Gate | **THE anchor fact** — where you sit / board. |
| Date / Time / Doors / Boarding time | When. |
| Venue / Origin→Destination | Where. |
| Barcode / QR / BCBP | The scannable admission token (Rendro can't render live). |
| Booking reference / PNR / Order # / Confirmation | The lookup key (human-readable, and what a code would encode). |
| Fare class / Cabin / Ticket type | GA / VIP / Economy / etc. |
| Stub / Tear-off | The retained portion (event tickets); the perforation line. |
| Sequence number | Boarding order (flights). |
| Terms / Admission conditions | Fine print. |

### 6.2 Personas + JTBD

- **Who:** the **ticket holder** (at the gate, glancing on a phone or a printed page) and the **gate
  agent/scanner** (who normally scans the code).
- **Where/when/lens:** **glance under time pressure** at a venue/gate — often printed, often on a phone.
  Needs to be legible at arm's length, high-contrast, in bad lighting.
- **The ONE fact first:** **Seat + gate/section** (boarding pass: **gate + boarding time + seat**;
  event: **section/row/seat + doors time**). Passenger name and event/flight are the immediate context.
- **Why:** get admitted and find your place fast.

### 6.3 Required vs conventional — and the no-barcode solution

**MUST:** event/flight identity, holder/passenger name, date + time, venue/route, **seat/section/gate**,
a **booking reference / order number** (human-readable), and a **code area**.

**How a ticket reads as a ticket WITHOUT a live scannable code — the "code panel" convention:**

1. **A fixed, clearly-bordered "code box"** drawn with `{:rect}` / `{:rounded_rect}` in the canonical
   position (right side or bottom stub), sized like a real barcode/QR zone. Its *presence and placement*
   is 80% of the "this is a ticket" signal.
2. Inside it, render the **human-readable reference in large mono-ish type** (the PNR/order number) — real
   boarding passes always print the PNR/sequence in human-readable form *beside* the code; a ticket with a
   prominent, boxed confirmation code reads as scannable-adjacent.
3. Optionally a **placeholder label** ("Present this code at the gate" / "Scan at entry") and, if a real
   code is ever needed, a **pre-rendered barcode/QR image** supplied by the caller as a **PNG via
   `register_image/3`** (the engine embeds images — the *generation* of the code is the caller's job,
   keeping the engine free of a barcode dependency). Document this as the escape hatch.
4. **Stub / perforation affordance:** a vertical dashed rule (`{:line}` dashes via `stroke` style, or a
   column of short `{:line}` segments) separating the **stub** from the main ticket — a strong, cheap
   "ticket" cue unique to this family.
5. **Small fixed-box format:** boarding passes/event tickets are **small, dense, fixed-layout** (not a full
   A4 flow). Use a **fixed sub-region** (e.g. a 3.5in × 8in ticket band, or a boarding-pass strip) with
   `anchor: :fixed` regions — this is the family's signature and distinguishes it from the flowing
   invoice/statement families.

**Air vs event (data):** boarding pass adds gate, boarding time, sequence, cabin, origin→destination,
group/zone; event ticket adds section/row/seat, doors time, GA/VIP. Same skeleton, different labels.

### 6.4 Layout / typographic conventions

- **Fixed dense grid**, not flow. Left/main panel: event/flight + passenger + date/time + venue/route.
  **Seat/gate/section rendered LARGE** (the anchor) in its own labeled cell. Right/stub panel or bottom
  band: the **code box** + human-readable reference, repeated key facts (seat/gate) for the tear-off.
- **Perforation line** between main and stub.
- **Anchor dominance:** seat/gate is the biggest element after the event name; boxed and labeled.
- High contrast, generous size — designed to be read fast, possibly on a small printed area.

### 6.5 "Award-quality within functional bounds"

A ticket that is instantly recognizable as a ticket — the boxed code area, the perforation, the dense
fixed grid, the oversized seat/gate — reading cleanly in black-on-white at small size. Elegant use of
rules and boxes (the engine's strength) instead of the color/gradient flourishes a designed ticket might
use. The code-box convention turns a genuine engine limitation into a clean, honest affordance.

### 6.6 Recipe-build notes (A3)

New `Rendro.Recipes.Ticket` on the 3-rung pattern with a **fixed-region template** (main + stub + code
box). Validate required fields errors-as-product. Provide the **image-code escape hatch** (`code_image:`
registered PNG) documented but optional; default renders the boxed human-readable reference. This is the
family that most exercises `%Rendro.Path{}` (boxes, rules, perforation) and fixed-region composition.

---

## 7. Reader-Quality Rubric (the durable A0 artifact)

The rubric is reused across all four milestones as a **standing quality ratchet**. It must be repeatable by
a **non-designer reviewer**, machine-recordable, and grounded in Rendro's rendering envelope (§0).

### 7.1 Dimensions

Six **core** dimensions scored **1–5** (confirming + refining the sketch) plus two **additive gate**
checks scored **pass/fail** (the prompt's suggested accessibility-reading-order and print-safety). Splitting
the two additive ones out as booleans keeps the 1–5 scoring tight for a non-designer while still enforcing
them.

| # | Dimension | What it measures |
|---|---|---|
| D1 | **Information architecture** | Is content grouped into the right regions in the right order (header/identity → body → totals/anchor → footer)? Does structure match the family's DOMAIN.md? |
| D2 | **Content hierarchy (anchor)** | Is the ONE key fact (amount due / net pay / closing balance / seat+gate / recipient) the unmistakable visual anchor? **Must score 5.** |
| D3 | **Least-surprise / domain-fit** | Does it match what a reader of THIS family expects (terms, field names, conventional positions)? No missing table-stakes field. |
| D4 | **Reader affordances** | Fixed-width normalized money columns, sensible scan path, "Page X of Y", repeating headers, totals kept with last rows, carried/brought-forward continuity, labeled anchor. |
| D5 | **Typographic craft** | Disciplined type scale, consistent rules/tint system, balanced whitespace/margins, no size/weight chaos, print-safe contrast (works in B/W). |
| D6 | **Restraint / cohesion** | No decoration competing with meaning; one visual system; nothing that fights the envelope (no faux effects). *(Refinement of the sketch's "domain-fit" split from D3.)* |
| G1 | **Reading-order integrity** (pass/fail) | Content is emitted in a logical reading order that matches visual order (so text extraction / a screen reader gets a coherent sequence). |
| G2 | **Print-safety & margins** (pass/fail) | Adequate margins, nothing in the non-printable edge, no color-only signal, anchor legible in grayscale, no content clipped at page boundary. |

> Note: the sketch listed "information architecture, content hierarchy, least-surprise, reader affordances,
> typographic craft, domain-fit." This refines it to keep all six but separate **least-surprise/domain-fit**
> (D3, correctness of fields) from **restraint/cohesion** (D6, visual discipline), because a non-designer
> can judge "is a required field missing / in the wrong place" (D3) more reliably than a blended
> "domain-fit" score. G1/G2 are the additive dimensions the prompt asked for.

### 7.2 Concrete 1–5 scale (repeatable by a non-designer)

Generic anchor for every dimension: **1 = broken/absent · 2 = present but poor · 3 = acceptable/functional ·
4 = good/professional · 5 = exemplary/flagship.** Per-dimension specifics:

- **D2 Content hierarchy (the load-bearing one):**
  - **3** = the anchor fact is present and findable but competes with other elements (same size/weight as
    line items or totals detail).
  - **4** = the anchor is clearly larger/heavier than surrounding text and in the conventional position.
  - **5** = the anchor is the **single dominant element** — largest number/name on the page, set apart by
    size **and** a supporting device (tint panel / rule / dedicated cell), findable in **≤1 second** by a
    first-time reader. Nothing else on the page reaches its weight.
- **D4 Reader affordances (example rows):**
  - **3** = money in a fixed-width column but inconsistent formatting; page numbers present.
  - **4** = all money `Rendro.Format`-normalized in fixed columns; repeating headers; "Page X of Y"; totals
    don't orphan.
  - **5** = all of 4 **plus** family-specific niceties done right (carried/brought-forward continuity on
    statements; earnings/deductions reconcile to net on payslips; perforation + code box on tickets;
    keep-with-last totals verified across a real page break).
- **D5 Typographic craft:**
  - **3** = readable, a couple of inconsistent sizes.
  - **4** = one coherent type scale (≈3–4 sizes), consistent rule/tint system, balanced margins.
  - **5** = flagship discipline — every size/weight earns its place, rules are hairline-consistent, vertical
    rhythm is even, margins generous, reads beautifully in grayscale.

The same 1/3/4/5 pattern applies to D1, D3, D6 (a reviewer asks: right structure? right/complete fields?
visually disciplined? — scoring 3 acceptable / 4 professional / 5 flagship).

### 7.3 Pass threshold

**Recommended gate (refines the sketch's "all ≥4, hierarchy =5"):**

- **D2 (hierarchy) = 5** — non-negotiable; the anchor MUST dominate.
- **D1, D3, D4, D5, D6 ≥ 4** — professional on every core dimension.
- **G1 and G2 = pass** — reading order coherent; print-safe.

**Is that right?** Yes, with one nuance. "All core ≥4 and hierarchy=5" is a **high bar (mean ≥4.17/5)** —
appropriate because these are **curated flagship examples and the standing quality ratchet**, not arbitrary
user content. Keep it strict for the **catalog/unbranded-default** templates (Milestones A4/C). Consider a
**softer advisory tier** (all ≥3, D2 ≥4) only for stress-matrix edge fixtures (A5) whose job is to prove
error/overflow behavior, not to be beautiful — those should be **exempt from the beauty gate** and scored
only on G1/G2 + not crashing. Recommendation: the rubric gate applies to **demonstration/catalog templates**;
edge-case fixtures are explicitly out of rubric scope.

### 7.4 How it should be recorded (machine-checkable + ratchet)

**Yes, make it a machine-checkable file** — mirror the shipped `public_api.json` / `support_matrix.json`
discipline (JSON + schema + a docs-contract test lane). Two-part design:

1. **`priv/quality/rubric_scores.json`** — one entry per catalog template:
   ```
   { "template": "invoice/nimbus_saas.light", "family": "invoice", "domain": "saas",
     "scores": { "D1": 5, "D2": 5, "D3": 4, "D4": 5, "D5": 5, "D6": 4 },
     "gates": { "G1": "pass", "G2": "pass" },
     "reviewed_at": "2026-07-15", "reviewer": "handle", "notes": "…" }
   ```
   Scores are **human-assigned** (a designer/reviewer records them — quality is a human judgment) but the
   **file is machine-validated**: a docs-contract test asserts (a) schema-valid against
   `priv/schemas/rubric_scores.schema.json`, (b) every catalog template has an entry, (c) each entry meets
   the threshold (D2=5, core ≥4, gates pass).
2. **Ratchet behavior (for Milestone C's catalog):** the test enforces **monotonic non-regression** — a
   template's recorded scores may go **up** but a drop below threshold fails CI. Track scores over time so
   the catalog demonstrably "oozes quality," including the unbranded default. This makes quality a
   committed, reviewable artifact rather than a vibe.

**Recommendation:** author the **schema + empty scores file + the docs-contract lane** in A0 (so the
contract exists), populate scores in A4 (demonstration set) and extend in C (catalog). Keep the human
scoring lightweight: a short `RUBRIC.md` scoring guide co-located in `priv/quality/` so any reviewer scores
consistently.

---

## 8. Recommendations for A0 / A1

### 8.1 What each `priv/examples/<domain>/DOMAIN.md` should contain

Per-domain (reused across that domain's families), sections:

1. **Domain-language glossary** — the family's own nouns/verbs/events (the §1–6 tables above), so fixtures
   and guides use correct vocabulary.
2. **Personas + JTBD** — who reads it, in what lens (screen/print, glance/audit), who/what/where/when/why,
   and **the ONE anchor fact** stated explicitly (this drives D2 scoring).
3. **Required vs conventional fields** — a checklist a fixture author can satisfy; note US/UK differences as
   **data** (label/formatter overrides), never engine locale-awareness.
4. **Layout & typographic conventions** — scan path, anchor-dominance recipe, money-column approach (fixed-
   width + `Rendro.Format`, no true right-align), pagination affordances.
5. **"Award-quality within functional bounds"** paragraph — the aspirational bar for that family.
6. **Rendering-envelope notes** — family-specific constraints (e.g. ticket has no barcode → code-box
   convention; payslip needs two side-by-side regions; certificate is landscape single-page).
7. **Rubric anchor** — restate the anchor fact and any family-specific D4 affordances the reviewer checks.

### 8.2 What A1 fixtures must encode

- **Decimal money everywhere** (never Float — recipes raise), cents-accurate, with **caller assertions**
  (`totals`, `closing_balance`, gross−deductions==net) so `Decimal.equal?` validation is exercised.
- **The full anatomy** of each family (all MUST fields + the conventional ones the DOMAIN.md lists) — this
  is what makes examples production-grade vs toy.
- **US and UK/EU flavors as data** — VAT vs sales-tax labels, `£`/`€` via `formatters`, VAT number / tax
  point fields present in the VAT fixture (Halden & Roe).
- **De-quarantine `bench/comparison/fixtures/invoice_data.json`** into `priv/examples/` (it already has
  real addresses, Net 30, 60 line items, subtotal/tax/total in cents) and repoint the bench harness.
- **Named fictional businesses** per the matrix (Nimbus, Marigold, Northwind, Halden & Roe, Cedar Mutual,
  Vantage Health, Aurora Live, Meridian, Ironwood, Sentinel, Beacon, Rivet Payroll) — brand is **data**,
  never a module.
- **Masked identifiers** (account/NI/SSN/card → `··· 4321`) in every fixture — privacy-safe examples.
- **Page-boundary data** — at least one fixture per paginating family with 60+ rows to exercise repeating
  headers, "Page X of Y", carried/brought-forward, and keep-with-last totals.
- **A JSON schema** (`priv/schemas/`) per family mirroring the `public_api.schema.json` discipline so
  fixtures are validated and the loader can be dev/test-scoped (out of the public API manifest).

### 8.3 One engine micro-enhancement worth flagging for A2 scoping

**Optional table `cell_align: :right`** (or per-column alignment on `{:fixed, pt, :right}`) is the single
highest-leverage rendering upgrade for financial families — it would turn every money column from "visually
columnar via fixed width" into true right-aligned figures, materially improving D4/D5 across invoice,
statement, receipt, and payslip. It is **additive and small** (alignment offset at cell-render time). Not
required for A (the rubric is grounded without it), but worth a decision at A2 kickoff since A2 is already
the only `lib/`-touching phase and is upgrading the money-heaviest family. **Do not assume it exists.**

---

## 9. Sanity-check verdict

**Are Payslip + Ticket the right two new families?** **Yes — with high confidence.**

- Both are **named in Rendro's own brand book** ("invoices, statements, reports, certificates, labels,
  tickets, and operational documents"; docs recipe list includes "Shipping label", "Event ticket") — they
  are on-thesis, not scope creep, and organized **by document family** (not industry).
- **Payslip** is the strongest addition: it introduces a genuinely new anatomy (**two-column
  earnings/deductions + net-pay anchor + YTD**) not covered by the existing four families, is universally
  needed, statutorily well-defined (a crisp MUST-have list), and is a clean data+recipe job on existing
  primitives. It stress-tests **side-by-side fixed regions** and `Decimal` reconciliation.
- **Ticket** is the highest-*design*-value addition and the best exercise of `%Rendro.Path{}` (boxes,
  rules, perforation) and **fixed dense layout** — a different shape from every flowing family. Its one risk
  (no barcode primitive) is **resolvable and even clarifying**: the **code-box + human-readable-reference +
  optional image escape-hatch** convention is honest, deterministic, and turns a limitation into a
  recognizable affordance. It also forces the "small fixed-box format" muscle the engine hasn't shown off.
- Deferred candidates (quote/estimate, credit note, packing slip, remittance advice) are correctly left as
  **data flavors of the invoice/statement families**, not new recipes — that judgment holds.

**Is A0's rubric scope right-sized?** **Yes — with two refinements adopted above.**

- The six sketched dimensions are the right ones; keeping them and splitting **least-surprise/domain-fit**
  (field correctness) from **restraint/cohesion** (visual discipline) makes the 1–5 scoring **more
  repeatable by a non-designer**, which is the whole point of a durable cross-milestone rubric.
- Adding **reading-order** and **print-safety** as **pass/fail gates** (not 1–5) captures the prompt's
  accessibility/print concerns **without inflating scoring burden** — a good size-vs-rigor trade.
- The **strict threshold (D2=5, core ≥4, gates pass)** is correct for **catalog/flagship** templates but
  should **explicitly exempt the A5 edge-case stress fixtures** (whose job is error/overflow behavior, not
  beauty). Making that scope boundary explicit prevents the rubric from blocking the stress matrix.
- Making the rubric a **machine-checkable JSON + schema + docs-contract lane with a monotonic ratchet** (not
  just prose) is essential for it to survive as the standing quality bar across Milestones A→D — it matches
  Rendro's existing `public_api.json` / `support_matrix.json` culture and is the mechanism that makes
  "everything oozes quality" enforceable rather than aspirational.

**Net:** the milestone's family choices and rubric scope are sound; the only genuinely new design problem
(Ticket without a barcode) has a clean, deterministic solution, and the rubric should ship as a
schema-backed, ratcheted artifact authored in A0 and populated in A4/C.

---

## Sources

- HMRC full VAT invoice required fields — [VATREC5010, GOV.UK internal manual](https://www.gov.uk/hmrc-internal-manuals/vat-trader-records/vatrec5010)
- UK statutory itemised pay statement (Employment Rights Act 1996 s.8) — [Acas: Payslips](https://www.acas.org.uk/payslips)
- IATA Bar Coded Boarding Pass (BCBP) field structure / Resolution 792 — [IATA BCBP Implementation Guide (PDF)](https://www.iata.org/contentassets/1dccc9ed041b4f3bbdcf8ee8682e75c4/2021_03_02-bcbp-implementation-guide-version-7-.pdf)
- Comparable-library onboarding-by-job precedent (QuestPDF invoice tutorial, WeasyPrint use-cases) — via `.planning/research/JTBD-USER-FLOWS.md`
- Engine capability envelope — read directly from `lib/rendro/{text,table,path,row,format}.ex` and the shipped `Statement`/`Receipt`/`Invoice`/`Certificate` recipes (this repo)
