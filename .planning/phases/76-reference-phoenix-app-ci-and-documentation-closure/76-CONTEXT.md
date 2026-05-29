# Phase 76: Reference Phoenix App, CI, and Documentation Closure - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

A Phoenix engineer arriving at the repository can run the reference app locally, read a HexDocs guide for the PAGE primitive and each recipe, and see CI prove the example is exercised — all without touching engine-critical proof lanes.

**In scope (REF-01, REF-02, REF-03, CONTRACT-02):**
- Modernize `examples/phoenix_example` to non-stale constraints (Phoenix `~> 1.8`, Jason `~> 1.4`, Elixir `~> 1.19`), add a README, keep it `mix`-runnable.
- Demonstrate all five shipped recipes (Invoice, BrandedInvoice, Statement, Receipt/Report, Certificate) through `Rendro.Adapters.Phoenix`.
- Add an isolated, **non-required** `example-phoenix` CI job running `mix test` against the reference app.
- Author HexDocs guides for the PAGE primitive + recipes, wired into ExDoc extras, with docs-contract tests rejecting claims beyond `priv/support_matrix.json` + proof lanes.

**Out of scope:** New engine capabilities, new recipes, changes to engine-critical proof lanes (`signing-live-proof`, `long-lived-live-proof`, `release-proof`, `test`), live GitHub branch-protection config (managed outside the repo).
</domain>

<decisions>
## Implementation Decisions

Discussion ran in `--auto` advisor mode (calibration tier `minimal_decisive`). Each area was grounded by a parallel research agent reading the actual codebase; the recommended (decisive) option was locked. Findings are concrete and reuse the project's existing disciplines verbatim.

### Phoenix Reference-App Modernization Strategy
- **D-01:** Upgrade the existing scaffold **in place** — do NOT regenerate with `mix phx.new`. The app is already a hand-rolled minimal Phoenix 1.8-line app (its `mix.lock` resolves Phoenix 1.8.5 / jason 1.4.4 / plug 1.19.1) with deliberately zero generator boilerplate (no Ecto/assets/LiveView/daisyUI/gettext). Regeneration would only re-add the boilerplate the app was built to omit and force re-porting all recipe controllers.
- **D-02:** Final dep constraints for `examples/phoenix_example/mix.exs`: `{:phoenix, "~> 1.8"}`, `{:jason, "~> 1.4"}`, `{:plug, "~> 1.18"}` (bandit 1.10 already requires `~> 1.18`; current `~> 1.14` is misleadingly low), `{:bandit, "~> 1.0"}`, `{:rendro, path: "../.."}`. Set `elixir: "~> 1.19"` to match the root library.
- **D-03:** **Load-bearing bug fix:** `examples/phoenix_example/config/config.exs` references `PhoenixExampleWeb.ErrorJSON` (render_errors handler) but no such module exists. Add a minimal `lib/phoenix_example_web/controllers/error_json.ex` so render-error handling is not broken.
- **D-04:** Verification gate after edits: `mix deps.get && mix compile --warnings-as-errors && mix phx.server` to confirm REF-01 `mix`-runnable + clean re-lock. Author the README documenting setup + each demonstrated recipe.

