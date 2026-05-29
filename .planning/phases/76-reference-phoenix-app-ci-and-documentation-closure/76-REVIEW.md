---
phase: 76-reference-phoenix-app-ci-and-documentation-closure
reviewed: 2026-05-29T18:30:00Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - .github/workflows/ci.yml
  - examples/phoenix_example/README.md
  - examples/phoenix_example/lib/phoenix_example_web/controllers/error_json.ex
  - examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex
  - examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex
  - examples/phoenix_example/lib/phoenix_example_web/router.ex
  - examples/phoenix_example/mix.exs
  - examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs
  - guides/page_primitive.md
  - guides/recipes.md
  - mix.exs
  - priv/guardrails/required_status_checks.json
  - scripts/verify_docs.exs
  - test/docs_contract/page_primitive_claims_test.exs
  - test/docs_contract/recipes_claims_test.exs
  - test/docs_contract/recipes_contract_test.exs
  - test/guardrails/required_checks_contract_test.exs
findings:
  critical: 1
  warning: 4
  info: 4
  total: 9
status: issues_found
---

# Phase 76: Code Review Report

**Reviewed:** 2026-05-29T18:30:00Z
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found

## Summary

Phase 76 ships a reference Phoenix 1.8 example app, a non-required `example-phoenix`
CI job, two HexDocs guides (`page_primitive.md`, `recipes.md`), and the docs-contract
+ guardrails tests that bind them. I verified behavior empirically rather than reading
only: I ran `mix deps.get && mix test` in the example app (12 tests, 0 failures), ran the
four reviewed docs-contract/guardrails test files (49 tests, 0 failures), confirmed the
real pagination token names in `lib/rendro/pipeline/paginate.ex`, and booted
`mix phx.server` to confirm the root route serves HTTP 200.

The wiring is sound and the contract tests are green. The most serious problem is that
`guides/page_primitive.md` documents the wrong substitution tokens — it tells readers to
use `{page}` / `{total}` when the engine only substitutes `{{page_number}}` /
`{{total_pages}}`. A reader copying the documented pattern gets literal unsubstituted
tokens in their PDF. Several secondary issues concern stale test labels, README claims
that drift from the actual routes/config, and a fragile source-path lookup in a test.

## Critical Issues

### CR-01: page_primitive.md documents non-functional substitution tokens (`{page}`/`{total}`)

**File:** `guides/page_primitive.md:11`, `guides/page_primitive.md:75-82`
**Issue:** The guide prose and the "Page X of Y pattern" schematic instruct readers to use
`{page}` and `{total}` tokens:

```
line 11:  replace `{page}` and `{total}` tokens with the resolved page number ...
line 77:  Rendro.page_number(format: "Page {page} of {total}")
line 82:  The tokens `{page}` and `{total}` are substituted after pagination completes ...
```

But the engine only substitutes the double-brace tokens. `lib/rendro/pipeline/paginate.ex:431-448`
calls `String.replace("{{page_number}}", ...)` and `String.replace("{{total_pages}}", ...)`,
and `Rendro.page_number/1` (`lib/rendro.ex:211`) defaults to
`"Page {{page_number}} of {{total_pages}}"`. The same guide's *verified* fence at
`guides/page_primitive.md:54` correctly uses `{{page_number}}`/`{{total_pages}}`, so the
guide actively contradicts itself.

A reader who copies the line-77 pattern (`format: "Page {page} of {total}"`) ships a PDF
that literally renders `Page {page} of {total}` — silent data corruption in user output.
The contract tests do not catch this because the offending block is an
`elixir-schematic`-tagged fence (line 75), which `Rendro.Test.DocsContract.verified_fences/1`
(`test/support/docs_contract.ex:11`) filters out — only `elixir` fences are evaluated.

**Fix:** Replace every `{page}`/`{total}` occurrence in the prose and the schematic with the
real tokens:

```elixir
# Illustrative only — a real recipe assigns section content from data.
Rendro.page_number(format: "Page {{page_number}} of {{total_pages}}")
```

And update lines 11 and 82 to reference `{{page_number}}` / `{{total_pages}}`. Consider
adding a `page_primitive_claims_test.exs` assertion that the guide does NOT contain a
single-brace `{page}`/`{total}` token, so this regression cannot reappear:
`refute guide =~ ~r/\{page\}/` and `refute guide =~ ~r/\{total\}/`.

## Warnings

### WR-01: Guardrails test label says "eight lanes" / "lane 8" but asserts and counts ten

**File:** `test/guardrails/required_checks_contract_test.exs:95-96`
**Issue:** The describe block is named `"docs-contract lane count"` and the test is named
`"verify_docs.exs registers exactly eight lanes with viewer evidence as lane 8"`, but the
body asserts `assert length(lane_entries) == 10`. `scripts/verify_docs.exs` does register
10 lanes (confirmed via grep: 10 matching entries). The assertion is correct; the
human-readable name is stale and will mislead the next maintainer who reads a failure
("expected 8?") or audits required-check coverage. Stale "lane 8" framing also no longer
locates viewer-evidence, which is lane 8 of 10 by position but the name implies it is the
last.
**Fix:** Rename to reflect reality:

```elixir
test "verify_docs.exs registers exactly ten lanes including viewer evidence" do
  ...
  assert length(lane_entries) == 10
  assert script =~
           ~s|{"Viewer evidence semantic-claims lane", ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]}|
end
```

### WR-02: README claims "All routes are under the `:api` pipeline" — the root route is not

