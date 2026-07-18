---
phase: 116
slug: new-families-payslip-ticket
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-18
---

# Phase 116 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 116-RESEARCH.md `## Validation Architecture`. Both new recipes are
> pure Elixir functions — every behavior below is automatable with ExUnit; there is
> no manual/visual-only gate at the code contract level (visual rubric grading is
> Phase 118's job, not this phase's verification).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` (already present) |
| **Quick run command** | `mix test test/rendro/recipes/payslip_test.exs test/rendro/recipes/ticket_test.exs` |
| **Full suite command** | `mix test` |
| **Docs-contract lane** | `mix test test/docs_contract/` (public_api / examples_schema / recipes / rubric_manifest contracts) |
| **Estimated runtime** | quick ~2–5s · full suite ~30–90s |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the recipe under change.
- **After every plan wave:** Run `mix test` (full suite) — recipe + docs-contract lanes must be green.
- **After any registration change** (`priv/public_api.json`, `priv/support_matrix.json`, `@public_modules` allowlist, `priv/schemas/examples.schema.json`): Run `mix test test/docs_contract/` — the byte-comparing contract lanes catch un-regenerated manifests.
- **Before `/gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** < 90 seconds (full suite).

---

## Sampling Strategy (Nyquist — from RESEARCH `## Validation Architecture`)

Sample the data-contract edges, not just the happy path. Minimum coverage per recipe:

| Invariant | Edge to sample | Expected signal | Test type |
|-----------|----------------|-----------------|-----------|
| Money is `Decimal`, never Float | earnings/deductions/net_pay supplied as Float | instructive `ArgumentError` (four-part), no `ArithmeticError`/`BadMapError` leak | unit |
| Reconciliation holds | `net_pay ≠ gross − Σdeductions` | `ArgumentError` naming the mismatch (via `Decimal.equal?/2`, never `==`) | unit |
| PII masking present | fixture rendered | no raw SSN/NI/bank number bytes in fixture data; ids masked `··· 4321`, fictional employer/employee | unit (byte assertion on fixture) |
| Overflow → typed error | pathological un-splittable / over-region content | pipeline surfaces typed `:content_overflow`, never truncates silently | unit |
| Bad image → instructive error | `data.code.image` = non-PNG / corrupt bytes | `ArgumentError` naming `data.code.image` (via pure `ImageParser.parse/1` in `validate_data!`), NOT a leaked `InvalidAssetError` | unit |
| Oversized image → no error | very large valid PNG | renders; fit-contain scales down deterministically | unit |
| Missing/blank required field | blank `reference` / missing `net_pay` / empty `earnings` | four-part `ArgumentError` | unit |
| Opts-shape validation (D-19) | `:labels` non-map / non-binary values; `:formatters` non-keyword / non-arity-1 | four-part `ArgumentError` via `Pagination.type_name/1`, never `BadMapError`/`BadArityError` | unit |
| Palette seam (S1) | grep recipe source | no inlined `{0,0,0}` / raw `{r,g,b}`; every color reads a role from `palette(opts)` | source assertion |
| `label_resolver` additive | Statement's existing arity-1 call | Statement tests still green after arity-2 generalization | regression |
| Byte-stability | default-opts render twice | byte-identical output (determinism); `image: nil` path byte-identical to no-image path | unit (byte-identity, à la `invoice_byte_identity_test.exs`) |
| Registration proof | `priv/public_api.json` + `priv/support_matrix.json` | docs-contract lane passes after `mix rendro.api.gen`; support-matrix rows proof-backed | contract |

---

## Per-Task Verification Map

