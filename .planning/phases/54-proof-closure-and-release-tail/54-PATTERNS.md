# Phase 54: Proof Closure and Release Tail - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md` | test | batch | `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-VALIDATION.md` + `.planning/phases/47-form-validation-and-viewer-proof-closure/47-VALIDATION.md` | role-match |
| `.planning/phases/54-proof-closure-and-release-tail/54-VERIFICATION.md` | test | batch | `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md` | exact |
| `scripts/protected_viewer_proof_fixture.exs` | utility | batch | `scripts/release_preflight_proof.exs` + `test/rendro/adapters/protected_validation_live_test.exs` | role-match |
| `priv/support_matrix.json` | config | transform | `priv/support_matrix.json` (`embedded_files`, `links`, `protection`) | exact |
| `guides/api_stability.md` | config | transform | `guides/api_stability.md` (`Embedded Artifact Viewer Posture`, `Protected PDF Support Boundary`) | exact |
| `guides/integrations.md` | config | transform | `guides/integrations.md` (protected-delivery recipe) | exact |
| `test/docs_contract/protection_claims_test.exs` | test | transform | `test/docs_contract/protection_claims_test.exs` + `test/docs_contract/embedded_artifact_claims_test.exs` | exact |
| `scripts/verify_docs.exs` | utility | batch | `scripts/verify_docs.exs` | exact |
| `CHANGELOG.md` | config | transform | `CHANGELOG.md` | exact |
| `lib/mix/tasks/release/preflight.ex` | utility | batch | `lib/mix/tasks/release/preflight.ex` | exact |
| `test/mix/tasks/release_preflight_test.exs` | test | batch | `test/mix/tasks/release_preflight_test.exs` | exact |
| `scripts/release_preflight_proof.exs` | utility | batch | `scripts/release_preflight_proof.exs` | exact |
| `test/scripts/release_preflight_proof_test.exs` | test | batch | `test/scripts/release_preflight_proof_test.exs` | exact |

## Pattern Assignments

### `.planning/phases/54-proof-closure-and-release-tail/54-VALIDATION.md` (test, batch)

**Analogs:** `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-VALIDATION.md`, `.planning/phases/47-form-validation-and-viewer-proof-closure/47-VALIDATION.md`

**Frontmatter + lane split pattern** (`53-VALIDATION.md` lines 1-21):
```markdown
---
phase: 53
slug: delivery-threading-and-truthful-support-contract
status: passed
nyquist_compliant: true
wave_0_complete: true
source: planning
created: 2026-05-06
updated: 2026-05-06
---

# Phase 53 — Validation Strategy

> Per-phase validation contract for protected-artifact transport/storage truthfulness and synchronized `protection` support-boundary claims.

Phase 53 has two closure lanes and keeps them separate:

1. The **runtime seam lane** proves protected artifacts remain truthful across first-party storage reload and existing delivery composition.
2. The **support-contract lane** proves `priv/support_matrix.json`, guides, and Mailglass docs publish the same narrow `protection` story.
```

**Per-task verification table pattern** (`53-VALIDATION.md` lines 40-48):
```markdown
## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 53-02-01 | 02 | 2 | TRUST-01 | T-53-05, T-53-06 | `priv/support_matrix.json` exposes a compact `protection.boundaries` subsection without widening the family-first matrix. | docs-contract | `mix test test/docs_contract/protection_claims_test.exs` | ✅ | ✅ green |
| 53-02-02 | 02 | 2 | TRUST-01, TRUST-02 | T-53-06, T-53-07, T-53-08 | Guides and Mailglass docs mirror the matrix and keep async/password boundaries explicit. | docs-contract | `mix test test/docs_contract/protection_claims_test.exs test/docs_contract/integrations_claims_test.exs && mix docs.contract` | ✅ | ✅ green |
```

