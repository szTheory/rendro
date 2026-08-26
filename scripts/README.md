# Maintainer Helper Inventory

This is the authoritative inventory of retained tracked helpers under `scripts/`.
Each row has a current caller. A helper is removed when that caller, its stated
purpose, or its supported invocation is no longer present. Rows are ordered by
path so reviews and diagnostics remain stable.

## Authority boundaries

Helpers are maintainer tooling, not Rendro runtime APIs. They do not grant
product, release-fact, package, or ordinary-regression authority unless their
lane says so explicitly. `gsd_tooling` is narrower still: it may inspect
planning placement solely because that structure is its subject; it is never a
product, release, package, or ordinary-regression consumer.

`mix quality.hygiene` is the single canonical repository-hygiene command. The
former broad worktree wrapper has no compatibility alias or replacement script.

## Retained entry points

| Helper | Stable owner role | Purpose and supported invocation | Inputs / outputs | Authority lane | Current callers | Review / removal trigger |
| --- | --- | --- | --- | --- | --- | --- |
| `scripts/adoption_snapshot.exs` | adoption evidence maintainer | Capture the dated adoption snapshot: `mix run --require scripts/adoption_snapshot.exs -- --output PATH --date YYYY-MM-DD`. | GitHub read-only API facts -> redacted snapshot JSON. | advisory evidence | `test/docs_contract/adoption_evidence_contract_test.exs`. | Remove when the adoption gate/snapshot contract is retired. |
| `scripts/configurator_e2e/static-server.mjs` | catalog configurator maintainer | Serve the static configurator for the locked Playwright suite. | Catalog static files -> local HTTP responses. | regression | `scripts/configurator_e2e/playwright.config.mjs` and `npm test --prefix scripts/configurator_e2e`. | Remove with the static configurator browser contract. |
| `scripts/configurator_e2e/tests/configurator.spec.mjs` | catalog configurator maintainer | Exercise configurator breakpoints and visual states: `npm test --prefix scripts/configurator_e2e`. | Static configurator -> Playwright assertions and snapshots. | regression | `.github/workflows/ci.yml` required static-browser gate and package `test` script. | Remove with the browser contract; update snapshots only through its approved visual-review path. |
| `scripts/long_lived_viewer_proof_fixture.exs` | signing evidence maintainer | Generate the LTV viewer fixture: `mix run scripts/long_lived_viewer_proof_fixture.exs --output PATH`. | Signing fixture material -> LTV PDF fixture. | advisory evidence | `scripts/signing_viewer_proof_fixtures.exs`, `lib/rendro/viewer_evidence/recorder.ex`, and fixture documentation. | Remove when long-lived viewer proof is retired. |
| `scripts/pdfjs_observer/observe.mjs` | viewer evidence maintainer | Observe pinned PDF.js behavior: `node scripts/pdfjs_observer/observe.mjs --check`. | Pinned PDF.js inputs -> advisory observation JSON/check result. | advisory evidence | `mix ci.proofs`, `.github/workflows/ci.yml`, `mix verify`, and PDF.js docs-contract tests. | Remove when the pinned PDF.js advisory lane is retired. |
| `scripts/phoenix_clean_room_proof.exs` | Phoenix newcomer evidence maintainer | Run the bounded clean-room proof: `mix run scripts/phoenix_clean_room_proof.exs -- --prerequisite PATH --root PATH --output PATH`. | Capsule prerequisite and temporary project -> redacted advisory proof JSON. | advisory evidence | `.github/workflows/release.yml`, `test/scripts/phoenix_clean_room_proof_test.exs`, and public-release verifier tests. | Remove when the Phoenix newcomer proof contract is retired. |
| `scripts/protected_viewer_proof_fixture.exs` | protection evidence maintainer | Generate protected-viewer fixtures: `mix run scripts/protected_viewer_proof_fixture.exs --output PATH`. | Protection fixture material -> protected PDF fixture. | advisory evidence | `lib/rendro/viewer_evidence/recorder.ex` and viewer-evidence documentation. | Remove when protected-viewer proof is retired. |
| `scripts/quality_governance.cjs` | quality governance maintainer | Check active quality-governance state: `node scripts/quality_governance.cjs --check-active`. | Tracked governance records -> deterministic pass/fail diagnostics. | `gsd_tooling` | `mix quality.governance`, `mix ci.fast`, and quality-governance contract tests. | Remove only if the tracked governance contract is replaced; it may inspect planning only for this structural purpose. |
| `scripts/release_preflight_proof.exs` | release evidence maintainer | Build a clean release preflight proof: `mix run scripts/release_preflight_proof.exs --current-version-tag --skip-ci --skip-security-audits --worktree PATH`. | Git/tag/package facts and temporary worktree -> preflight proof result. | release evidence | `mix release.preflight`, `.github/workflows/ci.yml`, and release-preflight tests. | Remove when the release preflight contract is retired. |
| `scripts/signed_artifact_viewer_proof_fixture.exs` | signing evidence maintainer | Generate signed-artifact viewer fixture: `mix run scripts/signed_artifact_viewer_proof_fixture.exs --output PATH`. | Signing fixture material -> signed PDF fixture. | advisory evidence | `scripts/signing_viewer_proof_fixtures.exs`, `lib/rendro/viewer_evidence/recorder.ex`, and fixture documentation. | Remove when signed-artifact viewer proof is retired. |
| `scripts/signing_viewer_proof_fixtures.exs` | signing evidence maintainer | Orchestrate signed and LTV viewer fixture generation: `mix run scripts/signing_viewer_proof_fixtures.exs`. | Signing fixtures -> committed viewer-proof PDFs. | advisory evidence | Signing fixture documentation and the two child fixture scripts. | Remove when both signed and LTV viewer proof fixtures are retired. |
| `scripts/verify_docs.exs` | documentation contract maintainer | Verify documentation claims: `mix run scripts/verify_docs.exs`. | Public docs and support matrix -> deterministic docs-contract diagnostics. | regression | `mix docs.contract`, `mix ci.fast`, and docs-contract tests. | Remove only with replacement of the documentation contract. |
| `scripts/verify_livebook.exs` | Livebook tutorial maintainer | Convert/check a Livebook: `elixir scripts/verify_livebook.exs NOTEBOOK_PATH OUTPUT_PATH`. | Livebook source -> generated/checkable notebook artifact. | advisory evidence | `Rendro.Livebook.Check`, Livebook tests, and the advisory CI lane. | Remove when the Livebook tutorial is retired. |
| `scripts/verify_public_launch_urls.sh` | public launch maintainer | Poll approved public launch URLs: `scripts/verify_public_launch_urls.sh`. | Public GitHub/Hex/HexDocs URLs -> status/content check result. | advisory evidence | `.github/workflows/hexdocs.yml` and launch-execution contract tests. | Remove when public launch verification is retired. |
| `scripts/verify_public_release.exs` | release evidence maintainer | Verify public Hex/release identity facts: `mix run scripts/verify_public_release.exs`. | Public release responses and capsule facts -> redacted verification result. | advisory evidence | `test/scripts/public_release_verifier_test.exs` and the clean-room proof tests. | Remove when public-release identity verification is retired. |

