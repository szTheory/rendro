# Deferred Items — Phase 123 Plan 05 (Task 3 phase-gate run)

Found while running the Task 3 phase gate (`mix ci.fast` / `mix ci.advisory`). None of these
are caused by this plan's changes (`priv/quality/rubric_scores.json`, `priv/quality/SIGN-OFF.md`,
`priv/schemas/rubric_scores.schema.json`, `test/docs_contract/rubric_manifest_contract_test.exs`
— all last touched only by commit `5eda766`, verified via the isolation proof). Per the executor's
SCOPE BOUNDARY rule, these are out of scope for this plan and are NOT fixed here.

## 1. `mix format --check-formatted` fails on 7 pre-existing files

None were touched by this plan's commit. Last-touched history (all earlier phases/plans):

- `test/docs_contract/theme_industry_guard_test.exs` — last touched `8d779a5` (119-02)
- `lib/rendro/launch_artifacts.ex` — last touched `53e1ba7` (123-03)
- `test/docs_contract/theming_claims_test.exs` — last touched `814e1df` (123-04)
- `test/rendro/recipes/payslip_opts_threading_test.exs` — last touched `553f748` (122-05)
- `test/rendro/recipes/themed_render_smoke_test.exs` — last touched `54d2cbe` (122-05)
- `test/rendro/recipes/certificate_typography_test.exs` — last touched `101c1b7` (122-05)
- `test/rendro/recipes/theme_mode_background_golden_test.exs` — last touched `bacd712` (121-02)

Likely local-Elixir-formatter-version drift vs. whatever produced these files' committed
formatting (multi-line map/pipe reformatting, not a logic change). Because `ci.fast`'s alias
chain runs `format --check-formatted` FIRST, this single step blocks every subsequent `ci.fast`
step (`hex.build`, `compile --warnings-as-errors`, `test`, `docs --warnings-as-errors`, `credo`,
`dialyzer`) from running as a chain, though each was verified individually below.

## 2. 2 pre-existing test failures unrelated to phase 123 rubric work

`test/docs_contract/dx_local_reproducibility_claims_test.exs` — both failures are
`File.Error: could not read` on `.planning/phases/113-dx-local-reproducibility-validation/113-UAT.md`
and `113-METRICS.md`, which do not exist in this working tree's `113-dx-local-reproducibility-validation/`
directory (only partial phase-113 planning artifacts are present — see untracked
`.planning/phases/113-*` files at session start). Unrelated to phase 123's rubric/gallery/theming work.

## 3. `mix dialyzer` fails on pre-existing `lib/rendro/recipes/ticket.ex` contract errors

`no_return` / `call` breaks-the-contract errors on `Ticket.document/1,2`, `Ticket.sections/1,2`,
and a `Rendro.Recipes.Background.emit?/1` contract mismatch. Not touched by this plan's commit.
Plausibly related to the same Ticket hierarchy-inversion regression this plan's honest
`passed: false` score already documents (`.planning/WINDOWS.md` id 2) — but a dialyzer type-contract
fix is a separate, `lib/`-touching change outside this plan's D-05 Commit 3 isolation scope.

## 4. `mix rendro.launch_artifacts.check` (part of `ci.advisory`) fails: `pdfium-cli` not installed

`{:missing_executable, "pdfium-cli"}` — this execution environment does not have the pinned
`pdfium-cli` v0.11.0 binary (`priv/pdfium_pin.json`) on `PATH`. This is an environment/tooling
gap, not a code or manifest defect; per the executor's package-install exclusion, external
binaries are not auto-installed without human verification. `mix hex.build` (the tarball-packaging
step of `ci.fast`), `mix compile --warnings-as-errors`, `mix docs --warnings-as-errors`,
`mix credo --strict`, and the full `mix test --exclude quarantine` run (except item 2 above) were
all verified individually and are clean.

## What WAS verified clean for this plan's own changes

- `mix test test/docs_contract/rubric_manifest_contract_test.exs` — 74 tests, 0 failures (includes
  the new sign-off teeth loop, green with Ticket's honest `passed:false` present).
- `mix compile --warnings-as-errors` — clean.
- `mix docs --warnings-as-errors` — clean.
- `mix credo --strict` — 3159 mods/funs, no issues.
- `mix hex.build` — tarball builds successfully (1.0.0, checksum recorded, tarball removed after check).
- Git isolation proof: `git show --stat --name-only 5eda766` lists ONLY
  `priv/quality/SIGN-OFF.md`, `priv/quality/rubric_scores.json`,
  `priv/schemas/rubric_scores.schema.json`, `test/docs_contract/rubric_manifest_contract_test.exs`
  — zero `lib/` or `assets/` paths.
