---
phase: 117-edge-case-stress-matrix
verified: 2026-07-19T03:00:09Z
status: passed
score: 27/27 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: # none — initial verification
---

# Phase 117: Edge-case stress matrix — Verification Report

**Phase Goal:** Prove the whole recipe surface is robust and deterministic under stress — a family × stress-dimension grid of hash-checked goldens and typed-error assertions — exempt from the rubric's beauty gate because it proves robustness, not aesthetics.
**Verified:** 2026-07-19T03:00:09Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

Phase 117 is a TEST/INFRA phase with a locked scope fence (edits confined to `test/`, `test/support/`, non-`lib/` `priv/`). **Zero `lib/` changes confirmed** (`git log --name-only ... -- lib/` and `git status --porcelain lib/` both empty across all 117 commits) — the intended, correct design, not a gap.

All three ROADMAP success criteria are satisfied, and all 27 PLAN-frontmatter must-have truths across the 7 plans verify against the actual codebase. The full non-raster test surface runs green: **178 tests, 0 failures** (byte goldens + coverage ratchet + EDGE-02 typed errors + tarball guard + rubric D-15 contract). Raster lane is advisory and excluded by design.

### Roadmap Success Criteria

| # | Criterion | Status | Evidence |
| --- | --- | --- | --- |
| SC-1 | Each family × stress dimension renders a deterministic SHA-256 golden, matching pdfium raster refs where applicable, goldens/raster excluded from Hex tarball | ✓ VERIFIED | 62 committed `priv/goldens/<family>/<dimension>.sha256` refs (3 cert / 14 inv / 15 payslip / 13 receipt / 14 stmt / 3 ticket = 62); `edge_matrix_test.exs` generates one byte-identity test per `:applies` cell, each preceded by a two-run determinism pre-check; 6 curated raster fixtures wired in `pdfium_raster_snapshot_test.exs`; tarball guard passes (`refute contents =~ "priv/goldens/"` / `"priv/raster_refs/"`) |
| SC-2 | Overflow, single tall row, and RTL each raise an instructive typed `Rendro.Error`/`ArgumentError` — never silent truncation or leaked internal error | ✓ VERIFIED | `edge_error_matrix_test.exs` (green): overflow + tall-row → `%Rendro.Error{stage: :paginate, reason: :content_overflow}` via two distinct paths; RTL → `{:unsupported_glyph, char}` and `{:shaping_required, :arab, hint}` at `:measure`; two `refute match?({:ok, _}, ...)` regression locks |
| SC-3 | Stress fixtures explicitly exempt from rubric beauty gate; exemption explicit in manifest/tests | ✓ VERIFIED | Single top-level `stress_exemption` block in `rubric_scores.json`; schema root `required` includes `stress_exemption`; 4 D-15 contract guards pass (presence, loophole tripwire, disjointness, non-vacuous teeth) |

### Observable Truths (PLAN must_haves)

