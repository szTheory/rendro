---
status: passed
phase: 70-consolidate-already-validated-surfaces
verified: 2026-05-29
requirements: [VIEWER-01]
score: 12/12
---

# Phase 70 Verification Report

**Phase goal:** Every pre-v2.3 `supported` viewer row carries a checked-in `evidence:` pointer in the canonical home, with no regression in published support.

**Result:** PASSED

## Must-Haves Verified

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Five legacy rows have canonical evidence files | PASS | `priv/viewer_evidence/{forms/apple_preview,embedded_files/adobe_acrobat_reader,links/adobe_acrobat_reader,links/apple_preview,protection/apple_preview}.md` |
| 2 | Matrix `evidence:` pointers resolve | PASS | Six `evidence` keys in `priv/support_matrix.json` (5 legacy + chrome_pdfium) |
| 3 | `mix rendro.viewer_evidence list` shows 6 supported | PASS | CLI output: `supported=6` |
| 4 | `mix rendro.viewer_evidence validate` zero legacy warnings | PASS | Exit 0, "Viewer evidence validation passed." |
| 5 | Tier-B schema requires promotion keys on `supported` | PASS | `priv/schemas/support_matrix.schema.json` line 158 |
| 6 | `mix docs.contract` 8/8 lanes green | PASS | 55 tests, 0 failures |
| 7 | api_stability STACK mirrors for all five rows | PASS | Lines 48, 106, 108, 130 reference canonical paths |
| 8 | CHANGELOG five per-row re-home bullets | PASS | CHANGELOG.md lines 25–29 |
| 9 | embedded_files × Preview stays unverified (D-07) | PASS | Matrix row `unverified`, list output confirms |
| 10 | chrome_pdfium row unchanged | PASS | `priv/viewer_evidence/forms/chrome_pdfium.md` + matrix pointer intact |
| 11 | Fixture paths committed in frontmatter | PASS | All five evidence files use `test/fixtures/*.pdf` |
| 12 | VIEWER-01 requirement traceable | PASS | All three plan SUMMARYs mark `requirements-completed: [VIEWER-01]` |

## Automated Checks Run

```bash
mix rendro.viewer_evidence validate   # PASS
mix rendro.viewer_evidence list         # supported=6
mix docs.contract                       # 8/8 lanes PASS
mix test test/docs_contract/            # 55 tests, 0 failures
mix test test/rendro/viewer_evidence/   # 90 tests, 0 failures
```

## Deviations Accepted

- **Automation vs manual:** Phase 70 CONTEXT was revised to use pdfium-cli/poppler/qpdf structural CI proxies instead of manual GUI checkpoints. Evidence files carry honest GUI negation prose; matrix uses `viewer_kind: "pdfium-cli"`. This satisfies VIEWER-01 behavioral recording with CI-enforceable proxies.

## Human Verification

None required — all success criteria are machine-verifiable.

## Gaps

None.
