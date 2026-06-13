# Phase 92: Docs, Claims, Release Hygiene - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 13 likely new/modified files
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `guides/page_primitive.md` | documentation | request-response | `guides/page_primitive.md` | exact |
| `guides/recipes.md` | documentation | request-response | `test/docs_contract/launch_artifacts_claims_test.exs` | role-match |
| `guides/api_stability.md` | documentation | request-response | `guides/api_stability.md` | exact |
| `README.md` | documentation | request-response | `README.md` | exact |
| `ADOPTION.md` | documentation | request-response | `ADOPTION.md` | exact |
| `CHANGELOG.md` | documentation | request-response | `test/docs_contract/api_stability_claims_test.exs` | role-match |
| `priv/support_matrix.json` | config | transform | `priv/support_matrix.json` | exact |
| `priv/schemas/support_matrix.schema.json` | config | transform | `priv/schemas/support_matrix.schema.json` | exact |
| `test/docs_contract/page_primitive_claims_test.exs` | test | file-I/O | `test/docs_contract/page_primitive_claims_test.exs` | exact |
| `test/docs_contract/pdfjs_advisory_claims_test.exs` | test | file-I/O | `test/docs_contract/pdfjs_advisory_claims_test.exs` | exact |
| `test/docs_contract/adoption_claims_test.exs` | test | file-I/O | `test/docs_contract/adoption_claims_test.exs` | exact |
| `test/docs_contract/launch_artifacts_claims_test.exs` | test | batch | `test/docs_contract/launch_artifacts_claims_test.exs` | exact |
| `test/guardrails/required_checks_contract_test.exs` | test | file-I/O | `test/guardrails/required_checks_contract_test.exs` | exact |
| `scripts/verify_docs.exs` | script | batch | `scripts/verify_docs.exs` | exact |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `.github/workflows/ci.yml` | config | event-driven | `.github/workflows/hexdocs.yml` | role-match |
| `.github/workflows/release.yml` | config | event-driven | `.github/workflows/hexdocs.yml` | role-match |

## Likely Phase 92 Files

| File | One-Line Rationale |
|------|--------------------|
| `guides/page_primitive.md` | Primary public guide for section-local numbering tokens, `page_numbering: [restart: true]`, duplex `only_on`, and explicit unsupported boundaries. |
| `guides/recipes.md` | May add short recipe ergonomics pointers without duplicating the primitive guide. |
| `guides/api_stability.md` | Canonical support-boundary guide for support matrix, deferrals, PDF.js wording, and demand-gated shaping posture. |
| `README.md` | Should stay concise, link to updated guides, and avoid making unreleased HexDocs/package claims. |
| `ADOPTION.md` | Must keep global text shaping demand-gated and fix any v2.7 wording that now collides with shipped v2.7 page-context work. |
| `CHANGELOG.md` | Public docs/support/workflow posture changes should get a concise `[Unreleased]` entry. |
| `priv/support_matrix.json` | Add proof-backed non-viewer rows for `section_page_numbering` and `duplex_running_content` if schema/contract permits. |
| `priv/schemas/support_matrix.schema.json` | Tighten top-level non-viewer feature-row schema only as needed; do not force viewer-row fields onto feature rows. |
| `test/docs_contract/page_primitive_claims_test.exs` | Extend exact phrase, support row, evidence-path, and unsupported-boundary assertions. |
| `test/docs_contract/pdfjs_advisory_claims_test.exs` | Add advisory wording/link checks if public docs mention Phase 91 observations. |
| `test/docs_contract/adoption_claims_test.exs` | Guard demand-gated shaping language and root package/docs inclusion warning around `ADOPTION.md`. |
| `test/docs_contract/launch_artifacts_claims_test.exs` | Closest package-file inclusion test pattern for Hex tarball contents. |
| `test/guardrails/required_checks_contract_test.exs` | Add YAML/top-level `permissions: contents: read` and required/advisory check guardrails. |
| `scripts/verify_docs.exs` | Register any new docs-contract lane or update lane count. |
| `mix.exs` | Include `ADOPTION.md` in package files and optionally ExDoc extras/groups if resolving ExDoc warnings. |
| `.github/workflows/ci.yml` | Add least-privilege top-level permissions if current jobs remain compatible. |
| `.github/workflows/release.yml` | Add least-privilege top-level permissions while preserving tag-only manual release scope. |

