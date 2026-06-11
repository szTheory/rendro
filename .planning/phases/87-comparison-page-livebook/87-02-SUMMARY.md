---
phase: 87-comparison-page-livebook
plan: 02
subsystem: benchmarks
tags: [comparison, benchmarks, docker, chromic-pdf, pdf-generator, typst]

requires:
  - phase: 87-01
    provides: Static comparison manifest contract, claim registry, and docs-contract lane
provides:
  - Normalized invoice benchmark fixtures for Rendro, ChromicPDF, pdf_generator, and Typst CLI
  - Package-backed benchmark runner with pinned Docker environment for browser/wkhtml rows
  - Committed raw JSON/PDF artifacts and SHA-256-linked comparison manifest
affects: [comparison-guide, docs-contracts, launch-content, package-evidence]

tech-stack:
  added:
    - Docker benchmark image with Debian bookworm Chromium and wkhtmltopdf
    - Mix.install-only chromic_pdf and pdf_generator benchmark scripts
    - Host Typst CLI benchmark path
  patterns:
    - External comparator dependencies stay out of Rendro runtime and are isolated to benchmark scripts
    - Dependency install/build and project compile happen before measured samples
    - Raw artifacts are committed and referenced by SHA-256 from bench/results/comparison.json

key-files:
  created:
    - bench/comparison/Dockerfile
    - bench/comparison/tools/chromic_pdf_render.exs
    - bench/comparison/tools/pdf_generator_render.exs
    - bench/comparison/tools/prewarm_mix_install.exs
    - bench/results/raw/chromic_pdf.json
    - bench/results/raw/chromic_pdf.pdf
    - bench/results/raw/chromic_pdf_warm_pool.json
    - bench/results/raw/chromic_pdf_warm_pool.pdf
    - bench/results/raw/pdf_generator.json
    - bench/results/raw/pdf_generator.pdf
    - bench/results/raw/rendro.json
    - bench/results/raw/rendro.pdf
    - bench/results/raw/typst_cli.json
    - bench/results/raw/typst_cli.pdf
    - .gitattributes
  modified:
    - bench/comparison/README.md
    - bench/comparison/fixtures/invoice_data.json
    - bench/comparison/fixtures/invoice_rendro.exs
    - bench/comparison/fixtures/invoice_chromic_pdf.html.eex
    - bench/comparison/fixtures/invoice_pdf_generator.html.eex
    - bench/comparison/fixtures/invoice_typst.typ
    - bench/comparison/pins.json
    - bench/comparison/run.exs
    - bench/results/comparison.json
    - lib/rendro/comparison.ex
    - test/rendro/comparison_test.exs

key-decisions:
  - "ChromicPDF and pdf_generator benchmark rows call the actual package APIs inside the pinned Docker image; direct Chromium/wkhtmltopdf use is limited to those packages' external runtimes."
  - "The warm-pool row reports timed render latency after an untimed warm-up render, while RSS still comes from the full process tree measured by /usr/bin/time."
  - "Generated PDF outputs are committed beside raw JSON artifacts and marked binary through .gitattributes."

patterns-established:
  - "Benchmark-only package dependencies use Mix.install scripts and Docker prewarm layers, preserving Rendro core dependency purity."
  - "Runner writes output PDFs under bench/results/raw so raw artifact metadata never points at deleted temp files."
  - "Public comparison timing copy names comparator postures rather than implying the warm-pool row is a cold-start measurement."

requirements-completed: [CMP-01, CMP-02]

duration: 58 min
completed: 2026-06-11
---

# Phase 87 Plan 02: Normalized Benchmark Summary

**Reproducible comparison benchmark harness with package-backed comparator rows and committed raw evidence**

## Performance

- **Duration:** 58 min
- **Started:** 2026-06-11T20:24:00Z
- **Completed:** 2026-06-11T21:25:58Z
- **Tasks:** 3
- **Files modified:** 21

## Accomplishments

- Added normalized invoice fixtures and pins for Rendro, ChromicPDF, pdf_generator, and Typst CLI without adding comparator packages to Rendro runtime dependencies.
- Replaced the placeholder runner with a real benchmark runner that builds a pinned Docker image, prewarms external package deps, runs all five comparator rows, records samples, writes raw artifacts, and refreshes the manifest.
- Committed real raw JSON and PDF artifacts for `rendro`, `chromic_pdf`, `chromic_pdf_warm_pool`, `pdf_generator`, and `typst_cli`; `bench/results/comparison.json` references each raw JSON artifact by SHA-256.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add normalized benchmark fixtures and pins** - `6598fe0` (feat)
2. **Task 2: Add benchmark runner and Mix task wrappers** - `b0b04c5` (feat)
3. **Task 3: Run pinned benchmark and commit real raw/summary results** - `780e817`, `ab6bf9c`, `87cb49e` (feat/fix/feat)

**Plan metadata:** pending in this commit

## Files Created/Modified

