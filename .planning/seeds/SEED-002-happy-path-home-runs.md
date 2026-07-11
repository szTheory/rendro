---
id: SEED-002
status: dormant
planted: 2026-07-10
planted_during: C1 (post-archive, awaiting next milestone)
trigger_when: next product/feature milestone — the "toy → production" home run for business documents
scope: Large (full milestone)
part_of: "Happy-Path Home Runs program (Milestone A of 3 — see SEED-003, SEED-004)"
---

# SEED-002: Realistic Business-Document Examples & Anatomy (Milestone A)

Turn rendro's toy examples into **production-grade, domain-true** documents using existing capability +
one small additive Invoice upgrade + two new families (Payslip, Ticket). Goal: a serious user can jump
in and adapt an award-quality, domain-correct document immediately.

**Milestone A of a 3-milestone program.** Sequenced: A (this) → **[[SEED-003]]** Document Theming &
Design-Token System → **[[SEED-004]]** Style-Genre Presets & Public Example Catalog. Full program plan:
`~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md`.

## Why This Matters

**Posture is settled — examples are the gap.** Research (2026-07-10) confirmed rendro's positioning is
crisp and heavily documented (`PROJECT.md` "Out of Scope", `EPIC.md` "Permanent Boundaries"): a
pure-Elixir, Phoenix-first, deterministic, browser-free engine for **authored business documents**
(invoices, statements, receipts, certificates, reports), organized **by document family, never by
industry vertical**. NOT a generic layout engine, NOT HTML/CSS, NOT a markdown-to-book renderer. **No
positioning gap.**

**Toy vs. production.** All getting-started paths use placeholder data ("Widget A", "Acme Corp",
"Transaction 1"). The single realistic fixture (`bench/comparison/fixtures/invoice_data.json` — real
addresses, USD, Net 30, 60 line items, cents pricing, subtotal/tax/total) is **quarantined** in the
benchmark harness. And `Rendro.Recipes.Invoice` is thinner than a real invoice: only `INVOICE #id` +
date + a 3-col table with unformatted `"$#{price}"` + "Thank you" — no addresses/terms/tax/totals, no
money formatting. (`Receipt`/`Statement` are already richer; `Rendro.Format` exists but is
`@moduledoc false`.) This is the difference between a demo and a tool people trust for serious use.

## When to Surface

**Trigger:** the next product/feature milestone (rendro is in a "done-enough / awaiting demand signal"
holding pattern after C1). Surface when the goal is adoption / "make it easy to get started seriously."
This is the FIRST milestone of the program; SEED-003 and SEED-004 trigger after it.

## Scope Estimate

**Large — a full milestone** (~7 phases, A0–A6). Only A2 touches `lib/` product code.

### Reconciliation (fan out across industries WITHOUT breaking "organized by document family")

Industries are handled as **data + thin escape-hatch compositions**, never new core modules. Core
recipes stay family-organized; only family *anatomy* (an invoice having addresses/tax/totals) is a legit
`lib/` change.

### Phase outline (Milestone A)

- **A0 — Domain research + reader-quality rubric.** Per-domain `DOMAIN.md` (domain-language glossary of
  the domain's own nouns/verbs/events; personas + JTBD — who reads it, in what lens, and the ONE fact
  they need first; reading context; conventions), co-located under `priv/examples/<domain>/`. Plus a
  **quality rubric** scoring each template 1–5 on: information architecture, content hierarchy (the key
  fact — amount due / net pay / closing balance — is the visual anchor; must score 5), least-surprise,
  reader affordances (tabular money, scan path, "Page X of Y", totals kept with last rows), typographic
  craft, domain-fit. Threshold: all ≥4, hierarchy =5. *(Foldable into A1.)*
- **A1 — Realistic example-data library.** `priv/examples/` JSON fixtures + `priv/schemas/` schema;
  fictional-business catalog; de-quarantine `invoice_data.json`; dev/test loader; repoint bench harness.
  Fixtures encode A0 domain language. No `lib/` change.
- **A2 — Invoice anatomy upgrade** *(only `lib/` product change)* — additive optional
  `:issuer`/`:customer`/`:due_date`/`:terms`/`:totals` + Decimal money + totals section keep-with-last
  rows; promote `Rendro.Format` to public adapter tier; update `public_api.json` + migration note +
  docs-contract lane; keep the toy call working.
- **A3 — New families Payslip + Ticket** — two recipes on the 3-rung pattern
  (`document/2 → page_template/1 → sections/2`) on existing primitives; register in `public_api.json` +
  `support_matrix.json`.
