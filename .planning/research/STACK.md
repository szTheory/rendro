# Stack Research — v2.4 Batteries-Included Workflow & Adoption Closure

**Domain:** Rendro v2.4 — page-numbering/running-footer primitive, three new production recipes (Statement, Receipt/Report, Certificate), and a `mix`-runnable CI-exercised reference Phoenix app
**Researched:** 2026-05-29
**Confidence:** HIGH for all version pins (verified against Hex.pm, GitHub releases, and official sources as of 2026-05-29). HIGH for the pure-core determination (derives from direct inspection of the existing paginate pipeline, not external sources).

---

## Headline Recommendation

**Feature 1 (page-numbering/running-footer primitive): zero new dependencies — pure-core extension only.**

The existing `Rendro.Pipeline.Paginate` already performs a single-pass pagination followed by a per-page `apply_page_template/3` call that resolves `{{page_number}}` tokens. Total page count is available at the call site (it is `length(pages)` after the pagination accumulation). Extending to `{{page_count}}` and `{{carried_forward.<key>}}` tokens is a localized change to `replace_page_numbers/2` and its callers — no new library, no new pipeline stage, no fork of the rendering path.

**Feature 2 (three new production recipes): zero new dependencies — pure-core authoring only.**

Recipes are authored using existing `Rendro.Document`, `Rendro.PageTemplate`, `Rendro.Section`, `Rendro.Block`, `Rendro.Text`, `Rendro.Table` structs. No additional Hex libraries are needed for Statement, Receipt/Report, or Certificate; these are data-to-document transformations using the already-shipped pipeline. The docs-contract test pattern already used by `Invoice` and `BrandedInvoice` carries over unchanged.

**Feature 3 (reference Phoenix app): bounded, isolated additions inside `examples/phoenix_example/` only.**

The reference app is an isolated Mix project (`path: "../.."` dep, no Hex publish, no runtime entry in core `mix.exs`). Stack additions for the reference app are confined to that sub-project and do not touch the core library's dependency surface. The CI extension is a new step inside the existing `test` job (or a new named job), not a new required status check that widens the core compliance surface.

---

## Recommended Stack

### Core Technologies — No Change

| Technology | Current version (locked) | Purpose | Notes |
|------------|--------------------------|---------|-------|
| Elixir | `~> 1.19` (locked: `1.19.5`) | Core library language | No change. CI currently pins `1.19.5` with OTP 28. |
| OTP | `28` (CI pin) | BEAM runtime | OTP 28.5.0.1 is the current latest patch (released 2026-05-27). CI pin of `28` resolves to latest patch automatically via `erlef/setup-beam`. |
| `telemetry ~> 1.4` | locked `1.4.1` | Runtime observability | Unchanged; recipes and primitive emit telemetry through the existing pipeline hooks. |
| `harfbuzz_ex ~> 1.2` | locked `1.2.0` | Text shaping (HarfBuzz NIF) | Unchanged; text measurement and layout in recipes use the existing shaper. |
| `unicode_data ~> 0.8.0` | locked `0.8.0` | Unicode normalization | Unchanged. |

### Supporting Libraries — No New Runtime Deps

All existing dev/test-only libraries are unchanged. No new Hex package is needed for any of the three v2.4 features at the core level.

| Library | Version (locked) | Scope | Purpose |
|---------|-----------------|-------|---------|
| `ex_doc ~> 0.40` | locked `0.40.1`; latest Hex `0.40.3` (2026-05-21) | dev/test | ExDoc guide wiring for new recipe guides. Three new `guides/recipes/*.md` files should be added to `extras:` in `mix.exs docs/0`. No version bump needed; `~> 0.40` already matches `0.40.3`. Consider bumping the lock to `0.40.3` for latest ExDoc sidebar/search improvements but this is cosmetic. |
| `stream_data ~> 1.3` | locked `1.3.0` | dev/test | Property-based testing for recipe determinism. Already used; new recipe tests may add cases but no version change needed. |
| `credo ~> 1.7` | locked `1.7.18` | dev/test | Linting for new recipe modules. Unchanged. |
| `dialyxir ~> 1.4` | locked `1.4.7` | dev/test | Type checking for new recipe modules. Unchanged. |
| `jsv ~> 0.18` | locked `0.19.1` | dev/test | JSON Schema validator for `priv/support_matrix.json`. Unchanged from v2.3. |
| `yaml_elixir ~> 2.12` | locked `2.12.1` | dev/test | YAML frontmatter parsing for viewer-evidence files. Unchanged. |
| `req ~> 0.5` | locked `0.5.17` | dev/test | HTTP in test helpers. Unchanged. |

