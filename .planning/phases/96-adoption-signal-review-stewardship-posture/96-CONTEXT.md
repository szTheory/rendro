# Phase 96: Adoption Signal Review & Stewardship Posture - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Three independent, narrow **pure-docs** deliverables. **No code, no `mix` task, no public API/runtime surface, no engine behavior.** Each is an edit to an existing markdown file:

1. **SIGNAL-01 — Dated adoption-signal review.** Append a dated review row + short prose block to the existing `## Review Log` in `ADOPTION.md`, recording the current download / version / contributor signal against the three gate thresholds, applying the four-verdict decision rule (TRIGGER / ACCUMULATING / HOLD / HOLD-noise), reaching an explicit verdict (**HOLD** — current evidence supports it), and naming a concrete next trigger. Plus one append-only `## Download Snapshots` row anchoring the live numbers.
2. **STEW-01a — Stewardship posture in the milestone arc.** Add a dated `## Stewardship Posture (Done-Enough)` section to `.planning/MILESTONE-ARC.md` recording the ~90-93% done-enough estimate, the standing rule to prefer stewardship over deepening proof/viewer machinery, and the named non-goals as demand-gated deferrals tied to `ADOPTION.md` (not abandonment).
3. **STEW-01b — Public stewardship status in the stability guide.** Add a top `## Project Status & Stewardship` section to `guides/api_stability.md` signalling "stable and actively stewarded · feature-complete for its stated scope", a *Last reviewed* date, explicit tiered bug/security commitments, and "new capabilities are demand-gated, not abandoned" pointing to `ADOPTION.md`.

**Out of scope (held v2.8 non-goals):** global text shaping, mobile GUI viewer promotion, TOC/outlines/anchors/cross-refs, charts, existing-PDF editing, release-please automation, proactive outreach, any new `mix` task, any public API change.

</domain>

<decisions>
## Implementation Decisions

