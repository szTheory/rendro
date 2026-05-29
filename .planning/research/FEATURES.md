# Feature Research

**Domain:** PDF document generation — page-numbering/running-region primitive + Statement, Receipt/Report, Certificate recipes
**Researched:** 2026-05-29
**Confidence:** HIGH (page-numbering mechanics verified across ReportLab, fpdf2, Prawn, wkhtmltopdf; document field structures verified against industry templates and accounting standards)

---

## Context: Existing Capabilities This Research Builds On

Before mapping table-stakes vs differentiators, note what Rendro already ships — these are NOT features to build in v2.4:

- Named page-template regions (`:header`, `:body`, `:footer`, `:logo` + custom via `role: :custom`)
- Deterministic wrapped text + pagination with keep/break semantics
- Table continuation across page breaks
- Fixed-coordinate positioning (`Rendro.fixed/2`)
- Flow authoring (`Rendro.flow/2`)
- Three-rung recipe escape hatch (`document/2`, `page_template/1`, `sections/2`)
- Font registration and image asset registration
- Section-to-region mapping

The v2.4 work sits on top of this foundation. Page numbering is a new primitive that unlocks the new recipes. Existing recipe shape (Invoice, BrandedInvoice) shows the convention to match.

---

## Category 1: Page Numbering / Running Header-Footer Primitive

### The Core Technical Problem: Total Page Count Resolution

This is the hardest behavior in the category. "Page X of Y" requires knowing Y before writing page X. Every mature engine resolves this differently:

| Engine | Strategy | Mechanism |
|--------|----------|-----------|
| fpdf2 | Deferred string substitution | `{nb}` placeholder in footer text; replaced at document close with the final page count via `alias_nb_pages()`. Single-pass — placeholder is a string that gets substituted after all pages are generated. |
| ReportLab | Deferred canvas accumulation | Custom canvas subclass accumulates page codes in memory on `showPage()`, patches page numbers at final `save()`. Single-pass; total count is known at save time because no bytes have yet been emitted. |
| Prawn | Post-render stamp | `number_pages` called at end of document block; stamps `<total>` placeholder after all pages are already composed; `start_count_at` + `total_pages` override allow section restarts. |
| wkhtmltopdf | HTML variable injection | `[page]` / `[topage]` variables injected into footer HTML via query-string params before page render. Browser engine does the substitution. |
| LaTeX/fancyhdr | Two-pass TeX compilation | First pass writes `.aux` file with final page count; second pass substitutes `\pageref{LastPage}`. The canonical academic two-pass model — the only approach here that truly renders twice. |

**For Rendro's deterministic pipeline, the right approach is single-pass deferred injection.** The `paginate` stage already knows the total page count after it completes — it has laid out all pages. Before the `render` stage executes, the total is available. Region content that needs `{current_page, total_pages}` must be defined as a parameterized value (an arity-1 function over `{page, total}` rather than a static content list) so the render stage can call it per-page with the resolved values. No second render pass is needed.

This is the architecturally load-bearing decision for v2.4. Regions today accept static block lists. Page numbering requires regions (specifically footer/header regions) to accept a content function, not just static content. This is new authoring-primitive territory.

**What NOT to do:**
- Two-pass full rendering — wasteful and complicates the determinism story
- Resolving page count inside the PDF writer — couples content decisions to serialization code
- Storing page count in the authored `%Rendro.Document{}` struct — it is a pagination output, not an authored input
- Making `{nb}` a magic string inside text blocks — this leaks rendering concerns into authored content and is fragile to composition

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Existing Rendro Dependency |
|---------|--------------|------------|---------------------------|
| "Page X of Y" in footer region | Universal business document convention. Any statement, report, or multi-page certificate without it feels unprofessional. | MEDIUM — requires deferred total-count resolution; region content must accept a function over `{page, total_pages}` | Named regions (existing) + paginator page-count output (new exposure) |
| Repeated static content in header region per page (document title, account number, company name) | Users expect headers to repeat identically on every page, like a letterhead; this is the definition of a "running header" | LOW — regions already repeat per page by design; the primitive needs to confirm and document this behavior is intentional and tested | Named page-template regions (existing) |
| Current page number alone ("Page X") without total | Needed when total page count is unknowable at authoring time or undesirable (e.g., a certificate showing "Page 1") | LOW — subset of the `{page, total}` function approach | Same as "Page X of Y" |
| Footer/header suppress on specific pages (suppress on first page, suppress on last page) | Statement cover pages and single-page receipts need a clean first page without a footer number; compliance certificates always single-page | LOW — conditional rendering based on page index | Paginator provides current page index |

