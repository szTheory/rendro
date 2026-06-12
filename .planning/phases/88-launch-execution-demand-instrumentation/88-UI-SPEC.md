---
phase: 88
slug: launch-execution-demand-instrumentation
status: approved
shadcn_initialized: false
preset: none
surface_type: launch-execution-and-adoption-instrumentation
created: 2026-06-12
reviewed_at: 2026-06-12T01:29:17Z
---

# Phase 88 - UI Design Contract

Visual, copy, and interaction contract for quiet public discovery surfaces,
mobile-viewer evidence publication, root `ADOPTION.md`, and GitHub issue-only
intake.

Superseding posture, 2026-06-12: Phase 88 is quiet public discoverability, not
a proactive launch campaign. Keep GitHub, HexDocs, proof links, ADOPTION.md,
and issue templates available, but do not require ElixirForum, ElixirStatus,
awesome-elixir, demand-thread, mobile follow-up, or Show HN publication unless
the maintainer explicitly opts into a new task.

This is not a web application UI phase. No client framework, shadcn,
third-party component registry, custom JavaScript, or marketing landing page is
in scope. The primary surfaces are Markdown, GitHub issue forms, HexDocs/GitHub
rendered docs, and `priv/support_matrix.json`.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Markdown / GitHub issue forms / ExDoc |
| Preset | not applicable |
| Component library | none |
| Icon library | none |
| Font | Host defaults for rendered Markdown/forms; Inter and JetBrains Mono only if new custom docs CSS is introduced later |
| Primary surfaces | README/HexDocs proof links, mobile evidence docs, `ADOPTION.md`, issue templates |
| Source of truth for claims | `priv/support_matrix.json`, checked-in evidence files, docs-contract tests, benchmark results, Livebook and guide links |
| Source of truth for gate rules | Root `ADOPTION.md` and Phase 88 context decisions D-24..D-38 |

Contract:

- Keep the quiet public surfaces plain and useful, not a marketing microsite.
- Public discovery should route to README, HexDocs, ADOPTION.md, and issue templates.
- GitHub issue forms are structured intake for adoption signals, not an app-like workflow.
- Public docs are the product UI for this phase. Every claim in public copy
  must have a checked-in proof or named boundary.
- No custom browser widgets, remote images, CDN assets, social embeds, or
  JavaScript interactivity are allowed.

---

## Launch Readiness Gate

Primary launch blocker:

`CMP-03` must be reconciled before any public announcement is published.
`STATE.md` and `ROADMAP.md` report Phase 87 complete, while
`.planning/REQUIREMENTS.md` still marks `CMP-03` pending. Phase 88 execution
must make this mismatch visible in plan tasks and must not treat launch posts
as ready until the source-of-truth state is consistent.

Required readiness checklist presentation:

| Gate | Required display text | Pass condition |
|------|-----------------------|----------------|
| Claim accuracy | `Claim-accuracy fixes are shipped` | HYG-01..05 complete in requirements and docs |
| Gallery/manual | `Launch artifacts are published and byte-checked` | GAL-01..03 complete and public links work |
| Comparison/Livebook | `Comparison guide and Livebook are live` | CMP-01..03 complete or explicitly reconciled |
| Mobile evidence | `Mobile evidence outcome is recorded` | LNCH-02 rows are supported or explicitly deferred |
| Adoption ledger | `Adoption signal ledger is ready` | `ADOPTION.md` exists with thresholds and empty-state rows |

Launch gate visual hierarchy:

1. Show blocked gates first.
2. Use explicit text labels: `Ready`, `Blocked`, `Deferred with reason`.
3. Never rely on color alone.
4. Do not use celebratory launch copy until all required gates are ready.

---

## Launch Hub

Canonical hub:

`ElixirForum News > Announcing`

Required title:

`Rendro: Elixir-native PDF layout without Chrome`

Required structure:

1. What Rendro is.
2. Why it exists.
3. What works today.
4. Proof links.
5. Honest boundaries.
6. Feedback request.

First-mention sentence:

`Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome.`

Proof-link cluster:

- Rendered gallery/manual and manual SHA.
- Comparison guide.
- First-invoice Livebook.
- Support matrix or API stability guide.

Do not lead with benchmark victory language. Use `measured tradeoffs`,
`without Chrome`, `proof-backed`, `bounded support`, and `for Phoenix teams`.

Avoid:

- `Prawn equivalent`
- `HTML-to-PDF`
- `PDF/A compliant`
- `PDF/UA compliant`
- `works in every viewer`
- `mobile PDF support`
- broad complex-script support claims
- attack language about ChromicPDF, Gotenberg, Typst, or pdf_generator

---

## Channel Contracts

