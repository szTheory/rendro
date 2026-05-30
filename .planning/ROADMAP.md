# Roadmap: Rendro

**Phase numbering:** sequential and continuous across milestones (never restarts at 01). v2.4 closed at phase 77; v2.5 continues from phase 78.

## Milestones

- ✅ **v1.0 MVP** — deterministic core rendering (shipped)
- ✅ **v1.1 Layout Authoring** — templates/regions, pagination semantics (shipped)
- ✅ **v1.2 Typography & Assets** — deterministic typography, honest Unicode boundaries (shipped)
- ✅ **v1.3 Hex Release Readiness** — first public package boundary (shipped 2026-05-03)
- ✅ **v1.4 Async Delivery & Artifact Ops** — queued lifecycle, artifact metadata, integrations (shipped 2026-05-05)
- ✅ **v1.5 Validation & Trust Surfaces** — Poppler structural validation, support matrix (shipped 2026-05-05)
- ✅ **v1.8 Interactive PDF Forms** — Phases 45-47 (shipped 2026-05-05)
- ✅ **v1.9 Embedded Artifact Surfaces** — Phases 48-50 (shipped 2026-05-06)
- ✅ **v1.10 Protected Delivery Hooks** — Phases 51-54 (shipped 2026-05-06)
- ✅ **v2.0 Signature Fields & Signing Prep** — Phases 55-59 (shipped 2026-05-07)
- ✅ **v2.1 Cryptographic Signing** — Phases 60-63 (shipped 2026-05-07)
- ✅ **v2.2 Long-Lived Signatures** — Phases 64-67 (shipped 2026-05-08)
- ✅ **v2.3 Viewer Proof & Interop Closure** — Phases 68-72 (shipped 2026-05-29, tag v0.3.1)
- ✅ **v2.4 Batteries-Included Workflow & Adoption Closure** — Phases 73-77 (shipped 2026-05-30)
- 📋 **v2.5 1.0 Release Capstone** — Phases 78-82 (active) — formal SemVer/API-stability commitment + first 1.x public hex release (`1.0.0`)
- 💤 **v2.6 Global Text Shaping & Script Support** — conditional, only if adopter demand justifies the core investment

## Phases

<details>
<summary>✅ v1.0 – v2.4 (Phases 1-77) — SHIPPED</summary>

Earlier milestones are archived individually under `.planning/milestones/v[X.Y]-ROADMAP.md` with matching `-REQUIREMENTS.md` and (where present) `-MILESTONE-AUDIT.md`. See `.planning/MILESTONES.md` for the per-milestone accomplishment ledger. v2.4 (Phases 73-77) shipped 2026-05-30 — adoption closure, audit `passed`, 19/19 requirements, archived in `milestones/v2.4-ROADMAP.md`.

</details>

### 📋 v2.5 1.0 Release Capstone (Phases 78-82)

- [x] **Phase 78: Public API Surface Definition & Cleanup** - Hide accidentally-public internals, expose returned structs, author the tiered `priv/public_api.json` manifest, add ExDoc stability badges, normalize recipe opts (completed 2026-05-30)
- [x] **Phase 79: Public API Contract Enforcement Lane** - An introspection-based docs-contract test asserts documented surface == manifest (drift fails CI), wired into required status checks (completed 2026-05-30)
- [ ] **Phase 80: Stability Contract & Migration Docs** - Two-tier SemVer contract + byte-output carve-out + soft-deprecation policy, `upgrading_to_1.0.md`, internal-label scrub, Tier-1 claims test
- [ ] **Phase 81: Release Hardening** - Bump to 1.0.0, allowlist tarball audit + hex.audit/deps.audit, fix the CHANGELOG self-block, SHA-pin the publish lane
- [ ] **Phase 82: 1.0.0 Consolidation & Publish** - Write the consolidated `## [1.0.0]` CHANGELOG, then the irreversible proof-gated publish (hex package + docs, GitHub Release, post-publish verification)

## Phase Details

### Phase 78: Public API Surface Definition & Cleanup

**Goal**: The public API surface is what Rendro intends to expose — accidentally-public internals are hidden, returned structs are documented, every public module carries a tier tag, and a checked-in `priv/public_api.json` manifest is the canonical, schema-versioned source of truth for that surface
**Depends on**: Nothing (first phase of v2.5)
**Requirements**: API-01, API-02, API-03, API-05
**Success Criteria** (what must be TRUE):

  1. HexDocs no longer renders `Rendro.PDF.CidFont` or `Rendro.PDF.FontSubsetter` (now `@moduledoc false`), and the `Rendro.Sign`/`Rendro.Protect` `redact_*` helpers no longer appear in module docs (`@doc false`) — a sweep confirms every currently-public `lib/` module either lands in the manifest or is hidden
  2. `Rendro.Metadata` renders in HexDocs with a real `@moduledoc` and a documented `@type t`, so the return type of public `Rendro.metadata/1` is no longer an invisible type; any other invisible-type gaps surfaced by the sweep are closed
  3. `priv/public_api.json` exists as a schema-versioned manifest (mirroring `support_matrix.json`) listing every documented module/function with exactly one tier (`stable` | `adapter`)
  4. Each public module renders a stability badge (Stable / Adapter) in HexDocs sourced from `@moduledoc` metadata
  5. All five recipes handle `sections/2` opts uniformly (invoice/branded no longer silently ignore `_opts`); the normalization is additive and breaks no existing caller

