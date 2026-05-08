These files are test-only signing fixtures for Rendro's `live_pdf_tools` proof lane.

- `certomancer/` contains the checked-in non-secret offline PKI fixtures that back the Phase 66 long-lived proof lane.
- The certomancer config and keys are adapted from the official pyHanko test PKI so Rendro can stand up a localhost TSA, OCSP responder, CRL repo, and cert repo without any outbound dependency.
- The supported Phase 66 proof path is `Rendro.render_to_artifact/2 -> Rendro.Sign.sign/2 -> Rendro.Sign.augment/2 -> Rendro.Sign.validate/2` over runtime-generated PDFs only.
- `pdfsig` remains a secondary integrity check in the live lane; pyHanko-backed validation is authoritative for timestamp, revocation, and embedded-validation-evidence posture.
- OpenSSL is not part of the supported local proof command. If these fixtures ever need regeneration, OpenSSL is fixture-maintenance infrastructure only.
- Do not check signed PDFs into this directory. Signed outputs are generated in a private temp directory during the live proof test.
