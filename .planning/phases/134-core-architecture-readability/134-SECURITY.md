---
phase: 134
slug: core-architecture-readability
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-27
---

# Phase 134 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Historical evidence → quality ledger | Review prose and diagnostic signals cannot authorize repair until current repository evidence corroborates them. | Finding identities, dispositions, source/test evidence |
| Repository references → deletion authority | Source absence alone cannot authorize deletion because compiled, dynamic, documentation, package, or public consumers may remain. | Reference scans, xref results, package/public manifests |
| Recipe options → shared palette helper | Caller-controlled theme and palette values cross into a shared internal resolver whose compatibility semantics must remain exact. | Theme values, palette overrides, recipe defaults |
| Helper outcome → recipe rendering | A pure resolution refactor can still alter deterministic output if defaults or precedence drift. | Resolved color maps and rendered PDF bytes |
| Source narration → maintainer understanding | Spec/comment edits can erase provenance or overstate supported behavior without a compiler failure. | Documentation claims, phase/date provenance |
| Repair evidence → terminal ledger closure | Broad green suites cannot substitute for finding-specific closure under the original identity. | Focused proofs, before/after facts, resolution commits |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-134-01 | Tampering | `.planning/QUALITY.md` candidate intake | high | mitigate | QL-005–QL-008 retain distinct permanent identities, current source/test evidence, explicit disposition/status fields, and focused verification; `mix quality.baseline` validates the ledger. | closed |
| T-134-02 | Repudiation | narration/provenance audit | medium | mitigate | QL-008 records the bounded line-specific audit and preserves valid operational phase/date provenance instead of authorizing speculative edits. | closed |
| T-134-03 | Denial of service | palette characterization | high | mitigate | `palette_test.exs` fixes legacy default, nil, theme, override-order, and `BadMapError` behavior before and after extraction. | closed |
| T-134-04 | Denial of service | `Rendro.I18n.Analyzer` deletion | high | mitigate | Repository/package/public scans, zero xref callers, manifest identity, and the active shaper/error/i18n/measure tests prove removal does not strand a consumer. | closed |
| T-134-05 | Tampering | ledger lifecycle | medium | mitigate | QL-005 closes under its original identity with exact resolution evidence; duplicate QL/SIG identities and contradictory disposition/status states fail executable ledger validation. | closed |
| T-134-06 | Tampering | palette resolver and seven recipe call sites | high | mitigate | The resolver preserves nil/theme/default selection and final `Map.merge/2`; seven direct call sites are covered by characterization, opts-threading, byte-identity, and themed-render tests. | closed |
| T-134-07 | Denial of service | recipe option failure boundary | high | mitigate | The helper adds no coercion, rescue, validation, or alternate render path; direct characterization retains the invalid non-map override `BadMapError`. | closed |
| T-134-08 | Repudiation | narration/spec/comment audit | medium | mitigate | QL-008 requires line-specific evidence, preserves provenance-bearing references, and the docs/static/full deterministic gates pass. | closed |
| T-134-09 | Tampering | terminal ledger closure | medium | mitigate | QL-005 and QL-006 close under their original IDs with focused proof, before/after facts, resolution references, manifest identity, and rendered-byte compatibility evidence. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-27 | 9 | 9 | 0 | GSD secure-phase ASVS L1 evidence audit |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-27
