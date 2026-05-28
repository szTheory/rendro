# Phase 68: Viewer Evidence Schema, Mix Task, and Docs-Contract Lane - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 68 — Viewer Evidence Schema, Mix Task, and Docs-Contract Lane
**Areas discussed:** Deferral row shape, Frontmatter contract, Enforcement thresholds, Mix task UX
**Mode:** User requested all areas with subagent research (--all equivalent)

---

## Deferral row shape

| Option | Description | Selected |
|--------|-------------|----------|
| A: `status: "explicit_deferral"` + `evidence_deferred` | Third enum value; `missing` = bare `unverified` only | ✓ |
| B: `status: "unverified"` + `evidence_deferred` | Keeps regex tests green; overloads `unverified` | |

**User's choice:** A (via research synthesis — user asked for coherent recommendations)
**Notes:** ROADMAP/MATRIX-01 and Can I Use / OpenAPI “explicit negative” lessons favor A. ARCHITECTURE Pattern 1 example is stale.

---

## Evidence file frontmatter contract

| Option | Description | Selected |
|--------|-------------|----------|
| Flat `checks: {id: pass}` map | ARCHITECTURE example shape | |
| `behaviors[]` with `{behavior, result, note}` | JUnit-like; required notes; matrix `proof[]` alignment | ✓ |
| Handwritten Elixir validator only | No published schema | |
| JSV + Elixir cross-rules | Schema as contract + path/orphan/body lint | ✓ |

**User's choice:** `behaviors[]` array + JSV hybrid (D-06–D-12)
**Notes:** Reject `date_checked`, in-file `status`, `viewer_kind` in frontmatter.

---

## Enforcement thresholds

| Parameter | Alternatives considered | Locked |
|-----------|-------------------------|--------|
| Byte budget | 32 / 64 / 128 KiB | 65536 |
| Staleness Phase 68 | none / warn / block CI | warn, exit 0 |
| Staleness Phase 72 | — | block (--strict or audit) |
| Deferral scan scope | whole matrix / evidence bodies / reason field only | `evidence_deferred` only |

**User's choice:** Locked values in D-14–D-17

---

## Mix task UX

| Option | Description | Selected |
|--------|-------------|----------|
| Three separate Mix tasks | `viewer_evidence.list`, etc. | |
| One task, three subcommands | `mix rendro.viewer_evidence {list\|validate\|missing}` | ✓ |
| `missing` includes supported-without-evidence | Duplicates validate | |
| `missing` = `unverified` only | ROADMAP three-state model | ✓ |
| `missing` exit 1 when gaps | npm audit / cargo deny pattern | ✓ |
| `list` exit 1 when gaps | Rejected — informational only | |

**User's choice:** D-19–D-24

---

## Claude's Discretion

- Lint module path, table formatting, `recorded_at` equality rule, JSV schema internals.

## Deferred Ideas

- Operator guide, first cell, init scaffold, Pdfium/PdfJs adapters, staleness blocking — see CONTEXT.md `<deferred>`.
