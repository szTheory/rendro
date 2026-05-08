# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v2.2 — Long-Lived Signatures & Compliance Evidence

**Shipped:** 2026-05-08
**Phases:** 4 (64-67) | **Plans:** 8 | **Files changed:** 41 (+3,220 / -236)

### What Was Built
- `Rendro.Sign.augment/2`: artifact-first long-lived-signature seam over signed artifacts, separate from `sign/2` and `Rendro.render/2` semantics, with typed redacted `:augment` errors and explicit non-deterministic posture on every augmented artifact.
- First-party optional pyHanko long-lived adapter that adds timestamp and revocation evidence over the supported signed-artifact seam without claiming certificate-trust ownership and without introducing a hard runtime dependency in core.
- Validator-backed posture classification: `validate/2` reports cryptographic integrity, timestamp presence, revocation evidence presence, and narrow compliance posture as distinct signals; trust-explicit checks live behind a separate `validate_trust/2` seam.
- Offline `long-lived-live-proof` CI lane backed by a localhost certomancer PKI/TSA/OCSP fixture, exercising the full `sign → augment → validate` path end-to-end and required as a status check on `main`.
- Truthful support contract: `priv/support_matrix.json` publishes long-lived evidence under nested `signing.long_lived` rather than a new top-level family; `guides/api_stability.md` and docs-contract tests lock the exact supported nouns and keep blanket PDF/A, signer trust, viewer behavior, and multi-signature workflows visibly separate.
- Phase 67 verification ledger and closeout artifacts: `67-VERIFICATION.md` cites the live proof lanes that back the supported long-lived path, and `67-CLOSEOUT.md` carries the deferred-scope vocabulary forward verbatim into the v2.3/v2.4 handoff.

### What Worked
- **Locking semantics before adapters.** Phase 64 fixed the public API contract, redaction rules, and metadata posture before any first-party adapter shipped — so when Phase 65 landed, the adapter and validator code had nowhere to widen the public surface. Same discipline that worked in v2.1 for signing.
- **Posture-vs-tool split in metadata.** Splitting `metadata.long_lived` (shared, posture-only) from `metadata.long_lived_adapter` (allowlisted tool-shaped facts) kept the public surface stable while still letting adapters publish concrete evidence. No accidental coupling between operator-readable posture and tool-internal data.
- **Offline-first live proof.** Building the `long-lived-live-proof` lane on top of certomancer (localhost PKI/TSA/OCSP) instead of public PKI endpoints made the gate reproducible across forks, branches, and offline machines. Public-network dependence stayed strictly out of the required lane.
- **One canonical recipe across local and CI.** Publishing exactly one local recipe and one CI recipe in `guides/api_stability.md`, both downstream of the same proof command, kept the docs-contract lockstep narrow and easy to audit.
- **Caveat-forward state tracking.** When the artifact ledger reached completion but the branch-protection update was still pending, STATE.md and the closeout note carried the open caveat verbatim instead of pretending the milestone was fully shipped. The caveat then closed cleanly and explicitly on 2026-05-08.

### What Was Inefficient
- **Two MILESTONES.md entries.** `gsd-sdk milestone complete` appended a freshly auto-extracted v2.2 entry on top of the more detailed entry already written at the original ship commit, requiring a manual deduplication during close. The detailed entry was the correct one to keep.
- **Plan-count miscount in `roadmap.analyze`.** The CLI counted `66-PLAN-CHECK.md` as a third plan in Phase 66 (so it reported `progress_percent: 89` instead of 100), even though `phase-plan-index` correctly reported only the two canonical plans. Stale `roadmap.analyze` numbers required cross-checking against `phase-plan-index` before accepting the readiness verdict.
- **Roadmap convention drift.** The default `complete-milestone` workflow assumes one global ROADMAP.md with milestone groupings; this project actually overwrites ROADMAP.md per-milestone and restores the long-term strategic version on close. Reconciling those two conventions added a manual step.

