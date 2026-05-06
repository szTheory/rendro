---
phase: 50
plan: 03
status: complete
completed: 2026-05-06
requirements:
  - TRUST-01
  - TRUST-02
---

# Plan 50-03 — Human Viewer-Evidence Checkpoint + Post-Proof Contract Sync

Closes Phase 50 by recording manual viewer evidence for the v1.9 artifact
surfaces, promoting only those viewer/surface pairs whose recorded checklist
fully passed, and synchronizing the support matrix, public guide, and
claims-test contract to the recorded evidence.

## Tasks

### Task 1 — Manual viewer evidence (blocking checkpoint)

User ran the support-claims, structural-proof, and fixture-generation lanes,
opened `tmp/embedded_artifact_support_fixture.pdf` in Adobe Acrobat Reader and
Apple Preview, and reported per-surface, per-viewer results. Evidence recorded
in `.planning/phases/50-support-boundary-and-proof-closure/50-VALIDATION.md`.

| Viewer × Surface | Discoverable | Open/extract | Save/extract | External URI | Internal page | Result |
|------------------|--------------|--------------|--------------|--------------|---------------|--------|
| Adobe Acrobat Reader × `embedded_files` | pass | pass | pass | n/a | n/a | **supported** |
| Apple Preview × `embedded_files` | unverified | unverified | unverified | n/a | n/a | unverified |
| Adobe Acrobat Reader × `links` | n/a | n/a | n/a | pass | pass | **supported** |
| Apple Preview × `links` | n/a | n/a | n/a | pass | pass | **supported** |

Apple Preview embedded-files row stayed `unverified` rather than `unsupported`
because Rendro authors the surface correctly per the structural proof lane
(D-09 — the gap is on the viewer side, not on Rendro's authoring).

### Task 2 — Post-proof contract sync (TDD)

RED: Updated `test/docs_contract/embedded_artifact_claims_test.exs` to assert
the post-proof statuses and required guide wording. Three of four assertions
failed against the pre-proof matrix and guide.

GREEN: Promoted only the proof-backed viewer/surface pairs in
`priv/support_matrix.json`, replaced the pre-proof "all unverified" sentence
in `guides/api_stability.md` with three sentences that mirror the recorded
evidence exactly, and confirmed `mix test` and `mix docs.contract` pass.

## Commits

- `ac455d6` — `docs(50-03): record manual viewer evidence for embedded files and links` (Task 1)
- `6630a5e` — `test(50-03): assert proof-backed viewer statuses for embedded files and links` (Task 2 RED)
- `150fa35` — `feat(50-03): promote proof-backed viewer statuses for embedded files and links` (Task 2 GREEN)

## Verification

- `mix test test/docs_contract/embedded_artifact_claims_test.exs` — 4 tests, 0 failures
- `mix docs.contract` — all 5 lanes pass (README doctest, Integration contract, Integration semantic-claims, Forms semantic-claims, Embedded artifact semantic-claims)
- `mix test` — 530 tests, 0 failures (no regressions across phases)

## Locked decisions honored

- D-06..D-08: Per-surface, per-viewer claims; default `unverified`; promotion
  driven by recorded checklist evidence per surface.
- D-09: Apple Preview × `embedded_files` stays `unverified`, not `unsupported`,
  because Rendro authors the surface; the gap is in Preview's UI surfacing.
- D-10..D-14: Structural proof (`pdfinfo`/Poppler) remains a separate lane
  from the recorded viewer evidence; no inference between them.
- D-15..D-18: Public wording uses "embedded files" and plain "links",
  distinguishes PDF-internal embedded files from delivery attachments,
  publishes one coherent recommendation set.

## Deviations

None. Evidence was recorded as the user reported it; only fully-passing
viewer/surface pairs were promoted; conservative posture preserved everywhere
else.

## Out-of-scope notes

While testing, the user mentioned that `forms_support_fixture.pdf` also worked
in Adobe Acrobat Reader. That belongs to the Phase 47 forms surface, which
currently records Adobe Acrobat Reader as `unverified`. Promoting that pair
would require running the Phase 47 forms checklist (open, default state
visible, edit/toggle, save) and recording it in Phase 47 artifacts — not
Phase 50. Captured here as a candidate for a future gap-closure or follow-up
phase, but explicitly not actioned in Phase 50 to keep scope tight.

## Files modified

- Created: `.planning/phases/50-support-boundary-and-proof-closure/50-03-SUMMARY.md`
- Modified: `.planning/phases/50-support-boundary-and-proof-closure/50-VALIDATION.md`
- Modified: `priv/support_matrix.json`
- Modified: `guides/api_stability.md`
- Modified: `test/docs_contract/embedded_artifact_claims_test.exs`