## Retained support assets

| Helper asset | Stable owner role | Purpose / supported use | Inputs / outputs | Authority lane | Current callers | Review / removal trigger |
| --- | --- | --- | --- | --- | --- | --- |
| `scripts/configurator_e2e/.gitignore` | catalog configurator maintainer | Ignore local browser-test output. | Local Node output -> ignored files. | regression | `scripts/configurator_e2e` package scripts. | Remove with the static configurator browser contract. |
| `scripts/configurator_e2e/README.md` | catalog configurator maintainer | Documents the locked browser-test invocation. | Operator instructions -> reproducible execution. | regression | Catalog maintainers and the `configurator_e2e` package. | Remove with the static configurator browser contract. |
| `scripts/configurator_e2e/package-lock.json` | catalog configurator maintainer | Locks browser-test Node dependencies. | npm metadata -> reproducible dependency graph. | regression | `.github/workflows/ci.yml` and `npm ci --prefix scripts/configurator_e2e`. | Remove with the static configurator browser contract. |
| `scripts/configurator_e2e/package.json` | catalog configurator maintainer | Defines the browser-test commands. | npm metadata -> `npm test` commands. | regression | `.github/workflows/ci.yml` and catalog maintainers. | Remove with the static configurator browser contract. |
| `scripts/configurator_e2e/playwright.config.mjs` | catalog configurator maintainer | Configures the static server and browser runner. | Static configurator files -> Playwright run configuration. | regression | `scripts/configurator_e2e/tests/configurator.spec.mjs`. | Remove with the static configurator browser contract. |
| `scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/breakpoint-899-representative-linux.png` | catalog configurator maintainer | Approved 899px visual baseline. | Playwright screenshot -> comparison baseline. | regression | `scripts/configurator_e2e/tests/configurator.spec.mjs`. | Remove with its corresponding spec assertion. |
| `scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/breakpoint-900-none-linux.png` | catalog configurator maintainer | Approved 900px visual baseline. | Playwright screenshot -> comparison baseline. | regression | `scripts/configurator_e2e/tests/configurator.spec.mjs`. | Remove with its corresponding spec assertion. |
| `scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/desktop-dark-exact-linux.png` | catalog configurator maintainer | Approved desktop dark visual baseline. | Playwright screenshot -> comparison baseline. | regression | `scripts/configurator_e2e/tests/configurator.spec.mjs`. | Remove with its corresponding spec assertion. |
| `scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/desktop-light-exact-linux.png` | catalog configurator maintainer | Approved desktop light visual baseline. | Playwright screenshot -> comparison baseline. | regression | `scripts/configurator_e2e/tests/configurator.spec.mjs`. | Remove with its corresponding spec assertion. |
| `scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/mobile-dark-representative-linux.png` | catalog configurator maintainer | Approved mobile dark visual baseline. | Playwright screenshot -> comparison baseline. | regression | `scripts/configurator_e2e/tests/configurator.spec.mjs`. | Remove with its corresponding spec assertion. |
| `scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/mobile-loading-linux.png` | catalog configurator maintainer | Approved mobile loading-state baseline. | Playwright screenshot -> comparison baseline. | regression | `scripts/configurator_e2e/tests/configurator.spec.mjs`. | Remove with its corresponding spec assertion. |
| `scripts/configurator_e2e/tests/configurator.spec.mjs-snapshots/mobile-manifest-error-linux.png` | catalog configurator maintainer | Approved mobile manifest-error baseline. | Playwright screenshot -> comparison baseline. | regression | `scripts/configurator_e2e/tests/configurator.spec.mjs`. | Remove with its corresponding spec assertion. |
| `scripts/pdfjs_observer/package-lock.json` | viewer evidence maintainer | Locks PDF.js observer dependencies. | npm metadata -> reproducible observer install. | advisory evidence | `.github/workflows/ci.yml` and `scripts/pdfjs_observer/observe.mjs`. | Remove with the pinned PDF.js advisory lane. |
| `scripts/pdfjs_observer/package.json` | viewer evidence maintainer | Defines the PDF.js observer dependency contract. | npm metadata -> observer execution. | advisory evidence | `mix verify` and the PDF.js docs-contract tests. | Remove with the pinned PDF.js advisory lane. |
| `scripts/proof_requirements.in` | signing evidence maintainer | Human-maintained source for Python proof dependencies. | Requirement input -> locked requirements. | advisory evidence | `.github/workflows/ci.yml` long-lived proof lane. | Remove when the external signing proof lane is retired. |
| `scripts/proof_requirements.txt` | signing evidence maintainer | Hash-locked Python proof dependencies. | Locked requirements -> reproducible installation. | advisory evidence | `.github/workflows/ci.yml` long-lived proof lane. | Remove when the external signing proof lane is retired. |

## Removed ownerless scripts

The following files were removed after checking workflows, Mix aliases/tasks,
documentation, and focused tests. Historical mentions are not current callers.

| Removed helper | Reason |
| --- | --- |
| `scripts/audit_branch_protection.exs` | The Phase 72 close ritual is complete and there is no current workflow, Mix, docs, or focused-test caller. |
| `scripts/render_logo.exs` | No current workflow, Mix, docs, or focused-test caller exists. |
| `scripts/repo_hygiene_check.sh` | No current caller exists; it incorrectly rejected local debris and competed with the planned single `mix quality.hygiene` gate. |
