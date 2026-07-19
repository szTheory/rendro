---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
verified: 2026-07-19T19:38:10Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "SHOW-01 / SC1 — each family×domain demo passes the rubric (content_hierarchy = 5, other cores ≥ 4, both gates pass)"
  gaps_remaining: []
  regressions: []
---

# Phase 118: Rubric-gated demonstration set, gallery & docs closure — Verification Report

**Phase Goal:** Close the milestone with a rubric-PASSING family×domain demonstration set, regenerated gallery/artifacts (with S6 tags), and reconciled docs/support so every new family and claim is proof-backed and no accessibility overclaim is made.
**Verified:** 2026-07-19T19:38:10Z
**Status:** passed
**Re-verification:** Yes — after gap closure (118-08, 118-09)

## Goal Achievement

The previously-failing headline gap (SHOW-01: no demo cleared the rubric gate) is now closed. 118-08 reworked all six family compositions (dominant key-fact per family, faithful 2-decimal money, native-A6 ticket) and 118-09 regenerated the gallery/artifacts from those improved renders and re-scored all six demos. Independent re-verification below confirms this is not a repeat of the prior fabrication pattern: the arithmetic, the regenerated artifacts, and the rendered pixels were all checked directly against the codebase, not against SUMMARY.md prose.

### Observable Truths (roadmap Success Criteria)

| # | Truth | Status | Evidence |
| --- | ------- | ---------- | -------------- |
| SC1 (SHOW-01) | Family×domain matrix rendered via recipes+escape hatch, each demo citing DOMAIN.md **and passing the rubric** (hierarchy=5, core≥4, gates), scores appended to manifest (S5) | ✓ VERIFIED | Rendered ✓ (7 gallery renders, re-blessed). Cites DOMAIN.md ✓ (6/6, `demo_cites_domain_md_test` green). Scores appended ✓ (6 schema-valid entries). **Rubric arithmetic independently recomputed by hand for all 6 entries against the exact `passed?/2` rule (content_hierarchy==5 AND every other core ≥4 AND both gates true) — all 6 genuinely compute to `true`.** Recorded `passed:true` matches the honest computation, not an independent assertion. See "Rubric Arithmetic Recheck" below. |
| SC2 (SHOW-02) | recipes.md, branding.md, first_invoice.livemd, phoenix_example updated to demonstrate upgraded Invoice + new families, claims bounded to evidence | ✓ VERIFIED | Unchanged since prior pass (118-07); untouched by 118-08/09; `docs_contract` lane still green (293 tests, 0 failures) |
| SC3 (SHOW-03) | gallery/ + artifacts.json regenerated via `mix rendro.launch_artifacts.gen` to realistic renders w/ matching SHA-256; artifacts.json gains S6 theme/mode/preset tags | ✓ VERIFIED | Re-ran `mix rendro.launch_artifacts.check` myself with a version-pinned pdfium-cli (v0.11.0, matches `priv/pdfium_pin.json`, re-proven byte-identical via the `pdfium_raster_snapshot_test.exs:31` determinism gate before use) → **"Launch artifacts VERIFIED"** (zero drift) against the 118-08-improved renders. `artifacts.json` has 7 entries, each with `png_sha256`/`source_pdf_sha256` + theme/mode/preset (S6) keys. |
| SC4 (SHOW-04) | support_matrix.json + README reconciled, every new family/claim proof-backed, no tagged-PDF/PDF-UA accessibility claim (production-grade guarded) | ✓ VERIFIED | `accessibility_overclaim_test.exs` still green (self-tested tripwire). README/guides make no rubric-pass marketing claim, so nothing there is now stale. One minor doc-freshness note below (non-blocking). |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Rubric Arithmetic Recheck (independent, not trusting the recorded `passed` field)

The `passed?/2` rule (from `test/docs_contract/rubric_manifest_contract_test.exs:33-45`): `content_hierarchy == 5 AND every other dimension >= 4 AND every gate == true`. Recomputed by hand against `priv/quality/rubric_scores.json`'s real `dimension_scores`/`gate_results` for all 6 entries:

| demo_id | IA | CH | DF | RA | TC | RC | gates | passed?/2 recomputed | recorded `passed` |
| --- | -- | -- | -- | -- | -- | -- | ----- | --------------------- | ------------------ |
| invoice-acme-phoenix-saas | 5 | 5 | 5 | 4 | 4 | 4 | true/true | true | true — match |
| statement-northwind-ledger-co | 5 | 5 | 5 | 4 | 4 | 4 | true/true | true | true — match |
| receipt-harbor-and-oak-cafe | 5 | 5 | 5 | 4 | 4 | 4 | true/true | true | true — match |
| certificate-summit-training-institute | 5 | 5 | 5 | 4 | 4 | 4 | true/true | true | true — match |
| payslip-aurora-live | 4 | 5 | 5 | 4 | 4 | 4 | true/true | true | true — match |
| ticket-aurora-live | 5 | 5 | 5 | 4 | 4 | 4 | true/true | true | true — match |