**File:** `examples/phoenix_example/README.md:26`
**Issue:** The README states: "All routes are under the `:api` pipeline (`plug :accepts, ["json"]`)."
This is false. `router.ex:12-16` puts `GET /` (the HTML chooser) under the `:browser`
pipeline (`plug :accepts, ["html"]`); only the PDF routes are under `:api`. A reader
trusting this statement would expect `/` to negotiate JSON and reject `text/html`, which is
the opposite of what `PageController.index/1` does (it sends `text/html`).
**Fix:** Scope the claim to the PDF routes, e.g. "All PDF download/preview routes are under
the `:api` pipeline; the `/` chooser is under the `:browser` pipeline."

### WR-03: Example endpoint has no port/secret_key_base config; README's `localhost:4000` boot is implicit and fragile

**File:** `examples/phoenix_example/README.md:21`, `examples/phoenix_example/lib/phoenix_example_web/endpoint.ex` (supporting context)
**Issue:** The README "Boot" section promises the server "starts at `http://localhost:4000`".
The endpoint config (`config/config.exs`) sets no `http: [port: ...]` and no
`secret_key_base`, and there is no `config/runtime.exs`/`config/dev.exs`. I booted
`mix phx.server` and it does serve HTTP 200 on 4000 — but only because Bandit defaults to
4000, and the Phoenix banner prints "Access ... at http://localhost" with no port,
contradicting the README's explicit `:4000`. The reachable-by-accident behavior is brittle:
any Phoenix/Bandit default change, or a future addition of session/CSRF plugs (which require
`secret_key_base`), silently breaks the documented boot story. For a *reference* app whose
whole purpose is to be copied, the missing explicit config is a defect.
**Fix:** Add explicit endpoint config so the documented behavior is guaranteed, e.g. in
`config/config.exs`:

```elixir
config :phoenix_example, PhoenixExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: String.duplicate("a", 64),
  ...
```

(Note: `config/` and `endpoint.ex` are outside the explicit review file list but are
load-bearing for the reviewed README claim.)

### WR-04: page_primitive.md capability table claims "First-page suppression via `suppress_on`" but the support-matrix key and section semantics differ

**File:** `guides/page_primitive.md:45`, `guides/page_primitive.md:48`
**Issue:** The capability table row reads "First-page suppression via `suppress_on`" listed
as `supported`, and the prose at line 48 says "Pass `suppress_on: [:first]`". The actual
`Section.suppress_on` type (`lib/rendro/section.ex:14`) is
`nil | :first | {:pages, [pos_integer()]}` — there is no list form `[:first]`. The verified
fence in the same guide (line 64) correctly uses the bare atom `suppress_on: :first`. So the
prose at line 48 documents an invalid value (`[:first]`) that does not match the type or the
guide's own working example. A reader following the prose passes a list and gets either an
ignored suppression or a struct-validation surprise.
**Fix:** Change line 48 to `Pass \`suppress_on: :first\` to omit the page number on the first
page` to match `Section.suppress_on` and the line-64 fence.

## Info

### IN-01: Test 2 source-path lookup is fragile (relative `../../..` climbing)

**File:** `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs:211-236`
**Issue:** The "controller uses canonical recipe" test resolves the controller source by
joining `Application.app_dir(:phoenix_example, "priv")` with four `..` segments, then falls
back to `File.cwd!()/lib/...`. This couples the test to the exact `_build` directory depth.
It passes today, but any change to build layout (umbrella, custom `build_path`) breaks the
primary path and silently relies on the cwd fallback. A source-as-string assertion is also
a weak proxy — the structural recipe assertions elsewhere in this file already prove the same
fact more robustly.
**Fix:** Prefer a single robust anchor, e.g. `Path.join(File.cwd!(), "lib/phoenix_example_web/controllers/pdf_controller.ex")`,
or drop the source-grep test in favor of the existing `%Rendro.Document{}` structural
assertions.

### IN-02: README claims a "Multi-page billing statement" but the demo data cannot overflow

**File:** `examples/phoenix_example/README.md:44`, `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex:19-27`
**Issue:** The Statement section is described as a "Multi-page billing statement with 'Page X
of Y' footers", but `@demo_statement` has only 2 lines — it renders a single page, so the
demonstrated artifact never exercises the multi-page / carried-forward behavior the README
advertises. The recipe supports multi-page (verified), but the reference data does not
demonstrate it.
**Fix:** Either add enough demo lines to force a page break (best — the example then proves
the feature) or soften the README to "billing statement (scales to multiple pages with
'Page X of Y' footers)".

### IN-03: `_(Routes wired in plan 76-02.)_` planning annotations leaked into shipped README

**File:** `examples/phoenix_example/README.md:50`, `:60`, `:71`
**Issue:** Three `_(Routes wired in plan 76-02.)_` parenthetical notes reference an internal
planning artifact. These are meaningless to an external reader of the published example app
and read as leftover scaffolding.
**Fix:** Remove the three `_(Routes wired in plan 76-02.)_` lines.

### IN-04: page_primitive.md token-inconsistency between schematic and basic fence invites copy-paste of the wrong form

**File:** `guides/page_primitive.md:54` vs `guides/page_primitive.md:77`
**Issue:** Related to CR-01 but recorded separately for clarity: the guide presents two
different token conventions within ~20 lines — the working fence uses `{{page_number}}`
(line 54) while the "standard pattern" schematic uses `{page}` (line 77). Even after CR-01 is
fixed, having a non-evaluated schematic that mimics real API surface is risk-prone. Consider
making the canonical pattern an evaluated `elixir` fence (with a `# docs-contract:` id) so the
contract harness guarantees it stays correct, rather than an unverified `elixir-schematic`
fence.
**Fix:** Convert the "Page X of Y pattern" schematic to a verified fence, or add a contract
assertion that the guide contains no single-brace page tokens (see CR-01 fix).

---

_Reviewed: 2026-05-29T18:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
