---
phase: 123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani
verified: 2026-07-28T21:30:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 123: `from_brand/2` E2E + honest rubric-gap closure + gallery/docs/manifest closure Verification Report

**Phase Goal:** Close the milestone honestly — deliver a strong unbranded `default/0` and brand-seeded theming end-to-end, remediate the folded-in Phase-118 SHOW-01 rubric gap IN THE HONEST ORDER (fix DATA first, theme second, re-score with human sign-off), populate the S6 gallery tags, and reconcile the support matrix and docs so every theming claim is proof-backed. The trap this phase must avoid: applying a slick accent palette, declaring the demos prettier, and marking the rubric passed — a better palette raises craft/restraint, which were NOT the failing dimensions.

**Verified:** 2026-07-28
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `Theme.default/0` is a restrained neutral-ink unbranded default that looks strong on its own, and `from_brand/2` produces a themed document E2E from a single `accent:` seed with `brand:` assets orthogonal | ✓ VERIFIED | `lib/rendro/theme.ex` L48-58 `@default_colors` (ink `{16,24,39}`, accent `{44,107,237}`) unchanged; L79 `leading: 1.35` (the sole DEFAULT-01 value edit, confirmed via `git diff` in commit `3c69937` touching only that literal). `guides/theming.md`'s 3 executable `# docs-contract:` fences prove `from_brand(accent:"#0E7C76")` → `colors.accent == {14,124,118}` / `on_accent == {255,255,255}`, the both-ways amber case, and BrandedInvoice orthogonality (asset registry via `data.brand`, accent via `theme:`, `from_brand/2` alone returns a bare `%Theme{}`). All 3 fences execute green (`mix test test/docs_contract/theming_contract_test.exs` — pass). |
| 2 | SHOW-01 rubric gap closed honestly and in order — DATA fixed first, THEN `default/0` applied, THEN re-scored with human sign-off; `passed:true` committed only on an honest clear | ✓ VERIFIED | Git-provable 3-commit honest order confirmed directly: `ad8439b` (Commit 1, test-only diff — `test/rendro/examples_data_test.exs` only) → `3c69937`/`4b06aa4` (Commit 2a, `lib/rendro/theme.ex` + recipe geometry, zero `priv/quality/` touched) → `be64152`/`53e1ba7` (Commit 2b, gallery only) → `5eda766` (Commit 3, score-flip, **only** `priv/quality/`, `priv/schemas/`, `test/docs_contract/` touched — verified via `git show --stat --name-only 5eda766`, grep for `lib/`/`assets/` returns nothing). `rubric_scores.json` has only ever been touched by `5eda766` in this phase's range (`git log -- priv/quality/rubric_scores.json`). `passed?/2` recomputation test (`rubric_manifest_contract_test.exs`) asserts recorded `passed` equals recomputation from `dimension_scores`/`gate_results` for every entry — passes. 5/6 demos honestly `passed:true`; Ticket honestly `passed:false` (content_hierarchy 3, typographic_craft 3) — NOT flattened. Sign-off teeth (`signed_off_by`/`signed_off_at`/`evidence_ref`, schema if/then + test loop) verified present and green. |
| 3 | Themed and dark gallery renders populate S6 `theme`/`mode` tags (hash-checked), each (recipe × mode) a distinct row, `preset` null | ✓ VERIFIED | `assets/rendro/artifacts.json` parsed directly: exactly 11 gallery rows (invoice, branded_invoice, statement, receipt_report, certificate, payslip, ticket, invoice_dark, certificate_dark, ticket_dark, invoice_brand). `theme` = "default" ×10 / "brand" ×1 (invoice_brand); `mode` = "light" ×8 / "dark" ×3; `preset` is JSON `null` on all 11. `mix test test/docs_contract/launch_artifacts_claims_test.exs` — pass (11-id assertion). |
| 4 | `support_matrix.json` gains proof-backed `theming.light`/`theming.dark` rows; `guides/theming.md` + claims test binds every theming claim to proof; docs-contract + Hex-tarball lanes stay green | ✓ VERIFIED | `priv/support_matrix.json` `theming.light.capabilities` includes `from_brand_accent_seed`/`on_accent_readable_default`/`brand_theme_orthogonal` (all `"supported"`); `theming.dark.boundaries` keeps `print_recommended`/`accessibility_pdf_ua_claim`/`wcag_contrast_claim` `"unsupported"` (no overclaim). `guides/theming.md` exists with the 11-row SHA-256 block — every `png_sha256`/`source_pdf_sha256` verified byte-for-byte identical to `assets/rendro/artifacts.json` (cross-checked programmatically). `mix test test/docs_contract/theming_claims_test.exs test/docs_contract/branding_claims_test.exs` — both green. `git diff d305a3f..HEAD -- mix.exs` shows only docs-extras wiring, zero `package.files` change (tarball lane untouched). |
| 5 | The named trap is avoided — no slick-palette-only change flipping the score | ✓ VERIFIED | `5eda766` (the score-flip commit) contains zero `lib/*.ex` and zero `assets/` paths — grep-confirmed empty. The only colour/theme code changes (`theme.ex` leading, palette unchanged) landed in earlier, separate commits (`3c69937`) that did NOT touch `rubric_scores.json`. Ticket's honest `passed:false` (a hierarchy *regression* the theme itself caused) proves the re-score was not rubber-stamped — the opposite of the trap. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/theme.ex` | `default/0` strong-default leading=1.35, colors unchanged | ✓ VERIFIED | Confirmed via direct Read: L79 `leading: 1.35`, L48-58 colors byte-identical to Phase-119 baseline description |
| `test/rendro/examples_data_test.exs` | DATA-survival test (Commit 1) | ✓ VERIFIED | Test present, passes; commit `ad8439b` is test-only |
| `assets/rendro/artifacts.json` | 11 hash-checked gallery rows | ✓ VERIFIED | 11 rows parsed, tags/preset correct |
| `guides/theming.md` | 3 executable from_brand fences + 11-row SHA block | ✓ VERIFIED | 3 `# docs-contract:` fences present in correct order; SHA block matches manifest exactly |
| `test/docs_contract/theming_contract_test.exs` | from_brand E2E gate | ✓ VERIFIED | Exists, executes fences, passes |
| `priv/quality/rubric_scores.json` | 6 demos re-scored, sign-off fields, passed recomputed | ✓ VERIFIED | All 6 records present with `signed_off_by`/`signed_off_at`/`evidence_ref`; Ticket honestly `false` |
| `priv/quality/SIGN-OFF.md` | SCORECARD house-style human sign-off | ✓ VERIFIED | Exists, dated, per-demo, "Honest not flattering" style, cites WINDOWS.md ids |
| `priv/schemas/rubric_scores.schema.json` | if/then requiring sign-off fields when passed==true | ✓ VERIFIED | `if`/`then` block present requiring `signed_off_by`/`signed_off_at`/`evidence_ref` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `priv/examples/invoice/.../invoice.json` | `ExamplesData.transform_invoice/1` | `put_optional` issuer/customer/totals | WIRED | `examples_data_test.exs` asserts non-nil, passes |
| `theme.ex @default_typography.leading` | every recipe `%Text{line_height}` | Phase-122 uniform seam | WIRED | Confirmed via 123-02's discovered-and-fixed Statement/Payslip overflow (proves the seam is live, not inert) |
| `@gallery_specs` entry | `build_source_document/1` clause | pdfium raster → `png_sha256` in artifacts.json | WIRED | 11/11 rows hash-verified present |
| `assets/rendro/artifacts.json` png_sha256 | `guides/theming.md` SHA block | drift guard test | WIRED | Programmatically cross-checked: all 11 hashes identical between the two files |
| themed gallery PNG (Commit 2) | `evidence_ref` in `rubric_scores.json` | `File.exists?` + manifest coverage | WIRED | Test-loop teeth (`rubric_manifest_contract_test.exs`) verified green; evidence_ref paths (`assets/rendro/gallery/*.png`) exist on disk |
| human judgment | `passed` field | `passed?/2` recomputation | WIRED | Test explicitly recomputes and asserts equality for every entry, including Ticket's `false` |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DEFAULT-01 | 123-02, 123-04 | Strong unbranded `default/0` + `from_brand/2` E2E | ✓ SATISFIED | leading=1.35 landed isolated; from_brand E2E proven by executable fences |
| DEFAULT-02 | 123-01, 123-05 | SHOW-01 rubric gap closed honestly in order | ✓ SATISFIED | 3-commit honest order git-provable; honest re-score with sign-off teeth |
| DEFAULT-03 | 123-03 | S6 gallery tags populated, hash-checked | ✓ SATISFIED | 11 rows, preset null, theme/mode literal and correct |
| CONTRACT-02 | 123-04 | support_matrix + guides/theming.md + claims test + tarball green | ✓ SATISFIED | All verified directly above |

