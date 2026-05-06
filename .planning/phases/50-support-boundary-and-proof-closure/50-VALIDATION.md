---
phase: 50
slug: support-boundary-and-proof-closure
status: ready
nyquist_compliant: true
wave_0_complete: false
source: planning + execution (Plan 02 Task 2)
created: 2026-05-06
started: 2026-05-06
updated: 2026-05-06
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for truthful embedded-files and links support claims, an integrated structural proof lane, and a separate manual viewer proof lane.

Phase 50 has three closure axes and treats them as distinct evidence lanes:

1. The **support-claims lane** locks the machine-readable matrix and human docs together.
2. The **structural proof lane** runs an automated, merge-blocking proof on a single representative PDF.
3. The **viewer proof lane** is the smallest durable manual lane required to justify any named viewer support claim.

Per `50-CONTEXT.md` decisions D-10 through D-14, these lanes do not substitute for each other.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + docs-contract script |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/docs_contract/embedded_artifact_claims_test.exs test/rendro/adapters/poppler_test.exs test/rendro/embedded_artifact_support_fixture_test.exs && mix docs.contract` |
| **Full suite command** | `mix docs.contract && mix test test/docs_contract/embedded_artifact_claims_test.exs test/rendro/adapters/poppler_test.exs test/rendro/embedded_artifact_support_fixture_test.exs` |
| **Estimated runtime** | ~15-40 seconds, excluding manual viewer checks |

## Sampling Rate

- After every Plan 01 task: run the narrowest touched command for the support-claims lane, then run `mix docs.contract`.
- After Plan 02 Task 1: run `mix test test/rendro/adapters/poppler_test.exs test/rendro/embedded_artifact_support_fixture_test.exs`.
- After Plan 02 Task 2: re-run the quick command and confirm the validation document still matches the implemented commands.
- Before the Plan 03 checkpoint: run the full automated command set once end-to-end.
- After any post-proof promotion in Plan 03: re-run `mix test test/docs_contract/embedded_artifact_claims_test.exs` and `mix docs.contract`.
- Max automated feedback latency: 40 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-01-01 | 01 | 1 | TRUST-01, TRUST-02 | T-50-01, T-50-02 | Support matrix stays family-first and keeps embedded-file/link viewers unverified until evidence exists. | docs-contract | `mix test test/docs_contract/embedded_artifact_claims_test.exs` | ✅ | ⬜ pending |
| 50-01-02 | 01 | 1 | TRUST-01, TRUST-02 | T-50-01, T-50-02 | Canonical support wording matches the matrix and `mix docs.contract` remains the gate. | docs-contract | `mix docs.contract` | ✅ | ⬜ pending |
| 50-02-01 | 02 | 1 | TRUST-02 | T-50-03 | One representative PDF exercises embedded files and links together and passes Poppler structural validation when `pdfinfo` exists. | integration | `mix test test/rendro/adapters/poppler_test.exs` | ✅ | ✅ green |
| 50-02-02 | 02 | 1 | TRUST-02 | T-50-03 | Companion fixture test proves the representative PDF actually contains one embedded file, one external URI link, and one internal page link. | unit | `mix test test/rendro/embedded_artifact_support_fixture_test.exs` | ✅ | ✅ green |
| 50-02-03 | 02 | 1 | TRUST-02 | T-50-03, T-50-04 | Validation contract documents the exact structural-proof commands and keeps the viewer proof lane separate. | docs | `rg -n "mix docs.contract\|mix test test/rendro/adapters/poppler_test.exs\|EmbeddedArtifactSupportFixture\|viewer proof lane\|Poppler proves PDF structure only" .planning/phases/50-support-boundary-and-proof-closure/50-VALIDATION.md` | ✅ | ✅ green |
| 50-03-01 | 03 | 2 | TRUST-01, TRUST-02 | T-50-05 | Manual viewer evidence is recorded per viewer and per surface instead of as one blanket milestone claim. | manual checkpoint | `mix docs.contract && mix test test/rendro/adapters/poppler_test.exs` | ✅ | ⬜ pending |
| 50-03-02 | 03 | 2 | TRUST-01, TRUST-02 | T-50-05, T-50-06 | Only proof-backed viewer/surface pairs are promoted; all other pairs remain unverified. | docs-contract | `mix test test/docs_contract/embedded_artifact_claims_test.exs && mix docs.contract` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

## Wave 0 Requirements

- [x] Every planned task has an explicit automated verification command.
- [x] `mix docs.contract` remains the canonical docs gate and continues to run via `scripts/verify_docs.exs`.
- [x] One representative fixture path is defined for both automated structural proof and manual viewer checks.
- [x] The validation contract separates structural proof from viewer proof instead of implying Poppler validates interaction behavior.
- [x] `test/support/embedded_artifact_support_fixture.ex` exists and exposes `Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture/1`.
- [x] `test/rendro/adapters/poppler_test.exs` validates the representative fixture and preserves the explicit `pdfinfo` skip path.
- [ ] `test/docs_contract/embedded_artifact_claims_test.exs` must lock the Phase 50 support matrix shape, wording, and docs-lane registration. (Plan 01)

## Automated Proof Lanes

### 1. Support-claims lane

Purpose:
- Prove the machine-readable support contract, public wording, and docs-gate registration stay in sync.

Automation:
- `mix test test/docs_contract/embedded_artifact_claims_test.exs`
- `mix docs.contract`

Important boundary:
- `mix docs.contract` is the canonical gate and runs through `scripts/verify_docs.exs`. Use the script directly only when debugging the docs lanes themselves.
- Per D-06 through D-09, the matrix must keep viewer claims per surface and default to `unverified` until manual evidence promotes a specific viewer/surface pair.

Expected result:
- The Phase 50 claims test passes.
- `mix docs.contract` passes with the artifact support lane included alongside existing docs lanes.

### 2. Structural proof lane

Purpose:
- Prove a representative PDF that contains document-level embedded files and supported links together is structurally valid and reproducible.

Automation:
- `mix test test/rendro/adapters/poppler_test.exs`
- `mix test test/rendro/embedded_artifact_support_fixture_test.exs`
- `MIX_ENV=test mix run -e 'path = Path.expand("tmp/embedded_artifact_support_fixture.pdf"); path = Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture(path); IO.puts(path)'`

Important boundary:
- **Poppler proves PDF structure only.** It does not prove embedded-file discoverability, extract/save behavior, external-link handoff, internal-page navigation, or any viewer security-policy prompt behavior. Those claims belong in the viewer proof lane below.
- Missing `pdfinfo` remains an explicit graceful-degradation case rather than a hard failure.

Expected result:
- The Poppler test passes when `pdfinfo` is available, or explicitly skips the representative fixture validation when it is not.
- The companion fixture test proves the representative fixture actually contains one embedded file, one external URI link, and one internal page link.
- The fixture-generation command prints a stable path to the representative PDF used in the manual viewer proof lane.

## Manual Viewer Proof Lane

Purpose:
- Record the smallest durable viewer evidence required to justify named `supported` claims for embedded files and links per surface.

This is the **viewer proof lane**: a separate evidence lane from the automated structural proof above. The same representative PDF is used by both lanes, but a passing structural lane is **not** evidence of viewer behavior. Per D-13, this lane should remain the smallest durable manual lane and should not become a screenshot archive or a broad UX-certification system.

Required viewers:
- Adobe Acrobat Reader
- Apple Preview

Required fixture:
- `tmp/embedded_artifact_support_fixture.pdf`

Preparation:
1. Run `mix docs.contract`.
2. Run `mix test test/rendro/adapters/poppler_test.exs`.
3. Generate the viewer fixture with:
   - `MIX_ENV=test mix run -e 'path = Path.expand("tmp/embedded_artifact_support_fixture.pdf"); path = Rendro.Test.EmbeddedArtifactSupportFixture.write_fixture(path); IO.puts(path)'`
4. Record the exact fixture path, OS, and viewer version if easily available.

### Embedded Files Checklist

Record `pass`, `fail`, or `unverified` per behavior, per D-14:
- `discoverable`: the viewer exposes the embedded files in its UI without requiring unsupported tooling.
- `open_or_extract`: the embedded file can be opened or extracted successfully.
- `save_or_extract`: the embedded file can be saved or extracted to disk successfully.

### Links Checklist

Record `pass`, `fail`, or `unverified` per behavior, per D-14:
- `external_uri_handoff`: clicking the external link hands off to the browser/system as expected.
- `internal_page_navigation`: clicking the internal link navigates to the intended page in the same PDF.

Recording rules:
- Do not treat security warnings or prompts as support failures unless they block the basic behavior (D-14 prose direction in `50-CONTEXT.md`).
- Do not infer support for one surface from another on the same viewer.
- A surface stays `unverified` until the proof checklist for **that** surface on **that** viewer is recorded.

## Manual Proof Record

### Embedded Files

| Viewer | Version | OS | Date checked | Fixture | Discoverable | Open/extract | Save/extract | Result | Notes |
|--------|---------|----|--------------|---------|--------------|--------------|--------------|--------|-------|
| Adobe Acrobat Reader | pending | pending | pending | `tmp/embedded_artifact_support_fixture.pdf` | unverified | unverified | unverified | unverified | Not yet manually checked in this phase. Plan 03 fills this row. |
| Apple Preview | pending | pending | pending | `tmp/embedded_artifact_support_fixture.pdf` | unverified | unverified | unverified | unverified | Not yet manually checked in this phase. Plan 03 fills this row. |

### Links

| Viewer | Version | OS | Date checked | Fixture | External URI handoff | Internal page navigation | Result | Notes |
|--------|---------|----|--------------|---------|----------------------|--------------------------|--------|-------|
| Adobe Acrobat Reader | pending | pending | pending | `tmp/embedded_artifact_support_fixture.pdf` | unverified | unverified | unverified | Not yet manually checked in this phase. Plan 03 fills this row. |
| Apple Preview | pending | pending | pending | `tmp/embedded_artifact_support_fixture.pdf` | unverified | unverified | unverified | Not yet manually checked in this phase. Plan 03 fills this row. |

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity is preserved across Plans 01 through 03
- [x] Automated structural proof and the manual viewer proof lane are explicitly separated
- [x] No watch-mode flags
- [x] `mix docs.contract` remains the canonical docs gate
- [x] `nyquist_compliant: true` set in frontmatter
- [ ] Viewer evidence tables completed for any viewer/surface pair promoted to `supported`

**Approval:** Phase 50 validation lane prepared on 2026-05-06; Plan 02 Task 2 rewrite executed on 2026-05-06.
