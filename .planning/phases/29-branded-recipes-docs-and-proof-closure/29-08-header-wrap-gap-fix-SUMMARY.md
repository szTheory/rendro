---
phase: 29-branded-recipes-docs-and-proof-closure
plan: 8
subsystem: branded-recipe / page-template-geometry
status: escalated
tags: [gap-closure, branded-invoice, header-wrap, escalation, contingency-triggered]
requirements: [LAY-13]
gap_closure: true
contingency_triggered: true
dependency_graph:
  requires: [29-03, 29-04, 29-07]
  provides: []
  affects: [LAY-13]
tech_stack:
  added: []
  patterns: []
key_files:
  created:
    - .planning/phases/29-branded-recipes-docs-and-proof-closure/29-08-header-wrap-gap-fix-SUMMARY.md
  modified: []
decisions:
  - "Probe-measured B612 Regular @ 18pt: 'Invoice #INV-2026-001' = 423.0pt; 'Invoice #INV-2026-042' = 423.0pt — well above the plan's 371pt hard ceiling and above the maximum widenable region width given current page geometry (max 371.28pt at x=152 on A4 with 72pt right margin)."
  - "Plan's Task 1 contingency clause triggered (measured > 371). Per the clause: 'STOP and surface this as a gap-closure escalation in the executor summary.' Executor STOPPED before Task 2 because the contingency's authorized remedy (widening the :header region) cannot resolve the defect within page-geometry constraints; all alternative remedies (stacked blocks, font reduction, break_inside_word: false) are explicitly enumerated in the plan's 'Out of Scope' section."
metrics:
  duration: ~5 minutes
  tasks_completed: 1
  tasks_total: 3
  files_changed: 0
  completed_date: "2026-05-02"
---

# Phase 29 Plan 8: Header-Wrap Gap Fix Summary

**One-liner:** Probe measured B612 Regular @ size 18 widths far above the plan's hard ceiling (423.0pt vs 371pt); contingency clause triggered and execution stopped before Task 2 because no in-scope remedy can fit the canonical UAT string in the existing header region.

## Status: ESCALATED — contingency could not be resolved in scope

The plan's Task 1 contingency clause triggered, and the contingency's own authorized remedy (widen the `:header` region) is mathematically incapable of resolving the defect on the current page geometry without violating constraints the plan explicitly forbids. Per the plan's directive ("STOP and surface this as a gap-closure escalation in the executor summary"), the executor stopped after Task 1, did not modify any source files, and produced this SUMMARY.

## Task Outcomes

### Task 1 — Probe B612 metrics — DONE (no source diff, no commit per plan)

Ran the probe via `mix run -e '...'` against the recipe document so `Rendro.Pipeline.Build.run/1` accepted it and the embedded `:brand_heading` font resolved through `Rendro.FontRegistry.resolve_pdf_font_chain/3`.

**Probe results (B612 Regular @ size 18, via `Rendro.PDF.Font.text_width/3`):**

| String | Measured Width (pt) |
|---|---|
| `Rendro, Inc.` | 205.20 |
| `Invoice #INV-2026-001` | **423.00** |
| `Invoice #INV-2026-042` | **423.00** |
| `Invoice #INV-9999-9999` | 446.40 |

The two canonical UAT strings (`INV-2026-001` from `29-branded-preview.png`, `INV-2026-042` from `branded_invoice_test.exs` sample data) both measure **423.00pt** — `52.0pt over` the plan's 371pt hard ceiling, and `163.0pt over` the current `width: 260` block.

**Verify command from plan reproduced:**
```
$ mix run -e '... PROBE_WIDTH=#{Float.round(w, 2)} ...'
PROBE_WIDTH=423.0
```
Matches the plan's regex `^PROBE_WIDTH=[0-9]+\.[0-9]+$`.

**Width selection arithmetic that the plan asked for:**
- `measured_max = 423.0` (both `INV-2026-001` and `INV-2026-042`)
- `+ 4pt safety margin = 427.0`
- `chosen integer = 427`
- **`427 > 371` → HARD CEILING VIOLATED → contingency triggered.**

