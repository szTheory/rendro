---
phase: 85
slug: deterministic-raster-lane
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-10
audited: 2026-06-11
gap_count: 0
manual_only_count: 0
---

# Phase 85 - Validation Strategy

Per-phase validation contract and retroactive Nyquist audit for the deterministic raster lane.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in, Elixir 1.19) |
| Config file | `test/test_helper.exs` |
| Default excludes | `live_pdf_tools: true`, `live_signing: true`, `raster_snapshot: true` |
| Quick run command | `mix test test/docs_contract/raster_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs test/rendro/adapters/pdfium_test.exs` |
| Default snapshot command | `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs` |
| Advisory raster command | `MIX_RASTER_BLESS=false mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` with pinned `pdfium-cli` available |
| Docs-contract command | `mix run scripts/verify_docs.exs` |
| Full suite command | `mix test` |
| Estimated runtime | ~30 seconds for default suite; advisory raster lane depends on pdfium-cli container/shim startup |

---

## Sampling Rate

- After raster adapter changes: run `mix test test/rendro/adapters/pdfium_test.exs`.
- After support matrix, schema, guardrail, or docs-contract changes: run `mix test test/docs_contract/raster_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs`.
- After snapshot harness or ref changes: run `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs`, then the advisory `--include raster_snapshot` command in the pinned pdfium-cli environment.
- Before phase verification: run `mix test`, `mix run scripts/verify_docs.exs`, schema drift check, and the advisory raster snapshot lane.
- Max default feedback latency: ~30 seconds. The advisory raster lane is intentionally outside the required deterministic lane.

---

## Requirement Coverage Summary

| Requirement | Status | Primary Automated Evidence |
|-------------|--------|----------------------------|
| RAST-01 | COVERED | `test/rendro/adapters/pdfium_test.exs` covers missing executable, mock-runner success, invalid page range rejection before command execution, and numeric page ordering; `lib/rendro/adapters/pdfium.ex` implements private tmp writes and list-form argv. |
| RAST-02 | COVERED | `test/rendro/adapters/pdfium_raster_snapshot_test.exs` renders `test/fixtures/forms_support_fixture.pdf` through `Pdfium.render/2`; `priv/raster_refs/forms_support_fixture/page_1.sha256` stores the committed ref; `.github/workflows/ci.yml` defines a non-blocking `raster-advisory` job. |
| RAST-03 | COVERED | `test/docs_contract/raster_claims_test.exs` checks top-level raster evidence, guardrail isolation, GUI-viewer boundary rejection, and ref-hash consistency; `test/docs_contract/viewer_evidence_claims_test.exs` remains green with the narrowed GUI-viewer enum. |

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Evidence Files | Status |
|---------|------|------|-------------|-----------|-------------------|----------------|--------|
| 85-01 | 01 | 1 | RAST-01, RAST-02, RAST-03 | scaffold/unit/docs contract | `mix test test/rendro/adapters/pdfium_test.exs test/rendro/adapters/pdfium_raster_snapshot_test.exs` | `test/test_helper.exs`, `test/rendro/adapters/pdfium_raster_snapshot_test.exs`, `test/docs_contract/raster_claims_test.exs`, `priv/pdfium_pin.json` | COVERED |
| 85-02 | 02 | 2 | RAST-01 | unit | `mix test test/rendro/adapters/pdfium_test.exs` | `lib/rendro/adapters/pdfium.ex`, `test/rendro/adapters/pdfium_test.exs`, `priv/public_api.json` | COVERED |
| 85-03 | 03 | 2 | RAST-03 | docs contract/schema | `mix test test/docs_contract/raster_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs` | `priv/support_matrix.json`, `priv/schemas/support_matrix.schema.json`, `lib/rendro/viewer_evidence/validator.ex` | COVERED |
| 85-04 | 04 | 3 | RAST-02, RAST-03 | CI/guardrail/docs contract | `mix test test/docs_contract/raster_claims_test.exs` | `.github/workflows/ci.yml`, `priv/guardrails/required_status_checks.json`, `scripts/verify_docs.exs`, `test/guardrails/required_checks_contract_test.exs` | COVERED |
| 85-05 | 05 | 4 | RAST-02, RAST-03 | advisory raster/docs contract | `MIX_RASTER_BLESS=false mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs`; `mix test test/docs_contract/raster_claims_test.exs` | `test/rendro/adapters/pdfium_raster_snapshot_test.exs`, `priv/raster_refs/forms_support_fixture/page_1.sha256`, `priv/support_matrix.json` | COVERED |
| 85-06 | 06 | 4 | RAST-01, RAST-03 | unit/docs contract/security regression | `mix test test/docs_contract/raster_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs test/rendro/adapters/pdfium_test.exs` | `lib/rendro/adapters/pdfium.ex`, `test/rendro/adapters/pdfium_test.exs`, `test/docs_contract/raster_claims_test.exs`, `priv/schemas/support_matrix.schema.json` | COVERED |

