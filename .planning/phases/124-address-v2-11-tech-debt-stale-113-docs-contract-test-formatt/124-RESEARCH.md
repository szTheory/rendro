# Phase 124: Address v2.11 tech debt - Research

**Researched:** 2026-07-28
**Domain:** Elixir maintenance — stale test fixture, `mix format` drift, Dialyzer type-contract cascade
**Confidence:** HIGH — every finding in this document was reproduced live against the actual repo (test runs, `mix format --check-formatted`, `mix dialyzer`), not inferred from the audit text. Two of the three targets turned out to have a materially different shape than `124-CONTEXT.md`'s framing; both discrepancies are called out explicitly below.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Stale 113 docs-contract test: fix the test, do NOT resurrect deleted planning files**
- The two failing cases guard archived phase-113 planning artifacts that were deleted by design during milestone cleanup. Restoring `113-METRICS.md` / `113-UAT.md` is the wrong fix.
- Make the suite green by removing the dependency on the deleted archived paths. Research/plan determines the precise mechanism from what each test actually asserts: (a) delete the two now-obsolete cases if the claim they guarded pertains only to archived 113 planning docs; (b) skip/guard-on-absence if the guarded claim is still live but the evidence file is legitimately gone; or (c) re-point at the current source of truth if the claim must still be enforced.
- Guardrail: the 3 currently-passing tests in the file MUST stay green. Do not silently weaken a still-relevant docs-contract guarantee — if a case is removed, record why (the claim is 113-archive-specific).

**D-02 — Formatter drift: apply `mix format`; formatting-only, bounded**
- Run `mix format` on the affected files so `mix format --check-formatted` exits 0 and unblocks `ci.fast` step 1.
- Guardrail: the diff must be formatting-only (verify via `git diff` shows no token or logic changes) and bounded to the known ~7-file set. If `mix format` would touch a large swath beyond the known set, STOP and treat it as a formatter config/version mismatch to investigate, not a mass reformat to commit.

**D-03 — Ticket dialyzer contract: spec-only fix, zero rendered-output change**
- Make `mix dialyzer` pass by correcting the type contract(s) causing the cascade — primarily the narrow `@spec emit?/1` in `lib/rendro/recipes/background.ex` so it matches the `colors` argument all callers pass, plus any genuinely-required `ticket.ex` `@spec`, so the `no_return` on `sections/1,2` and `document/1,2` clears.
- Guardrail (hard): the fix MUST NOT change runtime behavior or rendered bytes. The full golden / byte-identity regression suite MUST remain byte-identical after the change. If the true root cause turns out to be a genuine always-raises code path rather than a spec mismatch, surface it as a decision rather than silently altering behavior.
- Research confirms the exact `mix dialyzer` output and root cause against the already-built PLT before the fix is planned.

**D-04 — Ticket visual hierarchy regression stays OUT (locked Phase-122 decision)**
- The type-scale hierarchy inversion (WINDOWS.md id 2) is a locked, documented design outcome. This phase does not touch Ticket role mapping, type scale, or layout. Dialyzer-type-only.

**D-05 — Scope fence: only the three titled targets**
- IN: stale-113 test, formatter drift, ticket dialyzer contract. OUT (deferred): pdfium-cli tooling gap, Nyquist 121/122/123 validation, from_brand byte-level E2E golden, SUMMARY frontmatter bookkeeping. Do not expand scope into any of these; note them as deferred so the milestone audit stays honest.

**D-06 — Success bar: green gates + preserved byte-identity**
- Acceptance is gate-level and objectively checkable. No new feature behavior; the only observable delta is that previously-red/false-red gates now pass and the un-themed golden bytes are unchanged.

### Claude's Discretion
- The exact mechanism per stale-test case (delete / skip / re-point) — research determines this from what each case actually asserts (resolved below: both cases → delete).
- The precise `@spec` correction shape for `emit?/1` (resolved below, empirically verified).

### Deferred Ideas (OUT OF SCOPE)
- Ticket visual hierarchy re-mapping (locked Phase-122 architectural call) → future milestone
- `pdfium-cli` install / PATH provisioning → environment setup, not code
- `/gsd-validate-phase 121`, `122`, `123` → Nyquist coverage completion
- `from_brand/2` byte-level E2E golden → integration hardening follow-up
- SUMMARY frontmatter `requirements_completed` backfill → bookkeeping follow-up
</user_constraints>

## Summary

All three targets were reproduced live against the working tree (not just read from the audit). Two produced a materially more complete picture than `124-CONTEXT.md`'s framing suggested — both are good news, not scope creep, because the fixes required are still exactly what D-01/D-02/D-03 anticipated.

**Target 1 (stale 113 docs-contract test):** Confirmed exactly 2 failures / 5 tests in `test/docs_contract/dx_local_reproducibility_claims_test.exs`. Both failing cases are **entirely archive-specific** — every assertion in both bodies checks facts frozen at Phase-113/C1-milestone completion (specific GitHub run IDs, specific p50/p95 numbers, a specific UAT pass count). Neither case validates anything about current, live system behavior. **Mechanism: DELETE both cases** (D-01 option a), plus remove the 3 now-orphaned module attributes (`@uat_path`, `@metrics_path`, `@audit_path`) to avoid a `mix test`-time "module attribute set but never used" warning (confirmed reproducible; does not fail `--warnings-as-errors` because `test/` isn't in `compile`'s `elixirc_paths`, but it is noisy CI output that should be cleaned up in the same edit).

