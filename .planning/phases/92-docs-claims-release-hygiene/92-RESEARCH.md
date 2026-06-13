# Phase 92: Docs, Claims, Release Hygiene - Research

**Researched:** 2026-06-13  
**Domain:** Elixir HexDocs/docs-contract/release workflow hygiene  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Documentation Surface

- Prefer targeted updates to existing public docs over adding many new guides.
- `guides/page_primitive.md` is the right home for page context, section-local numbering, duplex running content, and explicit TOC/outline/anchor/chart boundaries.
- `guides/recipes.md` may reference these primitives only where they improve report/statement ergonomics; avoid duplicating the full primitive guide.
- `guides/api_stability.md` remains the canonical support-boundary guide for support matrix and viewer claims.
- `README.md` should stay concise and point to guides rather than becoming a reference manual.

### Support Matrix And Claims

- Add or update support matrix rows only for feature claims that are public and backed by tests.
- Do not add a PDF.js support row or promote any existing `pdfjs` viewer deferral row.
- If a top-level PDF.js advisory section is added, it must avoid support vocabulary and stay distinct from viewer support rows; otherwise keep Phase 91 observations outside the support matrix and rely on docs-contract tests.
- Named deferrals must include TOC/outlines/anchors/cross-references, charts, global text shaping, PDF.js GUI support, and full release automation.

### Release / HexDocs Hygiene

- Current scan found `ADOPTION.md` linked from README and scripts, but `mix.exs` package files do not include `ADOPTION.md`; `mix ci` emits ExDoc warnings for missing `ADOPTION.md`. Phase 92 should fix this if feasible.
- `hexdocs.yml` already sets `permissions: contents: read` and SHA-pins checkout/setup-beam. `ci.yml` and `release.yml` currently do not set top-level permissions; harden to least-privilege if compatible.
- Avoid introducing release-please or full release automation; the milestone explicitly defers it.
- Existing exact-tag release preflight and required-check guardrails should stay intact.

### Changelog / Public Versioning

- If Phase 92 changes public docs/support matrix/release workflow posture, add a concise `[Unreleased]` changelog entry.
- Do not imply these v2.7 docs are already available in the current Hex release until package/docs evidence proves they are included.

### the agent's Discretion

