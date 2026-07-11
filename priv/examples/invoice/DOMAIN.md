# Invoice — Domain Anatomy

Domain-research notes for the Invoice example family. This document captures the
language, readers, reading situations, and layout conventions that a faithful
invoice must honor. It is cited by rubric-scored demos (SHOW-01) so that scoring
is anchored to how invoices are actually read and used — not to generic
document-formatting taste.

## Domain Language

The vocabulary a reader expects an invoice to speak. Missing or renamed terms
make a document read as "not really an invoice."

**Nouns (the things on the page)**

- **Invoice** — the document itself; a demand for payment for goods/services rendered.
- **Invoice number / invoice ID** — the unique, human-quotable identifier used to
  reference this invoice in payments, correspondence, and reconciliation.
- **Issuer** — the party sending the invoice and owed the money (the "from" / "bill-from").
- **Customer / bill-to** — the party being charged and expected to pay (the "to").
- **Line item** — a single billable row: a description of what was provided.
- **Quantity** — how many units of a line item.
- **Unit price** — the per-unit charge for a line item.
- **Subtotal** — the sum of line items before tax.
- **Tax** — VAT/sales tax applied to the subtotal (often shown with a rate).
- **Total due** — the single amount the customer must pay. The headline number.
- **Due date** — the date by which payment is expected.
- **Payment terms** — the agreement governing when payment is due, e.g. "Net 30".
- **Remittance instructions** — how and where to pay (bank details, payment link, address).

**Verbs and events (the lifecycle)**

- **Issue / bill** — the issuer creates and sends the invoice.
- **Remit / pay** — the customer sends payment.
- **Settle** — the invoice is fully paid and closed.
- **Overdue** — the due date passed without full payment.
- **Dispute** — the customer contests a line item, the total, or the invoice's validity.

## Personas & Jobs-to-be-Done

Who reads an invoice, why, and — critically — the ONE fact each reader needs first.

- **Accounts Payable clerk — primary reader.** Processes invoices in a queue, one
  after another, often dozens per sitting. Their job is: decide whether and when to
  pay this. The ONE fact they need first is **total due**, immediately followed by
  **due date**. Everything else (line items, tax breakdown, terms) is consulted only
  when something looks off or a discrepancy must be resolved. Speed and unambiguous
  headline numbers matter more than completeness of detail.

- **Issuer / business owner — secondary reader.** Reviews the invoice for
  professional and legal correctness *before* it is sent. Their job is: confirm this
  represents my business accurately and will get me paid. They check that issuer and
  customer identities are right, that line items and totals are correct, and that the
  document looks credible enough to be taken seriously.

- **Bookkeeper / auditor — tertiary reader.** Reconciles the invoice against payments
  and records, sometimes long after issuance. Their job is: match this invoice to a
  payment and verify the math. They need the **invoice number** and **total** to tie
  out against ledgers, plus **itemization and tax broken out** so amounts can be
  categorized and verified line by line.

## Reading Context

The situations in which invoices are actually read — which drive what must survive.

- Invoices are triaged in a **stack, inbox, or queue** alongside many similar-looking
  documents. A given invoice competes for a few seconds of attention against its peers.
- The **first read is a fast top-to-bottom scan** answering three questions: *who is
  this from, how much, and by when?* Based on that scan the reader either files it for
  later or acts on it.
- A **slower second read** happens during actual payment processing or audit, when the
  reader works through line items, tax, and remittance details in full.
- Invoices are **as often printed as read on-screen**. Information must survive both:
  no reliance on color alone, hover states, or interactive reveal. What matters must be
  legible on a black-and-white printout as much as on a monitor.

## Layout & Typographic Conventions

The visual grammar that makes a document read as a trustworthy invoice.

- **Total due is the single most visually prominent number on the page** — larger,
  bolder, and/or set apart so it is found in the first glance.
- **Issuer and customer appear as two clearly separated blocks near the top**, so the
  "from" and "to" are never confused with each other.
- **Due date and payment terms sit near the top or adjacent to the totals** — never
  buried in the middle of the document where a fast scan would miss them.
- **The invoice number is an unambiguous, prominent identifier**, easy to quote in a
  payment reference or a phone call.
- **Line items render as an aligned table** with **right-aligned money columns**, so
  amounts line up on the decimal point and are easy to compare and sum by eye.
- **Subtotal, tax, and total are visually stepped toward the final total**, forming a
  short arithmetic ladder that leads the eye to the headline number.
- **Money uses fixed 2-decimal precision** and **consistent currency-symbol placement**
  throughout, so every amount reads as money and nothing looks like a typo.
