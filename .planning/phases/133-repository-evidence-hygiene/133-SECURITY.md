---
phase: 133
slug: repository-evidence-hygiene
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-26
---

# Phase 133 — Security

> Verified threat contract for the repository evidence capsule, archive boundaries, helper ownership, and package hygiene controls.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Evidence capsule → maintainer scripts | Internal release facts become inputs to clean-room and public-release verification only after loader validation. | Release identity, prerequisite, validation, and advisory journey facts |
| Repository → hygiene policy | Tracked paths and the actual unpacked Hex artifact are inspected without becoming runtime dependencies. | File paths, package members, helper inventory, planning references |
| Active planning → milestone archives | Historical planning moves to its proven milestone owner while active operational consumers remain prohibited. | Historical plans, summaries, research, and provenance |
| Local gates → CI/release | One deterministic hygiene command runs locally, in `ci.fast`, and in release validation; proof-only checks remain advisory. | Gate results and package metadata |
| Test fixtures → external viewers | PDF.js/PDFium observations use test-owned inputs and cannot inflate unavailable advisory evidence into deterministic proof. | Test PDFs and viewer observations |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-133-01 | Traversal / substitution / disclosure | Evidence loader filesystem boundary | high | mitigate | Confined regular non-symlink paths, SHA-256 verification, and mutation tests in `repository_evidence_test.exs`. | closed |
| T-133-02 | Stale or duplicate identity | Manifest and core roles | high | mitigate | Strict schemas, singleton core roles, unique IDs/paths, and release binding validation. | closed |
| T-133-03 | Provenance rewrite | Evidence envelopes | high | mitigate | Source/import separation, source commits and digests, facts digests, redaction facts, and sidecar binding. | closed |
| T-133-04 | Role or schema substitution | `load_role/1` dispatch | high | mitigate | Fixed role allowlist and shared fail-closed path/schema/digest/binding pipeline. | closed |
| T-133-05 | Journey rewrite or disclosure | Journey records and narratives | high | mitigate | Nine source-bound records, redaction classification, facts digests, and confined sidecar digest validation. | closed |
| T-133-06 | Journey omission or reordering | Journey index | high | mitigate | Exact ordered one-to-one index/manifest correspondence and nine-record/eight-sidecar cardinality tests. | closed |
| T-133-07 | Release identity substitution | Clean-room and public-release consumers | high | mitigate | All active consumers use `Rendro.RepositoryEvidence`; the loader verifies release, tag, and candidate bindings. | closed |
| T-133-08 | Archived planning as active authority | Operational-source scan | high | mitigate | Elixir, shell, JavaScript, and workflow sources are scanned; only two named `gsd_tooling` surfaces are exempt. | closed |
| T-133-09 | Unique-history loss | Legacy journey batch A | high | mitigate | Capsule provenance/fact/sidecar assertions were proven before deletion; focused contracts remain green. | closed |
| T-133-10 | Omission or pre-schema erasure | Legacy journey batch B | high | mitigate | Exact 9/8 cardinality and the explicit sidecar-less pre-schema record are enforced before deletion. | closed |
| T-133-11 | Provenance substitution | Phase 5 archive | high | mitigate | Commit `dbc81eb9` records a 100% Git rename into the proven v1.0 owner; the loose source is absent. | closed |
| T-133-12 | Provenance or history loss | Phase 45 archive | high | mitigate | Commit `58f649ef` records seven Git renames into the proven v1.8 owner; loose sources are absent. | closed |
| T-133-13 | Tooling privilege inflation | `scripts/` helper surface | high | mitigate | Every retained executable has an owner/caller/lane/removal trigger; three ownerless scripts were removed. | closed |
| T-133-14 | Package leakage | Hex artifact membership | high | mitigate | Sorted actual-versus-expected member diff plus forbidden-class rejection; `mix quality.hygiene` passes. | closed |
| T-133-15 | Temp corruption or denial of service | Package unpack workspace | high | mitigate | Cryptographically suffixed per-run temp roots, unconditional cleanup, and concurrency/failure tests. | closed |
| T-133-16 | Tooling elevation | Planning-reference exemptions | high | mitigate | Exemptions are limited to the named hygiene policy and governance script and cannot grant product/release authority. | closed |
| T-133-17 | Package omission or release-gate bypass | Mix and release workflow | high | mitigate | Explicit package list and the same hygiene command wired into local, `ci.fast`, and release paths. | closed |
| T-133-18 | Package proof leakage | PDF.js observer fixture | high | mitigate | Observer uses a test-only regular fixture that is absent from the package manifest. | closed |
| T-133-19 | Repudiation or authority inflation | QL-002 lifecycle | high | mitigate | Closure records deterministic scans/gates and keeps unavailable PDFium evidence explicitly deferred under NS-006. | closed |

## Accepted Risks Log

No accepted risks. Unavailable PDFium viewer evidence is an explicit advisory deferral, not an accepted security bypass or a completion claim.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-26 | 19 | 19 | 0 | `gsd-security-auditor` (ASVS L1) |

Focused audit verification: `mix quality.hygiene` passed; capsule/consumer/hygiene/guardrail tests passed with 93 tests and 0 failures.

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks are documented (none).
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-08-26