*Populated by the planner from PLAN.md tasks. Every task maps to at least one ExUnit command above.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 116-01-01 | 01 | 1 | FAM-03 | — | `label_resolver/2` additive; Statement arity-1 call sites unaffected | unit + regression | `mix test test/rendro/recipes/pagination_test.exs test/rendro/recipes/statement_test.exs` | ❌ W0 | ⬜ pending |
| 116-01-02 | 01 | 1 | FAM-03 | T-116-01-* | D-19 `:labels`/`:formatters` opts-shape validators → four-part ArgumentError, no BadMapError/BadArityError/FunctionClauseError leak | unit | `mix test test/rendro/recipes/pagination_test.exs` | ❌ W0 | ⬜ pending |
| 116-02-01 | 02 | 2 | FAM-01, FAM-03 | T-116-02-01/03 | `validate_data!/1` shape/type checks; Float money → ArgumentError; **PII masking test-enforced** (D-14 regex assertions) | unit | `mix test test/rendro/recipes/payslip_test.exs` | ❌ W0 | ⬜ pending |
| 116-02-02 | 02 | 2 | FAM-01, FAM-03 | — | net-pay anchor is the single dominant element (D-11); palette seam (no inlined `{0,0,0}`) | unit + source | `mix test test/rendro/recipes/payslip_test.exs` | ❌ W0 | ⬜ pending |
| 116-02-03 | 02 | 2 | FAM-01, FAM-03 | T-116-02-02 | combined ledger paginates; D-13 reconciliation via `Decimal.equal?/2`; D-17 arbitrary `:description` round-trips (negative test); byte-identity | unit | `mix test test/rendro/recipes/payslip_test.exs test/rendro/recipes/payslip_byte_identity_test.exs` | ❌ W0 | ⬜ pending |
| 116-03-01 | 03 | 2 | FAM-02, FAM-03 | T-116-03-01 | geometry from `PageSize.resolve/2`; byte guards; **D-10 image pre-validation** → ArgumentError naming `data.code.image`, no InvalidAssetError leak | unit | `mix test test/rendro/recipes/ticket_test.exs` | ❌ W0 | ⬜ pending |
| 116-03-02 | 03 | 2 | FAM-02, FAM-03 | — | D-02 placement-grid anchor (largest type on page) via `Rendro.table/2`; palette seam | unit + source | `mix test test/rendro/recipes/ticket_test.exs` | ❌ W0 | ⬜ pending |
| 116-03-03 | 03 | 2 | FAM-02, FAM-03 | T-116-03-02 | code box + always-on reference (D-06); NO faux barcode (D-07); PNG fit-contain, `image: nil` byte-identical to no-image; overflow → typed `:content_overflow` | unit | `mix test test/rendro/recipes/ticket_test.exs test/rendro/recipes/ticket_byte_identity_test.exs` | ❌ W0 | ⬜ pending |
| 116-04-01 | 04 | 3 | FAM-03 | — | both recipes added to `@public_modules`; `priv/public_api.json` regenerated via `mix rendro.api.gen` (not hand-edited); byte-compare passes | contract | `mix test test/docs_contract/public_api_contract_test.exs` | ❌ W0 | ⬜ pending |
| 116-04-02 | 04 | 3 | FAM-03 | — | proof-backed `payslip`/`ticket` rows in `priv/support_matrix.json`; per-capability assertions | contract | `mix test test/docs_contract/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. `File Exists ❌ W0` = test file is a Wave-0 deliverable (created before/with the task's implementation).*

---

## Wave 0 Requirements

- [ ] `test/rendro/recipes/payslip_test.exs` — stubs for FAM-01 (net-pay anchor, combined ledger, reconciliation assert, PII masking, opts threading)
- [ ] `test/rendro/recipes/ticket_test.exs` — stubs for FAM-02 (placement grid anchor, code box + reference, perforation, PNG fit-contain, no-PNG fallback, image error)
- [ ] `test/rendro/recipes/payslip_byte_identity_test.exs` / `ticket_byte_identity_test.exs` — determinism (clone `invoice_byte_identity_test.exs`)
- [ ] Docs-contract updates: `examples_schema_contract_test.exs` must accommodate any new fixture shape (or fixtures stay test-local — see Assumption A1)

*ExUnit itself is already installed; no framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase code-contract behaviors have automated verification. (Reader-quality / visual-rubric grading of the rendered PDFs is Phase 118 — SHOW-01 — not this phase.)*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (all 10 tasks map to an ExUnit command)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (test files created before/with each task)
- [x] No watch-mode flags
- [x] Feedback latency < 90s (full suite ~30–90s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-18
