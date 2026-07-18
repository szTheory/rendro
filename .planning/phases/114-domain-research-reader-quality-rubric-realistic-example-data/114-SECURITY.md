---
phase: 114
slug: domain-research-reader-quality-rubric-realistic-example-data
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-18
---

# Phase 114 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Register origin: authored at plan time (all 7 PLAN.md files carried a parseable
`<threat_model>` block). ASVS L1, `security_block_on: high`. No open threats at
or above the blocking threshold. L1 grep-depth verification per the secure-phase
short-circuit rule (`threats_open: 0 AND register_authored_at_plan_time: true AND
asvs_level == 1`); no auditor pass required.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Repo-controlled shell/git operations | `git mv`, `mix rendro.comparison.check`, `mix run` operate only on committed repo files; no network or attacker-controlled input crosses. | Repo-authored fixtures/scripts (non-sensitive) |
| `:dev`/`:test` schema-validation tooling | `JSV.build!/1` / `JSON.decode!` parse repo-authored, version-controlled schema + fixture files only, at CI/test time. | Repo-authored JSON (non-sensitive) |
| `Rendro.Examples.load!/1` / `list/1` argument | The only place a string parameter is joined into a filesystem path before a read. `@moduledoc false`; every current caller passes a hardcoded literal. | String path segment (internal, hardcoded) |
| Hex package build/publish boundary | `mix.exs` `package/0` `:files` list is the sole gate on what a downstream Hex consumer receives; `priv/schemas/`, `priv/quality/`, and non-`.json`/`.md`/`.svg` files under `priv/examples/` must never cross. | Published tarball contents (public) |
| Documentation / appendable manifest | `DOMAIN.md` (pure prose) and `priv/quality/rubric_scores.json` (schema-gated appendable) are read/validated only by the repo test suite; never runtime-writable by a shipped consumer. | Repo-authored docs/manifest (non-sensitive) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-114-01-01 | Tampering | `git mv` + bench-script path repoint | low | accept | Pure rename verified byte-identical via sha256 diff vs last-committed blob; no attacker input. | closed |
| T-114-01-02 | Information Disclosure | `comparison.json` `scenario.fixture` free-text | low | accept | Documentation-only string; never re-read/executed by hash verification. | closed |
| T-114-02-01 | Tampering | `priv/schemas/*.json` via `JSON.decode!`/`JSV.build!` | low | accept | Repo-authored, version-controlled; never fed attacker input (repo fixtures/manifest only). | closed |
| T-114-02-02 | Information Disclosure | `priv/schemas/` accidentally shipping in Hex tarball | medium | mitigate | Absent from `mix.exs` `:files` (verified — allowlist adds `priv/examples` only, line 118); `branding_claims_test.exs:69-70` refutes both schema files from tarball listing. | closed |
| T-114-03-01 | Tampering | `JSON.decode!` of normalized fixture at test/bench time | low | accept | Repo-authored fictional data, schema-validated at CI; never user-uploaded / attacker-path. | closed |
| T-114-03-02 | Information Disclosure | Fictional business/address data in fixture | low | accept | All names/addresses explicitly fictional per milestone no-real-PII guard. | closed |
| T-114-04-01 | Tampering / Information Disclosure | `Rendro.Examples.load!/1` `relative_path` param | medium | mitigate | `Path.safe_relative/1` guard resolves under `Application.app_dir(:rendro, "priv/examples")`, raising `ArgumentError` on `../` escape before `File.read!` (verified `lib/rendro/examples.ex:42-47`; traversal spot-check rejected in VERIFICATION). | closed |
| T-114-04-02 | Tampering | `Rendro.Examples.list/1` `domain` → `Path.wildcard/1` pattern | low | mitigate | Same `Path.safe_relative/1` guard applied to `domain` before wildcard build (verified `lib/rendro/examples.ex:27,42`). | closed |
| T-114-04-03 | Information Disclosure | `Rendro.Examples` module visibility | low | accept | `@moduledoc false`; asserted `:hidden` in `public_api_contract_test.exs`, absent from `api.gen.ex @public_modules` and `priv/public_api.json`. | closed |
| T-114-05-01 | Information Disclosure | `DOMAIN.md` domain-research prose | low | accept | Pure documentation; generic domain/persona descriptions, no real business/personal data. | closed |
| T-114-05-02 | Tampering | `domain_md_contract_test.exs` substring assertions | low | accept | Read-only structural check on repo-controlled markdown; no write path, no external input. | closed |
| T-114-06-01 | Tampering | `priv/quality/rubric_scores.json` appendable manifest | low | accept | Repo-controlled, schema-validated; not runtime-writable; Phase 118 appends via identical schema gate. | closed |
| T-114-06-02 | Repudiation | Threshold-arithmetic logic exists only as test helper | low | accept | Intentional per phase boundary ("no `lib/` product change except the loader"); no runtime code path depends on it. | closed |
| T-114-07-01 | Information Disclosure | `priv/schemas/*` + `priv/quality/` shipping in Hex tarball | medium | mitigate | `branding_claims_test.exs:69-71` refutes both schemas and `priv/quality/` from built tarball listing; `mix.exs` `:files` adds `priv/examples` only. | closed |
| T-114-07-02 | Tampering | `priv/examples/` shipping a non-text (raster/binary) asset | medium | mitigate | `.gitignore:70-79` bans 11 raster/binary extensions under `priv/examples/**`; tarball text-only assertion re-verifies every shipped entry's extension (defense against `git add -f`). | closed |
| T-114-07-03 | Information Disclosure | `mix hex.build` via `Rendro.Test.HexBuildCache` (shells out to `mix`) | low | accept | Existing, already-relied-upon shared test infrastructure; reuse introduces no new attack surface. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-114-01 | T-114-01-01, T-114-01-02 | Repo-controlled git/bench operations; no attacker input crosses the boundary. | Claude (gsd-security-auditor, short-circuit L1) | 2026-07-18 |
| R-114-02 | T-114-02-01 | Repo-authored, version-controlled schema files; only ever validate the repo's own checked-in inputs at CI/test time. | Claude (gsd-security-auditor, short-circuit L1) | 2026-07-18 |
| R-114-03 | T-114-03-01, T-114-03-02 | Repo-authored fictional fixture data, schema-validated at CI; no real PII, never an attacker-controlled runtime path. | Claude (gsd-security-auditor, short-circuit L1) | 2026-07-18 |
| R-114-04 | T-114-04-03 | Loader is `@moduledoc false` and asserted `:hidden`; not part of the public API surface. | Claude (gsd-security-auditor, short-circuit L1) | 2026-07-18 |
| R-114-05 | T-114-05-01, T-114-05-02 | Documentation-only prose + read-only structural test on repo-controlled markdown. | Claude (gsd-security-auditor, short-circuit L1) | 2026-07-18 |
| R-114-06 | T-114-06-01, T-114-06-02 | Repo-controlled schema-gated manifest; threshold logic is test-only per the phase boundary — no runtime surface. | Claude (gsd-security-auditor, short-circuit L1) | 2026-07-18 |
| R-114-07 | T-114-07-03 | Reuses existing shared `HexBuildCache` test infrastructure; no new attack surface. | Claude (gsd-security-auditor, short-circuit L1) | 2026-07-18 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-18 | 16 | 16 | 0 | Claude (gsd-security-auditor, short-circuit L1 grep-depth) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-18