This phase, like Phases 93-95, is **largely specified by its ROADMAP.md success criteria** (SC #1-#4) — they fix the verdict, dates, section names, the ~90-93% estimate, and the api_stability.md headline. Advisor mode (`minimal_decisive`, calibration tier from `vendor_philosophy: opinionated`) surfaced exactly three genuine forks; all three were researched in parallel and **locked to the researched recommendation** at the maintainer's request (one-shot). The live HOLD evidence below was pulled during discussion and is authoritative for the review.

### Live signal evidence (pulled 2026-06-13, authoritative for the review)
- **Downloads (Hex API):** `all=877`, `week=117`. Baseline (2026-06-12) was `867` / `115` → **+10 all / +2 week**. Threshold needs `+1,500 all` and `week >= 150` on two snapshots ≥14 days apart. **Blocked.**
- **Demand:** `0` qualifying text-shaping signals; `gh issue list --label adoption:signal` and `--label area:text-shaping` both empty. **Blocked.**
- **Contributor:** `0` merged non-maintainer PRs since baseline (`gh pr list --state merged --search "merged:>=2026-06-12 -author:szTheory"` empty). **Blocked.**
- **Version:** latest stable `1.0.0`. **Verdict: HOLD on all three families.** The 45-day gate floor lands `2026-07-27`.

### SIGNAL-01 — Review content + four-verdict rule (locked from criteria + live data)
- **D-01:** **Verdict = HOLD** on all three families. The +10 all / +2 week download movement is **noise, not the threshold** (and not hype — it is plain organic, so plain `HOLD`, not `HOLD-noise`; reserve `HOLD-noise` for stars/+1/generic-i18n). The review row must explicitly state the four-verdict rule was applied (TRIGGER = all three met in one window / ACCUMULATING = movement not yet met / HOLD = no qualifying movement / HOLD-noise = only stars/+1/generic-i18n).
- **D-02 (FORK 1 — next-trigger semantics, LOCKED: event-based + floor):** The next trigger is **event-based, not a scheduled calendar reminder** — triggered by the first qualifying text-shaping issue, OR a counted non-maintainer contributor PR, OR the next milestone-planning pass, **whichever comes first**. Name `2026-07-27` (45 days after the 2026-06-12 baseline) as the **earliest-possible floor date**, explicitly *not* a commitment to review on that day. Rationale (researched): satisfies SC#2's "next earliest re-check date" + resist-neglect while honoring ADOPTION.md's locked "reviews are pull-based, not scheduled from a launch date" philosophy; a standing calendar date was **rejected** because a date you don't honor becomes a broken public promise that reads as abandonment (the dominant deprecation-calendar footgun, acute for a solo maintainer). Mirrors Go's event-gated proposal reopening + SQLite scope discipline.
  - **Suggested microcopy (Notes cell / prose):** "Re-check is pull-based, not scheduled: the next review is triggered by the first qualifying text-shaping issue, a counted contributor PR, or the next milestone-planning pass — whichever comes first. The gate cannot trigger before 2026-07-27 (45 days after the 2026-06-12 baseline); that date is the earliest-possible floor, not a calendar reminder or a commitment to review on that day."
- **D-03 (FORK 2 — record live snapshot row, LOCKED: yes):** Append **one** append-only row to the `## Download Snapshots` table (currently a placeholder), AND add the Review Log row; the two surfaces must agree (snapshot table = queryable trendline, review row = verdict). Rationale (researched): append-only ADR / audit-log / lab-notebook discipline records the data point *when you look* including no-change results; the Downloads threshold (two snapshots ≥14 days apart) is **unprovable without dated snapshot rows**, so this review is the natural moment to lay the first post-baseline data point; MILESTONE-ARC's own durable lesson ("planning artifacts can lag shipped truth") argues against inline-prose-only. Cadence-creep footgun neutralized by anti-cadence microcopy.
  - **Suggested snapshot row:** `| 2026-06-13 | 877 | 117 | Hex package API | Captured during v2.8 stewardship planning review (not scheduled telemetry). +10 all / +2 week since 2026-06-12 baseline; negligible movement, Downloads threshold still blocked. First post-baseline data point; next snapshot only when planning future work or reviewing concrete demand. |`
- **D-04:** **Replace the `## Review Log` placeholder row** ("TBD … No review run yet") with the real dated review row; keep the "Review cadence" / issue-review-command prose above the table. **Leave untouched:** the `## Gate Thresholds` table status cells (stay `Blocked` — consistent with HOLD), the `## Discovery Baseline` row, the empty `## Signal Ledger` and `## External Contributors` placeholders (still zero — no new signals to record). No new `mix` task, no public surface (SC#1).

### STEW-01a — MILESTONE-ARC.md stewardship posture (locked from criteria)
- **D-05:** Add a **new dated `## Stewardship Posture (Done-Enough)` section** to `.planning/MILESTONE-ARC.md` capturing: (a) the **~90-93% done-enough estimate** for the stated product identity (already stated in the file's Active Strategic Arc — restate in the new dated section), (b) the **standing rule**: prefer stewardship / claim hygiene / adoption-feedback work over new feature families; do **not** deepen proof/viewer machinery by default (the proof axis is at diminishing returns), (c) the **named non-goals as demand-gated deferrals tied to `ADOPTION.md`, explicitly not abandonment**: global text shaping, mobile GUI viewer promotion, TOC/outlines/anchors/cross-references, charts, existing-PDF editing, release-please automation, proactive outreach.

### STEW-01b — api_stability.md status section (locked from criteria + FORK 3)
- **D-06:** Add a **top `## Project Status & Stewardship` section** (before `## Tier-1 Stable`) to `guides/api_stability.md` with the SC#4-mandated headline **"Stable and actively stewarded · feature-complete for its stated scope."** + a **_Last reviewed: 2026-06-13_** date.
- **D-07 (FORK 3 — bug/security commitment wording, LOCKED: tiered):** Use **three tiered commitments**, not a flat "best-effort" line: (1) **Security fixes prioritized** — triaged ahead of feature/bug work, no contractual SLA, ship as patch + CHANGELOG entry; report privately via **GitHub's built-in private vulnerability reporting** (Security tab → "Report a vulnerability"), not a public issue. (2) **Bug fixes best-effort, no SLA** — reproducible Tier-1 bugs, prioritized by adopter impact / documented-contract breach; minimal failing case = fastest path; "best-effort ≠ no effort, means no guaranteed timeline." (3) **New capabilities demand-gated, not abandoned** → link `ADOPTION.md`. Rationale (researched): matches the guide's existing tiered DNA (Tier-1/Tier-2, supported/explicit_deferral) and Elixir core's own SECURITY.md tiering; for a lib shipping cryptographic signing + AES-256 protection, flattening security to the same tier as a cosmetic bug is an actively wrong signal. **No SLA numbers anywhere** (overpromise footgun); flat "best-effort, no guarantees" rejected (scares enterprise adopters, undersells the trust-sensitive surfaces).
- **D-08:** **Do NOT invent a `SECURITY.md` reference** — none exists (`SECURITY.md`, `.github/SECURITY.md` both absent), and citing a non-existent file would violate the guide's proof-backed-claims discipline. Point to GitHub private vulnerability reporting instead (zero new files). Adding a real one-paragraph `SECURITY.md` this phase is an **optional** trust-boost (not required by SC#4); if the planner elects to, switch the security bullet's reporting clause to point at it.

### Claude's Discretion (planner / executor)
- Exact prose wording within the locked structure for all three files (the research agents supplied drop-in microcopy in `96-DISCUSSION-LOG.md` and the canonical refs below — use as the strong default).
- **MILESTONE-ARC.md staleness observation (NOT scope expansion):** the file's `## Active Milestone → None` and `## Next Recommendation → v2.8 recommended next milestone` lines are now stale (v2.8 is **active**; Phases 93-95 complete). SC#3 only requires *adding* the posture section. The planner **may** optionally reconcile those two adjacent lines for internal consistency (the file's own durable lesson warns the arc lags shipped truth) — but it is not required by the criterion and must not balloon into broader arc rewriting.
- `ADOPTION.md` link path from `guides/api_stability.md`: verify how other `guides/*.md` cross-link in published HexDocs (`../ADOPTION.md` vs a HexDocs extra slug) before committing the link form.
- Whether a docs-contract test should assert the `Last reviewed:` line exists (consistent with repo docs-contract DNA) — a test concern, optional, not a wording decision.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase definition (authoritative HOW)
- `.planning/ROADMAP.md` (Phase 96 block, lines ~118-130) — the four success criteria; they fix the verdict, dates, section names, the ~90-93% estimate, and the api_stability.md headline.
- `.planning/REQUIREMENTS.md` — SIGNAL-01 (dated adoption-signal review + recommendation), STEW-01 (maintainer done-enough posture + named non-goals).

### SIGNAL-01 — the file to edit + the gate it reviews
- `ADOPTION.md` — the full gate doc. Edit targets: `## Review Log` (table at ~lines 106-108 — replace placeholder row), `## Download Snapshots` (table at ~lines 57-59 — replace placeholder row with the D-03 snapshot). Leave `## Gate Thresholds`, `## Discovery Baseline`, `## Signal Ledger`, `## External Contributors` untouched (still zero / still Blocked). Counting rules (~lines 23-29) define what does NOT qualify (stars/+1/generic i18n) — feeds the HOLD-noise vs HOLD distinction.

### STEW-01 — the two files to edit
- `.planning/MILESTONE-ARC.md` — add `## Stewardship Posture (Done-Enough)`. Source material already in-file: "Active Strategic Arc" (90-93% estimate, prefer-stewardship ordering), "Durable Lessons" (proof axis at diminishing returns; adoption is pull-based; arc lags shipped truth), "Next Candidates" (the named demand-gated deferrals + their reasons).
- `guides/api_stability.md` — add top `## Project Status & Stewardship` (before `## Tier-1 Stable`). Match the guide's declarative, scoped, proof-backed, boundary-explicit voice; coherent with its Tier-1/Tier-2 SemVer contract.

### Project vision / posture (already-in-repo research grounding the recommendations)
- `.planning/PROJECT.md` — v2.8 goal ("reduce friction, keep posture truthful, don't widen scope"), explicit non-goals, demand-gated future candidates.
- `prompts/rendro-oss-dna.md`, `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — OSS posture/values, ecosystem positioning.
- `.planning/research/JTBD-USER-FLOWS.md` — the evaluator persona (Phoenix SaaS engineer deciding "is this stable, alive, safe to depend on?") that all three doc edits are written for.

### Ecosystem exemplars cited by the research (for wording fidelity)
- Go proposal process (event-gated reopening, not calendar dates) — next-trigger model.
- SQLite LTS / scope discipline + Elixir core `SECURITY.md` (tiered bug-vs-security commitments, private disclosure) — status + security wording model.
- Append-only ADR / audit-log / lab-notebook discipline — snapshot-row recording model.

### Contracts that must stay green
- No code, no `mix` task, no `priv/public_api.json` change, no engine behavior — this phase touches only `ADOPTION.md`, `.planning/MILESTONE-ARC.md`, and `guides/api_stability.md`. If a docs-contract lane parses `guides/api_stability.md`, the new section must not break it.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`ADOPTION.md` existing tables** — `## Review Log` and `## Download Snapshots` already have headers + placeholder rows; the edit is a row replacement, not new infra. The `curl … | jq '.downloads'` snapshot command is already documented in-file (use it verbatim as the source).
- **`guides/api_stability.md` tiered structure** — the new status section rhymes with the existing Tier-1/Tier-2 + NOT-covered-by-SemVer tiering; the tiered (security/bugs/features) commitment wording is the consistent choice, not the odd one out.
- **`.planning/MILESTONE-ARC.md` Active Strategic Arc + Durable Lessons** — already contain the 90-93% estimate, the prefer-stewardship rule, and the named deferrals with reasons; the new section restates them in a dated, posture-anchored form.

### Established Patterns
- **Proof-backed claims / no overclaiming** — every public claim must be truthful and bounded (PROJECT.md culture). Drives: no invented SECURITY.md (D-08), no SLA numbers (D-07), HOLD not overstated as ACCUMULATING (D-01).
- **Pull-based, no manufactured cadence** (v2.6 deliberate choice) — drives the event-based-not-scheduled next-trigger (D-02) and the anti-cadence snapshot framing (D-03).
- **Append-only evidence ledgers** — record the data point when you look, including no-change results (D-03).

### Integration Points
- Three markdown files only; no code, CI, or contract impact beyond a possible docs-contract parse of `guides/api_stability.md`. No new files required (SECURITY.md optional, deferred to planner discretion).

</code_context>

<specifics>
## Specific Ideas

- **Review row Notes microcopy (D-01/D-02):** "HOLD (all three families). Decision rule applied: TRIGGER / ACCUMULATING / HOLD / HOLD-noise. Downloads 867→877 all, 115→117 week since baseline: noise, not the +1,500 / ≥150 thresholds. Zero qualifying shaping signals; zero non-maintainer PRs. Re-check is pull-based, not scheduled: next review triggered by the first qualifying text-shaping issue, a counted contributor PR, or the next milestone-planning pass — whichever comes first. Gate cannot trigger before 2026-07-27 (earliest-possible floor, not a reminder)."
- **api_stability.md status section** — full drop-in prose block supplied by the research agent (see `96-DISCUSSION-LOG.md`): headline + 3 tiered bullets (security prioritized / bugs best-effort / capabilities demand-gated), GitHub private vuln reporting, no SLA numbers.
- **Snapshot row** — exact content in D-03.

</specifics>

<deferred>
## Deferred Ideas

- **Optional `SECURITY.md`** — adding a one-paragraph repo `SECURITY.md` would be a low-cost, high-trust boost for a signing/encryption lib, but it is NOT required by SC#4 and the locked wording is self-consistent without it. Planner may elect to add it within this phase; otherwise it is a future stewardship nicety. (Do not let it expand the phase.)
- **MILESTONE-ARC.md stale `Active Milestone`/`Next Recommendation` lines** — flagged in Claude's Discretion (D, above) as an optional adjacent reconcile, not new scope.
- **Docs-contract test for the `Last reviewed:` line** — optional future hygiene, consistent with repo DNA; not required by the criteria.

</deferred>

---

*Phase: 96-Adoption Signal Review & Stewardship Posture*
*Context gathered: 2026-06-13*