All 6 recomputations match the recorded value exactly. **Caveat for future hardening (not a blocker):** `test/docs_contract/rubric_manifest_contract_test.exs` only unit-tests the `passed?/2` helper against synthetic all-5s / near-miss inputs (lines 61-89) — it does not iterate the manifest's *real* `scores[]` entries and assert `entry["passed"] == passed?(entry["dimension_scores"], entry["gate_results"])`. The schema (`rubric_scores.schema.json`) also does not enforce this cross-field consistency. Nothing currently catches a future entry that sets `passed:true` while its own scores don't clear the gate. This verification closes that gap for *this* manifest by manual recomputation (all 6 honest), but the codebase has no standing tripwire against a future regression of the exact failure mode this phase exists to fix. Recommend a follow-up: add a `for score <- manifest()["scores"], do: assert entry["passed"] == passed?(...)` test to `rubric_manifest_contract_test.exs`.

### Visual Spot-Check (direct inspection of the re-rendered gallery PNGs)

Rather than trust the `justifications` prose, all 7 `assets/rendro/gallery/*.png` files were opened and visually inspected:

| Demo | Claimed dominant element | Visual confirmation |
| ---- | ------------------------- | -------------------- |
| Invoice | "Total Due: $696.60" (24px) vs. 19px title | ✓ Confirmed — clearly the largest text on the page |
| Statement | Boxed "Closing balance $6,647.56" (26px) vs. 19px title | ✓ Confirmed — boxed, unmistakably dominant |
| Receipt | "Total: $30.78" (22px) vs. 17-19px merchant name | ✓ Confirmed — largest element, merchant identity now present at top |
| Certificate | "Alex Rivera" (34px) vs. 26px title | ✓ Confirmed — recipient name is clearly the largest text, vertically/horizontally centered inside a border |
| Payslip | Boxed "NET PAY $3,292.50" | ✓ Confirmed dominant; "YTD Deductions" header renders with a clean space (no collision) |
| Ticket | "GA H 24 B" locator | ✓ Confirmed dominant on native A6 (narrow) page; event title/terms clearly smaller |

