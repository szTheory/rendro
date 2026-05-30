---
phase: 78-public-api-surface-definition-cleanup
reviewed: 2026-05-30T15:24:21Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/mix/tasks/rendro/api.gen.ex
  - lib/rendro/public_api.ex
  - lib/rendro/public_api/loader.ex
  - lib/rendro/public_api/validator.ex
  - lib/rendro/recipes/invoice.ex
  - lib/rendro/recipes/branded_invoice.ex
  - lib/rendro/metadata.ex
  - lib/rendro.ex
  - lib/rendro/sign.ex
  - lib/rendro/adapters/oban/render_worker.ex
  - priv/public_api.json
  - priv/schemas/public_api.schema.json
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 78: Code Review Report

**Reviewed:** 2026-05-30T15:24:21Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Phase 78 introduces a public-API-surface introspection subsystem (`Rendro.PublicApi`,
`PublicApi.Loader`, `PublicApi.Validator`, and the `mix rendro.api.gen` task) plus a
checked-in manifest (`priv/public_api.json`) governed by a JSON schema. The bulk of the
phase is single-attribute `@moduledoc tags:` / `@moduledoc false` / `@doc false` edits.

I audited the doc-attribute edits and they are well-executed: every tagged module uses the
correct two-attribute form (prose `@moduledoc` followed by a separate `@moduledoc tags:`),
all four conditional adapters carry `tags: [:adapter]`, nested exception modules
(`AssetRegistry.InvalidAssetError`, `FontRegistry.EmbeddedFontFamilyError`) are tagged
`[:stable]`, the six internal engine modules (`Format`, `Audit`, `Text.Bidi`, `Text.Shaper`,
`PDF.CidFont`, `PDF.FontSubsetter`) are `@moduledoc false` and absent from the manifest, and
the four `Sign.redact_*` helpers are `@doc false`. No misapplied tag or accidentally-hidden
load-bearing public type was found in the doc edits.

The substantive findings are in the new generator/introspection logic. The most material
issue is that the generator claims to produce a "schema-validated manifest" but never calls
the validator, allowing schema-violating output to be written silently. A second class of
findings concerns silent data loss (registered modules dropped without warning) and an
undeclared direct dependency on `Jason`.

There are no Critical findings — the subsystem is internal/dev-only (`@moduledoc false`,
"Do NOT call from application code"), so the dev-only dependency scoping and runtime-path
concerns do not reach production code.

## Warnings

### WR-01: Generator never validates the manifest it claims is "schema-validated"

**File:** `lib/mix/tasks/rendro/api.gen.ex:97-122`
**Issue:** The `@moduledoc` (line 28) states the task "Writes `priv/public_api.json` — a
schema-validated manifest", and a `Rendro.PublicApi.Validator.validate/1` function exists
specifically for this purpose. However `run/2` never calls it. The pipeline is
`build_manifest -> encode_manifest -> File.write!` with no validation step. Because
`PublicApi.build_manifest/1` emits `to_string(tier_of(mod))` unconditionally (no guard on
`:untagged`), a registered module that loses its tag will silently produce
`"tier": "untagged"` in the JSON — which violates the schema's `enum: ["stable", "adapter"]`
(`priv/schemas/public_api.schema.json:23`). The drift is only caught later by the separate
`ManifestTest` (test 4), not at generation time, so a developer running the generator gets a
"success" message while committing an invalid file.
**Fix:** Validate before writing and fail loudly:
```elixir
manifest = Rendro.PublicApi.build_manifest(loaded_modules)

case Rendro.PublicApi.Validator.validate(manifest) do
  :ok ->
    File.write!(@manifest_path, encode_manifest(manifest) <> "\n")
    Mix.shell().info("Wrote #{@manifest_path}")

  {:error, reason} ->
    Mix.shell().error("Generated manifest failed schema validation:\n#{reason}")
    exit({:shutdown, 1})
end
```

### WR-02: Registered modules silently dropped from the manifest when docs are unavailable

**File:** `lib/mix/tasks/rendro/api.gen.ex:107-112`
**Issue:** `run/2` filters `@public_modules` down to `loaded_modules` (those that load AND
have a `:docs_v1` chunk). Any registered module that fails this filter is dropped from the
manifest with no diagnostic. This is intentional for conditional adapters compiled in-memory,
but it also masks real mistakes: a typo in the registry (non-existent module), a module
accidentally given `@moduledoc false`, or a module compiled with `strip_beam`/no-docs would
all vanish silently. For a "canonical source of truth for the public API surface" this is a
correctness gap — a stable module could disappear from the contract without anyone noticing,
defeating the drift-detection purpose.
**Fix:** Distinguish "expected-conditional" from "unexpectedly missing" and warn on the
latter:
```elixir
{loaded_modules, missing} =
  Enum.split_with(@public_modules, fn mod ->
    Code.ensure_loaded?(mod) and
      match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod))
  end)

unexpected = missing -- @conditional_adapters
if unexpected != [] do
  Mix.shell().error(
    "Registered modules missing from manifest (no BEAM docs):\n" <>
      Enum.map_join(unexpected, "\n", &"  #{inspect(&1)}")
  )
  exit({:shutdown, 1})
end
```

