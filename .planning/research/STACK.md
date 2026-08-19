# Stack Research

**Domain:** v2.13 quality ratchet and adoption-readiness for a pure-Elixir, Phoenix-first PDF library
**Researched:** 2026-08-19
**Confidence:** HIGH for the committed toolchain and current Hex snapshot; MEDIUM for the external-tool documentation lookup (the mandated Context7 provider was unavailable and official docs were used directly).

## Recommendation

Add **no runtime dependencies, no database, no browser automation framework, and no telemetry/analytics service**. The repository already has the three needed toolchains: a deterministic catalog generator/checker, a pinned advisory raster lane, and a Phoenix 1.8 reference application. v2.13 should add only narrowly scoped test/fixture/process code where it closes a verification gap, then commit the resulting evidence. This preserves the core's pure-Elixir boundary and its deterministic/advisory evidence separation.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why recommended |
|---|---:|---|---|
| Elixir + OTP | Elixir 1.19.5 / OTP 28 | Run catalog generation, catalog checks, and integration tests | Already the pinned project runtime; catalog tooling is dev/test-only (`dev/`) and does not widen the library's production compilation surface. |
| `Rendro.Catalog` + `mix rendro.catalog.gen` / `mix rendro.catalog.check` | existing schema v1 | Rebuild and verify all 32 catalog cells and their rubric join | It already checks the exact `png_sha256` and source-PDF hash, renderer pin, disposition uniqueness, projected status, and promotion evidence. It is the right place to enforce the twelve repaired cells rather than inventing a review app. |
| `priv/quality/rubric_scores.json` | schema v1 | Committed, reviewer-owned quality evidence | The existing `catalog_dispositions` row ties each cell to its exact hashes and requires a non-empty `supersedes_evidence_ref` and `resolution_ref` whenever a failed cell is promoted. Keep this as the durable human-review record. |
| `pdfium-cli` | **v0.11.0**, SHA-256 `b1e7f3…e160a` | Advisory PNG rasterisation for visual review | The repository already pins and checksum-verifies this tool in CI. Retaining the exact pin makes before/after review reproducible while honestly limiting raster evidence to render proof, not GUI-viewer, accessibility, print-safety, or universal-design proof. |
| Phoenix reference app | Phoenix `~> 1.8`; Plug `~> 1.18`; Bandit `~> 1.0` | Newcomer-journey validation | `examples/phoenix_example` is a runnable controller integration with route tests. It should be the journey fixture; adding another scaffold duplicates the truth source and risks testing a path users cannot actually follow. |

### Supporting Tools

| Tool | Version | Purpose | When to use |
|---|---:|---|---|
| `mix ci.fast` | existing alias | Required deterministic lane | Run after each catalog or newcomer-path change: formatting, build, compile, tests, docs, Credo, Dialyzer. |
| `mix rendro.catalog.check --pdfium /path/to/pdfium-cli` | existing task | Verify catalog artifacts without writing | Run after generating candidate repair artifacts and again in CI. The supplied binary must match `priv/pdfium_pin.json`. |
| `mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs` | existing | Advisory review-image production/check | Use for the twelve cells' bounded full-size reviewer packet only; do not promote it into the deterministic required lane. |
| `gh` | local `2.95.0` | Pull-based GitHub issue/PR evidence snapshots | Use `gh issue list` and `gh pr list` with explicit JSON fields from `ADOPTION.md`; GitHub CLI documents both commands and their structured JSON output. |
| Hex package API | public `https://hex.pm/api/packages/rendro` | Current download snapshot | Fetch only during an inbound-signal review or milestone planning; record the returned `downloads` object and the UTC timestamp in `ADOPTION.md`. |
| Phoenix generator | current Phoenix 1.8 line (official docs currently show 1.8.9) | One clean-room validation run | Use `mix phx.new` only for a disposable, isolated confirmation that the dependency/install instructions work. The committed example remains the repeatable CI fixture. |

## Required Process Additions

### 1. Catalog quality ratchet