| # | Plan | Truth | Status | Evidence |
| --- | --- | --- | --- | --- |
| 1 | 01 | Missing golden ref hard-flunks unless `MIX_GOLDEN_BLESS=true` | ✓ VERIFIED | `golden.ex:63-74` `not File.exists? → flunk`; self-test green |
| 2 | 01 | Bless is un-gated (no `GITHUB_ACTIONS` check) | ✓ VERIFIED | `golden.ex:56-61` bless branch has no container gate |
| 3 | 01 | Two `deterministic: true` renders asserted byte-identical before hashing | ✓ VERIFIED | `assert_deterministic!/1` `golden.ex:27-32`; called first in every matrix test |
| 4 | 01 | `MIX_GOLDEN_DUMP` writes raw PDF to scratch, no effect on outcome | ✓ VERIFIED | `maybe_dump/3` `golden.ex:101-111`, called unconditionally before branch; self-test green |
| 5 | 02 | Every dispatched `{family,dimension}` renders through the real recipe | ✓ VERIFIED | `edge_fixtures.ex` `document/2` + `build/2` per-family clauses; `edge_matrix_test.exs` 62 renders pass |
| 6 | 02 | `document/2`/`build/2` raise `ArgumentError` on unrecognized pair | ✓ VERIFIED | `edge_fixtures.ex:356-357` catch-all `raise ArgumentError` |
| 7 | 02 | 4 EDGE-02 error fixtures built from public structs, zero lib/ edits | ✓ VERIFIED | `overflow_document/tall_row_document/rtl_default_font_document/rtl_shaping_required_document` (lines 95-121); zero lib/ diff |
| 8 | 02 | Money fixtures pass each recipe's `Decimal.equal?/2` caller-assertion | ✓ VERIFIED | Money `build/2` clauses render green in matrix suite (no raise on money cells) |
| 9 | 03 | Built Hex tarball never contains `priv/goldens/` or `priv/raster_refs/` | ✓ VERIFIED | `branding_claims_test.exs:83-84`; test green |
| 10 | 03 | Tarball still contains `lib/` and `priv/branded/` (positive companion) | ✓ VERIFIED | `branding_claims_test.exs:52-59` `assert contents =~ "lib/rendro"` |
| 11 | 04 | All 102 pairs have a `@matrix` entry (`:applies` or N/A reason) | ✓ VERIFIED | D-02 meta-test + "exactly 102 entries" test green |
| 12 | 04 | 62 `:applies` cells each verified by committed SHA-256 golden | ✓ VERIFIED | 62 `.sha256` files on disk; per-cell tests green; "exactly 62 :applies" test green |
| 13 | 04 | Missing golden ref hard-flunks (inherited from 117-01) | ✓ VERIFIED | Uses `Rendro.Test.Golden.assert_or_bless/2` |
| 14 | 04 | `@matrix` exhaustiveness machine-checked vs `@families × @dimensions` | ✓ VERIFIED | `edge_matrix_test.exs:170-177` meta-test |
| 15 | 05 | Overflow raises typed `:content_overflow`, `next =~ "does not auto-fit"`, `details.block` map | ✓ VERIFIED | `edge_error_matrix_test.exs:30-41` green |
| 16 | 05 | Tall row raises SAME typed error via distinct path, `row_height` detail, no `:block` | ✓ VERIFIED | `edge_error_matrix_test.exs:43-60` green |
| 17 | 05 | RTL default shaper → `{:unsupported_glyph, char}` at `:measure` | ✓ VERIFIED | `edge_error_matrix_test.exs:64-72` green |
| 18 | 05 | RTL shaping-capable font → `{:shaping_required, :arab, hint}` at `:measure` | ✓ VERIFIED | `edge_error_matrix_test.exs:74-82` green |
| 19 | 05 | `render/2` never returns `{:ok,_}` for either RTL fixture (regression lock) | ✓ VERIFIED | `edge_error_matrix_test.exs:87-93` two `refute` tests green |
| 20 | 06 | Exactly 6 curated raster fixtures within D-10 ceiling | ✓ VERIFIED | `pdfium_raster_snapshot_test.exs`: inv/stmt/payslip odd_even (3) + cert a4/us_letter (2) + inv extreme-wrap (1) = 6 |
| 21 | 06 | New raster tests live in the existing file (CI path discovery) | ✓ VERIFIED | All added to `test/rendro/adapters/pdfium_raster_snapshot_test.exs` |
| 22 | 06 | Every new raster test reuses the existing `assert_or_bless/2` helper | ✓ VERIFIED | All 6 call file-local `assert_or_bless(...)` |
| 23 | 06 | Every raster fixture proven deterministic before rasterization | ✓ VERIFIED | Fixtures build via `EdgeFixtures` + `Golden.assert_deterministic!/1` guard |
| 24 | 07 | Exactly ONE top-level `stress_exemption` block (exempt, non-empty reason) | ✓ VERIFIED | `rubric_scores.json:82-87`; D-15i test green |
| 25 | 07 | Schema root `required` includes `stress_exemption` (anti-silent-loss) | ✓ VERIFIED | `rubric_scores.schema.json:7` |
| 26 | 07 | No `scores` entry uses `stress_exempt` to dodge the gate (loophole tripwire) | ✓ VERIFIED | D-15ii test green (`scores: []`) |
| 27 | 07 | Stress-fixture ID set disjoint from + non-empty vs `demo_ids` | ✓ VERIFIED | D-15iii/iv tests green; imports `Rendro.EdgeMatrixTest.stress_fixture_ids/0` (size 62) |

