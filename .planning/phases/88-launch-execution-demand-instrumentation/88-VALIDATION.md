---
phase: 88
slug: launch-execution-demand-instrumentation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-12
---

# Phase 88 - Validation Strategy

> Per-phase validation contract for launch execution, mobile viewer evidence,
> GitHub intake, and adoption-signal instrumentation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix |
| Config file | `mix.exs`, `scripts/verify_docs.exs`, `.formatter.exs` |
| Quick run command | `mix test test/docs_contract/viewer_evidence_claims_test.exs test/docs_contract/forms_claims_test.exs test/docs_contract/signing_claims_test.exs test/docs_contract/raster_claims_test.exs` |
| Full suite command | `mix ci` plus `mix docs.contract` |
| Estimated runtime | Existing docs-contract lanes should stay under normal local Mix feedback; public URL and GitHub checks are operator-gated |

---

## Sampling Rate

- After every task commit that changes support-matrix, evidence, docs, or intake surfaces: run the relevant targeted docs-contract command.
- After support-matrix or evidence changes: run `mix rendro.viewer_evidence validate` and `mix rendro.viewer_evidence list`.
- After every plan wave: run `mix docs.contract`.
- Before launch publication: run `mix ci`, `mix docs.contract`, public URL checks, and GitHub label/template checks.
- Max automated feedback latency: keep targeted checks under 60 seconds when possible; use full `mix ci` only at wave/phase boundaries.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 88-W0-01 | TBD | 0 | LNCH-01 | T-88-01 | Launch copy cannot publish before CMP-03/public URL readiness gates pass | docs-contract/static | `mix test test/docs_contract/launch_execution_claims_test.exs` | W0 | pending |
| 88-W0-02 | TBD | 0 | LNCH-03 | T-88-02 | Adoption gate thresholds, ledger columns, labels, and intake routing are source-checked before public use | docs-contract/static | `mix test test/docs_contract/adoption_claims_test.exs test/docs_contract/github_intake_claims_test.exs` | W0 | pending |
| 88-LNCH-01 | TBD | TBD | LNCH-01 | T-88-01 | Quiet public posture, deferred outreach, banned claims, and public proof readiness are verified | docs-contract/manual URL | `mix test test/docs_contract/launch_execution_claims_test.exs`; public `curl` URL checks | W0 | pending |
| 88-LNCH-02 | TBD | TBD | LNCH-02 | T-88-03 | Mobile rows are either evidence-backed supported rows or explicit deferrals with no broad mobile overclaim | docs-contract + validator | `mix rendro.viewer_evidence validate`; targeted viewer/form/signing/raster docs-contract tests | yes | pending |
| 88-LNCH-03 | TBD | TBD | LNCH-03 | T-88-02 / T-88-04 | Public adoption ledger records only qualifying non-maintainer signals and preserves private-report boundaries | docs-contract + gh/manual | `mix test test/docs_contract/adoption_claims_test.exs test/docs_contract/github_intake_claims_test.exs`; `gh label list` | W0 | pending |

---

## Wave 0 Requirements

- [ ] `test/docs_contract/launch_execution_claims_test.exs` - launch readiness, external-copy constraints, public URL checklist, banned-claim guards, and CMP-03 reconciliation assertions.
- [ ] `test/docs_contract/adoption_claims_test.exs` - root `ADOPTION.md` section order, exact threshold text, ledger columns, empty states, review cadence, README/comparison links, and forbidden counting rules.
- [ ] `test/docs_contract/github_intake_claims_test.exs` - issue-template files, discussion-template shape if enabled, default-label assertions, blank-issue routing, and locked field coverage.
- [ ] Existing viewer-evidence docs-contract tests updated for mobile supported paths and signed-artifact deferral mirrors when support-matrix rows are added.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Public GitHub/HexDocs readiness | LNCH-01 | Public package/docs publication happens outside local test execution | Check exact public README, comparison guide, Livebook, gallery/manual, and HexDocs URLs before posting. |
| GitHub Discussions disabled | LNCH-03 | The accepted issue-only posture should not create a second inbox | Confirm `has_discussions: false` and no `.github/DISCUSSION_TEMPLATE/use-cases.yml` is committed. |
| Mobile iOS/Android viewer observations | LNCH-02 | Physical/device app behavior is operator-owned | Complete each proof ID on the representative forms fixture or use `explicit_deferral`; signed rows defer unless a real `/Sig` trust UI is observed. |
| Proactive outreach | LNCH-01 | Maintainer explicitly chose quiet public discoverability | Do not publish ElixirForum, ElixirStatus, awesome-elixir, demand-thread, mobile follow-up, or Show HN surfaces unless a future explicit opt-in task exists. |

---

## Threat Model

| ID | Threat | Severity | Mitigation |
|----|--------|----------|------------|
| T-88-01 | Quiet public docs link to local-only or unpublished artifacts | high | Keep public URL checks passing before marking proof surfaces Ready. |
| T-88-02 | Adoption gate is tampered with by vague, duplicate, or self-generated signals | medium | Require source URL, requester/org grouping, concrete document job, maintainer-applied `adoption:counted`, and ledger review cadence. |
| T-88-03 | Mobile evidence turns into broad viewer/support claims | high | Keep rows per viewer/surface; use explicit deferrals for signed mobile rows unless trust UI is observed; ban "mobile PDF support" copy. |
| T-88-04 | Private adopter reports leak confidential document details | high | Allow anonymized notes, cap counted private signals at two per window, and reject secrets/fixtures in public evidence bodies. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive implementation tasks without automated verification.
- [ ] Wave 0 covers all `MISSING` test references.
- [ ] No watch-mode flags.
- [ ] Feedback latency remains appropriate for the task scope.
- [ ] `nyquist_compliant: true` set in frontmatter after plans map concrete tasks to this strategy.

**Approval:** pending
