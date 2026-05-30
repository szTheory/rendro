# Requirements: Rendro — v2.5 1.0 Release Capstone

**Defined:** 2026-05-30
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

> Scope confirmed 2026-05-30 via parallel research + live-codebase audit (3 Explore + 3 Plan subagents, grounded in `prompts/` research). Decisions locked: **publish a single consolidated `1.0.0` to hex.pm** (last published is `0.3.0`; v2.3 + v2.4 are both unreleased), **cleanup first** (audit found ~zero real breaking changes, so no intermediate `0.4.0`), **formal stability tags** (a checked-in tiered manifest enforced by a docs-contract lane). "public ≡ what ExDoc renders." Two user-facing tiers: Tier 1 Stable (strict SemVer core) / Tier 2 Evolving (adapters + diagnostics/metadata map contents, additive-only). Soft-deprecation-first because `mix ci` compiles `--warnings-as-errors`. release-please deferred. Implementable with one new dev dep (`:mix_audit`); no new runtime deps. Build order: define+clean the surface → enforce it → stability docs → release hardening → publish.

## v1 Requirements

Requirements for the v2.5 milestone. Each maps to exactly one roadmap phase.

### Public API Surface, Cleanup & Enforcement (API)

- [x] **API-01**: Public API surface is formally defined in a checked-in manifest `priv/public_api.json` (schema-versioned like `support_matrix.json`), with every documented module/function assigned a tier (`stable` | `adapter`).
- [x] **API-02**: Accidentally-public internals are hidden — `@moduledoc false` on `Rendro.PDF.CidFont` + `Rendro.PDF.FontSubsetter` (confirmed leaking); `@doc false` on the `Rendro.Sign`/`Rendro.Protect` `redact_*` helpers; a full sweep of all currently-public `lib/` modules so each lands in the manifest or is hidden.
- [x] **API-03**: Returned/accepted types of public functions are themselves documented — expose `Rendro.Metadata` with a real `@moduledoc` + `@type t` (it is the return type of public `Rendro.metadata/1`), and fix any other invisible-type gaps surfaced by the sweep.
- [x] **API-04**: A docs-contract lane (`test/docs_contract/public_api_contract_test.exs`) introspects `Code.fetch_docs/1` and asserts the documented surface exactly equals the manifest (drift fails CI with an errors-as-product diff), asserts known internals are `:hidden`, asserts Tier-1 `@spec` coverage, and asserts every public module carries exactly one tier tag — wired into `priv/guardrails/required_status_checks.json`.
- [x] **API-05**: ExDoc renders a per-module stability badge (Stable / Adapter) from `@moduledoc` metadata, and recipe `sections/2` opts handling is normalized across all five recipes (invoice/branded currently ignore `_opts`; normalization is additive).

### Stability Contract, Deprecation Policy & Migration Docs (STAB)

- [ ] **STAB-01**: `guides/api_stability.md` rewritten with the formal two-tier SemVer contract — Tier-1 strict SemVer; Tier-2 additive-only / adapter-tracking; the byte-output carve-out ("deterministic within a version, not frozen across versions"); and an explicit "NOT covered by SemVer" list.
- [ ] **STAB-02**: A written deprecation policy (soft-deprecate-first lifecycle; `@doc deprecated:` + CHANGELOG by default, `@deprecated` hard-warning only once no in-tree caller remains, removal only in 2.0) plus a Deprecations table is added to the guide.
- [ ] **STAB-03**: `guides/upgrading_to_1.0.md` migration note created ("what 1.0 means for you" + tier summary + support-matrix pointer + any residual notes), added to `mix.exs` ExDoc `extras` and the Policies group.
- [ ] **STAB-04**: Internal milestone/phase labels are scrubbed from public guides (`api_stability.md` "Rendro v1.10", "Phase 53", "Phase 71" refs), with their string-pinned docs-contract tests (`protection_claims_test.exs` and siblings) updated in lockstep so `release-proof` stays green.
- [ ] **STAB-05**: A docs-contract test (`test/docs_contract/api_stability_claims_test.exs`) proves every Tier-1 symbol the guide names exists/is exported (`function_exported?` / `Code.ensure_loaded?` / struct presence) and asserts the tier headers, key promise sentences, and upgrade-guide presence.

### Release Hardening & 1.0.0 Publish (REL)

