# Phase 135: Test & CI/CD Simplification - Pattern Map

**Mapped:** 2026-08-27
**Files analyzed:** 15 planned new or modified files
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| .github/workflows/catalog-evidence.yml | workflow config | event-driven, file-I/O | .github/workflows/ci.yml | role-match |
| .github/workflows/ci.yml | workflow config | event-driven | itself | exact |
| .github/workflows/CATALOG-EVIDENCE.md | runbook documentation | request-response | brand/copy/VOICE.md | role-match |
| dev/rendro/catalog_evidence_bundle.ex | dev-only service | file-I/O, transform | dev/rendro/catalog.ex | role-match |
| dev/rendro/catalog_evidence_parity.ex | dev-only service | transform, file-I/O | dev/rendro/catalog_review_reconciliation.ex | role-match |
| test/rendro/catalog_evidence_bundle_test.exs | contract test | file-I/O, transform | test/rendro/catalog_review_payload_contract_test.exs | role-match |
| test/rendro/catalog_evidence_parity_test.exs | contract test | transform | test/docs_contract/catalog_quality_contract_test.exs | role-match |
| test/guardrails/required_checks_contract_test.exs | workflow-contract test | event-driven | itself | exact |
| test/docs_contract/catalog_evidence_runbook_test.exs | docs-contract test | request-response | test/docs_contract/catalog_manifest_contract_test.exs | role-match |
| scripts/verify_docs.exs | test-runner config | batch | itself | exact |
| test/rendro/recipes/themed_render_smoke_test.exs | regression test | request-response | itself | exact |
| test/rendro/recipes/payslip_opts_threading_test.exs | regression test | request-response | itself | exact |
| test/rendro/recipes/certificate_typography_test.exs | regression test | request-response | itself | exact |
| .planning/phases/135-test-ci-cd-simplification/135-test-inventory.md | durable evidence record | batch, transform | test/rendro/catalog_raster_review_test.exs | partial |
| scripts/README.md (if it inventories the helper) | documentation | request-response | itself | exact |

## Pattern Assignments

### .github/workflows/catalog-evidence.yml (workflow config, event-driven/file-I/O)

**Analog:** .github/workflows/ci.yml

Keep it standalone, not a job in ordinary CI. Copy full-SHA action pins, top-level read-only permissions, pinned PDFium verification, and post-run upload mechanics. Do not copy legacy branch triggers or multiple uploads.

**Permissions and action pin** (ci.yml lines 21-23, 43-50):

~~~yaml
permissions:
  contents: read

- name: Checkout
  uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
~~~

**Pinned PDFium installation** (ci.yml lines 240-247):

~~~yaml
- name: Install pdfium-cli (pinned)
  run: |
    EXPECTED_SHA256="b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a"
    curl -fsSL -o pdfium-cli URL
    echo "expected SHA and binary name" | sha256sum --check
    chmod +x pdfium-cli
    sudo mv pdfium-cli /usr/local/bin/pdfium-cli
~~~

**Artifact transport** (ci.yml lines 301-307):

~~~yaml
- name: Upload catalog evidence
  uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02
  with:
    name: phase-127-catalog-bless
    path: runner temporary artifact directory
    if-no-files-found: error
~~~

Adapt it for manual dispatch only: validate exact 40-lowercase-hex candidate SHA and closed operation enum; pass inputs through environment variables rather than shell interpolation; detached checkout with persist-credentials false; literal HEAD equality; no cache, secrets, writes, attestations, or privilege bridge. Upload one bundle at 30-day retention and write transport URL/digest only after upload. Default-branch workflow is control-plane authority; candidate code is untrusted input.

### .github/workflows/ci.yml (workflow config, event-driven)

**Analog:** itself

The cutover is deletion-only after all four remote parity rows pass. Preserve main/PR/schedule validation, deterministic/proof/advisory membership, and sole roll-up.

**Temporary route triggers** (lines 3-15):

~~~yaml
on:
  push:
    branches:
      - main
      - phase-126 raster branch pattern
      - phase-127 catalog branch pattern
      - phase-130 review branch pattern
      - phase-130 canonical branch pattern
~~~

**Authority boundary to preserve** (lines 220-223, 614-624):

~~~yaml
advisory-checks:
  runs-on: ubuntu-latest
  # no needs => graph-disconnected

