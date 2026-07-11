# Milestone A (SEED-002 / v2.10) — Research Synthesis & Locked Recommendation

**Milestone:** v2.10 "Realistic Business-Document Examples & Anatomy" (hex `1.1.0`, additive minor).
**Program context:** Milestone A of the 4-milestone Happy-Path Home Runs program (A realistic examples → B theming → C presets+catalog → D optional Studio). Phase numbering continues at **114**.
**Method:** 5 parallel research lenses (R1 domain/rubric, R2 API/DX, R3 example-data arch, R4 prior-art/pitfalls, R5 coherence/pillars). Full reports in `.planning/research/milestone-a/R1..R5-*.md`.

## Direction verdict — GREEN. Ship it.

All five lenses independently confirm SEED-002 is **not a pivot and not churn** — it closes the real
toy→production gap while the "organized by document family, never by industry / examples-as-data" boundary
holds cleanly across all of A→D. The canonical `Rendro.Recipes.Invoice` currently *under-sells* the engine
(it sets the ceiling every adopter copies); the additive upgrade is the highest adoption lever available.
Payslip + Ticket are the right two new families (on-thesis, named in the brand book, each adds genuinely new
anatomy/layout muscle). A reader-quality rubric is the right instrument.

**Version:** additive minor **v2.10 / hex `1.1.0`**, NOT v3.0 — A2 is strictly additive (toy call preserved
byte-identical), `Format` goes to the *adapter/Evolving* tier, new families are adapter-tier modules. Unlike
C1 (infra), A changes `lib/`, so it IS a versioned release.

## The single irreversible act (guard it)

**Promoting `Rendro.Format` from `@moduledoc false` into the public SemVer surface** is the milestone's only
one-way door — Hyrum's Law freezes its output (money/date strings, arity, rounding) forever on a 1.0 library.
Mitigation (locked): **adapter/Evolving tier** (not Tier-1 Stable), smallest useful surface (`money/1`,
`date/1`, `label/1`), `@spec` into `public_api.json`, and a doc note that formatted output may evolve. Treat
it as its own reviewed decision. Also requires editing Phase-79's `public_api_contract_test.exs` hidden set —
the likeliest surprise red build.

## Right-sized phase list — fold 7 → 5 (coarse granularity; precedent: v2.4 Phase 75 shipped 2 recipes at once)

- **Phase 114 — Domain research + reader-quality rubric + realistic example-data library.** Per-domain
  `DOMAIN.md`; schema-backed rubric manifest; `priv/examples/<domain>/<business>/<family>.json` + loader;
  de-quarantine `invoice_data.json`; repoint bench. (Folds seed A0+A1.) No `lib/` product change except the loader.
- **Phase 115 — Invoice anatomy upgrade + `Format` public promotion.** Additive optional
  issuer/customer/due_date/terms/totals + Decimal money + totals-kept-with-last-rows; promote `Format` to
  adapter tier; `validate_data!/1`; the **palette seam (S1)** lands here; update `public_api.json` + migration
  note + contract lane. (The only real product `lib/` change.)
- **Phase 116 — Payslip + Ticket families.** Two recipes on the 3-rung pattern; register in
  `public_api.json` + `support_matrix.json`.
- **Phase 117 — Edge-case stress matrix.** Deterministic hash-checked goldens + pdfium raster refs +
  errors-as-product assertions across the family × dimension grid.
- **Phase 118 — Rubric-gated demonstration set + gallery + docs closure.** Family×domain matrix rendered via
  recipes + escape hatch; each doc cites its `DOMAIN.md` and passes the rubric; expand `assets/rendro/gallery/`
  + `artifacts.json`; reconcile `support_matrix.json`; update README/guides/Livebook/phoenix_example.

## Shape-now seams (cheap in A, breaking if deferred) — attach as acceptance criteria

- **S1 (highest leverage): private `palette(opts)` per recipe keyed on SEED-003's locked color roles**
  (`ink`/`muted`/`accent`/`on_accent`/`background`/`surface`/`rule`), defaulting to today's literals. Sections
  never inline `{0,0,0}`. Turns Milestone B's `theme:` threading into a one-line swap instead of a 6-recipe
  color rewrite. Lands in Phase 115 (and applied to new recipes in 116).
- **S4: fixture schema models the fictional business with an OPTIONAL `brand`/`logo` sub-object** (empty in A)
  so Milestone C drops `brand.json`/`logo.svg` into existing `<business>/` dirs without re-keying `priv/examples/`.
- **S5: record the reader-quality rubric as a schema-backed *appendable* manifest** (`priv/quality/rubric_scores.json`
  + schema + docs-contract lane enforcing structure + threshold arithmetic, not the subjective score) so C's
  standing "quality ratchet" just appends. Author the contract in 114, populate in 118.
- **S6: add optional `theme`/`mode`/`preset` tags to `artifacts.json` now** so C's catalog grid explosion
  doesn't re-key the hash manifest.

