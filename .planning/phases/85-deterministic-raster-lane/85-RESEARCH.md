# Phase 85: Deterministic Raster Lane - Research

**Researched:** 2026-06-10
**Domain:** pdfium-cli rasterization adapter, golden-PNG snapshot harness, advisory CI lane, evidence vocabulary guard
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RAST-01 | `Rendro.Adapters.Pdfium.render/2` accepts a PDF binary + options (dpi, page range), returns `{:ok, [png_binary]}` — pdfium-cli pinned by version + sha256 | pdfium-cli `render` subcommand confirmed; existing `Rendro.Adapters.Pdfium` module is the correct extension point; version+sha256 pinning via env config pattern is established |
| RAST-02 | Golden-PNG snapshot harness in `mix test` — hash-equality fast path, committed ref hashes, pinned-CI-only bless command; refs generated only in containerized environment | ExUnit tag exclusion pattern (`live_pdf_tools`) is the established mechanism; `@tag raster_bless: true` excluded by default achieves bless-gate; hash comparison in Elixir is trivial with `:crypto.hash` |
| RAST-03 | Raster advisory CI lane (`needs: []`, graph-disconnected) never gates the four required engine lanes; `pdfium-render` viewer_kind vocabulary with docs-contract guard preventing GUI-viewer claim upgrade | Branch protection API confirms the four required checks; advisory lane pattern already exists (`viewer-evidence-live-proof`, `example-phoenix`); `viewer_kind` enum must be extended to include `"pdfium-render"` |

</phase_requirements>

---

## Summary

Phase 85 adds a deterministic raster lane to Rendro: a pdfium-cli-based render adapter, a golden-PNG snapshot test harness, an advisory CI lane, and new evidence vocabulary. The project already has `Rendro.Adapters.Pdfium` as the correct module to extend — it currently exposes `info/2`, `form_fields/2`, and `version/1` using a consistent pattern: injectable `executable_finder` and `command_runner` via `Application.get_env`, `find_executable/0`, `run_command/3`. A new `render/2` function fits this pattern exactly.

The golden-PNG harness must use hash equality (not pixel-diff) because Rendro's PDF output is byte-deterministic and pdfium-cli renders deterministically on a pinned Linux container image. The "bless" gate is simply an ExUnit tag (`raster_snapshot: true` or similar) excluded by default in `test_helper.exs`, matching how `live_pdf_tools` and `live_signing` tags gate the existing live-proof lanes. Refs are SHA-256 hashes of PNG binaries committed to `priv/raster_refs/` — not the PNG files themselves.

The advisory CI lane follows the `example-phoenix` and `viewer-evidence-live-proof` precedents: no `needs:` dependency, not listed in `required_contexts` in `priv/guardrails/required_status_checks.json`, and not listed in the GitHub branch protection required status checks (confirmed via API). A download failure for pdfium-cli in this lane cannot block the four required engine lanes.

The `viewer_kind: "pdfium-render"` label requires adding `"pdfium-render"` to the `enum` in both `priv/schemas/support_matrix.schema.json` and the `@viewer_kinds` compile-time constant in `lib/rendro/viewer_evidence/validator.ex`. The docs-contract guard is a test in `test/docs_contract/raster_claims_test.exs` that asserts GUI-viewer rows (Adobe, Apple Preview) do not carry `viewer_kind: "pdfium-render"`, and that the raster section's evidence files explicitly state the boundary.

**Primary recommendation:** Extend `Rendro.Adapters.Pdfium` with `render/2` following the established adapter pattern; use the ExUnit tag exclusion mechanism for bless-gating; model the advisory CI lane on `viewer-evidence-live-proof`; add `"pdfium-render"` to the `viewer_kind` enum with a docs-contract guard.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PDF-to-PNG rasterization | External CLI (pdfium-cli) | Elixir adapter wrapper | pdfium-cli is a WASM-static binary; Elixir wraps it via `System.cmd` — same tier assignment as qpdf, pdfsig, pdfinfo |
| Adapter API (`render/2`) | Elixir library (`Rendro.Adapters.Pdfium`) | — | Follows the established `Rendro.Adapters.*` pattern: injectable finder/runner, no hex dep |
| Version+SHA256 pinning | Elixir config + CI install step | `priv/pdfium_pin.json` or `config/pdfium.exs` | Pin must be checked at compile-time or runtime; CI step downloads pinned binary |
| Golden-PNG snapshot harness | ExUnit test module | `priv/raster_refs/` committed hashes | Hash comparison is pure Elixir; refs are `:crypto.hash(:sha256, png_binary)` |
| Bless gate (CI-only ref regen) | ExUnit tag exclusion | `MIX_RASTER_BLESS=true` env guard | Matches `live_pdf_tools`/`live_signing` tag pattern already in project |
| Advisory CI lane | GitHub Actions `raster-advisory` job | — | `needs: []`, not in `required_contexts`, `continue-on-error: true` recommended |
| `pdfium-render` viewer_kind enum | `priv/schemas/support_matrix.schema.json` + `validator.ex` | — | Both must be updated in sync; JSV schema validation gates `mix test` |
| Docs-contract guard | `test/docs_contract/raster_claims_test.exs` | — | Asserts GUI-viewer rows do not carry pdfium-render kind; asserts boundary language in evidence files |
| Guardrails registration | `priv/guardrails/required_status_checks.json` | — | Advisory lane registered under `advisory_contexts` per existing pattern |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| pdfium-cli | v0.11.0 (pinned) | PDF→PNG rasterization | Already used in project (viewer evidence); WASM static binary, no native dep install |
| ExUnit | OTP/Elixir built-in | Golden snapshot test harness | Already the project test framework |
| `:crypto` (OTP) | OTP built-in | SHA-256 hash of PNG binaries | No new dep; `Base.encode16(:crypto.hash(:sha256, binary), case: :lower)` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `req` (already in mix.exs) | `~> 0.5` | Optional: could fetch pdfium-cli binary in CI; already dep | Only if wrapping the download in a Mix task; curl is simpler for CI |

