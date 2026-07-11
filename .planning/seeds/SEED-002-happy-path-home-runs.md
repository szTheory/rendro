---
id: SEED-002
status: dormant
planted: 2026-07-10
planted_during: C1 (post-archive, awaiting next milestone)
trigger_when: next product/feature milestone — when choosing what to build after C1 infra hardening
scope: Large (full milestone)
---

# SEED-002: Happy-Path Home Runs & Realistic Example Library

Make rendro's business-document happy paths *shine* with vetted, realistic layout examples
(not toy data), upgrade the thin Invoice recipe to real invoice anatomy, and add two new
document families (Payslip, Ticket). Goal: a serious user can jump in and adapt a
production-quality document immediately.

Full plan: `~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md`

## Why This Matters

**Posture is NOT the problem — examples are.** Research (3 parallel Explore agents, 2026-07-10)
confirmed rendro's positioning is already crisp and heavily documented (`PROJECT.md` "Out of
Scope", `EPIC.md` "Permanent Boundaries"): a pure-Elixir, Phoenix-first, deterministic,
browser-free engine for **authored business documents** (invoices, statements, receipts,
certificates, reports), organized **by document family, never by industry vertical**. It is
explicitly NOT a generic layout engine, NOT HTML/CSS, NOT a markdown-to-book renderer. There is
**no positioning gap**.

**The real gap = toy vs. production.** Every getting-started path stops at placeholder data
("Widget A", "Acme Corp", "Transaction 1"). The single realistic fixture
(`bench/comparison/fixtures/invoice_data.json` — real addresses, USD, Net 30, 60 line items,
cents pricing, subtotal/tax/total) is **quarantined** in the benchmark harness, wired into no
recipe/guide/gallery. Worse, `Rendro.Recipes.Invoice` is structurally *thinner than a real
invoice*: only `INVOICE #id` + a date + a 3-col table with unformatted `"$#{price}"` + "Thank
you" — no addresses, terms, tax, totals, or money formatting. (`Receipt`/`Statement` are already
richer with Decimal money + totals; `Rendro.Format` exists but is `@moduledoc false`.) This is
the difference between a demo and a tool people trust for serious use.

## When to Surface