No fabrication or mismatch found between the recorded justifications and the actual rendered pixels for any of the 6 demos. This directly addresses the phase's core risk (a prior attempt asserted fake passing scores) — the current scores are genuinely defensible against the artifacts on disk, not merely asserted.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | ----------- | ------ | ------- |
| priv/quality/rubric_scores.json | 6 honest, passing score entries | ✓ VERIFIED | 6 entries, all `passed:true`, arithmetic independently recomputed and matched (see above) |
| assets/rendro/artifacts.json | 7 entries + hashes + S6, zero drift | ✓ VERIFIED | `mix rendro.launch_artifacts.check` → "Launch artifacts VERIFIED" (re-run live with pinned pdfium-cli) |
| assets/rendro/gallery/*.png | 7 renders reflecting 118-08 compositions | ✓ VERIFIED | All 7 present; directly viewed, contents match justifications |
| .planning/REQUIREMENTS.md | SHOW-01 honestly Complete, no lingering GAP note | ✓ VERIFIED | Line 51: `[x] SHOW-01` with closure rationale citing 118-08/09 and the exact `passed?/2` computation; no "GAP" text remains |
| lib/rendro/examples_data.ex, recipes/*.ex | Invoice money faithful (no `Decimal.to_float`), dominant key-fact composition | ✓ VERIFIED | `grep Decimal.to_float lib/rendro/examples_data.ex` → 0 hits in code (comment-only); invoice render shows `$696.60` (2-decimal, faithful) |
| test/docs_contract/rubric_manifest_contract_test.exs | Schema/arithmetic contract | ✓ VERIFIED | Green (part of 293-test docs_contract run); see caveat above re: no real-entry cross-check |

### Key Link Verification

| From | To | Via | Status |
| ---- | --- | --- | ------ |
| `mix rendro.launch_artifacts.gen` output | `assets/rendro/artifacts.json` + `gallery/*.png` | SHA-256 match, re-verified live | ✓ WIRED — `launch_artifacts.check` VERIFIED |
| `priv/quality/rubric_scores.json` entries | `passed?/2` arithmetic | manual recomputation (Step above) | ✓ WIRED — matches for all 6, though not machine cross-checked (see caveat) |
| REQUIREMENTS.md SHOW-01 | 118-08/118-09 SUMMARYs + rubric_scores.json | closure rationale citation | ✓ WIRED — text is accurate and specific |

### Behavioral Spot-Checks / Probe Execution

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Gallery/artifacts zero-drift (re-run live, not trusted from SUMMARY) | `mix rendro.launch_artifacts.check` (with pinned pdfium-cli v0.11.0 on PATH, determinism re-proven via `pdfium_raster_snapshot_test.exs:31` first) | "Launch artifacts VERIFIED" | ✓ PASS |
| pdfium-cli determinism gate (precondition for trusting the check above) | `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs:31 --include raster_snapshot` | 1 test, 0 failures | ✓ PASS |
| docs-contract lanes (rubric/domain/accessibility/gallery) | `mix test test/docs_contract/` | 1 doctest, 293 tests, 0 failures | ✓ PASS |
| launch-artifacts static-contract lane specifically | `mix test test/docs_contract/launch_artifacts_claims_test.exs` | 9 tests, 0 failures | ✓ PASS |
| Full project suite (run once) | `mix test` | 12 doctests, 4 properties, 1569 tests, 0 failures (26 excluded) | ✓ PASS — matches 118-09's claimed count exactly |
| No new format debt from 118-08/09 | `mix format --check-formatted` | 6 files red, all pre-existing (`golden_test.exs`, `edge_fixtures_test.exs`, `edge_matrix_test.exs`, `pdfium_raster_snapshot_test.exs`, `edge_fixtures.ex`, `edge_error_matrix_test.exs`) — all 6 are a subset of the 10 already logged in `deferred-items.md` before 118-08 ran | ℹ️ Info, not a phase-118 regression |
| No unresolved debt markers in phase-118-touched files | `grep -nE "TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER"` across all 118-08/09 modified files | 0 real hits (1 false positive: "JTBD" substring in REQUIREMENTS.md) | ✓ PASS |
| git commits for 118-08/09 exist | `git log --oneline` | All 9 commits (20e45ee, 2670917, 7da9cff, 841b472, c0236bc, ddd970b, e8b1c16, 65c0bd3, 8e96745) present | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| SHOW-01 | 118-01,02,03,06,08,09 | Demonstration matrix rendered, cited, rubric-passing, scored | ✓ SATISFIED | All 6 demos honestly `passed:true`; independently re-verified (arithmetic + visual) |
| SHOW-02 | 118-07 | Docs surfaces demonstrate upgraded Invoice + new families | ✓ SATISFIED | Untouched by gap closure; still green |
| SHOW-03 | 118-03,04,05,09 | Gallery/artifacts.json regenerated, S6 tags | ✓ SATISFIED | Re-generated by 118-09, zero-drift re-confirmed live |
| SHOW-04 | 118-07 | Support matrix + README reconciled, proof-backed, no accessibility overclaim | ✓ SATISFIED | Tripwire green; no README/guides claim references rubric-pass status so nothing there needed updating |

All 4 phase requirement IDs accounted for; REQUIREMENTS.md coverage table (lines 103-106) shows all 4 as "Complete." No orphaned requirements.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
| ---- | ------- | -------- | ------ |
| 6 pre-existing test files | `mix format --check-formatted` red | ℹ️ Info | Pre-existing debt logged in `deferred-items.md` before 118-08 ran; not introduced by the gap-closure plans; not attributed to this phase |
| `priv/support_matrix.json`'s `demonstration_set.boundaries` | `reader_quality_rubric_pass: "unsupported"` is now stale — the rubric does pass as of 118-09, but this internal support-matrix boundary field wasn't updated (118-09 did not modify `priv/support_matrix.json`) | ℹ️ Info (non-blocking) | This is an *under*-claim, not an overclaim — it doesn't violate SHOW-04's "no accessibility overclaim" or "proof-backed claims" requirements (no README/guide text asserts rubric-pass status, so there's no live overclaim to fix). It is a missed opportunity to update internal bookkeeping to reflect the phase's actual achievement. Recommend a trivial follow-up edit to flip this boundary to `"supported"` with an evidence pointer to `priv/quality/rubric_scores.json`, but it does not block phase closure. |

### Human Verification Required

None required to close the phase. The one item that would ordinarily be flagged for human sign-off — the inherently subjective aesthetic/visual dimension scores (content_hierarchy=5 in particular, per 118-09's own SUMMARY note requesting human confirmation) — was addressed directly in this verification pass: all 7 gallery PNGs were visually inspected and the claimed dominant elements were confirmed present and genuinely the largest/most prominent element on each page. No fabrication or mismatch was found. A developer may still want to do their own final skim of the 6 PNGs against the rubric anchor language purely as a taste check, but there is no unresolved verification question blocking closure.

### Gaps Summary

None. The phase's headline gap (SHOW-01: no demo passed the rubric) is closed and independently re-verified — not merely re-asserted. All four requirements (SHOW-01..04) are satisfied, `mix test` is fully green (1569/1569), the gallery/artifacts are re-blessed with zero drift (re-run live against a version-pinned, determinism-proven pdfium-cli, not assumed from the SUMMARY), the rubric arithmetic was independently recomputed by hand for all 6 entries and matches, and the rendered pixels were directly inspected and match the recorded justifications. One non-blocking documentation-freshness note (`support_matrix.json`'s stale `unsupported` boundary, which understates rather than overstates capability) and one non-blocking test-hardening recommendation (add a manifest-entries-vs-`passed?/2` cross-check test) are noted for optional follow-up but do not gate this phase or the milestone.

---

_Verified: 2026-07-19T19:38:10Z_
_Verifier: Claude (gsd-verifier)_
