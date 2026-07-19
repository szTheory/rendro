# Phase 114: Domain research, reader-quality rubric & realistic example-data library - Research

**Researched:** 2026-07-10
**Domain:** Elixir/Hex library packaging contracts (priv shipping, schema validation, docs-contract testing), plus business-document domain/reader-quality research
**Confidence:** HIGH (mechanics — verified against the live codebase) / MEDIUM (domain-research content — informed synthesis, not verifiable via tools)

## Summary

Phase 114 is almost entirely a **packaging and contract-testing** problem, not a new-library problem. Every mechanism it needs already exists in the codebase in a directly analogous form: `Rendro.Branded` shows the exact `@moduledoc false` + `Application.app_dir/2` loader pattern to copy for `Rendro.Examples`; `Rendro.PublicApi.Validator` / `Rendro.ViewerEvidence.Validator` show the exact `JSV.build!/1` + `JSV.validate/2` pattern to copy for the two new schemas; `test/docs_contract/branding_claims_test.exs` and `launch_artifacts_claims_test.exs` show the exact `tar -xOf <tarball> contents.tar.gz | tar -tzf -` pattern used to assert tarball contents (both inclusion and exclusion) — this is the mechanism for EXL-05's text-only/raster-ban proof, not a new CI job. `mix.exs`'s `package/0` `:files` allowlist and `lib/mix/tasks/rendro/api.gen.ex`'s hardcoded `@public_modules` list are both simple additive edits (add `"priv/examples"` to one list; do NOT add `Rendro.Examples` to the other).

The one genuinely research-heavy (not code-archaeology) part of this phase is the domain/rubric content itself (RUB-01/02): who reads an invoice, what's the one fact they need first, what "reader-quality" concretely means at each 1/3/4/5 anchor. That content is necessarily `[ASSUMED]` — general professional-services/print-design knowledge, not verifiable against this codebase — and should be flagged to the planner/user as the one area worth a light human sanity-check, per this repo's stated preference for locked recommendations over open questions.