## Locked API/architecture decisions (from R2 + R3)

- **A2 = additive layering, zero renames.** Freeze `:id`/`:date`/`:items`; new keys optional, absent ⇒ not
  rendered. Per-value money opt-in: bare number `price` stays `"$#{price}"`; `%Decimal{}` routes to
  `Format.money/1`; new money fields are Decimal-only and reject Float instructively. Totals: **validate
  (via `Decimal.equal?/2`), don't auto-compute**; render only when `:totals` present; reuse `Recipes.Pagination`
  for keep-with-last-rows. Reuse existing family shapes (`%{name: ...}` parties, Statement `period`, Receipt
  `totals`) so the contract is learned once.
- **errors-as-product:** add `Invoice.validate_data!/1` raising a four-part `ArgumentError`; fix the
  `opts → struct!` leak now by adopting Statement's `Keyword.take` whitelist in `page_template/1` across
  Invoice/Payslip/Ticket. Keep top-level `opts` open so B's `theme:` is purely additive.
- **Family shapes:** Payslip = Statement-shaped flow recipe (anchor = net pay; two side-by-side
  Earnings/Deductions regions + YTD + net-pay box). Ticket = Certificate-shaped fixed-box recipe (anchor =
  seat/gate/section; single page; overflow → typed error).
- **Loader (load-bearing):** `lib/rendro/examples.ex`, **`@moduledoc false`** — the only placement serving
  tests + bench(`:dev`) + Livebook + shipped consumers while staying out of `public_api.json`. NOT
  `test/support` (invisible to bench/Livebook), NOT a Mix task.
- **Fixtures:** money as decimal **strings** (`"79.00"`), never JSON floats. New `priv/schemas/examples.schema.json`
  (repo-only, never ships) validated by a docs-contract lane folded into the required `test` job.
- **Packaging:** ship `priv/examples/` **text-only** (`.json`/`.md`/`.svg`), enforced by a raster-ban test
  mirroring `brand/`; add to `mix.exs` allowlist + tarball audit. Unlocks Livebook/C/D/consumer use; negligible
  size; avoids a later breaking "suddenly ships" change.
- **De-quarantine safely:** `git mv` verbatim → repoint 4 bench refs + `guides/comparison.md` + docs-contract →
  `mix rendro.comparison.check` green → normalize money to strings — split "move verbatim" from "normalize
  money" so the rename is provably a no-op against bench (which is advisory, so no required gate is at risk).

## Reader-quality rubric (durable A0 artifact, reused A→D)

6 core 1–5 dimensions (information architecture; **content hierarchy — the ONE key fact is the visual anchor,
MUST score 5**; domain-fit/least-surprise; reader affordances; typographic craft; restraint/cohesion) + 2
pass/fail gates (reading-order, print-safety). Concrete 1/3/4/5 anchors written for non-designers. Threshold:
**hierarchy = 5, core ≥ 4, gates pass**; A5/117 edge fixtures are explicitly exempt from the beauty gate.

## Honest-affordance findings (engine constraints — plan against, don't assume away)

- **No text/cell right-align primitive today.** Conventional right-aligned money is impossible; the honest
  affordance is a fixed-width Amount column with `Format`-normalized values. A small additive
  **`cell_align: :right`** is the single highest-leverage typographic upgrade — flagged as a Phase-115
  candidate, but the rubric must NOT assume it.
- **No barcode/QR primitive.** Ticket "reads as a ticket" via a boxed code-area + human-readable reference +
  perforation line + optional **caller-supplied PNG** code image — turns a limitation into a recognizable,
  deterministic affordance.

## Design pillars (internal consistency) + guards

Determinism/byte-repro (static fixed-date fixtures) · **accessibility reality: do NOT claim tagged-PDF/PDF-UA —
guard "production-grade" wording** · performance/package-size (exclude goldens + raster-refs from tarball) ·
locale-free engine (differences are DATA; pick one jurisdiction per example) · **no real PII (Payslip is the
acute risk — fictional employees only)** · additive SemVer (public-tier freeze on `Format`) · proof-backed
claims (every new family needs support_matrix + tests + evidence) · family-not-industry · errors-as-product ·
single pipeline.

**Named tensions:** richer corpus vs Hex tarball size; realism vs determinism+security+locale-free; "award-
quality" marketing vs accessibility honesty.

## One correction to seed wording (verify, not a blocker)

The seed calls the quarantined `invoice_data.json` a "real addresses" fixture; it is already fictional. No PII
issue, but verify during 114 de-quarantine.

## Sequencing coherence

A does not paint B/C/D into a corner given S1/S4/S5/S6. B adds nothing to `priv/examples/` (themes are code);
C drops brand data into existing business dirs + appends rubric scores + tags artifacts; D is a read-only
consumer. "Design systems = code, brands = data" holds throughout. SEED-003/004/005 stay deferred as B/C/D.