| Channel | UI/copy contract | Link budget |
|---------|------------------|-------------|
| ElixirForum announcement | Canonical long-form hub; calm maintainer voice; proof links before roadmap asks | 4-6 links maximum |
| ElixirStatus | Short post linking to the forum announcement, HexDocs, and Livebook | 3 links maximum |
| awesome-elixir PR | Concise source-repo wording under `PDF`, alphabetically sorted | 1 repo link |
| Chromium demand thread | `for future readers` framing; disclose `Disclosure: I maintain Rendro.` near the top | 3 links maximum |
| Prawn-like demand thread | Native-Elixir fit language; not a Prawn clone; fair alternatives named | 3 links maximum |
| Mobile evidence follow-up | Title: `What happens when a Rendro PDF reaches a phone?` | Forum hub plus evidence docs |
| Show HN | Optional/later only when try path is frictionless and maintainer is available | Repo, Livebook, docs |

Demand-thread interaction rules:

- Reply only after the canonical announcement is live.
- Answer the original constraint before naming Rendro.
- Name alternatives generously where true.
- Route concrete unsupported documents to GitHub Discussions/issues and
  `ADOPTION.md`.
- Do not duplicate the announcement body.

---

## Mobile Evidence Beat

Required content title:

`What happens when a Rendro PDF reaches a phone?`

Core message:

Simple AcroForm rows can be manually proven per viewer; signed PDFs require a
real validation surface; Rendro records both outcomes in the support matrix.

Do not use the blanket phrase `mobile PDF support`.

Required evidence rows:

| Surface | Viewer key | Public viewer name | Expected outcome |
|---------|------------|--------------------|------------------|
| forms | `ios_files_preview` | `iOS Files/Preview` | `supported` only if all proof IDs pass |
| forms | `android_drive_viewer` | `Google Drive PDF viewer on Android` | `supported` only if all proof IDs pass |
| signed_artifact | `ios_files_preview` | `iOS Files/Preview` | expected `explicit_deferral` unless full trust UI is observed |
| signed_artifact | `android_drive_viewer` | `Google Drive PDF viewer on Android` | expected `explicit_deferral` unless full trust UI is observed |

Form proof IDs:

- `open`
- `default_state_visible`
- `edit_or_toggle`
- `save`

Evidence publication hierarchy:

1. `priv/support_matrix.json` terminal row.
2. Evidence file for supported rows under `priv/viewer_evidence/<surface>/<viewer>.md`.
3. `guides/api_stability.md` mirrors supported paths and deferral reasons.
4. `CHANGELOG.md` records public support-contract changes.
5. Launch follow-up links to the guide/matrix, not raw claims.

Signed-artifact deferral wording must distinguish drawn or Markup signatures
from `/Sig` cryptographic validation. Android deferral wording must name the
absent integrity, certificate-trust, or timestamp validation panel.

---

## Adoption Ledger

Path:

`ADOPTION.md` at repository root.

Required section order:

1. `# Adoption Signals`
2. `## Purpose`
3. `## Current Gate: v2.7 Global Text Shaping`
4. `## Gate Thresholds`
5. `## Discovery Baseline`
6. `## Signal Ledger`
7. `## Download Snapshots`
8. `## External Contributors`
9. `## Review Log`

Primary focal point:

The `Gate Thresholds` section must be the first dense information surface. It
should let a maintainer decide whether v2.7 text shaping is still blocked,
eligible for review, or triggered without reading the full ledger.

Threshold presentation:

| Threshold | Required copy |
|-----------|---------------|
| Demand | `6 qualifying text-shaping signals in a rolling 90-day window, from at least 4 distinct non-maintainer requesters and at least 3 distinct orgs/apps. At least 3 must block production or evaluation.` |
| Downloads | `Since discovery baseline, Hex downloads.all increases by at least 1,500 and downloads.week >= 150 on two snapshots at least 14 days apart after the baseline.` |
| Contributor | `At least 1 merged, non-maintainer PR after discovery baseline that materially improves code, tests, docs, examples, fixtures, or a reproducible failing case.` |

Signal ledger columns:

`ID | Date | Source URL | Channel | Requester | Org/App | Gate Area | Script/Language | Document Job | Blocking? | Qualifies? | Count Group | Notes`

Empty-state copy:

| Location | Copy |
|----------|------|
| Signal Ledger | `No qualifying shaping signals have been counted yet. Open a blocked-document issue with a concrete document job, script/language, current blocker, and source URL.` |
| Download Snapshots | `No post-baseline Hex download snapshots recorded yet. Add future snapshots only when reviewing inbound signal volume or planning a future milestone.` |
| External Contributors | `No qualifying non-maintainer contributor signal has been counted yet.` |
| Review Log | `No gate reviews have run yet. Reviews are pull-based: run one when qualifying issues exist or during future milestone planning.` |