**Primary recommendation:** Treat this phase as "wire four contract points + author two research docs," not as "build a new subsystem." No new Hex dependencies are needed (`jsv`, `decimal`, and Elixir's built-in `JSON` module are already available); the loader must decode with the built-in `JSON` module (not `Jason`, which is only a `:dev`/`:test`-transitive dependency here, not a direct runtime dep), and the `mix rendro.comparison.check` alias does **not** actually read `bench/comparison/fixtures/invoice_data.json` — proving EXL-04's no-op requires an explicit new assertion, not reliance on that command staying green.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Example fixture storage (`priv/examples/`) | Database/Storage (static, file-based) | — | Read-only shipped data, analogous to `priv/branded/` |
| `Rendro.Examples` loader | API/Backend (library internals) | — | `@moduledoc false` internal module, mirrors `Rendro.Branded`; not part of the public Builder API surface |
| Schema validation (`examples.schema.json`, rubric schema) | API/Backend (dev/test tooling) | — | Enforced by ExUnit tests in `:test` env, never shipped, mirrors `priv/schemas/public_api.schema.json` |
| Docs-contract lane(s) | API/Backend (CI/test tooling) | — | Ordinary `test/docs_contract/*_test.exs` files auto-discovered by the existing required `test` job; no new CI job |
| Rubric manifest (`priv/quality/rubric_scores.json`) | Database/Storage (static, file-based) | API/Backend (structural validator) | Appendable data file + a structural (not subjective) validator, mirrors `bench/results/comparison.json` + `Rendro.Comparison.static_contract_errors/1` |
| `DOMAIN.md` files | — (docs, no runtime tier) | — | Pure documentation co-located with fixtures; consumed by humans and Phase 118's demo citations |
| Bench harness repoint (EXL-04) | API/Backend (dev-only tooling) | — | `bench/comparison/run.exs`, `invoice_rendro.exs`, `invoice_typst.typ` are dev-time scripts, never shipped (`bench/comparison/` is absent from `mix.exs` `:files`; only `bench/results` ships) |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `jsv` | 0.19.1 (locked, `mix.lock`) [VERIFIED: mix.lock] | JSON Schema validation (draft 2020-12) | Already the repo's sole JSON-Schema validator; used identically for `public_api.schema.json`, `support_matrix.schema.json`, `viewer_evidence.schema.json` |
| `decimal` | 2.4.1 (locked) [VERIFIED: mix.lock] | Money-as-Decimal handling | Already a direct runtime dep (`mix.exs` line 59: `{:decimal, ">= 2.3.0 and < 4.0.0"}`); `Rendro.Format.money/1` already accepts `Decimal.new("string")` |
| Elixir built-in `JSON` module | ships with Elixir ~> 1.19 / OTP 27+ [VERIFIED: mix.exs `elixir: "~> 1.19"`, and existing call sites] | Decoding fixture/manifest JSON at runtime and in tests | Used today by `Rendro.Comparison.read_manifest!/0`, `Rendro.PublicApi.Validator`, `Rendro.ViewerEvidence.ValidatorTest` via `JSON.decode!/1`. **Do not use `Jason` for decoding in `lib/rendro/examples.ex`** — `Jason` is not a direct dependency in `mix.exs`'s `deps/0` (it is only pulled in transitively via `:dev`/`:test`-only deps like `credo`/`ex_doc`, guarded with `@compile {:no_warn_undefined, ...}` where used). A shipped Hex consumer calling `Rendro.Examples` at runtime may not have `Jason` compiled in; the built-in `JSON` module has no such risk. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Jason` (transitive, encode-only) | 1.4.5 (locked) [VERIFIED: mix.lock] | Deterministic pretty-printed JSON encoding via `Jason.OrderedObject` | Only for **writing** new/updated JSON (e.g. if a mix task regenerates `rubric_scores.json` or `examples.schema.json`-adjacent fixtures) — mirrors `Mix.Tasks.Rendro.Api.Gen.encode_manifest/1` and `Rendro.Comparison.encode_manifest/1`. Guard any such call site with `@compile {:no_warn_undefined, {Jason, :encode!, 2}}` exactly as those two modules do. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `jsv` (repo-standard) | `ex_json_schema` | Would introduce a second, inconsistent JSON-Schema validator into a repo that has three existing schemas all validated via `jsv`; no justification to diverge |
| Built-in `JSON` module | `Jason.decode!/1` | `Jason` is transitive-only here; using it for decoding in a shipped `lib/` module risks `UndefinedFunctionError` for consumers without a `Jason` dependency of their own |

**Installation:** No new dependencies required. All needed packages (`jsv`, `decimal`) are already present in `mix.exs`/`mix.lock`.

```bash
# Verified already-locked versions (no `mix deps.get` changes needed for Phase 114):
grep '"jsv"\|"decimal"' mix.lock
```

**Version verification:** `jsv` 0.19.1 and `decimal` 2.4.1 confirmed directly from the committed `mix.lock` (not `npm view` — this is a Hex/BEAM ecosystem, npm has an unrelated same-named `jsv` package; do not conflate the two). No registry lookup needed since these are pre-existing pinned dependencies, not new additions.

## Package Legitimacy Audit

**No new external packages are introduced by this phase.** `jsv` and `decimal` are pre-existing, already-audited dependencies in `mix.lock` used identically elsewhere in the codebase (`lib/rendro/public_api/validator.ex`, `lib/rendro/viewer_evidence/validator.ex`). The Package Legitimacy Gate is not applicable — there is nothing new to check against a registry.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| jsv | hex.pm (pre-existing dep) | pre-existing in mix.lock | n/a — already vetted | n/a | N/A | Not a new install |
| decimal | hex.pm (pre-existing dep) | pre-existing in mix.lock | n/a — already vetted | n/a | N/A | Not a new install |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```
                     ┌─────────────────────────────────────────┐
                     │  priv/examples/<domain>/<business>/      │
                     │  <family>.json  (text-only, shipped)     │
                     └───────────────┬───────────────────────────┘
                                     │ File.read! + JSON.decode!
                                     ▼
            ┌────────────────────────────────────────────────┐
            │  lib/rendro/examples.ex  (Rendro.Examples)       │
            │  @moduledoc false                                │
            │  resolves base dir via Application.app_dir/2     │
            │  (falls back to repo-relative "priv/examples"    │
            │   when running in-repo / :dev / :test)           │
            └───────┬───────────────┬───────────────┬─────────┘
                    │               │               │
          test/*.exs       bench/comparison/*   guides/*.md,
          (fixtures for    invoice_rendro.exs    Livebook (via
           assertions)     (repointed from       Mix.install of
                            bench/comparison/     :rendro from Hex
                            fixtures/…)            or local path)
                    │
                    ▼
     ┌───────────────────────────────────────────┐
     │ priv/schemas/examples.schema.json           │  ← repo-only, NOT shipped
     │ validated by test/docs_contract/            │    (absent from mix.exs :files)
     │ examples_schema_contract_test.exs           │
     │ (uses JSV.build!/1 + JSV.validate/2,        │
     │  same pattern as Rendro.PublicApi.Validator)│
     └───────────────────────────────────────────┘

     ┌───────────────────────────────────────────┐
     │ priv/quality/rubric_scores.json (appendable)│  ← shipped-or-not is a
     │ + priv/schemas/rubric_scores.schema.json    │    planner decision (likely
     │ validated by test/docs_contract/            │    repo-only, like other
     │ rubric_manifest_contract_test.exs           │    priv/schemas/* + priv/
     │ (structure + threshold arithmetic only —    │    guardrails/*.json — see
     │  hierarchy=5, core>=4, gates pass; NOT the   │    Open Questions)
     │  subjective score itself)                   │
     └───────────────────────────────────────────┘

     ┌───────────────────────────────────────────┐
     │ priv/<domain>/DOMAIN.md (co-located docs)   │  → cited by Phase 118 demos
     └───────────────────────────────────────────┘

Hex tarball assembly (mix.exs package/0 :files):
  lib, assets/rendro, priv/branded, priv/examples (NEW),
  bench/results, guides, .formatter.exs, mix.exs, README.md,
  ADOPTION.md, LICENSE, NOTICE, CHANGELOG.md
  ── priv/schemas/, priv/quality/, priv/guardrails/, priv/support/,
     priv/viewer_evidence/, priv/plts/ intentionally absent (repo-only) ──
```

### Recommended Project Structure

```
priv/
├── examples/
│   └── invoice/                         # domain (grows: payslip, ticket in Ph 116)
│       └── <fictional-business-slug>/
│           └── invoice.json             # money as Decimal-safe STRINGS, optional empty brand/logo (S4)
├── schemas/
│   ├── examples.schema.json             # NEW — repo-only, draft 2020-12 (matches sibling schemas)
│   └── rubric_scores.schema.json        # NEW — repo-only, draft 2020-12
└── quality/
    └── rubric_scores.json               # NEW — appendable manifest (S5)

lib/rendro/
└── examples.ex                          # NEW — @moduledoc false, mirrors lib/rendro/branded.ex

.planning docs (not shipped) or priv/examples co-location:
priv/examples/invoice/DOMAIN.md          # RUB-01 — domain language, personas+JTBD, reading context

test/
├── rendro/
│   └── examples_test.exs                # loader behavior + raster-ban assertion
└── docs_contract/
    ├── examples_schema_contract_test.exs    # EXL-03 — every fixture validates
    └── rubric_manifest_contract_test.exs    # RUB-03 — structure + threshold arithmetic
```

### Pattern 1: `@moduledoc false` priv-reading loader (mirror `Rendro.Branded`)

**What:** A tiny internal module exposing plain functions that resolve absolute paths via `Application.app_dir/2`, then read/parse.
**When to use:** Any time `lib/` needs to read a file shipped under `priv/` for both in-repo dev/test and for a consumer who installed the Hex package.
**Example:**
```elixir
# Source: lib/rendro/branded.ex (existing, verbatim pattern to mirror)
defmodule Rendro.Branded do
  @moduledoc false

  @spec font_path() :: Path.t()
  def font_path, do: Application.app_dir(:rendro, "priv/branded/fonts/B612-Regular.ttf")

  @spec logo_path() :: Path.t()
  def logo_path, do: Application.app_dir(:rendro, "priv/branded/images/rendro-logo.png")
end
```
`Application.app_dir(:rendro, subpath)` resolves correctly in **all three** consumption contexts this phase must support:
1. In-repo `mix test`/`mix run` (dev/test) — `:rendro` is the running app itself; `app_dir` resolves to `_build/<env>/lib/rendro`, and `priv/` is symlinked/copied there by Mix automatically.
2. A downstream Hex consumer (`{:rendro, "~> 1.1"}` in their `mix.exs`) — resolves to their `deps/rendro/priv/...`, IF `priv/examples` is in the Hex tarball (EXL-05). This is the load-bearing reason EXL-05 exists: without it, `Rendro.Examples` would raise for every Hex consumer.
3. Livebook via `Mix.install([{:rendro, "~> 1.0"}, ...])` (see `guides/livebook/first_invoice.livemd`) — `Mix.install` compiles `:rendro` as a real OTP app with its own `priv/`, so `Application.app_dir/2` resolves identically to case 2. **This is the same reason `guides/livebook/first_invoice.livemd`'s dependency line will need bumping to `"~> 1.1"` in a later phase** — noted here as a downstream dependency, not this phase's job.

For `Rendro.Examples`, recommend a slightly richer surface than `Rendro.Branded`'s (which only returns paths):

```elixir
defmodule Rendro.Examples do
  @moduledoc false

  @base_dir "priv/examples"

  @spec load!(String.t()) :: map()
  def load!(relative_path) do
    @base_dir
    |> then(&Application.app_dir(:rendro, &1))
    |> Path.join(relative_path)
    |> File.read!()
    |> JSON.decode!()
  end

  @spec list(String.t()) :: [String.t()]
  def list(domain) do
    @base_dir
    |> then(&Application.app_dir(:rendro, &1))
    |> Path.join(domain)
    |> Path.join("**/*.json")
    |> Path.wildcard()
  end
end
```
Return raw JSON-decoded maps (money still as strings) rather than converting to `%Decimal{}` at load time — keeps the loader generic across all future domains/families and defers Decimal-specific mapping to each family's own data-shaping code (Phase 115+), consistent with "no `lib/` product change except the loader."

### Pattern 2: JSON Schema validation via `jsv` (mirror `Rendro.PublicApi.Validator`)

**What:** Decode schema + data with the built-in `JSON` module, build a compiled schema with `JSV.build!/1`, validate with `JSV.validate/2`.
**When to use:** Any repo-only structural contract (EXL-03, RUB-03).
**Example:**
```elixir
# Source: lib/rendro/public_api/validator.ex (existing, verbatim pattern to mirror)
defmodule Rendro.PublicApi.Validator do
  @moduledoc false
  @schema_path "priv/schemas/public_api.schema.json"

  @spec validate(map()) :: :ok | {:error, String.t()}
  def validate(manifest) do
    schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()

    case JSV.validate(manifest, schema) do
      {:ok, _} -> :ok
      {:error, err} -> {:error, err |> JSV.normalize_error() |> inspect(limit: :infinity)}
    end
  end
end
```
Use `"$schema": "https://json-schema.org/draft/2020-12/schema"` (the draft version used identically by all three existing schemas: `public_api.schema.json`, `support_matrix.schema.json`, `viewer_evidence.schema.json`) for both new schemas, for consistency.

### Pattern 3: Tarball content assertions (mirror `branding_claims_test.exs` / `launch_artifacts_claims_test.exs`)

**What:** Build the real Hex tarball once (cached via `Rendro.Test.HexBuildCache`), then list its inner `contents.tar.gz` and assert on path substrings — both **inclusion** and **exclusion**.
**When to use:** EXL-05's text-only/raster-ban proof. This is the mechanism to write the "raster-ban test mirroring `brand/`" the roadmap calls for — there is no dedicated ExUnit raster-ban test for the top-level `brand/` directory today (that directory's protection is a `.gitignore` extension-block, not a test — see Pitfall 1 below); "mirroring `brand/`" means reusing its **extension-list convention**, not an existing test file.
**Example:**
```elixir
# Source: test/docs_contract/branding_claims_test.exs (existing, verbatim pattern to mirror)
test "built tarball excludes operator-only priv paths" do
  tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
  {output, 0} = Rendro.Test.HexBuildCache.get_build_output()
  assert output =~ tarball
  assert File.exists?(tarball)

  list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
  {contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

  refute contents =~ "priv/viewer_evidence/"
  refute contents =~ "priv/support_matrix.json"
end
```
For EXL-05, write two assertions in this style:
1. `assert contents =~ "priv/examples/"` (or a specific known fixture path) — proves it ships.
2. For every path in `contents` under `priv/examples/`, `Path.extname/1` is one of `[".json", ".md", ".svg"]` — proves text-only. (There is no existing helper for "grep tarball listing → filter by prefix → assert extensions"; write it directly against the `contents` string, splitting on `\n`.)

