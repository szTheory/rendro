# Phase 88: Launch Execution & Demand Instrumentation - Research

**Researched:** 2026-06-12
**Domain:** launch execution, public documentation gates, mobile viewer evidence, GitHub intake, adoption instrumentation
**Confidence:** HIGH - core repo patterns verified by grep/read; external launch surfaces verified by current web/curl/gh checks.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- D-01: Use an Elixir-first proof hub launch, not a same-day broad blitz. Publish the canonical ElixirForum announcement first, then post ElixirStatus, open the awesome-elixir PR, reply to the two demand threads, publish mobile evidence as a follow-up, and treat Show HN as optional/later. [VERIFIED: .planning/phases/88-launch-execution-demand-instrumentation/88-CONTEXT.md]
- D-02: The ElixirForum announcement is the canonical launch hub. Shorter channels link back to it rather than creating parallel long-form launch narratives. [VERIFIED: repo read]
- D-03: Do not launch until public Hex/HexDocs/GitHub state contains the HYG/GAL/CMP artifacts, including the Livebook. Planning/execution must reconcile the current status mismatch first: `.planning/REQUIREMENTS.md` still shows `CMP-03` pending while `.planning/STATE.md` and `.planning/ROADMAP.md` say Phase 87 is complete. [VERIFIED: repo grep]
- D-04: Announcement title shape: `Rendro: Elixir-native PDF layout without Chrome`. Use ElixirForum `News > Announcing`; tags should include `library` and `pdf` if available. [CITED: https://elixirforum.com/c/news/announcing/159]
- D-05: Announcement structure: what Rendro is, why it exists, what works today, proof links, honest boundaries, and feedback request. Lead with gallery/manual SHA/Livebook/comparison and support boundaries, not benchmark victory language. [VERIFIED: context]
- D-06: Allowed core claim: "Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome." Avoid "Prawn equivalent", "HTML-to-PDF", "PDF/A compliant", "PDF/UA compliant", broad viewer support, and broad complex-script claims. [VERIFIED: context]
- D-07: ElixirStatus post follows immediately after the forum thread. Keep it short and link to the forum announcement, HexDocs, and Livebook. [CITED: https://elixirstatus.com/]
- D-08: awesome-elixir PR follows once public docs are live. Add Rendro under `PDF`, alphabetically sorted, with concise source-repo wording: `Rendro - Elixir-native PDF layout library with deterministic pagination and no browser runtime.` [CITED: https://github.com/h4cc/awesome-elixir]
- D-09: Show HN is optional and later. Use only when GitHub/HexDocs/Livebook provide a no-signup try path and a maintainer can answer comments live. Title shape: `Show HN: Rendro - Native PDF layout for Elixir without Chrome`. [CITED: https://news.ycombinator.com/showhn.html]
- D-10: Reply to the two existing ElixirForum demand threads only after the canonical announcement is live. Order: `PDF generation without Chromium dependency`, then `Looking for a Prawn-Like PDF Generation Library in Elixir`. [CITED: https://elixirforum.com/t/pdf-generation-without-chromium-dependency/68211] [CITED: https://elixirforum.com/t/looking-for-a-prawn-like-pdf-generation-library-in-elixir/67278]
- D-11: Frame both replies as "for future readers" and disclose maintainer status near the top: `Disclosure: I maintain Rendro.` Do not write as a neutral third party, ask others to seed replies, or duplicate the announcement body. [VERIFIED: context]
- D-12: Use decision-guide language, not winner language. Rendro fits business documents authored from Elixir data; ChromicPDF/Gotenberg fit HTML/CSS and browser print fidelity; pdf_generator fits existing wkhtmltopdf/chrome-headless workflows; Typst fits teams that want `.typ` templates and Typst's layout language. [VERIFIED: .planning/phases/87-comparison-page-livebook/87-CONTEXT.md]
- D-13: Use at most three links per demand-thread reply: public repo/HexDocs, comparison guide, and first-invoice Livebook. Avoid raw benchmark tables in forum replies; link to the reproducible guide instead. [VERIFIED: context]
- D-14: Route broad fit discussion in the forum, but route concrete unsupported documents, benchmark challenges, and feature requests to GitHub Discussions/issues and `ADOPTION.md` counting rules. [VERIFIED: context]
- D-15: Use the balanced four-row mobile evidence set: iOS Files/Preview and Google Drive PDF viewer on Android across `forms` and `signed_artifact`. [CITED: https://support.apple.com/guide/iphone/fill-out-and-sign-pdf-forms-iphd7e3c0c74/ios] [CITED: https://support.google.com/drive/answer/9463834?co=GENIE.Platform%3DAndroid&hl=en]
- D-16: Add `forms.viewers.ios_files_preview` with viewer name `iOS Files/Preview`, proof IDs `open`, `default_state_visible`, `edit_or_toggle`, `save`, and evidence path `priv/viewer_evidence/forms/ios_files_preview.md` if all checks pass. Matrix row uses `status: "supported"`, `viewer_kind: "manual"`, and exact `recorded_at`. If any proof fails, use `explicit_deferral` and no evidence file. [VERIFIED: context]
- D-17: Add `forms.viewers.android_drive_viewer` with viewer name `Google Drive PDF viewer on Android`, the same four form proof IDs, and evidence path `priv/viewer_evidence/forms/android_drive_viewer.md` if all checks pass. Matrix policy matches D-16. [VERIFIED: context]
- D-18: Add `signing.viewers.ios_files_preview` as an expected `explicit_deferral` for the `signed_artifact` evidence surface unless it unexpectedly passes the full signed-artifact proof gate. Deferral must distinguish drawn/Markup signatures from `/Sig` cryptographic validation. [VERIFIED: context]
- D-19: Add `signing.viewers.android_drive_viewer` as an expected `explicit_deferral` for `signed_artifact`. The deferral reason should name the absent signed-artifact trust UI: no observed integrity, certificate-trust, or timestamp validation panel for the representative signed fixture. [VERIFIED: context]
- D-20: Do not add `ios_mail_preview` in LNCH-02. Treat Mail as a delivery/handoff note inside `ios_files_preview` evidence only. Add a Mail viewer row later only if all proof IDs can be completed inside Mail attachment preview itself. [VERIFIED: context]
- D-21: Content beat title shape: "What happens when a Rendro PDF reaches a phone?" Core message: simple AcroForm rows can be manually proven per viewer; signed PDFs need a real validation surface; Rendro records both outcomes in the support matrix. Avoid the blanket phrase "mobile PDF support." [VERIFIED: context]
- D-22: Update `guides/api_stability.md` with supported mobile form evidence paths and signed deferral reasons; update `CHANGELOG.md` because support-matrix changes are public-contract changes; update hard-coded docs-contract path/count tests. [VERIFIED: guides/api_stability.md] [VERIFIED: test/docs_contract/viewer_evidence_claims_test.exs]
- D-23: Verification commands for mobile evidence work are `mix rendro.viewer_evidence validate`, `mix rendro.viewer_evidence list`, the targeted docs-contract tests, and `mix docs.contract`. [VERIFIED: lib/mix/tasks/rendro/viewer_evidence.ex] [VERIFIED: lib/mix/tasks/docs.contract.ex]
- D-24: Put `ADOPTION.md` at the repository root. It is a public product/roadmap surface, not private planning. Link it from README, comparison guide limitation block, issue/discussion templates, and launch replies. [VERIFIED: context]
- D-25: `ADOPTION.md` section order is `# Adoption Signals`, `## Purpose`, `## Current Gate: v2.7 Global Text Shaping`, `## Gate Thresholds`, `## Launch Snapshot`, `## Signal Ledger`, `## Download Snapshots`, `## External Contributors`, `## Review Log`. [VERIFIED: context]
- D-26: Signal ledger columns are `ID | Date | Source URL | Channel | Requester | Org/App | Gate Area | Script/Language | Document Job | Blocking? | Qualifies? | Count Group | Notes`. [VERIFIED: context]
- D-27: v2.7 gate triggers only when all three thresholds are met: demand threshold, downloads threshold, and contributor threshold exactly as defined in CONTEXT.md. [VERIFIED: context]
- D-28: Count one shaping signal only when it names a concrete document job, script/language, current blocker, and source URL; same requester/org/use case counts once per 90-day window; reactions/stars/forks/+1/social/generic wishes do not count; private reports may be anonymized but cap at 2 per window. [VERIFIED: context]
- D-29: Text-shaping signals count only when they require shaping/RTL/cluster behavior beyond current support: Arabic, Hebrew/RTL, Devanagari, Thai, bidi ordering, cluster-aware line breaking, or copy/paste extraction issues. Font installation, arbitrary HTML/CSS rendering, viewer bugs, and PDF/A/PDF/UA asks route elsewhere. [VERIFIED: context]
- D-30: Define `L` as the launch-thread date. Triage inbound twice weekly for the first 30 days, then weekly. Gate reviews happen at `L+30`, `L+60`, `L+90`, then monthly using the rolling 90-day window. The gate cannot trigger before `L+45`. [VERIFIED: context]
- D-31: Enable GitHub Discussions with `Announcements`, `Q&A`, and `Use cases` if available. Add `.github/DISCUSSION_TEMPLATE/use-cases.yml` for `Use cases`, asking for document type, Phoenix/Elixir context, blocker, script/language, workaround, and whether production/evaluation is blocked. [CITED: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms]
- D-32: Add only `.github/ISSUE_TEMPLATE/01_bug.yml`, `.github/ISSUE_TEMPLATE/02_blocked_document.yml`, and `.github/ISSUE_TEMPLATE/config.yml` in Phase 88. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository]
- D-33: Default labels for the blocked-document form are `state:triage` and `adoption:signal`. The maintainer manually adds `adoption:counted` after reviewing against the gate. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms]
- D-34: Label set: `state:triage`, `kind:bug`, `kind:enhancement`, `kind:docs`, `area:text-shaping`, `area:viewer-evidence`, `area:phoenix`, `adoption:signal`, `adoption:counted`, `adoption:duplicate`, `adoption:private`, `help wanted`, `good first issue`. [VERIFIED: context]
- D-35: Review workflow commands use Hex API downloads, `gh issue list` for adoption/text-shaping labels, `gh pr list` for merged non-maintainer PRs, GitHub UI for low-volume Discussions, and `gh api graphql` only if volume justifies it. [CITED: https://hex.pm/api/packages/rendro] [VERIFIED: gh 2.93.0 available]

### the agent's Discretion

- Exact final prose for the announcement and replies is left to execution, provided it follows the locked structure, disclosure, link policy, and brand voice. [VERIFIED: context]
- Exact issue-form field wording and label colors are discretionary. Preserve the template set, counting rules, and default labels. [VERIFIED: context]
- Exact mobile observation notes are operator-owned. Preserve the proof IDs, viewer keys, evidence paths, and deferral policy. [VERIFIED: context]

### Deferred Ideas (OUT OF SCOPE)

- Same-day broad launch blitz across ElixirForum, ElixirStatus, awesome-elixir, demand threads, and Show HN. [VERIFIED: context]
- Show HN as a required launch step. [VERIFIED: context] [CITED: https://news.ycombinator.com/showhn.html]
- `ios_mail_preview` as a mobile viewer row. [VERIFIED: context]
- GitHub Projects / labels-only adoption tracking. [VERIFIED: context]
- Broad mobile compatibility matrix. [VERIFIED: context]

## Project Constraints (from AGENTS.md)

- Rendro core stays pure: no hard dependency on Phoenix, Oban, admin tooling, browser tooling, or launch instrumentation code. [VERIFIED: AGENTS.md]
- Optional integrations must stay guarded with optional dependencies and compile/runtime checks. [VERIFIED: AGENTS.md] [VERIFIED: mix.exs]
- Documentation claims are product contracts; public claims must be backed by checked-in support matrix rows, evidence files, generated artifacts, or explicit deferrals. [VERIFIED: AGENTS.md]
- Preserve deterministic required lanes and advisory verification lane separation; mobile manual evidence must not become a required live CI dependency. [VERIFIED: AGENTS.md] [VERIFIED: priv/guardrails/required_status_checks.json]
- Architecture remains data-first: `build -> compose -> measure -> paginate -> render -> validate`; Phase 88 must not introduce rendering capability or pipeline changes. [VERIFIED: AGENTS.md]
- Errors and telemetry are product behavior, not post-hoc instrumentation; Phase 88 should route demand through transparent docs/forms rather than hidden analytics. [VERIFIED: AGENTS.md]
- Before source-changing work, use a GSD workflow entry point; this research turn is writing only the required research artifact as requested. [VERIFIED: AGENTS.md]
- No project-local custom skills exist under `.codex/skills` or `.agents/skills`. [VERIFIED: repo find]

## Summary

Phase 88 should be planned as a launch-readiness and public-contract phase, not an engine feature phase. The critical first gate is publication readiness: local `README.md`, `guides/comparison.md`, and `guides/livebook/first_invoice.livemd` exist, but public GitHub/HexDocs do not currently expose the Phase 86/87 artifacts; `origin/main` is 183 commits behind local `main`, public raw GitHub comparison/Livebook paths return 404, and public HexDocs comparison/Livebook URLs return 404. [VERIFIED: git status --short --branch] [VERIFIED: curl raw.githubusercontent.com] [VERIFIED: curl https://rendro.hexdocs.pm/comparison.html] [VERIFIED: curl https://rendro.hexdocs.pm/first_invoice.html]

The planner should split work into four lanes: readiness/public sync, mobile evidence/support matrix, adoption ledger/GitHub intake, and launch-copy execution checklists. All public claims must remain bounded: Rendro is Elixir-native PDF layout for Phoenix teams without Chrome, not HTML-to-PDF, not a Prawn equivalent, not PDF/A or PDF/UA compliant, not broadly mobile-supported, and not broadly complex-script capable. [VERIFIED: 88-CONTEXT.md] [VERIFIED: guides/api_stability.md]

**Primary recommendation:** Plan a hard launch gate before copy publication: reconcile `CMP-03`, push/publish Phase 86/87 artifacts, verify public URLs, create `ADOPTION.md` and intake templates, record/deflect the four mobile rows through existing viewer-evidence machinery, then publish the ElixirForum hub and downstream posts in the locked order. [VERIFIED: repo grep] [CITED: https://elixirforum.com/c/news/announcing/159]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LNCH-01 | Execute coordinated launch through ElixirForum, ElixirStatus, awesome-elixir PR, and genuine demand-thread replies after HYG/GAL/CMP are shipped. | External surfaces are reachable; both demand threads are visible/open; ElixirStatus has sign-in posting; awesome-elixir has a PDF category. [CITED: https://elixirforum.com/t/pdf-generation-without-chromium-dependency/68211] [CITED: https://elixirforum.com/t/looking-for-a-prawn-like-pdf-generation-library-in-elixir/67278] [CITED: https://elixirstatus.com/] [CITED: https://github.com/h4cc/awesome-elixir] |
| LNCH-02 | Record 2-4 mobile viewer-evidence rows via the existing evidence recipe and publish as a content beat. | Existing support matrix schemas allow `viewer_kind: "manual"`; evidence files live under `priv/viewer_evidence/<surface>/<viewer>.md`; hard-coded docs-contract path tests must be updated. [VERIFIED: priv/schemas/support_matrix.schema.json] [VERIFIED: priv/schemas/viewer_evidence.schema.json] [VERIFIED: test/docs_contract/viewer_evidence_claims_test.exs] |
| LNCH-03 | Define concrete v2.7 text-shaping demand gate with `ADOPTION.md`, thresholds, ledger, GitHub Discussions, and issue templates. | `ADOPTION.md` is absent; `.github/ISSUE_TEMPLATE/` and `.github/DISCUSSION_TEMPLATE/` are absent; Discussions are disabled on the live repo; `gh`, `curl`, and `jq` are available for the review workflow. [VERIFIED: test -f ADOPTION.md] [VERIFIED: find .github] [VERIFIED: gh api repos/szTheory/rendro] |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Launch readiness gate | Repository/docs/release | External HexDocs/GitHub | Public launch must wait for local traceability and public docs state to agree. [VERIFIED: REQUIREMENTS.md] [VERIFIED: curl HexDocs] |
| ElixirForum hub and replies | External community surface | Repository proof links | The forum is the canonical discussion hub; repo/docs links provide proof. [CITED: https://elixirforum.com/c/news/announcing/159] |
| ElixirStatus post | External community surface | ElixirForum hub | ElixirStatus is short-link distribution, not long-form launch narrative. [CITED: https://elixirstatus.com/] |
| awesome-elixir PR | External GitHub repo | Local source repo | The PR edits h4cc/awesome-elixir README under `PDF`; no local package change should be needed. [CITED: https://github.com/h4cc/awesome-elixir] |
| Mobile form evidence | Repository support contract | Manual operator | `priv/support_matrix.json` owns status; evidence files own observations; operator owns pass/fail notes. [VERIFIED: guides/viewer_evidence.md] |
| Mobile signed-artifact deferrals | Repository support contract | Manual operator | Signed mobile rows are expected `explicit_deferral` unless a real trust UI is observed. [VERIFIED: 88-CONTEXT.md] |
| Adoption gate | Root public Markdown | GitHub Issues/Discussions, Hex API | `ADOPTION.md` is the ledger; GitHub/Hex surfaces supply review inputs. [VERIFIED: context] [CITED: https://hex.pm/api/packages/rendro] |
| GitHub intake | GitHub platform config | Docs-contract tests | Issue/discussion YAML structures user input; tests keep labels, links, and routing honest. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] [CITED: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms] |

## Standard Stack

### Core

| Tool/Surface | Version/State | Purpose | Why Standard |
|--------------|---------------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, OTP 28 | Existing project runtime and verification commands. | Matches AGENTS.md and local toolchain. [VERIFIED: elixir --version] |
| ExUnit + docs-contract scripts | 152 test files; `mix docs.contract` wraps `scripts/verify_docs.exs` | Enforce documentation claims, support matrix paths, and guide mirrors. | Existing project pattern for public claims. [VERIFIED: rg --files test] [VERIFIED: lib/mix/tasks/docs.contract.ex] |
| `priv/support_matrix.json` | Existing public support contract | Terminal viewer rows and explicit deferrals. | Existing viewer-evidence architecture. [VERIFIED: jq keys priv/support_matrix.json] |
| `priv/viewer_evidence/` | Existing evidence tree | Manual and automated observation records. | Existing schema and lint pipeline. [VERIFIED: find priv/viewer_evidence] |
| `ADOPTION.md` | New root public document | Demand gate, snapshots, ledger, review history. | Locked Phase 88 decision. [VERIFIED: 88-CONTEXT.md] |

### Supporting

| Tool/Surface | Version/State | Purpose | When to Use |
|--------------|---------------|---------|-------------|
| `gh` CLI | 2.93.0, authenticated as `szTheory`, repo/workflow scopes | Labels, issue lists, PR lists, repo Discussions checks. | Adoption review workflow and repo setup. [VERIFIED: gh --version] [VERIFIED: gh auth status] |
| `curl` + `jq` | curl 8.7.1, jq 1.7.1 | Hex API snapshots and external URL readiness checks. | Launch snapshot and review commands. [VERIFIED: curl --version] [VERIFIED: jq --version] |
| GitHub issue forms | YAML under `.github/ISSUE_TEMPLATE` | Structured bug and blocked-document intake. | Add only locked templates. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| GitHub discussion category forms | YAML under `.github/DISCUSSION_TEMPLATE` | Structured use-case discovery. | Only after Discussions/categories are enabled. [CITED: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms] |
| ElixirForum / ElixirStatus / awesome-elixir | Current external community surfaces | Launch distribution and existing-demand reply path. | Use locked choreography. [CITED: https://elixirforum.com/c/news/announcing/159] [CITED: https://elixirstatus.com/] [CITED: https://github.com/h4cc/awesome-elixir] |

### No Package Installs

Phase 88 should not add runtime dependencies or install third-party packages. It should add Markdown, JSON/YAML templates, docs-contract tests, labels, and launch copy artifacts/checklists only. [VERIFIED: 88-UI-SPEC.md] Package Legitimacy Audit is not applicable. [VERIFIED: no external package installs planned]

## Architecture Patterns

### Pattern 1: Hard Launch Gate Before Public Copy

Plan a first task that checks both local and public readiness. Local state currently has `CMP-03` pending in `.planning/REQUIREMENTS.md` while Phase 87 closure says CMP-03 complete. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/87-comparison-page-livebook/87-06-SUMMARY.md]

Public state is also not launch-ready: `origin/main` is behind local `main`, public raw GitHub lacks the comparison/Livebook files, and public HexDocs returns 404 for comparison/Livebook pages. [VERIFIED: git status --short --branch] [VERIFIED: curl raw.githubusercontent.com] [VERIFIED: curl HexDocs]

Required readiness checklist:

```text
1. Reconcile CMP-03 in REQUIREMENTS.md or explicitly document why the mismatch is resolved.
2. Push/publish Phase 86/87 artifacts to GitHub and HexDocs.
3. Verify public URLs for README gallery/manual, comparison guide, and first-invoice Livebook.
4. Only then publish ElixirForum announcement.
```

### Pattern 2: Support Matrix Owns Claims; Evidence Owns Observations

For `supported` mobile form rows, add a promotion-complete viewer row in `priv/support_matrix.json` with `status`, `proof`, `evidence`, `recorded_at`, and `viewer_kind: "manual"`. [VERIFIED: priv/schemas/support_matrix.schema.json]

For `explicit_deferral` signed mobile rows, add only `status: "explicit_deferral"` and a named `evidence_deferred` reason; do not create an evidence file. [VERIFIED: priv/schemas/support_matrix.schema.json] [VERIFIED: Rendro.ViewerEvidence.Validator]

### Pattern 3: Public Markdown Ledger, Not Hidden Analytics

Root `ADOPTION.md` is the source of truth for thresholds, launch snapshot, signal ledger, download snapshots, external contributors, and review log. [VERIFIED: 88-CONTEXT.md] Do not add custom analytics scripts or private tracking databases. [VERIFIED: 88-UI-SPEC.md]

### Pattern 4: GitHub Intake Before Counting

Create labels before relying on issue form defaults: GitHub issue-form `labels` are only auto-added if labels already exist. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] Current repo labels are only GitHub defaults, so Phase 88 must add the locked label set. [VERIFIED: gh label list]

Discussions are currently disabled (`has_discussions: false`) and there are no categories. [VERIFIED: gh api repos/szTheory/rendro] Plan an explicit manual or API-backed enablement step before expecting `.github/DISCUSSION_TEMPLATE/use-cases.yml` to work. [CITED: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms]

### Pattern 5: Generated/Checked Copy Where Claims Are Contractual

Follow existing docs-contract style: if copy states a path, row, threshold, or forbidden claim, back it with a test. Existing hard-coded path tests in `viewer_evidence_claims_test.exs`, `forms_claims_test.exs`, and `signing_claims_test.exs` are expected edit points. [VERIFIED: repo grep]

## Don't Hand-Roll

| Problem | Do Not Build | Use Instead | Why |
|---------|--------------|-------------|-----|
| Adoption tracking | App, database, GitHub Projects, analytics script | Root `ADOPTION.md` plus GitHub issue/discussion intake | Locked public ledger; small volume expected. [VERIFIED: context] |
| Mobile viewer proof tooling | New mobile automation framework | Existing manual viewer-evidence recipe | Existing schema/validator/docs-contract already model manual rows. [VERIFIED: guides/viewer_evidence.md] |
| Download telemetry | Scraper or persistent service | Hex package API snapshots via `curl -fsSL https://hex.pm/api/packages/rendro | jq '.downloads'` | Endpoint currently exposes `downloads.all`, `downloads.day`, `downloads.recent`, `downloads.week`. [VERIFIED: curl https://hex.pm/api/packages/rendro] |
| GitHub signal counting | Custom GraphQL dashboard | `gh issue list`, `gh pr list`, GitHub UI for low-volume Discussions | Locked commands and authenticated CLI are available. [VERIFIED: context] [VERIFIED: gh auth status] |
| Launch website | Landing page, hero, custom widgets | Markdown, HexDocs, ElixirForum, ElixirStatus, GitHub forms | UI-SPEC forbids custom browser widgets, remote images, CDN assets, social embeds, and JS. [VERIFIED: 88-UI-SPEC.md] |
| Community amplification | Neutral/seeded replies or bots | Maintainer-authored replies with disclosure | Avoid astroturf perception. [VERIFIED: PITFALLS.md] |
| Broad viewer claims | "mobile PDF support" or "works in every viewer" | Per-viewer supported rows or explicit deferrals | Support matrix is the public contract. [VERIFIED: guides/api_stability.md] |

## Common Pitfalls

### Launching From Local State Instead of Public State

What goes wrong: the announcement links to artifacts that exist locally but not on public GitHub/HexDocs. [VERIFIED: curl HexDocs 404]

How to avoid: add a readiness task that checks exact public URLs and blocks all community posts until they pass. [VERIFIED: 88-CONTEXT.md]

### Treating `CMP-03` as Done Without Reconciling Traceability

What goes wrong: planning accepts Phase 87 closure while requirements still show pending. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/STATE.md]

How to avoid: reconcile or explicitly gate the mismatch before launch work. [VERIFIED: 88-UI-SPEC.md]

### Mobile Evidence Overclaims

What goes wrong: a successful iOS/Android form edit becomes a broad mobile or signed-PDF claim. [CITED: https://support.apple.com/guide/iphone/fill-out-and-sign-pdf-forms-iphd7e3c0c74/ios] [CITED: https://support.google.com/drive/answer/9463834?co=GENIE.Platform%3DAndroid&hl=en] [VERIFIED: support matrix schema]

How to avoid: say "simple AcroForm rows can be manually proven per viewer" and do not say "mobile PDF support." [VERIFIED: 88-CONTEXT.md]

### Confusing Markup Signatures With `/Sig` Validation

What goes wrong: iOS "sign PDF forms" UI is treated as cryptographic validation. Apple documents filling/signing PDFs in Preview on iPhone, but that reference does not prove `/Sig` integrity, certificate trust, or timestamp validation UI. [CITED: https://support.apple.com/guide/iphone/fill-out-and-sign-pdf-forms-iphd7e3c0c74/ios]

How to avoid: signed mobile rows should be `explicit_deferral` unless a real validation surface is observed. [VERIFIED: 88-CONTEXT.md]

### GitHub Forms Without Labels

What goes wrong: issue forms specify labels that do not exist, so defaults are not applied. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms]

How to avoid: create labels first, then commit templates. [VERIFIED: gh label list]

### Discussions Template Without Discussions

What goes wrong: `.github/DISCUSSION_TEMPLATE/use-cases.yml` exists but the repo has Discussions disabled or no matching category slug. [VERIFIED: gh api repos/szTheory/rendro] [CITED: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms]

How to avoid: enable Discussions and create/confirm `Use cases` before relying on the template. [ASSUMED: exact enablement path may be UI or API depending on repo settings]

### Vague Demand Gate

What goes wrong: "adopter demand" cannot be reviewed and v2.7 gets re-litigated. [VERIFIED: PITFALLS.md]

How to avoid: copy the exact numeric thresholds into `ADOPTION.md`; add empty-state rows and review dates. [VERIFIED: 88-CONTEXT.md]

### Demand-Thread Self-Promotion

What goes wrong: replies feel like drive-by marketing in old threads. [VERIFIED: PITFALLS.md]

How to avoid: answer original constraints, disclose maintainer status, link at most three times, and praise alternatives where true. [VERIFIED: 88-CONTEXT.md]

## Code Examples

### `ADOPTION.md` Skeleton

```markdown
# Adoption Signals

## Purpose

This ledger records public, reviewable signals for Rendro's conditional v2.7 global text shaping gate.

## Current Gate: v2.7 Global Text Shaping

## Gate Thresholds

| Threshold | Status | Required |
|-----------|--------|----------|
| Demand | Blocked | 6 qualifying text-shaping signals in a rolling 90-day window, from at least 4 distinct non-maintainer requesters and at least 3 distinct orgs/apps. At least 3 must block production or evaluation. |
| Downloads | Blocked | Since launch snapshot, Hex downloads.all increases by at least 1,500 and downloads.week >= 150 on two snapshots at least 14 days apart after launch week. |
| Contributor | Blocked | At least 1 merged, non-maintainer PR after launch that materially improves code, tests, docs, examples, fixtures, or a reproducible failing case. |

## Launch Snapshot

| Date | Launch Thread | Hex downloads.all | Hex downloads.week | Notes |
|------|---------------|-------------------|--------------------|-------|
| YYYY-MM-DD | TBD | TBD | TBD | Add before counting download growth. |

## Signal Ledger

| ID | Date | Source URL | Channel | Requester | Org/App | Gate Area | Script/Language | Document Job | Blocking? | Qualifies? | Count Group | Notes |
|----|------|------------|---------|-----------|---------|-----------|-----------------|--------------|-----------|------------|-------------|-------|
| - | - | - | - | - | - | - | - | - | - | - | - | No qualifying shaping signals have been counted yet. |

## Download Snapshots

## External Contributors

## Review Log
```

Source: locked section order and columns from Phase 88 context. [VERIFIED: 88-CONTEXT.md]

### Mobile Form Supported Row Pattern

```json
"ios_files_preview": {
  "status": "supported",
  "proof": ["open", "default_state_visible", "edit_or_toggle", "save"],
  "evidence": "priv/viewer_evidence/forms/ios_files_preview.md",
  "recorded_at": "YYYY-MM-DD",
  "viewer_kind": "manual"
}
```

Schema support: `viewer_kind` enum includes `manual`. [VERIFIED: priv/schemas/support_matrix.schema.json]

### Mobile Signed Deferral Pattern

```json
"android_drive_viewer": {
  "status": "explicit_deferral",
  "evidence_deferred": "Google Drive PDF viewer on Android did not expose an observed signed-artifact integrity, certificate-trust, or timestamp validation panel for the representative signed fixture; drawn annotations are not /Sig cryptographic validation."
}
```

Deferral discipline: no `evidence`, `recorded_at`, or `viewer_kind` on `explicit_deferral` rows. [VERIFIED: priv/schemas/support_matrix.schema.json]

### GitHub Issue Form Pattern

```yaml
name: Report blocked document
description: Describe a concrete document Rendro cannot handle yet.
title: "[blocked document]: "
labels: ["state:triage", "adoption:signal"]
body:
  - type: textarea
    id: document-job
    attributes:
      label: Document job
      description: What business document are you trying to generate?
    validations:
      required: true
  - type: input
    id: script-language
    attributes:
      label: Script/language
      description: Required when the blocker is text shaping, RTL, bidi ordering, line breaking, or extraction.
    validations:
      required: false
```

GitHub issue forms live under `.github/ISSUE_TEMPLATE/*.yml` and support default labels/body input fields. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms]

### GitHub Discussion Form Pattern

```yaml
title: "[use case]: "
labels: ["state:triage"]
body:
  - type: textarea
    id: document-type
    attributes:
      label: Document type
      description: What kind of PDF are you evaluating Rendro for?
    validations:
      required: true
```

Discussion category forms live under `.github/DISCUSSION_TEMPLATE/FORM-NAME.yml`, and the file name must correspond with a discussion category slug. [CITED: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms]

### Launch Readiness Command Pattern

```sh
curl -fsSL https://hex.pm/api/packages/rendro | jq '.downloads'
curl -fsSL -o /dev/null -w '%{http_code}\n' https://rendro.hexdocs.pm/comparison.html
curl -fsSL -o /dev/null -w '%{http_code}\n' https://rendro.hexdocs.pm/first_invoice.html
gh api repos/szTheory/rendro --jq '{has_discussions, has_issues, default_branch}'
```

Current Hex API shape for Rendro includes `downloads.all`, `downloads.day`, `downloads.recent`, and `downloads.week`; research snapshot was `all: 867`, `week: 115`, `latest_stable_version: "1.0.0"`. Treat these numbers as a pre-launch snapshot only; recapture at `L`. [VERIFIED: curl https://hex.pm/api/packages/rendro]

## Current External Surface Findings

- ElixirForum `PDF generation without Chromium dependency` is reachable, visible, open, not archived, with 22 posts and last activity on 2024-12-22. [CITED: https://elixirforum.com/t/pdf-generation-without-chromium-dependency/68211] [VERIFIED: curl https://elixirforum.com/t/68211.json]
- ElixirForum `Looking for a Prawn-Like PDF Generation Library in Elixir` is reachable, visible, open, not archived, with 25 posts and last activity on 2026-02-09. [CITED: https://elixirforum.com/t/looking-for-a-prawn-like-pdf-generation-library-in-elixir/67278] [VERIFIED: curl https://elixirforum.com/t/67278.json]
- ElixirForum `News > Announcing` exists and current library announcements use `library` tags. [CITED: https://elixirforum.com/c/news/announcing/159]
- ElixirStatus says users can announce a project/blog/version update, has a `Sign in and post` link, and distributes through site/RSS/Twitter/ElixirWeekly. [CITED: https://elixirstatus.com/]
- awesome-elixir has a `PDF` category with current entries `chromic_pdf`, `gutenex`, `pdf2htmlex`, `pdf_generator`, and `puppeteer_pdf`; `rendro` should sort after `puppeteer_pdf`. [CITED: https://github.com/h4cc/awesome-elixir] [VERIFIED: web open]
- `h4cc/awesome-elixir` root currently exposes `README.md` and no `CONTRIBUTING` file through the GitHub contents API, so a README edit PR is the apparent contribution path. [VERIFIED: curl GitHub API]
- Show HN guidance requires something users can try, preferably without signup/email, and asks the maker to be around to discuss; this supports keeping Show HN optional/later. [CITED: https://news.ycombinator.com/showhn.html]
- Apple documents filling and signing PDF forms in Preview on iPhone, including field entry and adding a signature/text box; this supports form evidence exploration but does not prove `/Sig` cryptographic validation. [CITED: https://support.apple.com/guide/iphone/fill-out-and-sign-pdf-forms-iphd7e3c0c74/ios]
- Google documents filling PDF forms in Google Drive on Android, including opening a PDF, using Form Filling, entering data, and saving; this supports Android form evidence exploration but does not prove signed-artifact trust UI. [CITED: https://support.google.com/drive/answer/9463834?co=GENIE.Platform%3DAndroid&hl=en]

## Current Repo Surface Findings

- `ADOPTION.md` does not exist. [VERIFIED: test -f ADOPTION.md]
- `.github/ISSUE_TEMPLATE/` and `.github/DISCUSSION_TEMPLATE/` do not exist locally; `.github` contains workflow files only. [VERIFIED: find .github]
- GitHub Discussions are disabled on the live repo and no discussion categories are returned. [VERIFIED: gh api repos/szTheory/rendro] [VERIFIED: gh api graphql]
- Current live labels are GitHub defaults only (`bug`, `documentation`, `duplicate`, `enhancement`, `good first issue`, `help wanted`, `invalid`, `question`, `wontfix`). [VERIFIED: gh label list]
- `priv/support_matrix.json` has `forms.viewers` and `signing.viewers`; there is no top-level `signed_artifact` key. Use `signing.viewers.*` for signed-artifact viewer rows and `priv/viewer_evidence/signed_artifact/*.md` for signed-artifact evidence paths if unexpectedly supported. [VERIFIED: jq .signing priv/support_matrix.json]
- `test/docs_contract/viewer_evidence_claims_test.exs` hard-codes existing evidence paths and will need mobile path updates for supported rows. [VERIFIED: repo grep]
- `guides/api_stability.md` has an `Explicit Deferral Reasons` mirror section that must gain the mobile signed deferrals. [VERIFIED: guides/api_stability.md]
- `CHANGELOG.md` already states viewer-evidence promotions/deferrals are public-contract changes; Phase 88 must add an Unreleased entry for mobile support-matrix changes. [VERIFIED: CHANGELOG.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix. [VERIFIED: mix.exs] |
| Config file | `.formatter.exs`, `mix.exs`, `scripts/verify_docs.exs`; docs-contract task wraps the script. [VERIFIED: repo read] |
| Quick run command | `mix test test/docs_contract/viewer_evidence_claims_test.exs test/docs_contract/forms_claims_test.exs test/docs_contract/signing_claims_test.exs test/docs_contract/raster_claims_test.exs` [VERIFIED: 88-CONTEXT.md] |
| Full suite command | `mix ci` plus `mix docs.contract`; public launch also needs manual URL checks. [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| LNCH-01 | Launch does not proceed until HYG/GAL/CMP and public URLs are ready; launch copy avoids banned claims. | docs-contract/manual URL gate | New launch checklist/copy tests plus `curl` checks. | New tests needed. [ASSUMED: file names planner chooses] |
| LNCH-02 | Mobile rows are terminal, evidence-backed or explicitly deferred, mirrored in API stability and changelog. | docs-contract + viewer evidence validator | `mix rendro.viewer_evidence validate`; targeted docs-contract tests. | Existing tests need edits. [VERIFIED: repo grep] |
| LNCH-03 | `ADOPTION.md`, labels, issue/discussion templates, and ledger thresholds exist and match locked rules. | docs-contract/static YAML checks + gh manual check | New `test/docs_contract/adoption_claims_test.exs` and `test/docs_contract/github_intake_claims_test.exs`; `gh label list`. | New tests needed. [ASSUMED: file names planner chooses] |

### Sampling Rate

- Per task commit: targeted docs-contract tests and `mix rendro.viewer_evidence validate` when matrix/evidence changes. [VERIFIED: 88-CONTEXT.md]
- Per wave merge: `mix docs.contract` and relevant guardrail tests. [VERIFIED: scripts/verify_docs.exs]
- Phase gate: `mix ci`, `mix docs.contract`, public URL checks, manual launch-copy review, and `gh` checks for labels/templates/Discussions state. [VERIFIED: mix.exs] [VERIFIED: gh api]

### Wave 0 Gaps

- Add static contract tests for `ADOPTION.md` section order, exact thresholds, ledger columns, empty states, README/comparison links, and banned overclaims. [VERIFIED: 88-UI-SPEC.md]
- Add static contract tests for `.github/ISSUE_TEMPLATE/01_bug.yml`, `02_blocked_document.yml`, `config.yml`, and optional `.github/DISCUSSION_TEMPLATE/use-cases.yml`. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository] [CITED: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms]
- Update hard-coded viewer evidence path tests and deferral mirror tests if mobile rows are added. [VERIFIED: test/docs_contract/viewer_evidence_claims_test.exs]
- Add launch checklist artifact or copy fixtures only if execution wants to keep announcement/reply drafts in repo; if not, manual launch review must be explicit in the plan. [ASSUMED]

## Security Domain

Security enforcement is enabled by default because `.planning/config.json` does not disable it. [VERIFIED: .planning/config.json]

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No runtime app auth in scope. | GitHub/ElixirForum/ElixirStatus auth is external platform behavior. [ASSUMED] |
| V3 Session Management | No application sessions in scope. | N/A. [ASSUMED] |
| V4 Access Control | Yes for repo settings/labels/templates. | Use authenticated maintainer `gh`/GitHub UI; do not store tokens. [VERIFIED: gh auth status] |
| V5 Input Validation | Yes for public intake forms and ADOPTION ledger. | GitHub YAML required fields plus maintainer review before `adoption:counted`. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms] |
| V6 Cryptography | Yes only as claims boundary. | Do not claim mobile signed-artifact cryptographic validation without observed `/Sig` trust UI. [VERIFIED: 88-CONTEXT.md] |
| V8 Data Protection | Yes for private adopter reports. | Anonymize private reports, cap counted private signals at 2 per window, and do not put confidential PDFs/secrets into evidence bodies. [VERIFIED: 88-CONTEXT.md] [VERIFIED: viewer evidence lint tests] |

Known threat patterns:

| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Accidental private data in evidence/ledger | Information Disclosure | Use source URLs or anonymized notes; evidence lint already rejects secrets/home paths/PEM/image embeds. [VERIFIED: test/docs_contract/viewer_evidence_claims_test.exs] |
| Fake/adversarial adoption signals | Tampering | Require concrete document job, source URL, requester/org grouping, and maintainer-applied `adoption:counted`. [VERIFIED: 88-CONTEXT.md] |
| Overclaiming compliance/signature trust | Repudiation/Information Disclosure | Keep PDF/A/PDF/UA/PAdES/mobile signed validation claims forbidden unless proof-backed. [VERIFIED: guides/api_stability.md] |
| Untrusted uploads through issue forms | Information Disclosure | Ask for minimal fixtures/repro notes and permission to quote/anonymize; do not require confidential uploads. [VERIFIED: 88-UI-SPEC.md] |

## Environment Availability

| Dependency | Required By | Available | Version/State | Fallback |
|------------|-------------|-----------|---------------|----------|
| Elixir | Tests/docs-contract | Yes | 1.19.5 / OTP 28 | None needed. [VERIFIED: elixir --version] |
| Mix | Tests/docs-contract | Yes | 1.19.5 | None needed. [VERIFIED: mix --version] |
| gh CLI | GitHub labels/issues/PRs/Discussions checks | Yes | 2.93.0, authenticated | GitHub UI for manual tasks. [VERIFIED: gh --version] |
| curl | Hex/public URL checks | Yes | 8.7.1 | Browser/manual check. [VERIFIED: curl --version] |
| jq | Hex API parsing | Yes | 1.7.1 | Elixir JSON decode or manual parse. [VERIFIED: jq --version] |
| GitHub Discussions | Use-case discussion intake | No | `has_discussions: false`, categories empty | Enable in repo settings/API before relying on template. [VERIFIED: gh api] |
| iOS device with Files/Preview | Mobile form/signed evidence | Not verified in research | Operator-owned | Use explicit deferral if proof cannot be completed. [ASSUMED] |
| Android device with Google Drive PDF viewer | Mobile form/signed evidence | Not verified in research | Operator-owned | Use explicit deferral if proof cannot be completed. [ASSUMED] |
| ElixirForum/ElixirStatus accounts | Posting | Not verified in research | External login needed | Manual maintainer action. [ASSUMED] |

Missing dependencies with no fallback:

- GitHub Discussions are disabled if Phase 88 requires Discussions to be active before launch; enablement is a repo-setting task. [VERIFIED: gh api]

Missing dependencies with fallback:

- Physical mobile viewer observations can fall back to `explicit_deferral` rows when proof IDs cannot all be completed. [VERIFIED: 88-CONTEXT.md]

## Planner Notes

- Plan Wave 1 as "readiness and publication gate": reconcile `CMP-03`, verify local Phase 86/87 artifacts, push/publish public GitHub/HexDocs, then verify public URLs. [VERIFIED: repo grep] [VERIFIED: curl HexDocs]
- Plan Wave 2 as "adoption ledger and intake": create labels, `ADOPTION.md`, README/comparison links, issue forms, config, optional discussion form after enabling Discussions, and docs-contract tests. [VERIFIED: gh label list] [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository] [CITED: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms]
- Plan Wave 3 as "mobile evidence": operator records iOS/Android form observations or defers; signed mobile rows likely defer; update support matrix, evidence files, API stability, CHANGELOG, and tests. [VERIFIED: 88-CONTEXT.md]
- Plan Wave 4 as "launch copy artifacts/checklist": store drafts or a checklist in planning artifacts, not source, unless user wants source-tracked launch copy. If source-tracked, keep it Markdown-only and docs-contractable. [ASSUMED]
- Plan Wave 5 as "execution": publish ElixirForum announcement, then ElixirStatus, awesome-elixir PR, demand-thread replies, mobile follow-up, and optional/later Show HN only after a no-signup try path is public. [VERIFIED: context] [CITED: Show HN guidelines]
- Do not count download growth until the launch snapshot row is recorded with exact `L` date and Hex downloads. Current research snapshot is pre-launch. [VERIFIED: curl Hex API]
- Do not make `adoption:counted` a default label. It is maintainer-applied only after ledger review. [VERIFIED: 88-CONTEXT.md]
- Do not update `.planning/STATE.md` or public requirements as part of research; planning should make state reconciliation explicit. [VERIFIED: user instruction]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact GitHub Discussions enablement path may be UI or API depending on repo settings. | Common Pitfalls / Environment | Planner may need a manual checkpoint. |
| A2 | Physical iOS/Android devices and app versions are operator-owned and not verified during research. | Environment | Mobile rows may become explicit deferrals instead of supported rows. |
| A3 | Launch copy drafts may be source-tracked or kept as planning artifacts; user has not locked storage location. | Planner Notes | Plan should choose one and keep public source clean. |
| A4 | ElixirForum/ElixirStatus posting accounts are available to the maintainer. | Environment | Launch execution could require manual login/setup. |

## Open Questions (RESOLVED)

1. Should Phase 88 create source-tracked launch copy files, or keep announcement/reply drafts in planning artifacts only?
   - What we know: UI-SPEC says primary surfaces are external posts and public Markdown/forms. [VERIFIED: 88-UI-SPEC.md]
   - Recommendation: keep final external posts as checklist/drafts in planning unless the user explicitly wants source-tracked launch artifacts. [ASSUMED]
   - RESOLVED: Plans store launch checklist and copy in `.planning/phases/88-launch-execution-demand-instrumentation/88-LAUNCH-CHECKLIST.md` and `88-LAUNCH-COPY.md`, not as public source files. Public source changes stay limited to proof, intake, support-boundary, and adoption-ledger surfaces. [VERIFIED: 88-01-PLAN.md] [VERIFIED: 88-05-PLAN.md]
2. Can GitHub Discussions be enabled before templates land?
   - What we know: live repo `has_discussions` is false and categories are empty. [VERIFIED: gh api]
   - Recommendation: add a manual/API checkpoint before committing or relying on `use-cases.yml`. [CITED: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms]
   - RESOLVED: Plan 03 creates the template but blocks until Discussions is enabled and `.has_discussions` is exactly `true`; if API enablement is insufficient, execution pauses for maintainer UI confirmation before launch replies route users there. [VERIFIED: 88-03-PLAN.md]
3. Will mobile form rows pass in the actual app versions on available devices?
   - What we know: Apple and Google document form-filling flows, but actual Rendro fixture behavior must be observed. [CITED: https://support.apple.com/guide/iphone/fill-out-and-sign-pdf-forms-iphd7e3c0c74/ios] [CITED: https://support.google.com/drive/answer/9463834?co=GENIE.Platform%3DAndroid&hl=en]
   - Recommendation: plan both supported and explicit-deferral branches for forms; signed rows are expected deferrals. [VERIFIED: 88-CONTEXT.md]
   - RESOLVED: Plan 04 records all four mobile observations in `88-LAUNCH-CHECKLIST.md` and branches each row to `supported` only when its proof IDs pass, otherwise to `explicit_deferral`; signed rows remain expected deferrals unless a real `/Sig` trust UI is observed. [VERIFIED: 88-04-PLAN.md]

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project constraints, stack, architecture, workflow. [VERIFIED: repo read]
- `.planning/phases/88-launch-execution-demand-instrumentation/88-CONTEXT.md` - locked Phase 88 decisions. [VERIFIED: repo read]
- `.planning/phases/88-launch-execution-demand-instrumentation/88-UI-SPEC.md` - UI/copy/intake contract. [VERIFIED: repo read]
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` - Phase 88 scope and CMP-03 mismatch. [VERIFIED: repo read]
- `.planning/research/*.md` and prior phase contexts/summaries 83-87 - inherited proof, claim, raster, comparison, and launch constraints. [VERIFIED: repo read]
- `priv/support_matrix.json`, schemas, `guides/viewer_evidence.md`, `guides/api_stability.md`, docs-contract tests - existing viewer-evidence architecture. [VERIFIED: repo grep]

### Current External (HIGH/MEDIUM confidence)

- ElixirForum demand threads and announcing category. [CITED: https://elixirforum.com/t/pdf-generation-without-chromium-dependency/68211] [CITED: https://elixirforum.com/t/looking-for-a-prawn-like-pdf-generation-library-in-elixir/67278] [CITED: https://elixirforum.com/c/news/announcing/159]
- ElixirStatus posting surface. [CITED: https://elixirstatus.com/]
- awesome-elixir PDF category. [CITED: https://github.com/h4cc/awesome-elixir]
- GitHub issue and discussion template docs. [CITED: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository] [CITED: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms]
- Hex package API. [CITED: https://hex.pm/api/packages/rendro]
- Apple iPhone Preview PDF form support page. [CITED: https://support.apple.com/guide/iphone/fill-out-and-sign-pdf-forms-iphd7e3c0c74/ios]
- Google Drive Android PDF form support page. [CITED: https://support.google.com/drive/answer/9463834?co=GENIE.Platform%3DAndroid&hl=en]
- Show HN guidelines. [CITED: https://news.ycombinator.com/showhn.html]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - repo stack and local tool versions verified. [VERIFIED: elixir --version; mix --version; gh --version; curl --version; jq --version]
- Architecture: HIGH - existing viewer-evidence/docs-contract patterns verified in source. [VERIFIED: repo grep]
- External surfaces: HIGH for availability; MEDIUM for exact posting UI details that require logged-in accounts. [CITED: https://elixirforum.com/c/news/announcing/159] [CITED: https://elixirstatus.com/] [CITED: https://github.com/h4cc/awesome-elixir] [ASSUMED: account-specific UI]
- Mobile evidence outcomes: MEDIUM - official mobile form docs exist, but actual Rendro fixtures need operator observation. [CITED: https://support.apple.com/guide/iphone/fill-out-and-sign-pdf-forms-iphd7e3c0c74/ios] [CITED: https://support.google.com/drive/answer/9463834?co=GENIE.Platform%3DAndroid&hl=en]

**Research date:** 2026-06-12
**Valid until:** 2026-06-19 for external/community surface state; repo-internal findings valid until Phase 88 planning edits begin.