### Reference App (`examples/phoenix_example/`) — Scoped Additions

These additions are **strictly confined to `examples/phoenix_example/mix.exs`** and have **zero effect on the core `rendro` library's dependency surface** or its `mix.exs`.

| Technology | Current version | Recommended version | Purpose | Why |
|------------|----------------|---------------------|---------|-----|
| Phoenix | `~> 1.7` (locked `1.8.5`) | Update constraint to `~> 1.8` | Web framework for reference endpoints | Phoenix 1.8.7 is the current latest stable (released 2026-05-06). The lock already resolves to 1.8.5; updating the constraint from `~> 1.7` to `~> 1.8` in `phoenix_example/mix.exs` accurately reflects what is actually running and enables resolving 1.8.7. |
| Bandit | `~> 1.0` (locked: inspect mix.lock) | `~> 1.0` (latest `1.11.1`, 2026-05-13) | Pure-Elixir HTTP server | Already the default HTTP server for Phoenix since 1.7.11. No change needed; constraint is already permissive enough to resolve to 1.11.1. |
| Jason | `~> 1.2` | `~> 1.4` | JSON encoding | Jason 1.4.5 is latest (2026-05-05). Update constraint in `phoenix_example/mix.exs` to `~> 1.4`. Not a breaking change. |
| Plug | `~> 1.14` | `~> 1.14` (latest `1.19.1`) | Conn pipeline | Already resolves to 1.19.1 via `~> 1.14`. No change needed. |
| Elixir (phoenix_example) | `~> 1.15` | `~> 1.19` | Language requirement | The example's `mix.exs` currently requires `~> 1.15` while the core requires `~> 1.19`. Align the example to `~> 1.19` to match the core and CI environment. This is a quality-of-life fix, not a breaking change. |

### CI — Targeted Extension Only

| Area | Current | Recommended for v2.4 | Rationale |
|------|---------|----------------------|-----------|
| `erlef/setup-beam` version | `@v1` (floating) | Keep `@v1` for now | Already in use across all jobs. The `@v1` floating tag is fine for this project given CI is never published as a reusable action. |
| Elixir version in CI | `1.19.5` | Keep `1.19.5` | 1.19.5 is the latest stable (released 2026-01-09); 1.20 is still in RC (rc.6 as of 2026-05-21). Stay on 1.19.5 until 1.20.0 stable ships. |
| OTP version in CI | `28` | Keep `28` | OTP 28.5.0.1 is the latest patch. `28` resolves correctly via setup-beam. OTP 29 dropped but `~> 1.19` requires OTP 27+; no urgent reason to pin to 29 in v2.4. |
| ubuntu runner | `ubuntu-latest` (resolves to Ubuntu 24.04) | Keep `ubuntu-latest` | ubuntu-latest resolved to Ubuntu 24.04 since Oct 2024; Ubuntu 26.04 not yet in ubuntu-latest as of 2026-05-29. |
| phoenix_example CI step | `cd examples/phoenix_example && mix deps.get && mix compile` | Extend to also run `mix test` | The example already has `PDFControllerTest`. The CI step only compiles today; it should also run the test suite to make it genuinely "exercised in CI" as specified. No new job needed — extend the existing `Verify Phoenix Example` step in the `test` job. |
| ExDoc guide wiring | Existing `extras:` list in `mix.exs docs/0` | Add three new recipe guide paths | New `guides/recipes/statement.md`, `guides/recipes/receipt_report.md`, `guides/recipes/certificate.md` should be added to `extras:` under a new `"Recipes"` group in `groups_for_extras:`. Verified with existing ExDoc `0.40.x` — no version bump needed. |

---

## What NOT to Add

This is the critical boundary list for v2.4. All of these would violate the pure-core constraint or are unnecessary.