Additionally, **separately from the tarball test**, add a fast, no-build-required in-repo test that walks `Path.wildcard("priv/examples/**/*")` and asserts the same extension allowlist — this catches an accidental raster commit at `mix test` speed without needing a `mix hex.build` round-trip, and is the more direct analog of `brand/`'s `.gitignore` guard (see Pitfall 1).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON Schema validation | A custom map-shape validator | `jsv` (`JSV.build!/1` + `JSV.validate/2`) | Already the repo's sole validator for 3 other schemas; a hand-rolled validator would be an inconsistent fourth approach |
| Tarball inspection | Unpacking with `:erl_tar` or a temp-dir `File.cp_r!` simulation | `tar -xOf <tarball> contents.tar.gz \| tar -tzf -` via `System.cmd("sh", ...)` | This exact one-liner is the established, working pattern in two existing docs-contract tests; Hex tarballs are a nested tar-of-tar (outer tar contains `contents.tar.gz`, `metadata.config`, `VERSION`, `CHECKSUM`) and the shell pipeline already handles that correctly |
| priv-file path resolution | `Path.join(__DIR__, "../../priv/...")` or `:code.priv_dir/1` directly | `Application.app_dir(:rendro, "priv/...")` | `Rendro.Branded` already established this exact idiom; `Application.app_dir/2` is the standard, dep-agnostic way (works identically for `Mix.install` Livebook consumers, in-repo dev/test, and installed Hex deps) |
| Rubric "quality gate" enforcement | A custom numeric-threshold DSL | Plain Elixir functions over the appendable JSON manifest (mirror `Rendro.Comparison.static_contract_errors/1`'s `collect_*_errors` accumulator style) | The existing `Rendro.Comparison` module is a working, in-repo template for "validate a JSON manifest's structure + arithmetic, return a list of error strings" — reuse that shape rather than inventing a new validation framework |

**Key insight:** Every mechanical piece of this phase (schema validation, tarball auditing, priv-path resolution, structural-manifest validation) already has a working, committed reference implementation elsewhere in this codebase. The risk in this phase is *not* picking the wrong tool — it's forgetting to mirror an existing convention (e.g. building a bespoke tarball-listing parser instead of reusing the `tar -xOf ... | tar -tzf -` one-liner, or reaching for `Jason.decode!` instead of the built-in `JSON` module).

## Common Pitfalls

### Pitfall 1: "raster-ban test mirroring `brand/`" is NOT a literal existing test to copy

**What goes wrong:** Searching the test suite for an existing "brand raster ban" ExUnit test wastes time — it doesn't exist. `priv/branded/images/rendro-logo.png` is a PNG that IS shipped (verified by `test/rendro/branded_test.exs` and `branding_claims_test.exs`'s "built tarball includes branded assets" test) — so `priv/branded/` is explicitly NOT raster-banned.
**Why it happens:** The roadmap's "`brand/`" refers to the top-level **`brand/` directory** (the design-source brand book from Milestone B1, at repo root, absent from `mix.exs` `:files` and thus never shipped) — not `priv/branded/`. `brand/`'s raster protection is a `.gitignore` rule block (lines 56-67: `brand/**/*.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.pdf`, `.woff`, `.woff2`, `.ttf`, `.otf`, `.eot`), documented in `.planning/milestones/B1-phases/107-brand-book-qa/107-SUMMARY.md` (QA-01 was verified manually, not by an automated test).
**How to avoid:** (1) Add an analogous `.gitignore` extension-block for `priv/examples/**` (defense-in-depth, prevents ever committing a raster there). (2) Write a genuinely NEW ExUnit test — both an in-repo wildcard-extension check and a tarball-content check (Pattern 3 above) — since EXL-05 explicitly requires a *test*, and no automated test currently exists to copy for `brand/` itself.
**Warning signs:** Grepping `test/` for "raster" + "brand" together returns nothing; don't conclude the requirement is already satisfied — it means the test must be authored fresh, using the *conceptual* pattern (extension allowlist) from `brand/`'s `.gitignore`.

