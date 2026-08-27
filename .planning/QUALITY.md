# Rendro Quality Ledger

This is the current, human-first quality decision ledger. It is maintainer state, not product, package, release, or ordinary regression-test state. Normalized evidence is committed in the versioned companion snapshot; raw logs, PDFs, PNGs, reports, and caches remain outside Git.

## Compatibility contract

The public API and all unrelated rendered bytes are frozen compatibility contracts. Only these Phase 136 catalog cells may change visually: Corporate Classic Invoice dark, Minimal Mono Statement dark, Swiss Payslip light/dark, and Brutalist Ticket light/dark. A diagnostic movement, label, or unrelated green test is never closure evidence.

## Baseline registry

| Baseline | Snapshot or command | Authority and limit |
| --- | --- | --- |
| Initial normalized snapshot | `.planning/quality/baselines/132-initial.json` (SHA-256 `f7a187ae4687cf0823e43786a0d58b8c571d94aded9fb79e540a998bd7b239be`) | Schema-valid, redacted local capture bound to source SHA `dcd7db62949f4089bded7878192ae1dafb0a4f46`; later captures use a new dated snapshot. |
| Deterministic gate | `mix ci.fast` | Local reproduction is useful evidence; primary CI remains authoritative for CI-only results. |
| Proof lane | `mix ci.proofs` | Separate proof evidence; local PDFium absence is explicitly unavailable. |
| Advisory lane | `mix ci.advisory` | Non-authoritative; unavailable raster output stays unavailable with a rerun trigger. |
| Architecture diagnostics | `mix xref graph --format stats --label compile-connected`; `mix xref graph --format cycles --label compile-connected` | Diagnostic evidence is not repair authority. |
| Test diagnostics | `mix test --cover --slowest 10` | Signals require qualitative triage, never a metric quota. |
| Package contract | `mix hex.build` | Verifies package construction only. |
| Documentation and catalog contracts | public API, rubric, workflow, and human sign-off contracts | Existing contracts remain their own authority. |

## Evidence and finding rules

An **evidence item** records what ran, its lane, authority, and limit. A **finding** records maintainer judgment: why it matters, disposition, owner, verification, trigger, and closure. Finding IDs are permanent opaque `QL-NNN` values; never renumber or reuse them. Evidence IDs (`EV-*`) and signal IDs (`SIG-*`) are permanent within a snapshot; duplicate IDs are rejected.

The initial snapshot is immutable after capture. Validation is read-only and capture/edit work is serialized; a materially new observation receives a fresh dated snapshot rather than an overwrite. Raw logs, PDFs, PNGs, reports, and caches are never committed as snapshot payloads.

## Active findings

### Findings in permanent ID order

#### QL-001 — Compile-connected xref topology is a baseline signal, not a repair mandate

- **Opened:** 2026-08-26
- **Evidence:** `EV-ARCH-001`, `EV-ARCH-002` in `.planning/quality/baselines/132-initial.json`
- **Signal:** `SIG-ARCH-001`
- **Signal:** `SIG-ARCH-002`
- **Impact:** low
- **Confidence:** high
- **Compatibility risk:** bounded_internal
- **Evidence quality:** reproducible
- **Priority:** low — five compile-connected edges and zero cycles do not demonstrate a supported-contract or maintenance harm.
- **Disposition:** reject_signal
- **Decision basis:** diagnostic_signal_only
- **Owner phase:** 132 (classification)
- **Scope:** baseline architecture topology only; no extraction or cleanup is authorized.
- **Verification:** rerun the registered xref statistics and cycles commands against the recorded source boundary.
- **Status:** rejected
- **Trigger:** reopen only if a concrete ownership collision, compatibility break, or measured maintenance cost is demonstrated.
- **Closure:** rejected because topology alone is insufficient evidence for repair; no unrelated green check or count change can alter that decision.
- **Relationships/history:** observed and triaged on 2026-08-26; the two tools corroborate one cause-plus-boundary judgment.

#### QL-002 — Archived Phase 131 planning evidence is consumed by active release and proof paths