**Manual proof lane and table pattern** (`47-VALIDATION.md` lines 65-93):
```markdown
### 4. Viewer-proof lane

Purpose:
- Back supported-viewer claims with manual verification for the named support contract only.

Required viewers:
- Adobe Acrobat Reader
- Apple Preview

Required checks per viewer:
- Opens successfully
- Default text, checkbox, and radio state is visible on first open
- Text field editing works
- Checkbox toggle works
- Radio selection works
- Saving preserves the edited result

Status recording:
- Record results in the table below during execution.
- If a viewer is not checked, leave it `unverified`.
- This document is the source of truth for the post-checkpoint sync back into `priv/support_matrix.json` and `guides/api_stability.md`.

| Viewer | Open | Default state visible | Edit/toggle | Save | Result | Notes |
|--------|------|------------------------|-------------|------|--------|-------|
| Adobe Acrobat Reader | pending | pending | pending | pending | unverified | Not yet manually checked in this phase. |
| Apple Preview | pass | pass | pass | pass | supported | Manually verified against `tmp/forms_support_fixture.pdf`. |
```

**Use in Phase 54:** keep the Phase 53 frontmatter/table structure, but replace the viewer-proof table with the five locked `protection` checks and record viewer version, OS, fixture, date checked, and notes inline in the manual proof record.

---

### `.planning/phases/54-proof-closure-and-release-tail/54-VERIFICATION.md` (test, batch)

**Analog:** `.planning/phases/53-delivery-threading-and-truthful-support-contract/53-VERIFICATION.md`

**Frontmatter + report header pattern** (lines 1-15):
```markdown
---
phase: 53-delivery-threading-and-truthful-support-contract
verified: 2026-05-06T17:09:13Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
---

# Phase 53: Delivery Threading and Truthful Support Contract Verification Report

**Phase Goal:** Keep protected artifacts composable with existing delivery seams while publishing one canonical support boundary for the new surface.
**Verified:** 2026-05-06T17:09:13Z
**Status:** passed
**Re-verification:** No - initial verification
```

**Observable truths table pattern** (lines 16-29):
```markdown
## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 4 | The machine-readable support matrix and the human-facing docs tell the same narrow protection-boundary story. | ✓ VERIFIED | [priv/support_matrix.json](...:106), [guides/api_stability.md](...:62), and [test/docs_contract/protection_claims_test.exs](...:4) align on password-to-open support, advisory-permission honesty, unsupported narratives, and boundary leaves. |
| 5 | Protected delivery is documented as `render_to_artifact -> Protect.password -> store/deliver`, with delivery and storage seams transporting bytes rather than passwords. | ✓ VERIFIED | [guides/integrations.md](...:67) states identifier-only async args and the canonical protected-delivery recipe, [guides/integrations.md](...:255) shows `attach_artifact/3` transport, and [lib/rendro/adapters/mailglass.ex](...:18) repeats the transport-only boundary. |
```

---

### `scripts/protected_viewer_proof_fixture.exs` (utility, batch)

**Analogs:** `scripts/release_preflight_proof.exs`, `test/rendro/adapters/protected_validation_live_test.exs`

**Operator-facing CLI precondition pattern** (`scripts/release_preflight_proof.exs`):
- Validate required inputs and environment before doing any real work.
- Print a dry-run/operator message that names the prerequisites and intended output path.
- Keep the script isolated from the active workspace contract; it should explain missing prerequisites explicitly instead of failing opaquely.

**Protected fixture generation pattern** (`test/rendro/adapters/protected_validation_live_test.exs`):
- Reuse the existing qpdf-backed protected-artifact path instead of inventing a second protection API.
- Generate proof artifacts at runtime rather than checking in protected binaries.
- Treat host-tool readiness (`qpdf`, `pdfinfo`) as explicit prerequisites.

**Use in Phase 54:** implement `scripts/protected_viewer_proof_fixture.exs` as a small operator-facing proof utility that follows the release-proof script's precondition/dry-run style while reusing the live protected-fixture generation path established in `test/rendro/adapters/protected_validation_live_test.exs`.

**Behavioral proof section pattern** (lines 63-76):
```markdown
### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Runtime seam lane proves storage reload plus protected delivery composition | `mix test ...` | `23 tests, 0 failures` | ✓ PASS |
| Docs contract lane includes the protection claims closure | `mix docs.contract` | All 6 explicit docs-contract lanes passed, including `Protection semantic-claims lane` | ✓ PASS |
```

