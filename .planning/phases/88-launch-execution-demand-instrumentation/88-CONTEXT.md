# Phase 88: Launch Execution & Demand Instrumentation - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver Phase 88 `LNCH-01..03`: Rendro becomes visible to the Elixir community through a proof-backed public launch, honest mobile viewer evidence is recorded as a launch-adjacent content beat, and the conditional v2.7 text-shaping gate becomes concrete enough to review without re-litigating "adopter demand."

This phase does not add rendering capability. It coordinates already-shipped v2.6 truth fixes, visual proof, raster proof, comparison guide, and Livebook into public launch execution and demand instrumentation.

</domain>

<decisions>
## Implementation Decisions

### Launch Choreography
- **D-01:** Use an **Elixir-first proof hub** launch, not a same-day broad blitz. Publish the canonical ElixirForum announcement first, then post ElixirStatus, open the awesome-elixir PR, reply to the two demand threads, publish mobile evidence as a follow-up, and treat Show HN as optional/later.
- **D-02:** The ElixirForum announcement is the canonical launch hub. Shorter channels link back to it rather than creating parallel long-form launch narratives.
- **D-03:** Do not launch until public Hex/HexDocs/GitHub state contains the HYG/GAL/CMP artifacts, including the Livebook. Planning/execution must reconcile the current status mismatch first: `.planning/REQUIREMENTS.md` still shows `CMP-03` pending while `.planning/STATE.md` and `.planning/ROADMAP.md` say Phase 87 is complete.
- **D-04:** Announcement title shape: `Rendro: Elixir-native PDF layout without Chrome`. Use ElixirForum `News > Announcing`; tags should include `library` and `pdf` if available.
- **D-05:** Announcement structure: what Rendro is, why it exists, what works today, proof links, honest boundaries, and feedback request. Lead with gallery/manual SHA/Livebook/comparison and support boundaries, not benchmark victory language.
- **D-06:** Allowed core claim: "Rendro is an open-source, Elixir-native PDF layout library for Phoenix teams that need reliable PDFs without Chrome." Avoid "Prawn equivalent", "HTML-to-PDF", "PDF/A compliant", "PDF/UA compliant", broad viewer support, and broad complex-script claims.
- **D-07:** ElixirStatus post follows immediately after the forum thread. Keep it short and link to the forum announcement, HexDocs, and Livebook.
- **D-08:** awesome-elixir PR follows once public docs are live. Add Rendro under `PDF`, alphabetically sorted, with concise source-repo wording: `Rendro - Elixir-native PDF layout library with deterministic pagination and no browser runtime.`
- **D-09:** Show HN is optional and later. Use only when GitHub/HexDocs/Livebook provide a no-signup try path and a maintainer can answer comments live. Title shape: `Show HN: Rendro - Native PDF layout for Elixir without Chrome`.

### Demand-Thread Posture
- **D-10:** Reply to the two existing ElixirForum demand threads only after the canonical announcement is live. Order: `PDF generation without Chromium dependency`, then `Looking for a Prawn-Like PDF Generation Library in Elixir`.
- **D-11:** Frame both replies as "for future readers" and disclose maintainer status near the top: `Disclosure: I maintain Rendro.` Do not write as a neutral third party, ask others to seed replies, or duplicate the announcement body.
- **D-12:** Use decision-guide language, not winner language. Rendro fits business documents authored from Elixir data; ChromicPDF/Gotenberg fit HTML/CSS and browser print fidelity; pdf_generator fits existing wkhtmltopdf/chrome-headless workflows; Typst fits teams that want `.typ` templates and Typst's layout language.
- **D-13:** Use at most three links per demand-thread reply: public repo/HexDocs, comparison guide, and first-invoice Livebook. Avoid raw benchmark tables in forum replies; link to the reproducible guide instead.
- **D-14:** Route broad fit discussion in the forum, but route concrete unsupported documents, benchmark challenges, and feature requests to GitHub Discussions/issues and `ADOPTION.md` counting rules.

