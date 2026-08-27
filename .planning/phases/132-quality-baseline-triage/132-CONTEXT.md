# Phase 132: Quality Baseline & Triage - Context

**Gathered:** 2026-08-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the dated, reproducible quality baseline, durable current quality ledger, compatibility contract, and evidence-gated finding set that governs Phases 133-137. This phase classifies and assigns work; it does not perform the later repository, architecture, test/CI, or catalog repairs and does not add product capabilities.

</domain>

<decisions>
## Implementation Decisions

### Ledger Form and Audience
- **D-01:** Use one human-first, repository-native `.planning/QUALITY.md` as the canonical current finding ledger. It must be concise, Git-reviewable, usable offline, and independent of archived phase artifacts.
- **D-02:** Organize the ledger around the compatibility contract, baseline registry/reference, disposition rules, active findings, resolved/rejected findings, deferred triggers, and a baseline-versus-final section populated in Phase 137.
- **D-03:** The ledger serves maintainers, reviewers, contributors, and downstream planning agents. Product code, package contents, release workflows, and ordinary regression tests must not consume it as executable state.
- **D-04:** Do not introduce Ecto, a hosted dashboard, GitHub Issues, or generated machine data as the canonical ledger. Structured companion evidence is appropriate only where machine validation adds value.

### Finding Identity and History
- **D-05:** Give every finding a permanent, opaque, sequential ID such as `QL-001`. Never encode severity, area, owner phase, or filename in the ID; never renumber or reuse IDs.
- **D-06:** Deduplicate by underlying cause plus compatibility/ownership boundary. Multiple tools, files, or symptoms become evidence on one finding when they share that boundary; keep separate findings when ownership, blast radius, remediation, or verification differs.
- **D-07:** Use the lifecycle `observed -> triaged`, then `accepted -> in_progress -> verified -> closed`, with explicit `rejected`, `deferred`, `accepted_risk`, and `superseded` branches where applicable.
- **D-08:** Preserve resolved, rejected, deferred, reopened, related, and superseded relationships. Rely on Git for line-level history while retaining the finding's opened date, meaningful state changes, disposition, closing evidence, and resolution reference in the ledger.
- **D-09:** Reopen an existing ID only when new evidence invalidates its prior disposition. Create a new related ID for a distinct regression or recurrence.

### Baseline Evidence
- **D-10:** Use two evidence layers: commit normalized, schema-valid, redacted baseline snapshots and keep large raw logs/binaries as bounded, hash-bound CI artifacts. `QUALITY.md` links the durable normalized snapshot and its raw evidence references.
- **D-11:** Each normalized evidence item records a stable item ID, schema version, exact source SHA, UTC capture time, clean/dirty worktree state, OS and toolchain identities, dependency-lock identity where relevant, renderer identity where relevant, registered command, evidence lane, normalized result, `passed | failed | unavailable` status, unavailability reason, raw-output SHA-256/byte count/location/expiry, and redaction classification.
- **D-12:** Register and reuse the existing project contracts rather than inventing parallel commands: `mix ci.fast`, `mix ci.proofs`, `mix ci.advisory`, xref stats and compile-connected diagnostics, coverage/slow-test diagnostics, `mix hex.build`, and the existing public API/catalog contracts.
- **D-13:** Preserve deterministic, proof, advisory, and human-review authority boundaries. Unavailable advisory evidence remains explicitly unavailable and cannot be coerced to zero, failure, or success. Local reproduction is valid evidence; the pinned primary CI environment remains authoritative for CI-only evidence.
- **D-14:** Keep the initial Phase 132 baseline immutable. Phase 137 adds a final snapshot and before/after comparison rather than overwriting the starting evidence. Do not commit raw generated logs, PDFs, PNGs, or reports merely for offline completeness, and never use caches as evidence.

