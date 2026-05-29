# Phase 72 Pattern Map: Closure — Audit, Polish, and Ship

**Mapped:** 2026-05-29  
**Sources:** `72-CONTEXT.md`, `72-RESEARCH.md`, Phase 68–71 patterns, existing codebase analogs  
**Phase boundary:** Close GUARDRAIL-02 and v2.3 through **audit ritual + publication closure** — no new matrix recording, no CI topology changes, no Hex `files:` expansion. Phase 71 already terminalized all 26 cells (`supported=17`, `explicit_deferral=9`, `unverified=0`).

---

## 1. File role map

### Create — guardrails contract (Wave 1)

| Path | Role | Closest analog |
|------|------|----------------|
| `priv/guardrails/required_status_checks.json` | Committed normalized baseline: branch, `strict`, `policy`, sorted `required_contexts`, per-context semantic class + job→command mapping, advisory contexts | `priv/support_matrix.json` (machine-readable contract) + `priv/schemas/*.json` (versioned schema metadata) |
| `test/guardrails/required_checks_contract_test.exs` | Offline wiring proof: JSON integrity, `ci.yml` job names, behavioral command strings, eight docs-contract lanes — **no GitHub API** | `test/mix/tasks/ci_alias_contract_test.exs` (alias ↔ documented contract); `viewer_evidence_claims_test.exs` describe `"docs-contract lane registration"` |
| `scripts/audit_branch_protection.exs` | Live GitHub protection fetch → normalize `{strict, contexts}` → fail if baseline ⊄ live or `strict` false | `scripts/release_preflight_proof.exs` (close-only script, `System.halt`, isolated from `mix ci`) |

### Create — verification ledger (Wave 2)

| Path | Role | Closest analog |
|------|------|----------------|
| `.planning/phases/72-closure-audit-polish-and-ship/72-VERIFICATION.md` | B+C hybrid closure packet: must-haves table, machine `list --json` export, trust-sensitive spot-check (~8–12 rows), GUARDRAIL-02 audit table + live snapshot | `70-VERIFICATION.md` (frontmatter + must-haves + automated checks + gaps) |
| `.planning/phases/69-.../69-VERIFICATION.md` | Lightweight backfill if milestone audit blocks | `70-VERIFICATION.md` stub citing SUMMARY metrics |
| `.planning/phases/71-.../71-VERIFICATION.md` | Lightweight backfill if milestone audit blocks | Same |

### Modify — staleness strict gate (Wave 2)

| Path | Role | Closest analog |
|------|------|----------------|
| `lib/mix/tasks/rendro/viewer_evidence.ex` | Add `validate --strict`; thread `strict?` into `run_validate/1`; reclassify staleness warnings as fatal when strict | Existing `pop_json_flag/1` + `partition_warnings/1` advisory split |
| `lib/rendro/viewer_evidence/validator.ex` | Optional: `strict_staleness?:` on `run_full/3` — only if cleaner than task-level reclassification | `validate_promotion_complete/2` `strict:` opt pattern |
| `test/mix/tasks/viewer_evidence_task_test.exs` | `--strict` exit 1 on backdated fixture; exit 0 on production matrix | Existing `capture_shell_messages/1` + `describe "validate/1"` |
| `test/rendro/viewer_evidence/validator_test.exs` | Unit: `staleness_warnings/1` with synthetic backdated `recorded_at` | Tier-B fixture subtests in `viewer_evidence_claims_test.exs` |

### Modify — guide polish + docs-contract (Wave 3)

| Path | Role | Closest analog |
|------|------|----------------|
| `guides/viewer_evidence.md` | Phase 71 automated path + `trust_sensitive_viewer_evidence_live_test.exs`; fix stale manual steps; Appendix D `--strict` | Phase 70 automated path block (lines 29–67); existing Appendix D task table |
| `guides/api_stability.md` | Drift-fix only — deferral substrings + supported path mirrors | Phase 70 STACK mirror pattern (`70-PATTERNS` §2.8) |
| `test/docs_contract/viewer_evidence_claims_test.exs` | Add missing path asserts (`forms/chrome_pdfium.md`, `signature_widget/chrome_pdfium.md`); optional deferral mirror | Existing `"api stability guide mirrors..."` for loop (lines 32–51) |

### Modify — ship mechanics (Wave 3)