- **Opened:** 2026-08-26
- **Evidence:** `EV-CI-001` in `.planning/quality/baselines/132-initial.json`
- **Signal:** `SIG-CI-001`
- **Impact:** high
- **Confidence:** high
- **Compatibility risk:** evidence_authority
- **Evidence quality:** reproducible
- **Priority:** high — active consumers make archived planning artifacts operational evidence, risking stale or non-durable authority.
- **Disposition:** repair
- **Decision basis:** supported_contract_risk
- **Owner phase:** 133
- **Scope:** replace active archive reads with durable repository-owned evidence without changing product behavior, public API, or rendered bytes.
- **Verification:** focused archive-consumer scan returns no product, release, or regression consumer; run the relevant deterministic and proof gates.
- **Status:** closed
- **Trigger:** work is mandatory before Phase 137; new archive consumption reopens the finding.
- **Closure:** closed 2026-08-26 after the predeclared terminal evidence contract passed. Resolution references: atomic consumer cutover `dda731e`; capsule/archive preservation plans 133-06 and 133-07; helper ownership `80fa85e`; hygiene policy `71b5743`; package/CI wiring `ef98618` and `13ca6df`; and the post-Wave-7 regression correction `44b99fb` were all present before terminal execution. The focused operational scan (`git grep -n -E '\\.planning/(phases|milestones)/' -- lib dev scripts .github`) found only the two exact owned structural `gsd_tooling` surfaces: `dev/rendro/repository_hygiene.ex` policy checks and `scripts/quality_governance.cjs` fixture assertions; it found no product, release, or ordinary-regression archive consumer. `mix quality.hygiene` passed with exact package member contract SHA-256 `41db3c276bdf1858925c443673560a42f20cfb46e6d58af99c6135d4c3b691b9`; the capsule manifest SHA-256 was `3f32c5c3f63837fa47a08e374dbb843c17b3f3343db9f411731d0c7298b5d8c2`. The focused capsule/consumer/hygiene suite passed (90 tests, 0 failures), and `mix ci.fast` passed. Compatibility review against the source-bound initial SHA `dcd7db62949f4089bded7878192ae1dafb0a4f46` proved `priv/public_api.json` remains byte-identical (SHA-256 `963e5caa5fea2b3e7b40d31a3d4c13d66fcf8896ff562c4a195327ba57a727af`), with zero `lib/`, `assets/rendro`, and `priv/examples` changes; the existing required-checks catalog-route contract remained green, so Phase 135 topology was not altered. Before: active release/newcomer paths could consume archived Phase 131 planning facts. After: active consumers read the validated v1.3.4 capsule while archived planning is provenance only. Separate proof result: `mix ci.proofs` passed (7 tests, 0 failures); its unavailable `pdfium-cli` viewer observations remain explicitly deferred under NS-006 with the existing exact-SHA CI/pinned-executable rerun trigger, not promoted to deterministic success.
- **Relationships/history:** observed and triaged on 2026-08-26; repaired and closed on 2026-08-26 through the source-bound cutover and terminal evidence above. No duplicate finding because scripts, workflow, and tests shared one evidence-authority boundary; new operational archive consumption reopens this same ID.

### Medium

#### QL-003 — Milestone-numbered catalog workflow routes need generic authority/parity replacement

- **Opened:** 2026-08-26
- **Evidence:** `EV-CI-002` in `.planning/quality/baselines/132-initial.json`
- **Signal:** `SIG-CI-002`
- **Impact:** medium
- **Confidence:** high
- **Compatibility risk:** evidence_authority
- **Evidence quality:** reproducible
- **Priority:** medium — the numbered routes are bounded workflow maintenance debt, but parity and authority must be preserved before removal.
- **Disposition:** repair
- **Decision basis:** bounded_maintenance_cost
- **Owner phase:** 135
- **Scope:** converge on one generic read-only exact-SHA catalog evidence workflow; do not alter catalog content or claim renderer authority locally.
- **Verification:** prove generic workflow parity against retained Phase 126, 127, and 130 outputs and authority checks before deleting any route.
- **Status:** accepted
- **Trigger:** complete before the old routes disappear; a failed parity comparison blocks closure.
- **Closure:** record focused parity evidence, relevant CI proof, and before/after route inventory; count reduction alone is insufficient.
- **Relationships/history:** observed and triaged on 2026-08-26; distinct from QL-002 because remediation and owner boundary are catalog CI rather than archive consumption.

#### QL-004 — Six evidence-backed catalog cells are bounded visual repair work

