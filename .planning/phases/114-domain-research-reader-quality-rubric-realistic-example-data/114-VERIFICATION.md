---
phase: 114-domain-research-reader-quality-rubric-realistic-example-data
verified: 2026-07-11T00:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification:

  - test: "Read priv/examples/invoice/DOMAIN.md end-to-end and judge whether the domain language, personas+JTBD, reading context, and layout/typographic conventions are genuinely faithful Invoice domain research (RUB-01) rather than plausible-looking filler."
    expected: "The prose reads as accurate, specific domain knowledge an AP clerk / issuer / bookkeeper would recognize; the 'ONE fact the reader needs first' (total due + due date) is correctly identified."
    why_human: "Structural test proves the four required headings exist and are substantive (94 lines), but faithfulness of synthesized domain-research prose (flagged MEDIUM/LOW confidence in 114-RESEARCH.md, human_judgment:true in 114-05 SUMMARY) is a subjective quality judgment grep cannot make."

  - test: "Read the 6 dimensions' 1/3/4/5 anchor prose in priv/quality/rubric_scores.json (RUB-02) and confirm a non-designer could actually apply each anchor to score a rendered document."
    expected: "Each anchor is concrete and observable (e.g. 'the one fact the reader needs first is visually dominant'), not vague design jargon — a non-designer can pick a level without training."
    why_human: "The schema/contract test enforces exactly-6-dimensions/2-gates and threshold arithmetic structurally, but whether the anchor wording is genuinely non-designer-applicable is a subjective usability judgment."
---

# Phase 114: Domain research, reader-quality rubric & realistic example-data library — Verification Report

**Phase Goal:** Establish the milestone's data + quality foundation — a realistic, schema-validated example corpus with a load-bearing loader, per-domain domain research, and an appendable reader-quality rubric — with NO `lib/` product change except the `@moduledoc false` loader.
**Verified:** 2026-07-11
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Fixtures at `priv/examples/<domain>/<business>/<family>.json` encode domain language + real-shaped fictional business (addresses, terms, tax), money as Decimal-safe strings (never floats), optional empty `brand`/`logo` slot (S4); validate against repo-only `examples.schema.json` via a docs-contract lane in the `test` job. | ✓ VERIFIED | `priv/examples/invoice/acme-phoenix-saas/invoice.json` present: issuer/customer w/ full addresses, `invoice.terms "Net 30"`, `totals.tax "379.20"`, all money as `"79.00"`-style strings (`grep -c _cents` = 0), `"brand": {"logo": null}` present. Schema has 0 `"type":"number"` money fields, 5 `money_string` refs. `examples_schema_contract_test.exs` passes (fixture validates + non-empty wildcard guard). Registered as `verify_docs.exs` lane. |
| 2 | `Rendro.Examples` loader (`lib/rendro/examples.ex`, `@moduledoc false`) reads fixtures via `app_dir`, asserted absent from `priv/public_api.json`. | ✓ VERIFIED | `lib/rendro/examples.ex` has `@moduledoc false`, `Application.app_dir(:rendro, "priv/examples")`, `JSON.decode!` (0 `Jason` refs), `Path.safe_relative` ×3. Behavioral spot-check: `load!("invoice/acme-phoenix-saas/invoice.json")` → `fixture_id=invoice_v1`; `list("invoice")` → 1 path; traversal `../../../etc/passwd` → `ArgumentError` (REJECTED_OK). `Rendro.Examples` absent from `priv/public_api.json` (0 refs) and `api.gen.ex @public_modules` (0); asserted `:hidden` in `public_api_contract_test.exs` (passes). |
| 3 | Invoice fixture de-quarantined from `bench/comparison/fixtures/invoice_data.json` into the library, bench repointed, `mix rendro.comparison.check` green — provable no-op (money-string normalization separate). | ✓ VERIFIED | Old path gone (`ls` = No such file). `git log` confirms move (6ecb4f6) + repoint (47ee0b5) as separate commits from money normalization (16f5da3), per Pitfall 6. `mix rendro.comparison.check` → "Comparison benchmark evidence VERIFIED" exit 0. No stale `fixtures/invoice_data.json` refs remain outside recorded raw evidence. |
| 4 | `priv/examples/` ships in Hex tarball text-only (`.json`/`.md`/`.svg`), added to `mix.exs` allowlist + tarball audit, raster-ban mirroring `brand/`. | ✓ VERIFIED | `mix.exs` `:files` has `priv/examples` (after `priv/branded`), 0 refs to `priv/schemas`/`priv/quality`. `.gitignore` bans 11 raster/binary extensions under `priv/examples/**`. `examples_schema_contract_test.exs` "hex tarball contents" test runs a real `mix hex.build` (337ms) and passes (ships + text-only). `branding_claims_test.exs` refutes `priv/schemas/*` + `priv/quality/` from tarball (9 tests pass). |
| 5 | Co-located `DOMAIN.md` (domain language, personas+JTBD, reading context, layout/typographic conventions) + reader-quality rubric (6 core 1–5 dims + 2 gates, non-designer anchors) as schema-backed appendable manifest whose docs-contract lane enforces structure + threshold arithmetic (hierarchy=5, core≥4, gates pass) — not subjective score (S5). | ✓ VERIFIED | `DOMAIN.md` (94 lines) has all 4 required `## ` headings, substantive content. `rubric_scores.json`: 6 dims + 2 gates (8 `"id"`), 24 anchor entries (6×4), `"scores": []` empty appendable. `rubric_manifest_contract_test.exs` passes: schema validation + structural enumeration + threshold-arithmetic on synthetic inputs (helper is test-only, no `lib/` module). `domain_md_contract_test.exs` passes. See Human Verification for prose-quality sanity-check. |

