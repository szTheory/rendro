# Pitfalls Research

**Domain:** Adding style-genre presets, vendored fonts, a public example catalog, and a static
client-side configurator to a deterministic, proof-backed, no-overclaim Elixir PDF library
(Rendro v2.12 / `SEED-004`, Milestone C of the Happy-Path Home Runs program).
**Researched:** 2026-07-28
**Confidence:** HIGH (font-licensing mechanics, determinism-preservation patterns, catalog/rubric
scaling risk, and overclaim tripwires are grounded directly in this codebase's existing source,
tests, and locked v2.11 decisions — `lib/rendro/theme.ex`, `lib/rendro/font_registry.ex`,
`lib/rendro/pdf/font_subsetter.ex`, `mix.exs` package allowlist, `NOTICE`,
`test/docs_contract/*`, `priv/quality/rubric_scores.json` + `SIGN-OFF.md`. General OFL/RFN
licensing mechanics and client-side XSS patterns are well-established public knowledge, MEDIUM-HIGH
confidence on their own but verified against how this repo already vendors its one existing font.)

## Critical Pitfalls

### Pitfall 1: Sourcing a preset font without a genuine, explicitly-redistributable license

**What goes wrong:**
A "free-looking" font (found via a random download site, a font aggregator, or a designer's
personal portfolio) gets vendored into `priv/fonts/` without actually confirming its license
permits redistribution *inside a software package* and *embedding inside generated documents*.
Many "free for personal use" or unlicensed webfonts are not OFL — they are copyright-all-rights-
reserved with informal "you may use this" language that does not survive legal scrutiny once
Rendro redistributes the binary itself (not just links to it) via Hex.

**Why it happens:**
Under deadline pressure to hit the "flagship presets render out of the box" bar (`PRESET-02`),
it's tempting to grab whatever font looks right for the genre (e.g. a Swiss grotesque, an
editorial serif) without checking its license terms carry an explicit *redistribution* grant, not
just a *use* grant. The existing codebase already vendors exactly one font (`B612-Regular.ttf`,
SIL OFL 1.1, `NOTICE` at repo root) — that precedent makes it easy to assume "any freely
downloadable font" is equivalent, when only fonts sharing B612's actual license class are safe.

**How to avoid:**
Restrict sourcing to fonts under SIL OFL 1.1 (or equivalently permissive: Apache 2.0, Ubuntu Font
License) from a canonical, auditable source — Google Fonts' OFL catalog is the safest default
(e.g. a grotesque like Public Sans/IBM Plex Sans, a humanist sans like Inter, a text serif like
Source Serif 4/Fraunces, a mono like JetBrains Mono/IBM Plex Mono — final picks are a design
decision, but the license class is not negotiable). For each candidate, verify the license file
shipped *with the font's own release* (not a third-party mirror) explicitly states OFL 1.1 and
confirm the FAQ language on embedding in generated documents (OFL is explicit that fonts and
derivatives can be "bundled, embedded, redistributed" with software, and that documents *created
using* the font are not bound by the OFL — this is exactly the shape Rendro needs). Never accept
"license unclear, looks free" as sufficient.

**Warning signs:**
No license file ships alongside the font's own distribution zip/repo; the font's page uses vague
language like "free for commercial use" without naming a license; the only copy of the license
text you can find is on a third-party aggregator site rather than the original foundry/author
repo.

**Phase to address:**
The `PRESET-02` phase (curated preset fonts) — font selection must happen with license
verification as a go/no-go gate *before* any byte lands in `priv/fonts/`, not as a post-hoc
audit.

---

### Pitfall 2: Missing or incomplete license artifacts in the shipped Hex tarball (NOTICE, RFN, package allowlist)

**What goes wrong:**
Even a correctly-licensed OFL font ships incompletely: (a) the font's own `OFL.txt` +
copyright/attribution block never gets added to `NOTICE` (which today has exactly one font's
license text, sized for one font — scaling to 4-6 fonts needs 4-6 distinct attribution blocks,
easy to under-scope as "just append the new font's copyright line"); (b) `priv/fonts/` is never
added to the `mix.exs` `package.files` allowlist (it currently is **not** present — only
`priv/branded` and `priv/examples` are listed), so the fonts silently don't ship in the Hex
tarball at all, and every preset breaks for real Hex consumers while looking fine in local dev;
(c) a font's Reserved Font Name (RFN) is violated — if the preset pipeline ever transforms/subsets
the font and then re-labels the family name in a way that still uses the original RFN-protected
name (most OFL fonts reserve their own name), that's a license violation, not just a hygiene gap.

**Why it happens:**
The existing tarball-exclusion pattern (`branding_claims_test.exs` / the negative allowlist audit)
proves what's *excluded*; nothing today proves fonts are correctly *included*, because there
have been zero binary assets that mattered to Hex-consumer functionality until now (B612 already
had this exact problem solved once, but as one file, one NOTICE entry — it's easy to assume the
existing setup "already handles fonts" without re-checking for the *new* files).

**How to avoid:**
Treat this as one explicit `PRESET-02` deliverable, not incidental packaging: (1) add
`priv/fonts` to `mix.exs` `package.files`; (2) extend `NOTICE` with one clearly-delimited
copyright+OFL block per vendored font family (source URL, exact version/commit pinned, copyright
holder, RFN name if any); (3) extend the existing tarball audit test to *positively* assert every
file under `priv/fonts/` used by a shipped preset is present in the built tarball (not just that
disallowed things are absent) — mirrors the "positive + negative" pattern already used for
`priv/examples`; (4) if any font subsetting/renaming step runs, assert the output family name
does not collide with a reserved name unless it *is* the unmodified original.