### Differentiators (Above What Users Expect)

| Feature | Value Proposition | Complexity | Existing Rendro Dependency |
|---------|-------------------|------------|---------------------------|
| Carried-forward running totals across page breaks (e.g. "Balance Carried Forward: $X") | Multi-page statements require the closing balance at page N's break to appear as "Balance Brought Forward" at the top of page N+1. This is standard accounting form, not optional for a real statement. | HIGH — requires accumulated numeric state per page-break point. The paginator must expose a hook where the author supplies a running-total function called at each page-break boundary, producing per-page derived values before render. This is new engine behavior. | Table continuation (existing) + new paginator page-break hook |
| "Continued" marker on table split (cross-page) | Table continuation already works structurally; surfacing a "(Continued)" label as a built-in option makes recipe output match user expectation without escape-hatching | LOW — optional decoration label on the existing table continuation mechanism | Existing table continuation |
| Even/odd header content variants | Duplex/book-style documents need mirrored headers (chapter title on left page, section title on right page). Needed for formal compliance reports that will be printed. | MEDIUM — page-parity flag exposed to region content function | Named regions + page index |
| Section-local page number restart | Formal multi-section documents (appendix restarts at A-1) need independent counters per section | MEDIUM — page counter scoped to a document-section definition | Pagination section structure |

### Anti-Features

| Feature | Why Requested | Why It Violates Rendro's Design Bias | Alternative |
|---------|---------------|--------------------------------------|-------------|
| Arbitrary JavaScript/CSS in running regions | wkhtmltopdf and Puppeteer users expect this; browser-based PDF tools expose it as the mechanism | Rendro is deterministic and browser-free; JS/CSS evaluation requires a browser runtime dependency — directly contradicts the core constraint in PROJECT.md | Use parameterized Elixir functions in region content; caller owns all logic |
| Table of contents (TOC) with page numbers | Natural extension of page numbering — if we have page numbers, TOC seems like a short step | TOC requires forward-reference resolution at authoring time: the page number of a section header is unknown until pagination completes, and TOC itself may paginate differently when inserted. This is a multi-pass layout concern that expands the surface to a document-management system. | Defer; TOC is a separate, larger primitive — not v2.4 scope |
| Named section anchors / page-reference cross-links | LaTeX `\ref` analogs; "see page X" cross-references | Same forward-reference problem as TOC with added author-visible anchor DSL | Out of scope for v2.4 |
| Magic string substitution in text blocks (e.g. `"Page {{page}} of {{total}}"` as a raw string) | Simpler authoring API than a function | String interpolation at render time leaks rendering concerns into authored content, creates an implicit mini-template language, and is harder to test than plain functions | Use a clear function-based region content API |
| Dynamic header content resolved from DB/HTTP at render time | Some teams want fresh data (current stock price, live timestamp) in every page header | Breaks determinism guarantee. The caller owns all data resolution before document authoring begins. | Caller pre-resolves all data and passes to `document/2`; render stays pure |

---

## Category 2: Statement Recipe

### What a Statement Is

A statement of account summarizes all transactions between a vendor and a customer over a defined period. Unlike an invoice (a single billing event), a statement covers a time range and carries a running balance. It is the multi-page business document most likely to span several pages and most in need of the carried-forward totals primitive from Category 1.

### Data Structure (Verified Against Industry Templates and Accounting Standards)

**Account summary / header block (page 1 top, then repeats in running header):**
- Vendor name + address
- Customer name + address
- Statement period (from date → to date)
- Statement issue date
- Account number / reference ID

**Opening summary panel (page 1 only):**
- Opening balance (balance brought forward from prior period — "B/F")
- Total invoiced this period
- Total paid this period
- Closing balance / balance due

**Transaction line table (the paginating body section):**
- Date
- Reference / invoice number
- Description (e.g., "Invoice", "Payment", "Credit", "Adjustment")
- Charge amount (debit column)
- Payment/credit amount (credit column)
- Running balance (balance after each line)

**Multi-page continuation lines (at page breaks):**
- End of each non-final page: "Balance Carried Forward: $X" (total balance at the page break, accounting "C/F")
- Start of each continuation page: "Balance Brought Forward: $X" (same value, accounting "B/F")