**Score:** 27/27 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `test/support/golden.ex` | Un-gated assert/bless + determinism helper | ✓ VERIFIED | 112 lines; both funcs `@spec`'d, `@moduledoc false` |
| `test/support/edge_fixtures.ex` | Fixture builder + 4 error fixtures | ✓ VERIFIED | 592 lines; per-family `document/build/opts` + `ArgumentError` guard |
| `test/rendro/edge_matrix_test.exs` | `@matrix` 102 cells / 62 applies + D-02 | ✓ VERIFIED | 202 lines; meta-tests + 62 generated golden tests |
| `test/rendro/edge_error_matrix_test.exs` | EDGE-02 typed-error assertions | ✓ VERIFIED | 119 lines; 7 tests green |
| `test/docs_contract/branding_claims_test.exs` | Tarball exclusion tripwire | ✓ VERIFIED | goldens/raster refute + lib/branded positive companion |
| `test/docs_contract/rubric_manifest_contract_test.exs` | D-15 guards | ✓ VERIFIED | `require_file` import + 4 D-15 guards |
| `test/rendro/adapters/pdfium_raster_snapshot_test.exs` | +6 raster fixtures | ✓ VERIFIED | 189 lines; 6 `raster_snapshot`-tagged fixtures |
| `priv/quality/rubric_scores.json` | `stress_exemption` block | ✓ VERIFIED | Single top-level block, `exempt: true` |
| `priv/schemas/rubric_scores.schema.json` | schema-required exemption | ✓ VERIFIED | def + root `required` entry |
| `priv/goldens/**` | 62 hash-only refs | ✓ VERIFIED | 62 `.sha256` files, one hex line each |

### Key Link Verification

| From | To | Via | Status |
| --- | --- | --- | --- |
| `edge_matrix_test.exs` | `Rendro.Test.Golden` / `EdgeFixtures` | `assert_deterministic!/1` + `assert_or_bless/2` + `document/2` per cell | ✓ WIRED |
| `edge_error_matrix_test.exs` | `EdgeFixtures` | 4 `<case>_document/0` builders | ✓ WIRED |
| `pdfium_raster_snapshot_test.exs` | `EdgeFixtures` / `Golden` | `document/2`, `build/2`, `opts/2`, `assert_deterministic!/1` | ✓ WIRED |
| `rubric_manifest_contract_test.exs` | `Rendro.EdgeMatrixTest.stress_fixture_ids/0` | `Code.require_file/2` single source of truth | ✓ WIRED |
| `branding_claims_test.exs` | `mix.exs` `files:` allowlist | untar + refute goldens/raster paths | ✓ WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Byte + error + contract + tarball lanes | `mix test <6 files>` | 178 tests, 0 failures | ✓ PASS |
| Zero lib/ changes | `git log --name-only -- lib/` + `git status --porcelain lib/` | empty | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| EDGE-01 | 01, 02, 03, 04, 06 | Deterministic goldens + raster refs + tarball exclusion | ✓ SATISFIED | 62 goldens + 6 raster fixtures + tarball guard, all green |
| EDGE-02 | 02, 05 | Typed errors for overflow/tall-row/RTL | ✓ SATISFIED | `edge_error_matrix_test.exs` 7 tests green |
| EDGE-03 | 07 | Rubric beauty-gate exemption, explicit | ✓ SATISFIED | `stress_exemption` block + schema-required + 4 D-15 guards |

All requirement IDs cross-referenced against `REQUIREMENTS.md` (lines 45-47, 100-102): EDGE-01/02/03 all mapped to Phase 117, all marked Complete. No orphaned requirements — every ID declared in a PLAN `requirements:` field is accounted for, and REQUIREMENTS.md maps no additional EDGE IDs to Phase 117.

### Anti-Patterns Found

None blocking. No `TBD`/`FIXME`/`XXX` debt markers in phase files. The `scores: []` empty array in `rubric_scores.json` is intentional (Phase 118 appends real demo scores; stress fixtures are exempt by construction). Error fixtures returning typed `%Rendro.Error{}` are the product behavior under test, not stubs.

### Human Verification Required

None. All truths are exercised by passing behavioral tests (typed-error state transitions and two-run determinism invariants are proven by the green `edge_error_matrix_test.exs` and `assert_deterministic!/1` guards, not by presence alone).

**Note (not a gap, per phase design):** The 6 pdfium raster refs are blessed only in the pinned CI container (`GITHUB_ACTIONS=true`, `raster_snapshot` tag excluded from default `mix test`). This is the locked advisory-lane design (D-11): byte goldens are the authoritative gating signal; raster is advisory so a pdfium pin bump cannot red-wall the required job. The raster fixtures exist, are correctly structured, and are wired — their pixel-ref blessing is a CI-time step by design, not a codebase gap.

### Gaps Summary

No gaps. Phase goal achieved: the recipe surface is proven robust and deterministic under a 102-cell family × stress-dimension grid (62 hash-checked byte goldens + 6 curated raster fixtures + a coverage-honesty ratchet), overflow/tall-row/RTL each raise instructive typed errors with regression locks, and stress fixtures are explicitly exempt from the rubric beauty gate with schema-enforced, fail-loud contract guards. Zero `lib/` changes — the intended, verified test-only posture.

---

_Verified: 2026-07-19T03:00:09Z_
_Verifier: Claude (gsd-verifier)_
