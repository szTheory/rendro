# Rendro Quality Ledger

This is the current, human-first quality decision ledger. It is a maintainer document, not product, package, release, or ordinary regression-test state. Machine-verifiable evidence lives in the versioned companion snapshot; raw logs, PDFs, PNGs, reports, and caches remain outside Git.

## Compatibility contract

The public API and all unrelated rendered bytes are frozen compatibility contracts. Only the six catalog cells named in the v2.14 roadmap may change visually. A label, diagnostic movement, or unrelated green test is never closure evidence.

## Baseline registry

| Baseline | Snapshot or command | Authority and limit |
| --- | --- | --- |
| Initial normalized snapshot | `.planning/quality/baselines/132-initial.json` | Schema-valid, redacted local evidence; it does not claim primary-CI authority. |
| Deterministic gate | `mix ci.fast` | Primary CI is authoritative for CI-only results. |
| Proof lane | `mix ci.proofs` | Proof evidence remains distinct from deterministic evidence. |
| Advisory lane | `mix ci.advisory` | Unavailable advisory evidence stays unavailable with a rerun trigger. |
| Architecture diagnostics | `mix xref graph --format stats --label compile-connected`; `mix xref graph --format cycles --label compile-connected` | Diagnostic evidence is not repair authority. |
| Test diagnostics | coverage and slow-test diagnostics | Signals require qualitative triage. |
| Package contract | `mix hex.build` | Verifies package construction only. |
| Public contracts | public API and catalog contracts | Existing contract tests remain their own authority. |

## Evidence and finding rules

An **evidence item** records what ran, in which lane, with its authority and limit. A **finding** records the maintainer judgment: why it matters, its disposition, owner phase, verification, trigger, and closure. Finding IDs are permanent opaque `QL-NNN` values; never renumber or reuse them.

The snapshot is immutable after capture: validation is read-only and capture/edit work is serialized. A competing or interrupted writer must fail before commit. Evidence IDs (`EV-*`) and signal IDs (`SIG-*`) are permanent within a snapshot; duplicates are rejected. Raw logs, PDFs, PNGs, reports, and caches are never committed as snapshot payloads.

## Active findings

### Medium

None recorded.

### Low / signal

#### QL-001 — Compile-connected xref topology is a baseline signal, not a repair mandate

- **Opened:** 2026-08-26
- **Evidence:** `EV-ARCH-001` in `.planning/quality/baselines/132-initial.json`
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
- **Relationships/history:** observed and triaged on 2026-08-26; no related or superseded finding.

## Current historical and deferred findings

No resolved, deferred, reopened, superseded, or accepted-risk findings are recorded yet. `None recorded` means this category has no rows; it does not claim risk is absent.

## Finding lifecycle and relationships

`observed -> triaged -> accepted -> in_progress -> verified -> closed`

From `triaged`, a finding may instead be `rejected`, `deferred`, `accepted_risk`, or `superseded`. Reopen the same ID only when new evidence invalidates its prior disposition. A distinct regression or recurrence receives a new related ID. Keep meaningful state changes, related/reopened/superseded links, and the resolution reference in the finding; Git remains the line-level history.

Deduplicate only when the underlying cause **and** compatibility or ownership boundary are the same. Tool name, adjacency, or similar symptoms alone do not merge findings. At equal priority, display findings in ascending `QL-NNN` order.

## Qualitative rubric and dispositions

There is no composite quality score. Each finding independently states:

| Field | Allowed vocabulary |
| --- | --- |
| Impact and confidence | `low`, `medium`, `high` |
| Compatibility risk | `none`, `bounded_internal`, `public_api`, `rendered_bytes`, `evidence_authority` |
| Evidence quality | `signal`, `reproducible`, `contract_backed`, `independently_reviewed` |
| Disposition | `repair`, `defer`, `reject_signal`, `accept_risk`, and `superseded` |

High priority is a credible threat to a supported contract, rendered-byte guarantee, security boundary, release/package correctness, CI authority, or truthful evidence. Medium priority is demonstrated bounded maintenance, test, documentation, or workflow cost without a current public-contract break. Low priority or a signal is an observation without demonstrated harm; it cannot authorize standalone churn.

## Routing and closure

Phase 132 classifies. Phase 133 owns repository/evidence hygiene; Phase 134 architecture/readability; Phase 135 tests and CI authority; Phase 136 the six catalog cells; and Phase 137 final evidence reconciliation.

High findings must be repaired or rejected with evidence before Phase 137. Medium findings need a bounded repair or concrete trigger-backed deferral. Low/style signals may be addressed only inside an already-justified change.

- A **repair** needs an owner phase, scope boundary, focused verification, relevant full gate, before/after statement, and resolution reference.
- A **defer** needs an owner, concrete event trigger, and evidence-refresh rule.
- A **reject_signal** records why evidence is insufficient and the reopening condition.
- An **accept_risk** needs compensating evidence or control, an owner, and an expiry or review event.
- A **superseded** finding links the replacement finding and preserves its history.

Closure uses the predeclared focused proof and compatibility evidence. Labels, severity changes, improved diagnostic counts, or unrelated green tests do not close a finding.

## Resolved, rejected, deferred, and superseded findings

`QL-001` is the currently rejected signal. No resolved, deferred, accepted-risk, reopened, or superseded rows are recorded. This empty state is explicit and non-vacuous: it says no rows exist, not that risks or future findings are absent.

## Baseline versus final

Phase 137 adds a separate final snapshot and a before/after comparison. It must not overwrite `baseline-132-initial`.

## Maintainer guide

Start with the baseline, follow the evidence item, then read the finding's disposition and owner phase. A repair needs a focused verification, relevant full gate, compatibility evidence, before/after statement, and resolution reference. A deferral needs an owner, concrete trigger, and evidence-refresh rule.
