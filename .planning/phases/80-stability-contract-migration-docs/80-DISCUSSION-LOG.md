# Phase 80: Stability Contract & Migration Docs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 80-stability-contract-migration-docs
**Areas discussed:** Guide rewrite structure, Internal-label scrub scope, Tier-1 claims test scope, Upgrade guide + carve-out content
**Mode:** advisor (`minimal_decisive` tier — parallel grounded research per area, decisive single recommendation, accepted as written)

---

## Guide rewrite structure (STAB-01/02)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Contract-first restructure | Two-tier contract + deprecation table lead; per-surface boundary blocks relocated verbatim below | ✓ |
| B — Additive prepend only | New sections on top, every existing block left in historical place | |

**User's choice:** A (Accept all four).
**Notes:** Research surprise — the framed "release-proof breakage" risk largely dissolves: every guide assertion is a position-independent `guide =~ "substring"` match (no line/ordering regexes against the guide; the only ordering regexes target `support_matrix.json`). Moving blocks byte-identical = zero forced test churn. Discipline: verify with `mix test test/docs_contract/` + `release-proof` before commit; new carve-out prose must avoid `refute`-banned overclaim phrases.

---

## Internal-label scrub scope (STAB-04)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Scrub all leaking public guides | api_stability.md + viewer_evidence.md (other 6 extras already clean) | ✓ |
| B — Only requirement-enumerated guides | Smallest diff; leaves Phase 71 leaks in viewer_evidence.md | |

**User's choice:** A.
**Notes:** Only TWO leaks are CI-pinned (both `protection_claims_test.exs`: the v1.10 AES-256 line + the "Phase 53 does not introduce…" line) — updated in lockstep, dropping the label while preserving the substantive claim. ~13 other occurrences are free prose edits + 3 test title/comment renames. `refute` guards (viewer_evidence_claims_test.exs:106-107) enforce the scrub and are kept.

---

## Tier-1 claims test scope (STAB-05)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Guide-named symbols only | Single-responsibility claims test; disjoint from Phase 79 manifest lane | ✓ |
| B — Full-manifest reconcile | Cross-check guide against all 27 stable/18 adapter modules | |

**User's choice:** A.
**Notes:** Phase 79's `public_api_contract_test.exs` already owns manifest==code + tier-tag + `@spec` coverage; B duplicates it. Landmine surfaced: the current guide names `Rendro.Inspector`, which is NOT in the stable manifest — the rewrite must reconcile (this is exactly the prose-vs-reality drift STAB-05 catches). Assertion set: guide-named symbol existence (false-pass guarded) + tier headers + key promise sentences + `upgrading_to_1.0.md` presence + verify_docs.exs lane registration.

---

## Upgrade guide + carve-out content (STAB-01/03)

| Option | Description | Selected |
|--------|-------------|----------|
| Upgrade framing A — reassurance only | "1.0 = stability, no code changes" + tier summary + matrix pointer | |
| Upgrade framing B — reassurance + "new since 0.3.0" digest | Same + short forward-pointing digest of v2.3/v2.4 additions | ✓ |
| Carve-out — curated list | Real/currently-true/testable bullets only | ✓ |
| Deprecations table — A+ (truthful + prose example) | `_None as of 1.0.0_` sentinel row; format shown via illustrative prose example | ✓ |

**User's choice:** B framing + curated carve-out + truthful empty table (Accept all four).
**Notes:** Forward-pointing rule — do NOT deep-link the unwritten `## [1.0.0]` CHANGELOG anchor (Phase 82/REL-04 writes it); link CHANGELOG generically, point support claims at api_stability.md. "NOT covered" list = byte output across versions (headline) + internals + diagnostics/metadata exact shape + adapter-tracks-upstream + error-message wording + log/telemetry text. EXCLUDE support-matrix contents (covered evidence-backed contract). Soft-deprecate-first is mandatory because `mix ci` compiles `--warnings-as-errors`. Ecosystem precedent: Elixir compatibility-and-deprecations doc + Oban "Upgrading to v2.0".

---

## Claude's Discretion

- Exact prose wording, heading text, and ordering within the rewritten guide and new upgrade guide (subject to byte-identical-move + banned-phrase constraints).
- Final list of symbols named in the rewritten prose (the `Rendro.Inspector` reconcile) and therefore asserted by STAB-05.

## Deferred Ideas

- `@doc since:` retrofitting across 0.x — out of scope (going-forward only).
- CHANGELOG `## [1.0.0]` consolidation entry — Phase 82 (REL-04).
- Version bump / source_ref / package links / `:mix_audit` — Phase 81 (REL-01).
- Tarball allowlist audit (operator/evidence artifacts absent) — Phase 81 (REL-02).
- release-please / conventional-commits — deferred post-1.0 (AUTO-01).