All 4 phase requirement IDs (DEFAULT-01, DEFAULT-02, DEFAULT-03, CONTRACT-02) are accounted for across the 5 plans with no orphans. Cross-referenced against `.planning/REQUIREMENTS.md` traceability table (Phase 123 row: DEFAULT-01/02/03 + CONTRACT-02, all marked Complete) — consistent with plan frontmatter; no requirement mapped to Phase 123 in REQUIREMENTS.md is missing from a plan's frontmatter, and no plan claims a requirement not mapped to Phase 123.

### Anti-Patterns Found

Scanned all files touched by phase-123 commits (`git diff --name-only d305a3f..HEAD`) for `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`placeholder` markers: **none found.**

### Behavioral Spot-Checks / Test Execution

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| from_brand E2E fences execute | `mix test test/docs_contract/theming_contract_test.exs` | 0 failures | ✓ PASS |
| Theming claims/overclaim tripwire | `mix test test/docs_contract/theming_claims_test.exs` | 0 failures | ✓ PASS |
| DATA-survival (Commit 1) | `mix test test/rendro/examples_data_test.exs` | 0 failures | ✓ PASS |
| Rubric manifest contract (recompute + sign-off teeth) | `mix test test/docs_contract/rubric_manifest_contract_test.exs` | 0 failures | ✓ PASS |
| Gallery manifest (11 rows) | `mix test test/docs_contract/launch_artifacts_claims_test.exs` | 0 failures | ✓ PASS |
| Hex tarball lane | `mix test test/docs_contract/branding_claims_test.exs` | 0 failures | ✓ PASS |
| Industry-guard (CONTRACT-03 regression check) | `mix test test/docs_contract/theme_industry_guard_test.exs` | 0 failures | ✓ PASS |
| Full suite | `mix test --exclude quarantine` | 1699 tests, 2 failures (both `dx_local_reproducibility_claims_test.exs`, pre-existing/environmental, `git log` shows zero phase-123 commits touch that file) | ✓ PASS (net of pre-existing, out-of-scope failures) |
| Score-flip commit isolation | `git show --stat --name-only 5eda766` | Only `priv/quality/`, `priv/schemas/`, `test/docs_contract/` | ✓ PASS |
| `package.files` untouched | `git diff d305a3f..HEAD -- mix.exs` | No `package.files` change | ✓ PASS |
| Certificate hierarchy ratio | `21/16.5` | 1.2727... | ✓ PASS (matches claimed 1.27) |
| SHA drift guard (guide ↔ manifest) | programmatic cross-check of all 11 `png_sha256`/`source_pdf_sha256` pairs | identical byte-for-byte | ✓ PASS |

### Human Verification Required

None. All must-haves resolved to VERIFIED via direct codebase inspection and test execution; no items require additional human sign-off beyond the human checkpoint already completed and recorded in `123-05-SUMMARY.md` / `priv/quality/SIGN-OFF.md`.

### Gaps Summary

No gaps. All 5 observable truths, all 8 required artifacts, and all 6 key links verified directly against the codebase (not from SUMMARY.md claims). The phase's central discipline — the honest 3-commit order (DATA → theme → score) — is git-provably real: each commit's diff was inspected directly and matches the claimed isolation. The named trap (slick palette + rubber-stamped score) is demonstrably avoided: the score-flip commit contains zero colour/rendering code, and the honest re-score produced a genuine `passed:false` (Ticket) rather than a uniformly green result.

**Non-blocking context (informational, not a gap):** `.planning/WINDOWS.md` has 7 open findings. IDs 1-3 (Invoice dark-table illegibility, Ticket hierarchy inversion, Payslip numeric wrap) are honest, disclosed-not-hidden theming deviations discovered *by* this phase's own honest measurement work — consistent with, not contrary to, the phase's goal. IDs 4-7 are pre-existing/environmental (format debt in files untouched by phase 123, the 2 known dx_local_reproducibility failures, pre-existing dialyzer errors, missing `pdfium-cli` binary) and are correctly out of this phase's scope. These are recorded honestly rather than silently patched, matching the phase's stated ethos; they do not block the phase goal but will gate `/gsd-ship` per the existing WINDOWS.md discipline (a separate, already-tracked mechanism).

---

_Verified: 2026-07-28_
_Verifier: Claude (gsd-verifier)_