### WR-03: `Jason` used directly but not declared as a dependency

**File:** `lib/mix/tasks/rendro/api.gen.ex:137,148,152`
**Issue:** `encode_manifest/1` references `%Jason.OrderedObject{}` and `Jason.encode!/2`
directly, but `jason` does not appear in `mix.exs` `deps/0`. It currently resolves only
transitively (via `req`, `credo`, `rustler`, `oban`, `phoenix`). The byte-equality drift test
(`manifest_test.exs:95`) also depends on `Jason.OrderedObject` being present. If the
transitive provider that pins `jason` is removed or bumped, both the generator and the drift
guard break with `Jason.OrderedObject is undefined` — a confusing failure far from its cause.
Relying on transitive resolution for a direct, code-level dependency is fragile.
**Fix:** Declare it explicitly, scoped to where it is used (dev/test, since this is a Mix task
and a test):
```elixir
{:jason, "~> 1.4", only: [:dev, :test], runtime: false},
```

### WR-04: Validator/Loader use repo-relative paths that break outside the project root

**File:** `lib/rendro/public_api/loader.ex:4,8` and `lib/rendro/public_api/validator.ex:4,8`
**Issue:** Both modules build paths from string literals relative to CWD
(`"priv/public_api.json"`, `"priv/schemas/public_api.schema.json"`) and call `File.read!/1`.
This only works when the process CWD is the project root. `Rendro.PublicApi`
(`public_api.ex:93`) likewise hardcodes `File.cwd!()` as the project root in
`recompile_conditional_adapters/0`. For Mix tasks and ExUnit runs CWD is the root, so it
works today, but any other caller (a release, a different working directory, a nested umbrella
invocation) gets a `File.Error`. Since these are documented internal/dev tools the blast
radius is limited, hence WARNING not BLOCKER.
**Fix:** Resolve against the application's `priv` dir, which is location-independent:
```elixir
defp manifest_path, do: Path.join(:code.priv_dir(:rendro), "public_api.json")
```
(and the analogous `schemas/public_api.schema.json` for the validator).

## Info

### IN-01: Recipe `opts` parameter is threaded but never consumed

**File:** `lib/rendro/recipes/invoice.ex:112,123,142` and
`lib/rendro/recipes/branded_invoice.ex:139,149,167,186`
**Issue:** `sections/2` now forwards `opts` to every private section builder, but each builder
ignores it (`_opts`). The opts-threading tests
(`invoice_opts_threading_test.exs`, `branded_invoice_opts_threading_test.exs`) only assert
that unknown opts are accepted and that default output is byte-identical — i.e. they confirm
the plumbing exists but nothing actually reads it. This is acceptable as deliberate
forward-compatibility scaffolding (the phase notes call this D-10/D-11), but it is currently
dead parameter passing. Flagging so it is tracked as intentional rather than forgotten.
**Fix:** No change required if this is intentional scaffolding; otherwise wire at least one
builder to consume an opt (e.g. an override for header text) so the parameter is exercised.

### IN-02: `BrandedInvoice.document/2` validates data twice

**File:** `lib/rendro/recipes/branded_invoice.ex:115-118`
**Issue:** `document/2` calls `validate_data!(data)` (line 116) and then calls `sections/2`
(line 118), which itself calls `validate_data!(data)` again (line 101). The validation is
pure and idempotent so this is harmless, but it is redundant work and a minor maintenance
smell (two call sites to keep in sync).
**Fix:** Drop the explicit `validate_data!/1` call in `document/2` and rely on the one inside
`sections/2`, or factor validation to a single guaranteed entry point.

### IN-03: `format_jsv_error/1` uses `inspect(limit: :infinity)`, producing opaque error strings

**File:** `lib/rendro/public_api/validator.ex:16-20`
**Issue:** Validation failures are surfaced as `inspect(normalized_error, limit: :infinity)`.
This yields a single, unbounded Elixir term dump rather than a human-readable message,
which is poor diagnostics for the very drift scenario the validator exists to catch. Because
the generator does not yet call the validator (WR-01), this code path is currently unused,
but once wired up the message quality matters.
**Fix:** Render the JSV normalized error into a readable summary (e.g. join per-instance
error paths and messages) instead of a raw `inspect`, or at least bound `limit:` to a sane
value.

---

_Reviewed: 2026-05-30T15:24:21Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
