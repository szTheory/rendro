<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** **Verdict = HOLD** on all three families. The +10 all / +2 week download movement is **noise, not the threshold**.
- **D-02:** The next trigger is **event-based, not a scheduled calendar reminder**. Name `2026-07-27` as the **earliest-possible floor date**.
- **D-03:** Append **one** append-only row to the `## Download Snapshots` table.
- **D-04:** **Replace the `## Review Log` placeholder row** with the real dated review row; keep the "Review cadence" / issue-review-command prose above the table. **Leave untouched** the other tables.
- **D-05:** Add a **new dated `## Stewardship Posture (Done-Enough)` section** to `.planning/MILESTONE-ARC.md` capturing: (a) ~90-93% done-enough estimate, (b) the standing rule to prefer stewardship over deepening proof/viewer machinery, (c) the named non-goals as demand-gated deferrals tied to `ADOPTION.md`.
- **D-06:** Add a **top `## Project Status & Stewardship` section** (before `## Tier-1 Stable`) to `guides/api_stability.md` with headline **"Stable and actively stewarded · feature-complete for its stated scope."** + a **_Last reviewed: 2026-06-13_** date.
- **D-07:** Use **three tiered commitments**: (1) Security fixes prioritized (private reporting), (2) Bug fixes best-effort, no SLA, (3) New capabilities demand-gated, not abandoned.
- **D-08:** **Do NOT invent a `SECURITY.md` reference**. Point to GitHub private vulnerability reporting instead.

### the agent's Discretion
- Exact prose wording within the locked structure for all three files.
- **MILESTONE-ARC.md staleness observation:** The planner **may** optionally reconcile the stale `Active Milestone` and `Next Recommendation` lines for internal consistency, but it is not required.
- `ADOPTION.md` link path from `guides/api_stability.md`: verify how other `guides/*.md` cross-link. (Verified: `../ADOPTION.md` is the correct path).
- Whether a docs-contract test should assert the `Last reviewed:` line exists.

### Deferred Ideas (OUT OF SCOPE)
- **Optional `SECURITY.md`** — adding a one-paragraph repo `SECURITY.md` would be a low-cost, high-trust boost, but is NOT required.
- **MILESTONE-ARC.md stale `Active Milestone`/`Next Recommendation` lines** — optional adjacent reconcile.
- **Docs-contract test for the `Last reviewed:` line** — optional future hygiene.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGNAL-01 | Dated adoption-signal review in ADOPTION.md | Canonical review wording and snapshot row formats provided below. |
| STEW-01 | Maintainer done-enough posture & status updates in MILESTONE-ARC.md and api_stability.md | Exact section headers, tiered security/bug commitments, and cross-linking paths defined. |
</phase_requirements>

# Phase 96: Adoption Signal Review & Stewardship Posture - Research

**Researched:** 2026-06-13
**Domain:** Documentation, Open Source Governance, Stewardship Strategy
**Confidence:** HIGH

## Summary

Phase 96 is a pure-documentation stewardship update representing the end of the v2.8 "Done-Enough" milestone loop. It solidifies Rendro's posture as stable, actively stewarded, and feature-complete for its stated scope, explicitly pausing feature growth in favor of demand-gated deferrals. 

**Primary recommendation:** Apply the locked prose edits verbatim to `ADOPTION.md`, `.planning/MILESTONE-ARC.md`, and `guides/api_stability.md` using the exact microcopy defined in this research to honor the project's strict proof-backed and anti-cadence commitments.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stewardship Posture | Documentation (`MILESTONE-ARC.md`) | `guides/api_stability.md` | Posture decisions live in planning state, with public status surfaced in user guides. |
| Adoption Signal Tracking | Documentation (`ADOPTION.md`) | — | Dedicated append-only log prevents demand-gating from getting lost in issue trackers. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / ExDoc | N/A (Docs) | HexDocs generation | This phase operates purely on markdown text processed by ExDoc. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| N/A | N/A | N/A | No additional dependencies. |

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages. Run the Package Legitimacy Gate protocol before completing this section.

*No packages are introduced or modified in this phase.*

## Architecture Patterns

### Recommended Project Structure
This phase mutates existing planning and guide files, adhering to the established layout:
```
.planning/
├── MILESTONE-ARC.md      # Receives internal stewardship posture section
ADOPTION.md               # Receives new review log and snapshot rows
guides/
└── api_stability.md      # Receives top-level public status section
```

### Pattern 1: Event-Gated Reopening
**What:** Reviews are triggered by concrete demand or milestone events, not calendar dates.
**When to use:** Managing roadmap expansion for solo-maintained open-source projects.
**Example:**
```markdown
Re-check is pull-based, not scheduled: the next review is triggered by the first qualifying text-shaping issue, a counted contributor PR, or the next milestone-planning pass — whichever comes first.
```

### Pattern 2: Append-Only Snapshot Logging
**What:** Data observations are appended in tables even if they don't meet thresholds.
**When to use:** To prove thresholds requiring multiple snapshots (like "1,500 downloads over 14 days").
**Example:** Adding the `2026-06-13` row to `## Download Snapshots`.

### Anti-Patterns to Avoid
- **Cadence Creep:** Setting calendar reminders for reviews. (Instead: explicitly state dates are a floor, not a reminder).
- **Overpromising SLAs:** Offering fixed turnaround times for open-source bug fixes. (Instead: "Best-effort, no SLA").
- **Inventing Unbacked Claims:** Referencing a `SECURITY.md` file that doesn't exist.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Vulnerability Reporting | A custom `SECURITY.md` email address (if not required) | GitHub's built-in private vulnerability reporting | Standardized UI for external researchers; already exists. |
| Link Resolution | Absolute URLs to `ADOPTION.md` | `../ADOPTION.md` relative links | ExDoc resolves these natively when flattening guides in HexDocs. |

