# Phase 26: Deterministic Font Metrics and PDF Embedding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 26-deterministic-font-metrics-and-pdf-embedding
**Areas discussed:** font source contract, registration shape, failure policy, support boundary, determinism proof target, downstream recommendation posture

---

## Font source contract

| Option | Description | Selected |
|--------|-------------|----------|
| Path only | Register custom fonts from filesystem paths only | |
| Binary only | Register custom fonts from caller-provided bytes only | |
| One mixed API | One API accepts both built-ins and embedded sources | |
| Distinct built-in vs embedded APIs | Keep semantics separate; embedded API accepts tagged path or bytes | ✓ |

**User's choice:** Discuss all options, research via subagents, then pick one coherent recommendation set.
**Notes:** Recommended outcome is to keep built-ins and embedded fonts as separate concepts. Embedded fonts should accept `{:path, path}` and `{:binary, bytes}` and eagerly normalize to owned pure data. Avoid system-font lookup or ambient environment resolution.

---

## Registration shape

| Option | Description | Selected |
|--------|-------------|----------|
| Extend `register_font/3` for everything | One overloaded registration surface for built-ins and embedded fonts | |
| Add explicit embedded registration | Preserve `register_font/3` for built-ins and add a dedicated embedded-font path | ✓ |
| Infer by input shape | Guess semantics from strings, binaries, or tuples | |

**User's choice:** One-shot cohesive recommendation rather than open-ended alternatives.
**Notes:** Recommended outcome is an explicit embedded-font registration path plus existing built-in registration. Keep logical font naming public and PDF object/resource details private.

---

## Failure policy

| Option | Description | Selected |
|--------|-------------|----------|
| Late failure | Detect unreadable/unembeddable custom fonts only in measure/render | |
| Early preflight | Validate embedded font readiness before measure/paginate/render | ✓ |
| Best-effort fallback | Silently degrade to another face if custom setup fails | |

**User's choice:** Research tradeoffs and pick the least-surprise DX path.
**Notes:** Recommended outcome is explicit preflight before layout work begins. Invalid explicit font setup must fail through typed errors; no silent fallback from an explicitly selected custom font.

---

## Support boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Regular face only | Support one explicit embedded face per logical font | |
| Small explicit family set | Support `regular`, `bold`, `italic`, `bold_italic` with explicit caller-provided variants | ✓ |
| Broad CSS-like styling | Implicit weights, family discovery, faux style synthesis | |

**User's choice:** Cover all gray areas and optimize for coherent project-aligned recommendations.
**Notes:** Recommended outcome is the narrow four-variant family model, but only with explicit variant files/bytes. No faux bold/italic, no implicit discovery, no broad style system, and no generalized weight-axis scope.

---

## Determinism proof target

| Option | Description | Selected |
|--------|-------------|----------|
| Layout determinism only | Lock line breaks, widths, page breaks, and page counts | ✓ |
| Full PDF byte identity | Make exact final bytes the primary public contract | |
| Both equally public | Treat layout and full-byte identity as equal product guarantees | |

**User's choice:** Prefer a thoughtful, ecosystem-informed default rather than having to arbitrate.
**Notes:** Recommended outcome is to make stable layout behavior the public contract and treat embedding assertions structurally. Whole-file byte identity may exist as a narrow internal regression check, but not as the main promise of Phase 26.

---

## Downstream recommendation posture

| Option | Description | Selected |
|--------|-------------|----------|
| Ask often | Surface many equivalent options for user selection | |
| Coherent default synthesis | Collapse research into one recommendation set; escalate only high-impact semantic choices | ✓ |
| Full autonomy always | Never escalate, even for product-semantics changes | |

**User's choice:** "think deeply one-shot a perfect set of recommendations so i dont have to think" and shift that preference left within GSD except for very impactful choices.
**Notes:** This matches the existing `.planning/METHODOLOGY.md` escalation rule and should be applied strongly for Phase 26 planning/execution.

---

## the agent's Discretion

- Internal representation of preflighted embedded font descriptors.
- Exact module boundaries for parsing, metrics extraction, and PDF embedding.
- Whether a family helper expands into multiple logical names or stores an internal variant map.
- Exact typed error names and telemetry metadata fields.

## Deferred Ideas

- Glyph fallback chains and missing-glyph behavior belong to Phase 27.
- Unicode support-matrix publication and unsupported-shaping diagnostics belong to Phase 27.
- Variable fonts, arbitrary weights, and ambient system-font lookup are intentionally not part of Phase 26.
