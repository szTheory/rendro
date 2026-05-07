# Research Summary — v2.1 Cryptographic Signing & Signed-Artifact Proof

**Date:** 2026-05-07

## Stack additions

- First proof-backed signing runtime: **pyHanko CLI**
- First proof-backed signed-artifact inspection runtime: **Poppler `pdfsig`**
- Local proof fixture tool: **OpenSSL CLI**

## Feature table stakes

- Sign a rendered artifact through an explicit public API.
- Target an existing unsigned signature field.
- Keep signer credentials and tool execution adapter-local.
- Inspect signed-artifact posture without collapsing integrity, trust, viewer, and compliance claims.

## Watch out for

- Signed output is non-deterministic and must be documented that way.
- `pdfsig` can inspect signatures, but it is not a blanket compliance proof lane.
- pyHanko can do more than `v2.1` should claim; resist timestamp/revocation/PAdES scope creep.
- Credential redaction and support-matrix wording are product behavior, not cleanup tasks.
