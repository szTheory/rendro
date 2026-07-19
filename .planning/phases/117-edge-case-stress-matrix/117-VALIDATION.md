---
phase: 117
slug: edge-case-stress-matrix
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-18
---

# Phase 117 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **Meta-note:** the "system under validation" for this TEST/INFRA phase IS the test matrix
> itself — the question is *how do we know the matrix proves what it claims, not merely asserts?*
> (See RESEARCH.md `## Validation Architecture`.)

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in — zero new dependencies) |
| **Config file** | `test/test_helper.exs` (existing; `raster_snapshot: true` already excluded by default at line 10) |
| **Quick run command** | `mix test test/rendro/edge_matrix_test.exs test/rendro/edge_error_matrix_test.exs` |
| **Full suite command** | `mix test --include raster_snapshot` |
| **Estimated runtime** | ~seconds (byte + error cells, `async: true`); raster lane adds pdfium render time |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/edge_matrix_test.exs test/rendro/edge_error_matrix_test.exs` (byte + error cells only — fast, `async: true`, no pdfium dependency)
- **After every plan wave:** add `mix test test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/branding_claims_test.exs`
- **Before `/gsd-verify-work`:** Full suite green, PLUS one CI-container run of `mix test --include raster_snapshot` per raster fixture addition (raster is advisory in CI, not gating — byte goldens are the gating signal)
- **Max feedback latency:** < 30 seconds for the byte + error lane

---

## Per-Task Verification Map

> Task IDs are indicative; the planner assigns final plan/wave numbers. Every EDGE requirement
> maps to an automated ExUnit command.

| Requirement | Behavior | Test Type | Automated Command | File Exists |
|-------------|----------|-----------|-------------------|-------------|
| EDGE-01 (byte) | Every `:applies` cell renders a stable, SHA-256-verified PDF | unit (data-driven `for`-comprehension) | `mix test test/rendro/edge_matrix_test.exs` | ❌ W0 — new file |
| EDGE-01 (matrix honesty, D-02) | Every `{family, dimension}` pair has a `@matrix` entry (`:applies` or N/A reason) | unit (meta) | `mix test test/rendro/edge_matrix_test.exs` | ❌ W0 |
| EDGE-01 (determinism guard, D-04) | Two `deterministic: true` renders are byte-identical before any hash is blessed | unit (shared `assert_deterministic!/1`) | `mix test test/rendro/edge_matrix_test.exs` | ❌ W0 |
| EDGE-01 (raster) | Curated ≤6 fixtures / ≤~12 refs match pixel refs at pinned pdfium | unit (`@tag raster_snapshot: true`, advisory) | `mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` | ✅ existing file, **extend in-place** (in-fence CI decision — no new file, no ci.yml edit) |
| EDGE-01 (tarball) | `priv/goldens` + `priv/raster_refs` excluded from Hex tarball; `lib`/`priv/branded` still ship | docs-contract | `mix test test/docs_contract/branding_claims_test.exs` | ✅ existing, extend |
| EDGE-02 | Overflow, tall-row, RTL (×2 paths) each raise typed instructive `%Rendro.Error{}` — never silent truncation | unit (struct + `stage`/`reason` + `next`-substring pattern match) | `mix test test/rendro/edge_error_matrix_test.exs` | ❌ W0 — new sibling file (D-08) |
| EDGE-03 | Exemption present, valid, disjoint, non-vacuous (fail-loud both directions, D-15) | docs-contract | `mix test test/docs_contract/rubric_manifest_contract_test.exs` | ✅ existing, extend |

---

## Wave 0 Requirements

- [ ] `test/support/edge_fixtures.ex` — `Rendro.Test.EdgeFixtures.build/2` fixture builder (6 families × applicable dimensions)
- [ ] `test/support/golden.ex` — `assert_or_bless/2` (byte, un-gated) + `assert_deterministic!/1` shared helpers
- [ ] `test/rendro/edge_matrix_test.exs` — `@matrix`/`@dimensions`/`@families` + data-driven byte-golden tests + D-02 coverage-honesty meta-test
- [ ] `test/rendro/edge_error_matrix_test.exs` — EDGE-02 typed-error assertions (overflow, tall-row, RTL default-font + RTL fake-font)
- [ ] `priv/goldens/` tree — created by first `MIX_GOLDEN_BLESS=true` run, never hand-authored
- [ ] Raster cells added **into** `test/rendro/adapters/pdfium_raster_snapshot_test.exs` so the existing CI raster job discovers them (in-fence decision — **no `.github/workflows/ci.yml` edit**)

*Determinism proof itself (`deterministic_test.exs` property tests) already exists — this phase adds per-fixture regression guards, not new determinism infrastructure.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First golden bless | EDGE-01 | Blessing is a deliberate human gesture (no silent auto-create) | `MIX_GOLDEN_BLESS=true mix test test/rendro/edge_matrix_test.exs`; review one-line hash diffs |
| First raster bless | EDGE-01 | Raster hashes are platform-pinned; require CI container | `MIX_RASTER_BLESS=true GITHUB_ACTIONS=true mix test --include raster_snapshot` (pinned pdfium) |
| `MIX_GOLDEN_DUMP` eyeball | EDGE-01 | Visual sanity of a golden artifact before blessing | `MIX_GOLDEN_DUMP=<scratch-dir> mix test …`; inspect PDF in gitignored scratch dir |

*All regression-checkable behaviors have automated verification; the above are one-time authoring gestures.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (fixture builder, golden helper, matrix + error modules)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (byte + error lane)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