### Task 2 — Apply the fix — NOT EXECUTED

Skipped because Task 1 contingency triggered. Per the plan's contingency clause:

> If the measured width of either string is `> 371` (the region ceiling): STOP and surface this as a gap-closure escalation in the executor summary. The recipe-only fix is no longer sufficient; widening the region is now in scope and Task 2 must also patch the `:header` region `width:` in `page_template/1`.

The plan authorizes widening the `:header` region in this case, but the page geometry forbids it from being widened enough to fit 423pt at the current `x: 152`:

**Page-geometry analysis (from `lib/rendro/page_template.ex` defaults — A4):**
- Page width: `595.28pt`
- Right margin: `72pt`
- Right edge of usable area: `595.28 - 72 = 523.28pt`
- Header region origin: `x: 152` (immediately to the right of the logo column at `x: 72, width: 64`, so the logo column ends at `x = 136` and the header starts with 16pt of breathing room).
- Maximum widenable header region width at `x: 152`: `523.28 - 152 = 371.28pt` — the plan's "hard ceiling" was correctly derived from this same right edge.

**To fit 427pt at `x: 152`, the region's right edge would need to be at `152 + 427 = 579pt`, which is `55.72pt past the page's 523.28 usable right edge` and only `16.28pt short of the page width itself`** — i.e., the text would render past the right margin (visual defect) or off the page (clipped).

**Other ways to fit 427pt — all out of scope per the plan:**

| Option | Effect | Why Out of Scope |
|---|---|---|
| (A) Move header region to `x: 72`, `width: 451.28` (full body span, overlaps logo column) | Fits 427pt with 24pt headroom; header text would render *over* the logo region. | Logo render is currently broken (UAT Gap 1, deferred to Phase 30). Once Phase 30 lands the PNG-stream fix, the header text would visibly clash with the logo. |
| (B) Stack title + id into two `Rendro.block`s so the id sizes itself | Fits any id length; no width math needed. | Plan's "Out of Scope" explicitly forbids: "Splitting title and id into two stacked `Rendro.block` fragments (alternative UAT mentions but doesn't recommend)." |
| (C) Reduce text size below 18 | Linear scaling: at size 14, the string measures `423 * 14 / 18 = 329pt` — fits at current region. | Plan's `must_haves.truths` lock the size at 18 ("B612 Regular at size 18"). |
| (D) Add `break_inside_word: false` to `Rendro.Text` so wrapping prefers safer break points | Doesn't help — the `#INV-2026-001` token has no whitespace breakpoints to use; `split_graphemes` would still fire on a single token wider than the block. | Plan's "Out of Scope" explicitly forbids: "UAT explicitly rejects this scope for the gap fix." |
| (E) Widen the page or shrink the right margin in the recipe's `page_template/1` | Could buy up to ~50pt of additional region width. | Out of scope: page geometry change is not enumerated in `files_modified` and is a much wider architectural change than the gap-closure mandate. |

### Task 3 — Verify end-to-end — NOT EXECUTED

Skipped because Task 2 did not run.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] `mix deps.get` required before probe**
- **Found during:** Task 1 (initial `mix run -e ...` invocation)
- **Issue:** Worktree did not have dependencies fetched (`stream_data`, `oban`, `req`, `ex_doc`, `telemetry`, `phoenix`, `dialyxir`, `credo`, `plug` all missing).
- **Fix:** Ran `mix deps.get`, then re-ran the probe successfully.
- **Files modified:** None (no `mix.lock` change committed; deps fetch is environment setup).
- **Commit:** None (env setup, no diff).

### Escalations

