# Payslip — Domain Anatomy

Domain-research notes for the payslip example family. This document captures the
language, readers, reading situations, and layout conventions that a faithful
payslip must honor. It is cited by rubric-scored demos (SHOW-01) so that scoring
is anchored to how payslips are actually read and used — not to generic
document-formatting taste.

## Domain Language

The vocabulary a reader expects a payslip to speak. Missing or renamed terms
make a document read as "not really a payslip."

**Nouns (the things on the page)**

- **Payslip / pay stub** — the document itself; a statement of what an employee was
  paid for a period and how that figure was arrived at.
- **Employer** — the party paying the wage and issuing the payslip.
- **Employee** — the person being paid; identified by name, an ID, and a tax code.
- **Pay period** — the date range (from–to) the pay covers.
- **Pay date** — the date the money is or was paid.
- **Earnings** — the gross components of pay: base salary, bonus, overtime, each a line.
- **Deductions** — the amounts withheld: income tax, national insurance / social
  contributions, pension, each a line.
- **Gross pay** — total earnings before any deductions.
- **Net pay** — the take-home amount after deductions. The headline number.
- **Year-to-date (YTD)** — the cumulative total for each line across the tax year so far.
- **Tax code** — the identifier governing how much tax is withheld.
- **Payment method** — how net pay is delivered (e.g. direct deposit), often masked.

**Verbs and events (the lifecycle)**

- **Earn / accrue** — the employee works and accrues gross pay over the period.
- **Deduct / withhold** — statutory and voluntary amounts are subtracted from gross.
- **Pay / disburse** — net pay is transferred to the employee.
- **Accumulate** — each line's year-to-date figure grows across the tax year.
- **Reconcile** — the employee or accountant checks net pay equals gross minus deductions.

## Personas & Jobs-to-be-Done

Who reads a payslip, why, and — critically — the ONE fact each reader needs first.

- **Employee — primary reader.** Opens the payslip on pay day to confirm they were paid
  correctly. Their job is: check my take-home. The ONE fact they need first is **net
  pay** — the number that hits their account. Earnings and deductions are read only if
  net pay differs from what they expected.

- **Payroll / HR administrator — secondary reader.** Reviews payslips for correctness
  before or after a run. Their job is: confirm the arithmetic and the withholdings are
  right. They need **gross**, each **deduction line**, and **net** to tie out exactly
  (net = gross − deductions), plus the **tax code** and period to be correct.

- **Lender / auditor — tertiary reader.** Reads the payslip as proof of income. Their
  job is: assess earnings over time. They lean on **net pay**, **gross**, and the
  **year-to-date** figures to judge income stability across the tax year.

## Reading Context

The situations in which payslips are actually read — which drive what must survive.

- The **first read is a net-pay check on pay day** — the employee confirms the take-home
  figure matches expectation before reading anything else.
- Payslips are **filed and retrieved as proof of income** months later (for loans,
  tenancy, tax), so they must be self-explanatory and legible long after issuance.
- A **detailed second read** happens when net pay looks wrong or during a pay query,
  when the reader works through each earnings and deduction line and checks the YTD.
- Payslips contain **sensitive personal and financial data** and are frequently printed;
  identifiers are masked, and nothing essential may rely on color or interactivity.

## Layout & Typographic Conventions

The visual grammar that makes a document read as a trustworthy payslip.

- **Net pay is the single most visually prominent number on the page** — set apart,
  typically in a tinted band directly under the identity header, so the take-home figure
  is found in the first glance.
- **The employer and employee identity sit clearly at the top**, with the pay period and
  pay date, so the payslip is unambiguous about who, when, and for what.
- **Earnings and deductions render as two aligned tables** with **right-aligned money
  columns**, so amounts line up on the decimal point and gross and deductions are easy
  to sum and compare.
- **A year-to-date column runs beside the period column**, so each line shows both this
  period and the running annual total without confusion between them.
- **Gross, total deductions, and net form a short arithmetic ladder**, visually stepping
  from gross down through deductions to the headline net figure.
- **Statutory line labels are plain descriptive text** (e.g. "Income Tax (PAYE)"), so the
  payslip reads correctly in any jurisdiction without a fixed regional vocabulary.
- **Money uses fixed 2-decimal precision** and **consistent currency-symbol placement**,
  so every amount reads as money and net reconciles cleanly against gross minus deductions.
