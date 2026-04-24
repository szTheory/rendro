# Phase 1: Core Deterministic Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-24T10:49:04-0400
**Phase:** 01-core-deterministic-foundation
**Areas discussed:** Core Boundary, Deterministic Contract, Telemetry Schema, Structured Errors
**Mode:** auto (`--auto`)

---

## Core Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Pure core package only; adapters deferred | Preserve pure-core guarantees and avoid optional dependency leakage in Phase 1 | ✓ |
| Implement core + Phoenix adapter now | Accelerates adoption path but introduces coupling risk before core contracts stabilize | |
| Scaffold all adapters now | Front-loads ecosystem breadth at the cost of early architectural noise | |

**User's choice:** Auto-selected recommended default: Pure core package only; adapters deferred.
**Notes:** [auto] Core Boundary — Q: "How should core and integrations be scoped in Phase 1?" → Selected recommended default.

| Option | Description | Selected |
|--------|-------------|----------|
| Data-first pipeline entrypoint with explicit stage boundaries | Establishes clear, testable interface for downstream planning | ✓ |
| Separate APIs per stage without common contract | Risks fragmented semantics and duplicated behaviors | |
| Single render call with hidden internals | Simpler surface but weak observability and extensibility | |

**User's choice:** Auto-selected recommended default: Data-first pipeline entrypoint with explicit stage boundaries.
**Notes:** [auto] Core Boundary — Q: "What API shape should Phase 1 establish?" → Selected recommended default.

---

## Deterministic Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Stabilize ordering, object IDs, timestamps, and metadata fields under deterministic mode | Prevents fixture flapping and supports repeatable CI artifacts | ✓ |
| Only normalize timestamps | Leaves object graph drift unresolved | |
| Do not normalize; rely on fixture tolerance | Makes deterministic claims weak and brittle | |

**User's choice:** Auto-selected recommended default: Stabilize ordering, object IDs, timestamps, and metadata fields.
**Notes:** [auto] Deterministic Contract — Q: "What should deterministic mode normalize for repeatable artifacts?" → Selected recommended default.

| Option | Description | Selected |
|--------|-------------|----------|
| Provide explicit deterministic option for tests/CI | Keeps behavior intentional and auditable for maintainers | ✓ |
| Always deterministic by default with no opt-out | Can constrain future runtime behavior and diagnostics scenarios | |
| Hidden env-var toggle only | Hard to discover and document reliably | |

**User's choice:** Auto-selected recommended default: Explicit deterministic option for tests/CI.
**Notes:** [auto] Deterministic Contract — Q: "How should deterministic behavior be surfaced to users?" → Selected recommended default.

---

## Telemetry Schema

| Option | Description | Selected |
|--------|-------------|----------|
| Emit stage-specific start/stop/exception events for all pipeline stages | Enables lifecycle visibility and precise failure localization | ✓ |
| Emit one summary event only | Too coarse for diagnostics and performance analysis | |
| Emit ad-hoc log-style events without stable schema | Reduces long-term observability contract quality | |

**User's choice:** Auto-selected recommended default: Stage-specific start/stop/exception events.
**Notes:** [auto] Telemetry Schema — Q: "How should lifecycle telemetry events be structured?" → Selected recommended default.

| Option | Description | Selected |
|--------|-------------|----------|
| Include render_id, document type, deterministic flag, metrics, and status | Supports correlation, SLO tracking, and operational debugging | ✓ |
| Minimal metadata with stage name only | Insufficient for production diagnostics | |
| Full raw payload including document contents | Raises privacy/security risk and event bloat | |

**User's choice:** Auto-selected recommended default: Correlation + metrics metadata set.
**Notes:** [auto] Telemetry Schema — Q: "What metadata should telemetry include by default?" → Selected recommended default.

---

## Structured Errors

| Option | Description | Selected |
|--------|-------------|----------|
| Stable envelope with what/where/why/next fields | Produces actionable diagnostics and consistent downstream handling | ✓ |
| Return plain exception messages only | Low signal and inconsistent remediation guidance | |
| Expose internal stack traces as primary error output | Noisy and may leak internals | |

**User's choice:** Auto-selected recommended default: Stable envelope with what/where/why/next fields.
**Notes:** [auto] Structured Errors — Q: "What shape should structured render errors follow?" → Selected recommended default.

| Option | Description | Selected |
|--------|-------------|----------|
| Attach render_id and stage for telemetry correlation | Speeds root-cause analysis by linking errors to event timelines | ✓ |
| No correlation metadata | Forces manual forensic matching | |
| Correlation only in debug mode | Reduces operator value in normal production incidents | |

**User's choice:** Auto-selected recommended default: Always include render_id + stage.
**Notes:** [auto] Structured Errors — Q: "How should errors relate to telemetry and troubleshooting?" → Selected recommended default.

---

## Claude's Discretion

- Module names and folder layout for core pipeline implementation.
- Final event naming conventions within the selected schema.
- Error helper API ergonomics.

## Deferred Ideas

None.