### No New Hex Dependencies
This phase adds zero new hex dependencies. pdfium-cli is a downloaded binary. All hashing uses OTP `:crypto`. [VERIFIED: mix.exs + project conventions]

**Installation (CI step — no mix install):**
```bash
# Pin by version in CI YAML:
curl -fsSL -o pdfium-cli \
  "https://github.com/klippa-app/pdfium-cli/releases/download/v0.11.0/pdfium-webassembly-linux-amd64"
echo "b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a  pdfium-cli" | sha256sum --check
chmod +x pdfium-cli
sudo mv pdfium-cli /usr/local/bin/pdfium-cli
```

**Version verification:**
- pdfium-cli v0.11.0 webassembly-linux-amd64 SHA256: `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a` [VERIFIED: downloaded and sha256sum computed 2026-06-10]
- Current CI uses v0.10.3 (from ci.yml line 66). Phase 85 should decide: keep v0.10.3 (already deployed, already working) or upgrade to v0.11.0. **Recommendation: use v0.10.3 for the raster advisory lane** (same version as the existing viewer-evidence lane) to avoid introducing a separate version divergence. Upgrade to v0.11.0 in a separate task if desired.
- v0.10.3 SHA256 for webassembly-linux-amd64: [ASSUMED] — not computed in this session. Planner should confirm via `curl ... | sha256sum` before committing the pin file.

---

## Package Legitimacy Audit

This phase installs **no new Hex packages**. pdfium-cli is a pre-built binary downloaded from a pinned GitHub release URL with SHA256 verification. No slopcheck needed for binary downloads.

| Asset | Source | Age | Auth | Disposition |
|-------|--------|-----|------|-------------|
| pdfium-cli v0.11.0 | github.com/klippa-app/pdfium-cli | Active project, maintained by Klippa | GitHub release, SHA256-pinned | Approved (already used in project) |

**Packages removed due to slopcheck:** none
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
PDF binary (in-memory)
        │
        ▼
Rendro.Adapters.Pdfium.render/2
        │  writes to tmp file
        ▼
pdfium-cli render <input.pdf> <output-%d.png> --dpi N --file-type png [--pages range]
        │  reads output PNG files
        ▼
[png_binary_page_1, png_binary_page_2, ...]  ← {:ok, [binary]}
        │
        ├──► golden snapshot harness (mix test)
        │       reads priv/raster_refs/<fixture>/<page>.sha256
        │       :crypto.hash(:sha256, png) == stored_hash  ← pass/fail
        │       [raster_snapshot tag excluded by default]
        │
        └──► advisory CI lane (raster-advisory job)
                needs: []  (graph-disconnected)
                NOT in required_status_checks
                continue-on-error: true
                downloads pdfium-cli v0.11.0 + sha256 verify
                runs: mix test --include raster_snapshot
```

### Recommended Project Structure
```
lib/rendro/adapters/
└── pdfium.ex                  # extended with render/2

priv/
├── pdfium_pin.json            # {"version": "v0.11.0", "binary": "pdfium-webassembly-linux-amd64", "sha256": "<hash>"}
└── raster_refs/               # committed SHA-256 hashes of reference PNGs
    ├── invoice/
    │   ├── page_1.sha256      # hex string, e.g. "a3f9..."
    │   └── page_2.sha256
    └── certificate/
        └── page_1.sha256

test/rendro/adapters/
└── pdfium_raster_snapshot_test.exs   # golden harness + bless task

test/docs_contract/
└── raster_claims_test.exs     # docs-contract guard

