# ROADMAP — B1 Brand System & Identity Lab

> Non-semver brand milestone. Brand collateral only — **no library/`lib/` changes, no Hex release.**
> Phases continue the repo's global sequential numbering (101–107) even though the milestone label is `B1`.
> Self-contained in `brand/`. Strict anti-bloat: SVG/JSON/CSS/MD/HTML only, no font/raster binaries.

## Phases

- [x] **Phase 101: Brand Audit & DNA Pressure-Test** — Critically audit `prompts/Rendro Brand Book.txt` against a 14-section framework; emit KEEP/TIGHTEN/REWORK/ADD/REMOVE rulings that steer all downstream phases.
- [x] **Phase 102: Design Tokens** — Canonical `tokens.json` (raw + semantic + type/spacing/radius/state, light+dark) with a `mix brand.gen` generator emitting `tokens.css` + `tailwind.tokens.js`.
- [x] **Phase 103: Logo Lab (Options + Selection Gate)** — directions explored; user selected Frame-R → title-case "Rendro", stencil "endro", seam-in-R.
- [x] **Phase 104: Logo System Finalization** — primary/mark/mono/subtitle/favicon/social-avatar + usage sheet, all self-theming and render-verified.
- [x] **Phase 105: Visual Specimens** — palette, typography, components, code-block, README-header mock, social card (SVG).
- [x] **Phase 106: Voice, Microcopy & Marketing Copy** — refined `VOICE.md` + `marketing-copy.md`.
- [x] **Phase 107: HTML Brand Book Assembly, QA Gate & Repo Integration** — self-contained `brand/index.html`, README links, `.gitignore` rules, anti-bloat gate.

**Milestone B1 complete — 2026-06-14. `brand/` = 280K, text-only, excluded from the Hex package.**

## Phase Details

### Phase 101: Brand Audit & DNA Pressure-Test
**Goal**: An evidence-backed audit produces explicit disposition rulings for every downstream artifact.
**Depends on**: Nothing (source of truth for all downstream phases)
**Requirements**: AUD-01, AUD-02, AUD-03, AUD-04, AUD-05
**Success Criteria**:
  1. `AUDIT.md` covers all 14 framework sections with candid, non-flattering judgment.
  2. `SCORECARD.md` scores 15 dimensions (1–10) with why/risk/fix each.
  3. A ≥25-surface stress test matrix records pass/gap per real surface.
  4. A consolidated KEEP/TIGHTEN/REWORK/ADD/REMOVE table names what each later phase must honor.
  5. The CHILI / `rendro` name-collision trademark risk is surfaced as a flagged ruling for human review.
**Artifacts**: `brand/audit/AUDIT.md`, `brand/audit/SCORECARD.md`

### Phase 102: Design Tokens
**Goal**: A buildable token system, single-source-of-truth in JSON, generating CSS + Tailwind.
**Depends on**: Phase 101
**Requirements**: TOK-01, TOK-02, TOK-03, TOK-04
**Success Criteria**:
  1. `tokens.json` defines raw scale + semantic roles; every semantic role resolves to a raw value in light AND dark.
  2. Type scale, spacing scale, radii, and interaction-state tokens form a closed set (no orphan references).
  3. `mix brand.gen` emits `tokens.css` + `tailwind.tokens.js`; CSS custom properties match JSON keys 1:1.
  4. WCAG AA contrast noted for documented text/background pairings.
**Artifacts**: `brand/tokens/tokens.json`, `brand/tokens/tokens.css`, `brand/tokens/tailwind.tokens.js`, `lib/mix/tasks/brand.gen.ex`

### Phase 103: Logo Lab (Options + Selection Gate)
**Goal**: Present multiple constraint-compliant logo directions and capture a recorded selection.
**Depends on**: Phase 101, Phase 102
**Requirements**: LOGO-01, LOGO-02, LOGO-03
**Success Criteria**:
  1. 4–5 editable SVG directions exist, each: no background box, motif worked into letterforms, logotype tight to mark, main combo has no subtitle.
  2. Each direction renders at mark / full-lockup / favicon scale, light and dark.
  3. `logo-lab.html` shows all directions on mock surfaces (GitHub header, README hero, favicon @16px, social avatar).
  4. A recorded selection (decision) captures the chosen direction + tweak notes before Phase 104 starts.