**Footer (every page):**
- "Page X of Y"
- Optional: payment terms / due date reminder, contact information

**Closing summary (last page only):**
- Aging summary (optional but common): current / 30 days overdue / 60 days / 90+ days buckets
- Total amount due (prominently displayed)
- Payment instructions / remittance section

### Table Stakes

| Feature | Why Expected | Complexity | Existing Rendro Dependency |
|---------|--------------|------------|---------------------------|
| Statement period + account number in header | Every real statement has this; users orient immediately from the period label | LOW | Named regions (existing) |
| Opening balance line in summary panel | Standard accounting form; missing it makes the statement financially ambiguous | LOW | Static section content |
| Transaction line table: date, reference, description, debit, credit, balance | Core content of a statement — this IS the statement | MEDIUM | Table with continuation (existing) |
| Running balance column (balance after each transaction line) | Enables the user to trace their position at each event; without it the statement is just a list of charges | LOW — computed by caller as part of data preparation | Table primitive (existing) |
| "Page X of Y" footer | Table-stakes for any multi-page document; statements are always potentially multi-page | MEDIUM | Page numbering primitive (Category 1) |
| Balance Carried Forward / Brought Forward at page breaks | Without this, multi-page statements are financially ambiguous across the break | HIGH | Carried-forward running totals (Category 1 differentiator) |
| Closing balance summary on final page | Required on every real statement; this is what the recipient acts on | LOW | Static section content |

### Differentiators

| Feature | Value Proposition | Complexity | Existing Rendro Dependency |
|---------|-------------------|------------|---------------------------|
| Aging summary panel on final page (current/30/60/90+ day buckets) | Common on B2B statements; useful for collections-workflow teams; caller pre-computes the buckets | LOW — data-driven table, caller provides bucketed values | Table primitive (existing) |
| Zero-balance guard in `document/2` (raise or return `{:error, :zero_balance}` when no transactions) | Prevents empty statement generation; common billing-platform guard | LOW — guard clause in `document/2` at data validation | None |
| Optional payment remittance section on last page (tear-off style) | Professional B2B statements include a remittance stub the customer returns with their check | LOW — optional section, caller opts in via data flag | Named regions, static content |

### Anti-Features

| Feature | Why Requested | Why It Violates Rendro's Design Bias | Alternative |
|---------|---------------|--------------------------------------|-------------|
| Multi-currency display with live FX conversion | Global billing platforms want it; feels like it belongs in the billing document | FX conversion is business logic, not rendering logic; pulling HTTP/DB into a recipe would break determinism and pure-Elixir portability | Caller converts all values to display currency before passing data to `document/2` |
| Statement email delivery logic (send via Mailglass/SMTP) | Natural next step after generating the statement | Out of scope for a rendering library; Rendro has an existing delivery seam via `render_to_artifact/2` + Oban + Mailglass | Use existing delivery adapters as documented |
| Arbitrary column configuration DSL in `document/2` (reorder columns, add custom fields without escape-hatching) | Ops engineers want flexible column config | Turns the recipe into a report builder; breaks the three-rung simplicity and widens the `document/2` API surface unpredictably | Use the `sections/2` escape hatch to replace the transaction table with a custom one |
| Payment portal deep-link QR code baked into recipe | Marketing request from billing teams; "every statement should link to the portal" | Dynamic URLs are caller-injected data, not a recipe primitive; baking URL generation into the recipe couples it to a specific SaaS topology | Caller passes `data.payment_url`; recipe renders it as a plain text field or link annotation via the existing links surface |
| Reconciliation logic (match debits to credits, flag unmatched items) | Accounts payable teams want it | Data transformation, not rendering; the recipe must not own business logic | Caller pre-reconciles; recipe renders the result |

---

## Category 3: Receipt / Report Recipe

### What a Receipt Is vs What a Report Is

These are structurally related but different documents:

**Payment Receipt**: Single-event document proving a specific payment was received. Almost always one page (rarely two). Documents who paid, to whom, for what, how much, by what method, with what reference. The defining characteristic is that it confirms a completed transaction.

**Operational Report**: Multi-page tabular document summarizing a set of records with subtotals and a grand total. Examples: monthly transaction report, expense report, sales report, dispatch log. Needs column headers that repeat, grouping by key fields, subtotals, grand total, optional summary section. The defining characteristic is that it presents a set of events for review.