| Do Not Add | Why | What to Do Instead |
|------------|-----|-------------------|
| Any new runtime Hex dep in core `mix.exs` | All three features are pure-core Elixir; adding a runtime dep for any of them would break the "pure-core/no-hard-Phoenix/no-hard-Oban" constraint and widen the install surface for every downstream user | Implement entirely with existing structs, pipeline, and interpolation logic |
| Phoenix, Oban, Bandit, Jason, or any other app-layer dep in core `mix.exs` runtime section | These are already `optional: true`; promoting any of them to required would collapse the library/adapter boundary that has held from v1.0 through v2.3 | Keep optional; reference app uses them as `path:` dep additions only |
| A second pipeline stage or a fork of `Rendro.Pipeline.Paginate` for "running content" | Would create a second rendering path, which the project constraint explicitly forbids | Extend `apply_page_template/3` and `replace_page_numbers/2` in the existing paginate stage — total page count is already available at the call site |
| Any JavaScript, Node, Python, or external binary for the page-numbering or recipe features | Pure computation in Elixir; no rendering engine needed | All arithmetic and string interpolation is native Elixir |
| LiveView, Ecto, phoenix_live_dashboard, Swoosh, Gettext, esbuild, or Tailwind in the reference app | Not needed for a PDF-generation reference app; these add install-and-config complexity that obscures the actual integration story | Use `phx.new --no-ecto --no-live --no-dashboard --no-mailer --no-gettext` flags if ever regenerating from scratch; the existing minimal setup already omits them |
| A new required CI status check for the reference app | Adding a required check widens the protected gates beyond what v2.4 ships as core behavior; the reference app is adoption proof, not engine proof | Extend the existing `Verify Phoenix Example` step in the `test` job — the `test` job is already required on `main` |
| A Hex-published `rendro_phoenix` or `rendro_examples` package | Adoption proof lives in the repo; publishing a separate package adds a maintenance surface before the 1.0 API contract is cut | Keep as `path: "../.."` in the example; document the pattern for users to follow directly |
| Upgrading `oban` beyond `~> 2.17` (core) | No v2.4 feature uses Oban; the reference app demonstrably does not need Oban for page-numbering or recipe demos | Leave at `~> 2.17`, optional. Current Oban latest is 2.23.0 (2026-05-27); upgrade if/when Oban functionality is expanded, not for cosmetic reasons. |
| Any new viewer-evidence tooling, compliance validator, or signing adapter | v2.4 is adoption ergonomics; the proof/trust axis is at diminishing returns per the scoping thread | Inherit v2.3's evidence discipline for any new recipe surfaces, but do not add new evidence infrastructure |

---

## Integration Points

### 1. Page-Numbering / Running-Footer Primitive (pure-core)

**Where it lives:** `lib/rendro/pipeline/paginate.ex` — specifically `apply_page_template/3` and `replace_page_numbers/2`.

**What changes:**
- Pass total page count into `apply_page_template/3` so the function signature becomes `apply_page_template(page, idx, total, layout)`.
- Extend `replace_page_numbers/2` to also resolve `{{page_count}}` using the total.
- Optionally add a `{{carried_forward.<key>}}` interpolation token that receives a map of caller-supplied totals (e.g., `carried_forward: %{subtotal: "1,500.00"}`), computed by the recipe before calling `Rendro.render/2` via the document's options map.
- No new module, no new pipeline stage, no new dependency. The change is additive and backward-compatible: documents that do not use `{{page_count}}` are unaffected.

**Test surface:** New unit tests in `test/rendro/pipeline/paginate_test.exs` asserting that `{{page_count}}` is resolved to the final page total. Property-based tests (using existing `stream_data`) asserting determinism across multi-page documents.

**Docs contract:** A new `guides/running_content.md` guide (or a section in `guides/integrations.md`) added to `extras:` in `mix.exs` docs.

### 2. Three New Production Recipes (pure-core authoring)

**Where they live:** `lib/rendro/recipes/statement.ex`, `lib/rendro/recipes/receipt_report.ex`, `lib/rendro/recipes/certificate.ex` — plus dispatcher functions in `lib/rendro/recipes.ex`.

**What changes:**
- New recipe modules following the exact `document/1` → `page_template/1` → `sections/1` three-rung pattern established by `Invoice` and `BrandedInvoice`.
- New entries in `mix.exs` docs `groups_for_modules:` under `"Canonical Recipes"`.
- New guide files under `guides/recipes/` (or `guides/`) added to `extras:` under a `"Recipes"` group in `groups_for_extras:`.
- No new dependency of any kind.