**Target 2 (formatter drift):** Confirmed exactly 7 files, exactly matching WINDOWS.md id 4's list. Ran `mix format` live: the diff touched **only** those 7 files (47 insertions / 17 deletions), every hunk is pure whitespace/parenthesization/line-wrap (verified by inspection and by running all 6 affected files' test suites afterward — 43 tests, 0 failures, identical to baseline). **Bounded — no formatter config/version mismatch.** Command: bare `mix format` (uses `.formatter.exs`, which is unchanged and standard).

**Target 3 (dialyzer):** This is where CONTEXT.md's framing undersold the scope, but the *fix* is unchanged. Live `mix dialyzer` reports **133 total errors across 10 files** (not just `ticket.ex`): `lib/rendro/recipes/{statement,ticket,certificate,branded_invoice,invoice,payslip,receipt}.ex` (11-16 errors each), `lib/rendro/recipes.ex` (20), `lib/rendro/launch_artifacts.ex` (15), and `lib/mix/tasks/rendro.visual_uat.ex` (16). Root cause confirmed and empirically fixed: `Background.emit?/1`'s `@spec` at `background.ex:25-26` uses the Elixir map-shorthand `%{background: T}`, which Erlang/Dialyzer treats as a **closed** map type (accepts a map with *exactly* that one key, nothing else) — not an open/permissive supertype as the shorthand visually suggests. Every real caller passes a 7-9-key `colors` map (`ink`/`muted`/`accent`/`on_accent`/`background`/`surface`/`rule`[/`positive`/`negative`]), so **no real call site can ever satisfy the closed 1-key contract**. Dialyzer marks every call "will not succeed" → poisons the enclosing function to `no_return` → cascades transitively through every caller chain: `recipes/*.ex` sections/document → `recipes.ex` facade → `launch_artifacts.ex`'s gallery-build functions → the `visual_uat` mix task (`+` a long tail of "unused_fun" warnings on helpers only reachable through the now-tainted paths). **One-line, single-file, spec-only fix in `background.ex` — verified live to take the error count from 133 to 0** with zero code/runtime change and zero test regressions (34 byte-identity/golden tests green before and after). `ticket.ex` itself needs **no spec change at all** — its own `@spec`s were already correct; they only showed `invalid_contract` because the internal `Background.emit?/1` call poisoned their success typing.

**Primary recommendation:** (1) Delete both stale test cases + their 3 orphaned attributes. (2) Run bare `mix format`, commit the 7-file diff as formatting-only. (3) Widen `Background.emit?/1`'s `@spec` to an open map type requiring `:background` — this single edit resolves the entire 133-error cascade, no other file needs a code or spec change.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Docs-contract test correctness | Test suite (ExUnit) | — | Pure test-code fix; no production code involved |
| Source formatting | Build tooling (`mix format`) | — | Whitespace-only; `.formatter.exs` config unchanged |
| Type contract correctness (Dialyzer) | Library/`lib` tier (`Rendro.Recipes.Background`) | Recipe modules (transitively unblocked) | `background.ex` is the single shared seam all 7 recipes call through; fixing the seam's contract fixes every consumer without touching the consumers |

This phase is 100% "maintenance/tooling" tier — there is no browser/frontend/API/database tier involved. `gsd-ui-plan-gate` may report `frontend:true` on this repo (a known false positive per project memory — Rendro is a PDF-generation library, not a web app); this phase has zero UI surface and UI-SPEC should be skipped.

## Package Legitimacy Audit

**Not applicable.** This phase installs no new packages and modifies no `mix.exs` dependency. All three fixes touch only `@spec`/test-body content in already-vendored, already-approved source files.

## Target 1 — Stale 113 docs-contract test (per-case mechanism)

File: `test/docs_contract/dx_local_reproducibility_claims_test.exs` (119 lines, 5 `test` blocks).

### Live reproduction
```
$ mix test test/docs_contract/dx_local_reproducibility_claims_test.exs
5 tests, 2 failures

  1) test validation reports keep local and remote evidence boundaries truthful
     ** (File.Error) could not read file ".planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md": no such file or directory
     test/docs_contract/dx_local_reproducibility_claims_test.exs:78

  2) test Phase 113 UAT is completed from automated evidence with no human prompt remaining
     ** (File.Error) could not read file ".planning/phases/113-dx-local-reproducibility-validation/113-UAT.md": no such file or directory
     test/docs_contract/dx_local_reproducibility_claims_test.exs:104
```
Confirmed on disk: `.planning/phases/113-dx-local-reproducibility-validation/` contains only `113-PATTERNS.md` and `113-RESEARCH.md` — `113-METRICS.md` and `113-UAT.md` are gone (milestone-cleanup, commit `0de2de8`, per audit).