- [ ] **REL-01**: `mix.exs` bumped to `@version "1.0.0"`, `docs[:source_ref]` pinned to `v1.0.0`, `Changelog`/`Docs` package links added, `{:mix_audit, ...}` dev dep added, and the declared `elixir:` requirement matches the CI-proven matrix.
- [ ] **REL-02**: Preflight hardened with an exact-allowlist tarball content audit — asserts operator/evidence artifacts are **absent** (`priv/support_matrix.json`, `priv/viewer_evidence/`, `priv/guardrails/`, `scripts/`, `test/`, `*.pem`/`*.key`/cert globs) and required files present — plus `mix hex.audit` + `mix deps.audit` and a version/`source_ref` parity check.
- [ ] **REL-03**: The preflight CHANGELOG gate is generalized to accept a **dated** `## [1.0.0]` (regex `\d{4}-\d{2}-\d{2}`, not "Unreleased") and the brittle hardcoded protected-delivery pointer string is dropped — fixing the self-block that would otherwise block the 1.0 cut.
- [ ] **REL-04**: A CHANGELOG `## [1.0.0] - <date>` entry consolidates `0.3.0 → 1.0.0` (v2.3 viewer evidence currently stubbed under "0.3.1 - Unreleased" + the uncatalogued v2.4 batteries-included features + the 1.0 stability/cleanup work), with a "Stability" subsection linking the upgrade guide.
- [ ] **REL-05**: GitHub Actions on `release.yml`'s publish lane are SHA-pinned (the lane holds `HEX_API_KEY`), and the `v*.*.*` trigger is confirmed not to match legacy two-segment milestone tags (`v1.0`…`v2.4`).
- [ ] **REL-06**: `1.0.0` is published to hex.pm (package + docs) via the tag-triggered, proof-gated pipeline following the safe publish sequence; a GitHub Release is cut from `v1.0.0`; and post-publish verification confirms HexDocs render, version shield, and a tarball spot-check.

## v2 Requirements

Deferred to future release. Tracked but not in the current roadmap.

### Globalization (conditional v2.6)

- **GLOBAL-01**: Global text shaping, RTL support, and broader complex-script coverage — only if adopter demand justifies the core investment.

### Release automation (post-1.0)

- **AUTO-01**: Adopt release-please (conventional-commit-driven changelog + tag) for the 1.x train, if commit hygiene warrants — deferred from this milestone to avoid churn on the irreversible 1.0 cut and tag-scheme collisions with legacy milestone tags.

## Out of Scope

Explicitly excluded for v2.5. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Intermediate `0.4.0` feature release before 1.0 | Cleanup audit found ~zero real breaking changes; a single consolidated `1.0.0` is cleaner. |
| `1.0.0-rc.1` soak release | Project's existing proof gates (docs-contract, live-proof, release-proof) already de-risk the cut; user chose single consolidation. |
| Splitting into separate `rendro` / `rendro_adapters` hex packages | Large restructure during a stability milestone; tier differentiation achieved via documented tiers, not package surgery. Revisit only if adapter churn proves painful. |
| release-please / conventional-commits pipeline | Conflicts with hand-curated narrative CHANGELOG that preflight asserts; collides with legacy `v1.0`-style tags; adds a moving part to an irreversible event. Deferred (AUTO-01). |
| Retrofitting `@doc since:` across the existing 0.x surface | Would misstate history (0.x funcs didn't ship in 1.0) and burn freeze time for zero enforcement value; adopt going-forward only. |
| Byte-for-byte output stability across versions | A deterministic engine can't freeze rendered bytes across versions without blocking every layout/shaping fix; output is stable *within* a version (carve-out documented in STAB-01). |
| New rendering surfaces / features (TOC, charts, borders, duplex headers) | Held in PROJECT.md Deferred Items; 1.0 is a stability/promise milestone, not a feature milestone. |

## Traceability

Which phases cover which requirements. All 16 v1 requirements mapped — each to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| API-01 | Phase 78 | Complete |
| API-02 | Phase 78 | Complete |
| API-03 | Phase 78 | Complete |
| API-04 | Phase 79 | Complete |
| API-05 | Phase 78 | Complete |
| STAB-01 | Phase 80 | Pending |
| STAB-02 | Phase 80 | Pending |
| STAB-03 | Phase 80 | Pending |
| STAB-04 | Phase 80 | Pending |
| STAB-05 | Phase 80 | Pending |
| REL-01 | Phase 81 | Pending |
| REL-02 | Phase 81 | Pending |
| REL-03 | Phase 81 | Pending |
| REL-04 | Phase 82 | Pending |
| REL-05 | Phase 81 | Pending |
| REL-06 | Phase 82 | Pending |
