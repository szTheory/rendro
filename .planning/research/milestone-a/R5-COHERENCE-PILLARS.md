# R5 — Coherence, Sequencing & Design-Pillars Sanity-Check (Milestone A / SEED-002)

**Lens:** Does anything in Milestone A create lock-in or friction for B/C/D? What seams must A leave open? Enumerate + apply every design pillar. Is A0–A6 right-sized? Direction verdict.
**Program:** A (SEED-002 realistic examples) → B (SEED-003 theming) → C (SEED-004 presets + catalog + configurator) → D (SEED-005 optional Studio).
**Reviewed:** 2026-07-10 · **Confidence:** HIGH (grounded in the shipped recipe code, `Rendro.Format`, `text.ex`, `public_api.json`/`support_matrix.json` discipline, and the locked seed decisions).

---

## Executive Verdict (read this first)

**The direction is right and it is NOT a pivot** — A fills the confirmed gap (toy → production examples + Invoice anatomy + two new families) while the family-not-industry boundary holds cleanly. **Churn risk is LOW *if and only if* four cheap "shape-now" seams are honored in A;** skip them and B forces a 6-recipe color rewrite and C/D force breaking re-keys of the fixture and gallery manifests. The single highest-leverage action: **A2/A3 recipes must read colors from a private per-recipe palette keyed on SEED-003's already-locked role names — never inline `{0,0,0}` — while exposing nothing public.** A is an **additive minor** (hex `1.1.0`; milestone label v2.10), not a v3.0/2.0.0 — nothing breaks.

**Key nuance found in the code:** the "realistic" invoice pattern A2 wants already exists verbatim in `Rendro.Recipes.Receipt` (`customer` / `totals` / `Rendro.Format`), so A2 is a low-risk *port of a proven pattern*, not new design. And the "quarantined fixture with real addresses" the seed frets about (`bench/comparison/fixtures/invoice_data.json`) is **already fictional** ("Rendro Systems", "Acme Phoenix SaaS", "100 Deterministic Way") — the seed's "real addresses" wording is inaccurate; the PII risk is smaller than stated (still verify before shipping into `priv/`).

---

## 1. Forward-Compat Seam Audit

Legend: **HELPS** = actively eases a downstream milestone · **NEUTRAL** = no impact · **RISK** = becomes a breaking change / rewrite later unless shaped now.