## Pattern Assignments

### `guides/page_primitive.md` (documentation, request-response)

**Analog:** `guides/page_primitive.md`

**Current guide shape** (lines 35-46):
```markdown
## Capabilities (bounded by support matrix)

The support matrix row `page_numbering` records the exact capabilities shipped
in `priv/support_matrix.json`. The following are `supported` and backed by
proof in `test/rendro/pipeline/paginate_test.exs`:

| Capability | Status |
|---|---|
| Single-pass `{{page_number}}` / `{{total_pages}}` substitution | supported |
| Deterministic output (same input -> same bytes) | supported |
| First-page suppression via `suppress_on` | supported |
```

**Builder example pattern** (lines 50-69):
```elixir
# docs-contract: page-primitive-suppress
block = Rendro.page_number(format: "Page {{page_number}} of {{total_pages}}")

section =
  Rendro.section(
    name: :footer_suppressed,
    region: :footer,
    suppress_on: :first,
    content: [block]
  )

assert section.suppress_on == :first
```

**Boundary pattern** (lines 84-92):
```markdown
## Scope boundaries

The PAGE primitive does **not** support:

- Digital signatures or signing preparation (see `priv/support_matrix.json` `unsupported` array)
- Blanket compliance claims (see `unsupported` array)
```

**Apply to Phase 92:** Extend the same guide, not a new guide. Add examples for `Rendro.section(page_numbering: [restart: true])`, section tokens, and `only_on: :odd | :even`. Keep examples docs-contract marked and name deferrals: TOC/outlines/anchors/cross-references, charts, global text shaping, PDF.js GUI support, and full release automation.

### `test/docs_contract/page_primitive_claims_test.exs` (test, file-I/O)

**Analog:** `test/docs_contract/page_primitive_claims_test.exs`

**Imports/setup pattern** (lines 1-11):
```elixir
defmodule Rendro.DocsContract.PagePrimitiveClaimsTest do
  use ExUnit.Case, async: true

  @guide_path "guides/page_primitive.md"
  @matrix_path "priv/support_matrix.json"

  setup_all do
    guide = File.read!(@guide_path)
    matrix = Jason.decode!(File.read!(@matrix_path))
    {:ok, guide: guide, matrix: matrix}
  end
```

**Positive public claim + matrix backing pattern** (lines 13-34):
```elixir
test "guide contains Page X of Y backed phrase", %{guide: guide} do
  assert guide =~ "Page X of Y"
end

test "page_numbering evidence path exists on disk", %{matrix: matrix} do
  evidence_path = matrix["page_numbering"]["evidence"]
  assert is_binary(evidence_path), "page_numbering evidence key must be a string"
  assert File.exists?(evidence_path), "evidence path must exist: #{evidence_path}"
end
```

**Negative claim guard pattern** (lines 37-45):
```elixir
describe "page_primitive guide claim refutations" do
  test "guide does not claim digital signatures", %{guide: guide} do
    refute guide =~ "digital signatures"
  end

  test "guide does not claim full_pdf_compliance", %{guide: guide} do
    refute guide =~ "full_pdf_compliance"
  end
end
```

**Lane registration pattern** (lines 47-53):
```elixir
test "verify_docs.exs includes the page-primitive semantic-claims lane" do
  script = File.read!("scripts/verify_docs.exs")

  assert script =~
           ~r/\{"Page-primitive semantic-claims lane",\s*\["test",\s*"test\/docs_contract\/page_primitive_claims_test\.exs"\]\}/s
end
```

**Apply to Phase 92:** Add assertions for literal public strings: `page_numbering: [restart: true]`, `{{section_page_number}}`, `{{section_total_pages}}`, `only_on: :odd`, `only_on: :even`, and exact unsupported-boundary phrases.

### `priv/support_matrix.json` and `priv/schemas/support_matrix.schema.json` (config, transform)

**Analogs:** `priv/support_matrix.json`, `priv/schemas/support_matrix.schema.json`

**Existing top-level non-viewer feature row** (`priv/support_matrix.json` lines 400-410):
```json
"page_numbering": {
  "surface": "page_numbering",
  "status": "supported",
  "evidence": "test/rendro/pipeline/paginate_test.exs",
  "recorded_at": "2026-05-29",
  "capabilities": {
    "single_pass_substitution": "supported",
    "deterministic_output": "supported",
    "suppress_on_first_page": "supported"
  }
}
```

