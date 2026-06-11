---
phase: 85-deterministic-raster-lane
reviewed: 2026-06-10T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - .github/workflows/ci.yml
  - lib/rendro/adapters/pdfium.ex
  - lib/rendro/viewer_evidence/validator.ex
  - priv/guardrails/required_status_checks.json
  - priv/pdfium_pin.json
  - priv/public_api.json
  - priv/schemas/support_matrix.schema.json
  - priv/support_matrix.json
  - scripts/verify_docs.exs
  - test/docs_contract/raster_claims_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - test/rendro/adapters/pdfium_raster_snapshot_test.exs
  - test/rendro/adapters/pdfium_test.exs
  - test/test_helper.exs
findings:
  critical: 2
  warning: 5
  info: 4
  total: 11
status: issues_found
---

# Phase 85: Code Review Report

**Reviewed:** 2026-06-10T00:00:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Phase 85 adds a "deterministic raster lane": a `Pdfium.render/2` adapter that
shells out to pdfium-cli, a new `raster` section in the support matrix, a
`pdfium-render` viewer_kind enum entry in both the JSON schema and the validator,
a `raster-advisory` CI job, and a raster snapshot test harness.

The most serious problem is that the **headline deliverable — deterministic
raster snapshot verification — does not actually verify anything**. The CI
`raster-advisory` job runs a test file whose snapshot machinery
(`assert_or_bless`, `assert_golden_hashes`, `bless_refs`) is never invoked with
real rendered output. `Pdfium.render/2` is never called from the snapshot test.
The one tagged test that "runs" is a self-referential tautology that hashes a ref
file and compares it to its own decoded contents. The lane is named, wired, and
green, but it is hollow: a genuine raster regression would pass CI silently.

The second blocker is a guardrail weakening: adding `pdfium-render` to the
`viewer_row.viewer_kind` enum now structurally permits GUI-viewer rows to claim
engine-only `pdfium-render` evidence. The only thing preventing that
misclassification is a single `=~`/`refute` docs-contract assertion, not the
schema. This is exactly the truthfulness boundary the matrix exists to protect.

There are also several robustness and correctness warnings in the adapter and
test harness, detailed below.

## Critical Issues

### CR-01: Raster snapshot lane verifies nothing — dead harness, tautological test

**File:** `test/rendro/adapters/pdfium_raster_snapshot_test.exs:23-37`, `66-85`; `.github/workflows/ci.yml:50-79`

**Issue:** The CI `raster-advisory` job exists to prove byte-deterministic raster
output (`byte_deterministic_on_pinned_container: "supported"` in
`priv/support_matrix.json:489`). But the test it runs proves no such thing:

1. `Pdfium.render/2` is **never called** anywhere in this test file. No PDF is
   rendered, so no rendered PNG is ever hashed against a golden ref.
2. `assert_or_bless/2`, `assert_golden_hashes/2`, and `bless_refs/2` are dead
   except for `assert_or_bless_stub/0`, which only exercises the bless *guard*
   with `pngs: []`. With an empty list, `assert_golden_hashes` /`bless_refs`
   iterate zero times and trivially pass.
3. The only `@tag raster_snapshot` test (lines 24-37) reads
   `priv/raster_refs/invoice/page_1.sha256`, then hashes *that ref file's bytes*
   and asserts the hash equals the file's own trimmed contents. This can never
   be a meaningful equality (a sha256 hex string is not the sha256 of itself),
   and in practice the ref does not exist (`priv/raster_refs/` contains only
   `.gitkeep`), so the test takes the `else` branch and prints "Skipping". The
   assertion is unreachable.

Net effect: the `raster-advisory` job downloads pdfium, then runs a test that
renders nothing and skips. A real raster regression cannot fail this lane. The
phase's central claim ("deterministic raster lane") is unbacked by any executing
assertion.

**Fix:** Wire the snapshot test to actually render a committed fixture and
compare against blessed hashes, e.g.:
```elixir
@tag raster_snapshot: true
test "invoice fixture renders to byte-stable PNGs" do
  pdf = File.read!("test/fixtures/raster/invoice.pdf")
  {:ok, pngs} = Rendro.Adapters.Pdfium.render(pdf, dpi: 150)
  assert_or_bless("invoice", pngs)
end
```
and replace the tautological hash test (lines 24-37) with a real render-and-
compare (or delete it). Until a render call feeds `assert_golden_hashes`, the
lane should not be advertised as a determinism proof.

### CR-02: Schema/validator change lets GUI-viewer rows claim engine-only `pdfium-render` evidence

**File:** `priv/schemas/support_matrix.schema.json:115`; `lib/rendro/viewer_evidence/validator.ex:15`

