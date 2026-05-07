# Rendro Milestone Arc

**Last updated:** 2026-05-07
**Purpose:** Preserve the recommended next-milestone sequence so milestone-definition work does not reopen already-set architectural tradeoffs unless the project direction materially changes.

## Last Shipped Milestone

### v2.1 Cryptographic Signing & Signed-Artifact Proof

- **Status:** shipped
- **Why now:** Extended the shipped unsigned/preparation seam into one truthful cryptographic-signing and signed-artifact-validation path without widening the core contract into generic trust or compliance claims.
- **Scope recommendation:**
  - Artifact-first cryptographic signing through `Rendro.Sign.sign/2`
  - First-party optional runtime adapters for signing and signed-artifact validation
  - Proof-backed support language that separates signature integrity, certificate trust, viewer posture, and deferred compliance narratives
- **Non-goals:**
  - In-core certificate management, key custody, or signer workflows by default
  - Long-lived-signature and revocation evidence
  - PAdES/LTV/TSA/OCSP/CRL and blanket compliance claims

## Next Candidate

### Post-v2.1 Long-Lived Signatures & Compliance Evidence

- **Status:** candidate
- **Why after v2.1:** Long-lived-signature and compliance work only makes sense after Rendro proves one truthful cryptographic-signing and validation path, plus the operational boundaries around it.
- **Scope recommendation:**
  - Timestamp, revocation, and long-lived-signature evidence lanes
  - Narrow PAdES-baseline narratives only when backed by explicit validator and artifact proof
  - Additional adapter stories only where the public support contract can stay precise
- **Non-goals:**
  - Broad compliance branding without artifact-level evidence
  - Default in-core trust-store, CA, or HSM management
  - Viewer promotion that outruns recorded proof

## Follow-On Direction

- Keep post-`v2.1` signature work focused on long-lived evidence and compliance only when the current signing seam remains stable in real usage.
- Continue treating viewer promotion as evidence-gated and separate from structural, cryptographic, and compliance validity claims.
- Keep support-matrix growth tied to exact proof lanes and milestone scope so the public contract stays narrow and auditable.

## Arc Rules

- Treat unsigned field authoring, cryptographic signing, and long-lived/compliance narratives as separate milestone layers unless a future proof-backed design shows they can be merged safely.
- Keep core focused on deterministic authored surfaces and optional adapters focused on environment-specific trust operations.
- Keep `priv/support_matrix.json`, docs-contract tests, and milestone scope in lockstep before claiming any new signing or compliance boundary.
