# Receipt — Domain Anatomy

Domain-research notes for the receipt example family. This document captures the
language, readers, reading situations, and layout conventions that a faithful
receipt must honor. It is cited by rubric-scored demos (SHOW-01) so that scoring
is anchored to how receipts are actually read and used — not to generic
document-formatting taste.

## Domain Language

The vocabulary a reader expects a receipt to speak. Missing or renamed terms
make a document read as "not really a receipt."

**Nouns (the things on the page)**

- **Receipt** — the document itself; proof that a payment was made and a transaction
  completed. Unlike an invoice (a demand for payment), a receipt confirms money has
  already changed hands.
- **Merchant / seller** — the party that received the payment and issued the receipt.
- **Customer** — the party who paid; often anonymous ("Walk-in Guest") at point of sale.
- **Date** — when the purchase was made.
- **Line item** — a single purchased thing: a description and its amount.
- **Subtotal** — the sum of line items before tax.
- **Tax** — sales tax/VAT applied to the subtotal.
- **Total** — the amount actually paid. The headline number and the proof figure.
- **Payment method** — how the total was settled (cash, card, etc.), when shown.

**Verbs and events (the lifecycle)**

- **Purchase** — the customer buys goods or services.
- **Pay / settle** — the customer tenders payment and the merchant accepts it.
- **Issue** — the merchant hands over the receipt as proof of the completed sale.
- **Return / refund** — the customer brings the receipt back to reverse the purchase.
- **Reconcile** — the receipt is matched against a card statement or expense report.

## Personas & Jobs-to-be-Done

Who reads a receipt, why, and — critically — the ONE fact each reader needs first.

- **Customer at point of sale — primary reader.** Glances at the receipt in the
  moment to confirm they were charged correctly. Their job is: check I paid the right
  amount. The ONE fact they need first is the **total paid**, with **proof of payment**
  (that the sale completed) immediately implied. Line items are scanned only if the
  total looks wrong.

- **Expense filer / reimbursee — secondary reader.** Keeps the receipt to claim the
  spend back later. Their job is: prove what was bought and how much. They need the
  **total**, the **date**, and the **merchant** legible enough to survive a photo or a
  crumpled pocket, plus itemization if the claim must be justified.

- **Bookkeeper / auditor — tertiary reader.** Reconciles the receipt against card
  statements and books. Their job is: match this receipt to a payment and categorize
  it. They need the **total** and **tax broken out** so the amount ties out and the
  tax is accounted for separately.

## Reading Context

The situations in which receipts are actually read — which drive what must survive.

- The **first read happens in seconds at the counter** — a quick check that the total
  is right before the customer walks away.
- Receipts are **small-format and physical as often as digital** (narrow slips, A5/A6
  cards). Everything essential must fit a small page and survive printing without color.
- A **later second read** happens during expense filing or reconciliation, sometimes
  from a photo, so the total, date, and merchant must stay legible when reproduced.
- Receipts are **kept as proof** and retrieved out of context weeks later, so they must
  be self-explanatory with no reliance on the moment of purchase to make sense.

## Layout & Typographic Conventions

The visual grammar that makes a document read as a trustworthy receipt.

- **The total paid is the single most visually prominent number on the page** — it is
  the proof figure and the reader's whole reason for glancing at the receipt.
- **The merchant and date sit clearly near the top**, so the receipt is self-identifying
  as evidence of who was paid and when.
- **Line items render as a compact, aligned list or table** with **right-aligned money**,
  so amounts line up on the decimal point even on a narrow slip.
- **Subtotal, tax, and total are visually stepped toward the final total**, forming a
  short arithmetic ladder that leads the eye to the amount paid.
- **The layout fits a small page** without crowding — receipts are printed narrow, so
  the hierarchy must hold when column width is scarce.
- **Money uses fixed 2-decimal precision** and **consistent currency-symbol placement**,
  so every amount reads as money and the total is unmistakable as the amount paid.
