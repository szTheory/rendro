---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
plan: 06
subsystem: quality-rubric
tags: [rubric, scoring, pdfium, raster, quality-gate, elixir]

# Dependency graph
requires:
  - phase: 118-05
    provides: "7-tile re-blessed gallery — the rasterized demo renders scored here"
  - phase: 118-02
    provides: "per-family DOMAIN.md anchors cited by each score entry"
provides:
  - "test/docs_contract/demo_cites_domain_md_test.exs — D-05 citation contract (every score cites an existing DOMAIN.md; every demonstrated domain is cited)"
  - "Six honest rubric score entries in priv/quality/rubric_scores.json (schema-valid, justified, DOMAIN.md-cited)"
  - "118-06-FINDINGS.md — the per-demo, per-dimension gap analysis behind the scores"
affects: [118-07, gap-closure]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Honest rubric self-scoring against the actual rasterized render (D-11): passing is earned, sub-threshold demos are surfaced as findings, never scored up"
key-files:
  created:
    - test/docs_contract/demo_cites_domain_md_test.exs
    - .planning/phases/118-rubric-gated-demonstration-set-gallery-docs-closure/118-06-FINDINGS.md
  modified:
    - priv/quality/rubric_scores.json

key-decisions:
  - "D-11 honesty enforced: all six demos scored passed=false because none reaches content_hierarchy==5 + all other cores>=4 + gates. Scores were NOT inflated to make the gate pass."
  - "Demo-quality remediation deliberately deferred to a focused gap-closure follow-up rather than improvised mid-execute — it spans transform_invoice (118-03), the LaunchArtifacts repoint (118-04), and six recipe layouts, and needs a determinism re-bless per change. Catalogued in 118-06-FINDINGS.md."

patterns-established:
  - "Score against the render, cite the DOMAIN.md, justify every dimension; compute passed via the shared passed?/2 arithmetic, never assert it."

requirements-completed: []  # SHOW-01's gate is NOT met by these scores — surfaced as a gap, not claimed complete.
---

## Accomplishments

- **D-05 citation contract (test-first).** `demo_cites_domain_md_test.exs` asserts every score
  entry carries a `domain_md` path that exists on disk and that every demonstrated domain
  (derived from `priv/examples/*/*/*.json`, never hardcoded) is cited by at least one entry, with
  a non-vacuity guard.
- **Six honest rubric self-scores** appended to `priv/quality/rubric_scores.json`. Each was scored
  against the 96-dpi rasterized render (the 118-05 gallery PNGs) with a per-dimension
  `justifications` object and a `domain_md` citation. `passed` computed by the exact `passed?/2`
  arithmetic; `demo_id`s use the `<family>-<business>` namespace (disjoint from the 62 stress ids);
  no entry sets `stress_exempt`.

| demo_id | IA | CH | DF | RA | TC | RC | passed |
|---------|----|----|----|----|----|----|--------|
| invoice-acme-phoenix-saas | 2 | 2 | 2 | 3 | 3 | 3 | false |
| statement-northwind-ledger-co | 4 | 3 | 4 | 4 | 4 | 4 | false |
| receipt-harbor-and-oak-cafe | 3 | 3 | 3 | 4 | 4 | 4 | false |
| certificate-summit-training-institute | 3 | 3 | 3 | 3 | 3 | 2 | false |
| payslip-aurora-live | 3 | **5** | 4 | 3 | 3 | 4 | false |
| ticket-aurora-live | 4 | 4 | 4 | 4 | 4 | 3 | false |

## Finding (D-11): the demonstration set does not clear the rubric gate

None of the six demos honestly reaches `content_hierarchy == 5` AND all other cores `>= 4` AND both
gates. Per D-11 the scores were recorded honestly (all `passed=false`), not inflated. The biggest
gap is the **invoice**, which is under-built — `transform_invoice` feeds the recipe only items +
header, dropping the issuer/customer/totals the fixture contains and the recipe supports, and money
renders as `$79.0`. The other demos are realistic and clean but do not make their one key fact
visually dominant. Full per-demo, per-dimension analysis and remediation guidance: **118-06-FINDINGS.md**.

**Implication:** SHOW-01 (the rubric-gated demonstration set) is **not** satisfied by these scores.
This is surfaced deliberately as a gap for phase verification to route to a focused gap-closure
phase, where the recipe/transform/fixture improvements can be planned and researched properly.

## Verification

- `mix test test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/demo_cites_domain_md_test.exs` — green (schema validation, `passed?/2` arithmetic, D-15 disjointness/teeth, D-05 citations).
- `mix test test/docs_contract/` — 274 tests + 1 doctest, 0 failures.
- Scoring evidence: the six 96-dpi renders in `assets/rendro/gallery/` (rasterized via the pinned pdfium wasm build; determinism proven in 118-05).
