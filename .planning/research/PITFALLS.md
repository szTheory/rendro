# Project Research — Pitfalls for v2.1 Cryptographic Signing & Signed-Artifact Proof

**Milestone:** v2.1 Cryptographic Signing & Signed-Artifact Proof
**Date:** 2026-05-07

## Major pitfalls

### Collapsing multiple trust claims into one

- Risk: saying "signed" as if it also proves certificate trust, viewer acceptance, or compliance.
- Prevention: publish separate support-matrix/docs language for signature integrity, certificate trust, viewer posture, and deferred compliance.
- Phase pressure: must be handled no later than the support-contract phase.

### Letting credentials leak into errors or metadata

- Risk: key paths, passphrases, temp paths, or raw stderr escaping in typed errors or artifact metadata.
- Prevention: keep adapter opts redacted, expose only safe adapter metadata, and test redaction paths explicitly.
- Phase pressure: must be handled in the public contract phase before adapter proof is trusted.

### Treating signed output as deterministic

- Risk: downstream docs or tests accidentally imply that cryptographically signed bytes should match across runs.
- Prevention: mark signed artifacts non-deterministic, keep deterministic claims limited to pre-sign unsigned output, and phrase proof lanes accordingly.
- Phase pressure: must be handled with the public API and metadata contract.

### Over-coupling core to a tool choice

- Risk: pyHanko or pdfsig semantics leaking into core abstractions or mandatory dependencies.
- Prevention: keep both behind optional runtime adapters and document the supported path as "first-party proof-backed," not universal.
- Phase pressure: adapter phase.

### Premature compliance scope

- Risk: sneaking timestamps, revocation evidence, or PAdES language into the milestone because the tools can do more.
- Prevention: freeze `v2.1` to one basic signing path and explicitly defer long-lived-signature/compliance stories to the next candidate milestone.
- Phase pressure: roadmap and docs phases.
