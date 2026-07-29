# Phase 121: Light/dark background-fill mechanism (all 7 recipes) - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a **role-derived, full-page background-fill mechanism** so every one of the 7 recipes gets dark mode "for free" by reading `theme.colors.background`, while an un-themed (light/no-theme) render stays **byte-identical to v2.10**. Concretely this phase ships: a first-in-list `:background` page-template region that paints a single full-page rect (behind all content, on every page incl. paginate-generated overflow), the completion of foreground-text color seams so dark actually reads (not just paints), a deterministic dark-mechanism test, and a `theming` support-matrix stub row with an explicit screen-only / non-print boundary.

**In scope:** MODE-01 (`mode: :light | :dark` via `Rendro.Theme.dark/1` role swap, no draw-time transcendental color math), MODE-02 (full-page background region emitted per-page; light emits no rect, byte-identical), MODE-03 (dark documented as screen-oriented, non-print boundary + support-matrix row, no PDF-UA/accessibility/WCAG claim, all *shipped* demos light), plus the legibility completion that makes dark honest.

**Out of scope (deferred, do not pull in):** the human-facing dark **gallery visual** and `guides/theming.md` (Phase 123, DEFAULT-03 + CONTRACT-02); typography/type-scale wiring (Phase 122); `default/0` rubric tuning and the DATA-first SHOW-01 fix (Phase 123); any engine-pipeline theme awareness; any new dependency.
</domain>

<decisions>
## Implementation Decisions

Backed by four parallel research passes (one per decision point), each reading the brand book, the OSS deep-research corpus, and the actual theme/recipe/pipeline code. The four decisions are mutually coherent — legibility completion (D-01) is the connective tissue that makes the value-driven emit trigger (D-04) safe and any future dark demo honest.

### Legibility scope — dark must READ, not just paint
- **D-01:** Ship **legibility-complete** dark, not page-background-only. Adopt a lint-able **foreground role contract**: *no recipe draws text with a hardcoded literal or the implicit `Rendro.Text` default `{0,0,0}` — every foreground reads a swappable role by what it sits on.* Primary text → `colors.ink`; secondary/captions/page-numbers → `colors.muted`; text on a `surface` band → `ink`/`muted` (surface is a flat tint sharing the same neutral foreground poles, not a distinct elevation plane); text on an `accent` fill → `on_accent` (latent — no live draw-site today, documented for future accent bands); rules/borders/frames → `rule`. — **Reversibility:** costly — the role contract becomes an implicit public expectation once themed recipes ship; walking it back would strand text on a theme swap (the exact defect being fixed) and would need every recipe re-audited.
- **D-02:** Only **two** recipes need edits; the other five are verify-only. **Statement** is the primary outlier (it currently passes NO `color:` on any text block, so under `dark/1` the whole document is near-black-on-near-black): seam its header/account/period/opening-balance/closing-label/closing-value text, its body table cells (currently plain strings — the one real byte-risk, so preserve the current effective cell size), and its footer `page_number` (`page_number/1` forwards `color:` to `text/1`). **Certificate** needs its body text (the two `Rendro.text(text, size: size)` draw-sites) seamed to `colors.ink`. **Payslip** is the reference pattern to copy verbatim (already all-correct). **Verify-only, do NOT edit:** Payslip, Invoice, Receipt, Branded Invoice, Ticket (each already passes an explicit swappable `color:` on every `Rendro.text`).
- **D-03:** Byte-identity is preserved **by construction**: in each seamed recipe's `palette/1` **nil-branch**, add the neutral roles at today's literal (`ink: {0,0,0}`, `muted: {0,0,0}`) so `color: colors.ink` resolves to `{0,0,0}` on the no-theme path (identical to today's implicit default) and to the swapped pole under a theme. The frozen sha256 goldens + `edge_matrix` are the enforcement gate. This mirrors Phase 120's split discipline — light path proven byte-identical.

### Layering & existing bands/frames — everything rides the role swap
- **D-04:** Add the `:background` as the **first region** in each recipe's `template.regions` list, painting one `%Rendro.Path{}` full-page fill rect (`{:rect, 0, 0, page_w, page_h}`, region `x:0 y:0 width:page_w height:page_h`, block `height: page_h`). **Z-order is already guaranteed by the engine — no engine change:** `apply_page_template/5` builds `anchored_blocks` from `regions |> reject(:body) |> flat_map(...)` (order-preserving) and prepends via `anchored_blocks ++ page.blocks` (paginate.ex:911-923); the writer emits blocks in list order (writer.ex:511-513) and PDF paints in stream order (painter's algorithm), so first-in-`regions` `:background` = bottom of the paint stack, behind header/footer/body on every page including overflow. `validate_region_fit!` passes iff the region ≥ page, so size it to the full page exactly. — **Reversibility:** reversible — a recipe-level ordering convention, no engine or contract change.
- **D-05:** **Every existing colored element rides the `dark/1` swap for free — zero recipes get a bespoke dark branch.** Statement's `surface` closing-balance band, Payslip's `surface` summary backdrop, Certificate's `rule` frame, Ticket's `rule` perforation/stub strokes, Invoice's `accent` link (accent is intentionally unchanged in dark, R2) all already read roles and swap automatically — expressing dark elevation as a *lighter surface tint on a darker page* (the Material "surface tint = elevation without shadows" idiom, mandatory here since Rendro bans shadow/opacity/gradient). Grep confirms **no recipe ever does `fill: colors.background`** — the `:background` role is consumed solely by the new region, so the un-guarded `background: {255,255,255}` literal in each `palette/1` is not a clash and correctly stays outside the `no_inline_color_literals` guard.