| Path | Role | Closest analog |
|------|------|----------------|
| `CHANGELOG.md` | Freeze `## [0.3.0] - 2026-05-08` (pre–v2.3 viewer); move Viewer Evidence bullets to `## [0.3.1] - <ship-date>` | Phase 69/70/71 CHANGELOG discipline under `#### Viewer Evidence (v2.3)` |
| `mix.exs` | Bump `@version` to `"0.3.1"`; **`files:` unchanged** (operator priv stays repo-only) | v1.10 tag-push release precedent |
| `.github/workflows/release.yml` | Optional: add `mix release.preflight` before `hex.publish` | `release-proof` CI job runs `release_preflight_proof.exs` |

### Optional modify (discretion)

| Path | Role | Closest analog |
|------|------|----------------|
| `test/docs_contract/branding_claims_test.exs` or new test | Negative `hex.build`: refute `priv/viewer_evidence/`, refute `priv/support_matrix.json` | `describe "hex tarball contents"` (lines 41–56) |

### Explicitly out of scope (do not create/modify)

- `priv/support_matrix.json` cell statuses — closure audits only
- `.github/workflows/ci.yml` required job semantics — advisory `viewer-evidence-live-proof` already present
- GitHub branch protection UI settings — already correct; audit verifies
- `mix.exs` `package/0` `files:` — no Hex packaging of operator workspace (D-29)
- `mix rendro.viewer_evidence init` — v2.4 backlog (D-28)
- Wire `validate --strict` into `mix ci`, docs-contract lane 8, or branch protection (D-09)
- Promote `viewer-evidence-live-proof` to required on `main` (D-32)
- `PITFALLS.md` edit — reconcile via JSON `supersedes_planning_refs` + VERIFICATION note (default)

---

## 2. Pattern excerpts

### 2.1 Required-check baseline JSON — `priv/guardrails/required_status_checks.json`

**Pattern:** Machine-readable contract in `priv/` with `schema_version`, milestone provenance, sorted required set, semantic classes, and explicit advisory fold-in notes. Single source for offline test + live audit script.

**Recommended shape (from RESEARCH §2.6):**

```json
{
  "schema_version": 1,
  "branch": "main",
  "strict": true,
  "policy": "additive_only",
  "since_milestone": "v2.3",
  "required_contexts": [
    "long-lived-live-proof",
    "release-proof",
    "signing-live-proof",
    "test"
  ],
  "contexts": [
    {
      "name": "test",
      "semantic_class": "deterministic",
      "ci_job": "test",
      "command": "mix ci",
      "notes": "Includes mix test (8 docs-contract lanes), format, hex.build, compile --warnings-as-errors, docs, credo, dialyzer. Viewer-evidence schema/lint folded here per Phase 68 D-18 — not a separate required context."
    }
  ],
  "advisory_contexts": [
    {
      "name": "viewer-evidence-live-proof",
      "semantic_class": "behavioral_live_proof",
      "ci_job": "viewer-evidence-live-proof",
      "command": "mix test --include live_pdf_tools test/rendro/adapters/*_viewer_evidence_live_test.exs (7 files)",
      "notes": "Phase 71 structural-proxy evidence regen; not required on main per D-18/D-32."
    }
  ],
  "supersedes_planning_refs": {
    "pitfalls_7_viewer_evidence_schema_required": false,
    "rationale": "Structural viewer-evidence enforcement folds into test job; no fourth required GitHub context."
  }
}
```

**v2.3 close baseline (D-03):** Four required contexts only. Pre-v2.3 and v2.3-close **sets are identical**; semantics unchanged — v2.3 additive change is advisory `viewer-evidence-live-proof` job + in-tree tooling.

**Folded into `test` / `mix ci` (not separate GitHub contexts):**

```60:70:mix.exs
  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "hex.build",
        "compile --warnings-as-errors",
        "test",
        "docs",
        "credo --strict",
        "dialyzer"
      ]
    ]
  end
```

Lane 8 runs because `mix test` includes `test/docs_contract/*.exs`; `mix docs.contract` is explicit in `mix release.preflight` Phase 2 only.

---

### 2.2 Offline guardrails contract test — `test/guardrails/required_checks_contract_test.exs`

**Pattern:** Read committed JSON + `ci.yml` + `verify_docs.exs` as strings; assert structural invariants. Fork-safe — no network, no tokens.

**Closest analog — CI alias contract:**

```4:17:test/mix/tasks/ci_alias_contract_test.exs
  test "ci alias matches the documented QUAL-01 contract" do
    project = Rendro.MixProject.project()
    aliases = Keyword.fetch!(project, :aliases)
    ci_steps = Keyword.fetch!(aliases, :ci)

    assert ci_steps == [
             "format --check-formatted",
             "hex.build",
             "compile --warnings-as-errors",
             "test",
             "docs",
             "credo --strict",
             "dialyzer"
           ]
  end
```

**Lane registration analog (duplicate or share helper — guard against drift):**

