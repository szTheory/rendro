# Phase 88 Quiet Public Checklist

Operator ledger for quiet public discoverability, proof readiness, and low-maintenance intake.

## Quiet Public Posture

Rendro is public and findable through GitHub, HexDocs, proof links, and issue templates. No proactive announcement campaign is required.

Use only these statuses: `Ready`, `Deferred with reason`.

| Gate | Status | Evidence / URL | Notes |
| --- | --- | --- | --- |
| Claim-accuracy fixes are shipped | Ready | HYG-01..05 complete in `.planning/REQUIREMENTS.md` | Pure core and shaping boundaries must stay true for public readers. |
| Launch artifacts are published and byte-checked | Ready | GAL-01..03 complete; `mix docs.contract` passed 2026-06-12T20:55Z; public GitHub README raw URL passed 2026-06-12T20:55Z | Gallery/manual proof stays available for people who find the project. |
| Comparison guide and Livebook are live | Ready | `mix docs.contract`, `mix rendro.livebook.check`, `mix hex.build`, raw GitHub comparison/Livebook checks, and HexDocs comparison/Livebook checks passed 2026-06-12T20:55Z; CMP-03 checked in `.planning/REQUIREMENTS.md` | Hex downloads at readiness check: `all=867`, `week=115`. |
| Mobile evidence outcome is recorded | Ready | Four terminal `explicit_deferral` rows in `priv/support_matrix.json` | Zero-human UAT decision: no mobile GUI support claim is promoted until automated device-level CI evidence exists. |
| Adoption signal ledger is ready | Ready | `ADOPTION.md` exists; targeted launch/adoption/intake tests and D-34 remote label check passed 2026-06-12T15:49Z | Issue-only intake is the locked Phase 88 path; Discussions remain disabled by the accepted 88-03 checkpoint deviation. |
| Proactive outreach | Deferred with reason | No ElixirForum announcement, ElixirStatus post, awesome-elixir PR, demand-thread reply, mobile follow-up post, or Show HN is required | Maintainer posture: keep Rendro quietly public, but avoid creating a recurring community-response obligation unless explicitly opted in later. |

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

## Deferred Outreach

The following are intentionally not part of Phase 88 completion:

| Surface | Status | Reason |
| --- | --- | --- |
| ElixirForum announcement | Deferred with reason | No proactive announcement campaign is planned. |
| ElixirStatus post | Deferred with reason | No short-channel promotion is planned. |
| awesome-elixir PR | Deferred with reason | No listing PR is required. |
| Demand-thread replies | Deferred with reason | No external thread replies are required. |
| Mobile evidence follow-up post | Deferred with reason | Mobile evidence remains documented in support boundaries, not promoted as a content beat. |
| Show HN | Deferred with reason | No broad launch step is planned. |

## Operator Notes

- Do not treat deferred outreach as blocked work.
- Keep public docs, HexDocs, ADOPTION.md, and issue templates truthful and discoverable.
- Do not route launch copy to GitHub Discussions; Phase 88 accepted the issue-only intake deviation in 88-03.
- If the maintainer later opts into outreach, create a new explicit task instead of reactivating Phase 88 publication obligations.