### Pitfall 2: `mix rendro.comparison.check` does not read the fixture file — it can't prove the de-quarantine no-op

**What goes wrong:** Assuming "`mix rendro.comparison.check` stays green" is itself sufficient proof that moving `bench/comparison/fixtures/invoice_data.json` was behavior-preserving.
**Why it happens:** `Rendro.Comparison.check/0` → `static_contract_errors/1` only validates `bench/results/comparison.json`'s **already-recorded** structure (schema_version, comparator ids, per-result required keys, raw-artifact SHA-256 hashes of files in `bench/results/raw/`). It never re-reads `bench/comparison/fixtures/invoice_data.json` or re-renders anything. The manifest's `scenario.fixture` field is a free-text string (`"bench/comparison/fixtures/invoice_data.json"`), checked only for key-presence, never for file existence or content match. So `check` would stay green even if the fixture were deleted entirely.
**How to avoid:** Plan an explicit separate verification step for the no-op claim: e.g. (a) `git mv` the file verbatim (byte-identical) to its new `priv/examples/...` location and diff to confirm zero content drift, (b) update the **three** actual consumers that hardcode the old path — `bench/comparison/run.exs`'s `@fixture_path` module attribute, `bench/comparison/fixtures/invoice_rendro.exs`'s `File.read!("bench/comparison/fixtures/invoice_data.json")` call, and `bench/comparison/fixtures/invoice_typst.typ`'s Typst `--input data-path=` resolution (Typst resolves relative paths against the compiling `.typ` file's own directory, so this breaks silently if not updated to point at the new location or given an absolute/relative path adjustment in `run.exs`'s `System.cmd` invocation), and (c) update `bench/results/comparison.json`'s `scenario.fixture` string for documentation accuracy (optional for `check` to pass, but required for the manifest to not lie about where the fixture lives).
**Warning signs:** If the plan's only verification step for EXL-04 is "run `mix rendro.comparison.check`," the no-op is not actually proven — that command was already green before touching anything, and stays green after deleting the file's old path entirely.