## Common Pitfalls

### Pitfall 1: Breaking HexDocs Generation
**What goes wrong:** Adding bad links or syntactically invalid markdown breaks `mix docs`.
**Why it happens:** Misunderstanding ExDoc's flat structure for `guides/` vs root files.
**How to avoid:** Use `../ADOPTION.md` within `guides/api_stability.md`.
**Warning signs:** CI fails on the docs-contract verification step.

## Code Examples

Verified patterns from official sources:

### `ADOPTION.md` Update Wording
```markdown
| Date | Reviewer | Demand | Downloads | Contributor | Decision | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-06-13 | Maintainer (v2.8 planning) | 0 | 877 all / 117 wk | 0 | HOLD | HOLD (all three families). Decision rule applied: TRIGGER / ACCUMULATING / HOLD / HOLD-noise. Downloads 867→877 all, 115→117 week since baseline: noise, not the +1,500 / >=150 thresholds. Zero qualifying shaping signals; zero non-maintainer PRs. Re-check is pull-based, not scheduled: next review triggered by the first qualifying text-shaping issue, a counted contributor PR, or the next milestone-planning pass — whichever comes first. Gate cannot trigger before 2026-07-27 (earliest-possible floor, not a reminder). |
```

### `ADOPTION.md` Snapshot Row Wording
```markdown
| 2026-06-13 | 877 | 117 | Hex package API | Captured during v2.8 stewardship planning review (not scheduled telemetry). +10 all / +2 week since 2026-06-12 baseline; negligible movement, Downloads threshold still blocked. First post-baseline data point; next snapshot only when planning future work or reviewing concrete demand. |
```

### `api_stability.md` Section Wording
```markdown
## Project Status & Stewardship

**Stable and actively stewarded · feature-complete for its stated scope.**  
*Last reviewed: 2026-06-13*

- **Security fixes prioritized:** Triaged ahead of feature/bug work, no contractual SLA, shipped as a patch with a CHANGELOG entry. Report privately via GitHub's built-in private vulnerability reporting (Security tab → "Report a vulnerability").
- **Bug fixes best-effort, no SLA:** Reproducible Tier-1 bugs are prioritized by adopter impact or documented-contract breach. A minimal failing case is the fastest path to a fix. "Best-effort" means no guaranteed timeline.
- **New capabilities demand-gated, not abandoned:** Future capabilities are deferred to the [ADOPTION.md](../ADOPTION.md) demand gate rather than being closed as won't-fix.
```

### `.planning/MILESTONE-ARC.md` Stewardship Posture Wording
```markdown
## Stewardship Posture (Done-Enough)

*Date recorded: 2026-06-13*

Rendro is considered ~90-93% feature-complete for its stated product identity. 

**Standing Rule:** Prefer stewardship, claim hygiene, and adoption-feedback work over new feature families. Do not deepen proof or viewer machinery by default, as the proof axis is at diminishing returns.

**Demand-Gated Deferrals:** The following named non-goals are demand-gated, tied to `ADOPTION.md`, and are explicitly *not* abandonment:
- Global text shaping
- Mobile GUI viewer promotion
- TOC / outlines / anchors / cross-references
- Charts
- Existing-PDF editing
- Release-please automation
- Proactive outreach
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Scheduled Reviews | Event-gated triggers | 2026-06 | Prevents "cadence creep" and empty maintenance chores. |
| Feature factories | "Done-enough" stewardship | v2.8 | Signals maturity to enterprise adopters and avoids feature bloat. |

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
|   | No assumptions were made. All recommendations stem from locked decisions in `CONTEXT.md` | - | - |

## Open Questions (RESOLVED)

None. All decision forks (trigger semantics, snapshot rows, bug/security commitments) were resolved via `CONTEXT.md`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/docs_contract` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STEW-01 | (Optional) Verify `Last reviewed:` line exists | unit | `mix test test/docs_contract` | ❌ Wave 0 (Discretionary) |

### Sampling Rate
- **Per task commit:** `mix test` (docs compile check)
- **Per wave merge:** `mix ci`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- (Optional) A docs-contract test could be implemented to assert the presence of `Last reviewed:` in `api_stability.md`. This is at the planner's discretion based on `CONTEXT.md`.

## Security Domain

### Applicable ASVS Categories

*As a pure documentation phase, standard application security verifications (V2-V6) do not apply. However, this phase establishes the project's security response posture.*

| Posture Category | Standard Control |
|------------------|------------------|
| Vulnerability Reporting | Point users to GitHub's built-in private vulnerability reporting. Do not invent a `SECURITY.md` unless fully implemented. |
| Triage Priority | Security patches are triaged ahead of standard feature/bug work. |

### Known Threat Patterns for Open Source Stewardship

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overpromising SLAs | Information Disclosure / Repudiation | Flatly state "no guaranteed timeline" and "best-effort". |
| False Trust Signals | Tampering | Do not link non-existent security policies. Ensure all claims are backed by reality. |

## Sources

### Primary (HIGH confidence)
- `96-CONTEXT.md` - Source of all locked decisions and microcopy.
- `mix.exs` - Verified `extras:` configuration proving `ADOPTION.md` is compiled by ExDoc, justifying the `../ADOPTION.md` relative link.
- `.planning/MILESTONE-ARC.md` - Verified current layout to position the new sections.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Pure markdown.
- Architecture: HIGH - Defined by locked CONTEXT.
- Pitfalls: HIGH - ExDoc linking is a known constraint.

**Research date:** 2026-06-13
**Valid until:** End of v2.8 milestone planning.
