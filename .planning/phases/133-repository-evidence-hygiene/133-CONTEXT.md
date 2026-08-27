# Phase 133: Repository & Evidence Hygiene - Context

**Gathered:** 2026-08-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Make current product, release, regression, package, and operational behavior depend only on durable current inputs while preserving historical planning as immutable archive material. This phase migrates the v1.3.4 release/newcomer evidence contract, repairs tracked archive and helper ownership, and establishes repository/package hygiene enforcement. It does not change public APIs or rendered bytes, consolidate catalog workflows owned by Phase 135, add product capabilities, or generalize future release policy beyond the bounded v1.3.4 migration.

</domain>

<decisions>
## Implementation Decisions

### Durable Evidence Structure
- **D-01:** Replace every active Phase 131 archive read with a repository-owned, version-scoped internal evidence capsule rooted at `evidence/releases/v1.3.4/`. The capsule is excluded from the Hex package and is not runtime application data.
- **D-02:** Make `manifest.json` the capsule's sole durable entry point. It indexes authority-separated records by stable opaque ID, repository-relative path, SHA-256, media type, evidence lane, authority, status, retention policy, and provenance; it does not become a flat copy of every payload fact.
- **D-03:** Separate record responsibilities: `public_prerequisite.json` is the only operational clean-room/release input; `release_identity.json` records sealed candidate/tag/release provenance; `validation.json` carries the durable successful journey identities now asserted from `131-VALIDATION.md`; `journey/index.json` orders attempts; individual structured attempt records and Markdown sidecars preserve evidence and explanation.
- **D-04:** Validate the manifest and authoritative JSON records with existing JSV/repository schema conventions, an explicit JSON Schema draft, `schema_version: 1`, strict record roles, bounded fields, path confinement, and digest verification. Add no Ecto, Phoenix, hosted service, runtime dependency, or parallel quality stack for repository evidence.
- **D-05:** Give scripts and tests one narrow shared loader/validator rather than duplicating hard-coded paths and decoding rules. It must reject traversal, malformed or unknown authority roles, unsupported schema versions, digest mismatch, and release/candidate/tag mismatch before returning operational facts.
- **D-06:** Migrate all active consumers atomically: the clean-room script default, release workflow, clean-room tests, public-release verifier tests, newcomer docs contract, required-checks guardrail, and any verifier candidate-record default or fixture. A focused scan must prove no product, release, workflow, or ordinary regression consumer retains a Phase 131 archive dependency.
- **D-07:** Keep `priv/adoption_evidence/2026-08-21.json` separately governed and package-visible because it supports the public adoption document. Do not add the internal release capsule, journey attempts, schemas, or planning records to that package exception.

### Historical Evidence Retention
- **D-08:** Treat migration as preservation, not re-assertion. Every imported record carries its original source path and digest, source commit where available, separate import time/reason, and sanitized/redaction classification; original observed facts remain distinguishable from migration metadata.
- **D-09:** Preserve all successful, failed, and pre-schema v1.3.4 attempts. Structured JSON is the contract record; Markdown remains a paired explanatory narrative and can never be the only source for a fact used by an active consumer.
- **D-10:** Historical payload bytes, IDs, and meanings are immutable after import. Corrections and changed interpretations append a new record with `supersedes`; they never overwrite or repurpose the original. Manifest/index evolution is append-only for historical entries.
- **D-11:** Keep evidence lanes truthful: schema, digest, path, absence, and package membership are deterministic checks; retained clean-room success is historical advisory evidence; workflow artifacts are expiring transport rather than durable authority; no deterministic test requires live GitHub/Hex access or a retry of an immutable failed attempt.
- **D-12:** Scope the current release advisory job explicitly to v1.3.4 while it consumes a v1.3.4-bound harness and capsule. Do not allow every future `v*.*.*` tag to reuse fixed 1.3.4 facts. A generic future-release evidence framework is deferred rather than smuggled into this migration.
- **D-13:** Do not claim that an embedded digest alone creates independent immutability. Git history, protected branches, and release-tag controls remain the repository authority; the capsule supplies bounded provenance and tamper evidence.

