# Milestone A — R4: Cross-Ecosystem Prior-Art & Pitfalls (the toy→production gap)

**Milestone:** v2.10 / Milestone A — "Realistic Business-Document Examples & Anatomy" (SEED-002)
**Lens:** What makes example/showcase strategy DRIVE ADOPTION vs. become dead weight — plus the specific footguns of adding a large example corpus + two new recipes + a public-API promotion to a mature 1.0 library.
**Researched:** 2026-07-10
**Confidence:** HIGH on ecosystem lessons and SemVer/golden pitfalls (well-documented, cross-checked); MEDIUM on the exact quantitative reader-quality thresholds (rubric direction is sound; specific pt sizes are illustrative, not prescriptive).

> Scope note: this report is LENS 4. It deliberately does **not** re-derive per-family document anatomy (that is LENS 1) or the theming-token contract (Milestone B). It answers: *is the "realistic examples + rubric + stress matrix + one additive API change" shape the right instrument, what have other ecosystems learned about it, and where are the landmines?*

---

## 1. Executive read (for the impatient)

The milestone's thesis is **correct and well-precedented**: across every mature doc/UI/PDF ecosystem, examples are not documentation garnish — they are the primary adoption surface, and toy examples ("Widget A", "Acme Corp") actively *suppress* adoption because evaluators cannot see themselves in the output. Rendro already did the hard part (a deterministic, hash-checked, proof-backed engine); the remaining gap is that the showcase under-sells the engine. Closing it with realistic fictional-business fixtures, a reader-quality rubric, and a hash-checked stress matrix is squarely the pattern that Prawn, Stripe, shadcn/ui, and Typst all used to win.

The risk is **not** the thesis — it's the *execution surface*. This milestone simultaneously: (a) adds a large data corpus to a package that has an exact-allowlist tarball audit, (b) promotes a `@moduledoc false` internal (`Rendro.Format`) into the SemVer-committed public surface, (c) changes the canonical `Invoice` recipe's shape, and (d) adds two new recipes. Each of those is individually low-risk; together they are four different ways to accidentally widen the public contract or break the "toy call still works" promise. The single highest-leverage discipline is to keep **industries as DATA and the corpus as dev/test-scoped**, and to treat the `Format` promotion as the one irreversible decision that deserves its own scrutiny.

---

## 2. Ecosystem "did right / did wrong → lesson for Rendro"