```243:250:test/docs_contract/viewer_evidence_claims_test.exs
  describe "docs-contract lane registration" do
    @describetag :lane_registration
    test "verify_docs.exs includes the viewer evidence semantic-claims lane" do
      script = File.read!("scripts/verify_docs.exs")

      assert script =~
               ~s|{"Viewer evidence semantic-claims lane", ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]}|
    end
```

**Eight-lane registry (exact count + lane 8 identity):**

```7:16:scripts/verify_docs.exs
lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  {"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]},
  {"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]},
  {"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]},
  {"Signing semantic-claims lane", ["test", "test/docs_contract/signing_claims_test.exs"]},
  {"Embedded artifact semantic-claims lane", ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]},
  {"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]},
  {"Viewer evidence semantic-claims lane", ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]}
]
```

**Suggested describe blocks (D-04):**

1. Baseline JSON parses; `required_contexts` sorted; `strict == true`; `policy == "additive_only"`.
2. `ci.yml` contains job keys for all `required_contexts` + `viewer-evidence-live-proof`.
3. Behavioral command wiring — `signing-live-proof` contains `live_signing` + `signing_live_test.exs`; `long-lived-live-proof` contains `live_pdf_tools` + `signing_live_test.exs`.
4. `verify_docs.exs` registers exactly eight lanes; lane 8 is `viewer_evidence_claims_test.exs`.
5. Each `contexts[].ci_job` in JSON exists in `ci.yml`.

**CI job names to match (existing topology — do not change):**

```11:29:.github/workflows/ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    ...
      - name: Run CI
        run: mix ci
```

```91:123:.github/workflows/ci.yml
  signing-live-proof:
    ...
      - name: Run Signing Live Proof
        run: mix test --include live_signing test/rendro/adapters/signing_live_test.exs
```

```125:158:.github/workflows/ci.yml
  long-lived-live-proof:
    ...
      - name: Run Long-Lived Live Proof
        run: mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs
```

```160:178:.github/workflows/ci.yml
  release-proof:
    ...
      - name: Verify Release Proof
        run: mix run scripts/release_preflight_proof.exs --current-version-tag --worktree "$RUNNER_TEMP/rendro-release-proof"
```

---

### 2.3 Live branch-protection audit — `scripts/audit_branch_protection.exs`

**Pattern:** Close-only Elixir script; read baseline JSON; fetch GitHub API; normalize; print JSON on success, gap diff on stderr; `System.halt(1)` on failure. **Not** invoked from `mix ci` (D-04 fork safety).

**Script shell analog — exit semantics:**

```1:28:scripts/release_preflight_proof.exs
defmodule Rendro.ReleasePreflightProof do
  @moduledoc false

  def run(args, context \\ default_context()) do
    with {:ok, options} <- parse_args(args, context),
         :ok <- validate_ref(options.ref),
         :ok <- validate_worktree(options.worktree) do
      ...
    else
      {:error, message} ->
        Mix.shell().error(message)
        System.halt(1)
    end
  end
```

**Normalization logic (RESEARCH §2.7):**

```elixir
live_contexts =
  protection
  |> get_in(["required_status_checks", "contexts"])
  |> Enum.map(& &1["context"])
  |> Enum.sort()

live_strict = get_in(protection, ["required_status_checks", "strict"])

missing = baseline_required -- live_contexts
# fail if missing != [] or live_strict != true
```

**Auth:** `GITHUB_TOKEN` with repo admin read. Repo identity from `mix.exs` `@source_url` (`https://github.com/szTheory/rendro`).

**Live snapshot already matches baseline (2026-05-29):**

```json
{ "strict": true, "contexts": ["test", "signing-live-proof", "release-proof", "long-lived-live-proof"] }
```

**VERIFICATION capture (D-06):** Record command, timestamp, normalized JSON, mapping table. Status `gaps_found` with explicit gap — never silent pass.

**v2.2 lesson:** Artifact closure ≠ operational closure — committed contract + offline test + live snapshot, not checklist theatre.

---

### 2.4 `validate --strict` — Mix task extension

**Pattern:** Add flag beside existing `--json`; default behavior unchanged (Phase 68 D-17); strict scope **staleness only** (legacy promotion warnings already zero).

**Current advisory partition (extend, do not replace):**

```343:350:lib/mix/tasks/rendro/viewer_evidence.ex
  defp partition_warnings(warnings) do
    Enum.split_with(warnings, &advisory_warning?/1)
  end

  defp advisory_warning?(warning) do
    String.contains?(warning, "missing promotion-complete") or
      String.contains?(warning, "is older than")
  end
```

**Current `run_validate` flow:**

