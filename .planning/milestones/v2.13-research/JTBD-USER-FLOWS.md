# Rendro JTBD Map and Gap Analysis

Last updated: 2026-05-23

## Purpose

This memo is the durable planning companion to the public "User Flows and Jobs To Be Done" guide.

Use it when you want to answer four questions:

1. Which user jobs does Rendro already support well?
2. Which jobs are only partially supported or poorly packaged?
3. Which gaps should influence milestone ordering next?
4. At what point does more JTBD mapping stop being high-leverage work?

## Reader and post-read action

Primary reader: maintainer or product-minded engineer planning future Rendro milestones.

Post-read action: decide whether a new milestone should improve onboarding, workflow closure, trust proof, or core capability breadth, and justify that choice in concrete user-flow terms.

## Current JTBD map

### A. First-use adoption jobs

These are the jobs a Phoenix SaaS engineer hits in the first few days.

| Job | Current state | Notes |
|---|---|---|
| Generate a PDF from app data in-request | strong | Builder API, flow/fixed entry points, Phoenix adapter, invoice recipe, branded invoice path |
| Choose recipe vs custom composition | medium | Supported in code and README, but the user story has been scattered across docs |
| Understand flow vs fixed layout | medium | Core API is stable, but the decision aid has been weaker than it should be |
| Produce one branded business document | medium-strong | Font/image registration and branded recipe exist; packaging is credible |
| Learn the library through one canonical walkthrough | weak | No single "start here if you are building a SaaS export/invoice/report" narrative until this docs task |

### B. Production workflow jobs

These are the jobs teams hit once the first document is live.

| Job | Current state | Notes |
|---|---|---|
| Queue renders in background jobs | medium-strong | Oban worker is intentionally narrow and truthful |
| Attach artifacts to transactional email | medium | Mailglass path exists, but end-to-end workflow packaging is still light |
| Persist/store artifacts with metadata | medium | Artifact and storage seams exist; not yet presented as one batteries-included journey |
| Debug layout or render failures | strong | Diagnostics, telemetry, typed errors, and Inspector are strong product behavior |
| Enforce render limits and bounded execution | strong | Policies are narrow and operator-friendly |

### C. Trust-sensitive jobs

These are the jobs where proof burden matters more than API surface area.

| Job | Current state | Notes |
|---|---|---|
| Protect a PDF for password-to-open delivery | strong | Narrow artifact-first story, proof-backed boundaries |
| Prepare a PDF for external signing | strong | Explicit preparation seam and truthful support language |
| Sign an artifact through one supported path | strong | Existing-field signing path is shipped and proof-backed |
| Add long-lived evidence and validate posture | strong | `sign -> augment -> validate` path shipped in v2.2 |
| Know which viewers are actually proven | weak-medium | This is the active v2.3 gap and the main truth/adoption blocker |

### D. Rich-document jobs

These jobs matter when the PDF is more than a printable report.

| Job | Current state | Notes |
|---|---|---|
| Add forms to authored PDFs | medium-strong | Narrow but useful widget set; viewer proof still incomplete |
| Add document-level attachments | medium-strong | Supported and structurally proven; viewer story not fully closed |
| Add curated links | strong | Useful scope, explicit constraints, proof-backed in supported viewers |
| Support broader international text needs | weak-medium | Some bidi/shaping work exists, but global shaping/script support remains a conditional future milestone |

## What comparable ecosystems teach us

These references are useful not because Rendro should copy them literally, but because they reveal what users expect from a serious document library.

### QuestPDF

- Official docs center onboarding around a concrete invoice tutorial and a clean quick-start path.
- Lesson for Rendro: the first-class story should be a complete business-document journey, not just API reference and composable primitives.
- Reference:
  - https://www.questpdf.com/invoice-tutorial.html
  - https://www.questpdf.com/concepts/generating-output.html

### WeasyPrint

- Official docs package common use cases such as invoices, attachments, metadata, and PDF forms in one discoverable place.
- It also benefits from the familiarity of HTML/CSS, which makes use-case discovery easier even when correctness tradeoffs differ.
- Lesson for Rendro: product docs should cluster around user jobs, not just features.
- Reference:
  - https://doc.courtbouillon.org/weasyprint/stable/common_use_cases.html

### ChromicPDF

- The value proposition is obvious: render HTML or URLs to PDF inside Elixir/Phoenix workflows.
- Lesson for Rendro: some users will compare against "print the HTML I already have." Rendro docs should address when authored deterministic layout is a better fit and when browser-backed rendering may still be the simpler choice.
- Reference:
  - https://hexdocs.pm/chromic_pdf/0.4.0/ChromicPDF.html

### Prawn

- Prawn's manual demonstrates breadth, mature examples, and practical topics like repeatable content, metadata, and security.
- It also shows the downside of very broad PDF surface area: users can infer stronger support than the maintainers actually want to stand behind.
- Lesson for Rendro: breadth is attractive, but truthfulness and proof discipline are a differentiator worth preserving.
- Reference:
  - https://prawnpdf.org/manual.pdf

