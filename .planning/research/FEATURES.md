# Project Research — Features for v2.1 Cryptographic Signing & Signed-Artifact Proof

**Milestone:** v2.1 Cryptographic Signing & Signed-Artifact Proof
**Date:** 2026-05-07

## Cryptographic Signing

**Table stakes**
- Sign a rendered artifact through an explicit public API.
- Target a specific unsigned signature field.
- Accept signer key/certificate material through adapter-local configuration.
- Return typed, redacted failures for missing fields, missing executables, and signing-tool failures.

**Differentiators**
- Preserve the existing unsigned/preparation seam instead of replacing it with a signer-owned rendering path.
- Label signed artifacts as non-deterministic in metadata and public docs.
- Keep adapter-local metadata narrow and secret-free.

## Signed-Artifact Validation

**Table stakes**
- Inspect whether a PDF contains signatures.
- Surface signer identity, signature type, signing time, hash algorithm, and signed-range posture.
- Distinguish signature validity from certificate trust.

**Differentiators**
- Keep validation results framed as proof-backed artifact posture, not blanket compliance.
- Add a live proof lane using real tools to show the supported path works end to end.

## Truthful Support Boundaries

**Table stakes**
- Publish `digital_signatures` separately from unsigned fields and signing preparation.
- Keep viewer support rows unverified until exact evidence exists.
- Keep compliance and long-lived-signature narratives deferred.

**Differentiators**
- Explain the difference between signature integrity, certificate trust, viewer behavior, and compliance in one consistent vocabulary across docs, support matrix, and tests.

## Anti-features for this milestone

- Timestamping or embedded revocation evidence
- PAdES baseline claims
- In-core certificate/key custody
- Generic "signed PDFs are supported" marketing without precise qualifiers
