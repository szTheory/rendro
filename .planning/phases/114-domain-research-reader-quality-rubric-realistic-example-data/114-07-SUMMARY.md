---
phase: 114
plan: 07
subsystem: packaging-docs-contract
tags: [hex-packaging, docs-contract, tarball-assertions, gitignore, guardrails]
requires:
  - "priv/examples/ fixtures + DOMAIN.md (Plans 114-01, 114-03, 114-05)"
  - "priv/schemas/*.schema.json (Plan 114-02)"
  - "priv/quality/rubric_scores.json (Plan 114-06)"
  - "test/docs_contract/examples_schema_contract_test.exs (Plan 114-03)"
  - "test/docs_contract/rubric_manifest_contract_test.exs (Plan 114-06)"
  - "test/docs_contract/domain_md_contract_test.exs (Plan 114-05)"
provides:
  - "priv/examples shipped in Hex tarball (text-only), enforced by mix.exs allowlist + tarball assertion"
  - "priv/schemas + priv/quality kept repo-only, enforced by branding_claims_test.exs refutes"
  - "3 new docs-contract lanes registered in scripts/verify_docs.exs (guardrail count 22 -> 25)"
affects:
  - mix.exs
  - .gitignore
  - scripts/verify_docs.exs
tech-stack:
  added: []
  patterns:
    - "Rendro.Test.HexBuildCache tarball-listing assertion (tar -xOf ... | tar -tzf -)"
    - "asymmetric priv/ packaging: priv/examples ships, priv/schemas + priv/quality repo-only"
    - ".gitignore raster/binary extension-ban block per text-only tree"
key-files:
  created:
    - .planning/phases/114-domain-research-reader-quality-rubric-realistic-example-data/deferred-items.md
  modified:
    - mix.exs
    - .gitignore
    - test/docs_contract/examples_schema_contract_test.exs
    - test/docs_contract/branding_claims_test.exs
    - scripts/verify_docs.exs
    - test/guardrails/required_checks_contract_test.exs
decisions:
  - "114-RESEARCH Pitfall 5 either/or resolved as REGISTER: the 3 new docs-contract test files are formal verify_docs.exs lanes (EXL-03/RUB-01/RUB-03 each use the phrase 'docs-contract lane')."
  - "branding_claims_test.exs and public_api_contract_test.exs were NOT added as lanes (neither was in the 22-lane set); extending them does not change lane count."
metrics:
  duration_minutes: 3
  tasks_completed: 4
  files_changed: 6
  completed_date: 2026-07-11
requirements: [EXL-05, EXL-03, RUB-01, RUB-03]
status: complete
---

# Phase 114 Plan 07: Hex Packaging Boundary + Docs-Contract Lane Registration Summary

Proves the shipped Hex package respects the example/schema packaging boundary in both directions — `priv/examples/` ships text-only, `priv/schemas/` and `priv/quality/` never leak — and registers this phase's three new docs-contract test files as formal `verify_docs.exs` lanes (count 22 → 25).

## What Was Built

- **Task 1 (`cfebad3`)** — Added `"priv/examples"` to `mix.exs` `package/0` `:files` allowlist immediately after `priv/branded`; deliberately left `priv/schemas`/`priv/quality` out (repo-only). Appended a `.gitignore` block banning the same 11 raster/binary extensions under `priv/examples/**` that the existing `brand/` block bans. `mix compile --warnings-as-errors` still clean.
- **Task 2 (`9cc559d`)** — Added a `describe "hex tarball contents"` block to `examples_schema_contract_test.exs`: builds the real tarball via `Rendro.Test.HexBuildCache.get_build_output()`, lists it with `tar -xOf … contents.tar.gz | tar -tzf -`, filters to `priv/examples/` entries, asserts non-empty, and asserts every entry's `Path.extname/1` is `.json`/`.md`/`.svg`. 3 tests pass.
- **Task 3 (`db9eb11`)** — Added three `refute contents =~ …` lines to the existing tarball-exclusion test in `branding_claims_test.exs` for `priv/schemas/examples.schema.json`, `priv/schemas/rubric_scores.schema.json`, and `priv/quality/`. 9 tests pass.
- **Task 4 (`48a67f8`)** — Registered `Examples schema contract lane`, `Rubric manifest contract lane`, and `Domain content contract lane` in `scripts/verify_docs.exs` after the DX lane; bumped `required_checks_contract_test.exs`'s hardcoded assertion `22 → 25` and updated its test-name string ("twenty-two" → "twenty-five"). Guardrail suite: 16 tests pass. All three new lanes PASS when `verify_docs.exs` runs.

## Verification Results

- `mix test test/docs_contract/examples_schema_contract_test.exs` — 3 tests, 0 failures.
- `mix test test/docs_contract/branding_claims_test.exs` — 9 tests, 0 failures.
- `mix test test/guardrails/required_checks_contract_test.exs` — 16 tests, 0 failures.
- `grep -c` acceptance checks for Task 4 (3 new lanes present, count == 25 present) all pass.
- `mix run scripts/verify_docs.exs` — all three new lanes PASS. One pre-existing, unrelated lane fails (see Deferred Issues).

## Deviations from Plan

None to the plan's own tasks. Plan executed exactly as written.

## Deferred Issues

**1. [Out of scope] Comparison claims lane fails on stale generated guide block**
- **Found during:** Task 4 (`mix run scripts/verify_docs.exs` phase-gate check).
- **Issue:** `test/docs_contract/comparison_claims_test.exs:56` fails — the checked-in comparison guide block still references the old benchmark scenario path `bench/comparison/fixtures/invoice_data.json`, while `Rendro.Comparison.evidence_block/1` now generates `priv/examples/invoice/acme-phoenix-saas/invoice.json`.
- **Root cause:** Plans 114-01/114-03 repointed the comparison benchmark fixture but did not regenerate the checked-in comparison guide markdown. Not caused by Plan 114-07 — none of this plan's six touched files relate to the comparison guide.
- **Disposition:** Logged to `deferred-items.md`; NOT fixed here per the executor scope boundary (pre-existing failure in an unrelated file). Needs the comparison guide regenerated before the phase-gate `mix ci.fast` / `verify_docs.exs` goes fully green.

## Threat Mitigations Applied

- **T-114-07-01 (Info Disclosure — schemas/quality shipping):** Task 3 refutes fail CI if either new schema or the rubric manifest appears in the tarball; Task 1 keeps them out of the `:files` list.
- **T-114-07-02 (Tampering — non-text asset shipping):** Task 1 `.gitignore` block blocks committing raster files under `priv/examples/**`; Task 2 tarball text-only assertion independently re-verifies every shipped entry's extension, closing the `git add -f` bypass gap.
- **T-114-07-03 (accepted):** Reuses existing `Rendro.Test.HexBuildCache` infra shared with `branding_claims_test.exs`; no new attack surface.

## Self-Check: PASSED

- FOUND: mix.exs (priv/examples in allowlist)
- FOUND: .gitignore (priv/examples raster-ban block)
- FOUND: test/docs_contract/examples_schema_contract_test.exs (tarball describe block)
- FOUND: test/docs_contract/branding_claims_test.exs (3 new refutes)
- FOUND: scripts/verify_docs.exs (3 new lanes)
- FOUND: test/guardrails/required_checks_contract_test.exs (count == 25)
- FOUND commit: cfebad3, 9cc559d, db9eb11, 48a67f8