### Archive and Script Ownership
- **D-14:** Move loose tracked Phase 5 and Phase 45 artifacts into their historically correct milestone archives, deriving ownership from archived roadmaps and Git history. Use Git-recognizable moves, update inbound planning references, and leave no redirect stubs or duplicate authoritative copies.
- **D-15:** If an early phase has no provable milestone owner after the historical scan, place it in one explicitly labeled legacy archive with the uncertainty recorded; do not invent provenance or delete unique history merely to make the tree uniform.
- **D-16:** Make the active `.planning/phases/<NN>-<slug>/` shape the sole non-archived phase-artifact form. Completed historical phase material belongs under milestone archives; product and release behavior never consumes either location.
- **D-17:** Establish `scripts/README.md` as the complete tracked-helper inventory. Each retained executable records purpose, stable owner role, supported invocation, inputs/outputs, authority lane, current callers, and a review/removal trigger. Role ownership is preferred over a named individual.
- **D-18:** Retain a helper only when a current workflow, Mix alias/task, documented operator action, or focused test proves its purpose. Remove ownerless or superseded helpers after entry-point/reference checks; do not preserve scripts solely because they once supported a phase.
- **D-19:** Mark planning-aware checks as a narrow `gsd_tooling` class in names, inventory, and policy. These checks may inspect planning because planning structure is their subject; they are not product, release-fact, package, or ordinary-regression consumers.
- **D-20:** Replace the unreferenced broad `scripts/repo_hygiene_check.sh` contract with the single Mix-based hygiene gate unless planning discovers a current documented caller that requires a thin compatibility wrapper. Do not keep two competing canonical hygiene commands.

### Package and Repository Hygiene
- **D-21:** Provide one purpose-named deterministic maintainer command, `mix quality.hygiene`, and use that same contract locally, in `ci.fast`, and from the clean release checkout. CI records authoritative execution; local runs provide identical fast feedback.
- **D-22:** Inspect the actual built/unpacked Hex artifact, not only `mix.exs` intent. Compare normalized members with a versioned expected package manifest, report unexpected and missing members, and fail on `.planning`, `evidence`, internal schemas, tests, scripts, CI metadata, caches, editor debris, raw proof artifacts, or internal journey history.
- **D-23:** Model evidence/package eligibility explicitly: runtime/public documentation and intentionally public discovery/adoption assets may ship; durable internal evidence and ephemeral artifacts may not. Package exceptions are narrow, named, owner-bearing, and reviewable rather than broad directory allowlists.
- **D-24:** Validate tracked planning placement with NUL-safe `git ls-files` input. Permit only project-level planning files, the canonical active-phase shape, milestone archives, and explicit GSD-tooling artifacts; fail on loose or misplaced tracked phase material.
- **D-25:** Enforce archive-consumer prohibition across `lib/`, release/proof scripts, workflows, package configuration, and ordinary regression tests. Any GSD-tooling exception must identify its purpose and owner and remain outside product/evidence claims.
- **D-26:** Do not fail merely because unrelated untracked or ignored developer-local files exist. Fail when debris enters the built package, becomes tracked in a forbidden location, or influences an authoritative workflow.
- **D-27:** Make command UX deterministic and accessible: stable ordering; no color-only or emoji-only meaning; concise success output; and failures that state the path, violated rule, why it matters, and the exact next action. Keep backend evidence classifications out of package-consumer and Phoenix-newcomer surfaces.

