# Phase 96: Adoption Signal Review & Stewardship Posture - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 96-Adoption Signal Review & Stewardship Posture
**Areas discussed:** Next-trigger semantics, Record live snapshot row, Bug/security commitment wording
**Mode:** Advisor (`minimal_decisive`, `vendor_philosophy: opinionated`). Maintainer requested deep parallel subagent research on all three forks and a one-shot locked set of coherent recommendations.

---

## Next-trigger semantics (FORK 1)

| Option | Description | Selected |
|--------|-------------|----------|
| Event-based + 45-day floor | Trigger = qualifying issue OR counted contributor PR OR next-milestone planning; `2026-07-27` named as earliest-possible floor, NOT a scheduled reminder. | ✓ |
| Standing calendar re-check | A fixed future date to re-review regardless of inbound signal. | |

**User's choice:** Event-based + floor (locked to research recommendation).
**Notes:** Research (Go proposal process, SQLite scope discipline, Ecto/Plug support-posture signaling, deprecation-calendar liability literature) was decisive. Standing calendar date rejected: a date you don't honor becomes a broken public promise that reads as abandonment — the dominant footgun, acute for a solo maintainer — and directly contradicts ADOPTION.md's locked "reviews are pull-based, not scheduled from a launch date." Event-based + floor satisfies SC#2 (names a date, resists neglect) without a recurring obligation.
**Locked microcopy (next-trigger sentence):** "Re-check is pull-based, not scheduled: the next review is triggered by the first qualifying text-shaping issue, a counted contributor PR, or the next milestone-planning pass — whichever comes first. The gate cannot trigger before 2026-07-27 (45 days after the 2026-06-12 baseline); that date is the earliest-possible floor, not a calendar reminder or a commitment to review on that day."

---

## Record live snapshot row (FORK 2)

| Option | Description | Selected |
|--------|-------------|----------|
| Append snapshot + review row | Add dated `## Download Snapshots` row (877 all / 117 week, 2026-06-13) AND the Review Log row. | ✓ |
| Review row only | Cite numbers inline in review prose; leave Download Snapshots table as placeholder. | |

**User's choice:** Append snapshot + review row (locked to research recommendation).
**Notes:** Research (append-only audit-log discipline, ADR event-driven records, lab-notebook "record negative/no-change results," OSS vanity-metric critique) was decisive. The Downloads threshold (two snapshots ≥14 days apart, +1,500 all, week≥150) is *unprovable without dated snapshot rows*, so this review is the natural moment to lay the first post-baseline data point. Recording an unflattering "+2/week" point is the anti-vanity move. Cadence-creep footgun neutralized by anti-cadence "captured during planning, not scheduled telemetry" microcopy.
**Locked snapshot row:** `| 2026-06-13 | 877 | 117 | Hex package API | Captured during v2.8 stewardship planning review (not scheduled telemetry). +10 all / +2 week since 2026-06-12 baseline; negligible movement, Downloads threshold still blocked. First post-baseline data point; next snapshot only when planning future work or reviewing concrete demand. |`

---

## Bug/security commitment wording (FORK 3)

| Option | Description | Selected |
|--------|-------------|----------|
| Tiered (security / bugs / features) | Security fixes prioritized (no SLA, private reporting); bug fixes best-effort (no SLA); new capabilities demand-gated → ADOPTION.md. | ✓ |
| Flat best-effort | Single "best-effort maintenance" line without tiering. | |

**User's choice:** Tiered (locked to research recommendation).
**Notes:** Research (SQLite LTS longevity + scope discipline, Elixir core SECURITY.md tiering, Sinatra/urllib3/requests "feature-complete not dead" framing, SLA-overpromise + best-effort-undersell footguns) was decisive. Flat wording rejected: it flattens security to the same tier as a cosmetic bug, which for a lib shipping cryptographic signing + AES-256 protection is an actively *wrong* signal, and "best-effort, no guarantees" scares enterprise adopters. No SLA numbers anywhere. No invented SECURITY.md (none exists) — point to GitHub private vulnerability reporting.

**Locked drop-in prose for `## Project Status & Stewardship` (api_stability.md):**

```markdown
## Project Status & Stewardship

**Stable and actively stewarded · feature-complete for its stated scope.** _Last reviewed: 2026-06-13._

Rendro is at `1.0.0` and is considered done for the scope this guide defines: deterministic
document rendering, the canonical business recipes, Phoenix integration, and the trust-sensitive
signing and password-protection surfaces. "Done" here means the stated scope is complete and
proof-backed — not that the project is finished with. It is solo-maintained and stewarded on a
pull basis: the maintainer responds to concrete, reproducible reports rather than running a
scheduled support rotation.

- **Security fixes are prioritized.** Because Rendro touches cryptographic signing and password
  protection, security issues take precedence over everything else here. Report a suspected
  vulnerability privately through GitHub's private vulnerability reporting ("Report a vulnerability"
  on the Security tab) — please do not open a public issue for a security report. There is no
  contractual response-time SLA, but security reports are triaged ahead of feature and bug work,
  and fixes ship as a patch release with a CHANGELOG entry.
- **Bug fixes are best-effort, with no SLA.** Reproducible bugs against the Tier-1 stable surface
  (above) are addressed on a best-effort basis, prioritized by how many adopters they block and
  whether they breach a documented contract. A minimal failing case — input, expected output, and
  observed output — is the fastest path to a fix. Best-effort does not mean no effort; it means no
  guaranteed timeline.
- **New capabilities are demand-gated, not abandoned.** Rendro does not add feature families
  speculatively. Larger surfaces — global text shaping and broader script support chief among them —
  are gated on recorded adoption demand rather than a roadmap date. The gate, its thresholds, and
  how to register a qualifying signal are public in [`ADOPTION.md`](../ADOPTION.md). A quiet release
  cadence is a deliberate stewardship posture, not a sign of an unmaintained project.
```

---

## Claude's Discretion

- Exact prose within the locked structure for all three files (research microcopy above is the strong default).
- Optional reconcile of MILESTONE-ARC.md's stale `Active Milestone: None` / `Next Recommendation: v2.8 recommended` lines (v2.8 is active, 93-95 done) — adjacent to SC#3, not required by it.
- `ADOPTION.md` link form from `guides/api_stability.md` (`../ADOPTION.md` vs HexDocs extra slug) — verify against existing guide cross-links.
- Whether to add a docs-contract test asserting the `Last reviewed:` line.

## Deferred Ideas

- Optional repo `SECURITY.md` (low-cost trust boost for a signing/encryption lib; not required by SC#4; locked wording is self-consistent without it).
- Docs-contract test for the `Last reviewed:` line (future hygiene).
