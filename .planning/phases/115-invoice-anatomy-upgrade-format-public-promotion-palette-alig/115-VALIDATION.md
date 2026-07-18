---
phase: 115
slug: invoice-anatomy-upgrade-format-public-promotion-palette-align-seams
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-18
---

# Phase 115 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Authored from `115-RESEARCH.md § Validation Architecture` (the authoritative source).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (stdlib), `async: true` throughout `test/rendro/recipes/` |
| **Config file** | none dedicated — `mix test` / `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/recipes/invoice_test.exs test/rendro/format_test.exs` |
| **Full suite command** | `mix test` (or scoped `mix ci.fast` per C1 aliases) |
| **Estimated runtime** | ~quick: <10s scoped · full: project suite |

---

## Sampling Rate

- **After every task commit:** `mix test test/rendro/recipes/invoice_test.exs test/rendro/format_test.exs`
- **After every plan wave:** `mix test test/rendro/ test/docs_contract/public_api_contract_test.exs`
- **Before `/gsd-verify-work`:** full `mix test` must be green
- **Max feedback latency:** ~10 seconds (scoped) between task commits

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 115-01 (toy golden) | 01 | 1 | INV-01 | — | N/A (baseline capture) | golden | `mix test test/rendro/recipes/invoice_byte_identity_test.exs` | ❌ W0 (created here) | ⬜ pending |
| 115-01 (table golden) | 01 | 1 | INV-05 | — | N/A (baseline capture) | golden | `mix test test/rendro/table_byte_identity_test.exs` | ❌ W0 (created here) | ⬜ pending |
| 115-02 T1 | 02 | 2 | INV-04 | T-115-02-01 | Adapter surface capped to money/1,date/1,label/1 + "output may evolve" caveat | unit/doctest | `mix test test/rendro/format_test.exs` | ✅ exists | ⬜ pending |
| 115-02 T2 | 02 | 2 | INV-04 | T-115-02-02/03 | Manifest regenerated not hand-edited; no partial promotion merges green | contract | `mix rendro.api.gen && git diff --exit-code priv/public_api.json; mix test test/docs_contract/public_api_contract_test.exs` | ✅ exists (red→green) | ⬜ pending |
| 115-03 T1 (spike) | 03 | 2 | INV-05 | — | Offset gated strictly on `:right`; default output byte-identical | determinism | `mix test test/rendro/table_byte_identity_test.exs` | ❌ W0 (from 01) | ⬜ pending |
| 115-03 T2 | 03 | 2 | INV-05 | — | `cell_align` inert struct field + `table/2` option; no new public function | unit + determinism | `mix test test/rendro/table_test.exs test/docs_contract/public_api_contract_test.exs` | ⚠️ extend/new | ⬜ pending |
| 115-04 T1 | 04 | 3 | INV-06, INV-07 | input validation | `validate_data!/1` instructive `ArgumentError`, no `BadMapError`/`FunctionClauseError` leak; never rejects toy call; `page_template/1` `Keyword.take` whitelist | unit | `mix test test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_opts_threading_test.exs` | ✅ extend | ⬜ pending |
| 115-04 T2 | 04 | 3 | INV-01, INV-02 | Decimal/Float | Decimal-only new money fields route via `Format.money/1`; bare `price` stays `"$#{price}"`; Float rejected instructively | unit + golden | `mix test test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_byte_identity_test.exs` | ✅ extend | ⬜ pending |
| 115-04 T3 | 04 | 3 | INV-03 | totals integrity | `:totals` renders only when supplied; `Decimal.equal?/2` caller assertion; kept with last table rows | unit + pagination | `mix test test/rendro/recipes/invoice_test.exs` | ✅ extend (mirror `receipt_test.exs`) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/recipes/invoice_byte_identity_test.exs` — record + assert sha256 golden of pre-upgrade toy render (INV-01)
- [ ] `cell_align` alignment + no-op byte-identity test — `test/rendro/table_byte_identity_test.exs` (extend `test/rendro/table_test.exs` if present, else new file) (INV-05)
- [ ] Confirm a `Format` public-doc example/doctest is added so HexDocs shows the adapter surface (INV-04)

*Totals, validation, and opts-threading gaps are covered by extending existing `invoice_test.exs` /
`invoice_opts_threading_test.exs` — no new infra needed; mirror `receipt_test.exs` / `statement.ex`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rendered adapter surface appears correctly in HexDocs | INV-04 | HexDocs HTML output is not asserted in the suite | After `mix docs`, confirm `Rendro.Format` renders with `money/1`/`date/1`/`label/1` and the "output may evolve" caveat |

---

## Security Validation (ASVS L1)

Applicable ASVS category: **V5 Input Validation** (all others N/A — pure library, no auth/session/access/crypto/network surface).

| Threat | Requirement | Automated Check |
|--------|-------------|-----------------|
| Malformed caller data crashing the recipe / leaking `BadMapError`/`FunctionClauseError` | INV-06 | `invoice_test.exs` asserts `ArgumentError` with instructive message on malformed input |
| Float money producing silently-wrong output | INV-02 | `invoice_test.exs` asserts Float money fields raise instructively; Decimal-only accepted |
| Totals assertion tampering | INV-03 | `invoice_test.exs` asserts `Decimal.equal?/2` caller-assertion failure path |
| Public-API over-exposure (Format freeze) | INV-04 | `public_api_contract_test.exs` byte-equality + hidden-set assertions |

---

*Validation contract authored 2026-07-18 from `115-RESEARCH.md § Validation Architecture`.*
*`wave_0_complete` flips to `true` once the two Wave-0 golden test files exist and are green.*
