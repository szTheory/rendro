# Catalog Evidence

Run one bounded, read-only evidence job for one immutable Rendro commit. The
workflow is manual only. It does not join ordinary CI, `ci-success`, merge
approval, or release authority.

Candidate generation and default-branch control packaging run in separate jobs
on separate runners. The requested candidate is credential-free input; it can
only cross into the trusted default-branch control job through a bounded,
validated artifact handoff. The final job uploads one 30-day evidence bundle.

## Request evidence for one immutable commit

Choose a full lowercase commit SHA. Do not use a branch name, tag, or shortened
SHA.

```bash
FULL_SHA="$(git rev-parse HEAD)"
git rev-parse --verify "${FULL_SHA}^{commit}"

gh workflow run catalog-evidence.yml -f "candidate_sha=${FULL_SHA}" -f operation=review
```

Use `review` to collect candidate, final-review, and multipage-review evidence.
The workflow records this limit exactly: Candidate evidence only — reviewer approval is not recorded here.

Use `canonical` only when you need the checked 32-cell canonical payload for
local, human-authorized materialization:

```bash
FULL_SHA="$(git rev-parse HEAD)"
gh workflow run catalog-evidence.yml -f "candidate_sha=${FULL_SHA}" -f operation=canonical
```

The workflow records this limit exactly: Canonical evidence — materialize only after the catalog check passes.

Find the dispatched run, replace `RUN_ID`, and wait for the bounded job:

```bash
gh run list --workflow catalog-evidence.yml --limit 10
gh run watch RUN_ID
```

If dispatch rejects the request, use a full 40-character lowercase hexadecimal
SHA and choose exactly `review` or `canonical`. The next command is the same
`gh workflow run` form above with corrected inputs.

## Review one complete evidence bundle

Download the one uploaded bundle. Its name is always:

```text
rendro-catalog-evidence--{operation}--{full_candidate_sha}--run-{run_id}--attempt-{run_attempt}
```

The bundle expires after 30 days. Its root contains only `README.md`,
`manifest.json`, `checksums.sha256`, and the operation's closed payload roles.
Read the root README and manifest before opening any payload file. Text and
manifest facts carry status; color, icons, thumbnails, and screenshots do not.

Next: download the one bundle, then validate its root manifest and checksums.
Copy the **Artifact URL** from the completed GitHub Actions run's artifact entry
when you need a durable operator reference; use its run ID with `gh run download`
for the supported retrieval command below. Record the **Archive digest** from the
run artifacts API beside that URL so later evidence checks can verify the exact
downloaded archive rather than trusting its name:

```bash
gh api "repos/OWNER/REPO/actions/runs/RUN_ID/artifacts" \
  --jq '.artifacts[] | {id, name, digest, archive_download_url}'
```

```bash
mkdir -p /tmp/rendro-catalog-evidence
gh run download RUN_ID --dir /tmp/rendro-catalog-evidence
find /tmp/rendro-catalog-evidence -maxdepth 2 -type f | sort
```

Before validating or reading bundle metadata, establish `CONTROL_SHA` from an
independently trusted default-branch control record. Do not derive it from the
bundle. Validate the extracted root from that exact trusted control checkout.
Replace `BUNDLE_ROOT` with the directory that contains `manifest.json`:

```bash
git checkout --detach CONTROL_SHA
mix deps.get
mix run -e '
  Code.require_file("dev/rendro/catalog_evidence_bundle.ex")
  case Rendro.CatalogEvidenceBundle.validate(System.fetch_env!("BUNDLE_ROOT"), System.fetch_env!("OPERATION"), System.fetch_env!("CONTROL_SHA")) do
    :ok -> IO.puts("Catalog evidence bundle VERIFIED")
    {:error, reasons} -> Mix.raise("Catalog evidence bundle failed validation: #{inspect(reasons)}")
  end
'
```

Run it with explicit values:

```bash
CONTROL_SHA=TRUSTED_DEFAULT_BRANCH_CONTROL_SHA BUNDLE_ROOT=/tmp/rendro-catalog-evidence/EXTRACTED_ROOT OPERATION=review mix run -e 'Code.require_file("dev/rendro/catalog_evidence_bundle.ex"); IO.inspect(Rendro.CatalogEvidenceBundle.validate(System.fetch_env!("BUNDLE_ROOT"), System.fetch_env!("OPERATION"), System.fetch_env!("CONTROL_SHA")))'
```

Check these textual facts against the downloaded bundle manifest:

- candidate SHA and checked-out HEAD are the same requested full candidate
  identity; control SHA is the distinct default-branch control-plane identity;
- `priv/pdfium_pin.json` supplies the PDFium version and binary SHA-256;
- operation, run ID, run attempt, payload roles, counts, and per-file hashes are present;
- `review` has candidate-only authority with no reviewer approval recorded;
- `canonical` is evidence transport, not repository mutation or publication.

