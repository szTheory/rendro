# Phase 123: `from_brand/2` E2E + honest rubric-gap closure + gallery/docs/manifest closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-28
**Phase:** 123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-manifest-closure
**Areas discussed:** Sign-off protocol, Gallery curation, default/0 finalization, from_brand E2E shape

---

**Discussion mode:** The user selected all 4 offered gray areas and directed a deep,
parallel, subagent-driven research pass across every decision point (full lens stack:
Elixir/Hex/ecosystem idiom, lessons from comparable libs/apps, DX/API-consumer perspective,
JTBD/persona/who-what-where-when-why, design pillars, brand fidelity, honesty discipline),
against the living `brand/` system (authoritative over the older `prompts/Rendro Brand Book.txt`)
and the actual code — with instruction to one-shot a single coherent, cohesive locked
recommendation set so the user does not have to think. Four `gsd-advisor-researcher` agents ran
in parallel; results were synthesized into the locked decisions below (one cross-agent tension
resolved: the gallery `from_brand` row recipe + the leading-1.35 byte impact on the "default" retag).

---

## Sign-off protocol (honest SHOW-01 re-score)

| Option | Description | Selected |
|--------|-------------|----------|
| Per-record `signed_off_by`/`signed_off_at`/`evidence_ref` fields + schema + test teeth | Machine-enforced; a `passed:true` without a live hash-checked evidence_ref fails the build | ✓ |
| Standalone `SIGN-OFF.md` review artifact (SCORECARD house style) | Human-legible record the evidence_ref points at | ✓ (companion) |
| Git `Signed-off-by:` trailer only | Native provenance, but invisible to manifest/tests | ✓ (additive only) |
| Interactive tool-gated approval (Chromatic/Percy-style) | Strongest anti-rubber-stamp, but wrong weight class / violates zero-dep DNA | |
| Re-score all 6 families | Theming changed every render → every stale justification must be re-earned | ✓ |
| Re-score invoice only | Reintroduces the stale-evidence trap on the other 5 | |

**User's choice:** Machine-enforced sign-off fields + SIGN-OFF.md companion + additive git trailer;
re-score all 6 families; evidence = the shipped themed-default gallery rasters + pre-computed
glyph-height deltas; three-commit split (data → theme → score-flip-only) making the order provable in git.
**Notes:** Key grounding finding — the invoice DATA fix was already delivered in Phase 115
(`transform_invoice` put_optionals parties/totals; fixture carries them), so "fix DATA first" is a
verify-and-attest step, not a rescue; the honest order still holds via the split commit.

---

## Gallery curation

| Option | Description | Selected |
|--------|-------------|----------|
| Exhaustive matrix (~26–28 rows) | Every combo literally in the gallery; reads as a CI test-grid; violates brand restraint | |
| Curated-representative (~8–9 rows) | Cheapest; single dark row under-sells the dark story | |
| Hybrid: 11 rows (7 light/default + 3 dark + 1 from_brand), additive | Proves every claim, reads as a designed showcase, 4 net-new rasters | ✓ |

**User's choice:** 11-row additive hybrid — retag 7 light rows `theme:null→"default"`, add
`invoice_dark`/`certificate_dark`/`ticket_dark` + `invoice_brand` (teal accent); flagship Invoice
triptych; `readme_hero` subset flag; `preset:null` on all 11.
**Notes:** Mechanism-level "dark works everywhere" is already proven by Phase 121 goldens + support
matrix; the gallery is showcase, not exhaustive re-proof. Dense recipes (Statement/Receipt) and
dark brand-asset renders honestly excluded from dark. Coherence correction folded in: `leading:1.35`
re-flows the prose-bearing "default" rows, so the retag is byte-neutral only for non-prose recipes —
the re-bless is folded into the same human-signed gallery bless.

---

## default/0 finalization

| Option | Description | Selected |
|--------|-------------|----------|
| Lock palette as-is (zero deltas) | All 9 roles faithfully mined, AA+ on white, warm/cool coherent | ✓ |
| Re-tune (e.g. accent blue-700, white surface) | Would unmine token aliases + desync from_brand + collapse accent/accent-strong | |
| Apply `leading: 1.35` now | Realizes the parked one-line change; Brand Book §9 generous prose leading | ✓ |
| Keep `leading: 1.2` | Zero re-bless, but leaves prose cramped + punts the deferred item past its own closure phase | |

**User's choice:** Lock palette as-is; apply `leading: 1.2 → 1.35`; re-bless only the 3 multi-line
prose blocks on the themed path (Certificate citation, Invoice/BrandedInvoice/Ticket terms);
7 no-theme recipe goldens untouched.
**Notes:** Keep accent = blue-600 (the token's actual `accent`/`action-primary-bg`); recipe-usage
guard: accent is a fill/large-text role, not small text on the warm surface band. Verify themed
Certificate still fits single-page A4-landscape at 1.35.

---

## from_brand E2E shape

| Option | Description | Selected |
|--------|-------------|----------|
| Test-only integration proof | Cheap/deterministic but invisible to docs; teaches nothing | |
| Gallery demo render | Visual accent proof; hash-checked; required by DEFAULT-03 anyway | ✓ |
| Guide worked example w/ docs-contract markers | Copy-pasteable + executes as the E2E test; required by CONTRACT-02 anyway | ✓ |
| Combination (gallery + guide; guide's docs-contract execution IS the test) | Reuses the two required artifacts → near-free triple proof | ✓ |

**User's choice:** Combination — `invoice_brand` gallery row (Invoice + `from_brand(accent:"#0E7C76")`,
accent-only) + `guides/theming.md` worked examples whose `# docs-contract:` markers execute as the
E2E test; BrandedInvoice is the guide's orthogonality-composition vehicle (assets + accent in one call).
**Notes:** Headline one-liner
`Invoice.document(data, theme: Rendro.Theme.from_brand(accent: "#0E7C76"))` (keyword form, hides
`on_accent` derivation). Seeds: teal-700 `#0E7C76` (visibly non-blue) for the render + a light-accent
amber-300 `#E6B450` assertion to prove the contrast heuristic both ways; third-party hex only in
teaching prose. Mandatory honest wording: `on_accent` is a readable default, not a WCAG/PDF-UA claim,
overridable.

## Claude's Discretion

Per-demo measured-delta numbers and SIGN-OFF.md prose; `readme_hero` filter implementation; slice
split; `defp` helper naming for themed `build_source_document/1`; docs-contract marker names;
whether the retag threads `theme: default()` via a shared helper. Binding constraints listed in
CONTEXT.md D-01…D-05.

## Deferred Ideas

Genre presets / catalog / configurator / curated fonts → Milestone C; live Studio → Milestone D;
exhaustive 28-row gallery matrix (deliberately not built); dark rows for dense/asset-branded recipes;
`density: :compact` deep multipliers; tabular figures / small-caps / OpenType mono; WCAG-AA/PDF-UA
conformance claims (permanently out).
