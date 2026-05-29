---
phase: 76-reference-phoenix-app-ci-and-documentation-closure
verified: 2026-05-29T19:05:00Z
status: passed
score: 18/18 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  note: initial verification (no prior VERIFICATION.md)
---

# Phase 76: Reference Phoenix App, CI, and Documentation Closure Verification Report

**Phase Goal:** A Phoenix engineer arriving at the repository can run the reference app locally (examples/phoenix_example), read a HexDocs guide for the PAGE primitive and each recipe, and see CI prove the example is exercised — all WITHOUT touching engine-critical proof lanes (signing-live-proof, long-lived-live-proof, release-proof, test).
**Verified:** 2026-05-29T19:05:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal is observably achieved in the codebase. The reference app compiles clean and its 12-test suite passes; all five recipes are demonstrated through `Rendro.Adapters.Phoenix` with routes, chooser links, and per-recipe tests; the two HexDocs guides are wired into ExDoc and bounded to the support matrix with three passing docs-contract tests + two new verify_docs lanes; and the `example-phoenix` CI job is graph-disconnected and advisory while the four engine lanes remain required and untouched.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | examples/phoenix_example compiles clean with --warnings-as-errors on new dep floors | ✓ VERIFIED | `mix compile --warnings-as-errors` exits 0; the only 6 warnings are `(rendro 0.3.1) lib/rendro/...` library-owned (JSV optional dep), none from example source |
| 2 | App boots without missing-module crash (ErrorJSON exists, wired into config) | ✓ VERIFIED | `error_json.ex` defines `PhoenixExampleWeb.ErrorJSON.render/2` returning `status_message_from_template`; `config/config.exs:8` `render_errors formats: [json: PhoenixExampleWeb.ErrorJSON]` |
| 3 | README documents setup + boot + each recipe + advisory-CI caveat | ✓ VERIFIED | `README.md` contains `mix deps.get`, `mix phx.server`, all five recipe names, `Rendro.Adapters.Phoenix`, and "not required" CI note (WR-02 pipeline scoping + IN-03 leakage fixes landed) |
| 4 | mix.exs has non-stale floors (Phoenix ~>1.8, plug ~>1.18, jason ~>1.4, elixir ~>1.19) | ✓ VERIFIED | mix.exs project `elixir: "~> 1.19"`; deps `{:phoenix, "~> 1.8"}`, `{:plug, "~> 1.18"}`, `{:jason, "~> 1.4"}`, plus unchanged `{:bandit, "~> 1.0"}`, `{:rendro, path: "../.."}` |
| 5 | Statement/Receipt/Certificate download routes return 200 + application/pdf + %PDF- via adapter | ✓ VERIFIED | `mix test` 12 tests 0 failures; tests assert `binary_part(conn.resp_body,0,5) == "%PDF-"` for all three (lines 105/132/160/188) |
| 6 | Each new recipe also has a /preview inline route | ✓ VERIFIED | router.ex lines 26/28/30 `/statement/preview`, `/receipt/preview`, `/certificate/preview`; controller `*_preview/2` actions call `RendroPhoenix.preview_pdf` |
| 7 | Index chooser lists download + preview links for all three new recipes | ✓ VERIFIED | page_controller.ex has 6 `href="/{statement,receipt,certificate}/{download,preview}"` links (grep count 6) |
| 8 | Statement & Receipt expose [:header,:body,:footer]; Certificate exactly [:body] | ✓ VERIFIED | Test lines 146-149 (Statement) + 174-177 (Receipt) assert header/body/footer; line 203 asserts `region_names == [:body]` exactly |
| 9 | example-phoenix CI job runs mix deps.get && mix test against examples/phoenix_example | ✓ VERIFIED | ci.yml lines 31-48: job `example-phoenix`, `working-directory: examples/phoenix_example`, runs `mix deps.get` then `mix test`, setup-beam otp 28 / elixir 1.19.5 |
| 10 | example-phoenix job is graph-disconnected (no needs:) and has no continue-on-error | ✓ VERIFIED | ci.yml line 33 comment + structural read: no `needs:` key, no `continue-on-error:` in the job |
| 11 | "Verify Phoenix Example" step removed from required test job | ✓ VERIFIED | `grep -c "Verify Phoenix Example" ci.yml` == 0; test job only runs `mix deps.get` + `mix ci` |
| 12 | example-phoenix recorded as advisory (not required) in guardrail manifest | ✓ VERIFIED | required_status_checks.json advisory_contexts entry name=example-phoenix, notes "not required ... REF-03/D-09"; `required_contexts` does NOT include it |
| 13 | Four engine lanes remain required unchanged | ✓ VERIFIED | required_contexts == ["long-lived-live-proof","release-proof","signing-live-proof","test"]; contract test asserts equality + refutes example-phoenix in required |
| 14 | guides/page_primitive.md + guides/recipes.md exist and wired into mix.exs docs/0 extras + "Recipes & Primitives" group | ✓ VERIFIED | Both files exist (3705 / 7576 bytes); mix.exs extras lines 99-100/112-113, groups_for_extras lines 124-126 |
| 15 | Guide claims bound to support matrix; out-of-matrix claims refuted; evidence paths exist on disk | ✓ VERIFIED | 3 docs-contract tests 38 tests 0 failures; 4 evidence files (paginate/statement/receipt/certificate _test.exs) exist on disk; no `{page}`/`{total}` (CR-01 fixed), `suppress_on: :first` (WR-04 fixed) |
| 16 | verify_docs.exs registers two new lanes (10 total) | ✓ VERIFIED | lane regex count == 10; recipes_claims + page_primitive_claims lanes present (lines 16-17) |
| 17 | mix run scripts/verify_docs.exs reports "Docs contract VERIFIED!" | ✓ VERIFIED | Run exits 0, prints "Docs contract VERIFIED!", both new lanes PASS |
| 18 | mix test test/guardrails/required_checks_contract_test.exs passes | ✓ VERIFIED | 11 tests, 0 failures, exit 0 |

