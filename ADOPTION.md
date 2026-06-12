# Adoption Signals

## Purpose

This ledger records public, reviewable signals for Rendro's conditional v2.7 global text shaping gate. It is the source of truth for deciding whether global text shaping work has enough concrete adopter demand to justify a dedicated milestone.

Rendro does not use private analytics, social counters, or GitHub Projects to trigger this gate. Every counted signal must be reviewable from a source URL or an explicitly anonymized private report.

## Current Gate: v2.7 Global Text Shaping

The gate is currently **blocked** until all three threshold families are met in the same review window: demand, downloads, and contributor signal.

Text-shaping signals count only when they require shaping, RTL, or cluster behavior beyond current support: Arabic, Hebrew/RTL, Devanagari, Thai, bidi ordering, cluster-aware line breaking, or copy/paste extraction behavior. Font installation, arbitrary browser layout, viewer bugs, archival compliance, and accessibility compliance requests route to separate work.

## Gate Thresholds

| Threshold | Status | Required |
| --- | --- | --- |
| Demand | Blocked | 6 qualifying text-shaping signals in a rolling 90-day window, from at least 4 distinct non-maintainer requesters and at least 3 distinct orgs/apps. At least 3 must block production or evaluation. |
| Downloads | Blocked | Since launch snapshot, Hex downloads.all increases by at least 1,500 and downloads.week >= 150 on two snapshots at least 14 days apart after launch week. |
| Contributor | Blocked | At least 1 merged, non-maintainer PR after launch that materially improves code, tests, docs, examples, fixtures, or a reproducible failing case. Typos, bots, Dependabot, and maintainer alternate accounts do not count. |

Counting rules:

- Count one shaping signal only when it names a concrete document job, script/language, current blocker, and source URL.
- Same requester/org/use case counts once per 90-day window.
- Reactions, stars, forks, `+1`, "please support Arabic", social posts, and generic i18n wishes do not qualify.
- Private adopter reports may be anonymized but cap at 2 counted signals per window.
- A maintainer applies `adoption:counted` only after checking these rules.

## Launch Snapshot

Record the launch-thread date as `L` before counting download growth.

| Date | Launch Thread | Hex downloads.all | Hex downloads.week | Notes |
| --- | --- | --- | --- | --- |
| YYYY-MM-DD | TBD | TBD | TBD | Add before counting download growth. |

## Signal Ledger

No qualifying shaping signals have been counted yet. Open a blocked-document issue or use-case discussion with a concrete document job, script/language, current blocker, and source URL.

| ID | Date | Source URL | Channel | Requester | Org/App | Gate Area | Script/Language | Document Job | Blocking? | Qualifies? | Count Group | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| - | - | - | - | - | - | - | - | - | - | - | - | No qualifying shaping signals yet. |

## Download Snapshots

No post-launch Hex download snapshots recorded yet. Add the launch snapshot before counting download growth.

Use this command when recording a snapshot:

```sh
curl -fsSL https://hex.pm/api/packages/rendro | jq '.downloads'
```

| Date | Hex downloads.all | Hex downloads.week | Source | Notes |
| --- | --- | --- | --- | --- |
| YYYY-MM-DD | TBD | TBD | Hex package API | Add the first row at launch, then compare later snapshots against it. |

## External Contributors

No qualifying non-maintainer contributor signal has been counted yet.

Contributor review command:

```sh
gh pr list --state merged --search "merged:>=$LAUNCH_DATE -author:szTheory" \
  --json number,title,author,mergedAt,url
```

Reject any contributor candidate whose author is a bot, `dependabot[bot]`, a maintainer alternate account listed below, or whose change is only typo cleanup.

Maintainer alternate accounts excluded from the contributor threshold:

| Account | Reason | Notes |
| --- | --- | --- |
| TBD | Maintainer alternate account | Add before counting a borderline contributor PR. |

Rejected contributor candidates:

| PR | Author | Reason |
| --- | --- | --- |
| TBD | TBD | No rejected candidates recorded yet. |

## Review Log

No gate reviews have run yet. First review is scheduled for L+30 and the gate cannot trigger before L+45.

Review cadence:

- Triage inbound signals twice weekly for the first 30 days after `L`, then weekly.
- Gate reviews happen at `L+30`, `L+60`, `L+90`, then monthly using the rolling 90-day window.
- The gate cannot trigger before L+45.

Issue review commands:

```sh
gh issue list --state all --label "adoption:signal" \
  --json number,title,author,createdAt,url,labels

gh issue list --state all --label "area:text-shaping" \
  --json number,title,author,createdAt,url,labels
```

Use the GitHub UI for low-volume Discussions. Use GraphQL only if volume justifies it.

| Date | Reviewer | Demand | Downloads | Contributor | Decision | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| TBD | TBD | Blocked | Blocked | Blocked | No review run yet | First scheduled review is L+30. |
