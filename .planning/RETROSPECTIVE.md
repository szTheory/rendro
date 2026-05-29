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

## Milestone: v2.3 — Viewer Proof & Interop Closure

**Shipped:** 2026-05-29 (tag v0.3.1)
**Phases:** 5 (68-72) | **Plans:** 15 | **Tasks:** 32

### What Was Built
- `explicit_deferral` as a third matrix row state alongside `supported`/`unverified`, with a required `evidence_deferred` reason that must name a specific viewer behavior or version — making non-promotable cells honest, named non-promotions distinct from un-attempted cells.
- Additive `evidence:` / `recorded_at:` / `viewer_kind:` fields on `priv/support_matrix.json` viewer rows, enforced by an in-tree two-tier JSON-Schema (Draft 2020-12) validator wired to the required `test` job — no existing field renamed or retyped, all v1.5–v2.2 readers still pass.
- `mix rendro.viewer_evidence` operator task (list / validate / missing subcommands, `--json` contract, D-22 exit codes) reporting every (surface × viewer) cell against the matrix.
- The 8th docs-contract lane (`viewer_evidence_claims_test.exs`) rejecting unevidenced `supported` rows, unnamed deferrals, forbidden vocabulary (`TBD`, `not yet`, `deferred for later`, empty), and orphan evidence files — folded into the required `test` job via `verify_docs.exs` rather than adding a new required GitHub context.
- `guides/viewer_evidence.md` operator-grade recipe under the HexDocs Policies extras group, plus the canonical `priv/viewer_evidence/<surface>/<viewer>.md` template, smoke-tested end-to-end on forms × Apple Preview.
- All 26 (surface × viewer) cells driven terminal: 17 `supported` with resolvable evidence pointers, 9 `explicit_deferral` with named reasons, 0 silently `unverified`, across forms, protection, signature widgets, signing preparation, signed artifacts, and long-lived artifacts.
- Live branch-protection audit confirming the engine-level required-check list (`signing-live-proof`, `long-lived-live-proof`, `release-proof`, `test`) grew or stayed flat, never shrank; ship gate closed at v0.3.1 with a CHANGELOG split, `@version` bump, negative Hex-tarball test, and `release.yml` preflight hardening.

### What Worked
- **Additive-only schema discipline, enforced by a validator.** Extending the matrix with new fields and a new row state — never renaming or retyping — let every v1.5–v2.2 docs-contract reader keep passing untouched while the new recording discipline failed CI before merge. The JSON-Schema validator made "strictly additive" a machine-checked invariant rather than a review-time hope.
- **`explicit_deferral` as a first-class state.** Giving non-promotable cells a named, required reason (instead of leaving them silent `unverified`) converted an ambiguous coverage gap into an auditable, honest ledger. `missing` empty ≠ everything supported — the distinction is now explicit in the data.
- **Recipe before the bulk recording.** Phase 69 published the operator recipe and walked one full cell end-to-end before phases 70/71 recorded at scale, so the parallel-safe waves had a settled template with no shape drift.
- **Parallel-safe disjoint waves.** Phases 70 (consolidate legacy) and 71 (record new + defer) touched disjoint files by design, so they ran as independent waves with no merge conflicts.
- **Structural-proxy automation kept the milestone GUI-free.** Legacy and new viewer rows were re-attested via pdfium-cli / pdfinfo / qpdf CI proof modules rather than manual GUI sessions, keeping the recording reproducible.
- **Folding the new lane into `test`, not a new required context.** The 8th docs-contract lane runs inside the existing required `test` job via `verify_docs.exs` (D-18), so the required-check list never grew a new GitHub context while still gaining enforcement.

### What Was Inefficient
- **Doubled audit filename.** The milestone audit was written as `v2.3-v2.3-MILESTONE-AUDIT.md`, so `gsd-sdk milestone.complete` reported `audit: false` and the file had to be moved into `milestones/` and renamed manually during close.
- **Auto-extracted MILESTONES.md accomplishments were per-plan and noisy.** `milestone.complete` pulled 14 plan-level one-liners (including a stray `forms × chrome_pdfium` fragment) instead of milestone-level themes, requiring a manual rewrite to the curated 6-item list — same friction noted in the v2.2 retro.
- **First audit ran too early.** The 2026-05-28 audit ran with only Phase 68 complete and returned `gaps_found`; it had to be regenerated 2026-05-29 after 69–72 verified. The regenerated audit superseded it (per D-15/D-21).
- **Traceability drift on VIEWER-02..07.** REQUIREMENTS.md still listed those rows as `[ ]`/Pending (stale from the early audit) while VERIFICATION.md and SUMMARY frontmatter confirmed completion; the checkboxes were corrected during the audit.

