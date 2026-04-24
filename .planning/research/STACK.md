# Stack Research

**Domain:** Elixir-native PDF/document generation library (Phoenix-first, pure core)
**Researched:** 2026-04-24
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir + OTP | 1.19.5 + OTP 28 | Core runtime for rendering engine | Current stable baseline for BEAM performance, tooling, and library compatibility. |
| Phoenix (adapter) | 1.8.5 | Optional web integration (download/preview) | Mature Phoenix integration path for Rendro persona #1 without coupling core to web stack. |
| Telemetry | 1.4.1 | Instrument render lifecycle | Standard observability contract across Elixir ecosystem; enables production trust and diagnostics. |
| Oban (adapter) | 2.21.1 | Optional background render orchestration | Standard resilient job processing for large PDF workloads and retries at scale. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| stream_data | 1.3.0 | Property testing for rendering/pagination invariants | Required for deterministic and structural guarantees in core engine. |
| credo | 1.7.17 | Static linting/code consistency | Use in merge-blocking CI verification lane. |
| dialyxir | 1.4.7 | Static analysis and type-consistency checks | Use for pre-release hardening and reliability-sensitive modules. |
| ex_doc | 0.40.1 | Public docs generation | Required for docs-contract workflow and release trust posture. |
| qpdf + veraPDF + MuPDF (`mutool`) | current stable (tooling-managed) | Structural validation, conformance checks, visual rendering/diff | Use in advisory or release preflight validation lanes. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| GitHub Actions | CI verification and release workflows | Pin release-critical action SHAs and separate deterministic vs advisory jobs. |
| mix aliases (`mix ci`, `mix verify.*`) | Canonical quality gates | Keep one explicit merge authority; make optional lanes clearly labeled. |
| Example host app (`examples/rendro_phoenix`) | Executable adoption proof | Run in CI to ensure docs and onboarding paths remain truthful. |

## Installation

```bash
# Core app (future mix.exs target)
mix deps.get

# Typical development tooling dependencies
mix deps.add telemetry
mix deps.add --dev ex_doc credo dialyxir stream_data

# Optional adapters (when enabled by package split)
mix deps.add phoenix oban
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Pure-Elixir render core | Chrome/Chromium (`chromic_pdf`) | If a team needs full HTML/CSS rendering fidelity over deterministic native-layout behavior. |
| Native document AST + layout pipeline | Typst template execution | If team prioritizes Typst authoring UX and can accept adapter/runtime constraints. |
| Optional adapters with compile/runtime guards | Hard-coupled Phoenix/Oban dependencies in core | Only for internal/private app code where library reuse and package boundaries are irrelevant. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Browser runtime as core rendering dependency | Expands runtime attack surface and deployment complexity; breaks pure-core requirement | Native Elixir renderer core; keep browser path as optional adapter only |
| Implicit optional dependencies | Causes compile leakage and hidden coupling in OSS packages | `optional: true` dependencies plus explicit guards and isolated adapters |
| Unverified compliance/signature claims in docs | Erodes trust and creates legal/operational risk | Validator-backed claims with explicit support matrix and tests |

## Stack Patterns by Variant

**If building pure library core milestones:**
- Prioritize Elixir/OTP + telemetry + StreamData + deterministic fixtures.
- Keep Phoenix/Oban/admin surfaces out of core compile paths.

**If building adoption-focused integration milestones:**
- Add Phoenix/Oban adapters as separate packages/modules.
- Require end-to-end example app verification in CI before release.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Elixir 1.19.5 | OTP 28 | Recommended baseline for new project initialization. |
| Phoenix 1.8.5 | Elixir 1.14+ / OTP 25+ | Satisfies current Elixir baseline and adapter needs. |
| Oban 2.21.1 | Modern PostgreSQL/SQLite/MySQL | Keep as optional adapter dependency, not core runtime requirement. |
| Telemetry 1.4.1 | Broad ecosystem dependents | Safe default for lifecycle instrumentation. |

## Sources

- [Elixir current version](https://elixir.current-version.com/) — runtime baseline verification
- [Phoenix versions on Hex](https://hex.pm/packages/phoenix/versions) — Phoenix adapter version verification
- [Oban versions on Hex](https://hex.pm/packages/oban/versions) — job adapter version verification
- [Telemetry versions on Hex](https://hex.pm/packages/telemetry/versions) — observability dependency verification
- [ExDoc versions on Hex](https://hex.pm/packages/ex_doc/versions) — documentation tooling verification
- [Credo versions on Hex](https://hex.pm/packages/credo/versions) — lint tooling verification
- [Dialyxir versions on Hex](https://hex.pm/packages/dialyxir/versions) — static analysis tooling verification
- [StreamData versions on Hex](https://hex.pm/packages/stream_data/versions) — property test tooling verification
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — domain architecture and product constraints
- `prompts/rendro-oss-dna.md` — proven CI/release/process defaults from related Elixir OSS projects

---
*Stack research for: Elixir-native PDF generation*
*Researched: 2026-04-24*