### Risk and Disposition Governance
- **D-15:** Use an evidence-gated qualitative rubric, not a calculated composite score. Record `impact`, `confidence`, `compatibility risk`, `evidence quality`, optional likelihood where meaningful, and a justified qualitative priority as independent fields.
- **D-16:** Use `low | medium | high` for impact and confidence. Use `none | bounded_internal | public_api | rendered_bytes | evidence_authority` for compatibility risk. Use `signal | reproducible | contract_backed | independently_reviewed` for evidence quality.
- **D-17:** High priority means a credible threat to a supported contract, rendered-byte guarantee, security boundary, release/package correctness, CI authority, or truthful evidence. Medium means demonstrated bounded maintenance/test/docs/workflow cost without a current public-contract break. Low/signal means an observation or preference without demonstrated harm.
- **D-18:** Allowed dispositions are `repair`, `defer`, `reject_signal`, rare time-bounded `accept_risk`, and `superseded`. A signal alone cannot justify a repair.
- **D-19:** High findings must be repaired or rejected with evidence before Phase 137. Medium findings receive a bounded repair or a concrete trigger-backed deferral. Low/style signals do not create standalone churn and may only be addressed incidentally inside an already-justified change.
- **D-20:** A repair requires an owner phase, scope boundary, focused verification, relevant full gate, before/after statement, and resolution reference. A deferral requires a concrete event trigger, evidence-refresh rule, and owner. `reject_signal` records why evidence is insufficient and what would reopen it. `accept_risk` requires compensating evidence/control, an owner, and an expiry or review event.
- **D-21:** Labels, severity changes, improved diagnostic counts, or unrelated green tests cannot close a finding. Closure requires the predeclared proof and compatibility evidence.
- **D-22:** Owner routing follows the roadmap: Phase 133 owns repository/evidence hygiene, Phase 134 architecture/readability, Phase 135 tests and CI authority, Phase 136 the six catalog cells, and Phase 137 final evidence reconciliation. Phase 132 owns classification.

### Maintainer Experience
- **D-23:** Optimize the ledger for the maintainer JTBD: reproduce the baseline, understand why a finding matters, see the evidence boundary, and know exactly what action or proof closes it.
- **D-24:** Use plain domain language: `baseline`, `evidence item`, `finding`, `disposition`, `owner phase`, `verification`, `trigger`, and `closure`. Follow Rendro's current voice: lead with concrete facts, state limits beside claims, explain failures with next actions, and avoid opaque scores, hype, or enterprise ceremony.

### the agent's Discretion
- Choose the exact companion snapshot directory, schema filenames, and repository-owned validation mechanism while preserving the human-first canonical ledger and archive-independent evidence contract.
- Choose the precise Markdown table/layout and whether long evidence references use footnotes or compact linked subsections, provided ordinary Git diffs remain scannable.
- Choose focused contract-test mechanics for IDs, required fields, transitions, and evidence references. Do not turn free-form ledger prose into a pseudo-database or add a runtime dependency.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Locked Project Boundaries
- `.planning/ROADMAP.md` — Phase 132 goal, success criteria, requirements mapping, phase ownership, and milestone sequencing.
- `.planning/REQUIREMENTS.md` — AUDIT-01 through AUDIT-04 plus the compatibility, evidence, and no-churn boundaries shared across v2.14.
- `.planning/PROJECT.md` — Current milestone outcomes, public-contract constraints, quality discipline, and project-wide architecture decisions.
- `.planning/STATE.md` — Accumulated v2.14 decisions, current baseline signals, blockers, and deferred capability gates.

### Current v2.14 Research
- `.planning/research/SUMMARY.md` — Research synthesis, phase ordering rationale, and gaps that Phase 132 must resolve.
- `.planning/research/ARCHITECTURE.md` — Quality control-plane architecture, proposed durable ledger responsibility, finding flow, and archive-independence boundary.
- `.planning/research/FEATURES.md` — Maintainer outcomes, table stakes, anti-features, and quality-ratchet acceptance boundaries.
- `.planning/research/PITFALLS.md` — Cleanup churn, metric gaming, executable planning history, evidence-authority, weaker-test, and stale-ledger failure modes.
- `.planning/research/STACK.md` — Existing Elixir/Mix quality tools, diagnostic boundaries, workflow trust rules, and the decision not to add speculative tooling.