**Score:** 5/5 truths verified (0 present, behavior-unverified). Human sanity-check items raised on subjective prose quality (does not lower the structural score).

### Phase Boundary: "NO lib/ product change except the loader"

✓ VERIFIED. Across every phase-114 commit (17 commits), the ONLY file under `lib/` touched is `lib/rendro/examples.ex` (added in 24e0c7e). The post-merge fix c4e122e touched only `guides/comparison.md`. All other changes are under `priv/`, `test/`, `bench/`, `scripts/`, `mix.exs`, `.gitignore`.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/examples.ex` | `@moduledoc false` loader, `load!/1` + `list/1`, `JSON` (not `Jason`), `Path.safe_relative` guards | ✓ VERIFIED | Substantive (51 lines), wired (used by tests + spot-check), behaviorally exercised. |
| `priv/examples/invoice/acme-phoenix-saas/invoice.json` | Normalized string money, brand slot, real-shaped | ✓ VERIFIED | Loads to real data; validated by schema lane. |
| `priv/examples/invoice/DOMAIN.md` | 4 required headings, genuine content | ✓ VERIFIED (structure) | 94 lines; prose faithfulness → human. |
| `priv/schemas/examples.schema.json` | draft 2020-12, `money_string`, S4 brand slot | ✓ VERIFIED | 0 numeric money types; builds via `JSV.build!`. |
| `priv/schemas/rubric_scores.schema.json` | 6 dims + 2 gates enum, hierarchy_min=5/core_min≥4 | ✓ VERIFIED | Builds; enforces constants. |
| `priv/quality/rubric_scores.json` | 6 dims + 2 gates + anchors + empty scores | ✓ VERIFIED | Validates against schema; `scores: []`. |
| `test/rendro/examples_test.exs` | loader behavior + extension-ban | ✓ VERIFIED | Passes (part of 44-test run). |
| `test/docs_contract/*_contract_test.exs` (3 new + 2 extended) | schema/tarball/heading/arithmetic lanes | ✓ VERIFIED | All pass. |
| `mix.exs` / `.gitignore` | allowlist + raster-ban | ✓ VERIFIED | Correct asymmetric packaging. |
| `scripts/verify_docs.exs` / guardrail | 3 new lanes, count 22→25 | ✓ VERIFIED | 3 new lanes present; `lane_entries == 25`; guardrail test passes. |

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| `Rendro.Examples.load!/1` | `priv/examples` | `Application.app_dir/2` → `Path.safe_relative` → `File.read!`/`JSON.decode!` | WIRED (spot-checked) |
| fixture | `examples.schema.json` | `examples_schema_contract_test.exs` JSV validate loop | WIRED |
| `rubric_scores.json` | `rubric_scores.schema.json` | `rubric_manifest_contract_test.exs` | WIRED |
| bench consumers | de-quarantined fixture | `@fixture_path` + literal repoints | WIRED (comparison.check green) |
| 3 new tests | `verify_docs.exs` lanes | `lanes` list + guardrail count 25 | WIRED |
| `guides/comparison.md` | new fixture path | c4e122e resync | WIRED (comparison_claims_test 10/0) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Loader reads real fixture | `Rendro.Examples.load!(...)` | `fixture_id=invoice_v1` | ✓ PASS |
| Domain listing | `Rendro.Examples.list("invoice")` | 1 path | ✓ PASS |
| Path-traversal rejection | `load!("../../../etc/passwd")` | `ArgumentError` | ✓ PASS |
| Comparison evidence | `mix rendro.comparison.check` | VERIFIED, exit 0 | ✓ PASS |
| Hex tarball ships text-only | tarball describe test (real `hex.build`) | pass (337ms) | ✓ PASS |
| Phase test lanes | `mix test` (7 files) | 44 tests, 0 failures | ✓ PASS |
| Deferred comparison-claims regression | `mix test comparison_claims_test.exs` | 10 tests, 0 failures | ✓ PASS (resolved by c4e122e) |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| EXL-01 | 114-03 | ✓ SATISFIED | String money fixture, real-shaped fictional business. |
| EXL-02 | 114-04 | ✓ SATISFIED | Loader `@moduledoc false`, absent from public_api.json, `:hidden` asserted. |
| EXL-03 | 114-02, 114-03, 114-07 | ✓ SATISFIED | `examples.schema.json` + validation lane registered in `verify_docs.exs`. |
| EXL-04 | 114-01 | ✓ SATISFIED | Provable no-op de-quarantine; comparison.check green. |
| EXL-05 | 114-04, 114-07 | ✓ SATISFIED | In-repo extension-ban + real-tarball text-only assertion. |
| EXL-06 | 114-03 | ✓ SATISFIED | Optional empty `brand`/`logo` slot on fixture + schema. |
| RUB-01 | 114-05 | ✓ SATISFIED (structure); prose → human | DOMAIN.md + heading contract lane. |
| RUB-02 | 114-06 | ✓ SATISFIED (structure); anchors → human | 6 dims + 2 gates + anchors in manifest. |
| RUB-03 | 114-02, 114-06, 114-07 | ✓ SATISFIED | Schema-backed appendable manifest + threshold-arithmetic lane. |

All 9 declared requirement IDs are accounted for in PLAN frontmatter and match REQUIREMENTS.md's Phase-114 mapping (9 reqs). No orphaned requirements.

### Anti-Patterns Found

None. No `TBD`/`FIXME`/`XXX`/`HACK`/`PLACEHOLDER`/"not yet implemented" markers in any phase-created source file. The `brand.logo: null` is an intentional documented S4 seam (EXL-06), not a stub. The empty `scores: []` array is the intentional S5 appendable seam (RUB-03).

### Note on `deferred-items.md`

`deferred-items.md` logged the `comparison_claims_test.exs:56` regression (guide referenced the old fixture path) as out-of-scope for Plan 114-07. This was subsequently closed by post-merge commit **c4e122e** (resync of `guides/comparison.md`). Re-run confirms `comparison_claims_test.exs` now passes 10/0. The deferred item is **resolved**, not an open gap.

### Human Verification Required

Two light, non-blocking prose-quality sanity-checks — reserved by the planner (114-05 marks `human_judgment: true`) because the domain-research/anchor prose is synthesized (MEDIUM/LOW confidence per 114-RESEARCH.md) and its faithfulness cannot be verified programmatically. All structural contracts and the code boundary are already VERIFIED.

1. **DOMAIN.md domain-research faithfulness (RUB-01)** — Read `priv/examples/invoice/DOMAIN.md`; confirm the content is genuine Invoice domain knowledge, not plausible filler. Expected: an AP clerk / issuer / bookkeeper would recognize the personas and the "total due + due date first" reading model.
2. **Rubric anchor applicability (RUB-02)** — Read the 1/3/4/5 anchors in `priv/quality/rubric_scores.json`; confirm a non-designer could actually apply each level.

### Gaps Summary

No gaps. All 5 ROADMAP success criteria and all 9 requirements are structurally verified against the codebase; the phase's defining boundary ("no `lib/` product change except the loader") holds exactly. Behavioral checks (loader, comparison.check, real hex.build tarball, 44 tests) all pass. Status is `human_needed` solely for the two subjective prose-quality sanity-checks the planner explicitly reserved for phase verification — not for any missing, stub, or unwired artifact.

---

_Verified: 2026-07-11_
_Verifier: Claude (gsd-verifier)_
