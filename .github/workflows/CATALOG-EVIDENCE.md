# Catalog Evidence

Run one bounded, read-only evidence job for one immutable Rendro commit. The
workflow is manual only. It does not join ordinary CI, `ci-success`, merge
approval, or release authority. Candidate generation and default-branch control
packaging run on separate runners with `permissions: contents: read` and
`persist-credentials: false`.

A successful `review` run exposes two separate 30-day artifacts: one
authoritative closed evidence bundle and one `authority: none` eight-image
reviewer packet. No secrets, caches, writes, workflow bridge, or attestation are
available. The packet never crosses into the trusted control job and never
records review, disposition, approval, or canonical eligibility.
Both review artifacts are retained for 30 days.

## Request evidence for one immutable commit

Choose a full lowercase commit SHA. Do not use a branch name, tag, prefix, or
shortened SHA.

```bash
FULL_SHA="$(git rev-parse HEAD)"
git rev-parse --verify "${FULL_SHA}^{commit}"
gh workflow run catalog-evidence.yml -f "candidate_sha=${FULL_SHA}" -f operation=review
```

Use `review` to collect candidate, final-review, multipage-review, preset-review,
and the separately bound reviewer packet. The workflow records this limit
exactly: Candidate evidence only — reviewer approval is not recorded here.

Use `canonical` only when the requested commit is the trusted default-branch
control SHA and you need the checked 32-cell payload for local,
human-authorized materialization:

```bash
FULL_SHA="$(git rev-parse HEAD)"
gh workflow run catalog-evidence.yml -f "candidate_sha=${FULL_SHA}" -f operation=canonical
```

The workflow records this limit exactly: Canonical evidence — materialize only after the catalog check passes.

Find the dispatched run, replace `RUN_ID`, and wait for it:

```bash
gh run list --workflow catalog-evidence.yml --limit 10
gh run watch RUN_ID
```

If dispatch rejects the request, correct the full SHA or operation and repeat
the same `gh workflow run` command. A renderer pin that is malformed JSON, has
the wrong key set or value type, or lacks a full lowercase SHA-256 fails before
PDFium is downloaded or any image is produced.

## Review one complete evidence bundle

Next: resolve the exact attempt and both artifact records, download fresh
archives, and Validate review bundle before opening the reviewer packet.

The evidence artifact naming contract is
`rendro-catalog-evidence--{operation}--{full_candidate_sha}--run-{run_id}--attempt-{run_attempt}`.

Derive the actual attempt from the run. Never assume attempt 1: a rerun may be
attempt 2 or later.

```bash
FULL_CANDIDATE_SHA=FULL_40_CHARACTER_CANDIDATE_SHA
RUN_ID=GITHUB_ACTIONS_RUN_ID
RUN_ATTEMPT=$(gh api "repos/OWNER/REPO/actions/runs/${RUN_ID}" --jq '.run_attempt')
test "${RUN_ATTEMPT}" -ge 1

EVIDENCE_NAME="rendro-catalog-evidence--review--${FULL_CANDIDATE_SHA}--run-${RUN_ID}--attempt-${RUN_ATTEMPT}"
PACKET_NAME="rendro-catalog-reviewer-packet--${FULL_CANDIDATE_SHA}--run-${RUN_ID}--attempt-${RUN_ATTEMPT}"
ARTIFACTS_JSON=$(gh api "repos/OWNER/REPO/actions/runs/${RUN_ID}/artifacts")
test "$(jq --arg name "${EVIDENCE_NAME}" '[.artifacts[] | select(.name == $name)] | length' <<<"${ARTIFACTS_JSON}")" = 1
test "$(jq --arg name "${PACKET_NAME}" '[.artifacts[] | select(.name == $name)] | length' <<<"${ARTIFACTS_JSON}")" = 1
```

Resolve and record each artifact independently. `Artifact URL` means the API
`archive_download_url`; `Archive digest` means the SHA-256 computed over the
downloaded archive bytes. The provider digest must equal that archive digest.

```bash
EVIDENCE_META=$(jq -c --arg name "${EVIDENCE_NAME}" '.artifacts[] | select(.name == $name) | {id,name,archive_download_url,digest}' <<<"${ARTIFACTS_JSON}")
PACKET_META=$(jq -c --arg name "${PACKET_NAME}" '.artifacts[] | select(.name == $name) | {id,name,archive_download_url,digest}' <<<"${ARTIFACTS_JSON}")

EVIDENCE_ID=$(jq -r '.id' <<<"${EVIDENCE_META}")
EVIDENCE_ARTIFACT_URL=$(jq -r '.archive_download_url' <<<"${EVIDENCE_META}")
EVIDENCE_PROVIDER_DIGEST=$(jq -r '.digest' <<<"${EVIDENCE_META}")
PACKET_ID=$(jq -r '.id' <<<"${PACKET_META}")
PACKET_ARTIFACT_URL=$(jq -r '.archive_download_url' <<<"${PACKET_META}")
PACKET_PROVIDER_DIGEST=$(jq -r '.digest' <<<"${PACKET_META}")
test "${EVIDENCE_ID}" != "${PACKET_ID}"
test "${EVIDENCE_NAME}" != "${PACKET_NAME}"
test "${EVIDENCE_ARTIFACT_URL}" != "${PACKET_ARTIFACT_URL}"
```