**Use in Phase 54:** preserve the same verification-report skeleton, but make the must-have truths about per-viewer proof closure, support-matrix/docs parity, changelog/publish-tail wording, `mix release.preflight`, and `scripts/release_preflight_proof.exs`.

---

### `priv/support_matrix.json` (config, transform)

**Analog:** `priv/support_matrix.json`

**Per-viewer promoted/unverified row pattern** (`embedded_files` and `links`, lines 52-105):
```json
"embedded_files": {
  "capabilities": {
    "document_level": "supported"
  },
  "behaviors": {
    "explicit_metadata": "supported",
    "authored_timestamps": "supported",
    "page_attachment_annotations": "unsupported"
  },
  "viewers": {
    "adobe_acrobat_reader": {
      "status": "supported",
      "proof": [
        "discoverable",
        "open_or_extract",
        "save_or_extract"
      ]
    },
    "apple_preview": {
      "status": "unverified",
      "proof": [
        "discoverable",
        "open_or_extract",
        "save_or_extract"
      ]
    }
  }
}
```

**Current protection family pattern** (lines 106-148):
```json
"protection": {
  "capabilities": {
    "password_to_open": "supported",
    "external_hook_qpdf": "supported",
    "native_encryption": "unsupported"
  },
  "algorithms": {
    "aes_256": "supported",
    "aes_128": "unsupported",
    "rc4": "unsupported"
  },
  "behaviors": {
    "advisory_permissions": "supported",
    "deterministic_output": "unsupported",
    "digital_signatures": "unsupported",
    "pdf_a_compliance": "unsupported",
    "tamper_evidence": "unsupported"
  },
  "boundaries": {
    "external_hook_only": "supported",
    "persisted_async_job_args_passwords": "unsupported",
    "delivery_and_storage_seams_transport_artifacts_not_passwords": "supported"
  },
  "viewers": {
    "adobe_acrobat_reader": {
      "status": "unverified",
      "proof": [
        "opens_with_user_password",
        "displays_authored_content_correctly",
        "honors_advisory_print_flag",
        "honors_advisory_copy_flag"
      ]
    }
  }
}
```

**Use in Phase 54:** copy the existing family-first JSON shape exactly. Promote viewer rows independently, not in a grouped surface update, and keep non-passing viewers at `"unverified"`. The planner should expect only the `viewers.*.status` and `proof` list names to change for this phase.

---

### `guides/api_stability.md` (config, transform)

**Analog:** `guides/api_stability.md`

**Per-surface viewer-posture prose pattern** (`Embedded Artifact Viewer Posture`, lines 50-58):
```markdown
## Embedded Artifact Viewer Posture

Viewer support is tracked per surface and per viewer in `priv/support_matrix.json`, with each `supported` claim backed by a recorded checklist in the phase validation record. Promotion requires recorded evidence (viewer name, version when easily available, OS, fixture, date checked, and per-behavior pass/fail); a pass for one surface does not imply a pass for another on the same viewer, and no viewer is implicitly supported by structural validity alone.

Adobe Acrobat Reader is `supported` for both `embedded_files` and `links`.

Apple Preview is `supported` for `links` and `unverified` for `embedded_files`.
```

**Protection boundary prose pattern** (`Protected PDF Support Boundary`, lines 60-76):
```markdown
## Protected PDF Support Boundary

Rendro supports password-to-open PDF protection through an external artifact-first boundary.

The canonical API is `Rendro.Protect.password/2`, which wraps an already-rendered `%Rendro.Artifact{}` through a protection adapter such as `Rendro.Adapters.Qpdf`.

Advisory permissions are an honor-system PDF flag surface, not a cryptographic enforcement mechanism.

Protection is not compliance, not tamper evidence, and not digital signing.

Delivery and storage seams should transport already-protected artifacts, not password material.

Structural validation through `pdfinfo`/Poppler proves that a protected PDF remains structurally readable when a password is supplied to the validator. If validation succeeds only with `owner_password`, that proves structural decryptability fallback rather than the normative password-to-open path. It does not prove viewer behavior. All `protection` viewer rows remain `unverified` in `priv/support_matrix.json` until a recorded checklist promotes a named viewer.
```