```203:217:lib/mix/tasks/rendro/viewer_evidence.ex
  defp run_validate(_json?) do
    case Validator.run_full(@matrix_path, @evidence_root, []) do
      {:ok, warnings} ->
        {advisory, fatal} = partition_warnings(warnings)

        Enum.each(advisory, fn warning -> Mix.shell().error(warning) end)
        Enum.each(fatal, fn warning -> Mix.shell().error(warning) end)

        if fatal == [] do
          print_validate_summary(warnings)
          :ok
        else
          Mix.shell().error("Viewer evidence validation failed.")
          exit({:shutdown, 1})
        end
```

**Implementation path (minimal diff):**

1. `parse_args!`: accept `["validate", "--strict"]` (add `pop_strict_flag/1` alongside `pop_json_flag/1`).
2. Thread `strict?: true` into `run_validate/1`.
3. When `strict?`, treat staleness warnings (`"is older than"`) as **fatal** — either `partition_warnings(warnings, strict?: true)` or promote in `Validator.run_full/3`.
4. Update moduledoc exit-code table: `validate --strict` → exit 1 on staleness.
5. **Do not** wire into `mix ci`, lane 8, or branch protection (D-09).

**Flag parsing analog:**

```165:168:lib/mix/tasks/rendro/viewer_evidence.ex
  defp pop_json_flag(args) do
    {flags, rest} = Enum.split_with(args, &(&1 == "--json"))
    {flags != [], rest}
  end
```

**Moduledoc exit codes to extend:**

```54:60:lib/mix/tasks/rendro/viewer_evidence.ex
  ## Exit codes (D-22)

    * `list` — **0** when the matrix parses successfully.
    * `missing` — **1** when any `unverified` cell exists; **0** when none.
    * `validate` — **1** on Tier-A schema errors, evidence-file failures, or orphan
      scans; **0** when only Tier-B legacy-supported warnings and/or staleness
      warnings (180 days) remain.
```

---

### 2.5 Staleness source — `Validator.staleness_warnings/1`

**Pattern:** 180-day comparison on `supported` rows with `recorded_at`; always appended to warnings list today; `--strict` promotes to fatal at operator/release gate only.

```89:112:lib/rendro/viewer_evidence/validator.ex
  @spec staleness_warnings(map()) :: [String.t()]
  def staleness_warnings(matrix) do
    today = Date.utc_today()

    matrix
    |> Matrix.enumerate_viewer_cells()
    |> Enum.flat_map(fn cell ->
      row = fetch_row(matrix, cell)

      with "supported" <- cell.status,
           recorded_at when is_binary(recorded_at) <- Map.get(row, "recorded_at"),
           {:ok, date} <- Date.from_iso8601(recorded_at) do
        if Date.diff(today, date) > @staleness_days do
          [
            "#{cell.matrix_path}: recorded_at #{recorded_at} is older than #{@staleness_days} days"
          ]
        else
          []
        end
      else
        _ -> []
      end
    end)
  end
```

**`run_full` warning assembly (staleness always advisory today):**

```125:132:lib/rendro/viewer_evidence/validator.ex
      warnings =
        []
        |> Kernel.++(legacy_supported_warnings(matrix))
        |> Kernel.++(validate_referenced_evidence(matrix, repo_root))
        |> Kernel.++(orphan_violations(matrix, evidence_root, repo_root))
        |> Kernel.++(staleness_warnings(matrix))

      {:ok, warnings}
```

**Production state at ship:** All `supported` rows `recorded_at` **2026-05-28** or **2026-05-29** — both `validate` and `validate --strict` exit 0 unless tests use backdated fixtures.

**Browserslist precedent (D-11):** Structural honesty merge-blocking; temporal refresh operator-owned with explicit opt-in strictness.

---

### 2.6 Mix task tests — `--strict` exit codes

**Pattern:** `capture_shell_messages/1` + synthetic fixture matrix with backdated `recorded_at`; production matrix asserts exit 0.

**Existing harness:**

```95:107:test/mix/tasks/viewer_evidence_task_test.exs
  defp capture_shell_messages(fun) do
    original_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    result =
      try do
        fun.()
      after
        Mix.shell(original_shell)
      end

    {flush_shell_messages([]), result}
  end
```

**Existing production validate test:**

```64:72:test/mix/tasks/viewer_evidence_task_test.exs
  describe "validate/1" do
    test "returns :ok on the unchanged production matrix" do
      {messages, result} = capture_shell_messages(fn -> ViewerEvidence.run(["validate"]) end)

      assert result == :ok
      output = Enum.join(messages, "\n")
      assert output =~ "Viewer evidence validation passed"
      refute output =~ "missing promotion-complete"
    end
  end
```