| Project | Did RIGHT | Did WRONG / cautionary | Lesson for Rendro Milestone A |
|---|---|---|---|
| **Prawn (Ruby PDF)** | The **manual is a PDF built by Prawn itself** — the showcase *is* the proof. "Treat examples/manuals as product, not afterthought" (from Rendro's own prior deep-research). Rich examples for tables, flowing text, repeaters. | Explicitly does **not** follow SemVer for experimental APIs; "bug fixes can change behavior" — users must read release notes. Ambiguity about what's stable bit adopters. | Keep the dogfooding: the gallery/manual should be rendered *by Rendro* and hash-checked (it already is via `mix rendro.launch_artifacts.gen`). But do the OPPOSITE of Prawn on stability: the `Format` promotion must land in the machine-checked `public_api.json` tier with an explicit stability tag, not an informal "probably stable." |
| **ReportLab (Python, PLATYPUS)** | Clean separation of *content* (Flowables) from *page layout* (DocTemplates/Frames) — the reason it scales to real reports. Ships runnable sample scripts. | `multiBuild` multi-pass TOC layout is a known source of oscillation/non-determinism; samples can drift from the shipped API. | Rendro's determinism discipline already avoids the multiBuild trap. For the corpus, mirror ReportLab's *content vs. layout* split as **data (`priv/examples/`) vs. recipe (`lib/`)** — the corpus must never encode layout, only realistic data. |
| **Typst template gallery** | Deterministic layout + a **template gallery organized by document kind** (invoice, CV, report). "Same format / different data" is the exact high-volume JTBD Rendro serves. Good errors. | Templates live in a fast-moving ecosystem; some community templates rot against language versions. Template maintenance + input-asset management called out as the tradeoff. | Organize the catalog **by document family, brand-tagged** (already the locked decision) — matches Typst's winning axis. Guard against rot by hash-checking every catalog artifact in CI (Rendro's superpower Typst lacks). |
| **shadcn/ui** | Copy-paste **ownership** over dependency: users copy source into their app, no "npm-install black box," no waiting on maintainer PRs. Galleries/blocks let people start from something that *looks like their screen*. Massive adoption. | The flip side: no central version to patch; consumers own drift. Not applicable to a compiled engine, but the "copy the code" instinct matters. | Rendro's escape-hatch (`document/2` → `page_template/1` → `sections/2`) is the equivalent of "copyable source." Each catalog entry should show the **copy-paste-able recipe call + the escape-hatch override**, so an evaluator sees both "one-liner" and "I can own it." Make the snippet the hero, like shadcn blocks. |
| **Stripe docs / receipts** | Docs are the **primary conversion channel**: choose a goal → copy a working example → run it → expand. Realistic data, immediately runnable, "looks like my use case." Built a $90B+ business on docs-as-adoption. | N/A — this is the gold standard to emulate. | The rubric + realistic fixtures should optimize **time-to-"that looks like my invoice."** Every catalog doc should be traceable to a real JTBD (the family×domain matrix already does this: Nimbus SaaS invoice, Halden & Roe VAT, etc.). Make the fixtures *runnable* in the Livebook/Phoenix example, not just static PNGs. |
| **Tailwind UI / shadcn blocks** | "67 examples you can copy today" — breadth of *realistic* compositions (dashboards, pricing, auth) is the product. Progressive disclosure: zero-to-one block → customizable primitives. | Paid/large galleries can become dead weight if examples aren't *maintained* against the core. | Breadth matters but each entry must be rubric-gated and hash-checked, or the catalog rots into dead weight (Milestone C makes it a standing ratchet — good). Don't ship a big catalog that isn't CI-enforced. |
| **`rails new` / Phoenix generators** | Scaffolds produce **realistic, opinionated, working** starting points, not empty stubs. Sets the quality bar by example. | Generated code can bit-rot vs. framework; scaffolds sometimes teach anti-patterns that stick. | The realistic fixtures + upgraded `Invoice` are Rendro's "scaffold." They must model **best-practice** document structure (the rubric enforces this) — because whatever the canonical Invoice does, every adopter copies. |
| **LaTeX invoice/CV template repos** | Enormous long-tail of realistic templates; people adopt LaTeX *because* a template already looks like their use case. | Fragmented, unvetted quality, PII/real-logo leakage in community templates, trademark misuse. | This is the direct cautionary tale for the **fake-PII / trademark footgun**: the plan's use of invented businesses (Nimbus Analytics, Northwind Provisions, Halden & Roe, etc.) is exactly right. Never use a real company name, VAT number, or logo, even as a "placeholder." |
| **Storybook (visual regression)** | Made "component states as reviewable snapshots" a first-class workflow; visual regression as a quality ratchet. | Snapshot **brittleness + reviewer fatigue**: when snapshots fail for irrelevant reasons, teams blindly click "update" and the tests become noise. | Rendro's goldens are byte-hash + pdfium raster, which is *more* deterministic than DOM snapshots — but the human-review failure mode still applies. Golden updates must be **rare, intentional, and reviewed** (see §4). |
| **PrawnEx / Mudbrick / Paddlefish (Elixir peers)** | Validate demand for pure-Elixir PDF; PrawnEx is honest about limits (no auto-pagination, overflow is user's problem). | Thin examples, no realistic corpus, no rubric — they *look* like toys, which caps evaluation. | This is precisely the gap Rendro is closing. The realistic corpus is the differentiator that makes Rendro read as production-grade next to the Elixir peers. High-leverage. |

---

## 3. The toy→production example gap — synthesis

**Why toys suppress adoption (not just "look unpolished"):**

1. **Evaluators pattern-match on recognizability, not features.** Stripe's entire docs strategy is "copy a working example that looks like your goal." An invoice that says "Widget A / Acme Corp / $10.00" gives an evaluator nothing to map onto their SaaS-subscription-with-VAT reality. A `Nimbus Analytics` invoice with tiered line items, proration, tax, and a totals block that survives a page break *does*. The realistic fixture is a **recognizability surface**, and recognizability is the conversion event.

2. **The canonical example sets the ceiling, not the floor.** Whatever `Rendro.Recipes.Invoice` renders is what every adopter copies and what every evaluator assumes is "the best it does." Today the canonical Invoice has no addresses/tax/totals/money formatting while `Receipt`/`Statement` are richer — so the *flagship* recipe undersells the engine. The additive A2 upgrade fixes the ceiling. This is the single most important adoption lever in the milestone.

3. **Progressive disclosure is the adoption ramp.** The winning galleries (shadcn, Typst, Stripe) all offer: zero-to-one (copy the one-liner) → escape hatch (own the source). Rendro's three-rung pattern already is this; the corpus must *demonstrate both rungs per family* so an evaluator sees "easy default" and "I won't hit a wall."

4. **The one realistic fixture is quarantined.** `bench/comparison/fixtures/invoice_data.json` is the only realistic data and it's locked in the bench harness. De-quarantining it into a shared `priv/examples/` corpus (A1) and repointing the bench at it is pure leverage: one artifact serves benchmarks, catalog, guides, and tests. **Single source of realistic truth** is the pattern.

**What makes a corpus adoption-driving vs. dead weight** (the dividing line):

| Adoption-driving | Dead weight |
|---|---|
| Realistic, domain-true data an evaluator recognizes | Generic "Item 1 / $1.00" placeholders |
| Rubric-gated + hash-checked in CI (can't rot) | Unmaintained, drifts from the API silently |
| One shared fixture source (bench + catalog + guides + tests) | Duplicated fixtures per surface that diverge |
| Shows both the one-liner and the escape hatch | Only shows the happy-path one-liner |
| Fictional businesses (safe, invented) | Real names/logos/VAT numbers (legal risk) |
| Data-only; industry lives in data, not modules | Per-industry recipe modules (surface-area sprawl) |

---

## 4. Golden-file / quality-ratchet patterns (and their pitfalls)

Rendro is unusually well-positioned here: it already has **byte-deterministic SHA-256 artifacts + pdfium raster refs + a docs-contract lane**. That is a stronger substrate than the DOM-snapshot world most "golden test" advice is written against. But the *human* failure modes still apply, and Milestone C turns the catalog into a *standing* ratchet, so getting the discipline right now matters.

**The quality-ratchet pattern that works (what to adopt):**

- **Two-layer goldens.** (1) *Byte/structural* goldens (SHA-256 of the PDF) catch any determinism regression — the strict, cheap, non-negotiable gate. (2) *Raster* goldens (pdfium PNG refs) catch visual regressions the byte hash can't explain to a human. Rendro already has both; the stress matrix (A5) extends layer 1, the catalog (A6/C) extends layer 2.
- **Rubric-as-ratchet.** Score each template 1–5 (information architecture, hierarchy, least-surprise, reader affordances, typographic craft, domain-fit) with a threshold (all ≥4, hierarchy =5). Track scores across the grid over time so the bar only rises. This is exactly how "golden tests in AI" quality suites work: a scored baseline that regressions must not fall below. **The rubric is the quality ratchet; the hashes are the determinism ratchet.** Keep them distinct instruments.
- **Errors-as-product goldens.** The stress matrix should assert that overflow → typed `:content_overflow` error, RTL → instructive raise, single-row-taller-than-body → typed error. Golden the *error*, not just the success. Rendro's culture already does this (v2.4 recipe `ArgumentError` discipline).

**The pitfalls (documented failure modes to design against):**

1. **Brittleness / noise.** Snapshot tests that fail for irrelevant reasons train developers to ignore failures — "erosion of trust is more dangerous than having no snapshot tests at all" (Kreya). *Prevention:* byte goldens should only change when output *intentionally* changes; the additive A2 upgrade must keep the toy `id`/`date`/`items` call **byte-identical** (see footgun #3), so unrelated goldens don't churn.
2. **Reviewer fatigue / rubber-stamping.** When many goldens update at once, reviewers "stop analyzing the diff and blindly press Update Snapshot to get the build green" (teachmeidea, testthat). A milestone that adds a big corpus + new recipes will generate a *large* first golden commit — the exact condition that trains rubber-stamping. *Prevention:* land goldens in **small, per-family commits** with a human rubric pass per batch; never one mega-commit of hundreds of new goldens. Make the *first* generation of each artifact a reviewed event.
3. **Non-determinism leaks into goldens.** The classic PDF determinism traps: map/key ordering, float money (use Decimal — the plan already does), embedded timestamps (`/CreationDate`), locale in formatted output, font-subset ordering. Any of these makes a golden flap and destroys trust. Rendro has fought these before and has a determinism gate, but the *new* fixtures/recipes are fresh surface. *Prevention:* every new golden must pass the existing byte-determinism SHA check across two runs before it's committed; keep `Rendro.Format` locale-free by construction (already a locked decision).
4. **Golden bloat / cost.** A large raster corpus is heavy to store and slow to diff. *Prevention:* byte-hash is the primary gate (cheap); raster refs are advisory and scoped. Don't raster every stress cell — raster the *catalog* (visual), byte-hash the *stress matrix* (determinism).

---

## 5. Footguns for THIS milestone (ranked, with prevention)

Ranked by (likelihood × blast radius). Each maps to a concrete guardrail Rendro already has or should add.

### 🔴 F1 — Promoting `Rendro.Format` into the SemVer-committed public surface (the freeze risk) — HIGHEST
**What goes wrong:** `Rendro.Format` is currently `@moduledoc false`. A2 promotes it to the public adapter tier. Per Hyrum's Law, "with enough users, all observable behaviors will be depended on" — once public, the *exact* money/date output strings, function arity, option names, and rounding behavior become a frozen contract you cannot change without a major bump. Rendro is `1.0.0` on hex.pm under a strict two-tier SemVer contract; this is an **irreversible** decision.
**Why it's #1:** It's the one thing in the milestone that can't be walked back, and it's easy to under-scrutinize because it "already exists and works."
**Prevention:**
- Treat the promotion as its own reviewed decision, not a side-effect of A2. Decide the tier deliberately — likely **Tier-2 "Evolving" (adapter)**, not Tier-1 Stable, so its output strings can evolve without a major bump. The plan already says "adapter tier" — hold that line.
- Freeze the **smallest useful surface**: promote only the functions the recipes actually need publicly; keep helpers `@doc false`. Smaller public surface = smaller Hyrum's-Law exposure (Nordic APIs / effective-rust).
- Add it to `priv/public_api.json` with an explicit `@spec` (the existing contract lane enforces this) + a migration note.
- Assert its output in goldens so *you* control when its behavior changes — but document that adapter-tier output can evolve, so adopters don't hard-depend on exact strings.

### 🔴 F2 — Example-corpus BLOAT in the core Hex package
**What goes wrong:** `priv/examples/` (JSON fixtures + per-domain `DOMAIN.md` + schemas), curated fonts (later, C), and raster refs get shipped in the published Hex tarball, bloating the package for every adopter who never runs the examples. Rendro has an **exact-allowlist tarball content audit** (from v2.5) — so a new `priv/examples/` tree will either (a) fail the audit (good, forces a decision) or (b) get allowlisted without thinking (bad).
**Prevention:**
- Decide *explicitly* what ships. Realistic fixtures used by **runtime** recipes/tests may need to ship; the *large* catalog/raster/`DOMAIN.md`/bench-only fixtures should be **excluded** from the package (dev/test-scoped), mirroring the ecosystem norm of excluding test assets/examples from the published artifact (e18e / webpack authoring guidance). Rendro already excludes B1's website tokens and `scrypath_ops`-style siblings — same discipline.
- Keep the `package.files` allowlist tight; let the tarball audit be the gate. Every new `priv/` path is a conscious "ship or dev-only" decision, recorded.
- Prefer **one canonical fixture set** loaded by a dev/test-scoped loader (A1 already specifies "out of the public API manifest") over sprinkling fixtures across surfaces.

### 🟠 F3 — Additive Invoice change that breaks the toy call OR the public-API contract lane
**What goes wrong:** A2 adds optional `:issuer`/`:customer`/`:due_date`/`:terms`/`:totals`. If any becomes required, or if the default rendering path changes, the existing toy `Invoice` call (`id`/`date`/`items`) breaks — a SemVer-major violation on a 1.0 library. Separately, changing the recipe's public signature can trip the `public_api_contract_test.exs` drift lane.
**Prevention:**
- **Byte-identical guarantee for the legacy call.** Add a golden that renders the pre-upgrade toy call and asserts its SHA-256 is unchanged after the upgrade. "Additive" must be *proven*, not assumed. (This also protects against F4's golden churn.)
- New fields strictly optional with sane defaults; new behavior only activates when new fields are present.
- Regenerate `public_api.json` (`mix rendro.api.gen`) and review the diff — the contract lane fails on unreviewed drift by design (v2.5). That's a feature; expect it and read the diff.
- Errors-as-product: malformed new fields raise structured `ArgumentError`, not `BadMapError` (the v2.4 Phase 77 discipline).

### 🟠 F4 — New recipes (Payslip/Ticket) widening the "family vs. industry" boundary
**What goes wrong:** Payslip and Ticket are legitimate *families* (like Invoice/Statement/Certificate). The footgun is scope drift: a "restaurant ticket" vs. "event ticket" vs. "support ticket" invites per-industry recipe modules, and payslips invite jurisdiction-specific tax modules. That violates the permanent boundary: **industries must be DATA + thin compositions, never modules** (PROJECT.md, EPIC.md, and the plan's three-layer reconciliation).
**Prevention:**
- Payslip/Ticket are *families* on the 3-rung pattern over existing primitives — no new engine capability, no per-jurisdiction logic in `lib/`. Jurisdiction/industry variation lives in `priv/examples/` data + escape-hatch compositions.
- `Rendro.Format` stays **locale-free by construction** (locked decision) — no CLDR/gettext/tax tables in core. Payslip tax math is *caller-supplied data*, not engine logic.
- Register in `public_api.json` + `support_matrix.json` as families with terminal rows, same as v2.4 recipes. Two new families, not two new industry verticals.

### 🟡 F5 — Coupling examples/corpus to test-only code
**What goes wrong:** The bench harness, the golden tests, the catalog generator, and the guides all reach into one fixture loader. If that loader or the fixtures depend on `test/support` or bench-only modules, you either leak test code into the shipped package or create a load-order tangle that breaks `mix test` vs. `mix rendro.launch_artifacts.gen`.
**Prevention:**
- The A1 fixture loader is **dev/test-scoped and explicitly out of the public API manifest** (already specified). Keep it dependency-light and standalone (parse JSON from `priv/examples/`), usable by bench, tests, guides, and the gen task without any `test/support` coupling.
- Repoint the bench at the shared fixture (already planned) so there's exactly one realistic-data source and no divergence.

### 🟡 F6 — Determinism traps in the new goldens
**What goes wrong:** Fresh fixtures/recipes reintroduce map-ordering, float-money, timestamp, or locale non-determinism into goldens — the classic PDF flapping. (Covered in §4.3; listed here as a ranked milestone footgun because A5 adds many new goldens at once.)
**Prevention:** Decimal money (planned); locale-free `Format`; two-run SHA equality before commit; no `/CreationDate` or wall-clock in output; deterministic key ordering in serialization (Rendro's existing determinism gate). The stress matrix's own byte-determinism cell (SHA-256) is the enforcement.

### 🟡 F7 — Fake-PII / trademark issues in "realistic" fixtures
**What goes wrong:** "Realistic" tempts real company names, real logos, real VAT/EIN numbers, real addresses, real people — creating trademark misuse or fake-PII that looks like a data leak. This is the documented LaTeX-template-repo failure mode.
**Prevention:** The plan already names **invented** businesses (Nimbus Analytics, Northwind Provisions, Halden & Roe, Cedar Mutual, Vantage Health Plan, Aurora Live, Rivet Payroll, etc.) and invented people. Hold that line rigorously: fictional names, obviously-fake tax IDs (e.g., reserved/invalid ranges), invented addresses, and Rendro's own placeholder logo — never a real brand mark, even as a "demo." Add a one-line note in each `DOMAIN.md` that all entities are fictional.

---

## 6. Reader-quality / information-design sanity check (is a rubric the right instrument?)

**Verdict: yes, a scored rubric is the correct instrument** — and the external evidence strongly validates the rubric's *direction*, especially the "one key fact must be the visual anchor" criterion.

Cross-industry invoice/transactional-document design guidance converges on exactly the rubric's priorities:
- **A single dominant fact.** "The Total Amount Due should be the largest or boldest number on the page; the Due Date second" (Pricefic, invoicely). This is precisely the plan's hierarchy criterion (amount due / net pay / closing balance must score 5 as the visual anchor). The rubric is not arbitrary taste — it encodes a documented design principle.
- **Scan-path affordances.** Readers scan in an F-pattern; critical info belongs top-left/top-right. Tabular money, aligned columns, "find the amount owed in under 5 seconds." Maps to the rubric's "reader affordances" and "scan path" criteria.
- **Restraint.** One-or-two font families, consistent margins, generous whitespace, ≥4.5:1 contrast. Maps to "typographic craft" and (later) to Milestone B's unbranded-default and theming constraints.
- **Business impact is real.** Well-designed invoices reportedly get paid ~15% faster; ~61% of late payments blamed on confusing/incorrect invoice info (invoicely/Pricefic — MEDIUM confidence on exact figures, but directionally consistent across sources). This is the "adoption-driving" case for the rubric in concrete terms: better documents are a *product outcome*, not vanity.

**Caveats for the rubric (so it doesn't become dead weight):**
- Keep it a **scored, thresholded, tracked** instrument (all ≥4, hierarchy =5) — a checklist reviewers actually score, not prose. That's what makes it ratchet (Milestone C tracks scores over time).
- The specific pt sizes in the external guidance (16–18pt for totals, etc.) are *illustrative* — Rendro's rubric should score *relative* hierarchy and craft, not hard-code numeric type sizes (that's Milestone B's type-scale concern). Defer exact per-family anatomy to LENS 1; the rubric only needs to sanity-check that a document *has* a clear anchor, scan path, and craft.
- Don't over-fit the rubric to invoices — Payslip (net pay is the anchor), Statement (closing balance), Ticket (event/seat/QR) each have a *different* dominant fact. The rubric's "the ONE key fact per family" framing already handles this; keep it family-parameterized.

---

## 7. Sanity-check verdict

**The milestone's overall approach is sound and well-precedented — ship it, with three guardrails.**

- The **thesis is right**: examples are the adoption surface, toys suppress adoption, and Rendro's engine is under-sold by its showcase. Every mature ecosystem (Prawn, Stripe, shadcn/ui, Typst, `rails new`) won on exactly this move. The realistic corpus is the differentiator that makes Rendro read as production-grade next to PrawnEx/Mudbrick.
- The **structure is right**: data-first corpus (industries as data), one additive `lib/` change, two new *families* (not industries), a scored rubric as the quality instrument, and hash-checked goldens as the determinism instrument. This respects every permanent boundary (pure core, family-not-industry, deterministic, proof-backed).
- The **discipline already exists**: exact-allowlist tarball audit, `public_api.json` contract lane, byte-determinism gate, pdfium raster refs, errors-as-product culture. The milestone mostly needs to *use* the guardrails it already has, deliberately.

**The three guardrails that convert "sound plan" into "safe ship":**
1. **Prove additivity by hash.** Golden the legacy toy `Invoice` call and assert its SHA is unchanged post-A2. "Additive" must be a test, not a claim.
2. **Land goldens in small reviewed batches**, per-family, to defeat reviewer-fatigue rubber-stamping — never one mega-commit.
3. **Decide the `Format` promotion tier explicitly and minimally** (adapter/Evolving, smallest surface), because it is the one irreversible act in the milestone.

### 🎯 The single biggest risk to watch

**The `Rendro.Format` promotion (F1).** It is the milestone's only irreversible decision: once `Format` is public on a 1.0 library, Hyrum's Law freezes its observable output (money/date strings, arity, options, rounding) into a SemVer contract you can't quietly change. Everything else in the milestone is additive data or new families that can be revised; this one hardens forever. Scrutinize it as its own decision — pick the **adapter/Evolving tier**, freeze the **smallest** surface, spec it, and document that its formatted output may evolve — so a convenience helper promotion doesn't silently become a permanent liability.

---

## 8. Sources

**External (this research):**
- shadcn/ui copy-paste ownership & adoption — [LogRocket adoption guide](https://blog.logrocket.com/shadcn-ui-adoption-guide/), [ui.shadcn.com/docs](https://ui.shadcn.com/docs), [Medium: shadcn copy-paste](https://medium.com/@dc0/shadcn-has-done-it-again-cad209b16181), [67 shadcn examples](https://converter.brightcoding.dev/blog/stop-building-ui-from-scratch-67-shadcn-examples-you-can-copy-today)
- Snapshot/golden test pitfalls (brittleness, reviewer fatigue, rubber-stamping) — [Kreya: API snapshot testing](https://kreya.app/blog/api-snapshot-testing/), [teachmeidea: snapshot benefits & pitfalls](https://teachmeidea.com/snapshot-testing-benefits-pitfalls-when-to-use/), [testthat snapshotting](https://testthat.r-lib.org/articles/snapshotting.html), [Shaped: golden tests in AI](https://www.shaped.ai/blog/golden-tests-in-ai)
- Hyrum's Law / SemVer freeze risk of exposing internals — [Laws of Software Engineering: Hyrum's Law](https://lawsofsoftwareengineering.com/laws/hyrums-law/), [Effective Rust: understand what SemVer promises](https://effective-rust.com/semver.html), [Nordic APIs: Hyrum's Law for API design](https://nordicapis.com/what-does-hyrums-law-mean-for-api-design/)
- Keeping the published package small / excluding examples & fixtures — [e18e: bundling dependencies (and when not to)](https://e18e.dev/blog/bundling-dependencies), [webpack: authoring libraries](https://webpack.js.org/guides/author-libraries/)
- Invoice/transactional information hierarchy (validates the rubric) — [Pricefic: psychology of invoice design](https://www.pricefic.com/post/hidden-psychology-invoice-design-makes-clients-pay-faster), [invoicely: professional invoice design](https://invoicely.timelinedigi.com/blog/articles/05-create-professional-invoices-design-tips-templates.php), [FreshBooks: what an invoice looks like](https://www.freshbooks.com/hub/invoicing/design-an-invoice)
- Stripe docs / examples as the adoption channel — [Moesif: Stripe DX & docs teardown](https://www.moesif.com/blog/best-practices/api-product-management/the-stripe-developer-experience-and-docs-teardown/), [Mintlify: how Stripe creates the best docs](https://www.mintlify.com/blog/stripe-docs), [apidog: why Stripe's docs are the benchmark](https://apidog.com/blog/stripe-docs/)

**Internal (mined, not re-derived):**
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Prawn "treat examples/manuals as product," Prawn/ReportLab/Typst/fpdf2/PrawnEx ecosystem lessons, "same format / different data" JTBD, golden-fixture/visual-snapshot needs.
- `.planning/PROJECT.md`, `.planning/EPIC.md` — pure-core & family-not-industry permanent boundaries, two-tier SemVer contract, `public_api.json` contract lane, exact-allowlist tarball audit, errors-as-product culture, locale-free `Rendro.Format` decision.
- `~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md` — the 4-milestone program, the family×domain matrix with fictional businesses, the stress matrix, the rubric definition, and the locked decisions this report sanity-checks.
- `prompts/rendro-oss-dna.md` — docs-contract, reference-app-in-CI, optional-dep discipline, tight-package-boundary DNA.

---
*R4 Prior-Art & Pitfalls research for Rendro Milestone A (SEED-002). Researched 2026-07-10.*