**Warning signs:**
`mix hex.build` (or the project's tarball-diff test) shows a preset font referenced by
`lib/rendro/theme/presets.ex` but absent from the built `.tar`; `NOTICE` has one generic OFL
block that doesn't clearly attribute which font it covers once there's more than one.

**Phase to address:**
`PRESET-02` (packaging is part of "ships out of the box," not a follow-up); verified again at
milestone close alongside the existing `mix hex.audit`/tarball-allowlist gates.

---

### Pitfall 3: Font subsetting nondeterminism breaks byte-identity across catalog renders

**What goes wrong:**
`Rendro.PDF.FontSubsetter.subset/2` takes `(bytes, used_glyphs)` and already sorts its output
table tags (`Enum.sort`), which is good — but `used_glyphs` itself is a caller-supplied *list*.
If two code paths compute the same logical glyph set in different insertion/iteration order (e.g.
`MapSet` iteration order, or a `Map.keys/1` result whose enumeration order isn't pinned), the
subsetted font bytes can differ byte-for-byte between two runs that are logically identical —
silently breaking the sha256 byte-identity goldens the whole catalog depends on, and doing so
non-reproducibly (a flaky golden, not a clean diff).

**Why it happens:**
Subsetting is new *load-bearing* determinism surface once presets ship real embedded fonts at
catalog scale (today the font pipeline exists but has never been exercised end-to-end across
dozens of preset/brand/mode combinations in one release). A glyph-set builder written for
correctness ("collect every codepoint used in this document") can easily forget the same
determinism discipline the rest of the pipeline already enforces (`Enum.sort` before anything
order-sensitive; no wall-clock/system-random inputs).

**How to avoid:**
Require the `used_glyphs` input to `subset/2` to be a sorted, deduplicated list at the call site
(or make `subset/2` itself defensively sort/dedupe on entry) so subsetting is a pure function of
*which* glyphs are used, never *in what order* they were discovered. Add an `assert_deterministic!/1`
style test (mirrors `Rendro.Test.Golden.assert_deterministic!/1` from the Phase 117 edge-matrix
work) that subsets the same font+glyph-set twice and asserts byte-identical output, for every
vendored preset font. Also audit `font_subsetter.ex`/`font_parser.ex` for any table field that
encodes a timestamp (TrueType `head` table `created`/`modified` fields are a classic nondeterminism
trap in font tooling) and force those to a fixed epoch value rather than "now."

**Warning signs:**
A catalog golden that passes locally but fails in CI (or vice versa) with a byte-diff confined to
font-embedding regions of the PDF; re-running the same `mix rendro.launch_artifacts.gen` twice
locally produces two different hashes for the same artifact.

**Phase to address:**
`PRESET-02` (subsetting is exercised the moment embedded preset fonts exist) — verified again
under `CATALOG-01` at full-grid scale, since that's where many distinct glyph subsets (one per
document/brand/preset combination) get exercised for the first time.

---

### Pitfall 4: Float math sneaks into preset token derivation (accent-derived type scale, contrast, tint)

**What goes wrong:**
Style-genre presets are richer than plain theming — they may derive spacing rhythm, rule
weights, or scale ratios "from" a genre's character (e.g. "Editorial has higher type-scale
contrast"). If any of that derivation happens as a runtime formula (a `:math.pow`-style scale
ratio, a live WCAG contrast recompute, or a tint blend) evaluated *at render time* rather than
*once* when the preset/theme is resolved, Rendro reintroduces exactly the per-draw float-math
nondeterminism the v2.11 milestone explicitly eliminated (`Theme.dark/1` is a pure `Map.merge` of
pre-resolved integer tuples specifically *because* per-draw float tint math breaks byte-
reproducibility, per the locked D-01/MODE-01 decision).

**Why it happens:**
Presets look conceptually like "compute me a theme from a genre + accent," which invites treating
`Theme.preset/2` as a bigger, more computational sibling of `from_brand/2` — and `from_brand/2`
already does float-adjacent work (WCAG contrast comparison for `on_accent` derivation). It is easy
to reuse or extend that machinery in a way that runs per-draw instead of once per `resolve/1`
call, especially for anything preset-specific (e.g. "derive rule weight as a function of density").