### Recipe Demonstration Surface
- **D-05:** Extend the **existing plain dead-controller pattern** — do NOT introduce LiveView (it isn't a dependency and contradicts the minimal/PDF-only mandate) or a shared SampleData module. Add one `download` + one `preview` action per new recipe (Statement, Receipt, Certificate) on `PDFController`, mirroring the shipped Invoice/BrandedInvoice surface that already calls the adapter `render_pdf/3` (attachment) and `preview_pdf/2` (inline).
- **D-06:** Sample data lives as **inline module attributes** on `PDFController` (consistent with current `@demo_invoice`/`@demo_branded_invoice`). Fixture shapes (confirm against recipe moduledocs during planning): Statement `%{period: %{from,to}, account: %{name}, opening_balance: Decimal, lines: [%{date, description, amount(Decimal)}]}`; Receipt `%{title, date, customer: %{name}, lines: [%{description, amount(Decimal)}], totals?: %{subtotal, total}}`; Certificate `%{title, recipient, date, body?, seal_line?}` (landscape A4 default; no brand for base demo).
- **D-07:** Index page (`page_controller.ex`) gains download + preview links per new recipe. Routes mirror existing `/branded/*` in the `:api` scope: `/statement/{download,preview}`, `/receipt/{download,preview}`, `/certificate/{download,preview}`.
- **D-08:** Per-recipe `mix test` assertions (mirror existing Invoice/Branded tests — prove render-through-adapter without over-asserting bytes): `status == 200`; `content-type =~ "application/pdf"`; `binary_part(resp_body, 0, 5) == "%PDF-"`; plus one structural assertion re-running `document/2` and asserting `%Rendro.Document{}` with the recipe's expected `page_template` atom + non-empty sections (confirm each atom against source before writing).

### CI Isolation Mechanism
- **D-09:** New `example-phoenix` job uses `needs: []` (**fully independent**, not `needs: test`). Graph-disconnected so it can neither gate nor be gated by `test` / `signing-live-proof` / `long-lived-live-proof` / `release-proof`, and always produces its own visible green/red signal. (`viewer-evidence-live-proof` is the precedent for *how non-required is encoded* here, but its `needs: test` wiring is wrong for this job because it would suppress the example signal whenever engine `test` is red.)
- **D-10:** Job runs `working-directory: examples/phoenix_example` → `mix deps.get && mix test`, with `otp-version: '28'` / `elixir-version: '1.19.5'` matching the other jobs. **No `continue-on-error`** — REF-03 wants failure visible-but-non-blocking, and `continue-on-error` would mask red as green.
- **D-11:** **Remove** the now-redundant "Verify Phoenix Example" step (≈lines 31-35) from the required `test` job so Phoenix deps no longer run inside a required lane.
- **D-12:** Record non-required status in `priv/guardrails/required_status_checks.json` by adding `example-phoenix` to `advisory_contexts` (do NOT touch `required_contexts`/`contexts` — the four engine lanes stay required per the `additive_only` policy). Update `test/guardrails/required_checks_contract_test.exs`: it currently destructures a single-element advisory list (`[advisory] = ...`) which breaks with two entries — switch to an `Enum.find/2` lookup and add an assertion that the `example-phoenix` advisory entry exists (notes reference "not required" / "REF-03") and is absent from `required_contexts`. No live GitHub branch-protection change is encoded in-repo; the manifest is the in-repo source of truth.

### Guides + Docs-Contract Enforcement
- **D-13:** Author **two** new guides (not six): `guides/page_primitive.md` (PAGE primitive) and a consolidated `guides/recipes.md` (one `##` section per canonical recipe). The support matrix has exactly four new surface rows (`page_numbering`, `statement`, `receipt_report`, `certificate`) and NO separate `invoice`/`branded_invoice` rows — so the recipes guide's Invoice/BrandedInvoice section is a **pointer to `guides/branding.md`** (no new claims), preserving a single source of truth and avoiding guides whose claims have no matrix row to cross-check.
- **D-14:** Wire both guides into root `mix.exs` `docs/0` `extras:` (after `guides/viewer_evidence.md`) and add a `groups_for_extras:` group `"Recipes & Primitives": ["guides/page_primitive.md", "guides/recipes.md"]`. Add to `skip_undefined_reference_warnings_on:` if needed (matching branding/integrations).
- **D-15:** Reuse the project's **two existing harnesses, invent nothing new.** (1) Runnable API examples → tag elixir fences `# docs-contract: <id>` and verify via `Rendro.Test.DocsContract.verified_fences/1` + `evaluate!/2` (the branding mechanism). (2) Capability/scope claims → `*_claims_test.exs` that `File.read!` the guide, `assert guide =~ <backed phrase>` AND asserts the matching `priv/support_matrix.json` capability is `"supported"`, and `refute guide =~ <out-of-scope phrase>` for entries in the matrix `"unsupported"` array (`full_pdf_compliance`, `digital_signatures`). (3) Proof-lane linkage → assert each cited row's `evidence:` path exists on disk.
- **D-16:** New test files (3): `test/docs_contract/page_primitive_claims_test.exs` (cross-checks `page_numbering` row), `test/docs_contract/recipes_claims_test.exs` (cross-checks `statement`/`receipt_report`/`certificate` rows + asserts each row's evidence path exists), `test/docs_contract/recipes_contract_test.exs` (fence verification over both guides, mirroring `branding_contract_test.exs`). Register two semantic-claims lanes in `scripts/verify_docs.exs` (Recipes + Page-primitive); the fence-contract test runs in the normal suite like branding's does.

### Claude's Discretion
- README prose/structure, exact guide wording and example selection, fixture sample values, and `docs-contract` fence ids — all left to planning/execution, constrained by the decisions above and the existing guides' tone.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

ROADMAP.md lists no explicit `Canonical refs:` line for Phase 76; the following were accumulated from REQUIREMENTS.md and the codebase scout/research.

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` — REF-01 (lines 42), REF-02 (43), REF-03 (44), CONTRACT-02 (51); status rows 101-104.
- `.planning/ROADMAP.md` §"Phase 76" — goal + 4 success criteria.

### Phoenix Reference App
- `examples/phoenix_example/mix.exs` — dep constraints to bump (D-02).
- `examples/phoenix_example/config/config.exs` — references missing `PhoenixExampleWeb.ErrorJSON` (D-03 fix).
- `examples/phoenix_example/lib/phoenix_example_web/router.ex` — `:api` scope; add new recipe routes (D-07).
- `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` — existing Invoice/Branded download/preview pattern to extend (D-05/D-06).
- `examples/phoenix_example/lib/phoenix_example_web/controllers/page_controller.ex` — index/chooser page (D-07).
- `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` — assertion pattern to mirror (D-08).
- `lib/rendro/adapters/phoenix.ex` — adapter API (`render_pdf/3` attachment, `preview_pdf/2` inline); the surface REF-02 requires recipes to flow through.
- `lib/rendro/recipes/statement.ex`, `lib/rendro/recipes/receipt.ex`, `lib/rendro/recipes/certificate.ex` — `document/2` data-map shapes for fixtures (D-06).
- `lib/rendro/recipes/invoice.ex`, `lib/rendro/recipes/branded_invoice.ex` — already-demonstrated baseline.

### CI Isolation
- `.github/workflows/ci.yml` — full job graph; required `test` job's "Verify Phoenix Example" step to remove (D-11); engine lanes `signing-live-proof`, `long-lived-live-proof`, `release-proof`; advisory precedent `viewer-evidence-live-proof`.
- `priv/guardrails/required_status_checks.json` — `required_contexts` (keep) vs `advisory_contexts` (add `example-phoenix`); `additive_only` policy (D-12).
- `test/guardrails/required_checks_contract_test.exs` — single-element advisory destructure to refactor to `Enum.find/2` + new assertion (D-12).

### Guides & Docs-Contract
- `mix.exs` (root) `docs/0` (≈lines 93-171) — `extras:`, `groups_for_extras:`, `skip_undefined_reference_warnings_on:` (D-14).
- `test/support/docs_contract.ex` — `Rendro.Test.DocsContract` fence harness (`verified_fences/1`, `evaluate!/2`) (D-15).
- `test/docs_contract/branding_contract_test.exs`, `test/docs_contract/branding_claims_test.exs` — both-harness reference pattern.
- `test/docs_contract/viewer_evidence_claims_test.exs`, `test/docs_contract/integrations_claims_test.exs` — semantic-claims `assert`/`refute` + matrix cross-check pattern.
- `priv/support_matrix.json` — rows for `page_numbering`, `statement`, `receipt_report`, `certificate` (added Phase 75; ≈rows 384-433), incl. `unsupported` array; the claim-bounding source of truth.
- `guides/branding.md`, `guides/viewer_evidence.md` — tone/structure/fence reference; branding is the single source of truth for Invoice/BrandedInvoice (D-13).
- `scripts/verify_docs.exs` — docs lane registration (D-16).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Rendro.Adapters.Phoenix`** (`render_pdf/3` attachment, `preview_pdf/2` inline; both yield 200 + `application/pdf` + `%PDF-` body): the exact integration surface REF-02 mandates; reuse verbatim for the three new recipes.
- **Existing `PDFController` Invoice/BrandedInvoice actions + inline fixtures + `ConnCase` tests**: the demonstration idiom to clone for Statement/Receipt/Certificate.
- **`Rendro.Test.DocsContract`** (fence harness) + the `*_claims_test.exs` semantic-claims pattern: both docs-contract enforcement mechanisms already exist; CONTRACT-02 only extends them to new guides.
- **`priv/guardrails/required_status_checks.json` + `required_checks_contract_test.exs`**: the in-repo mechanism for recording required vs advisory CI checks; `viewer-evidence-live-proof` is a working advisory-job precedent.

### Established Patterns
- **Minimal, generator-free Phoenix example** — no Ecto/assets/LiveView/gettext; keep it that way (in-place upgrade, not regenerate).
- **Two-harness docs discipline** — runnable fences (`# docs-contract:` ids) prove examples execute; semantic-claims tests bound prose to the support matrix + proof lanes.
- **`additive_only` required-checks policy** — engine lanes stay required; new jobs land in `advisory_contexts`.

### Integration Points
- New CI job is graph-disconnected (`needs: []`) — connects to nothing, by design.
- New guides connect to ExDoc via `mix.exs` `docs/0` extras + a new group.
- New docs-contract tests connect to `priv/support_matrix.json` rows and on-disk proof-lane evidence paths.
</code_context>

<specifics>
## Specific Ideas

- "Page X of Y" footers, repeating table headers, carried/brought-forward balances are already shipped engine/recipe behaviors — guides document them but must not claim beyond the matrix rows.
- Arriving-engineer experience is the north star: the demo should look like the plain controller integration a real Phoenix engineer would copy, not a framework showcase.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. (Research surfaced one in-scope latent bug — the missing `PhoenixExampleWeb.ErrorJSON` module — captured as D-03 rather than deferred, since it blocks REF-01's `mix`-runnable requirement.)
</deferred>

---

*Phase: 76-Reference Phoenix App, CI, and Documentation Closure*
*Context gathered: 2026-05-29*