- **Opened:** 2026-08-26
- **Evidence:** `EV-CATALOG-001` in `.planning/quality/baselines/132-initial.json`
- **Signal:** `SIG-CATALOG-001`
- **Impact:** medium
- **Confidence:** high
- **Compatibility risk:** rendered_bytes
- **Evidence quality:** independently_reviewed
- **Priority:** medium — exactly six named catalog cells are `needs_work`; their bounded review supports repair but not a wider catalog rewrite.
- **Disposition:** repair
- **Decision basis:** supported_contract_risk
- **Owner phase:** 136
- **Scope:** only Corporate Classic Invoice dark, Minimal Mono Statement dark, Swiss Payslip light/dark, and Brutalist Ticket light/dark; all other cells and public API remain frozen.
- **Verification:** exact-SHA pinned-renderer artifact plus full-size human review for each repaired cell, with deterministic byte/contract coverage where applicable.
- **Status:** accepted
- **Trigger:** repair only these six cells; a request to alter another cell requires new evidence and a new related finding.
- **Closure:** exact named-cell before/after evidence and human review are required; an improved rubric aggregate cannot close it.
- **Relationships/history:** observed and triaged on 2026-08-26; catalog scope is separate from workflow authority in QL-003.

#### QL-005 — Uncalled I18n Analyzer is a bounded dead-code repair candidate

- **Opened:** 2026-08-26
- **Evidence:** `EV-ARCH-001`, `EV-ARCH-002` in `.planning/quality/baselines/132-initial.json`; current 2026-08-26 source/reference scan; `mix xref callers Rendro.I18n.Analyzer` (no callers); focused shaper, error, public-manifest, and documentation-contract tests (56 tests, 0 failures).
- **Signal:** current zero-caller analyzer ownership scan
- **Impact:** medium
- **Confidence:** high
- **Compatibility risk:** bounded_internal
- **Evidence quality:** reproducible
- **Priority:** medium — the authoritative shaping gate superseded this private module in Phase 83, and its isolated implementation/test pair has no current production, public, or compiled caller.
- **Disposition:** repair
- **Decision basis:** bounded_maintenance_cost
- **Owner phase:** 134
- **Scope:** remove only `lib/rendro/i18n/analyzer.ex` and its isolated test after the predeclared zero-reference, focused-shaping/error, public-manifest, and deterministic-byte compatibility checks; do not change the active shaping path.
- **Verification:** `rg -n 'Rendro\\.I18n\\.Analyzer|I18n\\.Analyzer' lib test guides README.md priv/public_api.json`, `mix xref callers Rendro.I18n.Analyzer`, focused shaper/error/public-contract tests, all recipe byte-identity tests, and the public manifest byte comparison.
- **Status:** closed
- **Trigger:** begin repair only while the no-caller proof remains true; any public, dynamic, or compiled caller reopens triage on this same ID.
- **Closure:** verified then closed 2026-08-26 after atomic removal commit `196981a`. Exact zero-reference proof found no `Rendro.I18n.Analyzer`/`I18n.Analyzer` source, guide, README, manifest, or test reference; `mix xref callers Rendro.I18n.Analyzer` returned no callers. The active-shaper/error/i18n/measure plus every deterministic recipe byte-identity test passed (90 tests, 0 failures); public-manifest and documentation-contract tests plus the byte suite passed (32 tests, 0 failures). `priv/public_api.json` remained unedited and byte-identical to the fresh generated manifest (SHA-256 `963e5caa5fea2b3e7b40d31a3d4c13d66fcf8896ff562c4a195327ba57a727af`). Before: dormant private Analyzer implementation/test pair remained beside the authoritative `Rendro.Text.Shaper.Simple` gate. After: both sole-owner files are absent; active shaper behavior, public API, and deterministic rendered bytes remain unchanged.
- **Relationships/history:** Phase 83 recorded the analyzer as dormant after `Rendro.Text.Shaper.Simple` became the authoritative gate; this is distinct from QL-001 because it is a concrete unused ownership boundary rather than a graph count. Plan 134-02 re-ran the source, guide, task, dynamic, package, manifest, and `mix xref callers Rendro.I18n.Analyzer` checks before removal; all returned no Analyzer consumer. The same permanent ID advanced through `in_progress` and `verified` to this closed state; reopening requires a new public, dynamic, or compiled Analyzer consumer.

#### QL-006 — Recipe palette resolution has one cohesive, characterization-gated drift surface