**Score:** 18/18 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/phoenix_example/mix.exs` | Non-stale dep floors | ✓ VERIFIED | All four floors present + bandit/rendro unchanged |
| `examples/phoenix_example/lib/phoenix_example_web/controllers/error_json.ex` | ErrorJSON handler | ✓ VERIFIED | render/2 via status_message_from_template; no Ecto/LiveView/gettext |
| `examples/phoenix_example/README.md` | Setup + per-recipe docs | ✓ VERIFIED | Complete; WR-02/IN-03 review fixes applied |
| `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` | 3 fixtures + 6 actions | ✓ VERIFIED | Decimal fixtures, 6 actions wired to recipe document/1 + adapter |
| `examples/phoenix_example/lib/phoenix_example_web/router.ex` | 6 new routes | ✓ VERIFIED | All 6 routes in :api scope (lines 25-30) |
| `examples/phoenix_example/test/.../pdf_controller_test.exs` | HTTP + magic-byte + structural | ✓ VERIFIED | 12 tests pass; Certificate single-region trap avoided |
| `.github/workflows/ci.yml` | example-phoenix advisory job; step removed | ✓ VERIFIED | Job present, no needs/no continue-on-error; step count 0 |
| `priv/guardrails/required_status_checks.json` | advisory example-phoenix entry | ✓ VERIFIED | In advisory_contexts only |
| `test/guardrails/required_checks_contract_test.exs` | Enum.find + assertions + lane 10 | ✓ VERIFIED | 11 tests pass; Enum.find, REF-03, == 10 present |
| `guides/page_primitive.md` | PAGE primitive guide | ✓ VERIFIED | "Page X of Y", double-brace tokens, suppress_on: :first |
| `guides/recipes.md` | Recipes guide + branding pointer | ✓ VERIFIED | statement/receipt/certificate sections; no overclaims |
| `scripts/verify_docs.exs` | +2 lanes (10 total) | ✓ VERIFIED | 10 lanes, both new ones present |
| `test/docs_contract/{page_primitive_claims,recipes_claims,recipes_contract}_test.exs` | 3 docs-contract tests | ✓ VERIFIED | All exist; 38 tests pass |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| config/config.exs | PhoenixExampleWeb.ErrorJSON | render_errors formats | ✓ WIRED | Module referenced + defined |
| pdf_controller.ex | Rendro.Adapters.Phoenix | RendroPhoenix.render_pdf/preview_pdf | ✓ WIRED | All 6 actions call adapter |
| router.ex | PDFController recipe actions | get "/...", PDFController, :*_* | ✓ WIRED | All 6 routes bind matching action atoms |
| required_status_checks.json | ci.yml | advisory ci_job == example-phoenix | ✓ WIRED | Names match; job exists |
| contract test | required_status_checks.json | Enum.find advisory + refute required | ✓ WIRED | Test green |
| mix.exs | guides/*.md | extras + groups_for_extras | ✓ WIRED | Both paths in extras + group |
| recipes_claims_test.exs | priv/support_matrix.json | Jason.decode + File.exists?(evidence) | ✓ WIRED | Test green; evidence files exist |
| scripts/verify_docs.exs | docs_contract claims tests | lanes list tuples | ✓ WIRED | Both lanes registered + PASS |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| pdf_controller recipe actions | `@demo_*` fixtures → recipe document/1 → adapter | Real `Rendro.Recipes.*.document/1` | Yes (response body begins `%PDF-`) | ✓ FLOWING |
| docs-contract claims tests | matrix capabilities + evidence paths | priv/support_matrix.json + on-disk *_test.exs | Yes (4 evidence files exist, File.exists? assertions pass) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Example app suite passes | `mix test` (in examples/phoenix_example) | 12 tests, 0 failures, exit 0 | ✓ PASS |
| Example compiles clean | `mix compile --warnings-as-errors` | exit 0 (only library-owned rendro warnings) | ✓ PASS |
| Guardrail contract holds | `mix test test/guardrails/required_checks_contract_test.exs` | 11 tests, 0 failures | ✓ PASS |
| Docs-contract tests pass | `mix test .../recipes_claims .../page_primitive_claims .../recipes_contract` | 38 tests, 0 failures | ✓ PASS |
| Docs contract verifier | `mix run scripts/verify_docs.exs` | "Docs contract VERIFIED!", exit 0, 10 lanes PASS | ✓ PASS |
| Guides build clean | `mix docs` | No undefined-reference warnings for the two new guides | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| REF-01 | 76-01 | Reference app mix-runnable + README on non-stale deps | ✓ SATISFIED | Truths 1-4 |
| REF-02 | 76-02 | All 5 recipes via Rendro.Adapters.Phoenix | ✓ SATISFIED | Truths 5-8 |
| REF-03 | 76-03 | Isolated non-required example-phoenix CI job | ✓ SATISFIED | Truths 9-13, 18 |
| CONTRACT-02 | 76-04 | PAGE primitive + recipes guides bounded by docs-contract | ✓ SATISFIED | Truths 14-17 |

All four requirement IDs from PLAN frontmatter are accounted for and mapped to Phase 76 in REQUIREMENTS.md (lines 42-44, 51, 101-104). No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| guides/page_primitive.md | 88 | "Digital signatures" (capital D) in negative-disclaimer context | ℹ️ Info | Not a stub or overclaim — explicitly disclaims the capability; case-sensitive refute for lowercase "digital signatures" still passes |

No debt markers (TBD/FIXME/XXX) in phase-76 files. No stubs: all controller actions wire to real recipe document/1; all guide claims are matrix-bound with on-disk evidence. CR-01 and WR-04 (review blockers) confirmed fixed in page_primitive.md.

### Human Verification Required

None. All goal-bearing behaviors are programmatically verifiable and were exercised: compilation, the full example test suite, the guardrail contract test, all docs-contract tests, and the verify_docs verifier all pass. The "Phoenix engineer can run the app locally" path is proven by the green example test suite (which exercises real HTTP routes through the adapter) plus the documented `mix phx.server` boot.

### Gaps Summary

No gaps. The phase goal is fully achieved:
- The reference app is mix-runnable on non-stale constraints with a complete README (REF-01).
- All five recipes are demonstrated through the Phoenix adapter with routes, chooser links, and a passing 12-test suite (REF-02).
- The example-phoenix CI job is graph-disconnected, advisory, and visible; the four engine lanes remain required and untouched (REF-03).
- Both HexDocs guides exist, are wired into ExDoc, and are bounded to the support matrix by three passing docs-contract tests and two new verify_docs lanes; "Docs contract VERIFIED!" (CONTRACT-02).

Pre-existing out-of-scope items (paginate.ex / deterministic_test.exs / statement_test.exs uncommitted changes and the dangling `guides/user_flows_and_jtbd.md` mix docs warning) were not attributed to this phase, per instructions. Review Info items IN-02 (single-page demo statement) and IN-01/IN-04 are accepted/advisory and do not block the goal.

---

_Verified: 2026-05-29T19:05:00Z_
_Verifier: Claude (gsd-verifier)_
