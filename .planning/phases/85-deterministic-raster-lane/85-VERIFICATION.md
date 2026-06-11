---
phase: 85-deterministic-raster-lane
verified: 2026-06-10T00:00:00Z
status: gaps_found
score: 6/9 must-haves verified
gaps:
  - truth: "Snapshot harness exercises Pdfium.render/2 — a real rendered PDF feeds assert_golden_hashes so a raster regression can fail CI"
    status: failed
    reason: "Pdfium.render/2 is never called anywhere in pdfium_raster_snapshot_test.exs. The only @tag raster_snapshot test reads a ref file that does not exist and prints 'Skipping'. assert_golden_hashes and bless_refs are invoked only via assert_or_bless_stub() with pngs: [] (empty list), which iterates zero times. No PDF is ever rendered; no PNG hash is ever compared. A genuine raster regression passes this lane silently."
    artifacts:
      - path: "test/rendro/adapters/pdfium_raster_snapshot_test.exs"
        issue: "No call to Pdfium.render/2 or Rendro.Adapters.Pdfium.render/2 anywhere in the file. The @tag raster_snapshot test is a dead branch (ref file absent) and the only non-tagged test calls assert_or_bless('stub_fixture', []) with an empty PNG list."
      - path: "test/rendro/adapters/pdfium_raster_snapshot_test.exs:24-37"
        issue: "Tautological hash test: reads a .sha256 ref file, hashes the file's own bytes with sha256, and asserts that hash equals the file content. A sha256 hex string is never the sha256 of itself — this assertion would always fail if the ref file existed. Since priv/raster_refs/ contains only .gitkeep, the test takes the else branch and succeeds vacuously."
      - path: "priv/support_matrix.json:489"
        issue: "byte_deterministic_on_pinned_container: 'supported' — this capability claim is unbacked because no executing assertion actually demonstrates determinism."
    missing:
      - "A committed PDF fixture (e.g. test/fixtures/raster/invoice.pdf) used as render input"
      - "A @tag raster_snapshot test that calls Pdfium.render(pdf_binary, dpi: 150) and passes the result to assert_or_bless/2"
      - "Committed .sha256 ref files under priv/raster_refs/ blessed by running MIX_RASTER_BLESS=true in CI once"
      - "Either remove the tautological hash test or replace it with a real render-and-compare"
      - "Downgrade byte_deterministic_on_pinned_container to 'unverified' until the above is fixed, or fix the above"

  - truth: "viewer_kind: 'pdfium-render' is structurally restricted from GUI-viewer rows at the schema level, not just by a runtime test"
    status: failed
    reason: "CR-02 confirmed: pdfium-render was added to the shared viewer_row.viewer_kind enum in priv/schemas/support_matrix.schema.json. viewer_row is the type for every row under forms.viewers, signing.viewers, etc. — GUI-viewer promotion rows. The schema now structurally permits a row like forms.viewers.adobe_acrobat_reader to carry viewer_kind: 'pdfium-render' and pass both JSV validation and promotion_complete_row?/1 in validator.ex. The intended invariant ('engine-only kind must not appear on GUI-viewer rows') is enforced only by a single docs-contract test (raster_claims_test.exs test 5), which iterates a hardcoded section list. If that list drifts or the test is weakened, the misclassification ships silently."
    artifacts:
      - path: "priv/schemas/support_matrix.schema.json:115"
        issue: "viewer_row.viewer_kind enum now includes 'pdfium-render'. viewer_row is the type enforced by additionalProperties: {$ref: viewer_row} on every viewer_map. This means the structural contract permits GUI-viewer rows to carry engine-only evidence."
      - path: "lib/rendro/viewer_evidence/validator.ex:15"
        issue: "@viewer_kinds includes pdfium-render; promotion_complete_row?/1 accepts it as valid for any viewer_row, including GUI-viewer rows."
      - path: "test/docs_contract/raster_claims_test.exs:45-59"
        issue: "This single test is the only guard. It checks a hardcoded section list ['forms','signing','signing_preparation','embedded_files','links','protection'] — sections not in this list are unchecked. The structural contract should own this invariant, not a runtime test."
    missing:
      - "Remove 'pdfium-render' from the viewer_row.viewer_kind enum in support_matrix.schema.json (GUI-viewer rows do not need it; the raster section sits under additionalProperties: true at root)"
      - "Remove 'pdfium-render' from @viewer_kinds in validator.ex (atomically with the schema change)"
      - "If pdfium-render must remain in viewer_row for future use, add a schema-level constraint (e.g. a not/anyOf pattern) that forbids it on rows inside viewer_map sections, OR add the exclusion to promotion_complete_row?/1 directly"
      - "Retain raster_claims_test.exs test 5 as a belt-and-suspenders guard regardless"