- **Opened:** 2026-08-26
- **Evidence:** `EV-ARCH-001`, `EV-ARCH-002` in `.planning/quality/baselines/132-initial.json`; current source-body scan shows five byte-identical `palette/1` bodies and two algorithmically identical variants with only legacy defaults changed; Phase 120 review WR-02; current public-manifest/documentation-contract tests (56 tests, 0 failures).
- **Signal:** current seven-site palette-resolution body comparison
- **Impact:** medium
- **Confidence:** high
- **Compatibility risk:** rendered_bytes
- **Evidence quality:** contract_backed
- **Priority:** medium — seven copied resolution sites share theme/nil/override semantics, so a future change can drift across recipes; a helper is authorized only if Wave 0 proves every legacy default shape and the existing failure boundary.
- **Disposition:** repair
- **Decision basis:** bounded_maintenance_cost
- **Owner phase:** 134
- **Scope:** add one private `Rendro.Recipes.Palette.resolve/2` helper and replace only the seven recipe resolution bodies, preserving each exact legacy default map, `Rendro.Theme.resolve(theme).colors`, `Map.merge/2` precedence, existing error shape, public manifest, and deterministic bytes.
- **Verification:** fail-first `test/rendro/recipes/palette_test.exs` covering all defaults/nil/theme/override/failure cases; then focused helper tests, all affected byte-identity and option-threading tests, themed smoke coverage, public-manifest/documentation contracts, and `mix ci.fast` before closure.
- **Status:** in_progress
- **Trigger:** Wave 0 must first prove one uniform contract for all seven maps; any recipe-specific behavior, changed byte golden, changed failure shape, or manifest movement reopens triage and suppresses the extraction.
- **Closure:** record the Wave 0 red contract, helper/migration commits, passing focused and compatibility results, and a before/after statement that no-theme bytes and public API remained identical.
- **Relationships/history:** Phase 120 WR-02 identified the same owner/semantics boundary; it is distinct from QL-005 because palette resolution is a shared recipe behavior rather than dead code. Plan 134-03 advanced this record to `in_progress` after the seven-source Wave 0 contract remained uniformly red only because its planned hidden owner did not yet exist; its focused helper tests prove exact nil/theme/override and failure semantics before any recipe call-site migration.

#### QL-007 — Shaping-hint fallback overlap is a signal, not a current repair

- **Opened:** 2026-08-26
- **Evidence:** `EV-ARCH-001`, `EV-ARCH-002` in `.planning/quality/baselines/132-initial.json`; current `lib/rendro/text/shaper/simple.ex`, `lib/rendro/error.ex`, and focused shaper/error tests (56 tests, 0 failures).
- **Signal:** current producer/fallback shaping-guidance comparison
- **Impact:** low
- **Confidence:** high
- **Compatibility risk:** bounded_internal
- **Evidence quality:** reproducible
- **Priority:** low — `Simple` is the only production producer and emits the contextual three-tuple, while `Rendro.Error` retains a tested two-tuple fallback; no inconsistent emitted guidance or responsibility collision was demonstrated.
- **Disposition:** reject_signal
- **Decision basis:** diagnostic_signal_only
- **Owner phase:** 134
- **Scope:** no code change; retain the producer-specific hint and the error fallback exactly as they are.
- **Verification:** rerun focused shaper/error tests and the producer scan for `{:shaping_required, script}` / `{:shaping_required, script, hint}` before reconsideration.
- **Status:** rejected
- **Trigger:** reopen only if a new two-tuple producer appears or a user-observable mismatch is demonstrated between emitted shaping reasons and actionable guidance.
- **Closure:** rejected because superficial fallback overlap does not establish harm, and factoring it could discard context-sensitive built-in-font guidance.
- **Relationships/history:** distinct from QL-005 because the active shaper is a live behavior contract, not dormant code.

#### QL-008 — Runtime phase/date narration has no line-specific stale claim