**Use in Phase 54:** preserve the terse contract style and swap only the final viewer-status paragraph(s) to match the recorded proof. Keep the structural-vs-viewer split and the unsupported-security wording intact.

---

### `guides/integrations.md` (config, transform)

**Analog:** `guides/integrations.md`

**Async-secret boundary pattern** (lines 67-73):
```markdown
The worker also does **not** accept password or protection fields in job args.
Protection secrets do not belong in persisted Oban args. Persist only business identifiers in Oban args. Resolve protection secrets at execution time inside your application boundary.

The canonical protected-delivery recipe is
`render_to_artifact -> Protect.password -> store/deliver`. If you need protected
delivery, render the artifact in your worker and apply `Rendro.Protect.password/2`
in an application-owned secret boundary before storage or delivery.
```

**Thin downstream callout pattern** (lines 255-277):
```markdown
If your workflow needs password-to-open delivery, protect the artifact first and
then hand the protected artifact to `attach_artifact/3`:

{:ok, artifact} =
  doc
  |> Rendro.render_to_artifact(deterministic: true)
  |> then(fn {:ok, artifact} ->
    Rendro.Protect.password(artifact,
      open_password: System.fetch_env!("PDF_OPEN_PASSWORD"),
      owner_password: System.fetch_env!("PDF_OWNER_PASSWORD"),
      advisory_permissions: [:print],
      adapter: Rendro.Adapters.Qpdf
    )
  end)

Protected delivery uses `Rendro.Adapters.Mailglass.attach_artifact/3` with an already-protected `%Rendro.Artifact{}`.

That flow keeps protection at the artifact boundary. Mailglass does not need to know the passwords; it just transports the already-protected PDF bytes.
```

**Use in Phase 54:** if release-tail docs add a pointer or callout, copy this exact “pointer, not tutorial” posture. Do not fork a second integration recipe.

---

### `test/docs_contract/protection_claims_test.exs` (test, transform)

**Analogs:** `test/docs_contract/protection_claims_test.exs`, `test/docs_contract/embedded_artifact_claims_test.exs`

**Scalar contract assertions pattern** (`protection_claims_test.exs` lines 4-32):
```elixir
test "support matrix publishes the narrow protection family and leaves viewers unverified" do
  matrix = File.read!("priv/support_matrix.json")

  assert matrix =~ ~s|"password_to_open": "supported"|
  assert matrix =~ ~s|"external_hook_qpdf": "supported"|
  assert matrix =~ ~s|"native_encryption": "unsupported"|
  assert matrix =~ ~s|"advisory_permissions": "supported"|

  assert matrix =~
           ~r/"protection".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

  assert matrix =~
           ~r/"protection".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s
end
```

**Promotion/non-promotion regex pattern** (`embedded_artifact_claims_test.exs` lines 32-42, 67-73):
```elixir
assert matrix =~
         ~r/"embedded_files".*?"viewers".*?"adobe_acrobat_reader"\s*:\s*\{\s*"status"\s*:\s*"supported"/s

assert matrix =~
         ~r/"embedded_files".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"unverified"/s

assert matrix =~
         ~r/"links".*?"viewers".*?"apple_preview"\s*:\s*\{\s*"status"\s*:\s*"supported"/s
```

**Guide wording lock pattern** (`protection_claims_test.exs` lines 34-68):
```elixir
test "api stability guide uses narrow, truthful protection wording" do
  guide = File.read!("guides/api_stability.md")

  assert guide =~ "Rendro supports password-to-open PDF protection through an external artifact-first boundary."
  assert guide =~ "Advisory permissions are an honor-system PDF flag surface"
  assert guide =~ "Protection is not compliance, not tamper evidence, and not digital signing."
  assert guide =~ "All `protection` viewer rows remain `unverified`"

  refute guide =~ "secure PDF"
  refute guide =~ "tamper-proof"
end
```

**Use in Phase 54:** keep this file as the single protection docs-contract lock. Update explicit strings and regexes in the same change set as `priv/support_matrix.json` and `guides/api_stability.md`.

---

### `scripts/verify_docs.exs` (utility, batch)

