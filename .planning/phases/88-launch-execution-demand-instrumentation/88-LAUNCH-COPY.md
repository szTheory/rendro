# Phase 88 Launch Copy

Markdown-only copy contract and draft workspace for the public launch. Final posts must be maintainer-authored, checked against the launch checklist, and published only after all blocking gates are ready.

## Shared Copy Contract

First mention:

> Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome.

Demand-thread disclosure:

> Disclosure: I maintain Rendro.

Demand-thread framing must include `for future readers` near the top.

Decision-guide posture:

- Rendro fits business documents authored from Elixir data where deterministic layout, pagination, telemetry, and no browser runtime matter.
- ChromicPDF and Gotenberg fit teams whose source of truth is HTML/CSS or browser print fidelity.
- pdf_generator fits teams already invested in wkhtmltopdf or Chrome-headless workflows.
- Typst fits teams that want `.typ` templates and Typst's layout language.

Claim boundaries:

- Do not describe Rendro as a Prawn clone or drop-in replacement.
- Do not imply Rendro renders arbitrary browser markup.
- Do not make compliance promises for archival or accessibility standards.
- Do not promise universal viewer behavior.
- Do not imply full Arabic, Hebrew, Devanagari, Thai, RTL, or cluster-aware shaping coverage beyond the support matrix.
- Keep signed-PDF statements separate from certificate trust and viewer validation UI.

## ElixirForum Hub

Title: `Rendro: Elixir-native PDF layout without Chrome`

Category: `News > Announcing`

Tags, when available: `library`, `pdf`

Link budget: 4-6 links maximum.

Structure:

1. What Rendro is.
2. Why it exists.
3. What works today.
4. Proof links.
5. Honest boundaries.
6. Feedback request.

Proof links to include:

- Rendered gallery/manual and manual SHA.
- Comparison guide.
- First-invoice Livebook.
- Support matrix or API stability guide.

Draft notes:

- Lead with the gallery/manual SHA/Livebook/comparison proof cluster.
- Use measured tradeoffs, bounded support, and Phoenix-team language.
- Ask for concrete document jobs and unsupported surfaces, not generic interest.

## ElixirStatus Short Post

Link budget: 3 links maximum.

Draft:

Rendro: Elixir-native PDF layout without Chrome. The launch thread shows rendered recipe gallery, byte-reproducible manual, comparison guide, Livebook tutorial, and support boundaries for Phoenix teams evaluating PDF generation.

Links:

1. ElixirForum hub URL: TBD
2. HexDocs URL: `https://hexdocs.pm/rendro/readme.html`
3. First-invoice Livebook URL: `https://hexdocs.pm/rendro/first_invoice.html`

## awesome-elixir PR

Wording under `PDF`:

`Rendro - Elixir-native PDF layout library with deterministic pagination and no browser runtime.`

Link budget: 1 repo link.

Checklist:

- Sort alphabetically in the PDF section.
- Use the repository URL, not a planning artifact.
- Open after public docs are live.

## Chromium Demand-Thread Reply

Thread: `PDF generation without Chromium dependency`

Link budget: 3 links maximum.

Draft skeleton:

Disclosure: I maintain Rendro.

For future readers looking for PDFs from Elixir data without carrying a browser runtime, Rendro may fit the business-document case: deterministic layout, pagination, telemetry, and proof-backed boundaries.

ChromicPDF/Gotenberg are still the better fit when the document source is browser markup or print CSS. Rendro is the fit when the PDF is authored from Elixir data/components and the team wants reproducible output.

Links:

1. Public repo or HexDocs: `https://hexdocs.pm/rendro/readme.html`
2. Comparison guide: `https://hexdocs.pm/rendro/comparison.html`
3. First-invoice Livebook: `https://hexdocs.pm/rendro/first_invoice.html`

Route concrete unsupported documents or shaping blockers to GitHub issues and `ADOPTION.md`.

## Prawn-like Demand-Thread Reply

Thread: `Looking for a Prawn-Like PDF Generation Library in Elixir`

Link budget: 3 links maximum.

Draft skeleton:

Disclosure: I maintain Rendro.

For future readers: Rendro is not a Prawn clone, but it covers the native-Elixir, data-driven business-document lane with deterministic pagination and no browser runtime.

If your team wants arbitrary browser markup, use ChromicPDF/Gotenberg. If your templates already live in Typst, use Typst. If your current flow depends on wkhtmltopdf or Chrome-headless wrappers, pdf_generator may be the lower-friction bridge.

Links:

1. Public repo or HexDocs: `https://hexdocs.pm/rendro/readme.html`
2. Comparison guide: `https://hexdocs.pm/rendro/comparison.html`
3. First-invoice Livebook: `https://hexdocs.pm/rendro/first_invoice.html`

Route concrete unsupported documents or shaping blockers to GitHub issues and `ADOPTION.md`.

## Mobile Follow-Up

Title: `What happens when a Rendro PDF reaches a phone?`

Core message:

Simple AcroForm rows can be manually proven per viewer; signed PDFs need a real validation surface; Rendro records both outcomes in the support matrix.

Link budget: forum hub plus evidence docs.

Draft notes:

- Publish after Plan 88-04 records the mobile rows.
- Keep the story about evidence outcomes, not blanket phone coverage.
- Name supported rows and explicit deferrals separately.

## Show HN Deferred

Status: deferred and non-blocking.

Use only when GitHub, HexDocs, and Livebook provide a no-signup try path and a maintainer can answer comments live.

Title shape:

`Show HN: Rendro - Native PDF layout for Elixir without Chrome`
