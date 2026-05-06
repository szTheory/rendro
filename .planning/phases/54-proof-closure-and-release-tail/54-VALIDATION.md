---
phase: 54
slug: proof-closure-and-release-tail
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-06
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for protection viewer-proof closure and release-tail readiness.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix task/script tests + docs-contract task |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/docs_contract/protection_claims_test.exs test/docs_contract/integrations_claims_test.exs test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs` |
| **Full suite command** | `mix test test/docs_contract/protection_claims_test.exs test/docs_contract/integrations_claims_test.exs test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs && mix docs.contract && mix release.preflight` |
| **Estimated runtime** | ~15-45 seconds |

## Sampling Rate

- After every task commit: run the narrowest command from the per-task verification map below
- After every plan wave: run `mix docs.contract` after any contract-surface edits
- Before `$gsd-verify-work`: run the full suite command once the worktree is clean
- Phase gate: run `mix run scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-release-proof` only after proof closure and a clean exact-tag state
- Max feedback latency: 45 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 54-01-01 | 01 | 1 | TRUST-03 | T-54-01, T-54-02, T-54-04 | The proof scaffold names the locked five checks, records the Phase 52 plus host-tool gate explicitly, and provides a repeatable protected-fixture generator entrypoint. | script / planning | `mix run scripts/protected_viewer_proof_fixture.exs --dry-run --output /tmp/rendro-phase54-proof.pdf && rg -n "opens_with_open_password|displays_authored_content_correctly|advisory_print_behavior|advisory_copy_behavior|save_and_reopen_readability|Phase 52|qpdf|pdfinfo" .planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md` | ✅ | ✅ green |
| 54-01-02 | 01 | 1 | TRUST-03 | T-54-02, T-54-03 | The manual proof sheet contains at least one completed viewer row with the required metadata and does not use owner-password-only success as a promotion basis. | manual + regex check | `rg -nP '^\| (Adobe Acrobat Reader|Apple Preview) \| (?!pending \|)([^|]+) \| (?!pending \|)([^|]+) \| (?!pending \|)([^|]+) \| (?!pending \|)([^|]+) \| (pass|fail) \| (pass|fail) \| (pass|fail) \| (pass|fail) \| (pass|fail) \| (supported|unverified) \| (?! pending)([^|]+) \|$' .planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md` after the human checkpoint review | ✅ | ⬜ pending |
| 54-01-03 | 01 | 1 | TRUST-03 | T-54-01, T-54-03 | Any per-viewer promotion is synced across the support matrix, API-stability guide, and protection docs-contract assertions with no drift. | docs-contract | `mix test test/docs_contract/protection_claims_test.exs && mix docs.contract` | ✅ | ⬜ pending |
| 54-02-01 | 02 | 2 | RELEASE-01 | T-54-06, T-54-08 | Release-tail wording stays pointer-thin and directs users back to the canonical protected-delivery recipe without introducing a second integration story. | docs-contract | `mix test test/docs_contract/integrations_claims_test.exs` | ✅ | ⬜ pending |
| 54-02-02 | 02 | 2 | RELEASE-01 | T-54-05, T-54-07 | Release readiness is executable through preflight plus isolated exact-tag proof, and the worktree proof path remains the canonical final publish gate. | unit / script | `mix test test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

## Wave 0 Requirements