**Test surface:** Docs-contract tests following the existing `Invoice` pattern: verify the `%Rendro.Document{}` struct shape, named regions, non-empty sections, and that `Rendro.render/2` produces a valid artifact. Add `{{page_count}}` usage in at least one recipe (Statement is the natural candidate — multi-page statement with "Page X of Y" footer).

### 3. Reference Phoenix App — CI Extension and Quality Lift

**Where it lives:** `examples/phoenix_example/` — entirely isolated from core `mix.exs`.

**What changes:**
- Update `mix.exs` Elixir constraint from `~> 1.15` to `~> 1.19`.
- Update `phoenix` constraint from `~> 1.7` to `~> 1.8`.
- Update `jason` constraint from `~> 1.2` to `~> 1.4`.
- Add a `README.md` at `examples/phoenix_example/README.md` explaining how to run the app locally (`mix deps.get && mix phx.server`), what routes it serves, and how it demonstrates each recipe.
- Extend the existing `Verify Phoenix Example` CI step in `ci.yml` to run `mix test` in addition to `mix deps.get && mix compile`. The existing `PDFControllerTest` already tests the two invoice recipes; add tests for the three new recipes as they ship.
- Add demonstration routes/actions for the three new recipes in `pdf_controller.ex` — one download + one preview per recipe, following the existing invoice/branded_invoice pattern.
- No new required CI job. The `test` job (already required on `main`) contains the `Verify Phoenix Example` step.

**ExDoc guide wiring for new recipes:**

```elixir
# In mix.exs docs/0, extend extras: and groups_for_extras:
extras: [
  "README.md",
  "guides/running_content.md",      # NEW: page-numbering / running-footer guide
  "guides/recipes/statement.md",    # NEW
  "guides/recipes/receipt_report.md", # NEW
  "guides/recipes/certificate.md",  # NEW
  "guides/integrations.md",
  "guides/branding.md",
  "guides/api_stability.md",
  "guides/viewer_evidence.md"
],
groups_for_extras: [
  "Guides": [
    "guides/running_content.md",
    "guides/branding.md",
    "guides/integrations.md"
  ],
  "Recipes": [
    "guides/recipes/statement.md",
    "guides/recipes/receipt_report.md",
    "guides/recipes/certificate.md"
  ],
  "Policies": [
    "guides/api_stability.md",
    "guides/viewer_evidence.md"
  ]
]
```

---

## Version Compatibility