### the agent's Discretion
- Choose exact internal module/test filenames, schema filenames, manifest formatting, and opaque record-ID spelling while preserving the locked capsule responsibilities, version boundary, authority separation, and stable IDs.
- Choose the narrowest implementation for the shared loader and Mix-based gate using existing dev/test compilation paths and dependencies. Do not widen the public API or runtime package surface.
- Derive the exact Phase 5/45 destination paths from repository history during research/planning and record any genuinely unprovable legacy mapping explicitly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Governance
- `.planning/ROADMAP.md` — Phase 133 goal, success criteria, sequencing, and boundary from Phase 135 catalog workflow work.
- `.planning/REQUIREMENTS.md` — HYGIENE-01 through HYGIENE-04 plus milestone compatibility and no-churn constraints.
- `.planning/PROJECT.md` — Current milestone outcomes, pure-core/package boundaries, documentation honesty, and unchanged public API/rendered-byte contract.
- `.planning/STATE.md` — Accumulated v2.14 decisions, immutable v1.3.0-v1.3.3 incident constraint, current concerns, and deferred capability gates.
- `.planning/QUALITY.md` — QL-002 evidence-authority finding, required scope, predeclared verification, and closure contract.
- `.planning/quality/baselines/132-initial.json` — Source-bound baseline evidence and the Phase 131 consumer signal behind QL-002.
- `.planning/phases/132-quality-baseline-triage/132-CONTEXT.md` — Locked evidence lanes, immutable baseline, disposition governance, and Phase 133 ownership.

### Current v2.14 Research
- `.planning/research/SUMMARY.md` — Research synthesis, Phase 133 ordering rationale, and exhaustive-manifest field warning.
- `.planning/research/ARCHITECTURE.md` — Planning-is-history pattern, release-evidence data flow, package boundary, and initial capsule architecture.
- `.planning/research/FEATURES.md` — Durable evidence and repository-hygiene maintainer outcomes and acceptance boundaries.
- `.planning/research/PITFALLS.md` — Executable-planning-history, authority-loss, stale-evidence, cleanup-churn, and weaker-contract footguns.
- `.planning/research/STACK.md` — Existing Elixir/Mix/JSV tooling decision and prohibition on speculative runtime/quality dependencies.

### Product, Engineering, and Voice DNA
- `prompts/rendro-oss-dna.md` — Canonical verification lanes, strict Hex file whitelists, release safety, archive lessons, and truthful evidence boundaries.
- `prompts/rendro-gsd-seed.md` — Core personas/JTBD, release posture, package checks, and pure-Elixir/Phoenix-first constraints.
- `prompts/rendro-integration-opportunities.md` — Consumer-first integration and audit/evidence JTBD without widening core coupling.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — Original maintainer/SRE personas, release ergonomics, pure-core goal, and scope footguns.
- `brand/README.md` — Current brand source hierarchy and the model of repository-owned material intentionally excluded from Hex; supersedes prompt-era operational brand guidance.
- `brand/copy/VOICE.md` — Current maintainer/SRE voice and the what/where/why/next failure-message contract for hygiene diagnostics.

### Historical Inputs to Preserve, Not Execute
- `.planning/milestones/v2.13-phases/131-adoption-snapshot-phoenix-newcomer-proof/131-PUBLIC-PREREQUISITE.json` — Current operational prerequisite facts to preserve in the durable capsule.
- `.planning/milestones/v2.13-phases/131-adoption-snapshot-phoenix-newcomer-proof/131-RELEASE-CANDIDATE.md` — Sealed v1.3.4 candidate and release identity to extract with source provenance.
- `.planning/milestones/v2.13-phases/131-adoption-snapshot-phoenix-newcomer-proof/131-VALIDATION.md` — Journey evidence identities currently asserted by an active test; becomes archival narrative after migration.
- `priv/journey_evidence/phoenix_clean_room_1.3.4.json` — Current structured successful newcomer proof to preserve.
- `priv/journey_evidence/phoenix_clean_room_1.3.4.md` — Current successful proof narrative and truth-boundary wording to preserve as a sidecar.
- `priv/adoption_evidence/2026-08-21.json` — Intentionally public/package-visible adoption evidence that must remain separate from internal release evidence.

