---
phase: 91-pdf-js-advisory-proof-lane
verified: 2026-06-13T03:23:56Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
---

# Phase 91: PDF.js Advisory Proof Lane Verification Report

**Phase Goal:** Add pinned PDF.js advisory observations for committed fixtures, keep the lane advisory and graph-disconnected, and prevent PDF.js observations from becoming GUI-viewer support claims.
**Verified:** 2026-06-13T03:23:56Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Maintainers can run `node scripts/pdfjs_observer/observe.mjs --check` without invoking Mix or core runtime code | VERIFIED | `scripts/pdfjs_observer/observe.mjs:1-254` is a Node ESM CLI; `node scripts/pdfjs_observer/observe.mjs --check` passed and printed checks for both observation files. |
| 2 | The observer records exact pdfjs-dist version, Node version, page count, page dimensions, warnings, and errors for committed fixtures | VERIFIED | `observe.mjs:183-197` records version, node, platform, fixture, page count, pages, warnings, and errors; `priv/pdfjs_observations/*.json` contain `pdfjs_dist_version: "6.0.227"`, `node_version`, two pages each, dimensions, `warnings: []`, and `errors: []`. |
| 3 | `pdfjs-dist` is exact-pinned under `scripts/pdfjs_observer` and never added to `mix.exs`, Mix deps, required CI, or Hex package files | VERIFIED | `package.json:14-16` pins `"pdfjs-dist": "6.0.227"`; lockfile root and package entry both resolve `6.0.227`; `mix.exs:42-60` contains no pdfjs dependency and `mix.exs:77-95` package files exclude `scripts/` and `priv/pdfjs_observations`. |
| 4 | Committed observations live under `priv/pdfjs_observations` as compact advisory evidence, not support-matrix promotion rows | VERIFIED | Observation files live under `priv/pdfjs_observations/`; `priv/support_matrix.json` PDF.js rows remain `explicit_deferral` with no `evidence`, `recorded_at`, `viewer_kind`, or `proof`. |
| 5 | The `pdfjs-advisory` CI job is graph-disconnected, `continue-on-error`, and listed only under `advisory_contexts` | VERIFIED | `.github/workflows/ci.yml:124-144` defines `pdfjs-advisory` with `continue-on-error: true` and no `needs:`; `priv/guardrails/required_status_checks.json:76-82` lists it only in `advisory_contexts`, and it is absent from `required_contexts:7-12`. |
| 6 | The required `test` job contains no Node/npm/pdfjs observer setup | VERIFIED | `.github/workflows/ci.yml:12-29` runs checkout, Beam setup, `mix deps.get`, and `mix ci`; guardrail test `test/guardrails/required_checks_contract_test.exs:191-221` bans `setup-node`, `npm`, `pdfjs`, `pdfjs-dist`, and `pdfjs_observer` in that block. |
| 7 | Public docs do not contain unqualified PDF.js support claims | VERIFIED | `rg` found banned phrases only inside the docs-contract test definitions; `test/docs_contract/pdfjs_advisory_claims_test.exs:116-133` enforces the public-doc ban. |
| 8 | Existing PDF.js viewer rows for forms, signature widgets, signing preparation, signed artifacts, and long-lived signatures remain explicit deferral rows without promotion fields | VERIFIED | Direct `jq` check confirmed all five PDF.js rows are `explicit_deferral`; tests cover forms at `forms_claims_test.exs:103-117`, signing at `signing_claims_test.exs:126-140`, and all rows at `pdfjs_advisory_claims_test.exs:135-148`. |
| 9 | First-page PNG hashes are deferred unless deterministic proof is added in a future phase | VERIFIED | `observe.mjs` does not render PNGs or emit `first_page_png_sha256`; `schema.json:91-94` permits the field only as optional 64-hex if future proof is added; committed observations omit the key. |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/pdfjs_observer/observe.mjs` | Pinned PDF.js advisory observer with `--check` | VERIFIED | Substantive CLI with fixture allowlist, `pdfjs-dist/legacy/build/pdf.mjs`, warning/error capture, write/check modes, stable-fact comparison. |
| `scripts/pdfjs_observer/package.json` | Maintainer-only npm boundary with exact `pdfjs-dist` pin | VERIFIED | Private ESM package, Node engine `>=22.13.0 || >=24`, exact dependency `6.0.227`. |
| `scripts/pdfjs_observer/package-lock.json` | Exact lockfile | VERIFIED | Root dependency and `node_modules/pdfjs-dist` package entry both resolve `6.0.227`. |
| `priv/pdfjs_observations/schema.json` | Project-owned observation schema | VERIFIED | Requires advisory fields, version pin, fixture enum, positive page counts/dimensions, warning/error arrays; optional PNG hash pattern only. |
| `priv/pdfjs_observations/embedded_artifact_support_fixture.json` | Committed observation for embedded artifact fixture | VERIFIED | Fixture path is repo-relative; page count 2; two 612x792 pages; warnings/errors arrays present. |
| `priv/pdfjs_observations/bench_rendro_invoice.json` | Committed observation for invoice fixture | VERIFIED | Fixture path is repo-relative; page count 2; two 595.28x841.89 pages; warnings/errors arrays present. |
| `test/docs_contract/pdfjs_advisory_claims_test.exs` | Docs/package/support-matrix guardrails | VERIFIED | Checks private package, lockfile pin, observation shape, banned public wording, deferral rows, docs lane registration. |
| `scripts/verify_docs.exs` | Explicit docs-contract lane registration | VERIFIED | Includes exactly one `"PDF.js advisory claims lane"` at lines 27-28 and all 21 lanes passed. |
| `.github/workflows/ci.yml` | Advisory-only CI job | VERIFIED | `pdfjs-advisory` is separate, non-blocking, and has no `needs:` edge. |
| `priv/guardrails/required_status_checks.json` | Advisory context registration | VERIFIED | `pdfjs-advisory` appears in `advisory_contexts`, not `required_contexts`. |
| `test/guardrails/required_checks_contract_test.exs` | Required/advisory CI separation checks | VERIFIED | Tests assert required lane purity, `pdfjs-advisory` non-blocking topology, and Node setup only in advisory job. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `scripts/pdfjs_observer/package.json` | `scripts/pdfjs_observer/observe.mjs` | exact `pdfjs-dist` dependency | WIRED | `gsd-sdk query verify.key-links` found `pdfjs-dist`; code imports `pdfjs-dist/legacy/build/pdf.mjs`. |
| `scripts/pdfjs_observer/observe.mjs` | `priv/pdfjs_observations/*.json` | `--write` and `--check` observation contract | WIRED | Fixture allowlist maps each PDF to a committed JSON output; `--check` compares stable facts. |
| `.github/workflows/ci.yml` | `priv/guardrails/required_status_checks.json` | `pdfjs-advisory` context name | WIRED | CI job and advisory context both use `pdfjs-advisory`; guardrail tests assert alignment. |
| `scripts/verify_docs.exs` | `test/docs_contract/pdfjs_advisory_claims_test.exs` | explicit docs-contract lane | WIRED | Lane registration points to the exact test file and `mix run scripts/verify_docs.exs` passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `observe.mjs` | `page_count`, `pages`, `warnings`, `errors` | `pdfjsLib.getDocument`, `doc.numPages`, `doc.getPage`, `page.getViewport`, captured `console.warn/error` | Yes | FLOWING |
| `priv/pdfjs_observations/*.json` | Stable observation facts | Output from `observe.mjs --write`, revalidated by `observe.mjs --check` | Yes | FLOWING |
| `pdfjs_advisory_claims_test.exs` | Observation/support-matrix/doc assertions | Reads package, lockfile, schema, observation JSON, public docs, support matrix | Yes | FLOWING |
| `required_checks_contract_test.exs` | CI and guardrail assertions | Reads `.github/workflows/ci.yml`, `priv/guardrails/required_status_checks.json`, `scripts/verify_docs.exs` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Install observer dependencies from lockfile | `npm ci --prefix scripts/pdfjs_observer` | Added/audited 3 packages; 0 vulnerabilities | PASS |
| Check committed observations against current PDF.js output | `node scripts/pdfjs_observer/observe.mjs --check` | Checked both committed observation JSON files | PASS |
| Focused PDF.js docs/guardrail tests | `mix test test/docs_contract/pdfjs_advisory_claims_test.exs test/guardrails/required_checks_contract_test.exs` | 25 tests, 0 failures | PASS |
| Existing forms/signing/viewer deferral posture | `mix test test/docs_contract/forms_claims_test.exs test/docs_contract/signing_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs` | 34 tests, 0 failures | PASS |
| Full docs-contract lanes | `mix run scripts/verify_docs.exs` | 21 lanes passed; `Docs contract VERIFIED!` | PASS |
| Full project CI | `mix ci` | 12 doctests, 4 properties, 1180 tests, 0 failures; credo no issues; dialyzer total errors 0 | PASS |

### Probe Execution

No Phase 91 probe scripts were declared or discovered. Step 7c skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PDFJS-01 | `91-01-PLAN.md` | Maintainers can run a pinned PDF.js advisory observer that records renderer version, Node version, page count, page dimensions, warnings, and optional first-page PNG hash for committed fixtures. | SATISFIED | Exact-pinned Node observer exists and `--check` passed; committed observations include required metadata and facts; PNG hash is optional and deferred. |
| PDFJS-02 | `91-01-PLAN.md` | The PDF.js observer runs only in graph-disconnected advisory CI and cannot block required engine lanes or promote GUI-viewer claims. | SATISFIED | CI job has no `needs:`, is `continue-on-error`, installs Node only in `pdfjs-advisory`; guardrail JSON lists it only under advisory contexts; required test block has no Node/npm/pdfjs fragments. |
| PDFJS-03 | `91-01-PLAN.md` | Support matrix and docs-contract checks keep PDF.js wording narrow and preserve existing PDF.js deferrals for forms, signatures, and long-lived signatures unless exact proof rows pass. | SATISFIED | Docs-contract tests ban unqualified PDF.js support wording and assert all PDF.js rows remain explicit deferrals without promotion fields. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `scripts/pdfjs_observer/observe.mjs` | 41, 214, 237 | `console.log` | INFO | Intentional CLI output for help/write/check status, not a stub. |
| `test/docs_contract/forms_claims_test.exs` | 12, 54, 57, 60 | `placeholder` wording | INFO | Existing signature-placeholder contract language, not incomplete implementation. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers found in Phase 91 modified files.

### Human Verification Required

None. The phase contract is repo-verifiable. Live GitHub branch-protection settings remain outside repository-state verification and are listed as residual risk rather than a phase blocker.

### Residual Risks

- Repository guardrails prove intended required/advisory context separation, but they do not query live GitHub branch-protection settings.
- PDF.js observations record metadata/page geometry only. They intentionally do not prove GUI viewer behavior or visual rendering correctness.
- `mix ci` still emits existing non-failing documentation/reference warnings and viewer-evidence staleness noise; these are outside Phase 91 and did not fail the gate.

### Gaps Summary

No blocking gaps found. PDFJS-01, PDFJS-02, and PDFJS-03 are satisfied by substantive implementation, tests, and CI/docs wiring.

### Commands Run

```text
cat .planning/phases/91-pdf-js-advisory-proof-lane/*-VERIFICATION.md 2>/dev/null
gsd-sdk query roadmap.get-phase 91 --raw
grep -n -A 80 -B 10 -E 'PDFJS-0[1-3]|Phase 91|91\b|pdf-js-advisory-proof-lane' .planning/REQUIREMENTS.md .planning/ROADMAP.md
gsd-sdk query verify.artifacts .planning/phases/91-pdf-js-advisory-proof-lane/91-01-PLAN.md
gsd-sdk query verify.key-links .planning/phases/91-pdf-js-advisory-proof-lane/91-01-PLAN.md
jq '{forms_pdfjs:.forms.viewers.pdfjs, forms_sig_pdfjs:.forms.signature_widget_viewers.pdfjs, signing_prep_pdfjs:.signing_preparation.viewers.pdfjs, signing_pdfjs:.signing.viewers.pdfjs, long_lived_pdfjs:.signing.long_lived.viewers.pdfjs}' priv/support_matrix.json
rg -n "PDF\.js support|PDF\.js is supported|supports PDF\.js|PDF\.js viewer support|PDF\.js GUI support" README.md guides priv/support_matrix.json CHANGELOG.md test scripts .github mix.exs --glob '!node_modules/**' --glob '!deps/**' --glob '!_build/**'
rg -n "pdfjs-dist|scripts/pdfjs_observer|setup-node|\bnpm\b|\bnode\b" mix.exs mix.lock .formatter.exs .github/workflows/ci.yml priv/guardrails/required_status_checks.json scripts/verify_docs.exs test/docs_contract test/guardrails
node -e "const p=require('./scripts/pdfjs_observer/package-lock.json'); console.log(p.packages[''].dependencies['pdfjs-dist']); console.log(p.packages['node_modules/pdfjs-dist'].version);"
npm ci --prefix scripts/pdfjs_observer
node scripts/pdfjs_observer/observe.mjs --check
mix test test/docs_contract/pdfjs_advisory_claims_test.exs test/guardrails/required_checks_contract_test.exs
mix test test/docs_contract/forms_claims_test.exs test/docs_contract/signing_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs
mix run scripts/verify_docs.exs
mix ci
rg -n "TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER|placeholder|coming soon|not yet implemented|not available|return null|return \{\}|return \[\]|=> \{\}|console\.log" <phase-91-files>
find scripts -path '*/tests/probe-*.sh' -type f -print
gsd-sdk query roadmap.analyze --raw
git status --short
```

---

_Verified: 2026-06-13T03:23:56Z_
_Verifier: the agent (gsd-verifier)_
