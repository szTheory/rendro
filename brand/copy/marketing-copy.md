# Rendro Marketing Copy

Ready-to-paste blocks, each sized to its surface. Every claim maps to a real capability in the README and API. Banned words (magic, seamless, pixel-perfect, HTML-to-PDF, SDK, viewer, etc.) are avoided throughout.

Primary tagline (locked, from the brand book): **Native PDF layout for Elixir.**

---

## One-line project description

**Primary:**
Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome.

**Alternate 1:**
Rendro builds PDFs from composable Elixir data — deterministic output, automatic pagination, and production telemetry, no browser required.

**Alternate 2:**
A pure-Elixir document layout engine for invoices, statements, and reports — composable, deterministic, observable.

---

## 140-character description

**Primary** (136 chars):
`Rendro: native PDF layout for Elixir. Build documents as composable data, paginate them predictably, render without Chrome. Open source.`

**Alternate** (135 chars):
`Open-source Elixir PDF layout library. Compose documents as data, get deterministic output and render telemetry. No browser, no Chrome.`

---

## GitHub repo description (About field, ≤ ~120 chars)

**Primary** (96 chars):
`Native PDF layout for Elixir. Build documents as composable data and render them without Chrome.`

**Alternate** (88 chars):
`Open-source Elixir-native PDF layout library. Deterministic output, no browser runtime.`

---

## Hex.pm package description (one sentence, mix.exs `description` style)

**Primary:**
`Native PDF layout for Elixir — build documents as composable data with deterministic output, automatic pagination, tables, and render telemetry.`

**Alternate:**
`Pure-Elixir PDF layout library for Phoenix: composable document components, automatic pagination, and telemetry, with no Chrome runtime.`

---

## HexDocs intro paragraph

Rendro is an open-source, Elixir-native PDF layout library. You build documents as composable Elixir data — pages, page templates, regions, sections, blocks, and tables — and Rendro measures the content, inserts page breaks, and produces a render plan before writing PDF bytes. It runs without Chrome, Node, or wkhtmltopdf, emits telemetry for every render, and is honest about its limits: Rendro is not an HTML/CSS-to-PDF renderer and not a PDF editor. Start with **Your first PDF**, then read **Tables**, **Pagination**, and **Telemetry**.

---

## README opening paragraph

# Rendro

Native PDF layout for Elixir.

Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome. Build documents as composable data and components, paginate them predictably, render them without a browser runtime, and inspect exactly what happened in production through telemetry and diagnostics.

---

## Landing page hero

**Headline (locked):**
Native PDF layout for Elixir.

**Subheadline (primary):**
Rendro helps Phoenix teams generate reliable PDFs from composable Elixir document components — with automatic pagination, tables, deterministic output, and render telemetry. No Chrome runtime.

**Subheadline (alternate):**
Build invoices, statements, and reports as Elixir data. Get predictable layout, deterministic bytes, and production telemetry — without a headless browser.

---

## CTAs

**Primary CTA**
1. Generate your first PDF *(recommended)*
2. Render an invoice
3. Get started

**Secondary CTA**
1. View examples *(recommended)*
2. Read the guide
3. View on GitHub

---

## Feature blurbs

**Native, no Chrome**
Rendro is pure Elixir. Build PDFs from data and components with no headless Chrome, Node, or wkhtmltopdf in your deploy. One less moving part in production, one less thing to keep alive.

**Deterministic output with telemetry**
The same document renders to the same bytes in deterministic mode, so you can snapshot-test PDFs in CI. Every render emits telemetry for duration, page count, byte size, and warnings — observe PDF generation like the rest of your Phoenix app.

**Pagination and tables that explain themselves**
Flow layout inserts page breaks automatically; tables repeat their headers across pages. Rows are atomic by design — a row that can't fit raises a clear layout error instead of silently truncating, telling you the region, the available height, and the fix.

---

## "Why this exists" bullets

- **Browsers are a heavy way to make a PDF.** Shipping headless Chrome to render an invoice means a second runtime to deploy, monitor, and keep patched. Rendro renders in the BEAM you already run.
- **PDF layout should be testable.** Documents as Elixir data — measured, paginated, and rendered to deterministic bytes — can be snapshot-tested and reasoned about, instead of debugged through a browser.
- **Production deserves visibility.** Render duration, page count, byte size, and layout warnings belong in your telemetry, not in a black box. Rendro emits them on every render.

---

## Example error message

```
Table row could not fit the remaining body space.
  Template: MyApp.PDF.Statement
  Region:   :body
  Block:    document.body.table[0].row[112]
  Available height: 16pt
  Required height:  40pt
Rendro table rows are atomic and do not split across pages.
Try one of: start the row on a new page, reduce cell padding,
or shorten the cell content.
```

---

## Example empty state

**No render artifacts yet.**
Generate a sample PDF to inspect page count, byte size, document hash, and any layout warnings.

*[ Generate sample ]*

---

## Example success state

**Render complete.**
5 pages · 48.2 KB · 38ms · `sha256:a9f1a2…dc94`

*[ Download PDF ]  [ View diagnostics ]*

---

## Example release announcement

### Rendro v0.3.0

This release adds opt-in table polish and improves layout diagnostics. No breaking changes.

**Added**
- Opt-in table `borders:`, `border_style:`, and `header_fill:` for deterministic table styling. Borderless defaults are unchanged.
- `Rendro.render_with_diagnostics/2` returns the laid-out document struct alongside the PDF for layout debugging.

**Changed**
- Layout overflow errors now include the region name and the available-vs-required heights.

**Fixed**
- Repeated table headers no longer drop the header fill on the second page.

Telemetry event names, the public break surface (`keep_together`, `keep_with_next`, `break_before`, `break_after`), and deterministic output are unchanged. Upgrade with `{:rendro, "~> 0.3"}`.

---

## Social preview card (1200×630)

**Headline:**
Native PDF layout for Elixir.

**Supporting line:**
Build documents as composable data. Deterministic output, automatic pagination, render telemetry — no Chrome.

**Footer strip (optional):**
`rendro` · open source · hex.pm/packages/rendro
