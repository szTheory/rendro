---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
plan: 08
subsystem: demo-composition
tags: [invoice, statement, receipt, certificate, payslip, ticket, gap-closure, SHOW-01]
status: complete

dependency-graph:
  requires:
    - lib/rendro/examples_data.ex (118-03 transform seam)
    - lib/rendro/recipes/*.ex (all six family recipes, 114-116)
    - priv/examples/**/*.json (118-01/02 fixtures)
  provides:
    - Enriched transform_invoice/1 (issuer/customer/due_date/terms/totals passthrough, faithful money)
    - Dominant-key-fact composition for all six demo families
    - Native-A6 Ticket page size (Rendro.PageSize gains :a6)
    - De-crowded Payslip earnings/deductions table
  affects:
    - lib/rendro/launch_artifacts.ex (gallery/demo source path; one text-wrap regression fix)
    - assets/rendro/artifacts.json (source-PDF hashes now stale, container-gated re-bless required)
    - priv/goldens/** (117 edge-matrix byte-identity goldens re-blessed)

tech-stack:
  added:
    - Rendro.PageSize :a6 (297.64 x 419.53pt portrait)
    - Invoice/Receipt data-derived :header_height opt (grows only when anatomy fields present)
  patterns:
    - Dominant key-fact composition (large isolated block, muted supporting block) — Invoice Total Due, Receipt Total, Statement closing balance
    - Explicit block :width on every free-standing text block so realistic (non-toy) content wraps instead of raising :content_overflow

key-files:
  created: []
  modified:
    - lib/rendro/examples_data.ex
    - lib/rendro/recipes/invoice.ex
    - lib/rendro/recipes/statement.ex
    - lib/rendro/recipes/receipt.ex
    - lib/rendro/recipes/certificate.ex
    - lib/rendro/recipes/payslip.ex
    - lib/rendro/recipes/ticket.ex
    - lib/rendro/page_size.ex
    - lib/rendro/launch_artifacts.ex
    - priv/schemas/examples.schema.json
    - priv/examples/invoice/acme-phoenix-saas/invoice.json
    - priv/examples/receipt/harbor-and-oak-cafe/receipt.json
    - priv/goldens/{invoice,statement,certificate,payslip,ticket}/*.sha256 (39 files)
    - test/rendro/examples_data_test.exs
    - test/rendro/recipes/{invoice,statement,receipt,certificate,payslip,ticket}_test.exs
    - test/rendro/recipes/{invoice,payslip,ticket}_byte_identity_test.exs
    - test/rendro/launch_artifacts_test.exs

decisions:
  - "Invoice/Receipt header height is now computed from `data` (conservative per-optional-field budget) rather than a fixed constant, threaded through document/2 into page_template/1 and the body capacity math — the frozen INV-01 toy-call byte-identity golden is preserved exactly (no anatomy fields -> exact frozen default height)."
  - "Ticket defaults to native A6 (Rendro.PageSize gained :a6) instead of A4; every free-standing header/terms text block now carries an explicit width so realistic content wraps instead of overflowing the smaller region; @band_ratio lowered from 2.4 to 2.0 so a full realistic ticket's main-region content fits (absolute pt font sizes don't shrink with the page)."
  - "Payslip's data-row cells are now explicit size-11 Rendro.Block/Text (matching the subtotal row) instead of bare (default size-12) strings — both a consistency fix and what actually freed enough column budget to widen the YTD amount columns without starving the description columns."
  - "Rendro.LaunchArtifacts.constrain_text_width/2 now only overwrites a block's width when it is still nil — a block that already carries an explicit width (e.g. Certificate's centered blocks) is left alone, since overwriting width while leaving a centering x offset in place produced a new :content_overflow."

metrics:
  duration: ~70min
  completed: 2026-07-19
---

# Phase 118 Plan 08: Rubric demo composition rework (SHOW-01 gap closure) Summary

Reworked all six family x domain demonstration documents (Invoice, Statement, Receipt,
Certificate, Payslip, Ticket) per 118-06-FINDINGS.md so each family's one key fact is
visually dominant, invoice money is faithful 2-decimal cents with no lossy Decimal
coercion, and every previously-cramped/overflowing layout renders cleanly end-to-end.
This plan is composition-only — no rubric scores were touched (D-11: honest re-scoring
is 118-09's job).

## What was built

**Task 1 — Invoice overhaul.** `transform_invoice/1` now passes issuer, customer,
due_date, terms, and totals through to `Rendro.Recipes.Invoice` (previously only
id/date/items reached the recipe, so the recipe's existing issuer_block/
customer_block/build_totals_blocks never fired). The invoice's legacy `:price` slot
now also accepts `%Decimal{}` (formatted via `Rendro.Format.money/1`), eliminating the
`$79.0` one-decimal money defect while keeping the frozen INV-01 bare-number toy path
byte-identical. "Total Due" now renders alone in its own large (size 20), accent-colored
block, separate from a small muted Subtotal/Tax/Discount block. The invoice fixture's
36 identical filler rows became 5 distinct SaaS line items (platform plan, seat
licenses, priority support, analytics, API overage) reconciling to subtotal/tax/total.

**Task 2 — Statement/Receipt/Certificate key-fact dominance.** Statement's header now
renders a dominant boxed closing-balance summary (size 22, mirrors Payslip's Net Pay
box) derived from the exact Decimal fold. Receipt's header now renders the merchant
identity (previously entirely absent from the data path — `transform_receipt/1` gained
a `:merchant` passthrough and `examples.schema.json` gained an optional
`$defs/party`-typed `merchant` field), and the Total now renders in its own dominant
block. Certificate now centers all content vertically (an estimated top spacer, derived
from measured font metrics) and horizontally (exact `Rendro.PDF.Font.text_width/3`
centering) within the border; the recipient name is now the dominant element (34pt vs.
the title's 20pt); the body paragraph is width-constrained to 68% of the region so it no
longer runs edge-to-edge.

**Task 3 — Payslip de-crowd + Ticket native A6.** Payslip's earnings/deductions data
cells now render at an explicit, consistent size 11 (matching the subtotal row —
previously bare strings defaulted to size 12); the YTD amount columns widened from 55pt
to 60pt (the exact defect: "$25,200.00" measured 55.044pt in its own 55pt column,
wrapping a digit); a narrow spacer column now separates the earnings and deductions
header groups. Ticket gained native A6 support (`Rendro.PageSize` gained `:a6`,
297.64 x 419.53pt) as its new default page size instead of A4 (fixing the ~65% empty
canvas defect); margins, stub text sizes, and the band-height ratio were all re-tuned
for the smaller physical size; the placement-grid values were bumped to 26pt so the
whole grid reads as the page's one dominant anchor.

## Deviations from Plan

### Auto-fixed issues (Rule 1 — bugs discovered running the full render pipeline)

**1. [Rule 1] Invoice/Receipt header region overflow with real anatomy fields**
- **Found during:** post-Task-3 full-suite verification (`mix test`), not caught by
  the recipe unit test suites, which build `%Rendro.Document{}` structs but never call
  `Rendro.render/1` (the only place pagination/overflow checks run).
- **Issue:** the frozen header region heights (Invoice 56pt, Receipt 48pt) were sized
  for the pre-118-08 2-3 line toy headers. With issuer/customer/due_date/terms
  (Invoice) or merchant (Receipt) actually present, header content exceeded the region.
- **Fix:** both recipes now compute a data-derived header height (conservative
  per-optional-field budget) threaded through `document/2` into `page_template/1` and
  the body capacity math. A toy call (no optional fields) still computes the exact
  frozen default — Invoice's INV-01 byte-identity golden is unchanged.
- **Files:** `lib/rendro/recipes/invoice.ex`, `lib/rendro/recipes/receipt.ex`
- **Commit:** `841b472`

**2. [Rule 1] Ticket main-region text overflow at the new A6 size**
- **Found during:** rendering the realistic aurora-live ticket fixture end-to-end.
- **Issue:** free-standing issuer/title/subtitle/terms text blocks measured at their
  natural (unwrapped) width, which fit comfortably in the prior A4-sized `:main`
  region but overflowed the much narrower A6 region.
- **Fix:** every such block now carries an explicit `width:`, allowing wrap; the
  stub's reference/caption text sizes were reduced and `@band_ratio` lowered from 2.4
  to 2.0 so the full realistic content fits vertically.
- **Files:** `lib/rendro/recipes/ticket.ex`
- **Commit:** `7da9cff`

**3. [Rule 1] launch-only text-wrap post-process clobbered Certificate's centering**
- **Found during:** `mix test test/docs_contract/launch_artifacts_claims_test.exs`.
- **Issue:** `Rendro.LaunchArtifacts.constrain_text_width/2` unconditionally
  overwrote every text block's width to the region width; Certificate's new centered
  blocks carry a deliberate `x` offset, so overwriting width alone (leaving `x`
  untouched) produced `x + width > region width` — `:content_overflow`.
- **Fix:** the post-process now only touches a block whose width is still `nil`.
- **Files:** `lib/rendro/launch_artifacts.ex`
- **Commit:** `c0236bc`

**4. [Rule 1] Stale test expectations/collectors after legitimate content changes**
- Two `test/rendro/launch_artifacts_test.exs` assertions referenced content this plan
  intentionally changed (the invoice fixture's old "Monthly platform service" filler
  text; the payslip table-cell text collector assumed bare-string cells, but Payslip's
  cells are now `%Rendro.Block{%Rendro.Text{}}`). Updated both to the new, correct
  expectations.
- **Commit:** `c0236bc`

**5. [Rule 1] Phase-117 edge-matrix byte-identity goldens re-blessed**
- 39 golden SHA-256 refs across invoice/statement/certificate/payslip/ticket (no
  receipt — its geometry was unchanged) drifted as a direct, legitimate consequence of
  this plan's recipe changes. Re-blessed via
  `MIX_GOLDEN_BLESS=true mix test test/rendro/edge_matrix_test.exs` (un-gated per
  117-01's cross-platform-stable PDF-byte-hash doctrine).
- **Commit:** `ddd970b`

### Known deferred item (container-gated, not fixable in this environment)

`assets/rendro/artifacts.json`'s gallery source-PDF SHA-256 hashes are now stale for
the same legitimate reason (39 golden re-bless above). Regenerating them requires
`mix rendro.launch_artifacts.gen`, which needs the pinned `pdfium-cli` executable —
unavailable in this environment (`{:missing_executable, "pdfium-cli"}`), matching the
same container-gated limitation the 118-05/118-06 plans already documented. As a
result, `test/docs_contract/launch_artifacts_claims_test.exs`'s "static contract is
current" test currently fails with 7 hash-drift errors (invoice, branded_invoice,
statement, receipt_report, certificate, payslip, ticket) and no render-failure errors.
**Next step:** run `mix rendro.launch_artifacts.gen` in the pinned pdfium
CI/container environment, then re-verify this test is green.

## Verification results

```
mix test test/rendro/recipes/ test/rendro/examples_data_test.exs \
  test/docs_contract/examples_schema_contract_test.exs \
  test/rendro/launch_artifacts_test.exs test/rendro/edge_matrix_test.exs
# 3 doctests, 376 tests, 0 failures

grep -nE 'Decimal\.to_float|Decimal\.to_integer' lib/rendro/examples_data.ex
# 4 matches, all in comments (documenting the absence) — no invoice money-path hit

mix format --check-formatted lib/rendro/examples_data.ex lib/rendro/recipes/*.ex
# clean, no new formatting debt

git diff --stat priv/quality/rubric_scores.json
# (empty) — untouched, per D-11

mix test  # full project suite
# 12 doctests, 4 properties, 1569 tests, 1 failure (26 excluded)
# The 1 failure is the known, documented, container-gated
# launch_artifacts_claims_test.exs hash-drift item above.
```

## Self-Check

- FOUND: lib/rendro/examples_data.ex
- FOUND: lib/rendro/recipes/invoice.ex
- FOUND: lib/rendro/recipes/statement.ex
- FOUND: lib/rendro/recipes/receipt.ex
- FOUND: lib/rendro/recipes/certificate.ex
- FOUND: lib/rendro/recipes/payslip.ex
- FOUND: lib/rendro/recipes/ticket.ex
- FOUND: lib/rendro/page_size.ex
- FOUND: lib/rendro/launch_artifacts.ex
- FOUND: priv/schemas/examples.schema.json
- FOUND: priv/examples/invoice/acme-phoenix-saas/invoice.json
- FOUND: priv/examples/receipt/harbor-and-oak-cafe/receipt.json
- FOUND commit: 20e45ee (Task 1: invoice overhaul)
- FOUND commit: 2670917 (Task 2: statement/receipt/certificate dominance)
- FOUND commit: 7da9cff (Task 3: payslip de-crowd + ticket A6)
- FOUND commit: 841b472 (fix: invoice/receipt header overflow)
- FOUND commit: c0236bc (fix: launch_artifacts text-wrap regression)
- FOUND commit: ddd970b (chore: edge-matrix golden re-bless)

## Self-Check: PASSED