### Patterns Established
- **Three-state support vocabulary.** Support rows are `supported` (with evidence) / `explicit_deferral` (with a named reason) / `unverified` (un-attempted). Silent `unverified` for a known-unsupportable cell is now a recording-discipline failure, not a default.
- **Evidence-as-checked-in-text.** Per-(surface × viewer) proof lives as text-only Markdown under `priv/viewer_evidence/`, fixtures by repo-path or content hash, within a byte budget, with secret/PII scanning at the docs-contract level. Future surfaces inherit the recipe instead of re-deriving it.
- **Record the gap, never widen the engine.** Viewer shortcomings are recorded as `explicit_deferral`, never patched into the writer with per-viewer polyfills — protecting determinism and preventing false portability claims.
- **Schema-enforced additive evolution.** Public-contract data files (`priv/support_matrix.json`) evolve under a wired-in JSON-Schema validator that blocks non-additive mutation at CI time.

### Key Lessons
1. **Name the unsupportable, don't leave it silent.** A required-reason `explicit_deferral` state turned a fuzzy "unverified" backlog into a closed, auditable ledger. Honesty became structurally enforced rather than a documentation habit.
2. **Enforce "additive-only" with a validator, not a review checklist.** Wiring a JSON-Schema validator into the required job let the matrix evolve confidently without breaking a single legacy reader.
3. **Walk one cell end-to-end before recording at scale.** The Phase 69 worked example settled the template so the parallel recording waves had zero shape drift.
4. **Audit only when the milestone is actually complete.** Running the audit at Phase 68 produced a throwaway `gaps_found` verdict and stale traceability that had to be corrected later. Audit after all phases verify.
5. **Recurring close-time friction is now a pattern worth tooling.** Auto-extracted MILESTONES.md accomplishments and the per-milestone-vs-global ROADMAP convention have each caused manual rework across v2.2 and v2.3 — candidates for a project-specific close helper.

### Cost Observations
- 5 phases / 15 plans / 32 tasks across two calendar days (2026-05-28 → 2026-05-29); 78 commits.
- Recording-discipline milestone, not an engineering one: no core engine code changed (hence Nyquist replay intentionally skipped for 69–72 per D-21). New surface area was concentrated in `priv/viewer_evidence/`, the schema/validator/mix-task tooling, the 8th docs-contract lane, and viewer-proof fixtures.
- Rework: one early throwaway audit (regenerated), one manual MILESTONES.md rewrite, one manual audit-file move/rename at close.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v2.0 | 5 (55-59) | 10 | Established artifact-first signing-preparation seam and verification-backfill closure pattern. |
| v2.1 | 4 (60-63) | 8 | Established public-contract-before-adapters discipline and operationally enforced live-proof gate (`signing-live-proof` required on `main`). |
| v2.2 | 4 (64-67) | 8 | Extended live-proof gate pattern to long-lived (`long-lived-live-proof` required on `main`); established augmentation-as-separate-seam pattern and posture-vs-tool metadata split. |
| v2.3 | 5 (68-72) | 15 | Recording-discipline (not engineering) milestone: added the `explicit_deferral` three-state support vocabulary, schema-enforced additive matrix evolution, the `mix rendro.viewer_evidence` operator task + 8th docs-contract lane, and the durable `guides/viewer_evidence.md` recipe. |

### Cumulative Quality

| Milestone | Live-Proof Gates Required on `main` | First-Party Optional Adapters |
|-----------|-------------------------------------|-------------------------------|
| v2.0 | 0 | 0 (signing-prep was a first-party seam, not an adapter) |
| v2.1 | 1 (`signing-live-proof`) | 2 (pyHanko signing, pdfsig validation) |
| v2.2 | 2 (`signing-live-proof`, `long-lived-live-proof`) | 2 (pyHanko long-lived augmentation reuses signing adapter; pyHanko-backed validation) |
| v2.3 | 2 (engine lanes unchanged; viewer-evidence lane folded into required `test`, not a new context) | 0 new (manual-only recording; observer adapters deferred to a later milestone) |

### Top Lessons (Verified Across Milestones)

1. **Lock the public contract before any first-party adapter ships.** Verified in v2.1 (Phases 60 → 61) and v2.2 (Phases 64 → 65). The pattern keeps adapters from quietly widening the public surface during implementation.
2. **Operationally enforce live proof.** A required CI status check (`signing-live-proof`, `long-lived-live-proof`) turns "we tested it once" into "the supported path cannot regress unobserved." This pattern now governs every trust-sensitive seam.
3. **Publish trust-sensitive support as posture, not as one binary "supported" row.** v2.1 split signing integrity from certificate trust; v2.2 added timestamp / revocation / narrow compliance as distinct signals. Operators read truth at the granularity their workflow needs, and over-claiming becomes structurally hard.
4. **Reuse one taxonomy for adjacent trust capabilities.** Embedded files and links shared the artifact-surface taxonomy in v1.9; long-lived shares the signing taxonomy in v2.2. Adjacent capabilities should nest under existing families instead of creating new top-level rows.
