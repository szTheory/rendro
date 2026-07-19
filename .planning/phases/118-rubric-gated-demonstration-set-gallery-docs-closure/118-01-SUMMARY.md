---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
plan: 01
subsystem: example-fixtures
tags: [fixtures, schema, show-01, examples]
requires:
  - priv/schemas/examples.schema.json (invoice-only shape, generalized here)
  - lib/rendro/recipes/{statement,receipt,certificate,payslip,ticket}.ex validate_data!/1 contracts
provides:
  - Generalized per-family examples.schema.json (invoice + 5 new families)
  - 5 realistic fixtures (statement, receipt, certificate, payslip, ticket) validating against it
affects:
  - 118-03 JSON→recipe transform (consumes these fixtures as string-keyed input)
  - test/docs_contract/examples_schema_contract_test.exs (required lane — all 6 shapes green)
tech-stack:
  added: []
  patterns:
    - JSON Schema draft-2020-12 allOf + if/then family discrimination
    - money-as-decimal-strings (^-?[0-9]+\.[0-9]{2}$), never JSON floats
    - S4 optional empty brand/logo slot
key-files:
  created:
    - priv/examples/statement/northwind-ledger-co/statement.json
    - priv/examples/receipt/harbor-and-oak-cafe/receipt.json
    - priv/examples/certificate/summit-training-institute/certificate.json
    - priv/examples/payslip/aurora-live/payslip.json
    - priv/examples/ticket/aurora-live/ticket.json
  modified:
    - priv/schemas/examples.schema.json
decisions:
  - "Schema generalization used allOf + if/then (not oneOf): invoice branch keyed on the structural 'invoice' property so the original invoice fixture stays byte-identical (no 'family' field added to it); the 5 new families are keyed on a top-level 'family' const discriminator."
  - "Fictional business names (planner discretion, D-02): statement = Northwind Ledger Co, receipt = Harbor & Oak Cafe, certificate = Summit Training Institute. Payslip + Ticket = Aurora Live (D-02 lock)."
  - "Payslip Pitfall 5 reconciliation: the payslip recipe test uses employer 'Aurora Textiles Co.', but D-02 locks 'Aurora Live'. The fixture deliberately uses 'Aurora Live'."
metrics:
  duration: 3min
  completed: 2026-07-19
status: complete
---

# Phase 118 Plan 01: Rubric-Gated Demonstration Set — Data Foundation Summary

Generalized the invoice-only `examples.schema.json` into a per-family discriminated JSON Schema and authored five realistic, fictional, Decimal-string-money fixtures (statement, receipt, certificate, payslip, ticket) that validate against it, keeping the required docs-contract test lane green across all six fixture shapes.

## What Was Built

**Task 1 — Schema generalization (`priv/schemas/examples.schema.json`)**
- Added an optional top-level `family` discriminator (enum: invoice/statement/receipt/certificate/payslip/ticket).
- Replaced the top-level invoice-only `required: [fixture_id, issuer, customer, invoice, items]` with `allOf` if/then branches.
- **Invoice branch** is keyed on the structural `invoice` property (`if: {required: ["invoice"]}`) rather than the `family` field, so the original `priv/examples/invoice/acme-phoenix-saas/invoice.json` was not touched and stays byte-identical. Its full requirement set (issuer/customer/invoice/items + item shape + totals) is preserved exactly inside the branch.
- **Five new family branches** are keyed on `family` const. Each requires only its own keys, mirroring the recipe `validate_data!/1` atom-keyed contract:
  - statement: `period{from,to}` + `account{name}` + `opening_balance` + `lines[]{date,description,amount}`
  - receipt: `title` + `date` + `customer{name}` + `lines[]{description,amount}`
  - certificate: `title` + `recipient` + `date`
  - payslip: `employer{name}` + `employee{name,id,tax_code}` + `period{from,to}` + `pay_date` + `earnings[]` + `deductions[]` + `net_pay`
  - ticket: `issuer{name}` + `title` + `placement[]{label,value}` + `code{reference}`