## Highest-value gaps now

These are ordered by user impact, adoption leverage, and fit with Rendro's current strategic arc.

### 1. Viewer proof and interop closure

Why it matters:

- Several advanced flows already exist, but users still cannot answer "will this work in the viewer my customers use?" with enough confidence.
- This is now the largest gap between technical capability and adoption trust.

Why it should stay early:

- It unlocks stronger claims across forms, protection, signature widgets, signing preparation, signed artifacts, and long-lived evidence.
- It compounds the value of work already shipped instead of widening scope.

Status:

- Already aligned with active milestone `v2.3`.

### 2. Batteries-included workflow closure

Why it matters:

- A lot of real product value already exists, but it is still packaged more like "excellent parts" than "one obvious Phoenix path."
- Teams adopting Rendro want one recommended workflow for sync render, queued render, protected delivery, email delivery, and audit visibility.

What it likely means:

- Canonical end-to-end Phoenix/Oban/Mailglass/Threadline walkthroughs
- More cookbook-quality examples
- A shorter path from "I need an invoice/export" to "this is how I run it in production"

Status:

- Already aligns with candidate milestone `v2.4`.

### 3. Global text shaping and broader script support

Why it matters:

- This is a real adoption boundary for teams with multilingual or RTL-heavy needs.
- It can be a deal-breaker for specific markets.

Why it should not leapfrog everything:

- It is a large core investment with high proof burden.
- The adoption payoff is huge for some teams but not universal for the average Phoenix SaaS integrator.

Status:

- Correctly positioned as a conditional later candidate, not the immediate next milestone.

### 4. Richer canonical recipes beyond invoice

Why it matters:

- Recipes are where adoption speed becomes tangible.
- Every widely needed document family with a strong recipe reduces time-to-first-success dramatically.

Good future targets:

- statements
- receipts
- simple reports
- certificates or letters only if demand is real

Why this is not above viewer proof:

- Packaging more recipes before trust/interop closure risks widening the "looks impressive, still hard to trust" gap.

## Lower-priority or likely-niche gaps

These are real possibilities, but they should not drive the roadmap by default.

- Multi-signature workflows and signer orchestration
- HSM/key-custody stories in core
- Broad annotation/comment/review workflows
- Existing-PDF editing and fill-in on arbitrary third-party documents
- Generic HTML/CSS rendering inside the core library
- Very broad viewer claims without per-surface proof

These can attract attention because they sound enterprise-grade or feature-complete, but most of them either widen the truth surface too quickly or pull Rendro away from its authored deterministic core.

## Recommended prioritization rule

When choosing among future JTBD gaps, favor work that scores well on all of these:

1. It solves a job many Phoenix SaaS teams actually hit.
2. It shortens time-to-first-production-use.
3. It reinforces the core deterministic/authored/truthful product identity.
4. It reuses or closes value around already shipped seams.
5. Its proof burden is manageable relative to the user value.

By that rule, the current ordering still makes sense:

1. viewer proof and interop closure
2. batteries-included workflow and adoption closure
3. broader script/global text support if demand remains strong

## What "feature-complete enough" should mean here

Rendro does not need to implement all of PDF to feel done for its intended market.

A reasonable "feature-complete enough" line for the current product identity looks like this:

- a new Phoenix SaaS team can generate and deliver branded business PDFs quickly
- the recommended sync and async production workflows are obvious
- common operational concerns have one truthful answer
- trust-sensitive flows have one proof-backed happy path each
- viewer support claims are explicit, not guessed
- the most common rich-document surfaces are covered without scope creep

If those conditions are met, Rendro is probably "done enough" for the majority of expected users even if it still lacks broader PDF-platform features.

## Diminishing-returns boundary for future JTBD work

Further JTBD research likely hits diminishing returns once all of these are true:

- the public guide already covers the dominant adoption journeys
- the remaining open gaps are mostly niche, enterprise-specific, or geographically narrow
- new research keeps rediscovering the same few deferred themes
- roadmap choices are being driven more by proof burden and implementation cost than by user-flow ambiguity

At that point, future refreshes should be lightweight delta passes:

- what shipped since last time
- which gap closed
- whether priority order changed
- whether any new job has emerged from real user demand

## Suggested maintenance loop

When this prompt is rerun later:

1. Re-read the public guide and confirm whether the dominant user journeys changed.
2. Compare current `README`, guides, support matrix, and milestone arc against this memo.
3. Update this memo with:
   - newly shipped jobs
   - closed gaps
   - reordered priorities
   - any fresh diminishing-returns signal
4. Only rewrite the public guide if the actual user-flow map changed, not just because more roadmap detail exists.

## Current bottom line

Rendro is no longer missing core capability so much as it is missing workflow closure and trust closure.

The biggest wins now are not "add another isolated feature." They are:

- prove viewer behavior where claims still stall adoption
- package one obvious production workflow for Phoenix teams
- keep broadening capabilities only where the new surface clearly earns its proof burden