A single recipe can serve both: structure it around the Report shape, where a receipt is a minimal single-page report with payment-specific fields. This matches the three-rung escape-hatch pattern — full `document/2` defaults to receipt shape, caller uses escape hatches for richer report layout.

### Receipt Field Structure (Verified Against IRS and Industry Standards)

**Header:**
- Document title ("Receipt" or "Payment Receipt")
- Receipt number (unique identifier)
- Date (and optionally time)

**Issuer + Payer block:**
- Vendor/issuer name, address, contact
- Payer name (and optionally address)

**Line items:**
- Description of goods/services
- Quantity, unit price, subtotal per line
- Subtotal, tax, total

**Payment block:**
- Total amount paid
- Payment method (cash / check number / bank transfer reference / last 4 of card)
- Transaction reference number (for electronic payments)

**Footer:**
- "Paid in Full" confirmation / thank-you note
- Optional: return policy, terms

### Operational Report Field Structure

**Header (repeats every page via running-region primitive):**
- Report title and date range
- Filter/criteria description ("All departments", "Region: West", etc.)
- "Page X of Y"

**Optional group headers (when data is grouped):**
- Group label (e.g., "Department: Engineering")
- Group subtotal row at bottom of each group

**Data rows:**
- Column-keyed values (caller defines columns via data structure)
- Table continues across page breaks

**Summary section (last page only):**
- Grand total row
- Optional: count, average, min/max for numeric columns
- Run timestamp (when the report was generated — shows freshness)

**Footer (every page):**
- "Page X of Y"
- Optional: confidentiality / classification notice

### Table Stakes

| Feature | Why Expected | Complexity | Existing Rendro Dependency |
|---------|--------------|------------|---------------------------|
| Receipt number + date + payer + payee header block | Non-negotiable for any receipt; without a receipt number it cannot be referenced | LOW | Named regions (existing) |
| Itemized line items with per-line subtotals and a total | Users expect to see what was paid for and how much; the IRS requires itemization | MEDIUM | Table primitive (existing) |
| Payment method and transaction reference | Required by IRS and standard receipt norms; needed for expense reimbursement | LOW | Static section content |
| "Paid" / total amount paid confirmation block | The core purpose of a receipt: confirming payment received | LOW | Static section content |
| Multi-page report: column header repeating on each page + "Page X of Y" | Reports that span multiple pages must orient the reader on every page | MEDIUM | Running regions primitive (Category 1) + table continuation (existing) |
| Grand total row on final page | Every report needs a bottom line; without it the report is just a log | LOW | Static section at end of table |

### Differentiators

| Feature | Value Proposition | Complexity | Existing Rendro Dependency |
|---------|-------------------|------------|---------------------------|
| Group subtotals with a pre-grouped data shape | Grouped operational reports (by department, category, date range) are very common; if the caller pre-groups, the recipe renders group headers + subtotals naturally | MEDIUM — recipe accepts grouped data shape (list of `{group_key, [rows]}`) and renders a header row between groups | Table primitive (existing) |
| Run timestamp in footer | Shows report freshness; standard in BI/reporting outputs | LOW | Footer region content |
| "Continued" marker on table splits | Polished multi-page reports show "(Continued)" on continuation page table headers | LOW | Existing table continuation + optional label |

### Anti-Features

| Feature | Why Requested | Why It Violates Rendro's Design Bias | Alternative |
|---------|---------------|--------------------------------------|-------------|
| Dynamic grouping/aggregation engine inside recipe | Report builders do grouping; engineers want the recipe to accept a flat list and group automatically | This is data transformation, not rendering; coupling Ecto/Enum aggregation to a recipe creates a dependency on data-layer semantics the recipe cannot own safely | Caller pre-groups using Ecto/Enum/Stream; recipe renders the already-grouped structure |
| Chart/graph rendering in report body | Reports often include charts; bar charts of monthly totals are common | Charts require SVG/Canvas drawing primitives not in Rendro's current pipeline; adding them in a recipe would add a major unproven rendering surface | Out of scope for v2.4; flag as potential conditional v2.5+ feature if demand justifies investment |
| Configurable column order/visibility DSL in `document/2` | Ops engineers want per-report column configuration without escape-hatching | Turns the recipe into a report-builder tool; widens the API surface unpredictably | Use `sections/2` escape hatch to replace the data table with a custom-configured one |
| "PAID" / "DRAFT" / "CONFIDENTIAL" watermark baked into recipe | Common on financial documents; teams expect it | Watermarks can already be implemented with fixed-position text blocks; no new recipe-level primitive is needed | Caller injects a fixed-position text block with appropriate opacity/color via `sections/2` override |

