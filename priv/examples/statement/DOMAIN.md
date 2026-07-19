# Account Statement — Domain Anatomy

Domain-research notes for the account-statement example family. This document
captures the language, readers, reading situations, and layout conventions that
a faithful statement must honor. It is cited by rubric-scored demos (SHOW-01) so
that scoring is anchored to how statements are actually read and used — not to
generic document-formatting taste.

## Domain Language

The vocabulary a reader expects a statement to speak. Missing or renamed terms
make a document read as "not really a statement."

**Nouns (the things on the page)**

- **Statement** — the document itself; a periodic record of every transaction on
  an account, bracketed by an opening and closing balance.
- **Account** — the ledger being reported on; identified by name and often a
  partially masked account number.
- **Statement period** — the date range (from–to) the statement covers.
- **Opening balance** — the account balance carried in at the start of the period.
- **Closing balance** — the account balance at the end of the period. The figure
  the reader reconciles against. The headline number.
- **Transaction line** — a single dated movement: a description plus a signed amount.
- **Debit** — a transaction that decreases the balance (a withdrawal, payment, or fee).
- **Credit** — a transaction that increases the balance (a deposit or receipt).
- **Running balance** — the balance after each successive transaction, folded from
  the opening balance.
- **Carried forward / brought forward** — the balance handed across a page break so
  a multi-page statement stays continuous.
- **Summary** — the period totals: total debits, total credits, transaction count,
  and the closing balance.

**Verbs and events (the lifecycle)**

- **Post** — a transaction is recorded against the account on its value date.
- **Reconcile** — the reader matches the statement's lines and closing balance
  against their own records.
- **Carry forward** — a running balance is continued onto the next page or period.
- **Dispute** — the reader contests a line they do not recognize or that looks wrong.
- **Close** — the period ends and the closing balance becomes the next period's opening.

## Personas & Jobs-to-be-Done

Who reads a statement, why, and — critically — the ONE fact each reader needs first.

- **Account holder — primary reader.** Checks the statement to confirm the account
  is healthy and nothing is amiss. Their job is: verify the money is right. The ONE
  fact they need first is the **closing balance** — does it match what they expect?
  Only if it looks wrong do they scan the transaction lines to find the discrepancy.

- **Bookkeeper / accountant — secondary reader.** Reconciles the statement against
  the books, line by line. Their job is: tie every transaction to a record and confirm
  the arithmetic. They need the **running balance** to trace continuously from opening
  to closing, and clear debit/credit signing so each line categorizes correctly.

- **Lender / reviewer — tertiary reader.** Reads the statement as evidence of activity
  and standing (e.g. for a loan or audit). Their job is: assess the pattern of inflows
  and outflows over the period. They lean on the **period** and the **summary totals**
  to judge cash flow at a glance.

## Reading Context

The situations in which statements are actually read — which drive what must survive.

- Statements are reviewed **against the reader's own expectation or records**: the
  first act is comparing the closing balance to a number the reader already has in mind.
- The **first read is a balance check** — opening, closing, and "does this look right?"
  — before any line-by-line work begins.
- A **slower second read** happens only when reconciliation or a dispute is needed,
  when the reader works down the transaction lines and follows the running balance.
- Statements are frequently **multi-page and often printed** for filing or audit.
  The running balance must stay continuous across page breaks (carried/brought
  forward), and nothing essential may rely on color or interactivity.

## Layout & Typographic Conventions

The visual grammar that makes a document read as a trustworthy statement.

- **The closing balance is the single most visually prominent number** — set apart
  so the reader's balance check is answered in the first glance.
- **The account identity and statement period sit clearly near the top**, so the
  reader knows which account and which date range before reading any line.
- **Transactions render as a dated, aligned table** with **right-aligned money
  columns**, so amounts line up on the decimal point and are easy to compare and sum.
- **A running-balance column steps down the page** beside the transactions, forming a
  continuous arithmetic ladder from opening balance to closing balance.
- **Debits and credits are unambiguously distinguished** by sign and column position —
  never by color alone — so a black-and-white printout reads correctly.
- **Carried-forward / brought-forward rows mark every page break**, so a multi-page
  statement reads as one continuous ledger rather than disconnected fragments.
- **Money uses fixed 2-decimal precision** and **consistent currency-symbol placement**
  throughout, so every amount reads as money and the totals reconcile cleanly.
