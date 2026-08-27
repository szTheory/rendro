# Phase 133: Repository & Evidence Hygiene - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-26
**Phase:** 133-repository-evidence-hygiene
**Areas discussed:** Durable evidence structure, Historical evidence retention, Archive and script ownership, Hygiene enforcement

---

## Durable Evidence Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Keep Phase 131 planning authoritative | Retain archived paths as operational inputs. Lowest migration cost, but archive structure remains executable and brittle. | |
| One flat mutable release-facts JSON | Put prerequisite, release, journey, and incident facts in one record. Simple path, but mixed authority and rewrite risk. | |
| Indexed version-scoped evidence capsule | Use one manifest with separate authority-specific records, schemas, digests, and provenance outside the Hex package. | ✓ |

**User's choice:** Accepted the complete researched recommendation package.
**Notes:** Emphasized Elixir/Phoenix ecosystem fit, consumer-first design, least surprise, maintainer/SRE/DevOps lenses, strong DX, and a coherent one-shot recommendation rather than isolated local choices.

---

## Historical Evidence Retention

| Option | Description | Selected |
|--------|-------------|----------|
| Retain only successful proof | Smallest active corpus, but loses incident history and failure provenance. | |
| Summarize failures in a mutable record | Easier browsing, but rewrites historical evidence and discards exact identity. | |
| Append-only structured records with narrative sidecars | Preserve every attempt, original hashes, provenance, lane, corrections, and explanatory text without making history operational. | ✓ |

**User's choice:** Accepted the complete researched recommendation package.
**Notes:** Failed attempts remain immutable and non-retryable; a correction appends a superseding record. Deterministic checks validate structure and identity without promoting advisory evidence.

---

## Archive and Script Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Leave loose files and infer ownership from Git | No moves, but the current tree remains ambiguous and helpers stay ownerless. | |
| Copy files and leave redirect stubs | Preserves old paths, but creates duplicate authorities and drift. | |
| Move history once and govern retained scripts explicitly | Preserve Git history in milestone archives; inventory every retained helper by purpose, owner role, caller, authority, and lifecycle. | ✓ |

**User's choice:** Accepted the complete researched recommendation package.
**Notes:** Current brand sources supersede old prompt-era brand guidance. Planning-aware checks receive a narrow `gsd_tooling` label instead of becoming a broad exception.

---

## Hygiene Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Rely on `mix.exs` and spot assertions | Idiomatic positive file list, but does not prove the complete tarball or tracked planning placement. | |
| Broad denylist scans | Catches known debris, but misses new classes and creates false positives. | |
| One policy-driven fail-closed Mix gate | Inspect the actual Hex payload, exact expected membership, tracked placement, archive consumers, and narrow owned exceptions with actionable output. | ✓ |

**User's choice:** Accepted the complete researched recommendation package.
**Notes:** The command runs locally, in `ci.fast`, and from release checkout. It does not reject unrelated untracked developer files; it fails only when a durable boundary is crossed.

---

## the agent's Discretion

- Exact internal module, test, schema, and manifest filenames within the locked evidence-capsule responsibilities.
- Exact opaque record-ID syntax and manifest formatting.
- Exact destination for genuinely unmappable legacy phases, provided uncertainty is recorded and no provenance is invented.
- Narrow implementation mechanics for the shared loader and Mix hygiene gate using existing dev/test infrastructure.

## Deferred Ideas

- Generalize the fixed v1.3.4 advisory clean-room release job and capsule design for future releases after the bounded migration proves the contract.
