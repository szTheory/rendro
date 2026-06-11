---
phase: 85
slug: deterministic-raster-lane
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-11
---

# Phase 85 - Security

Per-phase security contract: threat register, accepted risks, and audit trail for the deterministic raster lane.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| filesystem -> priv/raster_refs/ | Hash reference files are committed ground truth for raster comparisons. | PNG SHA-256 digests |
| priv/pdfium_pin.json -> CI install step | The pin file and CI job must agree on pdfium-cli version and SHA-256. | Binary version and digest |
| caller -> Rendro.Adapters.Pdfium.render/2 | PDF binaries and render opts are untrusted inputs. | PDF bytes, dpi, pages |
| render/2 -> pdfium-cli | The adapter invokes an external executable. | argv list and temporary file paths |
| tmp dir -> filesystem | Raster input/output files are created per invocation and removed after use. | Private input PDF and PNG outputs |
| priv/support_matrix.json -> JSV validator | Matrix shape must preserve viewer-row validation. | JSON support claims |
| viewer_kind schema -> validator.ex | Schema enum and runtime validator vocabulary must remain aligned. | Viewer evidence labels |
| GitHub Actions raster-advisory -> required engine lanes | Advisory raster evidence must not block deterministic engine CI. | CI job graph and status policy |
| pdfium-cli download -> binary execution | Downloaded binary must be hash-verified before execution. | External binary |
| pdfium-cli binary -> rendered PNG bytes | Raster bytes are trusted only from the pinned Linux binary. | PNG output bytes |
| CI/container bless command -> committed refs | Ref updates must be restricted to the pinned CI environment. | SHA-256 ref writes |
| committed refs -> support matrix claims | Determinism claim is truthful only if matrix hash equals committed ref. | Matrix evidence pointer and digest |
| support_matrix.schema.json -> GUI-viewer evidence rows | GUI-viewer rows must reject engine-only raster labels. | JSON schema validation |
| validator.ex -> promotion-complete claims | Runtime promotion checks must use GUI-viewer-only vocabulary. | Promotion-complete validation |
| caller pages option -> pdfium-cli argv | Page range input must be constrained before becoming an argv token. | Page range string |
| pdfium-cli output files -> returned PNG list | Page order is a semantic contract for returned PNGs. | page_N.png files |
| private temp input file -> filesystem | Existing files in the private tmp dir must fail closed. | input.pdf write |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-85-01 | Tampering | Committed raster hash refs | mitigate | Hash refs are committed under `priv/raster_refs/`; raster snapshot test compares rendered PNG hashes to committed refs; bless path is CI-guarded. Evidence: `test/rendro/adapters/pdfium_raster_snapshot_test.exs:28`, `test/rendro/adapters/pdfium_raster_snapshot_test.exs:72`, `priv/raster_refs/forms_support_fixture/page_1.sha256`. | closed |
| T-85-02 | Spoofing | `MIX_RASTER_BLESS=true` bless path | mitigate | Blessing raises unless `GITHUB_ACTIONS=true`, with a normal test covering the guard. Evidence: `test/rendro/adapters/pdfium_raster_snapshot_test.exs:11`, `test/rendro/adapters/pdfium_raster_snapshot_test.exs:52`. | closed |
| T-85-03 | Tampering | `priv/pdfium_pin.json` SHA-256 value | mitigate | Pin file records the expected version/digest and docs-contract test checks exact values. Evidence: `priv/pdfium_pin.json:1`, `test/docs_contract/raster_claims_test.exs:17`. | closed |
| T-85-04 | Information Disclosure | Temporary input PDF file | mitigate | Raster tmp dir is chmod 0700, input write uses exclusive mode and chmod 0600, and tmp dir is removed in `after`. Evidence: `lib/rendro/adapters/pdfium.ex:80`, `lib/rendro/adapters/pdfium.ex:117`, `lib/rendro/adapters/pdfium.ex:132`. | closed |
| T-85-05 | Tampering | `:pdfium_cli_executable_finder` binary injection | accept | Accepted as a privileged test hook. Production default remains `System.find_executable/1`; no public API exposes finder injection. Evidence: `lib/rendro/adapters/pdfium.ex:183`, accepted risk AR-85-01. | closed |
| T-85-06 | Elevation of Privilege | Command injection through `dpi` or `pages` args | mitigate | `dpi` must be a positive integer, `pages` must match numeric page-range grammar, args are list-form tokens, and command execution uses `System.cmd/3` runner contract without shell interpolation. Evidence: `lib/rendro/adapters/pdfium.ex:10`, `lib/rendro/adapters/pdfium.ex:76`, `lib/rendro/adapters/pdfium.ex:151`, `lib/rendro/adapters/pdfium.ex:210`. | closed |
| T-85-07 | Tampering | pdfium-cli binary download in CI | mitigate | `raster-advisory` downloads the pinned v0.11.0 WASM binary and runs `sha256sum --check` before chmod and install. Evidence: `.github/workflows/ci.yml:64`, `.github/workflows/ci.yml:69`, `priv/pdfium_pin.json:1`. | closed |
| T-85-08 | Information Disclosure | `pdfium-render` on GUI-viewer rows | mitigate | Raster evidence uses `pdfium-render` only in top-level raster evidence; GUI-viewer rows are tested to reject that value. Evidence: `priv/support_matrix.json:483`, `test/docs_contract/raster_claims_test.exs:47`, `test/docs_contract/raster_claims_test.exs:70`. | closed |
| T-85-09 | Tampering | Raster section misclassified inside viewer map | mitigate | Raster evidence is top-level `raster`, viewer row schema remains separate, and no `priv/viewer_evidence/raster/` directory exists. Evidence: `priv/support_matrix.json:483`, `priv/schemas/support_matrix.schema.json:13`, filesystem check during audit. | closed |
| T-85-10 | Tampering | Schema enum and runtime viewer kinds diverge | mitigate | GUI-viewer schema enum and `@viewer_kinds` both exclude `pdfium-render`, and mutation test verifies schema and validator rejection. Evidence: `priv/schemas/support_matrix.schema.json:113`, `lib/rendro/viewer_evidence/validator.ex:15`, `test/docs_contract/raster_claims_test.exs:70`. | closed |
| T-85-11 | Denial of Service | Advisory raster lane blocks required engine merges | mitigate | `raster-advisory` has `continue-on-error: true`, no job-local `needs:`, and is registered only as advisory. Evidence: `.github/workflows/ci.yml:50`, `.github/workflows/ci.yml:52`, `priv/guardrails/required_status_checks.json:40`. | closed |
| T-85-12 | Tampering | `raster-advisory` added to required contexts | mitigate | Guardrails required contexts exclude `raster-advisory`; docs-contract test asserts the absence. Evidence: `priv/guardrails/required_status_checks.json:7`, `test/docs_contract/raster_claims_test.exs:29`. | closed |
| T-85-13 | Tampering | Golden PNG ref generation | mitigate | Ref generation is CI-guarded, hashes are computed with SHA-256, and committed refs are verified by raster snapshot test. Evidence: `test/rendro/adapters/pdfium_raster_snapshot_test.exs:52`, `test/rendro/adapters/pdfium_raster_snapshot_test.exs:88`, `priv/raster_refs/forms_support_fixture/page_1.sha256`. | closed |
| T-85-14 | Repudiation | Matrix determinism claim | mitigate | Matrix evidence includes committed ref path and PNG SHA-256; docs-contract test requires the matrix digest to equal the committed ref. Evidence: `priv/support_matrix.json:496`, `test/docs_contract/raster_claims_test.exs:91`. | closed |
| T-85-15 | Denial of Service | Advisory raster lane evidence drift | accept | Accepted by design: raster evidence drift is advisory and must not block required engine lanes. Evidence: `.github/workflows/ci.yml:52`, accepted risk AR-85-02. | closed |
| T-85-16 | Information Disclosure | GUI-viewer rows using `pdfium-render` | mitigate | Schema enum and validator vocabulary reject `pdfium-render` for viewer rows; mutation test verifies the rejection path. Evidence: `priv/schemas/support_matrix.schema.json:113`, `lib/rendro/viewer_evidence/validator.ex:17`, `test/docs_contract/raster_claims_test.exs:70`. | closed |
| T-85-17 | Tampering | Page range argument injection | mitigate | Page ranges must match the numeric grammar before args are built; test proves `--help` is rejected before invoking the runner. Evidence: `lib/rendro/adapters/pdfium.ex:10`, `lib/rendro/adapters/pdfium.ex:95`, `test/rendro/adapters/pdfium_test.exs:48`. | closed |
| T-85-18 | Tampering | Page order in golden hashes | mitigate | Rendered PNG files are sorted by numeric page suffix, with a test covering page 1, 2, 10 ordering. Evidence: `lib/rendro/adapters/pdfium.ex:163`, `lib/rendro/adapters/pdfium.ex:176`, `test/rendro/adapters/pdfium_test.exs:69`. | closed |
| T-85-19 | Tampering | Private input overwrite | mitigate | Private input uses `File.write/3` with `:exclusive`; audit confirmed no pre-write `File.rm(path)` remains. Evidence: `lib/rendro/adapters/pdfium.ex:132`, `lib/rendro/adapters/pdfium.ex:145`. | closed |
| T-85-SC | Tampering | Package or binary installation drift | accept | Plan-wide package-manager risk accepted for no new package installs in Phase 85; binary-specific risk is mitigated by T-85-07 and T-85-13. Evidence: Phase 85 commit history did not touch `mix.exs` or `mix.lock`; `priv/pdfium_pin.json:1`; accepted risk AR-85-03. | closed |