**Schema currently permits top-level feature rows** (`priv/schemas/support_matrix.schema.json` lines 83-88):
```json
"unsupported": {
  "type": "array",
  "items": { "type": "string" }
}
},
"additionalProperties": true,
```

**Viewer-row constraints to avoid misapplying to feature rows** (`priv/schemas/support_matrix.schema.json` lines 94-118):
```json
"viewer_row": {
  "type": "object",
  "additionalProperties": false,
  "required": ["status"],
  "properties": {
    "status": {
      "type": "string",
      "enum": ["supported", "unverified", "explicit_deferral"]
    },
    "proof": {
      "type": "array",
      "items": { "type": "string", "minLength": 1 },
      "uniqueItems": true
    },
    "evidence": {
      "type": "string",
      "pattern": "^priv/viewer_evidence/[a-z0-9_]+/[a-z0-9_]+\\.md$"
    },
    "recorded_at": { "type": "string", "format": "date" },
    "viewer_kind": {
      "type": "string",
      "enum": ["manual", "pdfium-cli", "pdfjs-dist"]
    },
    "evidence_deferred": { "type": "string", "minLength": 40 }
  }
```

**Apply to Phase 92:** Prefer new top-level rows shaped like `page_numbering`, for example `section_page_numbering` and `duplex_running_content` with `surface`, `status`, `evidence`, `recorded_at`, and `capabilities`. Do not place these under `viewers`, and do not add `viewer_kind` or viewer evidence paths for engine features.

### `guides/api_stability.md` (documentation, request-response)

**Analog:** `guides/api_stability.md`

**Support-boundary prose pattern** (lines 67-83):
```markdown
## Per-Surface Support Boundaries

## Interactive Forms Support Boundary

Rendro supports authored AcroForm text fields, checkboxes, radio groups, and the explicit `Rendro.signature_field/2` helper for unsigned signature placeholders.

Structural validation through `pdfinfo`/Poppler proves PDF structure only. It does not prove interactive viewer behavior.

Unsupported narratives: digital signatures, signer identity or trust, tamper evidence, compliance narratives, and PAdES/LTV/TSA/OCSP/CRL support remain unsupported.
```

**Viewer-specific deferral wording pattern** (lines 91-97):
```markdown
PDF.js is `explicit_deferral` for `forms` because the four-check save-and-reopen round-trip failed on the representative fixture during operator review - edit/toggle persistence is not reliable.

Other viewers are not part of Rendro's supported contract unless `priv/support_matrix.json` later records proof-backed support for them.
```

**Mirrored deferral list pattern** (lines 185-204):
```markdown
## Explicit Deferral Reasons (matrix-mirrored)

Every `explicit_deferral` viewer row in `priv/support_matrix.json` carries a named `evidence_deferred` reason. These are mirrored verbatim here so the adopter-visible contract states why a viewer is deferred rather than `unsupported`:

- forms x PDF.js: PDF.js failed the forms four-check save-and-reopen round-trip on the representative fixture during operator review; edit_or_toggle persistence is not reliable.
- text_shaping x arabic: Arabic shaping requires contextual glyph substitution, joining forms, and right-to-left reordering that Shaper.Simple does not implement; full shaping is demand-gated at LNCH-03.
```

**Apply to Phase 92:** Keep this file as the canonical support-boundary and deferral home. Update stale text-shaping `v2.7` references to demand-gated wording because v2.7 is now page context/browser proof hardening, not shaping.

### `test/docs_contract/pdfjs_advisory_claims_test.exs` (test, file-I/O)

**Analog:** `test/docs_contract/pdfjs_advisory_claims_test.exs`

**Public docs list pattern** (lines 27-33):
```elixir
@public_docs [
  "README.md",
  "guides/api_stability.md",
  "guides/viewer_evidence.md",
  "guides/recipes.md",
  "guides/comparison.md"
]
```

**Advisory observation contract pattern** (lines 64-113):
```elixir
test "observation schema and committed observations use the advisory contract" do
  schema = @schema_path |> File.read!() |> JSON.decode!()

  assert schema["title"] == "Rendro PDF.js advisory observation"
  assert schema["properties"]["pdfjs_dist_version"]["const"] == "6.0.227"
  assert schema["properties"]["observer"]["const"] == "rendro-pdfjs-advisory"

  for path <- @observation_paths do
    observation = path |> File.read!() |> JSON.decode!()
    assert observation["advisory_boundary"] =~ "Pinned PDF.js advisory observation only"
    assert observation["advisory_boundary"] =~ "not GUI-viewer proof"
  end
end
```