### Patterns Established
- **Augmentation-as-separate-seam pattern.** New trust-sensitive capabilities (long-lived, future revocation refresh, future trust-store layering) live on additional explicit artifact-stage APIs (`Rendro.Sign.augment/2`-shaped) rather than as new options on existing seams. Keeps signing, augmentation, validation, and trust-explicit checks as four boundaries instead of one widening API.
- **Nested support taxonomy.** Trust-sensitive features publish under nested keys in `priv/support_matrix.json` (e.g. `signing.long_lived`) instead of as new top-level families, so adjacent capabilities inherit the integrity baseline without colliding with viewer or compliance rows.
- **Validator output as a posture record, not a binary verdict.** Validation results carry distinct `integrity` / `timestamp` / `revocation` / `compliance_evidence` signals; trust verdicts live behind a separate `validate_trust/2` call. Operators can read truth at the granularity their workflow actually needs.
- **Caveat-forward closeout artifacts.** Closeout notes consume canonical verification ledgers and explicitly carry forward open operational caveats (branch-protection, viewer rows, etc.) instead of retelling proof or hiding open items behind "shipped."

### Key Lessons
1. **Lock the public contract before any adapter ships.** Phases 64 → 65 mirrored Phases 60 → 61 and produced the same outcome: the adapter could only land where the public surface had room for it. This pattern is now load-bearing for trust-sensitive milestones.
2. **Offline fixtures beat public endpoints for required lanes.** Any required CI gate that depends on the open internet eventually flakes; certomancer-style localhost fixtures give the same proof shape with none of the operational risk.
3. **Distinguish artifact closure from operational closure.** A milestone can have all artifacts complete while still being one repository-policy step away from operational closure. Naming that gap explicitly (rather than rolling it into "we shipped") preserved truth across two days of state without any rewriting.
4. **Trust the authoritative source over the analytics source.** When `roadmap.analyze` and `phase-plan-index` disagreed on Phase 66's plan count, the index file (built directly from canonical plan files) was right and the analytics was wrong. Default to the canonical source.

### Cost Observations
- Plan count: 8, all completed in two calendar days (2026-05-07 → 2026-05-08).
- Rework: Phase 65 plan summaries and validation strategy needed a `record summaries` follow-up (commit `467c84b`); operational closure required a final branch-protection commit (`04142e1`) before truthful close.
- Notable: most milestone work was contained inside the existing signing test suite — only one new test fixture directory (`test/fixtures/signing/certomancer/`) and one new helper (`priv/support/pyhanko_validate.py`) entered the codebase.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v2.0 | 5 (55-59) | 10 | Established artifact-first signing-preparation seam and verification-backfill closure pattern. |
| v2.1 | 4 (60-63) | 8 | Established public-contract-before-adapters discipline and operationally enforced live-proof gate (`signing-live-proof` required on `main`). |
| v2.2 | 4 (64-67) | 8 | Extended live-proof gate pattern to long-lived (`long-lived-live-proof` required on `main`); established augmentation-as-separate-seam pattern and posture-vs-tool metadata split. |

### Cumulative Quality

| Milestone | Live-Proof Gates Required on `main` | First-Party Optional Adapters |
|-----------|-------------------------------------|-------------------------------|
| v2.0 | 0 | 0 (signing-prep was a first-party seam, not an adapter) |
| v2.1 | 1 (`signing-live-proof`) | 2 (pyHanko signing, pdfsig validation) |
| v2.2 | 2 (`signing-live-proof`, `long-lived-live-proof`) | 2 (pyHanko long-lived augmentation reuses signing adapter; pyHanko-backed validation) |

### Top Lessons (Verified Across Milestones)

1. **Lock the public contract before any first-party adapter ships.** Verified in v2.1 (Phases 60 → 61) and v2.2 (Phases 64 → 65). The pattern keeps adapters from quietly widening the public surface during implementation.
2. **Operationally enforce live proof.** A required CI status check (`signing-live-proof`, `long-lived-live-proof`) turns "we tested it once" into "the supported path cannot regress unobserved." This pattern now governs every trust-sensitive seam.
3. **Publish trust-sensitive support as posture, not as one binary "supported" row.** v2.1 split signing integrity from certificate trust; v2.2 added timestamp / revocation / narrow compliance as distinct signals. Operators read truth at the granularity their workflow needs, and over-claiming becomes structurally hard.
4. **Reuse one taxonomy for adjacent trust capabilities.** Embedded files and links shared the artifact-surface taxonomy in v1.9; long-lived shares the signing taxonomy in v2.2. Adjacent capabilities should nest under existing families instead of creating new top-level rows.