**Trigger:** The next product/feature milestone (rendro is currently in a "done-enough / awaiting
demand signal" holding pattern after C1 infra hardening). Surface this when deciding what to build
next, especially if the goal is adoption / "make it easy to get started seriously."

This seed will surface automatically during `/gsd-new-milestone` when scope matches examples,
recipes, invoicing, gallery, onboarding, or document breadth.

## Scope Estimate

**Large — a full milestone** (~6 phases). Only Phase 2 + 3 touch `lib/`; the rest is data,
guides, gallery, and stress-test goldens.

### Reconciliation (fan out across industries WITHOUT breaking "organized by document family")

Three layers keep this inside the documented boundaries:
1. **Core recipes (`lib/`)** stay family-organized. Industry is *data*, never a module. A "SaaS
   invoice" and a "VAT invoice" are the same `Invoice` recipe with different data. Only family
   *anatomy* (an invoice having addresses/tax/totals) is a legitimate `lib/` change.
2. **Demonstration content** (guides, livebook, gallery, example app) is where *industry* lives —
   realistic data + small escape-hatch (`sections/2`) compositions.
3. **Shared realistic-data catalog** (`priv/examples/` JSON) drives layers 1–2 and the stress
   tests deterministically.

### Document-family × industry matrix (named fictional businesses)

- **Invoice/BrandedInvoice:** SaaS subscription (*Nimbus Analytics*) · freelance/agency
  (*Marigold Studio*) · retail/e-commerce (*Northwind Provisions*) · pro-services w/ VAT
  (*Halden & Roe*, hosts quote/credit-note flavors).
- **Statement:** SaaS billing (*Nimbus Analytics*) · bank/fintech multi-page (*Cedar Mutual*) ·
  AR aging 30/60/90 (*Halden & Roe*) · health insurance EOB (*Vantage Health Plan*).
- **Receipt/Report:** POS (*Northwind Provisions*) · payment/email-attachment Stripe-style
  (*Nimbus Analytics*) · ticketing order confirmation (*Aurora Live*) · multi-page operational
  report 60+ rows (*Meridian Logistics*).
- **Certificate:** training (*Ironwood Academy*) · compliance attestation (*Sentinel Assurance*) ·
  COI (*Beacon Casualty*) · award (*Aurora Live*).
- **Payslip (NEW family):** *Rivet Payroll* — earnings/deductions/net + YTD.
- **Ticket/boarding-pass (NEW family):** *Aurora Live* — small fixed-box format.

### Edge-case stress matrix (each family × dimension → deterministic hash-checked golden)

Text length/wrapping/long names · line-item count 0/1/few/page-boundary/60+ · missing optional
fields · overflow → typed `:content_overflow` error (never silent truncation) · numeric edges
($0.00, negatives as parens, $1M+, cents rounding, zero-qty) · currency/locale (USD vs GBP/EUR,
VAT vs sales-tax labels; engine stays locale-free) · pagination boundaries (totals kept-with last
rows, repeating header, "Page X of Y", section restart) · A4 vs US Letter, odd/even running
content · RTL raises instructively · single row taller than body → typed error · byte-determinism
(SHA-256, like `assets/rendro/artifacts.json`).

### Phase outline

1. **Realistic example-data library** — de-quarantine `invoice_data.json`; `priv/examples/` JSON +
   `priv/schemas/` schema; fictional-business catalog; dev/test loader; repoint bench harness. No
   `lib/` change.
2. **Invoice anatomy upgrade** *(only `lib/` product change)* — additive optional
   `:issuer`/`:customer`/`:due_date`/`:terms`/`:totals` + Decimal money + totals section
   keep-with-last-rows; promote `Rendro.Format` to public adapter tier; update `priv/public_api.json`
   + migration note + docs-contract lane; keep toy call working.
3. **New families Payslip + Ticket** — two recipes on the 3-rung pattern
   (`document/2 → page_template/1 → sections/2`) on existing primitives; register in
   `public_api.json` + `support_matrix.json`.
4. **Industry demonstration set** — render the matrix via recipes + escape hatch into
   `guides/recipes.md`, `guides/branding.md`, upgrade `guides/livebook/first_invoice.livemd`,
   `examples/phoenix_example` controllers.
5. **Edge-case stress matrix** — golden artifacts + raster refs (`priv/raster_refs/`) +
   errors-as-product assertions.
6. **Gallery & docs closure** — expand `assets/rendro/gallery/` + `artifacts.json` via
   `mix rendro.launch_artifacts.gen` to realistic renders; reconcile `support_matrix.json`; update
   `README.md` (family-primary, industry-tagged gallery).
7. **Document theming / palette system** *(NEW — added ad hoc; enables Phase 8; a real `lib/`
   capability, not demo)* — a first-class PDF **theme/palette** primitive (colors as `{r,g,b}`,
   likely mined from `brand/tokens/tokens.json`) with recipe plumbing to accept a `theme:` (colors)
   alongside today's `brand:` (font+logo). Ships: (a) a named **unbranded/default** theme (restrained
   grayscale/ink that still looks strong — NOT everything-is-blue); (b) a **light** + **dark** variant
   convention (full-page background fill via `Rendro.Path {:rect}` + inverted text colors); (c) 2–3
   example brand presets with strong typography+color. Register in `public_api.json` + `support_matrix.json`.
8. **Public example catalog (marketing-site) + quality ratchet** *(NEW — added ad hoc)* — generate the
   catalog (see below): every family × domain × {2–3 brands} × {light, dark} + unbranded default, as
   deterministic hash-checked artifacts; doubles as a standing visual quality-bar baseline.

### Public example catalog + light/dark + unbranded default (added ad hoc, session 2026-07-10)