**Banned PDF.js wording pattern** (lines 139-155):
```elixir
test "public docs do not claim unqualified PDF.js support" do
  banned_phrases = [
    "PDF.js support",
    "PDF.js is supported",
    "supports PDF.js",
    "PDF.js viewer support",
    "PDF.js GUI support"
  ]

  for path <- @public_docs do
    content = File.read!(path)

    for phrase <- banned_phrases do
      refute String.contains?(content, phrase),
             "#{path} contains banned unqualified PDF.js claim #{inspect(phrase)}"
    end
  end
end
```

**PDF.js deferral preservation pattern** (lines 158-170):
```elixir
for path <- @pdfjs_deferral_paths do
  row = get_in(matrix, path)

  assert row["status"] == "explicit_deferral", Enum.join(path, ".")
  assert is_binary(row["evidence_deferred"])
  refute Map.has_key?(row, "evidence")
  refute Map.has_key?(row, "recorded_at")
  refute Map.has_key?(row, "viewer_kind")
  refute Map.has_key?(row, "proof")
end
```

**Apply to Phase 92:** If public docs mention Phase 91, require "pinned PDF.js advisory observations" and links/references to `priv/pdfjs_observations/`. Do not add a support matrix PDF.js support row.

### `mix.exs` and package/HexDocs inclusion tests (config/test, batch)

**Analogs:** `mix.exs`, `test/docs_contract/launch_artifacts_claims_test.exs`

**Package files pattern** (`mix.exs` lines 77-94):
```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url},
    files: ~w(
      lib
      assets/rendro
      priv/branded
      bench/results
      guides
      .formatter.exs
      mix.exs
      README.md
      LICENSE
      NOTICE
      CHANGELOG.md
    )
  ]
end
```

**ExDoc extras pattern** (`mix.exs` lines 116-128):
```elixir
extras: [
  "README.md",
  "guides/integrations.md",
  "guides/branding.md",
  "guides/api_stability.md",
  "guides/upgrading_to_1.0.md",
  "guides/viewer_evidence.md",
  "guides/page_primitive.md",
  "guides/recipes.md",
  "guides/user_flows_and_jtbd.md",
  "guides/comparison.md",
  "guides/livebook/first_invoice.livemd"
],
```

**Hex tarball inclusion test pattern** (`test/docs_contract/launch_artifacts_claims_test.exs` lines 132-157):
```elixir
test "hex package includes public launch assets" do
  tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
  File.rm(tarball)
  on_exit(fn -> File.rm(tarball) end)

  {output, 0} = System.cmd("mix", ["hex.build"], stderr_to_stdout: true)
  assert output =~ tarball
  assert File.exists?(tarball)

  list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
  {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

  expected_assets = [
    @manifest_path,
    "assets/rendro/manual.pdf"
  ]

  for asset <- expected_assets do
    assert contents =~ asset
  end
end
```

**Apply to Phase 92:** Add `ADOPTION.md` to package `files` because README links it. If adding to ExDoc extras, also place it in a docs group. Add/extend a package inclusion assertion for `ADOPTION.md`; this is the closest pattern for proving Hex package contents.

### GitHub Actions permissions and required-check guardrails (config/test, event-driven)

**Analogs:** `.github/workflows/hexdocs.yml`, `test/guardrails/required_checks_contract_test.exs`

**Existing least-privilege workflow pattern** (`.github/workflows/hexdocs.yml` lines 12-14):
```yaml
permissions:
  contents: read
```

**YAML parse pattern** (`test/guardrails/required_checks_contract_test.exs` lines 83-88):
```elixir
test "ci.yml parses as YAML" do
  ci = File.read!(@ci_path)

  assert {:ok, %{"jobs" => jobs}} = YamlElixir.read_from_string(ci)
  assert is_map(jobs)
end
```

