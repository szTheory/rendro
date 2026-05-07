# Rendro Milestone Arc

**Last updated:** 2026-05-07
**Purpose:** Preserve the recommended next-milestone sequence so milestone-definition work does not reopen already-set architectural tradeoffs unless the project direction materially changes.

## Last Shipped Milestone

### v2.0 Signature Fields & External Signing Preparation

- **Status:** shipped
- **Why now:** Extended Rendro's authored forms and artifact-first trust seams into unsigned signature widgets and external-signing preparation without turning core into a cryptographic trust stack.
- **Scope recommendation:**
  - Unsigned signature-field authoring on the shared `%Rendro.FormField{}` seam
  - Deterministic unsigned widget serialization on the existing AcroForm path
  - Artifact-first external-signing preparation with explicit adapter isolation
- **Non-goals:**
  - Core key custody
  - PAdES/LTV/TSA/OCSP/CRL support
  - Broad compliance or cryptographic-signature claims

## Active Milestone

### v2.1 Cryptographic Signing & Signed-Artifact Proof

- **Status:** active
- **Why after v2.0:** The unsigned-field and signing-preparation contract is shipped, and the narrowest next step is to prove a real cryptographic-signing path over that seam instead of widening into generic compliance or viewer marketing.
- **Scope recommendation:**
  - Artifact-first cryptographic signing through `Rendro.Sign.sign/2`
  - First-party optional runtime adapters for signing and signed-artifact validation
  - Proof-backed support language that separates signature integrity, certificate trust, viewer posture, and deferred compliance narratives
- **Non-goals:**
  - Re-scoping unsigned widget authoring or signing preparation fundamentals
  - In-core certificate management, key custody, or signer workflows by default
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

- Keep post-`v2.0` signature work focused on proof-backed cryptographic behavior first, then compliance evidence later if the signing seam proves stable in real usage.
- Continue treating viewer promotion as evidence-gated and separate from structural, cryptographic, and compliance validity claims.
- Keep support-matrix growth tied to exact proof lanes and milestone scope so the public contract stays narrow and auditable.

## Arc Rules

- Treat unsigned field authoring, cryptographic signing, and long-lived/compliance narratives as separate milestone layers unless a future proof-backed design shows they can be merged safely.
- Keep core focused on deterministic authored surfaces and optional adapters focused on environment-specific trust operations.
- Keep `priv/support_matrix.json`, docs-contract tests, and milestone scope in lockstep before claiming any new signing or compliance boundary.