**How to avoid:**
Every preset is a `%Theme{}` *value*, fully materialized with integer `{r,g,b}` tuples and
explicit point sizes at construction time (mirrors the existing "type scale as explicit
materialized points, never a runtime formula" decision, D-03). Any derivation math (scale ratios,
contrast picks, tint blends) must run exactly once, inside `presets.ex`/`resolve/1`, producing a
plain, already-resolved struct — never inside a recipe's per-draw/per-page code path. Add a
source-grep guard (mirroring `theme_industry_guard_test.exs`'s static-source-check style) that
`lib/rendro/recipes/**` never calls a float-producing preset-derivation function directly.

**Warning signs:**
Any function under `lib/rendro/theme/presets.ex` accepting a page/draw-time argument;
`:math.pow`, `Float.round`, or WCAG contrast computation appearing in a recipe module rather than
in theme/preset resolution; a byte-identity golden that is deterministic on one machine but drifts
across BEAM versions/architectures (a classic float-nondeterminism tell).

**Phase to address:**
`PRESET-01` (presets as `%Theme{}` values) — this is a design-time constraint on how
`Theme.preset/2` is implemented, not a later cleanup.

---

### Pitfall 5: Hash-check drift from later font or preset-token revisions silently detonates the whole catalog

**What goes wrong:**
Once fonts and presets are load-bearing catalog inputs, a well-intentioned later change — "bump
the vendored font to its newest upstream release," "nudge Editorial's leading by 0.02," "swap a
preset's rule weight" — changes bytes in every rendered artifact that uses that font/preset,
which at catalog scale (see Pitfall 6) can be 30-100+ blessed sha256 goldens at once. Without an
explicit policy, the natural response is a blanket `MIX_GOLDEN_BLESS` re-run and commit — which
both hides the actual visual delta and turns a deliberate design change into an unreviewed mass
rewrite.

**Why it happens:**
The existing golden-bless workflow (`Rendro.Test.Golden`, `MIX_GOLDEN_BLESS`) was built and proven
at 1-recipe-at-a-time and later 62-cell-edge-matrix scale, where a mass re-bless after a real
`lib/` change is rare and reviewable. Fonts and presets are *shared* inputs multiplying across the
entire domain × brand × preset × mode grid, so the blast radius of one asset change is
structurally much larger than anything the golden system has faced before.

**How to avoid:**
Pin exact font file versions (commit hash / release tag, recorded in `NOTICE`) and treat any font
file *byte* change as an intentional, reviewed golden-rebless event exactly like a rendering
logic change — never an incidental "oh I grabbed the latest version." For preset token changes,
require the re-bless diff to be scoped and explained per-preset in the commit message (which
preset(s) changed, why, and which catalog rows are expected to move) rather than accepted as an
opaque bulk diff. Consider keeping goldens hash-only (already the pattern, not full PDF bytes) so
diffs are reviewable as "these N hashes changed" rather than binary noise.

**Warning signs:**
A single-line font/preset-token PR touches dozens of files under `priv/goldens/`; a re-bless
commit has no prose explaining which visual attribute is expected to move and why.

**Phase to address:**
`CATALOG-01` (this is where the blast radius becomes visible) — but the *policy* (pin font
versions, scoped re-bless review) should be written down as part of `PRESET-01`/`PRESET-02`
before the catalog phase generates its first full grid.

---

### Pitfall 6: Catalog combinatorial explosion (render time, tarball bloat, CI budget)

**What goes wrong:**
The catalog's honest cross product is domain × brand/preset × mode: today there are 6 example
domains (invoice, statement, receipt, certificate, payslip, ticket) and the seed specifies 2-3
example brands/presets per domain × {light, dark} + an unbranded default per domain. Taken
literally as a full cross product against 5-6 style-genre presets, that's roughly 6 × 3 × 6 × 2 ≈
200+ rendered/rasterized/hash-checked artifacts — nearly 20x today's 11-row gallery. Left
unbounded, this blows out render time, raster-proof tooling load (pdfium-cli), local repo/tarball
size, and `mix rendro.launch_artifacts.gen` runtime, and risks accidentally making raster/pdfium
proof feel load-bearing for the catalog (which would push toward making it required CI —
violating the standing "Node/npm/browser/pdfium never required CI or Hex runtime dep"
constraint).

**Why it happens:**
"Show off every domain in every preset" is the natural literal reading of "public by-domain
example catalog" — nobody deliberately chooses a 200-cell grid, it accretes one dimension at a
time (add brands, then add presets, then add dark) without anyone totaling the product until CI
is slow and the tarball has grown.

**How to avoid:**
Set an explicit, written combinatorial budget *before* generation, not after: e.g. every domain
gets its unbranded default + a small *curated* set of {brand × preset} pairs (not every preset ×
every brand — 2-3 *curated combinations* per domain as the seed literally says), each shown in
both modes. Add a structural test that asserts the catalog manifest's total row count stays under
an explicit ceiling, so a future "just add one more preset to everything" PR fails loudly instead
of silently 6xing the grid. Keep pdfium/raster proof advisory-only for the catalog exactly as it
already is for the rest of the product (do not add it to any required CI context).

**Warning signs:**
`mix rendro.launch_artifacts.gen` wall-clock time growing far faster than domain/preset count
growth; `assets/rendro/artifacts.json` row count with no corresponding budget test; a PR that
adds a 6th preset and silently changes gallery row count by 6× the domain count.

**Phase to address:**
`CATALOG-01` — the budget/ceiling should be a designed, tested constraint from the first commit
of catalog generation, not retrofitted after the grid already exists.

---

### Pitfall 7: Hash-brittleness turns catalog maintenance into rubber-stamped mass re-blessing

**What goes wrong:**
Every catalog cell is a sha256-blessed byte golden extending the same pattern used for the 11-row
gallery today. At 100+ cells, any shared-surface change (a font tweak, a preset token nudge, a
recipe fix folded in from the v2.11 carryover) invalidates a large fraction of the grid at once.
The realistic failure mode isn't a crash — it's a maintainer running `MIX_GOLDEN_BLESS=1 mix
test`, seeing a big green diff, and committing it without actually opening a meaningful sample of
the changed PDFs, because manually reviewing 80 changed hashes isn't tractable under normal
review time budgets.

**Why it happens:**
The blessing mechanism was designed to make "expected, reviewed" output changes cheap to accept
— at 1-11 cells that's still a real review. At 100+ shared-surface-dependent cells, the *mechanism*
stays cheap but the *review discipline* it assumes does not scale, so the human step quietly
degrades into a rubber stamp.

**How to avoid:**
Require every mass re-bless PR to include a small, explicit, human-reviewed visual sample
(e.g. one rendered PDF/PNG per *distinct* preset or font touched, not per cell) as a checked-in
review artifact — mirroring the existing rubric sign-off discipline (`SIGN-OFF.md`) rather than
inventing a new process. Keep the golden diff itself scoped to hash-only comparisons (already the
pattern) so a reviewer can quickly see *which* cells moved and cross-reference against the
expected blast radius from Pitfall 5/6, rather than eyeballing a wall of binary diffs.

**Warning signs:**
A re-bless PR touching 50+ golden files with a commit message shorter than the list of changed
files; no rendered artifact attached to the PR for human review; re-bless PRs becoming routine/
unremarkable rather than flagged events.

**Phase to address:**
`CATALOG-01` — the review-discipline policy must exist before the first full-grid generation,
since that's the first commit at a scale where rubber-stamping becomes physically possible.

---

### Pitfall 8: The reader-quality rubric ratchet becomes a rubber stamp at catalog scale

**What goes wrong:**
The existing rubric process (`priv/quality/rubric_scores.json` + `SIGN-OFF.md`) is *human visual
judgment* per demo — and it is genuinely honest: the Phase 123 sign-off records Ticket as
`passed: false` with a real, undisguised hierarchy-inversion defect, rather than flattering the
score. That process does not scale to ~100-200 catalog cells; a human cannot meaningfully eyeball
every cell every time the grid regenerates. The natural failure mode is to quietly narrow what
"the ratchet" actually checks (e.g. only re-score the unbranded defaults, or only spot-check a
few cells) while continuing to *describe* the catalog as "the standing quality-bar ratchet" for
the whole grid — an accuracy gap between the claim and what's actually verified.

**Why it happens:**
The seed's stated goal — "so all layouts eventually look award-winning, including the unbranded
default" — is aspirational and grid-wide, but the *mechanism* that makes that credible (a human
signing off with anchored 1-5 dimension scores) is fundamentally not automatable, and there's no
existing capacity signal for how much human rubric-scoring time is available per catalog
regeneration.