| # | A decision / artifact | B (theme threading) | C (presets/catalog/configurator/codegen) | D (Studio) | Shape-now action (in A) |
|---|---|---|---|---|---|
| S1 | **Recipe section color** — Invoice/Payslip/Ticket emit text with no `color:` → engine default `{0,0,0}`; Certificate hardcodes `{34,34,34}` stroke | **RISK (highest)** — B must add `color: theme.colors.ink/.muted/.accent/.rule` to *every* text/stroke call across ~6 recipes | RISK (presets are `%Theme{}`; if the seam isn't there, C inherits B's rewrite debt) | NEUTRAL | **Introduce a PRIVATE `defp palette(opts)` per recipe returning a map keyed on SEED-003's LOCKED roles (`ink, muted, accent, on_accent, background, surface, rule`), defaulting to today's literals; sections read `palette.ink`, never a literal. Expose NOTHING public.** B then swaps the default for `Rendro.Theme.resolve/1` — a one-line change per recipe instead of a per-call rewrite. |
| S2 | **`sections/2` opts-threading convention** (uniform `_opts` threading landed v2.5 Phase 78) | **HELPS** — `theme:` is just a new key on the *existing* seam | HELPS | HELPS | Make A3's new Payslip/Ticket builders **actually receive+forward `opts`** to every private section builder (not `_opts` placeholders like today's `Invoice`), and thread the full opts down all three rungs. Reserve `:theme` as a documented-internal future key. |
| S3 | **`Rendro.Format` public promotion + tier** (`@moduledoc false` → public) | NEUTRAL (theming is orthogonal to money formatting) | **HELPS** if adapter tier | NEUTRAL | Promote to **adapter tier, not stable** (matches seed). Keep `money/1` USD+grouping; route currency/locale via the **caller-supplied `:formatters`/`:labels` opts** (locked v2.4 decision) — do NOT freeze a USD-only assumption into a *stable* signature. Adapter tier lets `money/2`/labels grow without a major bump. |
| S4 | **`priv/examples/<domain>/` layout + fixture schema** (A1; loader is dev/test-scoped, out of the public manifest) | NEUTRAL | **RISK** — C stores example-brand palettes/logos as data here; if A models fixtures as bare facts, C re-keys the schema (breaking) + re-points bench again | Uses C's brands via cache | **Model the fictional business as a first-class entity with an OPTIONAL `brand`/`identity` sub-object (accent `{r,g,b}` + logo ref), empty in A.** The named businesses (Nimbus, Marigold, …) are the natural brand carriers. Reserve `priv/examples/<domain>/` for a future `logo`/asset slot. Additive-neutral to the bench harness. |
| S5 | **Reader-quality rubric format** (A0: 1–5 on IA / hierarchy=5 / least-surprise / affordances / craft / domain-fit) | NEUTRAL | **RISK** — C makes this a "standing quality ratchet" tracked across the catalog grid; prose-only forces C to invent a format + re-score | NEUTRAL | Record scores as a **schema-backed appendable manifest** (`priv/quality_scores.json` + a `priv/schemas/` schema, mirroring `public_api.schema.json` discipline). **Scores stay recorded human judgment; the docs-contract lane enforces STRUCTURE + threshold arithmetic (all ≥4, hierarchy=5), never *computes* the subjective score.** C just appends rows. |
| S6 | **Gallery axis + `artifacts.json`** (A6: family/domain-primary, brand-tagged, hash-checked) | NEUTRAL | **RISK** — C explodes the grid to domain × {2–3 brands/presets} × {light,dark}; if artifacts.json has no theme/mode/preset fields, C re-keys every entry (breaking the hash manifest) | Reads catalog | **Add OPTIONAL `theme` / `mode` / `preset` tag fields to the `artifacts.json` entry schema now, defaulting to `"unbranded-default"` / `"light"` / `null`.** C populates them; the axis already anticipates brand-tagging, so this is the artifacts.json analog of S4. |
| S7 | **New Payslip/Ticket recipes** (A3, on the 3-rung pattern) | RISK folded into S1 (they'll hardcode black) | NEUTRAL | NEUTRAL | Build on **existing primitives + the S1 palette seam + S2 opts threading**; Ticket parametrizes page size (locked v2.4 Certificate decision — no hardcoded A4); errors-as-product `validate_data!` like `BrandedInvoice`. |
| S8 | **Invoice anatomy as additive opts** (A2: `:issuer/:customer/:due_date/:terms/:totals` + Decimal + keep-with-last totals) | HELPS (opts are the theme seam) | HELPS | NEUTRAL | Port the **proven `Receipt` pattern verbatim**; assert the pre-upgrade `%{id,date,items}` toy call renders **byte-identically** (hard SemVer gate + migration note + docs-contract lane). |
| S9 | **`page_template/1` geometry** (hardcoded `@margin 72`, A4 points as module attrs) | mild RISK — B's `spacing`/`density` tokens are tier-3 "honored with defaults" | NEUTRAL | NEUTRAL | Low stakes. For A3's new recipes, **derive geometry from a small named set in one place** (as `Certificate` does) so B can later parametrize `spacing`/`density` without a rewrite. Don't rely on "paper is white" for contrast (B prepends a full-page dark `{:rect}`). |
| S10 | **DOMAIN.md structure** (per-domain glossary/personas/JTBD) | NEUTRAL | HELPS (C's catalog cites it) | NEUTRAL | Keep as **human prose** — it's cited, not computed. No machine format needed. State the jurisdiction assumption per domain (see Pillar 4). |
| S11 | **Loader is dev/test-scoped, out of `public_api.json`** | NEUTRAL | HELPS — C's `mix rendro.launch_artifacts.gen` (dev-time) can still read it; not a frozen public contract | NEUTRAL | Keep it out of the public manifest (correct). Ensures fixtures/loader can evolve freely across A→C. |

**The four load-bearing shape-now seams:** **S1** (private palette), **S4** (fixture brand slot), **S5** (rubric-as-schema), **S6** (artifacts.json theme/mode/preset tags). All four are cheap, use B/C's already-*locked* vocabulary (so they're not speculative), and each prevents a specific downstream breaking change.

**The discipline that makes shaping safe:** A must shape these **INTERNAL** seams using B/C's locked role names — and **freeze nothing public**. No public `theme:`/`palette:` option, no public Theme-ish struct in A. The public theming contract is B's to design; A only pre-arranges its own internals so B's contract drops in without a rewrite. (This resolves the "you'll build the wrong seam before B designs it" objection: the role names, light/dark model, and excluded tokens are already locked in SEED-003, so the internal palette keys are known, not guessed.)

---

## 2. Design-Pillar Enumeration + Application to Milestone A

| # | Pillar | Application to A | Honest to CLAIM in A | Honest to DEFER |
|---|---|---|---|---|
| P1 | **Determinism / byte-reproducibility (SHA-256)** | A5 hash-checks goldens. Fixtures must be static data — no `Date.utc_today()`, no random IDs, no timestamps. `Rendro.Format` is already deterministic. | Byte-identical renders per fixture across runs/platforms. | — |
| P2 | **PDF accessibility reality (tagged-PDF / reading order)** | Rendro emits **no `/StructTree`, no `/MarkInfo`** today. A's documents will *look* professional but are **not tagged / not PDF-UA / not screen-reader-ordered**. The rubric's "reader affordances" = *visual* scan-path, not machine reading-order. | Visual hierarchy, tabular alignment, print fidelity, "Page X of Y". | Tagged structure, screen-reader reading order, PDF/UA. **Guard the "award-quality / production-grade" language so it never implies accessibility.** |
| P3 | **Performance (render cost + package size)** | **Biggest tension.** Golden PDFs + `priv/raster_refs/` + (C's) `priv/fonts/` bloat the Hex tarball (rendro has an exact-allowlist tarball audit from v2.5). A5's 60+-row multi-page × many cells inflates CI time. | — | **Decide the tarball-inclusion policy for `priv/examples/` + goldens/raster-refs NOW: keep goldens/raster-refs as test fixtures EXCLUDED from the shipped tarball; ship only the small JSON fixtures + DOMAIN.md.** Layer A5's heavy renders into C1's proof/slow lane (reuse the just-shipped C1 test-concurrency work). Sets the precedent C inherits for `priv/fonts/`. |
| P4 | **i18n / locale (engine locale-free; differences are DATA)** | Locked v2.4. VAT (Halden & Roe), GBP/EUR, insurance EOB, and **payslip** cross a real line: *statutory* payslip/VAT content differs by jurisdiction — that's **domain correctness, not engine locale**. | Each fixture is correct-looking for **one stated fictional jurisdiction**; labels/currency/tax-line = data via `:labels`/`:formatters`. | **Do NOT build locale logic into Payslip/Ticket recipes.** Pick ONE plausible jurisdiction per example and state it in DOMAIN.md. Engine stays locale-free; "supports every locale" stays out. |
| P5 | **Security / redaction (no real PII)** | Extend the operational-safety pillar to shipped fixtures. **Payslip is the acute risk** (SSN/NI, bank/sort codes, employee IDs). | Fictional businesses (already the design) + obviously-fake identifiers (`XXX-XX-0000`, fictional sort codes). | **Verify `invoice_data.json` is fully fictional before de-quarantining into `priv/` (it appears already fictional — the seed's "real addresses" claim is inaccurate — but confirm).** No real emails/tax-IDs/account numbers anywhere in the corpus. |
| P6 | **Backward-compat / SemVer (additive-only)** | A2 opts are optional; bare `%{id,date,items}` must render byte-identically. New families = adapter-tier modules (Invoice is `tags: [:adapter]`). Format → adapter tier (evolvable). | A is a clean **additive minor (`1.1.0`)**. | Any breaking change. **Test the pre-upgrade toy call byte-for-byte + migration note + public_api.json diff review.** |
| P7 | **Docs-honesty / proof-backed claims** | Every new family/claim needs a `support_matrix.json` row + tests + evidence; A4 is rubric-gated. The rubric itself is a claim surface. | Payslip/Ticket "supported" only with a matrix row + golden (+ evidence if viewer-claimed). | Overclaiming subjective "award-winning" as objective — keep the rubric a *recorded judgment*, not an automated quality verdict. |
| P8 | **Maintainability (family-not-industry; examples as data)** | The core coherence test. Only Invoice *anatomy* + Payslip/Ticket *families* are `lib/`. Industries live as data + escape-hatch compositions in guides/catalog. | — | **No per-industry recipe modules** (`SaasInvoice`, `VatInvoice` = forbidden). Verify A2/A3 module names carry no industry. This boundary **holds** across A→D. |
| P9 | **Errors-as-product** (bonus; v2.4 Phase 77) | A5: overflow → typed `:content_overflow`; RTL raises instructively; single-row-too-tall → typed error; malformed input → structured `ArgumentError`. | Typed `Rendro.Error` / `ArgumentError` at the recipe boundary. | Silent truncation / leaked `BadMapError`/`FunctionClauseError`. |
| P10 | **Single-pipeline / no alternate render path** (bonus; core constraint) | Payslip/Ticket use existing primitives; no new pipeline; no engine change beyond Invoice anatomy. | — | — |

**Named pillar tensions (call these out in the roadmap):**
1. **Richer examples/goldens/fonts vs Hex package size** (P3) — the dominant tension; resolve by excluding goldens/raster-refs from the tarball and setting the `priv/` inclusion precedent in A.
2. **Realism vs determinism + security + locale-free engine** (P1/P4/P5) — resolve with static fixed-date, single-jurisdiction, obviously-fake-PII fixtures.
3. **"Award-quality / production-grade" marketing vs docs-honesty + accessibility reality** (P2/P7) — resolve by scoping the claim to *visual* craft and explicitly deferring tagged/PDF-UA.

---

## 3. Right-Sizing — Proposed Phase List

**Assessment of the 7-phase A0–A6 against rendro's declared "coarse" GSD granularity:** too fine. Four of the seven are pure authoring/data/docs with no `lib/` change (A0, A1, A4, A6). Precedent: v2.4 **Phase 75 shipped Receipt *and* Certificate in one phase** — two recipes per phase is established and coarse. Fold to **5 phases**.

**Recommended phase list (numbering continues at 114 — confirmed; highest existing is 113):**

| # | Phase | Folds seed | `lib/`? | Core deliverables |
|---|---|---|---|---|
| **114** | **Domain research, schema-backed reader-quality rubric & realistic example-data library** | A0 + A1 | No | Per-domain `DOMAIN.md` (glossary/personas/JTBD, states jurisdiction); **rubric as `priv/quality_scores.json` + schema (S5)**; `priv/examples/<domain>/` layout **with optional `brand`/identity sub-object + reserved logo slot (S4)**; scrub-verify + de-quarantine `invoice_data.json`; dev/test loader (out of public manifest); repoint bench. Tarball policy decided (P3). |
| **115** | **Invoice anatomy upgrade + `Rendro.Format` public (adapter tier)** | A2 | **Yes** | Additive `:issuer/:customer/:due_date/:terms/:totals` + Decimal + keep-with-last totals (**port `Receipt` pattern**); **introduce the private `palette(opts)` seam (S1)**; Format → adapter tier with `:formatters`/`:labels` locale seam (S3); byte-identical toy-call test + migration note + public_api.json diff + docs-contract lane. |
| **116** | **Payslip + Ticket families** | A3 | **Yes** | Two recipes on the 3-rung pattern + existing primitives + **palette seam (S1) + full opts threading (S2)**; Ticket parametrizes page size; errors-as-product `validate_data!`; register in `public_api.json` (adapter) + `support_matrix.json`. |
| **117** | **Edge-case stress matrix & determinism goldens** | A5 | No (test) | Family × dimension → deterministic hash-checked goldens + `priv/raster_refs/` (excluded from tarball) + errors-as-product assertions (overflow/RTL/oversize-row typed errors); layered into C1's proof lane. |
| **118** | **Rubric-gated demonstration set, gallery & docs closure** | A4 + A6 | No | Render family×domain matrix into `guides/recipes.md`, `guides/branding.md`, `first_invoice.livemd`, `examples/phoenix_example` — each cites DOMAIN.md and passes the rubric; expand `assets/rendro/gallery/` + **`artifacts.json` with reserved `theme`/`mode`/`preset` tags (S6)**; reconcile `support_matrix.json`; update README. |

**Notes on the fold:**
- **A0→114:** the seed already flags A0 "foldable into A1." Keep the rubric a first-class, cross-cutting deliverable of 114 (A4 and all of C consume it).
- **A4+A6→118:** both are "prove + showcase the corpus + reconcile manifests/docs" — one coherent closure phase.
- **A5 stays standalone (117):** edge-case determinism is genuine engineering (hash-stability across numeric/pagination/locale edges), distinct from docs.
- **115 and 116 stay separate:** the two `lib/` product changes are the meaty, SemVer-gated work and deserve independent verification loops.
- If the team prefers 6 phases, the only sensible split is un-folding 114 back into A0 (rubric+research) and A1 (data library). I recommend **5**.

---

## 4. Direction Verdict

**Scope + boundary: CORRECT — ship it.** SEED-002 is confirmed *not a pivot*; it closes the one real gap (toy → production examples + Invoice anatomy + Payslip/Ticket) while the **family-not-industry / examples-as-data boundary holds cleanly across all of A→D** (Pillar P8). The reconciliation (core recipes family-organized; industries as data + escape-hatch; shared `priv/examples/` corpus; design-systems-are-code / brands-are-data) is coherent and durable.

**Churn: LOW — conditional on four cheap seams.** With **S1 (private palette), S4 (fixture brand slot), S5 (rubric-as-schema), S6 (artifacts.json theme tags)** honored, B and C drop in additively. Skip them and you buy: a 6-recipe color rewrite in B (S1), a breaking fixture re-key in C (S4), a re-invented + re-scored rubric in C (S5), and a broken hash manifest re-key in C (S6). All four cost near-zero in A because they use B/C's *already-locked* vocabulary — the only discipline required is **freeze nothing public** (shape internals only; leave the public theming contract to B).

**Version: additive minor — `1.1.0` (milestone label v2.10), NOT v3.0 / 2.0.0.** A2 is strictly additive (toy call preserved byte-for-byte), `Format` promotes to *adapter* tier (adding a public adapter surface is not a break), and new families are additive adapter-tier modules. Nothing breaks → minor bump. Unlike C1 (non-version infra), **A genuinely changes `lib/` → it IS a versioned product release** and should cut a hex `1.1.0` tag.

**One clear recommendation:** Proceed with SEED-002 as a **5-phase additive-minor milestone (phases 114–118, hex 1.1.0)**, and add the four shape-now seams (S1/S4/S5/S6) plus the three pillar guards (exclude goldens from the tarball; single-jurisdiction fictional-PII fixtures; scope "production-grade" to *visual* craft and defer tagged/PDF-UA) as **explicit acceptance criteria of phases 114–116** so B and C inherit an open, non-breaking foundation.

---

## Sources & Confidence

- **HIGH** — grounded in shipped code read this session: `lib/rendro/recipes/{invoice,branded_invoice}.ex`, `lib/rendro/format.ex` (`@moduledoc false`, deterministic `money/1`), `lib/rendro/recipes/receipt.ex` (the exact `customer`/`totals`/`Format` pattern A2 ports), `text.ex` (`color: {0,0,0}` default), `certificate.ex` (hardcoded `{34,34,34}` stroke), `priv/public_api.json` (stable/adapter tiers), `priv/support_matrix.json` (row discipline), `bench/comparison/fixtures/invoice_data.json` (already-fictional).
- **HIGH** — locked decisions cross-checked across SEED-002/003/004/005 + `~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md` (theme role names, light/dark model, excluded tokens, gallery axis all *locked* → internal seams are non-speculative).
- **HIGH** — `PROJECT.md` Key Decisions / Constraints / Out-of-Scope (locale-free `Format`, additive-only SemVer, two-tier API, errors-as-product, single pipeline, tarball allowlist), `EPIC.md` permanent boundaries, `guides/branding.md` (font+logo-only convention `theme:` extends), `prompts/Rendro Brand Book.txt` (voice: "honest capability", no overclaim → grounds the P2/P7 accessibility/honesty guards).
- Phase numbering (next = 114) confirmed against `.planning/phases/` (highest = 113).
