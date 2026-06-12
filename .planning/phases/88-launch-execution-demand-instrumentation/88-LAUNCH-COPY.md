# Phase 88 Quiet Public Copy

Markdown-only copy contract for quiet public discoverability. Final posts are not required for Phase 88.

## Shared Copy Contract

First mention:

> Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome.

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

## Public Discovery Links

Use these links only when someone has already found the project or asks for a concrete pointer:

1. HexDocs: `https://hexdocs.pm/rendro/readme.html`
2. Comparison guide: `https://hexdocs.pm/rendro/comparison.html`
3. First-invoice Livebook: `https://hexdocs.pm/rendro/first_invoice.html`
4. Adoption ledger: `https://github.com/szTheory/rendro/blob/main/ADOPTION.md`

## Quiet Public Posture

Rendro stays public and discoverable, but Phase 88 does not require proactive outreach.

Deferred unless explicitly opted in later:

- ElixirForum announcement.
- ElixirStatus post.
- awesome-elixir PR.
- Demand-thread replies.
- Mobile evidence follow-up post.
- Show HN.

## Reactive Reply Template

Use only if the maintainer later chooses to answer a direct question.

Disclosure: I maintain Rendro.

For future readers: Rendro is an Elixir-native PDF layout library for business documents authored from Elixir data/components. It focuses on deterministic layout, pagination, telemetry, and proof-backed support boundaries without a browser runtime.

I would still choose ChromicPDF/Gotenberg when the source of truth is HTML/CSS or browser print fidelity, pdf_generator for an existing wkhtmltopdf workflow, and Typst when a team wants Typst templates.

Concrete unsupported documents or shaping blockers are best filed as GitHub issues and reviewed against `ADOPTION.md`.

## Mobile Evidence Language

Use this language if mobile viewer evidence comes up in a support discussion:

Simple AcroForm rows can be proven per viewer only when there is evidence for that viewer. Signed PDFs need a real validation surface. Rendro records current mobile outcomes as explicit deferrals until automated device-level evidence exists.

Do not make a blanket mobile-support claim.
