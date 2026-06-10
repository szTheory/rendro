# Research Summary — v2.6 Public Launch & Adoption Bootstrap

**Milestone:** v2.6 Public Launch & Adoption Bootstrap
**Researched:** 2026-06-10 (five parallel research agents: repo vision/state digest; global text shaping; release automation + automated render verification; layout/recipes primitives; post-1.0 adoption strategy)
**Decision context:** choosing v2.6 from seven deferred candidates after `rendro 1.0.0` shipped to hex.pm (2026-06-05).

## Executive summary

**Rendro is feature-deep and adoption-invisible.** Measured June 2026: ~856 lifetime hex downloads (essentially all self/CI), 0 GitHub stars/forks/watchers, no ElixirForum announcement ever, absent from awesome-elixir. ChromicPDF (Chrome-based incumbent) has ~1M downloads traceable to one forum thread + one differentiated blog post. Two live ElixirForum threads ask for exactly Rendro's category and conclude it doesn't exist:

- "PDF generation without Chromium dependency" — https://elixirforum.com/t/pdf-generation-without-chromium-dependency/68211
- "Looking for a Prawn-Like PDF Generation Library in Elixir" — https://elixirforum.com/t/looking-for-a-prawn-like-pdf-generation-library-in-elixir/67278

The roadmap's own rule — "v2.7 global text shaping only if adopter demand justifies it" — is an open circuit at zero visibility. The in-niche cautionary tale is `mudbrick`: pure-Elixir PDF writer, 12 releases in 11 months, no launch work, stalled at 2.8k downloads. **v2.6 is therefore a launch/adoption milestone, not a feature milestone.**

## Two blocking truth/polish findings

1. **Claim-accuracy liability (must fix before launch):** `harfbuzz_ex ~> 1.2` (rustybuzz Rust NIF, bus-factor-1, ~755 downloads) is a **hard** dependency (`mix.exs`), so the "pure Elixir / no external dependencies" positioning is currently inaccurate. Also: `unicode_data 0.8.0` is dead (last release 2019, ~Unicode 11 tables), and `lib/rendro/pipeline/measure.ex` `split_graphemes` (~line 601-650) shapes one grapheme at a time — a latent width bug for any joining script (Arabic).
2. **Visible polish gap:** tables draw **no borders/rules** today — path operators (`re`, `S`, `f`, `q/Q`, etc.) exist only inside form-field appearance XObject streams (`lib/rendro/pdf/writer.ex` ~1278-1410). A visual gallery would showcase borderless tables. A declarative `%Rendro.Path{}` primitive is ~20 deterministic PDF operators on an existing writer pattern — the lowest-risk engine item researched.

## Why each candidate won/lost

| Candidate | v2.6 verdict | Key evidence |
|---|---|---|
| **Public launch & adoption** | **WINNER** | Oban (forum thread + recipes series), ChromicPDF (one thread → ~1M downloads), Typst (HN + Universe gallery), pdf-lib (live-demo site + roundup posts), Prawn (self-rendered manual.pdf). arXiv study (2506.12643): HN promotion measurably increases forks/stars/contributors. |
| Claim-accuracy/shaping hygiene | **In scope (first phase)** | Truth gate before launch; iText pdfCalligraph seam precedent (shaping behind optional load, hard error not silent garbage). |
| Path primitive + borders | **In scope** | Table-stakes in every comparator (Prawn/ReportLab/fpdf2/Typst all had graphics before TOC/charts); needed so the gallery shows well. |
| Pdfium raster lane | **In scope** | ~80% built (`Rendro.Adapters.Pdfium` wraps pdfium-cli `info`/`form`; just add `render`); enables gallery + Typst-style golden-PNG regression harness that de-risks every future layout feature. |
| Mobile viewer evidence | Folded in as launch content (2–4 rows) | Real pain (Adobe KB: form data missing on mobile; signature validation absent on mobile) but highest value now is a publishable finding, not matrix completeness. |
| Global text shaping | **Defer to conditional v2.7** (gate becomes measurable in the launch phase) | fpdf2: ~6 expert-months for shaping alone; ReportLab: still "experimental" after a year; iText: paid add-on (pdfCalligraph). Zero recorded Elixir demand. Thin honest slice documented in ARCHITECTURE.md for v2.7. |
| release-please | Defer | BEAM norm is manual/semi-manual (ecto/oban/req/jason: no publish workflow; ash: git_ops; tesla: release-please with a PAT). GITHUB_TOKEN won't trigger downstream workflows → needs a PAT credential on an irreversible pipeline, to save minutes/year. `git_ops` is the cheap future alternative. |
| Multi-signature workflows | Defer (optional hedge: counter-signing recipe doc) | DocuSign-shaped demand — hard part is signer identity/UX/audit-trail, not PDF bytes. pyHanko already supports what a future milestone would need (DocMDP, FieldMDP, sequential incremental updates). |
| Charts / TOC | Defer (designs documented) | Charts = DX scope sink (ReportLab's chart module panned for years; SVG-to-PDF is a documented trap). TOC has a clean no-fixpoint reserve-space design that fits the existing substitution machinery (see ARCHITECTURE.md) but demand is book/report-shaped. |
| Even/odd headers, section restart | Defer | Trivial extensions of `suppress_on` + token machinery; duplex is a print-shop concern, zero pull. |

## Locked phase structure (83–88)

1. **Phase 83 — Claim-accuracy & shaping hygiene**: harfbuzz_ex optional behind `Rendro.Text.Shaper` behaviour; pure-Elixir `Shaper.Simple` in core; fix per-grapheme bug; `unicode_data` → `ex_unicode`; `explicit_deferral` matrix rows for complex scripts.
2. **Phase 84 — Drawn-path primitive + visible polish**: declarative `%Rendro.Path{}`; table rules/borders/header bands; Certificate `border:` frame; determinism goldens.
3. **Phase 85 — Deterministic raster lane**: `Pdfium.render/2` (pinned); golden-PNG snapshot harness; advisory CI lane; `viewer_kind: "pdfium-render"` vocabulary.
4. **Phase 86 — Self-proving launch artifacts**: visual recipe gallery (CI hash-checked); self-rendered `manual.pdf` + published SHA-256; brand-book-conformant presentation (prompts/Rendro Brand Book.txt).
5. **Phase 87 — Comparison page + Livebook lane**: reproducible benchmarks vs ChromicPDF/pdf_generator/Typst-CLI; `.livemd` tutorial + ExDoc Livebook badges, executed in CI.
6. **Phase 88 — Launch execution + demand instrumentation**: ElixirForum/ElixirStatus/awesome-elixir/demand-thread replies/optional Show HN; mobile-evidence content beat; concrete v2.7 shaping demand gate + ADOPTION.md ledger.

## Coherence

Truth fix (83) → output worth showing (84) → tooling to show it (85) → artifacts that prove it (86–87) → launch that routes existing demand (88) → closes the loop the conditional-v2.7 rule requires. No phase widens the engine contract; determinism and proof-backed claims are load-bearing in every artifact. **The proof culture is the marketing asset** — a byte-reproducible manual with a published hash, checked-in benchmark lanes, and an honest viewer matrix are claims no competitor can copy.

See: FEATURES.md (per-candidate detail + adoption playbooks), ARCHITECTURE.md (integration points + deferred designs), PITFALLS.md (footguns), STACK.md (dependency decisions).