.github/workflows/
└── ci.yml                     # new raster-advisory job
```

### Pattern 1: `render/2` in `Rendro.Adapters.Pdfium`
**What:** Accept a PDF binary (not a file path) and options; write to tmp file; invoke `pdfium-cli render`; read back PNG files.
**When to use:** Called by golden snapshot harness and by Phase 86 gallery generation.
**Example:**
```elixir
# Source: modeled on existing Rendro.Adapters.Pdfium.form_fields/2 pattern
@spec render(binary(), keyword()) :: {:ok, [binary()]} | {:error, term()}
def render(pdf_binary, opts \\ []) do
  with {:ok, executable} <- find_executable(),
       {:ok, tmp_dir} <- make_tmp_dir() do
    try do
      render_in_tmp(executable, tmp_dir, pdf_binary, opts)
    after
      if Keyword.get(opts, :cleanup, true), do: File.rm_rf(tmp_dir)
    end
  end
end

defp render_in_tmp(executable, tmp_dir, pdf_binary, opts) do
  input_path = Path.join(tmp_dir, "input.pdf")
  output_pattern = Path.join(tmp_dir, "page_%d.png")
  dpi = Keyword.get(opts, :dpi, 150)
  pages = Keyword.get(opts, :pages, nil)

  with :ok <- File.write(input_path, pdf_binary),
       {:ok, _output} <- run_render(executable, input_path, output_pattern, dpi, pages) do
    collect_pngs(tmp_dir)
  end
end

defp run_render(executable, input_path, output_pattern, dpi, nil) do
  run_command(executable, render_args(input_path, output_pattern, dpi))
end

defp run_render(executable, input_path, output_pattern, dpi, pages) do
  run_command(executable, render_args(input_path, output_pattern, dpi) ++ ["--pages", pages])
end

defp render_args(input_path, output_pattern, dpi) do
  ["render", input_path, output_pattern, "--dpi", Integer.to_string(dpi), "--file-type", "png"]
end

defp collect_pngs(tmp_dir) do
  pngs =
    tmp_dir
    |> Path.join("page_*.png")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&File.read!/1)
  {:ok, pngs}
end
```

### Pattern 2: Golden-PNG snapshot harness
**What:** Hash-equality fast path comparing rendered PNGs against committed `.sha256` ref files. Bless gate is an ExUnit tag excluded by default.
**When to use:** `mix test` always runs hash comparison (fast, no pdfium-cli needed when hash files exist). Blessing only runs in the pinned CI container via `--include raster_snapshot`.
**Example:**
```elixir
# Source: modeled on live_pdf_tools / live_signing tag pattern in test_helper.exs
defmodule Rendro.Adapters.PdfiumRasterSnapshotTest do
  use ExUnit.Case, async: false

  @tag raster_snapshot: true
  test "invoice recipe renders match golden hashes" do
    executable = Rendro.TestSupport.PdfiumCli.find_executable()

    if is_nil(executable) do
      IO.puts("Skipping raster snapshot: pdfium-cli not installed")
    else
      Application.put_env(:rendro, :pdfium_cli_executable_finder, fn _ -> executable end)
      on_exit(fn -> Application.delete_env(:rendro, :pdfium_cli_executable_finder) end)

      {:ok, pdf} = Rendro.render(invoice_document(), deterministic: true)
      {:ok, pngs} = Rendro.Adapters.Pdfium.render(pdf, dpi: 150)

      if System.get_env("MIX_RASTER_BLESS") == "true" do
        bless_refs("invoice", pngs)
      else
        assert_golden_hashes("invoice", pngs)
      end
    end
  end

  defp assert_golden_hashes(fixture_name, pngs) do
    Enum.each(Enum.with_index(pngs, 1), fn {png, page_num} ->
      ref_path = "priv/raster_refs/#{fixture_name}/page_#{page_num}.sha256"
      expected_hash = File.read!(ref_path) |> String.trim()
      actual_hash = Base.encode16(:crypto.hash(:sha256, png), case: :lower)
      assert actual_hash == expected_hash,
        "Page #{page_num} hash mismatch for #{fixture_name}. Run in CI with MIX_RASTER_BLESS=true to update refs."
    end)
  end

  defp bless_refs(fixture_name, pngs) do
    Enum.each(Enum.with_index(pngs, 1), fn {png, page_num} ->
      ref_path = "priv/raster_refs/#{fixture_name}/page_#{page_num}.sha256"
      File.mkdir_p!(Path.dirname(ref_path))
      hash = Base.encode16(:crypto.hash(:sha256, png), case: :lower)
      File.write!(ref_path, hash <> "\n")
    end)
  end