Status: open or closed.
Disposition: mitigate (implementation required), accept (documented risk), or transfer (third-party).

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-85-01 | T-85-05 | The executable finder is a test hook controlled through application env. Altering it in production already requires privileged runtime/config access; production default uses `System.find_executable/1`. | Plan-time disposition, verified by Codex inline security audit | 2026-06-11 |
| AR-85-02 | T-85-15 | The raster lane is intentionally advisory. Failures expose raster evidence drift without blocking deterministic engine lanes or required merge contexts. | Plan-time disposition, verified by Codex inline security audit | 2026-06-11 |
| AR-85-03 | T-85-SC | Phase 85 introduced no new package-manager installs. The only binary path is handled by the pinned pdfium-cli download and committed hash evidence. | Plan-time disposition, verified by Codex inline security audit | 2026-06-11 |

Accepted risks do not resurface in future audit runs.

---

## Summary Threat Flags

No `## Threat Flags` sections were present in the Phase 85 plan summaries. The summary threat-surface scans reported no unregistered network endpoints or auth paths; file-system and CI changes map to declared threats T-85-01 through T-85-19 and T-85-SC.

---

## Security Audit 2026-06-11

| Metric | Count |
|--------|-------|
| Threats found | 20 |
| Closed | 20 |
| Open | 0 |
| Unregistered flags | 0 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-11 | 20 | 20 | 0 | Codex inline gsd-security-auditor fallback |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

Approval: verified 2026-06-11
