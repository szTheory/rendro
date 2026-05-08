---
phase: 66
slug: live-proof-and-support-contract-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 66 - Validation Strategy

> Per-phase validation contract for long-lived live proof and support-contract closure.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + docs-contract task + GitHub Actions long-lived live-proof job + repository required-check checkpoint |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/docs_contract/signing_claims_test.exs` |
| **Full suite command** | `mix test test/rendro/sign_test.exs test/rendro/error_test.exs test/rendro/adapters/py_hanko_test.exs test/rendro/adapters/pdfsig_test.exs test/docs_contract/signing_claims_test.exs && mix docs.contract` |
| **Live proof command** | `mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs` |
| **Estimated runtime** | ~30 seconds for helper/docs inner-loop checks; ~60-120 seconds for the tagged live proof lane |

---

## Sampling Rate

- **After every Task 66-01-01 change:** run the narrow pyHanko adapter/helper suite.
- **After every Task 66-01-02 change:** run the tagged live proof lane if tools are present; otherwise confirm the explicit skip path still compiles and defer execution to CI.
- **After every Task 66-01-03 change:** run a structural workflow assertion against `.github/workflows/ci.yml`.
- **After every Task 66-02 change:** run `mix test test/docs_contract/signing_claims_test.exs`, then `mix docs.contract` once guide or matrix wording changes.
- **Before `$gsd-verify-work`:** run the full suite command and the live proof command on a host with the required tools installed, then confirm required-check enforcement.
- **Max feedback latency:** 30 seconds for the primary inner loop. The tagged long-lived live proof is an explicit slower gate and may take up to ~120 seconds when invoked.

---

## Deterministic Proof

These lanes remain tool-free and must stay green while Phase 66 lands:

- `mix test test/rendro/sign_test.exs test/rendro/error_test.exs`
- `mix test test/rendro/adapters/py_hanko_test.exs test/rendro/adapters/pdfsig_test.exs`
- `mix test test/docs_contract/signing_claims_test.exs`
- `mix docs.contract`

Deterministic proof stays distinct from the opt-in live proof. Phase 66 must not widen `mix ci`.

---

## Live Proof

Primary proof command:

```sh
mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs
```

Required live-proof behavior:

- The test exercises `Rendro.render_to_artifact/2 -> Rendro.Sign.sign/2 -> Rendro.Sign.augment/2 -> Rendro.Sign.validate/2` with `adapter: Rendro.Adapters.PyHanko`.
- The proof uses runtime-generated PDFs in a private temp dir and checked-in non-secret signer/trust fixtures only.
- `pyHanko` validation is the required authority for timestamp, revocation, and embedded-validation-evidence posture.
- `pdfsig` remains secondary and only confirms signed-artifact integrity/trust parity after augmentation.
- Missing tools in the explicitly-invoked lane yield explicit ExUnit skip reasons, not `IO.puts`.
- The required proof lane avoids outbound TSA or revocation fetches by standing up a localhost certomancer PKI/TSA/OCSP service from checked-in non-secret fixtures.

Dedicated CI proof gate:

- GitHub Actions job name: `long-lived-live-proof`
- Runs separately from deterministic `test`
- Provisions pyHanko, certomancer, and pdfsig explicitly
- Runs only the narrow tagged long-lived proof command
- Must be recorded as a required repository status check before `ADAPT-09` is considered closed

---

## Docs-Contract Proof

Required commands:

- `mix test test/docs_contract/signing_claims_test.exs`
- `mix docs.contract`

Required contract facts:

- `priv/support_matrix.json` publishes long-lived support as a dedicated subtree under `signing`.
- The guide distinguishes signed artifact support from long-lived evidence support.
- Timestamp/revocation evidence, certificate trust, viewer posture, and narrow compliance-evidence posture remain separate concepts.
- Signed-viewer and long-lived-viewer rows remain `unverified`.
- Wording avoids blanket compliance, LT/LTA marketing, signer-identity trust ownership, and viewer promotion.

---

## Tool Prerequisites

| Tool | Needed For | Required For Supported Local Proof Path | Notes |
|------|------------|------------------------------------------|-------|
| `pyhanko` | augmentation and authoritative long-lived validation | yes | Required by the tagged live proof lane and the dedicated CI proof job. |
| `pdfsig` | secondary signed-artifact integrity confirmation | yes | Required by the tagged live proof lane and the dedicated CI proof job. |
| network TSA / revocation lookups | operator realism only | no | The required gate stays offline and reproducible. |

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 66-01-01 | 01 | 1 | ADAPT-09 | T-66-01 / T-66-02 | The helper returns machine-readable timestamp, revocation, and compliance-evidence facts without CLI text parsing or host-detail leakage. | unit | `mix test test/rendro/adapters/py_hanko_test.exs test/rendro/error_test.exs` | ✅ | green |
| 66-01-02 | 01 | 1 | ADAPT-09 | T-66-01 / T-66-03 / T-66-04 | The live proof executes the exact `sign -> augment -> validate` path offline with runtime-only outputs, explicit skip reasons, and secondary `pdfsig` parity. | live ExUnit | `mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs` | ✅ | green |
| 66-01-03 | 01 | 1 | ADAPT-09 | T-66-04 | CI has a dedicated `long-lived-live-proof` job that depends on deterministic `test`, provisions live tools, and keeps the tagged command isolated from `mix ci`. | workflow config | `rg -n "long-lived-live-proof:|needs: test|mix ci|live_pdf_tools|pyhanko|pdfsig" .github/workflows/ci.yml` | ✅ | green |
| 66-01-04 | 01 | 1 | ADAPT-09 | T-66-04 | Repository policy enforces `long-lived-live-proof` as the required support-contract gate after the workflow lands. | manual operational gate | `gh api repos/szTheory/rendro/branches/main/protection/required_status_checks` | ✅ | pending |
| 66-02-01 | 02 | 2 | TRUST-07 / TRUST-08 | T-66-05 / T-66-06 | Guide and support matrix publish one exact long-lived path, nested under signing, while keeping trust, viewer, and broad compliance claims separate. | docs-contract | `mix test test/docs_contract/signing_claims_test.exs` | ✅ | pending |
| 66-02-02 | 02 | 2 | TRUST-07 / TRUST-08 | T-66-05 / T-66-06 / T-66-07 | Docs-contract lane freezes the exact long-lived claim and rejects viewer promotion, signer-identity trust ownership, LT/LTA wording, and blanket compliance drift. | docs-contract | `mix test test/docs_contract/signing_claims_test.exs && mix docs.contract` | ✅ | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] `test/test_helper.exs` already excludes `live_pdf_tools` by default.
- [x] `test/rendro/adapters/signing_live_test.exs` already provides the preferred opt-in live-proof harness shape to extend.
- [x] `.github/workflows/ci.yml` already demonstrates the separate deterministic-vs-live CI split.
- [x] `priv/support/pyhanko_validate.py` already exists as the intended machine-readable seam and is the completion target for Phase 66.
- [x] `guides/api_stability.md`, `priv/support_matrix.json`, and `test/docs_contract/signing_claims_test.exs` already form the support-contract lockstep surface that Phase 66 must refine rather than replace.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `long-lived-live-proof` is configured as a required status check in branch protection or rulesets | ADAPT-09 | Repository required-check enforcement lives outside versioned workflow YAML. | After the workflow lands, inspect repository branch protection or ruleset settings, confirm the exact `long-lived-live-proof` job name is required, then record the result in this file. |

---

## Threat References

| Threat ID | Category | Risk | Mitigation |
|-----------|----------|------|------------|
| T-66-01 | Semantic confusion | The live proof could prove a raw tool path instead of the supported public seam. | Require `Rendro.Sign.validate/2` as the canonical proof assertion after `sign -> augment`. |
| T-66-02 | Information disclosure | Helper or adapter failures could leak temp paths, raw output, or host details. | Keep helper output narrow and redaction-safe; test failure shaping explicitly. |
| T-66-03 | Flaky proof | Outbound TSA or revocation fetches could make the gate non-reproducible. | Keep the required proof offline and fixture-backed. |
| T-66-04 | Scope drift | Live-tool proof could silently widen deterministic CI or remain advisory only. | Keep a separate `long-lived-live-proof` job and require it in repository policy. |
| T-66-05 | Semantic overclaim | Docs could turn one proof-backed path into generic long-lived/compliance support. | Freeze one exact claim and explicit non-claims in guide, support matrix, and docs-contract tests. |
| T-66-06 | Capability confusion | Support metadata could collapse trust, viewer, and compliance posture into one reassuring headline. | Publish separate nested leaves and keep viewer rows `unverified`. |
| T-66-07 | Drift | Guide and support matrix could diverge after runtime proof lands. | Enforce lockstep with the docs-contract lane and `mix docs.contract`. |

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage except the explicit required-check checkpoint
- [x] The single operational gate is isolated as a manual checkpoint
- [x] Sampling continuity is preserved across both plans
- [x] Deterministic proof and live proof are explicitly separated
- [x] No watch-mode flags
- [x] Feedback latency target stays under 30 seconds for primary inner-loop checks; the tagged live proof is explicitly treated as a slower gate
- [x] `nyquist_compliant: true` set in frontmatter
- [x] `wave_0_complete: true` for planning because the harness, docs-contract lane, and helper seam already exist

**Approval:** pending
