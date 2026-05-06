# Research Summary: Rendro v1.10 Protected Delivery Hooks & Encryption Boundaries

**Domain:** PDF protection for a deterministic, pure-Elixir, Phoenix-first document engine
**Researched:** 2026-05-06
**Overall confidence:** HIGH

## Executive Summary

Rendro should ship `v1.10` as an **external-hook-first** protection milestone. The render pipeline and writer remain unchanged; protection happens after rendering on `%Rendro.Artifact{}` through an optional executable boundary such as `qpdf`. This delivers the practical downstream need for password-to-open PDFs without forcing cryptographic non-determinism into the core engine.

## Locked Recommendations

- **Public API shape:** artifact-first (`Rendro.Protect.password/2`), not `Rendro.render/2` options
- **Algorithm scope:** AES-256 only on the public protection surface
- **Boundary posture:** advisory permissions are published as advisory only, never as hard security
- **Validation posture:** Poppler structural validation remains separate from viewer proof; all new protection viewer rows start `unverified`
- **Native encryption:** deferred; do not include in `v1.10`

## Implications for Roadmap

1. **Phase 51:** Protection API contract, typed validation, and password redaction
2. **Phase 52:** `qpdf` adapter plus password-aware Poppler validation
3. **Phase 53:** Delivery threading for protected artifacts plus support-matrix/docs closure
4. **Phase 54:** Manual proof closure and release-preflight tail

## Critical Risks

- Leaking passwords into artifact metadata, audit payloads, or persisted async job args
- Overclaiming advisory permissions as enforced security
- Publishing viewer claims before recorded manual evidence exists
- Reopening native encryption scope before the external-hook contract is settled

## Milestone Posture

This milestone is the right next step after `v1.9` because it extends downstream delivery usefulness without broadening Rendro into signatures, compliance, or native cryptographic trust operations. It should end in a releasable state so the next Hex version can be consumed immediately by `mailglass`.