Do not use a bare `gh run download RUN_ID`, which can silently mix neighboring
artifacts. Download the two API archives into distinct new paths, hash each
archive, compare both provider digests, and only then extract them.

```bash
DOWNLOAD_ROOT="/tmp/rendro-catalog-review-${RUN_ID}-${RUN_ATTEMPT}"
EVIDENCE_DIR="${DOWNLOAD_ROOT}/evidence"
PACKET_DIR="${DOWNLOAD_ROOT}/packet"
EVIDENCE_ARCHIVE="${DOWNLOAD_ROOT}/evidence.zip"
PACKET_ARCHIVE="${DOWNLOAD_ROOT}/reviewer-packet.zip"
test ! -e "${DOWNLOAD_ROOT}"
test ! -e "${EVIDENCE_DIR}"
test ! -e "${PACKET_DIR}"
mkdir -p "${EVIDENCE_DIR}" "${PACKET_DIR}"
gh api -H 'Accept: application/vnd.github+json' "${EVIDENCE_ARTIFACT_URL}" > "${EVIDENCE_ARCHIVE}"
gh api -H 'Accept: application/vnd.github+json' "${PACKET_ARTIFACT_URL}" > "${PACKET_ARCHIVE}"
EVIDENCE_ARCHIVE_SHA256=$(sha256sum "${EVIDENCE_ARCHIVE}" | cut -d ' ' -f 1)
PACKET_ARCHIVE_SHA256=$(sha256sum "${PACKET_ARCHIVE}" | cut -d ' ' -f 1)
test "${EVIDENCE_PROVIDER_DIGEST}" = "sha256:${EVIDENCE_ARCHIVE_SHA256}"
test "${PACKET_PROVIDER_DIGEST}" = "sha256:${PACKET_ARCHIVE_SHA256}"
unzip -q "${EVIDENCE_ARCHIVE}" -d "${EVIDENCE_DIR}"
unzip -q "${PACKET_ARCHIVE}" -d "${PACKET_DIR}"
```

The evidence root contains only `README.md`, `manifest.json`,
`checksums.sha256`, and its closed payload roles. Before validating or reading
payload metadata, establish `CONTROL_SHA` from an independently trusted default-branch control record.
Do not derive it from the bundle. Validate from
that exact detached control checkout:

```bash
git checkout --detach CONTROL_SHA
mix deps.get
export BUNDLE_ROOT="${EVIDENCE_DIR}"
export OPERATION=review
export CONTROL_SHA=TRUSTED_DEFAULT_BRANCH_CONTROL_SHA
mix run -e '
  Code.require_file("dev/rendro/catalog_evidence_bundle.ex")
  case Rendro.CatalogEvidenceBundle.validate(System.fetch_env!("BUNDLE_ROOT"), System.fetch_env!("OPERATION"), System.fetch_env!("CONTROL_SHA")) do
    :ok -> IO.puts("Catalog evidence bundle VERIFIED")
    {:error, reasons} -> Mix.raise("Catalog evidence bundle failed validation: #{inspect(reasons)}")
  end
'
```

Check the candidate SHA, checked-out HEAD, distinct control SHA, run ID, live run
attempt, closed role order/counts, safe paths, full hashes, and checked-in
`priv/pdfium_pin.json`. Remote Ubuntu/PDFium alone proves raster identity.
Phase 136 alone owns visual judgment. If
`Rendro.CatalogEvidenceBundle.validate/3` fails, stop: do not interpret a packet
or open an image. The trusted control argument is always required.

## Review the bound eight-image reviewer packet

Validate the evidence bundle first, then bind the authority-none packet to that
validated bundle before opening any image:

```bash
mix rendro.catalog.gallery \
  --validate-intake "${PACKET_DIR}" \
  --bundle "${BUNDLE_ROOT}" \
  --control-sha "${CONTROL_SHA}"
```

The committed build command used by the workflow is:

```bash
mix rendro.catalog.gallery \
  --candidate-manifest tmp/phase130-candidate/candidate-manifest.json \
  --final-manifest handoff/final-manifest.json \
  --output tmp/catalog-reviewer-packet
```

The packet manifest must say `authority: none`, repeat the same exact
candidate/control/run/attempt/renderer facts, and contain these eight roles in
this order with full PNG and source-PDF hashes:

