---
phase: 130
slug: catalog-quality-evidence-ratchet
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-19
---

# Phase 130 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Deterministic checks are merge authority; pinned-PDFium output and human review remain advisory evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 / OTP 28 |
| **Config file** | `test/test_helper.exs` plus recipe, catalog, and docs-contract suites |
| **Quick run command** | Run the modified family's `*_test.exs`, `*_typography_test.exs`, and `*_byte_identity_test.exs` files |
| **Full suite command** | `mix test --exclude quarantine --slowest 10 && mix rendro.catalog.check` |
| **Advisory command** | `RENDRO_CATALOG_REVIEW_DIR="$PWD/tmp/phase130-review" mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs` under the pinned PDFium environment |
| **Estimated runtime** | Focused family checks should remain sub-minute; record actual full-suite and catalog-check durations during execution |

---

## Sampling Rate

- **After every recipe task:** Run that family's three focused recipe files, including byte identity.
- **After every engineering checkpoint:** Run the affected public supplied-theme structural assertions; use `mix rendro.catalog.check` only as a read-only drift signal before the single final regeneration.
- **After the recipe wave:** Run all six families' recipe, typography, and byte-identity suites.
- **After the single complete regeneration:** Run `mix rendro.catalog.check` plus catalog/schema/docs-contract tests.
- **Before final human review:** Produce exactly one canonical twelve-image pinned-PDFium payload with its complete identity manifest; keep multipage proof separate.
- **Before `$gsd-verify-work`:** The full deterministic suite and catalog check must be green, and advisory evidence must be current and explicitly hash-bound.
- **Max feedback latency:** Keep focused checks under 60 seconds where the runner permits; measure rather than fabricate a full-suite budget.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 130-01-01 | 01 | 1 | CATALOG-06 | — | No catalog-ID/preset/quality branch; nil-theme bytes remain frozen | unit + structural + byte identity | `mix test test/rendro/recipes/{invoice,statement,certificate,payslip,ticket}_test.exs test/rendro/recipes/{invoice,statement,certificate,payslip,ticket}_typography_test.exs test/rendro/recipes/{invoice,statement,certificate,payslip,ticket}_byte_identity_test.exs` | ✅ existing; add missing assertions | ⬜ pending |
| 130-01-02 | 01 | 1 | CATALOG-07 | — | Receipt uses semantic theme roles and the same structured cells for measurement/rendering; nil-theme bytes remain frozen | unit + structural + byte identity | `mix test test/rendro/recipes/receipt_test.exs test/rendro/recipes/receipt_typography_test.exs test/rendro/recipes/receipt_byte_identity_test.exs` | ✅ existing; add missing assertions | ⬜ pending |
| 130-02-01 | 02 | 2 | CATALOG-08 | T-130-01, T-130-02 | Literal 32-cell registry, safe paths, current SHA-256 identities, explicit changed-unscored rebinds, unchanged schema | integration + contract | `mix rendro.catalog.check && mix test test/rendro/catalog_test.exs test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs` | ✅ existing; extend only if current contract cannot express explicit rebind reason | ⬜ pending |
| 130-03-01 | 03 | 3 | CATALOG-09 | T-130-02, T-130-03 | Exactly twelve canonical page-one review images; renderer and PDF/PNG identities are current; generation cannot invent a verdict | tagged advisory + contract | `RENDRO_CATALOG_REVIEW_DIR="$PWD/tmp/phase130-review" mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs` then rerun deterministic catalog/contracts after reviewer records | ✅ existing; payload split/assertions missing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Threat references:

- `T-130-01`: unsafe fixture/artifact path (tampering/information disclosure) — retain `Path.safe_relative/1` and literal registry behavior.
- `T-130-02`: stale or mismatched artifact presented as current evidence (tampering/repudiation) — join catalog ID, PNG SHA, complete PDF SHA, and pinned renderer identity fail-closed.
- `T-130-03`: generated output or CI automation smuggles a human-quality approval (repudiation/integrity) — reviewer-owned scores and sign-off remain separate and are validated after observation.

---

## Wave 0 Requirements

- [ ] Add a Receipt contract proving themed header/description/amount cells use semantic `ink`, footer/page number uses `muted`, exact structured cells feed measurement and rendering, curated metric fonts are registered, and nil-theme strings/bytes remain unchanged.
- [ ] Add one public supplied-theme hierarchy contract for each of Invoice, Statement, Certificate, Payslip, and Ticket; assert behavior through recipe output, not `catalog_layout` styling.
- [ ] Add the final-payload test/staging split: exactly twelve page-one review images in canonical light-then-dark order plus an identity manifest, with the bounded multipage proof kept separate.
- [ ] Add an explicit changed-unscored rebind assertion only if the existing rubric schema and contracts cannot distinguish the required current hash/reason record.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Genre-specific hierarchy and craft across the twelve target cells | CATALOG-06, CATALOG-07 | Aesthetic hierarchy and cohesion are advisory human judgments, not safely derivable from deterministic assertions | Inspect the exact twelve full-size page-one rasters sequentially in canonical family order, light then dark; score only the current hash-bound artifacts using the frozen rubric. |
| Promotion or retained `needs_work` disposition | CATALOG-09 | Human observation owns rubric scores and bounded justification | Record current scores, signer/date, `supersedes_evidence_ref`, and `resolution_ref`; promote a light cell only at the exact threshold. Retain every dark cell as `needs_work` while `print_safety: false`. |
| Mechanical unscored identity rebind review | CATALOG-08 | The changed set is determined by the one actual regeneration, not a predicted list | Diff the generated catalog identities, enumerate every changed unscored cell, and record current hashes/date/concrete reason without adding scores or mass-blessing byte-stable cells. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or explicit Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers every missing assertion identified by research.
- [ ] No watch-mode flags.
- [ ] Focused feedback latency stays under 60 seconds where supported; actual durations are recorded.
- [ ] Deterministic and advisory lanes remain visibly separate in commands, CI artifacts, and claims.
- [ ] `nyquist_compliant: true` is set only after execution evidence satisfies this contract.

**Approval:** pending execution evidence
