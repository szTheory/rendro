# Phase 117: Edge-case stress matrix - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-18
**Phase:** 117-edge-case-stress-matrix
**Areas discussed:** Matrix shape & golden layout, RTL & errors-as-product (EDGE-02), Byte-golden vs raster split, Rubric exemption wiring (EDGE-03)

**Mode:** User selected all four gray areas and requested a deep 4-agent parallel research fan-out with a single one-shot, mutually-coherent, locked recommendation set (research-first, minimize-asks preference). All four decisions were locked from that research; no per-question interactive selection.

---

## Matrix shape & golden layout

| Option | Description | Selected |
|--------|-------------|----------|
| Full mechanical cross-product (6 × ~20) | Force every cell; trivially "exhaustive" | |
| Hand-written test block per family | Max per-case control | |
| Data-driven `@matrix {family,dim}→:applies\|reason` + generator + exhaustiveness meta-test | One source of truth; N/A cells carry reasons; gap can't masquerade as coverage | ✓ |

**Golden storage sub-question:**

| Option | Description | Selected |
|--------|-------------|----------|
| Inline `@golden_sha256` constants | table_byte_identity precedent | |
| Per-case files `priv/goldens/<family>/<dimension>.sha256` | Named case, one-line diffs, mirrors raster_refs | ✓ |
| Single JSON manifest | One file, but whole-file churn / skim-LGTM risk | |
| Commit actual PDF bytes | Unreviewable binary blobs | |

**User's choice:** Data-driven `@matrix` + exhaustiveness ratchet; per-case hash-only golden files with an explicit `MIX_GOLDEN_BLESS` gesture (un-gated — PDF-byte hashes are portable). See CONTEXT D-01..D-04.
**Notes:** Deliberate inverse of Jest's `-u` auto-bless footgun — missing ref hard-flunks; failure message frames a hash change as a defect, not a refresh. Two-run determinism pre-check before hashing.

---

## RTL & errors-as-product (EDGE-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Assume a `lib/` guard is needed for RTL | Add an additive validator/early error | |
| Pure test assertions (no `lib/` change) | All three inputs already surface public typed errors | ✓ |

**User's choice:** Pure test-only assertions. Verified by live render probes: overflow + tall-row → `%Rendro.Error{stage: :paginate, reason: :content_overflow}`; RTL → `%Rendro.Error{stage: :measure, reason: {:unsupported_glyph, _}}` (default font) or shaper `{:shaping_required, ...}`. No silent-wrong-output hole exists. See CONTEXT D-05..D-08.
**Notes:** Headline finding — Phase 117 stays posture-clean (no `lib/` change; milestone's only irreversible act remains Phase 115). Assert typed struct + `stage`/`reason` + `next` substring, never message prose; `refute` render ever returns `{:ok, _}` for RTL. Engine-level granularity (one representative each, not per-family). `i18n/analyzer.ex` is dead code — do not wire in.

---

## Byte-golden vs raster split ("where applicable")

| Option | Description | Selected |
|--------|-------------|----------|
| Raster every applicable cell | Maximal visual coverage; count explosion + flake | |
| Byte golden every cell; raster only for placement-geometry claims (curated, ceilinged) | Portable backbone + targeted visual confirmation | ✓ |

**User's choice:** Every cell gets a byte golden; raster refs added only where the claim is page/placement geometry (pagination, page-size, running content, extreme wrap). Curated set ~6 fixtures / ~12 page refs, hard ceiling ≤8/≤16. See CONTEXT D-09..D-12.
**Notes:** Reuse existing `raster_snapshot` tag + `MIX_RASTER_BLESS`/`GITHUB_ACTIONS` container guard verbatim; raster stays advisory (not a required check) so a pdfium pin bump can't red-wall the required job. Tarball-exclusion guard cloned from branding_claims_test.

---

## Rubric exemption wiring (EDGE-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Per-fixture `stress_exempt: true` entries in `scores` | Uses field literally; high manifest noise + forced dummy scores | |
| Exclude-by-construction only | Zero change but exemption is implicit (violates "explicit") | |
| Manifest-level `stress_exemption` block + contract guards + per-entry flag as tripwire | One reviewer-visible statement; scores stays clean; fail loud both directions | ✓ |

**User's choice:** One top-level `stress_exemption` block (schema-`required`), zero per-fixture entries; contract tests assert exemption present + non-empty, no live `stress_exempt` in `scores`, disjointness of stress-fixture ids vs scored `demo_id`s, and a non-empty teeth guard. See CONTEXT D-13..D-15.
**Notes:** Minimal schema delta (add `stress_exemption` def + root-required; no `if/then`). Fixture ids imported from the `@matrix` enumeration — one source of truth.

---

## Claude's Discretion

- Exact dimension-list granularity, fixture-builder shape, N/A reason strings, and the single representative family for A4/Letter + extreme-wrap.
- Whether the two-run determinism pre-check is inline or a shared helper.
- Exact `stress_exemption.reason` wording and `fixture_source` target.

## Deferred Ideas

- Wire or delete `Rendro.I18n.Analyzer.analyze/1` (unwired dead code) — future cleanup phase.
- HarfBuzz adapter for real RTL/complex-script shaping — large separate capability, out of milestone scope.
- Retrofit opts-shape/`validate_data!` typed-error coverage to Invoice/Statement (Phase-116 D-19 scoped it to Payslip/Ticket) — future additive phase.
