---
phase: 78
phase_slug: public-api-surface-definition-cleanup
created: 2026-05-30
status: draft
---

# Phase 78 Validation Strategy

**Phase:** public-api-surface-definition-cleanup
**Created:** 2026-05-30
**Status:** Draft — created during planning, completed during execution

> Nyquist validation strategy: defines WHAT to validate and HOW, derived from RESEARCH.md's
> "Validation Architecture" section. Executors fill in actual test results during execution.
>
> Scope note: Phase 78 **defines and cleans** the surface. Enforcement (drift-fails-CI
> introspection-vs-manifest contract test) is **Phase 79** and is deliberately out of scope
> here — only the shared introspection module + generator are built now so 79 can reuse them.

---

## Validation Dimensions

| Capability | Validation Method | Tooling | Pass Threshold | Status |
|------------|-------------------|---------|----------------|--------|
| `priv/public_api.json` validates against `public_api.schema.json` | integration | ExUnit + `JSV.validate/2` (mirror `viewer_evidence/validator_test.exs`) | `JSV.validate` returns `:ok` | ⬜ Pending |
| `mix rendro.api.gen` is idempotent / deterministic | integration | ExUnit golden test — run generator twice, assert byte-identical output | identical bytes both runs; matches checked-in `public_api.json` | ⬜ Pending |
| `Rendro.Metadata` is no longer an invisible type | integration | `Code.fetch_docs(Rendro.Metadata)` assertion | `module_doc != :hidden` AND `@type t` present | ⬜ Pending |
| Hidden modules absent from manifest & HexDocs | integration | introspection assertion over swept modules | `CidFont`, `FontSubsetter`, `Bidi`, `Shaper`, `Format`, `Audit` → `module_doc == :hidden` and NOT in manifest | ⬜ Pending |
| `redact_*` helpers hidden | unit | `Code.fetch_docs` per-function assertion | `Sign.redact_*` + `Protect.redact_opts/2` doc == `:hidden` | ⬜ Pending |
| Every manifested module carries exactly one tier | integration | introspection assertion (`tags` ∈ {`:stable`,`:adapter`}) | no `:untagged` public module; foundation for P79 | ⬜ Pending |
| Stable/Adapter badge renders in ExDoc | manual + build | `mix docs` + visual check of rendered `.note` span + injected CSS/JS | badge visible, stable=green / adapter=blue | ⬜ Pending |
| Recipe `sections/2` opts normalized, output byte-identical | integration | snapshot test — render Invoice & BrandedInvoice before/after with default opts | rendered bytes unchanged vs baseline (D-11) | ⬜ Pending |
| Conditional adapters present during generation | integration | generator recompiles adapters (mirror `AdapterReloader.recompile/0`) OR runs `MIX_ENV=test` | Phoenix/Oban/Threadline/Mailglass/Accrue appear in introspection | ⬜ Pending |
| `mix ci` clean (`--warnings-as-errors`) | build | `mix ci` | exit 0, no new warnings (arity-2 helper unused opts named `_opts`) | ⬜ Pending |

---

## Test Architecture

- **Unit tests:** `Code.fetch_docs/1` shape assertions on individual swept modules/functions (hidden vs documented); `Rendro.PublicApi.tier_of/1` extraction logic.
- **Integration tests:** manifest ↔ schema validation via JSV; generator idempotency golden test; full-surface tier-coverage introspection (with conditional adapters recompiled); recipe render snapshots before/after the opts thread-through.
- **E2E tests:** none required — this is a library-internal/docs phase, no runtime user flow.
- **Manual verification:** `mix docs` rendered output — confirm Stable/Adapter badges appear and are colored per D-14 (badge CSS targeting carried MEDIUM research confidence; the JS approach must be eyeballed in real HexDocs output).

---

## Coverage Targets

| Component | Target | Rationale |
|-----------|--------|-----------|
| `Rendro.PublicApi` introspection module | High (every public fn) | It is the single source feeding both the P78 generator and the P79 contract test — must not silently miss modules. |
| `mix rendro.api.gen` generator | Idempotency + schema-valid output | Drift treadmill risk (D-15): generator and future test must never disagree; deterministic output is the contract. |
| Recipe opts threading | Byte-identical snapshot | Additive guarantee (D-11) — zero behavioral change to existing callers. |
| Hiding sweep | 100% of swept targets asserted hidden | Success criteria 1 demands every currently-public `lib/` module either lands in the manifest or is hidden. |

---

## Validation Architecture (from RESEARCH.md)

### Testable NOW (Phase 78)
- Manifest validates against schema (`JSV.validate`, mirror viewer_evidence validator test).
- Generator output idempotent/stable (run twice, assert identical bytes — golden test).
- `Rendro.Metadata` renders (`Code.fetch_docs` module_doc != `:hidden`).
- Recipe opts byte-identical (snapshot Invoice/BrandedInvoice render before/after).
- Every public module has a tier tag (introspect all, assert tags present — foundation for P79).
- Hidden modules absent from manifest (assert `CidFont` etc. not in manifest).

### Deferred to Phase 79 (enforcement)
- Introspection-vs-manifest exact-equality contract test.
- Tier-1 `@spec` coverage assertion.
- Two-sided drift diff (in-code-not-manifest / manifest-not-in-code).

### Patterns to mirror in `test/`
- `test/rendro/viewer_evidence/validator_test.exs` — JSV validation testing.
- recipe snapshot tests — byte-identical output verification.
- `test/docs_contract/` — does not exist yet; Phase 79 creates it. P78 introspection tests can live under `test/rendro/public_api/`.

---

## Open Questions

1. Generator env strategy: inline-recompile conditional adapters vs `MIX_ENV=test` (research recommends inline-recompile mirroring `AdapterReloader`).
2. Whether the manifest carries a `conditional: true` marker on adapter entries, or handles conditional presence silently.

## Notes

- **Correction to RESEARCH.md:** there are **no existing custom mix tasks** in the repo (`lib/mix/tasks/` does not exist; no `use Mix.Task` anywhere in `lib/`). `mix rendro.api.gen` is greenfield — use standard `Mix.Task` boilerplate, no in-repo task analog to mirror.

*Source: RESEARCH.md Validation Architecture section*
