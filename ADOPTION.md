# Adoption Signals

## Purpose

This ledger records public, reviewable signals for Rendro's conditional global text shaping gate. It is intentionally low-maintenance: Rendro is quietly public, and signals are reviewed when people find the project and open concrete issues.

Rendro does not use private analytics, social counters, launch campaigns, or GitHub Projects to trigger this gate. Every counted signal must be reviewable from a source URL or an explicitly anonymized private report.

The current review is bound to the immutable, packaged sidecar [`priv/adoption_evidence/2026-08-21.json`](priv/adoption_evidence/2026-08-21.json). It contains bounded public source metadata and digests only; unavailable retrieval remains explicitly unavailable rather than becoming zero activity.

## Current Gate: Conditional Global Text Shaping

The gate is currently **blocked** until all three threshold families are met in the same review window: demand, downloads, and contributor signal.

Text-shaping signals count only when they require shaping, RTL, or cluster behavior beyond current support: Arabic, Hebrew/RTL, Devanagari, Thai, bidi ordering, cluster-aware line breaking, or copy/paste extraction behavior. Font installation, arbitrary browser layout, viewer bugs, archival compliance, and accessibility compliance requests route to separate work.

## Gate Thresholds

| Threshold | Status | Required |
| --- | --- | --- |
| Demand | Blocked | 6 qualifying text-shaping signals in a rolling 90-day window, from at least 4 distinct non-maintainer requesters and at least 3 distinct orgs/apps. At least 3 must block production or evaluation. |
| Downloads | Blocked | Since discovery baseline, Hex downloads.all increases by at least 1,500 and downloads.week >= 150 on two snapshots at least 14 days apart after the baseline. |
| Contributor | Blocked | At least 1 merged, non-maintainer PR after discovery baseline that materially improves code, tests, docs, examples, fixtures, or a reproducible failing case. Typos, bots, Dependabot, and maintainer alternate accounts do not count. |

Counting rules:

- Count one shaping signal only when it names a concrete document job, script/language, current blocker, and source URL.
- Same requester/org/use case counts once per 90-day window.
- Reactions, stars, forks, `+1`, "please support Arabic", social posts, and generic i18n wishes do not qualify.
- Private adopter reports may be anonymized but cap at 2 counted signals per window.
- A maintainer applies `adoption:counted` only after checking these rules.

## Discovery Baseline

The discovery baseline is the first recorded public-readiness snapshot. It is not tied to an announcement campaign.

| Date | Source | Hex downloads.all | Hex downloads.week | Notes |
| --- | --- | --- | --- | --- |
| 2026-06-12 | Quiet public readiness check | 867 | 115 | Baseline recorded after README, comparison guide, Livebook, ADOPTION.md, and HexDocs proof URLs were public. |

## Signal Ledger

No qualifying shaping signals have been counted yet. Open a blocked-document issue with a concrete document job, script/language, current blocker, and source URL.

| ID | Date | Source URL | Channel | Requester | Org/App | Gate Area | Script/Language | Document Job | Blocking? | Qualifies? | Count Group | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| - | - | - | - | - | - | - | - | - | - | - | - | No qualifying shaping signals yet. |

## Download Snapshots

No post-baseline Hex download snapshots recorded yet. Add future snapshots only when reviewing inbound signal volume or planning a future milestone.

Use this command when recording a snapshot:

```sh
curl -fsSL https://hex.pm/api/packages/rendro | jq '.downloads'
```

| Date | Hex downloads.all | Hex downloads.week | Source | Notes |
| --- | --- | --- | --- | --- |
| 2026-06-13 | 877 | 117 | Hex package API | Captured during v2.8 stewardship planning review (not scheduled telemetry). +10 all / +2 week since 2026-06-12 baseline; negligible movement, Downloads threshold still blocked. First post-baseline data point; next snapshot only when planning future work or reviewing concrete demand. |
| 2026-08-21 | 3,149 | 182 | [bounded source record](priv/adoption_evidence/2026-08-21.json) | AVAILABLE. +2,282 all / +67 week since baseline; the all-time and weekly predicates have progressed, but this review retains Downloads as ACCUMULATING pending the complete unchanged two-snapshot threshold record. |

## External Contributors

No qualifying non-maintainer contributor signal has been counted yet.

Contributor review command:

```sh
gh pr list --state merged --search "merged:>=2026-06-12 -author:szTheory" \
  --json number,title,author,mergedAt,url
```

Reject any contributor candidate whose author is a bot, `dependabot[bot]`, a maintainer alternate account listed below, or whose change is only typo cleanup.

Maintainer alternate accounts excluded from the contributor threshold:

| Account | Reason | Notes |
| --- | --- | --- |
| No alternate accounts are currently recorded | Maintainer alternate account exclusion | No account is excluded from the threshold at this dated review. |

Rejected contributor candidates:

| PR | Author | Reason |
| --- | --- | --- |
| No rejected candidates were recorded for the 2026-08-21 review | — | Bounded contributor review returned zero candidates. |

## Review Log

No gate reviews have run yet. Reviews are pull-based: run one when qualifying issues exist or during future milestone planning.

Review cadence:

- Triage inbound adoption-signal issues when they are opened.
- Run gate reviews only when concrete inbound signals exist or when planning a future milestone.
- The gate cannot trigger until at least 45 days after the 2026-06-12 discovery baseline.

Issue review commands:

```sh
gh issue list --state all --label "adoption:signal" \
  --json number,title,author,createdAt,url,labels

gh issue list --state all --label "area:text-shaping" \
  --json number,title,author,createdAt,url,labels
```

| Date | Reviewer | Demand | Downloads | Contributor | Decision | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-06-13 | Maintainer (v2.8 planning) | 0 | 877 all / 117 wk | 0 | HOLD | HOLD (all three families). Decision rule applied: TRIGGER / ACCUMULATING / HOLD / HOLD-noise. Downloads 867→877 all, 115→117 week since baseline: noise, not the +1,500 / >=150 thresholds. Zero qualifying shaping signals; zero non-maintainer PRs. Re-check is pull-based, not scheduled: next review triggered by the first qualifying text-shaping issue, a counted contributor PR, or the next milestone-planning pass — whichever comes first. Gate cannot trigger before 2026-07-27 (earliest-possible floor, not a reminder). |
| 2026-08-21 | Maintainer (Phase 131) | HOLD (AVAILABLE; 0 candidates) | ACCUMULATING (AVAILABLE; 3,149 all / 182 wk) | HOLD (AVAILABLE; 0 candidates) | HOLD | Read-only Hex and bounded GitHub issue/merged-PR review recorded in the [dated sidecar](priv/adoption_evidence/2026-08-21.json). Composite is HOLD because it is the weakest family decision; no source failure was counted as zero and no polling, mutation, labeling, or outreach was added. |