end
```

**test_helper.exs addition:**
```elixir
ExUnit.configure(exclude: [live_pdf_tools: true, live_signing: true, raster_snapshot: true])
```

### Pattern 3: Advisory CI lane (graph-disconnected)
**What:** A GitHub Actions job with `needs: []` that is not in `required_contexts` in the guardrails file and not in GitHub branch protection required checks.
**When to use:** Any lane that uses external binaries subject to download failure; must never block engine merges.
**Example:**
```yaml
# Source: modeled on example-phoenix and viewer-evidence-live-proof in ci.yml
raster-advisory:
  runs-on: ubuntu-latest
  continue-on-error: true
  # no `needs:` -> graph-disconnected; not a required check

  steps:
    - name: Checkout
      uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

    - name: Setup Beam
      uses: erlef/setup-beam@v1
      with:
        otp-version: '28'
        elixir-version: '1.19.5'

    - name: Install pdfium-cli (pinned)
      run: |
        EXPECTED_SHA256="b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a"
        curl -fsSL -o pdfium-cli \
          "https://github.com/klippa-app/pdfium-cli/releases/download/v0.11.0/pdfium-webassembly-linux-amd64"
        echo "${EXPECTED_SHA256}  pdfium-cli" | sha256sum --check
        chmod +x pdfium-cli
        sudo mv pdfium-cli /usr/local/bin/pdfium-cli

    - name: Install Elixir Dependencies
      run: mix deps.get

    - name: Run Raster Snapshot Tests
      run: mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs
```

**Note on `continue-on-error`:** The existing `example-phoenix` lane has a comment "no `continue-on-error`" (D-10). This was a specific decision for that lane. For the raster lane, `continue-on-error: true` is explicitly desired so a transient download failure does not create a red CI status that confuses contributors. The planner should choose deliberately: `continue-on-error: true` means the job "succeeds" from GitHub's perspective even on failure; alternatively, keeping it absent but ensuring the job is not in required checks achieves the same merge-blocking guarantee but leaves a visible failure signal. Both approaches are valid; the recommended approach is `continue-on-error: true` to fully isolate from required-check confusion.

### Pattern 4: `viewer_kind: "pdfium-render"` vocabulary
**What:** Add `"pdfium-render"` to the `viewer_kind` enum in two places: `priv/schemas/support_matrix.schema.json` and `@viewer_kinds` in `lib/rendro/viewer_evidence/validator.ex`.
**When to use:** Any evidence record produced by rasterizing with pdfium-cli in an automated context where the claim is about what the render engine produces, not what a human saw in a GUI viewer.
**Distinction:**
- `"pdfium-cli"` = existing viewer_kind meaning "pdfium-cli was used for structural/form/metadata proof (not rasterization as a display proxy)"
- `"pdfium-render"` = new viewer_kind meaning "pdfium-cli rendered the page to PNG; this is engine-render evidence, not GUI-viewer observation"

**support_matrix.json raster section shape:**
```json
"raster": {
  "renderer": "pdfium-render",
  "capabilities": {
    "pdf_to_png": "supported",
    "dpi_configurable": "supported",
    "page_range": "supported",
    "byte_deterministic_on_pinned_container": "supported"
  },
  "boundaries": {
    "gui_viewer_equivalence": "unsupported",
    "adobe_acrobat_visual_fidelity_claim": "unsupported",
    "apple_preview_visual_fidelity_claim": "unsupported"
  },
  "evidence": {
    "renderer_version": "v0.11.0",
    "viewer_kind": "pdfium-render",
    "platform": "Linux (x86_64) — CI container only",
    "dpi": 150,
    "notes": "pdfium-render evidence records what the pdfium engine renders. It does not claim GUI-viewer visual fidelity for Adobe Acrobat, Apple Preview, or Chrome PDF viewer."
  }
}
```

### Anti-Patterns to Avoid
- **Committing PNG files as golden refs:** Do NOT commit the PNG binaries. Commit only SHA-256 hashes in `.sha256` text files. PNGs are binary blobs that bloat git history and diff badly.
- **Platform-local bless:** Never run `MIX_RASTER_BLESS=true` on a developer laptop. pdfium-cli rendering is deterministic per platform/binary version but NOT cross-platform. Only the pinned CI container produces authoritative hashes.
- **Promoting raster evidence to GUI-viewer claims:** A docs-contract test must assert that `viewer_kind: "pdfium-render"` cells do not appear under `forms.viewers`, `signing.viewers`, or any surface that requires human GUI verification.
- **Running `pdfium-cli` with the path-input pattern for binaries in memory:** pdfium-cli requires a file path argument; always write the PDF binary to a tmp file first (see `Rendro.Adapters.Qpdf` for the established `make_tmp_dir` / `write_private_file` pattern).
- **Using `%d` in output path without the page range caveat:** When rendering all pages, pdfium-cli substitutes `%d` with the page number (1-indexed). For single-page PDFs this produces `page_1.png`, not `page_0.png`. Sort output globs numerically.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PDF rasterization | Custom PDF renderer | pdfium-cli | pdfium is the industry-standard PDF rendering library; hand-rolling PNG extraction is months of work |
| PNG binary hashing | Custom hash scheme | OTP `:crypto.hash(:sha256, binary)` | Already available; no dep; standard |
| Snapshot test orchestration | Custom snapshot framework | ExUnit tags + `.sha256` files | The tag-exclusion pattern is already established in the project; no new framework needed |
| SHA256 verification in CI | Custom download script | `sha256sum --check` (GNU coreutils) | Available on every ubuntu-latest runner; one line |
| CI lane isolation | Complex job dependency graphs | `needs: []` + not in required_contexts | Already the established project pattern for advisory lanes |

**Key insight:** The entire golden-snapshot harness can be built with zero new Hex dependencies, zero new CI infrastructure beyond a new job, and zero new abstractions beyond extending the existing `Rendro.Adapters.Pdfium` module.

---

## Common Pitfalls

### Pitfall 1: `viewer_kind: "pdfium-render"` not in schema enum
**What goes wrong:** Adding `"pdfium-render"` to `support_matrix.json` without updating the JSON schema fails `mix test` via the JSV validation in `Validator.validate_matrix_structure/1`.
**Why it happens:** The `viewer_kind` enum in `priv/schemas/support_matrix.schema.json` only allows `["manual", "pdfium-cli", "pdfjs-dist"]` (verified in source). The `@viewer_kinds` constant in `validator.ex` duplicates this constraint at runtime.
**How to avoid:** Update BOTH `priv/schemas/support_matrix.schema.json` AND `@viewer_kinds ~w(...)` in `validator.ex` in the same commit.
**Warning signs:** `mix test` fails with a JSV validation error on `support_matrix.json` after adding the raster section.

### Pitfall 2: pdfium-cli output file naming
**What goes wrong:** Expecting `page_0.png` but pdfium-cli produces `page_1.png`. Or expecting `page_1.png` but getting `page_%d.png` literally if the pattern isn't passed correctly.
**Why it happens:** pdfium-cli uses `strings.Replace(args[1], "%d", page, -1)` where page is a string like "1", "2". Without `%d` in the pattern, all pages overwrite the same file.
**How to avoid:** Always use `%d` in the output pattern. Collect output with `Path.wildcard(Path.join(tmp_dir, "page_*.png")) |> Enum.sort()`. Sort lexically is fine for up to 9 pages; for more use a numeric sort.
**Warning signs:** `collect_pngs/1` returns a list with 1 element for a multi-page PDF.

### Pitfall 3: Bless running on developer laptops
**What goes wrong:** A developer runs `MIX_RASTER_BLESS=true mix test` locally, generates platform-specific hashes, commits them, and CI starts failing because hashes don't match the containerized render.
**Why it happens:** pdfium-cli rendering is not byte-identical across platform variants (webassembly vs native, Linux vs macOS). Even the same binary version can produce different PNG bytes on different OS configurations due to font hinting.
**How to avoid:** Document clearly in the test file that bless must only run in the pinned CI container. Consider adding a guard: `if System.get_env("GITHUB_ACTIONS") != "true", do: raise "bless must only run in CI"` when `MIX_RASTER_BLESS=true`.
**Warning signs:** Committed `.sha256` files that differ from what CI computes; CI failures after a bless run.

### Pitfall 4: Raster section misclassified as a `viewer_map`
**What goes wrong:** Adding the raster section under `priv/support_matrix.json` in a structure that the `Matrix.enumerate_viewer_cells/1` function iterates over, triggering promotion-complete validation failures.
**Why it happens:** `Matrix.enumerate_viewer_cells/1` only knows about the eight hard-coded `@viewer_maps` paths. A new top-level section `"raster"` with a different shape is ignored — but if accidentally placed under an existing viewer map path (e.g., `forms.viewers.pdfium_render`), it gets validated as a viewer row.
**How to avoid:** Add the raster evidence as a new top-level key `"raster"` in `support_matrix.json`, NOT under any existing viewer map. The schema's `"additionalProperties": true` at the root level allows this.
**Warning signs:** Unexpected promotion-complete violations in `test/docs_contract/viewer_evidence_claims_test.exs`.

### Pitfall 5: Orphan evidence file detection triggered
**What goes wrong:** Creating a `priv/viewer_evidence/raster/pdfium_render.md` file triggers the orphan evidence file check in `Validator.list_orphan_evidence/1` because the raster surface is not in any viewer map.
**Why it happens:** The validator checks that every `.md` file under `priv/viewer_evidence/` is referenced by the matrix. A `raster/` surface subdirectory would be an orphan.
**How to avoid:** Option A: Do NOT put raster evidence under `priv/viewer_evidence/` — use `priv/raster_refs/` as the storage location for hash refs instead, and document raster evidence in the `"raster"` section of `support_matrix.json` without an `.md` evidence file. Option B: Add a `raster.viewer` row to `@viewer_maps` in `Matrix.ex` and the evidence path to the matrix — but this requires extending the viewer-evidence infrastructure significantly. **Option A is strongly recommended** to keep the two systems separate.
**Warning signs:** `Validator.list_orphan_evidence/1` returns paths under `priv/viewer_evidence/raster/`.

### Pitfall 6: Advisory lane not registered in guardrails JSON
**What goes wrong:** CI has a new `raster-advisory` job but `priv/guardrails/required_status_checks.json` is not updated, and the docs-contract test that validates this file (`test/docs_contract/viewer_evidence_claims_test.exs`) or a future guardrails contract test catches the discrepancy.
**Why it happens:** The guardrails file is the source of truth for the lane registry. Two existing advisory lanes are registered there under `advisory_contexts`.
**How to avoid:** Add `raster-advisory` under `advisory_contexts` in `priv/guardrails/required_status_checks.json` when adding the CI job.
**Warning signs:** Guardrails file is out of sync with actual CI jobs.

---

## Code Examples

### SHA-256 hash computation (established Elixir pattern)
```elixir
# Source: OTP :crypto module, standard Elixir pattern
def png_sha256(png_binary) when is_binary(png_binary) do
  Base.encode16(:crypto.hash(:sha256, png_binary), case: :lower)