1. `invoice_light_control`
2. `invoice_dark_target`
3. `statement_light_control`
4. `statement_dark_target`
5. `payslip_light_target`
6. `payslip_dark_target`
7. `ticket_light_target`
8. `ticket_dark_target`

Invoice-light and Statement-light are comparison controls; the other six are
targets. This preserves the family order Invoice light → dark, Statement light → dark, Payslip light → dark, Ticket light → dark.
Only after both validators
return success may the reviewer open full-size images:

```bash
open "${PACKET_DIR}/index.html"
```

The packet is navigation and presentation only, not an
automated visual score. If no named human review is supplied, continue with explicit deferral
and leave targets unpromoted.

## Validate review bundle

**Review bundle empty:** there is no review authority. Dispatch a new exact-SHA
`review` run and leave every affected cell unreviewed and unpromoted.

**Review bundle loading:** downloaded files are ineligible until evidence-first
validation completes against the independently trusted control SHA, checkout,
and checked-in PDFium pin.

**Review bundle error:** report the stable manifest, checksum, identity, pin,
role, count, artifact ambiguity, or packet-binding diagnostic. Correct it and
run a new exact-SHA dispatch before looking at images.

**Review bundle populated:** one valid closed bundle plus its uniquely matched
eight-image packet is the happy path. Thumbnails and prior hashes are navigation
aids, never review authority.

**Review bundle partial:** a missing control, target, score, reading order,
reviewer identity, rationale, role, count, provenance field, or hash keeps the
affected cell unreviewed and unpromoted.

**Review bundle overflow:** do not crop full-size images or abbreviate machine
identities to fit a display.

**Review bundle zero/one/many:** exactly one evidence artifact and one distinct
packet artifact must resolve for the exact run attempt. Zero or multiple matches
are controlled failures.

**Review bundle long text:** retain concise reviewer rationale and complete
machine identities/digests.

After deterministic validation, human review remains advisory. A visual
threshold is hierarchy `5` and every other visual dimension at least `4`;
`print_safety: false` remains a screen-only boundary and does not become a pass.
Never synthesize, round, clamp, average, or infer reviewer scores.

## Record the machine-readable receipt

Plans 12 and 13 consume `136-12-RECEIPT.json`. A `complete` receipt records the
candidate and control SHAs, renderer version/digest/DPI, run ID and attempt, the
two distinct artifacts (`id`, `name`, `url`, `provider_digest`, and
`archive_sha256`), the four closed evidence roles, eight packet image bindings,
and both validation results. An `unavailable` receipt records the same attempted
identity, explicit failure (`stage`, `code`, `message`, `expected`, `observed`,
and `next_action`), all targets unpromoted, and the bounded Revision Gate.

The `revision_gate` object uses integer `iteration`, `prior_receipt_ids`, status,
and `cap: 3`. Attempts one through three may be `retry_required`; after the
third failed or unavailable evidence/review attempt the status is `escalated`.
No filename, artifact name, shortened hash, or stale neighboring run can fill a
missing receipt field.

## Consume the stable bundle contract in Phase 136

Phase 136 consumes validated closed roles, hashes, control/candidate identity,
renderer pin, live run attempt, independent artifact identities/digests, and the
30-day transport boundary. It does not infer visual quality, approval, release
authority, attestation, or a required merge context from workflow success.

## Audit the control plane and diagnose failures

Inspect the trusted workflow and pin before dispatching:

```bash
sed -n '1,280p' .github/workflows/catalog-evidence.yml
cat priv/pdfium_pin.json
mix test test/guardrails/required_checks_contract_test.exs --max-failures 1
```

Reproduce deterministic candidate checks locally:

```bash
git checkout --detach FULL_SHA
mix deps.get
mix rendro.catalog.candidate
RENDRO_CATALOG_REVIEW_DIR=tmp/catalog-evidence-review mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs
mix rendro.catalog.gen
mix rendro.catalog.check
mix ci.fast
```

Common failure boundaries and next commands:

- Invalid input: correct the full SHA or operation, then re-run `gh workflow run`.
- Candidate/HEAD or control mismatch: inspect `git rev-parse HEAD` and the trusted
  default-branch control record.
- PDFium pin mismatch: validate the exact JSON key/type/hash contract and compare
  `sha256sum "$(command -v pdfium-cli)"` with `priv/pdfium_pin.json`.
- Missing, unsafe, reordered, partial, or ambiguous roles: run
  `Rendro.CatalogEvidenceBundle.validate` again before packet validation.
- Upload failure: inspect `gh run view RUN_ID --log-failed`, then dispatch a new
  run for the same immutable SHA after the failure is understood.

Run the docs contract whenever this runbook changes:

```bash
mix test test/docs_contract/catalog_evidence_runbook_test.exs --max-failures 1
mix run scripts/verify_docs.exs
```
