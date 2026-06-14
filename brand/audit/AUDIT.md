# Rendro Brand Book — Critical Audit

**Phase 101 · GSD milestone B1 · 2026-06-14**
Auditor stance: pressure-test, not redesign. Default = KEEP and TIGHTEN. REWORK only for generic, inaccessible, contradictory, or unbuildable items.
Source of truth: `prompts/Rendro Brand Book.txt` (1,171 lines), `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md`, `README.md`, `mix.exs`.

> Inferred items are marked **[INFERRED]**. Where the audit asserts a fact about the shipping library, it is grounded in `README.md` / `mix.exs`.

---

## 1. Executive judgment

**Is it strong enough to build from?** Yes. This is an unusually well-grounded brand book. The "structured flow" metaphor (`data → document AST → layout → pagination → PDF bytes`) is not decoration — it is the actual architecture of the library, which means the visual system, diagrams, microcopy, and docs all reinforce the product instead of papering over it. The voice section is the strongest asset: it is specific, anti-hype, and directly executable as copy. The color and type systems are complete enough to start tokenizing today.

**Distinct enough?** Mostly yes, *given disciplined execution*. The distinctiveness is entirely strategic, not yet visual: warm paper + ink + restrained blue is a genuinely differentiated stance against the "devtool neon on near-black" default, and the "explain the failure" personality is rare. But distinctiveness currently lives in prose. There is **no logo**, no specimen, no rendered surface — so the brand is distinct as a *position* but unproven as an *artifact*. The one thing that could make it generic is the wordmark advice ("slightly customized R and o") which, if executed literally, yields Inter-with-a-tweak — i.e., every other Hex package.

**Implementation-ready?** Color and type: yes. Voice and microcopy: yes. Tokens: partial — raw values exist but semantic roles, dark mode, and state tokens do not (Phase 102 must close this). Logo: no — concepts only (Phases 103/104 must produce the asset). Components: specified at prose level, not at spec level.