**Add:**

```elixir
test "validate --strict exits 0 on production matrix (dates inside 180-day window)" do
  {messages, result} =
    capture_shell_messages(fn -> ViewerEvidence.run(["validate", "--strict"]) end)

  assert result == :ok
  assert Enum.join(messages, "\n") =~ "Viewer evidence validation passed"
end

# Unit test with fixture: backdated recorded_at → exit {:shutdown, 1}
```

**Preserve contract test — task not in `mix ci`:**

```89:92:test/mix/tasks/viewer_evidence_task_test.exs
    test "mix ci alias does not register rendro.viewer_evidence" do
      mix_source = File.read!("mix.exs")
      refute mix_source =~ "rendro.viewer_evidence"
    end
```

---

### 2.7 `72-VERIFICATION.md` — B+C hybrid ledger

**Pattern:** YAML frontmatter + must-haves table + machine export + spot-check + GUARDRAIL-02 audit + automated checks + gaps. **Do not** hand-maintain 26-row matrix duplicate (D-17).

**Format precedent:**

```1:52:.planning/phases/70-consolidate-already-validated-surfaces/70-VERIFICATION.md
---
status: passed
phase: 70-consolidate-already-validated-surfaces
verified: 2026-05-29
requirements: [VIEWER-01]
score: 12/12
---

# Phase 70 Verification Report
...
## Must-Haves Verified
| # | Criterion | Status | Evidence |
...
## Automated Checks Run
```bash
mix rendro.viewer_evidence validate   # PASS
...
```
## Gaps
None.
```

**Phase 72 extensions (D-17–D-21):**