### Mobile Viewer Evidence Beat
- **D-15:** Use the balanced four-row mobile evidence set: iOS Files/Preview and Google Drive PDF viewer on Android across `forms` and `signed_artifact`.
- **D-16:** Add `forms.viewers.ios_files_preview` with viewer name `iOS Files/Preview`, proof IDs `open`, `default_state_visible`, `edit_or_toggle`, `save`, and evidence path `priv/viewer_evidence/forms/ios_files_preview.md` if all checks pass. Matrix row uses `status: "supported"`, `viewer_kind: "manual"`, and exact `recorded_at`. If any proof fails, use `explicit_deferral` and no evidence file.
- **D-17:** Add `forms.viewers.android_drive_viewer` with viewer name `Google Drive PDF viewer on Android`, the same four form proof IDs, and evidence path `priv/viewer_evidence/forms/android_drive_viewer.md` if all checks pass. Matrix policy matches D-16.
- **D-18:** Add `signing.viewers.ios_files_preview` as an expected `explicit_deferral` for the `signed_artifact` evidence surface unless it unexpectedly passes the full signed-artifact proof gate. Deferral must distinguish drawn/Markup signatures from `/Sig` cryptographic validation.
- **D-19:** Add `signing.viewers.android_drive_viewer` as an expected `explicit_deferral` for `signed_artifact`. The deferral reason should name the absent signed-artifact trust UI: no observed integrity, certificate-trust, or timestamp validation panel for the representative signed fixture.
- **D-20:** Do not add `ios_mail_preview` in LNCH-02. Treat Mail as a delivery/handoff note inside `ios_files_preview` evidence, for example "fixture delivered via Mail, saved/opened in Files/Preview, then checked." Add a Mail viewer row later only if all proof IDs can be completed inside Mail attachment preview itself.
- **D-21:** Content beat title shape: "What happens when a Rendro PDF reaches a phone?" Core message: simple AcroForm rows can be manually proven per viewer; signed PDFs need a real validation surface; Rendro records both outcomes in the support matrix. Avoid the blanket phrase "mobile PDF support."
- **D-22:** Update `guides/api_stability.md` with the supported mobile form evidence paths and signed deferral reasons; update `CHANGELOG.md` because support-matrix changes are public-contract changes; update hard-coded docs-contract path/count tests.
- **D-23:** Verification commands for mobile evidence work:
  - `mix rendro.viewer_evidence validate`
  - `mix rendro.viewer_evidence list`
  - `mix test test/docs_contract/viewer_evidence_claims_test.exs test/docs_contract/forms_claims_test.exs test/docs_contract/signing_claims_test.exs test/docs_contract/raster_claims_test.exs`
  - `mix docs.contract`

### Adoption Gate and Routing
- **D-24:** Put `ADOPTION.md` at the repository root. It is a public product/roadmap surface, not private planning. Link it from README, the comparison guide limitation block, issue/discussion templates, and launch replies.
- **D-25:** `ADOPTION.md` shape:
  - `# Adoption Signals`
  - `## Purpose`
  - `## Current Gate: v2.7 Global Text Shaping`
  - `## Gate Thresholds`
  - `## Launch Snapshot`
  - `## Signal Ledger`
  - `## Download Snapshots`
  - `## External Contributors`
  - `## Review Log`
- **D-26:** Signal ledger columns: `ID | Date | Source URL | Channel | Requester | Org/App | Gate Area | Script/Language | Document Job | Blocking? | Qualifies? | Count Group | Notes`.
- **D-27:** v2.7 gate triggers only when all three thresholds are met:
  - Demand: 6 qualifying text-shaping signals in a rolling 90-day window, from at least 4 distinct non-maintainer requesters and at least 3 distinct orgs/apps. At least 3 must be blocking production/evaluation, not curiosity.
  - Downloads: since launch snapshot, Hex `downloads.all` increases by at least 1,500 and `downloads.week >= 150` on two snapshots at least 14 days apart after launch week.
  - Contributor: at least 1 merged, non-maintainer PR after launch that materially improves code, tests, docs, examples, fixtures, or a reproducible failing case. Typos, bots, Dependabot, and maintainer alternate accounts do not count.
- **D-28:** Count one shaping signal only when it names a concrete document job, script/language, current blocker, and source URL. Same requester/org/use case counts once per 90-day window. Reactions, stars, forks, `+1`, "please support Arabic", social posts, and generic i18n wishes do not count. Private adopter reports may be anonymized but cap at 2 counted signals per window.
- **D-29:** Text-shaping signals count for v2.7 only when they require shaping/RTL/cluster behavior beyond current support: Arabic, Hebrew/RTL, Devanagari, Thai, bidi ordering, cluster-aware line breaking, or copy/paste extraction issues. Font installation, arbitrary HTML/CSS rendering, viewer bugs, and PDF/A/PDF/UA asks route elsewhere.
- **D-30:** Review cadence: define `L` as the launch-thread date. Triage inbound twice weekly for the first 30 days, then weekly. Gate reviews happen at `L+30`, `L+60`, `L+90`, then monthly using the rolling 90-day window. The gate cannot trigger before `L+45`.
- **D-31:** Enable GitHub Discussions with `Announcements`, `Q&A`, and `Use cases` if available. Add `.github/DISCUSSION_TEMPLATE/use-cases.yml` for `Use cases`, asking for document type, Phoenix/Elixir context, blocker, script/language, workaround, and whether production/evaluation is blocked. Discussions are discovery; scoped work becomes an issue.
- **D-32:** Add only these issue templates for Phase 88:
  - `.github/ISSUE_TEMPLATE/01_bug.yml`
  - `.github/ISSUE_TEMPLATE/02_blocked_document.yml`
  - `.github/ISSUE_TEMPLATE/config.yml` with `blank_issues_enabled: false` and contact links to Discussions and ElixirForum.