If validation reports a path, count, checksum, control/candidate/HEAD, or
renderer-pin failure, stop interpreting the payload. Re-run the exact operation
for the same full SHA after fixing the source or control-plane mismatch.

## Validate review bundle

Review eligibility starts only after the downloaded `review` bundle validates in
the trusted control checkout. Before looking at an image, compare the full
lowercase 40-character candidate SHA to detached HEAD, then check the control
SHA, PDFium version and full executable digest, positive run ID and attempt,
closed roles/counts, safe paths, full PDF/PNG hashes, Artifact URL, and Archive
digest. A prefix, uppercase, truncated, stale, neighboring-run, reordered,
extra, or partial value is a validation failure, not close-enough evidence.

**Review bundle empty:** there is no review authority. Dispatch a new exact-SHA
`review` run and leave every affected cell unreviewed and unpromoted.

**Review bundle loading:** downloaded files are ineligible for review until
`Rendro.CatalogEvidenceBundle.validate/3` completes successfully against the
independently trusted control SHA, checkout, and checked-in PDFium pin. There is no
browser or in-document loading surface to infer from.

**Review bundle error:** show the failing manifest, checksum, identity, pin,
role, or count condition. Do not score images; correct that condition and run a
new exact-SHA dispatch.

**Review bundle populated:** one valid closed manifest-rooted bundle is the
happy path. Review full-size images only, in the locked family order: Invoice light → dark, Statement light → dark, Payslip light → dark, Ticket light → dark. Thumbnails and prior hashes are navigation aids, never review authority.

**Review bundle partial:** a missing target image, score, reading order,
reviewer identity, rationale, role, count, provenance field, or hash keeps its
cell unreviewed and unpromoted. Record the exact missing item and dispatch or
correct only the matching immutable evidence.

**Review bundle overflow:** do not crop the full-size images. Preserve complete
machine-checked provenance values instead of abbreviated identifiers.

**Review bundle zero/one/many:** the candidate contract classifies exactly six
changed IDs and 26 byte-identical controls; six target review records are
required for a promotable Phase 136 decision. Any other quantity is partial.

**Review bundle long text:** retain complete but concise reviewer rationale and
verbatim machine identities/digests. Do not shorten fields to fit a display.

After deterministic validation, the human review remains advisory. For each of
the six targets, accept only a named independent record with the frozen integer
scores, reading order, `print_safety`, rationale, review date, source SHA,
PDFium identity, run/attempt, source-PDF hash, PNG hash, Artifact URL/digest,
and superseded reference. A visual threshold is hierarchy `5` and every other
visual dimension at least `4`; `print_safety: false` remains a screen-only
boundary and does not become a pass. If review is unavailable, incomplete, or a
target misses, continue with explicit deferral: record the actual unreviewed /
unpromoted cell and the bounded next action. Never synthesize, round, clamp,
average, or infer a reviewer score or approval.

## Consume the stable bundle contract in Phase 136

Phase 136 may consume the one validated bundle contract: root manifest,
checksums, closed role names, payload counts, hashes, control/candidate identity,
renderer pin, run/attempt, and 30-day transport boundary. Remote Ubuntu/PDFium alone proves raster identity. Phase 136 alone owns visual judgment.

Do not infer visual quality from a successful run. Do not treat the artifact as
approval, a release decision, an attestation, or a required merge context. The
next action for visual work is the Phase 136 review process after local manifest
validation has succeeded.

## Audit the control plane and diagnose failures

The workflow uses `permissions: contents: read`. No secrets, caches, writes, workflow bridge, or attestation are available. Both checkouts set
`persist-credentials: false`; candidate shell input arrives through environment
variables and must equal literal detached `git rev-parse HEAD` output.

Inspect the trusted workflow and pin before dispatching:

```bash
sed -n '1,260p' .github/workflows/catalog-evidence.yml
cat priv/pdfium_pin.json
mix test test/guardrails/required_checks_contract_test.exs --max-failures 1
```

Reproduce deterministic checks locally from the candidate checkout:

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

- Invalid input: provide a 40-character lowercase SHA and `review` or
  `canonical`, then re-run `gh workflow run`.
- Candidate/HEAD mismatch: inspect the detached candidate with
  `git rev-parse HEAD`; request the resulting full SHA again.
- PDFium pin mismatch: compare `sha256sum "$(command -v pdfium-cli)"` with
  `priv/pdfium_pin.json`, then repair the pinned renderer path before rerunning.
- Missing or unsafe bundle path, hash, or count: run
  `Rendro.CatalogEvidenceBundle.validate` again and fix the candidate generator
  or control workflow before trusting the bundle.
- Upload failure: inspect `gh run view RUN_ID --log-failed`, then dispatch a new
  run for the same immutable SHA after the failure is understood.

Run the docs contract whenever this runbook changes:

```bash
mix test test/docs_contract/catalog_evidence_runbook_test.exs --max-failures 1
mix run scripts/verify_docs.exs
```
