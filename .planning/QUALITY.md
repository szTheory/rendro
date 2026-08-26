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
- **Owner phase:** 133
- **Scope:** replace active archive reads with durable repository-owned evidence without changing product behavior, public API, or rendered bytes.
- **Verification:** focused archive-consumer scan returns no product, release, or regression consumer; run the relevant deterministic and proof gates.
- **Status:** accepted
- **Trigger:** work is mandatory before Phase 137; new archive consumption reopens the finding.
- **Closure:** only the predeclared focused scan, compatibility review, and relevant gate evidence can close it.
- **Relationships/history:** observed and triaged on 2026-08-26; no duplicate finding because scripts, workflow, and tests share one evidence-authority boundary.

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
- **Owner phase:** 136
- **Scope:** only Corporate Classic Invoice dark, Minimal Mono Statement dark, Swiss Payslip light/dark, and Brutalist Ticket light/dark; all other cells and public API remain frozen.
- **Verification:** exact-SHA pinned-renderer artifact plus full-size human review for each repaired cell, with deterministic byte/contract coverage where applicable.
- **Status:** accepted
- **Trigger:** repair only these six cells; a request to alter another cell requires new evidence and a new related finding.
- **Closure:** exact named-cell before/after evidence and human review are required; an improved rubric aggregate cannot close it.
- **Relationships/history:** observed and triaged on 2026-08-26; catalog scope is separate from workflow authority in QL-003.

## Explicit rejected and deferred non-action signals

Each record below is a classification surface, not a finding. It prevents a collected signal from silently disappearing and does not authorize standalone churn.

### NS-001 — Dependency identity is recorded for reproduction, not a defect

- **Evidence:** `EV-DEP-001`
- **Signal:** `SIG-DEP-001`
- **Disposition:** reject_signal
- **Rationale:** the locked dependency and toolchain identities are provenance facts; no incompatibility or supply-chain harm was demonstrated.
- **Trigger:** create a related finding only on a failed reproducibility, security, or compatibility check.

### NS-002 — Coverage and slow-test result is a diagnostic signal, not a quota

- **Evidence:** `EV-TEST-001`
- **Signal:** `SIG-TEST-001`
- **Disposition:** reject_signal
- **Rationale:** the existing coverage threshold failure and slow-test report do not identify a supported-contract break or bounded repair owner.
- **Trigger:** reopen when a specific untested supported behavior, flaky failure, or measured latency regression is evidenced.

### NS-003 — Initial fast-gate formatting failure was capture-local and corrected before sealing

- **Evidence:** `EV-CI-002`
- **Signal:** `SIG-CI-003`
- **Disposition:** reject_signal
- **Rationale:** the failure named only the new focused contract's formatting while it was under construction; it is not a repository behavior or CI-authority defect.
- **Trigger:** reopen if a clean committed fast gate fails after the focused contract passes formatting.

### NS-004 — Documentation and public-contract checks are positive baseline evidence

- **Evidence:** `EV-DOC-001`
- **Signal:** `SIG-DOC-001`
- **Disposition:** reject_signal
- **Rationale:** passing contracts establish a baseline and do not by themselves justify documentation churn.
- **Trigger:** create a related finding when a specific public claim, manifest, or workflow contract fails.

### NS-005 — Package construction is positive baseline evidence

- **Evidence:** `EV-PKG-001`
- **Signal:** `SIG-PKG-001`
- **Disposition:** reject_signal
- **Rationale:** a successful Hex build does not demonstrate a packaging defect.
- **Trigger:** reopen on a package-content, metadata, or release-preflight failure tied to an exact source identity.

### NS-006 — Local proof-lane PDFium absence is deferred evidence, not a failed product claim

- **Evidence:** `EV-REL-001`
- **Signal:** `SIG-REL-001`
- **Disposition:** defer
- **Owner phase:** 137
- **Rationale:** local proof tests passed, but skipped PDFium viewer evidence cannot be promoted without the pinned executable or exact CI artifact.
- **Trigger:** attach an exact-SHA primary-CI PDFium artifact or rerun on a host with the pinned executable.
- **Evidence refresh:** rerun `mix ci.proofs` in the authoritative environment before final reconciliation.

### NS-007 — Local advisory PDFium raster output is unavailable

- **Evidence:** `EV-ADV-001`
- **Signal:** `SIG-CATALOG-002`
- **Disposition:** defer
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

None recorded as resolved, superseded, accepted-risk, or reopened. QL-001 and NS-001 through NS-005 are explicit rejected signals; NS-006 and NS-007 are explicit trigger-backed deferred evidence. `None recorded` means a category has no rows, not that risk is absent.

## Baseline versus final

Phase 137 adds a separate final snapshot and a before/after comparison. It must not overwrite `baseline-132-initial`.

## Maintainer guide

Start with the baseline, follow the evidence item, then read the finding or explicit non-action disposition and owner. A repair needs focused verification, the relevant full gate, compatibility evidence, before/after statement, and resolution reference. A deferral needs an owner, concrete trigger, and evidence-refresh rule.