- **Opened:** 2026-08-26
- **Evidence:** `EV-ARCH-001`, `EV-ARCH-002` in `.planning/quality/baselines/132-initial.json`; current 2026-08-26 runtime-source narration scan; Phase 134 context D-08 and D-16.
- **Signal:** current bounded phase/date narration scan
- **Impact:** low
- **Confidence:** high
- **Compatibility risk:** none
- **Evidence quality:** reproducible
- **Priority:** low — matches are current feature history, immutable provenance, or planning metadata; no individual runtime/doc/comment line was shown to contradict current behavior.
- **Disposition:** reject_signal
- **Decision basis:** diagnostic_signal_only
- **Owner phase:** 134
- **Scope:** no narration, specification, documentation, or comment edit is authorized by this record.
- **Verification:** repeat the bounded phase/date scan and identify a concrete misleading line plus contradictory current behavior before any edit.
- **Status:** rejected
- **Trigger:** reopen only with a line-specific stale implementation-history claim, a bounded correction, and focused truthfulness/contract proof that preserves provenance.
- **Closure:** rejected because search matches alone are not stale narration evidence; Phase 134 may close without a narration repair.
- **Relationships/history:** distinct from QL-001 topology and QL-007 shaping because provenance preservation is a separate truthfulness boundary. Plan 134-05 re-ran the bounded runtime phase/date scan on 2026-08-27 and reviewed one surrounding line for each match. `lib/rendro/viewer_evidence/recorder.ex:259,277,295,310,328` explicitly label original Phase 47/50/54 validation facts as provenance-only and accurately state the current CI limits; `lib/rendro/font_registry.ex:216,320` truthfully limit support to the Phase 25 built-in-font boundary; `lib/rendro/link.ex:7` accurately scopes the curated target variants; `lib/rendro/public_api.ex:3`, `lib/mix/tasks/rendro/api.gen.ex:32`, and `lib/mix/tasks/rendro/viewer_evidence.ex:68` identify current internal/public-contract or non-CI boundaries; and `lib/mix/tasks/rendro.visual_uat.ex:13-16` preserves its Phase 29 replacement provenance. Date literals in recipe examples and formatter doctests are example data rather than historical claims. No reviewed line contradicted current behavior, failure shape, stability boundary, or documented limitation; public/boundary module docs remain accurate and comments retain non-obvious intent. This record therefore remains `reject_signal` with no source, specification, documentation, or comment edit. Reopen only with the existing line-specific stale-claim trigger plus contradictory current behavior, a bounded correction, focused truthfulness/contract proof, and preserved operational provenance.

## Explicit rejected and deferred non-action signals

Each record below is a classification surface, not a finding. It prevents a collected signal from silently disappearing and does not authorize standalone churn.

### NS-001 — Dependency identity is recorded for reproduction, not a defect

- **Evidence:** `EV-DEP-001`
- **Signal:** `SIG-DEP-001`
- **Disposition:** reject_signal
- **Decision basis:** diagnostic_signal_only
- **Rationale:** the locked dependency and toolchain identities are provenance facts; no incompatibility or supply-chain harm was demonstrated.
- **Trigger:** create a related finding only on a failed reproducibility, security, or compatibility check.

### NS-002 — Coverage and slow-test result is a diagnostic signal, not a quota

- **Evidence:** `EV-TEST-001`
- **Signal:** `SIG-TEST-001`
- **Disposition:** reject_signal
- **Decision basis:** diagnostic_signal_only
- **Rationale:** the existing coverage threshold failure and slow-test report do not identify a supported-contract break or bounded repair owner.
- **Trigger:** reopen when a specific untested supported behavior, flaky failure, or measured latency regression is evidenced.

### NS-003 — Initial fast-gate formatting failure was capture-local and corrected before sealing

- **Evidence:** `EV-CI-002`
- **Signal:** `SIG-CI-003`
- **Disposition:** reject_signal
- **Decision basis:** diagnostic_signal_only
- **Rationale:** the failure named only the new focused contract's formatting while it was under construction; it is not a repository behavior or CI-authority defect.
- **Trigger:** reopen if a clean committed fast gate fails after the focused contract passes formatting.

### NS-004 — Documentation and public-contract checks are positive baseline evidence

- **Evidence:** `EV-DOC-001`
- **Signal:** `SIG-DOC-001`
- **Disposition:** reject_signal
- **Decision basis:** diagnostic_signal_only
- **Rationale:** passing contracts establish a baseline and do not by themselves justify documentation churn.
- **Trigger:** create a related finding when a specific public claim, manifest, or workflow contract fails.

### NS-005 — Package construction is positive baseline evidence

- **Evidence:** `EV-PKG-001`
- **Signal:** `SIG-PKG-001`
- **Disposition:** reject_signal
- **Decision basis:** diagnostic_signal_only
- **Rationale:** a successful Hex build does not demonstrate a packaging defect.
- **Trigger:** reopen on a package-content, metadata, or release-preflight failure tied to an exact source identity.

### NS-006 — Local proof-lane PDFium absence is deferred evidence, not a failed product claim

