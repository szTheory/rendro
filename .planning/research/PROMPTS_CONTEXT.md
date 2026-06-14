# Rendro OSS DNA

Purpose: capture the reusable engineering and product DNA from recent `szTheory` Elixir OSS libraries so Rendro starts with proven defaults rather than rediscovering the same lessons.

## 1) Canonical Rendro synthesis (from existing prompt research)

Primary sources:
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md`
- `prompts/Rendro Brand Book.txt`

### Product thesis
- Rendro should be a pure-Elixir, Phoenix-first document/PDF platform with no Chrome runtime dependency in core.
- The strategic gap is not "PDF exists vs does not exist"; it is production-grade ergonomics: layout primitives, pagination, font/i18n path, operational telemetry, validation, docs, and deployment clarity.
- Scope must stay explicit: avoid promising full HTML/CSS rendering, arbitrary PDF editing, or compliance overclaims before support is real.

### Default architecture direction
- Keep a pure core and thin adapters:
  - `rendro` core (document model, layout, renderer, serializer).
  - Optional ecosystem adapters (`rendro_phoenix`, `rendro_oban`, validation adapters, optional admin tooling).
- Data-first document AST and deterministic render pipeline:
  - Build -> compose -> measure -> paginate -> render -> validate.
- Two top-level APIs sharing one engine:
  - Fixed-position API for exact forms/labels.
  - Flow API for reports/invoices/statements.

### Rendro north-star constraints
- Reliable pagination and table behavior are first-order.
- Errors must be instructive (what/where/why/next), not opaque.
- Production is a feature: bounded concurrency, telemetry, validation hooks, reproducibility.
- Honest support matrix beats broad claims.

## 2) Cross-library engineering DNA (what to repeat)

Focused libraries inspected:
- `threadline`, `sigra`, `lockspire`, `accrue`, `mailglass`, `rulestead`, `scrypath`, `kiln`, `lattice_stripe`.

Key implementation sources included:
- `mix.exs` in each library
- `.github/workflows/*`
- `.planning/RETROSPECTIVE.md`, `.planning/STATE.md`, milestone archives

### 2.1 CI/release patterns to copy

1. **Single canonical verify entrypoint**
- Pattern: explicit `mix verify.*` / `mix ci.*` aliases as the contract.
- Seen in: `threadline/mix.exs`, `mailglass/mix.exs`, `scrypath/mix.exs`, `accrue/accrue/mix.exs`.
- Rendro default:
  - one root `mix ci` contract
  - focused `mix verify.phase_nn` gates where needed
  - docs/build/package checks in the same contract.

2. **Release safety checks before publish**
- Pattern: dry-run publish + version/tag alignment + release-shape checks.
- Seen in:
  - `threadline/.github/workflows/hex-publish.yml`
  - `sigra/.github/workflows/release-please.yml`
  - `rulestead/.github/workflows/publish-hex.yml`
  - `scrypath/.github/workflows/release-please.yml`
- Rendro default:
  - verify tag equals `@version`
  - run tests/docs/package build before `mix hex.publish`
  - keep manual recovery workflow for emergency republish.

3. **Pinned action references for supply-chain stability**
- Pattern: pin GitHub Action SHAs for critical workflows.
- Seen in: `sigra/.github/workflows/ci.yml`, `lockspire/.github/workflows/ci.yml`, `rulestead/.github/workflows/*.yml`.
- Rendro default:
  - pin actions by commit SHA on release-critical workflows.

4. **Scheduled drift checks and rolling issue strategy**
- Pattern: periodic drift verification and update-existing issue handling.
- Seen in:
  - `lattice_stripe/.github/workflows/drift.yml`
  - `rulestead/.github/workflows/verify-published-release.yml`
  - `scrypath/.github/workflows/verify-published-release.yml`
- Rendro default:
  - scheduled drift checks for docs/examples/release parity and external dependency drift.

### 2.2 Test strategy patterns to copy

1. **Contract tests for docs/promises**
- Pattern: test files assert README/guide claims stay true.
- Seen in:
  - `threadline` doc-contract usage in `mix.exs` and CI
  - `accrue` docs contract scripts in CI
  - `sigra` release/readiness and installer contract focus
  - `scrypath` docs contract discipline across milestones
- Rendro default:
  - add docs-contract tests early for quickstart, supported surface, and limitations.

2. **Reference app as executable adoption proof**
- Pattern: maintain an example host app and run it in CI.
- Seen in:
  - `threadline/examples/threadline_phoenix`
  - `sigra/test/example`
  - `accrue/examples/accrue_host`
  - `scrypath/examples/phoenix_meilisearch`
- Rendro default:
  - ship `examples/rendro_phoenix` and include it in CI from the beginning.

3. **Optional integration lanes are explicit**
- Pattern: keep deterministic core lane merge-blocking, make external-provider/live lanes advisory.
- Seen in:
  - `accrue` Fake merge-blocking vs live Stripe advisory
  - `sigra` install and browser lanes separated by intent
  - `mailglass` no-optional-deps compile lane
- Rendro default:
  - merge-blocking deterministic lane; optional external rendering/validation adapters as separate, clearly labeled lanes.

### 2.3 API and package design patterns to copy

1. **Optional dependencies with explicit gates**
- Pattern: `optional: true`, `Code.ensure_loaded?`, and compile warning suppression by explicit allowlist.
- Seen in: `sigra/mix.exs`, `mailglass/mix.exs`, `accrue/accrue/mix.exs`, `scrypath/mix.exs`.
- Rendro default:
  - optional adapters and integrations must compile out cleanly.

2. **Clear package boundaries in monorepos**
- Pattern: sibling packages with strict package file whitelists.
- Seen in:
  - `accrue` and `rulestead` sibling-package release design
  - `scrypath` exclusion notes for `scrypath_ops` from Hex package.
- Rendro default:
  - separate core from Phoenix/admin integrations and keep Hex package contents minimal and explicit.

3. **Source/ref docs hygiene**
- Pattern: `source_ref` tied to release tags so HexDocs source links are stable.
- Seen in: `sigra/mix.exs`, `threadline/mix.exs`, `accrue/accrue/mix.exs`, `rulestead/rulestead/mix.exs`, `lattice_stripe/mix.exs`.
- Rendro default:
  - enforce docs/source tag parity pre-publish.

### 2.4 Process DNA from `.planning` retrospectives

1. **Traceability must be updated during execution, not deferred**
- Recurring lesson across: `threadline`, `sigra`, `accrue`, `scrypath`.
- Rendro default:
  - every phase close updates requirements traceability and verification references immediately.

2. **Milestone close tooling can fail; keep a manual close protocol**
- Recurring issue: milestone archive command failure noted in `threadline`, `sigra`, `accrue`, `scrypath`, `kiln`.
- Rendro default:
  - keep an explicit manual archive checklist in maintainer docs.

3. **Truthful verification boundaries**
- Pattern: do not claim beyond evidence; separate CI-proven vs external/human/advisory.
- Seen in: `accrue`, `sigra`, `threadline`, `rulestead`.
- Rendro default:
  - classify every verification row as deterministic, advisory, or human-required.

## 3) Footguns to avoid in Rendro

1. **Scope creep into browser-renderer territory**
- Avoid presenting Rendro core as full HTML/CSS renderer.

2. **Compliance language drift**
- Avoid "PDF/A compliant" or "PDF/UA compliant" claims without validator-backed proof paths.

3. **Optional dependency leakage**
- Avoid hard-linking optional adapters into core compile paths.

4. **Release narrative mismatch**
- Avoid docs/changelog/requirements drift around what actually shipped.

5. **Verification ambiguity**
- Avoid mixed "works locally" claims; define the merge authority and keep it consistent.

## 4) Rendro default quality contract (v1 baseline)

- Required on every PR:
  - formatting
  - compile with warnings-as-errors
  - tests
  - docs build
  - package build checks
  - quickstart/docs contract checks
- Required before publish:
  - version/tag parity
  - publish dry-run
  - release parity checks
- Optional/advisory lanes:
  - heavier visual regression lanes
  - external validator/lint integrations
  - stress/perf suites

This DNA is intentionally conservative: it optimizes for trust, reproducibility, and adoption clarity over premature breadth.
elixir-native-pdf-generation-oss-lib-deep-research.md

---


Research brief: Native PDF generation for Elixir/Phoenix without Chrome

Scope: Build a pure-Elixir, Phoenix-first, programmatic PDF generation library that avoids Chrome/Chromium as a production runtime dependency. The best opportunity is not “no Elixir PDF library exists”; as of April 24, 2026, there are active or recent native/BEAM-adjacent attempts such as PrawnEx, Mudbrick, ExGuten, and Paddlefish. The real gap is a mature, ergonomic, observable, Phoenix-integrated, production-grade PDF platform with great layout primitives, reliable pagination, font/i18n support, validation, docs, examples, CI, and deployment ergonomics.

1. Executive summary

The Elixir ecosystem has strong HTML-to-PDF options, especially ChromicPDF, but the best-supported route still depends on Chrome/Chromium and sometimes Ghostscript. ChromicPDF is current, widely used, and production-oriented; Hex lists it as a “Fast HTML-2-PDF/A renderer based on Chrome & Ghostscript,” with v1.17.1 updated March 19, 2026.  ￼ Its operational design is solid: it pools Chrome tabs, exposes configurable timeouts and concurrency, and emits telemetry events for rendering and PDF/A conversion.  ￼

The ecosystem gap is clearest in community discussion. In a November 2024 ElixirForum thread, the original ask was explicitly for “Prawn-like” capabilities: complex layouts, text styling, and custom tables; an early reply said there was “no real equivalence to Prawn for Elixir,” and later comments surfaced the practical split between HTML/CSS convenience, Typst/LaTeX quality, and native-code layout control.  ￼

The best product direction is a layered PDF library:

1. Core PDF writer: deterministic, pure Elixir, no Phoenix dependency.
2. Layout engine: blocks, inlines, tables, grids, pagination, page templates, headers/footers.
3. Phoenix adapter: send_download, controller/live preview helpers, HEEx/EEx-friendly component DSL, asset resolution.
4. Operational layer: Oban integration, telemetry, job metadata, retries, validation, snapshot testing, and optional admin UI.
5. Optional ecosystem bridges: Typst/Chrome/WeasyPrint adapters as explicit fallbacks, not as the core.

The “ultimate” library should not try to clone HTML/CSS first. It should learn from Prawn’s explicit non-HTML scope, ReportLab’s separation of document content from page templates/frames/flowables, fpdf2’s pragmatic feature set, Typst’s performance and developer experience, and iText/PDFBox’s enterprise-grade PDF capabilities. Prawn is explicit that it is not an HTML-to-PDF generator, while still offering vectors, flowing text, embedded fonts, images, encryption, repeaters, UTF-8/fallback/RTL text support, outlines, and low-level PDF escape hatches.  ￼ ReportLab’s Platypus design is especially instructive because it separates high-level layout decisions from content via DocTemplates, PageTemplates, Frames, and Flowables.  ￼

2. Current Elixir/BEAM ecosystem snapshot

ChromicPDF

What it does well: It is probably the strongest current Elixir production option for HTML-to-PDF/PDF-A rendering. It runs in a supervision tree, pools Chrome targets/tabs, lets users tune timeouts and pool sizes, and exposes telemetry.  ￼

Tradeoff: It requires Chrome/Chromium and, for PDF/A workflows, Ghostscript. This is fine for many teams, but it is exactly the dependency class your proposed library wants to avoid.

Lesson: Production users value pooling, timeouts, telemetry, supervision-tree fit, and clean operational knobs as much as the rendering API itself.

PdfGenerator / wkhtmltopdf / Puppeteer wrappers

PdfGenerator wraps wkhtmltopdf and PDFTK, and its README also covers Chrome-headless/Puppeteer usage.  ￼ The deployment pain is visible in its docs: embedding Chromium can add a roughly 300 MB binary to priv, Docker/root setups may require disabling Chrome sandboxing, and Chrome output is described as often larger than wkhtmltopdf output.  ￼

Lesson: Avoiding Chrome is valuable not just for purity; it reduces image size, sandbox issues, CI complexity, attack surface, cold starts, and “works locally but not in prod” incidents.

PrawnEx

PrawnEx is a recent pure-Elixir attempt: v0.2.0 on Hex describes itself as “Prawn-style declarative PDF generation for Elixir. Pure Elixir, no Chrome or HTML,” and the GitHub README lists pages, text, graphics, colors, tables, charts, flow layout, images, links, and headers/footers.  ￼ It also openly states current limitations: coordinates use PDF points with a bottom-left origin, and its flow layout does not yet include automatic pagination or flex/grid; overflow remains the user’s responsibility.  ￼

Lesson: PrawnEx validates demand and direction, but the “ultimate” version must solve pagination, richer layout, font shaping/subsetting, testing, validation, docs, Phoenix integration, and day-2 operations.

Mudbrick

Mudbrick targets PDF 2.0, a pure functional approach, OpenType support, ligatures, special characters, automatic kerning, text positioning, alignment, JPEG images, compression, and basic line drawing; its README also notes TODOs such as image formats, font subsetting, vector graphics, strikethrough, and highlights.  ￼

Lesson: Font handling and text shaping are a differentiator. A PDF generator that makes Unicode, glyph runs, kerning, ligatures, and fallback fonts pleasant will stand apart.

ExGuten / Gutenex / expdf

Gutenex was last updated in 2016 on Hex, expdf in 2019, and ExGuten appeared in 2026 as a “Typographic-quality PDF generation for Elixir” port/reimagining of Joe Armstrong’s Erlang PDF work.  ￼

Lesson: There is history here, but not yet a dominant modern API. Backward-looking ports are useful, but the winning library should feel like modern Elixir: immutable data, pipelines, protocols, behaviours, supervision, telemetry, ExDoc, property tests, and Phoenix affordances.

Typst bindings and Typst-powered tools

The community repeatedly mentions Typst as a strong PDF generation option. In the ElixirForum thread, users praised Typst’s deterministic layout, table control, output quality, and fit for high-volume same-format/different-data workloads, while noting tradeoffs around template maintenance and input asset management.  ￼ Hex now has packages such as typst, imprintor, and folio that generate PDFs through Typst or Typst templates.  ￼

Lesson: A native PDF builder should borrow Typst’s focus on deterministic layout, good errors, and templates, but should keep the core API Elixir-native and integrate naturally with Phoenix.

3. Lessons from mature libraries in other ecosystems

Ruby Prawn

Prawn’s strongest lessons:

* Be clear about scope: Prawn is not an HTML-to-PDF generator and does not pretend to be one.  ￼
* Offer both high-level convenience and low-level escape hatches.
* Treat examples/manuals as product, not afterthought.
* Support fonts, images, repeatable content, outlines, internationalization, and PDF object-tree access.
* Mark experimental APIs clearly. Prawn’s README notes it does not formally follow SemVer for experimental APIs and that bug fixes can change behavior, so users should read release notes and test updates.  ￼

Apply to Elixir: Use a stable public API for Document, Page, Layout, Table, Text, Image, and Phoenix integration. Put experimental APIs behind MyPDF.Experimental.* or feature flags.

Python ReportLab

ReportLab’s Platypus model is the most important architectural reference. It separates document content from page layout: DocTemplates contain the document, PageTemplates define page layouts, Frames define regions, and Flowables are content elements such as paragraphs, images, and tables that flow through those frames.  ￼

Apply to Elixir: Model layout as data and pure transformations. A good Elixir equivalent:

* Document → whole PDF plan and metadata.
* PageTemplate → page size, margins, frames, header/footer.
* Frame → named content area.
* Flowable / Block → paragraph, heading, table, image, chart, spacer.
* LayoutResult → pages, warnings, overflow diagnostics.
* Renderer → turns layout result into PDF objects/streams.

Python fpdf2

fpdf2 is simple, fast, and pragmatic. Its docs list UTF-8 TrueType subset embedding, internal/external links, images with transparency, SVG import, barcodes/charts, tables, automatic page breaks, headers/footers, HTML conversion, templates, accessibility alt descriptions, outlines, encryption, signing, annotations, attachments, and few dependencies.  ￼

Apply to Elixir: The MVP should feel simple like fpdf2, but the roadmap should include a credible path to fonts, tables, links, headers/footers, outlines, annotations, attachments, accessibility metadata, encryption, signing, and template batching.

JavaScript PDFKit

PDFKit positions itself as a Node/browser PDF generation library with chainable APIs, low-level functions, and higher-level abstractions for complex multi-page documents.  ￼

Apply to Elixir: Pipelined APIs can be the Elixir equivalent of chainability:

pdf =
  PDF.new(page_size: :a4)
  |> PDF.metadata(title: "Invoice")
  |> PDF.page(fn page ->
    page
    |> PDF.text("Invoice #123", style: :h1)
    |> PDF.table(line_items, columns: [...])
  end)
  |> PDF.render()

React-pdf

React-pdf proves that developers like component models for documents; it is a React renderer for creating PDF files in the browser and server.  ￼

Apply to Phoenix: Phoenix developers already understand components, assigns, slots, and HEEx. A PDF component DSL should feel close to Phoenix function components while producing a PDF AST, not HTML.

pdf-lib

pdf-lib is a cautionary example in scope management. Its README says it cannot extract or edit arbitrary page text outside form fields, does not support HTML/CSS embedding because that is extremely difficult and out of scope, and does not support encrypted documents.  ￼

Apply to Elixir: Do not promise arbitrary PDF editing, HTML/CSS rendering, or encrypted-file manipulation in v1. Define explicit product boundaries.

WeasyPrint and Prince

WeasyPrint is an HTML/CSS rendering engine for PDF that aims to support web standards for printing.  ￼ Prince is commercial and very capable for HTML-to-PDF, with headers/footers, page numbers, duplex printing, tables, lists, columns, floats, footnotes, and cross-references.  ￼

Apply to Elixir: HTML/CSS is attractive because teams already have templates and designers. Your native library can win by offering better deterministic layout, deployability, and observability, while optionally providing HTML/Typst/Chrome adapters for teams that need them.

iText and PDFBox

PDFBox is a mature open-source Java library for creating, manipulating, and extracting content from PDFs, with command-line utilities and an Apache license.  ￼ iText’s feature list shows what enterprise PDF eventually means: layout engine, manipulation, digital signing, forms, PDF/A, PDF/UA, FIPS cryptography, barcodes, SVG, OCR add-ons, redaction, international character sets, and optimization.  ￼

Apply to Elixir: Do not put all of this in the MVP, but design extension points early. The architecture should not block future forms, PDF/A, PDF/UA, signing, redaction, attachments, or optimization.

4. Core product thesis

Build the Phoenix-native Prawn/ReportLab for Elixir, not another browser wrapper.

The winning tagline:

Generate reliable, production-grade PDFs in pure Elixir: composable layout, automatic pagination, Phoenix integration, telemetry, validation, and no Chrome in production.

What users should feel on day 0:

* “I can generate an invoice in 15 minutes.”
* “I can send it from a Phoenix controller.”
* “I can preview it in LiveView.”
* “I do not need Chrome, Node, wkhtmltopdf, system packages, or Docker gymnastics.”
* “The docs show exactly how to do invoices, reports, certificates, statements, labels, and tables.”

What users should trust on day 2:

* “I can monitor render duration, queue time, PDF size, page count, and failures.”
* “I can validate PDFs in CI.”
* “I can snapshot visual output.”
* “I can version templates.”
* “I can render many PDFs concurrently without blowing memory.”
* “I know the library’s limits.”

5. Personas and jobs-to-be-done

Phoenix SaaS developer

Job: Generate invoices, receipts, certificates, tickets, account statements, shipping labels, and reports from app data.

Needs: Minimal setup, controller helpers, send_download, S3 upload examples, LiveView preview, simple tables, headers/footers, logos, page numbers, sane defaults.

DX win: mix pdf.gen.invoice scaffold and a working Phoenix example app.

Back-office/reporting developer

Job: Produce tables, charts, multi-page reports, exports, and operational documents.

Needs: Automatic pagination, repeating table headers, widows/orphans control, nested sections, table of contents, totals, page templates, deterministic layout.

DX win: Report components with predictable page breaks and clear overflow errors.

Enterprise/compliance developer

Job: Generate regulated statements, contracts, disclosures, audit artifacts, and archived documents.

Needs: Metadata, PDF/A, PDF/UA path, stable output, digital-signing extension points, encryption options where compatible, audit logs, reproducible rendering, versioned templates.

DX win: Validation reports, artifact hashes, deterministic mode, explicit compliance checklist.

SRE / DevOps

Job: Deploy and operate PDF generation safely at scale.

Needs: No browser runtime, low memory, bounded concurrency, telemetry, timeouts, retries, queue metrics, render-job IDs, structured errors, backpressure, health checks.

DX win: Built-in telemetry events and Oban integration.

Library maintainer / contributor

Job: Extend PDF features without breaking users.

Needs: Modular architecture, tests, property tests, golden fixtures, visual snapshots, conformance validation, clear release process, easy CI.

DX win: Small core, extension behaviours, clear specs, release-please automation, Hex dry-run checks.

6. Domain language

This is the domain model that should guide modules, types, events, docs, and APIs.

Core nouns

Term	Meaning
Document	The logical PDF document: metadata, pages, resources, outlines, attachments, options.
Page	A physical page with size, rotation, media/crop boxes, content streams, resources.
PageSize	Named or custom dimensions: :a4, :letter, {width_pt, height_pt}.
Box	Rectangle in PDF points: {x, y, width, height} or %Box{}.
MarginBox	Usable page area after margins.
Frame	Named flow region on a page: body, sidebar, header, footer.
PageTemplate	Page layout recipe: size, margins, frames, header/footer, background.
Flow	Ordered content that should be laid out over frames/pages.
Block	Flow-level element: paragraph, heading, table, image, chart, spacer, section.
Inline	Text-level element: span, link, emphasis, code, inline image.
TextRun	Text with resolved font, size, style, color, shaping direction.
GlyphRun	Shaped glyphs with advances and positions.
FontFamily	Logical font family with regular/bold/italic faces.
FontFace	Actual font file or built-in PDF font.
FontSubset	Embedded subset of a font used by a document.
FallbackFont	Secondary font used when primary lacks glyphs.
Image	Embedded raster image resource: PNG, JPEG, later WebP/TIFF via adapters.
Path	Vector path: move, line, curve, close.
Shape	Higher-level vector: line, rect, circle, ellipse, polygon.
Color	Gray/RGB/CMYK/spot color value.
Resource	PDF resource: font, image XObject, color space, graphics state.
Annotation	Link, text annotation, highlight, file attachment, form widget.
Outline	Bookmark tree / document navigation.
Destination	Named or explicit page location target.
Metadata	Info dictionary and XMP metadata.
Attachment	Embedded file associated with document or page.
Form	AcroForm structure. Future module.
Field	Text, checkbox, radio, signature field. Future module.
Signature	Digital signature or signature field. Future module/adapter.
Object	Low-level numbered PDF object.
Stream	Low-level PDF stream with filters/compression.
XRef	Cross-reference table/stream.
Trailer	PDF trailer/root/info references.
Catalog	PDF root object.
RenderJob	One request to render a document from data/template.
Template	Reusable document definition, code or stored template.
TemplateVersion	Immutable published version of a template.
Preview	Rendered artifact for development/admin review.
Artifact	Produced PDF plus metadata: hash, bytes, page count, render time.
ValidationReport	Output from structural, visual, PDF/A, or accessibility checks.
Snapshot	Golden rendered output used for tests.
Diff	Visual or structural difference between two outputs.
Policy	Runtime rules: max pages, max bytes, allowed assets, timeouts.
Renderer	Module that turns a document/layout into bytes.
LayoutEngine	Module that measures, flows, paginates, and places content.
Serializer	Module that writes PDF objects/streams/xref/trailer.
AssetResolver	Resolves images/fonts/files from app paths, priv, uploads, or storage.
Store	Storage target: memory, filesystem, S3, database, custom callback.

Core verbs

Verb	Meaning
build	Construct a document from code/template/data.
compose	Convert components into a document AST.
measure	Compute size of text/block/table before placement.
shape	Convert text into glyphs for a font/script/direction.
wrap	Break text into lines.
flow	Place blocks into frames across pages.
paginate	Add pages and page breaks.
place	Put content at a fixed coordinate.
draw	Emit vector/text/image operations.
embed	Add font/image/file resources.
subset	Embed only used font glyphs.
compress	Apply stream compression.
annotate	Add links, highlights, notes, widgets.
tag	Add semantic structure for accessibility.
outline	Add bookmarks/table of contents.
encrypt	Apply PDF encryption when allowed.
sign	Digitally sign or delegate signing.
linearize	Optimize for fast web view.
validate	Run structural/conformance checks.
render	Produce PDF bytes.
stream	Emit bytes to file/HTTP/storage without keeping all output in memory.
preview	Render for developer/admin inspection.
diff	Compare two outputs visually or structurally.
cache	Reuse font subsets, decoded images, compiled templates.
instrument	Emit telemetry events and metrics.
publish	Mark a template or package version as releasable.
hydrate	Load data/assigns for a template.
resolve	Find and authorize an asset.
sanitize	Clean untrusted template/data/asset inputs.

Domain events

Use these as telemetry event names and internal lifecycle events.

[:pdf, :document, :build, :start]
[:pdf, :document, :build, :stop]
[:pdf, :document, :build, :exception]
[:pdf, :layout, :measure, :start]
[:pdf, :layout, :measure, :stop]
[:pdf, :layout, :overflow, :detected]
[:pdf, :layout, :page_break, :inserted]
[:pdf, :font, :load, :start]
[:pdf, :font, :load, :stop]
[:pdf, :font, :subset, :stop]
[:pdf, :font, :missing_glyph]
[:pdf, :image, :decode, :start]
[:pdf, :image, :decode, :stop]
[:pdf, :image, :unsupported_format]
[:pdf, :render, :start]
[:pdf, :render, :stop]
[:pdf, :render, :exception]
[:pdf, :validation, :start]
[:pdf, :validation, :stop]
[:pdf, :validation, :failed]
[:pdf, :job, :queued]
[:pdf, :job, :started]
[:pdf, :job, :completed]
[:pdf, :job, :failed]
[:pdf, :job, :retry_scheduled]
[:pdf, :template, :compiled]
[:pdf, :template, :published]
[:pdf, :template, :previewed]
[:pdf, :cache, :hit]
[:pdf, :cache, :miss]

ChromicPDF is a useful telemetry precedent: it emits :start, :stop, and :exception events around print_to_pdf, screenshot capture, and PDF/A conversion.  ￼

7. API design principles

Principle 1: Pure core, Phoenix adapters

The core library should not depend on Phoenix, Ecto, Oban, Swoosh, or ExAws.

Suggested packages:

pdf_core          # pure PDF writer + layout
pdf_phoenix      # controller/live preview helpers
pdf_ecto         # optional template/version schemas
pdf_oban         # background render jobs
pdf_admin        # optional Phoenix LiveView admin UI
pdf_validation   # veraPDF/qpdf/mutool adapters, optional external tools

Principle 2: Data-first AST

Represent documents as structs and render later. This enables validation, previews, transforms, diffs, and template compilation.

%PDF.Document{
  metadata: %PDF.Metadata{},
  page_templates: %{},
  flow: [%PDF.Block.Heading{}, %PDF.Block.Table{}],
  resources: %PDF.Resources{}
}

Principle 3: Two APIs, one engine

Offer both:

Fixed-position API for labels, certificates, exact forms:

PDF.new(page_size: :letter)
|> PDF.page(fn page ->
  page
  |> PDF.text_at({72, 720}, "Certificate of Completion", font_size: 24)
  |> PDF.image_at("logo.png", {72, 650}, width: 120)
end)

Flow/layout API for reports, invoices, statements:

PDF.document(page_size: :a4, margin: 48)
|> PDF.heading("Invoice #{@invoice.number}")
|> PDF.paragraph("Bill to: #{@customer.name}")
|> PDF.table(@line_items, columns: Invoice.columns(), repeat_header: true)
|> PDF.render()

Principle 4: Phoenix component feel, not HTML semantics

A Phoenix-friendly DSL can use assigns and slots without implying HTML/CSS rendering.

defmodule MyApp.PDF.Invoice do
  use PDF.Component
  attr :invoice, MyApp.Billing.Invoice, required: true
  def render(assigns) do
    ~PDF"""
    <Document page_size="a4" margin="48">
      <Header>
        <Image src={~p"/images/logo.png"} width="96" />
        <Text style="h1">Invoice <%= @invoice.number %></Text>
      </Header>
      <Table rows={@invoice.line_items} repeat_header>
        <:column label="Item" field={:description} />
        <:column label="Qty" field={:quantity} align="right" />
        <:column label="Amount" field={:amount} align="right" format={:currency} />
      </Table>
    </Document>
    """
  end
end

The important part: this DSL compiles to a PDF AST, not HTML.

Principle 5: Error messages are part of the product

Bad:

{:error, :layout_failed}

Good:

Table overflowed page body frame.
Template: MyApp.PDF.Invoice
Block path: document/body/table[2]/row[47]/cell[3]
Available height: 18pt
Required height: 42pt
Try: reduce font size, allow row splitting, or set on_overflow: :new_page

8. Footguns and how to design them out

Footgun: Browser PDF generation creates deployment risk

Chrome/wkhtmltopdf/Puppeteer solutions are operationally familiar but bring large binaries, Docker package issues, sandbox flags, and runtime dependency drift. PdfGenerator’s docs explicitly discuss embedding a 300 MB Chromium binary, installing Node/Puppeteer, and passing no_sandbox in root/Docker environments.  ￼

Design response: No external renderer in core. Optional adapters must be explicit and isolated.

Footgun: Native PDF coordinates are unfriendly

PDF uses points and bottom-left coordinates. PrawnEx’s README explicitly calls out 72 pt = 1 inch and bottom-left origin.  ￼

Design response: Let low-level users use points, but layout users should think in margins, frames, blocks, rows, columns, and logical page flow.

Footgun: Pagination is the hard part

PrawnEx currently has flow layout but no automatic pagination or flex/grid, leaving overflow to users.  ￼ Community complaints also center on tables across pages and lack of control in headless-browser output.  ￼

Design response: Automatic pagination, repeating headers, row splitting policies, keep-with-next, avoid-orphans, and overflow diagnostics should be first-class.

Footgun: Fonts and i18n are deceptively difficult

Prawn advertises UTF-8 fonts, RTL text, fallback font support, and customizable wrapping extension points.  ￼ fpdf2 similarly highlights UTF-8 TrueType subset embedding across many scripts.  ￼ Mudbrick focuses on OpenType, ligatures, special characters, and kerning.  ￼

Design response: Treat font support as a core investment, not a late add-on. Minimum serious path: built-in PDF fonts for MVP, then TTF/OTF parsing, subset embedding, fallback fonts, HarfBuzz/Rust/NIF or pure-Elixir shaping strategy, and explicit unsupported-script errors.

Footgun: HTML/CSS scope creep

pdf-lib is explicit that HTML/CSS embedding is out of scope because it is extremely difficult.  ￼ Prawn is also explicit that it is not and will never be an HTML-to-PDF generator.  ￼

Design response: Do not market the core as “HTML to PDF.” Market it as “PDF documents as Elixir data/components.” Add a limited HTML/Markdown importer later only if it maps to supported document primitives.

Footgun: Compliance claims are easy to overstate

PDF/A requires everything needed for reproducible rendering to be inside the file, including fonts, color profiles, and images; it forbids dynamic content and encryption.  ￼ PDF/UA is a technical standard for accessible PDF, but PDF/UA alone does not guarantee the accessibility of the content itself.  ￼ veraPDF validates all PDF/A parts/conformance levels and PDF/UA machine checks, with rules formalized from each standard’s requirements.  ￼

Design response: Say “PDF/A-ready” or “PDF/UA validation support” until actual conformance is implemented and tested. Provide validation adapters and compliance checklists.

Footgun: Digital signing is complex

Zerodha’s high-volume PDF pipeline notes that they did not find performance-focused FOSS libraries for batch signing PDFs due to PDF signature complexity, so they wrapped a Java OpenPDF service for concurrent signing.  ￼

Design response: Do not make signing a v1 core promise. Provide signature-field support and a signing behaviour/adapter.

9. “Ultimate library” feature set

Day 0: adoption features

* mix pdf.install or clear dependency setup.
* mix pdf.gen.invoice
* mix pdf.gen.report
* mix pdf.gen.certificate
* Phoenix controller examples.
* LiveView preview example.
* S3/storage examples.
* ExDoc guides, not just module docs.
* Copy-paste recipes for invoices, statements, labels, charts, and tables.
* Excellent errors for missing fonts/images, overflow, unsupported image formats, invalid colors, and invalid page sizes.

Day 1: production features

* Bounded concurrency.
* Configurable render timeout.
* Memory-safe streaming to file/storage where possible.
* Deterministic output mode.
* Metadata and document hashes.
* Telemetry events.
* Structured errors.
* Render job IDs.
* Oban worker integration.
* Retry policy examples.
* Optional validation step after render.
* Optional visual snapshot rendering in CI.

Day 2: operations and governance

* Template versioning.
* Admin UI for previews and render history.
* Per-template metrics.
* Failed render inspection.
* Golden sample data.
* Visual diff between template versions.
* PDF/A/PDF/UA validation reports.
* Audit trail: who published template version, when, with which sample outputs.
* Deprecation and migration guides.
* Release automation.

10. Recommended module architecture

PDF
PDF.Document
PDF.Page
PDF.PageSize
PDF.Box
PDF.Metadata
PDF.Resources
PDF.Layout
PDF.Layout.Engine
PDF.Layout.Frame
PDF.Layout.PageTemplate
PDF.Layout.Block
PDF.Layout.Inline
PDF.Layout.Result
PDF.Layout.Overflow
PDF.Text
PDF.Text.Font
PDF.Text.FontFace
PDF.Text.FontSubset
PDF.Text.GlyphRun
PDF.Text.Measurement
PDF.Text.Wrapping
PDF.Table
PDF.Table.Column
PDF.Table.Row
PDF.Table.Cell
PDF.Table.Paginator
PDF.Graphics
PDF.Graphics.Path
PDF.Graphics.Shape
PDF.Graphics.Color
PDF.Graphics.State
PDF.Image
PDF.Image.PNG
PDF.Image.JPEG
PDF.Image.Decoder
PDF.Annotation
PDF.Outline
PDF.Attachment
PDF.Forms
PDF.Signatures
PDF.Renderer
PDF.Serializer
PDF.Object
PDF.Stream
PDF.XRef
PDF.Trailer
PDF.Validation
PDF.Validation.Structural
PDF.Validation.PDFA
PDF.Validation.PDFUA
PDF.Validation.Visual
PDF.Telemetry
PDF.Policy
PDF.Error
PDF.AssetResolver
PDF.Cache

Phoenix packages:

PDF.Phoenix.Controller
PDF.Phoenix.LivePreview
PDF.Phoenix.Component
PDF.Phoenix.AssetResolver
PDF.Ecto.Template
PDF.Ecto.TemplateVersion
PDF.Ecto.RenderArtifact
PDF.Oban.RenderWorker
PDF.Admin.Router
PDF.Admin.Live.TemplateIndex
PDF.Admin.Live.TemplatePreview
PDF.Admin.Live.RenderJobShow

11. Testing and CI strategy

Unit tests

Test:

* PDF object serialization.
* Stream filters.
* Cross-reference offsets.
* Page tree correctness.
* Resource dictionaries.
* Text escaping.
* Color operators.
* Image embedding.
* Font subset tables.
* Table measurement.
* Pagination rules.

Property tests

Property-test invariants:

* Every referenced object exists.
* XRef byte offsets point to valid object starts.
* Page count equals page tree count.
* No duplicate object IDs.
* Stream lengths match actual bytes.
* Generated PDFs open in multiple readers.
* Layout never writes outside allowed frame unless policy permits bleed.
* Pagination terminates for arbitrary finite content.

Golden tests

Use deterministic mode:

* Fixed creation date.
* Stable object ordering.
* Stable compression option or disabled compression in golden tests.
* Stable IDs.

Visual regression tests

Render PDFs to images in CI with an external tool, then compare with tolerance. MuPDF’s mutool draw is a useful tool for rendering documents to image files.  ￼

Validation tests

* Run qpdf --check or equivalent structural checks.
* Run veraPDF for PDF/A/PDF/UA profiles when relevant; veraPDF is a purpose-built validator for PDF/A and PDF/UA machine checks.  ￼
* Add sample PDFs to a corpus: tiny, large, multilingual, image-heavy, table-heavy, thousands of rows, many pages.

CI/CD and release

Use release-please for changelog generation, GitHub releases, and version bumps based on Conventional Commits, but remember it does not publish to package managers by itself.  ￼ Use mix hex.publish --dry-run in CI and a protected release workflow for actual Hex publication; Hex docs state mix hex.publish publishes a package and that docs are generated/published automatically through the docs task.  ￼

12. Security model

Inputs to distrust

* Template code or stored templates.
* Assigns/data from users.
* Remote asset URLs.
* Local file paths.
* Uploaded images/fonts.
* Metadata strings.
* Links and annotations.
* Embedded attachments.

Required protections

* No remote asset fetching by default.
* Asset allowlists.
* Path traversal prevention.
* Max PDF bytes.
* Max page count.
* Max image dimensions.
* Max decoded image bytes.
* Max font file size.
* Max render time.
* Max table rows or explicit streaming policy.
* No arbitrary code execution in stored templates.
* SSRF-safe asset resolver if remote assets are enabled.
* Safe error messages that do not leak secrets.
* Optional :redact_errors mode for production.

Compliance-sensitive notes

* PDF/A and encryption conflict: PDF/A prohibits encryption.  ￼
* Accessibility cannot be solved only by tags; content semantics, contrast, reading order, and alt text still matter.  ￼
* Digital signatures should be designed as an adapter/extension point until deeply implemented.

13. Phoenix integration design

Controller download

def show(conn, %{"id" => id}) do
  invoice = Billing.get_invoice!(id)
  {:ok, pdf} =
    MyApp.PDF.Invoice.render(invoice,
      validate: true,
      telemetry_metadata: %{invoice_id: invoice.id}
    )
  send_download(conn, {:binary, pdf},
    filename: "invoice-#{invoice.number}.pdf",
    content_type: "application/pdf"
  )
end

Background rendering with Oban

%{
  template: "invoice",
  template_version: "2026.04.24",
  invoice_id: invoice.id,
  requested_by_id: current_user.id
}
|> MyApp.PDF.RenderWorker.new()
|> Oban.insert()

Live preview

Admin UI should support:

* Select template version.
* Select fixture/sample data.
* Render preview.
* Show warnings: overflow, missing glyphs, large images, validation failures.
* Compare previous version.
* Download PDF.
* Approve/publish.

Ecto schema ideas

schema "pdf_templates" do
  field :name, :string
  field :description, :string
  field :status, Ecto.Enum, values: [:draft, :published, :archived]
  has_many :versions, PDF.TemplateVersion
  timestamps()
end
schema "pdf_template_versions" do
  belongs_to :template, PDF.Template
  field :version, :string
  field :source, :string
  field :compiled_hash, :string
  field :published_at, :utc_datetime_usec
  field :published_by_id, :binary_id
  timestamps()
end
schema "pdf_render_artifacts" do
  field :template_name, :string
  field :template_version, :string
  field :status, Ecto.Enum, values: [:ok, :error]
  field :byte_size, :integer
  field :page_count, :integer
  field :sha256, :string
  field :duration_ms, :integer
  field :validation_report, :map
  timestamps()
end

14. Product positioning

Do say

* “Pure-Elixir PDF generation.”
* “No Chrome required.”
* “Phoenix-first.”
* “Composable document components.”
* “Automatic pagination.”
* “Production telemetry.”
* “Validation-ready.”
* “Great for invoices, reports, statements, certificates, tickets, labels, and internal documents.”

Do not say too early

* “Fully HTML/CSS compatible.”
* “PDF/A compliant” unless validated.
* “PDF/UA compliant” unless tagged and validated.
* “Supports all fonts/scripts” unless shaping/fallback is real.
* “Digital signatures supported” unless implemented and tested against common validators.
* “PDF editor” unless existing PDFs can be safely parsed and modified.

15. MVP recommendation

The strongest MVP is not a toy low-level writer. It should solve a painful real use case end-to-end.

v0.1: Invoices and simple reports

Must have:

* PDF 1.7 or 2.0 writer with deterministic mode.
* Pages, metadata, text, lines, rectangles, colors.
* Built-in PDF fonts.
* JPEG and simple PNG.
* Basic flow layout.
* Automatic page breaks for paragraphs.
* Tables with repeating headers.
* Headers/footers with page numbers.
* Phoenix controller guide.
* ExDoc guides.
* Telemetry for build/layout/render.
* Golden tests and visual snapshots.
* mix hex.publish --dry-run CI.

v0.2: Serious layout

* Page templates.
* Frames.
* Sections.
* Keep-with-next.
* Row splitting policies.
* Table column sizing.
* Overflow diagnostics.
* Outlines/bookmarks.
* Links.
* Admin preview prototype.

v0.3: Fonts and i18n

* TTF/OTF embedding.
* Font subsetting.
* Fallback fonts.
* Missing glyph warnings.
* Kerning.
* Basic shaping strategy.
* RTL/CJK roadmap with explicit support matrix.

v0.4: Validation and operations

* qpdf/veraPDF/mutool adapters.
* Oban integration.
* Artifact metadata.
* Template fixtures.
* Visual diff tooling.
* S3/storage examples.

v1.0: Stable Phoenix PDF platform

* Stable core API.
* Stable Phoenix adapter.
* Stable layout primitives.
* Strong docs/examples.
* Performance benchmarks.
* Conformance/validation story.
* Clear extension behaviours.
* Release automation.
* Migration policy.

16. Hard design calls

Should the core be PDF 1.4, 1.7, or 2.0?

PDF 2.0 is the modern ISO core specification and is available at no cost through the PDF Association.  ￼ But many practical libraries still emit older versions for compatibility. A pragmatic path:

* Start with PDF 1.7-compatible output unless a feature requires otherwise.
* Keep internal model capable of PDF 2.0.
* Make version explicit: pdf_version: "1.7" or "2.0".
* Add PDF/A targets separately.

Should this include HTML-to-PDF?

Not in core. Add a future adapter that maps a small safe subset of HTML/Markdown to document primitives, but do not implement CSS layout. HTML/CSS rendering is a separate product category.

Should this include Typst?

Not in core. Consider an optional adapter:

PDF.Renderer.Typst.render(template, assigns)

This makes the library a broader PDF platform while preserving the native builder.

Should templates live in the database?

Optional. Code-first templates are safer, testable, and easier to version. Database templates are valuable for admin-editable documents, but they require sandboxing, versioning, validation, and approval workflows.

17. The biggest opportunities to beat existing options

1. Automatic pagination that actually works.
2. Tables that are pleasant.
3. Phoenix-native component ergonomics.
4. No browser runtime.
5. Great telemetry and operational controls.
6. Validation and visual regression baked into CI.
7. Font/i18n roadmap that is honest and visible.
8. Admin UI for template previews, versions, and render history.
9. Excellent examples: invoices, statements, reports, labels, certificates.
10. Clear scope boundaries.

18. Final design mantra

Make the common document boring, the complex document possible, the production render observable, and the unsupported case obvious.

The library should feel like idiomatic Elixir: small composable data structures, pure transformations, pipelines, behaviours, supervision-friendly integrations, telemetry, ExDoc guides, and clear errors. The winning path is not to out-Chrome Chrome; it is to give Phoenix teams a reliable native document engine with first-class layout, pagination, operations, and validation.Rendro Brand Book

Version: 0.1
Project: Open-source Elixir-native PDF/document generation library
Use: Logo, landing page, docs, UI, examples, microcopy, launch copy, and LLM design context
Core idea: Native document rendering for Elixir — reliable, composable, observable, and browser-free.

One caveat before canonizing the name: “Rendro” has a meaningful historical collision. CHILI used CHILI rendro for a PDF rendering/viewing solution, and printing-industry sources describe it as high-res/online PDF rendering. There is also a GitHub user and NPM profile using rendro. This does not mean you cannot use the name, but the brand should deliberately avoid CHILI, prepress, 3D-viewer, and commercial rendering-SDK cues. Use legal/trademark clearance before launch.  ￼

⸻

1. Brand Essence

Brand Name

Rendro

Pronunciation

REN-droh

Name Meaning

Rendro suggests:

* render — generate finished output.
* flow — shape content across pages.
* order — deterministic layout, predictable documents.
* Elixir-native craft — a compact tool name, not an enterprise product name.

One-Line Description

Rendro is an open-source, Elixir-native document layout and PDF rendering library for Phoenix teams that need reliable PDFs without Chrome.

Short Description

Rendro helps Elixir and Phoenix developers build production-grade PDFs as composable document data: pages, frames, blocks, tables, fonts, images, pagination, telemetry, validation, and clean Phoenix integration.

Brand Promise

Make PDF generation feel native to Elixir: composable in code, predictable in layout, observable in production, and honest about limits.

Brand Mantra

Render the document. Respect the system. Explain the failure.

Strategic Positioning

Rendro is not a browser wrapper, not a generic PDF toy, and not a commercial prepress SDK. It is a developer-first document engine for building invoices, statements, reports, certificates, labels, tickets, and operational documents in Elixir.

⸻

2. Positioning Statement

For Phoenix and Elixir developers who need dependable PDF generation in production, Rendro is an open-source document rendering library that provides native layout primitives, automatic pagination, tables, telemetry, validation paths, and Phoenix integration without requiring Chrome, Node, wkhtmltopdf, or runtime browser infrastructure.

Unlike browser-based HTML-to-PDF tools, Rendro treats documents as structured Elixir data and components, making layout more explicit, testable, observable, and production-friendly.

⸻

3. Brand Pillars

1. Native, Not Wrapped

Rendro should feel like Elixir, not like shelling out to a browser.

Use words like:

* native
* pure Elixir
* structured
* composable
* deterministic
* explicit

Avoid words like:

* magic
* pixel-perfect HTML
* browser automation
* headless
* screenshot
* print pipeline

2. Layout That Explains Itself

Pagination, overflow, tables, frames, and fonts are hard. Rendro’s identity should imply clarity, not mystery.

Core message:

When a document renders, you get a PDF. When it fails, you get a useful explanation.

3. Phoenix-First, Core-Pure

Rendro is useful in any BEAM app, but the main emotional home is Phoenix.

Message hierarchy:

1. Pure-Elixir core.
2. Phoenix integration.
3. Oban/telemetry/validation adapters.
4. Optional ecosystem bridges.

4. Production Is a Feature

The brand should not look like a weekend script. It should signal day-2 operations: telemetry, bounded work, validation, fixtures, snapshot tests, and render metadata.

5. Honest Capability

Rendro’s brand voice should be confident but never overclaim. Unsupported cases should be obvious, especially around HTML/CSS, PDF/A, PDF/UA, digital signing, arbitrary PDF editing, and advanced font shaping.

⸻

4. Taglines

Primary Tagline

Native PDF layout for Elixir.

Secondary Taglines

* Reliable PDFs without the browser.
* Documents rendered in Elixir.
* Composable PDFs for Phoenix.
* Build PDFs as data, not screenshots.
* Production PDF generation, the Elixir way.

Avoided Taglines

Avoid these because they sound too close to the historical CHILI Rendro/PDF-rendering-SDK space or imply wrong scope:

* “The PDF rendering SDK.”
* “High-res online PDF rendering.”
* “Render any PDF anywhere.”
* “The browserless PDF viewer.”
* “Perfect HTML-to-PDF for Elixir.”
* “Pixel-perfect PDFs from HTML.”

⸻

5. Brand Personality

Personality Attributes

Attribute	Meaning
Precise	Layout, pagination, coordinates, and output are controlled.
Calm	No hype, no panic, no magical claims.
Helpful	Errors teach the developer what to fix.
Native	Feels idiomatic to Elixir/Phoenix.
Observable	Production behavior is visible and measurable.
Crafted	Documents have typographic and structural care.
Open	Community-first, maintainable, transparent.

Personality Formula

70% senior maintainer, 20% typographer, 10% SRE.

Anti-Personality

Rendro is not:

* flashy
* mascot-heavy
* corporate-enterprise
* print-shop nostalgic
* “AI-generated everything”
* browser-rendering disguised as native
* legal/compliance-overclaiming
* dark-pattern SaaS

⸻

6. Naming System

Canonical Brand Usage

Use:

* Rendro in prose.
* rendro for the Hex package, CLI, config keys, and lowercase technical references.
* Rendro as the Elixir module namespace.

Examples:

{:rendro, "~> 0.1"}
Rendro.Document
Rendro.Layout
Rendro.Table
Rendro.Font
Rendro.Phoenix
Rendro.Renderer

Package Naming

Preferred ecosystem names:

rendro
rendro_phoenix
rendro_oban
rendro_validation
rendro_admin
rendro_typst

Avoid:

rendro_sdk
rendro_viewer
rendro_chili
chili_rendro
rendro3d
rendro_prepress
rendro_html_pdf

Repository / Organization Naming

Because github.com/rendro is already a user profile, do not assume that namespace is available. Stronger OSS org candidates:

rendro-dev
rendro-pdf
rendro-oss
rendro-elixir

Preferred repo:

rendro-dev/rendro

First-Mention Rule

On every important public surface, first mention should include the Elixir-native differentiator:

Rendro is an open-source, Elixir-native PDF layout library.

Not:

Rendro is a PDF rendering SDK.

⸻

7. Visual Identity

Visual Concept

Structured flow.

Rendro’s visual system should combine:

* page frames
* flowing content blocks
* baseline grids
* document margins
* pagination marks
* code-to-document transformation
* quiet paper tactility
* observability traces

The visual metaphor is not “printing.” It is content becoming a reliable document through structure.

Logo Direction

The logo should be simple enough to work in a README badge, Hex package icon, docs header, favicon, and GitHub avatar.

Preferred Mark Concepts

1. R-frame mark
    A geometric “R” built from a page frame and a flowing line.
2. Page-flow mark
    A rectangle/page with a single line turning into a second page, suggesting pagination.
3. Glyph-run mark
    Small horizontal text lines flowing through a frame boundary.
4. Object-tree mark
    Abstract nested rectangles suggesting PDF object structure and page hierarchy.

Wordmark

* Use Rendro, title case.
* The wordmark should feel technical but not sterile.
* Slightly customized “R” and “o” are enough.
* Avoid making the “o” a target, globe, or loading spinner.

Logo Clearspace

Use the height of the lowercase n as minimum clearspace around the mark and wordmark.

Minimum Sizes

Context	Minimum
Full wordmark digital	96 px wide
Mark-only digital	24 px
Favicon	16 px simplified mark
Print/sticker	0.75 in wide

Logo Don’ts

Do not use:

* chili peppers
* flames
* red hot-sauce visual language
* 3D cubes
* printer icons
* Acrobat-style red ribbon marks
* generic PDF document icons
* Elixir droplet as the primary mark
* Chrome/browser window as the hero visual
* “SDK” lockup as the main identity

⸻

8. Color System

Rendro should feel like ink, paper, layout grids, and reliable software. The palette should be calmer than typical devtool neon palettes.

WCAG 2.2 Level AA requires normal text contrast of at least 4.5:1 and large text contrast of at least 3:1; non-text UI indicators and meaningful graphics should meet at least 3:1 against adjacent colors. Use these as the minimum standard for Rendro UI and docs.  ￼

Core Palette

Token	Hex	Use
ink-900	#101827	Primary text, dark logo, nav text
ink-700	#1F2937	Secondary text, dark surfaces
paper-100	#F7F3EA	Main warm background
sheet-000	#FFFFFF	Cards, code panels, document previews
line-300	#D8D2C3	Borders, layout lines, dividers
blue-600	#2C6BED	Primary CTA, links, active states
teal-700	#0E7C76	Success-adjacent technical accent
plum-700	#6E3CB8	Elixir-adjacent secondary accent
amber-600	#C78600	Warnings, pagination notes
red-700	#C24132	Errors
green-700	#147A4B	Success/valid output

Tint Palette

Token	Hex	Use
blue-100	#D9E8FF	Link hovers, callout backgrounds
mint-100	#DDF4EE	Success callouts
plum-100	#E9DDFB	Secondary callouts
sand-200	#EDE4D3	Code block backgrounds, diagrams
paper-200	#EFE8DA	Alternate sections

Contrast-Safe Pairings

Use these freely:

Foreground	Background	Result
ink-900	paper-100	Excellent
ink-900	sheet-000	Excellent
ink-700	paper-100	Excellent
blue-600	sheet-000	Passes normal text
teal-700	sheet-000	Passes normal text
plum-700	sheet-000	Passes normal text
red-700	sheet-000	Passes normal text
green-700	sheet-000	Passes normal text
ink-900	amber-600	Good for warning labels

Use carefully:

Pairing	Rule
blue-600 on paper-100	Avoid for small body text; use for larger links/buttons or darken blue.
amber-600 on white	Do not use as body text. Use amber as background/border with dark ink text.
line-300 on paper-100	Fine for decoration, too subtle for essential UI boundaries.

CSS Variables

:root {
  --rendro-ink-900: #101827;
  --rendro-ink-700: #1F2937;
  --rendro-paper-100: #F7F3EA;
  --rendro-sheet-000: #FFFFFF;
  --rendro-line-300: #D8D2C3;
  --rendro-blue-600: #2C6BED;
  --rendro-teal-700: #0E7C76;
  --rendro-plum-700: #6E3CB8;
  --rendro-amber-600: #C78600;
  --rendro-red-700: #C24132;
  --rendro-green-700: #147A4B;
  --rendro-blue-100: #D9E8FF;
  --rendro-mint-100: #DDF4EE;
  --rendro-plum-100: #E9DDFB;
  --rendro-sand-200: #EDE4D3;
}

Color Ratios by Brand Role

* 60% paper/sheet
* 25% ink/line
* 10% blue
* 5% teal/plum/semantic colors

The brand should not become purple-heavy. Plum can nod to Elixir, but Rendro should own an ink/paper/blue system.

⸻

9. Typography

Primary Typeface

Inter

Use Inter for UI, docs, landing pages, navigation, buttons, labels, and marketing copy. It is designed for computer screens and has a tall x-height that supports mixed-case readability.  ￼

Recommended weights:

Inter Regular     400
Inter Medium      500
Inter SemiBold    600
Inter Bold        700

Code Typeface

JetBrains Mono

Use JetBrains Mono for code blocks, inline code, CLI examples, module names, telemetry event names, and config snippets. JetBrains describes it as adapted to reading code, with increased letter height and an open-source license.  ￼

Recommended weights:

JetBrains Mono Regular  400
JetBrains Mono Medium   500
JetBrains Mono Bold     700

International Fallback

Use Noto Sans as a fallback for broad script coverage. Google Fonts describes Noto as covering more than 1,000 languages and over 150 writing systems.  ￼

Type Scale

Display XL   56 / 64   Inter Bold
Display L    44 / 52   Inter Bold
H1           36 / 44   Inter Bold
H2           28 / 36   Inter SemiBold
H3           22 / 30   Inter SemiBold
Body L       18 / 30   Inter Regular
Body         16 / 26   Inter Regular
Body S       14 / 22   Inter Regular
Caption      12 / 18   Inter Medium
Code         14 / 22   JetBrains Mono Regular
Code S       12 / 18   JetBrains Mono Regular

Typography Style

Use:

* clear hierarchy
* generous line-height
* short paragraphs
* code examples close to explanation
* headings that describe the task

Avoid:

* huge SaaS hero typography with vague claims
* condensed display fonts
* retro typewriter fonts
* decorative serif fonts
* overusing monospace outside code

⸻

10. Layout System

Core Layout Motif

Rendro layouts should visually reference how the library works:

data → document AST → layout → pagination → PDF bytes

Use visual elements like:

* frames
* blocks
* flowing rows
* page breaks
* margin guides
* header/footer regions
* small measurement labels
* page count indicators
* debug overlays

Grid

Use a 12-column responsive grid for landing pages and docs.

Surface	Max Width
Marketing content	1120 px
Docs content	880 px
Code-heavy guides	1040 px
Full app/admin UI	1280 px

Spacing Scale

Use a 4px base scale:

4, 8, 12, 16, 24, 32, 48, 64, 96

Border Radius

Use	Radius
Small controls	6 px
Cards	12 px
Large panels	16 px
Document previews	4 px
Code blocks	10 px

The document preview itself should feel like a sheet of paper, not a rounded SaaS card.

⸻

11. Imagery and Art Direction

Acceptable Imagery

Use:

* rendered document previews
* invoice/report/certificate examples
* clean page-frame diagrams
* annotated layout grids
* pagination diagrams
* code beside generated output
* typography/glyph/fallback diagrams
* telemetry timeline diagrams
* subtle paper texture
* restrained geometric illustrations

Unacceptable Imagery

Avoid:

* stock photos of offices
* printers and copy machines
* chili peppers or spicy imagery
* 3D rendering cubes
* Acrobat-like red PDF swirls
* Chrome/browser screenshots as the hero
* “AI robot making PDFs”
* generic abstract gradients with no document metaphor
* heavy purple Elixir fan-art visuals

Illustration Style

* Monoline or thin filled shapes.
* Mostly ink and line colors.
* One accent color per illustration.
* Use page frames and flow arrows.
* No glossy gradients.
* No skeuomorphic paper stacks.

Diagram Style

Diagrams should look like engineering artifacts:

[Data] → [Document AST] → [Layout Engine] → [Pages] → [PDF]

Use labels like:

Frame: body
Available: 420pt
Required: 486pt
Action: insert page break

This reinforces Rendro’s personality: explicit, useful, inspectable.

⸻

12. Iconography

Icon Style

* 2px stroke.
* Rounded joins.
* Minimal detail.
* 24px base grid.
* Works at 16px.
* No filled emoji-style icons.
* No brand-color rainbow sets.

Core Icon Set

Create icons for:

Icon	Meaning
Page	Document/page creation
Frame	Page templates, margins, regions
Flow	Layout across frames
Table	Tabular reports
Font	Fonts, glyphs, fallback
Image	Image embedding
Link	Annotations/destinations
Pulse	Telemetry
Shield	Validation/policy
Box	PDF object/resource
Stack	Pagination/page tree
Sparkless wand	Do not use; avoid magic metaphor

⸻

13. UI Design System

UI Feel

Rendro UI should look like a precise developer tool with soft document warmth.

Think:

* ExDoc clarity
* Phoenix dashboard practicality
* typographic polish
* low-noise controls
* lots of readable examples

Not:

* enterprise dashboard clutter
* flashy launch-site gimmicks
* over-dark hacker aesthetic
* Figma-plugin neon palette

Primary Components

Button

Primary:

Background: blue-600
Text: sheet-000
Radius: 6px
Weight: Inter SemiBold

Secondary:

Background: sheet-000
Border: line-300
Text: ink-900

Quiet:

Background: transparent
Text: blue-600

Code Block

Background: sand-200 or ink-900
Font: JetBrains Mono
Line height: 1.55
Show copy button
Show language label
No fake terminal prompt unless actual CLI

Callouts

Type	Background	Border	Text
Info	blue-100	blue-600	ink-900
Success	mint-100	green-700	ink-900
Warning	sand-200	amber-600	ink-900
Error	white	red-700	ink-900

Document Preview

Document previews should be shown as real pages:

* white sheet
* subtle shadow
* page size label
* optional margin guides
* optional debug overlay
* page count indicator

Example labels:

A4 · Page 2 of 5
body frame · 48pt margin
table header repeated

⸻

14. Motion

Motion Principles

Motion should explain flow, not decorate.

Use motion for:

* content flowing from one frame to the next
* page break insertion
* table rows paginating
* render pipeline progress
* validation status transitions
* copy-to-clipboard feedback

Avoid:

* bouncy cartoon movement
* confetti
* spinning PDF icons
* loading animations that imply long-running mystery
* 3D page flips

Timing

Micro interaction: 120–180ms
Panel transition: 180–240ms
Diagram animation: 600–1200ms
Easing: ease-out, not springy

⸻

15. Brand Voice

Voice Principles

Rendro sounds like a senior open-source maintainer who respects the user’s time.

Use:

* concrete nouns
* precise verbs
* honest limitations
* short explanations
* helpful next steps
* production-aware language

Avoid:

* hype
* vague claims
* jokes in error messages
* “magic”
* “just works” without proof
* compliance claims before support exists

Tone by Context

Context	Tone
Landing page	Confident, concise, developer-friendly
Docs	Direct, explanatory, example-led
Errors	Specific, calm, actionable
Release notes	Transparent, factual
GitHub issues	Respectful, maintainer-aware
Admin UI	Operational, clear, low-noise
Community	Warm, practical, open

Voice Examples

Good

Build PDF documents as Elixir data, then render them with predictable layout and production telemetry.

Bad

Generate perfect PDFs instantly with magical browserless rendering.

Good

This table row cannot split across the remaining page space. Allow row splitting or start the row on a new page.

Bad

Layout failed.

Good

Rendro does not render arbitrary HTML/CSS. Use document components for reliable layout, or choose an HTML-to-PDF renderer when CSS compatibility is the goal.

Bad

Rendro replaces every PDF tool.

⸻

16. UX Microcopy

Primary CTAs

Get started
Generate your first PDF
View examples
Read the guide
Inspect layout
Validate output
Add Phoenix integration

Secondary CTAs

Browse recipes
Copy snippet
Open in HexDocs
View on GitHub
Compare renderers
See limitations

Status Messages

Building document
Measuring layout
Paginating pages
Embedding fonts
Decoding image
Rendering PDF
Validating output
Uploading artifact
Render complete

Empty States

No render artifacts yet.
Generate a sample PDF to inspect output, page count, file size, and warnings.
No validation report.
Enable validation to check structure, conformance, and common output issues.

Error Pattern

Every error should include:

What happened
Where it happened
Why it happened
What to try next

Example:

Table row overflowed the body frame.
Template: MyApp.PDF.Invoice
Block: document.body.table[2].row[47]
Available height: 18pt
Required height: 42pt
Try allowing row splitting, reducing cell padding, or starting the row on a new page.

⸻

17. Documentation Style

Documentation Promise

A developer should be able to render an invoice in 15 minutes and understand production tradeoffs within an hour.

Docs Structure

1. Introduction
2. Installation
3. Your first PDF
4. Phoenix download
5. Layout basics
6. Text and fonts
7. Tables
8. Images
9. Headers and footers
10. Pagination
11. Telemetry
12. Validation
13. Testing PDFs
14. Deployment
15. Limitations
16. API reference

Guide Style

Every guide should include:

* working code
* rendered result preview
* explanation of primitives
* common failure
* production note
* related APIs

Recipe Names

Use practical recipe names:

Invoice
Receipt
Account statement
Certificate
Shipping label
Event ticket
Monthly report
Table-heavy export
Multi-page report
LiveView preview
Oban render job
S3 upload
Visual snapshot test

Docs Voice Rules

Use:

Do this
This returns
This emits
This fails when
Try this instead

Avoid:

You might want to maybe
It should probably
This magically
Under the hood, we do some stuff

⸻

18. Landing Page Direction

Hero

Headline:

Native PDF layout for Elixir.

Subhead:

Rendro helps Phoenix teams generate reliable PDFs from composable Elixir document components — with automatic pagination, tables, telemetry, validation paths, and no Chrome runtime.

Primary CTA:

Generate your first PDF

Secondary CTA:

View examples

Hero visual:

* code snippet on left
* rendered invoice/report page on right
* subtle layout guides
* tiny telemetry/status strip below

Hero Code Snippet

invoice
|> Rendro.Document.new(page_size: :a4)
|> Rendro.heading("Invoice #{invoice.number}")
|> Rendro.table(invoice.line_items, repeat_header: true)
|> Rendro.footer(page_numbers: true)
|> Rendro.render()

Landing Page Sections

1. No browser required
    Explain why native rendering reduces deployment complexity.
2. Layout primitives that paginate
    Frames, blocks, tables, page templates, headers/footers.
3. Phoenix-ready
    Controller downloads, LiveView preview, asset resolution.
4. Production visibility
    Telemetry, render metadata, validation reports, warnings.
5. Examples gallery
    Invoice, statement, certificate, ticket, report, label.
6. Honest limitations
    Not arbitrary HTML/CSS. Not a PDF editor. Compliance support is explicit and validated.
7. OSS maintainer section
    Contribution guide, roadmap, tests, community expectations.

⸻

19. README Direction

README Opening

# Rendro
Native PDF layout for Elixir.
Rendro is an open-source Elixir library for building PDF documents as composable data and rendering them without Chrome, Node, wkhtmltopdf, or browser automation.

README Feature Bullets

- Pure-Elixir document model
- Flow layout and automatic pagination
- Tables with repeating headers
- Headers, footers, page numbers
- Phoenix controller helpers
- Telemetry events for production renders
- Deterministic output mode for tests
- Clear overflow and asset errors

README Honesty Block

## What Rendro is not
Rendro is not an HTML/CSS-to-PDF renderer, not a browser wrapper, and not an arbitrary PDF editor. It is a native document layout engine for generating new PDFs from Elixir data and components.

⸻

20. Brand Differentiation Rules

Because of the historical CHILI Rendro collision, Rendro OSS must differentiate itself consistently.

Always Signal

Elixir-native
open-source
PDF layout library
Phoenix-friendly
no Chrome runtime
document components

Avoid Signaling

commercial SDK
online PDF viewer
3D preview
prepress workflow
CHILI/pepper/spice
high-res rendering SDK
browser-based viewer

First-Screen Rule

The first screen of the website, GitHub README, and HexDocs intro should make it impossible to confuse Rendro with a commercial PDF viewer SDK:

Rendro is an open-source Elixir-native PDF layout library.

⸻

21. Product UI / Admin UI Direction

For future admin or LiveView preview interfaces, the brand should prioritize inspection over decoration.

Admin UI Features

* template list
* fixture selector
* render preview
* page thumbnails
* warnings panel
* validation report
* render metadata
* visual diff
* download artifact
* publish template version

UI Labels

Use:

Template
Template version
Fixture
Render artifact
Validation report
Layout warning
Overflow
Page count
Byte size
Render duration
Document hash

Avoid:

Magic output
PDF wizard
Super render
Chili
Prepress

⸻

22. Content Examples

Launch Copy

Rendro is a native PDF layout library for Elixir. Build documents as composable data, paginate them predictably, render them without Chrome, and inspect what happened in production.

Docs Intro Copy

Rendro documents are built from pages, frames, blocks, tables, images, fonts, and metadata. The layout engine measures content, inserts page breaks, and produces a render plan before writing PDF bytes.

Production Copy

Every render can emit telemetry for duration, page count, byte size, layout warnings, and failures. Use this data to monitor PDF generation like the rest of your Phoenix app.

Limitations Copy

Rendro does not attempt to implement full HTML/CSS layout. That scope belongs to browser and print-CSS renderers. Rendro focuses on explicit document primitives that are easier to test, paginate, and operate.

⸻

23. Design Tokens

{
  "brand": {
    "name": "Rendro",
    "tagline": "Native PDF layout for Elixir.",
    "personality": ["precise", "calm", "helpful", "native", "observable"]
  },
  "colors": {
    "ink900": "#101827",
    "ink700": "#1F2937",
    "paper100": "#F7F3EA",
    "sheet000": "#FFFFFF",
    "line300": "#D8D2C3",
    "blue600": "#2C6BED",
    "teal700": "#0E7C76",
    "plum700": "#6E3CB8",
    "amber600": "#C78600",
    "red700": "#C24132",
    "green700": "#147A4B"
  },
  "type": {
    "sans": "Inter",
    "mono": "JetBrains Mono",
    "fallback": "Noto Sans"
  },
  "shape": {
    "controlRadius": "6px",
    "cardRadius": "12px",
    "panelRadius": "16px",
    "documentRadius": "4px"
  },
  "motion": {
    "micro": "120ms",
    "panel": "220ms",
    "diagram": "900ms"
  }
}

⸻

24. LLM Context Block

Use this block when asking another model to create Rendro visuals, website copy, docs, UI, or brand assets.

Rendro is an open-source, Elixir-native PDF layout and document rendering library for Phoenix teams. It is not a browser wrapper, not an HTML/CSS-to-PDF renderer, not a PDF viewer SDK, and not a commercial prepress product. The brand should emphasize native Elixir, composable document data, automatic pagination, tables, Phoenix integration, production telemetry, validation paths, and no Chrome runtime.
Brand personality: precise, calm, helpful, native, observable, crafted, open. It should sound like a senior OSS maintainer: specific, honest, practical, and respectful of developer time. Avoid hype, magic claims, enterprise jargon, and compliance overclaims.
Visual identity: structured flow. Use page frames, layout grids, content blocks, pagination, code-to-document diagrams, document previews, and subtle paper/ink warmth. Avoid chili peppers, flames, Acrobat-style red PDF imagery, printers, 3D viewer visuals, generic SaaS gradients, and browser-window hero metaphors.
Primary tagline: “Native PDF layout for Elixir.”
Secondary lines: “Reliable PDFs without the browser.” “Documents rendered in Elixir.” “Composable PDFs for Phoenix.” “Build PDFs as data, not screenshots.”
Colors:
- ink-900 #101827
- ink-700 #1F2937
- paper-100 #F7F3EA
- sheet-000 #FFFFFF
- line-300 #D8D2C3
- blue-600 #2C6BED
- teal-700 #0E7C76
- plum-700 #6E3CB8
- amber-600 #C78600
- red-700 #C24132
- green-700 #147A4B
Typography:
- Primary: Inter
- Code: JetBrains Mono
- International fallback: Noto Sans
Logo direction: simple wordmark plus mark. Preferred mark is an “R” or page-frame symbol that suggests content flowing through document frames. It must work as a GitHub avatar, favicon, Hex package icon, docs header, and README badge. Avoid literal PDF icons, printers, flames, chili imagery, 3D cubes, and Chrome/browser symbolism.
Docs voice: example-led, concrete, and honest. Every guide should include working code, rendered output, common failure, and production note. Error messages should explain what happened, where it happened, why it happened, and what to try next.
UX microcopy examples:
- “Generate your first PDF”
- “Inspect layout”
- “Validate output”
- “Measuring layout”
- “Paginating pages”
- “Embedding fonts”
- “Render complete”
- “Table row overflowed the body frame.”
Public first mention should be: “Rendro is an open-source, Elixir-native PDF layout library.”

⸻

25. Final Creative Direction

Rendro should look and sound like a native document engine made by people who understand both Elixir systems and the pain of production PDF generation.

The brand should be:

* quieter than a SaaS startup,
* warmer than a systems library,
* more precise than a design tool,
* more honest than a “PDF magic” wrapper,
* and clearly distinct from any commercial PDF rendering/viewing SDK.

The north star:

Rendro turns Elixir data into reliable documents — with layout you can reason about and renders you can operate.