**1. [Rule 4 — Architectural] Plan contingency triggered; in-scope remedies cannot resolve.**
- **Found during:** Task 1 (probe).
- **Issue:** Measured B612 Regular @ size 18 widths (423.0pt for both canonical UAT id strings) exceed both the plan's stated 371pt hard ceiling and the maximum widenable region width on A4 with current geometry. The plan's contingency authorized widening the `:header` region but did not anticipate that the measured width would exceed the maximum geometrically achievable region width at `x: 152`.
- **Per plan directive:** "STOP and surface this as a gap-closure escalation in the executor summary." → executor stopped and produced this SUMMARY.
- **Recommended next steps for the orchestrator/user (decision required, none authorized by this plan):**
  1. **Bump font size down (e.g., 14pt)** — minimum diff, recipe-only, but contradicts plan `must_haves.truths` ("B612 Regular at size 18"). Requires an amended plan or a plan-truth waiver.
  2. **Stack title and id into two blocks** — explicitly out of scope for this gap fix per the plan's "Out of Scope". Requires a new plan that lifts that exclusion.
  3. **Widen header region to overlap logo column** (`x: 72`, `width: 451.28`) — visually OK today (logo not rendering), but creates a Phase 30 collision once the PNG render fix lands. Requires coordinating with Phase 30's logo-render plan.
  4. **Replace the canonical id format** (e.g., `#2026-001` instead of `#INV-2026-001`) — would shrink the string below 371pt but breaks the documented invoice-id contract.
  5. **Defer the gap to Phase 30** alongside the logo fix and re-plan both together with revised `Out of Scope` boundaries.

The plan author's predicted measurement range was "~290–330pt" — actual is 423pt, ~30% higher than the upper end of the predicted range. The recipe-only fix scope was undersized for the real B612 metrics.

## Acceptance Criteria Status

| # | Criterion | Status |
|---|---|---|
| 1 | `branded_invoice.ex` line ~123 has `width: {chosen}` justified by measured metrics + comment | **Not met** — Task 2 skipped due to contingency. |
| 2 | `branded_invoice_test.exs` no longer asserts `length(tl(lines)) > 1` | **Not met** — Task 2 skipped. |
| 3 | `mix test` passes at Phase 29 baseline | Not run — no source changes to verify. |
| 4 | Header renders exactly `["Rendro, Inc.", "Invoice #INV-2026-{id}"]` | **Not met** — defect remains. |
| 5 | No edits outside the two files in `files_modified` (no `lib/rendro/pdf/writer.ex`, no `:header` region change unless Task 1 contingency fired) | **Held** — no edits made. |
| 6 | `29-HUMAN-UAT.md` Gap 1 (logo) remains `status: deferred` | **Held** — `29-HUMAN-UAT.md` was not modified. |

## Authentication Gates

None encountered.

## Self-Check: PASSED

**Files claimed created:**
- `.planning/phases/29-branded-recipes-docs-and-proof-closure/29-08-header-wrap-gap-fix-SUMMARY.md` — written, will be committed in this run.

**Files claimed modified:** none.

**Commits claimed:** none for source (Task 1 had no diff; Task 2/3 skipped). Final SUMMARY commit will be created at end of executor run.

**Key claims verified:**
- Probe output `PROBE_WIDTH=423.0` reproduced via `mix run -e ...` (matches plan's regex `^PROBE_WIDTH=[0-9]+\.[0-9]+$`).
- Page geometry constants verified by reading `lib/rendro/page_template.ex` (`@default_width 595.28`, `@default_margin 72`).
- Header region constants verified by reading `lib/rendro/recipes/branded_invoice.ex:53` (`x: 152, width: 371.28`).
- Plan's hard ceiling (371) verified consistent with the geometry math (`595.28 - 72 - 152 = 371.28`).

## Note for the Orchestrator

The Phase 29 directory in the parent repo (`/Users/jon/projects/rendro/.planning/phases/29-branded-recipes-docs-and-proof-closure/`) holds many phase artifacts (CONTEXT, RESEARCH, REVIEW, VALIDATION, VERIFICATION, HUMAN-UAT, branded preview PNG, plans 29-01 through 29-07 and their SUMMARYs, and the 29-08 PLAN itself) that are **not git-tracked**. This worktree only carries the 29-08 PLAN and this SUMMARY (both fresh in the worktree, both will be committed). The orchestrator should preserve the parent-repo Phase 29 artifacts when merging this worktree back.

## Threat Flags

None. No new security-relevant surface introduced (no edits made).