**The idea (user):** a curated catalog of all example documents on the public/"marketing" website,
organized **by domain**, where each document type is shown across **2–3 example brands** and in **both
light and dark mode**, plus a strong **unbranded default** (grayscale/ink, not blue/purple). Purpose:
demonstrate out-of-the-box quality + brandability + light/dark robustness ("you get all this out of the
box"), AND act as a **standing quality-bar stress test** — the user reviews the whole grid to hold a high
bar, uses it as a baseline, and *ratchets* it so every layout eventually "oozes quality" (given strong
example-brand typography/colors), including the unbranded default, which must look great on its own.

**⚠️ Surfaced dependency — bigger than a website page.** Rendro has **no document color-theming system
today.** The B1 "Brand System" milestone built the *project's own website brand* (top-level `brand/` dir
with `tokens.json` + light/dark CSS/Tailwind tokens) that is **excluded from the Hex package** — not
runtime PDF code. In the library, recipe brand injection is **font + logo only, no colors**
(`Rendro.Recipes.BrandedInvoice` takes `brand: %{font_name, logo_name}` atoms wired to hardcoded demo
assets; plain `Invoice` has no color/theme knob). "Unbranded" is only an ad-hoc "omit `data.brand`"
convention (`Certificate`). So **light/dark PDFs + multi-brand palettes are new `lib/` capability**
(Phase 7), not just catalog wiring. Primitives to build on exist — `Rendro.Path {:rect}` + fill renders a
full-page dark background (`lib/rendro/pdf/writer.ex` ~1936), `Rendro.Text.color`/`Rendro.Path` carry
per-element `{r,g,b}`, and `brand/tokens/tokens.json` has light+dark semantic role maps + `night-*` dark
scale to mine — but nothing *composes* them into a theme.

**Open decision for milestone-planning time (captured, not blocking):** Phases 7–8 roughly double the
`lib/` surface and are arguably their own concern. At planning time decide: (A) fold Phases 7–8 into this
milestone, or (B) keep this milestone to realistic-examples/anatomy/new-families (Phases 1–6) and spin
theming + public catalog into a dedicated follow-on milestone (recommended if the theming design needs its
own discovery). The catalog's ratchet value only materializes once unbranded-default + light/dark + a
couple brand presets exist.

### Locked decisions (session 2026-07-10)

- **Deliverable:** capture this seed + scope the full milestone outline now.
- **Invoice:** upgrade anatomy *additively* + promote `Format` to public.
- **New families:** add BOTH Payslip and Ticket (user chose breadth over minimal-surface).
- **Gallery axis:** family-primary, industry-tagged.

## Breadcrumbs

- `lib/rendro/recipes/invoice.ex` — the thin recipe to upgrade (Phase 2).
- `lib/rendro/format.ex` — money/date helper, `@moduledoc false`; promote to public (Phase 2).
- `lib/rendro/recipes/receipt.ex`, `lib/rendro/recipes/statement.ex` — richer target pattern to
  follow (Decimal money, `totals`, `customer`).
- `bench/comparison/fixtures/invoice_data.json` — the quarantined realistic fixture to promote
  into `priv/examples/` (Phase 1).
- `lib/mix/tasks/rendro/launch_artifacts/gen.ex` — gallery + hash-check generator (Phases 5–6, 8).
- `priv/public_api.json`, `priv/support_matrix.json` — machine-checked manifests to update.
- `lib/rendro/recipes/branded_invoice.ex`, `lib/rendro/recipes/certificate.ex` — current brand injection
  (font+logo only) + the "optional/unbranded" convention; the seam Phase 7 theming extends.
- `lib/rendro/color.ex`, `lib/rendro/path.ex`, `lib/rendro/text.ex`, `lib/rendro/pdf/writer.ex` (~1936) —
  `{r,g,b}` color + `{:rect}` full-page background-fill primitives a theme/dark-mode layer composes (Phase 7).
- `brand/tokens/tokens.json` — web-only light/dark token source to mine for `{r,g,b}` theme values
  (currently excluded from the Hex package; Phase 7).
- `guides/recipes.md`, `guides/livebook/first_invoice.livemd`,
  `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` — demo surfaces.
- Related: `.planning/research/JTBD-USER-FLOWS.md` (recommends clustering docs by user job);
  `SEED-001-hex-release-readiness.md`.

## Notes

Captured via `/gsd-capture` after a 3-agent research + 1-agent design pass and a locked-decisions
session (2026-07-10). Fully enriched at capture time. Deferred candidates NOT built this
milestone but worth noting: additional invoice flavors (quote/estimate, credit note, packing
slip, remittance advice) remain *data flavors* of existing families, never new recipes.
