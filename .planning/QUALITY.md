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

## Baseline versus final

Phase 137 adds a separate final snapshot and a before/after comparison. It must not overwrite `baseline-132-initial`.

## Maintainer guide

Start with the baseline, follow the evidence item, then read the finding's disposition and owner phase. A repair needs a focused verification, relevant full gate, compatibility evidence, before/after statement, and resolution reference. A deferral needs an owner, concrete trigger, and evidence-refresh rule.
