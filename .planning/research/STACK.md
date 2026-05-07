# Project Research — Stack for v2.1 Cryptographic Signing & Signed-Artifact Proof

**Milestone:** v2.1 Cryptographic Signing & Signed-Artifact Proof
**Date:** 2026-05-07

## Existing validated stack to preserve

- Elixir 1.19.5 + OTP 28
- Pure-Elixir core render pipeline
- Optional external-tool adapters (`qpdf`, Poppler) with runtime checks
- Telemetry, docs-contract, and live proof lanes as product behavior

## Recommended stack additions for new capability

### Signing runtime

- **pyHanko CLI** as the first proof-backed signing executable
  - Rationale: official CLI supports `pyhanko sign addsig` over PEM/DER key material and can sign into an existing field or create one if needed; Rendro can stay narrower by requiring an already-authored unsigned field and using pyHanko only as the cryptographic signer.
  - Official reference: pyHanko CLI signing docs.

### Signed-artifact validation runtime

- **Poppler `pdfsig`** as the first signed-artifact inspection tool
  - Rationale: official tool reports signer identity, signing time, hash algorithm, signature type, signed ranges, and whether the total document is signed. That is enough to separate signature presence/integrity posture from trust/compliance narratives.
  - Official reference: `pdfsig(1)` man page.

### Proof-lane fixture tooling

- **OpenSSL CLI** for local proof certificates in the live lane
  - Rationale: `openssl req -x509` can mint a self-signed certificate for deterministic local proof workflows without implying production trust anchoring.
  - Official reference: `openssl-req` documentation.

## What not to add

- No hard dependency on Python packages or signing binaries in `mix.exs`.
- No in-core PKCS#11, HSM, CA-store, TSA, OCSP, or CRL management in this milestone.
- No promise that `pdfsig` is a full compliance validator; it is a narrow signed-artifact inspection tool.

## Integration notes

- Keep pyHanko and pdfsig fully optional and discovered at runtime.
- Preserve the existing adapter injection pattern for testability.
- Treat signed output as intentionally non-deterministic while keeping unsigned input and authored field layout deterministic.