### Emit trigger — value-driven, not mode-gated
- **D-06:** Emit the `:background` full-page fill **iff the resolved `theme.colors.background != {255,255,255}`** (exact integer-tuple equality as the sole "no-paint" sentinel — **no tolerance, no near-white rounding**). This strictly subsumes a dark-only gate (every dark background is non-white) while making the mechanism *value-driven*: the page paints its resolved `background`, and paper-white is the reserved identity value that paints nothing. — **Reversibility:** costly — the emit rule is an observable behavior; a tinted-light theme that paints today would stop painting if narrowed to dark-only later, a visible regression.
  - **Why not mode-gated:** `from_brand/2` *already* threads a `:background` token (theme.ex:270-282) and Phase 123's scope is `from_brand/2` E2E + tinted defaults + gallery. A mode-gated trigger would force **reopening paginate.ex** in Phase 123 to make branded/cream *light* backgrounds paint. Value-driven ships that capability now for free, same predicate, zero determinism cost, no re-bless.
  - **Determinism:** `default/0` and every no-theme render have `background == {255,255,255}` exactly → predicate false → region emits zero ops → byte-identical (frozen goldens hold). `dark/1` sets `{27,23,19}` → always paints. Near-white (`{254,254,254}`) correctly paints (consumer asked for a near-white page) — the exact sentinel is the guard against an arbitrary/non-deterministic cutoff. Document that pure white `{255,255,255}` is the reserved no-paint value.
  - **Phase-123 flag:** confirm `default/0` keeps `background` at exactly `{255,255,255}`. If a future "restrained neutral" default is ever nudged to a cream, that will *intentionally* start painting and require **net-new** (not re-blessed) goldens with human sign-off — the correct, visible consequence of D-06, never a silent regression.

