# Project Research — Architecture for v2.1 Cryptographic Signing & Signed-Artifact Proof

**Milestone:** v2.1 Cryptographic Signing & Signed-Artifact Proof
**Date:** 2026-05-07

## Recommended architecture shape

### 1. Preserve the authored/render split

- Authoring stays in the existing form-field surface (`Rendro.signature_field/2` on `%Rendro.FormField{}`).
- Rendering still produces an unsigned artifact first.
- Cryptographic signing happens only after render on a `%Rendro.Artifact{}` boundary.

### 2. Keep signing adapter-local

- `Rendro.Sign.sign/2` should normalize public options, validate the chosen field, and delegate cryptographic work to an optional adapter.
- The adapter owns signer credentials, executable invocation, temp files, and tool-specific metadata.
- Shared metadata should stay narrow: signing status, selected field, adapter module, and any safe high-level posture.

### 3. Keep validation separate from signing

- Signed-artifact validation belongs in a separate adapter path from signing itself.
- Validation should report observed artifact posture, not mutate the signed artifact or imply trust store policy.
- This separation keeps it possible to support multiple signing paths later without entangling their validators.

### 4. Treat proof lanes as part of architecture

- Docs-contract tests prove the public narrative.
- Runtime unit tests prove normalization, redaction, and adapter boundaries.
- A live-tool lane proves the supported pyHanko + pdfsig + OpenSSL path without making those tools mandatory for default CI.

## Suggested build order

1. Lock the public `sign/2` option contract and redaction rules.
2. Harden the first-party signing adapter boundary.
3. Add the first-party signed-artifact validation adapter.
4. Add live proof and support-contract updates together so the public story never outruns the evidence.