---

## Category 4: Certificate Recipe

### What a Certificate Is

A completion or compliance certificate is almost always:
- **Single page** (occasionally a second page for terms)
- **Fixed-coordinate layout** — the aesthetic identity requires precise placement; it cannot flow without destroying the design
- **Branded prominently** — logo, border/frame, typography are defining visual elements
- **Centered on the recipient name** — the largest single text element on the page
- **Signed / sealed** — one or two signature lines, optional seal/stamp image, optional QR code for external verification

The certificate maps naturally to Rendro's `Rendro.fixed/2` authoring path and fixed-anchor region support, which already ships.

### Field Structure (Verified Against Industry and Compliance Certificate Standards)

**Top band (issuer identity):**
- Issuer logo / seal image (centered or left-aligned)
- Issuer name (beneath or alongside logo)

**Title block (center-upper portion of page, large type):**
- Document title ("Certificate of Completion", "Certificate of Compliance", "Certificate of Achievement")

**Recipient block (the hero element — visually dominant):**
- "Presented to:" or "This certifies that:" label
- Recipient name (largest text element on the page, typically 24–36pt)
- Optional: recipient title/role

**Achievement block:**
- Course / program / standard title
- Brief achievement statement ("has successfully completed...", "has satisfactorily met the requirements of...")
- Completion date

**Verification block:**
- Certificate ID (unique, for external verification lookup)
- Issue date
- Optional: expiry date (compliance certs and first-aid certs expire)
- Optional: QR code image pointing to verification URL (caller provides QR as a registered image asset)

**Authorization block (bottom of page):**
- One or two signature lines (horizontal rule + printed name + title beneath)
- Optional: organizational seal image

### Table Stakes

| Feature | Why Expected | Complexity | Existing Rendro Dependency |
|---------|--------------|------------|---------------------------|
| Fixed-layout single page using `Rendro.fixed/2` | Certificates are design-driven, not content-driven; must use exact coordinates — a flowing layout would destroy the visual design | LOW — `Rendro.fixed/2` and fixed-anchor regions already exist | `Rendro.fixed/2`, fixed-anchor regions (existing) |
| Recipient name as the hero element (large centered type) | The certificate exists for the recipient; their name must be visually dominant | LOW | Fixed text block with registered font (existing) |
| Achievement statement + course title + completion date | These three fields define what the certificate proves; any missing field makes the cert legally and practically incomplete | LOW | Static fixed blocks |
| Issuer name + logo image | Issuer identity is half the certificate's value — the recipient presents it to third parties who need to identify the issuer | LOW | Image asset registration (existing) |
| Certificate ID | Required for any verifiable certificate; enables lookup in an external registry | LOW | Static text block |
| Signature line(s) | Standard credentialing convention; a certificate without a signature line feels unfinished | LOW — a horizontal rule + name/title text block below it | Fixed blocks or a drawn-line primitive |
| No page number footer | Certificates are single-page by convention; a "Page 1 of 1" footer looks wrong and amateurish | LOW — suppress via first-page/last-page suppress option from Category 1 | Page numbering suppress on first page |

### Differentiators

| Feature | Value Proposition | Complexity | Existing Rendro Dependency |
|---------|-------------------|------------|---------------------------|
| Optional second page (terms, verification detail, accreditation info) | Compliance and accreditation certificates often have a reverse side with program details | LOW — opt-in via recipe `document/2` option | Multi-page document structure (existing) |
| QR code as image asset (caller-generated, recipe positions it) | Modern verifiable certificates include a scannable QR code pointing to a verification URL; caller generates the QR code as an image, recipe positions it in the verification block | LOW — caller provides QR code PNG as a registered image asset; recipe places it at a fixed coordinate | Image asset registration (existing) |
| Expiry date field | Compliance, food-safety, and first-aid certificates expire; the expiry date must be prominent | LOW — optional field in recipe data struct | Static text block |
| Decorative border frame around the page | Strong visual convention for certificates; draws attention and signals prestige | MEDIUM — depends on whether Rendro has a drawn-rectangle / border-path primitive; if not, this requires a thin vector drawing addition | Depends on drawn-path primitive availability in engine |

### Anti-Features