No library is required. Add a **single reviewer packet/test seam** only if the existing `catalog_raster_review_test.exs` cannot emit exactly the twelve named `needs_work` cells at readable size. Keep the inputs and expected identifiers literal.

Current committed scope is exactly these 12 `quality.status: needs_work` cells, all rendered by `pdfium-cli v0.11.0`:

- Invoice / Cedar Mutual / Corporate Classic: light, dark
- Statement / Signal Ledger / Minimal Mono: light, dark
- Receipt / Poppy & Grain / Humanist: light, dark
- Certificate / Meridian Arts Fellowship / Editorial: light, dark
- Payslip / Northline Logistics / Swiss: light, dark
- Ticket / Aurora Live / Brutalist: light, dark

For each repaired row, regenerate through the existing catalog task, perform bounded human review of the exact SHA-bound PNG, and update its scored disposition. A promotion to `passes` must record the old evidence reference and concrete behavioral resolution. Do not alter the rubric threshold, replace the pin, or treat an unscored cell as a pass.

Reproducible commands:

```bash
# deterministic artifact + evidence-join verification
mix rendro.catalog.check --pdfium /absolute/path/to/pdfium-cli
mix ci.fast

# advisory visual lane; still a bounded human review, never a universal claim
mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs
mix ci.advisory
```

### 2. Current adoption evidence

Keep two evidence classes separate:

| Class | Source of truth | What v2.13 should do |
|---|---|---|
| **Committed local evidence** | `ADOPTION.md` ledger, date, thresholds, reviewer decision, public URLs/anonymized reports | Update it with one explicit `HOLD`, `ACCUMULATING`, or `TRIGGER` decision after applying existing counting rules. This is reviewable historical evidence. |
| **External current data** | Hex API response and GitHub issue/PR results at the time of review | Fetch live, record raw values plus date/URL/command result, then commit the assessed snapshot. Never assume prior counts remain current. |

At research time, the live Hex package API reported `downloads.all: 3014` and `downloads.week: 162`; the committed 2026-06-13 snapshot is 877 / 117. That is an external point-in-time observation, not a claim that the demand or contributor gate has triggered: the other threshold families still require a checked issue/PR review under `ADOPTION.md`'s rules.

Use existing commands, with a project-explicit repository target in automation:

```bash
curl -fsSL https://hex.pm/api/packages/rendro | jq '.downloads'

gh issue list --repo szTheory/rendro --state all --label 'adoption:signal' \
  --json number,title,author,createdAt,url,labels --limit 100

gh issue list --repo szTheory/rendro --state all --label 'area:text-shaping' \
  --json number,title,author,createdAt,url,labels --limit 100

gh pr list --repo szTheory/rendro --state merged \
  --search 'merged:>=2026-06-12 -author:szTheory' \
  --json number,title,author,mergedAt,url --limit 100
```

Do not schedule polling, add product analytics, scrape stars/forks, or introduce a metrics database. The project deliberately uses quiet, pull-based demand gates; those alternatives would change the adopted evidence model rather than validate it.

### 3. Phoenix newcomer journey

Use two complementary checks, neither requiring a new dependency:

1. **Committed repeatable path:** run the existing example app’s dependency install and test suite. It validates the adapter, routes, PDF headers, and PDF magic bytes as a Phoenix 1.8 consumer.
2. **One clean-room acceptance path:** in a disposable directory, create a Phoenix 1.8 app, add the released Rendro dependency plus optional Phoenix adapter prerequisites, render an invoice through `Rendro.Adapters.Phoenix`, and assert download and inline-preview headers. Capture the exact versions/commands and a brief outcome in a committed milestone evidence file. Do not commit the generated application.

```bash
# repeatable project fixture
(cd examples/phoenix_example && mix deps.get && mix test)

# interactive manual acceptance after booting the example fixture
(cd examples/phoenix_example && mix phx.server)
curl -fsSI http://localhost:4000/download
curl -fsSI http://localhost:4000/preview
```

The existing `example-phoenix` workflow is intentionally advisory. Preserve that status: it detects newcomer drift without allowing ecosystem-install noise to block Rendro’s deterministic release gate.

