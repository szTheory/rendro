---
schema_version: 1
open_count: 3
waived_count: 0
fixed_count: 0
total_count: 3
last_updated: 2026-07-28T19:40:14.268Z
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
  }
]
````