ci-success:
  if: always()
  needs: [test, configurator-browser, integration-proofs, quality-governance]
~~~

Remove only legacy branch patterns and Phase 126/127/130 conditional generation, staging, uploads, and matching string assertions (lines 260-472). Never connect generic catalog evidence to needs, ci-success, or required test jobs.

### dev/rendro/catalog_evidence_bundle.ex (dev-only service, file-I/O/transform)

**Analog:** dev/rendro/catalog.ex

Keep it under dev/rendro. Build in a fresh staging root; derive a literal ordered role registry; write root manifest.json, sorted checksums.sha256, and README.md; validate the completed root; then return :ok for one workflow upload. It is not runtime lib code.

**Compilation boundary** (mix.exs lines 55-59):

~~~elixir
defp elixirc_paths(:test), do: ["lib", "dev", "test/support"]
defp elixirc_paths(:dev), do: ["lib", "dev"]
defp elixirc_paths(_), do: ["lib"]
~~~

**Staging and cleanup lifecycle** (dev/rendro/catalog.ex lines 184-223):

~~~elixir
cleanup_candidate()

result =
  with {:ok, renderer_version} <- Rendro.Adapters.Pdfium.version(),
       :ok <- File.mkdir_p(@candidate_staging_root),
       {:ok, cells} <- build_cells(renderer_version, @candidate_staging_root, @candidate_root),
       :ok <- validate_candidate_staging(cells),
       :ok <- File.rename(@candidate_staging_root, @candidate_root) do
    :ok
  end

case result do
  :ok -> :ok
  {:error, _reason} = error ->
    cleanup_candidate()
    error
end
~~~

**Safe path/hash pattern** (lines 902-910, 1103-1110):

~~~elixir
match?({:ok, _}, Path.safe_relative(path)) and sha256?(png_sha) and sha256?(pdf_sha)

defp sha256?(value), do: is_binary(value) and Regex.match?(~r/\\A[0-9a-f]{64}\\z/, value)
~~~

Use crypto SHA-256 plus lowercase hex from line 871. Do not retain old tmp/phase130 paths as the new contract.

### dev/rendro/catalog_evidence_parity.ex (dev-only service, transform/file-I/O)

**Analog:** dev/rendro/catalog_review_reconciliation.ex

Normalize evidence then compare ordered roles, payload hashes, candidate/HEAD, renderer pin, counts, candidate-only reviewer-field absence, action pins/permissions, and run/attempt. ZIP digest and incidental path are not payload parity authority.

**Layered validation** (lines 7-30):

~~~elixir
with {:ok, final} <- normalize_candidate(candidate_manifest, proofs),
     :ok <- validate_exact_identity_order(expected, images),
     {:ok, renderer} <- renderer_identity(candidate_manifest, provenance),
     {:ok, bindings} <- bind_local_paths(expected, images, final_dir) do
  {:ok, %{"schema_version" => 1, "renderer" => renderer, "bindings" => bindings}}
else
  {:error, _reason} = error -> error
end
~~~

**Order and identity equality** (lines 49-55):

~~~elixir
Enum.map(expected, fn item -> item["catalog_id"] end) ==
  Enum.map(images, fn item -> item["catalog_id"] end) and
  Enum.zip(expected, images)
  |> Enum.all?(fn {candidate, image} ->
    Map.take(candidate, identity_fields()) == Map.take(image, identity_fields())
  end)
~~~

**Error aggregation** (lines 128-133):

~~~elixir
case Enum.find(results, fn result -> match?({:error, _reason}, result) end) do
  nil -> {:ok, Enum.map(results, fn {:ok, value} -> value end)}
  {:error, _reason} = error -> error
end
~~~

Local tests prove comparator behavior. Paired legacy/generic Ubuntu/PDFium runs in the committed matrix prove payload identity and permit route retirement.

### test/rendro/catalog_evidence_bundle_test.exs (contract test, file-I/O/transform)

**Analog:** test/rendro/catalog_review_payload_contract_test.exs

Use async true, local valid fixture helpers, a complete positive assertion, then one in-memory mutation per failure: unsafe path; duplicate/missing/extra role; wrong hash/count; invalid SHA/operation; forbidden reviewer field.

**Positive fixture pattern** (lines 21-52):

~~~elixir
manifest = candidate_manifest()
assert {:ok, result} = CatalogReviewPayload.classify(manifest, multipage_proofs())
assert Enum.map(result.final, fn item -> item["catalog_id"] end) == @ids
~~~