**Artifacts**: `brand/logo/options/option-*.svg`, `brand/logo/lab/logo-lab.html`
**GATE**: Terminal slice calls AskUserQuestion; no advance to 104 until a selection is recorded.

### Phase 104: Logo System Finalization
**Goal**: The chosen direction becomes a full production lockup system.
**Depends on**: Phase 103 + recorded selection
**Requirements**: LOGO-04, LOGO-05, LOGO-06, LOGO-07
**Success Criteria**:
  1. Primary, mark-only, wordmark, and 1-color monochrome share consistent geometry.
  2. Dark/light variants + favicon (legible @16px) + social avatar (legible cropped to circle) exist.
  3. A with-subtitle variant exists (separate from the main no-subtitle combo).
  4. `brand/logo/README.md` documents clear space, min sizes, do/don't, color pairings keyed to tokens.
**Artifacts**: `brand/logo/rendro-*.svg`, `brand/logo/favicon.svg`, `brand/logo/social-avatar.svg`, `brand/logo/README.md`

### Phase 105: Visual Specimens
**Goal**: Self-contained SVG specimens demonstrating the system in use.
**Depends on**: Phase 102, Phase 104
**Requirements**: SPEC-01, SPEC-02, SPEC-03, SPEC-04, SPEC-05
**Success Criteria**:
  1. Palette specimen shows every raw + semantic token (light/dark).
  2. Typography specimen shows the full scale; component/code-block/callout specimens show TOK states.
  3. README-header mock and 1200×630 social card reuse the finalized logo + tokens.
**Artifacts**: `brand/specimens/*.svg`

### Phase 106: Voice, Microcopy & Marketing Copy
**Goal**: Refined voice guidelines + reusable marketing copy blocks, governed by the audit.
**Depends on**: Phase 101 (runs in parallel with 102–105)
**Requirements**: COPY-01, COPY-02, COPY-03, COPY-04
**Success Criteria**:
  1. `VOICE.md` defines principles, tone-by-context, vocabulary do/don't, and before/after examples.
  2. Microcopy patterns cover error/empty/success consistent with the "Explain the failure" mantra.
  3. `marketing-copy.md` provides taglines, short/long descriptions, README intro, hero, CTAs (primary + alternates), length-fit to target surfaces.
**Artifacts**: `brand/copy/VOICE.md`, `brand/copy/marketing-copy.md`

### Phase 107: HTML Brand Book Assembly, QA Gate & Repo Integration
**Goal**: Assemble the self-contained HTML brand book, pass the quality gate, integrate with zero bloat.
**Depends on**: Phase 102, 104, 105, 106
**Requirements**: BOOK-01, BOOK-02, BOOK-03, QA-01, QA-02, QA-03
**Success Criteria**:
  1. `brand/index.html` opens offline with no external fetches and covers all work areas.
  2. Light/dark both correct; all internal links resolve; final logo is constraint-compliant.
  3. `.gitignore` excludes binaries under `brand/`; `brand/` absent from `mix.exs` `package.files`; `mix hex.build` tarball excludes `brand/`.
  4. `du -sh brand/` under budget (≤ ~400 KB target).
**Artifacts**: `brand/index.html`, `brand/README.md`, root `README.md` (links), `.gitignore`

## Progress

| Phase | Artifacts Complete | Status | Completed |
|-------|--------------------|--------|-----------|
| 101. Brand Audit & DNA Pressure-Test | 2/2 | Complete | 2026-06-14 |
| 102. Design Tokens | 4/4 | Complete | 2026-06-14 |
| 103. Logo Lab (Options + Gate) | 2/2 | Complete (Frame-R selected) | 2026-06-14 |
| 104. Logo System Finalization | 4/4 | Complete | 2026-06-14 |
| 105. Visual Specimens | 6/6 | Complete | 2026-06-14 |
| 106. Voice & Marketing Copy | 2/2 | Complete | 2026-06-14 |
| 107. HTML Brand Book + QA | 4/4 | Complete | 2026-06-14 |