- **Evidence:** `EV-REL-001`
- **Signal:** `SIG-REL-001`
- **Disposition:** defer
- **Decision basis:** explicit_unavailability
- **Owner phase:** 137
- **Rationale:** local proof tests passed, but skipped PDFium viewer evidence cannot be promoted without the pinned executable or exact CI artifact.
- **Trigger:** attach an exact-SHA primary-CI PDFium artifact or rerun on a host with the pinned executable.
- **Evidence refresh:** rerun `mix ci.proofs` in the authoritative environment before final reconciliation.

### NS-007 — Local advisory PDFium raster output is unavailable

- **Evidence:** `EV-ADV-001`
- **Signal:** `SIG-CATALOG-002`
- **Disposition:** defer
- **Decision basis:** explicit_unavailability
- **Owner phase:** 136
- **Rationale:** this macOS host lacks `pdfium-cli`; local advisory output is unavailable and cannot substitute for primary-CI or human-review authority.
- **Trigger:** make the pinned PDFium executable available or attach the exact-SHA advisory artifact.
- **Evidence refresh:** rerun `mix ci.advisory` only in an environment able to execute the pinned renderer.

## Finding lifecycle and relationships

`observed -> triaged -> accepted -> in_progress -> verified -> closed`

From `triaged`, a finding may instead be `rejected`, `deferred`, `accepted_risk`, or `superseded`. Reopen the same ID only when new evidence invalidates its prior disposition. A distinct regression or recurrence receives a new related ID. Keep meaningful state changes, related/reopened/superseded links, and the resolution reference in the finding; Git remains the line-level history.

Deduplicate only when the underlying cause **and** compatibility or ownership boundary are the same. Tool name, adjacency, or similar symptoms alone do not merge findings. At equal priority, display findings in ascending `QL-NNN` order.

## Qualitative rubric and dispositions

There is no composite quality score. Each finding independently states impact, confidence, compatibility risk, evidence quality, qualitative priority, disposition, owner, scope, verification, status, trigger, closure, and history.

| Field | Allowed vocabulary |
| --- | --- |
| Impact and confidence | `low`, `medium`, `high` |
| Compatibility risk | `none`, `bounded_internal`, `public_api`, `rendered_bytes`, `evidence_authority` |
| Evidence quality | `signal`, `reproducible`, `contract_backed`, `independently_reviewed` |
| Disposition | `repair`, `defer`, `reject_signal`, `accept_risk`, and `superseded` |

High priority is a credible threat to a supported contract, rendered-byte guarantee, security boundary, release/package correctness, CI authority, or truthful evidence. Medium priority is demonstrated bounded maintenance, test, documentation, or workflow cost without a current public-contract break. Low priority or a signal is an observation without demonstrated harm; it cannot authorize standalone churn.

## Routing and closure

Phase 132 classifies. Phase 133 owns repository/evidence hygiene; Phase 134 architecture/readability; Phase 135 tests and CI authority; Phase 136 the six catalog cells; and Phase 137 final evidence reconciliation.

High findings must be repaired or rejected with evidence before Phase 137. Medium findings need a bounded repair or concrete trigger-backed deferral. Low/style signals may be addressed only inside an already-justified change. A repair needs an owner phase, scope boundary, focused verification, relevant full gate, before/after statement, and resolution reference. A deferral needs an owner, concrete event trigger, and evidence-refresh rule. A `reject_signal` records insufficient evidence and its reopening condition.

Closure uses the predeclared focused proof and compatibility evidence. Labels, severity changes, improved diagnostic counts, or unrelated green tests do not close a finding.

## Resolved, rejected, deferred, and superseded findings

QL-002 is resolved and closed on 2026-08-26 with its terminal evidence recorded in the finding. None recorded as superseded, accepted-risk, or reopened. QL-001 and NS-001 through NS-005 are explicit rejected signals; NS-006 and NS-007 are explicit trigger-backed deferred evidence. `None recorded` means a category has no rows, not that risk is absent.

## Baseline versus final

Phase 137 adds a separate final snapshot and a before/after comparison. It must not overwrite `baseline-132-initial`.

## Maintainer guide

Start with the baseline, follow the evidence item, then read the finding or explicit non-action disposition and owner. A repair needs focused verification, the relevant full gate, compatibility evidence, before/after statement, and resolution reference. A deferral needs an owner, concrete trigger, and evidence-refresh rule.