### Demo & evidence posture — mechanism proof now, visual deferred
- **D-07:** Ship **zero shipped/public dark demos in Phase 121.** Gallery PNGs ride in the Hex tarball and are asserted by `launch_artifacts_claims_test.exs`, so any dark gallery PNG *is* a shipped dark demo → violates MODE-03 by construction, and an unlabeled dark raster beside light "print-ready" previews reads as an implicit print/output claim. Prove the mechanism the honest way — a deterministic **test** — and defer the human-facing dark **visual** to Phase 123 (DEFAULT-03 `(recipe × mode)` gallery rows + CONTRACT-02 `guides/theming.md`), which is also correctly *after* the WR-01 legibility fix (D-01), typography (122), and the DATA fix (123), so a dark image can never ship showing invisible/unstyled text. — **Reversibility:** reversible — a phasing choice; nothing shipped to walk back.
- **D-08:** The **mechanism test** (e.g. `test/rendro/recipes/theme_mode_background_golden_test.exs`, or folded into the determinism-golden suite) asserts: (a) light / no-theme emits **no** background rect and is byte-identical to the v2.10 golden (reuse the PLUMB-03 identity guard); (b) dark (`mode: :dark`) emits the `:background` fill as the **first** content op on page 1 **and** on a **forced-overflow** page (fixture sized to spill), fill color == the resolved `theme.colors.background` tuple; (c) existing band/frame/section ops are byte-unchanged (proves both light byte-identity and clean dark composition / z-order).
- **D-09:** Add a **`theming` support-matrix stub row** now, mirroring the existing idiom: `light` = `supported` (evidence = the determinism test; capabilities: no_background_rect, byte_identical_to_v2_10, deterministic_output); `dark` = `supported_screen_oriented` (capabilities: full_page_background_every_page, overflow_page_background, deterministic_output; **boundaries**: `print_recommended`, `accessibility_pdf_ua_claim`, `wcag_contrast_claim`, `gui_viewer_visual_fidelity_claim` all `unsupported`). Add a small `theming_claims_test.exs` docs-contract lane asserting the boundary keys are set, no `theming` row carries a print/PDF-UA/WCAG *support* term, and `Rendro.Theme.dark/1`'s `@doc` contains the explicit "screen-oriented, not recommended for print" boundary sentence. **Do NOT create `guides/theming.md`** — it belongs to Phase 123 (CONTRACT-02); the full `(recipe × mode)` gallery evidence fields are filled there.

### Cross-cutting
- **D-10:** Centralize the `:background` region construction (geometry + the D-06 emit predicate) in **one shared helper** the recipes call, rather than duplicating it across 7 recipes — this directly pays down the Phase-120 code-review WR-02 finding (`palette/1` copy-pasted with no sync guard) instead of compounding it.