Do not count reactions, stars, forks, `+1`, generic i18n wishes, or social
posts as shaping signals.

---

## GitHub Intake

Discussion template:

`.github/DISCUSSION_TEMPLATE/use-cases.yml`

Discussion category:

`Use cases`

Discussion form fields must ask for:

- document type
- Phoenix/Elixir context
- current blocker
- script/language
- workaround
- whether production or evaluation is blocked

Issue templates:

| File | Purpose | Default labels |
|------|---------|----------------|
| `.github/ISSUE_TEMPLATE/01_bug.yml` | Reproducible defects | `state:triage`, `kind:bug` |
| `.github/ISSUE_TEMPLATE/02_blocked_document.yml` | Concrete unsupported document jobs and adoption signals | `state:triage`, `adoption:signal` |
| `.github/ISSUE_TEMPLATE/config.yml` | Disable blank issues and route discovery | not applicable |

Blocked-document issue form fields must collect:

- document job
- expected PDF behavior
- current Rendro blocker
- script/language when text shaping is involved
- whether production or evaluation is blocked
- workaround or current alternative
- minimal fixture or reproduction notes
- source URL or private-report note
- permission to quote/anonymize if private

Issue form copy rules:

- Use `Report blocked document` or `Describe blocked document`, not `Submit`.
- Use `Open bug report`, not `Submit`.
- Use `Start use-case discussion`, not `Post`.
- `adoption:counted` is never a default label; it is maintainer-applied only
  after ledger review.

Label vocabulary:

`state:triage`, `kind:bug`, `kind:enhancement`, `kind:docs`,
`area:text-shaping`, `area:viewer-evidence`, `area:phoenix`,
`adoption:signal`, `adoption:counted`, `adoption:duplicate`,
`adoption:private`, `help wanted`, `good first issue`

---

## Spacing Scale

Declared values:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline punctuation gaps, compact labels when Markdown/HTML allows |
| sm | 8px | Adjacent proof links, issue-form helper text rhythm |
| md | 16px | Default paragraph-to-list and list-to-table rhythm |
| lg | 24px | Section-local separation in Markdown docs |
| xl | 32px | Major document sections such as launch snapshot to ledger |
| 2xl | 48px | Public-doc top-level breaks when custom docs CSS exists |
| 3xl | 64px | Reserved for future landing pages, not used in Phase 88 |

Exceptions: none.

Host-rendered Markdown and GitHub forms control their own physical spacing.
When Phase 88 introduces manual Markdown/HTML spacing, it must map to the
tokens above and must not introduce ad hoc values outside this table.

---

## Typography

Use host Markdown typography on GitHub, ElixirForum, ElixirStatus, and ExDoc.
Do not inject custom font loading for Phase 88.

If authored HTML/CSS is introduced in docs, use only this type contract:

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Caption | 12px | 400 | 1.5 |
| Label | 14px | 600 | 1.4 |
| Body | 16px | 400 | 1.6 |
| Heading | 20px | 600 | 1.3 |

Allowed font weights: 400 and 600.

Copy hierarchy:

- Channel posts use short paragraphs and scannable bullets.
- `ADOPTION.md` uses tables for thresholds, ledgers, snapshots, and review
  history.
- Issue/discussion forms use direct labels, one helper sentence per field, and
  no marketing copy inside forms.
- Code identifiers, labels, file paths, and commands use inline code.

Avoid huge SaaS hero typography, decorative type, negative letter spacing, and
monospace prose.

---

## Color

Use the Rendro brand palette only where Phase 88 introduces custom docs or
status treatment. Host surfaces may use their native link and text colors.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | sheet-000 `#FFFFFF` / paper-100 `#F7F3EA` | Markdown surface, public docs background, evidence tables |
| Secondary (30%) | ink-900 `#101827`, ink-700 `#1F2937`, line-300 `#D8D2C3` | Text, captions, borders, dividers |
| Accent (10%) | blue-600 `#2C6BED` | Primary proof links, forum hub link, Livebook link, active evidence references |
| Destructive | red-700 `#C24132` | Blocked launch gates and validation errors only |

Accent reserved for:

- the canonical ElixirForum hub link
- proof artifact links
- Livebook try path
- active/readiness states when paired with text labels
- focused links/buttons if custom docs CSS exists later

Accent is not for all interactive elements. Use text labels for status:
`Ready`, `Blocked`, `Deferred with reason`, `Counted`, `Does not qualify`.

Warning/caveat treatment:

- Use amber only as a labeled caveat or border/background accent, never as
  small body text on white.
- Complex-script, mobile-signature, and HTML/CSS limitations must be visible
  in prose, not color-only warnings.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| First mention | `Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome.` |