**Analog:** `scripts/verify_docs.exs`

**Ordered explicit lanes pattern** (lines 5-38):
```elixir
Mix.Task.run("app.start")

lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  {"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]},
  {"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]},
  {"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]},
  {"Embedded artifact semantic-claims lane", ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]},
  {"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]}
]

results =
  Enum.map(lanes, fn {label, args} ->
    {output, status} = System.cmd("mix", args, stderr_to_stdout: true)
    ...
  end)
```

**Use in Phase 54:** if new docs-contract coverage is added, wire it here as another explicit lane. If Phase 54 only extends `protection_claims_test.exs`, keep this file unchanged.

---

### `CHANGELOG.md` (config, transform)

**Analog:** `CHANGELOG.md`

**Release-tail entry style** (lines 8-24):
```markdown
## [0.1.0] - Unreleased

### Added

- `Rendro.Protect.password/2` and `Rendro.render_protected/3` for artifact-first AES-256 password-to-open protection through optional external adapters.
- `Rendro.Adapters.Qpdf` as the first-party external protection adapter, keeping `qpdf` as an optional runtime executable instead of a hard dependency.
- Password-aware `Rendro.Adapters.Poppler.validate/2` support so protected PDFs can still participate in the structural validation lane.
- A new `protection` family in `priv/support_matrix.json` plus docs-contract coverage for advisory-permissions wording and unsupported compliance/signature claims.
```

**Use in Phase 54:** keep the changelog terse and feature-scoped. Add one thin publish-tail note that points to existing protected-delivery guidance instead of duplicating the tutorial.

---

### `lib/mix/tasks/release/preflight.ex` (utility, batch)

**Analog:** `lib/mix/tasks/release/preflight.ex`

**Phase 1 / Phase 2 gate pattern** (lines 8-18, 26-61):
```elixir
@phase_2_checks [
  {"CI", ["ci"]},
  {"Docs Contract", ["docs.contract"]},
  {"Hex Build Unpack", ["hex.build", "--unpack"]},
  {"Hex Publish Dry Run", ["hex.publish", "--dry-run", "--yes"]}
]

def run_with_context(context) do
  ...
  phase_1_results = [
    check_clean_worktree(context),
    check_exact_tag(context, version),
    check_package_metadata(context.project_config),
    check_hex_artifacts(context, version)
  ]

  if Enum.any?(phase_1_results, &(&1.status == :fail)) do
    ...
  else
    phase_2_results =
      Enum.map(@phase_2_checks, fn {name, args} ->
        result = run_mix_check(context, name, args)
        print_result(result)
        result
      end)
  end
end
```

**Hex artifact required-files pattern** (lines 120-149):
```elixir
required_files = [
  "LICENSE",
  "README.md",
  "CHANGELOG.md",
  "guides/api_stability.md",
  "guides/branding.md",
  "guides/integrations.md"
]
```

**Use in Phase 54:** preserve the executable-gate structure. If release-tail work needs another required file or stricter readiness wording, add it through the same named-check pattern instead of introducing ad hoc shell logic.

---

### `test/mix/tasks/release_preflight_test.exs` (test, batch)

**Analog:** `test/mix/tasks/release_preflight_test.exs`

**Failure-before-expensive-work pattern** (lines 6-38):
```elixir
test "fails in phase 1 before any expensive checks when the worktree is dirty" do
  runner =
    command_runner_for(%{
      {"git", ["status", "--short"]} => {" M README.md\n", 0},
      {"git", ["describe", "--tags", "--exact-match"]} => {"v0.1.0\n", 0}
    })

  {messages, exit_reason} =
    capture_shell_messages(fn ->
      catch_exit(Preflight.run([]))
    end)

  assert exit_reason == {:shutdown, 1}
  assert output =~ "Phase 1: boundary blockers"
  refute output =~ "Phase 2: release parity checks"
end
```