- **D-33:** Default labels for the blocked-document form: `state:triage` and `adoption:signal`. The maintainer manually adds `adoption:counted` after reviewing against the gate.
- **D-34:** Label set: `state:triage`, `kind:bug`, `kind:enhancement`, `kind:docs`, `area:text-shaping`, `area:viewer-evidence`, `area:phoenix`, `adoption:signal`, `adoption:counted`, `adoption:duplicate`, `adoption:private`, `help wanted`, `good first issue`.
- **D-35:** Review workflow commands:
  ```sh
  curl -fsSL https://hex.pm/api/packages/rendro | jq '.downloads'

  gh issue list --state all --label "adoption:signal" \
    --json number,title,author,createdAt,url,labels

  gh issue list --state all --label "area:text-shaping" \
    --json number,title,author,createdAt,url,labels

  gh pr list --state merged --search "merged:>=$LAUNCH_DATE -author:szTheory" \
    --json number,title,author,mergedAt,url
  ```
  Use the GitHub UI for low-volume Discussions; use `gh api graphql` only if volume justifies it.

### the agent's Discretion
- Exact final prose for the announcement and replies is left to execution, provided it follows the locked structure, disclosure, link policy, and brand voice.
- Exact issue-form field wording and label colors are discretionary. Preserve the template set, counting rules, and default labels.
- Exact mobile observation notes are operator-owned. Preserve the proof IDs, viewer keys, evidence paths, and deferral policy.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Authoritative Scope
- `.planning/ROADMAP.md` — Phase 88 goal, dependencies, success criteria, and active milestone progress.
- `.planning/REQUIREMENTS.md` — `LNCH-01..03` requirement text and v2.6 traceability. Also contains the `CMP-03` pending mismatch that must be reconciled before launch.
- `.planning/STATE.md` — current GSD state, Phase 88 readiness, and prior-phase completion state.

### Prior Phase Decisions
- `.planning/phases/87-comparison-page-livebook/87-CONTEXT.md` — fair comparison framing, Livebook posture, benchmark claim boundaries, and advisory-lane split.
- `.planning/phases/86-self-proving-launch-artifacts/86-CONTEXT.md` — gallery/manual proof posture, generated docs blocks, brand presentation, and required/advisory verification split.
- `.planning/phases/85-deterministic-raster-lane/85-VERIFICATION.md` — verified raster lane closure and `pdfium-render`/GUI-viewer boundary.
- `.planning/phases/85-deterministic-raster-lane/85-06-SUMMARY.md` — advisory raster/GUI-row separation and adapter hardening.
- `.planning/phases/84-drawn-path-primitive-visible-polish/84-CONTEXT.md` — visible polish constraints and brand-aligned document preview decisions.
- `.planning/phases/83-claim-accuracy-shaping-hygiene/83-CONTEXT.md` — claim-accuracy, shaping-boundary, and complex-script deferral decisions; must be respected in launch copy.

### v2.6 Research
- `.planning/research/SUMMARY.md` — adoption invisibility, launch/adoption milestone rationale, and conditional v2.7 scope.
- `.planning/research/FEATURES.md` — adoption playbooks, launch channels, mobile evidence as content, and demand-gate framing.
- `.planning/research/PITFALLS.md` — Phase 88 footguns: launching before truth fixes, astroturf perception, vague gates, and maintainer responsiveness debt.
- `.planning/research/ARCHITECTURE.md` — Phase 88 integration point: root or planning `ADOPTION.md`, GitHub intake, and zero-new-machinery mobile evidence.
- `.planning/research/JTBD-USER-FLOWS.md` — primary personas and launch-evaluation jobs.
- `.planning/research/STACK.md` — Elixir ecosystem release/tooling norms and external-tool boundaries.