### Pitfall 3: `Jason` is not a direct dependency — using it in `lib/rendro/examples.ex` risks a runtime crash for consumers

**What goes wrong:** Copy-pasting `Jason.decode!/1` into the new loader because it "looks standard" for JSON in Elixir.
**Why it happens:** `Jason` appears throughout `mix.lock` and is used in a few `lib/` modules (`Rendro.Comparison`, `Mix.Tasks.Rendro.Api.Gen`) for **encoding** with `@compile {:no_warn_undefined, {Jason, :encode!, 2}}` guards — but it is not listed in `mix.exs`'s `deps/0` at all (it's pulled in transitively by `:dev`/`:test`-only deps like `credo`, `ex_doc`, `mix_audit`). A shipped Hex consumer who only installs `:rendro` in `:prod` will not have `Jason` compiled.
**How to avoid:** Use Elixir's built-in `JSON` module (`JSON.decode!/1`) for all reads in `lib/rendro/examples.ex`, exactly as `Rendro.Comparison.read_manifest!/0` and `Rendro.PublicApi.Validator` already do. Reserve `Jason` (with the `no_warn_undefined` guard) only for one-off dev-time encoding/codegen tasks, never for `lib/`-runtime reads.
**Warning signs:** A `Code.ensure_loaded?(Jason)` guard appearing in new `lib/` code, or Dialyzer/Credo warnings about undefined `Jason` functions in a fresh `mix deps.get --only prod` environment.

### Pitfall 4: Forgetting that `priv/examples/` and `priv/schemas/`/`priv/quality/` need opposite package-file treatment

**What goes wrong:** Adding all three new `priv/` subdirectories to `mix.exs`'s `package/0` `:files` list uniformly.
**Why it happens:** They're created together in the same phase, so it's easy to treat them as one unit.
**How to avoid:** Only `"priv/examples"` goes into `package/0`'s `:files` list (alongside the existing `lib`, `assets/rendro`, `priv/branded`, `bench/results`, `guides`, etc.). `priv/schemas/` and `priv/quality/` must stay **absent** from that list — this is the existing convention: `priv/public_api.json`, `priv/support_matrix.json`, and all of `priv/schemas/` are already repo-only (confirmed: none appear in the current `package/0` `:files`), enforced today by `branding_claims_test.exs`'s "built tarball excludes operator-only priv paths" test (which currently checks `priv/viewer_evidence/` and `priv/support_matrix.json` — extend or mirror this test to also refute `priv/schemas/examples.schema.json`, `priv/schemas/rubric_scores.schema.json`, and `priv/quality/rubric_scores.json` if EXL-06/RUB-03 wording is interpreted as repo-only; see Open Questions).
**Warning signs:** `mix hex.build` output growing unexpectedly, or a new negative-assertion test failing because a repo-only file leaked into the tarball.

### Pitfall 5: The "docs-contract lane" guardrail has an exact-count assertion that will break if lanes are added without updating it

**What goes wrong:** Adding `test/docs_contract/examples_schema_contract_test.exs` and `test/docs_contract/rubric_manifest_contract_test.exs` without also registering them in `scripts/verify_docs.exs`.
**Why it happens:** `test/guardrails/required_checks_contract_test.exs` has a test asserting `scripts/verify_docs.exs` registers **exactly twenty-two** lanes (a hardcoded count via regex scan). This guardrail test will still pass if new docs_contract test files exist but aren't registered as lanes (the count only reflects what's actually in `verify_docs.exs`) — but the phase's *intent* ("a docs-contract lane folded into the required `test` job") is best satisfied by registering them, both for local `mix docs.contract` runnability and for consistency with the other ~20 lanes. If they ARE registered, the guardrail's hardcoded count (22) must be bumped to 24 in the same commit, or that test goes red.
**How to avoid:** Either (a) register both new test files as lanes in `scripts/verify_docs.exs` AND bump the guardrail's count assertion from 22 to 24, or (b) deliberately leave them unregistered as lanes (they'll still run under the required `test` job automatically via ExUnit's default `test/**/*_test.exs` discovery) and note that choice explicitly. Note that the required CI `test` job (`mix test --exclude quarantine --slowest 10`) runs **all** test files regardless of `verify_docs.exs` registration — registration is a local-DX/consistency concern, not a CI-gating one.
**Warning signs:** `test/guardrails/required_checks_contract_test.exs` failing with a count mismatch after adding new docs_contract tests.

### Pitfall 6: Decimal-safe money-as-strings still needs a concrete JSON Schema shape decision

**What goes wrong:** Writing `"money": {"type": "number"}` in `examples.schema.json` out of habit — this is exactly the JSON-float trap EXL-01 explicitly forbids.
**Why it happens:** Most JSON Schema examples for "amount" fields default to `number`.
**How to avoid:** Every money field in `examples.schema.json` must be `{"type": "string", "pattern": "^-?[0-9]+\\.[0-9]{2}$"}` (or similar — enforce fixed 2-decimal-place string shape), never `"type": "number"`. Fixture authors write `"total": "474.00"`, not `"total": 474.00` or `"total_cents": 47400`. Note the current quarantined `bench/comparison/fixtures/invoice_data.json` uses `price_cents` (integer cents) — per the roadmap/STATE.md, the de-quarantine (EXL-04) moves that file **verbatim first** (a provable no-op), and money-string normalization to the `"79.00"`-style format is an explicitly separate, later commit — do not conflate the two steps into one plan task.

## Code Examples

### Reading a fixture from the loader (new — synthesized from Pattern 1)
```elixir
# Source: pattern mirrors lib/rendro/branded.ex (existing, verified)
Rendro.Examples.load!("invoice/acme-phoenix-saas/invoice.json")
```