**Issue:** This phase adds `pdfium-render` to the `viewer_row.viewer_kind` enum
in both the schema and `@viewer_kinds`. `viewer_kind` lives on the per-viewer
rows under `forms.viewers`, `signing.viewers`, etc. — rows that represent
*GUI viewer* promotion (Adobe Acrobat, Apple Preview, Chrome). `pdfium-render`
is an *engine* observation that the matrix itself explicitly says "does not claim
GUI-viewer visual fidelity" (`priv/support_matrix.json:501`).

By widening the row-level enum, the structural contract now *permits* a row like
`forms.viewers.adobe_acrobat_reader` to set `viewer_kind: "pdfium-render"` and
pass schema + promotion validation, falsely back-stamping a GUI-viewer support
claim with engine-only evidence. The intended invariant ("GUI-viewer rows must
not carry pdfium-render") is enforced **only** by one docs-contract assertion
(`test/docs_contract/raster_claims_test.exs:45-59`), not by the schema or
`promotion_complete_row?/1`. A single test is a weak guard for a truthfulness
boundary that the schema is supposed to own; if that test is ever weakened or
the section list (line 48) drifts out of sync with the matrix, the
misclassification ships silently.

Note the `raster` top-level section's own `evidence.viewer_kind: "pdfium-render"`
(`priv/support_matrix.json:498`) does **not** need this enum entry at all — that
block sits under the root's `additionalProperties: true` and is never validated
against `viewer_row`. So the enum widening grants no benefit to the legitimate
consumer while opening the GUI-row hole.

**Fix:** Do not widen the shared `viewer_row.viewer_kind` enum. Keep GUI-viewer
rows restricted to `["manual", "pdfium-cli", "pdfjs-dist"]` and model the raster
engine evidence under its own schema branch (the `raster` section), or add an
explicit schema constraint that `pdfium-render` is only permitted outside
`*.viewers.*` rows. At minimum, promote the GUI-row exclusion from a single
docs-contract test into a schema-level / `promotion_complete_row?` invariant so
the structural contract — not a stringly-typed test — enforces it.

## Warnings

### WR-01: `--pages` value can be interpreted as a pdfium-cli flag (argument injection)

**File:** `lib/rendro/adapters/pdfium.ex:90-94`, `132-138`

**Issue:** `validate_pages/1` accepts any non-empty binary and passes it as
`["--pages", pages]`. List-form `System.cmd` correctly prevents *shell* injection,
but it does not prevent *argument* injection: a `pages` value beginning with `-`
(e.g. `"--output-type"` or any pdfium flag) is still passed as a distinct argv
token and may be parsed by pdfium-cli as an option rather than a page range.
The moduledoc advertises `pages:` as a "page range string" but no format
constraint enforces that.

**Fix:** Validate the page-range format rather than just non-emptiness, e.g.
`Regex.match?(~r/\A[0-9,\-\s]+\z/, pages)`, and reject anything else with
`{:error, {:invalid_option, :pages, "must be a page range like \"1-3,5\""}}`.

### WR-02: `collect_pngs/1` sorts page filenames lexicographically — wrong order past page 9

**File:** `lib/rendro/adapters/pdfium.ex:144-155`

**Issue:** Output files are `page_%d.png` (`page_1.png`, `page_2.png`, ...,
`page_10.png`). `Enum.sort/1` on these paths is lexicographic, so for a 10+ page
document the order becomes `page_1, page_10, page_11, page_2, ...`. The returned
PNG list is therefore out of page order for any document with more than 9 pages,
silently corrupting the page->binary mapping that `assert_golden_hashes`
(and any real consumer) relies on via `Enum.with_index(pngs, 1)`.

**Fix:** Sort by extracted page number, not by string:
```elixir
Path.wildcard(Path.join(tmp_dir, "page_*.png"))
|> Enum.sort_by(fn p ->
  p |> Path.basename() |> String.replace(~r/\D/, "") |> String.to_integer()
end)
```

### WR-03: Snapshot test mutates and deletes the global `GITHUB_ACTIONS` env var

**File:** `test/rendro/adapters/pdfium_raster_snapshot_test.exs:6-19`

**Issue:** The bless-guard test calls `System.delete_env("GITHUB_ACTIONS")` and
the `on_exit` also deletes it. `System.put/delete_env` is process-global for the
whole VM, not test-scoped. Even though this file is `async: false`, other test
files may run concurrently with it (ExUnit parallelizes across files unless all
are `async: false`), and the `on_exit` unconditionally *deletes* `GITHUB_ACTIONS`
rather than restoring its prior value. On a CI runner where `GITHUB_ACTIONS=true`
is set, this can clobber that variable for any code/test that reads it.

**Fix:** Capture and restore the prior value instead of deleting:
```elixir
prior = System.get_env("GITHUB_ACTIONS")
on_exit(fn ->
  System.delete_env("MIX_RASTER_BLESS")
  if prior, do: System.put_env("GITHUB_ACTIONS", prior), else: System.delete_env("GITHUB_ACTIONS")
end)
```

### WR-04: pdfium-cli version mismatch between raster lane and live-proof lane

**File:** `.github/workflows/ci.yml:68` vs `:97`

**Issue:** The new `raster-advisory` job pins pdfium-cli `v0.11.0`
(`priv/pdfium_pin.json`), while the existing `viewer-evidence-live-proof` job
still installs `v0.10.3` (line 97). The matrix's existing GUI-viewer evidence
rows carry `viewer_kind: "pdfium-cli"` and were recorded against the older
binary, while the new raster evidence claims `renderer_version: "v0.11.0"`. Two
different pdfium versions now produce "evidence" in the same CI, which undercuts
the determinism story and makes the pin file ambiguous about which lane it
governs. The `pdfium_pin.json` is not referenced by `viewer-evidence-live-proof`
at all, so its sha256 guard does not protect that download.

**Fix:** Either bump `viewer-evidence-live-proof` to the pinned `v0.11.0` (and
re-record affected evidence) or document explicitly why the two lanes
intentionally run different pdfium versions, and have both lanes read the
version+sha from `priv/pdfium_pin.json` rather than hardcoding.

### WR-05: `write_private_file/1` ignores `File.rm` result; `:exclusive` + pre-`rm` is contradictory

**File:** `lib/rendro/adapters/pdfium.ex:111-118`

**Issue:** `write_private_file` first does `File.rm(path)` (discarding the result)
and then opens with `[:write, :exclusive, :binary]`. The `:exclusive` flag exists
to fail if the file already exists — but the unconditional preceding `File.rm`
defeats that protection by removing any pre-existing file first, so the
exclusivity guard is effectively a no-op. If the goal is to refuse a pre-existing
file (the tmp dir is freshly created with a unique name, so a collision indicates
a real anomaly), the `rm` should be dropped. If the goal is overwrite, the
`:exclusive` flag is misleading and should be dropped. The mixed intent makes the
security posture unclear.

**Fix:** Drop the `File.rm(path)` and rely on `:exclusive` (fail-closed on
collision), or drop `:exclusive` if overwrite is intended. Do not silently
discard the `File.rm` error either way.

## Info

### IN-01: Misleading lane label — "deterministic" / "advisory" but no determinism check runs

**File:** `priv/guardrails/required_status_checks.json:58-61`; `priv/support_matrix.json:489`

**Issue:** The advisory context notes and the matrix capability
`byte_deterministic_on_pinned_container: "supported"` assert a determinism
guarantee that no executing assertion currently backs (see CR-01). Marking a
capability "supported" in the matrix while its proof lane is hollow is precisely
the kind of unbacked claim the support matrix is designed to prevent.

**Fix:** Downgrade the capability to `unverified` until CR-01 is resolved, or
resolve CR-01 so the claim is backed.

### IN-02: pdfium-cli WASM binary installed as native executable

**File:** `.github/workflows/ci.yml:67-68`

**Issue:** The pinned artifact is `pdfium-webassembly-linux-amd64` — a WASM build
— installed directly as `/usr/local/bin/pdfium-cli`. This mirrors the pre-existing
`viewer-evidence-live-proof` pattern, so it may be intentional, but it is worth
confirming the WASM artifact is actually directly executable on the runner and is
the correct artifact for byte-deterministic raster output (vs. a native build).

**Fix:** Confirm the WASM artifact is the intended one for raster determinism;
add a one-line comment in the CI step documenting why the WASM build is used.

### IN-03: Module/section naming inconsistency: `pdfium-cli` adapter vs `pdfium-render` renderer

**File:** `lib/rendro/adapters/pdfium.ex:1-8`; `priv/support_matrix.json:484`

**Issue:** The adapter module documents itself as wrapping `pdfium-cli` and its
`render/2` shells out to `pdfium-cli`, but the matrix raster section declares
`"renderer": "pdfium-render"` and `viewer_kind: "pdfium-render"`. `pdfium-render`
is a distinct (Rust) project name. Using the `pdfium-render` label for output
produced by `pdfium-cli` is at best confusing and at worst an inaccurate
provenance claim in the evidence record.

**Fix:** Use a single consistent renderer identifier that matches what actually
produced the bytes (`pdfium-cli`), or document why `pdfium-render` is the chosen
label despite the CLI being the actual tool.

### IN-04: `find_executable/1` masks finder errors as `nil`

**File:** `lib/rendro/adapters/pdfium.ex:157-167`

**Issue:** `finder.("pdfium-cli") || finder.("pdfium")` treats any non-truthy
finder return as "not found". If an injected test finder (or future logic)
returns `false` or raises, the second lookup runs and the failure mode collapses
to `{:missing_executable, ...}`, hiding the real cause. Minor, since the default
finder only returns a path or `nil`.

**Fix:** Pattern-match explicitly on the first finder result before falling
through to the alias lookup.

---

_Reviewed: 2026-06-10T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