| Package | Constraint in `mix.exs` | Locked version | Latest available | Action |
|---------|------------------------|---------------|-----------------|--------|
| Elixir (core) | `~> 1.19` | `1.19.5` | `1.19.5` stable; `1.20.0-rc.6` | No change. Stay on 1.19.5 for v2.4. |
| OTP (CI pin) | `28` | (system) | `28.5.0.1` (2026-05-27) | No change. `28` resolves correctly. |
| `phoenix` (optional, core) | `~> 1.7` | `1.8.5` | `1.8.7` (2026-05-06) | No change needed in core `mix.exs`. Update in reference app only. |
| `plug` (optional, core) | `~> 1.14` | `1.19.1` | `1.19.1` | No change. |
| `oban` (optional, core) | `~> 2.17` | `2.21.1` | `2.23.0` (2026-05-27) | No change needed for v2.4 features. |
| `ex_doc` | `~> 0.40` | `0.40.1` | `0.40.3` (2026-05-21) | Optional: bump lock to `0.40.3` for latest improvements. Constraint already matches. |
| `jsv` | `~> 0.18` | `0.19.1` | `0.19.1` | No change. |
| `telemetry` | `~> 1.4` | `1.4.1` | `1.4.1` | No change. |
| `harfbuzz_ex` | `~> 1.2` | `1.2.0` | `1.2.0` | No change. |
| Phoenix (reference app) | `~> 1.7` | `1.8.5` | `1.8.7` | Update constraint to `~> 1.8` in `phoenix_example/mix.exs`. |
| Bandit (reference app) | `~> 1.0` | (see lock) | `1.11.1` (2026-05-13) | No change. Constraint already resolves to 1.11.1. |
| Jason (reference app) | `~> 1.2` | (see lock) | `1.4.5` (2026-05-05) | Update constraint to `~> 1.4` in `phoenix_example/mix.exs`. |
| Elixir (reference app) | `~> 1.15` | — | `1.19.5` | Update constraint to `~> 1.19` in `phoenix_example/mix.exs`. |

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| Extend `replace_page_numbers/2` in-place for `{{page_count}}` | New pipeline stage `Rendro.Pipeline.ResolveRunningContent` | A new stage would be premature abstraction: the only call site is `apply_page_template` in Paginate, and total page count is already computable at that site with `length(pages)`. New stages add to the pipeline's cognitive complexity before the feature justifies it. |
| `{{page_count}}` interpolation token | Requiring callers to pre-compute and inject total via a document option | Callers cannot know total pages before pagination runs — that is the entire point of the primitive. The pipeline must resolve it post-pagination. |
| Extend existing `test` job's `Verify Phoenix Example` step | New required CI job for the reference app | A new required job is a gate-widening decision. The reference app proves adoption ergonomics, not engine correctness. Adding it to the existing required `test` job's steps is the minimal CI extension that proves the app compiles, runs, and its tests pass without creating a new blocked-merge gate. |
| `phx.new --no-ecto --no-live --no-dashboard --no-mailer --no-gettext` for any fresh generation | Full-featured Phoenix generator defaults | The reference app needs only a router, a controller, and a Plug pipeline. All the LiveView/Ecto/Mailer machinery obscures the PDF-generation integration story and adds config noise. The existing minimal setup already omits these correctly. |
| In-tree `guides/recipes/` for recipe documentation | Adding recipe docs to `README.md` | Recipes need enough context (data shape, output description, escape-hatch commentary) that inline README sections become unwieldy. ExDoc extras with a `"Recipes"` group gives navigable, searchable per-recipe pages. |

---

## Sources

- Rendro repo direct inspection: `lib/rendro/pipeline/paginate.ex` (lines 397–455), `mix.exs`, `examples/phoenix_example/mix.exs`, `.github/workflows/ci.yml` — HIGH; primary source for all pure-core determinations and existing version pins
- [hex.pm/packages/phoenix/versions](https://hex.pm/packages/phoenix/versions) — Phoenix 1.8.7 as of 2026-05-06 (HIGH)
- [phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html](https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html) — confirmed `--no-ecto`, `--no-live`, `--no-dashboard`, `--no-mailer`, `--no-gettext` flags in Phoenix 1.8.7 (HIGH)
- [hex.pm/packages/bandit](https://hex.pm/packages/bandit) — Bandit 1.11.1 as of 2026-05-13 (HIGH)
- [hex.pm/packages/jason](https://hex.pm/packages/jason) — Jason 1.4.5 as of 2026-05-05 (HIGH)
- [hex.pm/packages/ex_doc](https://hex.pm/packages/ex_doc) — ExDoc 0.40.3 as of 2026-05-21 (HIGH)
- [hex.pm/packages/oban](https://hex.pm/packages/oban) — Oban 2.23.0 as of 2026-05-27 (HIGH)
- [github.com/elixir-lang/elixir/releases](https://github.com/elixir-lang/elixir/releases) — Elixir 1.19.5 stable (2026-01-09), 1.20.0-rc.6 pre-release (2026-05-21) (HIGH)
- [erlang.org/download/OTP-28.5.README](https://erlang.org/download/OTP-28.5.README) — OTP 28.5.0.1 as of 2026-05-27 (HIGH)
- [github.com/erlef/setup-beam/blob/main/README.md](https://github.com/erlef/setup-beam/blob/main/README.md) — confirmed `@v1` floating tag pattern; recommended matrix includes OTP 25/26/27 + Elixir 1.17/1.18 in examples; pinning to `@v1` is acceptable for non-reusable internal workflows (HIGH)
- [github.com/actions/runner-images — ubuntu-latest = Ubuntu 24.04](https://github.com/actions/runner-images/issues/10636) — migration to Ubuntu 24.04 completed Oct 2024; Ubuntu 26.04 not yet assigned to ubuntu-latest label as of 2026-05-29 (MEDIUM — based on search result, not direct runner-images query)

---
*Stack research for: Rendro v2.4 Batteries-Included Workflow & Adoption Closure*
*Researched: 2026-05-29*
