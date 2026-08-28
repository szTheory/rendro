---
schema_version: 1
open_count: 15
waived_count: 0
fixed_count: 6
total_count: 21
last_updated: 2026-08-28T19:23:45.832Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 123 | deviation | lib/rendro/recipes/invoice.ex |  | Phase 126 wraps themed Invoice table cells with semantic ink while preserving nil-theme bytes. Focused Invoice tests, the deterministic preset matrix, exact pinned-PDFium swiss/corporate rows, and approved full-size review found dark table header/body values readable. | fixed | closure evidence: 126-01, 126-03 run 31997957937, 126-04 approval | 2026-07-28T19:39:59.602Z | 2026-08-17T05:59:21.526Z |
| 2 | 123 | deviation | lib/rendro/recipes/ticket.ex |  | Phase 126 assigns themed Ticket placement/title/reference roles as display/title/caption. Focused Ticket tests, the deterministic preset matrix, exact pinned-PDFium editorial/minimal rows, and approved full-size review found placement dominant and the complete reference one-line, subordinate, and unclipped. | fixed | closure evidence: 126-01, 126-03 run 31997957937, 126-04 approval | 2026-07-28T19:40:14.182Z | 2026-08-17T05:59:21.869Z |
| 3 | 123 | deviation | lib/rendro/recipes/payslip.ex |  | Phase 126 uses measured themed 61pt Current / 68pt YTD widths while preserving nil-theme bytes. Focused Payslip tests, the deterministic preset matrix, exact pinned-PDFium humanist/brutalist rows, and approved full-size review found money values unbroken, right-aligned, and unclipped. | fixed | closure evidence: 126-01, 126-03 run 31997957937, 126-04 approval | 2026-07-28T19:40:14.268Z | 2026-08-17T05:59:22.217Z |
| 4 | 123 | lint-warning | lib/rendro/launch_artifacts.ex |  | mix format --check-formatted fails on 7 pre-existing files (lib/rendro/launch_artifacts.ex, test/docs_contract/theme_industry_guard_test.exs, test/docs_contract/theming_claims_test.exs, test/rendro/recipes/payslip_opts_threading_test.exs, test/rendro/recipes/themed_render_smoke_test.exs, test/rendro/recipes/certificate_typography_test.exs, test/rendro/recipes/theme_mode_background_golden_test.exs) -- last touched by phases 119/121/122/123-03/123-04, none by 123-05's rubric-score commit; blocks mix ci.fast's format-check gate. See 123-05 deferred-items.md item 1. | fixed |  | 2026-07-28T20:53:45.711Z | 2026-07-29T01:19:32.157Z |
| 5 | 123 | deviation | test/docs_contract/dx_local_reproducibility_claims_test.exs |  | 2 pre-existing test failures: File.Error reading .planning/phases/113-dx-local-reproducibility-validation/113-UAT.md and 113-METRICS.md (missing from this working tree's partial phase-113 planning artifacts) -- unrelated to phase 123 rubric/gallery/theming work. See 123-05 deferred-items.md item 2. | fixed |  | 2026-07-28T20:53:45.778Z | 2026-07-29T01:19:32.243Z |
| 6 | 123 | deviation | lib/rendro/recipes/ticket.ex |  | mix dialyzer fails on pre-existing lib/rendro/recipes/ticket.ex contract errors (no_return on document/1,2 and sections/1,2; Rendro.Recipes.Background.emit?/1 contract mismatch) -- not touched by 123-05's commit; plausibly related to the Ticket hierarchy-inversion regression already recorded honestly as passed:false (WINDOWS id 2) but a dialyzer fix is a separate lib/-touching change outside this plan's D-05 Commit 3 isolation scope. See 123-05 deferred-items.md item 3. | fixed |  | 2026-07-28T20:53:45.848Z | 2026-07-29T01:19:32.330Z |
| 7 | 123 | deviation | priv/pdfium_pin.json |  | mix rendro.launch_artifacts.check (part of ci.advisory) fails: pdfium-cli v0.11.0 binary not installed/on PATH in this execution environment -- environment/tooling gap, not a code or manifest defect; not auto-installed per the executor's external-binary caution. See 123-05 deferred-items.md item 4. | open |  | 2026-07-28T20:53:45.917Z |  |
| 8 | 125 | deviation | test/docs_contract/examples_schema_contract_test.exs |  | SVG external-reference assertion excludes only real external asset references, not the XML namespace | open |  | 2026-08-17T00:39:41.106Z |  |
| 9 | 125 | deviation | priv/schemas/examples.schema.json |  | Payslip net_pay_ytd is validated as a decimal string for exact YTD reconciliation | open |  | 2026-08-17T00:39:41.170Z |  |
| 10 | 125 | deviation | test/docs_contract/examples_schema_contract_test.exs |  | Made the synthetic-fixture helper family-safe for Statement coverage | open |  | 2026-08-17T00:49:04.416Z |  |
| 11 | 125 | deviation | test/rendro/theme/preset_raster_snapshot_test.exs |  | Guarded blessing bypasses only normal-run reference-existence assertion while seeding missing references. | open |  | 2026-08-17T01:25:59.222Z |  |
| 12 | 125 | deviation | test/rendro/theme/preset_raster_snapshot_test.exs |  | ARM host uses a temporary x86 container wrapper for the exact SHA-verified pinned PDFium binary. | open |  | 2026-08-17T01:25:59.289Z |  |
| 13 | 127 | deviation | priv/pdfium_pin.json |  | Used the exact SHA-verified GitHub advisory lane because the pinned Linux PDFium binary cannot execute on the macOS ARM executor. | open |  | 2026-08-18T01:41:06.678Z |  |
| 14 | 130 | unrun-verify | tmp/phase130-launch-reconcile |  | Focused local Mix tests were unrun because the detached staging worktree has no dependency cache; exact-SHA CI artifact provenance was verified. | open |  | 2026-08-20T15:34:07.544Z |  |
| 15 | 130 | deviation | tmp/phase130-launch-reconcile |  | Detached-worktree dependency cache unavailable; no packages were installed and only artifact/hash fences were used. | open |  | 2026-08-20T15:34:07.633Z |  |
| 16 | 131 | unrun-verify | .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-PUBLIC-PREREQUISITE.json |  | Plan 131-06 public prerequisite verifier intentionally not run: protected v1.3.3 release failed at unauthenticated Hex dry run before publication. | open |  | 2026-08-22T20:28:47.267Z |  |
| 17 | 133 | deviation | .planning/phases/133-repository-evidence-hygiene/133-08-PLAN.md | 41 | Literal legacy-path grep includes intentional plan-local provenance records; active-consumer reference check passed. | open |  | 2026-08-26T21:48:10.729Z |  |
| 18 | 133 | deviation | .planning/phases/133-repository-evidence-hygiene/133-05-PLAN.md |  | Mix 1.19 rejects the planned -x option; equivalent focused suite ran without it. | open |  | 2026-08-26T22:26:41.647Z |  |
| 19 | 133 | deviation | test/scripts/repository_evidence_test.exs |  | Legacy source reads in the evidence test were replaced with fixed capsule provenance, fact, and sidecar digest contracts before deleting batch A. | open |  | 2026-08-26T22:32:48.088Z |  |
| 20 | 133 | deviation | .planning/phases/133-repository-evidence-hygiene/133-07-PLAN.md |  | Mix 1.19 rejects the plan's -x option; the equivalent focused test command passed without it. | open |  | 2026-08-26T22:36:35.405Z |  |
| 21 | 136 | unrun-verify | .planning/todos/pending/2026-08-28-unify-catalog-recipe-visual-design-system.md |  | mix ci.fast stops at repository hygiene because a pre-existing tracked TODO is outside an active phase or milestone archive | open |  | 2026-08-28T19:23:45.832Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "123",
    "file": "lib/rendro/recipes/invoice.ex",
    "line": null,
    "description": "Phase 126 wraps themed Invoice table cells with semantic ink while preserving nil-theme bytes. Focused Invoice tests, the deterministic preset matrix, exact pinned-PDFium swiss/corporate rows, and approved full-size review found dark table header/body values readable.",
    "status": "fixed",
    "reason": "closure evidence: 126-01, 126-03 run 31997957937, 126-04 approval",
    "recorded_at": "2026-07-28T19:39:59.602Z",
    "resolved_at": "2026-08-17T05:59:21.526Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "123",
    "file": "lib/rendro/recipes/ticket.ex",
    "line": null,
    "description": "Phase 126 assigns themed Ticket placement/title/reference roles as display/title/caption. Focused Ticket tests, the deterministic preset matrix, exact pinned-PDFium editorial/minimal rows, and approved full-size review found placement dominant and the complete reference one-line, subordinate, and unclipped.",
    "status": "fixed",
    "reason": "closure evidence: 126-01, 126-03 run 31997957937, 126-04 approval",
    "recorded_at": "2026-07-28T19:40:14.182Z",
    "resolved_at": "2026-08-17T05:59:21.869Z"
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "123",
    "file": "lib/rendro/recipes/payslip.ex",
    "line": null,
    "description": "Phase 126 uses measured themed 61pt Current / 68pt YTD widths while preserving nil-theme bytes. Focused Payslip tests, the deterministic preset matrix, exact pinned-PDFium humanist/brutalist rows, and approved full-size review found money values unbroken, right-aligned, and unclipped.",
    "status": "fixed",
    "reason": "closure evidence: 126-01, 126-03 run 31997957937, 126-04 approval",
    "recorded_at": "2026-07-28T19:40:14.268Z",
    "resolved_at": "2026-08-17T05:59:22.217Z"
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
  },
  {
    "id": 13,
    "kind": "deviation",
    "phase": "127",
    "file": "priv/pdfium_pin.json",
    "line": null,
    "description": "Used the exact SHA-verified GitHub advisory lane because the pinned Linux PDFium binary cannot execute on the macOS ARM executor.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-18T01:41:06.678Z",
    "resolved_at": null
  },
  {
    "id": 14,
    "kind": "unrun-verify",
    "phase": "130",
    "file": "tmp/phase130-launch-reconcile",
    "line": null,
    "description": "Focused local Mix tests were unrun because the detached staging worktree has no dependency cache; exact-SHA CI artifact provenance was verified.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-20T15:34:07.544Z",
    "resolved_at": null
  },
  {
    "id": 15,
    "kind": "deviation",
    "phase": "130",
    "file": "tmp/phase130-launch-reconcile",
    "line": null,
    "description": "Detached-worktree dependency cache unavailable; no packages were installed and only artifact/hash fences were used.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-20T15:34:07.633Z",
    "resolved_at": null
  },
  {
    "id": 16,
    "kind": "unrun-verify",
    "phase": "131",
    "file": ".planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-PUBLIC-PREREQUISITE.json",
    "line": null,
    "description": "Plan 131-06 public prerequisite verifier intentionally not run: protected v1.3.3 release failed at unauthenticated Hex dry run before publication.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-22T20:28:47.267Z",
    "resolved_at": null
  },
  {
    "id": 17,
    "kind": "deviation",
    "phase": "133",
    "file": ".planning/phases/133-repository-evidence-hygiene/133-08-PLAN.md",
    "line": 41,
    "description": "Literal legacy-path grep includes intentional plan-local provenance records; active-consumer reference check passed.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T21:48:10.729Z",
    "resolved_at": null
  },
  {
    "id": 18,
    "kind": "deviation",
    "phase": "133",
    "file": ".planning/phases/133-repository-evidence-hygiene/133-05-PLAN.md",
    "line": null,
    "description": "Mix 1.19 rejects the planned -x option; equivalent focused suite ran without it.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T22:26:41.647Z",
    "resolved_at": null
  },
  {
    "id": 19,
    "kind": "deviation",
    "phase": "133",
    "file": "test/scripts/repository_evidence_test.exs",
    "line": null,
    "description": "Legacy source reads in the evidence test were replaced with fixed capsule provenance, fact, and sidecar digest contracts before deleting batch A.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T22:32:48.088Z",
    "resolved_at": null
  },
  {
    "id": 20,
    "kind": "deviation",
    "phase": "133",
    "file": ".planning/phases/133-repository-evidence-hygiene/133-07-PLAN.md",
    "line": null,
    "description": "Mix 1.19 rejects the plan's -x option; the equivalent focused test command passed without it.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T22:36:35.405Z",
    "resolved_at": null
  },
  {
    "id": 21,
    "kind": "unrun-verify",
    "phase": "136",
    "file": ".planning/todos/pending/2026-08-28-unify-catalog-recipe-visual-design-system.md",
    "line": null,
    "description": "mix ci.fast stops at repository hygiene because a pre-existing tracked TODO is outside an active phase or milestone archive",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T19:23:45.832Z",
    "resolved_at": null
  }
]
````
