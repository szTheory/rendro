---
phase: 76
slug: reference-phoenix-app-ci-and-documentation-closure
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-29
---

# Phase 76 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Result: **SECURED** — 8/8 threats closed (4 accept, 4 mitigate; T-76-SC n/a gate confirmed not-required).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Hex registry → example-app build | Dependency version-floor bumps resolved from Hex | Package versions (high-trust: Phoenix/Plug/Jason) |
| HTTP client → Phoenix `:api` controller | Inbound GET requests; controllers ignore params, serve fixed demo data | Request params (discarded) |
| GitHub Actions runner → repo checkout | CI job executes repo code; no secrets injected into the example job | Repo source only |
| In-repo manifest → live branch-protection | Manifest is in-repo source of truth; live required-set reconciled externally | Required-check context names |
| Guide prose → published HexDocs | Documentation claims reach adopters; must not overstate capability | Capability claims |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-76-01 | Tampering (supply chain) | `mix.exs` dep floor bumps | accept | Floor bumps only (`phoenix ~> 1.8`, `plug ~> 1.18`, `jason ~> 1.4`, `elixir ~> 1.19`); bandit + rendro path unchanged; no new packages; mix.lock resolves above floors — `mix.exs:8,27-31` | closed |
| T-76-02 | Information Disclosure | `error_json.ex` render path | accept | `render/2` returns only `status_message_from_template(template)`; `_assigns` discarded; no stack traces/secrets/PII — `error_json.ex:4-6` | closed |
| T-76-03 | Tampering (input) | PDFController recipe actions | accept | All 6 actions bind `_params`, serve only fixed `@demo_*` fixtures; recipes still validate via `validate_data!/1` — `pdf_controller.ex:72-106` | closed |
| T-76-04 | Information Disclosure | rendered PDF responses | accept | Demo fixtures fictitious only (Acme Corp, Jane Smith); no secrets/PII — `pdf_controller.ex:19-46` | closed |
| T-76-05 | Information Disclosure | example-phoenix CI job | mitigate | Job runs only `mix deps.get && mix test`; direct grep of ci.yml for `secrets.`/`GITHUB_TOKEN`/`gh api` = 0 matches — `.github/workflows/ci.yml:31-48` | closed |
| T-76-06 | Elevation of Privilege / gate bypass | required_status_checks manifest | mitigate | `additive_only`; `example-phoenix` in `advisory_contexts` only, NOT `required_contexts`; contract test refutes it in required set + asserts 4 engine lanes unchanged (11 tests pass) — `required_status_checks.json:5,7-12,49`; `required_checks_contract_test.exs:19,41` | closed |
| T-76-07 | Spoofing / overclaim | `guides/page_primitive.md`, `guides/recipes.md` | mitigate | Semantic-claims tests assert every claim `== "supported"` vs matrix, refute out-of-matrix language (`digital signatures`, `full_pdf_compliance`), and `File.exists?` on all 4 evidence paths (38 tests pass) — `recipes_claims_test.exs`, `page_primitive_claims_test.exs` | closed |
| T-76-08 | Tampering (illustrative code) | `elixir` fences in guides | mitigate | Fence harness runs every `elixir` fence via `evaluate!/2`, refutes `...`/`%{...}` placeholders; `elixir-schematic` skipped; harness requires docs-contract id — `recipes_contract_test.exs:6-18` | closed |
| T-76-SC | Tampering | npm/pip/cargo installs | n/a | No package-manager installs; Hex-only floor bumps, no new packages; gate not required | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-76-01 | T-76-01 | Hex floor bumps to already-locked high-trust packages (Phoenix/Plug/Jason/Elixir); mix.lock resolves above floors; no new transitive deps | szTheory | 2026-05-29 |
| AR-76-02 | T-76-02 | Reference-app error bodies emit only generic Phoenix status messages | szTheory | 2026-05-29 |
| AR-76-03 | T-76-03 | Reference-app controllers ignore request params and serve fixed demo fixtures | szTheory | 2026-05-29 |
| AR-76-04 | T-76-04 | Demo PDFs contain only fictitious fixture data | szTheory | 2026-05-29 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-29 | 8 | 8 | 0 | gsd-security-auditor |

---

## Audit Notes (advisory, non-blocking)

- **T-76-05 wording nuance:** The fork-safe contract block (`required_checks_contract_test.exs:136-145`) refutes token/`gh api` references against `__ENV__.file` (the test's own source), not `@ci_path`. The Information-Disclosure threat is still CLOSED — the `example-phoenix` job has no secret-bearing steps and a direct grep of ci.yml returns zero secret references. Recommended follow-up: add `refute File.read!(@ci_path) =~ "GITHUB_TOKEN"` to regression-lock ci.yml itself.
- **"Digital signatures" in `guides/page_primitive.md:88`** appears inside a "Scope boundaries — does **not** support" disclaimer (a negative claim). The T-76-07 refute matches lowercase `digital signatures`; the disclaimer is capitalized, so the test correctly passes. Not a gap.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-29