**Correction to CONTEXT.md's framing:** `@audit_path = ".planning/milestones/C1-AUDIT.md"` (line 6, used only by case `:77`) **still exists** and is readable — it is not one of the deleted files. This matters for the mechanism decision below (see case `:77`).

### Case `:77` — "validation reports keep local and remote evidence boundaries truthful"
```elixir
metrics = File.read!(@metrics_path)   # DELETED — raises here
audit = File.read!(@audit_path)       # exists — never reached

assert metrics =~ "mix ci.fast"
assert metrics =~ "1219 tests, 12 doctests, 4 properties, 0 failures"
assert metrics =~ "29133061301"   # a specific GitHub Actions run ID
assert metrics =~ "29133777702"
assert metrics =~ "29134266708"
assert metrics =~ "p50 783s"
assert metrics =~ "nearest-rank p95 1013s"
...
assert audit =~ "## Phase 113 Validation Summary"
assert audit =~ "three green `ci.yml` runs"
assert audit =~ "p50 783s"
assert audit =~ "nearest-rank p95 1013s"
```
**What it actually asserts:** that two now-historical documents (Phase 113's own local-run metrics snapshot, and the C1 milestone audit) contain **the same specific frozen numbers** — three literal GitHub Actions run IDs and a specific p50/p95 timing pair from a validation event that happened once, at Phase-113/C1-milestone closure (shipped 2026-07-11). This was a genuine "local evidence and the audit don't silently diverge" cross-check **at the time it was written**. It has zero forward-looking value now: the numbers it checks are permanently fixed historical facts, not a property of the current or future codebase — nothing that happens in today's `lib/` or `test/` could ever make this assertion catch a real regression. The claim is **entirely scoped to the archived Phase-113 evidence trail**, even though one of its two source documents (`C1-AUDIT.md`) happens to still be on disk.
**Mechanism: DELETE (D-01 option a).** Re-pointing is not viable — there is no "current source of truth" for a Phase-113-specific one-time GitHub Actions run ID; skip/guard-on-absence would just leave a permanently-skipped test with no future path to un-skip, which is functionally identical to deletion but noisier.

### Case `:103` — "Phase 113 UAT is completed from automated evidence with no human prompt remaining"
```elixir
uat = File.read!(@uat_path)   # DELETED — raises here

assert uat =~ "status: complete"
assert uat =~ "verifier: automated"
assert uat =~ "passed: 5"
assert length(Regex.scan(~r/^result: pass$/m, uat)) == 5
refute uat =~ "result: [pending]"
```
**What it actually asserts:** internal completeness of Phase 113's own UAT file — no cross-reference to any other document, purely self-contained facts about a single archived phase artifact. This is the cleanest possible DELETE case: the claim is 100% about the deleted file's own content.
**Mechanism: DELETE (D-01 option a).**

### Cleanup requirement (not in CONTEXT.md, discovered live)
Deleting both cases orphans all 3 module attributes (`@uat_path` line 4, `@metrics_path` line 5, `@audit_path` line 6 — none are used anywhere else in the file). Reproduced live:
```
$ mix test test/docs_contract/dx_local_reproducibility_claims_test.exs   # after deleting both cases, attrs left in place
warning: module attribute @uat_path was set but never used
warning: module attribute @metrics_path was set but never used
warning: module attribute @audit_path was set but never used
```
This does **not** fail `mix compile --warnings-as-errors` (ci.fast step 3) — `test/` files outside `test/support/` are not part of `elixirc_paths`, so `mix compile` never compiles this file; the warning only surfaces under `mix test` (ci.fast step 4), which has no `--warnings-as-errors` flag on its `mix.exs` alias entry. It is non-blocking but should still be cleaned up in the same edit for hygiene — delete lines 4-6 along with the two test blocks.

### Verified: the other 3 tests stay green
```
$ mix test test/docs_contract/dx_local_reproducibility_claims_test.exs   # with both cases + 3 attrs removed
3 tests, 0 failures      # no warnings
```
Confirmed live by temporarily removing both cases (and separately, all 3 attributes) and re-running — exact recommended end state.

### Exact edit
Delete lines 4-6 (all three `@..._path` attributes) and the two `test` blocks (`:77`-`:101` and `:103`-`:118`), leaving the file's other 3 tests (`:8`, `:17`, `:49`) untouched. Optionally leave a one-line comment noting why (e.g. `# 113-UAT.md/113-METRICS.md were phase-113-archive-specific evidence, deleted by milestone cleanup (commit 0de2de8); the frozen numbers they guarded have no forward-looking regression value — see 124-RESEARCH.md Target 1.`).

## Target 2 — Formatter drift

### Command
```bash
mix format --check-formatted   # detect (exit 1 currently)
mix format                     # fix (no path args — uses .formatter.exs inputs globs)
mix format --check-formatted   # verify (exit 0 after fix)
```

### Full file list (exactly 7 — matches WINDOWS.md id 4 verbatim)
1. `lib/rendro/launch_artifacts.ex`
2. `test/docs_contract/theme_industry_guard_test.exs`
3. `test/docs_contract/theming_claims_test.exs`
4. `test/rendro/recipes/payslip_opts_threading_test.exs`
5. `test/rendro/recipes/themed_render_smoke_test.exs`
6. `test/rendro/recipes/certificate_typography_test.exs`
7. `test/rendro/recipes/theme_mode_background_golden_test.exs`

### Bounded-check result: CONFIRMED bounded
Ran `mix format` live and captured `git status --short` afterward — **exactly these 7 files** were modified, nothing else. `git diff --stat`: `7 files changed, 47 insertions(+), 17 deletions(-)`. No formatter config/version mismatch signal (would show as dozens/hundreds of files touched); this is ordinary drift from files last edited under a slightly different `mix format` output style across phases 119/121/122/123-03/123-04.

### Diff is formatting-only — confirmed by inspection
Every hunk is one of:
- `refute source =~ term` → `refute(source =~ term)` (added parens, `theme_industry_guard_test.exs`)
- A long single-line map/keyword literal wrapped onto multiple lines (`payslip_opts_threading_test.exs`, `themed_render_smoke_test.exs`, `certificate_typography_test.exs`) — e.g. `%{description: "Base Salary", amount: Decimal.new("4200.00"), ytd: Decimal.new("25200.00")}` → same map, one key per line
- A multi-line string literal collapsed onto one line where it now fits (`lib/rendro/launch_artifacts.ex`'s `caption:` values) — same string content, byte-for-byte
- A blank line inserted between a variable binding and the following `assert` (`theming_claims_test.exs`, `theme_mode_background_golden_test.exs`)

No identifiers, string contents, operators, or control flow changed anywhere in the 7-file diff.

### Confirmed no test regression
Ran the 6 affected test files (the 7th, `launch_artifacts.ex`, is `lib/` code exercised by the byte-identity/gallery tests) after formatting:
```
$ mix test test/docs_contract/theme_industry_guard_test.exs test/docs_contract/theming_claims_test.exs \
    test/rendro/recipes/certificate_typography_test.exs test/rendro/recipes/payslip_opts_threading_test.exs \
    test/rendro/recipes/theme_mode_background_golden_test.exs test/rendro/recipes/themed_render_smoke_test.exs
43 tests, 0 failures
```
Identical pass count to the pre-format baseline. Change reverted after verification (research does not leave code changes behind); the plan re-applies it as the actual fix commit.

## Target 3 — Ticket/Background dialyzer contract

### Baseline: exact `mix dialyzer` output (before fix)
```
$ mix dialyzer
Total errors: 133, Skipped: 0, Unnecessary Skips: 0
done in 0m2.1s   # PLT was already built — confirmed fast, as CONTEXT.md expected
```
Error distribution by file (confirmed via grep count, not estimated):

| File | Error count |
|------|-------------|
| `lib/rendro/recipes.ex` | 20 |
| `lib/rendro/recipes/certificate.ex` | 16 |
| `lib/mix/tasks/rendro.visual_uat.ex` | 16 |
| `lib/rendro/launch_artifacts.ex` | 15 |
| `lib/rendro/recipes/ticket.ex` | 11 |
| `lib/rendro/recipes/statement.ex` | 11 |
| `lib/rendro/recipes/receipt.ex` | 11 |
| `lib/rendro/recipes/payslip.ex` | 11 |
| `lib/rendro/recipes/invoice.ex` | 11 |
| `lib/rendro/recipes/branded_invoice.ex` | 11 |
| **Total** | **133** |

**This is a wider blast radius than `124-CONTEXT.md`'s "pre-existing ticket.ex contract errors" framing implied** — it is not isolated to Ticket. All 7 recipe files, the `Rendro.Recipes` facade module, `launch_artifacts.ex` (the gallery-build pipeline), and even an unrelated-looking mix task (`rendro.visual_uat`) show errors. **This does not expand the phase's scope** — see root cause below: it is the exact same single spec mismatch D-03 already targeted, just with a longer cascade than the audit surfaced. The fix remains one line in one file.

### Ticket-specific error output (as CONTEXT.md's hypothesis anticipated)
```
lib/rendro/recipes/ticket.ex:132:invalid_contract
Function: Rendro.Recipes.Ticket.page_template/1
Success typing: (_) :: none()
But the spec is: (:elixir.keyword()) :: Rendro.PageTemplate.t()

lib/rendro/recipes/ticket.ex:224:invalid_contract
Function: Rendro.Recipes.Ticket.document/2
Success typing: (_, _) :: none()
But the spec is: (map(), :elixir.keyword()) :: Rendro.Document.t()

lib/rendro/recipes/ticket.ex:256:invalid_contract
Function: Rendro.Recipes.Ticket.sections/2
Success typing: (_, _) :: none()
But the spec is: (map(), :elixir.keyword()) :: [Rendro.Section.t()]

lib/rendro/recipes/ticket.ex:133:7:no_return   (page_template/0, page_template/1)
lib/rendro/recipes/ticket.ex:225:7:no_return   (document/1, document/2)
lib/rendro/recipes/ticket.ex:257:7:no_return   (sections/1, sections/2)

lib/rendro/recipes/ticket.ex:171:42:call
Rendro.Recipes.Background.emit?(
  _colors :: %{:accent => _, :background => _, :ink => _, :muted => _,
               :on_accent => _, :rule => _, :surface => _, _ => _}
)
breaks the contract
(%{:background => {non_neg_integer(), non_neg_integer(), non_neg_integer()}}) :: boolean()

lib/rendro/recipes/ticket.ex:273:40:call   (identical, second call site in sections/2)
```

### Root cause — CONFIRMED, and more precise than CONTEXT.md's hypothesis
CONTEXT.md's hypothesis was that the narrow `@spec` was a *value-type* mismatch (i.e. the resolved `colors` map's `:background` value isn't provably a `non_neg_integer()` triple). **That is not the actual mechanism.** The real cause is a well-known Elixir/Dialyzer gotcha: **a map type written with the shorthand `%{key: type}` syntax in a `@spec` is a CLOSED map type** — it denotes "a map with *exactly* this one key, and no others" — not "a map that has at least this key." (Erlang map-type semantics: `#{K := V}` alone, with no trailing `_ => _`/`optional(any()) => any()`, does not permit extra keys.)

`background.ex:25-26`'s spec:
```elixir
@spec emit?(%{background: {non_neg_integer(), non_neg_integer(), non_neg_integer()}}) :: boolean()
```
is therefore a contract for "a 1-key map, `%{background: ...}` and nothing else." But **every real call site** passes a 7-9-key `colors` map (`ink`, `muted`, `accent`, `on_accent`, `background`, `surface`, `rule`, and — when sourced via `Rendro.Theme.resolve(theme).colors` — also `positive`/`negative`), built by each recipe's private `palette/1` helper (`ticket.ex:644-663` and its structural twins in the other 6 recipe files). **No caller can ever satisfy the closed 1-key contract**, so Dialyzer marks every one of the 14 call sites (`Background.emit?(colors)` appears twice per recipe — once in `page_template/1`, once in `sections/2` — across all 7 recipes: `statement.ex:211,273`; `payslip.ex:166,226`; `ticket.ex:171,273`; `certificate.ex:143,220`; `branded_invoice.ex:105,155`; `invoice.ex:134,191`; `receipt.ex:178,246`) as "the function call will not succeed" → poisons the enclosing function's success typing to `none()` → produces `invalid_contract` on that function's own `@spec` → `no_return` on every arity/branch → transitively poisons every caller of that function. That is the entire 133-error cascade's single root: `recipes/*.ex` `page_template`/`sections`/`document` (all poisoned) → `recipes.ex` facade functions that just delegate to them (poisoned) → `launch_artifacts.ex`'s `build_source_document/1` (calls `Rendro.Recipes.Invoice.document(...)` etc., poisoned) → `render_source_pdf/1`/`source_document_for/1` (poisoned) → downstream style-helper functions that are now only reachable through a poisoned path become `unused_fun` → the same pattern independently through `rendro.visual_uat.ex`'s `render_and_rasterise/1`, which calls `Rendro.Recipes.BrandedInvoice.document(@invoice_fixture)` directly (poisoned) → `run/1` (poisoned) → every helper only reachable after that `with` chain becomes `unused_fun`.

`section/3` in the same file (`background.ex:67-68`) already uses a fully open `map()` spec and has **zero** dialyzer errors anywhere in the baseline — confirming `map()`/open-map specs are not the problem; the closed-map shorthand specifically is.

### The fix — empirically verified live (133 → 0 errors, single file, zero runtime change)
**Before** (`lib/rendro/recipes/background.ex:25-26`):
```elixir
@spec emit?(%{background: {non_neg_integer(), non_neg_integer(), non_neg_integer()}}) ::
        boolean()
def emit?(%{background: bg}), do: bg != @paper_white
```
**After:**
```elixir
@spec emit?(%{
        required(:background) => {non_neg_integer(), non_neg_integer(), non_neg_integer()},
        optional(atom()) => any()
      }) :: boolean()
def emit?(%{background: bg}), do: bg != @paper_white
```
This is the standard Elixir idiom for "a map that requires this one key with this type, and may have any number of other atom keys" — an **open** map type. `optional(any())` also works (verified) but `optional(atom())` is tighter/more accurate since every real caller's map uses atom keys exclusively; either is acceptable and both were confirmed live to reduce the error count to 0.

**Live verification performed and reverted (repo left clean):**
1. Applied the spec change above (only line changed in the whole repo).
2. `mix compile --force` → clean.
3. `mix dialyzer` → `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`, exit code 0. **All 133 errors across all 10 files cleared from this one edit** — no other file needed a change.
4. Ran the full byte-identity/golden suite (9 files, 27 tests: 7 recipe `*_byte_identity_test.exs` + `table_byte_identity_test.exs` + `theme_mode_background_golden_test.exs`) → `27 tests, 0 failures` — identical to pre-fix baseline.
5. Reverted via `git checkout -- lib/rendro/recipes/background.ex`; confirmed `git status --short` clean and `mix dialyzer` back to `Total errors: 133`.

**`ticket.ex` itself requires ZERO changes.** Its own `@spec`s on `page_template/1`, `document/2`, `sections/2` (`ticket.ex:132`, `:224`, `:256`) are already correct — they only surfaced `invalid_contract`/`no_return` because the internal `Background.emit?(colors)` call (lines 171, 273) poisoned their success typing. Once `background.ex`'s spec is corrected, `ticket.ex`'s existing specs are satisfied as-is. This directly confirms D-03's closing clause ("If the true root cause turns out to be a genuine always-raises code path... surface it") does **not** apply here — it is purely a spec-shape bug, not a real bug, and the fix touches zero runtime-executing code (only a `@spec` annotation, which Dialyzer reads at compile time and which has no runtime effect).

### Full caller list of `Background.emit?/1` (confirms the fix is valid for every consumer, not just Ticket)
| File | Call sites | Source of `colors` argument |
|------|-----------|------------------------------|
| `statement.ex` | `:211`, `:273` | `palette(opts)` — 5-key nil-branch map (no `accent`/`on_accent`) or `Rendro.Theme.resolve(theme).colors` (9-key) |
| `payslip.ex` | `:166`, `:226` | `palette(opts)` — 7-key nil-branch map or `Theme.resolve(theme).colors` (9-key) |
| `ticket.ex` | `:171`, `:273` | `palette(opts)` — 7-key nil-branch map or `Theme.resolve(theme).colors` (9-key) |
| `certificate.ex` | `:143`, `:220` | `palette(opts)` — 4-key nil-branch map (`ink`/`muted`/`background`/`rule` only) or `Theme.resolve(theme).colors` (9-key) |
| `branded_invoice.ex` | `:105`, `:155` | `palette(opts)` — 7-key nil-branch map or `Theme.resolve(theme).colors` (9-key) |
| `invoice.ex` | `:134`, `:191` | `palette(opts)` — 7-key nil-branch map or `Theme.resolve(theme).colors` (9-key) |
| `receipt.ex` | `:178`, `:246` | `palette(opts)` — 7-key nil-branch map or `Theme.resolve(theme).colors` (9-key) |

Every one of these is a map with **at least** `:background` plus other keys — the exact shape the open-map spec above accepts, and the exact shape the closed-map spec above rejected. `Rendro.Theme.colors()` type (`lib/rendro/theme.ex:107-117`) confirms the 9-key `Theme.resolve/1` shape: `ink`/`muted`/`accent`/`on_accent`/`background`/`surface`/`rule`/`positive`/`negative`, each `rgb() :: {0..255, 0..255, 0..255}` — a subtype of `non_neg_integer()` triples, so the value-type half of the spec (`{non_neg_integer(), non_neg_integer(), non_neg_integer()}`) was always fine; only the closedness was wrong.

## Cross-cutting — byte-identity guardrail

### Golden suite command
```bash
mix test \
  test/rendro/recipes/branded_invoice_byte_identity_test.exs \
  test/rendro/recipes/certificate_byte_identity_test.exs \
  test/rendro/recipes/invoice_byte_identity_test.exs \
  test/rendro/recipes/payslip_byte_identity_test.exs \
  test/rendro/recipes/receipt_byte_identity_test.exs \
  test/rendro/recipes/statement_byte_identity_test.exs \
  test/rendro/recipes/ticket_byte_identity_test.exs \
  test/rendro/recipes/theme_mode_background_golden_test.exs \
  test/rendro/table_byte_identity_test.exs
```
**Baseline (confirmed live, before any fix):** `27 tests, 0 failures`.
**After the Target-3 spec fix applied (confirmed live):** `27 tests, 0 failures` — byte-identical, no change. None of these test files are gated behind `--include` tags; they run under the plain `mix test --exclude quarantine --slowest 10` in `ci.fast` step 4 too, so the golden suite is already exercised by the standard test run — no extra CI wiring needed.

### mix ci.fast step mapping (confirmed against `mix.exs:78-86`)
```elixir
"ci.fast": [
  "format --check-formatted",              # step 1 — Target 2 (formatter)
  "hex.build",                              # step 2 — confirmed clean, not in scope
  "compile --warnings-as-errors",           # step 3 — confirmed clean, not in scope
  "test --exclude quarantine --slowest 10", # step 4 — Target 1 (stale test) + byte-identity golden suite lives here
  "docs --warnings-as-errors",              # step 5 — confirmed clean, not in scope
  "credo --strict",                         # step 6 — confirmed clean, not in scope
  "dialyzer"                                # step 7 — Target 3
]
```
**Baseline full-suite state (confirmed live, `mix test --exclude quarantine`):** `12 doctests, 8 properties, 1699 tests, 2 failures` — the 2 failures are exactly the two Target-1 cases; nothing else is red. `mix hex.build`, `mix compile --warnings-as-errors`, `mix docs --warnings-as-errors`, and `mix credo --strict` were all run live and are already clean — confirming the phase's 3 targets are the *only* red/false-red gates, exactly as D-06 asserts.

## Common Pitfalls

### Pitfall 1: Assuming `%{key: type}` in a Dialyzer `@spec` is an open/permissive map type
**What goes wrong:** Writing `@spec f(%{key: type}) :: ...` looks like "accepts any map that has at least this key" but Dialyzer treats it as a **closed** map type (exactly this key set). Every real-world caller passing a richer map gets an "unwinnable" contract, and the resulting `no_return`/`invalid_contract` cascades outward through every caller — often producing dozens of confusing errors in files that were never touched.
**Why it happens:** The Elixir `%{key: type}` shorthand silently expands to `%{required(:key) => type}` with no trailing `optional(any()) => any()`; Erlang map types default to closed unless a catch-all clause is present.
**How to avoid:** Any `@spec` for a function that receives "a map with at least these keys" (a common pattern for loosely-typed options/config maps) must explicitly add `optional(atom()) => any()` (or `optional(any()) => any()`) to keep the type open.
**Warning signs:** `mix dialyzer` reports `invalid_contract`/`no_return` on functions whose bodies look completely correct, especially cascading across many unrelated-looking files that share a common helper call.

### Pitfall 2: Fixing only the file named in the ticket, missing the cascade origin
**What goes wrong:** If the plan only edits `ticket.ex` (per the phase title's literal wording) without touching `background.ex`, `mix dialyzer` will still report the full 133-error cascade (unchanged) — Ticket's own specs were never the problem.
**How to avoid:** The fix belongs entirely in `background.ex`. Confirmed live: editing only that one file's `@spec` clears 100% of the 133 errors.

### Pitfall 3: Deleting the 2 stale test cases without removing their now-dead module attributes
**What goes wrong:** `@uat_path`/`@metrics_path`/`@audit_path` become unused, producing `mix test`-time compiler warnings (harmless to CI exit code today, but noisy and a code-smell that a future strictness bump could turn into a real failure).
**How to avoid:** Delete lines 4-6 in the same edit as the two test blocks.

### Pitfall 4: Treating `mix format`'s bounded-check as optional
**What goes wrong:** If `mix format` (bare, no path filter) ever touches more than the known ~7-file set, that is a signal of a `.formatter.exs`/mix-format-version drift across contributor machines, not something to blindly commit — D-02's guardrail exists precisely to catch this.
**How to avoid:** Confirmed live this run: exactly 7 files touched, matching the audited list. No mismatch signal present. The plan should still `git status --short` after running `mix format` and assert the file count/list before committing, as a repeatable guard.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (ships with Elixir 1.19.5 / OTP 28.4.1) |
| Config file | `test/test_helper.exs` (standard; no bespoke config needed for this phase) |
| Quick run command | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` |
| Full suite command | `mix test --exclude quarantine --slowest 10` |

### Phase targets → Test map
| Target | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| Target 1 | Stale docs-contract cases removed, other 3 stay green | unit | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` | ✅ (edit existing file) |
| Target 2 | `mix format --check-formatted` exits 0 | static/format | `mix format --check-formatted` | ✅ (no new file) |
| Target 2 | No behavior regression from reformatting | unit | `mix test test/docs_contract/theme_industry_guard_test.exs test/docs_contract/theming_claims_test.exs test/rendro/recipes/certificate_typography_test.exs test/rendro/recipes/payslip_opts_threading_test.exs test/rendro/recipes/theme_mode_background_golden_test.exs test/rendro/recipes/themed_render_smoke_test.exs` | ✅ (existing files) |
| Target 3 | `mix dialyzer` exits 0 with 0 errors | static/type-check | `mix dialyzer` | ✅ (PLT already built) |
| Target 3 | Byte-identity guard holds after spec change | unit/golden | `mix test test/rendro/recipes/branded_invoice_byte_identity_test.exs test/rendro/recipes/certificate_byte_identity_test.exs test/rendro/recipes/invoice_byte_identity_test.exs test/rendro/recipes/payslip_byte_identity_test.exs test/rendro/recipes/receipt_byte_identity_test.exs test/rendro/recipes/statement_byte_identity_test.exs test/rendro/recipes/ticket_byte_identity_test.exs test/rendro/recipes/theme_mode_background_golden_test.exs test/rendro/table_byte_identity_test.exs` | ✅ (existing files) |
| Cross-cutting | Full `ci.fast` chain green end-to-end | integration | `mix ci.fast` | ✅ (existing alias) |

### Sampling Rate
- **Per task commit:** run the specific target's scoped command above (e.g. after the `background.ex` spec edit, run `mix dialyzer` + the byte-identity suite; after the test-file edit, run the scoped docs-contract test).
- **Per wave/phase merge:** `mix ci.fast` in full (all 7 steps green, exit 0).
- **Phase gate:** `mix ci.fast` green + byte-identity golden suite green (already covered by step 4, but worth calling out explicitly per D-06's "central regression guard") before `/gsd-verify-work`.

### Wave 0 Gaps
None — every test file referenced above already exists; this phase edits existing files (`background.ex`'s `@spec`, the docs-contract test body, and `mix format` on 7 already-tracked files). No new test infrastructure or fixtures are required.

## Security Domain

Not applicable. This phase makes zero changes to authentication, session handling, input validation, cryptography, or any code path with a trust boundary — it is a `@spec` correction, a test-body edit, and whitespace formatting. No ASVS categories apply.

## Risks / Landmines

1. **Widening `emit?/1`'s spec could theoretically hide a real future error.** Because the new spec accepts any map with a `:background` key (any value type for other keys), a genuine future bug (e.g. a caller accidentally passing `colors.background` as a string) would still be caught at the type level for the `:background` value itself (still typed as `{non_neg_integer(), non_neg_integer(), non_neg_integer()}`), but a bug in one of the *other* keys (`ink`, `muted`, etc.) would not be caught by this spec — it never was, since those keys aren't part of `emit?/1`'s contract at all (the function only reads `:background`). No regression in caught-bug surface area versus the (broken) status quo.
2. **`mix format` touching `lib/rendro/launch_artifacts.ex`** is the one non-test file in the 7. Double-check post-format that this file's `git diff` is reviewed carefully (it was — confirmed pure string-literal-collapse, no logic) since it's `lib/` code that ships in the Hex package, not test-only code.
3. **Do not conflate this phase's 133-error dialyzer cascade with "133 new bugs to fix."** All 133 are the *same* root cause; fixing `background.ex` alone clears all of them. A plan that tries to "fix" `recipes.ex`, `launch_artifacts.ex`, or `rendro.visual_uat.ex` individually is unnecessary scope creep and risks touching runtime code that D-03's guardrail explicitly forbids.
4. **The `visual_uat.ex` mix task and its 16 dialyzer errors are entirely a side effect of the same cascade** (it calls `Rendro.Recipes.BrandedInvoice.document/1` directly) — not a separate, unrelated debt item. Confirmed by code inspection (`render_and_rasterise/1` at `rendro.visual_uat.ex:118-119`). No separate fix needed there.
5. **WINDOWS.md ids 4, 5, 6 map 1:1 to Targets 2, 1, 3 respectively.** Once the plan lands and verifies, these three ledger entries should be marked fixed (`gsd-tools windows fixed 4`, `5`, `6`) — an execution-phase action, noted here so the plan doesn't drop it. Ids 1, 2, 3, 7 remain untouched/out of scope (id 2 is the explicitly-locked Ticket hierarchy regression; id 7 is the pdfium-cli environment gap).
6. **`mix hex.build` produces a stray `rendro-1.0.0.tar` artifact in the repo root** when run locally (confirmed — this happened during this research session and was cleaned up). Not part of this phase's scope, but worth a one-line note so whoever executes doesn't accidentally commit it.

## Sources

### Primary (HIGH confidence — all reproduced live this session)
- `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` — exact failure output, case-by-case
- `mix format --check-formatted` / `mix format` (live run + revert) — exact 7-file list, diff-stat, hunk inspection
- `mix dialyzer` (live run against the pre-built PLT, live spec-edit + re-run + revert) — exact 133-error baseline, exact root cause, exact fix, exact 0-error confirmation
- `lib/rendro/theme.ex:95-117` — `Rendro.Theme.colors()` type definition (9-key `rgb()` map)
- `lib/rendro/recipes/{ticket,statement,payslip,certificate,branded_invoice,invoice,receipt}.ex` — all 7 recipes' `palette/1` private helpers, read in full
- `mix.exs:75-108` — `ci.fast`/`ci.proofs`/`ci.advisory` alias definitions, dialyzer PLT config
- `git diff`, `git status --short` after every experimental edit — confirms bounded/formatting-only claims

### Secondary (MEDIUM confidence)
- Erlang/Dialyzer map-type closedness semantics (`%{k: v}` shorthand = closed map type) — well-established Dialyzer behavior, not directly re-derived from Erlang's official reference docs in this session, but empirically confirmed via the live before/after spec-edit test (133 errors → 0 with only the openness change, value-type unchanged) — this constitutes direct empirical proof of the mechanism regardless of doc citation.

### Tertiary (LOW confidence)
None — every claim in this document was either read directly from source files in this repo or reproduced via a live command in this session.

## Metadata

**Confidence breakdown:**
- Target 1 (stale test) mechanism: HIGH — both cases' full bodies read, failure reproduced, fix reproduced (deletion + attribute cleanup) and re-verified green
- Target 2 (formatter): HIGH — exact file list, diff, and bounded-check all reproduced live
- Target 3 (dialyzer): HIGH — root cause and fix both empirically verified live (133→0), not inferred; caller list confirmed via full-file reads of all 7 recipes

**Research date:** 2026-07-28
**Valid until:** Until the next `mix.exs`/dialyxir/Elixir version bump, or until any of the 7 recipe `palette/1` helpers change shape — treat as valid for the remainder of this milestone's remediation (no expiry concern; this is a point-in-time maintenance fix, not an evolving external dependency).
