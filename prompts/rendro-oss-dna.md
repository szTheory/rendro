# Rendro OSS DNA

Purpose: capture the reusable engineering and product DNA from recent `szTheory` Elixir OSS libraries so Rendro starts with proven defaults rather than rediscovering the same lessons.

## 1) Canonical Rendro synthesis (from existing prompt research)

Primary sources:
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md`
- `prompts/Rendro Brand Book.txt`

### Product thesis
- Rendro should be a pure-Elixir, Phoenix-first document/PDF platform with no Chrome runtime dependency in core.
- The strategic gap is not "PDF exists vs does not exist"; it is production-grade ergonomics: layout primitives, pagination, font/i18n path, operational telemetry, validation, docs, and deployment clarity.
- Scope must stay explicit: avoid promising full HTML/CSS rendering, arbitrary PDF editing, or compliance overclaims before support is real.

### Default architecture direction
- Keep a pure core and thin adapters:
  - `rendro` core (document model, layout, renderer, serializer).
  - Optional ecosystem adapters (`rendro_phoenix`, `rendro_oban`, validation adapters, optional admin tooling).
- Data-first document AST and deterministic render pipeline:
  - Build -> compose -> measure -> paginate -> render -> validate.
- Two top-level APIs sharing one engine:
  - Fixed-position API for exact forms/labels.
  - Flow API for reports/invoices/statements.

### Rendro north-star constraints
- Reliable pagination and table behavior are first-order.
- Errors must be instructive (what/where/why/next), not opaque.
- Production is a feature: bounded concurrency, telemetry, validation hooks, reproducibility.
- Honest support matrix beats broad claims.

## 2) Cross-library engineering DNA (what to repeat)

Focused libraries inspected:
- `threadline`, `sigra`, `lockspire`, `accrue`, `mailglass`, `rulestead`, `scrypath`, `kiln`, `lattice_stripe`.

Key implementation sources included:
- `mix.exs` in each library
- `.github/workflows/*`
- `.planning/RETROSPECTIVE.md`, `.planning/STATE.md`, milestone archives

### 2.1 CI/release patterns to copy

1. **Single canonical verify entrypoint**
- Pattern: explicit `mix verify.*` / `mix ci.*` aliases as the contract.
- Seen in: `threadline/mix.exs`, `mailglass/mix.exs`, `scrypath/mix.exs`, `accrue/accrue/mix.exs`.
- Rendro default:
  - one root `mix ci` contract
  - focused `mix verify.phase_nn` gates where needed
  - docs/build/package checks in the same contract.

2. **Release safety checks before publish**
- Pattern: dry-run publish + version/tag alignment + release-shape checks.
- Seen in:
  - `threadline/.github/workflows/hex-publish.yml`
  - `sigra/.github/workflows/release-please.yml`
  - `rulestead/.github/workflows/publish-hex.yml`
  - `scrypath/.github/workflows/release-please.yml`
- Rendro default:
  - verify tag equals `@version`
  - run tests/docs/package build before `mix hex.publish`
  - keep manual recovery workflow for emergency republish.

3. **Pinned action references for supply-chain stability**
- Pattern: pin GitHub Action SHAs for critical workflows.
- Seen in: `sigra/.github/workflows/ci.yml`, `lockspire/.github/workflows/ci.yml`, `rulestead/.github/workflows/*.yml`.
- Rendro default:
  - pin actions by commit SHA on release-critical workflows.

4. **Scheduled drift checks and rolling issue strategy**
- Pattern: periodic drift verification and update-existing issue handling.
- Seen in:
  - `lattice_stripe/.github/workflows/drift.yml`
  - `rulestead/.github/workflows/verify-published-release.yml`
  - `scrypath/.github/workflows/verify-published-release.yml`
- Rendro default:
  - scheduled drift checks for docs/examples/release parity and external dependency drift.

### 2.2 Test strategy patterns to copy

1. **Contract tests for docs/promises**
- Pattern: test files assert README/guide claims stay true.
- Seen in:
  - `threadline` doc-contract usage in `mix.exs` and CI
  - `accrue` docs contract scripts in CI
  - `sigra` release/readiness and installer contract focus
  - `scrypath` docs contract discipline across milestones
- Rendro default:
  - add docs-contract tests early for quickstart, supported surface, and limitations.

2. **Reference app as executable adoption proof**
- Pattern: maintain an example host app and run it in CI.
- Seen in:
  - `threadline/examples/threadline_phoenix`
  - `sigra/test/example`
  - `accrue/examples/accrue_host`
  - `scrypath/examples/phoenix_meilisearch`
- Rendro default:
  - ship `examples/rendro_phoenix` and include it in CI from the beginning.

3. **Optional integration lanes are explicit**
- Pattern: keep deterministic core lane merge-blocking, make external-provider/live lanes advisory.
- Seen in:
  - `accrue` Fake merge-blocking vs live Stripe advisory
  - `sigra` install and browser lanes separated by intent
  - `mailglass` no-optional-deps compile lane
- Rendro default:
  - merge-blocking deterministic lane; optional external rendering/validation adapters as separate, clearly labeled lanes.

### 2.3 API and package design patterns to copy

1. **Optional dependencies with explicit gates**
- Pattern: `optional: true`, `Code.ensure_loaded?`, and compile warning suppression by explicit allowlist.
- Seen in: `sigra/mix.exs`, `mailglass/mix.exs`, `accrue/accrue/mix.exs`, `scrypath/mix.exs`.
- Rendro default:
  - optional adapters and integrations must compile out cleanly.

2. **Clear package boundaries in monorepos**
- Pattern: sibling packages with strict package file whitelists.
- Seen in:
  - `accrue` and `rulestead` sibling-package release design
  - `scrypath` exclusion notes for `scrypath_ops` from Hex package.
- Rendro default:
  - separate core from Phoenix/admin integrations and keep Hex package contents minimal and explicit.

3. **Source/ref docs hygiene**
- Pattern: `source_ref` tied to release tags so HexDocs source links are stable.
- Seen in: `sigra/mix.exs`, `threadline/mix.exs`, `accrue/accrue/mix.exs`, `rulestead/rulestead/mix.exs`, `lattice_stripe/mix.exs`.
- Rendro default:
  - enforce docs/source tag parity pre-publish.

### 2.4 Process DNA from `.planning` retrospectives

1. **Traceability must be updated during execution, not deferred**
- Recurring lesson across: `threadline`, `sigra`, `accrue`, `scrypath`.
- Rendro default:
  - every phase close updates requirements traceability and verification references immediately.

2. **Milestone close tooling can fail; keep a manual close protocol**
- Recurring issue: milestone archive command failure noted in `threadline`, `sigra`, `accrue`, `scrypath`, `kiln`.
- Rendro default:
  - keep an explicit manual archive checklist in maintainer docs.

3. **Truthful verification boundaries**
- Pattern: do not claim beyond evidence; separate CI-proven vs external/human/advisory.
- Seen in: `accrue`, `sigra`, `threadline`, `rulestead`.
- Rendro default:
  - classify every verification row as deterministic, advisory, or human-required.

## 3) Footguns to avoid in Rendro

1. **Scope creep into browser-renderer territory**
- Avoid presenting Rendro core as full HTML/CSS renderer.

2. **Compliance language drift**
- Avoid "PDF/A compliant" or "PDF/UA compliant" claims without validator-backed proof paths.

3. **Optional dependency leakage**
- Avoid hard-linking optional adapters into core compile paths.

4. **Release narrative mismatch**
- Avoid docs/changelog/requirements drift around what actually shipped.

5. **Verification ambiguity**
- Avoid mixed "works locally" claims; define the merge authority and keep it consistent.

## 4) Rendro default quality contract (v1 baseline)

- Required on every PR:
  - formatting
  - compile with warnings-as-errors
  - tests
  - docs build
  - package build checks
  - quickstart/docs contract checks
- Required before publish:
  - version/tag parity
  - publish dry-run
  - release parity checks
- Optional/advisory lanes:
  - heavier visual regression lanes
  - external validator/lint integrations
  - stress/perf suites

This DNA is intentionally conservative: it optimizes for trust, reproducibility, and adoption clarity over premature breadth.