**How to avoid:**
Make the actual review scope explicit and honest in the manifest schema itself rather than
implicit: e.g. a documented policy that full human-anchored rubric scoring covers the unbranded
default per domain (the existing 6 rubric demos) plus one flagship preset combination per domain,
while the remaining preset/brand/mode cells inherit a narrower, explicitly-named automated check
(e.g. "no overflow/wrap regression," "no illegible ink-on-background pair" — reusing the exact
carried-over dark-legibility/wrap defects as the automated check's seed cases). Never silently
flip an existing honest `passed: false` (Ticket) to `true` as a side effect of a preset/catalog
commit without addressing the underlying defect — this mirrors the already-locked Phase 123
decision ("never flip a score to `passed:true` in a colour-only commit").

**Warning signs:**
Catalog/README copy claiming "every catalog document passes the quality rubric" without a
manifest row backing every specific cell; `rubric_scores.json` growth that doesn't track 1:1 with
actual documented human sign-off entries; the known-`false` Ticket entry disappearing or flipping
to `true` in a commit whose stated scope is presets/catalog, not the Ticket hierarchy fix.

**Phase to address:**
`CATALOG-01`, in coordination with the folded-in carryover phase that fixes the WINDOWS ids 1-3
defects (invoice_dark legibility, Ticket hierarchy, payslip wrap) — those fixes should land
*before* or *alongside* the first full catalog generation so the ratchet's initial baseline is
honest rather than immediately showing known regressions across dozens of cells.

---

### Pitfall 9: The static configurator accidentally requires a server, Node/npm, or a build step

**What goes wrong:**
"Static client-side configurator" is easy to build correctly in isolation and then quietly
regress: someone reaches for a JS bundler/npm toolchain to manage the small amount of interactive
JS (dropdown, URL-query parsing, copy-to-clipboard), checks in a `package.json` + build step, and
wires it into CI so the shipped asset is *produced* by a Node build rather than hand-authored/
Elixir-generated and committed. Separately, "see the nearest pre-rendered preview" can quietly
grow a tiny lookup service (even a static JSON fetch is fine, but a live "compute nearest match"
endpoint is not) that turns "static" into "needs a runtime."

**Why it happens:**
Modern front-end habits default to npm tooling even for small amounts of vanilla JS, and CI
authors instinctively want a `test`/`build` job for anything JS-shaped — both instincts directly
collide with the project's standing constraint that Node/npm must never become required CI or a
Hex runtime dependency (already true for the pdfjs-observer advisory lane, which is deliberately
isolated/non-required).

**How to avoid:**
Author the configurator as hand-written (or Elixir/EEx-template-generated at doc-build time) HTML
+ vanilla JS + CSS, committed directly — no `package.json`, no bundler, no npm install step
anywhere in its build or CI path. Generate the "nearest preview" lookup table as static JSON from
the same manifest `mix rendro.launch_artifacts.gen` already produces, fetched client-side with no
compute step. If a JS lint/format tool is desired, keep it strictly advisory/local-dev, isolated
exactly like the existing pdfjs-observer Node usage (never wired into `ci.yml`'s required
contexts).

**Warning signs:**
A `package.json` appearing anywhere the configurator lives; any CI job with `npm install`/`npm
run build` added to required contexts; the "nearest preview" resolution making a network request
or invoking server-side Elixir at request time rather than reading a static file.

**Phase to address:**
`CONFIG-01` — this is the phase's central architectural constraint and should be locked in the
plan before any HTML/JS is written.

---

### Pitfall 10: URL-state XSS in the configurator

**What goes wrong:**
Configurator state lives in the URL query string (preset name, accent color, mode) and drives
what gets rendered into the DOM — the selected preset's label, the accent swatch, and critically
the "one-click copy" code snippet text. If any of that state is echoed into the page via
`innerHTML`/string concatenation rather than safe DOM APIs, an attacker-crafted URL
(`?accent=<script>...`) becomes a reflected XSS vector against anyone who opens a shared
configurator link — which is exactly the sharing use case the URL-state design is *for*
("shareable" per the seed).

**Why it happens:**
Small vanilla-JS UIs built without a framework often reach for template-literal string
concatenation into `innerHTML` for speed, since there's no framework auto-escaping backstop; and
because the values in question (accent, preset name) *look* like they're always "safe" enum/hex
values, it's easy to skip validating them before display.

**How to avoid:**
Whitelist-validate every URL parameter against a closed, known-good set before use: preset name
must match one of the shipped preset atoms exactly (reject anything else, don't render it), accent
must match a strict `^#[0-9a-fA-F]{6}$` (or similarly narrow) pattern before being used anywhere
(including as a CSS custom property value or in the copied snippet text). Render all
user-influenced values via `textContent`/`setAttribute` DOM APIs, never `innerHTML` string
interpolation. Treat this as a real security-review item, following the project's existing pattern
of an explicit closed threat count (e.g. the v2.10 examples-loader review closed 16 threats, 0
open) rather than an implicit "it's just static HTML, nothing to review" assumption.

**Warning signs:**
Any `innerHTML =` or template-literal HTML construction using a URL-derived value; no input
validation/whitelist check between `URLSearchParams` reads and DOM writes; no security-review pass
recorded for the configurator phase.

**Phase to address:**
`CONFIG-01` — should get its own security-review pass (mirrors `gsd-secure-phase`/the project's
existing threat-closure discipline) before ship, not treated as exempt because it's "just static
HTML."

---

### Pitfall 11: The copy-snippet generator produces invalid or semantically-wrong Elixir

**What goes wrong:**
The "one-click copy" snippet hand-assembles a string like `Rendro.Theme.preset(:editorial, accent:
{12, 74, 110}, mode: :dark)` from configurator state via ad-hoc string interpolation. Done
independently from the actual `mix rendro.gen.theme` codegen task, this duplicated logic risks:
wrong tuple arity or formatting for the accent value, an un-atomized or incorrectly-quoted preset
name, a dropped/misplaced `mode:` when a user picks a mode the pre-rendered preview didn't cover,
or literal float values leaking into what must be an integer `{r,g,b}` tuple (reintroducing
Pitfall 4's float-purity concern at the *authored-code* layer instead of the render layer). A user
pastes it, gets a `CompileError` or a confusing runtime `Theme.resolve/1` error, and the "zero
compute, 90% path" promise breaks on the very first click.

**Why it happens:**
The snippet-generator (client-side JS) and the codegen task (`mix rendro.gen.theme`, server-side
Elixir) are two independent implementations of "turn (preset, accent, mode) into Elixir source" —
built at different times, in different languages, with no shared source of truth, so they drift.

**How to avoid:**
Treat "how do I turn (preset, accent, mode) into a valid Elixir snippet" as one canonical
function, not two. Since the configurator is static JS and the codegen task is Elixir, the
practical route is: generate the *exact same string template* both paths use at build time (e.g.
`mix rendro.launch_artifacts.gen`/`mix rendro.gen.theme` emit the snippet format as data the
static JS consumes, rather than the JS re-deriving formatting rules independently), and add a CI
test that `Code.string_to_quoted!/1`s every producible snippet across the bounded enum of
preset × mode × the curated closed accent set (see Pitfall 12) to prove every one compiles.

**Warning signs:**
Two different string-templating implementations for the same snippet shape (one in JS, one in the
`mix rendro.gen.theme` task source) with no shared test proving they agree; no automated
"does every producible snippet actually compile" test.

**Phase to address:**
`CONFIG-01` — the snippet format should be designed once, shared by both the configurator and
`mix rendro.gen.theme`, and locked with a compile-round-trip test before either surface ships.

---

### Pitfall 12: Drift between the pre-rendered preview and the actual copy-snippet's real output

**What goes wrong:**
The configurator explicitly shows "the *nearest* pre-rendered preview" for an arbitrary
user-selected accent, then hands the user a snippet for their *exact* (possibly never-rendered)
accent choice. If accent selection is an open input (any hex value, e.g. via a color picker) but
previews only exist for a small curated palette, users can copy a snippet whose real rendered
output — contrast on `on_accent`, WCAG-adjacent readability, wrapping under a specific type scale
— was never actually verified and may look meaningfully different from what they saw in the
preview. This directly risks becoming an implicit design-quality guarantee the product does not
back (a form of Pitfall 13's overclaim, surfaced through the configurator UX rather than docs
copy).

**Why it happens:**
An open, freeform accent picker feels more powerful/flexible than a closed palette, and "nearest
match" language sounds like a reasonable approximation — but the gap between "nearest" and
"exact" is invisible to a user who just clicked copy and pasted the snippet into their app.

**How to avoid:**
Prefer a closed, curated accent palette in the URL-state design (a small set of accents that
*are* all pre-rendered, matching the seed's own framing: "pick a preset + a sample accent from a
small palette") over an open color picker — this makes "preview" and "what you'll get" the same
thing by construction, eliminating the drift risk entirely rather than just labeling it. If an
open picker is kept for flexibility, the UI must visibly flag when the selected accent differs
from the previewed swatch, and the docs/copy must not imply the preview is a guarantee of the
final render's quality.

**Warning signs:**
An accent input that accepts arbitrary hex values with no visible "approximate preview" indicator;
no docs language distinguishing "preview" from "guaranteed output."

**Phase to address:**
`CONFIG-01` — this is a design decision (closed palette vs. open picker) that should be locked
during planning, not discovered as a UX gap after ship.

---

### Pitfall 13: Presets implicitly promise a design-quality guarantee they don't back

**What goes wrong:**
Marketing-adjacent language around presets ("award-winning," "professionally designed," "always
looks great") reads as a blanket quality guarantee across every preset × brand × domain
combination — but the rubric process itself has already proven that's false for at least one
real combination (Ticket's themed hierarchy inversion, honestly scored `passed: false`). Shipping
presets with confident marketing copy while the rubric manifest simultaneously records known
failures is a direct violation of the project's no-overclaim culture (every public claim needs a
proof artifact + a matching support-matrix row + a docs-contract tripwire).

**Why it happens:**
Preset/catalog copy is naturally written to *sell* the feature ("turnkey," "near-zero effort,"
"ooze-quality") — those exact words are in the seed itself — and it's easy for that marketing
framing to leak into public docs as unconditional claims rather than staying scoped to "this is a
strong, curated starting point, not a guarantee."

**How to avoid:**
Keep preset-facing docs language conditional and scoped ("a strong starting point for X genre,"
never "guaranteed to look great" or "award-winning" without qualification). Publish per-cell
rubric status alongside the catalog itself (mirrors the existing per-demo honesty in
`SIGN-OFF.md`) so any reader can see exactly which combinations have and haven't cleared the bar,
rather than implying uniform quality. Extend the existing docs-contract overclaim-tripwire pattern
(`theming_claims_test.exs`, `accessibility_overclaim_test.exs`) with a new lane scanning
preset/catalog-facing docs for absolute-quality language not backed by a matching rubric row.

**Warning signs:**
README/guide copy using unconditional superlatives about preset output quality; catalog pages
that don't surface (or actively hide) cells with a `passed: false` rubric status.

**Phase to address:**
`PRESET-01`/`CATALOG-01` — the docs-contract tripwire extension should ship in the same phase
that first publishes preset-facing marketing copy, not retrofitted later.

---

### Pitfall 14: The public catalog implies accessibility or compliance coverage it doesn't have

**What goes wrong:**
A large, polished, publicly-browsable gallery of real-looking branded business documents (with
dark-mode tiles alongside light) strongly *reads* as "production-ready for accessible/compliant
use" even if no page anywhere says that explicitly — the sheer visual polish and breadth implies a
maturity claim beyond what `priv/support_matrix.json` actually backs (dark mode is explicitly
`supported_screen_oriented` with `accessibility_pdf_ua_claim: unsupported` and
`wcag_contrast_claim: unsupported`). A catalog page is exactly the kind of surface that can imply
a claim through presentation alone, without a single sentence of text actually asserting it.

**Why it happens:**
Docs-contract tripwires today scan specific known text surfaces (`theming.md`, `theme.ex` docs,
README) for forbidden claim language — but a new catalog/gallery surface (new HTML/markdown pages,
new image captions, new configurator copy) is exactly the kind of net-new surface that's easy to
forget to wire into the existing tripwire lane list, especially since the claim risk here is more
about *implication through presentation* than explicit sentences.

**How to avoid:**
Extend the existing `accessibility_overclaim_test.exs` and `theming_claims_test.exs` lanes (or add
a new catalog-specific lane) to cover every new catalog/configurator-facing text surface, not just
`guides/theming.md`. Add explicit, visible framing on the catalog page itself (a short standing
note that catalog examples demonstrate visual/structural capability, not accessibility or
compliance conformance) so the presentation doesn't have to rely on absence-of-claim alone.
Remember to bump the guardrails lockstep triple (`scripts/verify_docs.exs` lane count +
`required_checks_contract_test.exs` count assertion + `priv/guardrails/required_status_checks.json`)
if a new docs-contract lane is added — the existing lane count (26 as of v2.11) is asserted
exactly, so a new lane that isn't registered in all three places fails the guardrail contract, not
silently passes.

**Warning signs:**
New catalog/configurator markdown or HTML files with no corresponding docs-contract test coverage;
a docs-contract lane count assertion (`== 26` today) left unchanged after adding new claim-bearing
surfaces (a sign the new surface was never wired into the guard).

**Phase to address:**
`CATALOG-01` and `CONFIG-01` — each phase that introduces a new public-facing text/HTML surface
must extend or add a docs-contract lane in the same phase, per the project's existing "every claim
needs a matching tripwire" discipline.

---

### Pitfall 15: Preset/theme logic leaking into `lib/rendro/theme.ex` and tripping the locked industry-guard test

**What goes wrong:**
`test/docs_contract/theme_industry_guard_test.exs` is an already-shipped, locked v2.11 tripwire
that statically `refute`s the words `preset`, `catalog`, `configurator`, and `genre` (plus every
recipe-family/industry name) from ever appearing in `lib/rendro/theme.ex`'s source — by design,
`Rendro.Theme` ships exactly `default/0` + `from_brand/2`, nothing genre-aware. Any
implementation shortcut that adds preset dispatch logic, a `preset:` option, or genre-aware
branching directly into `theme.ex` (rather than the seed's specified new file,
`lib/rendro/theme/presets.ex`) fails this test immediately and hard — and if a developer's first
instinct is to "fix the test" rather than relocate the code, the milestone quietly reverses a
deliberate v2.11 architectural boundary.

**Why it happens:**
Presets are conceptually "a fancier `from_brand/2`," and `from_brand/2` already lives in
`theme.ex` — it's the path of least resistance to bolt preset dispatch onto the same module rather
than stand up a new one, especially mid-implementation when the seam feels artificial.

**How to avoid:**
Treat `theme_industry_guard_test.exs` as a hard boundary, not a test to modify: `Theme.preset/2`
and all genre-specific token tables must live in `lib/rendro/theme/presets.ex` (as the seed
already specifies), calling into `Theme.resolve/1` as its only touch point on `theme.ex`, exactly
the same way `from_brand/2` composes rather than special-cases. If a genuinely new capability
requires touching `theme.ex`, that's a signal to re-examine the design, not to relax the guard
test's forbidden-terms list.

**Warning signs:**
Any PR that edits `theme_industry_guard_test.exs`'s `forbidden` word list to make it pass; a
`preset`/`genre`/`catalog` string appearing anywhere in `theme.ex` (including comments — the guard
greps raw source, not just public API).

**Phase to address:**
`PRESET-01` — this is the single highest-leverage structural pitfall for the whole milestone,
since it's the one place a locked prior-milestone decision can be silently undone by this one; it
should be called out explicitly in the phase plan before implementation starts.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|-----------------|------------------|
| Full domain × brand × preset × mode cross product for the catalog instead of a curated subset | Simple to generate, "shows everything" | ~20x render/CI/tarball growth, unreviewable mass re-blessing (Pitfall 6/7) | Never — always cap with an explicit, tested budget |
| Reusing the copy-snippet formatting logic independently in configurator JS instead of sharing it with `mix rendro.gen.theme` | Faster to ship the static page in isolation | Drift produces invalid/wrong snippets (Pitfall 11) | Never — share the template/format from day one |
| Skipping a dedicated docs-contract lane for new catalog/configurator surfaces, relying on the existing lanes "probably" covering it | Fewer new test files to write | Silent overclaim surface with zero tripwire coverage (Pitfall 14) | Never — every new public surface gets its own lane or explicit extension |
| Vendoring a font without pinning an exact upstream version/commit | Faster to "just grab the font" | Any later "helpful" font upgrade silently invalidates dozens of goldens (Pitfall 5) | Never — pin at vendoring time, document in `NOTICE` |
| Open freeform accent color picker in the configurator instead of a closed curated palette | Feels more flexible/powerful | Preview/render drift and implicit quality-guarantee risk (Pitfall 12) | Only if paired with an explicit "approximate preview" UI warning — closed palette is strictly preferred |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|-----------------|-------------------|
| Font vendoring (OFL fonts) | Assuming "freely downloadable" implies redistribution rights | Verify OFL 1.1 (or equivalent) license text ships with the font's own release; pin exact version in `NOTICE` |
| Hex tarball packaging (`mix.exs` `package.files`) | Forgetting to add `priv/fonts` to the allowlist, so fonts silently don't ship to real Hex consumers | Add a positive tarball-content test asserting every preset-referenced font file is present in the built `.tar` |
| `mix rendro.launch_artifacts.gen` extension for the catalog | Treating catalog generation as "just loop over more combinations" of the existing gallery generator | Add an explicit combinatorial budget/ceiling test before wiring in new dimensions |
| `mix rendro.gen.theme` codegen vs. configurator copy-snippet | Two independent string-templating implementations of the same Elixir-snippet shape | Share one canonical snippet-format source; add a compile-round-trip test across the bounded enum |
| Guardrails lockstep triple (`scripts/verify_docs.exs`, `required_checks_contract_test.exs`, `priv/guardrails/required_status_checks.json`) | Adding a new docs-contract lane for catalog/font/configurator claims without updating all three lockstep locations | Bump all three in the same commit that adds the new lane; the lane-count assertion (`== 26` pre-milestone) will fail loudly if missed |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|-----------------|
| Unbounded catalog cross product | `mix rendro.launch_artifacts.gen` wall-clock time balloons; CI job timeouts | Explicit row-count ceiling test, curated (not full-product) brand/preset pairing per domain | Past ~50-100 rendered+rasterized artifacts on typical CI runners |
| Font subsetting run per-cell instead of cached per (font, glyph-set) | Redundant subsetting work multiplies with catalog size | Cache/memoize subset results keyed by (font id, sorted glyph set) during a single generation run | Once catalog cells sharing the same font/glyph-set exceed a handful |
| `mix ci.fast` runtime growth from new determinism/golden tests at catalog scale | The fast lane stops being fast, eroding the split-lane discipline C1 established | Keep catalog-grid generation/verification in the same proof/advisory lane tier as existing raster proof, not the required fast lane | Once catalog-specific tests meaningfully slow `mix ci.fast` |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Rendering URL-derived configurator state via `innerHTML`/string concatenation | Reflected XSS via a crafted shareable configurator URL | Whitelist-validate preset/accent/mode against closed enums; use `textContent`/DOM APIs, never string-built HTML |
| No security-review pass on the configurator because "it's just static HTML" | Real client-side attack surface (URL state, copy-to-clipboard, generated code) goes unreviewed | Run the project's standard threat-closure discipline (mirrors the 16-threats-closed pattern from the v2.10 examples loader) on `CONFIG-01` explicitly |
| Copy-snippet templating accepting unvalidated accent input | A malformed/malicious accent value could break out of the intended Elixir tuple literal in the generated snippet text | Validate accent as a strict hex-color pattern before any string interpolation into the snippet |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|--------------|-------------------|
| "Nearest pre-rendered preview" silently diverges from the copied snippet's actual output | User ships a document that looks different from what they previewed, eroding trust in the whole configurator | Closed curated accent palette so preview == actual output by construction; if open picker is kept, visibly flag approximation |
| Catalog implies every preset/brand/domain combination is equally polished | User picks the one combination (e.g. Ticket-style hierarchy) that's honestly known-broken, with no warning | Surface per-cell rubric status in the catalog UI itself, not just in an internal manifest |
| Configurator snippet doesn't compile or produces a confusing runtime error | First-touch failure on the exact "90% path" the feature exists to serve | Compile-round-trip test across the full producible-snippet enum in CI, shared snippet source with `mix rendro.gen.theme` |

## "Looks Done But Isn't" Checklist

- [ ] **Preset fonts:** Often missing from the actual Hex tarball even though they render fine locally — verify with `mix hex.build` + a positive tarball-content assertion, not just local `mix test`.
- [ ] **Font license compliance:** Often has a `NOTICE` entry with vague/generic attribution once more than one font is vendored — verify each font has its own clearly-delimited copyright + OFL block with a pinned version.
- [ ] **Catalog "quality ratchet":** Often implies full-grid human review while only a handful of cells were actually eyeballed — verify the rubric manifest's coverage claim matches its actual per-cell sign-off entries.
- [ ] **Configurator "static, no server":** Often has a hidden `npm install`/build step or a live "nearest match" compute path — verify by literally checking there is no `package.json` and no network/server dependency in the shipped path.
- [ ] **Copy-snippet correctness:** Often "looks right" for the handful of combinations manually tried in dev but fails to compile for edge combinations (e.g. an accent with all-zero or all-`f` bytes, an unusual preset/mode pairing) — verify with an exhaustive compile-round-trip test over the bounded enum.
- [ ] **Dark catalog tiles:** Often visually convincing enough to imply print-safety/accessibility despite the existing `supported_screen_oriented` boundary — verify catalog-facing copy carries the same non-print framing the theming guide already does.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|-----------------|------------------|
| Non-redistributable font shipped to Hex | HIGH | Yank/patch-release immediately removing the font + preset that depends on it; re-source a properly-licensed replacement; re-bless affected goldens with a clearly-scoped commit |
| Missing `priv/fonts` in `mix.exs` package allowlist discovered post-release | MEDIUM | Patch release adding the allowlist entry; verify via `mix hex.build` diff before re-publishing; no rendering-logic change needed |
| Catalog combinatorial explosion already merged | MEDIUM | Introduce the row-count budget test retroactively, prune the grid to the curated subset in a scoped follow-up commit with an explicit before/after row count in the message |
| Theme-industry-guard test violated (preset logic landed in `theme.ex`) | LOW-MEDIUM | Relocate the offending code to `lib/rendro/theme/presets.ex` in a dedicated refactor commit before the guard test is touched at all; never edit the guard's forbidden-word list to "fix" the failure |
| Rubric ratchet found to be silently narrower than its public description | LOW | Correct the catalog/docs copy to describe the actual reviewed scope; this is a docs-honesty fix, not a code fix, and should ship fast once discovered |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|----------------|
| 1. Non-redistributable font sourced | `PRESET-02` | License-class checklist (OFL 1.1/Apache 2.0/UFL only) gates font selection before any byte is vendored |
| 2. Missing NOTICE/RFN/tarball-allowlist entries | `PRESET-02` | Positive tarball-content test + per-font `NOTICE` block review |
| 3. Font subsetting nondeterminism | `PRESET-02` | `assert_deterministic!/1`-style double-subset test per vendored font |
| 4. Float math in preset token derivation | `PRESET-01` | Source-grep guard forbidding float-producing calls in recipe/render paths; presets resolve once to integer/point values |
| 5. Hash-check drift from font/preset revisions | `PRESET-01`/`PRESET-02`, enforced at `CATALOG-01` | Pinned font versions in `NOTICE`; scoped, explained re-bless commits |
| 6. Catalog combinatorial explosion | `CATALOG-01` | Structural row-count budget/ceiling test on the catalog manifest |
| 7. Hash-brittleness / rubber-stamped re-blessing | `CATALOG-01` | Required human-reviewed visual sample attached to any mass re-bless PR |
| 8. Rubric ratchet becomes a rubber stamp | `CATALOG-01` + carryover fix phase | Manifest schema documents actual reviewed scope; existing `passed:false` entries never silently flip |
| 9. Configurator requires server/Node/build step | `CONFIG-01` | No `package.json`/npm build anywhere in the shipped path; verified by repo inspection + CI-context audit |
| 10. URL-state XSS | `CONFIG-01` | Dedicated security-review pass; whitelist validation + `textContent`-only rendering |
| 11. Copy-snippet produces invalid Elixir | `CONFIG-01` | Compile-round-trip test (`Code.string_to_quoted!/1`) across the bounded preset × mode × accent enum |
| 12. Preview/render drift | `CONFIG-01` | Closed curated accent palette design decision, or explicit "approximate" UI flag if open picker is kept |
| 13. Presets imply a design-quality guarantee | `PRESET-01`/`CATALOG-01` | Docs-contract tripwire extension scanning preset/catalog copy for unconditional quality language |
| 14. Catalog implies accessibility/compliance coverage | `CATALOG-01`/`CONFIG-01` | Extended `accessibility_overclaim_test.exs`/`theming_claims_test.exs` coverage + guardrails lockstep lane-count bump |
| 15. Preset logic leaks into `theme.ex`, tripping the industry guard | `PRESET-01` | `theme_industry_guard_test.exs` stays green with its forbidden-word list unmodified; preset code lives only in `lib/rendro/theme/presets.ex` |

## Sources

- `lib/rendro/theme.ex` — existing `Theme` contract, `from_brand/2` derivation, D-01/D-03/D-05 determinism decisions in comments.
- `test/docs_contract/theme_industry_guard_test.exs` — locked v2.11 static tripwire forbidding preset/catalog/configurator/genre terms in `theme.ex`.
- `lib/rendro/font_registry.ex`, `lib/rendro/pdf/font_subsetter.ex`, `lib/rendro/pdf/cid_font.ex`, `lib/rendro/pdf/font_parser.ex` — existing font pipeline; subsetter's `Enum.sort` on table tags as the existing determinism precedent.
- `NOTICE` — existing single-font (B612, SIL OFL 1.1) attribution block, the template this milestone must scale.
- `mix.exs` (`defp package`) — current Hex tarball allowlist, confirming `priv/fonts` is not yet included.
- `test/docs_contract/*.exs` (26 lanes as of v2.11, incl. `branding_claims_test.exs`, `theming_claims_test.exs`, `accessibility_overclaim_test.exs`, `rubric_manifest_contract_test.exs`) — existing overclaim-tripwire and contract-enforcement patterns this milestone must extend.
- `test/guardrails/required_checks_contract_test.exs` — the lockstep lane-count assertion (`== 26`) that any new docs-contract lane must update.
- `priv/quality/rubric_scores.json`, `priv/quality/SIGN-OFF.md` — existing honest, human-signed-off rubric process (including Ticket's genuine `passed: false`), the precedent for catalog-scale rubric-ratchet honesty.
- `lib/mix/tasks/rendro/launch_artifacts/gen.ex`, `assets/rendro/artifacts.json` (11 rows today) — existing gallery generator the catalog extends; basis for the combinatorial-growth estimate.
- `lib/mix/tasks/brand.gen.ex` — existing `--check`-drift-gated codegen pattern `mix rendro.gen.theme` is modeled on.
- `.planning/PROJECT.md` — Constraints (pure-Elixir core, Node/npm never required, no-overclaim documentation honesty) and Key Decisions (MODE-01/MODE-03 dark-mode determinism/overclaim boundary, D-01 palette/theme precedence, CONTRACT-03 theme industry-agnosticism).
- `.planning/seeds/SEED-004-style-genre-presets-public-catalog.md` — milestone scope, locked design (presets as `%Theme{}` values in a new file, curated OFL fonts, catalog + rubric ratchet, static configurator boundary).
- SIL Open Font License 1.1 text (via the vendored `NOTICE` copy) — redistribution/embedding/RFN mechanics referenced in Pitfalls 1-2 (general OFL domain knowledge, cross-checked against this repo's own existing license copy).

---
*Pitfalls research for: Rendro v2.12 (SEED-004) — Style-Genre Presets, Public Catalog & Static Configurator*
*Researched: 2026-07-28*