- Kept and reused `$defs.money_string` and `$defs.party`; added `$defs.period` and `$defs.pay_lines`. All money fields reference `money_string`; all date fields use `format: date`. Top-level `additionalProperties: true` retained.

**Task 2 — statement / receipt / certificate fixtures**
- `statement/northwind-ledger-co/statement.json`: 8-line ledger of signed debits/credits; opening 3200.00 → closing 6647.56 (arithmetic reconciles).
- `receipt/harbor-and-oak-cafe/receipt.json`: cafe sales receipt; subtotal 28.50 + tax 2.28 = total 30.78.
- `certificate/summit-training-institute/certificate.json`: Certificate of Completion with fictional recipient, body, seal_line.

**Task 3 — Aurora Live payslip / ticket fixtures**
- `payslip/aurora-live/payslip.json`: employer Aurora Live; fictional employee; masked id `E-·····4821` and masked `payment_method` "Direct Deposit ···· 4321". net_pay 3292.50 = earnings 4550.00 − deductions 1257.50 (reconciles). All three totals are decimal strings.
- `ticket/aurora-live/ticket.json`: issuer Aurora Live, placement grid (Section/Row/Seat/Gate), human-readable `code.reference` `AUR-88213-GA`, no `code.image` (text-only). No money fields.

Every fixture carries `fixture_id`, the `family` discriminator, and the optional empty S4 slot `"brand": {"logo": null}`.

## Verification

- `mix test test/docs_contract/examples_schema_contract_test.exs` — 3 tests, 0 failures (invoice + 5 new shapes all validate).
- `mix test test/docs_contract/` — 271 tests + 1 doctest, 0 failures (no regression in the docs-contract lane).
- No JSON-float money anywhere: `grep -nE ':[[:space:]]*[0-9]+\.[0-9]+[^"]'` over all new fixtures returns nothing (money is quoted strings).
- No `code.image` in the ticket fixture (text-only milestone constraint held).
- `grep -c '"family"' priv/schemas/examples.schema.json` = 11 (≥1); `money_string`/`party` still present and referenced.

## Decisions Made

1. **Schema construct: allOf + if/then, invoice keyed on structural `invoice` key.** Chosen over `oneOf` and over adding a `family` field to the existing invoice fixture, because the plan explicitly warns against perturbing the invoice fixture's recorded byte-identity. Keying the invoice branch on the presence of the `invoice` property leaves the original fixture untouched while cleanly discriminating the five new families on their `family` const.
2. **Fictional business names (D-02 + planner discretion):** Northwind Ledger Co (statement), Harbor & Oak Cafe (receipt), Summit Training Institute (certificate), Aurora Live (payslip + ticket).
3. **Payslip "Aurora Live" reconciliation (Pitfall 5):** the payslip recipe test uses `"Aurora Textiles Co."`, but D-02 locks `"Aurora Live"`. The fixture deliberately uses `"Aurora Live"` to honor the D-02 lock; the recipe test's differing name is a test-only concern and was left unchanged.

## Deviations from Plan

None — plan executed exactly as written. No auto-fixes (Rules 1-3) were needed; each task's verification passed on first run.

## No-PII / Threat Notes (T-118-01)

- Payslip employee (`Jordan Vega`), employer, address, and tax_code are invented; the employee id and payment_method are masked with the recipe's middot token (only trailing digits shown) — no full account/card number anywhere.
- All businesses, people, and references across the five fixtures are fictional. No real addresses or tax IDs.

## Self-Check: PASSED

- FOUND: priv/schemas/examples.schema.json (generalized)
- FOUND: priv/examples/statement/northwind-ledger-co/statement.json
- FOUND: priv/examples/receipt/harbor-and-oak-cafe/receipt.json
- FOUND: priv/examples/certificate/summit-training-institute/certificate.json
- FOUND: priv/examples/payslip/aurora-live/payslip.json
- FOUND: priv/examples/ticket/aurora-live/ticket.json
- FOUND commit a5b753d (schema), 02f9ad4 (statement/receipt/certificate), 75898a4 (payslip/ticket)