**Teeth pattern** (lines 54-78):

~~~elixir
invalid_manifests = [
  Map.update!(manifest, "cells", &Enum.reverse/1),
  put_in(manifest, ["cells", Access.at(0), "png_path"], "../canonical.png"),
  put_in(manifest, ["candidate", "commit_sha"], "short")
]

for invalid <- invalid_manifests do
  assert {:error, _reason} = CatalogReviewPayload.classify(invalid, multipage_proofs())
end
~~~

### test/rendro/catalog_evidence_parity_test.exs (contract test, transform)

**Analog:** test/docs_contract/catalog_quality_contract_test.exs

Use valid normalized fixtures, then mutate exactly one authority fact: payload SHA; role presence/order; candidate/HEAD; renderer pin; count; reviewer data; permission/action/cache/secret facts; or evidence availability. Assert useful diagnostics.

**Exact join and stale hash control** (lines 84-136):

~~~elixir
assert Catalog.quality_contract_errors(%{"cells" => cells}, rubric(Enum.map(cells, &unscored/1))) == []

stale = %{unscored(first) | "png_sha256" => String.duplicate("c", 64)}
assert Enum.any?(stale_errors, &String.contains?(&1, "PNG hash is stale"))
~~~

**Mutation-loop diagnostic** (lines 139-165):

~~~elixir
for mutation <- scored_evidence_mutations() do
  errors = Catalog.quality_contract_errors(catalog, mutated_rubric)
  assert Enum.any?(errors, &String.contains?(&1, record["catalog_id"]))
end
~~~

No global mutation dependency or checkout-mutating CI.

### test/guardrails/required_checks_contract_test.exs (workflow-contract test)

**Analog:** itself

Extend parsed-YAML and bounded text contracts. During additive rollout, test old and new routes; after remote parity, replace old positive checks with route-absence tests. Preserve offline/no-token rules.

**Parsed permission style** (lines 51-65):

~~~elixir
assert {:ok, %{"jobs" => jobs}} = YamlElixir.read_from_string(ci)
assert is_map(jobs)

workflow = load_workflow!(path)
assert workflow["permissions"] == %{"contents" => "read"}
~~~

**Sole roll-up invariant** (lines 465-517):

~~~elixir
roll_up = Map.fetch!(jobs, "ci-success")
assert "quality-governance" in roll_up["needs"]
assert roll_up["if"] == "always()"
assert baseline["required_contexts"] == ["ci-success"]
~~~

Add a catalog-evidence path constant. Assert manual-only dispatch, exact inputs, environment handoff, detached/no-credential checkout, no cache/secrets/writes/privilege bridge, full action SHAs, one 30-day upload, and unchanged ordinary topology.

### Adjacent runbook, docs contract, and docs inventory

**Analogs:** test/docs_contract/catalog_manifest_contract_test.exs; brand/copy/VOICE.md

The new docs test reads .github/workflows/CATALOG-EVIDENCE.md directly; register it in scripts/verify_docs.exs if that runner owns docs-lane inventory. If scripts/README.md inventories this helper/operator path, link to the runbook instead of duplicating it.

**Minimal docs-contract pattern** (catalog_manifest_contract_test.exs lines 1-53):

~~~elixir
defmodule Rendro.DocsContract.CatalogManifestContractTest do
  use ExUnit.Case, async: true

  test "consumer manifest requires derived preview copy, disclosure, and quality fields" do
    cells = Enum.map(Catalog.catalog_specs(), &cell/1)
    assert Catalog.manifest_shape_errors(manifest(cells)) == []
  end
end
~~~

Assert exact-SHA dispatch, control/candidate/HEAD plus PDFium-pin verification, one-bundle validation, review versus canonical authority, local materialization boundary, local deterministic commands, and remote/human-review limits. Follow what/where/why/next voice from VOICE.md lines 15-37 and 151-184. Use locked state sentences verbatim where applicable.

### Bounded recipe cleanup

**Retained Payslip owner:** test/rendro/recipes/themed_render_smoke_test.exs lines 72-103:

~~~elixir
test "Payslip renders under default theme (masked-middot + accented, CR-01)" do
  # masked-middot and accented fixture data
  assert {:ok, _} = Rendro.render(Payslip.document(data, theme: @theme))
end
~~~