- `bench/comparison/Dockerfile` - Pinned Debian benchmark image with Chromium, wkhtmltopdf, time, fonts, and prewarmed Mix.install deps.
- `bench/comparison/tools/*.exs` - Actual package API render scripts for ChromicPDF and pdf_generator plus dependency prewarm script.
- `bench/comparison/run.exs` - Normalized benchmark runner, Docker orchestration, sample capture, raw artifact writing, manifest/pins generation.
- `bench/results/comparison.json` - Public comparison manifest with run metadata, comparator metadata, result rows, claims, and raw SHA-256 refs.
- `bench/results/raw/*.{json,pdf}` - Raw per-comparator samples and output PDFs.
- `bench/comparison/fixtures/*` - Shared invoice data and equivalent Rendro/HTML/Typst fixture implementations.
- `bench/comparison/pins.json` - Resolved versions and environment/tool pins.
- `test/rendro/comparison_test.exs` - Drift assertion now follows the manifest's current raw artifact path.

## Decisions Made

- Used Docker for ChromicPDF and pdf_generator rows because the local host lacked a working Chromium app and wkhtmltopdf. This also gives a pinned external-runtime environment for reproducibility.
- Kept Typst CLI on the host path because Homebrew Typst was installed and recorded in pins.
- Added an untimed `mix compile` preflight before Rendro samples so measured `mix run` samples do not include project compilation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Host browser/wkhtml tools were unavailable**
- **Found during:** Task 3
- **Issue:** Host Chromium wrapper was broken and wkhtmltopdf was missing.
- **Fix:** Added `bench/comparison/Dockerfile` and ran browser/wkhtml comparator rows in the pinned image.
- **Files modified:** `bench/comparison/Dockerfile`, `bench/comparison/run.exs`, `bench/comparison/README.md`
- **Verification:** `docker run --rm rendro-comparison-bookworm:local chromium --version` and `wkhtmltopdf --version` passed.
- **Committed in:** `780e817`

**2. [Rule 2 - Correctness] Package-named rows needed package APIs, not direct CLIs**
- **Found during:** Task 3
- **Issue:** Direct Chromium/wkhtml execution would not truthfully benchmark ChromicPDF/pdf_generator package rows.
- **Fix:** Added Mix.install render scripts that call `ChromicPDF.print_to_pdf/2` and `PdfGenerator.generate_binary/2`.
- **Files modified:** `bench/comparison/tools/chromic_pdf_render.exs`, `bench/comparison/tools/pdf_generator_render.exs`, `bench/comparison/run.exs`
- **Verification:** Full `elixir bench/comparison/run.exs --track normalized --all` passed with raw artifacts for both rows.
- **Committed in:** `780e817`

**3. [Rule 2 - Measurement hygiene] Dependency and project build work appeared in sample output**
- **Found during:** Task 3 smoke/final checks
- **Issue:** Initial Docker samples compiled Mix.install deps; first Rendro sample compiled the dev project.
- **Fix:** Docker prewarms the exact dependency sets used by scripts, and the runner runs an untimed `mix compile` before Rendro samples.
- **Files modified:** `bench/comparison/Dockerfile`, `bench/comparison/tools/prewarm_mix_install.exs`, `bench/comparison/run.exs`
- **Verification:** Grep over final raw JSON found no Hex resolution, dependency compile, or project compile output.
- **Committed in:** `780e817`, `ab6bf9c`

**4. [Rule 3 - Repo hygiene] Generated PDFs were treated as text diffs**
- **Found during:** staged diff check
- **Issue:** `git diff --check` flagged whitespace inside PDF payloads.
- **Fix:** Added `.gitattributes` with `*.pdf binary`.
- **Files modified:** `.gitattributes`
- **Verification:** `git diff --cached --check` passed.
- **Committed in:** `87cb49e`

---

**Total deviations:** 4 auto-fixed (2 blocking, 2 correctness/hygiene).
**Impact on plan:** All fixes were necessary to keep benchmark claims reproducible, truthful, and reviewable. No runtime dependency leakage.

## Issues Encountered

- A single-comparator smoke run correctly refused to publish a partial manifest because no existing real artifacts were present for the other comparator rows.
- The built-in Elixir `JSON` encoder writes compact JSON from the standalone runner; contract checks validate the manifest and raw artifact hashes regardless of formatting.

## User Setup Required

None for normal library use. Reproducing the benchmark requires Docker and Typst CLI as documented in `bench/comparison/README.md`.

## Verification

- `docker build -f bench/comparison/Dockerfile -t rendro-comparison-bookworm:local .` - passed.
- `elixir bench/comparison/run.exs --track normalized --all` - passed.
- `mix rendro.comparison.check` - passed.
- `mix test test/rendro/comparison_test.exs` - passed, 15 tests.
- `mix test test/docs_contract/comparison_claims_test.exs` - passed, 5 tests.
- `mix test test/guardrails/required_checks_contract_test.exs` - passed, 14 tests.
- `mix run scripts/verify_docs.exs` - passed, all 17 docs-contract lanes.

## Next Phase Readiness

Wave 2 benchmark evidence is complete and the Livebook tutorial summary already exists from Plan 04. Plan 03 can now generate the comparison guide from `bench/results/comparison.json` with citations bound to the committed claim IDs and raw artifacts.

## Self-Check: PASSED

- Manifest contains no placeholder/TODO/TBD/sample-only text.
- All five comparator ids have all four required metrics.
- Every raw artifact path exists and hashes to the manifest's declared `raw_sha256`.
- Final raw samples exclude dependency download/build and project compile output.
- Comparator packages remain benchmark-only and are absent from `mix.exs` runtime deps.

---
*Phase: 87-comparison-page-livebook*
*Completed: 2026-06-11*
