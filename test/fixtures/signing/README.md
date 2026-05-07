These files are test-only signing fixtures for Rendro's `live_pdf_tools` proof lane.

- `live_signer_key.pem`, `live_signer_cert.pem`, and `live_signer_passphrase.txt` are obvious non-secret fixture material checked in only for automated proof coverage.
- The supported Phase 62 proof path is `Rendro.Sign.sign/2` plus `Rendro.Sign.validate/2` over runtime-generated unsigned and signed PDFs.
- OpenSSL is not part of the supported local proof command. If these fixtures ever need regeneration, OpenSSL is fixture-maintenance infrastructure only.
- Do not check signed PDFs into this directory. Signed outputs are generated in a private temp directory during the live proof test.
