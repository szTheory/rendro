# Phase 88 Launch Checklist

Operator ledger for launch readiness, publication order, and final public URLs.

## [BLOCKING] Launch readiness

Launch is blocked until CMP-03 is reconciled and all required proof links are public. Update the requirements traceability, verify the Livebook link, then re-run the launch checklist.

Use only these statuses: `Ready`, `Blocked`, `Deferred with reason`.

| Gate | Status | Evidence / URL | Notes |
| --- | --- | --- | --- |
| Claim-accuracy fixes are shipped | Ready | HYG-01..05 complete in `.planning/REQUIREMENTS.md` | Pure core and shaping boundaries must stay true before posting. |
| Launch artifacts are published and byte-checked | Ready | GAL-01..03 complete; gallery and manual SHA are present | Public URLs still need final operator verification. |
| Comparison guide and Livebook are live | Blocked | `CMP-03` remains pending in `.planning/REQUIREMENTS.md` | Roadmap/state say Phase 87 complete; requirements traceability must be reconciled. |
| Mobile evidence outcome is recorded | Blocked | Pending Plan 88-04 | Rows must be supported with evidence or deferred with reason. |
| Adoption signal ledger is ready | Blocked | Pending Plan 88-02 | `ADOPTION.md` must exist before launch replies route signals. |

## Public URL Checklist

| Surface | Status | Final URL | Verified At | Notes |
| --- | --- | --- | --- | --- |
| GitHub README | Blocked | TBD | TBD | Verify rendered gallery, manual SHA, comparison, Livebook, and adoption links. |
| GitHub comparison guide | Blocked | TBD | TBD | Verify the guide renders with benchmark citations. |
| GitHub Livebook | Blocked | TBD | TBD | Verify the `.livemd` file opens from the repository. |
| GitHub ADOPTION.md | Blocked | TBD | TBD | Pending Plan 88-02. |
| HexDocs README | Blocked | TBD | TBD | Verify published package docs include launch artifacts. |
| HexDocs comparison guide | Blocked | TBD | TBD | Verify public HexDocs comparison route. |
| HexDocs Livebook page | Blocked | TBD | TBD | Verify public Livebook docs route or badge target. |
| ElixirForum hub | Blocked | TBD | TBD | Publish first, after readiness gates pass. |
| ElixirStatus post | Blocked | TBD | TBD | Publish after ElixirForum hub. |
| awesome-elixir PR | Blocked | TBD | TBD | Open after public docs are live. |
| Chromium demand-thread reply | Blocked | TBD | TBD | Reply after canonical announcement is live. |
| Prawn-like demand-thread reply | Blocked | TBD | TBD | Reply after Chromium thread. |
| mobile evidence follow-up | Blocked | TBD | TBD | Publish after mobile evidence outcome is recorded. |

## Publication Order

1. ElixirForum announcement
2. ElixirStatus
3. awesome-elixir PR
4. PDF generation without Chromium dependency
5. Looking for a Prawn-Like PDF Generation Library in Elixir
6. mobile evidence follow-up

## Operator Notes

- Show blocked gates first in any launch handoff.
- Do not publish celebratory copy while any required gate is `Blocked`.
- Show HN is deferred and non-blocking; it is not part of the required publication order.
- Record final public URLs in this checklist as each channel is posted.