| Feature | Why Requested | Why It Violates Rendro's Design Bias | Alternative |
|---------|---------------|--------------------------------------|-------------|
| Certificate "theme" gallery / style picker | Teams want design options without coding; Canva-style UX | This is WYSIWYG template editing, explicitly out of scope in PROJECT.md: "WYSIWYG builders, hosted template editing, or app-specific layout hacks in core — they widen surface area before the authoring contract is stable." | Ship one clean default layout; use `page_template/1` escape hatch for custom styling |
| Embedded digital signature / cryptographic signing seam baked into certificate recipe | Certificates "feel" like they should have a cryptographic stamp | The signing seam is a separate artifact-stage operation (`Rendro.Sign.sign/2`), not a recipe primitive. Conflating them blurs the authoring/artifact boundary and ties the recipe to an optional adapter. | Use `Rendro.Sign.sign/2` on the rendered artifact as a separate, explicit step after render |
| Bulk generation loop in `document/2` (generate certificates for a list of recipients) | "Generate 200 certificates from a CSV" is a real workflow | A loop belongs in the caller, not in a document recipe; baking it in would make `document/2` return a list instead of a document, breaking the three-rung pattern contract | Caller maps over recipients calling `document/2` per recipient; Oban worker handles the queue |
| Certificate validation service (check if a cert ID is valid) | Logical complement to generation | Backend service, not rendering logic | Out of scope for Rendro entirely; belongs in the caller's application |

---

## Feature Dependencies

```
Category 1: Page Numbering / Running Regions
    └── new primitive: region content as function over {page, total_pages}
            └──required by──> Category 2: Statement ("Page X of Y" + carried-forward totals)
            └──required by──> Category 3: Report variant ("Page X of Y" in repeating header)
            └──suppression option used by──> Category 4: Certificate (suppress page number)

Category 1: Carried-forward running totals (differentiator)
    └──required by──> Category 2: Statement (balance C/F and B/F at page breaks)
    └── this is new paginator-level engine behavior, not just recipe DSL

Category 2: Statement
    └── requires──> Table continuation (ALREADY SHIPPED)
    └── requires──> Page numbering primitive (new — Category 1)
    └── requires──> Carried-forward totals hook (new — Category 1 differentiator)

Category 3: Receipt/Report
    └── requires──> Table continuation (ALREADY SHIPPED)
    └── Report variant requires──> Page numbering primitive (new — Category 1)
    └── Receipt variant is INDEPENDENT of page numbering (single page)

Category 4: Certificate
    └── requires──> Rendro.fixed/2 + fixed-anchor regions (ALREADY SHIPPED)
    └── requires──> Image asset registration (ALREADY SHIPPED)
    └── is FULLY INDEPENDENT of page numbering primitive
    └── optional QR code requires caller to generate QR image externally
```

### Dependency Notes

- **Page numbering primitive must ship first in v2.4.** Statement and Report recipes are blocked on it for multi-page behavior. Receipt and Certificate can ship in parallel, but the primitive should lead the milestone since it unblocks the most.
- **Certificate is the most independent feature.** It uses only existing `fixed/2` and asset-registration capabilities. If schedule pressure hits, it can ship in parallel with or even before the primitive work.
- **Carried-forward totals is the hardest single feature.** It requires the paginator to expose an accumulation hook at page-break boundaries — this is new engine behavior, not just new recipe DSL. Scope it carefully and do not let it block simpler features.
- **The "region content as function" change is the key API primitive.** Once this is in place, all other page-numbering features (suppress, even/odd variants, section restart) are incremental. The hardest design question is: does the authoring API expose a bare function, a named primitive like `Rendro.page_number/1`, or both?

---

## Total Page Count Resolution — Recommended Strategy for Rendro

This warrants an explicit section because it is the most architecturally load-bearing decision in v2.4.

**Recommended: single-pass deferred injection.**

1. The `paginate` stage already knows the total page count after it completes — it has laid out all pages into a page list.
2. After pagination and before the `render` stage, the total count is a resolved integer.
3. Region content that needs `{current_page, total_pages}` is expressed as a 1-arity function (`fn {page, total} -> content_blocks end`) during authoring. Static region content (existing behavior) continues to work as-is.
4. The `render` stage, when emitting a page, checks whether each region's content is a function or a static list. If a function, it is called with `{page_index, total_pages}` to produce the blocks for that page.
5. No second render pass is needed. The total is available before the first byte is written.

