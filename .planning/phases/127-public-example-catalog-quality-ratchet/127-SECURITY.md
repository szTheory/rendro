---
phase: 127
slug: public-example-catalog-quality-ratchet
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-18
---

# Phase 127 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| literal registry → fixture/filesystem | Catalog paths select repository fixtures and committed output destinations. | Repository-relative paths and generated artifact bytes |
| deterministic PDF → pinned PDFium/CI artifact | Deterministic source PDFs cross into an advisory third-party rasterizer. | Complete PDF bytes, page-one PNGs, renderer version/SHA provenance |
| catalog evidence → reviewer records | Human judgments bind to exact artifacts without granting the generator write authority. | Catalog IDs, PNG/PDF SHA-256 identities, scores, gates, reviewer/date |
| rubric/manifest → Phase 128 consumer | Only a derived three-state projection crosses into future public UI metadata. | `passes`, `needs_work`, or `unscored`; bounded copy/disclosure |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-127-01 | Tampering / Information disclosure | fixture and artifact paths | high | mitigate | `Path.safe_relative/1`, literal registry membership, root-constrained path grammar, and traversal rejection before artifact reads/writes | closed |
| T-127-02 | Tampering | artifact/reviewer relation | high | mitigate | Exact one-to-one ID/path/PNG/PDF joins; missing, duplicate, orphan, stale, artifact-hash, and dimension drift rejection through `Catalog.check/1` | closed |
| T-127-03 | Tampering | pinned raster evidence | high | mitigate | Pinned PDFium version/SHA, exact CI commit/run provenance, bounded 32/16 payloads, post-import deterministic check, and verified evidence-ref cleanup | closed |
| T-127-04 | Repudiation | quality/status/scope claims | high | mitigate | Recomputed rubric thresholds; fail-closed pass-promotion provenance and resolution; fixed three-state labels; mode-derived dark disclosure; page-count-derived preview copy | closed |
| T-127-05 | Denial of service | registry and review cardinality | medium | mitigate | Literal exact-32 registry with hard ceiling, exactly 12 scored plus 20 reasoned-unscored dispositions, and bounded 16-image review payload | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-127-01 | T-127-05 | Visual judgment is intentionally limited to twelve flagship page-one previews plus four representative first/final-page images. The other twenty cells remain explicitly unscored; no universal viewer, print, accessibility, PDF/UA, WCAG, or production-readiness claim is made. | Jon / Phase 127 contract | 2026-08-17 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-18 | 5 | 5 | 0 | Codex orchestrator, ASVS L1 authored-register verification |

Evidence includes the clean post-fix code review, passed 4/4 goal verification, mandatory PNG-integrity regressions, exact page-count tests, no-silent-promotion schema/runtime mutations, package-boundary contracts, and successful pinned advisory job `95565301370`.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-18