**Over/under/balanced-specified?** **Balanced, leaning slightly over-specified in places that don't yet matter** (motion timings, admin-UI labels, iconography for icons that don't exist) and **under-specified in the one place that matters most** (the logo, which is the milestone's headline deliverable). It also spends real estate on a future Ecto/admin layer that the shipping README doesn't claim. Trim the speculative, deepen the logo.

**Highest-leverage improvement:** Produce the actual integrated typemark per the user's hard constraints (no box, motif worked into the letterforms, logotype tight to the mark, no subtitle on the main combo). Everything else is tightening; the logo is the missing load-bearing wall.

**What must NOT change:**
- The "structured flow" metaphor and the `data → … → PDF` pipeline as the visual spine.
- The voice principles and the four-part error pattern (*what / where / why / what to try*).
- The honesty stance ("What Rendro is not", "Honest Capability", no compliance overclaims).
- The ink/paper/blue palette identity and the 60/25/10/5 ratio discipline.
- Inter + JetBrains Mono (OFL/SIL-clean, screen-tuned, correct for the audience).

---

## 2. Brand DNA extraction

| Dimension | Extraction |
|---|---|
| **Essence** | A native Elixir document engine you can reason about and operate. |
| **Audience** | Phoenix/Elixir engineers shipping business documents in production (invoices, statements, receipts, certificates, reports). Secondary: back-office/reporting devs, SREs. **[INFERRED secondary order]** |
| **Emotional tone** | Calm competence. Relief, not excitement. "Finally, no Chrome in prod." |
| **Technical promise** | Composable in code, predictable in layout, observable in production, honest about limits. |
| **Visual metaphor** | Structured flow — content becoming a reliable document through frames, baselines, pagination, and observability traces. *Not* printing, *not* browser rendering. |
| **Personality traits** | Precise, calm, helpful, native, observable, crafted, open. Formula: 70% senior maintainer / 20% typographer / 10% SRE. |
| **Anti-traits** | Flashy, mascot-heavy, corporate-enterprise, print-shop nostalgic, "AI-generated everything", browser-rendering-disguised-as-native, compliance-overclaiming, dark-pattern SaaS. |
| **Design principles** | Structure over decoration; inspectable artifacts; document warmth over SaaS gloss; the sheet of paper is real (4px radius), the UI is soft (6–16px). |
| **Voice principles** | Concrete nouns, precise verbs, honest limits, short explanations, helpful next steps, no jokes in errors, no "magic", no "just works" without proof. |
| **Should feel like…** | ExDoc clarity + Phoenix dashboard practicality + a well-set technical manual. Quieter than a SaaS startup, warmer than a systems library, more precise than a design tool. |
| **Should never feel like…** | A commercial PDF SDK, a browser wrapper, a prepress/CHILI product, a hacker-neon devtool, or a hype landing page. |

---

## 3. Stress tests (narrative)

*(The row-by-row matrix lives in `SCORECARD.md`; this is the narrative read.)*

**Where the brand is strong and self-reinforcing.** On text-heavy, developer-facing surfaces — README, HexDocs, error messages, code blocks, comparison tables — the brand is essentially already built. The voice rules, the four-part error pattern, the docs-voice "Do this / This returns / This fails when" verbs, and the honesty block all drop directly into the existing README with almost no translation loss. The current README already *sounds* like the brand book (honest "What Rendro is not", operational proof language, no overclaims). This is the rare case where copy guidance and shipping product are in sync.

**Where the brand gets thin — visual surfaces.** Every surface that needs a *mark* rather than *words* is currently unserved: GitHub avatar, favicon, Hex package icon, social preview card, app icon, sticker, small-monochrome lockup. The HexDocs badge in the README is already generic purple (`hex--docs-purple`), which quietly contradicts the "Rendro should own ink/paper/blue, not become purple-heavy" rule. The book describes four logo *concepts* but commits to none and ships nothing, so all of these surfaces fail today not because guidance is wrong but because there is no asset to place.

**Where the brand risks self-contradiction at scale.** Dark mode is the sharpest stress fracture. The palette is explicitly warm-paper-first ("calmer than typical devtool neon"), but HexDocs, GitHub, and most devs' OS default to dark. The book gives `ink-900` as a code-block background option but never resolves what "paper" becomes in dark mode — does warm paper invert to warm-dark, or to neutral-dark? Without an answer, every dark surface is improvised and the brand loses its single most distinctive trait (warmth) exactly where most developers will first see it. The mix.exs `before_closing_head_tag` already hand-rolls a `prefers-color-scheme: dark` block — proof the gap is already being patched ad hoc.

**Where the brand is over-built for its current stage.** Sections 13 (UI system), 21 (admin UI), and parts of 12 (iconography) specify components, labels, and icons for surfaces that don't exist yet and that the shipping library (a pure-Elixir lib + ExDoc, no admin UI) does not yet claim. This is not wrong — it's a credible future — but it dilutes the book and can mislead a Phase 105/106 reader into specifying assets nobody will ship this milestone.

**Reality-vs-book drift to reconcile.** The book is versioned 0.1 and assumes `{:rendro, "~> 0.1"}`, a yet-to-be-claimed namespace, and a recommended `rendro-dev` org. The actual `mix.exs` is **v1.0.0**, source is **`github.com/szTheory/rendro`** (a personal namespace, not `rendro-dev`), and the README ships a mature operational story (telemetry, deterministic output, docs-contract, recipe gallery, signing/protection adapters). The brand book is describing an earlier, more tentative product than the one that exists. This is good news (the product over-delivered) but the book's "0.1 / find an org / pick a package name" framing is stale and should be reconciled.

---

## 4. Gaps & risks

### Critical
- **C1 — Name/trademark collision (CHILI rendro + existing `rendro` GitHub/NPM user). REQUIRES HUMAN/LEGAL REVIEW. Do not treat as resolved by this audit or any downstream phase.** The book correctly flags it but then proceeds as if cleared. CHILI publish/"CHILI rendro" is a *commercial PDF rendering/viewing SDK* — the single closest competitor category to mislead into — and `github.com/rendro` plus an NPM `rendro` profile already exist. The brand mitigations (always signal "Elixir-native open-source PDF layout library", avoid SDK/prepress/viewer cues) reduce *confusion* but do not address *trademark risk*. Concrete actions for a human: (a) trademark clearance search in relevant classes before any paid promotion; (b) confirm Hex `rendro` is held by this project; (c) decide GitHub org strategy given the personal-namespace reality. **Flag, don't resolve.**
- **C2 — No logo asset.** The headline deliverable of the milestone does not exist. Four concepts, zero artifacts, and a wordmark instruction ("slightly customized R and o") that, taken literally, produces a generic result and conflicts with the user's hard constraint that the motif be worked *into* the letterforms. This is the gating blocker for Phases 103/104 and for ~8 visual surfaces.
- **C3 — No dark-mode system.** Single biggest contradiction at scale (see §3). The brand's defining trait (warmth) has no defined dark behavior, yet dark is the default context for HexDocs/GitHub/most devs.

### Important
- **I1 — Tokens lack semantic roles + states.** The book ships raw color values and a JSON token block, but no `--color-text-primary`, `--color-bg-surface`, `--color-border-default`, `--color-link`, no hover/active/focus/disabled states, no focus-ring token. Phase 102 cannot build a real token system from raw hexes alone.
- **I2 — Contrast claims are asserted, not verified.** The book lists "Passes normal text" pairings (e.g. `blue-600 #2C6BED` on `sheet-000`, `teal-700 #0E7C76` on white, `amber-600` rules) without computed ratios. Several are plausibly borderline and **must be machine-verified in Phase 102**, not trusted. `blue-600` on `paper-100` is already flagged "avoid for small text" — good instinct, needs numbers.
- **I3 — Wordmark guidance is generic and partly conflicts with the user's logo constraints.** "Customized R and o" + "icon must work as avatar/favicon" pulls toward the *icon-left-of-text* lockup the user explicitly rejected. The book's logo section predates the user's hard constraints and must be overwritten by them.
- **I4 — Book-vs-reality drift (version, org, maturity).** v0.1 framing vs shipped v1.0.0; `rendro-dev` recommendation vs actual `szTheory/rendro`; tentative feature framing vs mature README. Stale guidance will mislead copy/README phases.
- **I5 — Generic-purple HexDocs badge contradicts the palette rule.** Small but real: the README's `hex--docs-purple` badge violates "own ink/paper/blue, not purple-heavy." Brandable.

### Nice-to-have
- **N1 — No social/OG preview spec** (1200×630), favicon master, or icon-grid construction.
- **N2 — Iconography specified before icons exist;** fine as a forward spec, but mark it as non-blocking for this milestone.
- **N3 — Admin/UI sections (13, 21) are speculative** relative to shipped scope; label as "future surfaces" so phase readers don't over-invest.
- **N4 — No motion-reduced / `prefers-reduced-motion` note** despite a full motion section.
- **N5 — `plum-700` Elixir-nod accent is a latent purple-creep risk;** the book warns against it but ships it as a core (not tint) token. Consider demoting to tint-only.

---

## 5. Recommended upgrades (only what needs work)

### 5.1 Logo system — REWORK (was concepts-only)
The four concepts are fine inspiration but must be superseded by an explicit, buildable spec honoring the user's hard constraints:

- **Integrated custom typemark**, not icon-left-of-text. The structured-flow motif must be worked *into the letterforms* — e.g., the bowl/leg of the **R** rendered as a page-frame with a flow line continuing through it, or a baseline/page-break rule integrated across the wordmark. The "R-frame" concept (#1) is the right seed *if* fused into the type rather than set beside it.
- **No rectangular background box.** Mark and logotype sit on the page directly.
- **Logotype tight to the mark** — the motif and wordmark read as one object, not a lockup with a gap.
- **Main combination mark has NO subtitle/tagline.** The tagline lives in copy, never baked into the primary logo.
- **Derive, don't redraw, the small forms.** Define how the integrated typemark reduces to (a) a standalone monogram glyph for favicon/avatar (16–24px) and (b) a one-color version. The book's "favicon 16px simplified mark" and "mark-only 24px" minimums stay, but they must be *derivations of the real mark*, not a separate icon.
- **Keep** the clearspace rule (height of lowercase `n`) and the "don'ts" list (no chili/flames/printer/Acrobat-ribbon/Elixir-droplet/browser-window/SDK-lockup). **Drop** "slightly customized R and o is enough" — it under-asks for what the user wants.
- **Color:** primary in `ink-900`; one-color and knockout (`sheet-000` on `ink-900`) variants required. Blue accent optional, never the whole mark.

### 5.2 Design tokens — TIGHTEN→ADD (was raw values only)
Phase 102 must add a *semantic layer* over the existing raw palette:
- **Semantic roles:** `text/primary|secondary|muted|inverse`, `bg/page|surface|raised|code`, `border/default|strong|subtle`, `link/default|hover|visited`, `accent/primary`, plus `feedback/info|success|warning|error` mapped to existing callout colors.
- **State tokens:** hover/active/focus/disabled for buttons and links; a dedicated **focus-ring** token (the book has zero focus states — an accessibility gap, see §5.3).
- **Dark mode:** define `paper`→dark behavior explicitly. Recommend a *warm-neutral dark* (not pure black) so the brand keeps warmth; map every semantic role to a dark value. This closes C3.
- **Verify, then publish:** run computed WCAG 2.2 contrast on every token pairing (closes I2). Encode pass/fail in the token doc, not prose.
- **Keep** the raw palette names (`ink-900`, `paper-100`, etc.) as the primitive layer; semantic tokens reference them. **Keep** shape/motion/type tokens as-is.
- Consider demoting `plum-700` to tint-only (N5).

### 5.3 Accessibility — TIGHTEN (was asserted, incomplete)
- Add **focus-visible** guidance and a focus-ring token (currently absent).
- Replace asserted contrast verdicts with computed ratios (I2).
- Add `prefers-reduced-motion` note to §14 (N4).
- Confirm callout patterns don't rely on color alone (add icon/label) — partially implied, make explicit.

### 5.4 Naming / org / version — TIGHTEN (stale)
- Reconcile to reality: package is `rendro` at **v1.0.0**, source is **`szTheory/rendro`**. Update or annotate the book's "0.1 / rendro-dev org / pick a name" guidance so Phase 106/107 don't propagate stale facts.
- Keep the first-mention rule and the differentiation signals verbatim — those are still correct and load-bearing for the C1 confusion mitigation.

### 5.5 Scope labeling — TIGHTEN
- Mark §13 (UI system), §21 (admin UI), §12 (icon set) as **"forward-looking surfaces, non-blocking for B1"** so specimen/copy/HTML-book phases focus on surfaces that ship now (README, HexDocs, landing, logo, tokens).

---

## 6. Disposition table (the B1 contract)

| Element | Disposition | Notes / what downstream phase must honor |
|---|---|---|
| "Structured flow" metaphor + `data→AST→layout→pagination→PDF` spine | **KEEP** | 105 specimens, 107 HTML book — use as the organizing visual logic. |
| Brand essence / promise / mantra ("Render the document. Respect the system. Explain the failure.") | **KEEP** | 106 copy. |
| Positioning + "Native, not wrapped" pillars | **KEEP** | 106, 107. |
| Voice principles + tone-by-context table | **KEEP** | 106 — drop in verbatim. |
| Four-part error pattern (what/where/why/try) | **KEEP** | 106; already mirrored in README. |
| Honesty block / "What Rendro is not" / no-overclaim rule | **KEEP** | 106, 107. |
| Ink/paper/blue palette + 60/25/10/5 ratio | **KEEP** | 102 tokens (primitive layer). |
| Inter + JetBrains Mono + Noto fallback | **KEEP** | 102, 105 specimens. |
| Type scale, spacing scale, radius scale, grid widths | **KEEP** | 102, 105, 107. |
| Clearspace rule (height of `n`) + minimum sizes | **KEEP** | 103/104 logo. |
| Logo "don'ts" list | **KEEP** | 103/104. |
| Contrast pairing verdicts ("Passes normal text" etc.) | **TIGHTEN** | 102 — replace assertions with computed WCAG 2.2 ratios. |
| Raw color tokens / JSON token block | **TIGHTEN→ADD** | 102 — keep as primitives; add semantic + state + dark layer on top. |
| Callout color system | **TIGHTEN** | 102 — map to `feedback/*` semantic tokens; ensure not color-only. |
| Naming / version / org guidance (0.1, rendro-dev) | **TIGHTEN** | 106, 107 — reconcile to v1.0.0 + `szTheory/rendro`. |
| Wordmark "customized R and o is enough" | **REWORK** | 103/104 — superseded by user's integrated-typemark constraints. |
| Logo system (concepts → asset) | **REWORK→ADD** | 103/104 — produce the actual integrated typemark: no box, motif in letterforms, tight to mark, no subtitle; define favicon/mono derivations. |
| Dark-mode behavior | **ADD** | 102 — warm-neutral dark; map all semantic roles; closes C3. |
| Semantic + state tokens + focus ring | **ADD** | 102 — closes I1 and the focus-state accessibility gap. |
| Focus-visible / reduced-motion / non-color callout cues | **ADD** | 102, and note in §14 motion. |
| Social/OG card, favicon master, icon-grid spec | **ADD** | 103/104, 107 — net-new surfaces. |
| HexDocs `hex--docs-purple` badge | **TIGHTEN** | 107 — rebrand to ink/paper/blue. |
| `plum-700` as core token | **REMOVE→demote** | 102 — move to tint-only to prevent purple-creep (optional). |
| UI system (§13), Admin UI (§21), Icon set (§12) | **KEEP (labeled future)** | 105/106/107 — mark non-blocking for B1; don't over-specify now. |
| Motion timings (§14) | **KEEP** | 107 — minor; add reduced-motion. |
| CHILI / `rendro` name collision | **FLAG — HUMAN/LEGAL** | All phases — do NOT mark resolved; route to legal clearance. |

---

*End of AUDIT.md. Companion: `SCORECARD.md`.*