### Brand and Product Direction
- `prompts/Rendro Brand Book.txt` — launch voice, first-mention rule, limitations copy, brand posture, and UI/content microcopy constraints.
- `prompts/rendro-oss-dna.md` — docs-contract discipline, advisory-vs-required verification, optional dependency boundaries, and proof-backed claims.
- `prompts/rendro-gsd-seed.md` — project thesis and pure-core/Phoenix-first boundaries.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Phoenix persona/JTBD, ecosystem lessons, scope boundaries, and "do not say too early" constraints.
- `prompts/rendro-integration-opportunities.md` — Phoenix SaaS/user-flow adjacency and optional-integration posture.

### Current Code Touchpoints
- `README.md` — launch-artifact block, guide links, and first-screen positioning.
- `guides/comparison.md` — fair comparison guide and bounded benchmark claims.
- `guides/livebook/first_invoice.livemd` — no-signup try path for launch and Show HN readiness.
- `guides/viewer_evidence.md` — manual evidence recording recipe and promotion/deferral rules.
- `guides/api_stability.md` — public support-boundary guide that must mirror new mobile evidence paths and deferral reasons.
- `priv/support_matrix.json` — public support contract to extend with mobile rows.
- `priv/schemas/support_matrix.schema.json` — status, `viewer_kind`, and evidence-path structural contract.
- `priv/schemas/viewer_evidence.schema.json` — evidence frontmatter contract for manual rows.
- `priv/viewer_evidence/_template.md` — canonical evidence file shape.
- `lib/mix/tasks/rendro/viewer_evidence.ex` — viewer-evidence operator tooling and supported workflow.
- `lib/rendro/viewer_evidence/validator.ex` — validation and orphan/promotion checks.
- `test/docs_contract/viewer_evidence_claims_test.exs` — docs-contract guard for evidence paths, guide mirrors, and deferral reasons.
- `test/docs_contract/forms_claims_test.exs` — form support claims lane affected by mobile form rows.
- `test/docs_contract/signing_claims_test.exs` — signed-artifact and trust-sensitive claims lane affected by mobile deferrals.
- `test/docs_contract/raster_claims_test.exs` — raster/GUI boundary lane that must remain separate from mobile manual rows.
- `priv/guardrails/required_status_checks.json` — required/advisory CI split; do not add mobile manual evidence to required live CI.
- `.github/workflows/ci.yml` — existing advisory contexts and absence of issue/discussion templates.
- `.github/ISSUE_TEMPLATE/` — does not currently exist; Phase 88 creates the minimal issue intake.
- `.github/DISCUSSION_TEMPLATE/` — does not currently exist; Phase 88 creates the use-case discussion template only if Discussions are enabled.
- `CHANGELOG.md` — support-matrix contract changes should be recorded here.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix rendro.viewer_evidence list|missing|validate|record` already provides the operator workflow and validation semantics for support-matrix rows.
- `priv/support_matrix.json` already has 26 terminal viewer cells and no unverified cells; mobile additions should preserve terminal-state discipline.
- `guides/viewer_evidence.md` already defines manual evidence, automated structural evidence, and matrix-vs-evidence separation. Reuse this instead of inventing a mobile-specific process.
- `test/docs_contract/viewer_evidence_claims_test.exs` already enforces schema, orphan checks, promotion completeness, guide mirrors, and deferral reason mirroring.
- `README.md`, `guides/comparison.md`, and `guides/livebook/first_invoice.livemd` are already launch-ready destinations for the announcement and short-channel links.
- `.github/workflows/ci.yml` and `priv/guardrails/required_status_checks.json` already model graph-disconnected advisory work. Mobile manual evidence should not become a required live CI dependency.

### Established Patterns
- Public claims are contracts. Copy must be bounded to support-matrix rows, benchmark claim citations, and checked-in artifacts.
- Deterministic/static proof belongs in required docs-contract lanes; manual viewer evidence and external-tool proof stay advisory or operator-owned.
- Evidence vocabulary is specific. `pdfium-render`, `pdfium-cli`, GUI/manual mobile viewers, and browser/Chrome support are not interchangeable.
- Elixir ecosystem launch posture rewards direct, useful, transparent maintainer communication more than broad marketing blasts.
- Root-level public docs are appropriate when adopters need to understand roadmap gates; `.planning/` is for internal planning state.

### Integration Points
- `ADOPTION.md` at repo root becomes the public ledger and should be linked from README, comparison guide, launch posts, and intake templates.
- `.github/ISSUE_TEMPLATE/02_blocked_document.yml` is the primary structured intake for concrete adoption signals.
- `.github/DISCUSSION_TEMPLATE/use-cases.yml` is the low-pressure discovery path when users are not ready to file scoped work.
- `guides/api_stability.md` and `CHANGELOG.md` must be updated with mobile evidence/deferral changes.
- The ElixirForum announcement thread becomes the canonical community hub and the place to post the mobile evidence follow-up.

</code_context>

<specifics>
## Specific Ideas

### Demand Thread Reply Skeletons

Chromium-dependency thread:

> Adding a current option for people who land here later. Disclosure: I maintain Rendro.
>
> For the specific "server-side PDF without Chromium/wkhtmltopdf" case, Rendro is an open-source, Elixir-native PDF layout library. It builds PDFs from Elixir data/components, with deterministic output, pagination, tables, page numbers, telemetry, and no Chrome/Node/wkhtmltopdf runtime in core.
>
> I would still choose ChromicPDF/Gotenberg when HTML/CSS or browser print fidelity is the source of truth; pdf_generator can still make sense for an existing wkhtmltopdf/chrome-headless workflow; and I would keep Typst if your team likes `.typ` templates. Rendro's narrower fit is business documents authored from Elixir data.
>
> Limits: Rendro is not HTML-to-PDF, and complex-script/RTL support is bounded by the support matrix. Unsupported shaping cases fail explicitly rather than silently producing broken output. Links: comparison guide, first-invoice Livebook, and repo/HexDocs. If anyone has a document shape Rendro cannot handle, please open a GitHub Discussion/issue with a small sample; I am using those as adoption signals for what to build next.

Prawn-like thread:

> Adding one newer native-Elixir option for future readers. Disclosure: I maintain Rendro.
>
> Rendro is not a Prawn clone, but it is aimed at the same explicit document-generation job: build PDFs from Elixir data, not HTML. Current fit: invoices, statements, reports, certificates, flow + fixed-position APIs, page templates/regions, tables with repeated headers and opt-in rules, fonts/images, page numbers, deterministic renders, diagnostics, and telemetry. There is a rendered gallery/manual and a first-invoice Livebook.
>
> I would not use it if your source is existing HTML/CSS; ChromicPDF, pdf_generator, Gotenberg, or WeasyPrint are more natural there. I would also keep Typst when the team wants Typst templates and Typst's layout language. PrawnEx is worth checking too if you want a more directly Prawn-styled API.
>
> Rendro's complex-script/RTL support is intentionally bounded today. The comparison guide and support matrix call out current limits. Specific missing document cases are best as GitHub Discussions/issues so they do not get lost in this thread.

### External References Consulted During Discussion
- `https://elixirforum.com/t/pdf-generation-without-chromium-dependency/68211` — existing demand thread where a later participant shared a Gotenberg setup; useful reply posture is concrete and helpful, not promotional.
- `https://elixirforum.com/t/looking-for-a-prawn-like-pdf-generation-library-in-elixir/67278` — existing demand thread that names Prawn-like native layout and discusses Typst/HTML tradeoffs.
- `https://elixirstatus.com/` — ElixirStatus accepts links to projects, posts, and version updates.
- `https://github.com/h4cc/awesome-elixir` — awesome-elixir contribution path and PDF category target.
- `https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository` — issue templates/forms and `blank_issues_enabled` behavior.
- `https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms` — discussion category form files under `.github/DISCUSSION_TEMPLATE/`.
- `https://news.ycombinator.com/showhn.html` — Show HN requires something people can try and discourages upvote/comment asks.
- `https://support.apple.com/guide/iphone/fill-out-and-sign-pdf-forms-iphd7e3c0c74/ios` — iOS Preview form/signing UX reference; does not by itself prove `/Sig` validation.
- `https://support.google.com/drive/answer/9463834?co=GENIE.Platform%3DAndroid&hl=en` — Google Drive Android PDF form filling reference.
- `https://github.com/mdn/browser-compat-data/blob/main/schemas/compat-data-schema.md` and `https://github.com/fyrd/caniuse` — compatibility-data discipline precedent: matrix says what is claimed, evidence says what was observed.

</specifics>

<deferred>
## Deferred Ideas

- Same-day broad launch blitz across ElixirForum, ElixirStatus, awesome-elixir, demand threads, and Show HN — deferred because it fragments discussion and raises maintainer-response risk.
- Show HN as a required launch step — deferred until after Elixir community launch and only if the try path is frictionless and maintainer availability is real.
- `ios_mail_preview` as a mobile viewer row — deferred until all proof IDs can be completed inside Mail attachment preview itself.
- GitHub Projects / labels-only adoption tracking — deferred until inbound volume outgrows `ADOPTION.md` plus issue/discussion intake.
- Broad mobile compatibility matrix — out of Phase 88; LNCH-02 needs a launch-adjacent evidence beat, not exhaustive mobile certification.

</deferred>

---

*Phase: 88-Launch Execution & Demand Instrumentation*
*Context gathered: 2026-06-12*