| Section | Source | Notes |
|---------|--------|-------|
| Matrix ledger | `mix rendro.viewer_evidence list --json` | Fenced JSON or script-trimmed table; counts from CLI aggregates |
| Trust-sensitive spot-check | D-19 named cells | ~8–12 rows: `signature_widget × pdfjs` (#4202), `signed_artifact × apple_preview`, signing_prep inheritance, long-lived deferral batch, `forms × adobe_acrobat_reader`, pdfium promoted rows |
| GUARDRAIL-02 audit | Baseline JSON + live snapshot | Pre-v2.3 vs v2.3-close mapping; `semantics changed` column (all **no** for four required) |
| Closure ritual | Both validates + guardrails test + live audit | `validate` + `validate --strict` both exit 0 at ship |

**Canonical ledger command:**

```bash
mix rendro.viewer_evidence list --json
# {"summary":{"total":26,"supported":17,"unverified":0,"explicit_deferral":9},"cells":[...]}
```

**Closure gate commands (merge-blocking vs ritual-only):**

```bash
mix test test/guardrails/required_checks_contract_test.exs   # merge-blocking (test job)
mix rendro.viewer_evidence missing                            # exit 0
mix rendro.viewer_evidence validate                           # exit 0 (advisory staleness)
mix rendro.viewer_evidence validate --strict                  # exit 0 at ship (closure only)
GITHUB_TOKEN=... mix run scripts/audit_branch_protection.exs  # close ritual, not default CI
mix docs.contract                                             # 8/8
mix run scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-preflight
```

---

### 2.8 Guide polish — `guides/viewer_evidence.md`

**Pattern:** Surgical edits only (D-22–D-24); preserve matrix/observation split and Hex omission honesty.

**Stale manual step 1 (fix):**

```77:81:guides/viewer_evidence.md
```bash
mix rendro.viewer_evidence missing
```

**Check:** Exit code **1** when unverified cells exist (expected today). Stdout lists `surface`, `viewer`, and `status` for each backlog cell. Pick your target cell from the table.
```

**Target:** Exit code **0** at v2.3 close — no unverified cells.

**Stale manual step 6 (fix):**

```123:129:guides/viewer_evidence.md
```bash
mix rendro.viewer_evidence validate
```

**Check:** Exit code **0**. Fix any Tier-A errors (schema, lint, orphan scan) before promoting. Legacy-supported rows without `evidence:` may still print advisory warnings — your new file must validate cleanly.
```

**Target:** Remove legacy promotion warning note — tier-B complete post Phase 70/71.

**Automated path extension (add Phase 71 trust-sensitive surfaces):**

```29:67:guides/viewer_evidence.md
### Automated path (Linux CI — pdfium-cli, pdfinfo, qpdf)
...
mix rendro.viewer_evidence record protection apple_preview \
  --fixture test/fixtures/protection_support_fixture.pdf \
  --recorded-by ci:viewer-evidence-live-proof
```

**Add:** Phase 71 `record` commands for signature_widget, signed_artifact, signing_preparation, long_lived_signed_artifact; link `trust_sensitive_viewer_evidence_live_test.exs`; extend CI file list to seven adapter tests (matches `ci.yml` lines 82–89).

**Appendix D extension — `--strict` table row:**

```278:286:guides/viewer_evidence.md
## Appendix D — Mix task reference
...
| `validate` | 1 on Tier-A errors; 0 with legacy/staleness warnings only | Schema + evidence files + orphan scan |
```

**Add row:**

| `validate --strict` | 1 on Tier-A errors **or** staleness (>180 days on `supported`); 0 otherwise | Operator/release gate when refreshing evidence — **not** merge-blocking CI |

**Prerequisites unchanged (Hex honesty):**

```9:11:guides/viewer_evidence.md
Recording requires a **full repo checkout**. The Hex package ships `guides/` but omits `priv/support_matrix.json`, `priv/schemas/`, and `priv/viewer_evidence/`. HexDocs is read-only documentation for this recipe — you cannot record promotions from the published package alone.
```

---

### 2.9 Docs-contract hardening — `viewer_evidence_claims_test.exs`

**Pattern:** Extend path assert loop; optional matrix-driven deferral mirror (≥40-char substring from `evidence_deferred`).

**Missing paths (D-26) — add to existing loop:**

```32:51:test/docs_contract/viewer_evidence_claims_test.exs
    test "api stability guide mirrors all consolidated viewer evidence paths" do
      guide = File.read!("guides/api_stability.md")

      for path <- [
            "priv/viewer_evidence/forms/apple_preview.md",
            ...
            "priv/viewer_evidence/long_lived_signed_artifact/adobe_acrobat_reader.md"
          ] do
        assert guide =~ path
      end
    end
```

**Add:**

```elixir
"priv/viewer_evidence/forms/chrome_pdfium.md",
"priv/viewer_evidence/signature_widget/chrome_pdfium.md",
```

**Optional deferral mirror (D-26):**

```elixir
test "api stability guide contains deferral reason substrings from matrix" do
  matrix = Matrix.load!()
  guide = File.read!("guides/api_stability.md")

  Matrix.enumerate_viewer_cells(matrix)
  |> Enum.filter(&(&1.status == "explicit_deferral"))
  |> Enum.each(fn cell ->
    row = fetch_row_for_test(matrix, cell)
    reason = row["evidence_deferred"]
    assert String.length(reason) >= 40
    assert guide =~ String.slice(reason, 0, 40)
  end)
end
```

**Lane registration — preserve, do not break:**

```243:276:test/docs_contract/viewer_evidence_claims_test.exs
  describe "docs-contract lane registration" do
    @describetag :lane_registration
    test "verify_docs.exs includes the viewer evidence semantic-claims lane" do
      ...
    end

    test "verify_docs.exs retains the prior seven docs-contract lanes" do
      ...
    end
  end
```

---

### 2.10 Negative hex.build test (optional D-30)

**Pattern:** `mix hex.build` → nested `tar -tzf` listing → assert inclusion for shipped assets, **refute** operator-only paths.

**Positive assertion analog:**

```41:56:test/docs_contract/branding_claims_test.exs
  describe "hex tarball contents" do
    test "built tarball includes branded assets and NOTICE" do
      tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
      File.rm(tarball)

      {output, 0} = System.cmd("mix", ["hex.build"], stderr_to_stdout: true)
      assert output =~ tarball
      assert File.exists?(tarball)

      list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
      {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

      assert contents =~ "priv/branded/fonts/B612-Regular.ttf"
      assert contents =~ "priv/branded/images/rendro-logo.png"
      assert contents =~ "NOTICE"
    end
  end
```

**Target negative test:**

```elixir
test "built tarball excludes operator-only priv paths" do
  # ... same tar listing ...
  refute contents =~ "priv/viewer_evidence/"
  refute contents =~ "priv/support_matrix.json"
end
```

**Package `files:` whitelist (unchanged — documents D-29):**

```74:89:mix.exs
  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(
        lib
        priv/branded
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

---

### 2.11 CHANGELOG / `mix.exs` reconciliation — `v0.3.1` ship

**Pattern:** Patch release closes adopter contract gap — `0.3.0` on Hex predates v2.3 viewer work; do not re-tag `0.3.0`.

**Current drift:**

| Artifact | Value | Action |
|----------|-------|--------|
| `mix.exs` `@version` | `"0.3.0"` | Bump to `"0.3.1"` |
| Git tag `v0.3.0` | `ba023c9` | Frozen — already on Hex |
| `CHANGELOG.md` | `## [0.3.0] - Unreleased` contains all v2.3 Viewer Evidence bullets | Split per D-13 |

**Target split (D-13):**

1. `## [0.3.0] - 2026-05-08` — historically published pre–v2.3 viewer content only (`git show v0.3.0:CHANGELOG.md` at execute).
2. `## [0.3.1] - <ship-date>` — entire `#### Viewer Evidence (v2.3)` section moved from 0.3.0 draft.
3. Tag `v0.3.1` → `release.yml` publishes.

**Release workflow (current — optional preflight hardening):**

```1:34:.github/workflows/release.yml
name: Release to Hex

on:
  push:
    tags:
      - 'v*.*.*'
...
      - name: Run CI and Preflight Checks
        run: mix ci

      - name: Publish to Hex
        ...
        run: mix hex.publish --yes
```

**Gap:** Tag publish runs `mix ci` only — not full `mix release.preflight`. `release-proof` CI job covers isolated worktree preflight on every `main` push.

**Preflight changelog coupling (plan at tag time):**

```121:127:lib/mix/tasks/release/preflight.ex
  defp check_changelog_release_tail(context) do
    changelog_path = Map.get(context, :changelog_path, "CHANGELOG.md")
    version = context.project_config[:version]

    with {:ok, changelog} <- File.read(changelog_path),
         true <- String.contains?(changelog, "## [#{version}] - Unreleased"),
```

**Isolated worktree proof analog:**

```97:107:scripts/release_preflight_proof.exs
  def execute_proof(options, context \\ default_context()) do
    case maybe_prepare_synthetic_tag(options, context) do
      {:ok, cleanup_state} ->
        with {_, 0} <-
               run_command(context, "git", ["rev-parse", "--verify", "#{options.ref}^{commit}"]),
             ...
             {preflight_output, status} <-
               run_command(context, "mix", ["release.preflight"], cd: options.worktree),
```

**Ship ordering (D-15):** Phase 72 execute → `v0.3.1` on Hex → `/gsd-audit-milestone v2.3` → `/gsd-complete-milestone v2.3`. Milestone tag `v2.3` is planning-only; Hex tag is `v0.3.1`.

---

### 2.12 Machine ledger CLI — closure inputs unchanged

**Pattern:** Phase 72 audits terminal state; does not mutate matrix.

**Production CLI state (2026-05-29):**

```bash
mix rendro.viewer_evidence list
# Viewer evidence: 26 cells (supported=17, unverified=0, explicit_deferral=9)

mix rendro.viewer_evidence missing
# Exit 0 — No unverified cells.
```

**JSON export for VERIFICATION:**

```170:180:lib/mix/tasks/rendro/viewer_evidence.ex
  defp run_list(matrix, cells, json?) do
    payload = build_payload(matrix, cells)

    if json? do
      IO.puts(JSON.encode!(payload))
    else
      print_human(payload, footer: nil)
    end

    :ok
  end
```

**Summary shape:**

```235:243:lib/mix/tasks/rendro/viewer_evidence.ex
  defp summary_from_cells(cell_maps) do
    counts = Enum.frequencies_by(cell_maps, & &1["status"])

    %{
      "total" => length(cell_maps),
      "supported" => Map.get(counts, "supported", 0),
      "unverified" => Map.get(counts, "unverified", 0),
      "explicit_deferral" => Map.get(counts, "explicit_deferral", 0)
    }
  end
```

---

## 3. Integration points

```
Phase 72 closure workflow
  W1 — Guardrails contract (GUARDRAIL-02 durable baseline)
        ├── priv/guardrails/required_status_checks.json
        ├── test/guardrails/required_checks_contract_test.exs
        │     reads JSON + ci.yml + verify_docs.exs (offline)
        └── scripts/audit_branch_protection.exs
              reads JSON → GitHub API → normalize → diff (close ritual only)

  W2 — Staleness gate + verification ledger
        ├── lib/mix/tasks/rendro/viewer_evidence.ex  (--strict)
        ├── test/mix/tasks/viewer_evidence_task_test.exs
        └── 72-VERIFICATION.md
              ├── mix rendro.viewer_evidence list --json  (machine ledger)
              ├── validate + validate --strict outputs
              └── audit_branch_protection.exs snapshot

  W3 — Polish + publish (single public-contract + Hex wave)
        ├── guides/viewer_evidence.md  (Appendix D --strict, Phase 71 path)
        ├── test/docs_contract/viewer_evidence_claims_test.exs  (path asserts)
        ├── CHANGELOG.md  (0.3.0 freeze + 0.3.1 section)
        ├── mix.exs  (@version 0.3.1, files: unchanged)
        └── tag v0.3.1 → release.yml → hex.pm

mix ci (test job — unchanged topology)
  └── mix test
        ├── test/guardrails/required_checks_contract_test.exs  (new)
        ├── test/docs_contract/viewer_evidence_claims_test.exs  (lane 8)
        └── test/docs_contract/*.exs  (all eight lanes via verify_docs.exs)

branch protection (main) — audit only, no UI change
  ├── test                    ← mix ci (+ lane 8 via mix test)
  ├── signing-live-proof      ← behavioral (unchanged)
  ├── long-lived-live-proof   ← behavioral (unchanged)
  └── release-proof           ← release_preflight_proof.exs

advisory (not required):
  └── viewer-evidence-live-proof  ← Phase 71 live tests (7 files)
```

| Integration | Phase 72 touch | Must remain stable |
|-------------|----------------|-------------------|
| `priv/support_matrix.json` | **No cell edits** | 26-cell terminal state from Phase 71 |
| `.github/workflows/ci.yml` required jobs | **No semantic change** | Four required + one advisory job names |
| `mix ci` alias | **No new steps** | Viewer task stays out of alias (D-09) |
| `scripts/verify_docs.exs` | **Eight lanes unchanged** | Lane 8 registration asserted by guardrails test |
| `Validator.run_full/3` default | Advisory staleness preserved | Only `--strict` promotes staleness |
| `mix.exs` `files:` | **Unchanged** | Operator priv repo-only |
| Signing / long-lived live-proof commands | Contract test asserts strings | No dilution (GUARDRAIL-02 core) |

**Implementer verification sequence (pre-merge):**

```bash
mix test test/guardrails/required_checks_contract_test.exs
mix rendro.viewer_evidence missing          # exit 0
mix rendro.viewer_evidence validate         # exit 0
mix rendro.viewer_evidence validate --strict # exit 0
mix test test/docs_contract/
mix docs.contract                           # 8/8
GITHUB_TOKEN=... mix run scripts/audit_branch_protection.exs  # close ritual
mix run scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-preflight
```

---

## 4. Anti-patterns to avoid

| Anti-pattern | Why it fails | Correct pattern |
|--------------|--------------|-----------------|
| Checklist-only GUARDRAIL-02 closure | v2.2 operational gap (artifact ≠ operational) | B-lite: JSON baseline + offline test + live audit snapshot (D-01) |
| List `viewer-evidence-schema` as required GitHub context | PITFALLS §7 drift; Phase 68 D-18 folded into `test` | Baseline JSON `supersedes_planning_refs`; four contexts only |
| GitHub API in default `mix ci` | Fork PR safety; pure-core boundary (D-04) | `audit_branch_protection.exs` at close only |
| Wire `--strict` into `mix ci` or branch protection | Calendar-bomb ~180 days after recording (D-09) | Operator/release gate only; default validate advisory |
| Hand-maintain 26-row table in VERIFICATION | Duplicates matrix; drifts (D-17) | `list --json` export + ~8–12 spot-check rows |
| Re-tag or re-publish `v0.3.0` | Hex consumers already consumed semver | Patch `v0.3.1` for v2.3 viewer claims (D-12) |
| Expand Hex `files:` for operator priv | Partial ship implies broken recording from deps (D-29) | Document omission; optional negative tarball test |
| Promote `viewer-evidence-live-proof` to required | Separate policy decision (D-32) | Document as advisory in baseline JSON |
| Full prose audit of guides | Phase 72 is closure, not rewrite (D-22) | Matrix-truth + docs-contract green + surgical fixes |
| Modify matrix cells during closure | Phase 71 already terminal | Audit `missing` / `list` / `validate` only |
| Dilute behavioral lane commands in `ci.yml` | GUARDRAIL-02 semantics preservation | Contract test asserts `live_signing` / `live_pdf_tools` strings |
| Silent pass when live audit fails | D-06 | VERIFICATION `gaps_found` with explicit gap list |
| Skip 69/71 VERIFICATION backfill | Milestone audit blocker (D-21) | Lightweight PASS stubs before `/gsd-audit-milestone` |
| Adopt release-please in Phase 72 | Process change out of scope (D-16) | Existing manual tag + `release.yml` |
| Change `CHANGELOG` without `git show v0.3.0:CHANGELOG.md` diff | Historical 0.3.0 content inaccuracy | Split bullets from tag snapshot at execute |
| Conflate milestone tag `v2.3` with Hex tag | Orthogonal artifacts (D-15) | Hex `v0.3.1`; planning archive separate |

---

## PATTERN MAPPING COMPLETE