## Alternatives Considered

| Recommended | Alternative | Why not for v2.13 |
|---|---|---|
| Existing JSON rubric + SHA-bound PNG/PDF evidence | Visual-regression SaaS or AI aesthetic scorer | Adds cost, non-determinism, and an opaque new authority without replacing the required human quality judgment. |
| Existing pinned PDFium advisory lane | Playwright/Puppeteer screenshot pipeline | Browser screenshots answer a different question and would blur deterministic rendering with GUI-viewer evidence. |
| `gh` + Hex API snapshots committed to `ADOPTION.md` | GitHub/Hex analytics warehouse | Over-engineered for a pull-based, low-volume adoption gate; creates privacy and maintenance scope. |
| Existing Phoenix 1.8 example + clean-room checklist | A second maintained tutorial app | Duplicates integration logic and provides a second route for documentation drift. |

## What NOT to Add

| Avoid | Why | Use instead |
|---|---|---|
| Any core runtime dependency | This milestone improves evidence and adoption readiness, not rendering capability; it would violate the pure-core scope. | Existing dev/test-only tasks and fixtures. |
| Phoenix as a non-optional core dependency | Reverses the optional-adapter boundary. | Keep `{:phoenix, "~> 1.7", optional: true}` in core and Phoenix `~> 1.8` in the example app. |
| Node/browser test framework for catalog review | Adds a second raster/viewer model and maintenance lane. | SHA-pinned `pdfium-cli` advisory raster evidence. |
| Scheduled download collection or private analytics | Contradicts the quiet pull-based adoption policy and produces data that does not meet the demand gate. | Dated, manual Hex/GitHub snapshots tied to a review decision. |
| PDFium upgrade in this milestone | A renderer upgrade invalidates all visual baselines and creates work unrelated to the quality repairs. | Retain v0.11.0; schedule a separate, explicit re-baselining decision if an upgrade becomes necessary. |

## Version Compatibility

| Component | Compatible with | Notes |
|---|---|---|
| Core Elixir `~> 1.19` | OTP 28 | Current local toolchain is Elixir 1.19.5 / OTP 28; keep it for reproducible commands. |
| Core optional Phoenix dependency `~> 1.7` | Phoenix 1.8 example consumer | The example pins Phoenix `~> 1.8`, Plug `~> 1.18`, and Bandit `~> 1.0`; the adapter is already compiled and exercised under that newer consumer surface. |
| Catalog manifest schema 1 | rubric schema 1 + pinned PDFium v0.11.0 | Hash joins mean a repair must update catalog artifact and its reviewer disposition together; do not manually edit only the public projection. |
| GitHub CLI 2.95.0 | GitHub CLI documented `--json` fields | Pin no `gh` dependency in `mix.exs`; CI/manual review should request documented fields and record results. |

## Sources

- [Phoenix `mix phx.new` documentation](https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html) — current Phoenix 1.8 generator syntax and options (MEDIUM; direct official lookup after Context7 was unavailable).
- [Phoenix Up and Running](https://phoenix.hexdocs.pm/up_and_running.html) — installation and standard project startup path (MEDIUM; direct official lookup).
- [GitHub CLI: `gh issue list`](https://cli.github.com/manual/gh_issue_list) and [GitHub CLI: `gh pr list`](https://cli.github.com/manual/gh_pr_list) — structured list commands and JSON fields (HIGH, primary documentation).
- [Hex package API: Rendro](https://hex.pm/api/packages/rendro) — live package/download snapshot, fetched 2026-08-19 (HIGH for this time-stamped response only).
- Local committed evidence: `mix.exs`, `dev/rendro/catalog.ex`, `priv/pdfium_pin.json`, `assets/rendro/catalog.json`, `priv/quality/rubric_scores.json`, `ADOPTION.md`, and `examples/phoenix_example/` (HIGH).

---

*Stack research for: Rendro v2.13 Quality Ratchet & Adoption Readiness*
*Researched: 2026-08-19*