---

# Phase 85: Deterministic Raster Lane — Verification Report

**Phase Goal:** Deterministic Raster Lane — `Pdfium.render/2`, golden-PNG snapshot harness, advisory CI lane, honest `pdfium-render` evidence vocabulary.
**Verified:** 2026-06-10T00:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | `Pdfium.render/2` exists, accepts pdf_binary + opts, returns `{:ok, [binary]}` or `{:error, term()}` | VERIFIED | `lib/rendro/adapters/pdfium.ex:68-83` — full implementation with validate_dpi/1, validate_pages/1, make_tmp_dir_for_raster/0, write_private_file/2, render_in_tmp/4, run_render/5, collect_pngs/1 |
| 2  | `render/2` returns `{:error, {:missing_executable, "pdfium-cli"}}` when pdfium-cli is absent | VERIFIED | `pdfium_test.exs` test active (no @tag :skip); confirmed by `mix test test/rendro/adapters/pdfium_test.exs` — 3 tests, 0 failures |
| 3  | Snapshot harness exercises `Pdfium.render/2` — a real rendered PDF feeds `assert_golden_hashes` so a raster regression can fail CI | FAILED | `Pdfium.render/2` is never called in `pdfium_raster_snapshot_test.exs`. The sole `@tag raster_snapshot` test reads a ref file that does not exist and prints "Skipping". The bless-guard test calls `assert_or_bless("stub_fixture", [])` with an empty PNG list — zero iterations. No regression can fail this lane. |
| 4  | `raster-advisory` CI job is graph-disconnected (no `needs:`), `continue-on-error: true`, and pdfium-cli v0.11.0 sha256-pinned | VERIFIED | `.github/workflows/ci.yml:50-79` — job has no `needs:` key, `continue-on-error: true`, sha256 b1e7f3dd… in install step |
| 5  | `raster-advisory` is in `advisory_contexts` and absent from `required_contexts` | VERIFIED | `priv/guardrails/required_status_checks.json:56-61` — entry present in advisory_contexts; required_contexts = ["long-lived-live-proof","release-proof","signing-live-proof","test"] |
| 6  | `viewer_kind: "pdfium-render"` is a distinct vocabulary entry recorded in the raster section of the support matrix | VERIFIED | `priv/support_matrix.json:498` — `"viewer_kind": "pdfium-render"` in the raster section's evidence object |
| 7  | A docs-contract guard prevents GUI-viewer rows from carrying `pdfium-render` | VERIFIED (partial) | `raster_claims_test.exs:45-59` — test 5 iterates viewer_map sections and asserts no row has `viewer_kind == "pdfium-render"`. Guard works at runtime but the structural contract (schema) does not enforce it — see gap for CR-02 |
| 8  | `pdfium-render` is structurally restricted from GUI-viewer rows at the schema/validator level | FAILED | `priv/schemas/support_matrix.schema.json:115` — `pdfium-render` added to `viewer_row.viewer_kind` enum; `viewer_row` is the type for ALL viewer_map rows including GUI-viewer rows. The schema now permits `adobe_acrobat_reader` to carry `viewer_kind: "pdfium-render"` and pass validation. |
| 9  | `byte_deterministic_on_pinned_container: "supported"` is backed by at least one executing assertion | FAILED | No executing assertion demonstrates determinism (consequence of gap #3). The capability is marked "supported" in the matrix but the proof lane is hollow. |

**Score:** 6/9 truths verified (truths 1, 2, 4, 5, 6, 7 verified; truths 3, 8, 9 failed)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/adapters/pdfium.ex` | `render/2` function with tmp-dir isolation | VERIFIED | 102 lines added; `def render(` present; `write_private_file`, `make_tmp_dir_for_raster`, `collect_pngs` all implemented |
| `test/rendro/adapters/pdfium_raster_snapshot_test.exs` | Snapshot harness that renders a real PDF and compares hashes | STUB | File exists and compiles. Infrastructure functions (`assert_golden_hashes/2`, `bless_refs/2`, `assert_or_bless/2`) present. But `Pdfium.render/2` is never called. The `@tag raster_snapshot` test is dead (always skips). No committed PDF fixture. No blessed refs. |
| `test/docs_contract/raster_claims_test.exs` | 6 docs-contract assertions | VERIFIED | 6 tests, 0 failures (`mix test` confirms). Tests 1-6 all active and green. |
| `priv/pdfium_pin.json` | v0.11.0 version + sha256 pin | VERIFIED | `{"version":"v0.11.0","sha256":"b1e7f3dd..."}` — correct content |
| `priv/raster_refs/.gitkeep` | Git-tracked directory for future refs | VERIFIED (only gitkeep) | Directory tracked by git; only `.gitkeep` present — no blessed hashes yet (expected, but harness not wired to produce them) |
| `priv/schemas/support_matrix.schema.json` | `pdfium-render` added to enum | VERIFIED but over-scoped | `enum: ["manual","pdfium-cli","pdfjs-dist","pdfium-render"]` present. However, this enum is on `viewer_row` (the GUI-viewer row type), not a separate raster-evidence type. |
| `lib/rendro/viewer_evidence/validator.ex` | `@viewer_kinds` extended | VERIFIED but over-scoped | `~w(manual pdfium-cli pdfjs-dist pdfium-render)` at line 15. Same scoping issue as schema. |
| `priv/support_matrix.json` | Top-level `raster` section | VERIFIED | `"raster"` key at root level with renderer, capabilities, boundaries, evidence sub-sections |
| `.github/workflows/ci.yml` | `raster-advisory` job | VERIFIED | Graph-disconnected, `continue-on-error: true`, sha256-pinned pdfium install, runs `mix test --include raster_snapshot` |
| `priv/guardrails/required_status_checks.json` | `raster-advisory` in `advisory_contexts` | VERIFIED | Entry present; absent from `required_contexts` |
| `scripts/verify_docs.exs` | `"Raster claims lane"` entry | VERIFIED | `{"Raster claims lane", ["test", "test/docs_contract/raster_claims_test.exs"]}` present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `pdfium_raster_snapshot_test.exs` @tag raster_snapshot test | `Pdfium.render/2` | Direct function call | NOT WIRED | No call to `Pdfium.render/2` exists in the file. The tagged test reads a ref file that does not exist and exits the `else` branch. |
| `pdfium_raster_snapshot_test.exs` assert_or_bless | `assert_golden_hashes/2` / `bless_refs/2` | Called from `assert_or_bless/2` with real PNG list | NOT WIRED | Only called with `pngs: []` (empty list). Neither function body ever executes with actual rendered PNG data. |
| CI `raster-advisory` job | Required engine lanes | No `needs:` + `continue-on-error: true` + advisory_contexts only | WIRED | Correctly isolated; download failure cannot block `test`, `signing-live-proof`, `release-proof`, `long-lived-live-proof` |
| `priv/schemas/support_matrix.schema.json` viewer_row enum | GUI-viewer row exclusion | Schema `not` constraint or separate type | NOT WIRED | No schema constraint prevents a GUI-viewer row from using `viewer_kind: "pdfium-render"`. Exclusion relies entirely on a runtime test. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `pdfium_raster_snapshot_test.exs` | `pngs` (PNG binaries to hash) | Should be `Pdfium.render/2` output | No — `pngs` is always `[]` or absent | DISCONNECTED — the harness infrastructure exists but the data source (render call) is not wired in |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Bless guard raises outside GITHUB_ACTIONS | `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs` | 1 test, 0 failures | PASS |
| Snapshot test skips gracefully when no refs | `mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` | Prints "Skipping: no ref hashes yet", 2 tests, 0 failures | PASS — but skipping IS the gap (not a success) |
| render/2 missing-executable path | `mix test test/rendro/adapters/pdfium_test.exs` | 3 tests, 0 failures | PASS |
| render/2 mock-runner happy path | included above | 3 tests, 0 failures | PASS |
| All 6 raster_claims docs-contract tests | `mix test test/docs_contract/raster_claims_test.exs` | 7 tests, 0 failures, 1 excluded | PASS |
| Full suite | `mix test` | 1082 tests, 0 failures, 11 excluded | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| RAST-01 | 85-02 | `render/2` producing PNG rasters via version+sha256-pinned pdfium-cli | SATISFIED | `lib/rendro/adapters/pdfium.ex:68-83` — implementation present; unit tests green; sha256 pin in `priv/pdfium_pin.json` |
| RAST-02 | 85-04 | Golden-PNG snapshot harness in advisory CI lane that never gates engine lanes | PARTIALLY SATISFIED | Advisory lane wiring is correct (no `needs:`, `continue-on-error: true`, advisory_contexts only). Snapshot harness infrastructure exists. But the harness does NOT exercise `render/2` — no real golden hashes can ever be generated or compared. The "golden-PNG" aspect is not satisfied. |
| RAST-03 | 85-03, 85-04 | `viewer_kind: "pdfium-render"` distinct from GUI observation; docs-contract guard prevents GUI-viewer claim upgrades | PARTIALLY SATISFIED | Vocabulary entry created; raster section boundary declarations present; runtime guard (test 5) works. Schema structural enforcement is absent — `pdfium-render` was added to the GUI-viewer-row type, not a separate type. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `test/rendro/adapters/pdfium_raster_snapshot_test.exs` | 24-37 | Tautological hash test — hashes a `.sha256` file's own bytes and asserts equality with its content (always false if file existed; always skips because file absent) | BLOCKER | The lane's central determinism check is permanently broken: would fail if triggered (wrong logic), but can never be triggered (file never exists because render is never called) |
| `test/rendro/adapters/pdfium_raster_snapshot_test.exs` | 44-46 | `assert_or_bless_stub` passes `pngs: []` — bless-guard test proves the guard mechanism but produces no coverage of actual hash comparison or bless write | WARNING | Hash infrastructure is untested with real data |
| `priv/support_matrix.json` | 489 | `"byte_deterministic_on_pinned_container": "supported"` — capability marked supported but no executing assertion backs it | BLOCKER | Unbacked claim in the support matrix; this is exactly what the matrix's proof culture is designed to prevent |
| `lib/rendro/adapters/pdfium.ex` | 144-148 | `collect_pngs/1` uses `Enum.sort/1` (lexicographic) on `page_*.png` paths — wrong order past page 9 (`page_10.png` sorts before `page_2.png`) | WARNING | Silent page-order corruption for any document with 10+ pages |
| `lib/rendro/adapters/pdfium.ex` | 111-118 | `write_private_file/2` calls `File.rm(path)` then opens with `[:exclusive]` — rm defeats the exclusivity guard | WARNING | Mixed security intent; minor in practice since tmp dir is freshly created per invocation |

### Human Verification Required

None. All gaps are code-verifiable.

## Gaps Summary

Two blockers, confirmed independently of SUMMARY.md claims, matching the 85-REVIEW.md findings:

**BLOCKER 1 (CR-01): Snapshot harness is hollow — `Pdfium.render/2` never called**

The raster-advisory CI lane downloads pdfium-cli, then runs a test file that never calls `Pdfium.render/2`. The only `@tag raster_snapshot` test reads `priv/raster_refs/invoice/page_1.sha256`, which does not exist, takes the `else` branch, and prints "Skipping". The bless-guard test calls `assert_or_bless("stub_fixture", [])` with an empty list, so `assert_golden_hashes` and `bless_refs` iterate zero times. A genuine raster regression (e.g., a change to the PDF rendering pipeline that produces visually different output) would not fail this lane.

The tautological hash assertion (lines 24-37) compounds this: even if a ref file existed, the test hashes the ref file's own bytes (a 64-char hex string) and asserts that hash equals the file content — an assertion that cannot be true. The test logic is inverted.

The `byte_deterministic_on_pinned_container: "supported"` matrix claim is therefore unbacked.

This directly undermines RAST-02 ("golden-PNG snapshot harness... hash-equality fast path").

**BLOCKER 2 (CR-02): Schema enum widening allows GUI-viewer rows to claim engine-only `pdfium-render` evidence**

`pdfium-render` was added to the `viewer_row.viewer_kind` enum. `viewer_row` is the shared type for every GUI-viewer promotion row in the matrix (forms, signing, protection, etc.). The schema now structurally permits `forms.viewers.adobe_acrobat_reader` to carry `viewer_kind: "pdfium-render"` and pass both JSV validation and `promotion_complete_row?/1`. The raster section at root does not need this enum entry — it lives under `additionalProperties: true` and is never validated against `viewer_row`.

The only thing preventing the misclassification is one runtime docs-contract test (raster_claims_test.exs test 5). The truthfulness boundary the schema is supposed to own is not owned by the schema.

This directly undermines RAST-03 ("with a docs-contract guard preventing raster evidence from upgrading GUI-viewer claims") because the structural contract now enables — rather than prevents — that misclassification.

---

_Verified: 2026-06-10T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