---

## Cross-Reference Matrix

| Behavior | Requirement | Automated Check | Status |
|----------|-------------|-----------------|--------|
| `Pdfium.render/2` returns `{:error, {:missing_executable, "pdfium-cli"}}` when absent | RAST-01 | `test/rendro/adapters/pdfium_test.exs` | COVERED |
| Mock runner returns `{:ok, [png_binary]}` | RAST-01 | `test/rendro/adapters/pdfium_test.exs` | COVERED |
| `pages:` rejects argv-shaped values before runner invocation | RAST-01 | `test/rendro/adapters/pdfium_test.exs` | COVERED |
| Rendered PNG files return in numeric page order | RAST-01 | `test/rendro/adapters/pdfium_test.exs` | COVERED |
| Tmp input uses private write semantics and no pre-delete | RAST-01 | `test/rendro/adapters/pdfium_test.exs`; code review/security audit grep checks | COVERED |
| `priv/pdfium_pin.json` has v0.11.0 and SHA-256 pin | RAST-01, RAST-02 | `test/docs_contract/raster_claims_test.exs` | COVERED |
| Snapshot harness renders a real fixture through `Pdfium.render/2` | RAST-02 | `test/rendro/adapters/pdfium_raster_snapshot_test.exs` with `--include raster_snapshot` | COVERED |
| Bless path raises outside `GITHUB_ACTIONS=true` | RAST-02 | `test/rendro/adapters/pdfium_raster_snapshot_test.exs` default test | COVERED |
| Committed PNG ref and support-matrix hash stay equal | RAST-02, RAST-03 | `test/docs_contract/raster_claims_test.exs` | COVERED |
| `raster-advisory` is advisory-only and absent from required contexts | RAST-02, RAST-03 | `test/docs_contract/raster_claims_test.exs`; `test/guardrails/required_checks_contract_test.exs` | COVERED |
| `raster-advisory` has no `needs:` and uses `continue-on-error: true` | RAST-02 | `.github/workflows/ci.yml`; phase verification grep/YAML checks | COVERED |
| Top-level `raster.evidence.viewer_kind` remains `pdfium-render` | RAST-03 | `test/docs_contract/raster_claims_test.exs`; support matrix JSON | COVERED |
| GUI-viewer rows do not carry `pdfium-render` | RAST-03 | `test/docs_contract/raster_claims_test.exs` | COVERED |
| Schema and promotion validator reject `pdfium-render` on a mutated GUI-viewer row | RAST-03 | `test/docs_contract/raster_claims_test.exs` | COVERED |

---

## Manual-Only Verifications

None.

The raster lane remains advisory by design. Real GitHub Actions execution is useful operational signal after push, but Phase 85's requirement coverage is automated through checked-in CI configuration, guardrail JSON, docs-contract tests, and the included raster snapshot lane.

---

## Validation Audit 2026-06-11

| Metric | Count |
|--------|-------|
| Plans audited | 6 |
| Requirements audited | 3 |
| Cross-reference behaviors audited | 14 |
| Gaps found | 0 |
| Resolved by new tests in this audit | 0 |
| Escalated to manual-only | 0 |
| Manual-only remaining | 0 |

### Commands Run During Audit

- `mix test test/docs_contract/raster_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs test/rendro/adapters/pdfium_test.exs` - 34 tests, 0 failures.
- `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs` - 1 test, 0 failures, 1 excluded.
- `PATH="/tmp/rendro-pdfium-shim:$PATH" MIX_RASTER_BLESS=false mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` - 2 tests, 0 failures.
- `mix run scripts/verify_docs.exs` - all 15 docs-contract lanes passed.
- `gsd-sdk query verify.schema-drift 85` - `drift_detected: false`.
- `gsd-sdk query verify.codebase-drift 85` - skipped, no structural map configured.

---

## Validation Sign-Off

- [x] All tasks have automated verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 references were replaced or backed by active tests.
- [x] No watch-mode flags.
- [x] Feedback latency remains under the default target for deterministic lanes.
- [x] Advisory raster lane remains separated from required deterministic checks.
- [x] `nyquist_compliant: true` set in frontmatter.

Approval: verified 2026-06-11
