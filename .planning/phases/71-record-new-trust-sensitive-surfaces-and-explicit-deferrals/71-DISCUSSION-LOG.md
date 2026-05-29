# Phase 71: Record New Trust-Sensitive Surfaces and Explicit Deferrals - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 71-record-new-trust-sensitive-surfaces-and-explicit-deferrals
**Areas discussed:** Wave batching, Acrobat session design, ambiguous cell disposition, signing-prep equivalence & PDFium path, long-lived fixtures & deferral templates
**Mode:** --all (all gray areas) + parallel subagent research

---

## Wave batching & closure rhythm

| Option | Description | Selected |
|--------|-------------|----------|
| A — Single atomic Phase 71 PR | All ~20 cells + prose + CHANGELOG in one merge | ✓ |
| B — Two waves (forms/protection/sig vs signing) | Smaller PRs; interim partial missing output | |
| C — Surface-by-surface (~6 PRs) | Smallest diffs; maximum contract fragmentation | |
| D — Promotions first, deferrals second | Positive narrative first; honesty gap mid-milestone | |

**User's choice:** Research-backed recommendation (Option A) — user requested one-shot coherent package without further deliberation.

**Notes:** Analogous to browserslist single snapshot PR and Phase 70 D-19. Internal recording waves allowed; publication atomic.

---

## Acrobat operator session design

| Option | Description | Selected |
|--------|-------------|----------|
| A — One session, one fixture chain | Single PDF lineage unsigned→augmented | |
| B — Surface-isolated sessions | Six Acrobat launches | |
| C — Reuse forms/protection; new signing chain | Committed unsigned/prepared; runtime signed/long-lived | ✓ |
| D — Commit all signing-stage PDFs | Violates signing/README; drift risk | |

**User's choice:** Option C with single-session ergonomics (six PDFs, six evidence files, ordered by destructiveness).

**Notes:** BCD batches collection but stores per feature×browser. PAdES uses distinct artifacts per stage.

---

## Ambiguous cell disposition

| Strategy | Description | Selected |
|----------|-------------|----------|
| A — Close all 20 in Phase 71 | promote or defer every cell | ✓ |
| D — Leave embedded_files×Preview for Phase 72 | Silent unverified through Phase 71 | |

**User's choice:** Strategy A. signed_artifact×chrome_pdfium promotes per ROADMAP (not deferred). forms×pdfjs: attempt promote, defer on failure. embedded_files×Preview: re-verify then defer default.

---

## Signing-prep equivalence

| Option | Description | Selected |
|--------|-------------|----------|
| A — Non-Acrobat inherits signature_widget status | supported + cross-ref evidence | ✓ |
| B — Case-by-case operator confirmation | Subjective | |
| C — Always separate recording | ROADMAP forbidden | |
| D — explicit_deferral with equivalence reason | Semantically wrong when promotable | |

**User's choice:** Option A with Acrobat exception (full separate prep evidence).

---

## PDFium recording path

| Option | Description | Selected |
|--------|-------------|----------|
| A — pdfium-cli + live test lane | Phase 70 precedent; CI reproducible | ✓ |
| B — Manual Chrome GUI | Channel drift; breaks automation uniformity | |
| C — Hybrid manual for sig/signed | Inconsistent under one matrix key | |

**User's choice:** Option A. Host pinning via substrate prose (pdfium-cli + embedded PDFium build). Preview sig_widget uses manual GUI for net-new promotion.

---

## Long-lived fixtures & deferral templates

| Fixture option | Description | Selected |
|----------------|-------------|----------|
| D — scripts/long_lived_viewer_proof_fixture.exs | Protection-script pattern + certomancer chain | ✓ |
| B — Operator saves live-test tmp output | Drift from CI chain | |
| C — fixture_sha256 only | Non-portable for promoted row | |

| Deferral option | Description | Selected |
|-----------------|-------------|----------|
| C — Hybrid templates + viewer clause | Appendix B skeletons; lint-safe | ✓ |
| B — Fully custom per cell | Error-prone at ~20 cells | |

**User's choice:** Committed viewer-evidence PDFs at `test/fixtures/` with README carve-out; hybrid deferral templates.

---

## Claude's Discretion

- forms×pdfjs promote vs defer (observation outcome)
- embedded_files×Preview promote vs defer (re-verify outcome)
- Thin stub vs direct evidence pointer for inherited signing_prep rows
- Pdfium live-test module naming

## Deferred Ideas

- Headless-browser viewer CI
- Frontmatter host_app schema fields
- Chrome GUI pinning as separate from pdfium-cli substrate