| Primary CTA | `Try the first-invoice Livebook` |
| Announcement feedback CTA | `Share a document Rendro cannot handle yet` |
| Demand-thread disclosure | `Disclosure: I maintain Rendro.` |
| Mobile evidence title | `What happens when a Rendro PDF reaches a phone?` |
| Adoption ledger CTA | `Record adoption signal` |
| Blocked-document issue CTA | `Describe blocked document` |
| Bug issue CTA | `Open bug report` |
| Discussion CTA | `Start use-case discussion` |
| Empty state heading | `No qualifying shaping signals yet` |
| Empty state body | `Open a blocked-document issue or use-case discussion with a concrete document job, script/language, current blocker, and source URL.` |
| Error state | `Launch is blocked until CMP-03 is reconciled and all required proof links are public. Update the requirements traceability, verify the Livebook link, then re-run the launch checklist.` |
| Destructive confirmation | `none - Phase 88 introduces no destructive UI actions` |

Required phrases:

- `for future readers`
- `Disclosure: I maintain Rendro.`
- `measured in this harness`
- `bounded by priv/support_matrix.json`
- `explicit deferral`
- `not HTML-to-PDF`
- `without Chrome`

Avoid these generic or overbroad labels:

- `Submit`
- `OK`
- `Click here`
- `Save`
- `Cancel`
- `mobile PDF support`
- `Prawn equivalent`
- `browserless viewer`
- `works everywhere`

---

## Accessibility

- Every table must have a header row.
- Status must be conveyed by text, not color alone.
- Links must be meaningful out of context: use `first-invoice Livebook`, not
  `here`.
- Form fields need specific labels and helper text. Required fields should be
  explicit in the GitHub form schema.
- Markdown images, if any are added in launch content, must have descriptive
  alt text. Do not use decorative screenshots in Phase 88.
- Long tables in `ADOPTION.md` should stay plain Markdown so they remain
  readable in GitHub's mobile layout.
- Do not suppress host focus outlines or introduce hover-only disclosure.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable |
| third-party registries | none | not applicable |

No third-party UI block, JavaScript widget, remote badge generator, CDN asset,
custom analytics snippet, or social embed is allowed for Phase 88.

---

## UI Verification

Required source assertions:

- `ADOPTION.md` exists at repo root with the required section order.
- `ADOPTION.md` contains the numeric demand, download, and contributor
  thresholds.
- `ADOPTION.md` contains the exact signal ledger columns.
- `.github/ISSUE_TEMPLATE/01_bug.yml`,
  `.github/ISSUE_TEMPLATE/02_blocked_document.yml`, and
  `.github/ISSUE_TEMPLATE/config.yml` exist.
- The blocked-document issue template defaults to `state:triage` and
  `adoption:signal`; it does not default to `adoption:counted`.
- If Discussions are enabled, `.github/DISCUSSION_TEMPLATE/use-cases.yml`
  exists and asks for document type, context, blocker, script/language,
  workaround, and production/evaluation impact.
- `priv/support_matrix.json` contains terminal rows for the Phase 88 mobile
  evidence set, either `supported` with evidence paths or
  `explicit_deferral` with named reasons.
- `guides/api_stability.md` mirrors mobile supported paths and signed-artifact
  deferral reasons.
- `CHANGELOG.md` records support-matrix public-contract changes.
- Launch copy does not publish until the `CMP-03` traceability mismatch is
  reconciled.

Manual review before public posting:

- Read the ElixirForum announcement as rendered Markdown and confirm proof
  links are visible before roadmap/demand asks.
- Read each demand-thread reply and confirm it answers the original constraint,
  names alternatives fairly, includes maintainer disclosure, and stays within
  the three-link budget.
- Read the mobile evidence follow-up and confirm it does not say
  `mobile PDF support`.
- Read `ADOPTION.md` on GitHub mobile width and confirm the threshold summary
  is understandable before the full ledger.

---

## Anti-Patterns

Do not implement:

- A README hero banner or landing-page composition for this phase.
- Browser chrome, printer, Acrobat-red, prepress, CHILI/spice, or generic PDF
  icon visual language.
- A broad launch blitz before the ElixirForum hub exists.
- Anonymous, neutral-sounding, or third-party-seeded demand-thread replies.
- Winner language against ChromicPDF, Gotenberg, Typst, or pdf_generator.
- Any support claim not backed by `priv/support_matrix.json` and evidence or
  an explicit deferral.
- Any required CI dependency on manual mobile viewer proof.
- GitHub Projects or labels-only tracking as the Phase 88 adoption system.
- Blanket text-shaping or RTL claims.
- Third-party registries, widgets, analytics snippets, or embeds.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-06-12
