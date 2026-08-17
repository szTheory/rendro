---
schema_version: 1
open_count: 9
waived_count: 0
fixed_count: 3
total_count: 12
last_updated: 2026-08-17T01:25:59.289Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 123 | deviation | lib/rendro/recipes/invoice.ex |  | invoice_dark gallery row: item/qty/price table body cells render via bare strings (no per-cell color), so they inherit a fixed default black text color rather than colors.ink -- illegible against the dark background. Root cause: Rendro.Table cells accept Block or String, but Invoice.body_section builds plain-string rows. Fix requires wrapping cells in themed Block+Text without breaking the frozen INV-01 byte-identity golden -- deferred to a follow-up plan, not fixed in 123-03 (out of scope, risk to frozen golden). | open |  | 2026-07-28T19:39:59.602Z |  |
| 2 | 123 | deviation | lib/rendro/recipes/ticket.ex |  | ticket/ticket_dark: the uniform themed type scale inverts the intended visual hierarchy -- the reference-code display anchor (scale.display, native 8pt) jumps to 21pt themed, now LARGER than the placement-grid title role (scale.title, native 26pt but 16.5pt themed) that the 2026-07-19 rubric actually scored as dominant. The reference code also now wraps awkwardly across 3 lines in its narrow stub column (AUR-8 / 8213- / GA). Flagged for the Plan 05 human sign-off -- not fixed in 123-03 (Q3's non-monotone role assignment is a locked Phase-122 decision; re-mapping is an architectural call, not a gallery-closure fix). | open |  | 2026-07-28T19:40:14.182Z |  |
| 3 | 123 | deviation | lib/rendro/recipes/payslip.ex |  | payslip themed render: earnings/deductions table numeric cells (e.g. $4,200.00, $4,550.00) wrap mid-number onto a second line ($4,200.0 / 0) in the Current/YTD columns at the themed 10.5pt body scale + 1.35 leading -- a new typographic_craft awkward-break regression vs. the native 11pt no-theme render. Flagged for the Plan 05 human sign-off -- not fixed in 123-03 (column-width retuning is out of this plan's gallery-closure scope). | open |  | 2026-07-28T19:40:14.268Z |  |
| 4 | 123 | lint-warning | lib/rendro/launch_artifacts.ex |  | mix format --check-formatted fails on 7 pre-existing files (lib/rendro/launch_artifacts.ex, test/docs_contract/theme_industry_guard_test.exs, test/docs_contract/theming_claims_test.exs, test/rendro/recipes/payslip_opts_threading_test.exs, test/rendro/recipes/themed_render_smoke_test.exs, test/rendro/recipes/certificate_typography_test.exs, test/rendro/recipes/theme_mode_background_golden_test.exs) -- last touched by phases 119/121/122/123-03/123-04, none by 123-05's rubric-score commit; blocks mix ci.fast's format-check gate. See 123-05 deferred-items.md item 1. | fixed |  | 2026-07-28T20:53:45.711Z | 2026-07-29T01:19:32.157Z |
| 5 | 123 | deviation | test/docs_contract/dx_local_reproducibility_claims_test.exs |  | 2 pre-existing test failures: File.Error reading .planning/phases/113-dx-local-reproducibility-validation/113-UAT.md and 113-METRICS.md (missing from this working tree's partial phase-113 planning artifacts) -- unrelated to phase 123 rubric/gallery/theming work. See 123-05 deferred-items.md item 2. | fixed |  | 2026-07-28T20:53:45.778Z | 2026-07-29T01:19:32.243Z |
| 6 | 123 | deviation | lib/rendro/recipes/ticket.ex |  | mix dialyzer fails on pre-existing lib/rendro/recipes/ticket.ex contract errors (no_return on document/1,2 and sections/1,2; Rendro.Recipes.Background.emit?/1 contract mismatch) -- not touched by 123-05's commit; plausibly related to the Ticket hierarchy-inversion regression already recorded honestly as passed:false (WINDOWS id 2) but a dialyzer fix is a separate lib/-touching change outside this plan's D-05 Commit 3 isolation scope. See 123-05 deferred-items.md item 3. | fixed |  | 2026-07-28T20:53:45.848Z | 2026-07-29T01:19:32.330Z |
| 7 | 123 | deviation | priv/pdfium_pin.json |  | mix rendro.launch_artifacts.check (part of ci.advisory) fails: pdfium-cli v0.11.0 binary not installed/on PATH in this execution environment -- environment/tooling gap, not a code or manifest defect; not auto-installed per the executor's external-binary caution. See 123-05 deferred-items.md item 4. | open |  | 2026-07-28T20:53:45.917Z |  |
| 8 | 125 | deviation | test/docs_contract/examples_schema_contract_test.exs |  | SVG external-reference assertion excludes only real external asset references, not the XML namespace | open |  | 2026-08-17T00:39:41.106Z |  |
| 9 | 125 | deviation | priv/schemas/examples.schema.json |  | Payslip net_pay_ytd is validated as a decimal string for exact YTD reconciliation | open |  | 2026-08-17T00:39:41.170Z |  |
| 10 | 125 | deviation | test/docs_contract/examples_schema_contract_test.exs |  | Made the synthetic-fixture helper family-safe for Statement coverage | open |  | 2026-08-17T00:49:04.416Z |  |
| 11 | 125 | deviation | test/rendro/theme/preset_raster_snapshot_test.exs |  | Guarded blessing bypasses only normal-run reference-existence assertion while seeding missing references. | open |  | 2026-08-17T01:25:59.222Z |  |
| 12 | 125 | deviation | test/rendro/theme/preset_raster_snapshot_test.exs |  | ARM host uses a temporary x86 container wrapper for the exact SHA-verified pinned PDFium binary. | open |  | 2026-08-17T01:25:59.289Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "123",
    "file": "lib/rendro/recipes/invoice.ex",
    "line": null,
    "description": "invoice_dark gallery row: item/qty/price table body cells render via bare strings (no per-cell color), so they inherit a fixed default black text color rather than colors.ink -- illegible against the dark background. Root cause: Rendro.Table cells accept Block or String, but Invoice.body_section builds plain-string rows. Fix requires wrapping cells in themed Block+Text without breaking the frozen INV-01 byte-identity golden -- deferred to a follow-up plan, not fixed in 123-03 (out of scope, risk to frozen golden).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T19:39:59.602Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "123",
    "file": "lib/rendro/recipes/ticket.ex",
    "line": null,
    "description": "ticket/ticket_dark: the uniform themed type scale inverts the intended visual hierarchy -- the reference-code display anchor (scale.display, native 8pt) jumps to 21pt themed, now LARGER than the placement-grid title role (scale.title, native 26pt but 16.5pt themed) that the 2026-07-19 rubric actually scored as dominant. The reference code also now wraps awkwardly across 3 lines in its narrow stub column (AUR-8 / 8213- / GA). Flagged for the Plan 05 human sign-off -- not fixed in 123-03 (Q3's non-monotone role assignment is a locked Phase-122 decision; re-mapping is an architectural call, not a gallery-closure fix).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T19:40:14.182Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "123",
    "file": "lib/rendro/recipes/payslip.ex",
    "line": null,
    "description": "payslip themed render: earnings/deductions table numeric cells (e.g. $4,200.00, $4,550.00) wrap mid-number onto a second line ($4,200.0 / 0) in the Current/YTD columns at the themed 10.5pt body scale + 1.35 leading -- a new typographic_craft awkward-break regression vs. the native 11pt no-theme render. Flagged for the Plan 05 human sign-off -- not fixed in 123-03 (column-width retuning is out of this plan's gallery-closure scope).",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T19:40:14.268Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "lint-warning",
    "phase": "123",
    "file": "lib/rendro/launch_artifacts.ex",
    "line": null,
    "description": "mix format --check-formatted fails on 7 pre-existing files (lib/rendro/launch_artifacts.ex, test/docs_contract/theme_industry_guard_test.exs, test/docs_contract/theming_claims_test.exs, test/rendro/recipes/payslip_opts_threading_test.exs, test/rendro/recipes/themed_render_smoke_test.exs, test/rendro/recipes/certificate_typography_test.exs, test/rendro/recipes/theme_mode_background_golden_test.exs) -- last touched by phases 119/121/122/123-03/123-04, none by 123-05's rubric-score commit; blocks mix ci.fast's format-check gate. See 123-05 deferred-items.md item 1.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-28T20:53:45.711Z",
    "resolved_at": "2026-07-29T01:19:32.157Z"
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "123",
    "file": "test/docs_contract/dx_local_reproducibility_claims_test.exs",
    "line": null,
    "description": "2 pre-existing test failures: File.Error reading .planning/phases/113-dx-local-reproducibility-validation/113-UAT.md and 113-METRICS.md (missing from this working tree's partial phase-113 planning artifacts) -- unrelated to phase 123 rubric/gallery/theming work. See 123-05 deferred-items.md item 2.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-28T20:53:45.778Z",
    "resolved_at": "2026-07-29T01:19:32.243Z"
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "123",
    "file": "lib/rendro/recipes/ticket.ex",
    "line": null,
    "description": "mix dialyzer fails on pre-existing lib/rendro/recipes/ticket.ex contract errors (no_return on document/1,2 and sections/1,2; Rendro.Recipes.Background.emit?/1 contract mismatch) -- not touched by 123-05's commit; plausibly related to the Ticket hierarchy-inversion regression already recorded honestly as passed:false (WINDOWS id 2) but a dialyzer fix is a separate lib/-touching change outside this plan's D-05 Commit 3 isolation scope. See 123-05 deferred-items.md item 3.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-28T20:53:45.848Z",
    "resolved_at": "2026-07-29T01:19:32.330Z"
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "123",
    "file": "priv/pdfium_pin.json",
    "line": null,
    "description": "mix rendro.launch_artifacts.check (part of ci.advisory) fails: pdfium-cli v0.11.0 binary not installed/on PATH in this execution environment -- environment/tooling gap, not a code or manifest defect; not auto-installed per the executor's external-binary caution. See 123-05 deferred-items.md item 4.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-28T20:53:45.917Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "125",
    "file": "test/docs_contract/examples_schema_contract_test.exs",
    "line": null,
    "description": "SVG external-reference assertion excludes only real external asset references, not the XML namespace",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-17T00:39:41.106Z",
    "resolved_at": null
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "125",
    "file": "priv/schemas/examples.schema.json",
    "line": null,
    "description": "Payslip net_pay_ytd is validated as a decimal string for exact YTD reconciliation",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-17T00:39:41.170Z",
    "resolved_at": null
  },
  {
    "id": 10,
    "kind": "deviation",
    "phase": "125",
    "file": "test/docs_contract/examples_schema_contract_test.exs",
    "line": null,
    "description": "Made the synthetic-fixture helper family-safe for Statement coverage",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-17T00:49:04.416Z",
    "resolved_at": null
  },
  {
    "id": 11,
    "kind": "deviation",
    "phase": "125",
    "file": "test/rendro/theme/preset_raster_snapshot_test.exs",
    "line": null,
    "description": "Guarded blessing bypasses only normal-run reference-existence assertion while seeding missing references.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-17T01:25:59.222Z",
    "resolved_at": null
  },
  {
    "id": 12,
    "kind": "deviation",
    "phase": "125",
    "file": "test/rendro/theme/preset_raster_snapshot_test.exs",
    "line": null,
    "description": "ARM host uses a temporary x86 container wrapper for the exact SHA-verified pinned PDFium binary.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-17T01:25:59.289Z",
    "resolved_at": null
  }
]
````