end
```

### pdfium-cli render invocation
```bash
# Source: github.com/klippa-app/pdfium-cli cmd/render.go — verified flags
pdfium-cli render input.pdf output/page_%d.png --dpi 150 --file-type png
# With page range:
pdfium-cli render input.pdf output/page_%d.png --dpi 150 --file-type png --pages "1-3"
# Single page (page 1 only):
pdfium-cli render input.pdf output/page_%d.png --dpi 150 --file-type png --pages "1"
```

### ExUnit tag exclusion (established project pattern)
```elixir
# Source: test/test_helper.exs — existing pattern for live_pdf_tools/live_signing
ExUnit.configure(exclude: [live_pdf_tools: true, live_signing: true, raster_snapshot: true])
```

### Bless guard (CI-only protection)
```elixir
# Source: pattern derived from GITHUB_ACTIONS env var (GitHub Actions docs)
defp assert_or_bless(fixture_name, pngs) do
  if System.get_env("MIX_RASTER_BLESS") == "true" do
    if System.get_env("GITHUB_ACTIONS") != "true" do
      raise """
      MIX_RASTER_BLESS=true must only run in the pinned CI container.
      Raster hashes are not deterministic across platforms.
      """
    end
    bless_refs(fixture_name, pngs)
  else
    assert_golden_hashes(fixture_name, pngs)
  end
end
```

### support_matrix.schema.json viewer_kind enum update
```json
// Source: priv/schemas/support_matrix.schema.json — current enum + new value
"viewer_kind": {
  "type": "string",
  "enum": ["manual", "pdfium-cli", "pdfjs-dist", "pdfium-render"]
}
```

### validator.ex @viewer_kinds update
```elixir
# Source: lib/rendro/viewer_evidence/validator.ex — sync with schema
@viewer_kinds ~w(manual pdfium-cli pdfjs-dist pdfium-render)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pixel-diff snapshot testing (e.g., Mneme, Snapshy) | Hash-equality fast path on deterministic binary output | N/A (choosing approach) | Hash equality is correct for Rendro because the PDF renderer is byte-deterministic; pixel-diff libraries add unnecessary complexity and are designed for non-deterministic rendering (browser screenshots, etc.) |
| Platform-neutral snapshot refs | Platform-pinned CI-only refs | N/A (project constraint) | pdfium-cli rendering is NOT byte-identical across platforms; CI-only blessing is mandatory |
| Separate snapshot testing framework | ExUnit tags + `.sha256` text files | N/A | Zero new deps; fits the established project pattern |

**Deprecated/outdated:**
- `pdftoppm` (Poppler): Used in `mix rendro.visual_uat` for legacy one-off rasterization, but pdfium-cli is the project-standard binary for consistent rendering across the viewer-evidence system. `pdftoppm` is not the correct tool for Phase 85.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | v0.10.3 SHA256 for pdfium-webassembly-linux-amd64 must be computed by the executor (not provided in this research) | Standard Stack, CI lane pattern | Planner must include a step to compute and commit this hash; wrong hash breaks the sha256sum --check gate |
| A2 | `--pages` flag syntax is `"1-3"` or `"1"` (string format) | Code Examples, render flags | Wrong syntax causes pdfium-cli to fail or render wrong pages; executor should run `pdfium-cli render --help` to confirm |
| A3 | pdfium-cli `%d` substitution is 1-indexed (page 1 = `page_1.png`) | Pitfall 2 | Off-by-one in PNG collection; easy to verify by inspecting output |
| A4 | The raster advisory lane should use `continue-on-error: true` | Architecture Patterns, Pattern 3 | If omitted, a download failure creates a red CI job visible in PRs (confusing but not blocking); acceptable either way |
| A5 | Bless refs should only cover recipes that are deterministic at the PDF level (i.e., use `deterministic: true` render option) | Pattern 2 | Non-deterministic PDFs (with timestamps) would produce different PNG hashes every run |