**Plans**: 5 plans
Plans:
**Wave 1**

- [x] 78-01-PLAN.md — Hiding sweep: @moduledoc false on 6 internals + @doc false on redact_* helpers + flip Rendro.Metadata to documented
- [x] 78-02-PLAN.md — Tier tagging: @moduledoc tags: [:stable|:adapter] across all public modules + mix.exs badge CSS/JS + groups_for_modules reconciliation
- [x] 78-03-PLAN.md — Recipe opts normalization: Invoice + BrandedInvoice sections/2 opts threading

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 78-04-PLAN.md — Rendro.PublicApi introspection module + Loader + Validator + priv/schemas/public_api.schema.json

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 78-05-PLAN.md — mix rendro.api.gen task + priv/public_api.json generation + manifest integration tests

### Phase 79: Public API Contract Enforcement Lane

**Goal**: API surface drift can no longer reach `main` silently — an introspection-based docs-contract test mechanically pins the documented surface to the manifest and is a required CI status check, so any accidental public/internal change fails the build with an errors-as-product diff
**Depends on**: Phase 78
**Requirements**: API-04
**Success Criteria** (what must be TRUE):

  1. `test/docs_contract/public_api_contract_test.exs` introspects `Code.fetch_docs/1` and asserts the documented surface exactly equals `priv/public_api.json` — adding a stray public function (or hiding a documented one) fails the public-api lane with a human-readable manifest-drift diff
  2. The test asserts the known internals (`PDF.CidFont`, `PDF.FontSubsetter`, the `redact_*` helpers) are reported `:hidden`, and fails if any becomes visible again
  3. The test asserts Tier-1 `@spec` coverage and that every public module carries exactly one tier tag
  4. The lane is wired into `priv/guardrails/required_status_checks.json` so it gates merges to `main` alongside the existing engine-critical lanes

**Plans**: 3 plans
Plans:
**Wave 1**

- [x] 79-01-PLAN.md — Contract test: public_api_contract_test.exs with all 4 API-04 sub-assertions (manifest equality, schema, hidden-internals, tier-tag, @spec — @spec starts RED)
- [x] 79-02-PLAN.md — @spec backfill: add 2 @spec annotations to lib/rendro/component.ex to turn @spec assertion GREEN

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 79-03-PLAN.md — Guardrails lockstep triple: verify_docs.exs lane 11 + required_checks_contract_test.exs count bump + required_status_checks.json notes update

### Phase 80: Stability Contract & Migration Docs

**Goal**: A reader of the public guides understands exactly what 1.0 promises — the two-tier SemVer contract with its byte-output carve-out, a soft-deprecation-first lifecycle, and how to move to 1.0 — with no leaked internal milestone/phase labels and a test proving every named Tier-1 symbol actually exists
**Depends on**: Phase 78
**Requirements**: STAB-01, STAB-02, STAB-03, STAB-04, STAB-05
**Success Criteria** (what must be TRUE):

  1. `guides/api_stability.md` states the two-tier contract (Tier-1 strict SemVer; Tier-2 additive-only / adapter-tracking), the byte-output carve-out ("deterministic within a version, not frozen across versions"), and an explicit "NOT covered by SemVer" list
  2. The guide carries a written soft-deprecate-first deprecation policy (`@doc deprecated:` + CHANGELOG by default; `@deprecated` hard-warning only once no in-tree caller remains; removal only in 2.0) plus a Deprecations table
  3. `guides/upgrading_to_1.0.md` exists, is wired into `mix.exs` ExDoc `extras` under the Policies group, and a HexDocs reader can find "what 1.0 means for you" + a tier summary + a support-matrix pointer
  4. No public guide contains internal milestone/phase labels (e.g. "Rendro v1.10", "Phase 53", "Phase 71"); the string-pinned docs-contract tests (`protection_claims_test.exs` and siblings) were updated in lockstep, so `release-proof` stays green
  5. `test/docs_contract/api_stability_claims_test.exs` proves every Tier-1 symbol the guide names exists/is exported (`function_exported?` / `Code.ensure_loaded?` / struct presence) and asserts the tier headers, key promise sentences, and upgrade-guide presence

**Plans**: 4 plans
Plans:
**Wave 1** *(can run in parallel)*

- [x] 80-01-PLAN.md — api_stability.md rewrite: contract-first restructure + label scrub (D-05 lockstep: protection_claims_test.exs lines 48 & 56)
- [x] 80-02-PLAN.md — viewer_evidence.md free-prose label scrub + test title/comment hygiene (signing_claims_test.exs, viewer_evidence_claims_test.exs, embedded_artifact_claims_test.exs)