- **A4 — Industry demonstration set — rubric-gated** — render the matrix via recipes + escape hatch into
  `guides/recipes.md`, `guides/branding.md`, upgrade `guides/livebook/first_invoice.livemd`,
  `examples/phoenix_example`; each doc cites its `DOMAIN.md` and passes the rubric.
- **A5 — Edge-case stress matrix** — golden artifacts + raster refs (`priv/raster_refs/`) +
  errors-as-product assertions.
- **A6 — Gallery & docs closure** — expand `assets/rendro/gallery/` + `artifacts.json` via
  `mix rendro.launch_artifacts.gen` to realistic renders; reconcile `support_matrix.json`; update README.

### Family × domain matrix (named fictional businesses)

- **Invoice/BrandedInvoice:** SaaS subscription (*Nimbus Analytics*) · freelance/agency (*Marigold
  Studio*) · retail/e-commerce (*Northwind Provisions*) · pro-services w/ VAT (*Halden & Roe*).
- **Statement:** SaaS billing (*Nimbus Analytics*) · bank/fintech multi-page (*Cedar Mutual*) · AR aging
  30/60/90 (*Halden & Roe*) · health insurance EOB (*Vantage Health Plan*).
- **Receipt/Report:** POS (*Northwind Provisions*) · payment/email-attachment Stripe-style (*Nimbus
  Analytics*) · ticketing order confirmation (*Aurora Live*) · multi-page operational report 60+ rows
  (*Meridian Logistics*).
- **Certificate:** training (*Ironwood Academy*) · compliance attestation (*Sentinel Assurance*) · COI
  (*Beacon Casualty*) · award (*Aurora Live*).
- **Payslip (NEW family):** *Rivet Payroll* — earnings/deductions/net + YTD.
- **Ticket/boarding-pass (NEW family):** *Aurora Live* — small fixed-box format.

### Edge-case stress matrix (each family × dimension → deterministic hash-checked golden)

Text length/wrapping/long names · line-item count 0/1/few/page-boundary/60+ · missing optional fields ·
overflow → typed `:content_overflow` error (never silent truncation) · numeric edges ($0.00, negatives
as parens, $1M+, cents rounding, zero-qty) · currency/locale (USD vs GBP/EUR, VAT vs sales-tax labels;
engine stays locale-free) · pagination boundaries (totals kept-with rows, repeating header, "Page X of
Y", section restart) · A4 vs US Letter, odd/even running content · RTL raises instructively · single row
taller than body → typed error · byte-determinism (SHA-256).

### Locked decisions (session 2026-07-10)

- **Program split into 3 milestones** — this seed is Milestone A; theming = [[SEED-003]]; presets +
  catalog = [[SEED-004]].
- **Invoice:** upgrade anatomy *additively* + promote `Format` to public.
- **New families:** add BOTH Payslip and Ticket (user chose breadth).
- **Domain research granularity:** per-domain `DOMAIN.md`, reused across that domain's families.
- **Gallery axis:** family/domain-primary, brand-tagged.

## Breadcrumbs

- `lib/rendro/recipes/invoice.ex` — the thin recipe to upgrade (A2).
- `lib/rendro/format.ex` — money/date helper, `@moduledoc false`; promote to public (A2).
- `lib/rendro/recipes/receipt.ex`, `lib/rendro/recipes/statement.ex` — richer target pattern (Decimal
  money, `totals`, `customer`).
- `bench/comparison/fixtures/invoice_data.json` — the quarantined realistic fixture to promote into
  `priv/examples/` (A1).
- `lib/mix/tasks/rendro/launch_artifacts/gen.ex` — gallery + hash-check generator (A5–A6).
- `priv/public_api.json`, `priv/support_matrix.json` — machine-checked manifests to update.
- `guides/recipes.md`, `guides/livebook/first_invoice.livemd`,
  `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` — demo surfaces.
- Related: `.planning/research/JTBD-USER-FLOWS.md` (recommends clustering docs by user job); [[SEED-003]],
  [[SEED-004]], `SEED-001-hex-release-readiness.md`.

## Notes

Captured via `/gsd-capture` after multi-agent research + design and a locked-decisions session
(2026-07-10). Originally scoped as a single 8-phase milestone; **restructured into a 3-milestone program**
per user direction (theming + presets + catalog are each meaty enough to warrant their own milestone).
Deferred candidates NOT built (still just *data flavors* of existing families, never new recipes):
quote/estimate, credit note, packing slip, remittance advice.