**If this table is empty:** Not empty — see above.

---

## Open Questions

1. **Which pdfium-cli version to pin for the raster lane?**
   - What we know: CI currently uses v0.10.3 for `viewer-evidence-live-proof`; v0.11.0 is latest (released 2026-05-11)
   - What's unclear: Should Phase 85 use v0.10.3 (matches existing lane, no upgrade churn) or upgrade to v0.11.0 (latest)? The render command has not changed between these versions.
   - Recommendation: Use v0.11.0 for the new raster advisory lane (it's the current release, and using a different version from the existing lane is fine since they are separate jobs). This gives Phase 85 its own pinned version without modifying the existing lane.

2. **How many fixtures to bless initially?**
   - What we know: Phase 86 depends on this lane for gallery generation; at minimum Invoice + Certificate are needed
   - What's unclear: Whether to bless all five recipes (Invoice, BrandedInvoice, Statement, Receipt, Certificate) or just a minimal set
   - Recommendation: Bless all five recipes that produce deterministic output; this makes Phase 86 easier and covers PATH-01 verification (the path primitive golden-PNG harness)

3. **DPI for golden refs?**
   - What we know: `mix rendro.visual_uat` uses 200 DPI; pdfium-cli default is 200 DPI
   - What's unclear: Whether the gallery (Phase 86) needs higher or lower DPI
   - Recommendation: 150 DPI for snapshot refs (smaller files, faster CI); Phase 86 can use higher DPI for gallery display. The DPI is part of the evidence record (`dpi: 150`) so changing it requires a bless-rebuild.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| pdfium-cli binary | `Rendro.Adapters.Pdfium.render/2`, raster snapshot tests | CI only (downloads) | v0.11.0 (plan) | Tests excluded by `raster_snapshot` tag when not installed |
| `:crypto` (OTP) | SHA-256 hashing | ✓ (built-in) | OTP 28 | — |
| `sha256sum` (GNU coreutils) | CI pin verification | ✓ ubuntu-latest | — | `shasum -a 256` on macOS |
| `File`, `Path`, `System.cmd` (Elixir stdlib) | tmp file I/O for render | ✓ | Elixir 1.19 | — |

**Missing dependencies with no fallback:** none (raster snapshot tests are tag-excluded when pdfium-cli is absent — graceful degradation already established by `Rendro.TestSupport.PdfiumCli.find_executable()` pattern)

**Missing dependencies with fallback:** pdfium-cli → tests skip via `nil` guard in test body (same pattern as `forms_viewer_evidence_live_test.exs`)

---

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true` in config.json).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in, Elixir 1.19) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/adapters/pdfium_test.exs test/docs_contract/raster_claims_test.exs` |
| Full suite command | `mix test` |
| Raster snapshot command | `mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RAST-01a | `render/2` returns `{:ok, [binary]}` when pdfium-cli absent returns `{:error, {:missing_executable, ...}}` | unit | `mix test test/rendro/adapters/pdfium_test.exs` | ✅ (extend existing) |
| RAST-01b | `render/2` with mock runner returns `{:ok, [png_binary]}` list | unit | `mix test test/rendro/adapters/pdfium_test.exs` | ❌ Wave 0 |
| RAST-01c | `pdfium_pin.json` exists and validates (version + sha256 keys present) | unit (docs contract) | `mix test test/docs_contract/raster_claims_test.exs` | ❌ Wave 0 |
| RAST-02a | Hash-equality fast path: assert golden hash matches (no pdfium-cli needed) | unit | `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs` | ❌ Wave 0 |
| RAST-02b | Bless guard: `MIX_RASTER_BLESS=true` outside GITHUB_ACTIONS raises | unit | `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs` | ❌ Wave 0 |
| RAST-02c | Raster snapshot tests run in full `mix test` suite (not excluded by default without `--exclude`) | integration | `mix test` | ❌ Wave 0 (raster_snapshot tag excluded; live render only with `--include`) |
| RAST-03a | Advisory lane is NOT in `required_contexts` in guardrails JSON | docs contract | `mix test test/docs_contract/raster_claims_test.exs` | ❌ Wave 0 |
| RAST-03b | `viewer_kind: "pdfium-render"` is valid per schema | unit | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ✅ (extend after schema update) |
| RAST-03c | GUI-viewer rows do not carry `viewer_kind: "pdfium-render"` | docs contract | `mix test test/docs_contract/raster_claims_test.exs` | ❌ Wave 0 |
| RAST-03d | `support_matrix.json` has `"raster"` section with correct boundary declarations | docs contract | `mix test test/docs_contract/raster_claims_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/adapters/pdfium_test.exs test/docs_contract/raster_claims_test.exs`
- **Per wave merge:** `mix ci` (full suite, no raster snapshot)
- **Phase gate:** Full suite green (`mix ci`) + raster snapshot lane green in CI before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/rendro/adapters/pdfium_raster_snapshot_test.exs` — covers RAST-01b, RAST-02a, RAST-02b
- [ ] `test/docs_contract/raster_claims_test.exs` — covers RAST-01c, RAST-03a, RAST-03c, RAST-03d
- [ ] `priv/raster_refs/` directory (with `.gitkeep` initially) — populated by bless run in CI
- [ ] `priv/pdfium_pin.json` — pinned version + sha256 for the raster lane binary

---

## Security Domain

`security_enforcement` is not explicitly set to `false` in config.json; treating as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes (PDF binary, dpi, pages options) | Validate `dpi` is positive integer; validate `pages` matches expected format if provided; write PDF to mode 0o600 tmp file |
| V6 Cryptography | yes (SHA-256 for hash comparison) | OTP `:crypto` — never hand-roll |

### Known Threat Patterns for {stack}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious PDF binary triggering pdfium exploit | Tampering | pdfium-cli runs in the CI container with no network access during render; `try/rescue` wraps `System.cmd` |
| SHA256 hash collision substitution in committed refs | Tampering | SHA-256 collision resistance; ref files are committed to git; CI verifies on bless |
| pdfium-cli binary substitution (supply chain) | Tampering | SHA256 pin in CI install step + `sha256sum --check`; use WASM variant (sandboxed) not native |
| Tmp file containing PDF binary world-readable | Info Disclosure | `File.chmod(path, 0o600)` after write (see `Rendro.Adapters.Qpdf.write_private_file/2` pattern) |
| Bless run producing platform-specific hashes as "golden" | Spoofing | GITHUB_ACTIONS guard in bless path; documented in test file |

---

## Sources

### Primary (HIGH confidence)
- `lib/rendro/adapters/pdfium.ex` — existing `Rendro.Adapters.Pdfium` module: `find_executable/0`, `run_command/3`, injectable config pattern [VERIFIED: codebase]
- `lib/rendro/adapters/qpdf.ex` — tmp file write pattern (`make_tmp_dir`, `write_private_file`, chmod 0o600) [VERIFIED: codebase]
- `.github/workflows/ci.yml` — pdfium-cli v0.10.3 install step, existing advisory lane structure (`example-phoenix`, `viewer-evidence-live-proof`), `needs: []` pattern [VERIFIED: codebase]
- `priv/guardrails/required_status_checks.json` — `required_contexts` list, `advisory_contexts` structure [VERIFIED: codebase]
- `gh api repos/szTheory/rendro/branches/main/protection` — branch protection required checks: `["test", "signing-live-proof", "release-proof", "long-lived-live-proof"]` [VERIFIED: GitHub API]
- `priv/schemas/support_matrix.schema.json` — `viewer_kind` enum: `["manual", "pdfium-cli", "pdfjs-dist"]` — `"pdfium-render"` NOT currently present [VERIFIED: codebase]
- `lib/rendro/viewer_evidence/validator.ex` — `@viewer_kinds ~w(manual pdfium-cli pdfjs-dist)` [VERIFIED: codebase]
- `test/test_helper.exs` — `ExUnit.configure(exclude: [live_pdf_tools: true, live_signing: true])` pattern [VERIFIED: codebase]
- `github.com/klippa-app/pdfium-cli cmd/render.go` — render flags: `--dpi`, `--file-type`, `--pages`, `%d` output pattern [VERIFIED: WebFetch from official source]
- SHA256 of pdfium-webassembly-linux-amd64 v0.11.0: `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a` [VERIFIED: downloaded and sha256sum computed]

### Secondary (MEDIUM confidence)
- pdfium-cli v0.11.0 release notes (GitHub API) — confirms v0.11.0 is current, no render command changes [CITED: gh api repos/klippa-app/pdfium-cli/releases/tags/v0.11.0]
- GitHub branch protection docs — advisory lanes not in required checks cannot block merges [CITED: github.com/orgs/community/discussions/13690]

### Tertiary (LOW confidence)
- pdfium-cli `--pages` flag string format (`"1-3"`, `"1"`) [ASSUMED: derived from render.go source; confirm with `pdfium-cli render --help`]

---

## Metadata

**Confidence breakdown:**
- Adapter extension pattern (RAST-01): HIGH — existing module is the template; pattern is identical to existing functions
- Advisory lane structure (RAST-03 CI): HIGH — branch protection API confirmed; guardrails JSON pattern confirmed
- viewer_kind schema gap: HIGH — both files verified in codebase; "pdfium-render" definitely absent
- pdfium-cli render flags: MEDIUM — render.go source confirmed --dpi, --file-type, --pages; %d output naming confirmed
- Bless gate mechanism: HIGH — ExUnit tag exclusion pattern directly verified in test_helper.exs
- v0.11.0 SHA256: HIGH — directly computed by download

**Research date:** 2026-06-10
**Valid until:** 2026-07-10 (30 days for stable tools; pdfium-cli releases ~monthly)
