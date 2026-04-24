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

The library should feel like idiomatic Elixir: small composable data structures, pure transformations, pipelines, behaviours, supervision-friendly integrations, telemetry, ExDoc guides, and clear errors. The winning path is not to out-Chrome Chrome; it is to give Phoenix teams a reliable native document engine with first-class layout, pagination, operations, and validation.