No separate `## the agent's Discretion` section exists in CONTEXT.md. [VERIFIED: `.planning/phases/92-docs-claims-release-hygiene/92-CONTEXT.md`]

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Public `Rendro.PageContext` struct or callback API.
- Full visual TOC, PDF outlines, anchors, and cross-references.
- Charts / `%Rendro.Chart{}`.
- Global text shaping and broad script support.
- PDF.js GUI support, browser rendering backend, or support-matrix promotion.
- release-please / full release automation.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Guides explain page context, section-local numbering, and duplex running content with code examples, rendered-proof references, and explicit unsupported TOC/outline/chart/text-shaping boundaries. [VERIFIED: `.planning/REQUIREMENTS.md`] | Use `guides/page_primitive.md` as the primary guide; bind claims to `test/rendro/pipeline/paginate_test.exs`, `test/rendro/flow_test.exs`, and support-matrix rows for `page_numbering`, `section_page_numbering`, and `duplex_running_content`. [VERIFIED: codebase grep] |
| DOC-02 | Release/HexDocs workflow hardening prevents unreleased public docs from silently overclaiming the current Hex package and pins/minimizes CI permissions where practical. [VERIFIED: `.planning/REQUIREMENTS.md`] | Add package/docs inclusion checks for `ADOPTION.md`, keep `mix hex.build` and `mix docs` in validation, and add top-level `permissions: contents: read` to read-only workflows. [VERIFIED: `mix hex.build`; CITED: GitHub Docs] |
| DOC-03 | Public roadmap and `ADOPTION.md` language keeps global text shaping demand-gated rather than reusing the v2.7 label for a false shaping promise. [VERIFIED: `.planning/REQUIREMENTS.md`] | Rename public-facing shaping gate wording away from "v2.7 Global Text Shaping" or clarify it as "conditional future global text shaping"; update matrix deferrals that still say "deferred to v2.7 behind the LNCH-03 demand gate". [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 92 should be a targeted docs-contract and release-hygiene closure, not a feature phase. [VERIFIED: `.planning/ROADMAP.md`] The implementation-ready path is to update `guides/page_primitive.md` as the canonical explanation for `page_numbering: [restart: true]`, `{{section_page_number}}`, `{{section_total_pages}}`, and `only_on: :odd | :even`; keep `README.md` concise; and add docs-contract assertions that the public guide names unsupported TOC/outlines/anchors/cross-references, charts, global text shaping, and PDF.js GUI support. [VERIFIED: `.planning/phases/92-docs-claims-release-hygiene/92-CONTEXT.md`]

Support matrix rows should be added for `section_page_numbering` and `duplex_running_content` as non-viewer top-level rows, because the matrix already accepts flat non-viewer rows such as `page_numbering`, `statement`, `receipt_report`, and `certificate`. [VERIFIED: `priv/support_matrix.json`] Do not add a PDF.js support row; Phase 91 intentionally stores observations under `priv/pdfjs_observations/` and keeps existing PDF.js viewer cells as `explicit_deferral`. [VERIFIED: `.planning/phases/91-pdf-js-advisory-proof-lane/91-VERIFICATION.md`]

Release hygiene has one concrete local defect: `ADOPTION.md` is linked from public docs, omitted from `mix.exs` package files, and `mix docs` warns that the file does not exist in the docs context. [VERIFIED: `mix hex.build`; VERIFIED: `mix docs`] The least surprising fix is to include `ADOPTION.md` in package files and ExDoc extras or rewrite links so packaged HexDocs resolve. [CITED: Hex package docs; CITED: ExDoc docs] Add top-level read-only `permissions: contents: read` to `ci.yml` and `release.yml` unless a job writes to GitHub APIs; the current jobs use checkout/build/test/publish-to-Hex flows and do not need repository write permissions. [VERIFIED: `.github/workflows/*.yml`; CITED: GitHub Docs]

**Primary recommendation:** Update existing docs and contracts in place: one expanded PAGE primitive guide, two flat support-matrix rows, narrow PDF.js advisory wording tests, package/docs inclusion for `ADOPTION.md`, and read-only GitHub Actions permissions. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Rendro is pure-Elixir and Phoenix-first, focused on deterministic layout/pagination, observability, and truthful scope boundaries. [VERIFIED: `AGENTS.md`]
- Elixir 1.19.5 + OTP 28 is the project runtime. [VERIFIED: `AGENTS.md`; VERIFIED: `elixir --version`]
- Optional adapters include Phoenix 1.8.5 and Oban 2.21.1; core must not gain hard dependencies on Phoenix, Oban, admin tooling, Node, or PDF.js. [VERIFIED: `AGENTS.md`; VERIFIED: `.planning/phases/91-pdf-js-advisory-proof-lane/91-VERIFICATION.md`]
- Preserve deterministic and advisory verification lane separation in CI and docs. [VERIFIED: `AGENTS.md`; VERIFIED: `priv/guardrails/required_status_checks.json`]
- Treat documentation claims as contracts and avoid unsupported capability claims. [VERIFIED: `AGENTS.md`]
- Prefer optional dependency guards for integrations. [VERIFIED: `AGENTS.md`]
- Public engine architecture remains `build -> compose -> measure -> paginate -> render -> validate`. [VERIFIED: `AGENTS.md`]
- Before implementation edits, planned phase work should go through `/gsd-execute-phase`; this research file is a planning artifact requested by the GSD research workflow. [VERIFIED: `AGENTS.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Public guide copy for page context and duplex running content | Documentation / HexDocs | Docs-contract tests | Public docs own explanation; tests enforce that claims stay backed by engine evidence. [VERIFIED: `guides/page_primitive.md`; VERIFIED: `test/docs_contract/page_primitive_claims_test.exs`] |
| Support matrix entries for section numbering and duplex running content | Support contract data | Docs-contract tests | `priv/support_matrix.json` is the claim source; docs tests bind guide language to rows and evidence paths. [VERIFIED: `priv/support_matrix.json`; VERIFIED: `test/docs_contract/*claims_test.exs`] |
| PDF.js advisory observations | Advisory evidence tier | CI advisory job | Observations are maintainer evidence, not runtime API or GUI-viewer support. [VERIFIED: `.planning/phases/91-pdf-js-advisory-proof-lane/91-VERIFICATION.md`] |
| HexDocs/package-file hygiene | Mix package/docs config | CI release workflows | `mix.exs` controls Hex package files and ExDoc extras; workflows should prove package/docs behavior before publishing. [CITED: Hex package docs; CITED: ExDoc docs] |
| Global text shaping demand gate wording | Public docs and planning docs | Docs-contract tests | `ADOPTION.md`, roadmap text, and support-matrix deferrals must not imply v2.7 shipped global shaping. [VERIFIED: `ADOPTION.md`; VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `priv/support_matrix.json`] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Build, docs, tests, Hex package generation. [VERIFIED: `mix --version`] | Existing project runtime and package toolchain. [VERIFIED: `AGENTS.md`] |
| OTP | 28 / ERTS 16.3 | BEAM runtime for tests and docs builds. [VERIFIED: `elixir --version`] | Existing project runtime target. [VERIFIED: `AGENTS.md`] |
| ExDoc | locked 0.40.1; current compatible release 0.40.3 | Generate HexDocs from modules and extras. [VERIFIED: `mix.lock`; VERIFIED: `mix hex.info ex_doc`] | Existing docs generator; official docs describe `extras` and `--warnings-as-errors`. [CITED: ExDoc docs] |
| Hex Mix tasks | Hex 2.4.2 docs checked | Package and publish docs/package artifacts. [CITED: Hex package docs] | Official Hex workflow for Elixir packages. [CITED: Hex publish docs] |
| GitHub Actions | hosted workflow syntax | CI, advisory lanes, HexDocs publish, release publish. [VERIFIED: `.github/workflows/*.yml`] | Existing project automation; official docs support least-privilege `GITHUB_TOKEN` permissions. [CITED: GitHub Docs] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| YamlElixir | locked 2.11.0; current 2.12.2 | Parse workflow YAML in guardrail tests. [VERIFIED: `mix.lock`; VERIFIED: `mix hex.info yaml_elixir`] | Extend `required_checks_contract_test.exs` to assert top-level permissions. [VERIFIED: `test/guardrails/required_checks_contract_test.exs`] |
| JSV | locked 0.19.1; current 0.19.4 | JSON schema validation support. [VERIFIED: `mix.lock`; VERIFIED: `mix hex.info jsv`] | Only needed if support-matrix schema tests require stricter row validation. [VERIFIED: `mix.exs`] |
| Node / npm | Node 22.14.0, npm 11.1.0 | Maintainer-only PDF.js advisory lane. [VERIFIED: `node --version`; VERIFIED: `npm --version`] | Do not move into required CI or Hex package. [VERIFIED: `.planning/phases/91-pdf-js-advisory-proof-lane/91-VERIFICATION.md`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Updating `guides/page_primitive.md` | New guide for page context/duplex | Rejected by locked decision; more pages increase cross-link and stale-claim risk. [VERIFIED: `.planning/phases/92-docs-claims-release-hygiene/92-CONTEXT.md`] |
| Flat support rows for `section_page_numbering` and `duplex_running_content` | Add nested capability keys under `page_numbering` | Flat rows are more discoverable and match existing non-viewer support-row patterns; nested keys are less visible to public docs. [VERIFIED: `priv/support_matrix.json`] |
| Include PDF.js in support matrix | Advisory section or no row | Rejected by locked decision and Phase 91 verification; support vocabulary would blur advisory observations with GUI-viewer support. [VERIFIED: `.planning/phases/91-pdf-js-advisory-proof-lane/91-VERIFICATION.md`] |
| Full release automation | release-please / auto-tagging | Rejected by locked decision; current release preflight and exact tag publishing should remain. [VERIFIED: `.planning/phases/92-docs-claims-release-hygiene/92-CONTEXT.md`] |

**Installation:** No new package installs are recommended for Phase 92. [VERIFIED: phase scope]

**Version verification:** `mix hex.info ex_doc`, `mix hex.info yaml_elixir`, and `mix hex.info jsv` were run on 2026-06-13; no dependency upgrade is required for this phase. [VERIFIED: local command]

## Architecture Patterns

### System Architecture Diagram

```text
Author-facing feature claim
  -> Existing implementation evidence
     -> support_matrix row (supported or explicit_deferral)
        -> public guide wording
           -> docs-contract assertions
              -> mix run scripts/verify_docs.exs
                 -> mix ci / HexDocs workflow

Maintainer PDF.js observation
  -> scripts/pdfjs_observer + priv/pdfjs_observations
     -> advisory CI job, continue-on-error, no needs edge
        -> public wording: "pinned PDF.js advisory observations"
           -> docs-contract ban on support-promotion phrases

Release docs artifact
  -> mix.exs package files + ExDoc extras
     -> mix hex.build and mix docs
        -> HexDocs publish workflow
```

### Recommended Project Structure

```text
guides/
├── page_primitive.md       # Canonical page context, section numbering, duplex content guide. [VERIFIED: CONTEXT.md]
├── recipes.md              # Short ergonomic references only. [VERIFIED: CONTEXT.md]
└── api_stability.md        # Support-boundary and viewer-claim contract. [VERIFIED: CONTEXT.md]
priv/
├── support_matrix.json     # Public support rows and deferrals. [VERIFIED: codebase]
└── pdfjs_observations/     # Advisory observations only, not support proof. [VERIFIED: Phase 91 verification]
test/docs_contract/
├── page_primitive_claims_test.exs
├── pdfjs_advisory_claims_test.exs
└── adoption_claims_test.exs
```

### Pattern 1: Support-Backed Guide Claims

**What:** Public guide language names the supported capability and points to the support row/evidence path. [VERIFIED: `guides/page_primitive.md`]  
**When to use:** Every new v2.7 public feature claim. [VERIFIED: `.planning/REQUIREMENTS.md`]  
**Example:**

```elixir
# Source: existing public API from Phase 89/90 tests. [VERIFIED: test/rendro/pipeline/paginate_test.exs]
Rendro.section(
  name: :chapter_one,
  region: :body,
  page_numbering: [restart: true],
  content: [...]
)

Rendro.section(
  name: :odd_footer,
  region: :footer,
  only_on: :odd,
  content: [Rendro.page_number(format: "Chapter {{section_page_number}} of {{section_total_pages}}")]
)
```

### Pattern 2: Advisory Evidence Vocabulary

**What:** Use "pinned PDF.js advisory observations" and avoid "PDF.js support" or "PDF.js GUI support". [VERIFIED: `test/docs_contract/pdfjs_advisory_claims_test.exs`]  
**When to use:** Any README, guide, changelog, or stability-guide reference to Phase 91. [VERIFIED: `.planning/REQUIREMENTS.md`]  
**Example:**

```markdown
Pinned PDF.js advisory observations record renderer facts for committed fixtures; they are not GUI-viewer support proof. [VERIFIED: priv/pdfjs_observations/schema.json]
```

### Pattern 3: Package-Inclusion Proof Before Docs Publish

**What:** Keep linked public docs inside `package.files` or avoid linking them from packaged docs. [CITED: Hex package docs]  
**When to use:** Any README/guide link intended to resolve on HexDocs. [VERIFIED: `mix docs`]  
**Example:**

```elixir
# Source: Hex package :files supports explicit file lists. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html]
files: ~w(
  lib
  guides
  README.md
  ADOPTION.md
  CHANGELOG.md
)
```

### Anti-Patterns to Avoid

- **Promoting PDF.js observations into support rows:** This contradicts Phase 91 and would turn maintainer telemetry into viewer support. [VERIFIED: Phase 91 verification]
- **Using "v2.7 Global Text Shaping" as current public gate name:** v2.7 is now page context/browser proof hardening, so that wording can imply shaping is v2.7 scope. [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `ADOPTION.md`]
- **Adding docs without docs-contract assertions:** This project treats docs as contracts, and `scripts/verify_docs.exs` is the explicit lane. [VERIFIED: `AGENTS.md`; VERIFIED: `scripts/verify_docs.exs`]
- **Publishing docs from main that are not in the Hex package:** This creates broken HexDocs links and apparent unreleased claims. [VERIFIED: `mix docs`; CITED: Hex package docs]
- **Granting default write-capable workflow tokens:** Official GitHub docs recommend limiting `GITHUB_TOKEN` to minimum required permissions. [CITED: GitHub Docs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hex package inclusion proof | Custom tarball parser | `mix hex.build --unpack <dir>` | Hex already reports the package file list. [VERIFIED: local command; CITED: Hex package docs] |
| HexDocs reference warnings | Ad hoc link scanner only | `mix docs --warnings-as-errors` or `mix docs` plus targeted contract | ExDoc owns doc reference resolution and supports warnings-as-errors. [CITED: ExDoc docs] |
| Workflow permissions validation | Regex-only YAML checks | Existing `YamlElixir.read_from_string/1` in guardrail tests | The project already parses workflow YAML in tests. [VERIFIED: `test/guardrails/required_checks_contract_test.exs`] |
| PDF.js compatibility proof | Browser support claims | Existing `scripts/pdfjs_observer` advisory path | Phase 91 explicitly scoped observations as advisory. [VERIFIED: Phase 91 verification] |
| Release automation | release-please/full auto-publish | Existing exact-tag release workflow plus `mix release.preflight` | Full automation is deferred by locked decision. [VERIFIED: CONTEXT.md] |

**Key insight:** Phase 92 should convert shipped behavior into bounded public contracts; it should not introduce new render behavior or broaden support semantics. [VERIFIED: `.planning/REQUIREMENTS.md`]

## Common Pitfalls

### Pitfall 1: Section Numbering Looks Like TOC Infrastructure

**What goes wrong:** Docs imply page context supports TOC, outlines, anchors, or cross-references. [VERIFIED: `.planning/REQUIREMENTS.md`]  
**Why it happens:** Section-local page totals sound like an anchor registry, but Phase 89 intentionally kept page context internal. [VERIFIED: Phase 89 summary]  
**How to avoid:** State that tokens are for running header/footer text only and future TOC/anchor APIs are deferred. [VERIFIED: CONTEXT.md]  
**Warning signs:** Public mention of "outline", "anchor", "cross-reference", or "TOC" without "deferred" or "unsupported". [VERIFIED: docs-contract pattern]

### Pitfall 2: Duplex Means Physical Parity, Not Section Parity

**What goes wrong:** Docs describe odd/even as chapter-local or recto/verso insertion behavior. [VERIFIED: Phase 90 summary]  
**Why it happens:** Duplex publishing language often implies blank page insertion; Phase 90 did not add recto/verso or blank-page insertion. [VERIFIED: Phase 90 summary]  
**How to avoid:** Say `only_on` is evaluated against physical page parity and does not insert blank pages. [VERIFIED: Phase 90 summary]  
**Warning signs:** Public copy says "recto", "verso", "force right-hand page", or "blank page insertion" without deferral. [VERIFIED: Phase 90 summary]

### Pitfall 3: PDF.js Advisory Becomes Viewer Support

**What goes wrong:** Public docs say "PDF.js support" because an observer script exists. [VERIFIED: `test/docs_contract/pdfjs_advisory_claims_test.exs`]  
**Why it happens:** The observation lane records renderer facts, which can be mistaken for GUI behavior. [VERIFIED: Phase 91 verification]  
**How to avoid:** Use exact advisory vocabulary and keep existing `pdfjs` rows as `explicit_deferral`. [VERIFIED: Phase 91 verification]  
**Warning signs:** New support-matrix `pdfjs` evidence fields or public phrases banned by `pdfjs_advisory_claims_test.exs`. [VERIFIED: test file]

### Pitfall 4: HexDocs Links Point Outside the Package

**What goes wrong:** README links to `ADOPTION.md`, but HexDocs cannot resolve it. [VERIFIED: `mix docs`]  
**Why it happens:** `package.files` is explicit and currently omits `ADOPTION.md`. [VERIFIED: `mix hex.build`]  
**How to avoid:** Include root public docs that are linked from packaged extras, and add contract tests for package file inclusion. [CITED: Hex package docs]  
**Warning signs:** `mix docs` warnings for missing files or `mix hex.build` file list lacking linked root docs. [VERIFIED: local command]

### Pitfall 5: Over-Automated Release Workflow

**What goes wrong:** A docs hygiene phase adds tag creation, release-please, or broad write permissions. [VERIFIED: CONTEXT.md]  
**Why it happens:** "Release hygiene" can be misread as full automation. [ASSUMED]  
**How to avoid:** Keep exact-tag release preflight and publish flow; add read-only permissions where possible. [VERIFIED: release workflow; CITED: GitHub Docs]  
**Warning signs:** New jobs with `contents: write`, tag creation, changelog generation, or publishing on branch pushes. [VERIFIED: release workflow]

## Code Examples

Verified patterns from existing sources:

### Section-Local Numbering Guide Example

```elixir
# Source: Phase 89 public API and paginate tests. [VERIFIED: test/rendro/pipeline/paginate_test.exs]
chapter =
  Rendro.section(
    name: :chapter,
    region: :body,
    page_numbering: [restart: true],
    content: [
      Rendro.text("Chapter body")
    ]
  )

footer =
  Rendro.section(
    name: :chapter_footer,
    region: :footer,
    content: [
      Rendro.page_number(format: "Chapter page {{section_page_number}} of {{section_total_pages}}")
    ]
  )
```

### Duplex Running Footer Example

```elixir
# Source: Phase 90 public API and flow/paginate tests. [VERIFIED: test/rendro/flow_test.exs]
odd_footer =
  Rendro.section(
    name: :odd_footer,
    region: :footer,
    only_on: :odd,
    content: [Rendro.page_number(format: "Right {{page_number}}")]
  )

even_footer =
  Rendro.section(
    name: :even_footer,
    region: :footer,
    only_on: :even,
    content: [Rendro.page_number(format: "{{page_number}} Left")]
  )
```

### Workflow Permissions Pattern

```yaml
# Source: GitHub recommends minimum required GITHUB_TOKEN permissions. [CITED: https://docs.github.com/en/actions/tutorials/authenticate-with-github_token]
permissions:
  contents: read
```

### ExDoc Extras Pattern

```elixir
# Source: ExDoc supports extras in docs configuration. [CITED: https://ex-doc.hexdocs.pm/Mix.Tasks.Docs.html]
docs: [
  main: "readme",
  extras: [
    "README.md",
    "ADOPTION.md",
    "guides/page_primitive.md"
  ]
]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Global `{{page_number}}` / `{{total_pages}}` only | Section-local `{{section_page_number}}` / `{{section_total_pages}}` via internal page context | Phase 89, 2026-06-13 [VERIFIED: Phase 89 summary] | Docs must explain new tokens without exposing `Rendro.PageContext`. [VERIFIED: Phase 89 summary] |
| Single running footer per region | Multiple physical odd/even running sections via `only_on` | Phase 90, 2026-06-13 [VERIFIED: Phase 90 summary] | Docs must state physical parity and no blank insertion. [VERIFIED: Phase 90 summary] |
| No browser-family observer | Pinned PDF.js advisory observations | Phase 91, 2026-06-13 [VERIFIED: Phase 91 summary] | Public docs may mention observations but not support. [VERIFIED: Phase 91 verification] |
| v2.7 label used for conditional global shaping gate | v2.7 is Page Context & Browser Proof Hardening; shaping remains conditional | Roadmap active state, 2026-06-13 [VERIFIED: `.planning/ROADMAP.md`] | Public gate wording must be updated to avoid false shaping promise. [VERIFIED: codebase grep] |

**Deprecated/outdated:**

- `ADOPTION.md` heading "Current Gate: v2.7 Global Text Shaping" is now misleading because active v2.7 scope is page context/browser proof hardening. [VERIFIED: `ADOPTION.md`; VERIFIED: `.planning/ROADMAP.md`]
- Support-matrix text-shaping deferrals that say Hebrew/Devanagari/Thai are "deferred to v2.7" are stale now that v2.7 is not shaping. [VERIFIED: `priv/support_matrix.json`]

## Support Matrix Recommendation

Add top-level non-viewer rows for `section_page_numbering` and `duplex_running_content`. [VERIFIED: `priv/support_matrix.json` pattern] The rows should be flat objects with `surface`, `status`, `evidence`, `recorded_at`, and `capabilities`, matching `page_numbering` rather than viewer matrices. [VERIFIED: existing `page_numbering` row]

Recommended rows:

```json
{
  "section_page_numbering": {
    "surface": "section_page_numbering",
    "status": "supported",
    "evidence": "test/rendro/pipeline/paginate_test.exs",
    "recorded_at": "2026-06-13",
    "capabilities": {
      "restart_on_new_physical_page": "supported",
      "section_page_number_token": "supported",
      "section_total_pages_token": "supported",
      "decimal_only": "supported"
    }
  },
  "duplex_running_content": {
    "surface": "duplex_running_content",
    "status": "supported",
    "evidence": "test/rendro/pipeline/paginate_test.exs",
    "recorded_at": "2026-06-13",
    "capabilities": {
      "only_on_odd_even": "supported",
      "physical_page_parity": "supported",
      "composes_with_suppress_on": "supported",
      "composes_with_section_tokens": "supported"
    }
  }
}
```

Schema/docs-contract risk: adding new top-level rows may require support-matrix schema or docs-contract updates if tests enumerate known keys. [ASSUMED] Local grep found docs tests directly read known rows rather than a single strict top-level allowlist, but planner should still run full docs-contract after edits. [VERIFIED: codebase grep]

## ADOPTION.md / Global Text Shaping Wording

Preserve the threshold mechanics exactly unless the user asks to re-open the gate policy. [VERIFIED: `test/docs_contract/adoption_claims_test.exs`] The risky part is the label, not the thresholds: current `ADOPTION.md` says "conditional v2.7 global text shaping gate" and "Current Gate: v2.7 Global Text Shaping", while `.planning/ROADMAP.md` says v2.7 is Page Context & Browser Proof Hardening and global shaping is conditional after the v2.6 gate. [VERIFIED: `ADOPTION.md`; VERIFIED: `.planning/ROADMAP.md`]

Recommended wording:

- Rename heading to `## Current Gate: Future Global Text Shaping`. [VERIFIED: current docs conflict]
- First paragraph: "This ledger records public, reviewable signals for Rendro's conditional future global text shaping milestone." [VERIFIED: current docs conflict]
- Keep baseline date, thresholds, counting rules, review cadence, and 45-day minimum unchanged. [VERIFIED: `test/docs_contract/adoption_claims_test.exs`]
- Update support-matrix text-shaping deferrals from "deferred to v2.7 behind the LNCH-03 demand gate" to "deferred until the ADOPTION.md global text-shaping demand gate triggers." [VERIFIED: `priv/support_matrix.json`]
- Update docs-contract expectations in `adoption_claims_test.exs` to assert "Future Global Text Shaping" and preserve exact threshold sentences. [VERIFIED: test file]

## Release / HexDocs Workflow Hygiene

Hex package `:files` can explicitly list files/directories included in the package, and Hex creates the tar from that list when publishing. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html] ExDoc supports `extras` in `docs` configuration, and `mix docs` has a `--warnings-as-errors` option. [CITED: https://ex-doc.hexdocs.pm/Mix.Tasks.Docs.html] The local project currently omits `ADOPTION.md` from package files and ExDoc extras while README links to it; `mix docs` warns about missing `ADOPTION.md`. [VERIFIED: `mix.exs`; VERIFIED: `mix docs`]

Recommended release hygiene tasks:

1. Add `ADOPTION.md` to `package.files`. [VERIFIED: `mix hex.build`]
2. Add `ADOPTION.md` to `docs.extras`, likely under `Policies`, or change README/comparison links so no packaged docs link to an excluded file. [CITED: ExDoc docs]
3. Add a docs-contract test that `Rendro.MixProject.project()[:package][:files]` includes every root markdown file linked from README guides section. [VERIFIED: existing docs-contract pattern]
4. Consider changing CI docs build from `mix docs` to `mix docs --warnings-as-errors` only after existing hidden-module warnings are resolved or explicitly skipped; current `mix docs` emits unrelated hidden-module warnings. [VERIFIED: `mix docs`; CITED: ExDoc docs]
5. Add `permissions: contents: read` to `.github/workflows/ci.yml` and `.github/workflows/release.yml`. [CITED: GitHub Docs; VERIFIED: workflow scan]
6. Do not add `contents: write` unless a job creates releases/tags or writes repository contents; current release workflow publishes to Hex with `HEX_API_KEY`, not GitHub API writes. [VERIFIED: `.github/workflows/release.yml`; CITED: GitHub Docs]
7. Extend `required_checks_contract_test.exs` to parse workflow YAML and assert `permissions.contents == "read"` for `ci.yml`, `hexdocs.yml`, and `release.yml`. [VERIFIED: existing YamlElixir usage]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | "Release hygiene" can be misread as full automation. | Common Pitfalls | Low; this is interpretive, not implementation-critical. |
| A2 | Adding new top-level support rows may require schema or docs-contract updates if tests enumerate known keys. | Support Matrix Recommendation | Medium; planner must run full docs-contract and schema tests after editing matrix. |

## Open Questions (RESOLVED)

1. **Should `ADOPTION.md` become an ExDoc extra or only a packaged file?**  
   - What we know: README and comparison link to it, and `mix docs` warns because it is missing from ExDoc context. [VERIFIED: `mix docs`]  
   - RESOLVED: Include it as a Policies extra because it is already public-facing and linked from public docs. [VERIFIED: current links]

2. **Should `page_numbering` be expanded instead of adding `section_page_numbering`?**  
   - What we know: `page_numbering` exists and is supported for the older global PAGE primitive. [VERIFIED: `priv/support_matrix.json`]  
   - RESOLVED: Add separate top-level rows for new v2.7 claims so docs-contract can bind exact capabilities without rewriting older semantics. [VERIFIED: CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix tests/docs/package | Yes | 1.19.5 / OTP 28 [VERIFIED: `elixir --version`] | None needed |
| Mix | `mix test`, `mix docs`, `mix hex.build` | Yes | 1.19.5 [VERIFIED: `mix --version`] | None needed |
| Git | Commit research and future phase edits | Yes | 2.41.0 [VERIFIED: `git --version`] | None needed |
| Node | PDF.js advisory verification | Yes | 22.14.0 [VERIFIED: `node --version`] | Advisory lane can be skipped locally if not touching observations. [VERIFIED: Phase 91 summary] |
| npm | PDF.js advisory dependency install | Yes | 11.1.0 [VERIFIED: `npm --version`] | Advisory lane can be skipped locally if not touching observations. [VERIFIED: Phase 91 summary] |

**Missing dependencies with no fallback:** None found. [VERIFIED: environment probes]  
**Missing dependencies with fallback:** None found. [VERIFIED: environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5. [VERIFIED: `mix --version`; VERIFIED: test files] |
| Config file | `mix.exs` aliases and `test/test_helper.exs`. [VERIFIED: codebase] |
| Quick run command | `mix test test/docs_contract/page_primitive_claims_test.exs test/docs_contract/pdfjs_advisory_claims_test.exs test/docs_contract/adoption_claims_test.exs test/guardrails/required_checks_contract_test.exs` [VERIFIED: files exist] |
| Full suite command | `mix ci` [VERIFIED: `mix.exs`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOC-01 | Guide claims for page context, section tokens, duplex running content, and explicit deferrals | docs-contract | `mix test test/docs_contract/page_primitive_claims_test.exs` | Yes, update needed. [VERIFIED: file exists] |
| DOC-02 | Package/docs inclusion and workflow permission hardening | docs-contract / guardrail | `mix test test/guardrails/required_checks_contract_test.exs test/docs_contract/adoption_claims_test.exs` plus `mix hex.build` and `mix docs` | Yes, update needed. [VERIFIED: files exist] |
| DOC-03 | Global shaping remains demand-gated and not v2.7 scope | docs-contract | `mix test test/docs_contract/adoption_claims_test.exs test/docs_contract/script_support_claims_test.exs` | Yes, update needed. [VERIFIED: files exist] |

### Sampling Rate

- **Per task commit:** Run focused docs-contract tests for touched files. [VERIFIED: existing workflow pattern]
- **Per wave merge:** Run `mix run scripts/verify_docs.exs`. [VERIFIED: `scripts/verify_docs.exs`]
- **Phase gate:** Run `mix ci` before verification. [VERIFIED: `mix.exs`]

### Wave 0 Gaps

- [ ] Update `test/docs_contract/page_primitive_claims_test.exs` for section tokens, duplex `only_on`, and named deferrals. [VERIFIED: file exists]
- [ ] Update or add support-matrix docs-contract checks for `section_page_numbering` and `duplex_running_content`. [VERIFIED: `priv/support_matrix.json`]
- [ ] Update `test/docs_contract/pdfjs_advisory_claims_test.exs` if adding public advisory wording to `guides/page_primitive.md` or `guides/api_stability.md`. [VERIFIED: file exists]
- [ ] Update `test/docs_contract/adoption_claims_test.exs` if `ADOPTION.md` heading changes away from "v2.7 Global Text Shaping". [VERIFIED: file exists]
- [ ] Add package-file inclusion assertions for `ADOPTION.md`. [VERIFIED: local package defect]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No | No app authentication changes. [VERIFIED: phase scope] |
| V3 Session Management | No | No session changes. [VERIFIED: phase scope] |
| V4 Access Control | Yes for CI token scope | Use least-privilege `GITHUB_TOKEN` permissions. [CITED: GitHub Docs] |
| V5 Input Validation | Yes for JSON/YAML contract tests | Use `Jason`/`JSON` and `YamlElixir` parsing rather than string-only validation. [VERIFIED: test files] |
| V6 Cryptography | No | No crypto implementation changes; signing support boundaries remain unchanged. [VERIFIED: phase scope] |

### Known Threat Patterns for Elixir/HexDocs Release Hygiene

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overbroad workflow token permissions | Elevation of privilege | Top-level `permissions: contents: read` unless write scopes are required. [CITED: GitHub Docs] |
| Publishing docs that imply unreleased package capabilities | Repudiation / Information disclosure | Tie public docs to support rows, evidence, package inclusion, and changelog entries. [VERIFIED: project docs-contract pattern] |
| External Node advisory dependency treated as runtime dependency | Tampering / Supply chain | Keep `scripts/pdfjs_observer` isolated, exact-pinned, and advisory-only. [VERIFIED: Phase 91 verification] |
| Broken HexDocs links to excluded files | Repudiation | Include linked files in `package.files` and ExDoc extras, then run `mix docs`. [VERIFIED: local warning; CITED: Hex package docs] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/92-docs-claims-release-hygiene/92-CONTEXT.md` - locked decisions, deferred ideas, and canonical files. [VERIFIED]
- `.planning/REQUIREMENTS.md` - DOC-01..03 scope and success criteria. [VERIFIED]
- `.planning/ROADMAP.md` - Phase 92 deliverables and active v2.7 scope. [VERIFIED]
- Phase 89, 90, and 91 summaries and Phase 91 verification - shipped behavior and proof boundaries. [VERIFIED]
- `guides/page_primitive.md`, `guides/api_stability.md`, `guides/recipes.md`, `ADOPTION.md`, `priv/support_matrix.json`, `test/docs_contract/*`, and workflows - current repo state. [VERIFIED]
- Hex package docs: `https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html` and `https://hex.pm/docs/publish` - package files and publish behavior. [CITED]
- ExDoc docs: `https://ex-doc.hexdocs.pm/Mix.Tasks.Docs.html` - docs extras and warnings-as-errors. [CITED]
- GitHub Actions docs: `https://docs.github.com/en/actions/tutorials/authenticate-with-github_token` and checkout Marketplace docs - least-privilege workflow permissions and checkout `contents: read`. [CITED]

### Secondary (MEDIUM confidence)

- `mix hex.info ex_doc`, `mix hex.info yaml_elixir`, `mix hex.info jsv` - registry versions and lock status. [VERIFIED: Hex registry]

### Tertiary (LOW confidence)

- None used for implementation recommendations. [VERIFIED: source log]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - existing project stack and local versions verified, with official Hex/ExDoc/GitHub docs for release facts. [VERIFIED]
- Architecture: HIGH - phase is docs/release-contract work over existing files and completed phases. [VERIFIED]
- Pitfalls: HIGH for project-specific pitfalls; MEDIUM for general release-automation overreach risk because it is partly interpretive. [VERIFIED; ASSUMED]

**Research date:** 2026-06-13  
**Valid until:** 2026-07-13 for project-specific docs patterns; 2026-06-20 for GitHub Actions and HexDocs workflow details because those docs can change. [ASSUMED]
