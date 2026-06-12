# Phase 88 Launch Checklist

Operator ledger for launch readiness, publication order, and final public URLs.

## [BLOCKING] Launch readiness

Launch is blocked until CMP-03 is reconciled and all required proof links are public. Update the requirements traceability, verify the Livebook link, then re-run the launch checklist.

CMP-03 was reconciled on 2026-06-12 after local Livebook checks and public GitHub/HexDocs URL checks passed. Remaining launch blockers are the manual external publication URLs below.

Use only these statuses: `Ready`, `Blocked`, `Deferred with reason`.

| Gate | Status | Evidence / URL | Notes |
| --- | --- | --- | --- |
| Claim-accuracy fixes are shipped | Ready | HYG-01..05 complete in `.planning/REQUIREMENTS.md` | Pure core and shaping boundaries must stay true before posting. |
| Launch artifacts are published and byte-checked | Ready | GAL-01..03 complete; `mix docs.contract` passed 2026-06-12T20:55Z; public GitHub README raw URL passed 2026-06-12T20:55Z | Public gallery/manual proof is available before posting. |
| Comparison guide and Livebook are live | Ready | `mix docs.contract`, `mix rendro.livebook.check`, `mix hex.build`, raw GitHub comparison/Livebook checks, and HexDocs comparison/Livebook checks passed 2026-06-12T20:55Z; CMP-03 checked in `.planning/REQUIREMENTS.md` | Hex downloads at launch-readiness check: `all=867`, `week=115`. |
| Mobile evidence outcome is recorded | Ready | Four terminal `explicit_deferral` rows in `priv/support_matrix.json` | Zero-human UAT decision: no mobile GUI support claim is promoted until automated device-level CI evidence exists. |
| Adoption signal ledger is ready | Ready | `ADOPTION.md` exists; targeted launch/adoption/intake tests and D-34 remote label check passed 2026-06-12T15:49Z | Issue-only intake is the locked Phase 88 path; Discussions remain disabled by the accepted 88-03 checkpoint deviation. |

## Mobile Evidence Outcome

| Row | Outcome | Proof / Deferral |
| --- | --- | --- |
| `forms.ios_files_preview` | `explicit_deferral` | iOS Files/Preview mobile GUI behavior is not part of CI; Phase 88 uses zero-human UAT, so promotion waits for automated device-level proof of `open`, `default_state_visible`, `edit_or_toggle`, and `save`. |
| `forms.android_drive_viewer` | `explicit_deferral` | Google Drive PDF viewer on Android mobile GUI behavior is not part of CI; Phase 88 uses zero-human UAT, so promotion waits for automated device-level proof of `open`, `default_state_visible`, `edit_or_toggle`, and `save`. |
| `signing.ios_files_preview` | `explicit_deferral` | iOS Files/Preview does not have automated device-level evidence for `/Sig` signed-artifact validation in CI; Markup or drawn signatures are separate from cryptographic integrity, certificate-trust, timestamp, and save/reopen validation. |
| `signing.android_drive_viewer` | `explicit_deferral` | Google Drive PDF viewer on Android does not have automated device-level evidence for `/Sig` signed-artifact validation in CI; promotion requires observed integrity, certificate-trust, timestamp, and save/reopen validation panels. |

## Public URL Checklist

| Surface | Status | Final URL | Verified At | Notes |
| --- | --- | --- | --- | --- |
| GitHub README | Ready | `https://raw.githubusercontent.com/szTheory/rendro/main/README.md` | 2026-06-12T20:55Z | Contains `Rendered Recipe Gallery`. |
| GitHub comparison guide | Ready | `https://raw.githubusercontent.com/szTheory/rendro/main/guides/comparison.md` | 2026-06-12T20:55Z | Contains `Generating PDFs in Elixir without Chrome`. |
| GitHub Livebook | Ready | `https://raw.githubusercontent.com/szTheory/rendro/main/guides/livebook/first_invoice.livemd` | 2026-06-12T20:55Z | Contains `First Invoice`. |
| GitHub ADOPTION.md | Ready | `https://raw.githubusercontent.com/szTheory/rendro/main/ADOPTION.md` | 2026-06-12T20:55Z | Contains `# Adoption Signals`. |
| HexDocs README | Ready | `https://hexdocs.pm/rendro/readme.html` | 2026-06-12T15:49Z | HTTP 200. |
| HexDocs comparison guide | Ready | `https://hexdocs.pm/rendro/comparison.html` | 2026-06-12T20:55Z | HTTP 200. |
| HexDocs Livebook page | Ready | `https://hexdocs.pm/rendro/first_invoice.html` | 2026-06-12T20:55Z | HTTP 200. |
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
- Do not route launch copy to GitHub Discussions; Phase 88 accepted the issue-only intake deviation in 88-03.
- Show HN is deferred and non-blocking; it is not part of the required publication order.
- Record final public URLs in this checklist as each channel is posted.