**Distinct Payslip contracts that remain:** test/rendro/recipes/payslip_opts_threading_test.exs lines 37-82:

~~~elixir
assert %Rendro.PageTemplate{} = Payslip.page_template(theme: Rendro.Theme.default())
refute Payslip.sections(data) == Payslip.sections(data, theme: Rendro.Theme.default())
refute themed == overridden
assert Payslip.sections(data) == Payslip.sections(data, [])
refute Payslip.sections(data) == Payslip.sections(data, typography: %{leading: 2.0})
~~~

Remove only targeted full-render duplicate at lines 84-122, only after D-05 inventory and deterministic negative-control gate demonstrate smoke catches the same behavior/failure. Do not modify threading, precedence, no-theme byte identity, or live seam contracts.

**Certificate rename-only correction:** test/rendro/recipes/certificate_typography_test.exs lines 47-55 only proves themed and unthemed sections construction succeeds:

~~~elixir
assert [%Rendro.Section{} | _] = Certificate.sections(data)
assert [%Rendro.Section{} | _] =
         Certificate.sections(data, theme: Rendro.Theme.default())
~~~

Rename it to that actual construction contract. Do not invent geometry equality; retain surrounding raises, rendering, role/leading, and override checks.

### 135-test-inventory.md (durable evidence record)

**Analog:** test/rendro/catalog_raster_review_test.exs for bounded count/identity language; no direct prose inventory analogue.

Record only D-05 candidates and D-18 four remote pairs. Columns: old test/route, retained/replacement owner, preserved behavior/failure mode, authority lane, oracle, negative control, focused command, result, exact candidate SHA, legacy/generic run URL and attempt, normalized result. Missing/unavailable/mismatch stays a blocker.

**Bounded identity vocabulary** (lines 95-112):

~~~elixir
assert length(cells) == 32
assert length(multipage) == 4
assert candidate["commit_sha"] =~ ~r/\A[0-9a-f]{40}\z/
~~~

## Shared Patterns

### Pure-core / dev-tooling boundary

**Source:** mix.exs lines 55-59, 81-147
**Apply to:** new evidence modules and Mix wiring.

Keep tooling in dev, with no runtime/package dependency or lib expansion.

### Fail-closed tests with teeth

**Source:** catalog_review_payload_contract_test.exs lines 54-94; catalog_quality_contract_test.exs lines 139-165
**Apply to:** bundle, parity, workflow, docs, and cleanup replacement contracts.

Pair each positive contract with one controlled invalid in-memory field or record and assert intended useful failure. Source scans, refute equality, count changes, or re-blessed goldens are insufficient.

### Local versus remote authority

**Source:** ci.yml lines 220-223, 240-247, 614-624
**Apply to:** workflow tests, parity matrix, runbook, cutover.

Local ExUnit/docs checks prove workflow structure/security/topology, manifest/path/hash closure, comparator behavior, Mix semantics, and docs. Remote Ubuntu/PDFium proves old/new renderer payload identity. Human visual review is Phase 136 authority. The new workflow remains disconnected from ci-success.

### Hash and safe-path identity

**Source:** dev/rendro/catalog.ex lines 868-871, 902-910; dev/rendro/catalog_review_payload.ex lines 132-146
**Apply to:** manifest, checksum index, bundle validator, comparator.

Use lowercase SHA-256, Path.safe_relative/1, and closed expected role/path sets. Validate ordering, uniqueness, presence, count, and digest; fail closed on missing, extra, unsafe, duplicate, or mismatched payloads.

### Operator voice

**Source:** brand/copy/VOICE.md lines 15-37, 151-184
**Apply to:** bundle README, GitHub summary, runbook.

State what happened, where evidence is, why authority is bounded, and the next command. Text and manifest are authoritative; color, thumbnails, and screenshots never encode approval.

## No Analog Found

| File | Role | Data Flow | Reason / planner direction |
|---|---|---|---|
| 135-test-inventory.md | evidence record | batch | No prior compact test-inventory/parity-matrix artifact. Follow locked D-05/D-18 table schema and explicit result/blocker states. |

## Metadata

**Analog search scope:** .github/workflows, dev/rendro, dev/mix/tasks, test/rendro, test/guardrails, test/docs_contract, scripts, brand
**Files scanned:** 17 primary analogs and supporting config surfaces
**Pattern extraction date:** 2026-08-27

