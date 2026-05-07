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

## Next Candidate

### Post-v2.0 Cryptographic Signing & Compliance Proof

- **Status:** candidate
- **Why after v2.0:** The unsigned-field and signing-preparation contract is now shipped, so any further signing work should focus only on proof-backed cryptographic trust and compliance surfaces rather than reopening preparation semantics.
- **Scope recommendation:**
  - Optional adapter/workflow boundaries for actual cryptographic signing
  - Proof-backed viewer and validator evidence for signed-artifact claims
  - Separate compliance narratives only if specific evidence lanes justify them
- **Non-goals:**
  - Re-scoping unsigned widget authoring or preparation fundamentals
  - Implicit trust or compliance marketing without recorded evidence
  - In-core certificate management by default

## Follow-On Direction

- Keep any post-`v2.0` milestone focused on proof-backed cryptographic-signature and compliance work only if the unsigned-field and signing-preparation contract proves stable in real usage.
- Continue treating viewer promotion as evidence-gated and separate from structural or cryptographic validity claims.

## Arc Rules

- Treat embedded artifacts, protection, and signatures as separate milestones unless a future proof-backed design shows they can be combined without widening the trust contract.
- Keep core focused on deterministic authored surfaces and optional adapters focused on environment-specific trust operations.
- Keep `priv/support_matrix.json`, docs-contract tests, and milestone scope in lockstep before claiming any new support boundary.
