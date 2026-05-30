# User Flows and Jobs To Be Done

This guide is for the Phoenix engineer who is about to use Rendro in a real app and wants the shortest honest answer to one question:

**What job is this library good at, and which path should I take?**

If you finish this guide, you should be able to choose the right Rendro path for your SaaS document workflow and implement the first production-credible version without reverse-engineering the library.

## The simplest mental model

Rendro is easiest to understand if you split your work into two moments.

**Moment 1: author the document.** You decide what the document is, where content flows, how pages break, and which optional surfaces it needs: branding, forms, links, attachments, or signature widgets.

**Moment 2: operate on the artifact.** Once the PDF exists, you can deliver it in a Phoenix response, queue it in Oban, audit it through telemetry and Threadline, password-protect it, sign it, augment it with long-lived evidence, validate it, store it, or attach it to an email.

That split explains most of the API:

- `Rendro.flow/2` and `Rendro.fixed/2` are document-authoring entry points.
- `Rendro.Document` and the recipe modules help you compose a document deliberately.
- `Rendro.render/2` and `Rendro.render_to_artifact/2` are the fork in the road between "just give me the PDF" and "I need the PDF plus operational metadata and follow-on steps."

## The jobs Rendro already does well

### 1. "Give my user a PDF right now"

This is the most common first job in a SaaS app.

You have invoice data, statement data, or a report payload in a controller or service. You want to turn it into a deterministic PDF and return it as a download or preview.

Start here:

- Use a canonical recipe if your document looks like a business document.
- Use `Rendro.Adapters.Phoenix` to return or preview the rendered PDF from a controller.
- Stay synchronous until you actually feel queue pressure.

This is the "happy path" Rendro wants to make boring: data in, document assembled in Elixir, PDF out.

### 2. "I need a respectable invoice or statement without inventing a layout system"

This is where the recipe story matters.

Rendro ships canonical recipes such as `Rendro.Recipes.Invoice` and `Rendro.Recipes.BrandedInvoice`. They exist to save you from building page templates, regions, and common document structure from scratch when the real job is "ship the invoice."

Think of the recipe path as a ladder with three rungs:

- `document/2`: use the whole recipe and render it.
- `page_template/1`: keep the layout, swap the content.
- `sections/2`: keep the content, inject it into your own document shell.

The practical meaning is simple: you can start batteries-included, then peel back layers only when your product actually needs it.

### 3. "My document is not a standard invoice; I need to control layout"

This is where Rendro stops being a recipe library and becomes a document engine.

Choose between two authored shapes:

- **Flow** when your content should fill regions and paginate naturally.
- **Fixed** when every block belongs at an explicit coordinate.

The pattern that helps most teams is:

- Use named page-template regions for anything with headers, body areas, or footers.
- Put width and break intent on blocks, not on raw text.
- Reach for fixed positioning only when the PDF really is a form, label, certificate, or coordinate-driven layout.

If you already know Phoenix and Ecto, the `Rendro.Document` builder style should feel familiar: build a struct, pipe it through explicit transforms, render only when the document is ready.

### 4. "This render belongs in the background, not in my web request"

This is the async delivery job.

Rendro's Oban worker exists for the narrow version of that job: build a document from a known module and args, render it, write it to an output path, and enforce bounded render policies.

Use this path when:

- PDFs can be generated after the request returns.
- You want to keep queue args small and business-oriented.
- You need clear failure shapes for missing modules, invalid args, or policy violations.

Do not use this path as a generic "throw arbitrary render settings into a job" escape hatch. Rendro keeps the worker intentionally narrow so your async contract stays explicit and safe.

### 5. "I need to know what happened in production"

This is the observability job.

Rendro treats telemetry, diagnostics, and artifact metadata as part of product behavior, not as afterthoughts.

You have three main surfaces:

- Telemetry for operational spans and production instrumentation.
- `render_with_diagnostics/2` when you need the final laid-out document plus structured warnings and layout details.
- Threadline integration when every render outcome should land in an audit trail.

If you are the person who gets paged when PDFs fail at 2am, this is one of Rendro's strongest stories already. The library wants failures to come back as typed, inspectable outcomes instead of folklore.

### 6. "The PDF is not just text on pages"

This is the richer-document job. Rendro already supports several important surfaces, but each one is intentionally narrow.

You can:

- add forms for text fields, checkboxes, radio groups, and unsigned signature widgets
- attach embedded files at the document level
- add curated links to external `http`/`https` targets or internal pages
- register fonts and images for branded output

You should not assume Rendro is trying to become a giant everything-PDF toolkit. The design bias is narrow useful surfaces with explicit boundaries, not a sprawling "maybe the PDF spec supports it" API.

### 7. "I need delivery, protection, or signing after render"

This is the trust-sensitive artifact job.

Once a PDF exists, Rendro supports a sequence of increasingly serious steps:

1. Render the document.
2. Turn it into an artifact when you need metadata and follow-on operations.
3. Optionally protect it for password-to-open delivery.
4. Optionally sign it through the supported artifact-first signing seam.
5. Optionally augment the signed artifact with long-lived evidence.
6. Validate the resulting posture explicitly.

The important thing to remember is that these are artifact-stage operations. Rendro does not try to hide them inside `render/2` because doing so would blur too many trust and operational boundaries.

## Choose your path

| If your job is... | Start here | Move deeper when... |
|---|---|---|
| Return a PDF from a controller | Recipe + Phoenix adapter | you need a custom layout or artifact-stage operations |
| Produce a branded invoice fast | `Rendro.Recipes.BrandedInvoice` | your document stops looking like the canonical recipe |
| Build a custom report with natural pagination | `Rendro.flow/2` + page templates + sections | you need exact coordinates instead of flow regions |
| Place content at exact positions | `Rendro.fixed/2` | you later discover the layout is really a flowing document |
| Run renders off-request | Oban render worker | you need a broader app-owned async contract |
| Debug layout behavior | `render_with_diagnostics/2` + inspector | production observability and auditing matter too |
| Deliver a protected or signed artifact | `render_to_artifact/2` + protect/sign/validate | you need long-lived evidence or viewer-proof discipline |

## What Rendro is not trying to be

This matters because choosing a library is partly about understanding what it refuses to pretend to do.

Rendro is not currently trying to be:

- an HTML-to-PDF browser runtime
- a generic existing-PDF editing toolkit
- a kitchen-sink annotation or review-workflow engine
- a broad enterprise-signing platform with multi-signature orchestration
- a library that makes portability claims before the proof exists

That restraint is not accidental. A large part of Rendro's value is that its docs and support matrix try to match reality closely.

## A practical first week with Rendro

If you were adopting Rendro in your own SaaS this week, a sensible sequence would be:

1. Render one canonical invoice or statement synchronously in a controller.
2. Add branding only after the basic document shape is stable.
3. Move to page templates and sections when product requirements stop fitting the recipe.
4. Add `render_with_diagnostics/2` and telemetry before the first production rollout.
5. Only then decide whether the workflow needs Oban, protection, signing, or long-lived evidence.

That order keeps you learning the engine in the same order your product risk rises.

## Where teams usually go next

Once the first document ships, the next question is usually one of these:

- How do we queue and deliver this safely?
- How do we standardize branded templates across document families?
- Which trust-sensitive path is actually supported today?
- Which viewer behaviors are proven and which are still unverified?

Those are not side questions. They are the next layer of the product. Rendro already has real answers for many of them, and the rest are exactly where the current roadmap is focused.