### Active Consumers and Enforcement Surfaces
- `mix.exs` — Existing explicit Hex `:files` boundary, quality aliases, dev/test-only tooling paths, and package contents.
- `scripts/phoenix_clean_room_proof.exs` — Hard-coded v1.3.4 verifier and archive-bound default prerequisite to migrate.
- `scripts/verify_public_release.exs` — Release identity/prerequisite producer and validation semantics to preserve.
- `scripts/repo_hygiene_check.sh` — Existing broad worktree/CI wrapper to supersede or justify.
- `.github/workflows/release.yml` — Archive-bound advisory release invocation and tag-scope footgun.
- `test/docs_contract/phoenix_newcomer_contract_test.exs` — Newcomer route, journey fact, redaction, and archived validation assertions.
- `test/scripts/phoenix_clean_room_proof_test.exs` — Clean-room prerequisite and failure-contract coverage.
- `test/scripts/public_release_verifier_test.exs` — Sealed release-incident and prerequisite-emission coverage.
- `test/guardrails/required_checks_contract_test.exs` — Workflow lane/retention contract and archive-path assertion to migrate.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix.exs` package `:files` allowlist and `mix hex.build` in `ci.fast`: positive package boundary and natural integration point for actual-artifact inspection.
- Existing JSV schemas under `priv/schemas/` and schema-backed manifests such as `priv/public_api.json` and `priv/quality/rubric_scores.json`: established fail-loud structured-data pattern.
- `scripts/verify_public_release.exs` and `Rendro.PhoenixCleanRoomProof.validate_prerequisite/1`: bounded release/prerequisite field validation that must be preserved behind a durable source.
- Existing docs-contract and guardrail tests: established contract-test lanes for public newcomer claims, workflow shape, package exclusions, redaction, and evidence identity.
- Phase 132 `quality.governance` and source-bound scan patterns: reusable vocabulary for deterministic path/reference checks without making planning executable product state.

### Established Patterns
- Core stays pure; maintainer-only validation belongs in existing dev/test paths and dependencies.
- Machine facts and human narrative remain separate, while exact hashes and schemas bind them.
- Deterministic, proof, advisory, and human evidence lanes never borrow authority from one another.
- Explicit package allowlists and actual tarball assertions protect the consumer boundary; repository-owned internal evidence is excluded unless a public contract deliberately requires it.
- Errors and checks follow Rendro's concrete what/where/why/next voice rather than opaque pass/fail output.

### Integration Points
- All five active Phase 131 consumer files plus the archive-string guardrail must migrate in the same bounded change.
- The release workflow must point at the durable prerequisite and stop applying the fixed 1.3.4 advisory proof to unrelated future tags.
- `ci.fast` and release preflight consume the same `mix quality.hygiene` contract so local and CI checks cannot drift.
- Git-tracked placement and script inventory jointly close HYGIENE-03; actual Hex payload inspection closes HYGIENE-04.
- QL-002 closes only after the focused consumer scan, compatibility review, relevant deterministic/proof gates, and recorded before/after evidence pass.

</code_context>

<specifics>
## Specific Ideas

- The evidence capsule should feel like a sealed release dossier: one inspectable index, narrow authority-specific records, exact digests, and explanatory sidecars rather than a generated dashboard or mutable database.
- Failed v1.3.4 attempts are useful incident history and must remain visible, but they are not current preconditions and must never be retried or rewritten merely to make the record look cleaner.
- A package consumer receives runtime code, public docs, and deliberately public evidence only; they do not receive planning history, internal schemas, clean-room attempts, operational metadata, or maintainer scripts.
- Hygiene output should read like a senior maintainer: name the offending path and rule, state the boundary it would violate, and give the exact command or edit that resolves it.

</specifics>

<deferred>
## Deferred Ideas

- Generalizing the v1.3.4 advisory clean-room job and evidence capsule into a version-agnostic future-release framework — future release-policy work after this bounded migration proves the model.

</deferred>

---

*Phase: 133-repository-evidence-hygiene*
*Context gathered: 2026-08-26*