- [x] `.planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md` records the five required protection checks and the per-viewer evidence table
- [x] Phase 52 completion or explicit dependency checkpoint is in place before any viewer-promotion execution
- [ ] `qpdf` is installed or otherwise available on the execution host for real protected viewer proof
- [ ] `test/docs_contract/protection_claims_test.exs` is updated for any post-proof viewer promotion outcome
- [ ] `test/docs_contract/integrations_claims_test.exs` and release-preflight tests cover any new release-tail wording or executable readiness check
- [ ] Release-tail wording has an executable guardrail if new publish-tail prose is introduced

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `opens_with_open_password` | TRUST-03 | Requires Adobe Acrobat Reader or Apple Preview interaction | Generate the representative protected fixture, open it in the target viewer with the open password, and record pass/fail for `opens_with_open_password`. |
| `displays_authored_content_correctly` | TRUST-03 | Viewer rendering behavior is outside structural validation | In the same viewer session, verify the protected fixture renders authored content correctly and record pass/fail for `displays_authored_content_correctly`. |
| `advisory_print_behavior` | TRUST-03 | Viewer UI and policy behavior are not reliably automatable in-repo | Attempt to print or inspect print availability for the fixture generated with advisory restrictions, then record pass/fail for `advisory_print_behavior` plus a short note. |
| `advisory_copy_behavior` | TRUST-03 | Viewer copy/select behavior is not covered by Poppler/qpdf tests | Attempt copy/select behavior for the same restricted fixture and record pass/fail for `advisory_copy_behavior` plus a short note. |
| `save_and_reopen_readability` | TRUST-03 | Save/reopen behavior is viewer-specific | Save the opened protected document, reopen the saved file, and record pass/fail for `save_and_reopen_readability`. |
| Exact-tag release proof on isolated worktree | RELEASE-01 | Must run against a clean tag/worktree state rather than ordinary dev workspace | Run `mix run scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-release-proof` after changelog/readiness closure and record the result in the phase verification artifact. |

## Blocking Prerequisites

- No viewer row may be promoted until accepted Phase 52 completion is confirmed and the representative fixture is generated successfully with `mix run scripts/protected_viewer_proof_fixture.exs --output /tmp/rendro-phase54-proof.pdf`.
- The proof lane is blocked on real host-tool readiness: `qpdf` must be available to generate the protected fixture, and `pdfinfo` must remain available for the established structural lane.
- Owner-password-only behavior is observational only. Record it in notes if useful, but do not use it as a pass condition or public support basis.

## Locked Proof Checklist

- `opens_with_open_password`
- `displays_authored_content_correctly`
- `advisory_print_behavior`
- `advisory_copy_behavior`
- `save_and_reopen_readability`

Required per-viewer metadata:
- Viewer name
- Version when easily available
- OS
- Fixture path or file name
- Date checked
- Result
- One short notes field

## Manual Proof Record

| Viewer | Version | OS | Fixture | Date | opens_with_open_password | displays_authored_content_correctly | advisory_print_behavior | advisory_copy_behavior | save_and_reopen_readability | Result | Notes |
|--------|---------|----|---------|------|---------------------------|-------------------------------------|-------------------------|------------------------|-----------------------------|--------|-------|
| Adobe Acrobat Reader | pending | pending | pending | pending | pending | pending | pending | pending | pending | unverified | Waiting for accepted Phase 52 completion, `qpdf`, and a generated representative fixture. |
| Apple Preview | pending | pending | pending | pending | pending | pending | pending | pending | pending | unverified | Waiting for accepted Phase 52 completion, `qpdf`, and a generated representative fixture. |

## Threat References

| Threat ID | Category | Risk | Mitigation |
|-----------|----------|------|------------|
| T-54-01 | Spoofing / semantic confusion | Promoting a viewer on open success alone overstates the support contract. | Require the full five-check checklist and keep failing viewers `unverified`. |
| T-54-02 | Information disclosure | Proof notes or public wording could leak password material or secret-like detail. | Record only viewer/version/OS/fixture/date/check results/short notes and reuse existing password-redaction posture. |
| T-54-03 | Repudiation | Owner-password fallback could be misreported as normative viewer support. | Treat owner-password-only success as observation only and do not use it for promotion. |
| T-54-04 | Tampering | Running release proof from a dirty workspace or wrong ref invalidates release readiness. | Keep exact-tag and clean-worktree checks in `mix release.preflight`, then use the isolated worktree proof helper. |
| T-54-05 | Scope drift | Release-tail wording could widen into a second integration guide or new API surface. | Keep the release note/changelog pointer thin and refer back to canonical Phase 53 guidance. |

## Validation Sign-Off

- [ ] All tasks have automated verification coverage or explicit manual-only verification
- [ ] Sampling continuity is preserved across proof and release-tail slices
- [ ] Wave 0 covers the missing dependency/host-tool prerequisites
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s for automated checks
- [ ] `nyquist_compliant: true` set in frontmatter before phase completion

**Approval:** pending
