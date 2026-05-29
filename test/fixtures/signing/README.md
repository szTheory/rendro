These files are test-only signing fixtures for Rendro's `live_pdf_tools` proof lane.

- `certomancer/` contains the checked-in non-secret offline PKI fixtures that back the Phase 66 long-lived proof lane.
- The certomancer config and keys are adapted from the official pyHanko test PKI so Rendro can stand up a localhost TSA, OCSP responder, CRL repo, and cert repo without any outbound dependency.
- The supported Phase 66 proof path is `Rendro.render_to_artifact/2 -> Rendro.Sign.sign/2 -> Rendro.Sign.augment/2 -> Rendro.Sign.validate/2` over runtime-generated PDFs only.
- `pdfsig` remains a secondary integrity check in the live lane; pyHanko-backed validation is authoritative for timestamp, revocation, and embedded-validation-evidence posture.
- OpenSSL is not part of the supported local proof command. If these fixtures ever need regeneration, OpenSSL is fixture-maintenance infrastructure only.
- Do not check signed PDFs into this directory. Signed outputs are generated in a private temp directory during the live proof test.

## Viewer-evidence carve-out (Phase 71)

Phase 71 commits two signed PDFs **outside** this `signing/` tree for repo-relative `fixture:` paths used in manual viewer recording:

- `test/fixtures/signed_artifact_viewer_proof.pdf` — signed with `test/fixtures/signing/live_signer_*.pem` via `scripts/signed_artifact_viewer_proof_fixture.exs`
- `test/fixtures/long_lived_viewer_proof.pdf` — LTV-augmented with the certomancer chain via `scripts/long_lived_viewer_proof_fixture.exs`

These committed PDFs exist solely for viewer-evidence recording and Acrobat session checklists. The CI signing lane (`@tag live_signing`) and long-lived lane (`@tag live_pdf_tools`) remain ephemeral — they generate signed outputs in private temp directories during live tests and do not depend on these committed files.

Regenerate all Phase 71 signing-surface fixtures:

```bash
mix run scripts/signing_viewer_proof_fixtures.exs
```