### Product and Engineering DNA
- `prompts/rendro-oss-dna.md` — Canonical verification lanes, docs contracts, package boundaries, archive lessons, and truthful evidence semantics learned across sibling Elixir libraries.
- `prompts/rendro-gsd-seed.md` — Non-negotiable core value, personas/JTBD, pure-core constraints, and lifecycle checks.
- `prompts/rendro-integration-opportunities.md` — Evidence/audit JTBD language and optional-integration boundary; useful context without expanding Phase 132 scope.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Original ecosystem research on maintainer/SRE personas, deterministic evidence, validation, developer ergonomics, and scope footguns.

### Current Brand and Maintainer UX
- `brand/README.md` — Current brand source hierarchy; supersedes relying on the older prompt-only brand book for operational presentation decisions.
- `brand/copy/VOICE.md` — Current concrete, honest, maintainer-first voice and microcopy rules for evidence, failures, limits, and next actions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix.exs` aliases: existing `ci.fast`, `ci.proofs`, `ci.advisory`, catalog, docs, package, Credo, and Dialyzer commands form the baseline command registry instead of requiring a new quality stack.
- `priv/public_api.json` plus public API contract tests: established fail-loud manifest pattern for preserving supported API boundaries.
- `priv/quality/rubric_scores.json` plus `priv/schemas/rubric_scores.schema.json`: established repository-owned JSON/schema pattern for structured evidence when machine validation is justified.
- `test/support/docs_contract.ex`: existing bounded evaluator pattern for protecting documentation and claim contracts.
- Existing SHA-bound catalog manifests, renderer pin, and review payload contracts: reusable provenance vocabulary for normalized baseline items and raw artifact references.

### Established Patterns
- Human decisions and machine facts remain separate: qualitative review owns dispositions, while schemas, hashes, and tests prove identity and structural claims.
- Deterministic, proof, advisory, and human-required evidence lanes remain explicitly separated; no lane may overclaim another lane's authority.
- Core and package purity are protected through dev/test-only tooling, explicit package allowlists, optional dependencies, and contract tests.
- Current manifests use fail-loud validation and exact identity checks; new normalized snapshots should follow that discipline without making the ledger itself machine-first.

### Integration Points
- `.planning/QUALITY.md` becomes the current maintainer control-plane ledger and must survive future milestone archiving.
- Phase 133 will replace active Phase 131 planning-file consumers with durable versioned evidence; Phase 132 findings must identify every affected consumer and verification route.
- Phase 134 consumes accepted architecture/readability findings and their characterization/compatibility requirements.
- Phase 135 consumes test/CI findings and must preserve exact-SHA, renderer, permission, cache, and artifact authority.
- Phase 136 consumes only the six named catalog findings and their human-review boundaries.
- Phase 137 reconciles the final evidence snapshot, closes or rejects remaining high findings, audits deferral triggers, and populates the before/after section.

</code_context>

<specifics>
## Specific Ideas

- The ledger should read like a senior maintainer's decision surface, not a generated dashboard: concise facts, stable references, explicit limits, and the next required proof.
- Example rejected signal: a large writer/recipe module or runtime xref cycle is not a repair target until evidence demonstrates responsibility collision, change fan-out, duplication, or testability cost.
- Example high finding: active product/release/test consumption of archived Phase 131 evidence is `evidence_authority` risk owned by Phase 133.
- Example high finding: historical phase-number catalog routes remain open until Phase 135 proves generic exact-SHA authority and output parity.
- Example unavailable evidence: local PDFium absence stays an explicit advisory unavailability with a rerun trigger and cannot be promoted to proof.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 132-quality-baseline-triage*
*Context gathered: 2026-08-26*