### Claude's Discretion
- Exact test file name/placement (new file vs folding into the existing determinism-golden suite) — planner/executor choice, provided D-08's assertions are all covered.
- The precise shape of the shared `:background` helper (module-private function vs a small shared recipe helper module) — implementation detail, provided D-10's single-source-of-truth intent holds.
- Whether to seam Certificate's empty spacer `Rendro.text("", size: 1)` — no visible glyphs, harmless either way.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — MODE-01, MODE-02, MODE-03 (this phase); DEFAULT-03 + CONTRACT-02 (Phase 123, own the dark visual — do NOT pull forward).
- `.planning/ROADMAP.md` — Phase 121 goal + Success Criteria (SC2 mandates the determinism dark golden with a forced-overflow page); Phase 122/123 boundaries.
- `.planning/phases/119-rendro-theme-core-module-the-one-way-door/119-CONTEXT.md` — locked `Rendro.Theme` shape, `dark/1`/`resolve/1` semantics, role list.
- `.planning/phases/120-.../120-REVIEW.md` — WR-01 (Statement band overlay text unseam ed → this phase's D-01/D-02) and WR-02 (`palette/1` duplication → D-10).

### Brand / design intent (prefer these over older brand docs on conflict)
- `prompts/Rendro Brand Book.txt` — brand color intent, honesty law (§5/§15: never ship a claim without proof; confident-but-never-overclaim — the basis for legibility-complete D-01 and demo-deferral D-07).
- `prompts/rendro-oss-dna.md`, `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — ecosystem posture, determinism-first values.
- `guides/branding.md` — current public branding guide.

### Code the plan must touch or honor
- `lib/rendro/theme.ex` — roles, `default/0` (`background {255,255,255}`), `dark/1` (`background {27,23,19}`), `resolve/1` idempotence, `from_brand/2` (already threads `:background`).
- `lib/rendro/text.ex` — default `color: {0,0,0}` (the implicit-black hole D-01 closes).
- `lib/rendro.ex` — `page_number/1` forwards `color:` to `text/1` (Statement footer seam).
- `lib/rendro/pipeline/paginate.ex` — `apply_page_template/5` (regions → `anchored_blocks ++ page.blocks`, per-page incl. overflow), `validate_region_fit!` (full-page fit).
- `lib/rendro/pipeline/compose.ex`, `lib/rendro/pipeline/measure.ex` — region/block flow (theme-unaware, must stay so).
- `lib/rendro/writer.ex` — `build_content_stream/4` (blocks emitted in list order → z-order).
- `lib/rendro/path.ex`, `lib/rendro/page_template.ex` — `%Rendro.Path{}` fill rect, `%Rendro.PageTemplate{regions:}`.
- `lib/rendro/recipes/{statement,certificate}.ex` — the two recipes to edit; `lib/rendro/recipes/payslip.ex` — the reference pattern; the other four — verify-only.
- `priv/support_matrix.json` — row-shape idiom for the `theming` stub (D-09).
- `test/rendro/recipes/no_inline_color_literals_test.exs` — Phase-120 guard (cross-check; `background` literal correctly un-guarded).
- `test/docs_contract/launch_artifacts_claims_test.exs`, `test/docs_contract/accessibility_overclaim_test.exs` — gallery-PNGs-ship proof (D-07) and the overclaim-tripwire pattern to mirror for `theming_claims_test.exs`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rendro.Theme.dark/1` + resolved integer-tuple roles: dark mode is a value swap, not new art — recipes need no per-mode logic.
- `apply_page_template/5` per-page region application (incl. overflow) + painter's-algorithm block order: the `:background` region rides existing machinery with **no engine change** (z-order proven, D-04).
- Payslip's already-correct text seams + nil-branch (`payslip.ex:686-692`, all-black) and `page_number(color:)` usage (`payslip.ex:669`): the exact copy-target pattern for Statement/Certificate.
- `%Rendro.Path{}` fill primitive: draws the full-page rect deterministically.

### Established Patterns
- 3-rung recipe pattern (`document/2` → `page_template/1` → `sections/2`) with `palette/1` nil-branch = today's literals: the byte-identity seam vehicle (D-03), proven across Phase 120.
- Support-matrix + docs-contract "claim must be bounded to evidence" discipline: the `theming` stub row + `theming_claims_test.exs` follow it (D-09).
- Material "surface tint = elevation without shadow" idiom already lived by Statement/Payslip bands: the coherent dark look across all 7 recipes (D-05).

### Integration Points
- New `:background` region prepended to each recipe's `template.regions` (Certificate at its `page_template` construction ~L130/132).
- Emit predicate reads the already-resolved `%Theme{}` threaded through the existing 3-rung path — no new plumbing.
</code_context>

<specifics>
## Specific Ideas

- User directive: research each decision deeply through ecosystem/DX/design-pillar lenses and lock one coherent set of recommendations. Done — four parallel research passes produced the mutually-coherent D-01…D-10 above.
- Ecosystem anchors the plan should honor: paint the page background **once, first, as a page-level fill** (Typst `page(fill:)`, ReportLab/Prawn draw-rect-first); express dark elevation as a lighter surface tint, never shadow/opacity (Material dark surfaces — and Rendro bans shadow/opacity/gradient); pair every fill role with a foreground role so a theme swap can't strand text (Material `on-*` tokens; the CSS/terminal footgun is one un-tokenized default — here `Text`'s `{0,0,0}`); keep dark strictly screen-context and light-first (Material/Primer/Tailwind force light for print).
</specifics>

<deferred>
## Deferred Ideas

- **Human-facing dark gallery visual** + `guides/theming.md` — Phase 123 (DEFAULT-03 `(recipe × mode)` blessed gallery rows + CONTRACT-02), after legibility (D-01), typography (122), and the DATA-first SHOW-01 fix, so no dark image ships pre-legibility/pre-typography.
- **`accent`-fill bands reading `on_accent`** — no recipe fills with `accent` today; the `on_accent` foreground pairing is documented in the D-01 contract as latent future-proofing, not work for this phase.
- **Tinted/cream light `default/0`** — D-06's value-driven trigger makes it *possible* now, but changing the shipped `default/0` background is Phase 123's rubric/`default` tuning (would require net-new blessed goldens + human sign-off).
- **Any WCAG/PDF-UA/print-safety dark claim** — permanently out; D-09 boundary keys assert `unsupported`.

None of these were scope creep from the user — they are the natural downstream owners for work this phase deliberately leaves out.
</deferred>

---

*Phase: 121-Light/dark background-fill mechanism (all 7 recipes)*
*Context gathered: 2026-07-27*