**Full named-check coverage pattern** (lines 40-79):
```elixir
test "runs every phase 2 check and exits only after the final summary" do
  runner =
    command_runner_for(%{
      {"mix", ["ci"]} => {"ci ok", 0},
      {"mix", ["docs.contract"]} => {"docs drifted", 1},
      {"mix", ["hex.build", "--unpack"]} => {"hex build ok", 0},
      {"mix", ["hex.publish", "--dry-run", "--yes"]} => {"dry run ok", 0}
    })

  assert_received {:preflight_command, "mix", ["ci"]}
  assert_received {:preflight_command, "mix", ["docs.contract"]}
  assert_received {:preflight_command, "mix", ["hex.build", "--unpack"]}
  assert_received {:preflight_command, "mix", ["hex.publish", "--dry-run", "--yes"]}
end
```

**Use in Phase 54:** if `release.preflight` changes, extend this test by stubbing the new named command and asserting execution order, final summary text, and artifact requirements.

---

### `scripts/release_preflight_proof.exs` (utility, batch)

**Analog:** `scripts/release_preflight_proof.exs`

**Exact-tag isolated-worktree pattern** (lines 4-27, 97-125):
```elixir
def run(args, context \\ default_context()) do
  with {:ok, options} <- parse_args(args, context),
       :ok <- validate_ref(options.ref),
       :ok <- validate_worktree(options.worktree) do
    ...
    case execute_proof(options, context) do
      {:ok, output} ->
        IO.write(output)
        :ok

      {:error, status, output} ->
        Mix.shell().error(output)
        System.halt(status)
    end
  end
end

with {_, 0} <- run_command(context, "git", ["rev-parse", "--verify", "#{options.ref}^{commit}"]),
     {_, 0} <- run_command(context, "git", ["worktree", "add", "--detach", options.worktree, options.ref]),
     {deps_output, 0} <- run_command(context, "mix", ["deps.get"], cd: options.worktree),
     {preflight_output, status} <- run_command(context, "mix", ["release.preflight"], cd: options.worktree),
     :ok <- cleanup(options, cleanup_state, context) do
  output = deps_output <> preflight_output
  ...
end
```

**Dry-run messaging pattern** (lines 156-161):
```elixir
defp dry_run_message(%{synthetic_tag: true, ref: ref, worktree: worktree}) do
  "Dry run: would create disposable exact tag #{ref} at HEAD, create isolated worktree #{worktree}, run mix deps.get and mix release.preflight, then clean up"
end
```

**Use in Phase 54:** keep the proof script as the only release isolation mechanism. If wording or behavior changes, preserve `--current-version-tag`, worktree isolation, and cleanup semantics.

---

### `test/scripts/release_preflight_proof_test.exs` (test, batch)

**Analog:** `test/scripts/release_preflight_proof_test.exs`

**Argument and guard tests pattern** (lines 8-31, 58-60):
```elixir
test "requires explicit ref and worktree arguments" do
  assert {:error, "missing required --ref vX.Y.Z or --current-version-tag"} =
           ReleasePreflightProof.parse_args([])
end

test "rejects ambiguous or non-release refs" do
  assert {:error, "ref must be an exact release tag like v0.1.0; got not-a-real-tag"} =
           ReleasePreflightProof.validate_ref("not-a-real-tag")
end

test "rejects using the active workspace as the proof worktree" do
  assert {:error, "worktree path must be isolated from the active workspace"} =
           ReleasePreflightProof.validate_worktree(File.cwd!())
end
```

**Cleanup-on-success / cleanup-on-failure pattern** (lines 63-134):
```elixir
test "synthetic tag proof creates and cleans up isolated release state on success" do
  ...
  assert_received {:proof_command, "mix", ["deps.get"], opts}
  assert opts[:cd] == "/tmp/release-proof"

  assert_received {:proof_command, "mix", ["release.preflight"], opts}
  assert opts[:cd] == "/tmp/release-proof"

  assert_received {:proof_command, "git", ["tag", "-d", "v0.1.0"], _}
end

test "synthetic tag proof restores previous tag target and cleans up after failure" do
  ...
  assert_received {:proof_command, "git", ["tag", "-f", "v0.1.0", "deadbeef"], _}
end
```

**Use in Phase 54:** extend this test only if the proof script’s release-tail behavior changes. Keep the current command-runner injection and `assert_received` style.

## Shared Patterns

