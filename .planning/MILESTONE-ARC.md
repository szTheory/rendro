# Rendro Milestone Arc

**Last updated:** 2026-05-06
**Purpose:** Preserve the recommended next-milestone sequence so milestone-definition work does not reopen already-set architectural tradeoffs unless the project direction materially changes.

## Last Shipped Milestone

### v1.10 Protected Delivery Hooks & Encryption Boundaries

- **Status:** shipped
- **Why now:** Added a truthful PDF protection story through an external artifact-first boundary without destabilizing deterministic core rendering or widening into compliance/signature claims.
- **Scope recommendation:**
  - External post-processing/enforcement hooks first
  - Truthful docs/support-matrix language around password protection vs advisory permissions
  - Proof-backed validation before any broader encryption story
- **Non-goals:**
  - Weak/legacy algorithms
  - Broad compliance or archival claims
  - Marketing PDF permissions as hard security

## Active Milestone

### v2.0 Signature Fields & External Signing Preparation

- **Status:** active
- **Why after v1.10:** Signature work is a higher-trust, higher-surprise surface that should follow the newly-shipped protection boundaries rather than overlap them.
- **Scope recommendation:**
  - Unsigned signature-field authoring in core
  - Deterministic preparation seams for external signing
  - Optional adapter/workflow boundary for actual cryptographic signing
- **Non-goals:**
  - Core key custody
  - PAdES/LTV/OCSP/CRL/TSA support
  - Broad compliance claims

## Follow-On Direction

- Keep any post-`v2.0` milestone focused on proof-backed cryptographic-signature and compliance work only if the unsigned-field and signing-preparation contract proves stable in real usage.

## Arc Rules

- Treat embedded artifacts, protection, and signatures as separate milestones unless a future proof-backed design shows they can be combined without widening the trust contract.
- Keep core focused on deterministic authored surfaces and optional adapters focused on environment-specific trust operations.
- Keep `priv/support_matrix.json`, docs-contract tests, and milestone scope in lockstep before claiming any new support boundary.