**Wave 2** *(blocked on 80-01 completion)*

- [x] 80-03-PLAN.md — Create guides/upgrading_to_1.0.md + wire into mix.exs ExDoc extras + Policies group

**Wave 3** *(blocked on 80-01 + 80-03 completion)*

- [ ] 80-04-PLAN.md — Create api_stability_claims_test.exs (STAB-05) + register lane 12 in scripts/verify_docs.exs

### Phase 81: Release Hardening

**Goal**: The release machinery is safe to fire for an irreversible 1.0 cut — version metadata is correct, the preflight refuses to ship operator/evidence artifacts and runs dependency audits, the CHANGELOG self-block is fixed, and the publish workflow's Actions are SHA-pinned
**Depends on**: Phase 78, Phase 79, Phase 80
**Requirements**: REL-01, REL-02, REL-03, REL-05
**Success Criteria** (what must be TRUE):

  1. `mix.exs` declares `@version "1.0.0"`, `docs[:source_ref]` pinned to `v1.0.0`, Changelog/Docs package links, the `{:mix_audit, ...}` dev dep, and an `elixir:` requirement matching the CI-proven matrix
  2. `mix release.preflight` passes against a dated `## [1.0.0]` CHANGELOG entry — the prior self-block (which required "Unreleased" / a hardcoded protected-delivery pointer string) is fixed so the 1.0 cut is not blocked by its own gate
  3. `mix hex.build --unpack` contains exactly the declared allowlist and none of the operator/evidence artifacts (`priv/support_matrix.json`, `priv/viewer_evidence/`, `priv/guardrails/`, `scripts/`, `test/`, `*.pem`/`*.key`/cert globs); preflight asserts both absence and required-file presence and runs `mix hex.audit` + `mix deps.audit` + a version/`source_ref` parity check
  4. `release.yml`'s publish lane (which holds `HEX_API_KEY`) has all GitHub Actions SHA-pinned, and the `v*.*.*` trigger is confirmed not to match legacy two-segment milestone tags (`v1.0`…`v2.4`)

**Plans**: TBD

### Phase 82: 1.0.0 Consolidation & Publish

**Goal**: `rendro 1.0.0` is permanently live on hex.pm — one consolidated CHANGELOG entry rolls up `0.3.0 → 1.0.0` (v2.3 + v2.4 + stability work), and the safe, proof-gated, tag-triggered publish sequence ships package + docs, cuts the GitHub Release, and is confirmed live by post-publish verification
**Depends on**: Phase 81 (all required CI lanes green)
**Requirements**: REL-04, REL-06
**Success Criteria** (what must be TRUE):

  1. A `## [1.0.0] - <date>` CHANGELOG entry consolidates `0.3.0 → 1.0.0` — the currently-stubbed "0.3.1 - Unreleased" v2.3 viewer-evidence work, the uncatalogued v2.4 batteries-included features, and the 1.0 stability/cleanup work — with a "Stability" subsection linking the upgrade guide
  2. `rendro 1.0.0` is resolvable on hex.pm (package + docs published via the tag-triggered, proof-gated pipeline following the safe publish sequence)
  3. HexDocs for 1.0.0 renders, and a tarball spot-check + version shield confirm the published artifact matches the cut
  4. A GitHub Release `v1.0.0` exists, cut from the `v1.0.0` tag

**Notes**: This is the final, IRREVERSIBLE phase. Hex `1.0.0` is permanent once the ~60-minute retirement window closes — there is no second attempt at the same version. Execute only after every required CI lane (docs-contract incl. the new public-api lane from Phase 79 + the api-stability lane from Phase 80, `signing-live-proof`, `long-lived-live-proof`, `release-proof`, `test`) is green and the Phase 81 preflight passes against the dated 1.0.0 CHANGELOG. The publish is tag-triggered and proof-gated by design; the `mix hex.publish` step is the point of no return.

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 78. Public API Surface Definition & Cleanup | v2.5 | 5/5 | Complete    | 2026-05-30 |
| 79. Public API Contract Enforcement Lane | v2.5 | 3/3 | Complete    | 2026-05-30 |
| 80. Stability Contract & Migration Docs | v2.5 | 3/4 | In Progress|  |
| 81. Release Hardening | v2.5 | 0/0 | Not started | - |
| 82. 1.0.0 Consolidation & Publish | v2.5 | 0/0 | Not started | - |

---
*v2.4 archived 2026-05-30 on milestone completion (Phases 73-77, 21 plans, 19/19 requirements, audit `passed`). v2.5 roadmap created 2026-05-30 from the approved deep-research + audit phase decomposition. Phase numbering: 78-82 (continues from v2.4's Phase 77). All 16 v2.5 requirements (API-01..05, STAB-01..05, REL-01..06) mapped to exactly one phase. Phase 82 is the irreversible 1.0.0 publish. Next: `/gsd-plan-phase 78`.*