This matches the conceptual model of fpdf2's `{nb}` substitution (single-pass, substitute at close time) and ReportLab's deferred canvas accumulation — both approaches know the total before emitting final output, but neither requires rendering twice.

Prawn's `number_pages` is a post-render stamp; it works differently from Rendro's pipeline model. LaTeX's two-pass model is the only genuine two-pass approach among the mature engines — it is efficient for TeX but wasteful for an in-memory Elixir pipeline.

**The authoring-side question:** Should the region content function be exposed as a raw anonymous function, or as a named helper like `Rendro.page_number(format: "Page ~p of ~t")`? A named helper is more discoverable for recipes. The raw function form gives the escape hatch for custom content. Both can coexist: the named helper returns a function that the same region-content mechanism accepts.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Phase Ordering |
|---------|------------|---------------------|----------|---------------|
| Page X of Y — deferred total count resolution (region content function) | HIGH | MEDIUM | P1 | Phase 1 — blocks all multi-page recipes |
| Repeated static header region per page | HIGH | LOW | P1 | Phase 1 with page numbering |
| Footer/header suppress on first/last page | MEDIUM | LOW | P1 | Phase 1 with page numbering |
| Statement: transaction lines + running balance + page X of Y | HIGH | MEDIUM | P1 | Phase 2 — after page numbering |
| Statement: balance carried forward / brought forward at page breaks | HIGH | HIGH | P1 | Phase 2 — requires new paginator hook |
| Certificate: fixed-layout, recipient name, issuer, signature line | HIGH | LOW | P1 | Can run in parallel with Phase 1 |
| Receipt: header + line items + payment block (single-page) | HIGH | LOW | P1 | Can run in parallel with Phase 1 |
| Report: repeating column header + grand total | HIGH | MEDIUM | P1 | Phase 2 — after page numbering |
| "Continued" marker on table splits | MEDIUM | LOW | P2 | Phase 2 alongside table features |
| Statement: aging summary (current/30/60/90 day) | MEDIUM | LOW | P2 | Phase 2, opt-in data field |
| Even/odd header content variants | LOW | MEDIUM | P3 | Defer post-v2.4 |
| Section-local page number restart | LOW | MEDIUM | P3 | Defer post-v2.4 |
| QR code on certificate (caller-generated image) | MEDIUM | LOW | P2 | Phase 2 alongside certificate |
| Decorative border frame on certificate | MEDIUM | MEDIUM | P3 | Depends on drawn-path primitive availability |

**Priority key:**
- P1: Required for v2.4 milestone to be called batteries-included
- P2: Add during v2.4 if schedule allows; clear user value
- P3: Defer post-v2.4; low demand relative to complexity or blocked on deeper engine work

---

## Sources

- fpdf2 Tutorial — `{nb}` mechanism and header/footer override: https://py-pdf.github.io/fpdf2/Tutorial.html
- ReportLab "Page X of Y" deferred canvas recipe: https://code.activestate.com/recipes/546511-page-x-of-y-with-reportlab/
- ReportLab `multibuild` two-pass discussion: https://reportlab-users.reportlab.narkive.com/jhk7kUgD/page-totals
- Prawn `number_pages` / `repeat` / `<total>` placeholder: https://github.com/prawnpdf/prawn/blob/master/manual/repeatable_content/page_numbering.rb
- wkhtmltopdf `[page]`/`[topage]` variable injection: https://wkhtmltopdf.org/usage/wkhtmltopdf.txt
- LaTeX fancyhdr even/odd, section restart, `\pageref{LastPage}`: https://www.overleaf.com/learn/latex/Headers_and_footers
- Statement of account structure, carried forward convention: https://www.zoho.com/books/academy/accounting-principles/what-is-a-statement-of-accounts.html
- Balance C/F and B/F accounting convention: https://www.accountingcapital.com/basic-accounting/balance-bf-and-balance-cf/
- Payment receipt required fields (IRS-aligned, Stripe resource): https://stripe.com/resources/more/receipt-template-what-to-include-and-templates-for-different-use-cases
- Completion certificate structure and verifiable fields: https://sertifier.com/blog/certificate-of-completion-template-verifiable/
- iText "Continued" table pattern: https://kb.itextpdf.com/itext/how-to-add-continue-on-next-page-continued-from--1

---
*Feature research for: Rendro v2.4 — page-numbering primitive + Statement/Receipt-Report/Certificate recipes*
*Researched: 2026-05-29*
