# Phase 88: Launch Execution & Demand Instrumentation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-12
**Phase:** 88-Launch Execution & Demand Instrumentation
**Areas discussed:** Launch choreography, Demand-thread posture, Mobile viewer evidence beat, Adoption gate and routing

---

## Launch Choreography

| Option | Description | Selected |
|--------|-------------|----------|
| Elixir-first proof hub | ElixirForum `News > Announcing` thread first, then ElixirStatus, awesome-elixir PR, tailored demand-thread replies, mobile evidence follow-up, optional Show HN after local feedback. | ✓ |
| Broad launch blitz | Show HN, forum, ElixirStatus, PR, and demand-thread replies all on the same day. | |

**User's choice:** Lock the recommended set after sub-agent research.
**Notes:** The selected approach matches Elixir norms, creates one durable discussion hub, lets proof artifacts do the selling, and avoids drive-by self-promotion. Same-day blitz was rejected as higher maintainer-load and higher astroturf/perception risk.

---

## Demand-Thread Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Contextual maintainer follow-up | Reply in both demand threads after the main announcement, disclose maintainer status, answer the original constraints, and use fair-fit language. | ✓ |
| Skip demand-thread replies | Only launch in #announcing / ElixirStatus / awesome-elixir and avoid reviving older threads. | |

**User's choice:** Lock the recommended set after sub-agent research.
**Notes:** The selected approach helps future readers in high-intent threads while preserving transparency. Replies must use "for future readers" framing, `Disclosure: I maintain Rendro.`, and at most three links.

---

## Mobile Viewer Evidence Beat

| Option | Description | Selected |
|--------|-------------|----------|
| Balanced 4 rows | iOS Files/Preview + Android Drive across `forms` and `signed_artifact`; form rows can become manual `supported`, signed rows are expected deferrals. | ✓ |
| Mail-heavy 4 rows | iOS Files forms, iOS Mail forms, Android Drive forms, one signed row. | |

**User's choice:** Lock the recommended set after sub-agent research.
**Notes:** The balanced set tests both recipient form usability and signed-artifact trust boundaries. Mail was deferred because attachment-preview save semantics are ambiguous and would make overclaiming easier.

---

## Adoption Gate and Routing

| Option | Description | Selected |
|--------|-------------|----------|
| Root `ADOPTION.md` + lightweight GitHub intake | Public ledger, issue/discussion templates, strict counting rules, and manual review. | ✓ |
| GitHub Projects / labels-only tracker | Native GitHub filtering with less duplicate bookkeeping. | |

**User's choice:** Lock the recommended set after sub-agent research.
**Notes:** Root `ADOPTION.md` is visible to adopters and can capture GitHub, ElixirForum, Hex snapshots, and contributor signals in one place. GitHub Projects was rejected as ceremony before inbound volume exists.

---

## the agent's Discretion

- Exact final launch and reply prose can be refined during execution while preserving the locked structure, disclosure, link policy, and claim boundaries.
- Exact issue-form field wording and label colors are discretionary.
- Exact mobile observation notes are operator-owned, provided the evidence path, proof IDs, viewer kind, and deferral rules stay intact.

## Deferred Ideas

- Same-day broad launch blitz across all channels.
- Required Show HN launch.
- `ios_mail_preview` as a Phase 88 mobile row.
- GitHub Projects / labels-only adoption tracker.
- Exhaustive mobile compatibility matrix.