### Validating a fixture against the schema in a docs-contract test (new — synthesized from Pattern 2)
```elixir
# Source: pattern mirrors lib/rendro/public_api/validator.ex + test/rendro/viewer_evidence/validator_test.exs
schema =
  "priv/schemas/examples.schema.json"
  |> File.read!()
  |> JSON.decode!()
  |> JSV.build!()

for path <- Path.wildcard("priv/examples/**/*.json") do
  fixture = path |> File.read!() |> JSON.decode!()
  assert {:ok, _} = JSV.validate(fixture, schema), "#{path} failed schema validation"
end
```

### Tarball text-only assertion for `priv/examples/` (new — synthesized from Pattern 3)
```elixir
# Source: pattern mirrors test/docs_contract/branding_claims_test.exs "hex tarball contents"
tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
{_output, 0} = Rendro.Test.HexBuildCache.get_build_output()
list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
{contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

example_paths =
  contents
  |> String.split("\n", trim: true)
  |> Enum.filter(&String.starts_with?(&1, "priv/examples/"))

assert example_paths != []

for path <- example_paths do
  assert Path.extname(path) in [".json", ".md", ".svg"],
         "#{path} must be text-only (.json/.md/.svg)"
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `invoice_data.json` lives only in `bench/comparison/fixtures/`, used solely for benchmark comparisons | De-quarantined into `priv/examples/`, shared across tests/bench/guides/Livebook via `Rendro.Examples` | This phase (EXL-04) | Single source of truth for the one existing realistic fixture; bench harness becomes a *consumer* of the shared library rather than owning its own private copy |

**Deprecated/outdated:** None — this phase is additive; nothing existing is removed except the fixture's old file-path (moved, not deleted).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The specific reader personas, JTBD, "one fact they need first," and layout/typographic conventions to document in `DOMAIN.md` for the Invoice domain (e.g., accounts-payable clerk needs total-due and due-date first; issuer/customer need legal-entity clarity) | RUB-01 (not directly quoted in this doc but load-bearing for the planner) | If the assumed reader model is wrong, `DOMAIN.md` content and the rubric's "domain-fit/least-surprise" anchors could mis-target what "reader quality" means, requiring a rewrite in Phase 118 when demos are scored against it |
| A2 | The concrete 1/3/4/5 anchor language for each of the 6 rubric dimensions (information architecture; content hierarchy; domain-fit/least-surprise; reader affordances; typographic craft; restraint/cohesion) — this is inherently subjective, non-designer-facing prose that must be authored, not looked up | RUB-02 | A poorly-anchored rubric could be too vague for Phase 118 demos to score consistently, or too strict/lenient relative to what Invoice/Payslip/Ticket can realistically achieve without the theming system (Milestone B) |
| A3 | Whether `priv/quality/rubric_scores.json` and `priv/schemas/rubric_scores.schema.json` should ship in the Hex tarball or stay repo-only | Package Legitimacy Audit / Pitfall 4 / Open Questions | If shipped when it should be repo-only (or vice versa), the tarball-exclusion test (Pitfall 4) will need adjusting later, and Milestone C's "public example catalog" (which explicitly reuses S4/S5) may need the manifest to be either shippable or not — worth locking down now rather than guessing wrong twice |
| A4 | Business/domain naming for the first Invoice fixture(s) beyond the already-established `"Rendro Systems"` (issuer) / `"Acme Phoenix SaaS"` (customer) pair already present in the quarantined fixture, and `"Acme Corp"` used elsewhere in `Rendro.LaunchArtifacts` demo generation | EXL-01 fixture content | Low risk — these are placeholder fictional names; reusing established ones (`Acme Phoenix SaaS`, `Rendro Systems`) keeps consistency with existing demo/bench naming, but the planner is free to introduce additional fictional businesses per the milestone's "family × domain" matrix groundwork |

**If this table is empty:** N/A — table is populated; the domain/rubric authorship (A1, A2) is the genuinely research-heavy part of this phase and should get a light human sanity-check per this project's stated preference for locked recommendations (per user's research-first-recommendations memory) rather than an open question — this research proceeds with a confident default (professional-services accounts-payable/payroll/travel reader model) and flags it here for the planner to carry forward as a locked assumption unless corrected.

## Open Questions

1. **Should `priv/quality/rubric_scores.json` + its schema ship in the Hex tarball, or stay repo-only like `priv/schemas/*` and `priv/support_matrix.json`?**
   - What we know: `priv/schemas/*` and `priv/public_api.json`/`priv/support_matrix.json` are all repo-only today (absent from `package/0` `:files`, actively excluded by a docs-contract test). The rubric manifest is analogous in *shape* (a structural JSON contract) but its *purpose* (S5: seam for Milestone C's "public example catalog" quality-ratchet) suggests it might eventually need to be readable by downstream tooling/consumers, possibly even by a future public catalog UI.
   - What's unclear: Whether "Milestone C reuses S4 brand slot + S5 rubric manifest" (per ROADMAP) implies the manifest must be *shippable* now, or whether Milestone C can simply re-read it from the repo at build/codegen time (since presets/catalog generation likely happens via a `mix rendro.gen.theme`-style dev-time task, not a runtime library call).
   - Recommendation: Default to **repo-only** for `priv/quality/rubric_scores.json` and both new schemas (mirrors every other structural-contract JSON file in the repo: `public_api.json`, `support_matrix.json`, `priv/guardrails/required_status_checks.json`) — only `priv/examples/` needs the shippable/tarball treatment, since only fixture *data* (not quality *metadata*) needs to reach Livebook/shipped-consumer contexts. If Milestone C later needs runtime access to rubric scores, it can add that seam then (S5 already permits append-only growth without breaking this default).

2. **Does `Rendro.Examples.load!/1` need a `list/1`-style enumeration API in this phase, or is `load!/1` (single fixture) sufficient for EXL-01..06's stated success criteria?**
   - What we know: EXL-02 only requires the loader to "read fixtures for tests, the bench harness, guides, and Livebook" — none of those consumers in *this* phase need to enumerate all fixtures in a domain (Phase 118's demo matrix will likely need enumeration, but that's a later phase).
   - What's unclear: Whether it's worth building `list/1` now (cheap, single function, low risk) versus deferring to Phase 118 when it's actually needed.
   - Recommendation: Build it now — it's a 5-line function using `Path.wildcard/1` off the same `Application.app_dir/2`-resolved base, and having it available (even unused within Phase 114) costs nothing and de-risks Phase 118's actual need for it. Do not, however, wire it into anything beyond the loader module itself — no `lib/` product change beyond the loader, per the phase goal.

## Environment Availability

Skipped — this phase has no external tool/runtime/service dependencies beyond what's already vetted in `mix.lock` (`jsv`, `decimal`) and Elixir's built-in `JSON` module, all already present in the dev/CI environment that runs the existing test suite. `tar`, `sh`, and `git` (used for the tarball-audit pattern and file moves) are already required and available per the existing `branding_claims_test.exs`/`launch_artifacts_claims_test.exs` tests that pass in CI today.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in), `mix test` |
| Config file | `test/test_helper.exs` (excludes `:quarantine`, `:live_pdf_tools`, `:live_signing`, `:raster_snapshot` by default) |
| Quick run command | `mix test test/rendro/examples_test.exs test/docs_contract/examples_schema_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs` |
| Full suite command | `mix test --exclude quarantine --slowest 10` (the required `test` job's exact command) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|--------------------|--------------|
| EXL-01 | Fixtures exist, encode domain language, money-as-strings, optional empty brand/logo slot | unit (schema) | `mix test test/docs_contract/examples_schema_contract_test.exs` | ❌ Wave 0 |
| EXL-02 | Loader reads fixtures via `app_dir`; absent from `public_api.json` | unit | `mix test test/rendro/examples_test.exs test/docs_contract/public_api_contract_test.exs` | ❌ Wave 0 (examples_test.exs); ✅ public_api_contract_test.exs exists, extend its hidden-modules list |
| EXL-03 | Every fixture validates against `examples.schema.json` | unit (docs-contract) | `mix test test/docs_contract/examples_schema_contract_test.exs` | ❌ Wave 0 |
| EXL-04 | De-quarantine is a provable no-op; `mix rendro.comparison.check` stays green | integration + manual byte-diff (see Pitfall 2) | `mix rendro.comparison.check` (necessary but NOT sufficient — supplement with an explicit before/after PDF-bytes or JSON-bytes diff assertion) | ❌ Wave 0 — new assertion needed since `check` alone can't prove this |
| EXL-05 | `priv/examples/` ships text-only; raster-ban test mirrors `brand/` | unit + tarball integration | `mix test test/rendro/examples_test.exs test/docs_contract/examples_schema_contract_test.exs` (wildcard-extension check) + a hex-build tarball-content test | ❌ Wave 0 |
| EXL-06 | Optional empty `brand`/`logo` sub-object present in every fixture (S4) | unit (schema `required`/`properties`) | `mix test test/docs_contract/examples_schema_contract_test.exs` | ❌ Wave 0 (folded into schema contract test) |
| RUB-01 | `DOMAIN.md` exists per domain with required sections | unit (docs-contract, structural — e.g. required headings present) | new `test/docs_contract/domain_md_contract_test.exs` (or fold into examples schema contract test) | ❌ Wave 0 |
| RUB-02 | Rubric defined with 6 core dims + 2 gates, concrete anchors | doc content (not independently automatable — anchors are prose) | manual review + `rubric_manifest_contract_test.exs`'s structural check that the schema *enumerates* the 6+2 dimensions | ❌ Wave 0 (schema-level enumeration only; anchor prose quality is human-reviewed) |
| RUB-03 | Rubric manifest is schema-backed, appendable; docs-contract lane enforces structure + threshold arithmetic (not subjective score) | unit (docs-contract) | `mix test test/docs_contract/rubric_manifest_contract_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** targeted `mix test` invocation for the file(s) touched (see Quick run command)
- **Per wave merge:** `mix test --exclude quarantine --slowest 10` (full suite)
- **Phase gate:** Full suite green + `mix hex.build` (or `mix ci.fast`, which runs `hex.build` then the full test suite) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/rendro/examples_test.exs` — loader behavior (`load!/1`, `list/1`) + in-repo wildcard extension-ban assertion
- [ ] `test/docs_contract/examples_schema_contract_test.exs` — every `priv/examples/**/*.json` validates against `priv/schemas/examples.schema.json`; also asserts the tarball's `priv/examples/` entries are text-only (Pattern 3)
- [ ] `test/docs_contract/rubric_manifest_contract_test.exs` — `priv/quality/rubric_scores.json` validates against `priv/schemas/rubric_scores.schema.json`; asserts threshold arithmetic (hierarchy == 5, core dims >= 4, both gates pass) is enforced structurally, not the subjective score value
- [ ] Extend `test/docs_contract/public_api_contract_test.exs`'s "known internal modules are :hidden" list (Assertion 3) to include `Rendro.Examples`, mirroring how `Rendro.Format`/`Rendro.Audit`/etc. are already asserted hidden — this is the concrete mechanism for "asserted absent from `priv/public_api.json`"
- [ ] Extend (or add a sibling to) `test/docs_contract/branding_claims_test.exs`-style "built tarball excludes operator-only priv paths" test to also `refute contents =~ "priv/schemas/examples.schema.json"` and `refute contents =~ "priv/quality/"`
- [ ] No new framework install needed — ExUnit + `jsv` + built-in `JSON` are all already present

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | no | This phase has no auth surface — read-only static file loader |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A — `Rendro.Examples` reads only files shipped by the library itself, never user-supplied paths |
| V5 Input Validation | yes | JSON Schema validation via `jsv` (`examples.schema.json`, `rubric_scores.schema.json`) is the input-validation control for the two new structured-data surfaces this phase introduces |
| V6 Cryptography | no | N/A — no cryptographic operations in this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Path traversal via a caller-supplied relative path to `Rendro.Examples.load!/1` | Tampering / Information Disclosure | Since `Rendro.Examples` is `@moduledoc false` (internal-only, never part of the public API surface), it is not a caller-facing attack surface in this milestone — but if the planner designs `load!/1` to accept arbitrary caller-supplied strings (rather than only being called internally with hardcoded literal paths from tests/bench/guides), validate that the resolved path stays within `Application.app_dir(:rendro, "priv/examples")` (e.g. via `Path.safe_relative/2`, available in Elixir 1.14+) before reading, to prevent `../../../etc/passwd`-style traversal if this internal module is ever exposed indirectly (e.g. through a future public catalog feature in Milestone C) |
| Malformed/oversized fixture JSON causing unbounded memory use at decode time | Denial of Service | Not a practical risk here — all fixtures are repo-authored, shipped, and schema-validated at CI time, not user-uploaded at runtime; no mitigation needed beyond the existing schema validation gate |

## Sources

### Primary (HIGH confidence)
- `lib/rendro/branded.ex` — the `@moduledoc false` + `Application.app_dir/2` loader pattern to mirror for `Rendro.Examples`
- `lib/rendro/public_api/validator.ex`, `lib/rendro/viewer_evidence/validator.ex`, `test/rendro/viewer_evidence/validator_test.exs` — the `jsv`/`JSV.build!`/`JSV.validate` pattern
- `priv/schemas/public_api.schema.json`, `priv/schemas/support_matrix.schema.json`, `priv/schemas/viewer_evidence.schema.json` — JSON Schema draft (`2020-12`) and structure conventions to mirror
- `test/docs_contract/branding_claims_test.exs`, `test/docs_contract/launch_artifacts_claims_test.exs` — the `tar -xOf <tarball> contents.tar.gz | tar -tzf -` tarball-content-assertion pattern (both inclusion and exclusion cases)
- `mix.exs` — `package/0` `:files` allowlist (current contents verified directly); `deps/0` (confirms `jsv`, `decimal` present; confirms `Jason` absent as a direct dep)
- `lib/mix/tasks/rendro/api.gen.ex` — the hardcoded `@public_modules` list mechanism that determines `priv/public_api.json` membership (confirms `Rendro.Examples` will be naturally absent as long as it's never added here)
- `test/docs_contract/public_api_contract_test.exs` — Assertion 3 ("known internal modules are :hidden") is the concrete mechanism for asserting a module is absent/hidden from the public API contract
- `.gitignore` lines 56-67 and `.planning/milestones/B1-phases/107-brand-book-qa/107-SUMMARY.md` — the actual `brand/` raster-protection mechanism (a `.gitignore` extension block, not a test)
- `lib/rendro/comparison.ex`, `lib/mix/tasks/rendro/comparison/check.ex`, `bench/comparison/run.exs`, `bench/comparison/fixtures/invoice_rendro.exs`, `bench/comparison/fixtures/invoice_typst.typ`, `bench/results/comparison.json` — full trace of what `mix rendro.comparison.check` actually validates (confirms it does NOT re-read the fixture file) and every hardcoded path reference that must be repointed for EXL-04
- `test/guardrails/required_checks_contract_test.exs`, `scripts/verify_docs.exs` — the exact-count (22) docs-contract-lane guardrail that must be considered if new lanes are registered
- `mix.lock` — confirmed locked versions: `jsv` 0.19.1, `decimal` 2.4.1, `jason` 1.4.5 (transitive)
- `priv/public_api.json` — current public module/tier manifest (confirms no `Rendro.Examples`-like entry exists yet, and confirms the manifest structure new code must not disturb)
- `bench/comparison/fixtures/invoice_data.json` — the actual fixture to be de-quarantined (confirmed: `price_cents` integer-cents format today, not yet Decimal-string money)
- `lib/rendro/format.ex`, `lib/rendro/recipes/invoice.ex` — confirm today's toy-call money format (`"$#{price}"` on a bare number) is untouched by this phase; Decimal integration is explicitly Phase 115's job

### Secondary (MEDIUM confidence)
- `guides/user_flows_and_jtbd.md`, `guides/livebook/first_invoice.livemd` — confirm Livebook's `Mix.install` dependency-resolution path, supporting the `Application.app_dir/2` reasoning for why EXL-05 (shipping `priv/examples/`) is load-bearing for Livebook/Hex consumers

### Tertiary (LOW confidence)
- General professional-services domain knowledge about invoice/payslip/ticket readers, JTBD, and reader-quality anchors (RUB-01/RUB-02 content) — `[ASSUMED]`, not verifiable against this codebase; flagged in Assumptions Log A1/A2

## Metadata

**Confidence breakdown:**
- Standard stack / packaging mechanics: HIGH — every pattern verified directly against committed, working code in this repository
- Architecture (loader, schema, tarball-audit patterns): HIGH — all three have a live, passing reference implementation to mirror
- Domain research content (personas, JTBD, rubric anchors): MEDIUM/LOW — necessarily synthesized from general domain knowledge, not verifiable via any tool available in this session; flagged for light human sanity-check

**Research date:** 2026-07-10
**Valid until:** Packaging/mechanics findings are stable until `mix.exs`, `jsv`, or the tarball format change (effectively indefinite — treat as ~180 days). Domain-research content (personas/rubric) does not go stale on a calendar basis but should be revisited if user feedback on the rubric surfaces during Phase 118's actual demo scoring.