**Required/advisory separation pattern** (`test/guardrails/required_checks_contract_test.exs` lines 191-221):
```elixir
test "required test job runs only the deterministic mix ci lane" do
  ci = File.read!(@ci_path)
  test_block = ci_job_block!(ci, "test")

  assert test_block =~ "run: mix ci"

  forbidden_required_fragments = [
    "setup-node",
    "npm",
    "pdfjs",
    "pdfjs-dist",
    "pdfjs_observer"
  ]

  for fragment <- forbidden_required_fragments do
    refute test_block =~ fragment
  end
end
```

**Advisory graph-disconnected pattern** (`test/guardrails/required_checks_contract_test.exs` lines 236-251):
```elixir
for {job, command} <- expected_advisory_jobs do
  block = ci_job_block!(ci, job)

  assert block =~ "continue-on-error: true"
  assert block =~ "run: #{command}"
  refute block =~ ~r/^\s+needs:/m
end
```

**Job-block helper pattern** (`test/guardrails/required_checks_contract_test.exs` lines 310-318):
```elixir
defp ci_job_block!(ci, job_name) do
  escaped_job_name = Regex.escape(job_name)
  pattern = ~r/^  #{escaped_job_name}:\n(?:(?!^  [A-Za-z0-9_-]+:).*(?:\n|$))*/m

  case Regex.run(pattern, ci) do
    [block] -> block
    _ -> flunk("expected CI job block #{inspect(job_name)}")
  end
end
```

**Apply to Phase 92:** Add tests that parse `.github/workflows/ci.yml`, `.github/workflows/hexdocs.yml`, and `.github/workflows/release.yml` and assert top-level `permissions: %{"contents" => "read"}` where intended. Preserve exact-tag release preflight and required/advisory contexts.

### Release preflight and release automation scope (script/test, batch)

**Analogs:** `scripts/release_preflight_proof.exs`, `test/scripts/release_preflight_proof_test.exs`

**Exact-tag release pattern** (`scripts/release_preflight_proof.exs` lines 30-87):
```elixir
OptionParser.parse(args,
  strict: [
    ref: :string,
    worktree: :string,
    dry_run: :boolean,
    keep: :boolean,
    current_version_tag: :boolean
  ],
  aliases: [r: :ref, w: :worktree]
)

def validate_ref("v" <> rest = ref) do
  if Regex.match?(~r/^\d+\.\d+\.\d+([-.][0-9A-Za-z.-]+)?$/, rest) do
    :ok
  else
    {:error, "ref must be an exact release tag like vX.Y.Z; got #{ref}"}
  end
end
```

**Isolated worktree proof pattern** (`scripts/release_preflight_proof.exs` lines 97-125):
```elixir
with {_, 0} <-
       run_command(context, "git", ["rev-parse", "--verify", "#{options.ref}^{commit}"]),
     {_, 0} <-
       run_command(context, "git", [
         "worktree",
         "add",
         "--detach",
         options.worktree,
         options.ref
       ]),
     {deps_output, 0} <-
       run_command(context, "mix", ["deps.get"], cd: options.worktree),
     {preflight_output, status} <-
       run_command(context, "mix", ["release.preflight"], cd: options.worktree),
     :ok <- cleanup(options, cleanup_state, context) do
```

**Preflight test pattern** (`test/scripts/release_preflight_proof_test.exs` lines 8-14, 29-56):
```elixir
test "requires explicit ref and worktree arguments" do
  assert {:error, "missing required --ref vX.Y.Z or --current-version-tag"} =
           ReleasePreflightProof.parse_args([])

  assert {:error, "missing required --worktree PATH"} =
           ReleasePreflightProof.parse_args(["--ref", "v0.2.0"])
end

test "rejects ambiguous or non-release refs" do
  assert {:error, "ref must be an exact release tag like vX.Y.Z; got not-a-real-tag"} =
           ReleasePreflightProof.validate_ref("not-a-real-tag")
end
```

**Apply to Phase 92:** Keep release automation bounded to existing tag/preflight posture. Do not introduce release-please, token-driven publishing changes, or broader release orchestration.

## Shared Patterns

### Docs-Contract Style

**Source:** `test/docs_contract/forms_claims_test.exs` lines 50-86
**Apply to:** Public guide/readme/adoption claim tests
```elixir
guide = File.read!("guides/api_stability.md")

assert guide =~
         "Rendro supports authored AcroForm text fields, checkboxes, radio groups, and the explicit `Rendro.signature_field/2` helper for unsigned signature placeholders."

refute guide =~ "standard PDF viewers"
refute guide =~ "digital signatures are supported"
refute guide =~ "viewer support for signature fields"
refute guide =~ "PAdES is supported"
refute guide =~ "mobile PDF support"
```