### Per-Viewer Promotion Is Independent
**Sources:** [priv/support_matrix.json](/Users/jon/projects/rendro/priv/support_matrix.json:52), [guides/api_stability.md](/Users/jon/projects/rendro/guides/api_stability.md:52), [test/docs_contract/embedded_artifact_claims_test.exs](/Users/jon/projects/rendro/test/docs_contract/embedded_artifact_claims_test.exs:32)

```json
"adobe_acrobat_reader": {
  "status": "supported",
  "proof": ["discoverable", "open_or_extract", "save_or_extract"]
},
"apple_preview": {
  "status": "unverified",
  "proof": ["discoverable", "open_or_extract", "save_or_extract"]
}
```

Apply to Phase 54 support updates: promote `adobe_acrobat_reader` and `apple_preview` separately based on recorded evidence. Do not invent a phase-level parity rule.

### Docs-Contract Sync Happens In One Change Set
**Sources:** [test/docs_contract/protection_claims_test.exs](/Users/jon/projects/rendro/test/docs_contract/protection_claims_test.exs:4), [scripts/verify_docs.exs](/Users/jon/projects/rendro/scripts/verify_docs.exs:7), [lib/mix/tasks/docs.contract.ex](/Users/jon/projects/rendro/lib/mix/tasks/docs.contract.ex:10)

```elixir
test "support matrix publishes the narrow protection family and leaves viewers unverified" do
  matrix = File.read!("priv/support_matrix.json")
  ...
end

runner = Application.get_env(:rendro, :docs_contract_command_runner, &System.cmd/3)
{output, status} = runner.("mix", ["run", "scripts/verify_docs.exs"], stderr_to_stdout: true)
```

Apply to `priv/support_matrix.json`, `guides/api_stability.md`, and `test/docs_contract/protection_claims_test.exs`: planner should keep them in the same slice, with `mix docs.contract` as the canonical gate.

### Release Tail Is Executable, Not Narrative
**Sources:** [lib/mix/tasks/release/preflight.ex](/Users/jon/projects/rendro/lib/mix/tasks/release/preflight.ex:9), [scripts/release_preflight_proof.exs](/Users/jon/projects/rendro/scripts/release_preflight_proof.exs:97), [.github/workflows/ci.yml](/Users/jon/projects/rendro/.github/workflows/ci.yml:40)

```elixir
@phase_2_checks [
  {"CI", ["ci"]},
  {"Docs Contract", ["docs.contract"]},
  {"Hex Build Unpack", ["hex.build", "--unpack"]},
  {"Hex Publish Dry Run", ["hex.publish", "--dry-run", "--yes"]}
]
```

```yaml
release-proof:
  runs-on: ubuntu-latest
  needs: test
  steps:
    - name: Verify Release Proof
      run: mix run scripts/release_preflight_proof.exs --current-version-tag --worktree "$RUNNER_TEMP/rendro-release-proof"
```

Apply to release-tail planning: prefer extending these gates and their tests over adding prose-only checklists.

### Thin Protected-Delivery Pointer, Not A Second Tutorial
**Sources:** [guides/integrations.md](/Users/jon/projects/rendro/guides/integrations.md:67), [guides/integrations.md](/Users/jon/projects/rendro/guides/integrations.md:255), [CHANGELOG.md](/Users/jon/projects/rendro/CHANGELOG.md:12)

```markdown
The canonical protected-delivery recipe is
`render_to_artifact -> Protect.password -> store/deliver`.

Protected delivery uses `Rendro.Adapters.Mailglass.attach_artifact/3` with an already-protected `%Rendro.Artifact{}`.
```

Apply to changelog or publish-tail wording: link back to the canonical recipe and reinforce the password-boundary warnings without expanding integration scope.

## No Analog Found

None. Every likely Phase 54 file has a direct in-repo analog.

## Metadata

**Analog search scope:** `.planning/phases/47-*`, `.planning/phases/53-*`, `priv/`, `guides/`, `lib/mix/tasks/`, `scripts/`, `test/docs_contract/`, `test/mix/tasks/`, `test/scripts/`, `.github/workflows/`
**Files scanned:** 15
**Pattern extraction date:** 2026-05-06