Use exact positive phrases for claims that must exist, and exact negative guards for wording that must not appear.

### Explicit Deferral Row Guard

**Source:** `test/docs_contract/signing_claims_test.exs` lines 126-140
**Apply to:** PDF.js, mobile viewer, and unsupported scope deferrals
```elixir
for row <- [
      matrix["signing_preparation"]["viewers"]["pdfjs"],
      matrix["signing"]["viewers"]["pdfjs"],
      matrix["signing"]["long_lived"]["viewers"]["pdfjs"]
    ] do
  assert row["status"] == "explicit_deferral"
  assert is_binary(row["evidence_deferred"])
  refute Map.has_key?(row, "evidence")
  refute Map.has_key?(row, "recorded_at")
  refute Map.has_key?(row, "viewer_kind")
  refute Map.has_key?(row, "proof")
end
```

### Docs Verification Registration

**Source:** `scripts/verify_docs.exs` lines 8-36
**Apply to:** Any new docs-contract test lane
```elixir
lanes = [
  {"Page-primitive semantic-claims lane",
   ["test", "test/docs_contract/page_primitive_claims_test.exs"]},
  {"PDF.js advisory claims lane", ["test", "test/docs_contract/pdfjs_advisory_claims_test.exs"]},
  {"Adoption claims lane", ["test", "test/docs_contract/adoption_claims_test.exs"]}
]
```

If Phase 92 adds a new test file, register it here and update `test/guardrails/required_checks_contract_test.exs` lane count. If existing test files are extended, keep the count unchanged.

### Offline Guardrail Tests

**Source:** `test/guardrails/required_checks_contract_test.exs` lines 288-296
**Apply to:** Workflow/branch-protection guardrail tests
```elixir
test "does not reference network APIs or tokens" do
  source = File.read!(__ENV__.file)

  refute source =~ ~r/\bReq\./
  refute source =~ ~r/\bHTTPoison\b/
  refute source =~ Enum.join(["gh", " ", "api"])
  refute source =~ Enum.join(["GITHUB_", "TOKEN"])
end
```

Keep guardrail tests repository-state based. Do not query live GitHub branch protection.

## Footguns / Mismatches

- `ADOPTION.md` is linked from `README.md` lines 39-48 but is not included in `mix.exs` package files lines 81-93. This causes a public package/HexDocs mismatch and should be fixed with a package inclusion test.
- `ADOPTION.md` and current matrix deferrals still say "v2.7 global text shaping" (`ADOPTION.md` lines 5 and 9; `priv/support_matrix.json` lines 457, 461, 465), but v2.7 is now page context/browser proof hardening. Update to "conditional global text shaping" or equivalent demand-gated wording.
- PDF.js wording must remain "pinned PDF.js advisory observations" and "not GUI-viewer proof". Do not add "PDF.js support", "PDF.js viewer support", or support-matrix promotion rows.
- Support-matrix `viewer_row` schema requires viewer evidence paths for supported viewer rows; non-viewer engine feature rows should copy `page_numbering`, not viewer rows.
- `.github/workflows/hexdocs.yml` already has top-level `permissions: contents: read`; `ci.yml` and `release.yml` currently do not. Add tests before or with workflow edits so least-privilege posture is guarded.
- Release automation is intentionally tag/preflight based. Do not introduce release-please, automatic version bumping, or token-heavy release orchestration in Phase 92.
- `scripts/verify_docs.exs` lane count is asserted as exactly 21 in `test/guardrails/required_checks_contract_test.exs` lines 150-170. Adding a new docs-contract file requires updating that count; extending existing files avoids churn.

## No Analog Found

None. All likely Phase 92 files have exact or role-match analogs in the current codebase.

## Metadata

**Analog search scope:** `guides/`, `README.md`, `ADOPTION.md`, `CHANGELOG.md`, `priv/support_matrix.json`, `priv/schemas/support_matrix.schema.json`, `test/docs_contract/`, `test/guardrails/`, `scripts/`, `.github/workflows/`, `mix.exs`.
**Files scanned:** 31 paths listed from targeted `rg --files`, plus Phase 89-91 summaries.
**Pattern extraction date:** 2026-06-13
